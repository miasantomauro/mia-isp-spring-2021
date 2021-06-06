#lang forge/core
(require "../macrosketch.rkt")

(set-option! 'verbose 5)
(set-option! 'solver 'MiniSatProver)
;(set-option! 'skolem_depth 2)
;(set-option! 'sb 20000)
(set-option! 'logtranslation 1)
(set-option! 'coregranularity 1)
(set-option! 'core_minimization 'hybrid)
;(set-option! 'core_minimization 'rce)


(defprotocol or basic
  (defrole init (vars (a b s name) (na text) (k skey) (m text))
    (trace
     (send (cat m a b (enc na m a b (ltk a s)))) ; 1
     ;(recv (cat m (enc na k (ltk a s)))) ; 4
    ))
  (defrole resp
    (vars (a b s name) (nb text) (k skey) (m text) (x y mesg))
    (trace
     (recv (cat m a b x)) ; 1
     (send (cat m a b x (enc nb m a b (ltk b s)))) ; 2
    ; (recv (cat m y (enc nb k (ltk b s)))) ; 3
    ; (send y) ; 4
     ))
  (defrole serv (vars (a b s name) (na nb text) (k skey) (m text))
    (trace  
     (recv (cat m a b (enc na m a b (ltk a s)) 
                (enc nb m a b (ltk b s)))) ;2
     )
     ;(send (cat m (enc na k (ltk a s)) (enc nb k (ltk b s))))) ;3
    (uniq-orig k)
    )
  )

; Only one skeleton: responder POV
; long-term keys are freshly chosen + not shared
; the nonce nb is freshly chosen and uniquely originated
(defskeleton or
  (vars (nb text) (s a b name))
  (defstrand resp 4 (a a) (b b) (s s) (nb nb))
  (non-orig (ltk a s) (ltk b s))
  (uniq-orig nb))

; vacuity check
#;(test OR_SAT
      #:preds [
               exec_or_init
               exec_or_resp
               exec_or_serv
               constrain_skeleton_or_0               
               temporary
               wellformed               
               ]
      #:bounds [(is next linear)]
      #:scope [(KeyPairs 1 1)
               (Timeslot 8 8) ; recv + send (recall attacker is medium)
               
               (mesg 21) ; 9 + 4 + 3 + 5
               
               (Key 9 9)
               (akey 6 6)               
               (PrivateKey 3 3)
               (PublicKey 3 3)
               (skey 3 3)
               
               (name 4 4) ; attacker plus server, init, resp's agents
               (Attacker 1 1)
               
               (text 3 3) ; includes data
               
               (Ciphertext 5 5)               
               
               (AttackerStrand 1 1)                              
               (or_init 1 1)
               (or_resp 1 1)
               (or_serv 1 1)               
               
               (skeleton_or_0 1 1)              
               (Int 5 5) 
               ]
      #:expect sat
      )


; vacuity check: IDENTICAL to above except for the a!=b constraint
; debug not anymore -- adding keys
;(test OR_SAT_diffab
(run OR_SAT_diffab
      #:preds [
               exec_or_init
               exec_or_resp
               exec_or_serv
               constrain_skeleton_or_0               
               temporary
               wellformed

               ; initiator's a, b, s differ (prevent annoying examples)
               (not (= (join or_init or_init_a)
                       (join or_init or_init_b)))
               (not (= (join or_init or_init_a)
                       (join or_init or_init_s)))
               (not (= (join or_init or_init_b)
                       (join or_init or_init_s)))

               ; force resp's x to be a ciphertext: debug issue with knowledge?
               (in (join or_init or_init_a) Ciphertext)
               
               ]
      #:bounds [(is next linear)]
      #:scope [(KeyPairs 1 1)
               ;(Timeslot 8 8) ; recv + send (recall attacker is medium)
               (Timeslot 6 6) ; min for first 3 steps s/b 6
               (Timeslot 4 4) ; min for first 3 steps s/b 6
               ; problem in knowledge -- require server to send a bunch first?
               
               (mesg 24) ; 9 + 4 + 3 + 5
                  ; + 2 akey + 1 skey
               (Key 12 12)
               (akey 8 8)               
               (PrivateKey 4 4)
               (PublicKey 4 4)  ; try increase 3->4
               (skey 4 4) ; ltkas ltkbs k (non attack)
               
               (name 4 4) ; attacker plus server, init, resp's agents
               (Attacker 1 1)
               
               (text 3 3) ; na, nb, m
               
               (Ciphertext 5 5)               
               
               (AttackerStrand 1 1)                              
               (or_init 1 1)
               (or_resp 1 1)
               (or_serv 1 1)               
               
               (skeleton_or_0 1 1)              
               (Int 5 5) 
               ]
    ;  #:expect sat
      )

