;;;; package.lisp

(defpackage #:hdf-cffi 
  (:use :cl :cffi)
  (:export
   ;; hdf data types:
   :size-t
   :hid-t
   :herr-t
   :hsize-t
   :hssize-t
   ;;enums:
   :h5t-class-t
   :H5T-NO-CLASS
   :H5T-INTEGER
   :H5T-FLOAT
   :H5T-TIME
   :H5T-STRING
   :H5T-BITFIELD
   :H5T-OPAQUE
   :H5T-COMPOUND
   :H5T-REFERENCE
   :H5T-ENUM
   :H5T-VLEN
   :H5T-ARRAY
   :h5t-direction-t
   :H5T-DIR-DEFAULT
   :H5T-DIR-ASCEND
   :H5T-DIR-DESCEND
   :h5s-seloper-t
   :H5S-SELECT-NOOP
   :H5S-SELECT-SET
   ;; constants:
   :+H5S-UNLIMITED+
   :+H5S-ALL+
   :+H5F-ACC-TRUNC+
   :+H5F-ACC-RDONLY+
   :+H5P-DEFAULT+
   :+H5P-DATASET-CREATE+
   ;; H5T type constants:
   :+H5T-NATIVE-CHAR+
   :+H5T-NATIVE-UCHAR+
   :+H5T-NATIVE-SHORT+
   :+H5T-NATIVE-USHORT+
   :+H5T-NATIVE-INT+
   :+H5T-NATIVE-UINT+
   :+H5T-NATIVE-LONG+
   :+H5T-NATIVE-ULONG+
   :+H5T-NATIVE-LLONG+
   :+H5T-NATIVE-ULLONG+
   :+H5T-NATIVE-FLOAT+
   :+H5T-NATIVE-DOUBLE+
   :+H5T-COMPOUND+
   :+H5T-NATIVE-CHAR+
   :+H5T-NATIVE-FLOAT+
   :+H5T-NATIVE-INT+
   :+H5T-NATIVE-SHORT+
   :+H5T-NATIVE-UCHAR+
   :+H5T-NATIVE-USHORT+
   :+H5T-COMPOUND+
   ;; hdf-cffi interface utilities:
   :*hdf-cffi-type-map*
   :cffi-native-type
   :hdf-native-type
   ;; hdf functions:
   :h5fcreate
   :h5fopen
   :h5pcreate
   :h5pset-chunk
   :h5pset-deflate
   :h5pget-chunk
   :h5tarray-create2
   :h5tcreate
   :h5tclose
   :h5tinsert
   :h5dcreate1
   :h5dopen2
   :h5dclose
   :h5dwrite
   :h5dread
   :h5dget-space
   :h5dget-type
   :h5dget-create-plist
   :h5dset-extent
   :h5fclose
   :h5screate-simple
   :h5sclose
   :h5sselect-hyperslab
   :h5sget-simple-extent-ndims
   :h5sget-simple-extent-dims
   :h5tget-class
   :h5tget-super
   :h5tget-native-type
   :h5tget-size
   :h5tget-array-ndims
   :h5tget-array-dims2
   :h5tget-nmembers
   :h5tget-member-type
   :h5tget-member-name
   :h5tget-member-offset
   :h5tequal
   ;; Group functions:
   h5gcreate2
   h5gcreate1
   h5gclose))
