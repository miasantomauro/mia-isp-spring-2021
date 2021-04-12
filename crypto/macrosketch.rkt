#lang forge/core

(require (for-syntax racket/syntax))
(require syntax/parse syntax/parse/define)
(require (for-syntax (only-in racket take last flatten)))
;(require racket/syntax)
;(require racket/stxparam)
;(require "current_model.rkt") ; the base crypto modl

;(define-syntax-parameter proto-exec-name #f)
;(define-for-syntax proto-exec-name (make-parameter #f))


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
             #:attr roleforge #`(begin
                                  (sig rname #:extends Agent)
                                 #,@(flatten
                                     (for/list ([d (syntax->list #'(vars.decls ...))])
                                      (let ([type (last (syntax->list d))])
                                        (for/list ([varid (take (syntax->list d) (- (length (syntax->list d)) 1))])
                                            #`(relation
                                               #,(format-id #'rname "~a_~a" #'rname varid)
                                               (rname #,type)))))))))
  
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
    
)

(define-syntax (defprotocol stx)
  (syntax-parse stx [(defprotocol pname:id ptype:id roles:defroleClass ...)
                     (quasisyntax/loc stx
                       (begin roles.roleforge ...))]))

;
;
;(define-syntax (defprotocol stx)
;  (syntax-case stx (basic)
;    [(defprotocol pname basic args ...)                 
;     (parameterize
;         ([proto-exec-name
;           (lambda (rolename)
;               (format-id #'pname "exec_~a_~a" #'pname rolename))])
;       (syntax/loc stx 
;         (begin args ...)))]))
;
;(define-syntax (defrole stx)
;  (syntax-case stx (vars trace)
;    [(defrole rname (vars vdecls ...) (trace msgs ...))
;     ;(proto-exec-name #'rname) ; not bound here
;     (with-syntax ([testpredname (proto-exec-name #'rname)])
;      (quasisyntax/loc stx                           
;          (begin   ; syntax-parameter-value ????
;           (printf "pred is: ~a~n" testpredname)
;           ;(sig rname #:extends Agent)
;           (sig rname)
;           ; (pred (predname args) body) or (pred nullarypredname body)
;           ; no: pred is a macro
;           ;(let ([testpredname (proto-exec-name rname)])
;           ;  (pred testpredname true))
;           
;           ;(pred #,(syntax-local-introduce #'testpredname) true)
;           ;(define testpredname true)
;           ;6
;           ;(pred (proto-exec-name rname) true) ; TODO fill in
;           ;(pred testpredname true) 
;          )))])) 
;
;;           (printf "todo handle var decls: ~a~n" '(vdecls ...))
;           (printf "todo handle traces: ~a~n" '(msgs ...))
;           (printf "defining: ~a~n" 'rname)


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

;#lang racket
;
;(define-syntax (f stx)
;  (syntax-case stx ()
;    [(f x y)
;     #`(begin
;         (define-syntax (#,(datum->syntax stx 'g) stx2)
;           (syntax-case stx2 ()
;             [(g z)
;              #'(println (format "~a ~a" x z))]))
;         y)]))
;
;
;(f 1 (g 2))
;
