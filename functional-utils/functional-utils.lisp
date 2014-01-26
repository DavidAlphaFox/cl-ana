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
;;;; functional-utils.lisp

(in-package :functional-utils)

(defun flip (f)
  "Takes a function of two parameters and creates a new function which
  takes the same parameters in reverse order; particularly useful in
  conjunction with reduce."
  (lambda (x y) (funcall f y x)))

;; (defun compose (&rest fs)
;;   "Arbitrary number of functions composed"
;;   (let ((f (first fs)))
;;     (if (= 1 (length fs))
;; 	(first fs)
;; 	(lambda (&rest xs)
;; 	    (funcall f (apply (apply #'compose (rest fs)) xs))))))

(defun to-pair-function (f)
  "Makes f apply to a pair instead of two arguments"
  (lambda (x) (funcall f (car x ) (cdr x))))

(defun lfuncall (fn &rest args)
  "Applies a function which takes a single list argument to an
arbitrary number of arguments."
  (funcall fn args))
