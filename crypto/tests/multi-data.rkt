#lang forge/core
(require "../macrosketch.rkt")

; Test case where multiple values are sent in a message

(defprotocol multi basic
  (defrole init
    (vars (x y text) (a b name))
    (trace
     (send x (enc y (pubk b)))
     (recv y (enc x (pubk a)))))
  (defrole resp
    (vars (x y text) (a b name))
    (trace
     (recv x (enc y (pubk a)))
     (send y (enc x (pubk b))))))

(defskeleton multi
  (vars (a b name))
  (defstrand init 1 (a a) (b b))  
  (non-orig (privk a) (privk b)))


(run example_multi
      #:preds [
               exec_multi_init
               exec_multi_resp               
               constrain_skeleton_multi_0
               temporary
               wellformed               
               ]
      #:bounds [(is next linear)]
      #:scope [(KeyPairs 1 1)
               (Timeslot 4 4) ; 4 steps for reflection attack
               (Message 4 4)
               
               (mesg 13) ; 6 keys + 3 names + 2 texts + 2 ciphertexts
               
               (Key 6)
               (akey 6)               
               (PrivateKey 3)
               (PublicKey 3)
               (skey 0)
               
               (name 3)
               (Attacker 1 1)
               
               (text 2) ; includes data
               
               (Ciphertext 2 2)               
               
               (AttackerStrand 1 1)                              
               (multi_init 1 1)
               (multi_resp 1 1)               
               
               (skeleton_multi_0 1 1)
               (Int 5 5) 
               ]
      ;#:expect sat
      )


(display example_multi)
