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
    operator_counter: dd 0                                  ; 4bytes counter- counts the number of operations.
    counter: dd 0                                           ; 4bytes counter
    op_stack: dd 1                                          ; initalize an empty pointer
    debug_flag: db 1

section	.rodata					                            ; we define (global) read-only variables in .rodata section
	format_string: db "%s", 10, 0	                        ; format string for printf func
    format_int: db "%d", 10, 0	                            ; format int for printf func
    format_oct: db "%o", 0                                  ; format for octal number
    prompt_string: db "calc: ", 0                           ; format for prompt message
    overflow_string: db "Error: Operand Stack Overflow",10,0; format for overflow message


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
        cmp dword [ebp+8], 1                                   ; check if argc is greater the 1
        jg modify_stack                                     ; we need to change the stack size
        push 5
        call malloc
        add esp, 4
        mov dword [op_stack], eax                                      

        mov ecx, [op_stack]                                   ; set ecx to point the top of the op_stack
        jmp start_loop

    modify_stack:
        mov dword ebx, [ebp + 12]                              ; ebx <- string representing stack size (in octal)
        mov dword ebx, [ebx + 4]
        push ebx                                        ; push ebx as an argument
        sub esp, 4
        call szatoi                                     ; call function szatoi
        pop eax
        add esp, 4                                      ; clean stack after func call
        push eax                                        ; eax is return value of szatoi
        call malloc
        add esp, 4                                      ; clean stack after func call

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
            push operator_counter			 ; call printf with 2 arguments -  
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

szatoi:                                                             ; function that converts octal string to numeric value
    push ebp
    mov ebp, esp

    mov ebx, dword [ebp+8]                              ; ebx <- pointer to the string
    mov eax, 0                                          ; eax <- ouput value
    .loop:                                              ; go over all chars in string
        cmp byte [ebx], 0                               ; checks if curr char is null- terminator
        je .return

        movzx ecx, byte [ebx]                           ; ecx <- cur char with zero padding
        sub ecx, 48                                     ; ecx <- real value of curr char with zero padding
        shl eax, 3                                      ; multiply eax by 8
        add eax, ecx                                    ; add the value of the curr char to eax
        inc ebx                                         ; ebx <- next char
        jmp .loop                                       ; continue looping
    
    .return:
        mov esp, ebp
        pop ebp
        mov dword [esp-4], eax

        


    