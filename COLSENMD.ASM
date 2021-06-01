;********************************************************************
;
; Date          : 06 Nov 2003
;
; File          : colsenmd.asm
;
;********************************************************************

$MOD812                          			; use 8052 predefined symbols

LED		EQU	P2.0
BUTTON		EQU	P3.2				;interrupt button
PLAY		EQU	P2.4				;enable chipcorder
STATUS		EQU	P3.4				;use red LED on eval board as status indicator

REDH		DATA	10h				;high byte of red intensity value
REDL		DATA	11h				;low byte of red intensity value
GREENH		DATA	12h				;high byte of green intensity value
GREENL		DATA	13h				;low byte of green intensity value
BLUEH		DATA	14h				;high byte of blue intensity value
BLUEL		DATA	15h				;low byte of blue intensity value

DSEG
ORG 16h

XNH:		DS	1				;high byte of x(n)
XNM:		DS	1				;middle byte of x(n)
XNL:		DS	1				;low byte of x(n)
XNM2H:		DS	1				;high byte of x(n-2)
XNM2M:		DS	1				;middle byte of x(n-2)
XNM2L:		DS	1				;low byte of x(n-2)
XNM4H:		DS	1				;high byte of x(n-4)
XNM4M:		DS	1				;middle byte of x(n-4)
XNM4L:		DS	1				;low byte of x(n-4)
YNH:		DS	1				;high byte of y(n)
YNM:		DS	1				;middle byte of y(n)
YNL:		DS	1				;low byte of y(n)
YNM1H:		DS	1				;high byte of y(n-1)
YNM1M:		DS	1				;middle byte of y(n-1)
YNM1L:		DS	1				;low byte of y(n-1)
YNM2H:		DS	1				;high byte of y(n-2)
YNM2M:		DS	1				;middle byte of y(n-2)
YNM2L:		DS	1				;low byte of y(n-2)
YNM3H:		DS	1				;high byte of y(n-3)
YNM3M:		DS	1				;middle byte of y(n-3)
YNM3L:		DS	1				;low byte of y(n-3)
YNM4H:		DS	1				;high byte of y(n-4)
YNM4M:		DS	1				;middle byte of y(n-4)
YNM4L:		DS	1				;low byte of y(n-4)
YH:		DS	1				;YH, YM, YL used in SCALEY subroutine
YM:		DS	1
YL:		DS	1
MAXH:		DS	1				;high byte of max value found in filtered samples
MAXL:		DS	1				;low byte of max value found in filtered samples
MINH:		DS	1				;high byte of min value found in filtered samples
MINL:		DS	1				;low byte of min value found in filtered samples
COLOURH:	DS	1				;high byte of colour to be output
COLOURL:	DS	1				;low byte of colour to be output
QUANTRED7H:	DS	1				;various quantisation thresholds for red, green and blue
QUANTRED7L:	DS	1
QUANTRED6H:	DS	1
QUANTRED6L:	DS	1
QUANTRED5H:	DS	1
QUANTRED5L:	DS	1
QUANTRED4H:	DS	1
QUANTRED4L:	DS	1
QUANTRED3H:	DS	1
QUANTRED3L:	DS	1
QUANTRED2H:	DS	1
QUANTRED2L:	DS	1
QUANTRED1H:	DS	1
QUANTRED1L:	DS	1
QUANTGREEN7H:	DS	1
QUANTGREEN7L:	DS	1
QUANTGREEN6H:	DS	1
QUANTGREEN6L:	DS	1
QUANTGREEN5H:	DS	1
QUANTGREEN5L:	DS	1
QUANTGREEN4H:	DS	1
QUANTGREEN4L:	DS	1
QUANTGREEN3H:	DS	1
QUANTGREEN3L:	DS	1
QUANTGREEN2H:	DS	1
QUANTGREEN2L:	DS	1
QUANTGREEN1H:	DS	1
QUANTGREEN1L:	DS	1
QUANTBLUE7H:	DS	1
QUANTBLUE7L:	DS	1
QUANTBLUE6H:	DS	1
QUANTBLUE6L:	DS	1
QUANTBLUE5H:	DS	1
QUANTBLUE5L:	DS	1
QUANTBLUE4H:	DS	1
QUANTBLUE4L:	DS	1
QUANTBLUE3H:	DS	1
QUANTBLUE3L:	DS	1
QUANTBLUE2H:	DS	1
QUANTBLUE2L:	DS	1
QUANTBLUE1H:	DS	1
QUANTBLUE1L:	DS	1
BN:		DS	1				;BN and N used as index in filter subroutine
N:		DS	1
NUMH:		DS	1				;NUMH and NUML used as operator in scaley subroutine
NUML:		DS	1
CAL:		DS	1				;used as enable bit for 'calibration' mode

CSEG
ORG 0000h

		CLR	STATUS				;clear port 3.4
		MOV	DPTR, #0h			;set address pointer to zero

STORE		MACRO	ADDRESS1, ADDRESS2
		MOV	A, ADDRESS1
		MOVX	@DPTR, A
		INC	DPTR
		MOV	A, ADDRESS2
		MOVX	@DPTR, A
		INC	DPTR
	ENDM

MULT		MACRO	OPP1, OPP2H, OPP2L
		CLR	CY
		MOV	A, OPP2L			;get low byte of 2nd operand
		MOV	B, OPP1				;get first operand
		MUL	AB
		MOV	R1, B				;store high byte of result in r1
		MOV	R2, A				;store low byte of result in r2
		MOV	A, OPP2H			;get high byte of second operand
		MOV	B, OPP1				;get first operand again
		MUL	AB
		ADD	A, R1				;add low bytes of results of both multiplications
		MOV	R1, A				;store low byte of total result in r1
		MOV	A, B				;get high byte of second result
		ADDC	A, #0
		MOV	R0, A				;store high byte of total result in r0
	ENDM

