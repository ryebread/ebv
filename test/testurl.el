(setq url (cdr(assq 'url (assq 'url-search (cdr ebv-site-info)))))
(setq key (cdr(assq 'key (assq 'url-search (cdr ebv-site-info)))))
(setq url-test "http://www.16kbook.com/")

(setq key "SearchKey")
(setq url "http://www.jpwx.net/modules/article/search.php")
(setq post-data (list (cons "searchkey"  "最强传")
                      (cons "searchtype" "articlename")
                      (cons "SeaButton.x" "32")
                      (cons "SeaButton.y" "1")))



(setq tmp-buf  (ebv-url-http-post url (list (cons key "最强传承"))))


(setq tmp (url-retrieve url-test (lambda(arg)
                                   (switch-to-buffer (current-buffer)))))

(w3m-browse-url "http://www.jpwx.net/files/article/info/92/92597.htm")

(setq tmp-buf  (ebv-url-http-post url post-data))

(defun my-encode(status)
  (mm-enable-multibyte)	;很重要，转换需要开启
  (w3m-decode-buffer)
  (switch-to-buffer (current-buffer)))

(when tmp-buf
  (set-buffer tmp-buf)
  (switch-to-buffer tmp-buf)
  (mm-enable-multibyte)	;很重要，转换需要开启
  (decode-coding-region (point-min) (point-max) 'gb2312))

  ;; (with-current-buffer tmp-buf
  ;;   (goto-char (point-min))
  ;;   (search-forward-regexp list-start-flag)
  ;;   (setq pos (match-beginning 0))
  ;;   (search-forward-regexp list-end-flag)
  ;;   (setq pos-end (match-beginning 0))


  ;;   (while (< pos pos-end)
  ;;     (setq bookinfo ())
  ;;     (search-forward-regexp (car title-flag)) ;标题
  ;;     (setq pos (+ (match-end 0) 1))
  ;;     (search-forward-regexp (cdr title-flag))
  ;;     (setq bookinfo (append bookinfo
  ;;                            (buffer-substring pos (match-beginning 0))))

  ;;     (search-forward-regexp (car index-flag)) ;目录页网址
  ;;     (setq pos (+ (match-end 0) 1))
  ;;     (search-forward-regexp (cdr index-flag))
  ;;     (setq bookinfo (append bookinfo
  ;;                            (buffer-substring pos (match-beginning 0))))

  ;;     (search-forward-regexp (car newer-flag)) ;最新章节
  ;;     (setq pos (+ (match-end 0) 1))
  ;;     (search-forward-regexp (cdr newer-flag))
  ;;     (setq bookinfo (append bookinfo
  ;;                            (buffer-substring pos (match-beginning 0))))
  ;;     (setq pos (+ (match-end 0) 1))
  ;;     (reverse bookinfo)
  ;;     (setq result-list (append result-list bookinfo))
  ;;     )
  ;;   )
  )
