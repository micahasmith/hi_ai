(in-package :hi)

(defparameter *current-workspace* nil
  "The root directory path for the current project being analyzed. If nil, no workspace is injected.")

;; user input data model

(defclass input-data ()
  ((source
    :initarg :source
    :accessor input-data-source
    :type t
    :documentation "Origin of the input (e.g. :cli, :file, :http, :repl).")
   (data
    :initarg :data
    :accessor input-data-data
    :type t
    :documentation "Input payload. Can be any type (string, list, map, etc.).")
   (context
    :initarg :context
    :initform nil
    :accessor input-data-context
    :type list
    :documentation "Optional list of context items (files, URLs, etc.)."))
  (:documentation "Represents user-provided input with a source, data payload, and optional context."))

(defun make-input-data (&key source data context)
  "Create an INPUT-DATA instance with flexible :source, :data types, and optional :context."
  (make-instance 'input-data :source source :data data :context context))

(defgeneric handle-input (source data &key context resume-task-id)
  (:documentation "Dispatch on SOURCE and DATA type to handle input. Returns task-id."))

(defun %classify-context-item (task-id item)
  "Heuristically classify a context string into an ontological type."
  (let ((entity (if (or (uiop:string-prefix-p "http://" item)
                        (uiop:string-prefix-p "https://" item))
                    (intern item :keyword)
                    (path->entity item))))
    (cond
      ((or (uiop:string-prefix-p "http://" item)
           (uiop:string-prefix-p "https://" item))
       (list (fact entity :type :url :ephemeral)
             (fact task-id :user-context entity :ephemeral)))
      ((uiop:directory-exists-p item)
       (list (fact entity :type :directory :ephemeral)
             (fact task-id :user-context entity :ephemeral)))
      ((uiop:file-exists-p item)
       (list (fact entity :type :file :ephemeral)
             (fact task-id :user-context entity :ephemeral)))
      (t
       (list (fact entity :type :unknown-artifact :ephemeral)
             (fact task-id :user-context entity :ephemeral))))))

(defun safe-read-eail (str)
  "Pre-process the LLM string to convert all namespaced symbols (except ∆:) 
   into keywords to prevent reader package errors from hallucinations."
  (let* ((clean-str (extract-lisp-list str))
         (no-props (cl-ppcre:regex-replace-all "prop:([a-zA-Z0-9\\-]+)" clean-str ":\\1"))
         (final-str no-props))
    (let* ((*read-eval* nil)
           (*package* (find-package :hi))
           (ast (read-from-string final-str))
           (approved-physics (list '∆:is-a '∆:requires '∆:implies '∆:∴ '∆:∆)))
      ;; Recursively verify no illegal ∆: symbols exist
      (labels ((verify-ast (node)
                 (cond
                   ((consp node)
                    (verify-ast (car node))
                    (verify-ast (cdr node)))
                   ((and (symbolp node) 
                         (uiop:string-prefix-p "HI-ONTOLOGY:" (symbol-name node))
                         (not (member node approved-physics)))
                    (error "LLM Hallucinated illegal physics operator: ~S" node)))))
        (verify-ast ast))
      ast)))

(defun %parse-eil (state)
  (let ((text (getf state :text)))
    (append state (list :eil (hi-eil:eng->eil text)))))

(defun %compile-eail (state)
  (let ((eil (getf state :eil)))
    (append state (list :eail (mapcar #'hi-eail:eil->eail eil)))))

(defun %ground-sail (state)
  (let ((eail (getf state :eail)))
    (append state (list :sail (mapcar #'hi-sail:eail->sail eail)))))

(defun %emit-facts (state)
  (let ((sail (getf state :sail)))
    (append state (list :facts (alexandria:mappend #'hi-sail-to-facts:sail->facts sail)))))

(defun compile-text (state)
  "Run the STATE plist (containing :text) through the NLP pipeline.
   Returns the modified STATE plist with :eil, :eail, :sail, and :facts appended."
  (let ((trace (hi:capture+tap-> state
                 :eil (%parse-eil)
                 :eail (%compile-eail)
                 :sail (%ground-sail)
                 :facts (%emit-facts))))
    ;; The final state is the value of the LAST step
    (cdr (car (last trace)))))

(defun explain-thought (text)
  "Run a raw English string through the entire cognitive pipeline and print the full trace."
  (format t "~%~%[COGNITIVE TRACE] \"~A\"~%" text)
  (format t "------------------------------------------------------------~%")
  (let* ((task-id (intern (string-upcase (format nil "TASK-~A" (get-universal-time))) :keyword))
         (initial-state (list :task-id task-id :text text))
         (nlp-state (compile-text initial-state))
         (final-state (hi-task::%bind-task-intent-trace task-id nlp-state)))
    
    (format t "[RESULT] Cognition Balanced. Task ~A is ~A.~%~%" 
            task-id (getf final-state :status)))
  t)

(defmethod handle-input ((source (eql :cli)) (data string) &key context resume-task-id)
  ;; Command mode interception
  (when (and (> (length data) 0) (char= (char data 0) #\/))
    (let* ((parts (uiop:split-string (string-trim " " data) :separator " "))
           (cmd (string-downcase (first parts))))
      (cond
        ((string= cmd "/clear")
         (hi-events:reset-json-graph)
         (clear-session-ontology *session-id*)
         (ignore-errors
           (redis:with-connection ()
             (redis:red-del (hi-events::%session-key "active-task"))))
         (return-from handle-input :command-clear))
        ((string= cmd "/help")
         (return-from handle-input :command-help))
        (t
         (return-from handle-input :command-unknown)))))

  (let* ((task-id (or resume-task-id (intern (string-upcase (format nil "TASK-~A-~A-~A" *session-id* (get-universal-time) (random 10000))) :keyword)))
         (initial-facts (if resume-task-id '() (list (fact data 'hi-ontology:implies task-id :ephemeral)))))

    (dolist (f initial-facts) (swap-ontology! #'state-add-fact f))
    (loop for item in context do 
          (dolist (f (%classify-context-item task-id item))
            (swap-ontology! #'state-add-fact f)))

    (run-active-scanners)

    (when resume-task-id
      (format t "~&[Socratic] Resuming blocked task ~A...~%" task-id)
      (swap-ontology! #'state-remove-fact task-id :status :blocked)
      (swap-ontology! #'state-add-fact (fact task-id :status :draft :ephemeral)))

    (unless resume-task-id
      (let* ((initial-state (list :task-id task-id :text data))
             (nlp-state (compile-text initial-state))
             (reasoning-trace (hi-task::%bind-task-intent-trace task-id nlp-state))
             ;; The final state is the value of the last step in the trace
             (final-state (cdr (car (last reasoning-trace))))
             (final-facts (getf final-state :task-facts)))
        
        (dolist (f (getf nlp-state :facts))
          (swap-ontology! #'state-add-fact f))
          
        (dolist (f final-facts)
          (swap-ontology! #'state-add-fact f))

        (swap-ontology! #'state-add-fact (fact task-id :user-input data :ephemeral))))

    task-id))
(defmethod handle-input ((source (eql :file)) (data list) &key context resume-task-id)
  (declare (ignore source data context resume-task-id))
  :no-task)

(defmethod handle-input ((source (eql :http)) (data fset:map) &key context resume-task-id)
  (declare (ignore source data context resume-task-id))
  :no-task)

(defmethod handle-input ((source (eql :repl)) (data string) &key context resume-task-id)
  (handle-input :cli data :context context :resume-task-id resume-task-id))

(defmethod handle-input ((source t) (data t) &key context resume-task-id)
  (declare (ignore source data context resume-task-id))
  :no-task)

(defun dispatch-input-data (input &key resume-task-id)
  "Route INPUT-DATA by its :source and :data type."
  (handle-input (input-data-source input)
                (input-data-data input)
                :context (input-data-context input)
                :resume-task-id resume-task-id))
