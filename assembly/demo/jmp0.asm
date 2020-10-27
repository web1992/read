assume cs:jmp0

jmp0 segment

    s: mov ax,0
       jmp short s0
       add ax,1
    s0:inc ax

jmp0 ends

end s