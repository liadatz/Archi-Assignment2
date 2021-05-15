

section .data                                               ; we define (global) initialized variables in .data section
    counter_stack: dd 5                                     ; 4bytes stack counter- counts the number of free spaces
    counter: dd 0                                           ; 4bytes counter- counts the number of operations.
    op_stack: TIMES 5 dd 0                                  ; initalize array of pointers in the size of 5 (default)
    binary_value: TIMES 3 db 0                              ; 12 zero bits that will be modified to represent the binary value of an 4 chars operand

section	.rodata					                            ; we define (global) read-only variables in .rodata section
	format_string: db "%s", 10, 0	                        ; format string for printf func
    format_int: db "%d", 10, 0	                            ; format int for printf func
    prompt_string: db "calc: ", 0                           ; format for prompt message
    overflow_string: db "Error: Operand Stack Overflow",10,0; format for overflow message


section .bss						                        ; we define (global) uninitialized variables in .bss section
    buffer: resb 80                                         ; 80bytes buffer- stores input from user (max length of input is 80 chars)
    

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

    init:
        cmp byte [esp], 1                                     ; check if argc is greater the 1
        jg modify_stack                                     ; we need to change the stack size
        
        mov ecx, op_stack                                   ; set ecx to point the top of the op_stack
        jmp start_loop

    modify_stack:
        mov eax, [esp + 8]
        mul eax, 4
        push eax
        call malloc
        add esp, 4			                                ; clean up stack after call
        mov op_stack, eax
        mov counter_stack, [esp + 8]                        ; set number of free spaces in stack to argv[1]    
        mov ecx, op_stack                                   ; set ecx to point the top of the op_stack
        jmp start_loop
    

    start_loop:
        push prompt_string			                        ; call printf with 2 arguments -  
		push format_string			                        ; pointer to prompt message and pointer to format string
		call printf
        add esp, 8					                        ; clean up stack after call

        push dword buffer                                   ; input buffer
        call gets
        add esp, 4                                          ; remove 1 push from stuck

        cmp byte [buffer], 48                               ; check if the input greater than '0'
	    jge is_number				                        ; if so jump to 'is_number' label

        jmp case_operator                                   ; if not, then the input is an operator

        

    is_number:
        cmp byte [buffer], 57                               ; check if the input is lesser than '9'
        jle case_operand                                    ; if so, the input first char is a number, and we want to deal with the it as a operand
        
      jmp case_operator                                     ; if not, then the input is an operator


    case_operand:
        mov edx, 0                                          
        mov ebx, 1
  

        operand_loop:
            cmp byte [buffer+edx], 10
            jz start_loop
            jmp binary_convertor

        operand_loop_continue:
            add edx, 4
            cmp ebx, 1
            je add_first_link
            jmp add_link
        


        add_first_link:
            cmp counter_stack, 0                             ; check for availible free space in stack
            je stack_overflow                                   ; if stack is full prompt error message

            push 7                                              ; push size of link in bytes
            call malloc
            add esp, 4			                                ; clean up stack after call
            mov [ecx], eax                                      ; set current free space to new allocated space
            mov byte [eax], binary_value                      ; set first byte in link
            inc eax
            mov byte [eax], binary_value+1                  ; set second byte in link
            inc eax
            mov byte [eax], binary_value+2                  ; set third byte in link
            inc eax
            mov [eax], 0                                 ; set next link to be NULL

            add ecx, 4                                          ; move ecx to the next availible free space
            sub counter_stack, 1                                ; substract 1 free space from number of availible free space in stack
            mov ebx, 0

            and binary_value, 0
        
            jmp operand_loop

            stack_overflow:
                push overflow_string			                ; call printf with 2 arguments -  
                push format_string			                    ; pointer to prompt message and pointer to format string
                call printf
                add esp, 8			                            ; clean up stack after call
                jmp start_loop
            

        add_link:
            push 7                                              ; push size of link in bytes
            call malloc
            add esp, 4			                                ; clean up stack after call
            mov ebx, [ecx-4]                                    ; temp
            mov [ecx-4], eax                                    ; set current free space to new allocated space
            mov byte [eax], binary_value                        ; set first byte in link
            inc eax
            mov byte [eax], binary_value+1                  ; set second byte in link
            inc eax
            mov byte [eax], binary_value+2                  ; set third byte in link
            inc eax
            mov [eax], ebx                                 ; set next link to be to be the previous link in [ecx]
        
            and binary_value, 0

            jmp operand_loop


        
        binary_convertor:
            push ebp                                                                               
            mov ebp, esp
            pushad
            
            mov ecx, buffer
            add ecx, edx
            mov eax, 2                                                              
            mov edx, 1
            jmp looping

            loopin:
                mov ebx, 0
                sub byte [ecx], 48                                                  ;get numeric value of the char
                jmp dec_to_binary

            dec_to_binary:
                cmp ebx, 3
                jz next_char
                shr byte [ecx], 1
                jc with_carry
                jmp without_carry

            with_carry:
                or [binary_value+eax], 1                                            ; change 'zero' bit to 'one' bit
                dec eax                                                             ; decrease number of bits counter
                inc ebx
                jmp dec_to_binary                                                 

            without_carry:
                dec eax                                                             ; decrease number of bits counter
                inc ebx
                jmp dec_to_binary

            next_char:
                add eax, 6
                inc ecx
                inc edx
                cmp byte [ecx], 10
                jz finish_1
                cmp edx, 5
                jz finish_2
                jmp looping

            finish_1:
                mul ebx, 3
                shr [binary_value], ebx
                jmp finish_2

            finish_2:
                popad
                mov esp, ebp
                pop edp
                jmp operand_loop_continue


    case_operator:
        cmp byte [buffer], 113 	                            ; check if the input is 'q'
	    jz quit_loop				                        ; if so quit the loop

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
            push counter			 ; call printf with 2 arguments -  
            push format_int			 ; pointer to prompt message and pointer to format string
            call printf
            add esp, 8			     ; clean up stack after call

        case_addition:

        case_popAndPrint:

        case_duplicate:

        case_and:

        case_n:

        ;case_multiplication:

    