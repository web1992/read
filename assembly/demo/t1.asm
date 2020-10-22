assume cs:t1

t1 segment

    mov ax,2000H
    mov ss,ax
    mov sp,0
    add sp,10
    pop ax
    pop bx
    push ax
    push bx
    pop ax
    pop bx
    
    mov ax,4c00H
    int 21H

t1 ends

end