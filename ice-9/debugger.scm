;;;; Guile Debugger

;;; Copyright (C) 1999 Free Software Foundation, Inc.
;;;
;;; This program is free software; you can redistribute it and/or
;;; modify it under the terms of the GNU General Public License as
;;; published by the Free Software Foundation; either version 2, or
;;; (at your option) any later version.
;;;
;;; This program is distributed in the hope that it will be useful,
;;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;;; General Public License for more details.
;;;
;;; You should have received a copy of the GNU General Public License
;;; along with this software; see the file COPYING.  If not, write to
;;; the Free Software Foundation, Inc., 59 Temple Place, Suite 330,
;;; Boston, MA 02111-1307 USA
;;;
;;; As a special exception, the Free Software Foundation gives permission
;;; for additional uses of the text contained in its release of GUILE.
;;;
;;; The exception is that, if you link the GUILE library with other files
;;; to produce an executable, this does not by itself cause the
;;; resulting executable to be covered by the GNU General Public License.
;;; Your use of that executable is in no way restricted on account of
;;; linking the GUILE library code into it.
;;;
;;; This exception does not however invalidate any other reasons why
;;; the executable file might be covered by the GNU General Public License.
;;;
;;; This exception applies only to the code released by the
;;; Free Software Foundation under the name GUILE.  If you copy
;;; code from other Free Software Foundation releases into a copy of
;;; GUILE, as the General Public License permits, the exception does
;;; not apply to the code that you add in this way.  To avoid misleading
;;; anyone as to the status of such modified files, you must delete
;;; this exception notice from them.
;;;
;;; If you write modifications of your own for GUILE, it is your choice
;;; whether to permit this exception to apply to your modifications.
;;; If you do not wish that, delete this exception notice.

(define-module (ice-9 debugger)
  :use-module (ice-9 debug)
  :use-module (ice-9 format)
  :no-backtrace
  )

