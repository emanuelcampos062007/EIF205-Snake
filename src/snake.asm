;Eng. Davis
;Snake Project
;University Microproccessor course
;version 1.1
;
;Proyecto 2 - EIF205 Arquitectura de Computadoras
;Adaptacion al Snake clasico (emu8086 y DOSBox)

META_COMIDAS equ 20      ;comidas necesarias para ganar
RETARDO_CX   equ 0001h   ;retardo entre movimientos en microsegundos (CX:DX)
RETARDO_DX   equ 86A0h   ;0001:86A0h = 100000 us = 0.1 s

PRINT macro texto, largo, posicion
    push cx
    push si
    push di
    lea si,texto
    mov di,posicion
    mov cx,largo
    call print_str
    pop di
    pop si
    pop cx
endm

data segment
    ;mainmenu
    main1 db "Snake 8086"
    main2 db "Hay que comer 20 comidas 'o' para ganar"
    main3 db "Para mover a la serpiente se usa w,a,s,d"
    main4 db "w:arriba"
    main5 db "s:abajo"
    main6 db "d:derecha"
    main7 db "a:izquierda"
    main10 db "p:pausa"                                
    about1 db "Basado en Davis Snake by Eng. Davis,"
    about2 db "Proyecto 2 Arquitectura"
    main8 db "La cabeza de la serpiente es la 'D'"
    main9 db "Presione cualquier tecla para empezar..."
    besttxt db "Record:"                           
    ;bild
    hlths db "Vidas:",3,3,3
    foodtxt db "Comida:"                                 
    hudbest db "Record:"                                 
    pausetxt db "Pausa (p)"      
    letadd dw 09b4h,0848h,06b0h,01E8h,05B4h,0A20h,0C00h,02D0h,04E0h,0B50h,0 Dup(0)
    dletadd dw 09b4h,0848h,06b0h,01E8h,05B4h,0A20h,0C00h,02D0h,04E0h,0B50h,0 Dup(0)
    letnum db 1
    fin db 4
    foodidx db 0
    hlth db 6 
               
    sadd dw 07D2h,39 Dup(0)
    snake db 'D',39 Dup(0)
    snakel db 1 ;collected letters count
   
    food dw 0     
    hiscore dw 0  
    newrec db 0   
    sp_ini dw 0   
    ;end 
    gmwin db "Victoria"
    gmov db "Game Over"
    eatentxt db "Cantidad de comida:"                         
    newbest db "Nuevo record!"                       
    endtxt db "Presione r para reiniciar o esc para salir"
    
ends

stack segment
    dw   128  dup(0)
ends

code segment
start:
    mov ax, data
    mov ds, ax
    
    mov ax,0b800h
    mov es, ax 
    
    cld ;clear Direction Flag
    
    mov sp_ini,sp
    
    ;hide text cursor
    mov ah,1
    mov ch,2bh
    mov cl,0bh
    int 10h  
    
    call main_menu
    
    new_game:
    mov sp,sp_ini
    mov food,0
    mov newrec,0
    mov hlth,6
    mov hlths[6],3
    mov hlths[7],3
    mov hlths[8],3
    jmp restart ;reinicia la serpiente y la comida, luego salta a startag
    
    startag:
    mov sp,sp_ini
    
    call bild ;put letters and draw borders
    
    xor cl,cl 
    xor dl,dl ;clear old values to not get input automatically or you can use it as the initial direction like " mov dl,'A' "
    read: ;check for keyboard inputs
    call delay
    mov ah,1
    int 16H
    jz s1
    mov ah,0
    int 16H
    and al,0dfh 
    mov dl,al
    jmp s1
    
    s1: ;check if esc button is pressed
    cmp dl,1bh
    je ext
    
    cmp dl,'P'
    jne s2
    call pause_game
    mov dl,cl ;seguir en la misma direccion
    jmp read
    
    s2:
    call no_reverse
    
    left:
    cmp dl,'A'
    jne right
    call ml
    mov cl,dl
    jmp read
    
    right:
    cmp dl,'D'
    jne up
    call mr
    mov cl,dl
    jmp read
    
    up:
    cmp dl,'W'
    jne down
    call mu 
    mov cl,dl
    jmp read
    
    down:
    cmp dl,'S'
    jne read1
    call md
    mov cl,dl
    jmp read
    
    read1:
    mov dl,cl
    jmp read
    
    
    ext:
    xor cx,cx
    mov dh,24
    mov dl,79
    mov bh,7
    mov ax,700h
    int 10h
    mov ax,3
    int 10h
    mov ax, 4c00h ; exit to operating system.
    int 21h    
ends 

