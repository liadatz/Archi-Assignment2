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

%macro printing 3
    pushad
    push %3
    push %2
    push dword [%1]
    call fprintf
    add esp, 12
    popad
%endmacro

section .data                                               ; we define (global) initialized variables in .data section
    stack_size: dd 5                                     ; 4bytes stack counter- counts the number of free spaces
    num_of_elements: dd 0                                   ; define number of current elements in stack 
    operator_counter: dd 0                                  ; 4bytes counter- counts the number of operations.
    args_counter: dd 0                                           ; 4bytes counter
    op_stack: dd 1                                          ; initalize an empty pointer
    debug_flag: db 0
    isFirstLink: db 1

section	.rodata					                            ; we define (global) read-only variables in .rodata section
	format_string: db "%s", 10, 0	                        ; format string for printf func
    format_int: db "%d", 10, 0	                            ; format int for printf func
    format_oct: db "%o", 0                                  ; format for octal number
    prompt_string: db "calc: ", 0                           ; format for prompt message
    overflow_string: db "Error: Operand Stack Overflow",0   ; format for overflow message
    max_args_string: db "Error: To much arguments entered",0; format for arguments error
    underflow_string: db "Error: Insufficient Number of Arguments on Stack" ,  ; format for non enough operands in stack error


section .bss						                        ; we define (global) uninitialized variables in .bss section
    buffer: resb 80                                         ; 80bytes buffer- stores input from user (max length of input is 80 chars)
    buffer_length: resb 80                                         
    


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

    init:
        mov ebx, [ebp+8]
        dec ebx
        mov [args_counter], ebx                     ; set counter to number of 'extra args'
        cmp byte [args_counter], 2
        jg .error

        mov dword ebx, [ebp+12]                             ; ebx <- argument array
        add ebx, 4                                          ; ebx <- first 'extra argument'
        
        .loop:
            cmp dword [args_counter], 0
            jz modify_stack
            cmp byte [ebx], 45
            jz .debug_on
            jmp .set_stack_size

        .debug_on:
            or byte [debug_flag], 1                     ; turn on debug flag
            sub byte [args_counter], 1                  ; reduce args counter by 1
            add ebx, 4                                  ; move to next extra arg
            jmp .loop                                   ; loop again

        .set_stack_size:
            push ebx                                    ; push arg to szatoi func
            call szatoi                                 ; call function szatoi
            add esp, 4                                  ; clean stack after func call
            mov dword [stack_size], eax                 ; save return value as stack size
            sub byte [args_counter], 1                  ; reduce args counter by 1
            add ebx, 4                                  ; move to next extra arg
            jmp .loop                                   ; loop again
            
        .error:
            push max_args_string		                 ; call printf with 2 arguments -  
            push format_string			                 ; pointer to prompt message and pointer to format string
            call printf                
            add esp, 8			                         ; clean up stack after call
            jmp case_quit

    modify_stack:
        push ecx
        push dword [stack_size]   ;???                            
        call malloc
        add esp, 4                                      ; clean stack after func call
        pop ecx
        mov [op_stack], eax
        mov ecx, [op_stack]                             ; set ecx to point the top of the op_stack
        jmp start_loop
    

    start_loop:
        or byte [isFirstLink], 1
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
        
        cmp byte [buffer], 48                               ; check if the input greater than '0'
	    jge is_number				                        ; if so jump to 'is_number' label

        jmp case_operator                                   ; if not, then the input is an operator

        

    is_number:
        cmp byte [buffer], 57                               ; check if the input is lesser than '9'
        jle case_operand                                    ; if so, the input first char is a number, and we want to deal with the it as a operand
        
        jmp case_operator                                   ; if not, then the input is an operator


    case_operand:
        push ecx
        mov dword ebx, buffer                ; ebx <- pointer to the string
        mov eax, 0                           ; al <- first value (00000000)
        mov ecx, 0 ; counter

        .charLoop:
        cmp byte [ebx+1], 0   ; check if next char is '0' (end of string) ?? maybe \n ??
        jne .incPointer
        jmp .loop  ; now ebx point to the end of the string

            .incPointer:
            inc ebx
            jmp .charLoop
        
        .loop:
            cmp dword ebx, buffer-1
            je .end

            movzx edx, byte [ebx]               ; dl <- cur char with zero padding
            sub dl, 48                          ; dl <- real value of curr char with zero padding
            push eax
            shl al, 1
            jc .no_free_bits
            pop eax
            push eax
            shl al, 2
            jc .one_free_bit
            pop eax
            push eax
            shl al, 3
            jc .two_free_bits
            pop eax
            shl dl, cl
            add al, dl
            add ecx, 3 
        .continue:
            dec ebx                          ; ebx <- next char
            jmp .loop 
        .end: 
            pop ecx
            push eax
            call addLink
            add esp, 4
            add ecx, 4
            jmp start_loop
         .no_free_bits:
            mov al, dl
            and edx, 0
            mov ecx, [esp-8]
            call addLink
            mov ecx, 3
            add esp, 4
            jmp .continue

         .one_free_bit:
            pop esi
            mov al, dl
            and dl, 1
            shl dl, 7
            or esi, edx
            push esi
            shr al, 1
            mov ecx, [esp-8]
            call addLink
            mov ecx, 2
            add esp, 4
            jmp .continue

         .two_free_bits:
            pop esi
            mov al, dl
            and dl, 3
            shl dl, 6
            or esi, edx
            push esi
            shr al, 2
            mov ecx, [esp-8]
            call addLink
            mov ecx, 1
            add esp, 4
            jmp .continue


        
        


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
            startFunction
            push dword [operator_counter]			 ; call printf with 2 arguments -  
            push dword [format_int]			     ; pointer to prompt message and pointer to format string
            call printf            
            add esp, 8			             ; clean up stack after call
            endFunction

        case_addition:

        case_popAndPrint:

        case_duplicate:
        cmp dword [num_of_elements], 1
        jl stack_underflow
        mov eax, ecx ; get operand address (first link)
        sub eax, 4
        mov dword ebx, [eax] ; bl <- address of operand
        
            .loop:
                mov eax, ebx
                mov ebx, 0
                mov bl, byte [eax]
                push ebx
                call addLink
                add esp, 4
                inc eax
                ;cmp dword [eax+1], 0
                mov dword eax, [eax] ; eax <- next link
                cmp eax, 0 ; check if curr link is NULL
                je .finish
                ;mov dword eax, [eax+1] ; eax <- next link
                jmp .loop

            .finish:
                inc dword [operator_counter]
                inc dword [num_of_elements]
                dec dword [stack_size]
                jmp start_loop
                
                

        case_and:
        cmp dword [num_of_elements], 2
        jl stack_underflow
        mov eax, ecx    ; get first operand address (first link)
        sub eax, 4
        mov ebx, ecx    ; get second operand address (first link)
        sub eax, 8

            .loop:
                mov byte dl, [eax] ; dl <- data of first operand
                mov esi, [ebx] ; esi <- data of second operand
                and edx, esi ; dl <- result of '&' bitwise of curr link
                push edx
                call addLink
                add esp, 4
                mov dword eax, [eax+1] ; eax <- next link
                cmp eax, 0 ; check if curr link is NULL
                je .finish
                mov dword ebx, [ebx+1] ; ebx <- next link
                cmp ebx, 0 ; check if curr link is NULL
                je .finish
                jmp .loop
            
            .finish:
                inc dword [operator_counter]
                dec dword [num_of_elements]
                inc dword [stack_size]
                mov eax, ecx ; get address of new link
                sub eax, 4
                sub ecx, 12
                mov [ecx], eax ; set first operand in stack to be new link
                add ecx, 4 ; set new current location of stack
                jmp start_loop
                

        case_n:

        ;case_multiplication:

        stack_underflow:
            push underflow_string			             ; call printf with 2 arguments -  
            push format_string			                 ; pointer to prompt message and pointer to format string
            call printf                
            add esp, 8			                         ; clean up stack after call
            jmp start_loop

