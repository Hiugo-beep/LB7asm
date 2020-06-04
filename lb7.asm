.model tiny
.code 
org 100h     ;com-program



Start:   
jmp start_program

;////////////////////////////////////////////////PRINT STR/////////////////////////////  
 macro print str
	mov ah,9
	mov dx,offset new_line 
	int 21h
  mov ah,9
  mov dx,offset str
  int 21h
  mov ah,9
	mov dx,offset new_line 
	int 21h
 endm  


;////////////////////////////////////////////////LOAD PROGTAM PATHR/////////////////////////////   
macro load_program path
     mov ax, 4B00h             ;function DOS 4Bh
    mov dx, offset path  ;file path
    mov bx, offset EPB           ;block EPB
    int 21h       
    
endm


;////////////////////////////////////////////////GET CATALOG NAME //////////////////////////////////////
get_path_name proc  
    xor cx, cx
    mov cl, es:[80h]  ;this adress contains size of cmd 
    cmp cl, 0 
    je empty_cmd
    mov di, 82h       ;start of cmd
    lea si, path_name     
get_symbols:
    mov al, es:[di]    
    cmp al, 0Dh       ;compare with end  
    je continue_main   
    cmp al, ' '
    je too_many_args
    mov [si], al       
    inc di            
    inc si  
            
jmp get_symbols 

    empty_cmd:
    print empty_cmd_message 
    jmp exit 
    too_many_args:
    print too_many_message 
    jmp  exit 
ret
get_path_name endp  
 

macro change_directory str ;NEAR USES ax,dx  
    xor ax,ax
    mov ah, 3Bh
    mov dx, offset str 
    int 21h
    jc exit
   ; print successful_directory_change  
endm 


 
 start_program:
    PUSHA
    
     print welcome       
     call get_path_name
     
    
    continue_main:

    print path_name 
    change_directory path_name 
    
        mov sp, program_length + 100h + 200h 
    mov ah, 4Ah   ;reduce program memory
    stack_shift = program_length + 100h + 200h
    mov bx, stack_shift shr 4 + 1  ;paragrave size
    int  21h    
    ;fill in the fields EPB, containing segment addresses        
    mov ax,cs
    mov word ptr EPB+4,ax    ;command line sigment
    mov word ptr EPB+8,ax    ;first segment FCB 
    mov word ptr EPB+0Ch,ax  ;second segment FCB      
    
    mov si, offset mask_file
    mov di, offset path_name
    copy_loop:      
        cmp [di], 0
        JE copy_loop_end
        
        mov ax, [di]
        mov [si],ax
        inc si
        inc di
    
    jmp copy_loop
    copy_loop_end:
    mov [si],'\'
    mov [si+1], '*' 
    mov [si+2],'.'
    mov [si+3], 'c'
    mov [si+4], 'o'
    mov [si+5],'m'
   mov [si+6],0
    print mask_file
    
    xor ax,ax
    mov ah, 4Eh      
    xor cx,cx
    mov dx, offset mask_file
    int 21h
    jc exit
    
   mov di, offset found_file 
    mov si, 80h+1Eh 
    mov count, 0
    copy_loop1: 
    
    mov ax,[si] 
    mov [di],ax
    inc si
    inc di   
    
    inc count
    cmp count,5
    JE end_copy_loop1 
    JMP copy_loop1
    
     end_copy_loop1:
     
     mov [di], 0
     add index_mask_file,6 
     print found_file  
     
    ;moving the stack on 200h after the end of the program
 
is_new_file:

; load_program found_file    
    xor ax,ax
    mov ah, 4Fh      

   
    int 21h
    jc no_more_file

  
     print mask_file 
    mov di, offset found_file
    add di,  index_mask_file
    mov si,offset 80h+1Eh 
    mov count, 0
    copy_loop2:
    MOVSB 
    inc count
    cmp count,5
    JE end_copy_loop2 
    JMP copy_loop2
    
     end_copy_loop2:
     
     mov [di], 0
    
     print found_file  
     
    inc count_file   
    add index_mask_file, 6
jmp is_new_file    


no_more_file:
print no_more_file_message

next_step:

mov index_real,0 

load_files:   
mov di, offset  real_load_file 
mov si, offset found_file
add si, index_real
 copy_loop_3:
 cmp [si],0 
 JE end_copy_loop_3
 
 mov ax,[si]
 mov [di],ax
 inc si
 inc di

 jmp copy_loop_3
 end_copy_loop_3:
   
 mov [di],0        

load_program real_load_file 

 add index_real, 6

 cmp count_file ,0 
  je end_exit 
  dec count_file 

  
jmp load_files
end_exit:  
    
    
    
    change_directory home_directory_name      

    POPA
    int 20h 
    

    
exit:            
    CMP ax, 02h
    JNE next1
	mov ah,9
	mov dx,offset new_line 
	int 21h
    mov ah,9
    mov dx,offset error1
    int 21h 
    JMP end_exit
next1:
    CMP ax,03h
    JNE next2
	mov ah,9
	mov dx,offset new_line 
	int 21h
    mov ah,9
    mov dx,offset error2
    int 21h 
    JMP end_exit
next2:
    CMP ax,04h
    JNE next3
	mov ah,9
	mov dx,offset new_line 
	int 21h
    mov ah,9
    mov dx,offset error3
    int 21h
    JMP end_exit
next3:
    CMP ax,05h
    JNE next4
	mov ah,9
	mov dx,offset new_line 
	int 21h
    mov ah,9
    mov dx,offset error4
    int 21h
    JMP end_exit 
next4:
    CMP ax,0Ch
    JNE next5
	mov ah,9
	mov dx,offset new_line 
	int 21h
    mov ah,9
    mov dx,offset error5
    int 21h
    JMP end_exit 
next5:
    CMP ax,12h
    JNE end_exit
	mov ah,9
	mov dx,offset new_line 
	int 21h
    mov ah,9
    mov dx,offset error5
    int 21h
JMP end_exit
 
 

   
    path_name db 64 dup(0),'$'      ;file name  
    empty_cmd_message db "cmd is empty...Nothing to handle",'$'   
too_many_message db "Too many args were entered",'$'
    
    
    found_file db 80 dup (0), '$'   
  
    EPB          dw 0000                    ;current environment
                 dw offset cmd, 0           ;command line address 
                 dw 005Ch, 0 , 006Ch, 0     ;FCB program addresses
    cmd          db 125                     ;command line length
                 db " /?"                   ;cmd (3)
    cmd_text     db 122 DUP(?)              ;cmd(122)
   
    
     real_load_file db dup  10 (0),'$'
    new_line db 13,10,'$'  
    welcome db 'Welcome! Program start!$'
    goodbye db 'Program finish! Goodbye!$'
    successful_directory_change db 'Successful directory change!$'

    mask_file db 200 dup (0), '$'
   index_mask_file dw 0  

    file_mask db '*.com',0 
    count dw 0
    index_real dw 0
    count_file dw 0
    directory_name_size equ 64 ;the path must have dimension 64-bit
    home_directory_name db 'D:\',0, '$'  
   ; home_directory_name db directory_name_size dup('$'), '$' 
    argc dw 0
    no_more_file_message db 'NO MORE FILES THERE!$' 
    error1 db 'ERROR1:FILE NOT FOUND$' 
    error2 db 'ERROR2:PATH NOT FOUND$'  
    error3 db 'ERROR3:TOO MANY OPEN FILE$' 
    error4 db 'ERROR4:ACCESS IS DENIED$' 
    error5 db 'ERROR5:INVALID ACCESS MODE$'
    program_length equ $-start              ;program length          
end Start
