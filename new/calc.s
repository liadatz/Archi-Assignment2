%macro startFunction 0
    push ebp
    mov ebp, esp
    pushad
%endmacro

%macro endFunction 0
    popad
    mov esp, ebp
    pop ebp
%endmacro

%macro printing 3    ; 1: stream, 2: format (pointer), 3: pointer to string/argument to print
    pushad
    push dword %3
    push %2
    push dword [%1]
    call fprintf
    add esp, 12
    popad
%endmacro

%macro print_operand 1
    mov esi, ecx                                    ; set esi to hold adress of first link
    sub esi, 4
    mov eax, pop_buffer+79                          ; go the last char of pop_buffer
    mov byte [eax], 0                               ; put null-terminator in the end of the buffer
    dec eax

    .233link:
        mov dword esi, [esi]                        ; set ecx to point to start of first/next link
        mov dl, byte [esi]                          ; edx <- data of curr link
        and edx, 7                                  ; take last 3 bits of data
        add edx, 48                                 ; convert to ascii value
        mov [eax], dl                               ; put char value in pop_buffer
        sub eax, 1

        mov dl, byte [esi]                          ; edx <- data of curr link
        and edx, 56                                 ; take next 3 bits of data
        shr edx, 3                                  ; move the bits to right end of edx
        add edx, 48                                 ; convert to ascii value
        mov [eax], dl                               ; put char value in pop_buffer
        dec eax

        mov dl, byte [esi]                          ; edx <- data of curr link
        and edx, 192
        shr edx, 6
        inc esi                                     ; set esi to point address of next link
        cmp dword [esi], 0                          ; if next link is null
        jnz .1331link                               ; jump to next possible type of link

        add edx, 48                                 ; convert to ascii value
        mov [eax], dl                               ; put char value in pop_buffer
        jmp .print_number                           ; print the number
            
    .1331link:
        mov dword esi, [esi]                        ; set ecx to point to start of next link
        mov ebx, edx                                ; put aside bits we pulled from prev link
        mov edx, [esi]                              ; edx <- data of curr link
        and edx, 1                                  ; take last bit of data
        shl edx, 2
        or edx, ebx                                 ; combine with bits from prev link
        add edx, 48                                 ; convert to ascii value
        mov [eax], dl                               ; put char value in pop_buffer
        dec eax

        mov dl, byte [esi]                          ; edx <- data of curr link
        and edx, 14                                 ; take next 3 bits of data
        shr edx, 1                                  ; move the bits to right end of edx
        add edx, 48                                 ; convert to ascii value
        mov [eax], dl                               ; put char value in pop_buffer
        dec eax
                
        mov dl, byte [esi]                          ; edx <- data of curr link
        and edx, 112                                ; take next 3 bits of data
        shr edx, 4                                  ; move the bits to right end of edx
        add edx, 48                                 ; convert to ascii value
        mov [eax], dl                               ; put char value in pop_buffer
        dec eax

        mov dl, byte [esi]                          ; edx <- data of curr link
        and edx, 128
        shr edx, 7
        inc esi
        cmp dword [esi], 0                          ; if next link is null
        jnz .332link                                ; jump to next possible type of link
                
        add edx, 48
        mov [eax], dl                               ; put char value in pop_buffer
        jmp .print_number

            
    .332link:
        mov dword esi, [esi]                        ; set ecx to point to start of next link
        mov ebx, edx                                ; put aside bits we pulled from prev link
        mov edx, [esi]                              ; edx <- data of curr link
        and edx, 3                                  ; take last 2 bits of data
        shl edx, 1
        or edx, ebx                                 ; combine with bits from prev link
        add edx, 48                                 ; convert to ascii value
        mov [eax], dl                               ; put char value in pop_buffer
        dec eax

        mov dl, byte [esi]                          ; edx <- data of curr link
        and edx, 28                                 ; take next 3 bits of data
        shr edx, 2                                  ; move the bits to right end of edx
        add edx, 48                                 ; convert to ascii value
        mov [eax], dl                               ; put char value in pop_buffer
        dec eax

        mov dl, byte [esi]                          ; edx <- data of curr link
        and edx, 224
        shr edx, 5
        add edx, 48                                 ; convert to ascii value
        mov [eax], dl                               ; put char value in pop_buffer
        dec eax
        inc esi
        cmp dword [esi], 0                          ; if next link is null
        jnz .233link                                ; jump to next possible type of link
        ;add edx, 48
        ;mov [eax], dl                               ; put char value in pop_buffer
        jmp .print_number

    .print_number:
        inc eax
        .clean_zeros_loop:
            cmp byte [eax], 48                      ; check if curr char is '0'
            jnz .end
            inc eax
            jmp .clean_zeros_loop
                
        .end:
            cmp byte [eax], 0
            jz .recreate_zero
                
        .recreate_zero:
            mov byte [eax], 48
            jmp .end_continue

        .end_continue:
            printing %1, format_string, eax
