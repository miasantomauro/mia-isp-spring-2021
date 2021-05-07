#lang forge/core
(require "../macrosketch.rkt") ; TODO #lang

; Sterling isn't displaying this right
;(set-option! 'skolem_depth 2)
;(set-option! 'verbose 5)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Needham-Schroeder example from CSPA

(defprotocol ns basic
  (defrole init
    (vars (a b name) (n1 n2 text))
    (trace (send (enc n1 a (pubk b)))
           (recv (enc b n1 n2 (pubk a)))
           (send (enc n2 (pubk b)))))
  (defrole resp 
    (vars (a b name) (n1 n2 text))
    (trace (recv (enc n1 a (pubk b)))
           (send (enc b n1 n2 (pubk a)))
           (recv (enc n2 (pubk b))))))

(defskeleton ns
  (vars (a b name) (n1 text))
  (defstrand init 3 (a a) (b b) (n1 n1)) 
  (non-orig (privk b) (privk a))
  (uniq-orig n1)
  (comment "Initiator point-of-view"))

(defskeleton ns
  (vars (a b name) (n2 text))
  (defstrand resp 3 (a a) (b b) (n2 n2))
  (non-orig (privk a) (privk b))
  (uniq-orig n2)
  (comment "Responder point-of-view"))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;



; Confirm
;(hash-keys (forge:State-sigs forge:curr-state))
;(hash-keys (forge:State-relations forge:curr-state))
(hash-keys (forge:State-pred-map forge:curr-state))
;(relation-typelist ns_init_a)
;(relation-typelist skeleton_ns_0_n1)


 ;some t1, t2: text | {
 ;     t1 in (Attacker.learned_times).Timeslot
 ;     t2 in (Attacker.learned_times).Timeslot
 ;     t1 not in (Attacker.generated_times).Timeslot
 ;     t2 not in (Attacker.generated_times).Timeslot
 ; }

; The attacker learns the initiator's n1 and n2
; but the attacker generated neither
(pred attack_exists
      (in (+ (join ns_init ns_init_n1)
             (join ns_init ns_init_n2))
          (join Attacker learned_times Timeslot))
      
      (! (in (join ns_init ns_init_n1)             
             (join Attacker generated_times Timeslot)))
      (! (in (join ns_init ns_init_n2)             
             (join Attacker generated_times Timeslot)))
      ; Stopgap: initiator believes they are a, and responder believes they are b
      (= (join ns_init ns_init_a) ns_init)            
      (= (join ns_resp ns_resp_b) ns_resp)
      
      ; Require the secrets to be different
      (! (= (join ns_init ns_init_n1)
            (join ns_init ns_init_n2))))

(test ns_fixed_SAT
      #:preds [
               exec_ns_init
               exec_ns_resp
               constrain_skeleton_ns_0
               constrain_skeleton_ns_1
               temporary
               wellformed
               ;attack_exists
               ]
      #:bounds [(is next linear)]
      #:scope [(mesg 16)
               (Key 6 6)
               (name 3 3)
               (KeyPairs 1 1)
               (Timeslot 6 6) ; TODO: for opt, consider merge with Message?
               (Message 6 6) ; not "mesg"
               (text 2 2)
               (Ciphertext 5 5)
               (Attacker 1 1)
               (ns_init 1 1)
               (ns_resp 1 1)
               (PrivateKey 3 3)
               (PublicKey 3 3)
               (skey 0 0)
               (skeleton_ns_0 1 1)
               (skeleton_ns_1 1 1)
               ]
      #:expect sat)

(run ns_fixed_exploit_UNSAT
      #:preds [
               exec_ns_init
               exec_ns_resp
               constrain_skeleton_ns_0
               constrain_skeleton_ns_1
               temporary
               wellformed
               attack_exists
               ]
      #:bounds [(is next linear)]
      #:scope [(mesg 16)
               (Key 6 6)
               (name 3 3)
               (KeyPairs 1 1)
               (Timeslot 6 6) ; TODO: for opt, consider merge with Message?
               (Message 6 6) ; not "mesg"
               (text 2 2)
               (Ciphertext 5 5)
               (Attacker 1 1)
               (ns_init 1 1)
               (ns_resp 1 1)
               (PrivateKey 3 3)
               (PublicKey 3 3)
               (skey 0 0)
               (skeleton_ns_0 1 1)
               (skeleton_ns_1 1 1)
               ]
      ;#:expect unsat
      )

(display ns_fixed_exploit_UNSAT)