LMULT		MACRO	OPP1H, OPP1L, OPP2H, OPP2L
		CLR	CY
		MOV	A, OPP2L			;get low byte of 2nd operand
		MOV	B, OPP1L			;get first operand
		MUL	AB
		MOV	R1, B				;store high byte of result in r1
		MOV	R2, A				;store low byte of result in r2
		MOV	A, OPP2H			;get high byte of second operand
		MOV	B, OPP1L			;get first operand again
		MUL	AB
		ADD	A, R1				;add low bytes of results of both multiplications
		MOV	R1, A				;store low byte of total result in r1
		MOV	A, B				;get high byte of second result
		ADDC	A, #0
		MOV	R0, A				;store high byte of total result in r0
		MOV	A, OPP2L			;get low byte of second operand again
		MOV	B, OPP1H			;get high byte of first operand
		MUL	AB
		ADD	A, R1				;add low byte of result to middle byte of result of previous multiplications
		MOV	R1, A				;store new middle byte of result
		MOV	A, R0				;get high byte of result of previous multiplications
		ADDC	A, B				;add result of last multiplication
		MOV	R0, A				;store new high byte of result
		MOV	A, OPP2H			;get high byte of second operand again
		MOV	B, OPP1H			;get high byte of first operand again
		MUL	AB
		ADD	A, R0				;add result of high byte of previous multiplications
		MOV	R0, A				;store new high byte of result
	ENDM

DECDPTR		MACRO	DECREMENT
		CLR	CY				;clear carry bit
		MOV	A, DPL				;get low byte of data pointer
		SUBB	A, DECREMENT
		MOV	DPL, A				;store result
		MOV	A, DPH				;decrement middle byte of data pointer if carry set
		SUBB	A, #0
		MOV	DPH, A
	ENDM

		STORE	#1, #36				;define colour space
		STORE 	#99, #12
		STORE 	#99, #12
		STORE	#66, #12
		STORE	#69, #12
		STORE	#66, #9
		STORE	#66, #102
		STORE	#66, #12
		STORE	#1, #12
		STORE	#1, #12
		STORE	#1, #9
		STORE	#66, #9
		STORE	#1, #102
		STORE	#1, #12
		STORE	#78, #9
		STORE	#1, #9
		STORE	#93, #9
		STORE	#102, #9
		STORE	#39, #102
		STORE	#39, #12
		STORE	#78, #9
		STORE	#39, #9
		STORE	#78, #9
		STORE	#72, #9
		STORE	#39, #102
		STORE	#66, #0
		STORE	#66, #15
		STORE	#99, #12
		STORE	#66, #15
		STORE	#69, #12
		STORE	#66, #21
		STORE	#66, #27
		STORE	#1, #12
		STORE	#45, #12
		STORE	#1, #12
		STORE	#63, #9
		STORE	#1, #9
		STORE	#1, #102
		STORE	#39, #12
		STORE	#39, #12
		STORE	#75, #9
		STORE	#1, #9
		STORE	#39, #9
		STORE	#39, #9
		STORE	#39, #12
		STORE	#6, #9
		STORE	#39, #9
		STORE	#72, #9
		STORE	#72, #9
		STORE	#39, #102
		STORE	#66, #0
		STORE	#54, #0
		STORE	#66, #15
		STORE	#66, #108
		STORE	#1, #12
		STORE	#1, #0
		STORE	#66, #18
		STORE	#1, #15
		STORE	#45, #12
		STORE	#78, #12
		STORE	#42, #0
		STORE	#39, #21
		STORE	#1, #27
		STORE	#39, #12
		STORE	#72, #12
		STORE	#1, #3
		STORE	#9, #6
		STORE	#72, #9
		STORE	#39, #102
		STORE	#39, #12
		STORE	#63, #6
		STORE	#72, #93
		STORE	#72, #9
		STORE	#72, #9
		STORE	#72, #102
		STORE	#1, #0
		STORE	#66, #18
		STORE	#69, #18
		STORE	#1, #15
		STORE	#1, #108
		STORE	#1, #3
		STORE	#66, #18
		STORE	#54, #18
		STORE	#39, #15
		STORE	#39, #108
		STORE	#81, #3
		STORE	#1, #3
		STORE	#1, #18
		STORE	#39, #15
		STORE	#72, #108
		STORE	#78, #3
		STORE	#1, #6
		STORE	#1, #111
		STORE	#39, #27
		STORE	#72, #12
		STORE	#6, #9
		STORE	#6, #9
		STORE	#1, #93
		STORE	#72, #9
		STORE	#72, #9
		STORE	#78, #0
		STORE	#78, #0
		STORE	#69, #15
		STORE	#1, #15
		STORE	#78, #15
		STORE	#42, #0
		STORE	#78, #0
		STORE	#66, #18
		STORE	#60, #15
		STORE	#60, #108
		STORE	#78, #3
		STORE	#78, #3
		STORE	#42, #18
		STORE	#1, #18
		STORE	#1, #15
		STORE	#42, #6
		STORE	#1, #6
		STORE	#60, #111
		STORE	#72, #18
		STORE	#72, #15
		STORE	#78, #6
		STORE	#78, #6
		STORE	#66, #24
		STORE	#1, #24
		STORE	#1, #30

		MOV	CAL, #1				;enable 'calibration' mode
MAIN:		CPL	STATUS				;flash red LED on eval board
		MOV	R5, #1
		CALL	DELAY				;delay 50ms
		JB	BUTTON, MAIN			;jump to MAIN if button not pressed
		MOV	R5, #1
		CALL	DELAY				;delay 50ms
		JB	BUTTON, MAIN			;jump to MAIN if button not still pressed - ensures aginast false trigger
		JMP	START1

START:		JB	BUTTON, $			;wait for button press
		MOV	R5, #1
		CALL	DELAY				;delay 50ms
		JB	BUTTON, START			;jump to MAIN if button not still pressed - ensures aginast false trigger

START1:		CLR	STATUS				;turn off red LED on eval board
		MOV	ADCCON1, #60h			;power-up ADC, 5.9us acquisition time + conv time
		MOV	ADCCON2, #0h			;set ADC channel = 0
		MOV	P2, #0				;clear port 2

		CALL	FLASH
		MOV	A, MAXL
		ADD	A, MINL
		MOV	REDL, A				;store low byte of red intensity (= sum of max and min values)
		MOV	A, MAXH
		ADDC	A, MINH
		MOV	REDH, A				;store high byte

		MOV	ADCCON2, #1			;set ADC channel = 1
		CALL	FLASH
		MOV	A, MAXL
		ADD	A, MINL
		MOV	GREENL, A			;store low byte of GREEN intensity (= sum of max and min values)
		MOV	A, MAXH
		ADDC	A, MINH
		MOV	GREENH, A			;store high byte

		MOV	ADCCON2, #2			;set ADC channel = 2
		CALL	FLASH
		MOV	A, MAXL
		ADD	A, MINL
		MOV	BLUEL, A			;store low byte of BLUE intensity (= sum of max and min values)
		MOV	A, MAXH
		ADDC	A, MINH
		MOV	BLUEH, A			;store high byte

		MOV	A, CAL
		CJNE	A, #0, CALIBRATE		;perform calibration if CAL bit set
		JMP	QUANT

