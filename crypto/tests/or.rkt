#lang forge/core
(require "../macrosketch.rkt")

(set-option! 'verbose 5)
;(set-option! 'solver 'MiniSatProver)
(set-option! 'solver 'MiniSatProver)
;(set-option! 'skolem_depth 2)
(set-option! 'sb 20000)
(set-option! 'logtranslation 1)
(set-option! 'coregranularity 1)
(set-option! 'core_minimization 'rce)


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
      #:scope [(mesg 0 21) ; (9 Key (??) + 4 name + 5 cipher + 3 text) -- except *21* in bound?
               (Key 0 9)
               (name 0 4)
               (KeyPairs 1 1)
               
               ;(Timeslot 0 6) ; DEBUGGING TEST
               ;(Message 0 6)
               
               (Timeslot 8 8) ; TODO: for opt, consider merge with Message?
               (Message 8 8) ; not "mesg" ; right now we're doubling up
               (text 0 3)
               
               (Ciphertext 0 5)
               (Attacker 1 1)
               (or_init 1 1)
               (or_resp 1 1)
               (or_serv 1 1) ; REPLACE THIS               
               (PrivateKey 4 4) ;; NOTE changed this, was 3. (3 legit strands, 1 attacker)
               (PublicKey 4 4)
               (skey 0 3)               
               (skeleton_or_0 1 1)
              ; (Int 6 6) ; Needed due to upper bound
               ;; -- unsure why needed here but not in NS
               (Int 5 5) ; DO need to be able to count #Keys though
               ]
      ;#:expect sat
      )

;(printf "~a~n" exec_or_serv)

;(display OR_SAT)
(is-sat? OR_SAT)
; This will auto-highlight if settings are correct
; (tree:get-value (forge:Run-result NS_SAT))
;(is-sat? NS_SAT)