section .data
    ; Prompts and messages for output
    prompt_buffer_size db 'Enter buffer size in bytes: ', 0
    len_prompt_buffer_size equ $ - prompt_buffer_size

    prompt_write_size db 'Enter number of bytes to write: ', 0
    len_prompt_write_size equ $ - prompt_write_size

    msg_alloc db 'Allocated buffer of size: ', 0
    len_msg_alloc equ $ - msg_alloc

    msg_written db 'Attempting to write bytes: ', 0
    len_msg_written equ $ - msg_written

    msg_success db 'Write completed successfully!', 10, 0
    len_msg_success equ $ - msg_success

    msg_alloc_fail db 'Memory allocation failed!', 10, 0
    len_msg_alloc_fail equ $ - msg_alloc_fail

    msg_invalid_input db 'Invalid input!', 10, 0
    len_msg_invalid_input equ $ - msg_invalid_input

    newline db 10, 0
    len_newline equ $ - newline

    buffer_size dq 0    ; Variable to store buffer size
    write_size dq 0     ; Variable to store number of bytes to write

section .bss
    input resb 20       ; Buffer to store user input

section .text
    global _start

_start:
    ; Display prompt for buffer size
    mov rax, 0x2000004              ; syscall: write
    mov rdi, 1                      ; file descriptor: stdout
    lea rsi, [rel prompt_buffer_size] ; address of the prompt string
    mov rdx, len_prompt_buffer_size ; length of the prompt string
    syscall

    ; Read buffer size input (limit to 19 characters)
    mov rax, 0x2000003              ; syscall: read
    mov rdi, 0                      ; file descriptor: stdin
    lea rsi, [rel input]            ; address to store input
    mov rdx, 19                     ; limit input to 19 bytes
    syscall

    ; Convert buffer size input to integer
    lea rsi, [rel input]            ; address of the input buffer
    call str_to_int
    test rax, rax                   ; check if conversion was successful
    js invalid_input_exit           ; if negative, exit due to invalid input
    mov [rel buffer_size], rax      ; store buffer size

    ; Display prompt for write size
    mov rax, 0x2000004              ; syscall: write
    mov rdi, 1                      ; file descriptor: stdout
    lea rsi, [rel prompt_write_size] ; address of the prompt string
    mov rdx, len_prompt_write_size  ; length of the prompt string
    syscall

    ; Read write size input (limit to 19 characters)
    mov rax, 0x2000003              ; syscall: read
    mov rdi, 0                      ; file descriptor: stdin
    lea rsi, [rel input]            ; address to store input
    mov rdx, 19                     ; limit input to 19 bytes
    syscall

    ; Convert write size input to integer
    lea rsi, [rel input]            ; address of the input buffer
    call str_to_int
    test rax, rax                   ; check if conversion was successful
    js invalid_input_exit           ; if negative, exit due to invalid input
    mov [rel write_size], rax       ; store write size

    ; Allocate buffer of user-specified size on the heap
    mov rax, 0x200000C5             ; syscall: mmap
    xor rdi, rdi                    ; addr = NULL, let kernel choose
    mov rsi, [rel buffer_size]      ; size from user input
    mov rdx, 0x3                    ; prot = PROT_READ | PROT_WRITE
    mov r10, 0x1002                 ; flags = MAP_PRIVATE | MAP_ANON
    mov r8, -1                      ; fd = -1 (not used with MAP_ANON)
    xor r9, r9                      ; offset = 0
    syscall

    ; Check if mmap succeeded
    cmp rax, -1                     ; check if rax is -1 (allocation failed)
    je alloc_fail_exit              ; jump to error handling if allocation failed

    ; Save the address of the allocated buffer
    mov rdi, rax                    ; rdi points to allocated buffer

    ; Display allocated buffer size
    mov rax, 0x2000004              ; syscall: write
    mov rdi, 1                      ; file descriptor: stdout
    lea rsi, [rel msg_alloc]        ; address of the message
    mov rdx, len_msg_alloc          ; length of the message
    syscall
    mov rsi, [rel buffer_size]      ; display buffer size
    call print_number
    mov rax, 0x2000004              ; syscall: write
    mov rdi, 1                      ; file descriptor: stdout
    lea rsi, [rel newline]          ; address of newline
    mov rdx, len_newline            ; length of newline
    syscall

    ; Display number of bytes to be written
    mov rax, 0x2000004              ; syscall: write
    mov rdi, 1                      ; file descriptor: stdout
    lea rsi, [rel msg_written]      ; address of the message
    mov rdx, len_msg_written        ; length of the message
    syscall
    mov rsi, [rel write_size]       ; display write size
    call print_number
    mov rax, 0x2000004              ; syscall: write
    mov rdi, 1                      ; file descriptor: stdout
    lea rsi, [rel newline]          ; address of newline
    mov rdx, len_newline            ; length of newline
    syscall

    ; Write specified number of bytes to the buffer (may overflow)
    mov rax, rdi                    ; rax points to start of buffer
    mov rcx, [rel write_size]       ; write size from user input

