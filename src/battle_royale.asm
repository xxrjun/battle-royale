; ======================================================================
;
; NCU CSIE Assembly Language and System Programming Fall 2023, Final Project
;
; Project Name: Battle Royale
; Student Info: 
;   - MIS 109403019 xxrjun (https://github.com/xxrjun)
;   - MIS 109403021 FuHarrison (https://github.com/FuHarrison)
;
;  _______               __        __      __                  _______                                 __                   ______    ______   __       __  ________ 
; /       \             /  |      /  |    /  |                /       \                               /  |                 /      \  /      \ /  \     /  |/        |
; $$$$$$$  |  ______   _$$ |_    _$$ |_   $$ |  ______        $$$$$$$  |  ______   __    __   ______  $$ |  ______        /$$$$$$  |/$$$$$$  |$$  \   /$$ |$$$$$$$$/ 
; $$ |__$$ | /      \ / $$   |  / $$   |  $$ | /      \       $$ |__$$ | /      \ /  |  /  | /      \ $$ | /      \       $$ | _$$/ $$ |__$$ |$$$  \ /$$$ |$$ |__    
; $$    $$<  $$$$$$  |$$$$$$/   $$$$$$/   $$ |/$$$$$$  |      $$    $$< /$$$$$$  |$$ |  $$ | $$$$$$  |$$ |/$$$$$$  |      $$ |/    |$$    $$ |$$$$  /$$$$ |$$    |   
; $$$$$$$  | /    $$ |  $$ | __   $$ | __ $$ |$$    $$ |      $$$$$$$  |$$ |  $$ |$$ |  $$ | /    $$ |$$ |$$    $$ |      $$ |$$$$ |$$$$$$$$ |$$ $$ $$/$$ |$$$$$/    
; $$ |__$$ |/$$$$$$$ |  $$ |/  |  $$ |/  |$$ |$$$$$$$$/       $$ |  $$ |$$ \__$$ |$$ \__$$ |/$$$$$$$ |$$ |$$$$$$$$/       $$ \__$$ |$$ |  $$ |$$ |$$$/ $$ |$$ |_____ 
; $$    $$/ $$    $$ |  $$  $$/   $$  $$/ $$ |$$       |      $$ |  $$ |$$    $$/ $$    $$ |$$    $$ |$$ |$$       |      $$    $$/ $$ |  $$ |$$ | $/  $$ |$$       |
; $$$$$$$/   $$$$$$$/    $$$$/     $$$$/  $$/  $$$$$$$/       $$/   $$/  $$$$$$/   $$$$$$$ | $$$$$$$/ $$/  $$$$$$$/        $$$$$$/  $$/   $$/ $$/      $$/ $$$$$$$$/ 
;                                                                                 /  \__$$ |                                                                         
;                                                                                 $$    $$/                                                                          
;                                                                                  $$$$$$/                                                                                                                                      
; 
; ======================================================================

; Assembler directives for 32-bit Assembly code

.686                   ; minimum processor needed for 32 bit
.model flat, stdcall 
option casemap :none   ; set code to case sensitive

; ======================================================================

INCLUDE battle_royale.inc

; ======================================================================

; ----------------------------------------------------------------------
; Macros Definitions
; ----------------------------------------------------------------------

; ----------------------------------------------------------------------
; szText MACRO
; Description: Insert TEXT into the code segment
; Parameters:
;   Name - Name of the string
;   Text - Text to be stored in the string
; ----------------------------------------------------------------------
szText MACRO Name, Text:VARARG
  LOCAL lbl       
    jmp lbl        
      Name DB Text,0  
    lbl:           
ENDM

; ----------------------------------------------------------------------
; m2m MACRO
; Description: Copy a value from one memory location to another
; Parameters:
;   M1 - Destination memory location
;   M2 - Source memory location
; ----------------------------------------------------------------------
m2m MACRO M1, M2
  push M2   
  pop  M1  
ENDM

; ----------------------------------------------------------------------
; return MACRO
; Description: Returns a value from a procedure
; Parameters:
;   arg - Value to be returned
; ----------------------------------------------------------------------
return MACRO arg
  mov eax, arg  
  ret           
ENDM

; ======================================================================

; ----------------------------------------------------------------------
; Prototypes for procedures
; Usage: Invoke procedureName, arg1, arg2, ...
; ----------------------------------------------------------------------

; ----------------------------------------------------------------------
; WinMain Procedure Prototype 
; Description: The main entry point for a Windows application
; Parameters:
;   hInst - Handle to the current instance of the application
;   hPrevInst - Handle to the previous instance of the application
;   CmdLine - Command line for the application
;   CmdShow - How the window is to be shown
; Reference: : https://learn.microsoft.com/en-us/windows/win32/api/winbase/nf-winbase-winmain
; ----------------------------------------------------------------------
WinMain PROTO :DWORD, :DWORD, :DWORD, :DWORD

; ----------------------------------------------------------------------
; WndProc 
; Description: A callback function, which you define in your application, that processes messages sent to a window.
; Parameters:
;   hWin - Handle to the window
;   uMsg - Message identifier
;   wParam - Additional message information
;   lParam - Additional message information
; Reference: https://learn.microsoft.com/en-us/windows/win32/api/winuser/nc-winuser-wndproc
; ----------------------------------------------------------------------
WndProc PROTO :DWORD,:DWORD,:DWORD,:DWORD 

TopXY PROTO :DWORD,:DWORD 
PlaySound PROTO STDCALL :DWORD,:DWORD,:DWORD  
ExitProcess PROTO, dwExitCode:DWORD
PaintBackground PROTO _hdc:HDC, _hMemDC:HDC, _hMemDC2:HDC
PlaySound PROTO STDCALL :DWORD,:DWORD,:DWORD  

; ======================================================================

.const
    menuBackground EQU 101
    gameBackground EQU 102
    endWithSurvivorBackground EQU 103
    endWithoutSurvivorBackground EQU 104
    player EQU  1001
    zombie  EQU 1002
    gadgetLighting EQU 1003
    gadgetIce EQU 1004
    gadgetStar EQU 1005
    gadgetMoney EQU 1006
    playerSpeedBuff EQU 1010
    zombieIceDebuff EQU 1011
    playerStarBuff EQU 1012
    playerScoreBuff EQU 1013

    MAX_ZOMBIES EQU 15 ; 殭屍數量上限
    CREF_TRANSPARENT  EQU 00000000h  ;去背之顏色(此為黑色)
    WM_FINISH EQU WM_USER + 100h

    TIMER_BUFF equ 105
    TIMER_SCORE equ 106
    TIMER_SEED  equ 107
    TIMER_SEED2  equ 108
    TIMER_ZOMBIE  equ 109
    TIMER_GADGET  equ 110

    ; Playback should start again at the beginning when the end of the content is reached.
    ; ref: https://learn.microsoft.com/en-us/previous-versions/ms710970(v=vs.85)
    MCI_PLAY_LOOP EQU MCI_DGV_PLAY_REPEAT

; ======================================================================

.data
    ; Window Viewport (FHD)
    windowWidth  DWORD 1280    
    windowHeight DWORD 784 ; 720 + 64   
    
    menuChoice DWORD ?
    inputKey BYTE ?     ; stores the user's input key
    CommandLine   DD 0

    startingGameMsg BYTE "Starting Battle Royale Game", 0
    szDisplayGameName BYTE "Battle Royale", 0
    singlePlayerGameMsg BYTE "Single-player Game", 0
    szUpdateScreenMsg BYTE "Updating the screen...", 0
    gameMode DD 1       ; 1 = single player, 2 = multiplayer
    gameState BYTE 1    ; 1 = menu, 2 = game, 3 = game over

    szLoadBitmapFailedMsg BYTE "Failed to load bitmap", 0

    windowClassName     DB 'Window',0
    szDisplayName         DB 'Battle Royale',0
    paintstruct   PAINTSTRUCT <>
    infoBuffer        DB 256 dup(0)
    scoreBuffer             DB 256 dup(0)

    ; game state: 1 = menu, 2 = game, 3 = game over
    GAMESTATE        DD  1

    ; bitmaps
    menuPageBmp     DD  0
    gameBackgroundBmp    DD  0
    playerBmp        DD  0
    zombieBmp        DD  0
    gadgetLightingBmp      DD 0
    gadgetIceBmp      DD 0
    gadgetStarBmp       DD 0
    gadgetMoneyBmp       DD 0
    playerSpeedBuffBmp  DD 0
    zombieIceDebuffBmp  DD 0
    playerStarBuffBmp  DD 0
    playerScoreBuffBmp  DD 0
    endWithoutSurvivorBackgroundBmp DD 0
    

    ; bitmaps' witdth & height
    playerWidth   DD 38
    playerHeight   DD 78
    zombieWidth   DD 35
    zombieHeight   DD 95
    gadgetWidth   DD 45
    gadgetHeight   DD 45


    ; in game variables
    playerX          DD  250     ; 玩家位置
    playerY          DD  250 
    playerSpeed      DD  10
    beenHit          DD  0      ;是否觸碰到殭屍
    gadgetX         DD  884     
    gadgetY         DD  500
    gadgetType      DD  0       ; 1-閃電,2-冰凍,3-無敵,4-分數加速累積
    gadgetAppear    DD  0       
    buffOn          DD  0       ;玩家是否在道具效果生效期間
    buffType        DD  0

    ; user input
    keyWPressed DD 0
    keyAPressed DD 0
    keySPressed DD 0
    keyDPressed DD 0

    zombies zombieObj MAX_ZOMBIES dup({0, 0, 0, 0})

    score  DD  0
    scoreIncrease DD  0

    seedA  DD  109403021
    seedB  DD  109403019

     ; music and sound effects
    backgroundMusic DB "../assets/sounds/backgroundmusic.mp3", 0
    buttonInputSound DB "../assets/sounds/button-input-sound-effects.mp3", 0
    startGameSound DB "../assets/sounds/start-game-sound-effects.mp3", 0
    exitGameSound DB "../assets/sounds/exit-game-sound-effects.mp3", 0

    ; - MCI_OPEN_PARMS Structure ( API=mciSendCommand ) -
    open_dwCallback     DD ?
    open_wDeviceID     DD ?
    open_lpstrDeviceType  DD ?
    open_lpstrElementName  DD ?
    open_lpstrAlias     DD ?

    ; - MCI_GENERIC_PARMS Structure ( API=mciSendCommand ) -
    generic_dwCallback   DD ?

    ; - MCI_PLAY_PARMS Structure ( API=mciSendCommand ) -
    play_dwCallback     DD ?
    play_dwFrom       DD ?
    play_dwTo        DD ?   

; ======================================================================

.data?
    hInstance   HINSTANCE ? ; handle to the current instance
    arguments  LPSTR ?     ; 應用程式參數
    threadID    DWORD ? 
    hEventStart HANDLE ?
    hWnd HWND ? ; handle to the main window

; ======================================================================

.code
start:
    invoke GetModuleHandle, NULL 
    mov hInstance, eax  ; provides the instance handle

    ; load bitmaps images into memory
    invoke LoadBitmap, hInstance, gameBackground
    test   eax, eax
    jz     LoadBitmapFailed
    mov    gameBackgroundBmp, eax

    invoke LoadBitmap, hInstance, menuBackground
    test   eax, eax
    jz     LoadBitmapFailed
    mov    menuPageBmp, eax

    invoke LoadBitmap, hInstance, player
    test   eax, eax
    jz     LoadBitmapFailed
    mov    playerBmp , eax

    invoke LoadBitmap, hInstance, zombie
    test   eax, eax
    jz     LoadBitmapFailed
    mov    zombieBmp , eax

    invoke LoadBitmap, hInstance, gadgetLighting
    test   eax, eax
    jz     LoadBitmapFailed
    mov    gadgetLightingBmp , eax

    invoke LoadBitmap, hInstance, gadgetIce
    test   eax, eax
    jz     LoadBitmapFailed
    mov    gadgetIceBmp , eax
    
    invoke LoadBitmap, hInstance, gadgetStar
    test   eax, eax
    jz     LoadBitmapFailed
    mov    gadgetStarBmp , eax
    
    invoke LoadBitmap, hInstance, gadgetMoney
    test   eax, eax
    jz     LoadBitmapFailed
    mov    gadgetMoneyBmp , eax

    invoke LoadBitmap, hInstance, playerSpeedBuff 
    test   eax, eax
    jz     LoadBitmapFailed
    mov    playerSpeedBuffBmp , eax

    invoke LoadBitmap, hInstance, zombieIceDebuff
    test   eax, eax
    jz     LoadBitmapFailed
    mov    zombieIceDebuffBmp , eax

    invoke LoadBitmap, hInstance, playerStarBuff
    test   eax, eax
    jz     LoadBitmapFailed
    mov    playerStarBuffBmp , eax

    invoke LoadBitmap, hInstance, playerScoreBuff
    test   eax, eax
    jz     LoadBitmapFailed
    mov    playerScoreBuffBmp , eax

    invoke LoadBitmap, hInstance, endWithoutSurvivorBackground
    test   eax, eax
    jz     LoadBitmapFailed
    mov    endWithoutSurvivorBackgroundBmp , eax
    
    invoke WinMain, hInstance, NULL, arguments, SW_SHOWDEFAULT
    invoke ExitProcess, eax ; cleanup & return to operating system

    LoadBitmapFailed:
        invoke StdOut, ADDR szLoadBitmapFailedMsg
        invoke ExitProcess, 0

    ; ----------------------------------------------------------------------

    ;隨機數產生器(生產lowerLimit~upperLimit間隨機整數)
    randomNumberGenerator PROC lowerLimit :DWORD, upperLimit :DWORD, seed : DWORD
        ; 計算範圍大小
        mov ebx, upperLimit
        sub ebx, lowerLimit
        add ebx, 1        ; 範圍大小 = upperLimit - lowerLimit + 1
        ; 生成隨機數
        mov eax, seed    ; 使用種子
        xor edx, edx
        div ebx           ; 除以範圍大小
        mov eax, edx
        add eax, lowerLimit       ; 添加偏移量
        ret
    randomNumberGenerator ENDP

    ; ----------------------------------------------------------------------

    ;初始化所有遊玩(GAMESTATE=2)要用到的變數
    initGameplay PROC
        ; 初始化玩家
        mov playerX, 100
        mov playerY, 100
        mov playerSpeed, 10

        ; 初始化殭屍
        lea ebx, zombies
        mov ecx, MAX_ZOMBIES
        InitializeZombieLoop:
            mov dword ptr [ebx + zombieObj.x], 0
            mov dword ptr [ebx + zombieObj.y], 0
            mov dword ptr [ebx + zombieObj.active], 0
            mov dword ptr [ebx + zombieObj.speed], 0
            add ebx, TYPE zombieObj
            loop InitializeZombieLoop
            
        ; 初始化道具
        mov gadgetX, 884
        mov gadgetY, 500
        mov gadgetType, 0
        mov gadgetAppear, 0
        mov buffOn, 0
        mov buffType, 0

        ;其他初始化
        mov beenHit, 0
        mov score, 0
        mov scoreIncrease, 7  ;分數累加速度
        ;初始化buffer
        lea edi, scoreBuffer ; 將 scoreBuffer 的地址加載到 edi 寄存器
        mov ecx, 256        ; 設置循環計數為 256（scoreBuffer 的大小）
        InitializeLoop:
            mov byte ptr [edi], 0 ; 將當前指向的字節設置為 0
            inc edi               ; 移動到下一個字節
            loop InitializeLoop   ; 循環直到 ecx 為 0
      
        ret
    initGameplay ENDP

    ; ----------------------------------------------------------------------

    ;繪製遊戲背景畫面
    paintBackground PROC _hdc:HDC, _hMemDC:HDC, _hMemDC2:HDC
        ; 繪製背景
        .if(GAMESTATE == 1)
            invoke SelectObject, _hMemDC2, menuPageBmp
        .elseif(GAMESTATE == 2)
            invoke SelectObject, _hMemDC2, gameBackgroundBmp
        .elseif(GAMESTATE == 3)
            invoke SelectObject, _hMemDC2, endWithoutSurvivorBackgroundBmp
        .endif
        
        invoke BitBlt, _hMemDC, 0, 0, windowWidth, windowHeight, _hMemDC2, 0, 0, SRCCOPY
        ret
    paintBackground ENDP

    ; ----------------------------------------------------------------------

    ;繪製分數欄
    paintScoreBar PROC _hdc:HDC, _hMemDC:HDC, _hMemDC2:HDC
        LOCAL rect: RECT  ; RECT 結構定義了矩形左上角和右下角的坐標。

        ; 格式化分數並寫入 scoreBuffer
        invoke wsprintf, addr scoreBuffer, chr$("SCORE: %d "), score
        ; ; 設置文本顏色
        ; invoke SetTextColor, _hMemDC, 00FF8800h

        ; 設置字體和顏色
        ; ref: https://learn.microsoft.com/zh-tw/windows/win32/api/wingdi/nf-wingdi-createfonta
        invoke CreateFontA, 30, 0, 0, 0, FW_NORMAL, FALSE, FALSE, FALSE, ANSI_CHARSET, OUT_DEFAULT_PRECIS, CLIP_DEFAULT_PRECIS, DEFAULT_QUALITY, DEFAULT_PITCH, NULL
        invoke SelectObject, _hMemDC, eax
        invoke SetTextColor, _hMemDC, 00FFFFFFh ; 白色

        ; 設置背景和邊框
        invoke CreateSolidBrush, 005F5F5Fh; 灰色
        invoke SelectObject, _hMemDC, eax
        invoke SetBkMode, _hMemDC, TRANSPARENT

        ; 設置繪製文本的矩形區域
        mov   rect.left, 540
        mov   rect.top, 20
        mov   rect.right, 740
        mov   rect.bottom, 60  

        invoke RoundRect, _hMemDC, rect.left, rect.top, rect.right, rect.bottom, 15, 15 ; 圓角矩形背景
        ; 繪製文本
        invoke DrawText, _hMemDC, addr scoreBuffer, -1, addr rect, DT_CENTER or DT_VCENTER or DT_SINGLELINE

        ret
    paintScoreBar ENDP

    ; ----------------------------------------------------------------------

    ;繪製玩家
    paintPlayer PROC _hdc:HDC, _hMemDC:HDC, _hMemDC2:HDC
        .if(buffOn == 1)
            .if(buffType == 1)
                invoke SelectObject, _hMemDC2, playerSpeedBuffBmp
            .elseif(buffType == 3)
                invoke SelectObject, _hMemDC2, playerStarBuffBmp
            .elseif(buffType == 4)
                invoke SelectObject, _hMemDC2, playerScoreBuffBmp
            .else
                invoke SelectObject, _hMemDC2, playerBmp
            .endif
        .else
            invoke SelectObject, _hMemDC2, playerBmp
        .endif
          invoke TransparentBlt, _hMemDC, playerX, playerY, playerWidth, playerHeight, _hMemDC2, 0, 0, playerWidth, playerHeight, CREF_TRANSPARENT
      ret
    paintPlayer ENDP

    ; ----------------------------------------------------------------------

    ;繪製所有殭屍
    paintZombie PROC _hdc:HDC, _hMemDC:HDC, _hMemDC2:HDC
        LOCAL zombieX :DWORD
        LOCAL zombieY :DWORD

        mov ecx, 0                  ; 初始化計數器
        lea ebx, zombies            ; 獲取殭屍陣列的地址
        DrawZombiesLoop:
            cmp [ebx + zombieObj.active], 0
            je SkipZombie           ; 如果殭屍未激活，跳過繪製

            ; 獲取殭屍的位置
            mov eax, [ebx + zombieObj.x] 
            mov zombieX, eax             

            mov eax, [ebx + zombieObj.y] 
            mov zombieY, eax            
            
            ; 繪製殭屍
            push ecx
            .if (buffOn == 1)
                .if (buffType == 2)
                    invoke SelectObject, _hMemDC2, zombieIceDebuffBmp
                .else
                    invoke SelectObject, _hMemDC2, zombieBmp
                .endif
            .else
                invoke SelectObject, _hMemDC2, zombieBmp
            .endif

            invoke TransparentBlt, _hMemDC, zombieX, zombieY, zombieWidth, zombieHeight, _hMemDC2, 0, 0, zombieWidth, zombieHeight, CREF_TRANSPARENT
            pop ecx

        SkipZombie:
            add ebx, TYPE zombieObj ; 移動到下一個殭屍
            inc ecx
            cmp ecx, MAX_ZOMBIES
            jl DrawZombiesLoop      ; 繼續循環直到處理完所有殭屍

        ret
    paintZombie ENDP

    ; ----------------------------------------------------------------------
    playSound proc uses ebx lpstrSound:DWORD
        mov   ebx, lpstrSound
        mov   open_lpstrDeviceType, 0h
        mov   open_lpstrElementName, ebx
        invoke mciSendCommandA, 0, MCI_OPEN, MCI_OPEN_ELEMENT, OFFSET open_dwCallback
        cmp   eax, 0h
        je    play_sound
        jmp   end_play_sound

        play_sound:
            invoke mciSendCommandA, open_wDeviceID, MCI_PLAY, MCI_NOTIFY, offset play_dwCallback
            invoke mciSendCommandA, open_wDeviceID, MCI_CLOSE, 0, 0
        end_play_sound:
            ret
    playSound endp

    ; ----------------------------------------------------------------------

    ;繪製道具
    paintGadget PROC _hdc:HDC,_hMemDC:HDC, _hMemDC2:HDC

        .if (gadgetAppear == 1)
            .if (gadgetType == 1)
                invoke SelectObject, _hMemDC2, gadgetLightingBmp
            .elseif (gadgetType == 2)
                invoke SelectObject, _hMemDC2, gadgetIceBmp
            .elseif (gadgetType == 3)
                invoke SelectObject, _hMemDC2, gadgetStarBmp
            .elseif (gadgetType == 4)
                invoke SelectObject, _hMemDC2, gadgetMoneyBmp
            .endif
            invoke TransparentBlt, _hMemDC, gadgetX, gadgetY, gadgetWidth, gadgetHeight, _hMemDC2, 0, 0, gadgetWidth, gadgetHeight, CREF_TRANSPARENT
        .endif

        ret
    paintGadget  ENDP

    ; ----------------------------------------------------------------------

    ;更新遊戲畫面
    updateScrenn PROC
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
        invoke CreateCompatibleBitmap, hDC, windowWidth, windowHeight
        mov hBitmap, eax

        invoke SelectObject, hMemDC, hBitmap

        invoke paintBackground, hDC, hMemDC, hMemDC2
        .if(GAMESTATE == 2)
            invoke paintGadget, hDC, hMemDC, hMemDC2
            invoke paintZombie, hDC, hMemDC, hMemDC2
            invoke paintPlayer, hDC, hMemDC, hMemDC2
            invoke paintScoreBar, hDC, hMemDC, hMemDC2
        .elseif(GAMESTATE == 3)
            invoke paintScoreBar, hDC, hMemDC, hMemDC2
        .endif
        invoke BitBlt, hDC, 0, 0, windowWidth, windowHeight, hMemDC, 0, 0, SRCCOPY

        invoke DeleteDC, hMemDC     ;DeleteDC 函數刪除指定的設備內容 (DC)。
        invoke DeleteDC, hMemDC2
        invoke DeleteObject, hBitmap
        invoke EndPaint, hWnd, ADDR paintstruct ;EndPaint 函數標記指定窗口中的繪製結束。每次調用 BeginPaint 函數時都需要此函數，但僅在繪製完成後才需要
        ret
    updateScrenn ENDP   

    ; ----------------------------------------------------------------------

    ;更新玩家位置
    updatePlayerPosition PROC
        mov edx, playerSpeed
        .if keyWPressed == 1
            .if playerY > 20
                sub playerY, edx
            .endif
        .endif 
        .if keySPressed == 1
          mov eax, windowHeight
          mov ebx, playerHeight
          sub eax, ebx
          sub eax, 100
            .if playerY < eax
                add playerY, edx
            .endif
        .endif
        .if keyAPressed == 1
            .if playerX > 20
                sub playerX, edx
            .endif
        .endif
        .if keyDPressed == 1
            mov eax, windowWidth
            mov ebx, playerHeight
            sub eax, ebx
            sub eax, 5
            .if playerX < eax
                add playerX, edx
            .endif
        .endif
        invoke InvalidateRect, hWnd, NULL, TRUE
    ret
    updatePlayerPosition ENDP

    ; ----------------------------------------------------------------------

    ;激活新殭屍
    activateZombie PROC zombieSpeed :DWORD;遍歷十隻殭屍，將一隻未激活的殭屍激活，如果全部都被激活則不做事
        mov ecx, 0
        lea ebx, zombies
        ActivateZombieLoop:
            cmp [ebx + zombieObj.active], 0
            je ToActivateZombie

            add ebx, TYPE zombieObj
            inc ecx
            cmp ecx, MAX_ZOMBIES
            jl ActivateZombieLoop
        jmp EndActivateZombie

        ToActivateZombie:
            ; 激活殭屍並設定初始值位置
            mov [ebx + zombieObj.x], 550      ;[此處調整殭屍生成位置]
            mov [ebx + zombieObj.y], 550
            mov [ebx + zombieObj.active], 1
            mov eax, zombieSpeed
            mov [ebx + zombieObj.speed], eax
        EndActivateZombie:
        ret
    activateZombie ENDP

    ; ----------------------------------------------------------------------

    ; The main entry point for a Windows application
    WinMain PROC hInst     :DWORD,
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


        ;================================
        ; Calculate window size & position
        ;================================

        ; get screen dimensions
        mov eax, windowWidth   
        mov Wwd, eax           
        mov eax, windowHeight 
        mov Wht, eax           

        ; calculate top left X & Y co-ordinates
        invoke GetSystemMetrics, SM_CXSCREEN 
        invoke TopXY, Wwd, eax
        mov Wtx, eax

        invoke GetSystemMetrics, SM_CYSCREEN 
        invoke TopXY, Wht, eax
        mov Wty, eax

        ; ==================================
        ; Center the window on the screen
        ; ==================================
        invoke CreateWindowEx, WS_EX_OVERLAPPEDWINDOW,
                                ADDR szClassName,
                                ADDR szDisplayGameName,
                                WS_OVERLAPPEDWINDOW,
                                Wtx, Wty, Wwd, Wht,
                                NULL, NULL,
                                hInst, NULL

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

    WinMain ENDP

    ; ----------------------------------------------------------------------

    ; Processes messages sent to a window
    WndProc proc hWin :DWORD,
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

         ; message handling
        .if uMsg == WM_COMMAND
            ;------------------------------------------------------------------
            ; WM_COMMAND message is sent when the user selects a command item
            ; such as a menu item, control, or accelerator key combination.
            ; ref: https://learn.microsoft.com/zh-tw/windows/win32/menurc/wm-command
            ;------------------------------------------------------------------
            
            ;======== menu commands ========

            .if wParam == 1000 ; if the user selects the Exit menu item
                invoke SendMessage,hWin,WM_SYSCOMMAND,SC_CLOSE,NULL    
            .elseif wParam == 2000  ; if the user selects the About menu item
                szText TheMsg,"Please visit: https://github.com/xxrjun/battle-royale"
                invoke MessageBox,hWin,ADDR TheMsg,ADDR szDisplayGameName,MB_OK
            .endif
        .elseif uMsg == WM_CREATE
            ; ---------------------------------------------------------------------
            ; WM_CREATE message is sent when an application requests that a window
            ; be created by calling the CreateWindowEx or CreateWindow function.
            ; ref: https://learn.microsoft.com/zh-tw/windows/win32/winmsg/wm-create
            ; ---------------------------------------------------------------------
            mov     hEventStart, eax
            invoke SetTimer, hWin, TIMER_SEED, 1, NULL ; seed generator
            invoke SetTimer, hWin, TIMER_SEED2, 500, NULL ; seed generator

            ; play background music
            mov   open_lpstrDeviceType, 0h                       ; 0h = 預設播放裝置
            mov   open_lpstrElementName, OFFSET backgroundMusic  ; 要播放的檔案
            invoke mciSendCommandA, 0, MCI_OPEN, MCI_OPEN_ELEMENT, OFFSET open_dwCallback  ; 打開播放裝置
            cmp   eax, 0h
            jne   open_error                                    ; 如果打開失敗則跳到錯誤處理
            mov   eax, open_wDeviceID
            invoke mciSendCommandA, eax, MCI_PLAY, MCI_NOTIFY, offset play_dwCallback ; 開始循環播放檔案

            open_error:
        .elseif uMsg == WM_TIMER
            .if wParam == TIMER_SEED
              add seedA, 17
            .elseif wParam == TIMER_SEED2
              add seedB, 1
            .elseif wParam == TIMER_ZOMBIE 
                invoke randomNumberGenerator, 3, 6, seedB ;[此處可調整殭屍速度區間]
                invoke activateZombie,eax
            .elseif wParam == TIMER_GADGET ;生成新道具
                mov ebx, windowWidth
                mov eax, gadgetWidth
                add eax, 100
                sub ebx, eax
                invoke randomNumberGenerator, eax, ebx, seedA
                mov gadgetX, eax

                mov ebx, windowHeight
                mov eax, gadgetHeight
                add eax, 100
                sub ebx, eax
                invoke randomNumberGenerator, eax, ebx, seedA
                mov gadgetY, eax

                invoke randomNumberGenerator, 1, 4, seedB
                mov gadgetType, eax
                mov gadgetAppear, 1
            .elseif wParam == TIMER_BUFF ; 檢查是否是道具效果計時器
                mov buffOn, 0        ; 關閉道具效果
                invoke KillTimer, hWnd, TIMER_BUFF ; 銷毀計時器
            .elseif wParam == TIMER_SCORE 
                mov eax, scoreIncrease
                add score, eax
            .endif 
        .elseif uMsg == WM_PAINT    ;當系統或其他應用程序請求繪製應用程序窗口的一部分時，會發送 WM_PAINT 消息
            invoke updateScrenn
        .elseif uMsg == WM_ERASEBKGND ;避免畫面更新閃爍
            mov eax, 1
        .elseif uMsg == WM_KEYDOWN
            .if wParam == VK_RETURN && GAMESTATE != 2 ; Enter 鍵
                ; play start game sound
                mov   open_lpstrDeviceType, 0h                      ; 0h = default device to play the file
                mov   open_lpstrElementName, OFFSET startGameSound  ; file to play
                invoke mciSendCommandA, 0, MCI_OPEN, MCI_OPEN_ELEMENT, OFFSET open_dwCallback  ; open the device
                cmp   eax,0h      ; if the device was opened successfully
                je    play_start_game_sound		  ; jump to next
                play_start_game_sound:	
                    invoke mciSendCommandA,open_wDeviceID,MCI_PLAY,MCI_NOTIFY,offset play_dwCallback ; start playing the file
                    ; close  the device after 0.2 seconds
                    mov eax, 400
                    invoke Sleep, eax
                    invoke mciSendCommandA, open_wDeviceID, MCI_CLOSE, 0, 0 

                .if (GAMESTATE == 1)
                  mov eax, offset ThreadProc
                  invoke CreateThread, NULL, NULL, eax, NULL, NORMAL_PRIORITY_CLASS, ADDR threadID 
                  invoke SetTimer, hWin, TIMER_ZOMBIE, 10000, NULL ; 設置計時器，殭屍生成觸發器(10秒一次)
                  invoke SetTimer, hWin, TIMER_GADGET, 7548, NULL ; 設置計時器，道具生成觸發器(7.548秒一次)
                  invoke SetTimer, hWin, TIMER_SCORE, 500, NULL ; 設置計時器，分數加分觸發器(0.5秒一次)
                  invoke initGameplay
                  mov GAMESTATE, 2
                  invoke randomNumberGenerator, 3, 6, seedB ;[此處可調整第一隻殭屍速度區間]
                  invoke activateZombie,eax
                .elseif (GAMESTATE == 3)
                    mov GAMESTATE, 1
                    invoke InvalidateRect, hWnd, NULL, TRUE
                .endif
            .endif

            ; 控制鍵
            .if wParam == VK_I 
                invoke randomNumberGenerator, 5, 10, seedB      ; just for testing
                invoke wsprintf, ADDR infoBuffer, chr$("Random Number: %d"), eax
                invoke MessageBox, hWin, ADDR infoBuffer, ADDR szDisplayName, MB_OK
            .elseif wParam == VK_W
                mov keyWPressed, 1
            .elseif wParam == VK_S
                mov keySPressed, 1
            .elseif wParam == VK_A
                mov keyAPressed, 1
        
            .elseif wParam == VK_D
                mov keyDPressed, 1
            .endif
            ; 離開鍵
            .if wParam == VK_ESCAPE && (GAMESTATE == 3 || GAMESTATE == 1)
                mov   open_lpstrDeviceType, 0h                      ; 0h = default device to play the file
                mov   open_lpstrElementName, OFFSET exitGameSound  ; file to play
                invoke mciSendCommandA, 0, MCI_OPEN, MCI_OPEN_ELEMENT, OFFSET open_dwCallback  ; open the device
                invoke mciSendCommandA,open_wDeviceID,MCI_PLAY,MCI_NOTIFY,offset play_dwCallback ; start playing the file
                
                ; exit game after 0.2 seconds
                mov eax, 200
                invoke Sleep, eax
                invoke SendMessage,hWin,WM_SYSCOMMAND,SC_CLOSE, NULL

            .endif
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
        .elseif uMsg == MM_MCINOTIFY
            ; cmp   wParam, MCI_NOTIFY_SUCCESSFUL
            ; jne   notify_error
            ; invoke mciSendCommandA, lParam, MCI_PLAY, MCI_NOTIFY, offset play_dwCallback
            ; notify_error:
            ;     ; 
        .elseif uMsg == WM_FINISH
            invoke InvalidateRect, hWnd, NULL, TRUE ;強制刷新畫面
            .if(GAMESTATE == 2)
                .if beenHit == 1
                    mov GAMESTATE, 3
                    
                    invoke KillTimer, hWin, TIMER_ZOMBIE
                    invoke KillTimer, hWin, TIMER_GADGET
                    invoke KillTimer, hWin, TIMER_SCORE
                    invoke KillTimer, hWin, TIMER_BUFF
                .endif
            .endif
        .elseif uMsg == WM_DESTROY                                        ; if the user closes our window 
            invoke PostQuitMessage,NULL          
        .else
            invoke DefWindowProc, hWin, uMsg, wParam, lParam                         ; quit our application 
        .endif                            ; quit our application 
        ret
    WndProc ENDP

    ; ----------------------------------------------------------------------

    TopXY PROC wDim:DWORD, sDim:DWORD

        ; ----------------------------------------------------
        ; This procedure calculates the top X & Y co-ordinates
        ; for the CreateWindowEx call in the WinMain procedure
        ; ----------------------------------------------------

        shr sDim, 1      ; divide screen dimension by 2
        shr wDim, 1      ; divide window dimension by 2
        mov eax, wDim    ; copy window dimension into eax
        sub sDim, eax    ; sub half win dimension from half screen dimension

        return sDim

    TopXY ENDP

    ; ----------------------------------------------------------------------

    ;更新所有殭屍位置
    updateZombiePositions PROC
        LOCAL zombieX:DWORD
        LOCAL zombieY:DWORD
        LOCAL zombieSpeed:DWORD


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

            .if(buffOn == 1)
            .if buffType == 2
                mov eax, 0 
            .else
                mov eax, [ebx + zombieObj.speed]     
            .endif
            .else
            mov eax, [ebx + zombieObj.speed]     
            .endif

            ; 殭屍 X 軸的移動
            mov edx, zombieX
            .if playerX > edx
                add zombieX, eax
            .elseif playerX < edx
                sub zombieX, eax
            .endif

            ; 殭屍 Y 軸的移動
            mov edx, zombieY
            .if playerY > edx
                add zombieY, eax
            .elseif playerY < edx
                sub zombieY, eax
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
    updateZombiePositions ENDP

    ; ----------------------------------------------------------------------

    ;檢查殭屍與玩家是否發生碰撞
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
            add edx, zombieWidth     ;edx存判斷子(殭屍座標+殭屍size)
            .if edx > eax;X small boundary
                add eax, playerWidth
                add eax, zombieWidth
                .if edx < eax;X large boundary
                    ; 判斷 Y 座標是否重疊
                    mov eax, playerY
                    mov edx, zombieY
                    add edx, zombieHeight
                    .if edx > eax;Y small boundary
                        add eax, playerHeight
                        add eax, zombieHeight
                        .if edx < eax;Y large boundary
                            .if buffOn == 1
                                .if buffType == 3
                                    mov beenHit, 0
                                .else
                                    mov beenHit, 1 ; 發生碰撞
                                .endif
                            .else
                                mov beenHit, 1 ; 發生碰撞
                            .endif
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

    ; ----------------------------------------------------------------------

    ;檢查道具與玩家是否發生碰撞
    checkGadgetCollision PROC
        ; 判斷 X 座標是否重疊
        mov eax, playerX;eax存判斷boundary
        mov edx, gadgetX
        add edx, gadgetWidth     ;edx存判斷子(道具座標+道具size)
        .if edx > eax;X small boundary
            add eax, playerWidth
            add eax, gadgetWidth
            .if edx < eax;X large boundary
                ; 判斷 Y 座標是否重疊
                mov eax, playerY
                mov edx, gadgetY
                add edx, gadgetHeight
                .if edx > eax;Y small boundary
                    add eax, playerHeight
                    add eax, gadgetHeight
                    .if edx < eax;Y large boundary
                        mov gadgetAppear, 0; 吃到道具
                        mov eax, gadgetType
                        mov buffType, eax
                        mov buffOn, 1          ; 啟用道具效果
                        invoke SetTimer, hWnd, TIMER_BUFF, 3000, NULL ; 設置一次性計時器，ID 為 TIMER_BUFF，3秒後觸發
                    .endif
                .endif
            .endif
        .endif

        ret
    checkGadgetCollision ENDP

    ; ----------------------------------------------------------------------

    ;道具1(玩家加速)、道具4(分數累加加速)實作
    checkBuffEffect PROC ;[此處可調整道具1、4加速程度]
        .if (buffOn == 1)
            .if(buffType == 1)
            mov playerSpeed, 20
            .elseif(buffType == 4)
            mov scoreIncrease, 99
            .endif
        .elseif
            mov playerSpeed, 10
            mov scoreIncrease, 7
        .endif
        ret
    checkBuffEffect ENDP

    ; ----------------------------------------------------------------------

    ;遊玩(GAMESTATE=2)每幀循環
    ThreadProc PROC USES ecx Param:DWORD
        ; 線程循環
        ThreadLoop:
            invoke Sleep, 100  ; 等待 100 毫秒

            invoke updatePlayerPosition
            invoke updateZombiePositions
            invoke checkZombieCollision
            invoke checkGadgetCollision
            invoke checkBuffEffect

            invoke SendMessage, hWnd, WM_FINISH, NULL, NULL

            .if beenHit == 1
                jmp ExitThreadLoop
            .endif

            jmp ThreadLoop

        ExitThreadLoop:
            ; 清理和終止線程前的代碼
            ret
    ThreadProc ENDP

    ; ----------------------------------------------------------------------

end start