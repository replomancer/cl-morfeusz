;;
;; cl-morfeusz.lisp --- Common Lisp bindings to Morfeusz library.
;;
;; Copyright (c) 2013, Łukasz Kożuchowski
;; All rights reserved.
;;
;; Redistribution and use in source and binary forms, with or without
;; modification, are permitted provided that the following conditions are met:
;;
;;     * Redistributions of source code must retain the above copyright
;;       notice, this list of conditions and the following disclaimer.
;;
;;     * Redistributions in binary form must reproduce the above copyright
;;       notice, this list of conditions and the following disclaimer in the
;;       documentation and/or other materials provided with the distribution.
;;
;; THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
;; ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
;; WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
;; DISCLAIMED. IN NO EVENT SHALL <COPYRIGHT HOLDER> BE LIABLE FOR ANY
;; DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
;; (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
;; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
;; ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
;; (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
;; SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

(cffi:define-foreign-library libmorfeusz
    (:unix (:or "libmorfeusz.so.0" "libmorfeusz.so"))
    (t (:default "libmorfeusz"))) ;; FIXME

(cffi:use-foreign-library libmorfeusz)

(defpackage :morfeusz
  (:use :common-lisp :cffi)
  (:export
        :make-interp-morf
        :interp-morf-p
        :interp-morf-s
        :interp-morf-k
        :interp-morf-forma
        :interp-morf-haslo
        :interp-morf-interp
        :copy-interp-morf
	:ENCODING-OPTION
	:UTF-8
	:ISO8859-2
	:CP1250
	:CP852
	:WHITESPACE-OPTION
	:SKIP-WHITESPACE
	:KEEP-WHITESPACE
        :analyse
        :about
        :set-option))

(in-package :morfeusz)

(defcstruct _InterpMorf
    ;; The explanation below has been copied from morfeusz.h:
    ;;
    ;; The result of analysis is  a directed acyclic graph with numbered
    ;; nodes representing positions  in text (points _between_ segments)
    ;; and edges representing interpretations of segments that span from
    ;; one node to another.  E.g.,
    ;;
    ;;     {0,1,"ja","ja","ppron12:sg:nom:m1.m2.m3.f.n1.n2:pri"}
    ;;     |
    ;;     |      {1,2,"został","zostać","praet:sg:m1.m2.m3:perf"}
    ;;     |      |
    ;;   __|  ____|   __{2,3,"em","być","aglt:sg:pri:imperf:wok"}
    ;;  /  \ /     \ / \
    ;; * Ja * został*em *
    ;; 0    1       2   3
    ;;
    ;; Note that the word 'zostałem' got broken into 2 separate segments.
    ;;
    ;; The structure below describes one edge of this DAG:
    ;;
  (p :int)
  (k :int)
  (forma :string)
  (haslo :string)
  (interp :string))


(defstruct interp-morf
  ;; s instead of p, because interp-morf-p is the structure type predicate
  s k forma haslo interp)


(defcfun ("morfeusz_about" about) :string
  "Return a string with information on library version and its authors")


(defcfun ("morfeusz_set_option" set-option) :int
  "Set option (see constants in cl-morfeusz.lisp)"
  (option :int) ( value :int))


(defcfun ("morfeusz_analyse" _morfeusz-analyse) :pointer
  (text :string))


(defun analyse (text)
  "Analyse the text, return a list of interp-morf structures"
  (let ((ptr (_morfeusz-analyse text)))
    (loop for i from 0
          for segm = (with-foreign-slots ((p k forma haslo interp)
                                          (mem-aref ptr '_InterpMorf i)
                                          _InterpMorf)
                       (make-interp-morf :s p :k k :forma forma :haslo haslo
                                         :interp interp))
          for s = (interp-morf-s segm)
          while (/= s -1)
              collect segm)))


;;
;; Options-related constants
;;

;; encoding option
(defconstant ENCODING-OPTION 1)

;; available encodings
(defconstant UTF-8 8)
(defconstant ISO8859-2 88592)
(defconstant CP1250 1250)
(defconstant CP852 852)

;; whitespace option
(defconstant WHITESPACE-OPTION 2)

;; values available for whitespace option
(defconstant SKIP-WHITESPACE 0)
(defconstant KEEP-WHITESPACE 2)
