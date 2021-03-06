;;; srfi-45.scm -- Primitives for Expressing Iterative Lazy Algorithms

;; Copyright (C) 2010 Free Software Foundation, Inc.
;; Copyright (C) 2003 André van Tonder. All Rights Reserved.

;; Permission is hereby granted, free of charge, to any person
;; obtaining a copy of this software and associated documentation
;; files (the "Software"), to deal in the Software without
;; restriction, including without limitation the rights to use, copy,
;; modify, merge, publish, distribute, sublicense, and/or sell copies
;; of the Software, and to permit persons to whom the Software is
;; furnished to do so, subject to the following conditions:

;; The above copyright notice and this permission notice shall be
;; included in all copies or substantial portions of the Software.

;; THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
;; EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
;; MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
;; NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS
;; BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
;; ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
;; CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
;; SOFTWARE.

;;; Commentary:

;; This is the code of the reference implementation of SRFI-45, slightly
;; modified to use SRFI-9.

;; This module is documented in the Guile Reference Manual.

;;; Code:

(define-module (srfi srfi-45)
  #:export (delay
             lazy
             force
             eager)
  #:replace (delay force)
  #:use-module (srfi srfi-9))

(define-record-type promise (make-promise val) promise?
  (val promise-val promise-val-set!))

(define-record-type value (make-value tag proc) value?
  (tag value-tag value-tag-set!)
  (proc value-proc value-proc-set!))

(define-syntax lazy
  (syntax-rules ()
    ((lazy exp)
     (make-promise (make-value 'lazy (lambda () exp))))))

(define (eager x)
  (make-promise (make-value 'eager x)))

(define-syntax delay
  (syntax-rules ()
    ((delay exp) (lazy (eager exp)))))

(define (force promise)
  (let ((content (promise-val promise)))
    (case (value-tag content)
      ((eager) (value-proc content))
      ((lazy)  (let* ((promise* ((value-proc content)))
                      (content  (promise-val promise)))        ; *
                 (if (not (eqv? (value-tag content) 'eager))   ; *
                     (begin (value-tag-set! content
                                            (value-tag (promise-val promise*)))
                            (value-proc-set! content
                                             (value-proc (promise-val promise*)))
                            (promise-val-set! promise* content)))
                 (force promise))))))

;; (*) These two lines re-fetch and check the original promise in case
;;     the first line of the let* caused it to be forced.  For an example
;;     where this happens, see reentrancy test 3 below.
