(in-package logres)

;; For now, hash-tables are converted into alists, but in the future
;; it would be nice if all container objects would use their storage
;; file as an index, allowing e.g. lists of histograms to be stored
;; (histograms are stored via HDF5, not text files).

(defmethod save-target (lid (ht hash-table) path)
  (let ((savedir
         (make-pathname
          :directory (pathname-directory path))))

    (let ((index-alist nil))
      (loop
         for k being the hash-keys in ht
         for v being the hash-values in ht
         do (let ((kid (next-log-id))
                  (vid (next-log-id)))
              ;; log sublids:
              (symbol-macrolet ((sublids
                                 (gethash lid
                                          (gethash *project-id*
                                                   *proj->lid->sublids*))))
                (push kid
                      sublids)
                (push vid sublids))
              ;; save content:
              (push (cons (list kid (target-type k))
                          (list vid (target-type v)))
                    index-alist)
              (save-target kid
                           k
                           (merge-pathnames (mkstr kid)
                                            savedir))
              (save-target vid
                           v
                           (merge-pathnames (mkstr vid)
                                            savedir))))
      (with-open-file (file path
                            :direction :output
                            :if-exists :supersede
                            :if-does-not-exist :create)
        (format file "~s~%" (nreverse index-alist))
        (format file "~s~%" (hash-table-test ht))))))

(defmethod load-target ((type (eql 'hash-table)) path)
  (let ((loaddir
         (make-pathname
          :directory (pathname-directory path))))
    (let ((index-alist nil)
          (test nil))
      (with-open-file (file path
                            :direction :input
                            :if-does-not-exist :error)
        (setf index-alist (read file))
        (setf test (read file)))
      (map->hash-table
       (mapcar (lambda (cons)
                 (destructuring-bind ((kid ktype) . (vid vtype))
                     cons
                   (cons (load-target ktype
                                      (merge-pathnames
                                       (mkstr kid)
                                       loaddir))
                         (load-target vtype
                                      (merge-pathnames
                                       (mkstr vid)
                                       loaddir)))))
               index-alist)
       test))))
