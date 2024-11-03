%ifdef WINDOWS
    extern _ExitProcess@4
    extern _WriteConsoleA@20
    section .data align=4
    handle dq -11                   ; -11 is the stdout handle for WriteConsole
%elifdef LINUX
    %define UNIX 1
    %define SYS_WRITE 1
    %define SYS_EXIT 60
%elifdef FREEBSD
    %define UNIX 1
    %define SYS_WRITE 4
    %define SYS_EXIT 1
%elifdef MACOS
    %define UNIX 1
    %define SYS_WRITE 0x2000004
    %define SYS_EXIT 0x2000001
%endif

section .data align=4
    msg db "Hello, world!", 0xA     ; Message with newline
    len equ $ - msg                 ; Calculate message length

section .text align=4
    global _start

_start:
%ifdef UNIX
    ; Shared code for Unix-based systems (Linux, FreeBSD, macOS)
    mov rax, SYS_WRITE              ; Syscall number for write
    mov rdi, 1                      ; File descriptor 1 (stdout)
    mov rsi, msg                    ; Address of the message
    mov rdx, len                    ; Length of the message
    syscall                         ; Perform syscall

    mov rax, SYS_EXIT               ; Syscall number for exit
    xor rdi, rdi                    ; Exit code 0
    syscall

%elifdef WINDOWS
    ; Windows-specific code using WriteConsoleA and ExitProcess
    mov rcx, qword [handle]         ; Get the stdout handle
    lea rdx, [msg]                  ; Load address of message
    mov r8, len                     ; Load length of message
    xor r9d, r9d                    ; No overlap
    call _WriteConsoleA@20          ; Call WriteConsoleA

    xor ecx, ecx                    ; Exit code 0
    call _ExitProcess@4             ; Call ExitProcess
%endif
