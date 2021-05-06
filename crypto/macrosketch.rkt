#lang forge/core

; Module to accept CPSA protocol and skeleton definitions and enhance a
; base crypto specification with protocol/skeleton-specific sigs and constraints.
;   Tim and Abby (Spring 2021)

;https://hackage.haskell.org/package/cpsa-3.3.2/src/doc/cpsamanual.pdf
; At the moment, we have prototype support for the "basic" algebra

(require syntax/parse syntax/parse/define)
(require (for-syntax (only-in racket take last flatten drop-right first second third filter-map
                              string-join
                              or/c define/contract listof [-> -->]) 
                     racket/match
                     racket/syntax))


; For debugging speed, don't import the full spec yet
(sig Message) ; NOT CPSA's "mesg" sort
(sig Timeslot)
(relation next (Timeslot Timeslot))
(sig mesg)
(sig name #:extends mesg)
(sig text #:extends mesg)

; TODO: break 1-1 between name and Strand
; TODO: mesg type for OR (just rename datum?)

(sig KeyPairs #:one)
(sig Ciphertext #:extends mesg)
(sig Key #:extends mesg)
(sig PrivateKey #:extends Key)
(sig PublicKey #:extends Key)
(sig skey #:extends Key) ; symmetric, e.g. LTK
(relation sendTime (Message Timeslot))
(relation data (Message mesg))
(relation sender (Message name))
(relation receiver (Message name))
(relation encryptionKey (Ciphertext Key))
 ;pairs: set PrivateKey -> PublicKey,
 ;owners: set PrivateKey -> name
(relation pairs (KeyPairs PrivateKey PublicKey))
(relation ltks (KeyPairs name name skey))
(relation owners (KeyPairs PrivateKey name))
(relation plaintext (Ciphertext mesg))
(relation generated_times (name mesg Timeslot))

; TODO: swap above with the below, once finalized
;(require "current_model.rkt") ; the base crypto modl

; First, define some syntax classes to ease parsing and improve errors.
; Syntax classes can expose custom attributes, which make them easier to process.
; Since these classes are used by macros, we need to define them for-syntax
;  Note that the AST structs exist at syntax time, because they are used only to generate Forge declarations at syntax time.
(begin-for-syntax

  
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ; Start with a rough approximation of CPSA's term grammar

  ;; Structure of a term in CPSA basic grammar (note "mesg" sort can be any term)
  ; ground value (text, data, name)
  ; keys look like: (ltk a b), (pubk a), (privk a)
  ; (cat t1 ...) // list constructor (may be implicit, as in enc below)
  ; (enc t1 ...) // ciphertext constructor
  
  (struct ast-text (value) #:transparent)
  (define-syntax-class textClass
    #:description "ground text value or variable (may be of sort text, name, or data)"
    (pattern x:id
             #:attr tostruct (ast-text #'x)))

  (struct ast-key (value wrap) #:transparent)
  (define-syntax-class keyClass
    #:description "public, private, or symmetric long-term key"
    (pattern ((~literal privk) x:id)
             #:attr tostruct (ast-key #'x 'privk))
    (pattern ((~literal pubk) x:id)
             #:attr tostruct (ast-key #'x 'pubk))
    (pattern ((~literal ltk) x:id y:id)
             #:attr tostruct (ast-key #'(x y) 'ltk)))
            
  (struct ast-enc (values key) #:transparent)
  (define-syntax-class encClass
    #:description "encryption term"    
    (pattern ((~literal enc)
              vals:termClass ...
              key:keyClass)
             #:attr tostruct (ast-enc (de-cat (attribute vals.tostruct)) (attribute key.tostruct))))

  (struct ast-cat (values) #:transparent)
  (define-syntax-class catClass
    #:description "explicit concatenation"
    (pattern ((~literal cat) ds:termClass ...)
             #:attr tostruct (ast-cat (de-cat (attribute ds.tostruct)))))

  (define-syntax-class termClass
    #:description "term"
    (pattern t:textClass
             #:attr tostruct (attribute t.tostruct))
    (pattern t:keyClass
             #:attr tostruct (attribute t.tostruct))
    (pattern t:encClass
             #:attr tostruct (attribute t.tostruct))
    (pattern t:catClass
             #:attr tostruct (attribute t.tostruct))) 

  ; Flatten explicit concatenations
  ; e.g., (cat (cat a b) (cat n1 n2)) would be (cat a b n1 n2)
  ; e.g., (enc (cat a b c) (ltk a b)) would be (enc a b c (ltk a b))
  (define term/c (or/c ast-text? ast-key? ast-enc? ast-cat?))
  (define/contract (de-cat ast-list)
    (--> (listof term/c) (listof term/c)) ; note rename from -> to avoid clash
    (flatten
     (for/list ([t ast-list])
       (match t
         [(ast-text _) t]
         [(ast-key _ _) t]
         [(ast-enc subterms k) (ast-enc (de-cat subterms) k)]
         [(ast-cat subterms) subterms]))))

  (define/contract (is-ground? t)
    (--> term/c boolean?)
    (or (ast-key? t) (ast-text? t)))
  
  
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  
  ;(defrole init
  ;    (vars (a b name) (n1 n2 text))
  ;    (trace (send (enc n1 a (pubk b)))
  ;           (recv (enc n1 n2 (pubk a)))
  ;           (send (enc n2 (pubk b)))))
  (struct ast-role (rname vars trace declarations) #:transparent)
  (define-syntax-class defroleClass
    #:description "Role definition"
    (pattern ((~literal defrole)
              rname:id
              vars:varsClass
              trace:traceClass
              decls:declClass ...) 
             #:attr tostruct (ast-role #'rname (attribute vars.tostruct) (attribute trace.tostruct) (attribute decls.tostruct))))
  
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

  (struct ast-event (origstx type contents) #:transparent)
  (define-syntax-class eventClass
    #:description "Event definition"
    (pattern ((~literal send) vals:termClass ...)             
             #:attr tostruct (ast-event #'this-syntax 'send (de-cat (attribute vals.tostruct))))
    (pattern ((~literal recv) vals:termClass ...)
             #:attr tostruct (ast-event #'this-syntax 'recv (de-cat (attribute vals.tostruct)))))
 

  ;  (non-orig (privk a) (privk b))
  (struct ast-non-orig (data) #:transparent)
  (define-syntax-class nonOrigClass
    #:description "non-origination declaration"
    (pattern ((~literal non-orig)
              data:termClass ...)
             #:attr tostruct (ast-non-orig (attribute data.tostruct))))
  
  ;  (uniq-orig n2)
  (struct ast-uniq-orig (data) #:transparent)
  (define-syntax-class uniqOrigClass
    #:description "unique-origination declaration"
    (pattern ((~literal uniq-orig)
              data:termClass ...)
             #:attr tostruct (ast-uniq-orig (attribute data.tostruct))))

  (define-syntax-class declClass
    #:description "declaration"
    (pattern d:uniqOrigClass
             #:attr tostruct (attribute d.tostruct))
    (pattern d:nonOrigClass
             #:attr tostruct (attribute d.tostruct)))
  
  ; (a1 a2)
  ; Name is from CPSA docs. Bind a strand's variable name to a term
  ;   constructed from variables of the skeleton.
  (struct ast-maplet (var value))
  (define-syntax-class mapletClass
    #:description "maplet"
    (pattern (var:id value:termClass)
             #:attr tostruct (ast-maplet #'var (attribute value.tostruct))))

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
             (sig rolesig #:extends name) ; declare sig
             ; variable fields of that subsig as declared            
             #,@(build-variable-fields (ast-role-vars rolestruct) #'pname (ast-role-rname rolestruct) #'rolesig)
             ; execution predicate for agents having this role
             (pred #,(format-id #'pname "exec_~a_~a" #'pname #'role.rname)
                   #,(build-role-predicate-body #'pname #'role.rname #'rolesig (ast-role-trace rolestruct) (ast-role-declarations rolestruct))))))]))

;(define-for-syntax (build-variable-fields vardecls name1 name2 parent #:prefix [prefix ""])
(define-for-syntax (build-variable-fields vardecls name1 name2 parent #:prefix [prefix ""])  
  (for/list ([decl (ast-vars-assoc-decls vardecls)])
    (with-syntax ([varid (first decl)]
                  [type (second decl)])
      #`(relation
         #,(format-id name1 "~a~a_~a_~a" prefix name1 name2 #'varid)
         (#,parent type)))))

(define-for-syntax (build-event-assertion pname rname this-strand ev msg prev-msg)
  ;(printf "ast-event-contents ev: ~a~n" (ast-event-contents ev))
  ; First, assert temporal ordering on this message variable; msg happens strictly after prev-msg unless no prev-msg
  #`(and #,(if prev-msg
               #`(in (join #,msg sendTime) (join #,prev-msg (^ sendTime)))
               #`true)

         ; Assert event constraints
         ; Sender or receiver
         ;      m0.receiver = resp ; or sender, depending on type of event         
         #,(cond [(equal? (ast-event-type ev) 'send)
                  #`(= #,this-strand (join #,msg sender))]
                 [(equal? (ast-event-type ev) 'recv)
                  #`(= #,this-strand (join #,msg receiver))]
                 [else (error (format "bad event type: ~a" (ast-event-type ev)))])

         ; What's in the message?
         ; E.g., (send a (enc b (enc c (pubk a)) (privk b)))
         ; (1) Need to say what the contents of the message are:
         ;   msg.data = (+ <expr for a> <expr for enc ...>)
         ; (2) structural constraints on those contents, built recursively
         ;   <expr for enc ...>.encryptionKey = <expr for (privk b)>
         ;   etc.

         ; we can build a, (pubk a) ... from below: who is "a" locally? etc.
         ; but (enc ...) needs a "some"; there's no canonical term generation!
         ; Suppose we have a nested enc. Then "outer.plaintext" is context:
         ; some sub1_outer: Ciphertext & outer.plaintext | { }

         ; The somes won't get added for non-constructor terms, right?
         ; ** Create var names in parent, so that we can say their union = the contents **
         
         ;;;;;;
                  
         #,(build-subterm-list-constraints pname rname msg #'data this-strand (ast-event-contents ev))))

; Assume that values are just strand-local.
; TODO: prevent match if unable to read within a term, unless mesg type
(define-for-syntax (build-subterm-list-constraints pname rname parentname fieldname this-strand subterms)
  (let* ([term-exprs-and-constraints
          (for/list ([a-term subterms])                                        
            (let ([term-expr (datum-ast->expr this-strand pname rname a-term)])
              ; For each subterm, produce (astnode, expr, constraint) pair.
              ; if not a ground term, the expr will be an identifier to use as a quant variable
              (list a-term term-expr (build-term-constraints pname rname this-strand a-term term-expr))))]
         ; Include ALL terms in the equality below, even ground terms
         [term-exprs (map second term-exprs-and-constraints)]
         ; Only quantify when needed (non-ground AST nodes)
         [term-vars (filter-map (lambda (pr) (if (is-ground? (first pr)) #f (second pr)))
                                term-exprs-and-constraints)])
    ;(printf "subterms: ~a~n" subterms)
    ;(printf "term-exprs: ~a~n" term-exprs)
    ;(printf "term vars: ~a~n" term-vars)
    #`(some #,(map (lambda (q) #`[#,q (join #,parentname #,fieldname)]) term-vars)
            (and
             (= (join #,parentname #,fieldname) ; Subterm field contains these exactly
                #,(if (> (length term-exprs) 1)
                      #`(+ #,@term-exprs)
                      #`#,(first term-exprs))) 
             #,@(map third term-exprs-and-constraints))))) ; which have these shapes and relationships

(define-for-syntax (build-term-constraints pname rname this-strand a-term term-expr)  
  (match a-term
    [(ast-text val)     
     #'true]    
    [(ast-key owner ktype)
     #'true]
    [(ast-enc subterms k)
     ; Recur for new constraints, but also require that the encryption key is as expected
     #`(and
        (= (join #,term-expr encryptionKey)
           #,(datum-ast->expr this-strand pname rname (ast-enc-key a-term) #:id-converter id->strand-var))
        #,(build-subterm-list-constraints pname rname term-expr #'plaintext this-strand subterms))
     ]
    [(ast-cat subterms)
     (error (format "unexpected cat in build-term-constraints: ~a" term-expr))]))


; Take an AST struct and produce the corresponding expression relative to given context
; use (id->strand-var pname strand-role id)  
(define-for-syntax (datum-ast->expr this-strand-or-skeleton pname strand-role-or-skeleton-idx t #:id-converter [id-converter id->strand-var])  
  (match t    
    [(ast-text val)
     ; It's just an identifier; resolve via looking it up in the strand's variables
     #`(join #,this-strand-or-skeleton #,(id-converter pname strand-role-or-skeleton-idx val))]

    [(ast-key owner-or-pair ktype) 
     ; It's the key of an identifier; resolve and wrap (owner will be either singleton or 2-ele list)
     ; The key belongs to someone corresponding to a variable in this strand
     ; If a private key, we just look them up in owners
     ; If a public key, we need to follow the private key into the pairs relation     
     (match ktype
       ['privk
        #`(join KeyPairs owners (join #,this-strand-or-skeleton #,(id-converter pname strand-role-or-skeleton-idx owner-or-pair)))]
       ['pubk
        #`(join (join KeyPairs owners (join #,this-strand-or-skeleton #,(id-converter pname strand-role-or-skeleton-idx owner-or-pair))) (join KeyPairs pairs))]
       ['ltk
        (let ([pr (syntax->list owner-or-pair)])
          #`(join KeyPairs ltks
                  (join #,this-strand-or-skeleton #,(id-converter pname strand-role-or-skeleton-idx (first pr)))
                  (join #,this-strand-or-skeleton #,(id-converter pname strand-role-or-skeleton-idx (second pr)))))])]
    [(ast-enc subterms k)
     ; Manufacture a fresh variable id
     (let ([fresh (gensym)])
       ;(printf "Generating ID ~a for ~a~n" fresh (equal-hash-code t))
       #`#,(format-id pname "enc~a" fresh))
     ]
    [(ast-cat subterms)
     (error (format "unexpected cat in datum-sat->expr: ~a" t))]))

;(define-for-syntax (build-key-expression-for-event pname rname rolevar ev)
;  (let* ([contents (ast-event-contents ev)]
;         [key (ast-enc-key contents)]
;         ; This message was encrypted with a key; we locally have a value for whose key it is
;         [local-knower (if key (format-id pname "~a_~a_~a" pname rname (ast-datum-value key)) #f)]) 
;    (cond [(and key (equal? 'privk (ast-datum-wrap key)))
;           ; The key belongs to someone corresponding to a variable in this strand
;           ; If a private key, we just look them up in owners
;           ; If a public key, we need to follow the private key into the pairs relation
;           #`(join KeyPairs owners (join #,rolevar #,local-knower))]
;          [(and key (equal? 'pubk (ast-datum-wrap key)))             
;           #`(join (join KeyPairs owners (join #,rolevar #,local-knower)) (join KeyPairs pairs))]
;          [key
;           (raise (error (format "Message was encrypted, but not with a key term: ~a" contents)))]
;          [else #'none])))

;      -- encrypted with public key of whoever is locally "b"
;      -- recall "owners" takes us to private key, and then lookup in pairs
;      m0.data.encryptionKey = KeyPairs.pairs[KeyPairs.owners.(resp.resp_b)]


; (recv (enc n1 a (pubk b)))
  
(define-for-syntax (build-role-predicate-body pname rname rolesig a-trace role-decls)
  ; E.g., ((msg0 . (rel Message)) (msg1 . (- (rel Message) msg0)) (msg2 . (- (- (rel Message) msg1) msg0)))
  (let ([msg-var-decls (for/list ([ev (ast-trace-events a-trace)]
                                  [i (build-list (length (ast-trace-events a-trace)) (lambda (x) x))])
                         #`[#,(format-id (ast-event-origstx ev) "msg~a" i)
                            #,(foldr (lambda (idx sofar) #`(- #,sofar #,(format-id (ast-event-origstx ev) "msg~a" idx)))
                                     #'Message
                                     (build-list i (lambda (x) x)))])])
    ; Add constraints for every one of the above message variables
    ; Trace structure for this role, plus temporal ordering
    (with-syntax ([rv (format-id rolesig "arbitrary_~a" rolesig)])
      #`(all ([rv #,rolesig])
             (and
              #,@(build-role-orig-constraints #'rv pname rname rolesig role-decls)
              (some (#,@msg-var-decls)
                    (and                                        
                     #,@(for/list ([ev (ast-trace-events a-trace)]
                                   [i (build-list (length (ast-trace-events a-trace)) (lambda (x) x))])
                          (let ([msg (format-id (ast-event-origstx ev) "msg~a" i)]
                                [prev-msg (if (> i 0) (format-id (ast-event-origstx ev) "msg~a"  (- i 1)) #f)])
                            (build-event-assertion pname rname #'rv ev msg prev-msg))))))))))


(define-for-syntax (struct->name a-struct)
  (define-values (t s) (struct-info a-struct))
  (define-values (n ifc afc ap mp ikl st s2) (struct-type-info t))
  n)

(define-for-syntax (build-role-orig-constraints rv pname rname rolesig role-decls)  
  (flatten
   (for/list ([d role-decls])
     (cond [(equal? (struct->name d) 'ast-uniq-orig)
            (build-orig-constraints rv rname #'one ast-uniq-orig-data pname (list d) #:id-converter id->strand-var)]
           [(equal? (struct->name d) 'ast-non-orig)
            (build-orig-constraints rv rname #'no ast-non-orig-data pname (list d) #:id-converter id->strand-var)]
           [else
            (error (format "unknown decl type: ~a in ~a" (struct->name d) d))]))))


; Main macro for defprotocol declarations
(define-syntax (defprotocol stx)
  (syntax-parse stx [(defprotocol pname:id ptype:id roles:defroleClass ...)
                     ;(quasisyntax/loc stx #,(attribute roles.tostruct))
                     (quasisyntax/loc stx
                       (begin (roleforge pname roles) ...))
                     ]))

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

; Define a skeleton subsig for each skeleton.
(define-syntax (defskeleton stx)
  (syntax-parse stx [(defskeleton pname:id vars:varsClass strands:strandClass ...
                       non-orig:nonOrigClass uniq-orig:uniqOrigClass (~optional comment:commentClass))
                     (let ([idx (unbox-and-increment skeleton-index)])
                       (with-syntax ([skelesig (format-id #'pname "skeleton_~a_~a" #'pname idx)])                         
                       (quasisyntax/loc stx
                         (begin                           
                           (sig skelesig #:one) ; declare sig
                           ; variable fields (similar to protocol case: TODO -- factor out shared code)                           
                           #,@(build-variable-fields (attribute vars.tostruct) #'pname idx #'skelesig #:prefix "skeleton_")

                           ; Represent each instance as an existentially quantified role strand, rather than
                           ; saving an (unused) explicit link from the skeleton to each declared instance
                           ; We do index strands, though, for readable skolem names
                                                      
                           (pred #,(format-id #'pname "constrain_skeleton_~a_~a" #'pname idx)
                                 (and
                                  ; Every instance (only "strand" declarations, for the moment) induces some constraints
                                  #,@(let* ([strand-decls (attribute strands.tostruct)]
                                            [strand-idxs (build-list (length strand-decls) (lambda (x) x))])                                      
                                       (for/list ([this-strand-ast strand-decls]
                                                  [strand-idx strand-idxs])                                         
                                         (build-skeleton-strand-constraints
                                          #'pname
                                          #'skelesig
                                          idx
                                          this-strand-ast
                                          strand-idx)))                                         
                                  ; declarations
                                  ; wrap in list for extensibility when we support >1 decl of each type
                                  #,@(build-orig-constraints #'skelesig idx #'no ast-non-orig-data #'pname (list (attribute non-orig.tostruct)))
                                  #,@(build-orig-constraints #'skelesig idx #'one ast-uniq-orig-data #'pname (list (attribute uniq-orig.tostruct)))
                                  ))))))]))


; we don't need to resolve each strand's idea of who "a" is.
; we just need the value corresponding to the SKELETON's "a" (or the local strand's "a", if this came from a role defn), which we have already
(define-for-syntax (build-orig-constraints this-strand-or-skeleton
                                           strand-role-or-skeleton-idx
                                           kind accessor pname asts #:id-converter [id-converter id->skeleton-var])
  (let ([result
         (flatten
          (for/list ([ast asts])
            (for/list ([decl (accessor ast)])              
              #`(#,kind ([aStrand name])
                     (originates aStrand #,(datum-ast->expr this-strand-or-skeleton pname strand-role-or-skeleton-idx decl #:id-converter id-converter))))))])  
    result))


;  (let* ([all-sigs (forge:State-sigs forge:curr-state)]
;         [role-sigs (filter (lambda (s) (equal? 'name (forge:Sig-extends s))) all-sigs)])

; TODO: import
(pred (originates strand value)
      (not (in strand value)))

(define-for-syntax (build-skeleton-strand-constraints pname skelesig skeleton-idx strand-ast strand-idx)  
  (let* ([this-strand (format-id #'skelesig "~a_strand~a" skelesig strand-idx)]
         [strand-role (ast-strand-role strand-ast)]
         [strand-role-sig (format-id #'skelesig "~a_~a" pname strand-role)]
         [strand-height (ast-strand-height strand-ast)] ; UNUSED
         [maplet-constraints
          ; <strand1_0>.resp_a = SkeletonNS_1.s1_a    
          #`(#,@(for/list ([mlt (ast-strand-maplets strand-ast)])
                  ; Note that datum-ast->expr needs to know the role whose viewpoint we're constraining
                  ;  For instance, if the datum is "a", but we're talking about a "resp" strand, then
                  ;  we need to use the field "resp_a" since that's what the macro expansion produces.
                  (unless (ast-text? (ast-maplet-value mlt))
                    (error (format "at the moment, right-hand-side terms in maplets must be (unwrapped) identifiers: ~a" (second mlt))))
                  #`(= (join #,this-strand #,(id->strand-var pname strand-role (ast-maplet-var mlt)))  ; VARIABLE    
                       (join #,skelesig #,(id->skeleton-var pname skeleton-idx (ast-text-value (ast-maplet-value mlt))))) ; VALUE                   
                  ))])
    #`(some ([#,this-strand #,strand-role-sig]) 
            (and #,@maplet-constraints))))


; this is just the field name for the datum in the strand
; TODO some tangling here vs. variable creation code, should reuse
;skeleton_ns_1_n2
(define-for-syntax (id->skeleton-var pname skeleton-idx id)  
  (format-id pname "skeleton_~a_~a_~a" pname skeleton-idx id))      

; ns_resp_n2
(define-for-syntax (id->strand-var pname strand-role id)  
  (format-id pname "~a_~a_~a" pname strand-role id))

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


; Notes:
; Basic algebra has sorts (Table 10.3):
;   text|data|name|tag|skey|akey|mesg
;     skey and akey are symmetric and asymmetric keys
;     data vs text: page 21 says they are interchangeable, but disjoint
;       "both are available for cases where an analyst may wish to describe
;        a protocol in which two types of simple values exist that cannot be
;        confused for each other."
;     mesg: sort of messages, which can stand in for any value 



;;
;(defprotocol or basic
;  (defrole init (vars (a b s name) (na text) (k skey) (m text))
;    (trace
;     (send (cat m a b (enc na m a b (ltk a s))))
;     (recv (cat m (enc na k (ltk a s))))))
;  (defrole resp
;    (vars (a b s name) (nb text) (k skey) (m text) (x y mesg))
;    (trace
;     (recv (cat m a b x))
;     (send (cat m a b x (enc nb m a b (ltk b s))))
;     (recv (cat m y (enc nb k (ltk b s))))
;     (send y)))
;  (defrole serv (vars (a b s name) (na nb text) (k skey) (m text))
;    (trace
;     (recv (cat m a b (enc na m a b (ltk a s))
;		(enc nb m a b (ltk b s))))
;     (send (cat m (enc na k (ltk a s)) (enc nb k (ltk b s)))))
;    (uniq-orig k)))
;
;(defskeleton or
;  (vars (nb text) (s a b name))
;  (defstrand resp 4 (a a) (b b) (s s) (nb nb))
;  (non-orig (ltk a s) (ltk b s))
;  (uniq-orig nb))

; Confirm
(hash-keys (forge:State-sigs forge:curr-state))
(hash-keys (forge:State-relations forge:curr-state))
(hash-keys (forge:State-pred-map forge:curr-state))
(relation-typelist ns_init_a)
(relation-typelist skeleton_ns_0_n1)

;;;;;;;;;TESTS (move to another file)
;
; exactly 16 Datum, exactly 6 Key, 
;			exactly 2 SkeletonNS, 
;			exactly 1 SkeletonNS_0,
; 		 	exactly 1 SkeletonNS_1, 
;			exactly 3 PrivateKey, 
;			exactly 3 PublicKey, 
;			exactly 0 SymmetricKey, 
;			exactly 1 Init, 
;			exactly 1 Resp, 
;			exactly 1 Attacker, 
;			exactly 5 Ciphertext, 
;			exactly 2 Text,
;			exactly 6 Message,
; 			exactly 6 Timeslot, 
;			exactly 1 KeyPairs, 
;			exactly 3 name for {next is linear}
;

(set-option! 'verbose 5)
(set-option! 'solver 'MiniSatProver)
(set-option! 'logtranslation 1)
(set-option! 'coregranularity 1)
(set-option! 'core_minimization 'rce)

(sig Attacker #:extends name)

; THIS IS UNSAT BECAUSE WE HAVE YET TO IMPORT THE CORRECT ORIGINATION PREDICATE

(run NS_SAT
      #:preds [
               ;exec_ns_init
               ;exec_ns_resp
               constrain_skeleton_ns_0
               ]
      #:bounds [(is next linear)]
      #:scope [(mesg 16)
               (Key 6 6)
               (name 3 3)
               (KeyPairs 1 1)
               (Timeslot 6 6)
               (Message 6 6) ; not "mesg"
               (text 2 2)
               (Ciphertext 5 5)
               (Attacker 1 1)
               (ns_init 1 1)
               (ns_resp 1 1)
               (PrivateKey 3 3)
               (PublicKey 3 3)
               (skey 0 0)
               (skeleton_ns_0 1 1)
               (skeleton_ns_1 1 1)
               ]
      ;#:expect sat
      )

; This will auto-highlight if settings are correct
; (tree:get-value (forge:Run-result NS_SAT))