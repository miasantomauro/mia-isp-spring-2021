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
 (vars (b name) (n1 text))
 (defstrand init 2 (b b) (n1 n1))
 (non-orig (privk b)) (uniq-orig n1)) 

(defskeleton ns
 (vars (a name) (n2 text))
 (defstrand resp 2 (a a) (n2 n2))
(non-orig (privk a)) (uniq-orig n2))