(display OR_SAT_diffab)

; vacuity check #2: frame for the attack, with 2 server strands
; Should be satisfied by, e.g., a run of the protocol (8 timeslots)
;   followed by a replay to the 2nd server strand (+2 timeslots for send/recv)
#;(test OR_SAT_2
      #:preds [
               exec_or_init
               exec_or_resp
               exec_or_serv
               constrain_skeleton_or_0               
               temporary
               wellformed

               ; initiator's a and b differ (prevent annoying examples)
               (not (= (join or_init or_init_a)
                       (join or_init or_init_b)))
               
               ]
      #:bounds [(is next linear)]
      #:scope [(KeyPairs 1 1)
               
               (Timeslot 10 10) ; recv + send (recall attacker is medium)
               
               (mesg 21) ; 9 + 4 + 3 + 5
               
               (Key 9 9)
               (akey 6 6)               
               (PrivateKey 3 3) ; guess: needs incr to allow a!=b from init pov
               (PublicKey 3 3)  ; attacker, init and resp and server...
               (skey 3 3)       ; could also be the LTK requirement?
                 ; [do we require ltk to exist? that wouldnt be unsat alone though]
               
               (name 4 4) ; attacker plus server, init, resp's agents
               (Attacker 1 1)
               
               (text 3 3) ; includes data
               
               (Ciphertext 5 5)               
               
               (AttackerStrand 1 1)                              
               (or_init 1 1)
               (or_resp 1 1)
               (or_serv 2 2)               
               
               (skeleton_or_0 1 1)              
               (Int 5 5) 
               ]
      #:expect sat
      )



;;;;;;; OR: can participants be fooled into having different keys?
; Requires 1 extra server strand (since 2 runs from server perspective)
; Requires extra timeslots. Specifically:
;   6 to perform the first 3 steps
;   +1 for B to reply to A but not be forwarded
;   +2 for attacker to reply to 2nd server strand (send, recv)
;   +1 for attacker to mock a reply to A as if from B

#;(run OR_attack
      #:preds [
               exec_or_init
               exec_or_resp
               exec_or_serv
               constrain_skeleton_or_0               
               temporary
               wellformed

               ; k for init and resp are different
               ; this notation requires unique init and resp strands
               ; sanity check: DEBUG
           ;    (not (= (join or_init or_init_k)
           ;            (join or_resp or_resp_k)))
               
               ; This is a modeling annoyance -- Attacker is an agent, so may have keys
               ; The attacker has no long-term keys
;               (no (+ (join Attacker (join name (join KeyPairs ltks)))
;                      (join name (join Attacker (join KeyPairs ltks)))))

               ; initiator's a and b differ (prevent annoying examples)
               (not (= (join or_init or_init_a)
                       (join or_init or_init_b)))
               
               ]
      #:bounds [(is next linear)]
      #:scope [(KeyPairs 1 1)
               (Timeslot 10 10) ; see above re: attack shape
               
               ;(mesg 21) ; 9 + 4 + 3 + 5
               (mesg 23) ; +1 for the new key, +2 for new ciphertext
               
               (Key 10 10)
               (akey 6 6)               
               (PrivateKey 3 3)
               (PublicKey 3 3)
               (skey 4 4)
               
               (name 4 4) ; attacker plus server, init, resp's agents
               (Attacker 1 1)
               
               (text 3 3) ; includes data
               
               (Ciphertext 7 7)               
               
               (AttackerStrand 1 1)                              
               (or_init 1 1)
               (or_resp 1 1)
               (or_serv 2 2) ; 2 server strands needed for this attack 
               
               (skeleton_or_0 1 1)              
               ;(Int 5 5)
               (Int 6 6) 
               ]
;      #:expect sat
      )

;(printf "~a~n" exec_or_serv)

;(display OR_attack)