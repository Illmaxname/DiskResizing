.386
data segment use16
CurrentSect	db 512 dup (0)
Vol	db 80h
ExtPart1	db 4 dup (0) ;528254
ExtPart2	db 4 dup (0) ;637056
SectSize	db 4 dup (0)
AsciiOut	dw 4 dup (0), '$'
InMess	db 0Dh, 0Ah, 'Current size: $'
ExtErr	db 0Dh, 0Ah, 'Extended partition not found! $'
SectErr	db 0Dh, 0Ah, 'The 2nd log disk not found! $'
MinValEr	db 0Dh, 0Ah, 'New size is too small! Try again!', 0Dh, 0Ah, '$'
InpErr	db 0Dh, 0Ah, 'Incorrect input! New size is bigger! Try again! $'
NewLine	db 0Dh, 0Ah, '$'
SuccessM	db 0Dh, 0Ah, 'Changes applied!$'
InSize	db 9, 10 dup (0)
NewSize	dd 0
ExtNum	dd 0
ExtNum2	dd 0
Size	db 4 dup (0)
paket	db 16
	db 0
	db 1
	db 0
	dw CurrentSect
	dw data
pakSect	dq 0
SzDiff	dd ?
AbsLBA	dd ?
SecMax	db 63
HeadMax	db 64
Cyl dw ?
Head db ?
Sec db ?

data ends

code segment use16
assume cs:code, ds:data
commands: mov dx, data
	mov ds, dx
;reading MBR
	lea si, ds:paket
	call readSect
;finding ext part
	call checkExt
	jnc short cd1
	lea dx, ExtErr
	call print
	jmp final
cd1:
;reading 1st EPR
	mov edx, dword ptr ExtPart1
	mov dword ptr pakSect, edx
	lea si, ds:paket
	call readSect
;checking EPR2
	call checkExt2
	jnc short cd2
	lea dx, SectErr
	call print
	jmp final
cd2:
;reading 2nd EPR
	mov edx, dword ptr ExtPart2
	mov dword ptr pakSect, edx
	lea si, ds:paket
	call readSect
;working with EPR2
	lea si, ds:CurrentSect+446
	mov edx, dword ptr ds:[si+12]
	mov dword ptr ds:SectSize, edx
	lea si, ds:SectSize
	lea di, AsciiOut+6
	mov cx, 4
cd3:
	mov bl, ds:si

	call SecSz
	mov ds:di, bx
	dec di
	dec di
	inc si
	loop short cd3

	lea dx, AsciiOut
	call print
	lea dx, NewLine
	call print
	jmp short cd5
;input processing
ValEr:
	lea dx, MinValEr
	call print
	jmp short cd5
cd4:
	lea dx, InpErr
	call print
	lea dx, NewLine
	call print
cd5:
	call inproc
	call AtoH

	mov edx, dword ptr ds:SectSize
	mov ecx, dword ptr ds:NewSize

	mov SzDiff, edx
	sub SzDiff, ecx

	cmp ecx, edx
	ja short cd4
	cmp ecx, 63
	jb short ValEr
;changing Current Sector
	lea si, ds:CurrentSect+446
	mov edx, dword ptr ds:NewSize
	mov dword ptr ds:[si+12], edx

	call toCHS
	mov al, ds:Head
	mov byte ptr ds:[si+5], al
	mov al, ds:Sec
	mov bx, ds:Cyl
	shr bx, 2
	and bl, 11000000b
	or al, bl
	mov bx, ds:cyl
	mov ah, bl
	add ax, 2
	mov word ptr ds:[si+6], ax

	lea si, ds:paket
	call writeSect
	lea dx, SuccessM
	call print

final:
	mov AH, 4Ch
	int 21h

;procs
print proc
	mov ah, 9
	int 21h
	ret
print endp

readSect proc
	mov ah, 42h
	mov dl, Vol
	int 13h
	ret
readSect endp

checkExt proc
	lea si, ds:CurrentSect+446
	mov cx, 4
m1:
	cmp byte ptr [si+4], 5
	je short m2
	cmp byte ptr [si+4], 0fh
	je short m2
	add si, 16
	loop short m1
	stc
	jmp short m3
m2:
	mov edx, dword ptr ds:[si+8]
	mov dword ptr ds:ExtPart1, edx
	clc
m3:
	ret
checkExt endp

