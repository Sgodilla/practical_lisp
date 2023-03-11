; Property Lists
(defun make-cd (title artist rating ripped)
  (list :title title :artist artist :rating rating :ripped ripped))

;; Global Database
(defvar *db* nil)

;; Function to add CDs to global database
(defun add-record (cd) (push cd *db*))

;; Function to print database
(defun dump-db ()
  (dolist (cd *db*)
    (format t "~{~a:~10t~a~%~}~%" cd)))

;; Prompting user for input
(defun prompt-read (prompt)
  (format *query-io* "~a: " prompt)
  (force-output *query-io*)
  (read-line *query-io*))

;; Prompting user for CDs
(defun prompt-for-cd ()
  (make-cd
   (prompt-read "Title")
   (prompt-read "Artist")
   (or (parse-integer (prompt-read "Rating") :junk-allowed t) 0)
   (y-or-n-p "Ripped [y/n]")))

;; Contue asking for CDs in a loop
(defun add-cds ()
  (loop (add-record (prompt-for-cd))
	(if (not (y-or-n-p "Another? [y/n]: ")) (return))))

;; Saving CD database to a file
(defun save-db (filename)
  (with-open-file (out filename
		       :direction :output
		       :if-exists :supersede)
    (with-standard-io-syntax
      (print *db* out))))

;; Loading CD database from a file
(defun load-db (filename)
  (with-open-file (in filename)
    (with-standard-io-syntax
      (setf *db* (read in)))))

;; Querying for a particular artist
(defun select-by-artist (artist)
  (remove-if-not
   #'(lambda (cd) (equal (getf cd :artist) artist))
   *db*))

;; General purpose query function
(defun select (selector-fn)
  (remove-if-not selector-fn *db*))

;; Function to select an artist
(defun artist-selector (artist)
  #'(lambda (cd) (equal (getf cd :artist) artist)))

;; Macro to generate selection expression
(defun make-comparison-expr (field value)
  `(equal (getf cd ,field) ,value))

;; Macro to generate list of selector expressions
(defun make-comparisons-list (fields)
  (loop while fields
	collecting (make-comparison-expr (pop fields) (pop fields))))

;; General purpose selector generator macro
(defmacro where (&rest clauses)
  `#'(lambda (cd)
      (and ,@(make-comparisons-list clauses))))

;; Function to update existing records
(defun update (selector-fn &key title artist rating (ripped nil ripped-p))
  (setf *db*
	(mapcar
	 #'(lambda (row)
	     (when (funcall selector-fn row)
	        (if title    (setf (getf row :title) title))
		(if artist   (setf (getf row :artist) artist))
		(if rating   (setf (getf row :rating) rating))
		(if ripped-p (setf (getf row :ripped) ripped)))
	     row)
	 *db*)))

;; Function to delete existing records
(defun delete-rows (selector-fn)
  (setf *db* (remove-if selector-fn *db*)))
