(in-package :makeres)

(declaim (optimize (debug 3)))

;;;; makeres is a make-like tool for generating your analysis, i.e. it
;;;; uses a dependency graph to determine what to do in order to
;;;; generate any/all results you desire.  Why couldn't you just use
;;;; GNU make?  Well because for any non trivial work, you'll have to
;;;; specify a bit of how to do what you want, and furthermore since
;;;; the target is von Neumann architecture computers, you'll have to
;;;; provide some optimizations if you want to do things
;;;; declaratively and efficiently.
;;;;
;;;; makeres bridges the gap by allowing you to specify any number of
;;;; graph transformations to put in between the initial dependency
;;;; graph specification and the final
;;;; ready-for-literal-interpretation dependency graph.
;;;;
;;;; My initial (and still rather exemplary) usage concept was for
;;;; analyzing particle physics data.  This consisted of making
;;;; multiple passes over semilarge datasets, collecting various
;;;; results along the way.  The approach almost everyone uses
;;;; starting out is to
;;;;
;;;; * Do everything in a single pass over the entire dataset
;;;;
;;;; But this fails once you need information from the initial pass to
;;;; do something like filtering: you need a second pass.
;;;;
;;;; So this procedure results in either numbering your passes to keep
;;;; track of how many you have or trying to come up with memorable
;;;; names for each pass.  (If you want to get fancy, you can call it
;;;; a pipeline.)
;;;;
;;;; My work had escalated to the point of combining the two
;;;; approaches, having names with numerical suffixes denoting various
;;;; stages of the analysis, but always wondering if the distinctions
;;;; were really necessary.  I had formalized this system to a degree
;;;; that made me think a computer should be doing the work.
;;;;
;;;; Probably due to my experience with make, I found that viewing the
;;;; problem as a series of targets and dependencies made much more
;;;; sense than trying to keep up with passes over data.  I tried many
;;;; approaches in my head before settling on makeres.

;; computations for a graph with different parameters are placed in
;; the same graph.  Provide functions for copying graph to a new
;; graph-id to allow storage of different results.

;; makeres is separate from urd (universal result database), analysis
;; package will be built on top of makeres and urd (universal result
;; database)

;;;; May have found a way to implement optimizations: Graph
;;;; transformations.  Instead of using the same dependency graph for
;;;; the entire process, pass graph to transformers which generate new
;;;; graphs.
;;;;
;;;; This pipeline of graphs should culminate in a final graph (the
;;;; temp graph) which has all the initially specified nodes as well
;;;; as any additional nodes required for efficiency; the structure
;;;; can be changed arbitrarily however, and the only requirement is
;;;; that the initial nodes are present.  The computation function
;;;; responsible for making the result will be generated from this
;;;; final dependency graph, and initial results will be collected
;;;; from the temporary graph and stored in the final result graph
;;;; which has the original structure.
;;;;
;;;; E.g., for table reductions, could create nodes which represent
;;;; all immediate dependencies of a table node (node id could be a
;;;; list containing all table dependency ids for a given table).  The
;;;; expression form would then be a loop which at the end returns a
;;;; list of the results needed from the table.
;;;;
;;;; This seems general enough for just about any
;;;; computation/optimization combination for which one would use a
;;;; dependency graph.
;;;;
;;;; There is one concern about recovering from errors.  As written,
;;;; the algorithm is: Generate temp graph -> Compute temp graph
;;;; results -> Copy final results from temp graph.  But, if any nodes
;;;; in the temp graph fail, then the final results may not be copied
;;;; properly.  This could be alleviated by providing a handler with
;;;; an option to copy completed results to the final graph.  This
;;;; would mean that the handler expression would need access to the
;;;; temp graph object, but seems doable.

