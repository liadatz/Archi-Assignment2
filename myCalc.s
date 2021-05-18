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

section .data                                               ; we define (global) initialized variables in .data section
    counter_stack: dd 5                                     ; 4bytes stack counter- counts the number of free spaces
    counter: dd 0                                           ; 4bytes counter- counts the number of operations.
    op_stack: dd 1                                          ; initalize an empty pointer
    binary_value: dd 0                                      ; 16 zero bits that will be modified to represent the binary value of an 4 chars operand
    debug_flag: db 1

section	.rodata					                            ; we define (global) read-only variables in .rodata section
	format_string: db "%s", 10, 0	                        ; format string for printf func
    format_int: db "%d", 10, 0	                            ; format int for printf func
    format_oct: db "%o", 0                                  ; format for octal number
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
        ;cmp byte [esp], 1                                   ; check if argc is greater the 1
        ;jg modify_stack                                     ; we need to change the stack size
        push 5
        call malloc
        add esp, 4
        mov dword [op_stack], eax                                      

        mov ecx, [op_stack]                                   ; set ecx to point the top of the op_stack
        jmp start_loop

    modify_stack:
        mov eax, [esp + 8]
        mov ebx, 4
        mul ebx
        ;startFunction
        push eax
        call malloc
        add esp, 4
        ;endFunction
        mov [op_stack], eax
        mov eax, [esp + 8]
        mov [counter_stack], eax                            ; set number of free spaces in stack to argv[1]    
        mov ecx, [op_stack]                                 ; set ecx to point the top of the op_stack
        jmp start_loop
    

    start_loop:
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
        mov edx, 0                                          ; current location in the String (char index)                                        
        mov ebx, 1                                          ; first link flag
  

        operand_loop:
            cmp byte [buffer+edx], 10                       ; check if current char in '\n' (indicate no char left to read)
            jz finish_operand_loop

            jmp binary_convertor                            ; otherwise, convert current string to binary 

        operand_loop_continue:
            add edx, 4                                      ; add 4 to the char index of the string
            cmp ebx, 1                                      ; check if first link flag is on
            je add_first_link                               ; if so, jump to add first link
            jmp add_link                                    ; otherwise, jump to add link
        
        finish_operand_loop:
            cmp byte [debug_flag], 1
            jz print_number
            jmp start_loop
        

        add_first_link:
            cmp dword [counter_stack], 0                     ; check for availible free space in stack
            je stack_overflow                                ; if stack is full prompt error message
            push ecx
            push 7                                           ; push size of link in bytes
            startFunction
            call malloc
            endFunction            
            add esp, 4			                             ; clean up stack after call
            pop ecx
            push edx
            mov [ecx], eax                         ; set current free space to new allocated space
            mov byte dl, [binary_value] 
            mov byte [eax], dl                     ; set first byte in link
            inc eax
            mov byte dl, [binary_value+1] 
            mov byte [eax], dl                  ; set second byte in link
            inc eax
            mov byte dl, [binary_value+2] 
            mov byte [eax], dl                   ; set third byte in link
            inc eax
            mov dword [eax], 0                                     ; set next link to be NULL

            add ecx, 4                                       ; move ecx to the next availible free space
            sub dword [counter_stack], 1                     ; substract 1 free space from number of availible free space in stack
            mov ebx, 0                                       ; set first link flag to 0
            and dword [binary_value], 0                            ; reset binary value   
            pop edx
            jmp operand_loop                                 ; jump to operand loop

            stack_overflow:
                push overflow_string			             ; call printf with 2 arguments -  
                push format_string			                 ; pointer to prompt message and pointer to format string
                startFunction
                call printf
                endFunction                
                add esp, 8			                         ; clean up stack after call
                jmp start_loop
            
        add_link:
            push 7                                           ; push size of link in bytes
            startFunction
            call malloc
            endFunction            
            add esp, 4			                             ; clean up stack after call
            push edx
            mov ebx, [ecx-4]                                 ; save previous link
            mov [ecx-4], eax                                 ; set current free space to new allocated space
            mov dl, [binary_value]
            mov byte [eax], dl                               ; set first byte in link
            inc eax
            mov dl, [binary_value+1]
            mov byte [eax], dl                               ; set second byte in link
            inc eax
            mov dl, [binary_value+2]
            mov byte [eax], dl                               ; set third byte in link
            inc eax
            mov [eax], ebx                                   ; set next link to be to be the previous link in [ecx]
        
            and dword [binary_value], 0                              ; reset binary value  
            mov ebx, 0                                       ; set first link flag to 0
            pop edx
            jmp operand_loop


        
        binary_convertor:
            push ebp                                         ; save stack pointer                                                       
            mov ebp, esp                                     ; set stack to curr location
            pushad                                           ; backup registers
            
            mov ebx, buffer                                  ; set ecx <- pointer to start point of the input string
            add ebx, edx                                     ; move ecx to point the first out of the next 4 chars
            mov eax, 2                                       ; set eax <- offset to the number of the bit being calculated out of the 3 per each char         
            mov edx, 1                                       ; set eax <- countes number of char that was converted so far

            looping:
                mov ecx, 0                                   ; set ecx <-  num of bits written so far for one char (zero out of three)
                sub byte [ebx], 48                           ; get numeric value of the char (according to ascii table)

            dec_to_binary:
                cmp ecx, 3                                   ; check if all three bits for the current char were written
                jz next_char                                 ; if so, go to convert next char
                shr byte [ebx], 1                            ; divide numeric value of first char by 2 
                jc with_carry                                ; checks if after division carry flag is on
                jmp without_carry                            ; check is after division carry flag is of

            with_carry:
                or byte [binary_value+eax], 128              ; change 'zero' bit to 'one' bit ??? byte ??? or with 10000000
                dec eax                                      ; decrease number of bits offset   
                inc ecx                                      ; increase number of bits that were written
                jmp dec_to_binary                            ; continue convert the same char 

            without_carry:
                dec eax                                      ; decrease number of bits counter
                inc ecx                                      ; increase number of bits that were written
                jmp dec_to_binary                            ; continue convert the same char

            next_char:
                add eax, 5                                   ; add 5 to the offset to the bit that needs to be written
                inc ebx                                      ; move the pointer to the next char out of the 4           
                inc edx                                      ; increase the number of chars that were converted
                test:
                cmp byte [ebx], 10                           ; checks if the current char that need to be converted is '\n'
                jz finish_1                                  ; if so jump to first part of finish converting
                cmp edx, 5                                   ; checks if 4 chars were already converted
                jz finish_2                                  ; if so jumps to second part of finish converting
                jmp looping                                  ; continue to convert the current char need to be converted

            finish_1:
                mov eax, ecx
                mov ecx, 3
                mul ecx                                     ; calculate the number of shifts need to be done to move the whole bits to the LSB
                mov ecx, eax
                shr dword [binary_value], cl                     ; shift the bits to the LSB side of the 'binary value' bits
                jmp finish_2                                ; jump to second part of finish converting

            finish_2:
                popad                                       ; pop al register that was backuped
                mov esp, ebp                                 
                pop ebp
                jmp operand_loop_continue                   ; continue to deal with the operand after value was converted


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
            push counter			 ; call printf with 2 arguments -  
            push format_int			 ; pointer to prompt message and pointer to format string
            startFunction
            call printf
            endFunction            
            add esp, 8			     ; clean up stack after call

        case_addition:

        case_popAndPrint:

        case_duplicate:

        case_and:

        case_n:

    print_number:
        mov edx, 0
        mov eax, [ecx-4]        ; eax = address on heap
        cmp byte [eax], 0 
        jnz print_loop

        print_loop:
            cmp byte [eax], 0
            jz start_print
            mov dword ebx, [eax]    ; ebx = 4bytes from the start of the link
            shr ebx, 8              ; ebx contains only data 
            push ebx
            push format_oct
            inc edx
            add eax, 3              ; set eax to next link
            jmp print_loop

        start_print:
            cmp edx, 0
            jnz print
            jz start_loop                                   

        print:
            startFunction
            call printf
            endFunction            
            add esp, 8
            dec edx
            jmp start_print






        ;case_multiplication:

    