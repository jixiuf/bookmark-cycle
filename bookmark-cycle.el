;;; bookmark-cycle.el --- Description

;; Description: Description
;; Created: 2013-11-18 21:45
;; Last Updated: 纪秀峰 2013-11-19 00:58:26 
;; Author: 纪秀峰  jixiuf@gmail.com
;; Keywords: bookmark

;; Copyright (C) 2013, 纪秀峰, all rights reserved.

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; goto next or previous bookmark
;; first: you should
;;     (require 'bookmark)
;;     (setq bookmark-sort-flag nil)
;;then:
;; (global-set-key (kbd "M-.") 'bookmark-cycle-push)
;; (global-set-key (kbd "M-,") 'bookmark-cycle-next)
;; (global-set-key (kbd "M-/") 'bookmark-cycle-previous)
;;
;; sometimes , you could add bookmark-cycle-push to
;; a hook. for example: before you goto a definition of a function
;;
;; I also provide two function:
;; bookmark-cycle-save-tmp-context and bookmark-cycle-push-context
;; for programmer save the current position to tmp marker,
;; you can call `bookmark-cycle-push-context' when you are ready to push
;; it to bookmark list.
;;
;; see emacs-helm/helm helm-bookmark.el for list all bookmarks
;;
;;; Code:

(eval-when-compile
  (require 'cl))

(require 'bookmark)


(defgroup bookmark-cycle nil
  "bookmarks cycle "
  :group 'bookmark)

(defcustom bookmark-cycle-highlight-after-jump t
  "*If non-nil, temporarily highlight current line
  after you jump to it."
  :group 'bookmark-cycle
  :type 'boolean)

(defcustom bookmark-cycle-highlight-delay 0.2
  "*How long to highlight the tag."
  :group 'bookmark-cycle
  :type 'number)

(defface bookmark-cycle-highlight-face
  '((t (:foreground "white" :background "cadetblue4" :bold t)))
  "Font Lock mode face used to highlight tags."
  :group 'bookmark-cycle)

(defvar bookmark-cycle-cur-name nil "current bookname")
(defvar bookmark-cycle-tmp-context-marker nil
  "save a marker here ,when you are ready push the marker to bookmark list,
call `bookmark-cycle-push-context'")

;;;###autoload
(defun bookmark-cycle-push()
  "Push a new bookmark (default using current line as name)."
  (interactive)
  (case (prefix-numeric-value current-prefix-arg)
    (1                                  ;default
     (bookmark-cycle--push-curline))
    (4                                  ;C-u
     (bookmark-set (read-string "Set bookmark name:"))
     (message "New bookmark created!"))))

;;;###autoload
(defun bookmark-cycle-next()
  "go to next bookmark cyclely"
  (interactive)
  (bookmark-cycle-next-internal (bookmark-all-names)))

;;;###autoload
(defun bookmark-cycle-previous()
    "go to previous bookmark cyclely"
  (interactive)
  (bookmark-cycle-next-internal (reverse (bookmark-all-names))))

(defun bookmark-cycle-save-tmp-context()
  "for programmer save the current position to tmp marker,
you can call `bookmark-cycle-push-context' when you are ready to push
it to bookmark list"
  (message "hello")
  (setq bookmark-cycle-tmp-context-marker (point-marker)))

(defun bookmark-cycle-push-context()
  "Push the saved `bookmark-cycle-tmp-context-marker' to bookmark list (for programmer)"
    (message "world")

  (when (and bookmark-cycle-tmp-context-marker
             (markerp bookmark-cycle-tmp-context-marker))
    (save-excursion
      (let ((buf (marker-buffer bookmark-cycle-tmp-context-marker))
            (pos (marker-position bookmark-cycle-tmp-context-marker)))
        (when buf
          (with-current-buffer buf
            (goto-char pos)
            (bookmark-cycle--push-curline)
            (setq bookmark-cycle-tmp-context-marker nil)))))))

(defun bookmark-cycle-next-internal(bookmark-names)
  (let((names bookmark-names))
    (case names
      (nil (message "no bookmarks!!!"))
      (otherwise
       (if (or (null bookmark-cycle-cur-name)
               (not (member bookmark-cycle-cur-name names)))
           (bookmark-cycle--jump (car names))
         (let ((first (car names)))
           (while (not (string-equal bookmark-cycle-cur-name (car names)))
             (setq names (cdr names)))
           (if (>  (length names) 1)
               (bookmark-cycle--jump (nth 1 names))
             (bookmark-cycle--jump first))))))))

(defun bookmark-cycle--jump(name)
  (case (prefix-numeric-value current-prefix-arg)
    (1                                  ;default
     (bookmark-jump name))
    (4                                  ;C-u
     (bookmark-jump-other-window name)))
  (setq bookmark-cycle-cur-name name)
  )

(defun bookmark-cycle--push-curline()
  (when (buffer-file-name)
    (setq bookmark-cycle-cur-name
          (replace-regexp-in-string
           "^[ \t]*" ""
           (buffer-substring-no-properties
            (line-beginning-position) (line-end-position))))
    (bookmark-set bookmark-cycle-cur-name )
    (message "New bookmark created!")))

(defun bookmark-cycle--highlight (beg end)
  "Highlight a region temporarily.
   (borrowed from etags-select.el)"
  (let ((ov (make-overlay beg end)))
      (overlay-put ov 'face 'bookmark-cycle-highlight-face)
      (sit-for bookmark-cycle-highlight-delay)
      (delete-overlay ov)))

(defun bookmark-cycle-after-jump-fun()
  (when bookmark-cycle-highlight-after-jump
    (bookmark-cycle--highlight
     (line-beginning-position) (line-end-position))))

(add-hook 'bookmark-after-jump-hook 'bookmark-cycle-after-jump-fun)
(provide 'bookmark-cycle)

;; Local Variables:
;; coding: utf-8
;; End:

;;; bookmark-cycle.el ends here
