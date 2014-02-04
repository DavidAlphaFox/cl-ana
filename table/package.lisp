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
;;;; package.lisp

(defpackage #:table 
  (:use #:cl
	#:list-utils
	#:macro-utils
	#:string-utils
        #:symbol-utils
	#:functional-utils
	#:alexandria)
  (:export :table
	   :table-column-names
	   :table-access-mode
	   :table-column-symbols
	   :table-load-next-row
           :table-activate-columns
	   :table-get-field
	   :table-set-field
           :table-push-fields
	   :table-commit-row
	   :table-close
           :table-nrows
	   :do-table
           :smart-do-table
           :table-reduce
	   ;; table-chain:
	   :open-table-chain
	   :reset-table-chain
	   ;; plist-table:
	   :open-plist-table))
