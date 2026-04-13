(require "asdf")
(let ((quicklisp-init (merge-pathnames "quicklisp/setup.lisp" (user-homedir-pathname))))
  (when (probe-file quicklisp-init) (load quicklisp-init)))
(push (uiop:getcwd) asdf:*central-registry*)
(asdf:load-system :hi)

(in-package :hi)

(format t "~&[Repro] Initializing state...~%")
(setf *session-id* "repro-session")
(setf *user-id* "local-user")
(setf *working-ontology* (list (hi:fact :user :said "what color is the sky?" :ephemeral)))

(format t "~&[Repro] Entering stabilize-graph...~%")
(handler-case
    (hi-lifecycle:stabilize-graph)
  (error (c)
    (format t "~&[Repro] Caught error: ~A~%" c)))

(format t "~&[Repro] Done.~%")
