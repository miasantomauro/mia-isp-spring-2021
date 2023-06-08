#lang forge/domains/crypto

;(herald "Blanchet's Simple Example Protocol"
;  (comment "There is a flaw in this protocol by design"))

(defprotocol blanchet basic
  (defrole init
    (vars (a b akey) (s skey) (d data))
    (trace
     (send (enc (enc s (invk a)) b))
     (recv (enc d s)))
    (uniq-orig s))
  (defrole resp
    (vars (a b akey) (s skey) (d data))
    (trace
     (recv (enc (enc s (invk a)) b))
     (send (enc d s)))
    (uniq-orig d))
  (comment "Blanchet's protocol"))

; Note well:
; The scenario the manual describes shows the *responder*'s value
; being compromised, but not the initiator's. Our model will create
; predicates for each skeleton, so be certain to invoke only ONE.

;  To do so, don't remove the skeleton, just prevent its constraint from taking effect.
(defskeleton blanchet
  (vars (a b akey) (s skey) (d data))
  (defstrand init 2 (a a) (b b) (s s) (d d))
  (deflistener d)
  (non-orig (invk b))
  (comment "From the initiator's perspective, is the secret leaked?"))

(defskeleton blanchet
  (vars (a b akey) (s skey) (d data))
  (defstrand resp 2 (a a) (b b) (s s) (d d))
  (deflistener d)
  (non-orig (invk a) (invk b))
  (comment "From the responders's perspective, is the secret leaked?"))

; Bounds can be quite troublesome. Count carefully.

(test blanchet_SAT
      #:preds [
               exec_blanchet_init
               exec_blanchet_resp
               temporary
               wellformed

               ; initiator's a and b are public keys
               ;   - without this we get odd CEs since the model doesn't prevent matching against unopenable encs
               ;   - ideally some of this would be enforced by non-orig anyway
               (in (join blanchet_init blanchet_init_a) PublicKey)
               (in (join blanchet_init blanchet_init_b) PublicKey)               
               
               ]
      #:bounds [(is next linear)]
      #:scope [(KeyPairs 1 1)
               (Timeslot 4 4)                               
               (mesg 20) ; 9 + 3 + 3 + 5
               
               (Key 8 8)
               (akey 6 6)               
               (PrivateKey 3 3)
               (PublicKey 3 3)
               (skey 2 2)
               
               (name 3 3)
               (Attacker 1 1)
               
               (text 2 2) 
               
               (Ciphertext 5 5)               
               
               (AttackerStrand 1 1)               
               (blanchet_init 1 1)
               (blanchet_resp 1 1)               
               (strand 3 3)
               
               (skeleton_blanchet_0 1 1)
               (skeleton_blanchet_1 1 1)                           
               (Int 5)
               ]
      #:expect sat
      )

; Initiator's perspective doesn't see an attack.
(test blanchet_attack_initiator
      #:preds [
               exec_blanchet_init
               exec_blanchet_resp
               constrain_skeleton_blanchet_0 ; initiator's POV
               temporary
               wellformed

               ; initiator's a and b are public keys
               ;   - without this we get odd CEs since the model doesn't prevent matching against unopenable encs
               ;   - ideally some of this would be enforced by non-orig anyway
               (in (join blanchet_init blanchet_init_a) PublicKey)
               (in (join blanchet_init blanchet_init_b) PublicKey)               
               
               ]
      #:bounds [(is next linear)]
      #:scope [(KeyPairs 1 1)
               (Timeslot 4 4)                               
               (mesg 20) ; 9 + 3 + 3 + 5
               
               (Key 8 8)
               (akey 6 6)               
               (PrivateKey 3 3)
               (PublicKey 3 3)
               (skey 2 2) ; allow extra to see compromise
               
               (name 3 3)
               (Attacker 1 1)
               
               (text 2 2) ; allow extra to see compromise
               
               (Ciphertext 5 5)               
               
               (AttackerStrand 1 1)               
               (blanchet_init 1 1)
               (blanchet_resp 1 1)               
               (strand 3 3)
               
               (skeleton_blanchet_0 1 1)
               (skeleton_blanchet_1 1 1)                           
               (Int 5)
               ]
      #:expect unsat
      )

; Responder's perspective does see an attack.
(run blanchet_attack_responder
      #:preds [
               exec_blanchet_init
               exec_blanchet_resp
               constrain_skeleton_blanchet_1 ; responder's POV
               temporary
               wellformed

               ; initiator's a and b are public keys
               ;   - without this we get odd CEs since the model doesn't prevent matching against unopenable encs
               ;   - ideally some of this would be enforced by non-orig anyway
               (in (join blanchet_init blanchet_init_a) PublicKey)
               (in (join blanchet_init blanchet_init_b) PublicKey)               
               
               ; FOR DISPLAY ONLY: dont send a LTK as d or s
               ; KeyPairs.ltks: name x name x skey, hence the join pattern
              (! (in (join blanchet_init blanchet_init_d)
                       (join name (join name (join KeyPairs ltks)))))
              (! (in (join blanchet_init blanchet_init_s)
                       (join name (join name (join KeyPairs ltks)))))
               
               ; to get an example for SHARED, remove the above LTK restriction
               ; and comment out the " assume long-term keys are fresh" in base.rkt
               ; plus:
               
               ;(
;; TODO

               ]
      #:bounds [(is next linear)]
      #:scope [(KeyPairs 1 1)
               (Timeslot 4 4)                               
               (mesg 20) ; 9 + 3 + 3 + 5
               
               (Key 8 8)
               (akey 6 6)               
               (PrivateKey 3 3)
               (PublicKey 3 3)
               (skey 2 2) ; allow extra to see compromise
               
               (name 3 3)
               (Attacker 1 1)
               
               (text 2 2) ; allow extra to see compromise
               
               (Ciphertext 5 5)               
               
               (AttackerStrand 1 1)               
               (blanchet_init 1 1)
               (blanchet_resp 1 1)               
               (strand 3 3)
               
               (skeleton_blanchet_0 1 1)
               (skeleton_blanchet_1 1 1)
               (Int 5)
               ]
     ; #:expect sat
      )


