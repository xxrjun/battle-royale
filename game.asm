;=====================================================================
;�βզX�y���}�o�E�l�� | 08/12/2023
;=====================================================================

;=====================================================================
;��ʽsĶ�y�{
;1)	\masm32\bin\ml /c /coff "main.asm"
;2)	\masm32\bin\PoLink /SUBSYSTEM:WINDOWS "main.obj"

;====================================================================


.386
option casemap	:none	;�j�p�g�Ϥ�

;�禡�w
include \masm32\include\masm32rt.inc
includelib \masm32\lib\kernel32.lib
includelib \masm32\lib\masm32.lib

;�w���n���@�Ө��
;��ƭ쫬�W��WinMain�A�㦳4�ӰѼ�
WinMain proto :DWORD,:DWORD,:DWORD,:DWORD


;�a����Ȫ��ܼ��n��
.DATA
windowClassName     db 'Window',0
windowTitle         db 'Nine Mens Morris',0

;�|����Ȫ��ܼ��n��
.DATA?
instancia   HINSTANCE ? ; ���f���
argumentos  LPSTR ?     ; ���ε{���Ѽ�

    ;�Ұʭ�l�X
    .CODE
start:
    ;=====================================================

    ;���o��e���檺��Ҫ����
    ;�ϥ�NULL������^��e���檺���
    ;�P�ɱN��Ҧs�Jeax�H�s��
    invoke GetModuleHandle, NULL ;�N��Ҧs�Jeax�H�s��
    mov instancia, eax  ;�Neax������ҭȲ��ʨ��ܼ� 'instancia' ���Fmov �ؼ�, �ӷ�
    invoke GetCommandLine ;������GetModuleHandle�A�����������ε{�����ѼơF�N�ѼƦs�Jeax�H�s��
    mov argumentos, eax ;�Neax�����ѼƭȲ��ʨ��ܼ� 'argumentos' ��

    ;����WinMain��ơA�ñN�ܼ� 'instancia' �M 'argumentos' �ǻ����Ѽ�
    ;NULL��ܨS�����Υ��e����ҡA�b�o�ر��p�U����
    ;SW_SHOWDEFAULT�����ܵ��f���Ҧ�/�覡
    invoke WinMain, instancia, NULL, argumentos, SW_SHOWDEFAULT

    ;�Heax������^�Ȱh�X�i�{
    invoke ExitProcess, eax

    ;�㦳4�ӰѼƪ�WinMain��ơA�w�b��25���n���Lprototype
    WinMain proc hInst:HINSTANCE, hPrevInst:HINSTANCE, CmdLine:LPSTR, CmdShow:DWORD
        ;���a�ܼ�
        LOCAL estVentana:WNDCLASSEX  ;���f���c�A�]�t���f���S��
        LOCAL mensaje:MSG             ;�B�z�o�e�쵡�f���������ܼơA�Ҧp���s���ʧ@
        LOCAL manejador:HWND          ;���f���B�z�{�ǡA�Ω��ѧO���f

        ;�]�m���f���c
        mov estVentana.cbSize, SIZEOF WNDCLASSEX
        mov estVentana.style, CS_HREDRAW or CS_VREDRAW
        mov estVentana.lpfnWndProc, OFFSET WndProc
        mov estVentana.cbClsExtra, NULL
        mov estVentana.cbWndExtra, NULL
        push instancia      ;���w���f�ݩ���ӹ��
        pop estVentana.hInstance
        mov estVentana.hbrBackground, COLOR_WINDOW + 1
        mov estVentana.lpszMenuName, NULL
        mov estVentana.lpszClassName, OFFSET windowClassName
        invoke LoadIcon, NULL, IDI_APPLICATION
        mov estVentana.hIcon, eax
        mov estVentana.hIconSm, eax
        invoke LoadCursor, NULL, IDC_ARROW
        mov estVentana.hCursor, eax

        ;���U���f���O
        invoke RegisterClassEx, addr estVentana
        
        ;�Ыص��f
        invoke CreateWindowEx,
            NULL,
            ADDR windowClassName,
            ADDR windowTitle,
            WS_OVERLAPPEDWINDOW,
            CW_USEDEFAULT, ;���f�ؤo
			CW_USEDEFAULT, 
			CW_USEDEFAULT, ;���f��m
			CW_USEDEFAULT,
            NULL,
            NULL,
            hInst,
            NULL

        ;�e�z��ƱN�B�z�{�Ǧs�Jeax
        mov manejador, eax

        ;��ܵ��f
        invoke ShowWindow, manejador, SW_SHOWNORMAL

        ;�q�L�ǻ��B�z�{�ǧ�s���f
        invoke UpdateWindow, manejador

        ;�`���H�B�z����
        .WHILE TRUE
            ;����Ū�����������
            invoke GetMessage, ADDR mensaje, NULL, 0, 0
            .BREAK .IF (!eax)

            ;�B�z����
            invoke TranslateMessage, ADDR mensaje
            invoke DispatchMessage, ADDR mensaje
        .ENDW

        ;�N�����ѼƲ���eax
        mov  eax, mensaje.wParam

        ;�Heax���ȵ����ê�^
        ret
    WinMain endP

    ;�B�z���������
    WndProc proc hWnd:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM
        ;�ˬd�����O�_���������f
        .IF uMsg==WM_DESTROY
            ;����h�X
            invoke PostQuitMessage, NULL
        .ELSE
            ;�ϥ��q�{�����B�z
            Invoke DefWindowProc, hWnd, uMsg, wParam,lParam
            ret
        .ENDIF

        ;�Neax�]��0
        xor eax, eax
        ret
    WndProc endp

    ;=====================================================
;��l�X����
end start