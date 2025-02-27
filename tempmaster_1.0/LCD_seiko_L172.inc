;;
;; Seiko LCD L1672 Driver definitions and Macros
;; Author: Claes M Nyberg <md0claes@mdstud.chalmers.se>
;; Date: Tue Dec 10 00:50:23 CET 2002
;;

;;.INCLUDE "../include/8535def.inc"
;;.DEF ZEROR = r0      ; r0 is always zero
;;.DEF TMP0 = r16     ; Does not survive rcall
;;.DEF TMP1 = r17     ; Does not survive rcall
;;.DEF ARG0 = r18
;;.DEF ARG1 = r19
;;.DEF RET0 = r20

;; LCD pins
;;.EQU LCD_DATA = PORTC
;;.EQU LCD_ENABLE = PIND7
;;.EQU LCD_RW = PIND5
;;.EQU LCD_RS = PIND6


;; LCD Commands
.EQU LCD_CLEAR_CMD = 0x01
.EQU LCD_HOME_CMD = 0x02

;; Addresses
.EQU LCD_LINE1_0 = 0x80
.EQU LCD_LINE1_1 = 0x81
.EQU LCD_LINE1_2 = 0x82
.EQU LCD_LINE1_3 = 0x83
.EQU LCD_LINE1_4 = 0x84
.EQU LCD_LINE1_5 = 0x85
.EQU LCD_LINE1_6 = 0x86
.EQU LCD_LINE1_7 = 0x87
.EQU LCD_LINE1_8 = 0x88
.EQU LCD_LINE1_9 = 0x89
.EQU LCD_LINE1_10 = 0x8a
.EQU LCD_LINE1_11 = 0x8b
.EQU LCD_LINE1_12 = 0x8c
.EQU LCD_LINE1_13 = 0x8d
.EQU LCD_LINE1_14 = 0x8e
.EQU LCD_LINE1_15 = 0x8f

.EQU LCD_LINE2_0 = 0xc0
.EQU LCD_LINE2_1 = 0xc1
.EQU LCD_LINE2_2 = 0xc2
.EQU LCD_LINE2_3 = 0xc3
.EQU LCD_LINE2_4 = 0xc4
.EQU LCD_LINE2_5 = 0xc5
.EQU LCD_LINE2_6 = 0xc6
.EQU LCD_LINE2_7 = 0xc7
.EQU LCD_LINE2_8 = 0xc8
.EQU LCD_LINE2_9 = 0xc9
.EQU LCD_LINE2_10 = 0xca
.EQU LCD_LINE2_11 = 0xcb
.EQU LCD_LINE2_12 = 0xcc
.EQU LCD_LINE2_13 = 0xcd
.EQU LCD_LINE2_14 = 0xce
.EQU LCD_LINE2_15 = 0xcf


;;
;; Move cursor to given position 
;; Line 1: 80-8F
;; Line 2: C0-CF
;;
.MACRO LCD_MOVE2
		ldi		ARG0, @0
		rcall	lcd_command
.ENDMACRO

;;
;; Write byte
;;
.MACRO LCD_WBYTE
		ldi		ARG0, @0
		rcall	lcd_write_byte
.ENDMACRO

;;
;; Write string from data segment
;;
.MACRO LCD_WRITE_ASCIIZ_EEPROM
        ldi     XL, low(@0)
        ldi     XH, high(@0)
        rcall   lcd_write_eeprom_asciiz
.ENDMACRO


;;
;; Write string from data segment
;;
.MACRO LCD_WRITE_ASCIIZ_DATA
		ldi		XL, low(@0)
		ldi		XH, high(@0)
		rcall	lcd_write_data_asciiz
.ENDMACRO
