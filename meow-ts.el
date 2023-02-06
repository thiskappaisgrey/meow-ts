;;; meow-tree-sitter.el --- Tree Sitter integration in Meow -*- lexical-binding: t -*-

;; This file is not part of GNU Emacs.

;; This program is free software; you can redistribute it and/or
;; modify it under the terms of the GNU General Public License
;; as published by the Free Software Foundation; either version 3
;; of the License, or (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.  If not, write to the
;; Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
;; Boston, MA 02110-1301, USA.


;;; Commentary:
;; Implementation for Meow Tree Sitter integration (Emacs 29 Treesitter)
(require 'meow)
(require 'treesit)
(require 'subr-x)


;; TODO Figure out how to extend meow-thing (using functions)
(defun meow-ts--get-defun-at-point ()
  (let ((node (treesit-defun-at-point)))
    ;; TODO abort when node is not the right node
    `(,(treesit-node-start node) . ,(treesit-node-end node))
    ))
(meow-thing-register 'ts-fun #'meow-ts--get-defun-at-point #'meow-ts--get-defun-at-point)
(add-to-list 'meow-char-thing-table '(?f . ts-fun))

;; TODO add more "meow-things" for treesit objects. Also, only add certain things for different languages with potentially different things.
;; Also, replace the whole thing table when in prog-mode
;; (setq meow-char-thing-table (remove '(?f . 'ts-fun) meow-char-thing-table))
;; TODO be able to "unregister" things (like string)

;; TODO meow next / previous defun (just like words) - also make an expandable defun too!
(defun meow-ts-next-defun (n)
  "Select to the end of the next Nth function(tree-sitter).
A non-expandable, function selection will be created."
  (interactive "p")
  (unless (equal 'fun (cdr (meow--selection-type)))
    (meow--cancel-selection))
  (let* ((expand (equal '(expand . fun) (meow--selection-type)))
         (_ (when expand (meow--direction-forward)))
         (type (if expand '(expand . fun) '(select . fun)))
         (m (or (save-mark-and-excursion
		  (treesit-end-of-defun n)
		  (when (treesit-beginning-of-defun)
		    (point)))
		(point)))
         (p (save-mark-and-excursion
              (when (treesit-end-of-defun n)
                (point)))))
    (when p
      (thread-first
        (meow--make-selection type m p expand)
        (meow--select))
      ;; this requires modifying `meow--select-expandable-p' - to include the "fun" seletion type as expandable
      (meow--maybe-highlight-num-positions '(meow-ts--backward-defun-1 . meow-ts--forward-defun-1))
      )))

(defun meow-ts--forward-defun-1 ()
  (when (treesit-end-of-defun 1)
    (point)))

(defun meow-ts--backward-defun-1 ()
  (when (treesit-beginning-of-defun 1)
    (point)))

;; TODO make a "meow-ts-node" function with API similar to "meow-block"
;; selects current node and expands to parent nodes
(provide 'meow-ts)