CALIBRATE:	MOV	R0, #0
		MOV	R1, REDH
		MOV	R2, REDL
		CALL	LDIV				;divide red intensity reading by 128
		MULT	#104, R3, R4			;first quantisation level = reading from white surface * 104/128
		MOV	QUANTRED1H, R1
		MOV	QUANTRED1L, R2
		MULT	#77, R3, R4			;second quantisation level = reading from white surface * 77/128
		MOV	QUANTRED2H, R1
		MOV	QUANTRED2L, R2
		MULT	#43, R3, R4			;third quantisation level = reading from white surface * 43/128
		MOV	QUANTRED3H, R1
		MOV	QUANTRED3L, R2
		MULT	#28, R3, R4			;fourth quantisation level = reading from white surface * 28/128
		MOV	QUANTRED4H, R1
		MOV	QUANTRED4L, R2

		MOV	R0, #0
		MOV	R1, GREENH
		MOV	R2, GREENL
		CALL	LDIV				;divide green intensity reading by 128
		MULT	#106, R3, R4			;first quantisation level = reading from white surface * 106/128
		MOV	QUANTGREEN1H, R1
		MOV	QUANTGREEN1L, R2
		MULT	#81, R3, R4			;second quantisation level = reading from white surface * 81/128
		MOV	QUANTGREEN2H, R1
		MOV	QUANTGREEN2L, R2
		MULT	#51, R3, R4			;third quantisation level = reading from white surface * 51/128
		MOV	QUANTGREEN3H, R1
		MOV	QUANTGREEN3L, R2
		MULT	#37, R3, R4			;fourth quantisation level = reading from white surface * 37/128
		MOV	QUANTGREEN4H, R1
		MOV	QUANTGREEN4L, R2

		MOV	R0, #0
		MOV	R1, BLUEH
		MOV	R2, BLUEL
		CALL	LDIV
		MULT	#110, R3, R4			;first quantisation level = reading from white surface * 110/128
		MOV	QUANTBLUE1H, R1
		MOV	QUANTBLUE1L, R2
		MULT	#89, R3, R4			;second quantisation level = reading from white surface * 89/128
		MOV	QUANTBLUE2H, R1
		MOV	QUANTBLUE2L, R2
		MULT	#65, R3, R4			;third quantisation level = reading from white surface * 65/128
		MOV	QUANTBLUE3H, R1
		MOV	QUANTBLUE3L, R2
		MULT	#54, R3, R4			;fourth quantisation level = reading from white surface * 54/128
		MOV	QUANTBLUE4H, R1
		MOV	QUANTBLUE4L, R2

		MOV	CAL, #0				;clear CAL bit
		SETB	STATUS				;turn on red LED on eval board
		JMP	START

QUANT:		CALL	QUANTISER			;quantise readings for red, green and blue
		CALL	QUANTISEG
		CALL	QUANTISEB

		CALL	COLSPC				;determine colour to be output
		MOV	A, COLOUR			;decrement colour number and multiply by two...
		DEC	A				;...corresponds to memory location of words describing colour
		MOV	B, #2
		MUL	AB
		MOV	DPL, A
		MOV	DPH, #0
		CALL	TALK

		SETB	STATUS
		JMP	START
;____________________________________________________________________
                                                        ; SUBROUTINES

DELAY:                          			; delay = 50ms * R5

		NOP
DLY1:		MOV	R7,#100         		; 100 * 500us = 50ms
DLY2:   	MOV	R6,#229         		; 229 * 2.17us = 500us
        	DJNZ	R6,$            		; sit here for 500us
        	DJNZ	R7,DLY2         		; repeat 100 times (50ms delay)
		DJNZ	R5, DLY1
        	RET
;____________________________________________________________________

FLASH:
		MOV	DPTR, #0h			;set pointer to position after colour space
		MOV	DPH, #1h
		MOV	R6, #75
FLSH:		CPL	LED
		CALL	SAMPLE
		CALL	SAMPLE
		CALL	SAMPLE
		CALL	SAMPLE
		DJNZ	R6, FLSH			;check if 300 samples taken

		CLR	LED
		CALL	FILTER		
		CALL	GETVAL
		RET
;____________________________________________________________________

SAMPLE:							;perform single ADC conversion
                         	
		SETB	SCONV				;perform single conversion
		NOP					;wait 5.9us approx
		NOP
		NOP
		NOP
		NOP
		MOV	A, ADCDATAH			;store ADC high byte
		MOVX	@DPTR, A
		INC	DPTR
		MOV	A, ADCDATAL			;store ADC low byte
		MOVX	@DPTR, A
		INC	DPTR
		RET

;____________________________________________________________________

FILTER:							;y(n) = [26*x(n) - 52*x(n-2) + 26*x(n-4) + 272*y(n-1) - 210*y(n-2) + 89*y(n-3) - 25*y(n-4)] / 128

		MOV	N, #0				;set sample index to zero
		MOV	BN, #0
		MOV	DPTR, #0
		MOV	DPH, #1				;set data pointer to beginning of stored samples

AGAIN:		MOV	A, N
		JNZ	N1				;jump to N1 if N is non-zero
		MOVX	A, @DPTR			;get high byte of first sample
		ANL	A, #0Fh				;get rid of channel ID
		MOV	XNM, A				;store as middle byte of x(n)
		INC	DPTR
		MOVX	A, @DPTR			;get low byte of first sample
		MOV	XNL, A				;store as low byte of x(n)
		MULT	#26, XNM, XNL
		CALL	LDIV
		MOV	YNM, R3				;y(n) = x(n) * 26 / 128
		MOV	YNL, R4
		INC	DPH
		INC	DPH
		INC	DPH
		DECDPTR	#2				;position data pointer at memory space for filtered samples
		JMP	SAVE

