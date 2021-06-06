#lang forge/core
(require "../macrosketch.rkt")

;(herald "The ffgg Protocol"
;(comment "From A Necessarily Parallel Attack by Jon K. Millen"))

(defprotocol ffgg basic
  (defrole init (vars (a b name) (n1 n2 m x y text))
    (trace
     (send a)
     (recv (cat b n1 n2))
     (send (cat a (enc n1 n2 m (pubk b))))
     (recv (cat n1 x (enc x y n1 (pubk b))))))
  (defrole resp (vars (b a name) (n1 n2 x y text))
    (trace
     (recv a)
     (send (cat b n1 n2))
     (recv (cat a (enc n1 x y (pubk b))))
     (send (cat n1 x (enc x y n1 (pubk b)))))
    (uniq-orig n1 n2)))

; From initiator's perspective, the message m is compromised
(defskeleton ffgg
  (vars (b name) (n1 n2 m text))
  (defstrand init 4 (b b) (m m))
  (deflistener m)
  ; Modification: flipped order for macro convenience
  (non-orig (privk b))
  (uniq-orig m)  )

; Semantic difference: uniq-orig yet attacker generates it and originates it?
; if it's in a strand var, you must know it?

(run ffgg_example
      #:preds [
               exec_ffgg_init
               exec_ffgg_resp
               constrain_skeleton_ffgg_0               
               temporary
               wellformed

               ; Enforce different names from init's perspective
               (not (= (join ffgg_init ffgg_init_a)
                       (join ffgg_init ffgg_init_b)))
               ; m is neither nonce from neither perspective
               ; Note the number of disequalities we have to force vs. Razor
               (not (in (join ffgg_init ffgg_init_m)
                        (+ (join ffgg_init ffgg_init_n1) (join ffgg_init ffgg_init_n2))))
               
               (not (in (join ffgg_resp ffgg_resp_x)
                        (+ (join ffgg_resp ffgg_resp_n1)
                           (join ffgg_resp ffgg_resp_n2)
                           (join ffgg_resp ffgg_resp_y))))

               ; Hack to handle unordered nature of messages;
               ; FFGG relies on ordering to disambiguate x and y in responder
               ; If we don't add this, the solver will find a run where responder
               ; (implicitly) flips values and sends m in the clear.
               (= (join ffgg_init ffgg_init_m)
                  (join ffgg_resp ffgg_resp_y))

               ]
      #:bounds [(is next linear)]
      #:scope [(KeyPairs 1 1)
               (Timeslot 14 14) ;  (http://www.csl.sri.com/papers/ffggpaper/ffggpaper.ps)                             
               (mesg 22) ; Key (6) + name (3) + text (6) + Ciphertext (6)
               
               (Key 6 6)
               (akey 6 6)               
               (PrivateKey 3 3)
               (PublicKey 3 3)
               (skey 0 0)
               
               (name 3 3)
               (Attacker 1 1)
               
               (text 6 6)
               
               (Ciphertext 6 6)               
               
               (AttackerStrand 1 1)               
               (ffgg_init 1 1)
               (ffgg_resp 2 2)               
               ;(strand 3 3)
               (strand 4 4) ; make room for 2 responders
               
               (skeleton_ffgg_0 1 1)               
               (Int 5)
               ]
     ; #:expect unsat
      )

(display ffgg_example)