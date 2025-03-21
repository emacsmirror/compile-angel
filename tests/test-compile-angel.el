;;; test-compile-angel.el --- Test compile-angel -*- lexical-binding: t; -*-

;; Copyright (C) 2025 James Cherti | https://www.jamescherti.com/contact/

;; Author: James Cherti
;; Version: 1.0.6
;; URL: https://github.com/jamescherti/compile-angel.el
;; Keywords: abbrev
;; Package-Requires: ((emacs "24.1"))
;; SPDX-License-Identifier: GPL-3.0-or-later

;; This file is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 2, or (at your option)
;; any later version.

;; This file is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:
;; Test compile-angel.

;;; Code:

(require 'ert)
(require 'compile-angel)

;; (with-no-warnings
;;   (when (require 'undercover nil t)
;;     (undercover "compile-angel.el"
;;                 (:report-file ".coverage")
;;                 (:report-format 'text)
;;                 (:send-report nil))))

(defvar test-compile-angel--test-dir (expand-file-name "~/.test-compile-angel"))
(defvar test-compile-angel--el-file
  (expand-file-name "simple-el-file.el" test-compile-angel--test-dir))
(defvar test-compile-angel--elc-file
  (expand-file-name "simple-el-file.elc" test-compile-angel--test-dir))
(defvar test-compile-angel--load-path (copy-sequence load-path))

(defun test-compile-angel--init ()
  (compile-angel-on-load-mode -1)
  (compile-angel-on-save-mode -1)
  (compile-angel-on-save-local-mode -1)

  (when (featurep 'simple-el-file)
    (unload-feature 'simple-el-file))
  (delete-file test-compile-angel--elc-file)

  (setq load-path (copy-sequence test-compile-angel--load-path))
  (add-to-list 'load-path test-compile-angel--test-dir)

  (make-directory test-compile-angel--test-dir t)
  (with-temp-buffer
    (insert "(message \"Hello world\") (provide 'simple-el-file)")
    (let ((coding-system-for-write 'utf-8-emacs)
          (write-region-annotate-functions nil)
          (write-region-post-annotation-function nil))
      (write-region (point-min) (point-max)
                    test-compile-angel--el-file nil 'silent)))

  (compile-angel-on-load-mode 1)
  (when (file-exists-p test-compile-angel--elc-file)
    (error "This file should not exist during init: %s"
           test-compile-angel--elc-file)))

(ert-deftest test-compile-angel--test-byte-compile ()
  (test-compile-angel--init)

  (load test-compile-angel--elc-file)
  (should (file-exists-p test-compile-angel--elc-file)))

(provide 'test-compile-angel)
;;; test-compile-angel.el ends here
