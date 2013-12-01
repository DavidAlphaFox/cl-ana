(require 'plotting)

(require 'alexandria)

(in-package :plotting)

;; Long example of how to use raw types for structure:
(defparameter *page*
  (make-instance
   'page
   :title "Just a couple plots"
   :layout (cons 1 2)
   :dimensions (cons 1300 600)
   :scale (cons 1 1)
   :plots
   (list (make-instance
          'plot2d
          :title "Plot 1"
          :x-range (cons -1 1)
          :y-range (cons -2 2)
          :lines
          (list (make-instance
                 'analytic-line
                 :title "Sine function"
                 :fn-string "sin(x)"
                 :color "blue")
                (make-instance
                 'analytic-line
                 :title "Cosine function"
                 :fn-string "cos(x)")))
         (make-instance
          'plot2d
          :title "Plot 2"
          :lines
          (list (make-instance
                 'data-line
                 :title "Some data"
                 :style "points"
                 :data (list (cons 1 1)
                             (cons 2 2)
                             (cons 3 3)
                             (cons 4 4))))))))

;; Quick example of how to draw a single plot with a function and some
;; data:
(defparameter *quick-page*
  (quick-multidraw (list (list (zip (list 1 2 3)
                                    (list 1 2 3))
                               :title "test data")
                         (list "sin(x)" :title "sine"))
                   :page-title "Test plot"
                   :plot-title "Test plot"))

(defparameter *hist2d*
  (make-contiguous-hist
   (list (list :name "x" :nbins 100 :low -3d0 :high 3d0)
         (list :name "y" :nbins 100 :low -3d0 :high 3d0))))

(defun gaus () (alexandria:gaussian-random -3d0 3d0))

(loop for i below 100000 do (hist-insert *hist2d* (list (gaus) (gaus))))

(quick-draw *hist2d*)

(defparameter *hist1d*
  (hist-project *hist2d* "x")) 

(quick-draw *hist1d* :title "histogram")