N1:		MOV	A, N
		CJNE	A, #1, N2			;jump to N2 if N is greater than 1
		MOVX	A, @DPTR			;get high byte of 2nd sample
		ANL	A, #0Fh				;get rid of channel ID
		MOV	XNM, A				;store as middle byte of x(n)
		INC	DPTR
		MOVX	A, @DPTR			;get low byte of second sample
		MOV	XNL, A				;store as low byte of x(n)
		INC	DPH
		INC	DPH
		INC	DPH
		DECDPTR	#3				;position data pointer at memory space for filtered samples
		MOVX	A, @DPTR			;get high byte of first filtered sample
		MOV	YNM1M, A			;store as middle byte of y(n-1)
		INC	DPTR
		MOVX	A, @DPTR			;get low byte of first filtered sample
		MOV	YNM1L, A			;store as low byte of y(n-1)

		MULT	#26, XNM, XNL
		MOV	XNH, R0
		MOV	XNM, R1
		MOV	XNL, R2				;x(n) = x(n) * 26

		MOV	YM, YNM1M
		MOV	YL, YNM1L
		MOV	NUMH, #1
		MOV	NUML, #10h
		CALL	SCALEY
		MOV	YNL, YL
		MOV	YNM, YM
		MOV	YNH, YH				;y(n) = y(n-1) * 272

		JMP	ADDXY

N2:		MOV	A, N
		CJNE	A, #2, N21
		JMP	N22
N21:		JMP	N3				;jump to N3 if N is greater than 2
N22:		MOVX	A, @DPTR			;get high byte of third sample
		ANL	A, #0Fh				;get rid of channel ID
		MOV	XNM, A				;store as middle byte of x(n)
		INC	DPTR
		MOVX	A, @DPTR			;get low byte of third sample
		MOV	XNL, A				;store as low byte of x(n)
		DECDPTR	#5
		MOVX	A, @DPTR			;get high byte of first sample
		ANL	A, #0Fh				;get rid of channel ID
		MOV	XNM2M, A			;store as middle byte of x(n-2)
		INC	DPTR
		MOVX	A, @DPTR			;get low byte of first sample
		MOV	XNM2L, A			;store as low byte of x(n-2)

		INC	DPH
		INC	DPH
		INC	DPH
		DECDPTR	#1				;position data pointer at memory space for filtered samples
		MOVX	A, @DPTR			;get high byte of first filtered sample
		MOV	YNM2M, A			;store as middle byte of y(n-2)
		INC	DPTR
		MOVX	A, @DPTR			;get low byte of first filtered sample
		MOV	YNM2L, A			;store as low byte of y(n-2)
		INC	DPTR
		MOVX	A, @DPTR			;get high byte of second filtered sample
		MOV	YNM1M, A			;store as middle byte of y(n-1)
		INC	DPTR
		MOVX	A, @DPTR			;get low byte of second filtered sample
		MOV	YNM1L, A			;store as low byte of y(n-1)

		MULT	#26, XNM, XNL
		MOV	XNH, R0
		MOV	XNM, R1
		MOV	XNL, R2				;x(n) = x(n) * 26

		MULT	#52, XNM2M, XNM2L
		MOV	XNM2H, R0
		MOV	XNM2M, R1
		MOV	XNM2L, R2			;x(n-2) = x(n-2) * 52

		MOV	YM, YNM2M
		MOV	YL, YNM2L
		MOV	NUMH, #0
		MOV	NUML, #210
		CALL	SCALEY
		MOV	YNM2H, YH
		MOV	YNM2M, YM
		MOV	YNM2L, YL			;y(n-2) = y(n-2) * 210
		MOV	YM, YNM1M
		MOV	YL, YNM1L
		MOV	NUMH, #1
		MOV	NUML, #10h
		CALL	SCALEY
		MOV	YNM1L, YL
		MOV	YNM1M, YM
		MOV	YNM1H, YH			;y(n-1) = y(n-1) * 272

		MOV	A, XNL
		SUBB	A, XNM2L
		MOV	XNL, A
		MOV	A, XNM
		SUBB	A, XNM2M
		MOV	XNM, A
		MOV	A, XNH
		SUBB	A, XNM2H
		MOV	XNH, A				;x(n) = x(n) - x(n-2)

		CLR	CY
		MOV	A, YNM1L
		SUBB	A, YNM2L
		MOV	YNL, A
		MOV	A, YNM1M
		SUBB	A, YNM2M
		MOV	YNM, A
		MOV	A, YNM1H
		SUBB	A, YNM2H
		MOV	YNH, A				;y(n) = y(n-1) - y(n-2)

		JMP	ADDXY		

N3:		MOV	A, N
		CJNE	A, #3, N31
		JMP	N32
