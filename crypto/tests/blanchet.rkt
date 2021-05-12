#lang forge/core
(require "../macrosketch.rkt")

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

(defskeleton blanchet
  (vars (a b akey) (s skey) (d data))
  (defstrand init 2 (a a) (b b) (s s) (d d))
  (non-orig (invk b))
  (comment "Analyze from the initiator's perspective"))

(defskeleton blanchet
  (vars (a b akey) (s skey) (d data))
  (defstrand resp 2 (a a) (b b) (s s) (d d))
  (non-orig (invk a) (invk b))
  (comment "Analyze from the responder's perspective"))

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
; 
(run blanchet_SAT
      #:preds [
               exec_blanchet_init
               exec_blanchet_resp
               constrain_skeleton_blanchet_0
               constrain_skeleton_blanchet_1
               constrain_skeleton_blanchet_2
               constrain_skeleton_blanchet_3
               temporary
               wellformed
               ]
      #:bounds [(is next linear)]
      #:scope [(KeyPairs 1 1)
               (Timeslot 6 6) 
               (Message 6 6)
               
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
               (blanchet_init 1 1)
               (blanchet_resp 1 1)               
               (strand 3 3)
               
               (skeleton_blanchet_0 1 1)
               (skeleton_blanchet_1 1 1)
               (skeleton_blanchet_2 1 1)
               (skeleton_blanchet_3 1 1)
               (Int 5)
               ]
      ;#:expect sat
      )

(display blanchet_SAT)