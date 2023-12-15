;=====================================================================
;用組合語言開發大逃殺 | 08/12/2023
;=====================================================================

;=====================================================================
;手動編譯流程
;1)	ml /c /coff "game.asm"
;2)	Link /SUBSYSTEM:WINDOWS "game.obj"

;====================================================================


.686
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
    WM_FINISH equ WM_USER+100h
    background  equ 100
    player      equ 1001
    zombie      equ 1002
    gadget      equ 1003
    MAX_ZOMBIES equ 3
    CREF_TRANSPARENT  EQU 00FFFFFFh
;帶有賦值的變數聲明
.data
    windowClassName     db 'Window',0
    szDisplayName         db 'Battle Royale',0
    paintstruct   PAINTSTRUCT <>
    zombieInfoBuffer        db 256 dup(0)

    backgroundBmp    dd  0      ;圖片檔
    playerBmp        dd  0
    zombieBmp        dd  0
    gadgetBmp        dd  0
    playerX          dd  250     ; 玩家位置
    playerY          dd  250 
    playerSpeed      dd  10
    activeZombieInitX          dd  550     ; 殭屍位置
    activeZombieInitY          dd  550 
    zombieSpeed      dd  5
    beenHit          dd  0

    gadgetX         dd  884
    gadgetY         dd  500
    gadgetType      dd  0
    gadgetAppear    dd  0

    keyWPressed dd 0
    keyAPressed dd 0
    keySPressed dd 0
    keyDPressed dd 0

    zombies zombieObj MAX_ZOMBIES dup({0, 0, 0})

