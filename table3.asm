locals @@
.model tiny 
.code
org 100h

start:
	mov ax, 0b800h
	mov es, ax
	xor ax, ax
	mov si, 82h

	call DecToHex 				; reading style
	push ax
	xor bx, bx
	xor cx, cx
	cmp ax, 0h
	jne @@NotUserStyle
	mov di, offset Styles
	mov cx, 9d

@@Reading:
	mov al, [si]
	inc si
	mov byte ptr [di], al
	inc di 
	loop @@Reading
	inc si

@@NotUserStyle:

	push si
	call ReadText
	pop si
	push ax
	push bx
	
	call CalculateCoord

; args ah = x, al = y, bh = widht, bl = height, cl = color, ch = style
	mov ah, bl

	pop bx 			
	mov bh, bl

	pop cx
	mov bl, cl
	pop cx

	mov ch, cl
	mov cl, 02h
	push ax
	dec ah
	dec al

	push si
	call DrawTable
	pop si
	pop ax

	mov bl, ah 	
	xor bh, bh
	xor ah, ah
	mov cl, 02h
	call WriteText

	mov ax, 4c00h
	int 21h

;------------------------------------------------
; Calculate coordinates in way table will be in center
;------------------------------------------------
; Entry: ax = widht, bx = height
; Exit : ax = x, bx = y
;------------------------------------------------
CalculateCoord 		proc

	push di
	push cx


	shr ax, 1
	shr bx, 1
	inc ax
	inc bx

	mov di, 13d
	mov cx, 40d

	sub di, ax
	sub cx, bx

	mov ax, di
	mov bx, cx
	dec bx 					; for more beatiful result


	pop cx
	pop di

	ret 
	endp 
;------------------------------------------------

;------------------------------------------------
; Find max
;------------------------------------------------
; Entry: ax, bx
; Exit: ax = max
; Destroys: bx
;------------------------------------------------
Max: 

	cmp ax, bx
	jbe @@axBelow
	jmp @@axAbove

@@axBelow:
	mov ax, bx
	jmp @@done


@@axAbove:
	jmp @@done

@@done:
	ret 
	endp

;------------------------------------------------
; Read text, just utility function, that reads text and counts number of line and max symbols in line
;------------------------------------------------
; Entry: 	si = start of str
; Exit: 	ax = number of lines, bx = symbols in line
; 
;------------------------------------------------
ReadText 	proc 
	xor ax, ax
	xor bx, bx
	push si
	push cx
	xor cx, cx

@@Loop:
	cmp byte ptr ds:[si], 0dh 			; enter symbol
	je @@done

	cmp byte ptr ds:[si], 23h
	jne @@notCountLine 			; counts line and calculate max len

	inc ax

	push ax 				; save ax

	mov ax, cx
	call Max
	mov bx, ax

	pop ax 					

	xor cx, cx
	jmp @@countinue

	@@notCountLine:
	inc cx
	cmp byte ptr ds:[si], 25h 		; if % in line, I decrease cx on 3 because color is not text
	jne @@countinue 
	dec cx 
	dec cx
	dec cx

	@@countinue:
	inc si
	jmp @@Loop


@@done:
	inc ax

	push ax  				; save ax

	mov ax, cx
	call Max
	mov bx, ax

	pop ax


	pop cx 					; save cx and si
	pop si

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
; Writes a text 
;------------------------------------------------
; Entry: 	si = pointer on start of the string, ax = y, bx = x (coord of the table), cl = color
; Exit: 	none
; Expects: 	es = 0b800h
; Destroys: 	dx
;------------------------------------------------
WriteText 	proc
	
	push cx
	xor dx, dx 
	mov cx, 00A0h
	mul cx
	pop cx
	shl bx, 1
	add ax, bx
	mov di, ax
	mov ah, cl
	push di

@@Loop:
	lodsb
	cmp al, 0dh
	je @@done
	cmp al, '%'
	jne @@notChngColor

	call ASCIItoHex
	mov ah, al
	lodsb

	@@notChngColor:
	cmp al, '#'

	jne @@notnextLine

	pop di 
	add di, 160d
	push di
	lodsb
	
	@@notnextLine:
	stosw
	jmp @@Loop

@@done:
	pop di
	ret 
	endp
;------------------------------------------------

;------------------------------------------------
; Draw table 
;------------------------------------------------
; Entry: 	ah = x, al = y, bh = widht, bl = height, cl = color, ch = style
; exit: 	none
; Expects: 	es = 0b800h
; Destroys: 	ax, bx, cx, dx, di, si
;------------------------------------------------
DrawTable 	proc
	
	push ax 				; counting style
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
; From ascii to hex
;------------------------------------------------
; Entry: si = address
; Exit: ax = number, si = skipped the number
; Destroys: bx 
;------------------------------------------------
ASCIItoHex 	proc

	mov cx, 2
	xor ax, ax

@@Main:
	mov bl, ds:[si]
	inc si
	cmp  bl, 97d
	jae @@letter
	sub bl, 30h
	jmp @@countinue

@@letter:
	sub bl, 87d 				; small letters 

@@countinue:
	cmp cx, 1
	je @@lastNumber 			; last number dont need to mul on 16

	shl bx, 4

@@lastNumber:
	add ax, bx
	loop @@Main

	ret
	endp
;------------------------------------------------

Styles 	db 0dah, 0c4h, 0bfh
	db 0b3h, 0h,   0b3h
	db 0c0h, 0c4h, 0d9h

	db 03h, 03h, 03h
	db 03h, 00h, 03h
	db 03h, 03h, 03h

	db 0c9h, 0cdh, 0bbh
	db 0bah, 00h, 0bah
	db 0c8h, 0cdh, 0bch

curStyle dw 00h

end start
