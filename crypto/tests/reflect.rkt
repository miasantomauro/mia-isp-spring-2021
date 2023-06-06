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


(test reflect_SAT
      #:preds [
               exec_reflect_init
               exec_reflect_resp               
               constrain_skeleton_reflect_0
               constrain_skeleton_reflect_1
               constrain_skeleton_reflect_2               
               temporary
               wellformed

               ; Enforce different principals
               (not (= (join reflect_resp agent)
                       (join reflect_init agent)))
               ]
      #:bounds [(is next linear)]
      #:scope [(KeyPairs 1 1)
               (Timeslot 4 4) ; 4 steps for reflection attack               
               
               (mesg 13) ; 9 + 3 + 0 + 4
               
               (Key 6 6)
               (akey 6 6)               
               (PrivateKey 3 3)
               (PublicKey 3 3)
               (skey 0)
               
               (name 3 3)
               (Attacker 1 1)
               
               (text 0) ; includes data
               
               (Ciphertext 4 4)               
               
               (AttackerStrand 1 1)                              
               (reflect_init 1 1)
               (reflect_resp 1 1)               
               
               (skeleton_reflect_0 1 1)
               (skeleton_reflect_1 1 1)
               (skeleton_reflect_2 1 1) 
               (Int 5 5) 
               ]
      #:expect sat
      )


(run reflect_resp_pov
      #:preds [
               exec_reflect_init
               exec_reflect_resp               
               ;constrain_skeleton_reflect_0
               ;constrain_skeleton_reflect_1
               constrain_skeleton_reflect_2 ; responder POV strand
               temporary
               wellformed

               ; Enforce different principals
               (not (= (join reflect_resp agent)
                       (join reflect_init agent)))
               ; Enforce b and a are not from the same pair
               (not (= (join reflect_resp reflect_resp_a)
                       (getInv (join reflect_resp reflect_resp_b))))               
               (not (= (join reflect_resp reflect_resp_a)
                       (join reflect_resp reflect_resp_b)))
               ]
      #:bounds [(is next linear)]
      #:scope [(KeyPairs 1 1)
               (Timeslot 4 4) ; 4 steps for reflection attack               
               
               (mesg 13) ; 9 + 3 + 0 + 4
               
               (Key 6 6)
               (akey 6 6)               
               (PrivateKey 3 3)
               (PublicKey 3 3)
               (skey 0)
               
               (name 3 3)
               (Attacker 1 1)
               
               (text 0) ; includes data
               
               (Ciphertext 4 4)               
               
               (AttackerStrand 1 1)                              
               (reflect_init 1 1)
               (reflect_resp 1 1)               
               
               (skeleton_reflect_0 1 1)
               (skeleton_reflect_1 1 1)
               (skeleton_reflect_2 1 1)              
               (Int 5 5) 
               ]      
      )



(display reflect_resp_pov)
