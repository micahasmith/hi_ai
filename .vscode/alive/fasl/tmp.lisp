(in-package #:hi-task)

;;; IR / IL v1: Graph-Native Tasks
;;; --------------------------------------------------------------------------
;;; We eliminate the rigid (task ...) data structure. A task is now simply an 
;;; entity (e.g., :this-task) embedded directly within the global state graph.
;;; We query the graph to access its properties, unifying tasks with standard ERV logic.

(defparameter *user-intents*
  '(:verify-result
    :summarize
    :transform-state
    :repair-state)
  "External orthogonal vectors representing macro-level human goals.")

(defparameter *system-directives*
  '(:determine-success-criteria
    :generate-plan)
  "Internal pipeline transitions not exposed to the LLM classifier.")

(defparameter *known-intents*
  (append *user-intents* *system-directives*)
  "The union of all valid intent symbols for the planning IR.")

(defparameter *known-operators*
  '(:inspect
    :execute
    :infer
    :decompose
    :derive
    :verify
    :repair
    :summarize
    :compare
    :select
    :ask-user
    'hi-ontology:∴)
  "Initial allowed plan operators for the planning IR.")

(defparameter *known-statuses*
  '(:draft :ready :verified :failed :summarized :blocked :waiting-on-user :in-progress)
  "Allowed task lifecycle statuses.")

;;; Pure Functional Pipeline for Target Identification

