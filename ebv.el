;;; ebv.el --- Emacs ebook viewer

;; Author: Liubin
;; Keywords: ebook

;; Copyright 2009 , Liubin
;;
;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 2, or (at your option)
;; any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program; if not, write to the Free Software
;; Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA
;; 02110-1301, USA.

;;; Commentary:

;; A book search and view client.
;; 

;;; Your should add the following to your Emacs configuration file:

;;; Code:
(eval-when-compile (require 'cl))
(require 'url)
(require 'url-http)
(require 'xml)

(require 'parse-time)

(when (> 22 emacs-major-version)
  (setq load-path
        (append (mapcar (lambda (dir)
                          (expand-file-name
                           dir
                           (if load-file-name
                               (or (file-name-directory load-file-name)
                                   ".")
                             ".")))
                        '("url-emacs21" "emacs21"))
                load-path))
  (and (require 'un-define nil t)
       ;; the explicitly require 'unicode to update a workaround with
       ;; navi2ch.
       (require 'unicode nil t)))
(require 'url)

(defconst ebv-version "HEAD")

(defun ebv-version ()
  "Display a message for ebv version."
  (interactive)
  (let ((version-string
         (format "ebv-v%s" ebv-version)))
    (if (interactive-p)
        (message "%s" version-string)
      version-string)))

(defvar ebv-dir "~/.emacs.d/ebv"
  "The directory of ebv books")

(defvar ebv-view-books t
  "whether display books window")

(defvar ebv-view-index t
  "whether display index windows")

(defvar ebv-scroll-speed 30
  "ebv scroll book speed")

(defvar ebv-display-font-size 150
  "Percent of the display font size")

(defgroup ebv nil "Emacs ebook viewer"
  :group 'applications)

(defgroup ebv-faces nil "Faces for displaying ebv"
  :group 'ebv)

(defface ebv-title-face
  '((t (:background "light gray")))
  "base face for title"
  :group 'title-faces)

(defcustom ebv-auto-remove-blank nil
  "是否自动去除空行."
  :type 'boolean
  :group 'ebv)

(defcustom ebv-revert-filter nil
  "是否对过滤的敏感词进行恢复"
  :type 'boolean
  :group 'ebv)

(defvar ebv-revert-filter-list
  '(("十**岁" . "十八九岁")
    ("zf" . "政府")
    ("fzf" . "反政府")
    )
  "The map of revert filter list.


(defconst twitter-web-status-format
  (concat (propertize "%u"
                      'face 'twitter-user-name-face)
          " %M\n"
          (propertize "%t from %s"
                      'face 'twitter-time-stamp-face)
          "\n\n")
  "A status format to appear more like the twitter website.
This can be set as the value for twitter-status-format to make it
display the tweets in a style similar to the twitter website. The
screen name of the tweeter preceeds the message and the time and
source is given on the next line.")

(defun ebv-retrieve-url (url cb &optional cbargs)
  "Wrapper around url-retrieve.
Optionally sets the username and password if username and password are set."
  (when (and twitter-username twitter-password)
    (let ((server-cons
           (or (assoc "twitter.com:80" url-http-real-basic-auth-storage)
               (car (push (cons "twitter.com:80" nil)
                          url-http-real-basic-auth-storage)))))
      (unless (assoc "Twitter API" server-cons)
        (setcdr server-cons
                (cons (cons "Twitter API"
                            (base64-encode-string
                             (concat twitter-username
                                     ":" twitter-password)))
                      (cdr server-cons))))))
  (url-retrieve url cb cbargs))


(defun ebv-reply-button-pressed (button)
  "Calls twitter-reply for the position where BUTTON is."
  (twitter-reply (overlay-start button)))

(defun ebv-reply (pos)
  "Sets up a status edit buffer to reply to the message at POS.
twitter-reply-status-id is set to the id of the status
corresponding to the status so that it will be marked as a
reply. The status' screen name is initially entered into the
buffer.

When called interactively POS is set to point."
  (interactive "d")
  (let ((status-screen-name (get-text-property pos 'twitter-status-screen-name))
        (status-id (get-text-property pos 'twitter-status-id)))
    (when (null status-screen-name)
      (error "Missing screen name in status"))
    (when (null status-id)
      (error "Missing status id"))
    (twitter-status-edit)
    (setq twitter-reply-status-id status-id)
    (insert "@" status-screen-name " ")))

(defun ebv-show-error (doc)
  "Show a Twitter error message.
DOC should be the XML parsed document returned in the error
message. If any information about the error can be retrieved it
will also be displayed."
  (insert "An error occured while trying to process a Twitter request.\n\n")
  (let (error-node)
    (if (and (consp doc)
             (consp (car doc))
             (eq 'hash (caar doc))
             (setq error-node (xml-get-children (car doc) 'error)))
        (insert (twitter-get-node-text (car error-node)))
      (xml-print doc))))

(defun ebv-compile-format-string (format-string)
  "Converts FORMAT-STRING into a list that is easier to scan.
See twitter-status-format for a description of the format. The
returned list contains elements that are one of the following:

- A string. This should be inserted directly into the buffer.

- A four element list like (RIGHT-PAD WIDTH COMMAND
  PROPERTIES). RIGHT-PAD is t if the - flag was specified or nil
  otherwise. WIDTH is the amount to pad the string to or nil if
  no padding was specified. COMMAND is an integer representing
  the character code for the command. PROPERTIES is a list of
  text properties that should be applied to the resulting
  string."
  (let (parts last-point)
    (with-temp-buffer
      (insert format-string)
      (goto-char (point-min))
      (setq last-point (point))
      (while (re-search-forward "%\\(-?\\)\\([0-9]*\\)\\([a-zA-Z%]\\)" nil t)
        ;; Push the preceeding string (if any) to copy directly into
        ;; the buffer
        (when (> (match-beginning 0) last-point)
          (push (buffer-substring last-point (match-beginning 0)) parts))
        ;; Make the three element list describing the command
        (push (list (> (match-end 1) (match-beginning 1)) ; is - flag given?
                    (if (> (match-end 2) (match-beginning 2)) ; is width given?
                        (string-to-number (match-string 2)) ; extract the width
                      nil) ; otherwise set to nil
                    ;; copy the single character for the command number directly
                    (char-after (match-beginning 3))
                    ;; extract all of the properties so they can be
                    ;; copied into the final string
                    (text-properties-at (match-beginning 0)))
              parts)
        ;; Move last point to the end of the last match
        (setq last-point (match-end 0)))
      ;; Add any trailing text
      (when (< last-point (point-max))
        (push (buffer-substring last-point (point-max)) parts)))
    (nreverse parts)))

(defconst twitter-status-commands
  '((?i . id)
    (?R . in_reply_to_status_id)
    (?S . in_reply_to_user_id)
    (?U . in_reply_to_screen_name)
    (?T . truncated))
  "Alist mapping format commands to XML nodes in the status element.")

(defconst twitter-user-commands
  '((?n . name)
    (?u . screen_name)
    (?I . id)
    (?l . location)
    (?d . description)
    (?A . profile_image_url)
    (?L . url)
    (?F . followers_count)
    (?P . protected))
  "Alist mapping format commands to XML nodes in the user element.")

(defun ebv-insert-status-part-for-command (status-node command)
  "Extract the string for COMMAND from STATUS-NODE and insert.
The command should be integer representing one of the characters
supported by twitter-status-format."
  (let ((user-node (car (xml-get-children status-node 'user))))
    (cond ((= command ?t)
           (let ((val (twitter-get-attrib-node status-node 'created_at)))
             (when val
               (cond ((stringp twitter-time-format)
                      (insert (format-time-string twitter-time-format
                                                  (twitter-time-to-time val))))
                     ((functionp twitter-time-format)
                      (insert (funcall twitter-time-format
                                       (twitter-time-to-time val))))
                     ((null twitter-time-format)
                      (insert val))
                     (t (error "Invalid value for twitter-time-format"))))))
          ((= command ?r)
           (insert-button "reply"
                          'action 'twitter-reply-button-pressed))
          ((or (= command ?m) (= command ?M))
           (let ((val (twitter-get-attrib-node status-node 'text)))
             (when val
               (if (= command ?M)
                   (fill-region (prog1 (point) (insert val)) (point))
                 (insert val)))))
          ((= command ?s)
           (let ((val (twitter-get-attrib-node status-node 'source)))
             (when val
               (with-temp-buffer
                 (insert val)
                 (setq val (twitter-get-node-text
                            (car (xml-parse-region (point-min) (point-max))))))
               (when val
                 (insert val)))))
          ((= command ?%)
           (insert ?%))
          (t
           (let (val elem)
             (cond ((setq elem (assoc command twitter-user-commands))
                    (setq val (twitter-get-attrib-node
                               user-node (cdr elem))))
                   ((setq elem (assoc command twitter-status-commands))
                    (setq val (twitter-get-attrib-node
                               status-node (cdr elem)))))
             (when val
               (insert val)))))))

(defun ebv-kill-status-buffer ()
  "Kill the *Twitter Status* buffer and restore the previous
frame configuration."
  (interactive)
  (kill-buffer "*Twitter Status*")
  (set-frame-configuration twitter-frame-configuration))

(define-derived-mode ebv-mode view-mode "ebv"
  "mode for ebv."
  ;; Schedule to update the character count after altering the buffer
  (make-local-variable 'after-change-functions)
  (add-hook 'after-change-functions 'twitter-status-edit-after-change)
  ;; Add the remaining character count to the mode line
  (make-local-variable 'twitter-status-edit-remaining-length)
  ;; Copy the mode line format list so we can safely edit it without
  ;; affecting other buffers
  (setq mode-line-format (copy-sequence mode-line-format))
  ;; Add the remaining characters variable after the mode display
  (let ((n mode-line-format))
    (catch 'found
      (while n
        (when (eq 'mode-line-modes (car n))
          (setcdr n (cons 'twitter-status-edit-remaining-length
                          (cdr n)))
          (throw 'found nil))
        (setq n (cdr n)))))
  ;; Make a buffer-local reference to the overlay for overlong
  ;; messages
  (make-local-variable 'twitter-status-edit-overlay)
  ;; A buffer local variable for the reply id. This is filled in when
  ;; the reply button is pressed
  (make-local-variable 'twitter-reply-status-id)
  (setq twitter-reply-status-id nil)
  ;; Update the mode line immediatly
  (twitter-status-edit-update-length))

;; search book
(defun ebv-search-book (book-name)
  "搜索电子书."
  (interactive "s请输入要找的书名:")
  (let ((old-buffer (current-buffer))
        (standard-output standard-output)
                                        ;	 (mode-end (make-string (- Buffer-menu-mode-width 2) ?\s))
        (header (concat "CRM "
                        (Buffer-menu-make-sort-button "小说站点" 2) " "
                        (Buffer-menu-make-sort-button "小说名称" 3) " "
                        (Buffer-menu-make-sort-button "目录页网址" 4) " "; mode-end
                        (Buffer-menu-make-sort-button "最新章节" 5) "\n"))
        
        (buf (get-buffer-create "*EBV*")))

    ;; 设置列表头
    (when Buffer-menu-use-header-line
      (let ((pos 0))
        ;; Turn whitespace chars in the header into stretch specs so
        ;; they work regardless of the header-line face.
        (while (string-match "[ \t\n]+" header pos)
          (setq pos (match-end 0))
          (put-text-property (match-beginning 0) pos 'display
                             ;; Assume fixed-size chars in the buffer.
                             (list 'space :align-to pos)
                             header)))
      ;; Try to better align the one-char headers.
      (put-text-property 0 3 'face 'fixed-pitch header)
      ;; Add a "dummy" leading space to align the beginning of the header
      ;; line with the beginning of the text (rather than with the left
      ;; scrollbar or the left fringe).  --Stef
      (setq header (concat (propertize " " 'display '(space :align-to 0))
                           header)))
    (with-current-buffer (get-buffer-create "*EBV*")
      (setq buffer-read-only nil)
      (erase-buffer)
      (setq standard-output (current-buffer))
      (unless Buffer-menu-use-header-line
        ;; Use U+2014 (EM DASH) to underline if possible, else use ASCII
        ;; (i.e. U+002D, HYPHEN-MINUS).
        (let ((underline (if (char-displayable-p ?\u2014) ?\u2014 ?-)))
          (insert header
                  (apply 'string
                         (mapcar (lambda (c)
                                   (if (memq c '(?\n ?\s)) c underline))
                                 header)))))

      ;; Collect info for every buffer we're interested in.
      ;; ;; 加入电子书搜索结果
      ;; (dolist (buffer (or buffer-list
      ;; 			  (buffer-list
      ;; 			   (when Buffer-menu-use-frame-buffer-list
      ;; 			     (selected-frame)))))
      ;; 	(with-current-buffer buffer
      ;; 	  (let ((name (buffer-name))
      ;; 		(file buffer-file-name))
      ;; 	    (unless (and (not buffer-list)
      ;; 			 (or
      ;; 			  ;; Don't mention internal buffers.
      ;; 			  (and (string= (substring name 0 1) " ") (null file))
      ;; 			  ;; Maybe don't mention buffers without files.
      ;; 			  (and files-only (not file))
      ;; 			  (string= name "*Buffer List*")))
      ;; 	      ;; Otherwise output info.
      ;; 	      (let ((mode (concat (format-mode-line mode-name nil nil buffer)
      ;; 				  (if mode-line-process
      ;; 				      (format-mode-line mode-line-process
      ;; 							nil nil buffer))))
      ;; 		    (bits (string
      ;; 			   (if (eq buffer old-buffer) ?. ?\s)
      ;; 			   ;; Handle readonly status.  The output buffer
      ;; 			   ;; is special cased to appear readonly; it is
      ;; 			   ;; actually made so at a later date.
      ;; 			   (if (or (eq buffer standard-output)
      ;; 				   buffer-read-only)
      ;; 			       ?% ?\s)
      ;; 			   ;; Identify modified buffers.
      ;; 			   (if (buffer-modified-p) ?* ?\s)
      ;; 			   ;; Space separator.
      ;; 			   ?\s)))
      ;; 		(unless file
      ;; 		  ;; No visited file.  Check local value of
      ;; 		  ;; list-buffers-directory and, for Info buffers,
      ;; 		  ;; Info-current-file.
      ;; 		  (cond ((and (boundp 'list-buffers-directory)
      ;; 			      list-buffers-directory)
      ;; 			 (setq file list-buffers-directory))
      ;; 			((eq major-mode 'Info-mode)
      ;; 			 (setq file Info-current-file)
      ;; 			 (cond
      ;; 			  ((equal file "dir")
      ;; 			   (setq file "*Info Directory*"))
      ;; 			  ((eq file 'apropos)
      ;; 			   (setq file "*Info Apropos*"))
      ;; 			  ((eq file 'history)
      ;; 			   (setq file "*Info History*"))
      ;; 			  ((eq file 'toc)
      ;; 			   (setq file "*Info TOC*"))
      ;; 			  ((not (stringp file))  ;; avoid errors
      ;; 			   (setq file nil))
      ;; 			  (t
      ;; 			   (setq file (concat "("
      ;; 					      (file-name-nondirectory file)
      ;; 					      ") "
      ;; 					      Info-current-node)))))))
      ;; 		(push (list buffer bits name (buffer-size) mode file)
      ;; 		      list))))))

      ;; Preserve the original buffer-list ordering, just in case.
                                        ;      (setq list (nreverse list))
      ;; Place the buffers's info in the output buffer, sorted if necessary.
      ;; (dolist (buffer
      ;; 	       (if Buffer-menu-sort-column
      ;; 		   (sort list
      ;; 			 (if (eq Buffer-menu-sort-column 3)
      ;; 			     (lambda (a b)
      ;; 			       (< (nth Buffer-menu-sort-column a)
      ;; 				  (nth Buffer-menu-sort-column b)))
      ;; 			   (lambda (a b)
      ;; 			     (string< (nth Buffer-menu-sort-column a)
      ;; 				      (nth Buffer-menu-sort-column b)))))
      ;; 		 list))
      ;; 	(if (eq (car buffer) old-buffer)
      ;; 	    (setq desired-point (point)))
      ;; 	(insert (cadr buffer)
      ;; 		;; Put the buffer name into a text property
      ;; 		;; so we don't have to extract it from the text.
      ;; 		;; This way we avoid problems with unusual buffer names.
      ;; 		(let ((name (nth 2 buffer))
      ;; 		      (size (int-to-string (nth 3 buffer))))
      ;; 		      (Buffer-menu-buffer+size name size
      ;; 		         `(buffer-name ,name
      ;; 				       buffer ,(car buffer)
      ;; 				       font-lock-face buffer-menu-buffer
      ;; 				       mouse-face highlight
      ;; 				       help-echo
      ;; 				       ,(if (>= (length name)
      ;; 						(- Buffer-menu-buffer+size-width
      ;; 						   (max (length size) 3)
      ;; 						   2))
      ;; 					    name
      ;; 					  "mouse-2: select this buffer"))))
      ;; 		"  "
      ;; 		(if (> (string-width (nth 4 buffer)) Buffer-menu-mode-width)
      ;; 		    (truncate-string-to-width (nth 4 buffer)
      ;; 					      Buffer-menu-mode-width)
      ;; 		  (nth 4 buffer)))
      ;; 	(when (nth 5 buffer)
      ;; 	  (indent-to (+ Buffer-menu-buffer-column Buffer-menu-buffer+size-width
      ;; 			Buffer-menu-mode-width 4) 1)
      ;; 	  (princ (abbreviate-file-name (nth 5 buffer))))
      ;; 	(princ "\n"))
      (Buffer-menu-mode)
      (when Buffer-menu-use-header-line
        (setq header-line-format header))
      ;; DESIRED-POINT doesn't have to be set; it is not when the
      ;; current buffer is not displayed for some reason.
                                        ;      (and desired-point
                                        ;	   (goto-char desired-point))
                                        ;      (setq Buffer-menu-files-only files-only)
                                        ;      (set-buffer-modified-p nil)
      (current-buffer)))
  (message "命令: m, u, t, RET, g, k, S, D, Q; q 退出; h 帮助")

  )

(setq site '("86中文网"
             "http://www.86zww.cn/"
             "http://www.86zww.cn/modules/article/search.php?searchkey="
             "<caption>搜索结果</caption>"
             "</table>"
             ("<a href=\"http://[a-z0-9A-Z\./?=\%\"]*>" "<") ;标题
             ("href=\"" "\"")		;目录页网址
             ("_blank\">" "</a>")	;最新章节
             "gb2312-dos"
             ))
;; search on site
(defun ebv-search-site(site bookname)
  (let* ((search-engin (nth 2 site))
         (list-start-flag (nth 3 site))
         (list-end-flag (nth 4 site))
         (title-flag (nth 5 site))
         (index-flag (nth 6 site))
         (newer-flag (nth 7 site))
         (site-code (nth 8 site))
         tmp-buf pos pos-end bookinfo result-list)

    (setq tmp-buf (url-retrieve-synchronously (concat search-engin
                                                      (w3m-url-encode-string bookname 'gb2312))))
    (when tmp-buf
      (set-buffer tmp-buf)
      (switch-to-buffer tmp-buf)
      (mm-enable-multibyte)	;很重要，转换需要开启
      (decode-coding-region (point-min) (point-max) 'gb2312-dos)
      (with-current-buffer tmp-buf
        (goto-char (point-min))
        (search-forward-regexp list-start-flag)
        (setq pos (match-beginning 0))
        (search-forward-regexp list-end-flag)	     
        (setq pos-end (match-beginning 0))


        (while (< pos pos-end)
          (setq bookinfo ())
          (search-forward-regexp (car title-flag)) ;标题
          (setq pos (+ (match-end 0) 1))
          (search-forward-regexp (cdr title-flag))
          (setq bookinfo (append bookinfo
                                 (buffer-substring pos (match-beginning 0))))
          
          (search-forward-regexp (car index-flag)) ;目录页网址
          (setq pos (+ (match-end 0) 1))
          (search-forward-regexp (cdr index-flag))
          (setq bookinfo (append bookinfo
                                 (buffer-substring pos (match-beginning 0))))

          (search-forward-regexp (car newer-flag)) ;最新章节
          (setq pos (+ (match-end 0) 1))
          (search-forward-regexp (cdr newer-flag))
          (setq bookinfo (append bookinfo
                                 (buffer-substring pos (match-beginning 0))))
          (setq pos (+ (match-end 0) 1))
          (reverse bookinfo)
          (setq result-list (append result-list bookinfo))
          )
        )
      (kill-buffer tmp-buf)
      (reverse result-list)
      )
    )
  )
;; test part
(setq a="gb2312")
(quote (a))
(ebv-search-site site "风流")
(ebv-search-site site "%B7%E7%C1%F7")
(require 'webjump)
(webjump-url-encode
 (w3m-url-encode-string "风流"  'gb2312)
 (url-http 
  (url-generic-parse-url (nth 1 site))
  (ebv-search-book "tt")
  (switch-to-buffer "*EBV*")

  ;; add book
  (defun ebv-add-book ()
    "thisandthat."
    (interactive)
    (let (var1)
      (setq var1 some)
      
      )
    )

  (setq content-start-flag "<div id=\"content\">")
  (setq content-end-flag "<span id='adbanner_8'>")
  (defun ebv-format-buffer ()
    "格式化整理."
    (interactive)
    ;; 去除多余头部
    (if content-start-flag
        (save-excursion
          (goto-char (point-min))
          (re-search-forward content-start-flag nil 'move)
          (goto-char (match-beginning 0))
          (delete-region (point-min) (point)))
      )
    ;; 去除多余尾部
    (if content-end-flag
        (save-excursion
          (goto-char (point-min))
          (re-search-forward content-end-flag nil 'move)
          (delete-region (match-beginning 0) (point-max)))
      )

    (html2text)

    ;; 自动去除多余空行
    (if ebv-auto-remove-blank		;FIXME:not work
        (save-excursion
          (goto-char (point-min))
          (query-replace-regexp "^[ \t]*$" "")))
    )

  (provide 'ebv)

;;; ebv.el ends here
