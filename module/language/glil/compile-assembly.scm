;;; Guile VM assembler

;; Copyright (C) 2001, 2009, 2010 Free Software Foundation, Inc.

;;;; This library is free software; you can redistribute it and/or
;;;; modify it under the terms of the GNU Lesser General Public
;;;; License as published by the Free Software Foundation; either
;;;; version 3 of the License, or (at your option) any later version.
;;;; 
;;;; This library is distributed in the hope that it will be useful,
;;;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;;;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;;;; Lesser General Public License for more details.
;;;; 
;;;; You should have received a copy of the GNU Lesser General Public
;;;; License along with this library; if not, write to the Free Software
;;;; Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA

;;; Code:

(define-module (language glil compile-assembly)
  #:use-module (system base syntax)
  #:use-module (system base pmatch)
  #:use-module (language glil)
  #:use-module (language assembly)
  #:use-module (system vm instruction)
  #:use-module ((system vm program) #:select (make-binding))
  #:use-module (ice-9 receive)
  #:use-module ((srfi srfi-1) #:select (fold))
  #:use-module (rnrs bytevectors)
  #:export (compile-assembly))

;; Variable cache cells go in the object table, and serialize as their
;; keys. The reason we wrap the keys in these records is so they don't
;; compare as `equal?' to other objects in the object table.
;;
;; `key' is either a symbol or the list (MODNAME SYM PUBLIC?)

(define-record <variable-cache-cell> key)

;; Subprograms can be loaded into an object table as well. We need a
;; disjoint type here too. (Subprograms have their own object tables --
;; though probably we should just make one table per compilation unit.)

(define-record <subprogram> table prog)


(define (limn-sources sources)
  (let lp ((in sources) (out '()) (filename #f))
    (if (null? in)
        (reverse! out)
        (let ((addr (caar in))
              (new-filename (assq-ref (cdar in ) 'filename))
              (line (assq-ref (cdar in) 'line))
              (column (assq-ref (cdar in) 'column)))
          (cond
           ((not (equal? new-filename filename))
            (lp (cdr in)
                `((,addr . (,line . ,column))
                  (filename . ,new-filename)
                  . ,out)
                new-filename))
           ((or (null? out) (not (equal? (cdar out) `(,line . ,column))))
            (lp (cdr in)
                `((,addr . (,line . ,column))
                  . ,out)
                filename))
           (else
            (lp (cdr in) out filename)))))))

(define (make-meta bindings sources arities tail)
  ;; sounds silly, but the only case in which we have no arities is when
  ;; compiling a meta procedure.
  (if (and (null? bindings) (null? sources) (null? arities) (null? tail))
      #f
      (compile-assembly
       (make-glil-program '()
                          (list
                           (make-glil-const `(,bindings ,sources ,arities ,@tail))
                           (make-glil-call 'return 1))))))

;; A functional stack of names of live variables.
(define (make-open-binding name boxed? index)
  (list name boxed? index))
(define (make-closed-binding open-binding start end)
  (make-binding (car open-binding) (cadr open-binding)
                (caddr open-binding) start end))
(define (open-binding bindings vars start)
  (cons
   (acons start
          (map
           (lambda (v)
             (pmatch v
               ((,name ,boxed? ,i)
                (make-open-binding name boxed? i))
               (else (error "unknown binding type" v))))
           vars)
          (car bindings))
   (cdr bindings)))
(define (close-binding bindings end)
  (pmatch bindings
    ((((,start . ,closing) . ,open) . ,closed)
     (cons open
           (fold (lambda (o tail)
                   ;; the cons is for dsu sort
                   (acons start (make-closed-binding o start end)
                          tail))
                 closed
                 closing)))
    (else (error "broken bindings" bindings))))
(define (close-all-bindings bindings end)
  (if (null? (car bindings))
      (map cdr
           (stable-sort (reverse (cdr bindings))
                        (lambda (x y) (< (car x) (car y)))))
      (close-all-bindings (close-binding bindings end) end)))

;; A functional object table.
(define *module* 1)
(define (assoc-ref-or-acons alist x make-y)
  (cond ((assoc-ref alist x)
         => (lambda (y) (values y alist)))
        (else
         (let ((y (make-y x alist)))
           (values y (acons x y alist))))))
(define (object-index-and-alist x alist)
  (assoc-ref-or-acons alist x
                      (lambda (x alist)
                        (+ (length alist) *module*))))
(define (make-object-table objects)
  (and (not (null? objects))
       (list->vector (cons #f objects))))

;; A functional arities thingamajiggy.
;; arities := ((ip nreq [[nopt] [[rest] [kw]]]]) ...)
(define (open-arity addr nreq nopt rest kw arities)
  (cons
   (cond
    (kw (list addr nreq nopt rest kw))
    (rest (list addr nreq nopt rest))
    (nopt (list addr nreq nopt))
    (nreq (list addr nreq))
    (else (list addr)))
   arities))
(define (close-arity addr arities)
  (pmatch arities
    (() '())
    (((,start . ,tail) . ,rest)
     `((,start ,addr . ,tail) . ,rest))
    (else (error "bad arities" arities))))
(define (begin-arity end start nreq nopt rest kw arities)
  (open-arity start nreq nopt rest kw (close-arity end arities)))

(define (compile-assembly glil)
  (receive (code . _)
      (glil->assembly glil #t '(()) '() '() #f '() -1)
    (car code)))

(define (glil->assembly glil toplevel? bindings
                        source-alist label-alist object-alist arities addr)
  (define (emit-code x)
    (values x bindings source-alist label-alist object-alist arities))
  (define (emit-code/object x object-alist)
    (values x bindings source-alist label-alist object-alist arities))
  (define (emit-code/arity x nreq nopt rest kw)
    (values x bindings source-alist label-alist object-alist
            (begin-arity addr (addr+ addr x) nreq nopt rest kw arities)))
  
  (record-case glil
    ((<glil-program> meta body)
     (define (process-body)
       (let lp ((body body) (code '()) (bindings '(())) (source-alist '())
                (label-alist '()) (object-alist (if toplevel? #f '()))
                (arities '()) (addr 0))
         (cond
          ((null? body)
           (values (reverse code)
                   (close-all-bindings bindings addr)
                   (limn-sources (reverse! source-alist))
                   (reverse label-alist)
                   (and object-alist (map car (reverse object-alist)))
                   (reverse (close-arity addr arities))
                   addr))
          (else
           (receive (subcode bindings source-alist label-alist object-alist
                     arities)
               (glil->assembly (car body) #f bindings
                               source-alist label-alist object-alist
                               arities addr)
             (lp (cdr body) (append (reverse subcode) code)
                 bindings source-alist label-alist object-alist arities
                 (addr+ addr subcode)))))))

     (receive (code bindings sources labels objects arities len)
         (process-body)
       (let* ((meta (make-meta bindings sources arities meta))
              (meta-pad (if meta (modulo (- 8 (modulo len 8)) 8) 0))
              (prog `(load-program ,labels
                                  ,(+ len meta-pad)
                                  ,meta
                                  ,@code
                                  ,@(if meta
                                        (make-list meta-pad '(nop))
                                        '()))))
         (cond
          (toplevel?
           ;; toplevel bytecode isn't loaded by the vm, no way to do
           ;; object table or closure capture (not in the bytecode,
           ;; anyway)
           (emit-code (align-program prog addr)))
          (else
           (let ((table (make-object-table objects)))
             (cond
              (object-alist
               ;; if we are being compiled from something with an object
               ;; table, cache the program there
               (receive (i object-alist)
                   (object-index-and-alist (make-subprogram table prog)
                                           object-alist)
                 (emit-code/object `(,(if (< i 256)
                                          `(object-ref ,i)
                                          `(long-object-ref ,(quotient i 256)
                                                            ,(modulo i 256))))
                                   object-alist)))
              (else
               ;; otherwise emit a load directly
               (let ((table-code (dump-object table addr)))
                 (emit-code
                  `(,@table-code
                    ,@(align-program prog (addr+ addr table-code)))))))))))))
    
    ((<glil-std-prelude> nreq nlocs else-label)
     (emit-code/arity
      (if (and (< nreq 8) (< nlocs (+ nreq 32)) (not else-label))
          `((assert-nargs-ee/locals ,(logior nreq (ash (- nlocs nreq) 3))))
          `(,(if else-label
                 `(br-if-nargs-ne ,(quotient nreq 256)
                                  ,(modulo nreq 256)
                                  ,else-label)
                 `(assert-nargs-ee ,(quotient nreq 256)
                                   ,(modulo nreq 256)))
            (reserve-locals ,(quotient nlocs 256)
                            ,(modulo nlocs 256))))
      nreq #f #f #f))

    ((<glil-opt-prelude> nreq nopt rest nlocs else-label)
     (let ((bind-required
            (if else-label
                `((br-if-nargs-lt ,(quotient nreq 256)
                                  ,(modulo nreq 256)
                                  ,else-label))
                `((assert-nargs-ge ,(quotient nreq 256)
                                   ,(modulo nreq 256)))))
           (bind-optionals
            (if (zero? nopt)
                '()
                `((bind-optionals ,(quotient (+ nopt nreq) 256)
                                  ,(modulo (+ nreq nopt) 256)))))
           (bind-rest
            (cond
             (rest
              `((push-rest ,(quotient (+ nreq nopt) 256)
                           ,(modulo (+ nreq nopt) 256))))
             (else
              (if else-label
                  `((br-if-nargs-gt ,(quotient (+ nreq nopt) 256)
                                    ,(modulo (+ nreq nopt) 256)
                                    ,else-label))
                  `((assert-nargs-ee ,(quotient (+ nreq nopt) 256)
                                     ,(modulo (+ nreq nopt) 256))))))))
       (emit-code/arity
        `(,@bind-required
          ,@bind-optionals
          ,@bind-rest
          (reserve-locals ,(quotient nlocs 256)
                          ,(modulo nlocs 256)))
        nreq nopt rest #f)))
    
    ((<glil-kw-prelude> nreq nopt rest kw allow-other-keys? nlocs else-label)
     (receive (kw-idx object-alist)
         (object-index-and-alist kw object-alist)
       (let* ((bind-required
               (if else-label
                   `((br-if-nargs-lt ,(quotient nreq 256)
                                     ,(modulo nreq 256)
                                     ,else-label))
                   `((assert-nargs-ge ,(quotient nreq 256)
                                      ,(modulo nreq 256)))))
              (ntotal (apply max (+ nreq nopt) (map 1+ (map cdr kw))))
              (bind-optionals-and-shuffle
               `((bind-optionals/shuffle
                  ,(quotient nreq 256)
                  ,(modulo nreq 256)
                  ,(quotient (+ nreq nopt) 256)
                  ,(modulo (+ nreq nopt) 256)
                  ,(quotient ntotal 256)
                  ,(modulo ntotal 256))))
              (bind-kw
               ;; when this code gets called, all optionals are filled
               ;; in, space has been made for kwargs, and the kwargs
               ;; themselves have been shuffled above the slots for all
               ;; req/opt/kwargs locals.
               `((bind-kwargs
                  ,(quotient kw-idx 256)
                  ,(modulo kw-idx 256)
                  ,(quotient ntotal 256)
                  ,(modulo ntotal 256)
                  ,(logior (if rest 2 0)
                           (if allow-other-keys? 1 0)))))
              (bind-rest
               (if rest
                   `((bind-rest ,(quotient ntotal 256)
                                ,(modulo ntotal 256)
                                ,(quotient rest 256)
                                ,(modulo rest 256)))
                   '())))
         
         (let ((code `(,@bind-required
                       ,@bind-optionals-and-shuffle
                       ,@bind-kw
                       ,@bind-rest
                       (reserve-locals ,(quotient nlocs 256)
                                       ,(modulo nlocs 256)))))
           (values code bindings source-alist label-alist object-alist
                   (begin-arity addr (addr+ addr code) nreq nopt rest
                                (and kw (cons allow-other-keys? kw))
                                arities))))))
    
    ((<glil-bind> vars)
     (values '()
             (open-binding bindings vars addr)
             source-alist
             label-alist
             object-alist
             arities))

    ((<glil-mv-bind> vars rest)
     (if (integer? vars)
         (values `((truncate-values ,vars ,(if rest 1 0)))
                 bindings
                 source-alist
                 label-alist
                 object-alist
                 arities)
         (values `((truncate-values ,(length vars) ,(if rest 1 0)))
                 (open-binding bindings vars addr)
                 source-alist
                 label-alist
                 object-alist
                 arities)))
    
    ((<glil-unbind>)
     (values '()
             (close-binding bindings addr)
             source-alist
             label-alist
             object-alist
             arities))
             
    ((<glil-source> props)
     (values '()
             bindings
             (acons addr props source-alist)
             label-alist
             object-alist
             arities))

    ((<glil-void>)
     (emit-code '((void))))

    ((<glil-const> obj)
     (cond
      ((object->assembly obj)
       => (lambda (code)
            (emit-code (list code))))
      ((not object-alist)
       (emit-code (dump-object obj addr)))
      (else
       (receive (i object-alist)
           (object-index-and-alist obj object-alist)
         (emit-code/object (if (< i 256)
                               `((object-ref ,i))
                               `((long-object-ref ,(quotient i 256)
                                                  ,(modulo i 256))))
                           object-alist)))))

    ((<glil-lexical> local? boxed? op index)
     (emit-code
      (if local?
          (if (< index 256)
              (case op
                ((ref) (if boxed?
                           `((local-boxed-ref ,index))
                           `((local-ref ,index))))
                ((set) (if boxed?
                           `((local-boxed-set ,index))
                           `((local-set ,index))))
                ((box) `((box ,index)))
                ((empty-box) `((empty-box ,index)))
                ((fix) `((fix-closure 0 ,index)))
                ((bound?) (if boxed?
                              `((local-ref ,index)
                                (variable-bound?))
                              `((local-bound? ,index))))
                (else (error "what" op)))
              (let ((a (quotient index 256))
                    (b (modulo index 256)))
                `((,(case op
                      ((ref)
                       (if boxed?
                           `((long-local-ref ,a ,b)
                             (variable-ref))
                           `((long-local-ref ,a ,b))))
                      ((set)
                       (if boxed?
                           `((long-local-ref ,a ,b)
                             (variable-set))
                           `((long-local-set ,a ,b))))
                      ((box)
                       `((make-variable)
                         (variable-set)
                         (long-local-set ,a ,b)))
                      ((empty-box)
                       `((make-variable)
                         (long-local-set ,a ,b)))
                      ((fix)
                       `((fix-closure ,a ,b)))
                      ((bound?)
                       (if boxed?
                           `((long-local-ref ,a ,b)
                             (variable-bound?))
                           `((long-local-bound? ,a ,b))))
                      (else (error "what" op)))
                   ,index))))
          `((,(case op
                ((ref) (if boxed? 'free-boxed-ref 'free-ref))
                ((set) (if boxed? 'free-boxed-set (error "what." glil)))
                (else (error "what" op)))
             ,index)))))
    
    ((<glil-toplevel> op name)
     (case op
       ((ref set)
        (cond
         ((not object-alist)
          (emit-code `(,@(dump-object name addr)
                       (link-now)
                       ,(case op 
                          ((ref) '(variable-ref))
                          ((set) '(variable-set))))))
         (else
          (receive (i object-alist)
              (object-index-and-alist (make-variable-cache-cell name)
                                      object-alist)
            (emit-code/object (if (< i 256)
                                  `((,(case op
                                        ((ref) 'toplevel-ref)
                                        ((set) 'toplevel-set))
                                     ,i))
                                  `((,(case op
                                        ((ref) 'long-toplevel-ref)
                                        ((set) 'long-toplevel-set))
                                     ,(quotient i 256)
                                     ,(modulo i 256))))
                              object-alist)))))
       ((define)
        (emit-code `(,@(dump-object name addr)
                     (define))))
       (else
        (error "unknown toplevel var kind" op name))))

    ((<glil-module> op mod name public?)
     (let ((key (list mod name public?)))
       (case op
         ((ref set)
          (cond
           ((not object-alist)
            (emit-code `(,@(dump-object key addr)
                         (link-now)
                         ,(case op 
                            ((ref) '(variable-ref))
                            ((set) '(variable-set))))))
           (else
            (receive (i object-alist)
                (object-index-and-alist (make-variable-cache-cell key)
                                        object-alist)
              (emit-code/object (case op
                                  ((ref) `((toplevel-ref ,i)))
                                  ((set) `((toplevel-set ,i))))
                                object-alist)))))
         (else
          (error "unknown module var kind" op key)))))

    ((<glil-label> label)
     (let ((code (align-block addr)))
       (values code
               bindings
               source-alist
               (acons label (addr+ addr code) label-alist)
               object-alist
               arities)))

    ((<glil-branch> inst label)
     (emit-code `((,inst ,label))))

    ;; nargs is number of stack args to insn. probably should rename.
    ((<glil-call> inst nargs)
     (if (not (instruction? inst))
         (error "Unknown instruction:" inst))
     (let ((pops (instruction-pops inst)))
       (cond ((< pops 0)
              (case (instruction-length inst)
                ((1) (emit-code `((,inst ,nargs))))
                ((2) (emit-code `((,inst ,(quotient nargs 256)
                                         ,(modulo nargs 256)))))
                (else (error "Unknown length for variable-arg instruction:"
                             inst (instruction-length inst)))))
             ((= pops nargs)
              (emit-code `((,inst))))
             (else
              (error "Wrong number of stack arguments to instruction:" inst nargs)))))

    ((<glil-mv-call> nargs ra)
     (emit-code `((mv-call ,nargs ,ra))))

    ((<glil-prompt> label escape-only?)
     (emit-code `((prompt ,(if escape-only? 1 0) ,label))))))

(define (dump-object x addr)
  (define (too-long x)
    (error (string-append x " too long")))

  (cond
   ((object->assembly x) => list)
   ((variable-cache-cell? x) (dump-object (variable-cache-cell-key x) addr))
   ((subprogram? x)
    (let ((table-code (dump-object (subprogram-table x) addr)))
      `(,@table-code
        ,@(align-program (subprogram-prog x)
                         (addr+ addr table-code)))))
   ((number? x)
    `((load-number ,(number->string x))))
   ((string? x)
    (case (string-bytes-per-char x)
      ((1) `((load-string ,x)))
      ((4) (align-code `(load-wide-string ,x) addr 4 4))
      (else (error "bad string bytes per char" x))))
   ((symbol? x)
    (let ((str (symbol->string x)))
      (case (string-bytes-per-char str)
        ((1) `((load-symbol ,str)))
        ((4) `(,@(dump-object str addr)
               (make-symbol)))
        (else (error "bad string bytes per char" str)))))
   ((keyword? x)
    `(,@(dump-object (keyword->symbol x) addr)
      (make-keyword)))
   ((list? x)
    (let ((tail (let ((len (length x)))
                  (if (>= len 65536) (too-long "list"))
                  `((list ,(quotient len 256) ,(modulo len 256))))))
      (let dump-objects ((objects x) (codes '()) (addr addr))
        (if (null? objects)
            (fold append tail codes)
            (let ((code (dump-object (car objects) addr)))
              (dump-objects (cdr objects) (cons code codes)
                            (addr+ addr code)))))))
   ((pair? x)
    (let ((kar (dump-object (car x) addr)))
      `(,@kar
        ,@(dump-object (cdr x) (addr+ addr kar))
        (cons))))
   ((and (vector? x)
         (equal? (array-shape x) (list (list 0 (1- (vector-length x))))))
    (let* ((len (vector-length x))
           (tail (if (>= len 65536)
                     (too-long "vector")
                     `((vector ,(quotient len 256) ,(modulo len 256))))))
      (let dump-objects ((i 0) (codes '()) (addr addr))
        (if (>= i len)
            (fold append tail codes)
            (let ((code (dump-object (vector-ref x i) addr)))
              (dump-objects (1+ i) (cons code codes)
                            (addr+ addr code)))))))
   ((and (array? x) (symbol? (array-type x)))
    (let* ((type (dump-object (array-type x) addr))
           (shape (dump-object (array-shape x) (addr+ addr type))))
      `(,@type
        ,@shape
        ,@(align-code
           `(load-array ,(uniform-array->bytevector x))
           (addr+ (addr+ addr type) shape)
           8
           4))))
   ((array? x)
    ;; an array of generic scheme values
    (let* ((contents (array-contents x))
           (len (vector-length contents)))
      (let dump-objects ((i 0) (codes '()) (addr addr))
        (if (< i len)
            (let ((code (dump-object (vector-ref contents i) addr)))
              (dump-objects (1+ i) (cons code codes)
                            (addr+ addr code)))
            (fold append
                  `(,@(dump-object (array-shape x) addr)
                    (make-array ,(quotient (ash len -16) 256)
                                ,(logand #xff (ash len -8))
                                ,(logand #xff len)))
                  codes)))))
   (else
    (error "assemble: unrecognized object" x))))

