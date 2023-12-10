;=====================================================================
;用組合語言開發九子棋 | 08/12/2023
;=====================================================================

;=====================================================================
;手動編譯流程
;1)	ml /c /coff "game.asm"
;2)	Link /SUBSYSTEM:WINDOWS "game.obj"

;====================================================================


.486
option casemap	:none	;大小寫區分

;函式庫
include game.inc

;預先聲明一個函數
;函數原型名為WinMain，具有4個參數
WinMain proto :DWORD,:DWORD,:DWORD,:DWORD

;常數宣告
.CONST
    gameBoard equ 100

;帶有賦值的變數聲明
.DATA
    windowClassName     db 'Window',0
    windowTitle         db 'Nine Mens Morris',0

;尚未賦值的變數聲明
.DATA?
    instance   HINSTANCE ? ; 窗口實例
    arguments  LPSTR ?     ; 應用程式參數
    hInstance  HINSTANCE ?
    gameBoardBmp    dd  0


;啟動原始碼
.CODE
start:

    ;取得當前執行的實例的函數
    ;使用NULL讓它返回當前執行的實例
    ;同時將實例存入eax寄存器
    invoke GetModuleHandle, NULL ;將實例存入eax寄存器
    mov instance, eax  ;將eax中的實例值移動到變數 'instance' 中；mov 目標, 來源
    invoke GetCommandLine ;類似於GetModuleHandle，此函數獲取應用程式的參數；將參數存入eax寄存器
    mov arguments, eax ;將eax中的參數值移動到變數 'arguments' 中

    ;載入圖片
    invoke LoadBitmap, hInstance, gameBoard
    mov    gameBoardBmp, eax

    ;執行WinMain函數，並將變數 'instance' 和 'arguments' 傳遞為參數
    ;NULL表示沒有父或先前的實例，在這種情況下為空
    ;SW_SHOWDEFAULT表示顯示窗口的模式/方式
    invoke WinMain, instance, NULL, arguments, SW_SHOWDEFAULT

    ;以eax中的返回值退出進程
    invoke ExitProcess, eax

    ;繪製圖片的函數
    paintBackground proc _hdc:HDC,_hMemDC:HDC, _hMemDC2:HDC
        LOCAL rect   :RECT; RECT 結構定義了矩形左上角和右下角的坐標。

        ; 選擇 hBmp 作為背景圖片
        invoke SelectObject, _hMemDC2, gameBoardBmp
        
        ; 將 _hMemDC2 中的圖片複製到 _hMemDC，顯示背景
        invoke BitBlt, _hMemDC, 0, 0, 880, 880, _hMemDC2, 0, 0, SRCCOPY
        ret
    paintBackground endp

    ;具有4個參數的WinMain函數，已在第25行聲明過prototype
    WinMain proc hInst:HINSTANCE, hPrevInst:HINSTANCE, CmdLine:LPSTR, CmdShow:DWORD
        ;本地變數
        LOCAL isWindow:WNDCLASSEX  ;窗口結構，包含窗口的特性
        LOCAL message:MSG             ;處理發送到窗口的消息的變數，例如按鈕的動作
        LOCAL handler:HWND          ;窗口的處理程序，用於識別窗口

        ;設置窗口結構
        mov isWindow.cbSize, SIZEOF WNDCLASSEX
        mov isWindow.style, CS_HREDRAW or CS_VREDRAW
        mov isWindow.lpfnWndProc, OFFSET WndProc
        mov isWindow.cbClsExtra, NULL
        mov isWindow.cbWndExtra, NULL
        push instance      ;指定窗口屬於哪個實例
        pop isWindow.hInstance
        mov isWindow.hbrBackground, COLOR_WINDOW + 1
        mov isWindow.lpszMenuName, NULL
        mov isWindow.lpszClassName, OFFSET windowClassName
        invoke LoadIcon, NULL, IDI_APPLICATION
        mov isWindow.hIcon, eax
        mov isWindow.hIconSm, eax
        invoke LoadCursor, NULL, IDC_ARROW
        mov isWindow.hCursor, eax

        ;註冊窗口類別
        invoke RegisterClassEx, addr isWindow
        
        ;創建窗口
        invoke CreateWindowEx,
            NULL,
            ADDR windowClassName,
            ADDR windowTitle,
            WS_OVERLAPPEDWINDOW,
            CW_USEDEFAULT, ;窗口尺寸
			CW_USEDEFAULT, 
			CW_USEDEFAULT, ;窗口位置
			CW_USEDEFAULT,
            NULL,
            NULL,
            hInst,
            NULL

        ;前述函數將處理程序存入eax
        mov handler, eax

        ;顯示窗口
        invoke ShowWindow, handler, SW_SHOWNORMAL

        ;通過傳遞處理程序更新窗口
        invoke UpdateWindow, handler

        ;循環以處理消息
        .WHILE TRUE
            ;執行讀取消息的函數
            invoke GetMessage, ADDR message, NULL, 0, 0
            .BREAK .IF (!eax)

            ;處理消息
            invoke TranslateMessage, ADDR message
            invoke DispatchMessage, ADDR message
        .ENDW

        ;將消息參數移到eax
        mov  eax, message.wParam

        ;以eax的值結束並返回
        ret
    WinMain endP

    ;處理消息的函數
    WndProc proc hWnd:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM
        ;檢查消息是否為關閉窗口
        .IF uMsg==WM_DESTROY
            ;執行退出
            invoke PostQuitMessage, NULL
        .ELSE
            ;使用默認消息處理
            invoke DefWindowProc, hWnd, uMsg, wParam,lParam
            ret
        .ENDIF

        ;將eax設為0
        xor eax, eax
        ret
    WndProc endp



    ;=====================================================
;原始碼結束
end start