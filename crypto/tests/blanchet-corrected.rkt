#lang forge/core
(require "../macrosketch.rkt")

(defprotocol blanchet-corrected basic
  (defrole init
    (vars (a b akey) (s skey) (d data))  ; b = bob's public key; a = alice's public key
    (trace
     (send (enc (enc s b (invk a)) b))   ; Alice signs (s, b) and then encrypts for Bob
     (recv (enc d s)))                 
    (uniq-orig s))
  (defrole resp
    (vars (a b akey) (s skey) (d data))
    (trace
     (recv (enc (enc s b (invk a)) b))
     (send (enc d s)))
    (uniq-orig d))
  (comment "Corrected Blanchet's protocol"))

(defskeleton blanchet-corrected
  (vars (a b akey) (s skey) (d data))
  (defstrand init 2 (a a) (b b) (s s) (d d))
  (non-orig (invk b))
  (comment "Analyze from the initiator's perspective"))

; The scenario the manual describes shows the *responder*'s value
; being compromised, but not the initiator's. Right now, our model
; will create a constraint for both listeners (conjuctively), yielding
; a spurious unsat result unless the initiator's deflistener is removed.

;(defskeleton blanchet-corrected
;  (vars (a b akey) (s skey) (d data))
;  (defstrand init 2 (a a) (b b) (s s) (d d))
;  (deflistener d)
;  (non-orig (invk b))
;  (comment "From the initiator's perspective, is the secret leaked?"))

(defskeleton blanchet-corrected
  (vars (a b akey) (s skey) (d data))
  (defstrand resp 2 (a a) (b b) (s s) (d d))
  (non-orig (invk a) (invk b))
  (comment "Analyze from the responder's perspective"))

(defskeleton blanchet-corrected
  (vars (a b akey) (s skey) (d data))
  (defstrand resp 2 (a a) (b b) (s s) (d d))
  (deflistener d)
  (non-orig (invk a) (invk b))
  (comment "From the responders's perspective, is the secret leaked?"))


(set-option! 'verbose 2)
(set-option! 'solver 'MiniSatProver)
(set-option! 'logtranslation 1)
(set-option! 'coregranularity 1)
(set-option! 'core_minimization 'rce)
;(set-option! 'skolem_depth 2)
(set-option! 'sb 20000)

#;(test blanchet_corrected_sanity
      #:preds [
               exec_blanchet-corrected_init
               exec_blanchet-corrected_resp
               constrain_skeleton_blanchet-corrected_0
               constrain_skeleton_blanchet-corrected_1
               ; No search for attack
               ;constrain_skeleton_blanchet-corrected_2 ; note this is the fourth skeleton including commented-out               
               temporary
               wellformed

               ; The attacker has no long-term keys
               (no (+ (join Attacker (join name (join KeyPairs ltks)))
                      (join name (join Attacker (join KeyPairs ltks)))))
               ; initiator's a and b are public keys, and not for the attacker               
               ;   - without this we get odd CEs since the model doesn't prevent matching against unopenable encs
               ;   - ideally some of this would be enforced by non-orig anyway
               (in (join blanchet-corrected_init blanchet-corrected_init_a) PublicKey)
               (in (join blanchet-corrected_init blanchet-corrected_init_b) PublicKey)
               (no (& (getInv (join blanchet-corrected_init blanchet-corrected_init_a))
                      (join KeyPairs owners Attacker)))
               ]
      #:bounds [(is next linear)]
      #:scope [(KeyPairs 1 1)
               (Timeslot 4 4) 
               
               (mesg 20) ; 9 + 3 + 3 + 5
               
               (Key 9)
               (akey 6)               
               (PrivateKey 3)
               (PublicKey 3)
               (skey 3)
               
               (name 3)
               (Attacker 1 1)
               
               (text 3) ; includes data
               
               (Ciphertext 5 5)               
               
               (AttackerStrand 1 1)               
               (blanchet-corrected_init 1 1)
               (blanchet-corrected_resp 1 1)               
               (strand 3 3)
               
               (skeleton_blanchet-corrected_0 1 1)
               (skeleton_blanchet-corrected_1 1 1)
               (skeleton_blanchet-corrected_2 1 1)               
               (Int 5)
               ]
      #:expect sat
      )

(run blanchet_corrected
      #:preds [
               exec_blanchet-corrected_init
               exec_blanchet-corrected_resp
               constrain_skeleton_blanchet-corrected_0
               constrain_skeleton_blanchet-corrected_1
               constrain_skeleton_blanchet-corrected_2 ; note this is the fourth skeleton including commented-out               
               temporary
               wellformed

               ; The attacker has no long-term keys
               (no (+ (join Attacker (join name (join KeyPairs ltks)))
                      (join name (join Attacker (join KeyPairs ltks)))))
               ; initiator's a and b are public keys, and not for the attacker               
               ;   - without this we get odd CEs since the model doesn't prevent matching against unopenable encs
               ;   - ideally some of this would be enforced by non-orig anyway
               (in (join blanchet-corrected_init blanchet-corrected_init_a) PublicKey)
               (in (join blanchet-corrected_init blanchet-corrected_init_b) PublicKey)
               (no (& (getInv (join blanchet-corrected_init blanchet-corrected_init_a))
                      (join KeyPairs owners Attacker)))
               (no (& (getInv (join blanchet-corrected_init blanchet-corrected_init_b))
                      (join KeyPairs owners Attacker)))
               ]
      #:bounds [(is next linear)]
      #:scope [(KeyPairs 1 1)
               (Timeslot 4 4)                
               
               (mesg 20) ; 9 + 3 + 3 + 5
               
               (Key 9)
               (akey 6)               
               (PrivateKey 3)
               (PublicKey 3)
               (skey 3)
               
               (name 3)
               (Attacker 1 1)
               
               (text 3) ; includes data
               
               (Ciphertext 5 5)               
               
               (AttackerStrand 1 1)               
               (blanchet-corrected_init 1 1)
               (blanchet-corrected_resp 1 1)               
               (strand 3 3)
               
               (skeleton_blanchet-corrected_0 1 1)
               (skeleton_blanchet-corrected_1 1 1)
               (skeleton_blanchet-corrected_2 1 1)               
               (Int 5)
               ]
      ;#:expect unsat
      )

(display blanchet_corrected)