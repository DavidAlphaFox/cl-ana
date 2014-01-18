;;;; package.lisp

(defpackage #:typespec 
  (:use :cl
        :int-char
	:list-utils
	:string-utils
        :symbol-utils
        :tensor
	:memoization
        :alexandria
	:cffi)
  (:export :typespec->cffi-type
           :typespec-foreign-alloc
	   :typespec-compound-p
	   :typespec-array-p
           ;; A function for setting the values of a foreign object
           ;; recursively; currently this is not directly provided by
           ;; CFFI
           :typespec->lisp-to-c 
           ;; Returns a function which, when applied to a C-pointer,
           ;; returns a lisp object corresponding to the C object
           :typespec->c-to-lisp
           ;; I may decide to use this (with changes) for providing
           ;; automatic flattening of typespecs so that nested array
           ;; types can be used as well as directly specifying the
           ;; rank of a multi-array:
	   :typespec-flatten-arrays
           ;; Function for handling strings stored as character arrays:
           :char-vector->string))
