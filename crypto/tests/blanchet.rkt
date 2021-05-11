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

(defprotocol blanchet-corrected basic
  (defrole init
    (vars (a b akey) (s skey) (d data))
    (trace
     (send (enc (enc s b (invk a)) b))
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

(defskeleton blanchet-corrected
  (vars (a b akey) (s skey) (d data))
  (defstrand init 2 (a a) (b b) (s s) (d d))
  (deflistener d)
  (non-orig (invk b))
  (comment "From the initiator's perspective, is the secret leaked?"))

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
      #:scope [(mesg 16)
               (Key 6 6)
               (name 3 3)
               (KeyPairs 1 1)
               (Timeslot 6 6) ; TODO: for opt, consider merge with Message?
               (Message 6 6) ; not "mesg"
               (text 2 2)
               (Ciphertext 5 5)
               (AttackerStrand 1 1)
               (Attacker 1 1)
               (blanchet_init 1 1)
               (blanchet_resp 1 1)
               (PrivateKey 3 3)
               (PublicKey 3 3)
               (skey 0 3)
               (strand 3 3)
               (skeleton_blanchet_0 1 1)
               (skeleton_blanchet_1 1 1)
               (skeleton_blanchet_2 1 1)
               (skeleton_blanchet_3 1 1)
               
               ]
      ;#:expect sat
      )

(display blanchet_SAT)