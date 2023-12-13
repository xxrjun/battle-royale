      include \masm32\include\masm32rt.inc

      ; ---------------------------------------------
      ; main include file with equates and structures
      ; ---------------------------------------------
      include \masm32\include\windows.inc

      

      ; -------------------------------------------------------------
      ; In MASM32, each include file created by the L2INC.EXE utility
      ; has a matching library file. If you need functions from a
      ; specific library, you use BOTH the include file and library
      ; file for that library.
      ; -------------------------------------------------------------
      includelib \Masm32\lib\winmm.lib
      include \masm32\include\windows.inc
      include \masm32\include\user32.inc
      include \masm32\include\kernel32.inc
      include \MASM32\INCLUDE\gdi32.inc
      include \Masm32\include\winmm.inc 
      includelib \masm32\lib\user32.lib
      includelib \masm32\lib\kernel32.lib
      includelib \MASM32\LIB\gdi32.lib
      include \masm32\include\masm32rt.inc
      include \masm32\include\windows.inc
      include \masm32\include\user32.inc
      include \masm32\include\kernel32.inc
      include \MASM32\INCLUDE\gdi32.inc
      include \MASM32\INCLUDE\Comctl32.inc
      include \MASM32\INCLUDE\comdlg32.inc
      include \MASM32\INCLUDE\shell32.inc
      INCLUDE \Masm32\Include\msimg32.inc
      INCLUDE \Masm32\Include\oleaut32.inc
      includelib \masm32\lib\user32.lib
      includelib \masm32\lib\kernel32.lib
      includelib \MASM32\LIB\gdi32.lib
      includelib \MASM32\LIB\Comctl32.lib
      includelib \MASM32\LIB\comdlg32.lib
      includelib \MASM32\LIB\shell32.lib
      INCLUDELIB \Masm32\Lib\msimg32.lib
      INCLUDELIB \Masm32\Lib\oleaut32.lib
      INCLUDELIB \Masm32\Lib\msvcrt.lib
      INCLUDELIB \Masm32\Lib\masm32.lib
      INCLUDELIB \Masm32\Lib\cryptdll.lib
      INCLUDE \MASM32\INCLUDE\cryptdll.inc