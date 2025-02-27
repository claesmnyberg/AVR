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
.ORG $000           	; $000-$011 Is reserved for interrupts
;================================= Avbrottsvektorer
    rjmp    RESET       ; $000 Reset Handler
    rjmp    EXT_INT0    ; $001 IRQ0 Handler
    rjmp    EXT_INT1    ; $002 IRQ1 Handler
    rjmp    TIM2_COMP   ; $003 Timer2 Output Compare Match Handler
    rjmp    TIM2_OVF    ; $004 Timer2 Overflow Handler
    rjmp    TIM1_CAPT   ; $005 Timer1 Input Capture Handler
    rjmp    TIM1_COMPA  ; $006 Timer1 Output Compare A Handler
    rjmp    TIM1_COMPB  ; $007 Timer1 Output Compare B Handler
    rjmp    TIM1_OVF    ; $008 Timer1 Overflow Handler
    rjmp    TIM0_OVF    ; $009 Timer0 Overflow Handler
    rjmp    SPI_STC     ; $00A SPI Transfer Complete Handler
    rjmp    UART_RXC    ; $00B UART RX Complete Handler
    rjmp    UART_DRE    ; $00C UDR Empty Handler
    rjmp    UART_TXC    ; $00D UART TX Complete Handler
    rjmp    ADC         ; $00E ADC Conversion Complete Interrupt Handler
    rjmp    EE_RDY      ; $00F EEPROM Write Complete = Ready Handler
    rjmp    ANA_COMP    ; $010 Analog Comparator Handler

EXT_INT0:
    reti
;---------------------------------
EXT_INT1:
    reti
;---------------------------------
TIM2_COMP:
    reti
;---------------------------------
TIM2_OVF:
    reti
;---------------------------------
TIM1_CAPT:
    reti
;---------------------------------
TIM1_COMPA:
    reti
;---------------------------------
TIM1_COMPB:
    reti
;---------------------------------
TIM1_OVF:
    reti
;---------------------------------


;;
;; Timer 0 overflow handler
;;
.ORG $015
TIM0_OVF:
    	inc		TIMER0_COUNTER        
    	sei         			; Reactivate global interrupt
    	reti

;---------------------------------
SPI_STC:
    reti
;---------------------------------
UART_RXC:
    reti
;---------------------------------
UART_DRE:
    reti
;---------------------------------
UART_TXC:
    reti
;---------------------------------
ADC:
		;; Read current value

;	LCD_WBYTE DOT

;sbi		ADCSR, ADSC

;	wait4_ADIF:
;		sbis    ADCSR, ADIF
;		rjmp    wait4_ADIF

		in      ARG0, ADCL
		in      ARG1, ADCH
;		sei
    	reti
;---------------------------------
EE_RDY:
    reti
;---------------------------------
ANA_COMP:
    reti


;;
;; Reset, set up stack, ports, timer 0 and LCD
;;
RESET:
		;; Set up stack
		ldi		TMP0, low(RAMEND)
		out		SPL, TMP0
		ldi		TMP0, high(RAMEND)
		out		SPH, TMP0
	
		;; Set up ports
		ldi		TMP0, 0xff
		out		DDRC, TMP0		  ; LCD
		out		DDRD, TMP0		  ; LCD

;		ldi     TMP0, 0b11110000  ; Keyboard
;		out     DDRB, TMP0
	
		;; Slow down timer 0 by 1024
;		ldi 	TMP0, 5 		 
;		out		TCCR0, TMP0

		;; Activate timer 0 overflow
;		in		TMP1, TIMSK
;		ori		TMP1, 0x01
;		out		TIMSK, TMP1

		;; Initiate LCD
		rcall   lcd_init

	    ;; Zero out important registers
        clr     ZEROR
        clr     TIMER0_COUNTER
        clr     LOC0
        clr     LOC1
        clr     LOC2

;		;; Disable Analog Comparator
;		sbi		ACSR, ACD

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

		;; Enable ADC
		sbi     ADCSR, ADEN

		;; Disable interrupt
		cbi     ADCSR, ADIE

		;; Turn on global interrupt
;		sei		

;;
;; Main loop
;;
main:
rcall	delay_long
rcall   delay_long
rcall   delay_long


;	main_loop:
;		cpi     TIMER0_COUNTER, COUNTER_ROUNDS
;		breq	read_adc0
;		rjmp	main_loop

;;
;; Reads value from ADC0 and writes it to LCD and 
;; continues to write_time
;;
read_adc0:
		;cli		; Disable global interrupt

cbi     ADCSR, ADSC
cbi     ADCSR, ADFR
        clr     TIMER0_COUNTER
        clr     ARG2
        clr     ARG3


		ldi		TMP0, (1<<SE)
		out		MCUCR, TMP0

cbi     ADCSR, ADFR
sbi     ADCSR, ADEN
sei
sbi		ADCSR, ADIE
		sleep
cbi     ADCSR, ADIE
cbi     ADCSR, ADEN
cbi     ADCSR, ADFR

cli
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

