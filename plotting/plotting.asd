;;;; plotting.asd

(asdf:defsystem #:plotting
  :serial t
  :description "Table subclass specializing on hdf5 data"
  :author "Gary Hollis"
  :license ""
  :depends-on (#:generic-math
               #:error-propogation
               #:gnuplot-i-cffi
               #:map
               #:string-utils
               #:list-utils
               #:histogram
               #:tensor)
  :components ((:file "package")
	       (:file "plotting")))
