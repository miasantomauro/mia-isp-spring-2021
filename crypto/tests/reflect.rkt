#lang forge/core
(require "../macrosketch.rkt")

;(herald reflect)

;; A simple protocol vulnerable to a reflection attack

(defprotocol reflect basic
  (defrole init
    (vars (a b akey))
    (trace
     (send (enc b (invk a)))
     (recv (enc a (invk b)))))
  (defrole resp
    (vars (a b akey))
    (trace
     (recv (enc b (invk a)))
     (send (enc a (invk b))))))

;; Expect two shapes

(defskeleton reflect
  (vars (a b akey))
  (defstrand resp 1 (a a) (b b))
  (non-orig (invk a) (invk b)))

(defskeleton reflect
  (vars (a b akey))
  (defstrand init 2 (a a) (b b))
  (non-orig (invk a) (invk b)))

(defskeleton reflect
  (vars (a b akey))
  (defstrand resp 1 (a a) (b (invk b)))
  (non-orig (invk a) b))



(run reflect_SAT
      #:preds [
               exec_reflect_init
               exec_reflect_resp               
               constrain_skeleton_reflect_0
               constrain_skeleton_reflect_1
               constrain_skeleton_reflect_2               
               temporary
               wellformed               
               ]
      #:bounds [(is next linear)]
      #:scope [(KeyPairs 1 1)
               (Timeslot 9 9) ; should only need 8; testing unused timeslots
               (Message 9 9)
               
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
               (reflect_init 1 1)
               (reflect_resp 1 1)               
               
               (skeleton_reflect_0 1 1)
               (skeleton_reflect_1 1 1)
               (skeleton_reflect_2 1 1)              
               (Int 5 5) 
               ]
      ;#:expect sat
      )


(display reflect_SAT)