checkExt2 proc
	lea si, ds:CurrentSect+446
	mov edx, dword ptr ds:[si+24]
	cmp edx, 0
	jne short c1
	stc
	jmp short c2
c1:
	add edx, dword ptr ds:ExtPart1
	mov dword ptr ExtPart2, edx
	clc
c2:
	ret
checkExt2 endp

SecSz proc
	xor bh, bh
	shl bx, 4
	shr bl, 4
	cmp bh, 9h
	ja short s1
	add bh, 30h
	jmp short s2
s1:
	add bh, 37h	
s2:
	cmp bl, 9h
	add bl, 30h
	jmp short s4
s3:
	add bl, 37h
s4:
	rol bx, 8
	ret
SecSz endp

inproc proc ;DS:InSize - user input buffer 
	mov ah, 0Ah
	lea dx, ds:InSize
	int 21h
	ret
inproc endp

AtoH proc ;input: DS:InSize - new log disk size in ascii, DS:NewSize - buffer for new size in hex
	lea si, ds:InSize+2
	lea di, ds:NewSize+3
	mov cx, 4
a1:
	mov dl, ds:[si+1]
	cmp dl, 39h
	ja short a2
	sub dl, 30h
	jmp short a3
a2:
	sub dl, 37h
a3:
	mov al, ds:si
	cmp al, 39h
	ja short a4
	sub al, 30h
	jmp short a5
a4:
	sub al, 37h
a5:
	shl al, 4
	or dl, al
	mov ds:di, dl
	inc si
	inc si
	dec di
	loop short a1
	ret
AtoH endp

writeSect proc
	mov ah, 43h
	mov dl, Vol
	int 13h
	ret
writeSect endp

proc toCHS ;ds:SzDiff-size difference, ds:SecMax, ds:HeadMax, si-2nd EPR sector ptr, DS:Cyl,Head,Sec, DS:AbsLBA-absolute value CHS end
	mov dl, byte ptr ds:[si+5]
	mov ds:Head, dl
	mov dx, word ptr ds:[si+6]
	mov ax, dx
	shl ax, 2
	and ax, 0000001100000000b
	mov bx, dx
	shr bx, 8
	and bx, 00FFh
	or bx, ax
	mov Cyl, bx
	and dl, 00111111b
	mov Sec, dl

	;=============getting CHS before changing to new size
	mov ax, Cyl
	movzx dx, byte ptr HeadMax
	mul dx
	shl edx, 16
	and eax, 0000FFFFh
	or eax, edx
	movzx dx, byte ptr ds:Head
	movzx ebx, dx
	add eax, ebx
	movzx dx, byte ptr SecMax
	movzx ebx, dx
	mul ebx
	movzx dx, byte ptr Sec
	sub dx, 1
	movzx ebx, dx
	add eax, ebx ;eax - LBA final LD coordinate before change
	
	sub eax, dword ptr SzDiff
	mov dword ptr ds:AbsLBA, eax

	mov edx, dword ptr ds:ExtPart2
	add edx, ds:NewSize
	add edx, dword ptr ds:[si+8]
	dec edx
	mov dword ptr ds:AbsLBA, edx

	;=============now eax (LBA after changing) to CHS	

	mov dh, HeadMax
	mov al, SecMax
	mul dh
	mov cx, ax ; ==========cx = total heads*total secs
	mov eax, dword ptr ds:AbsLBA
	mov edx, eax
	shr edx, 16
	div cx
	mov word ptr ds:Cyl, ax ;======cyl value

	mul cx
	mov ebx, dword ptr ds:AbsLBA
	shl edx, 16
	and eax, 0FFFFh
	or eax, edx
	sub ebx, eax
	mov ax, bx
	mov bl, byte ptr ds:SecMax
	div bl ; ===============al = heads
	mov byte ptr ds:Head, al
	
	xor eax, eax
	movzx ax, byte ptr ds:HeadMax
	mul word ptr ds:Cyl
	movzx dx, byte ptr ds:Head
	add ax, dx
	movzx dx, byte ptr ds:SecMax 
	mul dx
	shl edx, 16
	and edx, 0FFFF0000h
	or eax, edx
	add eax, 1
	mov ebx, dword ptr ds:AbsLBA
	sub ebx, eax
	mov byte ptr ds:Sec, bl
	

	ret
endp toCHS

code ends
	end commands
