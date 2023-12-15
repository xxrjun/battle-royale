; main.inc

; #########################################################################
; Standard Windows Libraries
; #########################################################################

; Windows Base APIs
; include \masm32\include\windows.inc
includelib \masm32\lib\kernel32.lib

; User Interface APIs
; include \masm32\include\user32.inc
includelib \masm32\lib\user32.lib

; Graphics Device Interface (GDI) APIs
; include \masm32\include\gdi32.inc
includelib \masm32\LIB\gdi32.lib

; Common Controls Library
; include \masm32\include\Comctl32.inc
includelib \masm32\LIB\Comctl32.lib

; Common Dialog Box Library
; include \masm32\include\comdlg32.inc
includelib \masm32\LIB\comdlg32.lib

; Shell API Library
; include \masm32\include\shell32.inc
includelib \masm32\LIB\shell32.lib

; Windows Multimedia API
include \masm32\include\winmm.inc
includelib \masm32\lib\winmm.lib

; Image Manipulation APIs
include \masm32\include\msimg32.inc
includelib \masm32\lib\msimg32.lib

; OLE Automation APIs
; include \masm32\include\oleaut32.inc
includelib \masm32\lib\oleaut32.lib

; #########################################################################
; MASM32 Runtime Library and Utilities
; #########################################################################

; MASM32 Standard Library and Runtime Utilities
include \masm32\include\masm32rt.inc
includelib \masm32\lib\masm32.lib

; Visual C++ Runtime Library
includelib \masm32\lib\msvcrt.lib

; Cryptographic API Library
include \masm32\include\cryptdll.inc
includelib \masm32\lib\cryptdll.lib

; #########################################################################
