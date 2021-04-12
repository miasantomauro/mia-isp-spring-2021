#lang forge/core

(require (for-syntax racket/syntax))
(require syntax/parse syntax/parse/define)
(require (for-syntax (only-in racket take last flatten)))
;(require racket/syntax)
;(require "current_model.rkt") ; the base crypto modl

; For debugging speed, don't import the full spec yet
(sig Agent)

;(defrole init
;    (vars (a b name) (n1 n2 text))
;    (trace (send (enc n1 a (pubk b)))
;           (recv (enc n1 n2 (pubk a)))
;           (send (enc n2 (pubk b)))))

(begin-for-syntax

  (define-syntax-class defroleClass
    (pattern ((~literal defrole)
              rname:id
              vars:varsClass
              trace:traceClass)             
             #:attr vardecls #'(vars.decls ...)
             ))
  
;  (vars (a b name) (n1 n2 text))
  (define-syntax-class varsClass
    (pattern ((~literal vars)
              decls:varsGrouping ...)))
  (define-syntax-class varsGrouping
    (pattern (var-or-type:id ...)))
  
;    (trace (send (enc n1 a (pubk b)))
;           (recv (enc n1 n2 (pubk a)))
;           (send (enc n2 (pubk b)))))
  (define-syntax-class traceClass
    (pattern ((~literal trace)
              events:eventClass ...)))
  
  (define-syntax-class eventClass
    (pattern ((~literal send) enc:encClass))
    (pattern ((~literal recv) enc:encClass)))
  (define-syntax-class encClass
    (pattern ((~literal enc)
              vals:id ...
              ((~literal pubk)
               pubkeyowner))))
    
) ; end begin-for-syntax

(define-syntax (roleforge stx)
  ;(printf "roleforge: ~a~n" stx)
  (syntax-parse stx
    [(roleforge pname:id role:defroleClass)     
     #`(begin
         (sig #,(format-id #'pname "~a_~a" #'pname #'role.rname) #:extends Agent) ; declare sig
         #,@(flatten
             (for/list ([decls (syntax->list #'role.vardecls)]) ; for each variable grouping                      
               (let ([type (last (syntax->list decls))])      ; last element is the type
                 (for/list ([varid (take (syntax->list decls) (- (length (syntax->list decls)) 1))]) ; for each var decl                          
                   #`(relation
                      #,(format-id #'role.rname "~a_~a_~a" #'pname #'role.rname varid)
                      (role.rname #,type))))))
         (pred #,(format-id #'pname "exec_~a_~a" #'pname #'role.rname) true))]))

(define-syntax (defprotocol stx)
  (syntax-parse stx [(defprotocol pname:id ptype:id roles:defroleClass ...)
                     (quasisyntax/loc stx
                       (begin (roleforge pname roles) ...))]))

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

(hash-keys (forge:State-sigs forge:curr-state))
(hash-keys (forge:State-relations forge:curr-state))
(hash-keys (forge:State-pred-map forge:curr-state))