(if (memq 'readline *features*)
    (define-module (ice-9 debugger)
      :use-module (ice-9 readline)))


(define debugger-prompt "debug> ")

(define-public (debug)
  (let ((stack (fluid-ref the-last-stack)))
    (if stack
	(let ((state (make-state stack 0)))
	  (display "This is the Guile debugger; type \"help\" for help.")
	  (newline)
	  (display "There are ")
	  (write (stack-length stack))
	  (display " frames on the stack.")
	  (newline)
	  (newline)
	  (write-state-short state)
	  (read-and-dispatch-commands state (current-input-port)))
	(display "Nothing to debug.\n"))))

(define (debugger-handler key . args)
  (case key
    ((exit-debugger) #f)
    ((signal)
     ;; Restore stack
     (fluid-set! the-last-stack (fluid-ref before-signal-stack))
     (apply display-error #f (current-error-port) args))
    (else
     (display "Internal debugger error:\n")
     (save-stack debugger-handler)
     (apply throw key args)))
  (throw 'exit-debugger))		;Pop the stack

(define (read-and-dispatch-commands state port)
  (catch 'exit-debugger
    (lambda ()
      (lazy-catch #t
        (lambda ()
	  (with-fluids ((last-command #f))
	    (let loop ((state state))
	      (loop (read-and-dispatch-command state port)))))
	debugger-handler))
    (lambda args
      *unspecified*)))

(define (read-and-dispatch-command state port)
  (if (using-readline?)
      (set-readline-prompt! debugger-prompt)
      (display debugger-prompt))
  (force-output)			;This should not be necessary...
  (let ((token (read-token port)))
    (cond ((eof-object? token)
	   (throw 'exit-debugger))
	  ((not token)
	   (discard-rest-of-line port)
	   (catch-user-errors port (lambda () (run-last-command state))))
	  (else
	   (or (catch-user-errors port
	         (lambda ()
	           (dispatch-command token command-table state port)))
	       state)))))

(define (run-last-command state)
  (let ((procedure (fluid-ref last-command)))
    (if procedure
	(procedure state))))

(define (catch-user-errors port thunk)
  (catch 'debugger-user-error
	 thunk
	 (lambda (key . objects)
	   (apply user-warning objects)
	   (discard-rest-of-line port)
	   #f)))

(define last-command (make-fluid))

(define (user-warning . objects)
  (for-each (lambda (object)
	      (display object))
	    objects)
  (newline))

(define (user-error . objects)
  (apply throw 'debugger-user-error objects))

;;;; Command dispatch

(define (dispatch-command string table state port)
  (let ((value (command-table-value table string)))
    (if value
	(dispatch-command/value value state port)
	(user-error "Unknown command: " string))))

(define (dispatch-command/value value state port)
  (cond ((command? value)
	 (dispatch-command/command value state port))
	((command-table? value)
	 (dispatch-command/table value state port))
	((list? value)
	 (dispatch-command/name value state port))
	(else
	 (error "Unrecognized command-table value: " value))))

(define (dispatch-command/command command state port)
  (let ((procedure (command-procedure command))
	(arguments ((command-parser command) port)))
    (let ((procedure (lambda (state) (apply procedure state arguments))))
      (warn-about-extra-args port)
      (fluid-set! last-command procedure)
      (procedure state))))

(define (warn-about-extra-args port)
  ;; **** modify this to show the arguments.
  (let ((char (skip-whitespace port)))
    (cond ((eof-object? char) #f)
	  ((char=? #\newline char) (read-char port))
	  (else
	   (user-warning "Extra arguments at end of line: "
			 (read-rest-of-line port))))))

(define (dispatch-command/table table state port)
  (let ((token (read-token port)))
    (if (or (eof-object? token)
	    (not token))
	(user-error "Command name too short.")
	(dispatch-command token table state port))))

(define (dispatch-command/name name state port)
  (let ((value (lookup-command name)))
    (cond ((not value)
	   (apply user-error "Unknown command name: " name))
	  ((command-table? value)
	   (apply user-error "Partial command name: " name))
	  (else
	   (dispatch-command/value value state port)))))

;;;; Command definition

(define (define-command name argument-template documentation procedure)
  (let ((name (canonicalize-command-name name)))
    (add-command name
		 (make-command name
			       (argument-template->parser argument-template)
			       documentation
			       procedure)
		 command-table)
    name))

(define (define-command-alias name1 name2)
  (let ((name1 (canonicalize-command-name name1)))
    (add-command name1 (canonicalize-command-name name2) command-table)
    name1))

(define (argument-template->parser template)
  ;; Deliberately handles only cases that occur in "commands.scm".
  (cond ((eq? 'tokens template)
	 (lambda (port)
	   (let loop ((tokens '()))
	     (let ((token (read-token port)))
	       (if (or (eof-object? token)
		       (not token))
		   (list (reverse! tokens))
		   (loop (cons token tokens)))))))
	((null? template)
	 (lambda (port)
	   '()))
	((and (pair? template)
	      (null? (cdr template))
	      (eq? 'object (car template)))
	 (lambda (port)
	   (list (read port))))
	((and (pair? template)
	      (equal? ''optional (car template))
	      (pair? (cdr template))
	      (null? (cddr template)))
	 (case (cadr template)
	   ((token)
	    (lambda (port)
	      (let ((token (read-token port)))
		(if (or (eof-object? token)
			(not token))
		    (list #f)
		    (list token)))))
	   ((exact-integer)
	    (lambda (port)
	      (list (parse-optional-exact-integer port))))
	   ((exact-nonnegative-integer)
	    (lambda (port)
	      (list (parse-optional-exact-nonnegative-integer port))))
	   ((object)
	    (lambda (port)
	      (list (parse-optional-object port))))
	   (else
	    (error "Malformed argument template: " template))))
	(else
	 (error "Malformed argument template: " template))))

(define (parse-optional-exact-integer port)
  (let ((object (parse-optional-object port)))
    (if (or (not object)
	    (and (integer? object)
		 (exact? object)))
	object
	(user-error "Argument not an exact integer: " object))))

(define (parse-optional-exact-nonnegative-integer port)
  (let ((object (parse-optional-object port)))
    (if (or (not object)
	    (and (integer? object)
		 (exact? object)
		 (not (negative? object))))
	object
	(user-error "Argument not an exact non-negative integer: " object))))

(define (parse-optional-object port)
  (let ((terminator (skip-whitespace port)))
    (if (or (eof-object? terminator)
	    (eq? #\newline terminator))
	#f
	(let ((object (read port)))
	  (if (eof-object? object)
	      #f
	      object)))))

;;;; Command tables

(define (lookup-command name)
  (let loop ((table command-table) (strings name))
    (let ((value (command-table-value table (car strings))))
      (cond ((or (not value) (null? (cdr strings))) value)
	    ((command-table? value) (loop value (cdr strings)))
	    (else #f)))))

(define (command-table-value table string)
  (let ((entry (command-table-entry table string)))
    (and entry
	 (caddr entry))))

(define (command-table-entry table string)
  (let loop ((entries (command-table-entries table)))
    (and (not (null? entries))
	 (let ((entry (car entries)))
	   (if (and (<= (cadr entry)
			(string-length string)
			(string-length (car entry)))
		    (= (string-length string)
		       (match-strings (car entry) string)))
	       entry
	       (loop (cdr entries)))))))

(define (match-strings s1 s2)
  (let ((n (min (string-length s1) (string-length s2))))
    (let loop ((i 0))
      (cond ((= i n) i)
	    ((char=? (string-ref s1 i) (string-ref s2 i)) (loop (+ i 1)))
	    (else i)))))

(define (write-command-name name)
  (display (car name))
  (for-each (lambda (string)
	      (write-char #\space)
	      (display string))
	    (cdr name)))

(define (add-command name value table)
  (let loop ((strings name) (table table))
    (let ((entry
	   (or (let loop ((entries (command-table-entries table)))
		 (and (not (null? entries))
		      (if (string=? (car strings) (caar entries))
			  (car entries)
			  (loop (cdr entries)))))
	       (let ((entry (list (car strings) #f #f)))
		 (let ((entries
			(let ((entries (command-table-entries table)))
			  (if (or (null? entries)
				  (string<? (car strings) (caar entries)))
			      (cons entry entries)
			      (begin
				(let loop ((prev entries) (this (cdr entries)))
				  (if (or (null? this)
					  (string<? (car strings) (caar this)))
				      (set-cdr! prev (cons entry this))
				      (loop this (cdr this))))
				entries)))))
		   (compute-string-abbreviations! entries)
		   (set-command-table-entries! table entries))
		 entry))))
      (if (null? (cdr strings))
	  (set-car! (cddr entry) value)
	  (loop (cdr strings)
		(if (command-table? (caddr entry))
		    (caddr entry)
		    (let ((table (make-command-table '())))
		      (set-car! (cddr entry) table)
		      table)))))))

(define (canonicalize-command-name name)
  (cond ((and (string? name)
	      (not (string-null? name)))
	 (list name))
	((let loop ((name name))
	   (and (pair? name)
		(string? (car name))
		(not (string-null? (car name)))
		(or (null? (cdr name))
		    (loop (cdr name)))))
	 name)
	(else
	 (error "Illegal command name: " name))))

(define (compute-string-abbreviations! entries)
  (let loop ((entries entries) (index 0))
    (let ((groups '()))
      (for-each
       (lambda (entry)
	 (let* ((char (string-ref (car entry) index))
		(group (assv char groups)))
	   (if group
	       (set-cdr! group (cons entry (cdr group)))
	       (set! groups
		     (cons (list char entry)
			   groups)))))
       entries)
      (for-each
       (lambda (group)
	 (let ((index (+ index 1)))
	   (if (null? (cddr group))
	       (set-car! (cdadr group) index)
	       (loop (let ((entry
			    (let loop ((entries (cdr group)))
			      (and (not (null? entries))
				   (if (= index (string-length (caar entries)))
				       (car entries)
				       (loop (cdr entries)))))))
		       (if entry
			   (begin
			     (set-car! (cdr entry) index)
			     (delq entry (cdr group)))
			   (cdr group)))
		     index))))
       groups))))

;;;; Data structures

(define command-table-rtd (make-record-type "command-table" '(entries)))
(define make-command-table (record-constructor command-table-rtd '(entries)))
(define command-table? (record-predicate command-table-rtd))
(define command-table-entries (record-accessor command-table-rtd 'entries))
(define set-command-table-entries!
  (record-modifier command-table-rtd 'entries))

(define command-rtd
  (make-record-type "command"
		    '(name parser documentation procedure)))

(define make-command
  (record-constructor command-rtd
		      '(name parser documentation procedure)))

(define command? (record-predicate command-rtd))
(define command-name (record-accessor command-rtd 'name))
(define command-parser (record-accessor command-rtd 'parser))
(define command-documentation (record-accessor command-rtd 'documentation))
(define command-procedure (record-accessor command-rtd 'procedure))

(define state-rtd (make-record-type "debugger-state" '(stack index)))
(define state? (record-predicate state-rtd))
(define make-state (record-constructor state-rtd '(stack index)))
(define state-stack (record-accessor state-rtd 'stack))
(define state-index (record-accessor state-rtd 'index))

(define (new-state-index state index)
  (make-state (state-stack state) index))

;;;; Character parsing

(define (read-token port)
  (letrec
      ((loop
	(lambda (chars)
	  (let ((char (peek-char port)))
	    (cond ((eof-object? char)
		   (do-eof char chars))
		  ((char=? #\newline char)
		   (do-eot chars))
		  ((char-whitespace? char)
		   (do-eot chars))
		  ((char=? #\# char)
		   (read-char port)
		   (let ((terminator (skip-comment port)))
		     (if (eof-object? char)
			 (do-eof char chars)
			 (do-eot chars))))
		  (else
		   (read-char port)
		   (loop (cons char chars)))))))
       (do-eof
	(lambda (eof chars)
	  (if (null? chars)
	      eof
	      (do-eot chars))))
       (do-eot
	(lambda (chars)
	  (if (null? chars)
	      #f
	      (list->string (reverse! chars))))))
    (skip-whitespace port)
    (loop '())))

(define (skip-whitespace port)
  (let ((char (peek-char port)))
    (cond ((or (eof-object? char)
	       (char=? #\newline char))
	   char)
	  ((char-whitespace? char)
	   (read-char port)
	   (skip-whitespace port))
	  ((char=? #\# char)
	   (read-char port)
	   (skip-comment port))
	  (else char))))

(define (skip-comment port)
  (let ((char (peek-char port)))
    (if (or (eof-object? char)
	    (char=? #\newline char))
	char
	(begin
	  (read-char port)
	  (skip-comment port)))))

(define (read-rest-of-line port)
  (let loop ((chars '()))
    (let ((char (read-char port)))
      (if (or (eof-object? char)
	      (char=? #\newline char))
	  (list->string (reverse! chars))
	  (loop (cons char chars))))))

(define (discard-rest-of-line port)
  (let loop ()
    (if (not (let ((char (read-char port)))
	       (or (eof-object? char)
		   (char=? #\newline char))))
	(loop))))

;;;; Commands

(define command-table (make-command-table '()))

(define-command "help" 'tokens
  "Type \"help\" followed by a command name for full documentation."
  (lambda (state tokens)
    (let loop ((name (if (null? tokens) '("help") tokens)))
      (let ((value (lookup-command name)))
	(cond ((not value)
	       (write-command-name name)
	       (display " is not a known command name.")
	       (newline))
	      ((command? value)
	       (display (command-documentation value))
	       (newline)
	       (if (equal? '("help") (command-name value))
		   (begin
		     (display "Available commands are:")
		     (newline)
		     (for-each (lambda (entry)
				 (if (not (list? (caddr entry)))
				     (begin
				       (display "  ")
				       (display (car entry))
				       (newline))))
			       (command-table-entries command-table)))))
	      ((command-table? value)
	       (display "The \"")
	       (write-command-name name)
	       (display "\" command requires a subcommand.")
	       (newline)
	       (display "Available subcommands are:")
	       (newline)
	       (for-each (lambda (entry)
			   (if (not (list? (caddr entry)))
			       (begin
				 (display "  ")
				 (write-command-name name)
				 (write-char #\space)
				 (display (car entry))
				 (newline))))
			 (command-table-entries value)))
	      ((list? value)
	       (loop value))
	      (else
	       (error "Unknown value from lookup-command:" value)))))
    state))

(define-command "frame" '('optional exact-nonnegative-integer)
  "Select and print a stack frame.
With no argument, print the selected stack frame.  (See also \"info frame\").
An argument specifies the frame to select; it must be a stack-frame number."
  (lambda (state n)
    (let ((state (if n (select-frame-absolute state n) state)))
      (write-state-short state)
      state)))

(define-command "position" '()
  "Display the position of the current expression."
  (lambda (state)
    (let* ((frame (stack-ref (state-stack state) (state-index state)))
	   (source (frame-source frame)))
      (if (not source)
	  (display "No source available for this frame.")
	  (let ((position (source-position source)))
	    (if (not position)
		(display "No position information available for this frame.")
		(display-position position)))))
    (newline)
    state))

(define-command "up" '('optional exact-integer)
  "Move N frames up the stack.  For positive numbers N, this advances
toward the outermost frame, to higher frame numbers, to frames
that have existed longer.  N defaults to one."
  (lambda (state n)
    (let ((state (select-frame-relative state (or n 1))))
      (write-state-short state)
      state)))

(define-command "down" '('optional exact-integer)
  "Move N frames down the stack.  For positive numbers N, this
advances toward the innermost frame, to lower frame numbers, to
frames that were created more recently.  N defaults to one."
  (lambda (state n)
    (let ((state (select-frame-relative state (- (or n 1)))))
      (write-state-short state)
      state)))

(define (eval-handler key . args)
  (let ((stack (make-stack #t eval-handler)))
    (if (= (length args) 4)
	(apply display-error stack (current-error-port) args)
	;; We want display-error to be the "final common pathway"
	(catch #t
	       (lambda ()
		 (apply bad-throw key args))
	       (lambda (key . args)
		 (apply display-error stack (current-error-port) args)))))
  (throw 'continue))

(define-command "evaluate" '(object)
  "Evaluate an expression.
The expression must appear on the same line as the command,
however it may be continued over multiple lines."
  (lambda (state expression)
    (let ((source (frame-source (stack-ref (state-stack state)
					   (state-index state)))))
      (if (not source)
	  (display "No environment for this frame.\n")
	  (catch 'continue
		 (lambda ()
		   (lazy-catch #t
			       (lambda ()
				 (let* ((env (memoized-environment source))
					(value (local-eval expression env)))
				   (display ";value: ")
				   (write value)
				   (newline)))
			       eval-handler))
		 (lambda args args)))
      state)))

(define-command "backtrace" '('optional exact-integer)
  "Print backtrace of all stack frames, or innermost COUNT frames.
With a negative argument, print outermost -COUNT frames.
If the number of frames aren't explicitly given, the debug option
`depth' determines the maximum number of frames printed."
  (lambda (state n-frames)
    (let ((stack (state-stack state)))
      ;; Kludge around lack of call-with-values.
      (let ((values
	     (lambda (start end)
	       ;;(do ((index start (+ index 1)))
	       ;;    ((= index end))
	       ;;(write-state-short* stack index))
	       ;;
	       ;; Use builtin backtrace instead:
	       (display-backtrace stack
				  (current-output-port)
				  (if (memq 'backwards (debug-options))
				      start
				      (- end 1))
				  (- end start))
	       )))
	(let ((end (stack-length stack)))
	  (cond ((not n-frames) ;(>= (abs n-frames) end))
		 (values 0 (min end (cadr (memq 'depth (debug-options))))))
		((>= n-frames 0)
		 (values 0 n-frames))
		(else
		 (values (+ end n-frames) end))))))
    state))

(define-command "quit" '()
  "Exit the debugger."
  (lambda (state)
    (throw 'exit-debugger)))

(define-command '("info" "frame") '()
  "All about selected stack frame."
  (lambda (state)
    (write-state-long state)
    state))

(define-command '("info" "args") '()
  "Argument variables of current stack frame."
  (lambda (state)
    (let ((index (state-index state)))
      (let ((frame (stack-ref (state-stack state) index)))
	(write-frame-index-long frame)
	(write-frame-args-long frame)))
    state))

(define-command-alias "f" "frame")
(define-command-alias '("info" "f") '("info" "frame"))
(define-command-alias "bt" "backtrace")
(define-command-alias "where" "backtrace")
(define-command-alias "p" "evaluate")
(define-command-alias '("info" "stack") "backtrace")

;;;; Command Support

(define (select-frame-absolute state number)
  (new-state-index state
		   (frame-number->index
		    (let ((end (stack-length (state-stack state))))
		      (if (>= number end)
			  (- end 1)
			  number))
		    (state-stack state))))

(define (select-frame-relative state delta)
  (new-state-index state
		   (let ((index (+ (state-index state) delta))
			 (end (stack-length (state-stack state))))
		     (cond ((< index 0) 0)
			   ((>= index end) (- end 1))
			   (else index)))))

(define (write-state-short state)
  (display "Frame ")
  (write-state-short* (state-stack state) (state-index state)))

(define (write-state-short* stack index)
  (write-frame-index-short stack index)
  (write-char #\space)
  (write-frame-short (stack-ref stack index))
  (newline))

(define (write-frame-index-short stack index)
  (let ((s (number->string (frame-number (stack-ref stack index)))))
    (display s)
    (write-char #\:)
    (write-chars #\space (- 4 (string-length s)))))

(define (write-frame-short frame)
  (if (frame-procedure? frame)
      (write-frame-short/application frame)
      (write-frame-short/expression frame)))

(define (write-frame-short/application frame)
  (write-char #\[)
  (write (let ((procedure (frame-procedure frame)))
	   (or (and (procedure? procedure)
		    (procedure-name procedure))
	       procedure)))
  (if (frame-evaluating-args? frame)
      (display " ...")
      (begin
	(for-each (lambda (argument)
		    (write-char #\space)
		    (write argument))
		  (frame-arguments frame))
	(write-char #\]))))

;;; Use builtin function instead:
(set! write-frame-short/application
      (lambda (frame)
	(display-application frame (current-output-port) 12)))

(define (write-frame-short/expression frame)
  (write (let* ((source (frame-source frame))
		(copy (source-property source 'copy)))
	   (if (pair? copy)
	       copy
	       (unmemoize source)))))

(define (write-state-long state)
  (let ((index (state-index state)))
    (let ((frame (stack-ref (state-stack state) index)))
      (write-frame-index-long frame)
      (write-frame-long frame))))

(define (write-frame-index-long frame)
  (display "Stack frame: ")
  (write (frame-number frame))
  (if (frame-real? frame)
      (display " (real)"))
  (newline))

(define (write-frame-long frame)
  (if (frame-procedure? frame)
      (write-frame-long/application frame)
      (write-frame-long/expression frame)))

(define (write-frame-long/application frame)
  (display "This frame is an application.")
  (newline)
  (if (frame-source frame)
      (begin
	(display "The corresponding expression is:")
	(newline)
	(display-source frame)
	(newline)))
  (display "The procedure being applied is: ")
  (write (let ((procedure (frame-procedure frame)))
	   (or (and (procedure? procedure)
		    (procedure-name procedure))
	       procedure)))
  (newline)
  (display "The procedure's arguments are")
  (if (frame-evaluating-args? frame)
      (display " being evaluated.")
      (begin
	(display ": ")
	(write (frame-arguments frame))))
  (newline))

(define (display-source frame)
  (let* ((source (frame-source frame))
	 (copy (source-property source 'copy)))
    (cond ((source-position source)
	   => (lambda (p) (display-position p) (display ":\n"))))
    (display "  ")
    (write (or copy (unmemoize source)))))

(define (source-position source)
  (let ((fname (source-property source 'filename))
	(line (source-property source 'line))
	(column (source-property source 'column)))
    (and fname
	 (list fname line column))))

(define (display-position pos)
  (format #t "~A:~D:~D" (car pos) (+ 1 (cadr pos)) (+ 1 (caddr pos))))

(define (write-frame-long/expression frame)
  (display "This frame is an evaluation.")
  (newline)
  (display "The expression being evaluated is:")
  (newline)
  (display-source frame)
  (newline))

(define (write-frame-args-long frame)
  (if (frame-procedure? frame)
      (let ((arguments (frame-arguments frame)))
	(let ((n (length arguments)))
	  (display "This frame has ")
	  (write n)
	  (display " argument")
	  (if (not (= n 1))
	      (display "s"))
	  (write-char (if (null? arguments) #\. #\:))
	  (newline))
	(for-each (lambda (argument)
		    (display "  ")
		    (write argument)
		    (newline))
		  arguments))
      (begin
	(display "This frame is an evaluation frame; it has no arguments.")
	(newline))))

(define (write-chars char n)
  (do ((i 0 (+ i 1)))
      ((>= i n))
    (write-char char)))
