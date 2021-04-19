#lang forge/core

; Module to accept CPSA protocol and skeleton definitions and enhance a
; base crypto specification with protocol/skeleton-specific sigs and constraints.
;   Tim and Abby (Spring 2021)

;https://hackage.haskell.org/package/cpsa-3.3.2/src/doc/cpsamanual.pdf
; At the moment, we have prototype support for the "basic" algebra, using only
;   asymmetric keys. 


; Comments from Ben for integration with prototype:
; each role is getting parsed twice (with defroleClass); make roleforge be a function and have defprotocol do more work --- unpacking things from each of the roles
; could kill the flatten with the in-value trick: (for*/list ((decls ....) (type (in-value (last ....))) (varid ....)) ....)
; the take could be drop-right
; for order-independence:
;    use the seq-no-order package https://docs.racket-lang.org/seq-no-order/index.html

(require (for-syntax racket/syntax))
(require syntax/parse syntax/parse/define)
(require (for-syntax (only-in racket take last flatten drop-right first second)))


; For debugging speed, don't import the full spec yet
(sig Agent)
(sig Message)
(sig Timeslot)
(sig Datum)
(sig KeyPairs #:one)
(sig Ciphertext #:extends Datum)
(sig Key #:extends Datum)
(sig PrivateKey #:extends Key)
(sig PublicKey #:extends Key)
(relation sendTime (Message Timeslot))
(relation data (Message Datum))
(relation sender (Message Agent))
(relation receiver (Message Agent))
(relation encryptionKey (Ciphertext Key))
 ;pairs: set PrivateKey -> PublicKey,
 ;owners: set PrivateKey -> Agent
(relation pairs (KeyPairs PrivateKey PublicKey))
(relation owners (KeyPairs PrivateKey Agent))
(relation plaintext (CipherText Datum))

; TODO: swap above with the below, once finalized
;(require "current_model.rkt") ; the base crypto modl

; First, define some syntax classes to ease parsing and improve errors.
; Syntax classes can expose custom attributes, which make them easier to process.
; Since these classes are used by macros, we need to define them for-syntax
;  Note that the AST structs exist at syntax time, because they are used only to generate Forge declarations at syntax time.
(begin-for-syntax

  ;(defrole init
  ;    (vars (a b name) (n1 n2 text))
  ;    (trace (send (enc n1 a (pubk b)))
  ;           (recv (enc n1 n2 (pubk a)))
  ;           (send (enc n2 (pubk b)))))
  (struct ast-role (rname vars trace) #:transparent)
  (define-syntax-class defroleClass
    #:description "Role definition"
    (pattern ((~literal defrole)
              rname:id
              vars:varsClass
              trace:traceClass)                          
             #:attr tostruct (ast-role #'rname (attribute vars.tostruct) (attribute trace.tostruct))
             ))
  
;  (vars (a b name) (n1 n2 text))
  (define-syntax-class varsGrouping
    #:description "Variable declaration"
    (pattern (var-or-type:id ...)))
  (struct ast-vars (assoc-decls) #:transparent)
  (define-syntax-class varsClass
    (pattern ((~literal vars)
              decls:varsGrouping ...)
             #:attr tostruct (ast-vars (apply append
                                              (for/list ([d (syntax->list #'(decls ...))])
                                                (let ([type (last (syntax->list d))])
                                                  (for/list ([v (drop-right (syntax->list d) 1)])                                                    
                                                    (list v type))))))))  
  
;    (trace (send (enc n1 a (pubk b)))
;           (recv (enc n1 n2 (pubk a)))
;           (send (enc n2 (pubk b)))))    
  (struct ast-trace (events) #:transparent)  
  (define-syntax-class traceClass
    #:description "Trace definition"
    (pattern ((~literal trace)
              events:eventClass ...)
             #:attr tostruct (ast-trace (attribute events.tostruct))))

  (struct ast-event (orig type contents) #:transparent)
  (define-syntax-class eventClass
    #:description "Event definition"
    (pattern ((~literal send) enc:encClass)
             #:attr tostruct (ast-event #'this-syntax 'send (attribute enc.tostruct)))
    (pattern ((~literal recv) enc:encClass)
             #:attr tostruct (ast-event #'this-syntax 'recv (attribute enc.tostruct))))
  
  (struct ast-enc (key vals) #:transparent)
  (define-syntax-class encClass
    #:description "encrypted message"
    (pattern ((~literal enc)
              vals:datumClass ...
              key:datumClass)
             #:attr tostruct (ast-enc (attribute key.tostruct) (attribute vals.tostruct))))

  ;  (non-orig (privk a) (privk b))
  (define-syntax-class nonOrigClass
    #:description "non-origination declaration"
    (pattern ((~literal non-orig)
              data:datumClass ...)))
  ;  (uniq-orig n2)
  (define-syntax-class uniqOrigClass
    #:description "unique-origination declaration"
    (pattern ((~literal uniq-orig)
              data:datumClass ...)))
  
  ; n1, a, (pubk a), (privk a)
  (struct ast-datum (wrap value) #:transparent)
  (define-syntax-class datumClass
    #:description "datum definition (an identifier, a public key, or a private key)"
    (pattern ((~literal privk) x:id)
             #:attr tostruct (ast-datum 'privk #'x))
    (pattern ((~literal pubk) x:id)
             #:attr tostruct (ast-datum 'pubk #'x))
    (pattern x:id
             #:attr tostruct (ast-datum #f #'x)))

  ; (a1 a2)
  ; Name is from CPSA docs
  (define-syntax-class mapletClass
    #:description "maplet"
    (pattern (x1:id x2:id)
             #:attr tostruct (list #'x1 #'x2)))

  ; (comment "this is a comment")
  (define-syntax-class commentClass
    #:description "comment"
    (pattern ((~literal comment) comment:string)))
    
  ;  (defstrand resp 3 (a a) (b b) (n2 n2))
  (struct ast-strand (role height maplets) #:transparent)  
  (define-syntax-class strandClass
    #:description "strand definition"
    (pattern ((~literal defstrand)
              strandrole:id
              height:number
              maplets:mapletClass ...)
             #:attr tostruct (ast-strand #'strandrole #'height (attribute maplets.tostruct))))

) ; end begin-for-syntax


; Helper syntax, generated by "defprotocol" to add context
; Produces forge declarations (sigs, relations, predicates...) for a role
(define-syntax (roleforge stx)
  (syntax-parse stx
    [(roleforge pname:id role:defroleClass)
     (let ([rolestruct (attribute role.tostruct)])       
       (with-syntax ([rolesig (format-id #'pname "~a_~a" #'pname #'role.rname)])
         #`(begin
             ; subsig for agents having this role
             (sig rolesig #:extends Agent) ; declare sig
             ; variable fields of that subsig as declared            
             #,@(build-variable-fields (ast-role-vars rolestruct) #'pname (ast-role-rname rolestruct) #'rolesig)
             ; execution predicate for agents having this role
             (pred #,(format-id #'pname "exec_~a_~a" #'pname #'role.rname) #,(build-role-predicate-body #'pname #'role.rname #'rolesig (ast-role-trace rolestruct))))))]))

;(define-for-syntax (build-variable-fields vardecls name1 name2 parent #:prefix [prefix ""])
(define-for-syntax (build-variable-fields vardecls name1 name2 parent #:prefix [prefix ""])  
  (for/list ([decl (ast-vars-assoc-decls vardecls)])
    (with-syntax ([varid (first decl)]
                  [type (second decl)])
      #`(relation
         #,(format-id name1 "~a~a_~a_~a" prefix name1 name2 #'varid)
         (#,parent type)))))

(define-for-syntax (build-event-assertion pname rname rolevar ev msg prev-msg)
  ;(printf "ast-event-contents ev: ~a~n" (ast-event-contents ev))
  ; First, assert temporal ordering on this message variable; msg happens strictly after prev-msg unless no prev-msg
  #`(and #,(if prev-msg
               #`(in (join #,msg sendTime) (join #,prev-msg (^ sendTime)))
               #`true)
         ; one content (TODO: is this safe to assert generally?)
         ;      one m0.data
         (one (join #,msg data))
         ; Then assert event constraints
         ; Sender or receiver
         ;      m0.receiver = resp ; or sender, depending on type of event
         #,(if (equal? (ast-event-type ev) 'send)
               #`(= #,rolevar (join #,msg receiver))
               #`(= #,rolevar (join #,msg sender)))

         #,(cond [(equal? (ast-event-type ev) 'send)
                  #`(= #,rolevar (join #,msg sender))]
                 [(equal? (ast-event-type ev) 'recv)
                  #`(= #,rolevar (join #,msg receiver))]
                 [else (error (format "bad event type: ~a" (ast-event-type ev)))])
         
         ; What's in the message? Order independent
         ; If encrypted vs. non-encrypted

         ; ASSUME: vals are just local variables TODO
         ; TODO: but in general, we'd need to descend arbitrarily deep to say what the plaintext is
         ;  m0.data.plaintext = resp.resp_a + resp.resp_n1
         #,(let ([args (for/list ([a-datum (ast-enc-vals (ast-event-contents ev))])
                         #`(join #,rolevar #,(format-id pname "~a_~a_~a" pname rname (ast-datum-value a-datum))))])
             #`(= (join #,msg data plaintext)
                  #,(if (> (length args) 1)
                        #`(+ #,@args)         ; union of all plaintext's contents
                        #`#,(first args))))   ; just a singleton content
         
         ; What's the encryption key, if any?
         (= (join #,msg data encryptionKey)
            #,(build-key-expression-for-event pname rname rolevar ev))))
 
(define-for-syntax (build-key-expression-for-event pname rname rolevar ev)
  (let* ([contents (ast-event-contents ev)]
         [key (ast-enc-key contents)]
         [local-knower (if key (format-id pname "~a_~a_~a" pname rname (ast-datum-value key)) #f)]) 
    (cond [(and key (equal? 'privk (ast-datum-wrap key)))
           ; The key belongs to someone corresponding to a variable in this strand
           ; If a private key, we just look them up in owners
           ; If a public key, we need to follow the private key into the pairs relation
           #`(join KeyPairs owners (join #,rolevar #,local-knower))]
          [(and key (equal? 'pubk (ast-datum-wrap key)))             
           #`(join (join KeyPairs owners (join #,rolevar #,local-knower)) (join KeyPairs pairs))]
          [key
           (raise (error (format "Message was encrypted, but not with a key: ~a" contents)))]
          [else #'none])))

;      -- encrypted with public key of whoever is locally "b"
;      -- recall "owners" takes us to private key, and then lookup in pairs
;      m0.data.encryptionKey = KeyPairs.pairs[KeyPairs.owners.(resp.resp_b)]


; (recv (enc n1 a (pubk b)))
  
(define-for-syntax (build-role-predicate-body pname rname rolesig a-trace)
  ; E.g., ((msg0 . (rel Message)) (msg1 . (- (rel Message) msg0)) (msg2 . (- (- (rel Message) msg1) msg0)))
  (let ([msg-var-decls (for/list ([ev (ast-trace-events a-trace)]
                                  [i (build-list (length (ast-trace-events a-trace)) (lambda (x) x))])
                         #`[#,(format-id (ast-event-orig ev) "msg~a" i)
                            #,(foldr (lambda (idx sofar) #`(- #,sofar #,(format-id (ast-event-orig ev) "msg~a" idx)))
                                     #'Message
                                     (build-list i (lambda (x) x)))])])
    ; Add constraints for every one of the above message variables
    ; Trace structure for this role, plus temporal ordering
    (with-syntax ([rv (format-id rolesig "x_~a" rolesig)])
      #`(all ([rv #,rolesig])
             (some (#,@msg-var-decls)
                   (and                                        
                    #,@(for/list ([ev (ast-trace-events a-trace)]
                                  [i (build-list (length (ast-trace-events a-trace)) (lambda (x) x))])
                         (let ([msg (format-id (ast-event-orig ev) "msg~a" i)]
                               [prev-msg (if (> i 0) (format-id (ast-event-orig ev) "msg~a"  (- i 1)) #f)])
                           (build-event-assertion pname rname #'rv ev msg prev-msg)))))))))


; Main macro for defprotocol declarations
(define-syntax (defprotocol stx)
  (syntax-parse stx [(defprotocol pname:id ptype:id roles:defroleClass ...)
                     (quasisyntax/loc stx
                       (begin (roleforge pname roles) ...))]))

;(defskeleton ns
;  (vars (a b name) (n2 text))
;  (defstrand resp 3 (a a) (b b) (n2 n2))
;  (non-orig (privk a) (privk b))
;  (uniq-orig n2)
;  (comment "Responder point-of-view"))

; Main macro for defskeleton declarations
; Note optional comment parameter
; since skeletons aren't named by the input, generate our own index
(define-for-syntax (unbox-and-increment b)
  (let ([result (unbox b)])
    (set-box! b (+ result 1))
    result))
(define-for-syntax skeleton-index (box 0))

(define-syntax (defskeleton stx)
  (syntax-parse stx [(defskeleton pname:id vars:varsClass strand:strandClass
                       non-orig:nonOrigClass uniq-orig:uniqOrigClass (~optional comment:commentClass))
                     (let ([idx (unbox-and-increment skeleton-index)])
                       (with-syntax ([parentsig (format-id #'pname "skeleton_~a_~a" #'pname idx)])
                       (quasisyntax/loc stx
                         (begin
                           ; subsig for skeleton
                           (sig parentsig #:one) ; declare sig
                           ; variable fields (similar to protocol case: TODO -- factor)                           
                           #,@(build-variable-fields (attribute vars.tostruct) #'pname idx #'rolesig #:prefix "skeleton_")
                           ; TODO: predicate body
                           (pred #,(format-id #'pname "constrain_skeleton_~a_~a" #'pname idx) true)
                           ))))]))
;(pname vars strand non-orig uniq-orig comment)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Tests (local for now)

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
(hash-keys (forge:State-sigs forge:curr-state))
(hash-keys (forge:State-relations forge:curr-state))
(hash-keys (forge:State-pred-map forge:curr-state))
(relation-typelist ns_init_a)
(relation-typelist skeleton_ns_0_n1)

; Notes:
; Basic algebra has sorts (Table 10.3):
;   text|data|name|tag|skey|akey|mesg
;     skey and akey are symmetric and asymmetric keys
;   data vs text: page 21 says they are interchangeable, but disjoint
;     "both are available for cases where an analyst may wish to describe
;      a protocol in which two types of simple values exist that cannot be
;      confused for each other."
