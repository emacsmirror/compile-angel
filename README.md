# compile-angel.el - Speed up Emacs by Byte-compiling and Native-compiling all .el files
[![MELPA](https://melpa.org/packages/compile-angel-badge.svg)](https://melpa.org/#/compile-angel)
![Build Status](https://github.com/jamescherti/compile-angel.el/actions/workflows/ci.yml/badge.svg)
![License](https://img.shields.io/github/license/jamescherti/compile-angel.el)
![](https://raw.githubusercontent.com/jamescherti/compile-angel.el/main/.images/made-for-gnu-emacs.svg)

The **compile-angel** package automatically byte-compiles and native-compiles Emacs Lisp libraries. It offers:
- `(compile-angel-on-load-mode)`: A global mode that compiles .el files before they are loaded.
- `(compile-angel-on-save-local-mode)`: A local mode that compiles .el files whenever the user saves them.

The *compile-angel* modes **speed up Emacs by ensuring all libraries are byte-compiled and native-compiled**. Byte-compilation reduces the overhead of loading Emacs Lisp code at runtime, while native compilation optimizes performance by generating machine code specific to your system.

The *compile-angel* author was previously an *auto-compile* user but encountered an issue where several .el files were not being compiled by auto-compile (see the explanation below), resulting in Emacs performance degradation due to the lack of native compilation.

After extensive experimentation and research, the author developed *compile-angel* to address this problem. **The compile-angel package guarantees that all .el files are both byte-compiled and native-compiled, which significantly speeds up Emacs.**

<!-- markdown-toc start - Don't edit this section. Run M-x markdown-toc-refresh-toc -->
## Table of Contents

- [compile-angel.el - Speed up Emacs by Byte-compiling and Native-compiling all .el files](#compile-angelel---speed-up-emacs-by-byte-compiling-and-native-compiling-all-el-files)
  - [Why use compile-angel?](#why-use-compile-angel)
  - [Before installing](#before-installing)
  - [Installation of compile-angel](#installation-of-compile-angel)
    - [Emacs](#emacs)
    - [Doom Emacs](#doom-emacs)
  - [Frequently Asked Questions](#frequently-asked-questions)
    - [What are some interesting Emacs customizations to consider alongside compile-angel?](#what-are-some-interesting-emacs-customizations-to-consider-alongside-compile-angel)
    - [How to exclude certain .el files from compilation in compile-angel?](#how-to-exclude-certain-el-files-from-compilation-in-compile-angel)
    - [How to exclude custom-file, recentf, savehist files?](#how-to-exclude-custom-file-recentf-savehist-files)
    - [How to enable or disable byte-compilation and native-compilation?](#how-to-enable-or-disable-byte-compilation-and-native-compilation)
    - [What's the point of using compile-angel? My Emacs compiles packages automatically anyway!](#whats-the-point-of-using-compile-angel-my-emacs-compiles-packages-automatically-anyway)
    - [Why not just use the package-recompile-all function?](#why-not-just-use-the-package-recompile-all-function)
    - [What is the impact on Emacs startup?](#what-is-the-impact-on-emacs-startup)
    - [What's the difference between native and byte compiled?](#whats-the-difference-between-native-and-byte-compiled)
    - [What are some use-cases of compile-angel?](#what-are-some-use-cases-of-compile-angel)
    - [What is the difference between auto-compile and compile-angel?](#what-is-the-difference-between-auto-compile-and-compile-angel)
  - [Author and License](#author-and-license)
  - [Links](#links)

<!-- markdown-toc end -->

## Why use compile-angel?

Because you are likely running a significant amount of interpreted, slow Elisp code that Emacs did not compile automatically. Ensuring that Elisp is native-compiled significantly improves Emacs' performance. Unfortunately, functions like *package-install* and *package-recompile-all* do not compile .el files that were not installed using *package.el*. Since these files are not byte-compiled, the Emacs JIT compiler does not native-compile them either, as a byte-compiled file signals the JIT compiler to perform native compilation. **In contrast, **compile-angel** modes ensure that all loaded `.el` files are compiled transparently, regardless of whether they are part of a package.**

## Before installing

It is highly recommended to set the following variables **at the very beginning of your early-init.el**:

``` emacs-lisp
;; Ensure Emacs loads the most recent byte-compiled files.
(setq load-prefer-newer t)

;; Ensure JIT compilation is enabled for improved performance by
;; native-compiling loaded .elc files asynchronously
(setq native-comp-jit-compilation t)
(setq native-comp-deferred-compilation t) ; Deprecated in Emacs > 29.1
```

Additionally, ensure that native compilation is enabled:

This should return t: `(native-comp-available-p)`

## Installation of compile-angel

### Emacs

To install *compile-angel* on Emacs from MELPA:

1. If you haven't already done so, [add MELPA repository to your Emacs configuration](https://melpa.org/#/getting-started).

2. Add the following code **at the very beginning of your init.el file, before all other packages**:
```emacs-lisp
(use-package compile-angel
  :ensure t
  :demand t
  :config
  ;; Set `compile-angel-verbose' to nil to silence compile-angel.
  (setq compile-angel-verbose t)

  (compile-angel-on-load-mode)
  (add-hook 'emacs-lisp-mode-hook #'compile-angel-on-save-local-mode))
```

### Doom Emacs

Here is how to install *compile-angel* on Doom Emacs:

1. Add to the `~/.doom.d/packages.el` file:
```elisp
(package! compile-angel)
```

2. Add to the top of `~/.doom.d/config.el`:
```elisp
;; Set `compile-angel-verbose' to nil to silence compile-angel.
(setq compile-angel-verbose t)

(setq compile-angel-predicate-function
      (lambda (file)
        (and (not (file-in-directory-p file doom-user-dir))
             (not (file-in-directory-p file (expand-file-name "lisp" doom-emacs-dir)))
             (not (file-in-directory-p file (expand-file-name doom-modules-dir))))))

(compile-angel-on-load-mode)
(add-hook 'emacs-lisp-mode-hook #'compile-angel-on-save-local-mode)
```

(This ensures that the Doom Emacs Lisp files and modules are not compiled by compile-angel. This is important because `.el` files in these directories should never be compiled, or Doom may fail to load some of them correctly.)

## Frequently Asked Questions

### What are some interesting Emacs customizations to consider alongside compile-angel?

Below are a few interesting options:

```elisp
;; Ensure that quitting only occurs once Emacs finishes native compiling,
;; preventing incomplete or leftover compilation files in `/tmp`.
(setq native-comp-async-query-on-exit t)
(setq confirm-kill-processes t)

;; Non-nil means to native compile packages as part of their installation.
(setq package-native-compile t)

;; -------------------------------------------------
;; Show buffer when there is a warning.
;; (NOT RECOMMENDED, except during development).
;; -------------------------------------------------
;; (setq compile-angel-verbose t)
;; (setq compile-angel-byte-compile-report-issues t)
;;
;; (setq warning-minimum-level :warning)
;; (setq byte-compile-verbose t)
;; (setq byte-compile-warnings t)
;; (setq native-comp-async-report-warnings-errors t)
;; (setq native-comp-warning-on-missing-source t)
```

### How to exclude certain .el files from compilation in compile-angel?

You can exclude .el files from compilation by adding path suffixes to the `compile-angel-excluded-files` list.

For instance, the following excludes any path that ends with `suffix.el` (or its variations, such as `/path/ANYTHINGsuffix.el.gz` or `ANYTHINGsuffix.el.gz`) and exactly matches paths that end with `/filename.el` (including their variations, like `/filename.el.gz` or `ANYTHING/filename.el.gz`).

```elisp
;; Run the following before enabling `compile-angel-on-load-mode'
(push "suffix.el" compile-angel-excluded-files)
(push "/filename.el" compile-angel-excluded-files)

;; Run here: (compile-angel-on-load-mode)
```

If a path suffix in `compile-angel-excluded-files` ends with `.el`, `compile-angel` will automatically exclude the `.el.gz` variant of that file. For instance, specifying `suffix.el` will also exclude `suffix.el.gz`.

### How to exclude custom-file, recentf, savehist files?

You can exclude the custom-file, recentf, and savehist files using the following code snippet:
``` emacs-lisp
;; Exclude the custom-file, recentf, and savehist files
;;
;; Ensure that compile-angel is loaded using `require`, `use-package`, or
;; another package manager, as compile-angel-excluded-files is declared after
;; the package is loaded.
(with-eval-after-load "savehist"
  (push (concat "/" (file-name-nondirectory savehist-file))
        compile-angel-excluded-files))

(with-eval-after-load "recentf"
  (push (concat "/" (file-name-nondirectory recentf-save-file))
        compile-angel-excluded-files))

(with-eval-after-load "cus-edit"
  (push (concat "/" (file-name-nondirectory custom-file))
        compile-angel-excluded-files))

;; Enable the (compile-angel-on-load-mode) mode after the above
```

### How to enable or disable byte-compilation and native-compilation?

You can control whether *compile-angel* performs byte-compilation or native-compilation of your .el files by setting the following variables in your configuration:
- **`compile-angel-enable-byte-compile`**: Set this variable to `t` to enable byte-compilation. When enabled, *compile-angel* will generate .elc files for your .el files, making them load faster by converting them into bytecode. Set it to `nil` to disable byte-compilation.
- **`compile-angel-enable-native-compile`**: Set this variable to `t` to enable native-compilation, which generates machine code for supported systems, further improving performance. Set it to `nil` to disable native-compilation.

Example configuration:
```emacs-lisp
;; Enable both byte-compilation and native-compilation (default)
(setq compile-angel-enable-byte-compile t)
(setq compile-angel-enable-native-compile t)
```

### What's the point of using compile-angel? My Emacs compiles packages automatically anyway!

Emacs often skips the compilation of certain Elisp files. To verify this:

- Install `compile-angel`,
- Enable verbose mode: `(setq compile-angel-verbose t)`
- Enable the mode: `(compile-angel-on-load-mode)`

Observe whether `compile-angel` compiles any Elisp files (you will see "Wrote" `.elc` files in the `*Messages*` buffer). If it does, this indicates that Emacs missed compiling those files and that `compile-angel` can help improve the performance of your Emacs.

### Why not just use the package-recompile-all function?

The *package-recompile-all* function is effective for recompiling files within packages, but it misses other files that are not part of a package.

In the *compile-angel* author's configuration, for example, *package-recompile-all* skipped most of the local packages loaded using *use-package* with *:ensure nil* or *require*. Additionally, *package-recompile-all* does not compile transparently; the user must manually run it and wait for it to complete.

The *compile-angel* package, on the other hand, transparently compiles all packages without any user intervention. The user simply needs to enable *(compile-angel-on-load-mode)*.

### What is the impact on Emacs startup?

The author of compile-angel reports an Emacs startup time of 0.25 seconds with compile-angel enabled and 0.23 seconds without it. Feel free to share your own benchmarks.

### What's the difference between native and byte compiled?

Byte-compilation translates Elisp code into an intermediate bytecode .elc that is faster to load than .el files.

Native-compilation goes a step further by converting this bytecode into machine code, which is directly executed by the CPU without the need for an interpreter. Native-compilation significantly improves performance.

### What are some use-cases of compile-angel?

Emacs often misses the compilation of certain Elisp files.

One of the author's primary use cases involves maintaining numerous Emacs packages, which are synchronized into `~/.emacs.d` using automation scripts and `rsync` for testing during development. The author appreciates how compile-angel automatically compiles the files synchronized to the `~/.emacs.d` directory while working on these packages.

There are many other use cases as well. For example, some Emacs users prefer storing packages locally or in GitHub repositories, periodically updating them using `git pull`. This approach is often adopted for packages that are no longer actively maintained, enabling users to manage them independently. In such cases, compile-angel can seamlessly handle both byte-compiling and native-compiling these packages whenever local modifications are made.

### What is the difference between auto-compile and compile-angel?

Jonas Bernouli, the author of auto-compile, has made some design decisions that prevent it from guaranteeing that all .el packages are byte-compiled and native-compiled. For example, if the user deletes all the .elc files or if the .el files have never been compiled before, auto-compile won't recompile them. Here is a quote from Jonas Bernouli, aka *u/tarsius_*, the auto-compile author ([from this discussion](https://www.reddit.com/r/emacs/comments/1gmmnhn/comment/lwhtte2/?utm_source=share&utm_medium=web3x&utm_name=web3xcss&utm_term=1&utm_content=share_button)):
> Both [autocompile] modes only ever re-compile a source file when the
> respective byte code file already exists but is outdated. Otherwise
> they do not compile the source file. By "otherwise" I mean if:
>   - The *.elc exists but is newer than the corresponding *.el, OR
>   - The *.elc does not exist.
> In both cases the source file is not compiled, by design.

This is one of the reasons why opening an issue or submitting a pull request regarding the auto-compile issue above is pointless, as Jonas Bernouli is unlikely to merge it due to his design decision.

Here are the main differences between compile-angel and auto-compile:
- Compile-angel is optimized. It is fast enough that it is nearly imperceptible to the user.
- Compile-angel ensures that even when when the .elc file doesn't exist, the .el source file is compiled. Auto-compile, on the other hand, requires (by design, as explained above) an existing .elc file in order to compile.
- Compile-angel ensures that files are compiled before and after they are loaded, In addition to compiling the `.el` files loaded using *load* and *require*, also handles files that auto-compile misses, using the `after-load-functions` hook. This ensures that all files are byte-compiled and native-compiled.
- Compile-angel can exclude files from compilation using regular expressions in *compile-angel-excluded-files-regexps*.
- `compile-angel` can exclude files from compilation based on path suffixes listed in `compile-angel-excluded-files`. This list contains path suffixes such as `("loaddefs.el" "/cus-load.el" "/charprop.el")`, which excludes any path ending with `loaddefs.el` (or its variations, such as `loaddefs.el.gz`) and exactly matches paths ending with `/cus-load.el` and `/charprop.el` (including their variations, like `/cus-load.el.gz` and `/charprop.el.gz`). If a path in `compile-angel-excluded-files` ends with `.el`, it will automatically exclude the corresponding `.el.gz` variant when Emacs is configured to load `.el.gz` files.
- Compile-angel provides options to allow enabling and disabling specific functions that should be advised (load, require, etc.).
- Compile-angel allows enabling debug mode, which allows knowing exactly what compile-angel does. Additionally, compiled files and features are stored in variables that help identify what was compiled.
- *compile-angel-on-save-mode* supports compiling indirect buffers (clones).
- *compile-angel-on-load-mode* compiles features that have already been loaded to make sure that they are compiled.
- Compile-Angel can use caching to enhance performance when locating the .el file corresponding to a given feature. Auto-compile does not compile features.
- compile-angel-on-load-mode performs native compilation only when Emacs fails to do so. Explanation: When JIT compilation is enabled, loading a .elc file automatically triggers native compilation, making Emacs load the native-compiled version asynchronously and replacing the auto-compiled functions. (However, auto-compile disables native compilation by default, causing Emacs to skip native-compiling some files, even in save mode. When enabled, auto-compile compiles files before loading, but Emacs will still recompile them after loading the .elc file.)
- Compile-Angel double-checks after packages are loaded to ensure that Emacs properly performs native compilation when JIT is enabled, as Emacs sometimes skips native-compiling .elc files that should be JIT compiled.
- Prevent `byte-compile-file` from displaying Wrote messages in the *Messages* buffer unless `compile-angel-verbose` customization is set to `t`.

## Author and License

The *compile-angel* Emacs package has been written by [James Cherti](https://www.jamescherti.com/) and is distributed under terms of the GNU General Public License version 3, or, at your choice, any later version.

Copyright (C) 2024-2025 James Cherti

This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version. This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details. You should have received a copy of the GNU General Public License along with this program.

## Links

- [compile-angel.el @GitHub](https://github.com/jamescherti/compile-angel.el)
- [compile-angel.el @MELPA](https://melpa.org/#/compile-angel)
- For users who prefer compiling .el files from the command line: [elispcomp](https://github.com/jamescherti/elispcomp)

Other Emacs packages by the same author:
- [minimal-emacs.d](https://github.com/jamescherti/minimal-emacs.d): This repository hosts a minimal Emacs configuration designed to serve as a foundation for your vanilla Emacs setup and provide a solid base for an enhanced Emacs experience.
- [compile-angel.el](https://github.com/jamescherti/compile-angel.el): **Speed up Emacs!** This package guarantees that all .el files are both byte-compiled and native-compiled, which significantly speeds up Emacs.
- [outline-indent.el](https://github.com/jamescherti/outline-indent.el): An Emacs package that provides a minor mode that enables code folding and outlining based on indentation levels for various indentation-based text files, such as YAML, Python, and other indented text files.
- [vim-tab-bar.el](https://github.com/jamescherti/vim-tab-bar.el): Make the Emacs tab-bar Look Like Vim’s Tab Bar.
- [easysession.el](https://github.com/jamescherti/easysession.el): Easysession is lightweight Emacs session manager that can persist and restore file editing buffers, indirect buffers/clones, Dired buffers, the tab-bar, and the Emacs frames (with or without the Emacs frames size, width, and height).
- [elispcomp](https://github.com/jamescherti/elispcomp): A command line tool that allows compiling Elisp code directly from the terminal or from a shell script. It facilitates the generation of optimized .elc (byte-compiled) and .eln (native-compiled) files.
- [tomorrow-night-deepblue-theme.el](https://github.com/jamescherti/tomorrow-night-deepblue-theme.el): The Tomorrow Night Deepblue Emacs theme is a beautiful deep blue variant of the Tomorrow Night theme, which is renowned for its elegant color palette that is pleasing to the eyes. It features a deep blue background color that creates a calming atmosphere. The theme is also a great choice for those who miss the blue themes that were trendy a few years ago.
- [Ultyas](https://github.com/jamescherti/ultyas/): A command-line tool designed to simplify the process of converting code snippets from UltiSnips to YASnippet format.
- [dir-config.el](https://github.com/jamescherti/dir-config.el): Automatically find and evaluate .dir-config.el Elisp files to configure directory-specific settings.
- [flymake-bashate.el](https://github.com/jamescherti/flymake-bashate.el): A package that provides a Flymake backend for the bashate Bash script style checker.
- [flymake-ansible-lint.el](https://github.com/jamescherti/flymake-ansible-lint.el): An Emacs package that offers a Flymake backend for ansible-lint.
- [inhibit-mouse.el](https://github.com/jamescherti/inhibit-mouse.el): A package that disables mouse input in Emacs, offering a simpler and faster alternative to the disable-mouse package.
- [quick-sdcv.el](https://github.com/jamescherti/quick-sdcv.el): This package enables Emacs to function as an offline dictionary by using the sdcv command-line tool directly within Emacs.
- [enhanced-evil-paredit.el](https://github.com/jamescherti/enhanced-evil-paredit.el): An Emacs package that prevents parenthesis imbalance when using *evil-mode* with *paredit*. It intercepts *evil-mode* commands such as delete, change, and paste, blocking their execution if they would break the parenthetical structure.