(eval-when (:compile-toplevel :load-toplevel :execute)
  ;; structure containing target information
  (defclass target ()
    ((id
      :accessor target-id
      :initarg :id
      :documentation "Identification")
     (expr
      :accessor target-expr
      :initarg :expr
      :documentation "Expression for computing")
     (deps
      :accessor target-deps
      :initarg :deps
      :documentation "list of target ids which are needed prior")
     (pdeps
      :accessor target-pdeps
      :initarg :pdeps
      :documentation "list of explicit parameter dependencies")
     (val
      :accessor target-val
      :initarg :val
      :initform nil
      :documentation "computation value, nil when needs computing,
      return value whenever computed")
     (stat
      :accessor target-stat
      :initarg :stat
      :initform nil
      :documentation "computation status, nil when needs computing, t
      otherwise")))

  (defmethod print-object ((tar target) stream)
    (format stream "~S"
            (copy-list
             `(target
               :id ,(target-id tar)
               :expr ,(target-expr tar)
               :deps ,(target-deps tar)
               :pdeps ,(target-pdeps tar)
               :val ,(target-val tar)
               :stat ,(target-stat tar)))))

  (defun find-dependencies (expr token)
    "Descends through expr, finding any forms of the form (token x)
which is then interpreted as a dependency on x (token must be a
symbol)"
    (let ((deps
           (make-hash-table :test 'equal)))
      (flet ((actual-listp (x)
               (and (listp x)
                    (listp (cdr (last x))))))
        (labels ((rec (ex)
                   ;; check for
                   (when (actual-listp ex)
                     (if (and (length-equal ex 2)
                              (eq (first ex)
                                  token))
                         (setf (gethash (second ex)
                                        deps)
                               t)
                         (mapcar #'rec ex)))))
          (rec expr)
          (hash-keys deps)))))

  (defun make-target (id expr &key
                                val
                                stat)
    (let ((deps (find-dependencies expr 'res))
          (pdeps (find-dependencies expr 'par)))
      (make-instance 'target
                     :id id
                     :expr expr
                     :deps (remove-if (lambda (d)
                                        (equal d id))
                                      deps)
                     :pdeps pdeps
                     :val val
                     :stat stat)))

  (defun copy-target (target)
    (make-instance 'target
                   :id (copy-tree (target-id target))
                   :expr (copy-tree (target-expr target))
                   :deps (copy-tree (target-deps target))
                   :pdeps (copy-tree (target-pdeps target))
                   :val (copy-tree (target-val target))
                   :stat (copy-tree (target-stat target))))

  (defparameter *makeres-propogate* t
    "Set to nil if you don't want dependents of uncomputed results to
have their statuses set to nil")

  (defvar *compiled-generators*
    (make-hash-table :test 'equal)
    "Maps from project id to a gensym used for the compiled function
name generated by compres.")

  ;; (defvar *symbol-tables*
  ;;   (make-hash-table :test 'equal)
  ;;   "Maps from project id to symbol-table for that project")

  (defvar *target-tables*
    (make-hash-table :test 'equal))

  (defvar *fin-target-tables*
    (make-hash-table :test 'equal))

  (defvar *project-id* nil)

  (defvar *transformation-table*
    (make-hash-table :test 'equal))

  (defvar *params-table*
    (make-hash-table :test 'equal))

  (defvar *args-tables*
    (make-hash-table :test 'equal))

  (defvar *makeres-args*
    (make-hash-table :test 'equal)
    "Map from arg symbol to supplied or default value at makeres
    execution")

  (defun compres-fname (&optional project-id)
    "Returns gensym for project used for compres"
    (symbol-macrolet ((gsym (gethash project-id *compiled-generators*)))
      (if gsym
          gsym
          (setf gsym (gensym)))))

  (defun project ()
    "Returns current project"
    *project-id*)

  ;; (defun symbol-table (&optional (project-id *project-id*))
  ;;   "Returns symboltable identified by id; defaults to current graph"
  ;;   (gethash project-id *symbol-tables*))

  (defun target-table (&optional (project-id *project-id*))
    (gethash project-id *target-tables*))

  (defun copy-target-table (target-table)
    "Returns a new hash-table object with copies of each target from
target-table."
    (let ((result (make-hash-table :test 'equal)))
      (loop
         for id being the hash-keys in target-table
         for tar being the hash-values in target-table
         do (setf (gethash id result)
                  (copy-target tar)))
      result))

  ;; makeres utilities:
  (defun pipe-functions (fns input)
    "Evaluates each function in fns given input either from the
  initial input or from the output of the previous function in the
  list fns"
    (let ((val (alexandria:copy-hash-table input)))
      (dolist (f fns)
        (setf val (funcall f val)))
      val))

  ;; Major function: res-dependencies
  ;;
  ;; returns full list of dependencies on a target
  (defun res-dependents (res-id target-table)
    "Returns full list of parameter-dependent targets in target-table"
    (let* (;; table mapping from id to those targets immediately
           ;; dependent on id
           (dependent-table
            (make-hash-table :test 'equal))
           (explicit-deps
            (loop
               for id being the hash-keys in target-table
               for tar being the hash-values in target-table
               when (member res-id (target-deps tar)
                            :test #'equal)
               collecting id))
           (deps nil))
      ;; fill dependent-table
      (loop
         for id being the hash-keys in target-table
         for target being the hash-values in target-table
         do
           (loop
              for d in (target-deps target)
              do (push id
                       (gethash d dependent-table))))
      ;; collect all dependents of explicit-deps and insert into deps
      (labels ((rec (id)
                 (setf deps
                       (adjoin id deps
                               :test #'equal))
                 (mapcar #'rec (gethash id dependent-table))))
        (mapcar #'rec explicit-deps)
        deps)))

  ;; Major function: dep<
  ;;
  ;; this uses lists for sets, inefficient for large dependency
  ;; graphs, so it needs to be updated in the future

  (defun dep< (target-table)
    "Returns comparison function from target-table which returns true
when the left argument does not depend on the right argument."
    (let ((depmap (make-hash-table :test 'equal)))
      (labels ((rec (id)
                 ;; returns full list of dependencies for id
                 (let ((tar (gethash id target-table)))
                   (when tar
                     (let ((deps (copy-list (target-deps tar))))
                       (when deps
                         (reduce (lambda (ds d)
                                   (adjoin d ds :test #'equal))
                                 (mapcan #'rec deps)
                                 :initial-value deps)))))))
        (loop
           for id being the hash-keys in target-table
           do (setf (gethash id depmap)
                    (rec id)))
        (lambda (x y)
          (not (member y (gethash x depmap)
                       :test #'equal))))))

  ;; depsort-graph functions:

  (defun last-dep (x lst dep<)
    "Returns last dependency of x found in lst and t; if no
dependencies are found then returns two nil values"
    (let ((res
           (remove-if (lambda (d)
                        (funcall dep< x d))
                      lst)))
      (if res
          (values (first (last res))
                  t)
          (values nil nil))))

  (defun insert-after! (insertion lst token)
    "Inserts insertion into list immediately following the first
element #'equal to token."
    (if (null lst)
        (push insertion lst)
        (if (equal (first lst) token)
            (setf (cdr lst)
                  (cons insertion
                        (cdr lst)))
            (insert-after! insertion (cdr lst) token))))

  (defun depsort (ids dep<)
    "Sorts a list of values given dependency comparison function dep<;
special algorithm since sort needs transitive operator while dep< is
not transitive in general."
    (let ((result nil))
      (loop
         for i in ids
         do (multiple-value-bind (last-dep any)
                (last-dep i result dep<)
              (if any
                  (insert-after! i result last-dep)
                  (push i result))))
      result))

  (defun depsort-graph (target-table &optional dep<)
    "Returns dependency-sorted target ids from target-table, if dep<
is provided then it is used instead of the dep< computed from the
target-table."
    (let ((dep< (if dep<
                    dep<
                    (dep< target-table))))
      (depsort (hash-keys target-table)
               dep<)))

  ;; Major function: param-dependents
  ;;
  ;; finds full list of targets which depend on parameter and returns
  ;; list of ids
  (defun param-dependents (parameter target-table)
    "Returns full list of parameter-dependent targets in target-table"
    (let* (;; table mapping from id to those targets immediately
           ;; dependent on id
           (dependent-table
            (make-hash-table :test 'equal))
           (explicit-deps
            (loop
               for id being the hash-keys in target-table
               for tar being the hash-values in target-table
               when (member parameter (target-pdeps tar)
                            :test #'equal)
               collecting id))
           (deps nil))
      ;; fill dependent-table
      (loop
         for id being the hash-keys in target-table
         for target being the hash-values in target-table
         do
           (loop
              for d in (target-deps target)
              do (push id
                       (gethash d dependent-table))))
      ;; collect all dependents of explicit-deps and insert into deps
      (labels ((rec (id)
                 (setf deps
                       (adjoin id deps
                               :test #'equal))
                 (mapcar #'rec (gethash id dependent-table))))
        (mapcar #'rec explicit-deps)
        deps))))

;; (defmacro res (id &optional (project-id *project-id*))
;;   "Expands to whatever the symbol for id in project identified by
;; project-id is, nil if id or project not specified."
;;   (awhen (symbol-table project-id)
;;     (awhen (gethash id it)
;;       it)))

(defmacro res (id)
  "Expands to whatever the symbol for id in project identified by
project-id is, nil if id or project not specified."
  `(progn
     (target-val
      (gethash ',id
               (gethash (project)
                        *target-tables*)))))

(defun resfn (id &optional (project-id *project-id*))
  (target-val
   (gethash id
            (gethash project-id
                     *target-tables*))))

(defmacro par (id)
  "Outside of generating function, returns the last used value of a
parameter.  Inside, expands to whatever the current parameter value
is."
  `(values
    (gethash ',id
             (gethash *project-id* *args-tables*))))

(defun parfn (id)
  (values (gethash id (gethash *project-id* *args-tables*))))

(defmacro in-project (project-id)
  "Selects graph identified by graph-id for use.  Graph does not need
initialization, will be initialized automatically if necessary."
  `(progn
     ;; select graph
     (setf *project-id* ',project-id)
     ;; initialize target table
     (when (not (gethash ',project-id *target-tables*))
       (setf (gethash ',project-id *target-tables*)
             (make-hash-table :test 'equal)))
     ;; initialize final target table
     (when (not (gethash ',project-id *fin-target-tables*))
       (setf (gethash ',project-id *fin-target-tables*)
             (make-hash-table :test 'equal)))
     ',project-id))

(defmacro defpars (params)
  "Adds parameters to project, updating default values for existing
parameters."
  (alexandria:with-gensyms (result ps)
    `(let* ((,ps ',params)
            (,result
             (set-difference (gethash *project-id* *params-table*)
                             ,ps
                             :key (lambda (x)
                                    (if (listp x)
                                        (first x)
                                        x)))))
       (loop for p in ,ps
          do
            (push p ,result))
       (setf (gethash *project-id* *params-table*)
             ,result)
       nil)))

(defmacro undefpars (&rest params)
  "Undefines parameters in params from project"
  (alexandria:with-gensyms (ps)
    `(let ((,ps ',params))
       (setf (gethash *project-id* *params-table*)
             (remove-if (lambda (p)
                          (member p ,ps
                                  :test #'equal))
                        (gethash *project-id* *params-table*))))))

(defmacro defres (id &body body)
  "Defines a result target with id and value expression `(progn ,@body)."
  ;; establish symbol mapping
  (alexandria:with-gensyms (tartab oldtar val stat)
    `(let* ((,tartab (target-table *project-id*))
            (,oldtar (gethash ',id ,tartab))
            (,val (if ,oldtar
                      (target-val ,oldtar)
                      nil))
            ;; statuses are reset
            (,stat nil))
       (setf (gethash ',id ,tartab)
             (make-target ',id `(progn ,@',body)
                          :val ,val
                          :stat ,stat))
       ',id)))

(defmacro undefres (res)
  "Undefines a result target"
  `(progn
     (remhash ',res
              (gethash *project-id* *target-tables*))
     (remhash ',res
              (gethash *project-id* *fin-target-tables*))
     nil))

(defun setresfn (id value)
  "Function version of setres"
  ;; *target-tables*:
  (setf (target-stat
         (gethash id
                  (gethash *project-id* *target-tables*)))
        t)
  (setf (target-val
         (gethash id
                  (gethash *project-id* *target-tables*)))
        value)
  ;; *fin-target-tables*:
  (when (gethash id
                 (gethash *project-id* *fin-target-tables*))
    (setf (target-stat
           (gethash id
                    (gethash *project-id* *fin-target-tables*)))
          t)
    (setf (target-val
           (gethash id
                    (gethash *project-id* *fin-target-tables*)))
          value)))

(defmacro setres (id value)
  "Sets target value of id in project to value and the status to t so
it will not be recomputed."
  `(setresfn ',id ,value))

(defun unsetresfn (id)
  "Function version of unsetres"
  (setf (target-stat
         (gethash id
                  (gethash *project-id* *target-tables*)))
        nil)
  (when (gethash id
                 (gethash *project-id* *fin-target-tables*))
    (setf (target-stat
           (gethash id
                    (gethash *project-id* *fin-target-tables*)))
          nil)))

(defmacro unsetres (id)
  "Sets status of target to nil, will be recomputed."
  `(unsetresfn ',id))

(defun clrresfn ()
  "Function version of clrres"
  (let ((tartab (gethash *project-id* *target-tables*))
        (fintab (gethash *project-id* *fin-target-tables*)))
    (loop
       for k being the hash-keys in tartab
       do (setf (target-stat (gethash k tartab))
                nil))
    (loop
       for k being the hash-keys in fintab
       do (setf (target-stat (gethash k fintab))
                nil))))

(defmacro clrres ()
  "Clears all status for result targets in current project"
  `(clrresfn))

(defun settrans (transforms &key
                              (op :add))
  "Takes each transformation function in list transforms (should be
names of functions available at compile & load times) and depending on
op does something to the project referred to by project-id.

transforms will not be evaluated and should be a list form containing
the transform functions.

op can be :set or :add for setting the entire list of transforms or
adding to the front of the transform list.  (Front-adding seemed more
reasonable since this allows languages to be built on top of previous
layers.)

Each transformation is a function taking a target table and returning
a new target table.  The only constraint is that the initial targets
be present in the output table.

Returns full transformation list from project after applying op."
  (let ((pid (project)))
    (case op
      (:add
       (setf (gethash pid *transformation-table*)
             (append transforms
                     (gethash pid *transformation-table*))))
      (:set
       (setf (gethash pid *transformation-table*)
             transforms)))
    (gethash pid *transformation-table*)))

(defun compres (&optional (project-id *project-id*))
  "Returns a compiled function which will generate result targets
given keyword arguments for each project parameter.  If default values
of parameters are specified, these will be used when no explicit value
is given."
  (let ((fintab
         (let ((fns
                (gethash project-id *transformation-table*))
               (input (copy-target-table
                       (gethash project-id *target-tables*))))
           (if fns
               (pipe-functions fns input)
               input))))
    ;; Update fintab:
    (setf (gethash project-id *fin-target-tables*)
          fintab)
    ;; ensure symbols are defined for fintab
    (alexandria:with-gensyms (val)
      (let* ((sorted-ids
              (depsort-graph fintab))
             (set-exprs
              (loop
                 for id in sorted-ids
                 when (not (target-stat
                            (gethash id
                                     (gethash project-id
                                              *fin-target-tables*))))
                 collecting
                   (let ((tar (gethash id fintab)))
                     `(let ((,val
                             ,(target-expr tar)))
                        (setf (target-stat
                               (gethash ',id
                                        (gethash ',project-id
                                                 *fin-target-tables*)))
                              t)
                        (setf (target-val
                               (gethash ',id
                                        (gethash ',project-id
                                                 *fin-target-tables*)))
                              ,val)
                        (when (gethash ',id
                                       (gethash ',project-id
                                                *target-tables*))
                          (setf (target-stat
                                 (gethash ',id
                                          (gethash ',project-id
                                                   *target-tables*)))
                                t)
                          (setf
                           (target-val
                            (gethash ',id
                                     (gethash (project)
                                              *target-tables*)))
                           ;;(res ,id)
                           ,val))))))
             (lambda-list (gethash project-id *params-table*))
             (params (mapcar (lambda (x)
                               (first (mklist x)))
                             lambda-list))
             (tartab (gethash project-id *target-tables*))
             (argmap (progn
                       (when (not (gethash project-id *args-tables*))
                         (setf (gethash project-id *args-tables*)
                               (make-hash-table :test 'equal)))
                       `(gethash ',project-id *args-tables*)))
             (body
              `(progn
                 ;; Set target statuses to nil which need updating due
                 ;; to new parameter values
                 ,@(loop
                      for p in params
                      appending
                        `((when (not (equal ,p
                                            (gethash ',p ,argmap)))
                            (setf (gethash ',p ,argmap)
                                  ,p)
                            ,@(loop
                                 for pdep in (param-dependents p fintab)
                                 appending
                                   `((when (target-stat (gethash
                                                         ',pdep
                                                         (gethash ',project-id
                                                                  *fin-target-tables*)))
                                       (setf
                                        (target-stat
                                         (gethash ',pdep
                                                  (gethash
                                                   ',project-id
                                                   *fin-target-tables*)))
                                        nil))
                                     (when (and (gethash ',pdep
                                                         ,tartab)
                                                (target-stat
                                                 (gethash ',pdep
                                                          (gethash (project)
                                                                   *target-tables*))))
                                       (setf (target-stat
                                              (gethash ',pdep
                                                       (gethash (project)
                                                                *target-tables*)))
                                             nil)))))))

                 ;; execute computations for targets which need
                 ;; updating.
                 ,@set-exprs
                 nil))
             (comp-form
              `(lambda (&key ,@lambda-list)
                 (macrolet ((par (id)
                              id))
                   ,body))))
        (symbol-function
         (compile (compres-fname project-id) comp-form))))))

(defun makeres (&rest args)
  "Function which compiles and executes generating function given args.
Treat args as if they will be evaluated."
  (when (not (gethash *project-id* *makeres-args*))
    (setf (gethash *project-id* *makeres-args*)
          (make-hash-table :test 'eq)))
  ;; unset any results dependent on new parameter values
  (let ((params
         (gethash *project-id* *params-table*)))
    (loop
       for p in params
       do (let* ((psym (first (mklist p)))
                 (val (let ((res (getf args (keywordify psym))))
                        (if res
                            res
                            (second
                             (mklist
                              (find psym params
                                    :key (lambda (x)
                                           (if (listp x)
                                               (first x)
                                               x))))))))
                 (oldval (gethash psym
                                  (gethash *project-id* *makeres-args*))))
            (when (not (equal val oldval))
              (setf (gethash psym
                             (gethash *project-id* *makeres-args*))
                    val)
              (let ((pdeps (param-dependents
                            psym
                            (gethash *project-id*
                                     *target-tables*))))
                (loop
                   for pdep in pdeps
                   do
                     (progn
                       (unsetresfn pdep))))))))
  ;; Whenever *makeres-propogate* is non-nil, unset any results
  ;; dependent on null-stat results
  (when *makeres-propogate*
    (loop
       for id being the hash-keys in (gethash *project-id*
                                              *target-tables*)
       for tar being the hash-values in (gethash *project-id*
                                                 *target-tables*)
       do (when (null (target-stat tar))
            (loop
               for r in (res-dependents id (gethash *project-id*
                                                    *target-tables*))
               do (unsetresfn r)))))

  (let ((comp (compres)))
    (apply comp args)))

;;;; Utilities:

(defun target-ids ()
  "Returns list of ids for defined targets in project"
  (hash-keys (gethash *project-id* *target-tables*)))

(defun fin-target-ids ()
  "Returns list of ids for defined targets in final target table."
  (hash-keys (gethash *project-id* *fin-target-tables*)))

;; Could create print representation of targets, that way there could
;; just be targets and fin-targets as functions which would return all
;; project targets and final target table targets.
