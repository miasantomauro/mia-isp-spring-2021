#lang forge/core
(require "../macrosketch.rkt")

(set-option! 'verbose 5)
;(set-option! 'solver 'MiniSatProver)
;(set-option! 'skolem_depth 2)
;(set-option! 'sb 20000)
;(set-option! 'logtranslation 1)
;(set-option! 'coregranularity 1)
;(set-option! 'core_minimization 'hybrid)


(defprotocol or basic
  (defrole init (vars (a b s name) (na text) (k skey) (m text))
    (trace
     (send (cat m a b (enc na m a b (ltk a s))))
     (recv (cat m (enc na k (ltk a s))))
    ))
  (defrole resp
    (vars (a b s name) (nb text) (k skey) (m text) (x y mesg))
    (trace
     (recv (cat m a b x))
     (send (cat m a b x (enc nb m a b (ltk b s))))
     (recv (cat m y (enc nb k (ltk b s))))
     (send y)))
  (defrole serv (vars (a b s name) (na nb text) (k skey) (m text))
    (trace
     (recv (cat m a b (enc na m a b (ltk a s))
		(enc nb m a b (ltk b s))))
     (send (cat m (enc na k (ltk a s)) (enc nb k (ltk b s)))))
    (uniq-orig k)))

(defskeleton or
  (vars (nb text) (s a b name))
  (defstrand resp 4 (a a) (b b) (s s) (nb nb))
  (non-orig (ltk a s) (ltk b s))
  (uniq-orig nb))

;(test OR_SAT
(run OR_SAT
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
;      #:expect sat
      )

;(printf "~a~n" exec_or_serv)

(display OR_SAT)
;(is-sat? OR_SAT)
; This will auto-highlight if settings are correct
; (tree:get-value (forge:Run-result NS_SAT))
;(is-sat? NS_SAT)