(display blanchet_attack_responder)

#;(run blanchet_attack_longer_init
      #:preds [
               exec_blanchet_init
               exec_blanchet_resp
               constrain_skeleton_blanchet_0 ; initiator's POV
               ;constrain_skeleton_blanchet_1
               temporary
               wellformed

               ; initiator's a and b are public keys
               ;   - without this we get odd CEs since the model doesn't prevent matching against unopenable encs
               ;   - ideally some of this would be enforced by non-orig anyway
               (in (join blanchet_init blanchet_init_a) PublicKey)
               (in (join blanchet_init blanchet_init_b) PublicKey)               

               ; Constraints allow for the addition of junk messages to
               ; allow exact bounds at all times. However, this leads to
               ; spurious CEs where uniq-orig values can be revealed in the clear
               ; or encrypted with a key the attacker knows, out of scope of the
               ; protocol itself
               ; This isn't strong enough:
               ;(not (in (join blanchet_init blanchet_init_s)
               ;         (join Timeslot data)))
               ; Instead, allow 1--2 strands of each type, and count:
               (all ([s blanchet_init]) (lone (join receiver s)))
               (all ([r blanchet_resp]) (lone (join receiver r)))
               (all ([s blanchet_init]) (lone (join sender s)))
               (all ([r blanchet_resp]) (lone (join sender r)))               
               ]
      #:bounds [(is next linear)]
      #:scope [(KeyPairs 1 1)
               (Timeslot 4 8)                               
               (mesg 22) ; 9 + 3 + 3 + 5
               
               (Key 9 9)
               (akey 6 6)               
               (PrivateKey 3 3)
               (PublicKey 3 3)
               (skey 3 3)
               
               (name 3 3)
               (Attacker 1 1)
               
               (text 3 3)
               
               (Ciphertext 5 5)               
               
               (AttackerStrand 1 1)               
               (blanchet_init 1 2)
               (blanchet_resp 1 2)               
               (strand 2 4)
               
               (skeleton_blanchet_0 1 1)
               (skeleton_blanchet_1 1 1)                           
               (Int 5)
               ]
;      #:expect unsat
      )
#;(display blanchet_attack_longer_init)


;(set-option! 'verbose 5)
;(set-option! 'solver 'MiniSatProver)
;;(set-option! 'skolem_depth 2)
;;(set-option! 'sb 20000)
;(set-option! 'logtranslation 1)
;(set-option! 'coregranularity 1)
;;(set-option! 'core_minimization 'hybrid)
;(set-option! 'core_minimization 'rce)

#;(test blanchet_attack_longer_validation
      #:preds [
               exec_blanchet_init
               exec_blanchet_resp
               ;constrain_skeleton_blanchet_0 
               ;constrain_skeleton_blanchet_1 
               temporary
               wellformed

               ; initiator's a and b are public keys
               ;   - without this we get odd CEs since the model doesn't prevent matching against unopenable encs
               ;   - ideally some of this would be enforced by non-orig anyway
               (in (join blanchet_init blanchet_init_a) PublicKey)
               (in (join blanchet_init blanchet_init_b) PublicKey)               

               ; Constraints allow for the addition of junk messages to
               ; allow exact bounds at all times. However, this leads to
               ; spurious CEs where uniq-orig values can be revealed in the clear
               ; or encrypted with a key the attacker knows, out of scope of the
               ; protocol itself
               ; This isn't strong enough:
               ;(not (in (join blanchet_init blanchet_init_s)
               ;         (join Timeslot data)))
               ; Instead, allow 1--2 strands of each type, and count:
               (all ([s blanchet_init]) (lone (join receiver s)))
               (all ([r blanchet_resp]) (lone (join receiver r)))
               (all ([s blanchet_init]) (lone (join sender s)))
               (all ([r blanchet_resp]) (lone (join sender r)))               
               ]
      #:bounds [(is next linear)]
      #:scope [(KeyPairs 1 1)
               (Timeslot 8 8)                               
               (mesg 22) ; 9 + 3 + 3 + 5
               
               (Key 9 9)
               (akey 6 6)               
               (PrivateKey 3 3)
               (PublicKey 3 3)
               (skey 3 3)
               
               (name 3 3)
               (Attacker 1 1)
               
               (text 3 3)
               
               (Ciphertext 5 5)               
               
               (AttackerStrand 1 1)               
               (blanchet_init 1 2)
               (blanchet_resp 1 2)               
               (strand 2 4)
               
               (skeleton_blanchet_0 1 1)
               (skeleton_blanchet_1 1 1)                           
               (Int 5)
               ]
      #:expect sat
      )



;(display blanchet_attack_longer_init)

;(display blanchet_attack_initiator)
;(display blanchet_attack_responder)