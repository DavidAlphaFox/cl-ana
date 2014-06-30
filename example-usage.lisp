;;;; makeres is a macro-driven library for performing computations
;;;; from declarative specifications of the computation, allowing
;;;; users to specify optimizations in computations directly.
;;;;
;;;; One of the reasons I am working on this is simply because I have
;;;; not run into another project which aims to do something similar.
;;;; I suspect that using Common Lisp may be the reason it occurred to
;;;; me, since it will most likely require macros to make it worth
;;;; using but simultaneously must be efficient/fast enough to use on
;;;; large/semi-large data sets.
;;;;
;;;; makeres is built on top of cl-ana, my library for general data
;;;; analysis.

;;;; The general flow of working with makeres should be:
;;;;
;;;; 1. Define as much about the computation as you like
;;;;
;;;; 2. Load these into a REPL
;;;;
;;;; 3. Generate results from these specifications
;;;;
;;;; 4. Modify/add information about computation results
;;;;
;;;; Then repeat 2-4 until you're done with analysis.

;;;; makeres is so close to the cells library that it makes me sad
;;;; inside that I cannot easily use it.  Ultimately the difference is
;;;; computation time, cells tries to recalculate on the fly and is an
;;;; extension to CLOS, whereas makeres aims to generate a function
;;;; which will perform computations given different parameters and
;;;; allow users to define operations which can be optimized.

;;;; My idea about declarative tabular data analysis should be built
;;;; on top of makeres in the form of defined optimizations and
;;;; operators.

;;;; The reductions can be stored in memory, but physical datasets
;;;; need to be stored on disk.  There should be a directory in which
;;;; all physical datasets are stored.  If reductions are to be stored
;;;; as well (necessary for very large datasets), then this can be
;;;; added as a feature

(require 'cl-ana)

(defpackage #:cl-tab
  (:use :cl))

(package-utils:use-package-group :cl-ana :cl-tab)

(in-package :cl-tab)

;; some datasets need to be generated in parallel with other datasets;
;; this should be done with a single pass over the source dataset.
;; This requires storing the code body necessary for each output
;; dataset, or generating it at compile time.

(defmacro gproc (&rest datasets)
  (let (;; dependency tree 
        (dep-tree (get-dep-tree datasets))
        (

(defstruct dataset
  ;; either :logical or :physical
  storage
  ;; function which loads the dataset, can take arbitrary parameters
  loader
  ;; table object
  table
  ;; hash-table mapping reduction name to dispatching function
  reductions
  ;; list of datasets which are needed for dataset.  e.g. if dataset
  ;; is a filtered dataset then it depends on the dataset from which
  ;; it is filtered.
  depends
  ;; load status, t for loaded, nil for needs loading
  load-state)

;; Use defana to define an analysis project.
(defmacro defana (name path)
  "Defines an analysis project named name and stored in path.  name
and path are evaluated."
  (alexandria:with-gensyms (n p)
    `(let ((,n ,name)
           (,p ,path))
       (setf (gethash ,n *analyses*)
             (make-ana :name ,n
                       :path ,p
                       :datasets (make-hash-table :test 'equal))))))

;; Use use-ana to checkout an analysis project, making each dataset
;; defined belong to analysis project.
(defun use-ana (ana)
  (setf *ana* ana))

(defun ana-path (&optional name)
  "setf-able path for analysis"
  (gethash name *ana-paths*))

(defun (setf ana-path) (val &optional name)
  (if name
      (setf (gethash name *ana-paths*) val)
      (setf (gethash *ana* *ana-paths*) val)))

(defmacro dataset (name type source)
  "Defines a dataset.

name is any object identifying the dataset (lists are useful)

type is either physical or logical (symbols) specifying whether it
should be written to disk.

source is a form using the operators defined in the context of this
macro specifying the source of the dataset.  Can represent a list of
HDF5 files, a plist, CSV, a filtered source dataset, etc.")

;; examples:

;; Defines an HDF5 dataset with
(dataset (source) physical
         (open-hdf-table-chain input-files "/group"))

;; Reductions are any quantity obtained by passing over the data once.
;; Typically used for histograms, max/min field values, means, etc.
;;
;; Each reduction is given a name and a form which should evaluate to
;; a dispatching (dlambda) closure accepting the argument forms you
;; then provide as the rest of the reduction specification list in the
;; default case.  Closure should return the reduction value given the
;; argument :get, and reset the reduction value given the argument
;; :reset.
(reductions (source)
            (x (hist-closure
                (make-shist
                 ((:name "x" :low -3d0 :high 3d0 :nbins 100))))
               (list x))
            (y (hist-closure ((:name "y" :low -5d0 :high 0d0 :nbins 5)))
               (list y)))

;; dlambda may not be efficient enough, we'll test it out
(defmacro hist-closure (creation-form &optional weighted)
  "Defines histogram closure for use with define-reductions and
datasets."
  (alexandria:with-gensyms (h args)
    `(let ((,h ,creation-form))
       (dlambda 
        (:get () ,h)
        (:reset ()
                (setf ,h ,creation-form))
        (t (&rest ,args)
           ,(if weighted
                `(apply #'hins ,h ,args)
                `(hins ,h (first ,args))))))))

(defmacro mean-closure ()
  "Defines mean closure for use with define-reductions and datasets."
  (alexandria:with-gensyms (args sum count)
    `(let ((,sum 0)
           (,count 0))
       (dlambda
        (:get () (/ ,sum ,count))
        (:reset ()
                (setf ,sum 0)
                (setf ,count 0))
        (t (&rest ,args)
           (incf ,sum (first ,args))
           (incf ,count))))))

(defmacro opt-closure (test-op)
  "Defines optimization closure for use with define-reductions and
datasets.  test-op should be a form evaluating to a comparison
operator."
  (alexandria:with-gensyms (args best op x)
    `(let ((,best nil)
           (,op ,test-op))
       (lambda (&rest ,args)
         (if ,args
             (let ((,x (first ,args)))
               (if ,best
                   (when (funcall ,op ,x ,best)
                     (setf ,best ,x))
                   (setf ,best (first ,args))))
             ,best)))))

;; filter takes input dataset, filter form, and an optional third form
;; (or maybe a &rest) specifying options for the filtered table,
;; e.g. copied fields, additional fields, or an explicit list of
;; fields.
(dataset (source above) logical
         (filter (source)
                 (> x 10)
                 (add-fields (z logical (+ x y))
                             (w physical (sqrt (sin x))))))

;; import-reductions: takes arguments from-dataset, to-dataset, and
;; the reduction names.  May provide special arguments e.g. for
;; copying all reductions
(include-reductions (source)
                    (source above)
                    x y)

(dataset (source below) logical
         (filter (source)
                 (<= x 10)
                 (add-fields (omega physical (sin x))
                             (theta logical (sqrt y)))))

(include-reductions (source)
                    (source below)
                    x y)
