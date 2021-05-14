#lang forge/core
(require "../macrosketch.rkt") ; TODO #lang

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

(defskeleton ns
  (vars (a b name) (n1 text))
  (defstrand init 3 (a a) (b b) (n1 n1)) 
  (non-orig (privk b) (privk a))
  (uniq-orig n1)
  (comment "Initiator point-of-view"))

(defskeleton ns
  (vars (a b name) (n2 text))
  (defstrand resp 3 (a a) (b b) (n2 n2))
  (non-orig (privk a) (privk b))
  (uniq-orig n2)
  (comment "Responder point-of-view"))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;



; Confirm
;(hash-keys (forge:State-sigs forge:curr-state))
;(hash-keys (forge:State-relations forge:curr-state))
;(hash-keys (forge:State-pred-map forge:curr-state))
;(relation-typelist ns_init_a)
;(relation-typelist skeleton_ns_0_n1)


(set-option! 'verbose 5)
(set-option! 'solver 'MiniSatProver)
(set-option! 'logtranslation 2)
(set-option! 'coregranularity 2)
(set-option! 'core_minimization 'rce)

(pred attack_exists
      (in (+ (join ns_init ns_init_n1)
             (join ns_init ns_init_n2))
           (join Attacker learned_times Timeslot)))

; Proxy for concrete attack, used to debug and sanity check:
; some message is sent encrypted with the attacker's public key
(pred proxy_shape
      (some ((m Message)) (in (getInv (join (join m data) encryptionKey))
                              (join KeyPairs owners Attacker ))))              ; unsat
                              ; (join KeyPairs owners (join ns_init agent) )))) ; sat

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
               (Timeslot 6 6) ; TODO: for opt, consider merge with Message?
               (Message 6 6) ; not "mesg"
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
               (skeleton_ns_0 1 1)
               (skeleton_ns_1 1 1)
               ] 
      #:expect sat
      )

(run NS_SAT
      #:preds [
               exec_ns_init
               exec_ns_resp
               constrain_skeleton_ns_0
               constrain_skeleton_ns_1
               temporary
               wellformed
               
              ; (! attack_exists)
               attack_exists
               ;proxy_shape
               success
               attack_frame
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
               (ns_init 1 1)
               (ns_resp 1 1)
               (PrivateKey 3 3)
               (PublicKey 3 3)
               (skey 0 0)
               (akey 6 6)
               (strand 3 3)
               (skeleton_ns_0 1 1)
               (skeleton_ns_1 1 1)
               ] 
      ;#:expect sat
      )

(display NS_SAT)
; This will auto-highlight if settings are correct
; (tree:get-value (forge:Run-result NS_SAT))
;(is-sat? NS_SAT)