%endmacro

section .data                                               ; we define (global) initialized variables in .data section
    stack_size: dd 5                                        ; 4bytes stack counter- counts the number of free spaces
    num_of_elements: dd 0                                   ; define number of current elements in stack 
    operator_counter: dd 0                                  ; 4bytes counter- counts the number of operations.
    args_counter: dd 0                                      ; 4bytes counter
    op_stack: dd 1                                          ; initalize an empty pointer
    debug_flag: db 0
    isFirstLink: db 1
    op1F: db 1
    op2F: db 1

section	.rodata					                            ; we define (global) read-only variables in .rodata section
	format_string: db "%s", 10, 0	                        ; format string for printf func
    format_int: db "%d", 10, 0	                            ; format int for printf func
    format_oct: db "%o", 0                                  ; format for octal number
    prompt_string: db "calc: ", 0                           ; format for prompt message
    overflow_string: db "Error: Operand Stack Overflow",0   ; format for overflow message
    max_args_string: db "Error: To much arguments entered",0; format for arguments error
    underflow_string: db "Error: Insufficient Number of Arguments on Stack",0 ; format for non enough operands in stack error


section .bss						                        ; we define (global) uninitialized variables in .bss section
    buffer: resb 80                                         ;        ;add ecx, 4 80bytes buffer- stores input from user (max length of input is 80 chars)
    pop_buffer: resb 80                                         
    

section .text
  align 16
  global main
  extern printf
  extern fprintf 
  extern fflush
  extern malloc 
  extern calloc 
  extern free 
  extern gets 
  extern getchar 
  extern fgets 
  extern stdout
  extern stdin
  extern stderr


