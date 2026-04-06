   (∆:IS-A ((∆:√ :SKY :ATMOSPHERE :STATE :SYSTEM) '())
           ((∆:√ :BLUE :COLOR :STATE :CONCEPT) '())
           'NIL)

(∆:IS-A 
        (:COLOR HI-ONTOLOGY:∴ '()) 
        (:GRASS '()) 
        'NIL)

 (∆:IS-A 
        ((∆:† :COLOR :ROOT :FORM :PILLAR HI-ONTOLOGY:∴ '()) '()) 
        (:GRASS '()) 
        'NIL)

(((∆:√ :GRASS :CONTAIN :PATIENT :MATERIAL T '()) :GRASS) '())


(:BE (:MAN '((:NUMBER :SING) (:DET :THE)
                             (:RELCL (:WRITE (:WHO 'NIL) (:LISP '((:NUMBER :SING)))
                                             '((:TENSE :PAST) (:VERBFORM :FIN))))))
     (:SMART '((:DEGREE :POS)))
     '((:MOOD :IND) (:NUMBER :SING) (:PERSON :|3|) (:TENSE :PRES)
                    (:VERBFORM :FIN) (:PUNCT :|.|)))

(∆:REQUIRES

 (∆:IS-A (:MAN '((∆:† :WHO HI-ONTOLOGY:∴ '()) '()))
         (:SMART '())
         'NIL)

 (∆:IMPLIES (∆:IS-A ((∆:† :WHO HI-ONTOLOGY:∴ '()) '()) (:NIL '()) 'NIL)
            (∆:IS-A (:LISP '((:WRITE T))) (:NIL '()) 'NIL)
            '((:WRITE T))
            '((:TENSE :PAST) (:VERBFORM :FIN)))

 '((∆:† :WHO HI-ONTOLOGY:∴ '()) '())

 '((:MOOD :IND) (:NUMBER :SING) (:PERSON :|3|) (:TENSE :PRES) (:VERBFORM :FIN) (:PUNCT :|.|)))

 (∆:REQUIRES

  (∆:IS-A ((∆:√ :MAN :HUMAN :AGENT :MATERIAL 'NIL '()) '((∆:† :WHO HI-ONTOLOGY:∴ '()) '()))
          ((∆:√ :SMART :INTELLIGENCE :STATE :CONCEPT 'NIL '()) '())
          'NIL)

  (∆:IMPLIES (∆:IS-A ((∆:† :WHO HI-ONTOLOGY:∴ '()) '()) (:NIL '()) 'NIL)
             (∆:IS-A ((∆:√ :LISP :LANGUAGE :PATIENT :SYSTEM 'NIL '()) '(((∆:√ :WRITE :CREATE :ACTION :MATERIAL 'NIL '()) T))) (:NIL '()) 'NIL)
             '(((∆:√ :WRITE :CREATE :ACTION :MATERIAL 'NIL '()) T))
             '((:TENSE :PAST) (:VERBFORM :FIN)))

  '((∆:† :WHO HI-ONTOLOGY:∴ '()) '())

  '((:MOOD :IND) (:NUMBER :SING) (:PERSON :|3|) (:TENSE :PRES) (:VERBFORM :FIN) (:PUNCT :|.|)))