(defvar ebv-site-info
  '(((name . "16k小说网")                 ;16k小说网
     (url . "http://www.16kbook.com/")
     (url-search . ((url . "http://www.16kbook.com/Book/Search.aspx")
                    (method . "post")
                    (key . "SearchKey.value")))
     (ListStart . "id=\"BookText\"&gt;")
     (ListEnd . "注：C")
     (ContentStart . "&lt;div id=\"BText\"&gt;")
     (ContentEnd . "&lt;a href=\"/U")
     (NeedDelStr . "[[&lt;font发]]]||[[(1⑹|1).{1,38}说]]")
     (VolumeStart . "NclassTitle\"&gt;")
     (VolumeEnd . "【")
     (BriefUrlStart . "连载首页&lt;/a&gt;")
     (BriefUrlEnd . "&lt;/a&gt;")
     (AuthorStart . "作者&lt;/li&gt;")
     (AuthorEnd . "&lt;/a&gt;")
     (BriefStart . "&lt;div id=\"CrbsSum\"&gt;")
     (BriefEnd . "&lt;/div&gt;")
     (BookImgUrlStart . "CrbtlBookImg\"&gt;")
     (BookImgUrlEnd . "width"))

    ((name . "极品文学网")                 ;极品文学网
     (url . "http://http://www.jpwx.net/")
     (url-search . ((url . "http://www.jpwx.net/modules/article/search.php")
                    (method . "post")
                    (key . "searchkey")))
     (ListStart . "id=\"BookText\"&gt;")
     (ListEnd . "注：C")
     (ContentStart . "&lt;div id=\"BText\"&gt;")
     (ContentEnd . "&lt;a href=\"/U")
     (NeedDelStr . "[[&lt;font发]]]||[[(1⑹|1).{1,38}说]]")
     (VolumeStart . "NclassTitle\"&gt;")
     (VolumeEnd . "【")
     (BriefUrlStart . "连载首页&lt;/a&gt;")
     (BriefUrlEnd . "&lt;/a&gt;")
     (AuthorStart . "作者&lt;/li&gt;")
     (AuthorEnd . "&lt;/a&gt;")
     (BriefStart . "&lt;div id=\"CrbsSum\"&gt;")
     (BriefEnd . "&lt;/div&gt;")
     (BookImgUrlStart . "CrbtlBookImg\"&gt;")
     (BookImgUrlEnd . "width"))
    ))

;; (setq site '("86中文网"
;;              "http://www.86zww.cn/"
;;              "http://www.86zww.cn/modules/article/search.php?searchkey="
;;              "<caption>搜索结果</caption>"
;;              "</table>"
;;              ("<a href=\"http://[a-z0-9A-Z\./?=\%\"]*>" "<") ;标题
;;              ("href=\"" "\"")		;目录页网址
;;              ("_blank\">" "</a>")	;最新章节
;;              "gb2312-dos"
;;              ))

;; (provide 'ebv-site-info)