main:
    push ebp
    mov ebp, esp
    pushad

    init:
        mov ebx, [ebp+8]
        dec ebx
        mov [args_counter], ebx                             ; set counter to number of 'extra args'
        cmp byte [args_counter], 2
        jg .error

        mov dword ebx, [ebp+12]                             ; ebx <- argument array
        add ebx, 4                                          ; ebx <- first 'extra argument'
        mov ebx, [ebx]

        .loop:
            cmp dword [args_counter], 0
            jz modify_stack
            cmp byte [ebx], 45
            jz .debug_on
            jmp .set_stack_size

        .debug_on:
            or byte [debug_flag], 1                         ; turn on debug flag
            sub byte [args_counter], 1                      ; reduce args counter by 1
            add ebx, 3
            jmp .loop                                       ; loop again

        .set_stack_size:
            push ebx
            call szatoi
            pop ebx                                         ; call function szatoi
            ;add esp, 4                                     ; clean stack after func call
            mov dword [stack_size], eax                     ; save return value as stack size
            sub byte [args_counter], 1                      ; reduce args counter by 1
            add ebx, 2                                      ; move to next extra arg
            jmp .loop                                       ; loop again
            
        .error:
            push max_args_string		                    ; call printf with 2 arguments -  
            push format_string			                    ; pointer to prompt message and pointer to format string
            call printf                
            add esp, 8			                            ; clean up stack after call
            mov ecx, 1                                      ; for free purpose
            jmp case_quit

    modify_stack:
        push ecx                                            ; backup ecx
        mov eax, [stack_size]                               ; push size for malloc  
        mov ecx, 4
        mul ecx
        push eax
        call malloc
        add esp, 4                                          ; clean stack after func call
        pop ecx                                             ; restore ecx
        mov [op_stack], eax                                 ; address of new stack
        mov ecx, [op_stack]                                 ; set ecx to point the top of the op_stack
        jmp start_loop
    
        
    start_loop:
        or byte [isFirstLink], 1                            ; [isFirstLink] <- 1
        startFunction
        push prompt_string			                        ; call printf with 2 arguments -  
		push format_string			                        ; pointer to prompt message and pointer to format string
        call printf        
        add esp, 8					                        ; clean up stack after call
        endFunction

        startFunction    
        push dword buffer                                   ; input buffer
        call gets
        add esp, 4                                          ; remove 1 push from stuck
        endFunction

        cmp byte [debug_flag], 1
        jne .continue
        .run_debug:
            call debug_print_input
        
        .continue:
        cmp byte [buffer], 48                               ; check if the input greater than '0'
	    jge is_number				                        ; if so jump to 'is_number' label

        jmp case_operator                                   ; if not, then the input is an operator

        
    is_number:
        cmp byte [buffer], 57                               ; check if the input is lesser than '9'
        jle case_operand                                    ; if so, the input first char is a number, and we want to deal with the it as a operand
        
        jmp case_operator                                   ; if not, then the input is an operator


    case_operand:
        push ecx                                            ; backup ecx
        mov dword ebx, buffer                               ; ebx <- pointer to the string
        mov eax, 0                                          ; al <- first value (00000000)
        mov ecx, 0                                          ; ecx <- 0 (counter)
        
        .charLoop:
        cmp byte [ebx+1], 0                                 ; check if next char is '0' (end of string)
        jne .incPointer                                     ; if not, move pointer to next char
        jmp .loop                                           ; now ebx point to the end of the string
            .incPointer:
            inc ebx
            jmp .charLoop
        
        .loop:
            cmp dword ebx, buffer-1                         ; check if ebx passed the first char of buffer
            je .end                                         ; if so, end the insertion

            movzx edx, byte [ebx]                           ; edx <- cur char with zero padding
            sub dl, 48                                      ; dl <- real value of curr char with zero padding
            push eax                                        ; backup eax
            shl al, 1                                       ; check if there is a room for 1 bit
            jc .no_free_bits                                ; if carry flag is on, no room available 
            pop eax                                         ; restore eax
            push eax                                        ; backup eax
            shl al, 2                                       ; check if there is a room for 2 bits
            jc .one_free_bit                                ; if carry flag is on, no room available
            pop eax                                         ; restore eax
            push eax                                        ; backup eax
            shl al, 3                                       ; check if there is a room for 3 bits
            jc .two_free_bits                               ; if carry flag is on, no room available
            pop eax                                         ; restore eax
            shl dl, cl                                      ; dl <- dl*2^counter (move data to the left)
            add al, dl                                      ; al <- al+dl (al recieve data from char)
            add ecx, 3                                      ; add 3 to counter
        .step:
            dec ebx                                         ; ebx <- next char
            jmp .loop
        .end: 
            pop ecx                                         ; restore ecx for addLink
            cmp eax, 0
            je .check_if_first
            jmp .push_data

            .check_if_first:
                cmp byte [isFirstLink], 1
                je .push_data

            .push_data:
                push eax                                    ; push data of new link
                call addLink
                add esp, 4                                  ; cleanup stack
            .end2:
                add ecx, 4                                  ; increase ecx to next available slot in stack
                jmp start_loop

        .no_free_bits:
            pop esi                                         ; restore esi (contain data of new link)
            mov al, dl                                      ; al <- new data of last char
            and edx, 0                                      ; reset edx
            pop ecx                                         ; restore ecx for addLink
            push esi                                        ; push data of new link
            call addLink
            add esp, 4                                      ; cleanup stack
            push ecx                                        ; backup ecx
            mov ecx, 3                                      ; set counter to 3
            jmp .step

        .one_free_bit:
            pop esi                                         ; restore esi (contain data of new link)
            mov al, dl                                      ; al <- data of curr char
            and dl, 1                                       ; get LSB of dl
            shl dl, 7                                       ; positon 1 rightmost bit in 1 leftmost cells 
            or esi, edx                                     ; combine esi and edx
            pop ecx                                         ; restore ecx for addLink
            push esi                                        ; push data of new link
            shr al, 1                                       ; delete the first bit
            call addLink
            add esp, 4                                      ; cleanup stack
            push ecx                                        ; backup ecx
            mov ecx, 2                                      ; set counter to 2
            jmp .step

        .two_free_bits:
            pop esi                                         ; restore esi (contain data of new link)
            mov al, dl                                      ; al <- data of curr char
            and dl, 3                                       ; get 2 rightmost bits of dl
            shl dl, 6                                       ; positon 2 rightmost bit in 2 leftmost cells 
            or esi, edx                                     ; combine esi and edx
            pop ecx                                         ; restore ecx for addLink
            push esi                                        ; push data of new link
            shr al, 2
            call addLink
            add esp, 4                                      ; cleanup stack
            push ecx                                        ; backup ecx
            mov ecx, 1                                      ; set counter to 3
            jmp .step



    case_operator:
        cmp byte [buffer], 113 	                            ; check if the input is 'q'
	    jz case_quit				                        ; if so quit the loop

        cmp byte [buffer], 43 	                            ; check if the input is '+'
	    jz case_addition			

        cmp byte [buffer], 112 	                            ; check if the input is 'p'
	    jz case_popAndPrint				

        cmp byte [buffer], 100 	                            ; check if the input is 'd'
	    jz case_duplicate				

        cmp byte [buffer], 38 	                            ; check if the input is '&'
	    jz case_and				

        cmp byte [buffer], 110 	                            ; check if the input is 'n'
	    jz case_n	

        ;cmp byte [buffer], 42 	                            ; check if the input is '*'
	    ;jz case_multiplication				
			
        case_quit:
            printing stdout, format_int, [operator_counter]
            .loop:
                cmp dword ecx, [op_stack]                   ; compare ecx (next available free spcae) with with start of the stack
                je .end                                     ; if so, no oprenads left to free 
                push dword [ecx-4]                          ; push next operand
                call free_operand                       
                add esp, 4                                  ; cleanup stack
                sub ecx, 4                                  ; ecx now point to next operand in stack or start of stack
                jmp .loop
            .end:
                cmp dword [op_stack], 1                     ; check if op_stack is allocated
                jne free_stack                              ; if so, free op_stack
                jmp restore_and_quit
                free_stack:
                    mov eax, [op_stack]
                    push eax
                    call free
                    add esp, 4                                  ; cleanup stack
            restore_and_quit:
            popad
            pop ebp
            ret

        case_addition:
            clc                                             ; CF <- 0
            cmp dword [num_of_elements], 2
            jl stack_underflow
            mov eax, ecx                                    ; eax <- ecx (pointer to available cell in stack)                                   
            sub eax, 4                                      ; get first operand address
            mov eax, [eax]                                      
            mov esi, ecx                                    ; eax <- ecx (pointer to available cell in stack)                                        
            sub esi, 8                                      ; get second operand address 
            mov esi, [esi]                                      
            mov edx, 0                                      ; reset edx
            mov ebx, 0                                      ; reset esi
            mov dl, byte [eax]                              ; dl <- data of first o            mov ecx, 0
            mov bl, byte [esi]                              ; esi <- data of second operand                
            pushf

            .loop:
                popf
                adc dl, bl                                  ; edx <- dl + esi + CF
                pushf
                push edx
                call addLink
                add esp, 4
                inc eax                                     ; eax now point to address of next link of first operand
                inc esi                                     ; ebx now point to address of next link of second operand
                cmp byte [op1F], 1
                je .step_first_operand
                mov edx, 0
                cmp byte [op2F], 1
                je .step_second_operand
                jmp .add_carry

            .step_first_operand:
                cmp dword [eax], 0                          ; check if next link of first operand is NULL
                je .first_empty
                mov dword eax, [eax]                        ; eax <- next link
                mov edx, 0
                mov dl, [eax]                               ; dl <- data of first operand
                jmp .step_second_operand
            
            .first_empty:
                mov edx, 0
                dec byte [op1F]
                jmp .step_second_operand
            
            .step_second_operand:
                cmp dword [esi], 0                          ; check if next link of second operand is NULL
                je .second_empty
                mov dword esi, [esi]                        ; ebx <- next link
                mov ebx, 0
                mov bl, byte [esi]                          ; dl <- data of first operand
                jmp .loop
            
            .second_empty:
                cmp byte [op1F], 0
                je .add_carry
                dec byte [op2F]
                mov ebx, 0
                jmp .loop
            
            .add_carry:
                mov ebx, 0
                popf
                jc .loop
                pushf
                jmp .end

            .end:
                popf
                inc dword [operator_counter]
                sub dword [num_of_elements], 2
                add dword [stack_size], 2

                mov eax, [ecx]                              ; get address of new link
                push dword [ecx-4]                          ; free second operand
                call free_operand
                add esp, 4                                  ; cleanup stack
                push dword [ecx-8]                          ; free first operand
                call free_operand
                add esp, 4                                  ; cleanup stack
                sub ecx, 8                                  ; ecx = stack address of first operand
                mov [ecx], eax                              ; replace first operand address with new link
                add ecx, 4                                  ; set next free space in stack
                
                cmp byte [debug_flag], 1
                jne .end2
                .run_debug:
                    call debug_print_result
                .end2:
                    jmp start_loop

        case_popAndPrint:
            cmp dword [num_of_elements], 0
            jz stack_underflow
            mov esi, ecx                                    ; set esi to hold adress of first link
            sub esi, 4
            mov eax, pop_buffer+79                          ; go the last char of pop_buffer
            mov byte [eax], 0                               ; put null-terminator in the end of the buffer
            dec eax

            .233link:
                mov dword esi, [esi]                        ; set ecx to point to start of first/next link
                mov dl, byte [esi]                          ; edx <- data of curr link
                and edx, 7                                  ; take last 3 bits of data
                add edx, 48                                 ; convert to ascii value
                mov [eax], dl                               ; put char value in pop_buffer
                sub eax, 1

                mov dl, byte [esi]                          ; edx <- data of curr link
                and edx, 56                                 ; take next 3 bits of data
                shr edx, 3                                  ; move the bits to right end of edx
                add edx, 48                                 ; convert to ascii value
                mov [eax], dl                               ; put char value in pop_buffer
                dec eax

                mov dl, byte [esi]                          ; edx <- data of curr link
                and edx, 192
                shr edx, 6
                inc esi                                     ; set esi to point address of next link
                cmp dword [esi], 0                          ; if next link is null
                jnz .1331link                               ; jump to next possible type of link

                add edx, 48                                 ; convert to ascii value
                mov [eax], dl                               ; put char value in pop_buffer
                jmp .print_number                           ; print the number
            
            .1331link:
                mov dword esi, [esi]                        ; set ecx to point to start of next link
                mov ebx, edx                                ; put aside bits we pulled from prev link
                mov edx, [esi]                              ; edx <- data of curr link
                and edx, 1                                  ; take last bit of data
                shl edx, 2
                or edx, ebx                                 ; combine with bits from prev link
                add edx, 48                                 ; convert to ascii value
                mov [eax], dl                               ; put char value in pop_buffer
                dec eax

                mov dl, byte [esi]                          ; edx <- data of curr link
                and edx, 14                                 ; take next 3 bits of data
                shr edx, 1                                  ; move the bits to right end of edx
                add edx, 48                                 ; convert to ascii value
                mov [eax], dl                               ; put char value in pop_buffer
                dec eax
                
                mov dl, byte [esi]                          ; edx <- data of curr link
                and edx, 112                                ; take next 3 bits of data
                shr edx, 4                                  ; move the bits to right end of edx
                add edx, 48                                 ; convert to ascii value
                mov [eax], dl                               ; put char value in pop_buffer
                dec eax

                mov dl, byte [esi]                          ; edx <- data of curr link
                and edx, 128
                shr edx, 7
                inc esi
                cmp dword [esi], 0                          ; if next link is null
                jnz .332link                                ; jump to next possible type of link
                
                add edx, 48
                mov [eax], dl                               ; put char value in pop_buffer
                jmp .print_number

            
            .332link:
                mov dword esi, [esi]                        ; set ecx to point to start of next link
                mov ebx, edx                                ; put aside bits we pulled from prev link
                mov edx, [esi]                              ; edx <- data of curr link
                and edx, 3                                  ; take last 2 bits of data
                shl edx, 1
                or edx, ebx                                ; combine with bits from prev link
                add edx, 48                                 ; convert to ascii value
                mov [eax], dl                               ; put char value in pop_buffer
                dec eax

                mov dl, byte [esi]                          ; edx <- data of curr link
                and edx, 28                                 ; take next 3 bits of data
                shr edx, 2                                  ; move the bits to right end of edx
                add edx, 48                                 ; convert to ascii value
                mov [eax], dl                               ; put char value in pop_buffer
                dec eax

                mov dl, byte [esi]                          ; edx <- data of curr link
                and edx, 224
                shr edx, 5
                add edx, 48                                 ; convert to ascii value
                mov [eax], dl                               ; put char value in pop_buffer
                dec eax
                inc esi
                cmp dword [esi], 0                          ; if next link is null
                jnz .233link                                ; jump to next possible type of link
                ;add edx, 48
                ;mov [eax], dl                               ; put char value in pop_buffer
                jmp .print_number

            .print_number:
                inc eax
                .clean_zeros_loop:
                    cmp byte [eax], 48                      ; check if curr char is '0'
                    jnz .end
                    inc eax
                    jmp .clean_zeros_loop
                
                .end:
                    cmp byte [eax], 0
                    jz .recreate_zero
                
                .end_continue:
                    printing stdout, format_string, eax
                    inc dword [operator_counter]
                    dec dword [num_of_elements]
                    inc dword [stack_size]

                    push dword [ecx-4]                      ; free operand
                    call free_operand
                    add esp, 4                              ; cleanup stack
                    sub ecx, 4                              ; ecx now points to next available space in stack  
            
                    jmp start_loop
                
                .recreate_zero:
                    mov byte [eax], 48
                    jmp .end_continue
            
                    
                            

        case_duplicate:
        cmp dword [num_of_elements], 1                      ; check if [num_of_elements] is atleast 1
        jl stack_underflow
        mov eax, ecx                                        ; eax <- address of free cell in stack
        sub eax, 4                                          ; get operand address in stack
        mov dword ebx, [eax]                                ; ebx <- address of link
        mov eax, ebx                                        ; eax <- address of link
            .loop:
                mov ebx, 0                                  ; reset ebx to 0
                mov bl, byte [eax]                          ; bl <- data of curr link
                push ebx                                    ; push data for addLink
                call addLink
                add esp, 4                                  ; cleanup stack
                inc eax                                     ; eax now point to address of next link
                cmp dword [eax], 0                          ; check if next link is NULL
                je .end                                     ; if so, end the function
            .step:
                mov dword eax, [eax]                        ; eax <- next link
                jmp .loop
            .end:
                inc dword [operator_counter]                ; increase num of operators
                add ecx, 4                                  ; ecx now points to next available space in stack

                cmp byte [debug_flag], 1
                jne .end2
                .run_debug:
                    call debug_print_result
                .end2:
                    jmp start_loop
                
                
        case_and:
        cmp dword [num_of_elements], 2
        jl stack_underflow
        mov eax, ecx                                        ; eax <- ecx (pointer to available cell in stack)                                   
        sub eax, 4                                          ; get first operand address
        mov eax, [eax]                                      ; get first link of first operand
        mov ebx, ecx                                        ; eax <- ecx (pointer to available cell in stack)                                        
        sub ebx, 8                                          ; get second operand address    
        mov ebx, [ebx]                                      ; get first link of second operand                                      

            .loop:
                mov edx, 0                                  ; reset edx
                mov esi, 0                                  ; reset esi
                mov dl, byte [eax]                          ; dl <- data of first operand
                mov esi, [ebx]                              ; esi <- data of second operand
                and edx, esi                                ; dl <- result of '&' bitwise of curr link
                push edx
                call addLink
                add esp, 4
                inc eax                                     ; eax now point to address of next link of first operand
                inc ebx                                     ; ebx now point to address of next link of second operand
                cmp dword [eax], 0                          ; check if next link of first operand is NULL
                je .end                                     ; if so, end the function
                cmp dword [ebx], 0                          ; check if next link of first operand is NULL
                je .end                                     ; if so, end the function
            .step:
                mov dword eax, [eax]                        ; eax <- next link
                mov dword ebx, [ebx]                        ; ebx <- next link
                jmp .loop
            .end:
                inc dword [operator_counter]
                sub dword [num_of_elements], 2
                add dword [stack_size], 2

                mov eax, [ecx]                              ; get address of new link
                push dword [ecx-4]                          ; free second operand
                call free_operand
                add esp, 4                                  ; cleanup stack
                push dword [ecx-8]                          ; free first operand
                call free_operand
                add esp, 4                                  ; cleanup stack
                sub ecx, 8                                  ; ecx = stack address of first operand
                mov [ecx], eax                              ; replace first operand address with new link
                add ecx, 4                                  ; set next free space in stack

                cmp byte [debug_flag], 1
                jne .end2
                .run_debug:
                    call debug_print_result
                .end2:
                    jmp start_loop
                

        case_n:
            cmp dword [num_of_elements], 1
            jl stack_underflow
            mov eax, ecx                                    ; eax <- address of free cell in stack
            sub eax, 4                                      ; get operand address in stack
            mov dword eax, [eax]                            ; eax <- address of link
            mov ebx, 0                                      ; reset ebx - link counter
            .loop:
                mov dl, byte [eax]                          ; bl <- data of curr link
                inc ebx                                     ; increase ebx
                inc eax                                     ; eax now point to address of next link
                cmp dword [eax], 0                          ; check if next link is NULL
                je .end                                     ; if so, end the function
            .step:
                mov dword eax, [eax]                        ; eax <- next link
                jmp .loop
            .end:
                push ebx
                call addLink
                add esp, 4                                  ; cleanup stack

                inc dword [operator_counter]                ; increase num of operators
                dec dword [num_of_elements]
                inc dword [stack_size]

                push dword [ecx-4]                          ; free operand
                call free_operand
                add esp, 4                                  ; cleanup stack

                mov eax, [ecx]                              ; get address of result
                mov [ecx-4], eax                            ; set result address to be previous operand

                cmp byte [debug_flag], 1
                jne .end2
                .run_debug:
                    call debug_print_result
                .end2:
                    jmp start_loop
                
                

        ;case_multiplication:

        stack_underflow:
            printing stderr, format_string, underflow_string
            jmp start_loop

