;;; docked-shell.el --- Dockerized shell mode interface shell command line into container

;; Author: Duzy Chan <code@duzy.info>

;; This file is NOT part of GNU Emacs.

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.  If not, write to the
;; Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
;; Boston, MA 02110-1301, USA.

;;; Commentary:

;;; Code:

(require 'comint)
(require 'pcomplete)

(defvar docked-shell-docker-command "/usr/bin/docker"
  "The file name of `docker' command.")

(defcustom docked-shell-prompt-pattern "^[^#$%>\n]*[#$%>] *"
  "Regexp to match prompts in the inferior shell.
Defaults to \"^[^#$%>\\n]*[#$%>] *\", which works pretty well.
This variable is used to initialize `comint-prompt-regexp' in the
shell buffer.

If `comint-use-prompt-regexp' is nil, then this variable is only used
to determine paragraph boundaries.  See Info node `Shell Prompts' for
how Shell mode treats paragraphs.

The pattern should probably not match more than one line.  If it does,
Shell mode may become confused trying to distinguish prompt from input
on lines which don't start with a prompt."
  :type 'regexp
  :group 'docked)

(define-derived-mode docked-shell-mode comint-mode "Docked"
  "\\[docked-shell-mode-map]"
  (setq comint-process-echoes t)
  (setq comint-prompt-regexp docked-shell-prompt-pattern)
  (setq comint-prompt-read-only t)
  ;; Local Settings
  (set (make-local-variable 'paragraph-separate) "\\'") ;; makes it so commands like M-{ and M-} work.
  (set (make-local-variable 'paragraph-start) comint-prompt-regexp)
  (set (make-local-variable 'font-lock-defaults) '(shell-font-lock-keywords t))
  (ansi-color-for-comint-mode-on) ;; turn on ansi-color
  (toggle-truncate-lines t)
  (hl-line-mode t))

;;;###autoload
(defun docked-shell (&optional buffer)
;;   "Run an inferior shell in a docker container, with I/O through BUFFER
;; (which defaults to `*shell*'). Interactively, a prefix arg means to prompt
;; for BUFFER. If `default-directory' is a remote file name, it is also 
;; prompted to change if called with a prefix arg."
  (interactive
   (list 
    (and current-prefix-arg
         (prog1 ;; if `current-prefix-arg' is set (e.g. M-0).
	     (read-buffer "Docked shell buffer: "
			  ;; If the current buffer is an inactive
			  ;; shell buffer, use it as the default.
			  (if (and (eq major-mode 'docked-shell-mode)
				   (null (get-buffer-process (current-buffer))))
			      (buffer-name)
			    (generate-new-buffer-name "*docked*")))
	   (if (file-remote-p default-directory)
	       ;; It must be possible to declare a local default-directory.
               ;; FIXME: This can't be right: it changes the default-directory
               ;; of the current-buffer rather than of the *shell* buffer.
	       (setq default-directory
		     (expand-file-name
		      (read-directory-name
		       "Default directory: " default-directory default-directory
		       t nil))))))))
  ;;
  ;; If the current buffer is a dead shell buffer, use it.
  (setq buffer (if (or buffer (not (derived-mode-p 'docked-shell-mode))
                       (comint-check-proc (current-buffer)))
                   (get-buffer-create (or buffer "*docked*"))
                 (current-buffer)))
  ;;
  ;; The buffer's window must be correctly set when we call comint (so
  ;; that comint sets the COLUMNS env var properly).
  (pop-to-buffer-same-window buffer)
  ;;
  ;; Create the comint process if there is no buffer.
  (unless (comint-check-proc buffer)
    (let* ((num (or current-prefix-arg 0))
           (image "blockchain-mail-exec")
           (prog (or docked-shell-docker-command (getenv "DOCKER")))
	   (name (or (format "blockchain-mail-node-%d" num)
                     (file-name-nondirectory prog)))
           (prev (shell-command-to-string (format "docker ps -a | grep %s | awk '{print $1}'" name)))
	   (xargs-name (intern-soft (concat "explicit-" name "-args")))
           (docking-args '("")))
      ;; Kill previous container of the name.
      (if (not (string= prev ""))
          (progn
            (shell-command-to-string (format "docker kill %s" prev))
            (shell-command-to-string (format "docker rm %s" prev))))
      ;; Load .docked-shell file.
      (let ((confile (concat default-directory ".docked-shell")))
        (if (file-exists-p confile) ;file-name-as-directory
            (condition-case er 
                (if (file-directory-p confile)
                    ;;(error (format "%s is a directory, not suported yet" confile))
                    (mapc (lambda (p) (load-file p)) 
                          (directory-files confile t "\\.el$"))
                  (load-file confile))
              (message (format "errors exists (%s)" confile)))))
      ;; Starts the container.
      (apply 'make-comint-in-buffer (format "docked: %s" name) buffer prog nil
             "run" (format "--name=%s" name) 
             "--rm=true" ;; remove container when terminated
             "-e" "TERM=dump" ;; this fixes the command prompt error
             ;;"-e" "TERM=xterm-256color" ;; this enables color but command prompts error
             ;;"-e" "TERM=xterm-color" ;; this enables color but command prompts error
             "-e" "PROMPT_COMMAND=echo \"----- NODE#$NODE\"" ;; command to execute after each command line
             "-e" (format "INSIDE_EMACS=%s,comint" emacs-version)
             "-e" "EMACS=t" ;; INSIDE_EMACS, EMACS for compatibility
             ;; `dircolors'
             "-e" "SET_COLORS=LS_COLORS='rs=0:di=01;34:ln=01;36:mh=00:pi=40;33:so=01;35:do=01;35:bd=40;33;01:cd=40;33;01:or=40;31;01:mi=00:su=37;41:sg=30;43:ca=30;41:tw=30;42:ow=34;42:st=37;44:ex=01;32:*.tar=01;31:*.tgz=01;31:*.arc=01;31:*.arj=01;31:*.taz=01;31:*.lha=01;31:*.lz4=01;31:*.lzh=01;31:*.lzma=01;31:*.tlz=01;31:*.txz=01;31:*.tzo=01;31:*.t7z=01;31:*.zip=01;31:*.z=01;31:*.Z=01;31:*.dz=01;31:*.gz=01;31:*.lrz=01;31:*.lz=01;31:*.lzo=01;31:*.xz=01;31:*.bz2=01;31:*.bz=01;31:*.tbz=01;31:*.tbz2=01;31:*.tz=01;31:*.deb=01;31:*.rpm=01;31:*.jar=01;31:*.war=01;31:*.ear=01;31:*.sar=01;31:*.rar=01;31:*.alz=01;31:*.ace=01;31:*.zoo=01;31:*.cpio=01;31:*.7z=01;31:*.rz=01;31:*.cab=01;31:*.jpg=01;35:*.jpeg=01;35:*.gif=01;35:*.bmp=01;35:*.pbm=01;35:*.pgm=01;35:*.ppm=01;35:*.tga=01;35:*.xbm=01;35:*.xpm=01;35:*.tif=01;35:*.tiff=01;35:*.png=01;35:*.svg=01;35:*.svgz=01;35:*.mng=01;35:*.pcx=01;35:*.mov=01;35:*.mpg=01;35:*.mpeg=01;35:*.m2v=01;35:*.mkv=01;35:*.webm=01;35:*.ogm=01;35:*.mp4=01;35:*.m4v=01;35:*.mp4v=01;35:*.vob=01;35:*.qt=01;35:*.nuv=01;35:*.wmv=01;35:*.asf=01;35:*.rm=01;35:*.rmvb=01;35:*.flc=01;35:*.avi=01;35:*.fli=01;35:*.flv=01;35:*.gl=01;35:*.dl=01;35:*.xcf=01;35:*.xwd=01;35:*.yuv=01;35:*.cgm=01;35:*.emf=01;35:*.ogv=01;35:*.ogx=01;35:*.aac=00;36:*.au=00;36:*.flac=00;36:*.m4a=00;36:*.mid=00;36:*.midi=00;36:*.mka=00;36:*.mp3=00;36:*.mpc=00;36:*.ogg=00;36:*.ra=00;36:*.wav=00;36:*.oga=00;36:*.opus=00;36:*.spx=00;36:*.xspf=00;36:'"
             "-e" "LS_COLORS='rs=0:di=01;34:ln=01;36:mh=00:pi=40;33:so=01;35:do=01;35:bd=40;33;01:cd=40;33;01:or=40;31;01:mi=00:su=37;41:sg=30;43:ca=30;41:tw=30;42:ow=34;42:st=37;44:ex=01;32:*.tar=01;31:*.tgz=01;31:*.arc=01;31:*.arj=01;31:*.taz=01;31:*.lha=01;31:*.lz4=01;31:*.lzh=01;31:*.lzma=01;31:*.tlz=01;31:*.txz=01;31:*.tzo=01;31:*.t7z=01;31:*.zip=01;31:*.z=01;31:*.Z=01;31:*.dz=01;31:*.gz=01;31:*.lrz=01;31:*.lz=01;31:*.lzo=01;31:*.xz=01;31:*.bz2=01;31:*.bz=01;31:*.tbz=01;31:*.tbz2=01;31:*.tz=01;31:*.deb=01;31:*.rpm=01;31:*.jar=01;31:*.war=01;31:*.ear=01;31:*.sar=01;31:*.rar=01;31:*.alz=01;31:*.ace=01;31:*.zoo=01;31:*.cpio=01;31:*.7z=01;31:*.rz=01;31:*.cab=01;31:*.jpg=01;35:*.jpeg=01;35:*.gif=01;35:*.bmp=01;35:*.pbm=01;35:*.pgm=01;35:*.ppm=01;35:*.tga=01;35:*.xbm=01;35:*.xpm=01;35:*.tif=01;35:*.tiff=01;35:*.png=01;35:*.svg=01;35:*.svgz=01;35:*.mng=01;35:*.pcx=01;35:*.mov=01;35:*.mpg=01;35:*.mpeg=01;35:*.m2v=01;35:*.mkv=01;35:*.webm=01;35:*.ogm=01;35:*.mp4=01;35:*.m4v=01;35:*.mp4v=01;35:*.vob=01;35:*.qt=01;35:*.nuv=01;35:*.wmv=01;35:*.asf=01;35:*.rm=01;35:*.rmvb=01;35:*.flc=01;35:*.avi=01;35:*.fli=01;35:*.flv=01;35:*.gl=01;35:*.dl=01;35:*.xcf=01;35:*.xwd=01;35:*.yuv=01;35:*.cgm=01;35:*.emf=01;35:*.ogv=01;35:*.ogx=01;35:*.aac=00;36:*.au=00;36:*.flac=00;36:*.m4a=00;36:*.mid=00;36:*.midi=00;36:*.mka=00;36:*.mp3=00;36:*.mpc=00;36:*.ogg=00;36:*.ra=00;36:*.wav=00;36:*.oga=00;36:*.opus=00;36:*.spx=00;36:*.xspf=00;36:'"
             "-e" (format "NODE=%d" num)
             (append 
              (if (listp docking-args) docking-args)
              (list "-t" "-i" image)
              (if (and xargs-name (boundp xargs-name))
                  (symbol-value xargs-name))))
      (docked-shell-mode))))

(read-buffer "Buffer: " "xx" (current-buffer))

(provide 'docked-shell)
