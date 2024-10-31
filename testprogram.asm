%ifdef WINDOWS
    extern _ExitProcess@4
    extern _WriteConsoleA@20
    extern _ReadConsoleA@20
    section .data align=4
    handle dq -11                   ; -11 is the stdout handle for WriteConsole
    input_handle dq -10             ; -10 is the stdin handle for ReadConsole
%elifdef LINUX
    %define UNIX 1
    %define SYS_WRITE 1
    %define SYS_READ 0
    %define SYS_EXIT 60
%elifdef FREEBSD
    %define UNIX 1
    %define SYS_WRITE 4
    %define SYS_READ 3
    %define SYS_EXIT 1
%elifdef MACOS
    %define UNIX 1
    %define SYS_WRITE 0x2000004
    %define SYS_READ 0x2000003
    %define SYS_EXIT 0x2000001
%endif

section .bss align=4
    num resb 6                      ; Reserve 6 bytes (5 for data + 1 for null terminator)
    maxInputLen equ ($ - num - 1)   ; Maximum number of input characters (buffer size - 1 for null terminator)

section .data align=4
    userMsg db 'Please enter a number (max ', '0'+maxInputLen, ' digits): ', 0xA
    lenUserMsg equ $ - userMsg

    dispMsg db 'You have entered: ', 0xA
    lenDispMsg equ $ - dispMsg

section .text align=4
    global _start

_start:
%ifdef UNIX
    ; Display prompt message
    mov rax, SYS_WRITE              ; Syscall number for write
    mov rdi, 1                      ; File descriptor 1 (stdout)
    lea rsi, [rel userMsg]          ; Relative address of the user prompt
    mov rdx, lenUserMsg             ; Length of the message
    syscall                         ; Perform syscall

    ; Read user input (limit to maxInputLen bytes)
    mov rax, SYS_READ               ; Syscall number for read
    mov rdi, 0                      ; File descriptor 0 (stdin)
    lea rsi, [rel num]              ; Relative address to store input
    mov rdx, maxInputLen            ; Max bytes to read
    syscall                         ; Perform syscall
    mov rbx, rax                    ; Save the number of bytes read in rbx

    ; Add null terminator for safety
    lea rdi, [rel num]              ; Load the relative address of num
    add rdi, rbx                    ; Add the number of bytes read (stored in rbx)
    mov byte [rdi], 0               ; Null-terminate at the end of the input

    ; Display "You have entered: " message
    mov rax, SYS_WRITE              ; Syscall number for write
    mov rdi, 1                      ; File descriptor 1 (stdout)
    lea rsi, [rel dispMsg]          ; Relative address of the display message
    mov rdx, lenDispMsg             ; Length of the message
    syscall                         ; Perform syscall

    ; Display user input
    mov rax, SYS_WRITE              ; Syscall number for write
    mov rdi, 1                      ; File descriptor 1 (stdout)
    lea rsi, [rel num]              ; Relative address of the entered number
    mov rdx, rbx                    ; Length of input read (stored in rbx)
    syscall                         ; Perform syscall

    ; Exit program
    mov rax, SYS_EXIT               ; Syscall number for exit
    xor rdi, rdi                    ; Exit code 0
    syscall

%elifdef WINDOWS
    ; Display prompt message
    mov rcx, qword [handle]         ; Stdout handle
    lea rdx, [userMsg]              ; Address of the user prompt
    mov r8, lenUserMsg              ; Length of the message
    xor r9d, r9d                    ; No overlap
    call _WriteConsoleA@20          ; Call WriteConsoleA

    ; Read user input (limit to maxInputLen bytes)
    mov rcx, qword [input_handle]   ; Stdin handle
    lea rdx, [num]                  ; Address to store input
    mov r8, maxInputLen             ; Max bytes to read (including null terminator)
    lea r9, [lenUserMsg]            ; Placeholder for bytes read
    call _ReadConsoleA@20           ; Call ReadConsoleA

    ; Display "You have entered: " message
    mov rcx, qword [handle]         ; Stdout handle
    lea rdx, [dispMsg]              ; Address of the display message
    mov r8, lenDispMsg              ; Length of the message
    xor r9d, r9d                    ; No overlap
    call _WriteConsoleA@20          ; Call WriteConsoleA

    ; Display user input
    mov rcx, qword [handle]         ; Stdout handle
    lea rdx, [num]                  ; Address of the entered number
    mov r8, maxInputLen             ; Length of input (maxInputLen digits + null terminator)
    xor r9d, r9d                    ; No overlap
    call _WriteConsoleA@20          ; Call WriteConsoleA

    ; Exit program
    xor ecx, ecx                    ; Exit code 0
    call _ExitProcess@4             ; Call ExitProcess
%endif