szatoi:                                                     ; function that converts octal string to numeric value
    push ebp
    mov ebp, esp

    mov ebx, dword [ebp+8]                                  ; ebx <- pointer to the string
    mov eax, 0                                              ; eax <- ouput value
    .loop:                                                  ; go over all chars in string
        cmp byte [ebx], 0                                   ; checks if curr char is null- terminator
        je .return

        movzx edx, byte [ebx]                               ; edx <- cur char with zero padding
        sub edx, 48                                         ; edx <- real value of curr char with zero padding
        shl eax, 3                                          ; multiply eax by 8
        add eax, edx                                        ; add the value of the curr char to eax
        inc ebx                                             ; ebx <- next char
        jmp .loop                                           ; continue looping
    
    .return:
        pop ebp
        ret

addLink:
    push ebp 
    mov ebp, esp
    pushad

    mov edx, [ebp+8]
    cmp byte [isFirstLink], 1
    jz .add_first_link
    jmp .add_link

    .add_first_link:
        cmp dword [stack_size], 0                           ; check for availible free space in stack
        je .stack_overflow
        push ecx
        push edx
        push 5
        call malloc
        add esp, 4
        pop edx
        pop ecx
        mov [ecx], eax
        mov byte [eax], dl
        inc eax
        mov dword [eax], 0
        and byte [isFirstLink], 0
        jmp .return_first_link

    .add_link:
        push ecx
        push edx
        push 5
        call malloc
        add esp, 4
        pop edx
        pop ecx
        mov dword ebx, [ecx]
        inc ebx
        .findNextLink:
            cmp dword [ebx], 0
            jnz .step
            jmp .continue
            .step:
                mov ebx, [ebx]
                inc ebx
                jmp .findNextLink

        .continue:
            mov dword [ebx], eax
            mov byte [eax], dl
            inc eax
            mov dword [eax], 0
            jmp .return

    .stack_overflow:
        printing stderr, format_string, overflow_string
        add esp, 4
        jmp start_loop

    .return_first_link:
        popad
        dec dword [stack_size]
        inc dword [num_of_elements]
        pop ebp
        ret

    .return:
        popad
        pop ebp
        ret    

free_operand:                                               ; recieve heap address of the first link in chain
    push ebp
    mov ebp, esp
    pushad   
    mov eax, [ebp+8]                                        ; eax <- argument
    mov ebx, [eax+1]                                        ; ebx <- heap address of next of argument
        .loop:
        startFunction
        push eax
        call free
        add esp, 4
        endFunction
        cmp dword ebx, 0
        jnz .step
        jmp .end
        .step:
            mov dword eax, ebx                              ; eax <- next
            mov dword ebx, [eax+1]                          ; ebx <- heap address of next of argument
            jmp .loop
        .end:
        popad
        pop ebp
        ret  
        
debug_print_input:
    printing stderr, format_string, buffer
    ret  

debug_print_result:
    ret  