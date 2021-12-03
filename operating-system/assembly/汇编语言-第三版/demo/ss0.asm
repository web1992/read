assume cs:ss0

ss0 segment

        s:mov ax,bx
          mov si,offset s
          mov di,offset s0
          mov ax,cs:[si]
          mov cs:[di],ax
       s0:nop
          nop
        
ss0 ends

end s