locals ??
.model tiny 
.code
org 100h

;------------------------------------------------
x = 9
y = 4
width1 = 10
height = 6
;------------------------------------------------

start:
	jmp main
;------------------------------------------------
; Draws horizontal line from (x, y) to (x + length, y)
;------------------------------------------------
; Entry: 	ah = x, al = y, bh = length
; Exit: 	none
; Expects: 	Es = 0b800h
; Destroys: 	cx, di
;------------------------------------------------
DrawHzlLn 		proc

	xor cx, cx

	mov cl, ah
	mov ah, 80d
	mul ah
	add ax, cx
	mov di, ax 				; calculate (x,y) in di
	shl di, 1
	xor cx, cx
	mov cl, bh

??line:

	mov es:[di], 02c4h 			; puts right symbols in videosegment
	inc di
	inc di 
	loop ??line
		

	ret	
	endp
;------------------------------------------------

;------------------------------------------------
; Draw a vertical line from (x, y) to (x, y + height)
;------------------------------------------------
; Entry: 	ah = x, al = y, bl = height
; Exit: 	None
; Expects: 	es = 0b8000
; Destoys
;------------------------------------------------
DrawVrcLn 	proc 

	mov cl, ah
	mov ah, 80d
	mul ah
	add ax, cx
	mov di, ax 				; calculate (x,y) in di
	shl di, 1

	xor cx, cx
	mov cl, bl
	dec cl
		
??line: 	
	mov es:[di], 02b3h 			; puts symbols in videosegment
	add di, 160d
	loop ??line
	
	ret
	endp
;------------------------------------------------

;------------------------------------------------
; Set corners
; brief: Set corners of the table. x, y  -
; cordinates of left upper corner
;------------------------------------------------
; Entry: 	ah = x, al = y, bh = width, bl = height
; Exit: 	none
; Expects: 	ES = 0b800h
; Destroys:  	ax, cx, di
;------------------------------------------------
DrawCorners 		proc
		
			mov cl, ah
			mov ah, 80d
			mul ah
			add ax, cx
			mov di, ax
			shl di, 1
			push di 		; calculate (x,y) in di

			mov es:[di], 02dah 	; top left corner

			mov al, bh 
			shl al, 1
			xor ah, ah
			add di, ax 		; calculate shift in x
			dec di
			dec di
			mov es:[di], 02bfh 	; top right corner

			mov al, bl
			mov cx, 80d
			xor ah, ah
			dec al
			mul cx
			shl ax, 1	
			add di, ax 		; calulate shift in y
			mov es:[di], 02d9h 	; bottom right corner 

			pop di
			add di, ax
			mov es:[di], 02c0h 	; bottom left corner


			ret
			endp
;------------------------------------------------


;------------------------------------------------
; Draw a table. Top left corner in (x, y)
;------------------------------------------------
; Entry: 	ah = x, al = y, bh = widht, bl = height
; Exit: 	None
; Expects: 	es = 0b800
; Destroys: 	
;------------------------------------------------
DrawTbl 	proc

	push ax 				; arguments for function
	push bx
	call DrawCorners
	
	pop bx 					; arguments for function
	pop ax 
	push ax
	push bx

	inc ah
	dec bh
	dec bh

	call DrawHzlLn
	
	pop bx 					; correct arguments for function 
	pop ax 
	push ax
	push bx

	add al, bl
	dec al
	inc ah
	dec bh
	dec bh
	call DrawHzlLn

	pop bx 					; correct arguments for function
	pop ax 
	push ax
	push bx

	inc al 
	dec bl
	call DrawVrcLn

	pop bx 					; correct arguments for function
	pop ax 

	inc al
	dec bl
	add ah, bh
	dec ah
	call DrawVrcLn
		
	
	ret
	endp
;------------------------------------------------

main:
		mov bx, 0b800h 			;ES = videosegment
		mov es, bx 			;
		xor bx, bx 			;bx = 0
		mov ah, x
		mov al, y
		mov bh, width1
		mov bl, height

		call DrawTbl

		mov ax, 4c00h
		int 21h

		
end start

Styles 	db 0dah, 0c4h, 0bfh
	db 0b3h, 20h, 0b3h
	db 0c0h, 0c4h, 0d9h
;------------------------------------------------

