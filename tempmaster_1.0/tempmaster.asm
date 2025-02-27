;;
;; Tempmaster 1.0
;; Author: Claes M Nyberg <md0claes@mdstud.chalmers.se>
;;

.NOLIST
.INCLUDE "tempmaster.inc"
.LIST

.DSEG
buf: .BYTE 100

.CSEG
.ORG $000               ; Int
    rjmp    reset       ; $000 Reset Handler

.ORG $00A
    rjmp    TIM0_OVF    ; $009 Timer0 Overflow Handler

;;
;; Timer 0 overflow handler
;;
.ORG $015
TIM0_OVF:
    	inc		TIMER0_COUNTER        
    	sei         			; Reactivate global interrupt
    	reti

;;
;; Reset, set up stack, ports, timer 0 and LCD
;;
reset:
		;; Set up stack
		ldi		TMP0, low(RAMEND)
		out		SPL, TMP0
		ldi		TMP0, high(RAMEND)
		out		SPH, TMP0
	
		;; Set up ports
		ldi		TMP0, 0xff
		out		DDRC, TMP0		  ; LCD
		out		DDRD, TMP0		  ; LCD

		ldi     TMP0, 0b11110000  ; Keyboard
		out     DDRB, TMP0
	
		;; Slow down timer 0 by 1024
		ldi 	TMP0, 5 		 
		out		TCCR0, TMP0

		;; Activate timer 0 overflow
		in		TMP1, TIMSK
		ori		TMP1, 0x01
		out		TIMSK, TMP1

		;; Initiate LCD
		rcall   lcd_init

	    ;; Zero out important registers
        clr     ZEROR
        clr     TIMER0_COUNTER
        clr     LOC0
        clr     LOC1
        clr     LOC2

		;; Disable Analog Comparator
		sbi		ACSR, ACD

		;;
		;; Activate ADC 
		;;

		;; Set channel 0 (ADC0/Pin 40)
		clr		TMP0
		out		ADMUX, TMP0

		;; Set prescaler  (125 Khz) XTAL/32
		ldi		TMP0, 0b00000101
		out     ADCSR, TMP0
		
		;; Single conversion
		cbi		ADCSR, ADFR	

		;; Disable interrupt
		cbi     ADCSR, ADIE

		;; Enable ADC
		sbi     ADCSR, ADEN

		;; Turn on global interrupt
		sei		
;;
;; Main loop
;;
main:

	main_loop:
		cpi     TIMER0_COUNTER, COUNTER_ROUNDS
		breq	read_adc0
		rjmp	main_loop


;;
;; Reads value from ADC0 and writes it to LCD and 
;; continues to write_time
;;
read_adc0:
		clr     TIMER0_COUNTER
		clr     ARG2
		clr     ARG3
		cbi		ADCSR, ADIF
		sbi		ADCSR, ADSC		; Measure

	wait4_ADCSR:
		sbis	ADCSR, ADIF
		rjmp	wait4_ADCSR
		
cbi		ADCSR, ADSC

		;; Read current value
		in		ARG0, ADCL
		in		ARG1, ADCH

cbi     ADCSR, ADIF

		;; Convert it to ASCII and write it to LCD
		ldi		XL, low(buf)
		ldi		XH, high(buf)
		rcall	itoa32

		rcall	lcd_clear_line1
		LCD_MOVE2 LCD_LINE1_0

		ldi     XL, low(buf)
		ldi     XH, high(buf)
		rcall	lcd_write_data_asciiz

rjmp	main

;;
;; Writes time in hh:mm:ss format to the LCD display.
;;
write_time:

	addsec:
		ldi		TMP0, 60
		inc		LOC0
		cp		LOC0, TMP0
		breq	addmin
		rjmp	printtime
		
	addmin:
		clr		LOC0
		inc		LOC1
		cp		LOC1, TMP0
		breq	addhour
		rjmp	printtime

	addhour:
		clr		LOC1
		inc		LOC2
		ldi     TMP0, 25
		cp		LOC2, TMP0
		brne	printtime
		clr		LOC2

	printtime:
		clr		ARG3
		clr		ARG2
		clr		ARG1
		ldi     XL, low(buf)
		ldi     XH, high(buf)

		;; Add a leading zero
		ldi		ARG0, 10
		cp		LOC2, ARG0
		brge	gethours
		ldi		TMP0, ZERO
		st		X+, TMP0
		
	gethours:
		mov		ARG0, LOC2		; Hours
		rcall	itoa32
		ldi     TMP0, COLON
		st      X+, TMP0

		;; Add a leading zero
		ldi     ARG0, 10
		cp      LOC1, ARG0
		brge    getmin
		ldi     TMP0, ZERO
		st      X+, TMP0
	
	getmin:
		mov     ARG0, LOC1      ; Minutes
		rcall   itoa32
		ldi     TMP0, COLON
		st      X+, TMP0

		;; Add a leading zero
		ldi     ARG0, 10
		cp      LOC0, ARG0
		brge    getsec
		ldi     TMP0, ZERO
		st      X+, TMP0

	getsec:
		mov     ARG0, LOC0      ; Seconds
		rcall   itoa32
	
		LCD_MOVE2 LCD_LINE2_8  
		ldi     XL, low(buf)
		ldi     XH, high(buf)
		rcall	lcd_write_data_asciiz
		rjmp	main



;; Yes, this is ugly 
.INCLUDE "LCD_seiko_L172.asm"
.INCLUDE "keypad4x4.asm"
.INCLUDE "count_delay.asm"
.INCLUDE "utils.asm"

