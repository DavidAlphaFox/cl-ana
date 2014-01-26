;;;; cl-ana is a Common Lisp data analysis library.
;;;; Copyright 2013, 2014 Gary Hollis
;;;; 
;;;; This file is part of cl-ana.
;;;; 
;;;; cl-ana is free software: you can redistribute it and/or modify it
;;;; under the terms of the GNU General Public License as published by
;;;; the Free Software Foundation, either version 3 of the License, or
;;;; (at your option) any later version.
;;;; 
;;;; cl-ana is distributed in the hope that it will be useful, but
;;;; WITHOUT ANY WARRANTY; without even the implied warranty of
;;;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;;;; General Public License for more details.
;;;; 
;;;; You should have received a copy of the GNU General Public License
;;;; along with cl-ana.  If not, see <http://www.gnu.org/licenses/>.
;;;;
;;;; You may contact Gary Hollis (me!) via email at
;;;; ghollisjr@gmail.com
;;;; macro-utils.lisp

(in-package :macro-utils)

;; (defmacro with-gensyms (vars &body body)

;;   "Masks the variables listed in vars with (gensym) symbol names.
;; When writing a body expression using with-gensyms, be sure to place
;; the comma in front of variables referring to the (gensym) variables,
;; as otherwise it will refer a different binding (which sometimes is
;; exactly what you want)."

;;   (let ((bindings (mapcar (lambda (v) `(,v (gensym))) vars)))
;;     `(let ,bindings
;;        ,@body)))

(defmacro inrange (xlo op1 x op2 xhi &key (prec 0))
  `(and (if ,xlo
	    (,op1 (- ,xlo ,prec) ,x)
	    t)
	(if ,xhi
	    (,op2 ,x (+ ,xhi ,prec))
	    t)))

(defmacro cond-setf (place value &optional (condition t))
  "Only sets the place when the condition is met.

condition may be one of three values: :place, :value, or :both.

:place specifies that the place must evaluate to a non-nil value,

:value specifies that the value must evaluate to a non-nil value, and

:both specifies that both place and value must evaluate to non-nil
values."
  (let ((test
	 (case condition
	   (:place
	    place)
	   (:value
	    value)
	   (:both
	    `(and ,place ,value))
	   (:otherwise
	    t))))
    `(when ,test
       (setf ,place ,value))))

(defmacro print-eval (arg)
  (with-gensyms (varname)
    `(let ((,varname ,arg))
       (prin1 ',arg)
       (format t ": ")
       (prin1 ,varname)
       (format t "~%")
       ,varname)))

;; Very useful macro for combining keyword arguments only when
;; appropriate
(defmacro when-keywords (&body keyword-arg-specs)
  "Creates a plist containing the keyword arguments only when the
values are non-nil; if a keyword-arg-spec is a list, then the first
element is taken to be the field symbol and the second element the
expression to be passed as the value."
  (let* ((specs
          (loop
             for kas in keyword-arg-specs
             collecting
               (if (consp kas)
                   kas
                   (list (keywordify kas)
                         kas))))
         (when-statements
          (loop
             for (field-name val) in specs
             collecting
               `(when ,val
                  (list ,field-name ,val)))))
    `(append ,@when-statements)))

;; Reader macro for when-keywords:
;; Use #k(fn arg1 ... &when-keys key1 ...) as a shorthand form for
;; (apply #'fn arg 1 ... (when-keywords key1 ...))
;;(eval-when (:compile-toplevel :load-toplevel :execute)
(defun when-keywords-transformer-reader-macro (stream subchar arg)
  (let ((expr (read stream t)))
    (multiple-value-bind (normal-terms when-keys)
        (loop
           for x in expr
           for lst on expr
           until (and (symbolp x) (equal (keywordify x) :&when-keys))
           collecting x into normal-terms
           finally (return (values normal-terms (rest lst))))
      (let ((fn (first normal-terms))
            (normal-args (rest normal-terms)))
        (append `(apply (function ,fn))
                normal-args
                (when when-keys
                  `((when-keywords ,@when-keys))))))))


(set-dispatch-macro-character
 #\# #\k #'when-keywords-transformer-reader-macro)
;;)

;;;; From let-over-lambda: (this should probably be somewhere else)
(defun symb (&rest args)
  (values (intern (apply #'mkstr args))))

;;;; This is actually fully implemented by both loop and the iterate
;;;; library
;;;; Useful for simple while loops:
;; (defmacro while (boolean &body body)
;;   "Executes boolean at the start of each iteration; if boolean is
;; non-nil then body is executed, else while exits.  At the moment the
;; return value is not specified.n"
;;   (with-gensyms (test)
;;     `(do ((,test ,boolean ,boolean))
;;          ((not ,test))
;;        ,@body)))
