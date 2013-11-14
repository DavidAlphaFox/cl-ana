;;;; csv-table.lisp

(in-package :csv-table)

(defclass csv-table (table)
  ((file
    :initarg :file
    :initform nil
    :accessor csv-table-file
    :documentation "The CSV file.")
   (delimeter
    :initarg :delimeter
    :initform #\,
    :accessor csv-table-delimeter
    :documentation "The delimeter denoting a new field; defaults to a
    comma.")
   (row
    :initarg :row
    :initform nil
    :accessor csv-table-row
    :documentation "hash table mapping column-symbols to values")
   (column-symbols
    :initarg :column-symbols
    :initform ()
    :accessor csv-table-column-symbols
    :documentation "Storing the lispified column symbols for
    efficiency.")))

(defun open-csv-table (filename &optional (delimeter #\,))
  "Open a CSV file to be read as a table.  Assumes that the first row
  consists of the column names and are separated by the delimeter."
  (let* ((file (open filename :direction :input))
	 (column-names
	  (first (read-csv (read-line file) :separator delimeter)))
	 (row (make-hash-table :test #'equal))
	 (table (make-instance 'csv-table
			       :column-names column-names
			       :file file
			       :delimeter delimeter
			       :row row)))
    (setf (csv-table-column-symbols table)
	  (table-column-symbols table))
    table))

;;; Reading methods:

(defmethod table-load-next-row ((table csv-table))
  (with-accessors ((file csv-table-file)
		   (column-symbols csv-table-column-symbols)
		   (delimeter csv-table-delimeter)
		   (row csv-table-row))
      table
    (let* ((line (read-line file nil nil))
	   (csv-data (when line
		       (mapcar #'read-from-string
			       (first (read-csv line :separator delimeter))))))
      (when line
	(iter (for s in column-symbols)
	      (for v in csv-data)
	      (setf (gethash s row) v))
	t))))

(defmethod table-get-field ((table csv-table) column-symbol)
  (with-accessors ((row csv-table-row))
      table
    (gethash column-symbol row)))

;;; Writing functions:

(defun make-csv-table (filename column-names &optional (delimeter #\,))
  "Creates a CSV file to be written to as a table."
  (let* ((file (open filename
		     :direction :output
		     :if-exists :supersede
		     :if-does-not-exist :create))
	 (row (make-hash-table :test #'equal))
	 (table (make-instance 'csv-table
			       :column-names column-names
			       :file file
			       :delimeter delimeter
			       :row row)))
    (setf (csv-table-column-symbols table)
	  (table-column-symbols table))
    (iter (for i upfrom 0)
	  (for n in column-names)
	  (when (not (= i 0))
	    (format file "~a" delimeter))
	  (format file "~a" n))
    (format file "~%")
    table))

(defmethod table-set-field ((table csv-table) column-symbol value)
  (with-accessors ((row csv-table-row))
      table
    (setf (gethash column-symbol row) value)))

(defmethod table-commit-row ((table csv-table))
  (with-accessors ((file csv-table-file)
		   (row csv-table-row)
		   (column-symbols csv-table-column-symbols)
		   (delimeter csv-table-delimeter))
      table
    (iter (for i upfrom 0)
	  (for (key value) in-hashtable row)
	  (when (not (= i 0))
	    (format file "~a" delimeter))
	  (format file "~a" value))
    (format file "~%")))

(defmethod table-close ((table csv-table))
  (with-accessors ((file csv-table-file))
      table
    (close file)))
