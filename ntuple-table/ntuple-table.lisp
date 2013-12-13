;;;; ntuple-table.lisp

(in-package :ntuple-table)

(defclass ntuple-table (typed-table)
  ((ntuple
    :initarg :ntuple
    :initform nil
    :accessor ntuple-table-ntuple
    :documentation "GSL handler for ntuple object")))

;;; Writing functions:

(defun create-ntuple-table (filename names-specs)
  "Creates an ntuple-table with file located at the path corresponding
to filename and names-specs being an alist mapping the column names to
their typespecs."
  (let* ((typespec (cons :compound names-specs))
	 (cstruct (typespec->cffi-type typespec))
	 (column-names (mapcar #'car names-specs))
	 (column-specs (mapcar #'cdr names-specs))
	 (row-pointer (typespec-foreign-alloc typespec)))
    (let ((ntuple (gsll:create-ntuple filename row-pointer cstruct)))
      (make-instance 'ntuple-table
		     :column-names column-names
		     :column-specs column-specs
		     :ntuple ntuple
		     :row-cstruct cstruct
		     :row-pointer row-pointer))))

;; (defmethod table-set-field ((table ntuple-table) column-symbol value)
;;   (with-accessors ((row typed-table-row-pointer)
;; 		   (cstruct ntuple-table-cstruct))
;;       table
;;     (setf
;;      (foreign-slot-value row
;; 			 cstruct
;; 			 column-symbol)
;;      value)))

(defmethod table-commit-row ((table ntuple-table))
  (with-accessors ((row typed-table-row-pointer)
		   (ntuple ntuple-table-ntuple))
      table
    (gsll:write-ntuple ntuple)))

;;; Reading functions:

(defun open-ntuple-table (filename names-specs)
  "Opens a pre-existing ntuple data file.  Must already know the
typespecs of each of the column types (and names); this is a
limitation of the ntuple file format itself."
  (let* ((typespec (cons :compound names-specs))
	 (cstruct (typespec->cffi-type typespec))
	 (column-names (mapcar #'car names-specs))
	 (column-specs (mapcar #'cdr names-specs))
	 (row (typespec-foreign-alloc typespec)))
    (let ((ntuple (gsll:open-ntuple filename row cstruct)))
      (make-instance 'ntuple-table
		     :column-names column-names
		     :column-specs column-specs
		     :ntuple ntuple
		     :row-cstruct cstruct
		     :row-pointer row))))

(defmethod table-load-next-row ((table ntuple-table))
  (with-accessors ((ntuple ntuple-table-ntuple))
      table
    (let ((read-status (gsl-cffi:gsl-ntuple-read ntuple)))
      (not (equal read-status gsl-cffi:+GSL-EOF+)))))

;; (defmethod table-get-field ((table ntuple-table) column-symbol)
;;   (with-accessors ((row typed-table-row-pointer)
;; 		   (cstruct ntuple-table-cstruct))
;;       table
;;     (foreign-slot-value row
;; 			cstruct
;; 			column-symbol)))

;;; Cleanup:

(defmethod table-close ((table ntuple-table))
  (with-accessors ((ntuple ntuple-table-ntuple)
		   (row typed-table-row-pointer))
      table
    (gsll:close-ntuple ntuple)
    (foreign-free row)))