;main menu
main_menu proc
    call border
    
    PRINT main1,10,186h
    PRINT main2,39,33Eh
    PRINT main3,40,3DEh
    PRINT main4,8,5dch
    PRINT main5,7,67ch
    PRINT main6,9,71ch
    PRINT main7,11,7bch
    PRINT main10,7,85Ch
    PRINT about1,36,8DEh
    PRINT about2,23,97Eh
    PRINT main8,35,0ABEh
    PRINT main9,40,0b5Eh
    
    PRINT besttxt,7,0C9Eh
    mov ax,hiscore
    mov di,0CAEh
    call print_num
       
    mov ah,7
    int 21h
    
    call clearall
    
    
ret
endp    
;Game screen 
bild proc ;is for placing borders and set chracters on the screen
    ;start point
    call border 
    
    PRINT hlths,9,0
    PRINT main1,10,88h
    
    PRINT foodtxt,7,1Ch
    PRINT hudbest,7,38h
    call draw_score
    
    xor dx,dx
    mov di,sadd
    mov dl,snake 
    es: mov [di],dl  
    ;Place chracters in game screen
    es: mov [09b4h],'o'
    es: mov [0848h],0
    es: mov [06b0h],0
    es: mov [01E8h],0
    ret
endp  

;snake move:
;left:
ml proc ;snake move left function
    push dx 
    call shift_addrs
    sub sadd,2
    
    call eat
    
    call move_snake
    pop dx
ret    
endp
;right:
mr proc ;snake move right function
    push dx 
    call shift_addrs
    add sadd,2
    
    call eat
    
    call move_snake 
    
    pop dx
    
ret    
endp
;up:
mu proc ;snake move up function
    push dx 
    call shift_addrs
    sub sadd,160
    
    call eat
    
    call move_snake
    pop dx
ret    
endp
;down:
md proc ;snake move down function
    push dx 
    call shift_addrs
    add sadd,160
    
    call eat
    
    call move_snake
    pop dx
ret    
endp

shift_addrs proc
    push ax
    xor ch,ch
    xor bh,bh
    mov cl,snakel
    inc cl
    mov al,2
    mul cl
    mov bl,al
    
    xor dx,dx
    
    shiftsnake:
    mov dx,sadd[bx-2]
    mov sadd[bx],dx
    sub bx,2
    loop shiftsnake:
pop ax
ret
endp


eat proc
    push ax
    push bx
    push cx
    push si
    push di

    mov di,sadd

    xor cx,cx
    mov cl,snakel
    dec cx
    jz checkfood

    mov si,2

bodycheck:
    cmp di,sadd[si]
    jz wallk
    add si,2
    loop bodycheck

checkfood:
    xor cx,cx
    mov cl,letnum
    xor si,si

foodcheck:
    cmp di,letadd[si]
    jz addf
    add si,2
    loop foodcheck

    cmp di,320
    jbe wallk
    cmp di,3840
    jae wallk

    mov ax,di
    mov bl,160
    div bl
    cmp ah,0
    jz wallk

    mov ax,di
    add ax,2
    mov bl,160
    div bl
    cmp ah,0
    jz wallk

    jmp no

addf:
    xor bx,bx
    mov bl,snakel
    es: mov dl,[di]
    mov snake[bx],dl
    es: mov [di],0
    add snakel,1
    mov letadd[si],0
    call nextfood
    call food_up
    jmp no

wallk:
    pop di
    pop si
    pop cx
    pop bx
    pop ax

    xor bh,bh
    mov bl,hlth
    es: mov [bx+10],0
    mov si,bx
    shr si,1
    mov hlths[si+5],0
    sub hlth,2
    cmp hlth,0
    jnz rest
    call game_over

rest:
    call restart
    ret

no:
    pop di
    pop si
    pop cx
    pop bx
    pop ax
    ret
endp 


move_snake proc
    xor ch,ch
    xor si,si
    xor dl,dl
    mov cl,snakel
    xor bx,bx
l1mr:
    mov di,sadd[si]
    mov dl,snake[bx]
    es: mov [di],dl
    add si,2
    inc bx
    loop l1mr
    mov di,sadd[si]
    es: mov [di],0
    ret
endp


border proc ;build borders function
    mov ah,0
    mov al,3
    int 10h
    
    mov ah,1
    mov ch,2bh
    mov cl,0bh
    int 10h
    
    mov ah,6
    mov al,0 
    mov bh,0ffh 
    
    mov ch,1
    mov cl,0
    mov dh,1
    mov dl,79
    int 10h
  
    mov ch,3
    mov cl,0
    mov dh,24
    mov dl,0
    int 10h
   
    mov ch,24
    mov cl,0
    mov dh,24
    mov dl,79
    int 10h
    
    mov ch,1
    mov cl,79
    mov dh,24
    mov dl,79
    int 10h

ret
endp

restart proc
    xor ch,ch
    xor si,si
    mov cl,snakel
    inc cl

delt:
    mov di,sadd[si]
    es: mov [di],0
    add si,2
    loop delt

    mov fin,4
    mov sadd,07D2h
    mov cl,snakel
    inc cl
    xor si,si
    inc si
    xor di,di
    add di,2