N31:		JMP	NOVER3				;jump to NOVER3 if N is greater than 3
N32:		MOVX	A, @DPTR			;get high byte of 3rd sample
		ANL	A, #0Fh				;get rid of channel ID
		MOV	XNM, A				;store as middle byte of x(n)
		INC	DPTR
		MOVX	A, @DPTR			;get low byte of 3rd sample
		MOV	XNL, A				;store as low byte of x(n)
		DECDPTR	#5
		MOVX	A, @DPTR			;get high byte of 1st sample
		ANL	A, #0Fh				;get rid of channel ID
		MOV	XNM2M, A			;store as middle byte of x(n-2)
		INC	DPTR
		MOVX	A, @DPTR			;get low byte of 1st sample
		MOV	XNM2L, A			;store as low byte of x(n-2)

		INC	DPH
		INC	DPH
		INC	DPH
		DECDPTR	#3				;position data pointer at memory space for filtered samples
		MOVX	A, @DPTR			;get high byte of 1st filtered sample
		MOV	YNM3M, A			;store as middle byte of y(n-3)
		INC	DPTR
		MOVX	A, @DPTR			;get low byte of 1st filtered sample
		MOV	YNM3L, A			;store as low byte of y(n-3)
		INC	DPTR
		MOVX	A, @DPTR			;get high byte of 2nd filtered sample
		MOV	YNM2M, A			;store as middle byte of y(n-2)
		INC	DPTR
		MOVX	A, @DPTR			;get low byte of 2nd filtered sample
		MOV	YNM2L, A			;store as low byte of y(n-2)
		INC	DPTR
		MOVX	A, @DPTR			;get high byte of 3rd filtered sample
		MOV	YNM1M, A			;store as middle byte of y(n-1)
		INC	DPTR
		MOVX	A, @DPTR			;get low byte of 3rd filtered sample
		MOV	YNM1L, A			;store as low byte of y(n-1)

		MULT	#26, XNM, XNL
		MOV	XNH, R0
		MOV	XNM, R1
		MOV	XNL, R2				;x(n) = x(n) * 26

		MULT	#52, XNM2M, XNM2L
		MOV	XNM2H, R0
		MOV	XNM2M, R1
		MOV	XNM2L, R2			;x(n-2) = x(n-2) * 52

		MOV	YM, YNM3M
		MOV	YL, YNM3L
		MOV	NUMH, #0
		MOV	NUML, #89
		CALL	SCALEY
		MOV	YNM3H, YH
		MOV	YNM3M, YM
		MOV	YNM3L, YL			;y(n-3) = y(n-3) * 89
		MOV	YM, YNM2M
		MOV	YL, YNM2L
		MOV	NUMH, #0
		MOV	NUML, #210
		CALL	SCALEY
		MOV	YNM2H, YH
		MOV	YNM2M, YM
		MOV	YNM2L, YL			;y(n-2) = y(n-2) * 210
		MOV	YM, YNM1M
		MOV	YL, YNM1L
		MOV	NUMH, #1
		MOV	NUML, #10h
		CALL	SCALEY
		MOV	YNM1L, YL
		MOV	YNM1M, YM
		MOV	YNM1H, YH			;y(n-1) = y(n-1) * 272

		MOV	A, XNL
		SUBB	A, XNM2L
		MOV	XNL, A
		MOV	A, XNM
		SUBB	A, XNM2M
		MOV	XNM, A
		MOV	A, XNH
		SUBB	A, XNM2H
		MOV	XNH, A				;x(n) = x(n) - x(n-2)

		CLR	CY
		MOV	A, YNM1L
		SUBB	A, YNM2L
		MOV	YNL, A
		MOV	A, YNM1M
		SUBB	A, YNM2M
		MOV	YNM, A
		MOV	A, YNM1H
		SUBB	A, YNM2H
		MOV	YNH, A
		MOV	A, YNL
		ADD	A, YNM3L
		MOV	YNL, A
		MOV	A, YNM
		ADDC	A, YNM3M
		MOV	YNM, A
		MOV	A, YNH
		ADDC	A, YNM3H
		MOV	YNH, A				;y(n) = y(n-1) - y(n-2) + y(n-3)

		JMP	ADDXY				

NOVER3:		CLR	CY				;clear carry bit
		CLR	F0				;clear negative flag
		MOVX	A, @DPTR	 		;get high byte of nth sample
		ANL	A, #0Fh				;get rid of channel ID
		MOV	XNM, A				;store as middle byte of x(n)
		INC	DPTR
		MOVX	A, @DPTR	 		;get low byte of nth sample
		MOV	XNL, A				;store as low byte of x(n)
		DECDPTR	#5
		MOVX	A, @DPTR			;get high byte of (n-2)th sample
		ANL	A, #0Fh				;get rid of channel ID
		MOV	XNM2M, A			;store as middle byte of x(n-2)
		INC	DPTR
		MOVX	A, @DPTR			;get low byte of (n-2)th sample
		MOV	XNM2L, A			;store as low byte of x(n-2)
		DECDPTR	#5
		MOVX	A, @DPTR			;get high byte of (n-4)th sample
		ANL	A, #0Fh				;get rid of channel ID
		MOV	XNM4M, A			;store as middle byte of x(n-4)
		INC	DPTR
		MOVX	A, @DPTR			;get low byte of (n-4)th sample
		MOV	XNM4L, A			;store as low byte of x(n-4)

		MULT	#26, XNM, XNL
		MOV	XNH, R0
		MOV	XNM, R1
		MOV	XNL, R2				;x(n) = x(n) * 26
		MULT	#52, XNM2M, XNM2L
		MOV	XNM2H, R0
		MOV	XNM2M, R1
		MOV	XNM2L, R2			;x(n-2) = x(n-2) * 52
		MULT	#26, XNM4M, XNM4L
		MOV	XNM4H, R0
		MOV	XNM4M, R1
		MOV	XNM4L, R2			;x(n-4) = x(n-4) * 26

		MOV	A, XNL
		CLR	CY
		SUBB	A, XNM2L
		MOV	XNL, A
		MOV	A, XNM
		SUBB	A, XNM2M
		MOV	XNM, A
		MOV	A, XNH
		SUBB	A, XNM2H
		MOV	XNH, A
		MOV	A, XNL
		ADD	A, XNM4L
		MOV	XNL, A
		MOV	A, XNM
		ADDC	A, XNM4M
		MOV	XNM, A
		MOV	A, XNH
		ADDC	A, XNM4H
		MOV	XNH, A				;x(n) = x(n) - x(n-2) + x(n-4)

		INC	DPH
		INC	DPH
		INC	DPH
		DECDPTR	#1				;position data pointer at memory space for filtered samples
		MOVX	A, @DPTR			;get high byte of (n-4)th filtered sample
		MOV	YNM4M, A			;store as middle byte of y(n-4)
		INC	DPTR
		MOVX	A, @DPTR			;get low byte of (n-4)th filtered sample
		MOV	YNM4L, A			;store as low byte of y(n-4)
		INC	DPTR
		MOVX	A, @DPTR			;get high byte of (n-3)th filtered sample
		MOV	YNM3M, A			;store as middle byte of y(n-3)
		INC	DPTR
		MOVX	A, @DPTR			;get low byte of (n-3)th filtered sample
		MOV	YNM3L, A			;store as low byte of y(n-3)
		INC	DPTR
		MOVX	A, @DPTR			;get high byte of (n-2)th filtered sample
		MOV	YNM2M, A			;store as middle byte of y(n-2)
		INC	DPTR
		MOVX	A, @DPTR			;get low byte of (n-2)th filtered sample
		MOV	YNM2L, A			;store as low byte of y(n-2)
		INC	DPTR
		MOVX	A, @DPTR			;get high byte of (n-1)th filtered sample
		MOV	YNM1M, A			;store as middle byte of y(n-1)
		INC	DPTR
		MOVX	A, @DPTR			;get low byte of (n-1)th filtered sample
		MOV	YNM1L, A			;store as low byte of y(n-1)

		MOV	YM, YNM4M
		MOV	YL, YNM4L
		MOV	NUMH, #0
		MOV	NUML, #25
		CALL	SCALEY
		MOV	YNM4H, YH
		MOV	YNM4M, YM
		MOV	YNM4L ,YL			;y(n-4) = y(n-4) * 25
		MOV	YM, YNM3M
		MOV	YL, YNM3L
		MOV	NUMH, #0
		MOV	NUML, #89
		CALL	SCALEY
		MOV	YNM3H, YH
		MOV	YNM3M, YM
		MOV	YNM3L, YL			;y(n-3) = y(n-3) * 89
		MOV	YM, YNM2M
		MOV	YL, YNM2L
		MOV	NUMH, #0
		MOV	NUML, #210
		CALL	SCALEY
		MOV	YNM2H, YH
		MOV	YNM2M, YM
		MOV	YNM2L, YL			;y(n-2) = y(n-2) * 210
		MOV	YM, YNM1M
		MOV	YL, YNM1L
		MOV	NUMH, #1
		MOV	NUML, #10h
		CALL	SCALEY
		MOV	YNM1L, YL
		MOV	YNM1M, YM
		MOV	YNM1H, YH			;y(n-1) = y(n-1) * 272

		CLR	CY				;clear carry bit
		MOV	A, YNM1L
		SUBB	A, YNM2L
		MOV	YNL, A
		MOV	A, YNM1M
		SUBB	A, YNM2M
		MOV	YNM, A
		MOV	A, YNM1H
		SUBB	A, YNM2H
		MOV	YNH, A
		MOV	A, YNL
		ADD	A, YNM3L
		MOV	YNL, A
		MOV	A, YNM
		ADDC	A, YNM3M
		MOV	YNM, A
		MOV	A, YNH
		ADDC	A, YNM3H
		MOV	YNH, A
		MOV	A, YNL
		SUBB	A, YNM4L
		MOV	YNL, A
		MOV	A, YNM
		SUBB	A, YNM4M
		MOV	YNM, A
		MOV	A, YNH
		SUBB	A, YNM4H
		MOV	YNH, A				;y(n) = y(n-1) - y(n-2) + y(n-3) - y(n-4)


