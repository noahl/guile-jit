;;; api-diff --- diff guile-api.alist files

;; 	Copyright (C) 2002, 2006 Free Software Foundation, Inc.
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

;; Usage: api-diff [-d GROUPS] ALIST-FILE-A ALIST-FILE-B
;;
;; Read in the alists from files ALIST-FILE-A and ALIST-FILE-B
;; and display a (count) summary of the groups defined therein.
;; Optional arg "--details" (or "-d") specifies a comma-separated
;; list of groups, in which case api-diff displays instead the
;; elements added and deleted for each of the specified groups.
;;
;; For scheme programming, this module exports the proc:
;;  (api-diff A-file B-file)
;;
;; Note that the convention is that the "older" alist/file is
;; specified first.
;;
;; TODO: Develop scheme interface.

;;; Code:

(define-module (scripts api-diff)
  :use-module (ice-9 common-list)
  :use-module (ice-9 format)
  :use-module (ice-9 getopt-long)
  :autoload (srfi srfi-13) (string-tokenize)
  :export (api-diff))

(define (read-alist-file file)
  (with-input-from-file file
    (lambda () (read))))

(define put set-object-property!)
(define get object-property)

(define (read-api-alist-file file)
  (let* ((alist (read-alist-file file))
         (meta (assq-ref alist 'meta))
         (interface (assq-ref alist 'interface)))
    (put interface 'meta meta)
    (put interface 'groups (let ((ht (make-hash-table 31)))
                             (for-each (lambda (group)
                                         (hashq-set! ht group '()))
                                       (assq-ref meta 'groups))
                             ht))
    interface))

(define (hang-by-the-roots interface)
  (let ((ht (get interface 'groups)))
    (for-each (lambda (x)
                (for-each (lambda (group)
                            (hashq-set! ht group
                                        (cons (car x)
                                              (hashq-ref ht group))))
                          (assq-ref x 'groups)))
              interface))
  interface)

(define (diff? a b)
  (let ((result (set-difference a b)))
    (if (null? result)
        #f                              ; CL weenies bite me
        result)))

(define (diff+note! a b note-removals note-additions note-same)
  (let ((same? #t))
    (cond ((diff? a b) => (lambda (x) (note-removals x) (set! same? #f))))
    (cond ((diff? b a) => (lambda (x) (note-additions x) (set! same? #f))))
    (and same? (note-same))))

(define (group-diff i-old i-new . options)
  (let* ((i-old (hang-by-the-roots i-old))
         (g-old (hash-fold acons '() (get i-old 'groups)))
         (g-old-names (map car g-old))
         (i-new (hang-by-the-roots i-new))
         (g-new (hash-fold acons '() (get i-new 'groups)))
         (g-new-names (map car g-new)))
    (cond ((null? options)
           (diff+note! g-old-names g-new-names
                       (lambda (removals)
                         (format #t "groups-removed: ~A\n" removals))
                       (lambda (additions)
                         (format #t "groups-added: ~A\n" additions))
                       (lambda () #t))
           (for-each (lambda (group)
                       (let* ((old (assq-ref g-old group))
                              (new (assq-ref g-new group))
                              (old-count (and old (length old)))
                              (new-count (and new (length new)))
                              (delta (and old new (- new-count old-count))))
                         (format #t " ~5@A  ~5@A  :  "
                                 (or old-count "-")
                                 (or new-count "-"))
                         (cond ((and old new)
                                (let ((add-count 0) (sub-count 0))
                                  (diff+note!
                                   old new
                                   (lambda (subs)
                                     (set! sub-count (length subs)))
                                   (lambda (adds)
                                     (set! add-count (length adds)))
                                   (lambda () #t))
                                  (format #t "~5@D ~5@D : ~5@D"
                                          add-count (- sub-count) delta)))
                               (else
                                (format #t "~5@A ~5@A : ~5@A" "-" "-" "-")))
                         (format #t "     ~A\n" group)))
                     (sort (union g-old-names g-new-names)
                           (lambda (a b)
                             (string<? (symbol->string a)
                                       (symbol->string b))))))
          ((assq-ref options 'details)
           => (lambda (groups)
                (for-each (lambda (group)
                            (let* ((old (or (assq-ref g-old group) '()))
                                   (new (or (assq-ref g-new group) '()))
                                   (>>! (lambda (label ls)
                                          (format #t "~A ~A:\n" group label)
                                          (for-each (lambda (x)
                                                      (format #t " ~A\n" x))
                                                    ls))))
                              (diff+note! old new
                                          (lambda (removals)
                                            (>>! 'removals removals))
                                          (lambda (additions)
                                            (>>! 'additions additions))
                                          (lambda ()
                                            (format #t "~A: no changes\n"
                                                    group)))))
                          groups)))
          (else
           (error "api-diff: group-diff: bad options")))))

(define (api-diff . args)
  (let* ((p (getopt-long (cons 'api-diff args)
                         '((details (single-char #\d)
                                    (value #t))
                           ;; Add options here.
                           )))
         (rest (option-ref p '() '("/dev/null" "/dev/null")))
         (i-old (read-api-alist-file (car rest)))
         (i-new (read-api-alist-file (cadr rest)))
         (options '()))
    (cond ((option-ref p 'details #f)
           => (lambda (groups)
                (set! options (cons (cons 'details
                                          (map string->symbol
                                               (string-tokenize
                                                groups
                                                #\,)))
                                    options)))))
    (apply group-diff i-old i-new options)))

(define main api-diff)

;;; api-diff ends here
