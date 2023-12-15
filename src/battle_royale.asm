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

.486                   ; minimum processor needed for 32 bit
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
      Name db Text,0  
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
; WinProc 
; Description: The window procedure for the main window
; Parameters:
;   hWin - Handle to the window
;   uMsg - Message identifier
;   wParam - Additional message information
;   lParam - Additional message information
; Reference: https://learn.microsoft.com/en-us/windows/win32/api/winuser/nc-winuser-wndproc
; ----------------------------------------------------------------------
WndProc   PROTO :DWORD,:DWORD,:DWORD,:DWORD 

TopXY     PROTO :DWORD,:DWORD 
PlaySound PROTO STDCALL :DWORD,:DWORD,:DWORD  
ExitProcess PROTO, dwExitCode:DWORD
UpdateScreen PROTO
PaintBackground PROTO _hdc:HDC, _hMemDC:HDC, _hMemDC2:HDC

; ======================================================================

.const
    menuBackground EQU 101
    gameBackground EQU 102
    endWithSurvivorBackground EQU 103
    endWithoutSurvivorBackground EQU 104
    player1 EQU  1001
    player2 EQU 1002
    zombie  EQU 1003

.data
    ; Window Viewport
    windowWidth  DWORD 1792    
    windowHeight DWORD 1082   
    
    menuChoice DWORD ?
    inputKey BYTE ?     ; stores the user's input key
    hInstance     DD 0  ; handle to the current instance
    hWnd       DD 0     ; handle to the main window
    CommandLine   DD 0

    paintstruct   PAINTSTRUCT <> 

    startingGameMsg BYTE "Starting Battle Royale Game", 0
    szDisplayGameName BYTE "Battle Royale", 0
    singlePlayerGameMsg BYTE "Single-player Game", 0
    szUpdateScreenMsg BYTE "Updating the screen...", 0
    gameMode DD 1       ; 1 = single player, 2 = multiplayer
    gameState BYTE 1    ; 1 = menu, 2 = game, 3 = game over

    szLoadBitmapFailedMsg BYTE "Failed to load bitmap", 0

    ; music and sound effects
    backgroundMusic DB "../assets/sounds/backgroundmusic.mp3", 0
    buttonInputSound DB "../assets/sounds/button-input-sound-effects.mp3", 0
    startGameSound DB "../assets/sounds/background-music.mp3", 0

    ; - MCI_OPEN_PARMS Structure ( API=mciSendCommand ) -
    open_dwCallback     dd ?
    open_wDeviceID     dd ?
    open_lpstrDeviceType  dd ?
    open_lpstrElementName  dd ?
    open_lpstrAlias     dd ?

    ; - MCI_GENERIC_PARMS Structure ( API=mciSendCommand ) -
    generic_dwCallback   dd ?

    ; - MCI_PLAY_PARMS Structure ( API=mciSendCommand ) -
    play_dwCallback     dd ?
    play_dwFrom       dd ?
    play_dwTo        dd ?   

.data?
    hBmpMenuBackground DD ?

