;------------------------------------------------
; new version of table, with new algorithm 
;------------------------------------------------
.8086
locals @@

.model tiny 
.code 
org 100h

start:
	mov ax, 0b800h
	mov es, ax
	xor ax, ax

	
	mov si, 82h
	call DecToHex 				; Reading x
	push ax
	xor ax, ax

	call DecToHex 				; Reading y
	push ax
	xor ax, ax

	call DecToHex 				; Reading widht
	push ax
	xor ax, ax

	call DecToHex 				; Reading heigh
	push ax
	xor ax, ax

	call ASCIItoHex 			; Reading color
	mov cl, al

	push cx
	inc si
	call DecToHex 				; reading style
	pop cx
	mov ch, al

	pop ax
	mov bl, al

	pop ax
	mov bh, al
	
	pop ax
	mov al, al
	
	mov di, sp
	mov ah, [di]
	inc sp 
	inc sp
	xor dx, dx

	

	call DrawTable
	
	mov ax, 4c00h
	int 21h
;------------------------------------------------
; Draw table 
;------------------------------------------------
; Entry: 	ah = x, al = y, bh = widht, bl = height, cl = color, ch = style
; exit: 	none
; Expects: 	es = 0b800h
; Destroys: 	ax, bx, cx, dx, di, si
;------------------------------------------------
DrawTable 	proc
	
	push ax
	push bx
	xor ax, ax
	mov al, ch
	mov ah, 9
	mul ah
	xor ah, ah
	lea bx, Styles 
	add ax, bx
	mov curStyle, ax
	pop bx
	pop ax

	xor ch, ch
	push cx 				; save color 

	mov cl, ah
	mov ah, 80d
	mul ah
	add ax, cx
	mov di, ax
	shl di, 1  				; calculate (x,y) in di

	pop cx 
	push di 				; save position
 

	mov ah, cl
	mov cl, bh
	mov si, [curStyle]
	call DrawLine
	mov dl, bl
	pop di 					; recover old position
	add di, 160d
	
@@height:
	
	push di

	mov cl, bh
	mov si, [curStyle] 		        ; change string
	add si, 3d
	call DrawLine

	pop di 
	add di, 160d

	dec dl 					
	cmp dl, 0
	jne @@height


	mov cl, bh 				; last line
	mov si, [curStyle]
	add si, 6
	call DrawLine

	ret
	endp
;------------------------------------------------

;------------------------------------------------
; Draw line like in str
;------------------------------------------------
; Entry: 	si = pointer on str, ah = color, cx = number of symbols
; Exit: 	None
; Expects: 	es = 0b800
; Destroys: 	ah, cx, si, di
;------------------------------------------------
DrawLine 	proc

	lodsb
	stosw

	lodsb
	rep stosw

	lodsb
	stosw

	ret
	endp
;------------------------------------------------


;------------------------------------------------
; Translate dec number from memory to hex
;------------------------------------------------
; Entry: si = address
; Exit: ax = number
; Expects: None
; Destroys: bx
;------------------------------------------------
DecToHex 	proc
	xor ax, ax 
	
	mov cx, 5d
@@number:
	xor bh, bh

	mov bl, ds:[si]
	inc si
	cmp bl, 0dh
	je @@done
	cmp bl, 00h
	je @@done
	cmp bl, 20h
	je @@done

	sub bx, 30h 				; calculation a number
	push bx

	mov bl, 10d 
	mul bx

	pop bx

	add ax, bx
	loop @@number

@@done:

	ret 
	endp
;------------------------------------------------

;------------------------------------------------
; From ascii to hex
;------------------------------------------------
; Entry: si = address
; Exit: ax = number
; Destroys:
;------------------------------------------------
ASCIItoHex 	proc

	lodsb
	mov ah, al
	xor al, al
	sub ah, 30h
	shl ax, 4
	lodsb
	sub al, 30h
	xchg al, ah
	add al, ah

	ret
	endp
;------------------------------------------------

Styles 	db 0dah, 0c4h, 0bfh
	db 0b3h, 03h, 0b3h
	db 0c0h, 0c4h, 0d9h

	db 03h, 03h, 03h
	db 03h, 03h, 03h
	db 03h, 03h, 03h

curStyle dw 00h

end start