ADDXY:		CLR	CY				;clear carry bit
		MOV	A, YNL				;get low byte of y(n)
		ADD	A, XNL				;add low byte of x(n)
		MOV	R2, A				;store result in R2
		MOV	A, YNM				;get middle byte of y(n)
		ADDC	A, XNM				;add middle byte of x(n) plus carry
		MOV	R1, A				;store result in R1
		MOV	A, YNH				;get high byte of y(n)
		ADDC	A, XNH				;add high byte of x(n) plus carry
		MOV	R0, A				;store result in R0

		MOV	A, R0				;get high byte of x(n) + y(n)
		ANL	A, #0F0h			;check if negative
		JNZ	YNEG1
		JMP	YPOS1
YNEG1:		SETB	F0				;set neg flag if x(n) + y(n) is negative
		CLR	CY				;clear carry bit
		MOV	A, R2
		XRL	A, #0FFh			;complement bits of low byte of x(n) + y(n)
		ADD	A, #1				;increment low byte of x(n) + y(n)
		MOV	R2, A
		MOV	A, R1
		XRL	A, #0FFh			;complement bits of middle byte of x(n) + y(n)
		ADDC	A, #0				;increment if carry set
		MOV	R1, A
		MOV	A, R0
		XRL	A, #0FFh			;complement bits of high byte of x(n) + y(n)
		ADDC	A, #0				;increment if carry set
		MOV	R0, A
YPOS1:		CALL	LDIV
		MOV	YNM, R3
		MOV	YNL, R4				;y(n) = [x(n) + y(n)] / 128
		JNB	F0, SAVE			;jump to SAVE if negative flag not set
		MOV	A, YNL
		XRL	A, #0FFh			;complement bits of low byte of y(n)
		CLR	CY				;clear carry bit
		ADD	A, #1				;increment low byte of y(n)
		MOV	YNL, A
		MOV	A, YNM
		XRL	A, #0FFh			;complement bits of middle byte of y(n)
		ADDC	A, #0				;increment if carry set
		MOV	YNM, A

SAVE:		INC	DPTR
		MOV	A, YNM				;get middle byte of y(n)
		MOVX	@DPTR, A			;store as high byte of nth filtered sample, since high byte of y(n) is now zero
		INC	DPTR
		MOV	A, YNL				;get low byte of y(n)
		MOVX	@DPTR, A			;store as low byte of nth filtered sample
		INC	DPTR
		INC	N				;increment sample index
		DEC	DPH
		DEC	DPH
		DEC	DPH				;return to memory space occupied by unfiltered samples
		MOV	A, N
		JNZ	SAVE1
		MOV	N, #4				;if N has incremented to 00, set it to 4, so as to return to NOVER3 in next loop
SAVE1:		MOV	A, DPL
		CJNE	A, #58h, REPEAT			;check how many samples done (358h is the address of the last sample)
		MOV	A, DPH
		CJNE	A, #3, REPEAT
		RET					;exit subroutine if all samples filtered

REPEAT:		JMP	AGAIN				;repeat process until all samples are filtered

;_____________________________________________________________________________

SCALEY:							;checks if y(n-a) is negative and multiplies it by NUM

		MOV	A, YM				;get high byte of y(n-a)
		ANL	A, #0F0h			;check if y(n-a) is negative
		JNZ	YNEG
		JMP	YPOS
YNEG:		SETB	F0				;set neg flag if y(n-a) is negative
		CLR	CY				;clear carry bit
		MOV	A, YL				;get low byte of y(n-a)
		XRL	A, #0FFh			;complement bits of low byte of y(n-a)
		ADD	A, #1				;increment low byte of y(n-a)
		MOV	YL, A
		MOV	A, YM				;get middle byt of y(n-a)
		XRL	A, #0FFh			;complement bits of middle byte of y(n-a)
		ADDC	A, #0				;increment if carry set
		MOV	YM, A
