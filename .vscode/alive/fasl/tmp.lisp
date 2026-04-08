(in-package #:hi)

(defun get-eail-test-14 ()
  (list
   :number 14
   :description "Property Void (What color is X)"
   :text "What color is the sky?"
   :eil '((:BE (:NIL 'NIL) (:COLOR '((:NUMBER :SING) (:DET :WHAT)))
           (:SKY '((:NUMBER :SING) (:DET :THE)))
           '((:MOOD :IND) (:NUMBER :SING) (:PERSON :|3|) (:TENSE :PRES) (:VERBFORM :FIN) (:PUNCT :?))))
   :eail '(∆:IS-A (:SKY 'NIL) (:COLOR hi-ontology:∴) '((:PUNCT :?)))
   :sail '(∆:IS-A ((∆:√ :SKY :ATMOSPHERE :STATE :SYSTEM 'NIL 'NIL) 'NIL)
           ((∆:√ :COLOR :PHYSICAL-NATURE :STATE :CONCEPT hi-ontology:∴ 'NIL) 'NIL) '((:PUNCT :?)))
   :facts '((FACT :SKY :PILLAR :SYSTEM :EPHEMERAL)
            (FACT :SKY :FORM :STATE :EPHEMERAL)
            (FACT :SKY :ROOT :ATMOSPHERE :EPHEMERAL)
            (FACT :COLOR :PILLAR :CONCEPT :EPHEMERAL)
            (FACT :COLOR :FORM :STATE :EPHEMERAL)
            (FACT :COLOR :ROOT :PHYSICAL-NATURE :EPHEMERAL)
            (FACT :COLOR :STATUS ∴ :EPHEMERAL)
            (FACT :COLOR :REPRESENTATION ∴ :EPHEMERAL)
            (FACT :S1 :PILLAR :SYSTEM :EPHEMERAL)
            (FACT :S1 :FORM :STATE :EPHEMERAL)
            (FACT :S1 ∆:IS-A (FACT :SKY ∆:IS-A (:COLOR :PHYSICAL-NATURE :STATE :CONCEPT ∴ 'NIL) :EPHEMERAL) :EPHEMERAL)
            (FACT :S1 :PUNCT :? :EPHEMERAL))))