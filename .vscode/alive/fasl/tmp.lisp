(defpackage hi/tests/main
  (:use :cl :hi :parachute))
(in-package :hi/tests/main)

;; NOTE: To run this test file, execute `(asdf:test-system :hi)' in your Lisp.

(define-test smoke-test
  (true (smoke-test)))

(define-test fact-construction
  (is equal
      (fact 'website 'status 'in-progress)
      '(fact website status in-progress)))

(define-test demo-state-test
  (true (state-has-fact-p (demo-state) 'website 'status 'in-progress))
  (is equal
      (state-find-by-entity (demo-state) 'website)
      '((fact website status in-progress)
        (fact website framework react))))

(define-test demo-task-test
  (true (task-p (demo-task)))
  (true (valid-task-p (demo-task)))
  (is equal
      (mapcar #'plan-step-operator (task-plan (demo-task)))
      '(inspect infer decompose verify)))