write_loop:
    mov byte [rax], 0x41            ; Write 'A' to memory at [rax]
    inc rax                         ; Move to the next byte
    loop write_loop                 ; Repeat for the specified write size

    ; Display success message if we reach here
    mov rax, 0x2000004              ; syscall: write
    mov rdi, 1                      ; file descriptor: stdout
    lea rsi, [rel msg_success]      ; success message
    mov rdx, len_msg_success        ; length of message
    syscall

    ; Exit program
    mov rax, 0x2000001              ; syscall: exit
    xor rdi, rdi                    ; exit code 0
    syscall

; Error handling for invalid input
invalid_input_exit:
    mov rax, 0x2000004              ; syscall: write
    mov rdi, 1                      ; file descriptor: stdout
    lea rsi, [rel msg_invalid_input] ; error message
    mov rdx, len_msg_invalid_input  ; length of message
    syscall
    mov rax, 0x2000001              ; syscall: exit
    mov rdi, 1                      ; exit code 1
    syscall

; Error handling for allocation failure
alloc_fail_exit:
    mov rax, 0x2000004              ; syscall: write
    mov rdi, 1                      ; file descriptor: stdout
    lea rsi, [rel msg_alloc_fail]   ; allocation failure message
    mov rdx, len_msg_alloc_fail     ; length of message
    syscall
    mov rax, 0x2000001              ; syscall: exit
    mov rdi, 1                      ; exit code 1
    syscall

; Function: str_to_int
; Converts ASCII string to integer, returns -1 on invalid input
str_to_int:
    xor rax, rax                    ; result = 0
    xor rcx, rcx                    ; clear rcx for loop
convert_loop:
    movzx rbx, byte [rsi + rcx]     ; load character
    cmp rbx, 10                     ; check for newline or end
    je done_convert                 ; break on newline
    cmp rbx, '0'                    ; check if character is less than '0'
    jl invalid_input_exit           ; if it is, jump to error handling
    cmp rbx, '9'                    ; check if character is greater than '9'
    jg invalid_input_exit           ; if it is, jump to error handling
    sub rbx, '0'                    ; convert ASCII to integer (0-9)
    imul rax, rax, 10               ; multiply result by 10
    add rax, rbx                    ; add digit to result
    inc rcx                         ; next character
    jmp convert_loop
done_convert:
    ret

; Function: print_number
; Prints an unsigned integer (in RSI) to stdout
print_number:
    mov rbx, 10
    xor rcx, rcx
.next_digit:
    xor rdx, rdx
    div rbx
    add dl, '0'
    push rdx
    inc rcx
    test rax, rax
    jnz .next_digit
.print_digits:
    mov rax, 0x2000004              ; syscall: write
    mov rdi, 1                      ; file descriptor: stdout
    pop rsi
    mov rdx, 1                      ; length of one digit
    syscall
    loop .print_digits
    ret
