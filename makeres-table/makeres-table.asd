;;;; makeres-table is a graph transformation for makeres
;;;; Copyright 2014 Gary Hollis
;;;; 
;;;; This file is part of makeres-table.
;;;; 
;;;; makeres-table is free software: you can redistribute it
;;;; and/or modify it under the terms of the GNU General Public
;;;; License as published by the Free Software Foundation, either
;;;; version 3 of the License, or (at your option) any later version.
;;;; 
;;;; makeres-table is distributed in the hope that it will be
;;;; useful, but WITHOUT ANY WARRANTY; without even the implied
;;;; warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
;;;; See the GNU General Public License for more details.
;;;; 
;;;; You should have received a copy of the GNU General Public License
;;;; along with makeres-table.  If not, see
;;;; <http://www.gnu.org/licenses/>.
;;;;
;;;; You may contact Gary Hollis via email at
;;;; ghollisjr@gmail.com

(defsystem #:makeres-table
  :serial t
  :author "Gary Hollis"
  :description "makeres-table is a graph transformation for makeres"
  :license "GPLv3"
  :depends-on (#:makeres
               #:makeres-macro)
  :components ((:file "package")
               (:file "smart-gensym")
               (:file "table-operators")
               (:file "tabletrans")
               (:file "openers")))
