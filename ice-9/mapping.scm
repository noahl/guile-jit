;;; installed-scm-file

;;;; 	Copyright (C) 1996 Free Software Foundation, Inc.
;;;; 
;;;; This program is free software; you can redistribute it and/or modify
;;;; it under the terms of the GNU General Public License as published by
;;;; the Free Software Foundation; either version 2, or (at your option)
;;;; any later version.
;;;; 
;;;; This program is distributed in the hope that it will be useful,
;;;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;;;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;;;; GNU General Public License for more details.
;;;; 
;;;; You should have received a copy of the GNU General Public License
;;;; along with this software; see the file COPYING.  If not, write to
;;;; the Free Software Foundation, Inc., 59 Temple Place, Suite 330,
;;;; Boston, MA 02111-1307 USA
;;;;
;;;; As a special exception, the Free Software Foundation gives permission
;;;; for additional uses of the text contained in its release of GUILE.
;;;;
;;;; The exception is that, if you link the GUILE library with other files
;;;; to produce an executable, this does not by itself cause the
;;;; resulting executable to be covered by the GNU General Public License.
;;;; Your use of that executable is in no way restricted on account of
;;;; linking the GUILE library code into it.
;;;;
;;;; This exception does not however invalidate any other reasons why
;;;; the executable file might be covered by the GNU General Public License.
;;;;
;;;; This exception applies only to the code released by the
;;;; Free Software Foundation under the name GUILE.  If you copy
;;;; code from other Free Software Foundation releases into a copy of
;;;; GUILE, as the General Public License permits, the exception does
;;;; not apply to the code that you add in this way.  To avoid misleading
;;;; anyone as to the status of such modified files, you must delete
;;;; this exception notice from them.
;;;;
;;;; If you write modifications of your own for GUILE, it is your choice
;;;; whether to permit this exception to apply to your modifications.
;;;; If you do not wish that, delete this exception notice.
;;;; 



(define-module (ice-9 mapping)
  :use-module (ice-9 poe))

(define-public mapping-hooks-type (make-record-type 'mapping-hooks '(get-handle
								     create-handle
								     remove)))


(define-public make-mapping-hooks (perfect-funcq 17 (record-constructor mapping-hooks-type)))
(define-public mapping-hooks? (record-predicate mapping-hooks-type))
(define-public mapping-hooks-get-handle (record-accessor mapping-hooks-type 'get-handle))
(define-public mapping-hooks-create-handle (record-accessor mapping-hooks-type 'create-handle))
(define-public mapping-hooks-remove (record-accessor mapping-hooks-type 'remove))

(define-public mapping-type (make-record-type 'mapping '(hooks data)))
(define-public make-mapping (record-constructor mapping-type))
(define-public mapping? (record-predicate mapping-type))
(define-public mapping-hooks (record-accessor mapping-type 'hooks))
(define-public mapping-data (record-accessor mapping-type 'data))
(define-public set-mapping-hooks! (record-modifier mapping-type 'hooks))
(define-public set-mapping-data! (record-modifier mapping-type 'data))

(define-public (mapping-get-handle map key)
  ((mapping-hooks-get-handle (mapping-hooks map)) map key))
(define-public (mapping-create-handle! map key . opts)
  (apply (mapping-hooks-create-handle (mapping-hooks map)) map key opts))
(define-public (mapping-remove! map key)
  ((mapping-hooks-remove (mapping-hooks map)) map key))

(define-public (mapping-ref map key . dflt)
  (cond
   ((mapping-get-handle map key)	=> cdr)
   (dflt				=> car)
   (else				#f)))

(define-public (mapping-set! map key val)
  (set-cdr! (mapping-create-handle! map key #f) val))



(define-public hash-table-mapping-hooks
  (let ((wrap (lambda (proc) (lambda (1st . rest) (apply proc (mapping-data 1st) rest)))))

    (perfect-funcq 17
		   (lambda (hash-proc assoc-proc delete-proc)
		     (let ((procs (list hash-proc assoc-proc delete-proc)))
		       (cond
			((equal? procs `(,hashq ,assq ,delq!))
			 (make-mapping-hooks (wrap hashq-get-handle)
					     (wrap hashq-create-handle!)
					     (wrap hashq-remove!)))
			((equal? procs `(,hashv ,assv ,delv!))
			 (make-mapping-hooks (wrap hashv-get-handle)
					     (wrap hashv-create-handle!)
					     (wrap hashv-remove!)))
			((equal? procs `(,hash ,assoc ,delete!))
			 (make-mapping-hooks (wrap hash-get-handle)
					     (wrap hash-create-handle!)
					     (wrap hash-remove!)))
			(else
			 (make-mapping-hooks (wrap
					      (lambda (table key)
						(hashx-get-handle hash-proc assoc-proc table key)))
					     (wrap
					      (lambda (table key)
						(hashx-create-handle hash-proc assoc-proc table key)))
					     (wrap
					      (lambda (table key)
						(hashx-get-handle hash-proc assoc-proc delete-proc table key)))))))))))

(define-public (make-hash-table-mapping table hash-proc assoc-proc delete-proc)
  (make-mapping (hash-table-mapping-hooks hash-proc assoc-proc delete-proc) table))

(define-public (hash-table-mapping . options)
  (let* ((size (or (and options (number? (car options)) (car options))
		   71))
	 (hash-proc (or (kw-arg-ref options :hash-proc) hash))
	 (assoc-proc (or (kw-arg-ref options :assoc-proc)
			 (cond
			  ((eq? hash-proc hash) assoc)
			  ((eq? hash-proc hashv) assv)
			  ((eq? hash-proc hashq) assq)
			  (else (error 'hash-table-mapping
				       "Hash-procedure specified with no known assoc function."
				       hash-proc)))))
	 (delete-proc (or (kw-arg-ref options :delete-proc)
			  (cond
			   ((eq? hash-proc hash) delete!)
			   ((eq? hash-proc hashv) delv!)
			   ((eq? hash-proc hashq) delq!)
			   (else (error 'hash-table-mapping
					"Hash-procedure specified with no known delete function."
					hash-proc)))))
	 (table-constructor (or (kw-arg-ref options :table-constructor)
				(lambda (len) (make-vector len '())))))
    (make-hash-table-mapping (table-constructor size)
			     hash-proc
			     assoc-proc
			     delete-proc)))

