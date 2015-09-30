SECTION	.data

prompt:	db	"Enter a postive integer: "
plen:	equ	$-prompt

answer: db 	"The greatest common divisor is "
anslen: equ 	$-answer

error:	db 	"Bad Number", 10
errlen:	equ	$-error

testP:	db	"number: "
testlen:	equ	$-testP

line:	db " ", 10
lleng:	equ	$-line
	
SECTION	.bss
digits: equ	20		;max of 20 digits

num1:	resw	8
num2:	resw	8
temp:	resb 	digits

SECTION .text
	
global _start

_start:
	;; note to self: [ebp+4] is the return address. don't screw with
	;; it. ebp+8 is first parameter, ebp+12 is second, etc

	;; readNumber takes in a string of numbers from the console
	;; string is in eax, push that onto stack and then readNumber
	;; feeds that string as as a parameter to getInt
	;; getInt converts the string to a decimal number
	;; and returns it in eax to readNumber
	;; readNumber finally returns decimal number in eax

	call 	readNumber		;read first string
	mov		[num1], eax		;store first number
	call 	readNumber		;read second number string
	mov 	[num2], eax 	;store second number
	mov		ebx, 	[num2]
	mov		ecx,	[num1]
	push	ebx
	push	ecx
	call 	gcd				;returns gcd in eax
	pop		ecx
	pop		ebx
	push	eax			
	call	result	
	call	makeDecimal
	call	printNewLine
	call	exit
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
readNumber:
	push 	ebp
	mov 	ebp, esp
	push	ebx
	push 	ecx
	push 	edx

	mov		eax, 4			; write
	mov		ebx, 1			; to standard output
	mov		ecx, prompt		; the prompt string
	mov		edx, plen		; of length plen
	int 	80H				; interrupt with the syscall

	mov		eax, 0
	mov		[temp], eax

	mov		eax, 3			; read
	mov		ebx, 0			; from standard input
	mov		ecx, temp		; into the input buffer
	mov		edx, digits + 1	; up to max length + 1 bytes
	int 	80H				; interrupt with the syscall

	
	push 	temp			;send  getInt
	call	getInt 			;getInt returns string >> dec in eax
	add 	esp, 4			;destroy the previous push of temp
	
	pop 	edx
	pop 	ecx
	pop 	ebx
	mov 	esp, ebp
	pop 	ebp
	ret
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
getInt:
	;; passed in the number string to ebp+8
	;; will now cycle through to the end
	;; find the newline then back up one
	;; character to find the last digit
	push 	ebp 			;preserving the stack
	mov 	ebp, esp
	push 	ebx
	push 	ecx
	push 	edx
	push	edi
	push	esi
	mov		ebx, [ebp+8]	;this was the passed parameter
	mov		eax, 0			;'result' in c code
							;ebx is 'digit'
	mov		ecx, 1			;ecx is digitValue

	;; the next line creates *digit, also used later

	mov		edx, 0			;clearing out edx/dh/dl
intLoop:
	mov		dl, [ebx]		;this block cycles through
	cmp		dl, 10			;the string, finding the newline
	je		newline			;and then backs up 1 character
	add 	ebx, 1
	cmp		dl, 10
	jne		intLoop		 	
newline:	
	sub		ebx, 1
	
checkLoop:	
	;changed from dl to ebx
	cmp		ebx, [ebp+8]		;while digit>=string
	jb		break
	mov		dl,	[ebx]
	cmp		dl, 32			;if a space is encountered we use
	je		break			; \s <number> \n
	cmp		dl, '0'			;check 0-9
	jb		badNumber
	cmp		dl, '9'
	ja		badNumber
;; do some math:  eax=result edi=*digit ecx=digitValue
;;result += (*digit - '0') * digitvalue;
;;eax += ( dl - '0' ) * ecx
	sub 	dl, '0'
	push	eax				;preserve 'result'
	mov		eax, edx		;loading dl-48 for mul
	mul		ecx				;edx|eax = (edi-48)*ecx
	mov		esi, eax		;save previous product
	pop		eax				;restore eax
	add		eax, esi		;eax+= (edi-48)*ecx
	push	eax				;preserve 'result' again
;;digitValue *= 10
;;ecx = ecx*10
	mov		eax, ecx		;load ecx into mul
	mov		ecx, 10
	mul		ecx				;eax = eax * 10
	mov		ecx, eax		;ecx = eax
							;preserves digitValue*=10
	pop		eax				;restore 'result'
;;digit--, NOT *digit-- 
	sub		ebx, 1			;digit--
	mov		dl, [ebx]		;update *digit
	jmp		checkLoop
break:					
;;encountered a space or the left-most digit 
;;so we're done here
	pop		esi
	pop		edi
	pop 	edx
	pop 	ecx
	pop 	ebx
	mov 	esp, ebp
	pop 	ebp
	ret						;back to readNumber
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
gcd:
	push 	ebp 			;preserving the stack
	mov 	ebp, esp
	push	edx
	push	ebx
	
	mov		ebx, [ebp+8]	;n
	mov		edx, [ebp+12]	;m

	cmp		ebx, edx		;compare n and m
	ja		nBigger
	jb		nLess
	
	mov		eax, ebx
done:
	pop		ebx
	pop		edx
	mov 	esp, ebp
	pop 	ebp
	ret

nBigger:
	sub		ebx, edx		;n-m
	;remember to push in reverse order
	push	edx				;push m
	push	ebx				;push (n-m)	
	call	gcd
	jmp		done

nLess:
	sub		edx, ebx		;m-n
	;remember to push in reverse order
	push	edx				;push (m-n)
	push	ebx				;push n
	call	gcd
	jmp		done

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
makeDecimal:
	push 	ebp 			;preserving the stack
	mov 	ebp, esp
	push 	ebx
	push 	ecx
	push 	edx
	push	esi
	mov		ebx, [ebp+8]	;points to the gcd
	mov		eax, ebx		;gcd
	mov		edx, 0			;clear out edx
	mov		ecx, 10
	div		ecx				;eax/10
	;;eax = eax / 10
	;;edx = eax % 10
	cmp		eax, 0
	jle		cont

	push	eax
	call	makeDecimal
	add		esp, 4

cont:

	add		dl, '0'			;convert dl to ascii
	mov		[esi], edx		;edx was a value, need a pointer
	mov		eax, 4
	mov		ebx, 1
	mov		ecx, esi
	mov		edx, 1			;print 1 byte/char
	int 	80H

retMD:
	pop		esi
	pop 	edx
	pop 	ecx
	pop 	ebx
	mov 	esp, ebp
	pop 	ebp
	ret 
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
result:	
	mov		eax, 4			; write
	mov		ebx, 1			; to standard output
	mov		ecx, answer		; the prompt string
	mov		edx, anslen		; of length plen
	int 	80H				; interrupt with the syscall
	ret
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
badNumber:	
	mov		eax, 4			; write
	mov		ebx, 1			; to standard output
	mov		ecx, error		; the prompt string
	mov		edx, errlen		; of length plen
	int 	80H				; interrupt with the syscall
exit:	
	mov		ebx, 0
	mov 	eax, 1
	int 	80H
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
printNewLine:
	mov		eax, 4
	mov		ebx, 1
	mov		ecx, line
	mov		edx, lleng 
	int 	80H
	ret
