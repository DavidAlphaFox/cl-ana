;;;; cl-ana is a Common Lisp data analysis library.
;;;; Copyright 2013-2015 Gary Hollis
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

(defpackage #:cl-ana.makeres
  (:use :cl
        :external-program
        :cl-ana.error-propogation
        :cl-ana.hdf-utils
        :cl-ana.macro-utils
        :cl-ana.list-utils
        :cl-ana.symbol-utils
        :cl-ana.map
        :cl-ana.functional-utils
        :cl-ana.file-utils
        :cl-ana.string-utils
        :cl-ana.serialization
        :cl-ana.histogram
        :cl-ana.pathname-utils
        :cl-ana.table
        :cl-ana.reusable-table
        :cl-ana.hash-table-utils)
  (:export
   ;; target
   :target
   :target-id
   :target-expr
   :target-deps
   :target-pdeps
   :target-val
   :target-stat
   :target-timestamp
   :make-target
   :copy-target
   ;; propogation:
   :res-dependents
   :makeres-set-auto-propogate
   :makeres-propogate!
   :makeres-set-sticky-pars
   ;; hash tables (these are for debugging only
   :*symbol-tables
   :*target-tables*
   :*fin-target-tables*
   :*project-id*
   :*transformation-table*
   :*params-table*
   :*args-tables*
   :*makeres-args*
   ;; noisy messages:
   :*makeres-warnings*
   ;; functions accessing hash tables
   :project
   :project-parameters
   :project-targets
   :symbol-table
   :target-table
   :copy-target-table
   ;; dependency sorting:
   :dep<
   :depsort
   :depsort-graph
   ;; target and parameter macros
   :res
   :resfn
   :par
   :parfn
   ;; project macros
   :defproject
   :in-project
   :defpars
   :undefpars
   :defres
   :undefres
   :setresfn
   :setres
   :unsetresfn
   :unsetres
   :clrres
   :clrresfn
   :settrans ; set transformation pipeline
   :makeres ; compile and call result generator
   ;; project utilities
   :target-ids
   :fin-target-ids
   ;; INCLUDED TRANSFORMATIONS:
   :lrestrans ; allows logical results
   :lres
   ;; Transformation utilities:
   :*trans->added-deps-fn*
   :deftransdeps
   ;; logres:
   :save-target
   :load-target
   :unload-target
   :define-save-target-method
   :define-load-target-method
   :load-object
   :save-object
   :cleanup
   :project-path
   :set-project-path
   :save-project
   :load-project
   :checkout-version
   :logres-ignore
   :logres-ignorefn
   :logres-ignore-by
   :logres-track
   :logres-trackfn
   :logres-track-by
   :function-target?
   :printable

   :current-path
   :target-path
   :work-path

   ;;; Snapshot Control:
   :save-snapshot
   :load-snapshot

   ;;; Caching:
   :defcache
   :init-logged-stats
   ;; Strategies:
   :open-cache
   :singleton-cache
   :fixed-cache

   ;; Utilities:
   :checkres
   :pruneres
   :purgeres))

(cl-ana.gmath:use-gmath :cl-ana.makeres)
