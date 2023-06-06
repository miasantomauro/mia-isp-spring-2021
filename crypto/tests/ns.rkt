#lang forge/core
(require "../translation.rkt") ; TODO #lang

; Sterling isn't displaying this right
;(set-option! 'skolem_depth 2)
;(set-option! 'verbose 5)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Needham-Schroeder example from CSPA

(defprotocol ns basic
  (defrole init
    (vars (a b name) (n1 n2 text))
    (trace (send (enc n1 a (pubk b)))
           (recv (enc n1 n2 (pubk a)))
           (send (enc n2 (pubk b)))))
  (defrole resp 
    (vars (a b name) (n1 n2 text))
    (trace (recv (enc n1 a (pubk b)))
           (send (enc n1 n2 (pubk a)))
           (recv (enc n2 (pubk b))))))

; Similarly to Blanchet, the problem is from the responder's POV:
; there is a confusion of identity. Both (responder vals for) a and b's
; keys are secret: neither is the MitM. but the responder believes that
; they are b, and the initiator has a different name for b; perhaps
; someone's identity is compromised.

; Note, vitally, this quote from the CPSA manual:
; "Below this is a list of trees, each of which represents the analysis
;  of one of the input defskeletons; in the case of our example, there are two trees."
; Unfortunately, our tool doesn't break the analysis out separately per skeleton.
; Thus, we need to invoke a single skeleton individually in each query

; SKELETON 0
(defskeleton ns
  (vars (a b name) (n1 text))
  (defstrand init 3 (a a) (b b) (n1 n1)) 
  (non-orig (privk b) (privk a))
  (uniq-orig n1)
  (comment "Initiator point-of-view"))

; SKELETON 1
(defskeleton ns
  (vars (a b name) (n2 text))
  (defstrand resp 3 (a a) (b b) (n2 n2))
  (non-orig (privk a) (privk b))
  (uniq-orig n2)
  (comment "Responder point-of-view"))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;



; Debugging: Confirm
;(hash-keys (forge:State-sigs forge:curr-state))
;(hash-keys (forge:State-relations forge:curr-state))
;(hash-keys (forge:State-pred-map forge:curr-state))
;(relation-typelist ns_init_a)
;(relation-typelist skeleton_ns_0_n1)


(pred attack_exists
      (in (+ (join ns_init ns_init_n1)
             (join ns_init ns_init_n2))
           (join Attacker learned_times Timeslot)))

(pred success      
      (in (+ (join ns_init ns_init_n1)
             (join ns_init ns_init_n2))
          (& (join (join ns_init agent) learned_times Timeslot)
             (join (join ns_resp agent) learned_times Timeslot))))

(pred attack_frame      
      (! (in (join ns_init ns_init_n1)             
             (join Attacker generated_times Timeslot)))
      (! (in (join ns_init ns_init_n2)             
             (join Attacker generated_times Timeslot)))

      ; Initiator believes they are a, and responder believes they are b
      ; (Note: cannot add restriction on identity of counterpart, or attack won't be produced!)
      (= (join ns_init ns_init_a) (join ns_init agent))
      (= (join ns_resp ns_resp_b) (join ns_resp agent))
      
      ; Require the secrets to be different
      (! (= (join ns_init ns_init_n1)
            (join ns_init ns_init_n2))))


(test NS_sanity
      #:preds [
               exec_ns_init
               exec_ns_resp
               constrain_skeleton_ns_0
               constrain_skeleton_ns_1
               temporary
               wellformed
                                           
               success
               attack_frame
               ]
      #:bounds [(is next linear)]
      #:scope [(mesg 16) ; 6 + 3 + 2 + 5
               (Key 6 6)
               (name 3 3)
               (KeyPairs 1 1)
               (Timeslot 6 6)
               (text 2 2)
               (Ciphertext 5 5)
               (AttackerStrand 1 1)
               (Attacker 1 1)
               (ns_init 1 1)
               (ns_resp 1 1)
               (PrivateKey 3 3)
               (PublicKey 3 3)
               (skey 0 0)
               (akey 6 6)
               (strand 3 3)
               (skeleton_ns_0 1)
               (skeleton_ns_1 1)
               ] 
      #:expect sat
      )

(test NS_attack_initiator
      #:preds [
               exec_ns_init
               exec_ns_resp
               constrain_skeleton_ns_0 ; INITIATOR POV
               temporary
               wellformed

               attack_exists
               success
               attack_frame
               ]
      #:bounds [(is next linear)]
      #:scope [(mesg 16)
               (Key 6 6)
               (name 3 3)
               (KeyPairs 1 1)
               (Timeslot 6 6)
               (text 2 2)
               (Ciphertext 5 5)
               (AttackerStrand 1 1)
               (Attacker 1 1)
               (ns_init 1 1)
               (ns_resp 1 1)
               (PrivateKey 3 3)
               (PublicKey 3 3)
               (skey 0 0)
               (akey 6 6)
               (strand 3 3)
               ; Skeletons must /exist/, but don't need to be constrained
               (skeleton_ns_0 1 1)
               (skeleton_ns_1 1 1)
               ] 
      #:expect unsat
      )

; Change the test to a run in order to view the result
(test NS_attack_responder
;(run NS_attack_responder
      #:preds [
               exec_ns_init
               exec_ns_resp
               constrain_skeleton_ns_1 ; RESPONDER POV
               temporary
               wellformed

               attack_exists
               success
               attack_frame
               ]
      #:bounds [(is next linear)]
      #:scope [(mesg 16)
               (Key 6 6)
               (name 3 3)
               (KeyPairs 1 1)
               (Timeslot 6 6)
               (text 2 2)
               (Ciphertext 5 5)
               (AttackerStrand 1 1)
               (Attacker 1 1)
               (ns_init 1 1)
               (ns_resp 1 1)
               (PrivateKey 3 3)
               (PublicKey 3 3)
               (skey 0 0)
               (akey 6 6)
               (strand 3 3)
               ; Skeletons must /exist/, but don't need to be constrained
               (skeleton_ns_0 1 1)
               (skeleton_ns_1 1 1)
               ] 
      ; Comment this expectation out if converting this test to a run
      #:expect sat
      )

(display NS_attack_responder)
