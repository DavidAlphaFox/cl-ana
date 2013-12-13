;;; Test results: It looks like the slowness in reading the data files
;;; is coming from the h5dread function, not from the LISP code!!!
;;; This means that I may still be able to do my analysis in common
;;; lisp after all.  The real issue seems to be the chunk size, as I
;;; currently have this set to 1 element per chunk.  This was my first
;;; dummy value, but now I think I should test various chunk sizes
;;; with C++ code and then use the proper chunk settings in my data
;;; files.
;;;
;;; I'll have to change the way I implement hdf-table to allow for a
;;; chunk buffer which stores multiple rows; shouldn't be too hard.

(require 'hdf-table)

(in-package :hdf-table)

;; (defvar *table*)

;; (setf *table*
;;       (make-instance 'hdf-table
;;                      :column-names (list "x" "y" "z")
;;                      :column-specs
;;                      (list :int
;;                            :float
;;                            (list :compound
;;                                  (cons "weight" :double)
;;                                  (cons "direction vector"
;;                                        (list :array :double 1 (list 20)))))))

;; (defun hdf-table-test ()
;;   (typespec->hdf-type (typed-table->typespec *table*)))

(defun hdf-type-test ()
  (hdf-type->typespec
   (typespec->hdf-type
    '(:compound
      ("x" . :double)
      ("y" . :int)
      ("xs" . (:array :double 1 (5)))
      ("ys" . (:compound
	       ("t" . :int)))))))

(defun hdf-type-test2 ()
  (hdf-type->typespec
   (typespec->hdf-type
    '(:compound
      ("x" . :double)
      ("y" . :int)
      ("xs" . (:compound
	       ("fs" . (:array :double 1 (5)))))
      ("ys" . (:compound
	       ("t" . :int)))))))

(defvar *table*)

(defvar *hdf-typespec*)

(defvar *table-typespec*)

(defvar *hdf-size*)

(defvar *cstruct-size*)

(defvar *hdf-file*)

(defun hdf-read-data-test ()
  (with-open-hdf-file (file "/home/ghollisjr/phys/research/phd/ana/hdffile.h5"
			    :direction :input)
    (setf *table* (open-hdf-table file "/h10"))
    (setf *hdf-file* file)
    (let ((result 0)
	  (last-row-index 0))
      (setf *table-typespec* (typed-table->typespec *table*))
      (setf *hdf-size* (h5tget-size (hdf-table-row-type *table*)))
      (setf *hdf-typespec* (hdf-type->typespec (hdf-table-row-type *table*)))
      (setf *cstruct-size* (foreign-type-size (typed-table-row-cstruct *table*)))
      (do-table (row-index *table*)
	  ("gpart")
	(incf result gpart)
	(setf last-row-index row-index))
      (format t "last-row-index: ~a~%" last-row-index)
      result)))

(defun hdf-write-table-test ()
  (with-open-hdf-file (file
		       "/home/ghollisjr/hdfwork/test.h5"
		       :direction :output
		       :if-exists :supersede)
    (let* ((table
            (create-hdf-table file
                            "/test"
                            (list (cons "x" :int)
                                  (cons "y" :float)))))
      ;;(print (typed-table-type-map table))
      (dotimes (i 1000000)
	(table-set-field table 'x i)
	(table-set-field table 'y (sqrt i))
	(table-commit-row table))
      (table-close table))))

(defun hdf-read-test ()
  (setf *table* (open-hdf-table-chain (list "/home/ghollisjr/hdfwork/test.h5") "/test"))
  (do-table (row-index *table*)
      ("x" "y")
    (format t "x: ~a, y: ~a~%" x y)))

(defun hdf-table-test ()
  (with-open-hdf-file (outfile "/home/ghollisjr/hdfwork/outfile.h5"
			       :direction :output
			       :if-exists :supersede)
    (let ((output-table (create-hdf-table outfile "/output-dataset"
                                        (zip (list "x" "y")
                                             (list :int :float))))
          (input-table
           (open-hdf-table-chain (list "/home/ghollisjr/hdfwork/test.h5") "/test")))
      ;;(open-hdf-table infile "/test")))
      (do-table (row-index input-table)
          ("x" "y")
        ;; (format t "~a ~a; ~a ~a~%"
        ;;         row-index (sqrt row-index)
        ;;         x y)
        
        (when (> row-index (hdf-table-chain-nrows input-table))
          (when (zerop (mod row-index 1000))
            (print row-index)))
        (when (<= 25 y 30)
          (table-push-fields output-table
            x
            y)))
      (table-close output-table)
      (table-close input-table))))

(defun hdf-typed-table-test ()
  (with-open-hdf-file (outfile "/home/ghollisjr/hdfwork/outfile.h5"
			       :direction :output
			       :if-exists :supersede)
    (let ((output-table (create-hdf-table outfile "/output-dataset"
					(zip (list "x" "y")
					     (list :int :float))))
	  (input-table
	   (open-hdf-table-chain (list "/home/ghollisjr/hdfwork/test.h5") "/test")))
      (do-table (row-index input-table)
	  ("x" "y")
	(when (<= 25 y 30)
	  (table-set-field output-table 'x x)
	  (table-set-field output-table 'y y)
	  (table-commit-row output-table)))
      (table-close output-table)
      (table-close input-table))))

(defun array-test ()
  (with-open-hdf-file (outfile "/home/ghollisjr/hdfwork/array.h5"
                               :direction :output
                               :if-exists :supersede
                               :if-does-not-exist :create)
    (let* ((table
            (create-hdf-table
             outfile "/array"
             (list (cons "x"
                         (list :array :float 1 (list 4))))))
           (x-type
            (typespec->cffi-type
             (first (typed-table-column-specs table)))))
      (loop
         for i below 30
         do (progn
              (table-push-fields table
                (x
                 (convert-to-foreign
                  (vector (float i) (sqrt (float i)) (float i)
                          (sqrt (float i)))
                  x-type)))))
    (table-close table))))
