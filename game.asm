;=====================================================================
;用組合語言開發九子棋 | 08/12/2023
;=====================================================================

;=====================================================================
;手動編譯流程
;1)	\masm32\bin\ml /c /coff "main.asm"
;2)	\masm32\bin\PoLink /SUBSYSTEM:WINDOWS "main.obj"

;====================================================================


.486
option casemap	:none	;大小寫區分

;函式庫
include C:\masm32\include\masm32rt.inc
include C:\Masm32\include\winmm.inc 
include C:\Masm32\Include\msimg32.inc

includelib C:\masm32\lib\user32.lib
includelib C:\masm32\lib\kernel32.lib
includelib C:\Masm32\Lib\msimg32.lib
includelib C:\Masm32\lib\winmm.lib
includelib C:\Masm32\Lib\masm32.lib

;預先聲明一個函數
;函數原型名為WinMain，具有4個參數
WinMain proto :DWORD,:DWORD,:DWORD,:DWORD


;帶有賦值的變數聲明
.DATA
windowClassName     db 'Window',0
windowTitle         db 'Nine Mens Morris',0

;尚未賦值的變數聲明
.DATA?
instancia   HINSTANCE ? ; 窗口實例
argumentos  LPSTR ?     ; 應用程式參數

    ;啟動原始碼
    .CODE
start:
    ;=====================================================

    ;取得當前執行的實例的函數
    ;使用NULL讓它返回當前執行的實例
    ;同時將實例存入eax寄存器
    invoke GetModuleHandle, NULL ;將實例存入eax寄存器
    mov instancia, eax  ;將eax中的實例值移動到變數 'instancia' 中；mov 目標, 來源
    invoke GetCommandLine ;類似於GetModuleHandle，此函數獲取應用程式的參數；將參數存入eax寄存器
    mov argumentos, eax ;將eax中的參數值移動到變數 'argumentos' 中

    ;執行WinMain函數，並將變數 'instancia' 和 'argumentos' 傳遞為參數
    ;NULL表示沒有父或先前的實例，在這種情況下為空
    ;SW_SHOWDEFAULT表示顯示窗口的模式/方式
    invoke WinMain, instancia, NULL, argumentos, SW_SHOWDEFAULT

    ;以eax中的返回值退出進程
    invoke ExitProcess, eax

    ;具有4個參數的WinMain函數，已在第25行聲明過prototype
    WinMain proc hInst:HINSTANCE, hPrevInst:HINSTANCE, CmdLine:LPSTR, CmdShow:DWORD
        ;本地變數
        LOCAL estVentana:WNDCLASSEX  ;窗口結構，包含窗口的特性
        LOCAL mensaje:MSG             ;處理發送到窗口的消息的變數，例如按鈕的動作
        LOCAL manejador:HWND          ;窗口的處理程序，用於識別窗口

        ;設置窗口結構
        mov estVentana.cbSize, SIZEOF WNDCLASSEX
        mov estVentana.style, CS_HREDRAW or CS_VREDRAW
        mov estVentana.lpfnWndProc, OFFSET WndProc
        mov estVentana.cbClsExtra, NULL
        mov estVentana.cbWndExtra, NULL
        push instancia      ;指定窗口屬於哪個實例
        pop estVentana.hInstance
        mov estVentana.hbrBackground, COLOR_WINDOW + 1
        mov estVentana.lpszMenuName, NULL
        mov estVentana.lpszClassName, OFFSET windowClassName
        invoke LoadIcon, NULL, IDI_APPLICATION
        mov estVentana.hIcon, eax
        mov estVentana.hIconSm, eax
        invoke LoadCursor, NULL, IDC_ARROW
        mov estVentana.hCursor, eax

        ;註冊窗口類別
        invoke RegisterClassEx, addr estVentana
        
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
        mov manejador, eax

        ;顯示窗口
        invoke ShowWindow, manejador, SW_SHOWNORMAL

        ;通過傳遞處理程序更新窗口
        invoke UpdateWindow, manejador

        ;循環以處理消息
        .WHILE TRUE
            ;執行讀取消息的函數
            invoke GetMessage, ADDR mensaje, NULL, 0, 0
            .BREAK .IF (!eax)

            ;處理消息
            invoke TranslateMessage, ADDR mensaje
            invoke DispatchMessage, ADDR mensaje
        .ENDW

        ;將消息參數移到eax
        mov  eax, mensaje.wParam

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
            Invoke DefWindowProc, hWnd, uMsg, wParam,lParam
            ret
        .ENDIF

        ;將eax設為0
        xor eax, eax
        ret
    WndProc endp

    ;=====================================================
;原始碼結束
end start