szatoi:                                                 ; function that converts octal string to numeric value
    push ebp
    mov ebp, esp

    mov ebx, dword [ebp+8]                              ; ebx <- pointer to the string
    mov eax, 0                                          ; eax <- ouput value
    .loop:                                              ; go over all chars in string
        cmp byte [ebx], 0                               ; checks if curr char is null- terminator
        je .return

        movzx edx, byte [ebx]                           ; edx <- cur char with zero padding
        sub edx, 48                                     ; edx <- real value of curr char with zero padding
        shl eax, 3                                      ; multiply eax by 8
        add eax, edx                                    ; add the value of the curr char to eax
        inc ebx                                         ; ebx <- next char
        jmp .loop                                       ; continue looping
    
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
        cmp dword [stack_size], 0            ; check for availible free space in stack
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
            mov byte [eax], dl
            inc eax
            mov dword [eax], 0
            mov dword [ebx], eax
            jmp .return

    .stack_overflow:
        push overflow_string			             ; call printf with 2 arguments -  
        push format_string			                 ; pointer to prompt message and pointer to format string
        call printf                
        add esp, 8			                         ; clean up stack after call
        jmp start_loop

    .return_first_link:
        popad
        ;add ecx, 4
        dec dword [stack_size]
        inc dword [num_of_elements]
        pop ebp
        ret

    .return:
        popad
        pop ebp
        ret    



   