(defun %find-all-voids (state)
  "Scan the input facts for any entity marked with :STATUS ∴."
  (let* ((facts (getf state :facts))
         (voids (remove-if-not (lambda (f) 
                                 (and (eq (third f) :status) 
                                      (eq (fourth f) 'hi-ontology:∴)))
                               facts))
         (void-entities (mapcar #'second voids)))
    (append state (list :void-list void-entities))))

(defun %type-voids (state)
  "Categorize voids as :EXPLICIT, :IMPLICIT, or :UNKNOWABLE based on their topology."
  ;; For now, everything is :EXPLICIT unless we have logic to prove it's :IMPLICIT.
  ;; A void is :EXPLICIT if it's the target of a question mark, or the unexecuted action of an imperative.
  ;; We will refine this heuristic. Defaulting all found voids to :EXPLICIT.
  (let* ((voids (getf state :void-list))
         (typed-voids (mapcar (lambda (v) (list v :explicit)) voids))
         (status (if typed-voids :blocked :ready)))
    (append state (list :typed-voids typed-voids :status status))))

(defun %determine-intent (state)
  "Analyze structural nodes (:S[n], :A[n]) to assign :INFER, :EXECUTE, or :INSPECT."
  (let* ((facts (getf state :facts))
         (voids (getf state :void-list))
         ;; Has a question mark? -> :infer
         (is-question (find-if (lambda (f) (and (eq (third f) :punct) (eq (fourth f) :?))) facts))
         ;; Has an implicit YOU? -> :execute
         (has-implicit-you (find-if (lambda (f) (and (eq (second f) :you) (eq (third f) :implicit) (eq (fourth f) 't))) facts))
         (intent (cond
                   (is-question :infer)
                   (has-implicit-you :execute)
                   (voids :infer)
                   (t :inspect))))
    (append state (list :intent intent))))

(defun %generate-meta-reasoning (state)
  "Generate :PENDING-QUESTION and :ASSUMPTION based on typed voids."
  (let* ((typed-voids (getf state :typed-voids))
         (intent (getf state :intent))
         (questions '())
         (assumptions '()))
    
    (dolist (tv typed-voids)
      (let ((v (first tv))
            (type (second tv)))
        (cond
          ((eq type :explicit)
           (push (format nil "I need to resolve ~A before I can proceed." v) questions))
          ((eq type :implicit)
           (push (format nil "I am assuming default parameters for ~A." v) assumptions)))))
    
    ;; Example assumption for implicit intent
    (when (eq intent :inspect)
      (push "I am assuming the user is simply stating a fact and requires no immediate action." assumptions))

    (append state (list :questions (reverse questions) :assumptions (reverse assumptions)))))

(defun %determine-subject (state)
  "Find the primary entity being operated on from the raw facts."
  (let* ((facts (getf state :facts))
         (subject nil))
    (dolist (f facts)
      (let* ((entity (second f))
             (relation (third f))
             (value (fourth f)))
        (when (and (symbolp entity) (eq relation 'hi-ontology:is-a) (listp value) (eq (first value) 'hi-fact:fact))
          (let ((nested-entity (second value))
                (nested-relation (third value))
                (nested-value (fourth value)))
            (if (member nested-entity '(:you :implicit :what :how :when))
                ;; The entity is a question/variable, so the subject is the object!
                (when (and (symbolp nested-value) (not (member nested-value '(:you :implicit :what :how :when))))
                  (setf subject nested-value)
                  (return))
                ;; The entity is the subject
                (when (symbolp nested-entity)
                  (setf subject nested-entity)
                  (return)))))))
    (append state (list :subject subject))))

(defun %emit-task-facts (state)
  "Construct the final task grounding facts from the state trace."
  (let* ((task-id (getf state :task-id))
         (intent (getf state :intent))
         (status (getf state :status))
         (subject (getf state :subject))
         (voids (getf state :void-list))
         (questions (getf state :questions))
         (assumptions (getf state :assumptions))
         (task-facts (list
                      (list 'hi:fact task-id 'hi-ontology:is-a intent :ephemeral)
                      (list 'hi:fact task-id :status status :ephemeral))))
    
    (when subject
      (push (list 'hi:fact task-id :subject subject :ephemeral) task-facts))
    
    (dolist (v voids)
      (push (list 'hi:fact task-id 'hi-ontology:requires v :ephemeral) task-facts))
      
    (dolist (q questions)
      (push (list 'hi:fact task-id :pending-question q :ephemeral) task-facts))
      
    (dolist (a assumptions)
      (push (list 'hi:fact task-id :assumption a :ephemeral) task-facts))
      
    (append state (list :task-facts (reverse task-facts)))))

(defun %bind-task-intent-trace (task-id state)
  "Run the intent pipeline and return the raw capture-> trace."
  (hi:capture+tap-> state
    :voids (%find-all-voids)
    :typed (%type-voids)
    :intent (%determine-intent)
    :meta (%generate-meta-reasoning)
    :subject (%determine-subject)
    :task-facts (%emit-task-facts)))

(defun bind-task-intent (task-id facts)
  "Analyze a flat list of semantic facts, determine the overarching intent, 
   and return a new list combining the semantic facts with task-binding facts."
  (let ((trace (%bind-task-intent-trace task-id (list :task-id task-id :facts facts))))
    (append facts (getf (cdr (car (last trace))) :task-facts))))

(defun plan-step (id operator &rest args)
  "Construct a plan step.
A step has the shape: (plan-step <id> (<operator> <arg> ...))."
  (list 'plan-step id (cons operator args)))

(defun plan-step-p (form)
  "Return true when FORM is a well-shaped plan step."
  (and (consp form)
       (eq (first form) 'plan-step)
       (= (length form) 3)
       (symbolp (second form))
       (consp (third form))
       (symbolp (first (third form)))))

(defun plan-step-id (form)
  "Return the id portion of a plan step."
  (assert (plan-step-p form) (form) "Not a valid plan step: ~S" form)
  (second form))

(defun plan-step-operation (form)
  "Return the operation list portion of a plan step."
  (assert (plan-step-p form) (form) "Not a valid plan step: ~S" form)
  (third form))

(defun plan-step-operator (form)
  "Return the operator symbol for a plan step."
  (first (plan-step-operation form)))

(defun plan-step-args (form)
  "Return the argument list for a plan step."
  (rest (plan-step-operation form)))

;;; Task Accessors (Graph Queries)

(defun task-p (entity &optional (state hi:*working-ontology*))
  "Return true if ENTITY has an intent in the STATE, marking it as a task."
  (not (null (task-intent entity state))))

(defun task-section-value (entity section-name &optional (state hi:*working-ontology*))
  "Query the STATE for the singular value of SECTION-NAME attached to ENTITY.
Returns the most recently added value (the last one chronologically)."
  (let ((matches (hi-fact:state-find-by-relation section-name state))
        (result nil))
    (dolist (f matches)
      (when (eq (hi-fact:fact-entity f) entity)
        (setf result (hi-fact:fact-value f))))
    result))

(defun task-prompt (entity &optional (state hi:*working-ontology*))
  "Return the human language prompt for the task."
  (let ((matches (hi-fact:state-find-by-relation 'hi-ontology:implies state)))
    (dolist (f matches)
      (when (and (eq (hi-fact:fact-value f) entity)
                 (stringp (hi-fact:fact-entity f)))
        (return-from task-prompt (hi-fact:fact-entity f))))
    nil))

(defun task-eil (entity &optional (state hi:*working-ontology*))
  "Return the EAIL/EIL AST for the task."
  (task-section-value entity :eil state))

(defun task-intent (entity &optional (state hi:*working-ontology*))
  "Return the task intent symbol (which it is-a)."
  (let ((matches (hi-fact:state-find-by-relation 'hi-ontology:is-a state)))
    (dolist (f matches)
      (when (eq (hi-fact:fact-entity f) entity)
        (let ((val (hi-fact:fact-value f)))
          (when (or (known-intent-p val) (known-operator-p val))
            (return-from task-intent val)))))
    nil))

(defun task-status (entity &optional (state hi:*working-ontology*))
  "Return the task status symbol."
  (task-section-value entity :status state))

(defun task-interaction (entity &optional (state hi:*working-ontology*))
  "Return the structured interaction request plist when waiting on user."
  (task-section-value entity :interaction state))

(defun task-plan (entity &optional (state hi:*working-ontology*))
  "Return the plan entity produced by the task."
  (let ((matches (hi-fact:state-find-by-relation 'hi-ontology:implies state)))
    (dolist (f matches)
      (when (eq (hi-fact:fact-entity f) entity)
        (let ((val (hi-fact:fact-value f)))
          (when (and (symbolp val) (uiop:string-prefix-p "PLAN-" (symbol-name val)))
            (return-from task-plan val)))))
    nil))

(defun known-intent-p (intent)
  "Return true when INTENT is in the current intent registry."
  (not (null (member intent *known-intents* :test #'eq))))

(defun known-operator-p (operator)
  "Return true when OPERATOR is in the current operator registry."
  (not (null (member operator *known-operators* :test #'eq))))

(defun known-status-p (status)
  "Return true when STATUS is in the current status registry."
  (not (null (member status *known-statuses* :test #'eq))))

(defun valid-task-p (entity &optional (state hi:*working-ontology*))
  "Return true when ENTITY is structurally and semantically a valid task in STATE."
  (and (task-p entity state)
       (let ((intent (task-intent entity state))
             (status (task-status entity state)))
         (and (symbolp intent)
              (known-intent-p intent)
              (symbolp status)
              (known-status-p status)))))

(defun demo-task-facts ()
  "Return a list of facts representing a demo task."
  (list
   (hi:fact :this-task 'hi-ontology:is-a :determine-success-criteria :ephemeral)
   (hi:fact :this-task :status :draft :ephemeral)
   (hi:fact :this-task :prompt "demo" :ephemeral)
   (hi:fact :website :status :in-progress :ephemeral)
   (hi:fact :website :type :file :ephemeral)))
