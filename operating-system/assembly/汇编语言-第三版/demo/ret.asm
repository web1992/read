assume cs:ret1


    stack segment
        db 16 dup (0)
    stack ends

    ret1 segment
            mov ax,4c0h
            int 21h

    start:    mov ax,stack
              mov ss,ax
              mov sp,16
              mov ax,0
              push ax
              mov bx,0
              ret
   
    ret1 ends

    end start