YPOS:		LMULT	NUMH, NUML, YM, YL
		MOV	YH, R0
		MOV	YM, R1
		MOV	YL, R2				;y(n-a) = y(n-a) * NUM
		JNB	F0, FINISH			;jump to FINISH if negative flag not set
		MOV	A, YL				;get low byte of y(n-a)
		XRL	A, #0FFh			;complement bits of low byte of y(n-a)
		CLR	CY				;clear carry bit
		ADD	A, #1				;increment low byte of y(n-a)
		MOV	YL, A
		MOV	A, YM				;get middle byte of y(n-a)
		XRL	A, #0FFh			;complement bits of high byte of y(n-a)
		ADDC	A, #0				;increment if carry set
		MOV	YM, A
		MOV	A, YH				;get high byte of y(n-a)
		XRL	A, #0FFh			;complement bits of high byte of y(n-a)
		ADDC	A, #0				;increment if carry set
		MOV	YH, A
		CLR	F0				;clear negative flag

FINISH:		RET
;____________________________________________________________________

LDIV:							;divide R0R1R2 by 128

		MOV	A, R2				;get least significant byte of operand
		ANL	A, #80h				;take most significant bit
		RR	A				;right shift 7 times
		RR	A
		RR	A
		RR	A
		RR	A
		RR	A
		RR	A
		MOV	R4, A				;store as least significant bit of solution
		MOV	A, R1				;take 2nd byte of operand
		ANL	A, #7Fh				;get rid of most significant bit
		RL	A				;left shift
		ADD	A, R4				;store as 7 most significant bits of low byte of solution
		MOV	R4, A
		MOV	A, R1				;take 2nd byte of operand again
		ANL	A, #80h				;take most significant bit of 2nd byte
		RR	A				;right shift 7 times
		RR	A
		RR	A
		RR	A
		RR	A
		RR	A
		RR	A
		MOV	R3, A				;store as least significant bit of high byte of solution
		MOV	A, R0				;take most significant byte of solution
		ANL	A, #7Fh				;get rid of most significant bit
		RL	A				;left shift
		ADD	A, R3				;store as 7 most significant bits of high byte of solution
		MOV	R3, A
		MOV	A, R2				;get least significant byte of operand
		ANL	A, #7Fh				;determine if remainder is less than or greater than 64
		CLR	CY				;clear carry bit
		SUBB	A, #64
		JC	DIV1				;if carry is set, remainder is less than 128 / 2
		CLR	CY				;clear carry bit
		MOV	A, R4				;get low byte of solution
		ADD	A, #1				;if remainder is greater than 128 / 2, solution is incremented (rounded up)
		MOV	R4, A
		MOV	A, R3				;get high byte of solution
		ADDC	A, #0				;increment if carry set
		MOV	R3, A
DIV1:		RET
;____________________________________________________________________

GETVAL:							;determine max and min of filtered samples

		MOV	MAXH, #0
		MOV	MAXL, #0
		MOV	MINH, #0
		MOV	MINL, #0
		MOV	DPTR, #450h			;skip first 40 samples - transient

SETMAX:		MOVX	A, @DPTR			;get high byte of nth sample
		ANL	A, #0F0h			;check if sample is negative...
		JNZ	SETMIN				;...if so, skip to setmin (it is assumed the minimum will be negative)
		CLR	CY				;clear carry bit
		INC	DPTR
		MOVX	A, @DPTR			;get high byte of nth sample
		MOV	R0, A
		DECDPTR	#1
		MOV	A, R0
		SUBB	A, MAXL				;determine if max is greater than current sample
		MOVX	A, @DPTR
		SUBB	A, MAXH
		JNC	NEWMAX				;if carry is set, current max is greater, move to setmin
		INC	DPTR
		INC	DPTR
		MOV	A, DPL
		CJNE	A, #58h, SETMAX			;if all samples checked...
		MOV	A, DPH
		CJNE	A, #6, SETMAX
		RET					;exit subroutine
NEWMAX:		MOVX	A, @DPTR			;otherwise, save new max value
		MOV	MAXH, A
		INC	DPTR
		MOVX	A, @DPTR
		MOV	MAXL, A
		INC	DPTR
		MOV	A, DPL
		CJNE	A, #58h, SETMAX			;check how many samples done
		MOV	A, DPH
		CJNE	A, #6, SETMAX
		RET					;exit subroutine if all samples filtered
		
SETMIN:		CLR	CY				;clear carry bit
		INC	DPTR
		MOVX	A, @DPTR			;get low byte of nth sample
		XRL	A, #0FFh			;complement low byte
		ADD	A, #1				;increment low byte
		MOVX	@DPTR, A			;store result
		DECDPTR	#1
		MOVX	A, @DPTR			;get high byte of nth sample
		XRL	A, #0FFh			;complement high byte
		ADDC	A, #0				;increment high byte if carry set as a result of incrementing low byte
		MOVX	@DPTR, A			;store result - overall effect is to make sample value positive
		INC	DPTR
		MOVX	A, @DPTR			;get low byte of nth sample again
		MOV	R0, A
		DECDPTR	#1
		MOV	A, R0
		SUBB	A, MINL				;subtract low byte of current min
		MOVX	A, @DPTR			;get high byte of nth sample
		SUBB	A, MINH				;determine if min is less than current min
		JNC	NEWMIN				;if carry not set, current min is greater, start over
		INC	DPTR
		INC	DPTR
		MOV	A, DPL
		CJNE	A, #58h, RETURN			;check how many samples done
		MOV	A, DPH
		CJNE	A, #6, RETURN
		RET					;exit subroutine if all samples checked
NEWMIN:		MOVX	A, @DPTR			;otherwise, save new min
		MOV	MINH, A				;store high byte of nth sample as high byte of min
		INC	DPTR
		MOVX	A, @DPTR			;get low byte of nth sample
		MOV	MINL, A				;store as low byte of min
		INC	DPTR
		MOV	A, DPL
		CJNE	A, #58h, RETURN			;check how many samples done
		MOV	A, DPH
		CJNE	A, #6, RETURN

		RET					;exit subroutine if all samples checked

RETURN:		JMP	SETMAX				;start over

;____________________________________________________________________

QUANTISER:						;quantise red intensity level

		CLR	CY
		MOV	A, REDL
		SUBB	A, QUANTRED7L			;if intensity is less than 12.5%, it is taken as zero
		MOV	A, REDH
		SUBB	A, QUANTRED7H
		JNC	RQ1
		MOV	REDH, #0
		RET
