;=====================================================================
;用組合語言開發九子棋 | 08/12/2023
;=====================================================================

;=====================================================================
;手動編譯流程
;1)	ml /c /coff "game.asm"
;2)	Link /SUBSYSTEM:WINDOWS "game.obj"

;====================================================================


.486
.model flat, stdcall  
option casemap	:none	;大小寫區分

include battle_royale.inc ;函式庫
; #########################################################################

; ------------------------------------------------------------------------
; MACROS are a method of expanding text at assembly time. This allows the
; programmer a tidy and convenient way of using COMMON blocks of code with
; the capacity to use DIFFERENT parameters in each block.
; ------------------------------------------------------------------------

      ; 1. szText
      ; A macro to insert TEXT into the code section for convenient and 
      ; more intuitive coding of functions that use byte data as text.

      szText MACRO Name, Text:VARARG
        LOCAL lbl
          jmp lbl
            Name db Text,0
          lbl:
        ENDM

      ; 2. m2m
      ; There is no mnemonic to copy from one memory location to another,
      ; this macro saves repeated coding of this process and is easier to
      ; read in complex code.

      m2m MACRO M1, M2
        push M2
        pop  M1
      ENDM

      ; 3. return
      ; Every procedure MUST have a "ret" to return the instruction
      ; pointer EIP back to the next instruction after the call that
      ; branched to it. This macro puts a return value in eax and
      ; makes the "ret" instruction on one line. It is mainly used
      ; for clear coding in complex conditionals in large branching
      ; code such as the WndProc procedure.

      return MACRO arg
        mov eax, arg
        ret
      ENDM

; #########################################################################
; ----------------------------------------------------------------------
; Prototypes are used in conjunction with the MASM "invoke" syntax for
; checking the number and size of parameters passed to a procedure. This
; improves the reliability of code that is written where errors in
; parameters are caught and displayed at assembly time.
; ----------------------------------------------------------------------

        WinMain   PROTO :DWORD,:DWORD,:DWORD,:DWORD
        WndProc   PROTO :DWORD,:DWORD,:DWORD,:DWORD
        TopXY     PROTO :DWORD,:DWORD
        PlaySound PROTO STDCALL :DWORD,:DWORD,:DWORD                    
; #########################################################################
; ------------------------------------------------------------------------
; This is the INITIALISED data section meaning that data declared here has
; an initial value. You can also use an UNINIALISED section if you need
; data of that type [ .data? ]. Note that they are different and occur in
; different sections.
; ------------------------------------------------------------------------
;常數宣告
.const
    background  equ 100
    player      equ 1001

    CREF_TRANSPARENT  EQU 00FFFFFFh
;帶有賦值的變數聲明
.data
    windowClassName     db 'Window',0
    szDisplayName         db 'Battle Royale',0
    paintstruct   PAINTSTRUCT <>
    buffer        db 256 dup(0)

    backgroundBmp    dd  0      ;圖片檔
    playerBmp        dd  0
    playerY          dd  250     ; 玩家位置
    playerX          dd  250 

;尚未賦值的變數聲明
.data?
    hInstance   HINSTANCE ? ; 窗口實例
    arguments  LPSTR ?     ; 應用程式參數
    
    hWnd HWND ?
