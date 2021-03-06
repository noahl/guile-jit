;;; use2dot --- Display module dependencies as a DOT specification

;; 	Copyright (C) 2001, 2006 Free Software Foundation, Inc.
;;
;; This program is free software; you can redistribute it and/or
;; modify it under the terms of the GNU Lesser General Public License
;; as published by the Free Software Foundation; either version 3, or
;; (at your option) any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;; Lesser General Public License for more details.
;;
;; You should have received a copy of the GNU Lesser General Public
;; License along with this software; see the file COPYING.LESSER.  If
;; not, write to the Free Software Foundation, Inc., 51 Franklin
;; Street, Fifth Floor, Boston, MA 02110-1301 USA

;;; Author: Thien-Thi Nguyen

;;; Commentary:

;; Usage: use2dot [OPTIONS] [FILE ...]
;; Display to stdout a DOT specification that describes module dependencies
;; in FILEs.
;;
;; A top-level `use-modules' form or a `:use-module' `define-module'-component
;; results in a "solid" style edge.
;;
;; An `:autoload' `define-module'-component results in a "dotted" style edge
;; with label "N" indicating that N names are responsible for triggering the
;; autoload.  [The "N" label is not implemented.]
;;
;; A top-level `load' or `primitive-load' form results in a a "bold" style
;; edge to a node named with either the file name if the `load' argument is a
;; string, or "[computed in FILE]" otherwise.
;;
;; Options:
;;  -m, --default-module MOD -- Set MOD as the default module (for top-level
;;                              `use-modules' forms that do not follow some
;;                              `define-module' form in a file).  MOD should be
;;                              be a list or `#f', in which case such top-level
;;                              `use-modules' forms are effectively ignored.
;;                              Default value: `(guile-user)'.

;;; Code:

(define-module (scripts use2dot)
  :autoload (ice-9 getopt-long) (getopt-long)
  :use-module ((srfi srfi-13) :select (string-join))
  :use-module ((scripts frisk)
               :select (make-frisker edge-type edge-up edge-down))
  :export (use2dot))

(define *default-module* '(guile-user))

(define (q s)                           ; quote
  (format #f "~S" s))

(define (vv pairs)                      ; => ("var=val" ...)
  (map (lambda (pair)
         (format #f "~A=~A" (car pair) (cdr pair)))
       pairs))

(define (>>header)
  (format #t "digraph use2dot {\n")
  (for-each (lambda (s) (format #t "  ~A;\n" s))
            (vv `((label . ,(q "Guile Module Dependencies"))
                  ;;(rankdir . LR)
                  ;;(size . ,(q "7.5,10"))
                  (ratio . fill)
                  ;;(nodesep . ,(q "0.05"))
                  ))))

(define (>>body edges)
  (for-each
   (lambda (edge)
     (format #t "  \"~A\" -> \"~A\"" (edge-down edge) (edge-up edge))
     (cond ((case (edge-type edge)
              ((autoload) '((style . dotted) (fontsize . 5)))
              ((computed) '((style . bold)))
              (else #f))
            => (lambda (etc)
                 (format #t " [~A]" (string-join (vv etc) ",")))))
     (format #t ";\n"))
   edges))

(define (>>footer)
  (format #t "}"))

(define (>> edges)
  (>>header)
  (>>body edges)
  (>>footer))

(define (use2dot . args)
  (let* ((parsed-args (getopt-long (cons "use2dot" args)    ;;; kludge
                                   '((default-module
                                       (single-char #\m) (value #t)))))
         (=m (option-ref parsed-args 'default-module *default-module*))
         (scan (make-frisker `(default-module . ,=m)))
         (files (option-ref parsed-args '() '())))
    (>> (reverse ((scan files) 'edges)))))

(define main use2dot)

;;; use2dot ends here
