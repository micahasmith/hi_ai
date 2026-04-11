(in-package #:hi-lifecycle)

;;; ============================================================================
;;; The Thermodynamic Engine (Master Loop)
;;; ============================================================================

(defun step-task (task-id)
  "Backward compatibility shim for server.lisp. Runs the stabilization loop."
  (declare (ignore task-id))
  (stabilize-graph))

(defun %safe-filename-string (text)
  "Convert a string into a safe filename component."
  (if (null text)
      "unknown"
      (let ((res (make-array (length text) :element-type 'character :fill-pointer 0)))
        (loop for c across text
              do (if (alphanumericp c)
                     (vector-push (char-downcase c) res)
                     (vector-push #\_ res)))
        (let ((trimmed (string-trim "_" res)))
          (if (string= trimmed "")
              "unknown"
              (subseq trimmed 0 (min (length trimmed) 40)))))))

(defun %get-timestamp-string ()
  "Get the current time formatted as YYYY_MM_DD_hhmmss."
  (multiple-value-bind (second minute hour date month year)
      (decode-universal-time (get-universal-time))
    (format nil "~4,'0D_~2,'0D_~2,'0D_~2,'0D~2,'0D~2,'0D"
            year month date hour minute second)))

(defun stabilize-graph ()
  "The thermodynamic heartbeat of the AGI. Loops until the graph reaches absolute rest (∆:∆)."
  (let ((cycle-count 0)
        (last-executed-task nil)
        (log-file nil)
        (log-dir (ensure-directories-exist (merge-pathnames "log-executions/" (uiop:getcwd)))))
    (loop
      (incf cycle-count)
      (format t "~&~%[Lifecycle] --- Starting Thermodynamic Cycle ~D ---~%" cycle-count)
      (let* ((initial-state (list :timestamp (get-universal-time)))
             ;; The capture+tap-> macro ensures every single phase of cognition is perfectly 
             ;; recorded, allowing the dashboard UI to render the "thought process" live.
             (trace (hi:capture+tap-> initial-state
                      :assimilate-senses  (%assimilate-sensory-inputs)
                      :project-voids      (%project-valences)
                      :apply-physics      (%run-implications)
                      :detect-unbalance   (%find-deepest-void)
                      :plan-resolution    (%generate-minimal-plan)
                      :execute-action     (%execute-plan-step)))
             (final-state (cdr (car (last trace)))))
        
        ;; Track the last task that had activity to report back to API
        (when (getf final-state :projected)
          (setf last-executed-task (getf final-state :projected)))
        
        ;; Determine log file name on first cycle (or when we first see text)
        (unless log-file
          (let ((text (or (getf final-state :assimilated)
                          (let ((ui-fact (find-if (lambda (f) (eq (hi:fact-relation f) :user-input)) hi:*working-ontology*)))
                            (when ui-fact (hi:fact-value ui-fact)))
                          (format nil "task_~A" (or last-executed-task "unknown")))))
            (setf log-file (merge-pathnames 
                            (format nil "~A_~A.lisp" 
                                    (%get-timestamp-string)
                                    (%safe-filename-string text))
                            log-dir))))

        ;; Write the trace to the log file
        (when log-file
          (with-open-file (stream log-file :direction :output :if-exists :append :if-does-not-exist :create)
            (format stream "~%;;; =========================================~%")
            (format stream ";;; Cycle ~D~%" cycle-count)
            (format stream ";;; =========================================~%")
            (let ((*print-pretty* t)
                  (*print-case* :downcase))
              (pprint trace stream))
            (format stream "~%~%")))

        ;; Stopping Condition: If there are no voids, the universe is balanced.
        (when (eq (getf final-state :unbalance) :balanced)
          (format t "~&[Lifecycle] Graph has reached absolute rest (∆:∆) after ~D cycles. Sleeping...~%" cycle-count)
          (format t "[Lifecycle] Execution trace logged to: ~A~%" log-file)
          ;; Return the format the API endpoint expects: (values ontology state-plist)
          (return (values hi:*working-ontology* (list :task-id (or last-executed-task (and (boundp 'hi:*active-task-id*) hi:*active-task-id*) :unknown-task)))))))))

(defun run-task (prompt &key context)
  "Interactive master agentic loop."
  (hi::with-log "lifecycle.lisp" 'run-task :prompt prompt :context context)
  
  (hi:reset-dot-graph)
  (hi::reset-tree-graph)
  (hi-events:reset-json-graph)
  (hi-events:add-ontology-listener #'hi:dot-renderer)
  (hi-events:add-ontology-listener #'hi::tree-renderer)
  (hi-events:add-ontology-listener #'hi:json-ontology-renderer)
  (unwind-protect
      (progn
        ;; Simply assert the sensory input and let the engine stabilize itself
        (hi:swap-ontology! #'hi:state-add-fact (hi:fact :user :said prompt :ephemeral))
        (when context
          (dolist (c context)
            (hi:swap-ontology! #'hi:state-add-fact (hi:fact :user :context c :ephemeral))))
        (stabilize-graph))
    (hi-events:clear-ontology-listeners)))
