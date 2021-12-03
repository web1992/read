assume cs:p3

p3 segment

    mov ax,0ffffH
    mov ds,ax
    mov bx,6
    mov al,[bx]
    mov ah,0
    mov dx,0
    mov cx,3

    s:
       add dx,ax
       loop s

    mov ax,4c00H
    int 21H

p3 ends

end