;尚未賦值的變數聲明
.data?
    hInstance   HINSTANCE ? ; 窗口實例
    arguments  LPSTR ?     ; 應用程式參數
    threadID    DWORD ? 
    hEventStart HANDLE ?
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
    invoke LoadBitmap, hInstance, zombie
    mov    zombieBmp , eax
    invoke LoadBitmap, hInstance, gadget
    mov    gadgetBmp , eax

    invoke WinMain, hInstance, NULL, arguments, SW_SHOWDEFAULT
    invoke ExitProcess, eax

    ;繪製圖片的函數
    paintBackground proc _hdc:HDC,_hMemDC:HDC, _hMemDC2:HDC
        LOCAL rect   :RECT; RECT 結構定義了矩形左上角和右下角的坐標。
        invoke SelectObject, _hMemDC2, backgroundBmp
        invoke BitBlt, _hMemDC, 0, 0, 1792, 1024, _hMemDC2, 0, 0, SRCCOPY
        ret
    paintBackground endp

    paintPlayer proc _hdc:HDC, _hMemDC:HDC, _hMemDC2:HDC 
        invoke SelectObject, _hMemDC2, playerBmp
        invoke TransparentBlt, _hMemDC, playerX, playerY,25, 25, _hMemDC2,0, 0, 25 ,25, CREF_TRANSPARENT
        ret
    paintPlayer endp

    paintZombie proc _hdc:HDC, _hMemDC:HDC, _hMemDC2:HDC
        LOCAL zombieX :DWORD
        LOCAL zombieY :DWORD

        ; mov ecx, 0                  ; 初始化計數器
        ; lea ebx, zombies            ; 獲取殭屍陣列的地址
        ; DrawZombiesLoop:
        ;     cmp [ebx + zombieObj.active], 0
        ;     je SkipZombie           ; 如果殭屍未激活，跳過繪製

        ;     ; 獲取殭屍的位置
        ;     mov eax, [ebx + zombieObj.x] ; 將殭屍的 x 坐標移動到 eax 寄存器
        ;     mov zombieX, eax           ; 再將 eax 寄存器的值移動到 zombieX 變數

        ;     mov eax, [ebx + zombieObj.y] ; 將殭屍的 y 坐標移動到 eax 寄存器
        ;     mov zombieY, eax           ; 再將 eax 寄存器的值移動到 zombieY 變數

        ;     ; 繪製殭屍
        ;     invoke SelectObject, _hMemDC2, zombieBmp
        ;     invoke TransparentBlt, _hMemDC, zombieX, zombieY, 25, 25, _hMemDC2, 0, 0, 25, 25, CREF_TRANSPARENT

        ;     SkipZombie:
        ;     add ebx, TYPE zombieObj ; 移動到下一個殭屍
        ;     inc ecx
        ;     cmp ecx, MAX_ZOMBIES
        ;     jl DrawZombiesLoop      ; 繼續循環直到處理完所有殭屍
        lea ebx, zombies    ; 獲取殭屍陣列的地址

        ; 繪製第一個殭屍
        cmp [ebx + zombieObj.active], 0
        jne DrawFirstZombie
        jmp SkipFirstZombie
        DrawFirstZombie:
            mov eax, [ebx + zombieObj.x]
            mov zombieX, eax
            mov eax, [ebx + zombieObj.y]
            mov zombieY, eax
            invoke SelectObject, _hMemDC2, zombieBmp
            invoke TransparentBlt, _hMemDC, zombieX, zombieY, 25, 25, _hMemDC2, 0, 0, 25, 25, CREF_TRANSPARENT
        SkipFirstZombie:

        ; 繪製第二個殭屍
        add ebx, TYPE zombieObj
        cmp [ebx + zombieObj.active], 0
        jne DrawSecondZombie
        jmp SkipSecondZombie
        DrawSecondZombie:
            mov eax, [ebx + zombieObj.x]
            mov zombieX, eax
            mov eax, [ebx + zombieObj.y]
            mov zombieY, eax
            invoke SelectObject, _hMemDC2, zombieBmp
            invoke TransparentBlt, _hMemDC, zombieX, zombieY, 25, 25, _hMemDC2, 0, 0, 25, 25, CREF_TRANSPARENT
        SkipSecondZombie:

        ; 繪製第三個殭屍
        add ebx, TYPE zombieObj
        cmp [ebx + zombieObj.active], 0
        jne DrawThirdZombie
        jmp SkipThirdZombie
        DrawThirdZombie:
            mov eax, [ebx + zombieObj.x]
            mov zombieX, eax
            mov eax, [ebx + zombieObj.y]
            mov zombieY, eax
            invoke SelectObject, _hMemDC2, zombieBmp
            invoke TransparentBlt, _hMemDC, zombieX, zombieY, 25, 25, _hMemDC2, 0, 0, 25, 25, CREF_TRANSPARENT
        SkipThirdZombie:        

        ret
    paintZombie endp

    paintGadget proc _hdc:HDC,_hMemDC:HDC, _hMemDC2:HDC
        cmp gadgetAppear, 1     ; 檢查 gadgetAppear 是否為true(1)
        jne paintGadgetEnd      ; 如果不為1，跳轉到過程的末尾

        invoke SelectObject, _hMemDC2, gadgetBmp
        invoke TransparentBlt, _hMemDC, gadgetX, gadgetY, 25, 25, _hMemDC2, 0, 0, 25, 25, CREF_TRANSPARENT

        paintGadgetEnd:
        ret
    paintGadget  endp

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
        invoke paintZombie, hDC, hMemDC, hMemDC2
        invoke paintGadget, hDC, hMemDC, hMemDC2
        invoke BitBlt, hDC, 0, 0, 1792, 1024, hMemDC, 0, 0, SRCCOPY

        invoke DeleteDC, hMemDC     ;DeleteDC 函數刪除指定的設備內容 (DC)。
        invoke DeleteDC, hMemDC2
        invoke DeleteObject, hBitmap
        invoke EndPaint, hWnd, ADDR paintstruct ;EndPaint 函數標記指定窗口中的繪製結束。每次調用 BeginPaint 函數時都需要此函數，但僅在繪製完成後才需要
        ret
    screenUpdate endp   

    updatePlayerPosition PROC
        mov eax, keyWPressed
        .if eax != 0
            .if playerY > 20
                sub playerY, 10
            .endif
        .endif
        mov eax, keySPressed
        .if eax != 0
            .if playerY < 934
                add playerY, 10
            .endif
        .endif
        mov eax, keyAPressed
        .if eax != 0
            .if playerX > 20
                sub playerX, 10
            .endif
        .endif
        mov eax, keyDPressed
        .if eax != 0
            .if playerX < 1712
                add playerX, 10
            .endif
        .endif
        invoke InvalidateRect, hWnd, NULL, TRUE
    ret
    updatePlayerPosition ENDP

