;;; summarize-guile-TODO --- Display Guile TODO list in various ways

;; 	Copyright (C) 2002, 2006, 2010 Free Software Foundation, Inc.
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

;;; Author: Thien-Thi Nguyen <ttn@gnu.org>

;;; Commentary:

;; Usage: summarize-guile-TODO TODOFILE
;;
;; The TODOFILE is typically Guile's (see workbook/tasks/README)
;; presumed to serve as our signal to ourselves (lest we want real
;; bosses hassling us) wrt to the overt message "items to do" as well as
;; the messages that can be inferred from its structure.
;;
;; This program reads TODOFILE and displays interpretations on its
;; structure, including registered markers and ownership, in various
;; ways.
;;
;; A primary interest in any task is its parent task.  The output
;; summarization by default lists every item and its parent chain.
;; Top-level parents are not items.  You can use these command-line
;; options to modify the selection and display (selection criteria
;; are ANDed together):
;;
;; -i, --involved USER  -- select USER-involved items
;; -p, --personal USER  -- select USER-responsible items
;; -t, --todo           -- select unfinished items (status "-")
;; -d, --done           -- select finished items (status "+")
;; -r, --review         -- select review items (marker "R")
;;
;; -w, --who            -- also show who is associated w/ the item
;; -n, --no-parent      -- do not show parent chain
;;
;;
;; Usage from a Scheme program:
;;   (summarize-guile-TODO . args)      ; uses first arg only
;;
;;
;; Bugs: (1) Markers are scanned in sequence: D R X N%.  This means "XD"
;;           and the like are completely dropped.  However, such strings
;;           are unlikely to be used if the markers are chosen to be
;;           somewhat exclusive, which is currently the case for D R X.
;;           N% used w/ these needs to be something like: "D25%" (this
;;           means discussion accounts for 1/4 of the task).
;;
;; TODO: Implement more various ways. (Patches welcome.)
;;       Add support for ORing criteria.

;;; Code:
(debug-enable 'backtrace)

(define-module (scripts summarize-guile-TODO)
  :use-module (scripts read-text-outline)
  :use-module (ice-9 getopt-long)
  :autoload (srfi srfi-13) (string-tokenize) ; string library
  :autoload (srfi srfi-14) (char-set) ; string library
  :autoload (ice-9 common-list) (remove-if-not)
  :export (summarize-guile-TODO))

(define put set-object-property!)
(define get object-property)

(define (as-leaf x)
  (cond ((get x 'who)
         => (lambda (who)
              (put x 'who
                   (map string->symbol
                        (string-tokenize who (char-set #\:)))))))
  (cond ((get x 'pct-done)
         => (lambda (pct-done)
              (put x 'pct-done (string->number pct-done)))))
  x)

(define (hang-by-the-leaves trees)
  (let ((leaves '()))
    (letrec ((hang (lambda (tree parent)
                     (if (list? tree)
                         (begin
                           (put (car tree) 'parent parent)
                           (for-each (lambda (child)
                                       (hang child (car tree)))
                                     (cdr tree)))
                         (begin
                           (put tree 'parent parent)
                           (set! leaves (cons (as-leaf tree) leaves)))))))
      (for-each (lambda (tree)
                  (hang tree #f))
                trees))
    leaves))

(define (read-TODO file)
  (hang-by-the-leaves
   ((make-text-outline-reader
     "(([ ][ ])*)([-+])(D*)(R*)(X*)(([0-9]+)%)* *([^[]*)(\\[(.*)\\])*"
     '((level-substring-divisor . 2)
       (body-submatch-number . 9)
       (extra-fields . ((status . 3)
                        (design? . 4)
                        (review? . 5)
                        (extblock? . 6)
                        (pct-done . 8)
                        (who . 11)))))
    (open-file file "r"))))

(define (select-items p items)
  (let ((sub '()))
    (cond ((option-ref p 'involved #f)
           => (lambda (u)
                (let ((u (string->symbol u)))
                  (set! sub (cons
                             (lambda (x)
                               (and (get x 'who)
                                    (memq u (get x 'who))))
                             sub))))))
    (cond ((option-ref p 'personal #f)
           => (lambda (u)
                (let ((u (string->symbol u)))
                  (set! sub (cons
                             (lambda (x)
                               (cond ((get x 'who)
                                      => (lambda (ls)
                                           (eq? (car (reverse ls))
                                                u)))
                                     (else #f)))
                             sub))))))
    (for-each (lambda (pair)
                (cond ((option-ref p (car pair) #f)
                       (set! sub (cons (cdr pair) sub)))))
              `((todo . ,(lambda (x) (string=? (get x 'status) "-")))
                (done . ,(lambda (x) (string=? (get x 'status) "+")))
                (review . ,(lambda (x) (get x 'review?)))))
    (let loop ((sub (reverse sub)) (items items))
      (if (null? sub)
          (reverse items)
          (loop (cdr sub) (remove-if-not (car sub) items))))))

(define (make-display-item show-who? show-parent?)
  (let ((show-who
         (if show-who?
             (lambda (item)
               (cond ((get item 'who)
                      => (lambda (who) (format #f " ~A" who)))
                     (else "")))
             (lambda (item) "")))
        (show-parents
         (if show-parent?
             (lambda (item)
               (let loop ((parent (get item 'parent)) (indent 2))
                 (and parent
                      (begin
                        (format #t "under : ~A~A\n"
                                (make-string indent #\space)
                                parent)
                        (loop (get parent 'parent) (+ 2 indent))))))
             (lambda (item) #t))))
    (lambda (item)
      (format #t "status: ~A~A~A~A~A~A\nitem  : ~A\n"
              (get item 'status)
              (if (get item 'design?) "D" "")
              (if (get item 'review?) "R" "")
              (if (get item 'extblock?) "X" "")
              (cond ((get item 'pct-done)
                     => (lambda (pct-done)
                          (format #f " ~A%" pct-done)))
                    (else ""))
              (show-who item)
              item)
      (show-parents item))))

(define (display-items p items)
  (let ((display-item (make-display-item (option-ref p 'who #f)
                                         (not (option-ref p 'no-parent #f))
                                         )))
    (for-each display-item items)))

(define (summarize-guile-TODO . args)
  (let ((p (getopt-long (cons "summarize-guile-TODO" args)
                        '((who (single-char #\w))
                          (no-parent (single-char #\n))
                          (involved (single-char #\i)
                                    (value #t))
                          (personal (single-char #\p)
                                    (value #t))
                          (todo (single-char #\t))
                          (done (single-char #\d))
                          (review (single-char #\r))
                          ;; Add options here.
                          ))))
    (display-items p (select-items p (read-TODO (car (option-ref p '() #f))))))
  #t)                                   ; exit val

(define main summarize-guile-TODO)

;;; summarize-guile-TODO ends here
