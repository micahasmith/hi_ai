(in-package #:hi-lifecycle)

;;; ============================================================================
;;; THE RULES OF THE LOOP (COGNITIVE METABOLISM)
;;; ============================================================================
;;; To maintain the architectural integrity of the Thermodynamic AGI, every 
;;; station in this assembly line MUST adhere to these five strict laws:
;;;
;;; 1. THE INPUT IS THE UNIVERSE: Stations only read from (getf state :ontology).
;;;    They must NEVER look at global variables or session state directly.
;;;
;;; 2. THE OUTPUT IS A DELTA: Stations must record their specific finding or 
;;;    contribution under a dedicated key in the state plist (e.g. :assimilated).
;;;
;;; 3. FUNCTIONAL ADVANCEMENT: Stations MUST NOT mutate the ontology. They use 
;;;    hi:state-add-fact/remove-fact to generate a new list and return it via 
;;;    %update-state.
;;;
;;; 4. TOTAL REIFICATION: Invisible thoughts, decisions, or metadata (like voids, 
;;;    depths, or rotations) must be reified as temporary (FACT ...) tuples in 
;;;    the ontology so they can be rendered by the UI and debugged in logs.
;;;
;;; 5. THE LOOP IS THE ONLY ACTOR: Helper functions, tools, and databases only 
;;;    emit facts or errors. The Loop is the sole entity that decides how to 
;;;    route those facts in the next cycle.
;;; ============================================================================

(defparameter *max-thermodynamic-cycles* 3
  "Safety limit to prevent infinite reasoning loops.")

;;; --- Reusable Loop Sub-Functions ---

(defun %graph-at-rest-p (ontology)
  "Predicate to determine if the graph has reached a stable thermodynamic state (∆:∆)."
  (let ((active-voids (remove-if-not (lambda (f) (and (hi:fact-p f)
                                                      (symbolp (hi:fact-value f))
                                                      (string= (symbol-name (hi:fact-value f)) "∴"))) 
                                     ontology))
        (active-senses (remove-if-not (lambda (f) (and (hi:fact-p f)
                                                       (eq (hi:fact-entity f) :user)
                                                       (eq (hi:fact-relation f) :said)))
                                      ontology))
        (unbound-inputs (remove-if-not (lambda (f) (and (hi:fact-p f)
                                                        (eq (hi:fact-entity f) :user)
                                                        (eq (hi:fact-relation f) :user-input)))
                                       ontology)))
    (and (null active-voids) (null active-senses) (null unbound-inputs))))

(defun %execute-cognitive-pipeline (initial-state)
  "Runs the functional assembly line for a single cycle and returns (VALUES final-state trace).
   The trace perfectly preserves the PLIST structure: (STATION-KEY (:state FULL-OBJECT :delta DELTA-PLIST :diff DIFF-STRING))."
  (let* ((current-val initial-state)
         (trace (list (list :input (list :state initial-state :delta initial-state :diff nil)))))
    (flet ((step-pipe (key fn)
             (let ((prev current-val))
               (setf current-val (funcall fn current-val))
               (let ((delta (%plist-diff prev current-val))
                     (diff-str (hi::generate-lisp-diff prev current-val)))
                 (push (list key (list :state current-val :delta delta :diff diff-str)) trace)
                 ;; Emit the ENTIRE object as payload, along with the diff
                 (hi-events:emit-tap-event key current-val diff-str)))))
      
      (step-pipe :assimilate-senses      #'%assimilate-sensory-inputs)
      (step-pipe :project-voids          #'%project-valences)
      (step-pipe :apply-physics          #'%run-implications)
      (step-pipe :transduce-isomorphisms  #'%transduce-isomorphisms)
      (step-pipe :hypothesize-isomorphisms #'%hypothesize-isomorphisms)
      (step-pipe :detect-unbalance       #'%find-deepest-void)
      (step-pipe :plan-resolution        #'%generate-minimal-plan)
      (step-pipe :execute-action         #'%execute-plan-step)
      
      (values current-val (nreverse trace)))))

(defun %recover-from-metabolic-failure (err trace history cycle-count log-dir last-task state)
  "Handles a CRASH within the pipeline, logging the partial trace and state."
  (let* ((bt (with-output-to-string (s) (uiop:print-backtrace :stream s)))
         (error-dump (list :task-id (or last-task :unknown-task)
                           :cycles cycle-count
                           :history (reverse (cons trace history)))))
    (format t "~&[Lifecycle] !!! CRASH in Cycle ~D !!! Error: ~A~%" cycle-count err)
    (let ((log-file (ensure-log-file state nil log-dir cycle-count last-task)))
      (log-final-state log-file error-dump (list :message (format nil "~A" err) :backtrace bt)))
    (error err)))

;;; --- Main Orchestrator ---

(defun stabilize-graph ()
  "The thermodynamic heartbeat of the AGI. Loops until the graph reaches absolute rest (∆:∆)."
  (let ((cycle-count 0)
        (last-executed-task nil)
        (history '())
        (log-dir (ensure-directories-exist (merge-pathnames "log-executions/" (uiop:getcwd)))))
    (loop
      (incf cycle-count)
      
      ;; 1. Check for Cognitive Stall
      (when (> cycle-count *max-thermodynamic-cycles*)
        (format t "~&[Lifecycle] !!! ERROR: Cognitive Stall detected after ~D cycles.~%" cycle-count)
        (let ((error-dump (list :task-id (or last-executed-task :unknown-task)
                                :cycles cycle-count
                                :history (reverse history))))
          (log-final-state (ensure-log-file (list :ontology hi:*working-ontology*) nil log-dir cycle-count last-executed-task)
                           error-dump (list :message "Cognitive Stall: Max cycles reached." :backtrace ""))
          (return (values hi:*working-ontology* error-dump))))

      (format t "~&~%[Lifecycle] --- Starting Thermodynamic Cycle ~D ---~%" cycle-count)
      
      ;; 2. Pre-Flight Check: Is the universe already balanced?
      (if (%graph-at-rest-p hi:*working-ontology*)
          (let ((final-dump (list :task-id (or last-executed-task :unknown-task)
                                  :cycles cycle-count
                                  :history (reverse history))))
            (format t "~&[Lifecycle] Universe is stable (∆:∆).~%")
            (log-final-state (ensure-log-file (list :ontology hi:*working-ontology*) nil log-dir cycle-count last-executed-task)
                             final-dump)
            (return (values hi:*working-ontology* final-dump)))

          ;; 3. Execute Cognitive Cycle
          (let* ((initial-state (list :timestamp (get-universal-time)
                                       :ontology hi:*working-ontology*)))
            (hi-events:emit-tap-event :input initial-state nil)
            
            (handler-case
                (multiple-value-bind (final-state trace) (%execute-cognitive-pipeline initial-state)
                  (push trace history)
                  (setf hi:*working-ontology* (getf final-state :ontology))
                  (when (getf final-state :projected-task)
                    (setf last-executed-task (getf final-state :projected-task))))
              
              (error (c)
                (%recover-from-metabolic-failure c '() history cycle-count log-dir last-executed-task initial-state))))))))

(defun step-task (task-id)
  (declare (ignore task-id))
  (stabilize-graph))

(defun run-task (prompt &key context)
  "Interactive master agentic loop."
  (let ((hi:*session-id* (or (and (boundp 'hi:*session-id*) hi:*session-id*) "cli-session"))
        (hi:*user-id* (or (and (boundp 'hi:*user-id*) hi:*user-id*) "local-user")))
    (hi::with-log "lifecycle.lisp" 'run-task :prompt prompt :context context)
    (hi-events:add-ontology-listener #'hi:dot-renderer)
    (hi-events:add-ontology-listener #'hi:json-ontology-renderer)
    (unwind-protect
        (progn
          (hi:swap-ontology! #'hi:state-add-fact (hi:fact :user :said prompt :ephemeral))
          (when context
            (dolist (c context)
              (hi:swap-ontology! #'hi:state-add-fact (hi:fact :user :context c :ephemeral))))
          (stabilize-graph))
      (hi-events:clear-ontology-listeners))))