formatZombiesInfo PROC
    LOCAL zombieX :DWORD
    LOCAL zombieY :DWORD
    LOCAL isActive:DWORD
    LOCAL bufferPos:DWORD
    LOCAL formattedLength:DWORD

    mov ecx, 0                   ; 初始化計數器
    lea ebx, zombies             ; 獲取殭屍陣列的地址
    lea edi, zombieInfoBuffer    ; 獲取資訊緩衝區的地址
    mov bufferPos, edi           ; 記住緩衝區的起始位置

    FormatLoop:
        cmp ecx, MAX_ZOMBIES
        jge EndFormat            ; 如果處理完所有殭屍，結束循環

        ; 從殭屍陣列中獲取資訊
        mov eax, [ebx + zombieObj.x]
        mov zombieX, eax
        mov eax, [ebx + zombieObj.y]
        mov zombieY, eax
        mov eax, [ebx + zombieObj.active]
        mov isActive, eax

        ; 格式化到緩衝區中
        cmp ecx, 2
        je  ToWrite
        jmp Skip

        ToWrite:
        invoke wsprintf, addr zombieInfoBuffer, chr$("X:%d,Y:%d,A:%d"), zombieX, zombieY, isActive
        mov formattedLength, eax   ; 獲取格式化字串的長度

        Skip:
        ; 更新緩衝區位置
        add edi, 30   ; 根據格式化字串長度更新緩衝區指針
        add ebx, SIZEOF zombieObj    ; 移動到下一個殭屍
        inc ecx
        jmp FormatLoop

    EndFormat:
        ; 在緩衝區的最後添加結束字元
        mov byte ptr [edi], 0

    ret
formatZombiesInfo ENDP



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
            mov     hEventStart, eax
            mov eax, offset ThreadProc
            invoke CreateThread, NULL, NULL, eax, NULL, NORMAL_PRIORITY_CLASS, ADDR threadID 
            invoke SetTimer, hWin, 1, 3000, NULL ; 設置計時器，ID為1，殭屍生成觸發器
            invoke SetTimer, hWin, 2, 5000, NULL ; 設置計時器，ID為2，道具生成觸發器
            ;生成20~1500的隨機整數並賦予給gadgetX
        .elseif uMsg == WM_TIMER
            .if wParam == 1 ;遍歷十隻殭屍，將一隻未激活的殭屍激活，如果十隻都被激活則不做事
                mov ecx, 0
                lea ebx, zombies
                ActivateZombieLoop:
                    cmp [ebx + zombieObj.active], 0
                    je ActivateZombie

                    add ebx, TYPE zombieObj
                    inc ecx
                    cmp ecx, MAX_ZOMBIES
                    jl ActivateZombieLoop
                jmp EndActivateZombie

                ActivateZombie:
                    ; 激活殭屍並並設定初始值位置
                    mov [ebx + zombieObj.x], 550
                    mov [ebx + zombieObj.y], 550
                    mov [ebx + zombieObj.active], 1
                EndActivateZombie:
            .elseif wParam == 2 ;生成新道具
                mov gadgetAppear, 1
            .endif 
        .elseif uMsg == WM_PAINT    ;當系統或其他應用程序請求繪製應用程序窗口的一部分時，會發送 WM_PAINT 消息
            invoke screenUpdate
        .elseif uMsg == WM_ERASEBKGND ;避免畫面更新閃爍
            mov eax, 1
        .elseif uMsg == WM_KEYDOWN
            .if wParam == VK_I
                invoke formatZombiesInfo
                invoke MessageBox, hWin, ADDR zombieInfoBuffer, ADDR szDisplayName, MB_OK
            .elseif wParam == VK_W
                mov keyWPressed, 1
            .elseif wParam == VK_S
                mov keySPressed, 1
            .elseif wParam == VK_A
                mov keyAPressed, 1
            .elseif wParam == VK_D
                mov keyDPressed, 1
            .endif
            invoke updatePlayerPosition
        .elseif uMsg == WM_KEYUP
            .if wParam == VK_W
                mov keyWPressed, 0
            .elseif wParam == VK_S
                mov keySPressed, 0
            .elseif wParam == VK_A
                mov keyAPressed, 0
            .elseif wParam == VK_D
                mov keyDPressed, 0
            .endif        
            invoke updatePlayerPosition
        .elseif uMsg == WM_FINISH
            invoke InvalidateRect, hWnd, NULL, TRUE ;;addr rect, TRUE
        .elseif uMsg == WM_DESTROY                                        ; if the user closes our window 
            invoke PostQuitMessage,NULL          
        .else
            invoke DefWindowProc, hWin, uMsg, wParam, lParam                         ; quit our application 
        .endif                            ; quit our application 
        ret
    WndProc endp

