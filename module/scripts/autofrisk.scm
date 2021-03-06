;;; autofrisk --- Generate module checks for use with auto* tools

;; 	Copyright (C) 2002, 2006, 2009 Free Software Foundation, Inc.
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

;; Usage: autofrisk [file]
;;
;; This program looks for the file modules.af in the current directory
;; and writes out modules.af.m4 containing autoconf definitions.
;; If given, look for FILE instead of modules.af and output to FILE.m4.
;;
;; After running autofrisk, you should add to configure.ac the lines:
;;   AUTOFRISK_CHECKS
;;   AUTOFRISK_SUMMARY
;; Then run "aclocal -I ." to update aclocal.m4, and finally autoconf.
;;
;; The modules.af file consists of a series of configuration forms (Scheme
;; lists), which have one of the following formats:
;;   (files-glob PATTERN ...)
;;   (non-critical-external MODULE ...)
;;   (non-critical-internal MODULE ...)
;;   (programs (MODULE PROG ...) ...)
;;   (pww-varname VARNAME)
;; PATTERN is a string that may contain "*" and "?" characters to be
;; expanded into filenames.  MODULE is a list of symbols naming a
;; module, such as `(srfi srfi-1)'.  VARNAME is a shell-safe name to use
;; instead of "probably_wont_work", the default.  This var is passed to
;; `AC_SUBST'.  PROG is a string.
;;
;; Only the `files-glob' form is required.
;;
;; TODO: Write better commentary.
;;       Make "please see README" configurable.

;;; Code:

(define-module (scripts autofrisk)
  :autoload (ice-9 popen) (open-input-pipe)
  :use-module (srfi srfi-1)
  :use-module (srfi srfi-8)
  :use-module (srfi srfi-13)
  :use-module (srfi srfi-14)
  :use-module (scripts read-scheme-source)
  :use-module (scripts frisk)
  :export (autofrisk))

(define *recognized-keys* '(files-glob
                            non-critical-external
                            non-critical-internal
                            programs
                            pww-varname))

(define (canonical-configuration forms)
  (let ((chk (lambda (condition . x)
               (or condition (apply error "syntax error:" x)))))
    (chk (list? forms) "input not a list")
    (chk (every list? forms) "non-list element")
    (chk (every (lambda (form) (< 1 (length form))) forms) "list too short")
    (let ((un #f))
      (chk (every (lambda (form)
                    (let ((key (car form)))
                      (and (symbol? key)
                           (or (eq? 'quote key)
                               (memq key *recognized-keys*)
                               (begin
                                 (set! un key)
                                 #f)))))
                  forms)
           "unrecognized key:" un))
    (let ((bunched (map (lambda (key)
                          (fold (lambda (form so-far)
                                  (or (and (eq? (car form) key)
                                           (cdr form)
                                           (append so-far (cdr form)))
                                      so-far))
                                (list key)
                                forms))
                        *recognized-keys*)))
      (lambda (key)
        (assq-ref bunched key)))))

(define (>>strong modules)
  (for-each (lambda (module)
              (format #t "GUILE_MODULE_REQUIRED~A\n" module))
            modules))

(define (safe-name module)
  (let ((var (object->string module)))
    (string-map! (lambda (c)
                   (if (char-set-contains? char-set:letter+digit c)
                       c
                       #\_))
                 var)
    var))

(define *pww* "probably_wont_work")

(define (>>weak weak-edges)
  (for-each (lambda (edge)
              (let* ((up (edge-up edge))
                     (down (edge-down edge))
                     (var (format #f "have_guile_module~A" (safe-name up))))
                (format #t "GUILE_MODULE_AVAILABLE(~A, ~A)\n" var up)
                (format #t "test \"$~A\" = no &&\n  ~A=\"~A $~A\"~A"
                        var *pww* down *pww* "\n\n")))
            weak-edges))

(define (>>program module progs)
  (let ((vars (map (lambda (prog)
                     (format #f "guile_module~Asupport_~A"
                             (safe-name module)
                             prog))
                   progs)))
    (for-each (lambda (var prog)
                (format #t "AC_PATH_PROG(~A, ~A)\n" var prog))
              vars progs)
    (format #t "test \\\n")
    (for-each (lambda (var)
                (format #t " \"$~A\" = \"\" -o \\\n" var))
              vars)
    (format #t "~A &&\n~A=\"~A $~A\"\n\n"
            (list-ref (list "war = peace"
                            "freedom = slavery"
                            "ignorance = strength")
                      (random 3))
            *pww* module *pww*)))

(define (>>programs programs)
  (for-each (lambda (form)
              (>>program (car form) (cdr form)))
            programs))

(define (unglob pattern)
  (let ((p (open-input-pipe (format #f "echo '(' ~A ')'" pattern))))
    (map symbol->string (read p))))

(define (>>checks forms)
  (let* ((cfg (canonical-configuration forms))
         (files (apply append (map unglob (cfg 'files-glob))))
         (ncx (cfg 'non-critical-external))
         (nci (cfg 'non-critical-internal))
         (report ((make-frisker) files))
         (external (report 'external)))
    (let ((pww-varname (cfg 'pww-varname)))
      (or (null? pww-varname) (set! *pww* (car pww-varname))))
    (receive (weak strong)
        (partition (lambda (module)
                     (or (member module ncx)
                         (every (lambda (i)
                                  (member i nci))
                                (map edge-down (mod-down-ls module)))))
                   external)
      (format #t "AC_DEFUN([AUTOFRISK_CHECKS],[\n\n")
      (>>strong strong)
      (format #t "\n~A=~S\n\n" *pww* "")
      (>>weak (fold (lambda (module so-far)
                      (append so-far (mod-down-ls module)))
                    (list)
                    weak))
      (>>programs (cfg 'programs))
      (format #t "AC_SUBST(~A)\n])\n\n" *pww*))))

(define (>>summary)
  (format #t
          (symbol->string
           '#{
AC_DEFUN([AUTOFRISK_SUMMARY],[
if test ! "$~A" = "" ; then
    p="         ***"
    echo "$p"
    echo "$p NOTE:"
    echo "$p The following modules probably won't work:"
    echo "$p   $~A"
    echo "$p They can be installed anyway, and will work if their"
    echo "$p dependencies are installed later.  Please see README."
    echo "$p"
fi
])
}#)
          *pww* *pww*))

(define (autofrisk . args)
  (let ((file (if (null? args) "modules.af" (car args))))
    (or (file-exists? file)
        (error "could not find input file:" file))
    (with-output-to-file (format #f "~A.m4" file)
      (lambda ()
        (>>checks (read-scheme-source-silently file))
        (>>summary)))))

(define main autofrisk)

;; Local variables:
;; eval: (put 'receive 'scheme-indent-function 2)
;; End:

;;; autofrisk ends here
