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
;;;; memoization.lisp

;;; Memoized functions remember the previous calls of the function and
;;; look-up the return value from the last time the function was
;;; called.
;;;
;;; This implementation uses hash tables to store the previous call values.
;;;
;;; I am still unsure whether or not to expose access to the
;;; memoization hash table, at the moment it is not exposed.

(in-package :memoization)

(defvar *memoized-map* (make-hash-table :test 'equal)
  "Hash table mapping each memoized function to its value hash
  table.")

(defun get-memo-map (memo-fn)
  "Returns the memoized function's value hash table."
  (gethash memo-fn *memoized-map*))

(defun reset-memo-map (memo-fn)
  "Resets the memoization hash table for memo-fn"
  (clrhash (gethash memo-fn *memoized-map*)))

(defmacro memoize (fn &key (test 'equal))
  "Macro for memoizing any function; test argument allows you to
specify how arguments will be looked up."
  (with-gensyms (memoized
                 lookup-value
                 lookup-stored-p
                 return-value
                 args
                 table
                 xs)
    `(let* ((,table
             (make-hash-table :test ',test))
            (,memoized
             (lambda (&rest ,xs)
               (let ((,args ,xs)) ; for accidental capture
                 (multiple-value-bind
                       (,lookup-value ,lookup-stored-p)
                     (gethash ,args ,table)
                   (if ,lookup-stored-p
                       ,lookup-value
                       (let ((,return-value
                              (apply ,fn ,args)))
                         (setf (gethash ,args ,table)
                               ,return-value)
                         ,return-value)))))))
       (setf (gethash ,memoized *memoized-map*)
             ,table)
       ,memoized)))

(defun unmemoize (fn)
  "Removes fn from the memoization lookup table; this prevents access
to the lookup map from outside the function but allows the function to
be garbage collected if necessary."
  (remhash fn *memoized-map*))

(defmacro defun-memoized (function-name arg-list &body body)
  "Macro for defining a memoized function.  Note that currently there
is a small inconvenience in that lambda-lists are not automatically
added to the documentation used by things like SLIME."
  (with-gensyms (raw-function memoized defuned xs)
    `(let* ((,raw-function
             (lambda (&rest ,xs)
               (destructuring-bind (,@arg-list)
                   ,xs
                 ,@body)))
            (,memoized
             (memoize ,raw-function))
            (,defuned
             (defun ,function-name (&rest ,xs)
               (apply ,memoized ,xs))))
       (setf (gethash (symbol-function ,defuned) *memoized-map*)
             (gethash ,memoized *memoized-map*))
       ,memoized
       ,defuned)))