moveZombies PROC
    LOCAL zombieX:DWORD
    LOCAL zombieY:DWORD

    mov ecx, 0                  ; 初始化計數器
    lea ebx, zombies            ; 獲取殭屍陣列的地址
    MoveZombiesLoop:
        cmp [ebx + zombieObj.active], 0
        je SkipZombieInLoop     ; 如果殭屍未激活，跳過此殭屍

        ; 獲取殭屍的位置
        mov eax, [ebx + zombieObj.x] ; 將殭屍的 x 坐標移動到 eax 寄存器
        mov [zombieX], eax           ; 再將 eax 寄存器的值移動到 zombieX 變數

        mov eax, [ebx + zombieObj.y] ; 將殭屍的 y 坐標移動到 eax 寄存器
        mov [zombieY], eax           ; 再將 eax 寄存器的值移動到 zombieY 變數


        ; 殭屍 X 軸的移動
        mov edx, zombieX
        .if playerX > edx
            add zombieX, 5
        .elseif playerX < edx
            sub zombieX, 5
        .endif

        ; 殭屍 Y 軸的移動
        mov edx, zombieY
        .if playerY > edx
            add zombieY, 5
        .elseif playerY < edx
            sub zombieY, 5
        .endif

        ; 更新殭屍的位置
        mov eax, zombieX
        mov [ebx + zombieObj.x], eax
        mov eax, zombieY
        mov [ebx + zombieObj.y], eax

        SkipZombieInLoop:
        add ebx, TYPE zombieObj ; 移動到下一個殭屍
        inc ecx
        cmp ecx, MAX_ZOMBIES
        jl MoveZombiesLoop      ; 繼續循環直到處理完所有殭屍

    ret
moveZombies ENDP

checkZombieCollision PROC
    LOCAL zombieX:DWORD
    LOCAL zombieY:DWORD

    mov ecx, 0                   ; 初始化計數器
    lea ebx, zombies             ; 獲取殭屍陣列的地址
    CheckCollisionLoop:
        cmp [ebx + zombieObj.active], 0
        je SkipZombieInCollisionCheck    ; 如果殭屍未激活，跳過此殭屍

        ; 獲取殭屍的位置
        mov eax, [ebx + zombieObj.x]
        mov [zombieX], eax
        mov eax, [ebx + zombieObj.y]
        mov [zombieY], eax

        ; 判斷 X 座標是否重疊
        mov eax, playerX;eax存判斷boundary
        mov edx, zombieX
        add edx, 25     ;edx存判斷子(殭屍座標+殭屍size)
        .if edx > eax;X small boundary
            add eax, 50
            .if edx < eax;X large boundary
                ; 判斷 Y 座標是否重疊
                mov eax, playerY
                mov edx, zombieY
                add edx, 25
                .if edx > eax;Y small boundary
                    add eax, 50
                    .if edx < eax;Y large boundary
                        mov beenHit, 1; 發生碰撞
                        ;invoke MessageBox, hWnd, ADDR zombieInfoBuffer, ADDR szDisplayName, MB_OK
                    .endif
                .endif
            .endif
        .endif

        SkipZombieInCollisionCheck:
        add ebx, TYPE zombieObj     ; 移動到下一個殭屍
        inc ecx
        cmp ecx, MAX_ZOMBIES
        jl CheckCollisionLoop        ; 繼續循環直到處理完所有殭屍

    ret
checkZombieCollision ENDP

checkGadgetCollision PROC
    ; 判斷 X 座標是否重疊
    mov eax, playerX;eax存判斷boundary
    mov edx, gadgetX
    add edx, 25     ;edx存判斷子(道具座標+道具size)
    .if edx > eax;X small boundary
        add eax, 50
        .if edx < eax;X large boundary
            ; 判斷 Y 座標是否重疊
            mov eax, playerY
            mov edx, gadgetY
            add edx, 25
            .if edx > eax;Y small boundary
                add eax, 50
                .if edx < eax;Y large boundary
                    mov gadgetAppear, 0; 發生碰撞
                    ;invoke MessageBox, hWnd, ADDR zombieInfoBuffer, ADDR szDisplayName, MB_OK
                .endif
            .endif
        .endif
    .endif

    ret
checkGadgetCollision ENDP


ThreadProc PROC USES ecx Param:DWORD
  ; 線程循環
  ThreadLoop:
    invoke Sleep, 100  ; 等待 100 毫秒

    invoke moveZombies
    invoke checkZombieCollision
    invoke checkGadgetCollision

    invoke SendMessage, hWnd, WM_FINISH, NULL, NULL


    ; 檢查是否需要退出線程
    ; （這需要一個額外的機制來設置某個全局變量，以指示線程何時應該結束）
    ; 例如:
    ; mov eax, [bThreadShouldExit]
    ; cmp eax, 1
    ; je ExitThreadLoop

    jmp ThreadLoop

  ExitThreadLoop:
  ret
ThreadProc ENDP

    ;=====================================================
;原始碼結束
end start


