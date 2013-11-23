;;;; package.lisp

(defpackage #:fitting
  (:use :cl
	:err-prop
	:map)
  (:export :fit
	   :get-value-alist
	   ;; fit functions:
	   :polynomial
	   :exponential
	   :power
	   :logarithm
	   :sinusoid
	   :gaussian))

(gmath:use-gmath :fitting)