emptsn:
    mov snake[si],0
    mov sadd[di],0
    add di,2
    inc si
    loop emptsn

    mov snakel,1
    mov foodidx,0

    xor ch,ch
    mov cl,letnum
    xor si,si

reslet:
    mov bx,dletadd[si]
    mov letadd[si],bx
    add si,2
    add bx,2
    loop reslet

    mov snake[0],'D'
    jmp startag
endp

win proc 
    call clearall
    call border
     
    PRINT gmwin,8,7c8h
    jmp end_screen
    endp
game_over proc
    call clearall
    call border
    
    PRINT gmov,9,7c8h
    jmp end_screen
endp

end_screen proc
    PRINT endtxt,42,846h
    
    PRINT eatentxt,19,998h
    mov ax,food
    mov di,9C0h
    call print_num
    
    PRINT besttxt,7,0A38h
    mov ax,hiscore
    mov di,0A60h
    call print_num
    
    cmp newrec,1
    jne qwer
    PRINT newbest,13,0AD8h
    
    qwer:         
    mov ah,7
    int 21h
    cmp al,1bh         
    jne qwer_r
    jmp ext
    qwer_r:
    and al,0dfh
    cmp al,'R'
    jne qwer
    jmp new_game
endp

clearall proc
    
    xor cx,cx
    mov dh,24
    mov dl,79
    mov bh,7
    mov ax,700h
    int 10h 
    
ret
endp 

nextfood proc
    push ax
    push bx
    push cx
    push dx
    push si
    push di

    mov dl,10

tryfood:
    xor bx,bx
    mov bl,foodidx
    shl bx,1
    mov di,dletadd[bx]

    inc foodidx
    cmp foodidx,10
    jb indexok
    mov foodidx,0

indexok:
    xor cx,cx
    mov cl,snakel
    xor si,si

checksnake:
    cmp di,sadd[si]
    jz occupied
    add si,2
    loop checksnake

    mov letadd,di
    mov letadd[2],0
    mov letadd[4],0
    mov letadd[6],0

    mov al,'o'
    es: mov [di],al
    jmp fooddone

occupied:
    dec dl
    jnz tryfood

fooddone:
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
endp

food_up proc
    push ax
    inc food
    mov ax,food
    cmp ax,hiscore
    jbe fu_draw
    mov hiscore,ax
    mov newrec,1
fu_draw:
    call draw_score
    cmp food,META_COMIDAS
    jb fu_end
    pop ax
    call win ;no regresa (win salta a end_screen)
fu_end:
    pop ax
    ret
endp

draw_score proc
    push ax
    push di
    mov ax,food
    mov di,2Ch
    call print_num
    mov ax,hiscore
    mov di,48h
    call print_num
    pop di
    pop ax
    ret
endp

print_num proc
    push ax
    push bx
    push cx
    push dx
    push di
    add di,4 ;empezar por el ultimo digito
    mov cx,3
    mov bx,10
pn_loop:
    xor dx,dx
    div bx ;AX = AX/10, DX = residuo
    add dl,'0'
    es: mov [di],dl
    sub di,2
    loop pn_loop
    pop di
    pop dx
    pop cx
    pop bx
    pop ax
    ret
endp

print_str proc
ps_loop:
    movsb
    inc di
    loop ps_loop
    ret
endp

pause_game proc
    push ax
    push cx
    push di
    PRINT pausetxt,9,58h
pg_key:
    mov ah,7
    int 21h
    cmp al,1bh
    jne pg_p
    jmp ext
pg_p:
    and al,0dfh
    cmp al,'P'
    jne pg_key
    mov di,58h ;borrar el texto
    mov cx,9
pg_clr:
    mov byte ptr es:[di],' '
    add di,2
    loop pg_clr
    pop di
    pop cx
    pop ax
    ret
endp

no_reverse proc
    cmp snakel,1
    jbe nr_end
    cmp dl,'A'
    jne nr_d
    cmp cl,'D'
    je nr_ignore
    jmp nr_end
nr_d:
    cmp dl,'D'
    jne nr_w
    cmp cl,'A'
    je nr_ignore
    jmp nr_end
nr_w:
    cmp dl,'W'
    jne nr_s
    cmp cl,'S'
    je nr_ignore
    jmp nr_end
nr_s:
    cmp dl,'S'
    jne nr_end
    cmp cl,'W'
    jne nr_end
nr_ignore:
    mov dl,cl
nr_end:
    ret
endp

delay proc
    push ax
    push cx
    push dx
    mov ah,86h
    mov cx,RETARDO_CX
    mov dx,RETARDO_DX
    int 15h
    pop dx
    pop cx
    pop ax
    ret
endp

    
end start ; set entry point and stop the assembler.
