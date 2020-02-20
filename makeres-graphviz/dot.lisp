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

(in-package :cl-ana.makeres-graphviz)

(defun dot-compile (path &key
                           (if-exists :error)
                           (target-table (target-table))
                           posts)
  "Writes target graph into a file located at path.  Returns path of
dot output file.  posts is a list of lines to append to the end of the
dot commands without semicolons."
  (let ((*print-pretty* nil))
    (ensure-directories-exist path)
    (with-open-file (file path
                          :direction :output
                          :if-does-not-exist :create
                          :if-exists if-exists)
      (format file "digraph \"~a\" {~%"
              (project))
      (loop
         for id being the hash-keys in target-table
         for tar being the hash-values in target-table
         do (let ((deps (target-deps tar)))
              (loop
                 for d in deps
                 do (format file "  \"~a\" -> \"~a\";~%"
                            d id))))
      (loop
         for p in posts
         do (format file "~a;~%" p))
      (format file "}~%")
      path)))

(defun dot->ps (from-path to-path
                &key
                  ;; can be one of
                  ;;
                  ;; :dot (normal)
                  ;; :neato
                  ;; :twopi
                  ;; :circo
                  ;; :fdp
                  ;; :sfdp
                  ;; :patchwork
                  ;; :osage
                  (type :dot))
  "Runs dot command to convert dot code in from-path to a ps file at
to-path"
  (let* ((types
          (list
           :dot
           :neato
           :twopi
           :circo
           :fdp
           :sfdp
           :patchwork
           :osage)))
    (when (member type types)
      (run (string-downcase (string type))
           (list from-path
                 "-Tps"
                 "-o"
                 to-path)))))

(defun dot->png (from-path to-path
                 &key
                   ;; can be one of
                   ;;
                   ;; :dot (normal)
                   ;; :neato
                   ;; :twopi
                   ;; :circo
                   ;; :fdp
                   ;; :sfdp
                   ;; :patchwork
                   ;; :osage
                   (type :dot))
  "Runs dot command to convert dot code in from-path to a png file at
to-path"
  (let* ((types
          (list
           :dot
           :neato
           :twopi
           :circo
           :fdp
           :sfdp
           :patchwork
           :osage)))
    (when (member type types)
      (run (string-downcase (string type))
           (list from-path
                 "-Tpng"
                 "-o"
                 to-path)))))

(defun dot->pdf (from-path to-path
                 &key
                   ;; can be one of
                   ;;
                   ;; :dot (normal)
                   ;; :neato
                   ;; :twopi
                   ;; :circo
                   ;; :fdp
                   ;; :sfdp
                   ;; :patchwork
                   ;; :osage
                   (type :dot))
  "Runs dot command to convert dot code in from-path to a pdf file at
to-path"
  (let* ((types
          (list
           :dot
           :neato
           :twopi
           :circo
           :fdp
           :sfdp
           :patchwork
           :osage)))
    (when (member type types)
      (run (string-downcase (string type))
           (list from-path
                 "-Tpdf"
                 "-o"
                 to-path)))))