.code
start:
        invoke GetModuleHandle, NULL ; provides the instance handle
        mov hInstance, eax

        invoke GetCommandLine        ; provides the command line address
        mov CommandLine, eax

        invoke LoadBitmap, hInstance, menuBackground
        test eax, eax
        jz LoadBitmapFailed         ; if eax is zero, jump to LoadBitmapFailed
        mov hBmpMenuBackground, eax


        invoke WinMain, hInstance, NULL, CommandLine, SW_SHOWNORMAL ; call WinMain 

        invoke ExitProcess, eax       ; cleanup & return to operating system

        ; Additional code to handle other scenarios can be added here

    LoadBitmapFailed:
        invoke StdOut, ADDR szLoadBitmapFailedMsg
        invoke ExitProcess, 0

    ; ======================================================================

    ; ----------------------------------------------------------------------
    ; PROCEDURES 
    ; ----------------------------------------------------------------------


    WinMain PROC hInst     :DWORD,
                hPrevInst :DWORD,
                CmdLine   :DWORD,
                CmdShow   :DWORD

        ;====================
        ; Put LOCALs on stack
        ;====================

        LOCAL wc   :WNDCLASSEX
        LOCAL msg  :MSG

        LOCAL Wwd  :DWORD
        LOCAL Wht  :DWORD
        LOCAL Wtx  :DWORD
        LOCAL Wty  :DWORD

        szText szClassName,"Win32ASM"      ; window class name

        ;==================================================
        ; Fill WNDCLASSEX structure with required variables
        ;==================================================

        mov wc.cbSize,         sizeof WNDCLASSEX
        mov wc.style,          CS_HREDRAW or CS_VREDRAW \
                                or CS_BYTEALIGNWINDOW
        mov wc.lpfnWndProc,    offset WndProc      ; address of WndProc
        mov wc.cbClsExtra,     NULL
        mov wc.cbWndExtra,     NULL
        m2m wc.hInstance,      hInst               ; instance handle
        mov wc.hbrBackground,  COLOR_BTNFACE + 1     ; system color
        mov wc.lpszMenuName,   NULL
        mov wc.lpszClassName,  offset szClassName  ; window class name

        invoke LoadIcon, hInst, 500                  ; icon ID   ; resource icon
        mov wc.hIcon,          eax
        invoke LoadCursor,NULL,IDC_ARROW         ; system cursor
        mov wc.hCursor,        eax
        mov wc.hIconSm,        0

        invoke RegisterClassEx, ADDR wc     ; register the window class

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

        mov hWnd,eax  ; copy return value into handle DWORD

        invoke LoadMenu, hInst, 600                 ; load resource menu
        invoke SetMenu, hWnd, eax                   ; set it to main window

        invoke ShowWindow, hWnd, SW_SHOWNORMAL      ; display the window
        invoke UpdateWindow, hWnd                  ; update the display

        ;===================================
        ; Loop until PostQuitMessage is sent
        ;===================================

        StartLoop:
            invoke GetMessage, ADDR msg, NULL, 0, 0     ; get each message
            cmp eax, 0                                  ; exit if GetMessage()
            je ExitLoop                                 ; returns zero
            invoke TranslateMessage, ADDR msg           ; translate it
            invoke DispatchMessage,  ADDR msg           ; send it to message PROC
            jmp StartLoop                               ; repeat
        ExitLoop:
            return msg.wParam

    WinMain ENDP

    ; ----------------------------------------------------------------------

    WndProc PROC hWin  :DWORD,
                uMsg   :DWORD,
                wParam :DWORD,
                lParam :DWORD

        LOCAL hDC    :DWORD
        LOCAL memDC  :DWORD
        LOCAL memDCp1 : DWORD
        LOCAL hOld   :DWORD
        LOCAL hWin2  :DWORD
        LOCAL direction : BYTE
        LOCAL keydown   : BYTE
        mov direction, -1
        mov keydown, -1

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

            ; play background music
            mov   open_lpstrDeviceType, 0h                       ; 0h = default device to play the file
            mov   open_lpstrElementName, OFFSET backgroundMusic  ; file to play
            invoke mciSendCommandA, 0, MCI_OPEN, MCI_OPEN_ELEMENT, OFFSET open_dwCallback  ; open the device
            cmp   eax,0h      ; if the device was opened successfully
            je    next		  ; jump to next
            next:	
                invoke mciSendCommandA,open_wDeviceID,MCI_PLAY,MCI_NOTIFY,offset play_dwCallback ; start playing the file


        .elseif uMsg == WM_PAINT      ; if the window needs repainting, repaint it
            invoke UpdateScreen
        .elseif uMsg == WM_ERASEBKGND ; to prevent flickering
            mov eax, 1
        .elseif uMsg == WM_DESTROY          ; if the user closes our window 
            invoke PostQuitMessage, NULL     ; post a quit message  
            return 0

        .endif

        ; default message handling
        invoke DefWindowProc, hWin, uMsg, wParam, lParam

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

    ; PaintBackground Procedure
    ; Draws the background image based on the current game state
    ; Parameters:
    ;   _hdc - Device context for drawing
    ;   _hMemDC - Memory device context for off-screen drawing
    ;   _hMemDC2 - Additional memory device context for double buffering
    PaintBackground PROC _hdc:HDC, _hMemDC:HDC, _hMemDC2:HDC
        LOCAL rect   :RECT

        
        ; Select the appropriate background image based on the game state
        .if(gameState == 1)
            invoke SelectObject, _hMemDC2, hBmpMenuBackground
        ; .elseif(gameState == 2)
        ;     invoke SelectObject, _hMemDC2, hBmp
        ; ; ... (additional game states)
        .endif

        ; Perform the bit-block transfer from memory DC to the target DC
        invoke BitBlt, _hMemDC, 0, 0, windowWidth, windowHeight, _hMemDC2, 0, 0, SRCCOPY

        ; Paint the score if the game state is 2 (gameState == 2)
        ; .if(gameState == 2)
        ;     invoke SetTextColor,_hMemDC,00FF8800h
        ;     invoke wsprintf, addr buffer, chr$("%d     x     %d"), player1.goals, player2.goals
        ;     mov   rect.left, 360
        ;     mov   rect.top , 10
        ;     mov   rect.right, 490
        ;     mov   rect.bottom, 50  
        ;     invoke DrawText, _hMemDC, addr buffer, -1, addr rect, DT_CENTER or DT_VCENTER or DT_SINGLELINE
        ; .endif

        ret
    PaintBackground ENDP

    ; ----------------------------------------------------------------------

    ; UpdateScreen Procedure
    ; Updates the screen with the current game visuals
    ; Performs double buffering to minimize flickering and improve performance
    UpdateScreen PROC
        LOCAL hMemDC:HDC
        LOCAL hMemDC2:HDC
        LOCAL hBitmap:HDC
        LOCAL hDC:HDC

        invoke StdOut, ADDR szUpdateScreenMsg

        invoke BeginPaint, hWnd, ADDR paintstruct
        mov hDC, eax
        invoke CreateCompatibleDC, hDC
        mov hMemDC, eax
        invoke CreateCompatibleDC, hDC
        mov hMemDC2, eax
        invoke CreateCompatibleBitmap, hDC, windowWidth, windowHeight
        mov hBitmap, eax

        invoke SelectObject, hMemDC, hBitmap
        invoke PaintBackground, hDC, hMemDC, hMemDC2

        ; Paint players if the game state requires it
        ; .if(gameState == 2)
        ;     invoke paintPlayers, hDC, hMemDC, hMemDC2
        ; .endif

        ; Transfer the composed image to the actual window
        invoke BitBlt, hDC, 0, 0, windowWidth, windowHeight, hMemDC, 0, 0, SRCCOPY

        ; Clean up device contexts and bitmap
        invoke DeleteDC, hMemDC
        invoke DeleteDC, hMemDC2
        invoke DeleteObject, hBitmap
        invoke EndPaint, hWnd, ADDR paintstruct
        ret
    UpdateScreen ENDP

    ; ----------------------------------------------------------------------
    ; MenuView PROC
    ;     ; Placeholder for loading and displaying the bitmap
    ;     invoke LoadBitmap, hInstance, menuBackground

    ;     .WHILE TRUE
    ;         ; invoke ReadKey
    ;         ; mov inputKey, al

    ;         ; cmp inputKey, '1'
    ;         ; je SinglePlayer
    ;         ; cmp inputKey, '2'
    ;         ; je Multiplayer
    ;         ; cmp inputKey, 13 ; ASCII code for Enter
    ;         ; je StartGame
    ;     .ENDW
    ; MenuView ENDP

    ; SinglePlayer:
    ;     ; Single-player game logic here
    ;     mov eax, 1

    ;     ; printout "Single-player Game" to the console
    ;     invoke StdOut, ADDR singlePlayerGameMsg

    ;     ret

    ; Multiplayer:
    ;     ; Multiplayer game logic here
    ;     mov eax, 2
    ;     ret

    ; StartGame:
    ;     ; Start game logic here
    ;     ; ...

    ; MultiplayerGame:
    ;     ; Multiplayer game logic here
    ;     ; ...
        
    ExitGame:
        ; Exit the application
        invoke ExitProcess, 0

end start