RQ1:		MOV	A, REDL
		SUBB	A, QUANTRED5L			;if intensity is between 12.5-37.5%, it is taken as 25%
		MOV	A, REDH
		SUBB	A, QUANTRED5H
		JNC	RQ2
		MOV	REDH, #1
		RET
RQ2:		MOV	A, REDL
		SUBB	A, QUANTRED3L			;if intensity is between 37.5-62.5%, it is taken as 50%
		MOV	A, REDH
		SUBB	A, QUANTRED3H
		JNC	RQ3
		MOV	REDH, #2
		RET
RQ3:		MOV	A, REDL
		SUBB	A, QUANTRED1L			;if intensity is between 32.5-87.5%, it is taken as 75%...
		MOV	A, REDH
		SUBB	A, QUANTRED1H
		JNC	RQ4				;...otherwise, taken as maximum
		MOV	REDH, #3
		RET
RQ4:		MOV	REDH, #4
		RET
;____________________________________________________________________

QUANTISEG:						;quantise green intensity level

		CLR	CY
		MOV	A, GREENL
		SUBB	A, QUANTGREEN7L			;if intensity is less than 12.5%, it is taken as zero
		MOV	A, GREENH
		SUBB	A, QUANTGREEN7H
		JNC	GQ1
		MOV	GREENH, #1
		RET
GQ1:		MOV	A, GREENL
		SUBB	A, QUANTGREEN5L			;if intensity is between 12.5-37.5%, it is taken as 25%
		MOV	A, GREENH
		SUBB	A, QUANTGREEN5H
		JNC	GQ2
		MOV	GREENH, #2
		RET
GQ2:		MOV	A, GREENL
		SUBB	A, QUANTGREEN3L			;if intensity is between 37.5-62.5%, it is taken as 50%
		MOV	A, GREENH
		SUBB	A, QUANTGREEN3H
		JNC	GQ3
		MOV	GREENH, #3
		RET
GQ3:		MOV	A, GREENL
		SUBB	A, QUANTGREEN1L			;if intensity is between 32.5-87.5%, it is taken as 75%...
		MOV	A, GREENH
		SUBB	A, QUANTGREEN1H
		JNC	GQ4				;...otherwise, taken as maximum
		MOV	GREENH, #4
		RET
GQ4:		MOV	GREENH, #5
		RET
;____________________________________________________________________

QUANTISEB:						;quantise blue intensity level

		CLR	CY
		MOV	A, BLUEL
		SUBB	A, QUANTBLUE7L			;if intensity is less than 12.5%, it is taken as zero
		MOV	A, BLUEH
		SUBB	A, QUANTBLUE7H
		JNC	BQ1
		MOV	BLUEH, #1
		RET
BQ1:		MOV	A, BLUEL
		SUBB	A, QUANTBLUE5L			;if intensity is between 12.5-37.5%, it is taken as 25%
		MOV	A, BLUEH
		SUBB	A, QUANTBLUE5H
		JNC	BQ2
		MOV	BLUEH, #2
		RET
BQ2:		MOV	A, BLUEL
		SUBB	A, QUANTBLUE3L			;if intensity is between 37.5-62.5%, it is taken as 50%
		MOV	A, BLUEH
		SUBB	A, QUANTBLUE3H
		JNC	BQ3
		MOV	BLUEH, #3
		RET
BQ3:		MOV	A, BLUEL
		SUBB	A, QUANTBLUE1L			;if intensity is between 32.5-87.5%, it is taken as 75%...
		MOV	A, BLUEH
		SUBB	A, QUANTBLUE1H
		JNC	BQ4				;...otherwise, taken as maximum
		MOV	BLUEH, #4
		RET
BQ4:		MOV	BLUEH, #5
		RET
;____________________________________________________________________

COLSPC:							;determine colour to be output

		MOV	R0, #4
		MOV	COLOURL, #126			;start at the top of the colour space and descend
CMPR:		MOV	R1, #5
CMPR1:		MOV	R2, #5
CMPR2:		DEC	COLOURL
		MOV	A, R2
		CJNE	A, 14h, DECCOL			;if R2 is not equal to quantised blue move to next colour in space
		MOV	A, R1
		CJNE	A, 12h, DECCOL			;if R2 is equal to quantised blue, but R1 is not equal to quantised green move to next colour in space
		MOV	A, R0
		CJNE	A, 10h, DECCOL			;if R2 is equal to quantised blue, and R1 is equal to quantised green, but R0 is not equal to quantised red, move to next colour in space
		RET					;exit subroutine when correct colour in colour space found
DECCOL:		DJNZ	R2, CMPR2
		DJNZ	R1, CMPR1
		DEC	R0
		JMP	CMPR
;____________________________________________________________________
TALK:							;provide control signals to talking circuit

		MOVX	A, @DPTR			;get address of first word to be output
		CJNE	A, #1, TALK1			;if 1 is stored at this location, only one word is neccessary to describe colour - jump to TALK2
		JMP	TALK2
TALK1:		MOV	R0, A
		ANL	A, #1Fh				;get rid of 3 most significant bits of address
		MOV	R1, A				;store in R1
		MOV	A, R0				;get address again
		ANL	A, #0E0h			;get rid of 5 least significant bits
		RL	A				;left shift remaining bits
		ADD	A, R1				;add this to 5 least significant bits - overall purpose is to avoid using p0.4 
		MOV	P0, A				;put this address on port 0
		SETB	PLAY				;enable the play pin
		MOV	R5, #1
		CALL	DELAY				;delay for 50ms
		CLR	PLAY				;clear the play pin
		MOV	R5, #18
		CALL	DELAY				;delay for a further 950ms to allow speach to finish
TALK2:		INC	DPTR				;increment to next word to be output
		MOVX	A, @DPTR
		MOV	R0, A
		ANL	A, #1Fh				;get rid of 3 most significant bits of address
		MOV	R1, A				;store in R1
		MOV	A, R0				;get address again
		ANL	A, #0E0h			;get rid of 5 least significant bits
		RL	A				;left shift remaining bits
		ADD	A, R1				;add this to 5 least significant bits - overall purpose is to avoid using p0.4 
		MOV	P0, A				;put this address on port 0
		SETB	PLAY				;enable the play pin
		MOV	R5, #1
		CALL	DELAY				;delay for 50ms
		CLR	PLAY				;clear the play pin
		RET					;exit subroutine
;____________________________________________________________________
END