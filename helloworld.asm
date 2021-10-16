section .text
    global _start   ;must be declared for linker (ld)

_start:             ;tells linker entry point
    mov edx, len    ;message length
    mov ecx, msg    ;message to write
    mov ebx, 1      ;file descriptor (stdout)
    mov eax, 4      ;system call number (sys_write), takes other registers as arguments
    int 0x80        ;call kernel interrupt

    mov eax, 1      ;system call number (sys_exit)
    int 0x80        ;call kernel interrupt

section .data
    msg db 'Hello, world!', 0xa     ;our string
    len equ $-msg                   ;length of our string
