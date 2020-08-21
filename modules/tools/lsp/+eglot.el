;;; tools/lsp/+eglot.el -*- lexical-binding: t; -*-

;; TODO set eglot-events-buffer-size to nil in doom-debug-mode

(use-package! eglot
  :commands eglot eglot-ensure
  :hook (eglot-managed-mode . +lsp-init-optimizations-h)
  :init
  (setq eglot-sync-connect 1
        eglot-connect-timeout 10
        eglot-autoshutdown t
        eglot-send-changes-idle-time 0.5
        ;; NOTE We disable eglot-auto-display-help-buffer because :select t in
        ;;      its popup rule causes eglot to steal focus too often.
        eglot-auto-display-help-buffer nil)

  :config
  (set-popup-rule! "^\\*eglot-help" :size 0.15 :quit t :select t)
  (set-lookup-handlers! 'eglot--managed-mode
    :implementations #'eglot-find-implementation
    :type-definition #'eglot-find-typeDefinition
    :documentation #'+eglot-lookup-documentation)
  (when (featurep! :checkers syntax)
    (after! flycheck
      (load! "autoload/flycheck-eglot")))

  (defadvice! +lsp--defer-server-shutdown-a (orig-fn &optional server)
    "Defer server shutdown for a few seconds.
This gives the user a chance to open other project files before the server is
auto-killed (which is a potentially expensive process). It also prevents the
server getting expensively restarted when reverting buffers."
    :around #'eglot--managed-mode
    (letf! (defun eglot-shutdown (server)
             (if (or (null +lsp-defer-shutdown)
                     (eq +lsp-defer-shutdown 0))
                 (funcall eglot-shutdown server)
               (run-at-time
                (if (numberp +lsp-defer-shutdown) +lsp-defer-shutdown 3)
                nil (lambda (server)
                      (unless (eglot--managed-buffers server)
                        (funcall eglot-shutdown server)))
                server)))
      (funcall orig-fn server))))
