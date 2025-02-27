.INCLUDE "keypad4x4.inc"
.INCLUDE "LCD_seiko_L172.inc"
.INCLUDE "8535def.inc"
.INCLUDE "ASCIIdef.inc"

.DEF ZEROR = r0		; r0 is always zero

;; Does not survive subroutine
.DEF TMP0 = r16
.DEF TMP1 = r17
.DEF TMP2 = r18
.DEF TMP3 = r19     
.DEF TMP4 = r12     
.DEF TMP5 = r13   
.DEF TMP6 = r14    
.DEF TMP7 = r15  

.DEF ARG0 = r21		
.DEF ARG1 = r22
.DEF ARG2 = r23
.DEF ARG3 = r24

.DEF RET0 = r25		
.DEF RET1 = r1
.DEF RET2 = r2
.DEF RET3 = r3
.DEF RET4 = r4
.DEF RET5 = r5
.DEF RET6 = r6
.DEF RET7 = r7

;; Survives subroutine
.DEF LOC0 = r8
.DEF LOC1 = r9
.DEF LOC2 = r10
.DEF LOC3 = r11

.DEF TIMER0_COUNTER = r20

;; Number of overflows for one second
.EQU COUNTER_ROUNDS = 15

;; LCD pins
.EQU LCD_DATA = PORTC
.EQU LCD_ENABLE = PIND7
.EQU LCD_RW = PIND5
.EQU LCD_RS = PIND6

;; Bell pin
.EQU BELL_PIN = PIND4

;;
;; Swap register values
;;
.MACRO SWAPR
		push	@0
		mov		@0, @1
		pop		@1
.ENDMACRO