; #########################################################################
; ------------------------------------------------------------------------
; This is the start of the code section where executable code begins. This
; section ending with the ExitProcess() API function call is the only
; GLOBAL section of code and it provides access to the WinMain function
; with the necessary parameters, the instance handle and the command line
; address.
; ------------------------------------------------------------------------
.code
start:
    invoke GetModuleHandle, NULL 
    mov hInstance, eax  ;將eax中的實例值移動到變數 'instance' 中；mov 目標, 來源

    ;載入圖片
    invoke LoadBitmap, hInstance, background
    mov    backgroundBmp, eax
    invoke LoadBitmap, hInstance, player
    mov    playerBmp , eax

    invoke WinMain, hInstance, NULL, arguments, SW_SHOWDEFAULT
    invoke ExitProcess, eax

    ;繪製圖片的函數
    paintBackground proc _hdc:HDC,_hMemDC:HDC, _hMemDC2:HDC
        LOCAL rect   :RECT; RECT 結構定義了矩形左上角和右下角的坐標。

        ; 選擇 hBmp 作為背景圖片
        invoke SelectObject, _hMemDC2, backgroundBmp
        
        ; 將 _hMemDC2 中的圖片複製到 _hMemDC，顯示背景
        invoke BitBlt, _hMemDC, 0, 0, 1792, 1024, _hMemDC2, 0, 0, SRCCOPY
        ret
    paintBackground endp

    paintPlayer proc _hdc:HDC, _hMemDC:HDC, _hMemDC2:HDC 
        invoke SelectObject, _hMemDC2, playerBmp
        invoke TransparentBlt, _hMemDC, playerX, playerY,25, 25, _hMemDC2,0, 0, 25 ,25, CREF_TRANSPARENT
        ret
    paintPlayer endp

    screenUpdate proc
        LOCAL hMemDC:HDC
        LOCAL hMemDC2:HDC
        LOCAL hBitmap:HDC
        LOCAL hDC:HDC

        invoke BeginPaint, hWnd, ADDR paintstruct   ;BeginPaint函數為繪畫準備指定的窗口，並用有關繪畫的信息填充 PAINTSTRUCT 結構。
        mov hDC, eax
        invoke CreateCompatibleDC, hDC  ;CreateCompatibleDC函數創建與指定設備兼容的內存設備內容 (DC)
        mov hMemDC, eax
        invoke CreateCompatibleDC, hDC ; for double buffering
        mov hMemDC2, eax
        invoke CreateCompatibleBitmap, hDC, 1792, 1024
        mov hBitmap, eax

        invoke SelectObject, hMemDC, hBitmap

        invoke paintBackground, hDC, hMemDC, hMemDC2
        invoke paintPlayer, hDC, hMemDC, hMemDC2
        invoke BitBlt, hDC, 0, 0, 1792, 1024, hMemDC, 0, 0, SRCCOPY

        invoke DeleteDC, hMemDC     ;DeleteDC 函數刪除指定的設備內容 (DC)。
        invoke DeleteDC, hMemDC2
        invoke DeleteObject, hBitmap
        invoke EndPaint, hWnd, ADDR paintstruct ;EndPaint 函數標記指定窗口中的繪製結束。每次調用 BeginPaint 函數時都需要此函數，但僅在繪製完成後才需要
        ret
    screenUpdate endp   

    ; 把 WinMain 程序放在這裡來創建窗口本身
    WinMain proc hInst     :DWORD,
                hPrevInst :DWORD,
                CmdLine   :DWORD,
                CmdShow   :DWORD

        LOCAL wc   :WNDCLASSEX
        LOCAL msg  :MSG     ;MSG結構包含來自Thread的消息隊列的信息

        LOCAL Wwd  :DWORD
        LOCAL Wht  :DWORD
        LOCAL Wtx  :DWORD
        LOCAL Wty  :DWORD

        szText szClassName,"Windowclass1"
        
        ;==================================================
        ; Fill WNDCLASSEX structure with required variables
        ;==================================================

        mov wc.cbSize,         sizeof WNDCLASSEX
        mov wc.style,          CS_HREDRAW or CS_VREDRAW \
                            or CS_BYTEALIGNWINDOW
        mov wc.lpfnWndProc,    offset WndProc       ;本視窗的訊息處裡函式
        mov wc.cbClsExtra,     NULL                 ;附加引數
        mov wc.cbWndExtra,     NULL                 ;附加引數
        m2m wc.hInstance,      hInst                ;當前應用程式的例向控制代碼
        mov wc.hbrBackground,  COLOR_BTNFACE+1      ;視窗背景色
        mov wc.lpszMenuName,   NULL                 ;視窗選單
        mov wc.lpszClassName,  offset szClassName   ;視窗結構體的名稱 ;給視窗結構體命名，CreateWindow函式將根據視窗結構體名稱來建立視窗
        ; RC 文件中的圖標 ID
        invoke LoadIcon,hInst, IDI_APPLICATION      ;視窗圖式
        mov wc.hIcon,          eax
        invoke LoadCursor,NULL,IDC_ARROW            ;視窗游標
        mov wc.hCursor,        eax
        mov wc.hIconSm,        0

        invoke RegisterClassEx, ADDR wc             ;註冊視窗


        invoke CreateWindowEx,WS_EX_OVERLAPPEDWINDOW, \
                            ADDR szClassName, \
                            ADDR szDisplayName,\
                            WS_OVERLAPPEDWINDOW,\
                            ;Wtx,Wty,Wwd,Wht,
                            CW_USEDEFAULT,CW_USEDEFAULT, 1792, 1024, \      ;窗口大小
                            NULL,NULL,\
                            hInst,NULL


        mov   hWnd,eax  ; copy return value into handle DWORD

        invoke LoadMenu,hInst,600                 ; load resource menu
        invoke SetMenu,hWnd,eax                   ; set it to main window

        invoke ShowWindow,hWnd,SW_SHOWNORMAL      ; display the window
        invoke UpdateWindow,hWnd                  ; update the display

        ;===================================
        ; Loop until PostQuitMessage is sent
        ;===================================

        StartLoop:
        invoke GetMessage,ADDR msg,NULL,0,0         ; get each message
        cmp eax, 0                                  ; exit if GetMessage()
        je ExitLoop                                 ; returns zero
        invoke TranslateMessage, ADDR msg           ; translate it
        invoke DispatchMessage,  ADDR msg           ; send it to message proc
        jmp StartLoop
        ExitLoop:

        return msg.wParam   ;wParam:指定有關消息的附加信息。確切含義取決於消息成員的值

    WinMain endp

    ;處理消息的函數
    WndProc proc hWin   :DWORD,
        uMsg   :DWORD,
        wParam :DWORD,
        lParam :DWORD

        LOCAL hDC    :DWORD
        LOCAL Ps     :PAINTSTRUCT
        LOCAL rect   :RECT
        LOCAL Font   :DWORD
        LOCAL Font2  :DWORD
        LOCAL hOld   :DWORD
        LOCAL memDC  :DWORD

        .if uMsg == WM_CREATE
            mov     playerX, 250
            mov     playerY, 250
        .elseif uMsg == WM_PAINT    ;當系統或其他應用程序請求繪製應用程序窗口的一部分時，會發送 WM_PAINT 消息
            invoke screenUpdate
        .elseif uMsg == WM_ERASEBKGND
            mov eax, 1
        .elseif uMsg == WM_KEYDOWN
            .if wParam == VK_W
                .if playerY > 20
                  sub playerY, 10
                .endif
            .endif                 
            .if wParam == VK_S
                .if playerY < 934
                  add playerY, 10
                .endif
            .endif          
            .if wParam == VK_A
                .if playerX > 20
                  sub playerX, 10
                .endif
            .endif
            .if wParam == VK_D
                .if playerX < 1712
                  add playerX, 10
                .endif
            .endif 
            invoke InvalidateRect, hWnd, NULL, TRUE
        .elseif uMsg == WM_DESTROY                                        ; if the user closes our window 
            invoke PostQuitMessage,NULL          
        .else
            invoke DefWindowProc, hWin, uMsg, wParam, lParam                         ; quit our application 
        .endif                            ; quit our application 
        ret
    WndProc endp



    ;=====================================================
;原始碼結束
end start