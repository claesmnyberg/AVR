;;
;; Seiko LCD L1672 routines
;; Author: Claes M Nyberg <md0claes@mdstud.chalmers.se>
;; Date: Tue Dec 10 00:50:23 CET 2002
;;

.CSEG

;;
;; Clears LCD.
;;
lcd_clear:
        ldi      ARG0, LCD_CLEAR_CMD
        rcall    lcd_command
        ret

;;
;; Clears Line one and sets cursor to
;; beginning.
;; TODO: Replace macro with code
;;
lcd_clear_line1:
        rcall    lcd_home

        ;; Write 16 spaces
        LCD_WBYTE 0x20
        LCD_WBYTE 0x20
        LCD_WBYTE 0x20
        LCD_WBYTE 0x20
        LCD_WBYTE 0x20
        LCD_WBYTE 0x20
        LCD_WBYTE 0x20
        LCD_WBYTE 0x20
        LCD_WBYTE 0x20
        LCD_WBYTE 0x20
        LCD_WBYTE 0x20
        LCD_WBYTE 0x20
        LCD_WBYTE 0x20
        LCD_WBYTE 0x20
        LCD_WBYTE 0x20
        LCD_WBYTE 0x20
        
        rcall    lcd_home
        ret

;;
;; Clears Line two and sets cursor to
;; beginning.
;; TODO: Replace macro with code 
;;
lcd_clear_line2:
        rcall   lcd_line2

        ;; Write 16 spaces
        LCD_WBYTE 0x20
        LCD_WBYTE 0x20
        LCD_WBYTE 0x20
        LCD_WBYTE 0x20
        LCD_WBYTE 0x20
        LCD_WBYTE 0x20
        LCD_WBYTE 0x20
        LCD_WBYTE 0x20
        LCD_WBYTE 0x20
        LCD_WBYTE 0x20
        LCD_WBYTE 0x20
        LCD_WBYTE 0x20
        LCD_WBYTE 0x20
        LCD_WBYTE 0x20
        LCD_WBYTE 0x20
        LCD_WBYTE 0x20

        rcall   lcd_line2
        ret


;;
;; Sets cursor to position 0 on line 1
;;
lcd_home:
        ldi        ARG0, LCD_HOME_CMD
        rcall    lcd_command
        ret

;;
;; Set cursor to start of line two
;;
lcd_line2:
        ldi        ARG0, LCD_LINE2_0
        rcall    lcd_command
        ret

;;
;; Initiates LCD
;;
lcd_init:
        ;; Make sure LCD got power 
        rcall   delay10
        rcall   delay10
        rcall   delay10
        rcall   delay10

        ;; Reset sequence
        ;; 8 bit data size, 2 lines 
        ;; and 5x7 dot format
        ldi     ARG0, 0x38
        rcall   lcd_command
        ldi     ARG0, 0x38
        rcall   lcd_command
        ldi     ARG0, 0x38
        rcall   lcd_command
        ldi     ARG0, 0x38
        rcall   lcd_command

        ;; Increment one and no shift 
        ldi     ARG0, 0x06
        rcall   lcd_command

        ;; Display on [Cursor off, Blink off: Last two bits]
        ldi     ARG0, 0b00001100
        rcall   lcd_command

        ;; Clear display
        ldi     ARG0, 0x01
        rcall   lcd_command

        ;; Set marker to home position
        ldi     ARG0, 0x80
        rcall   lcd_command
        ret

;;
;; Writes byte in ARG0 register to LCD
;;
lcd_write_byte:
        sbi     PORTD, LCD_RS
        cbi     PORTD, LCD_RW
        rcall   delay
        out     LCD_DATA, ARG0
        sbi     PORTD, LCD_ENABLE
        rcall   delay10
        cbi     PORTD, LCD_ENABLE
        ret
;;
;; Send byte in ARG0 as command 
;;
lcd_command:
        cbi     PORTD, LCD_RS
        cbi     PORTD, LCD_RW
        rcall   delay
        out     LCD_DATA, ARG0
        sbi     PORTD, LCD_ENABLE
        rcall   delay10
        cbi     PORTD, LCD_ENABLE
        ret

;;
;; Write a NULL terminated ASCII string stored in data
;; segment to LCD.
;; Address of string is assumed to be in register X.
;;
lcd_write_data_asciiz:

        ld      ARG0, X+
        tst     ARG0
        breq    lcd_write_data_asciiz_done

        rcall   lcd_write_byte
        rjmp    lcd_write_data_asciiz

    lcd_write_data_asciiz_done:
        ret

;;
;; Write a NULL terminated ASCII string stored in EEPROM to LCD.
;; Address of string is assumed to be in register X.
;;
lcd_write_eeprom_asciiz:
        
    _setaddr:
        out     EEARH, XH
        out     EEARL, XL        ; Set address of next char to output
    
    _poll_eeprom:                ; Wait for EEPROM
        in      TMP0, EECR
        andi    TMP0, 0b00000010
        brne    _poll_eeprom

        ldi     TMP0, 0x01        ; Tell EEPROM to output char
        out     EECR, TMP0

        in      ARG0, EEDR        ; Get char from EEPROM
        and     ARG0, ARG0
        breq    _write_ee_done    ; Char is NULL, we are done

        rcall   lcd_write_byte
        inc     XL
        adc     XH, ZEROR
        rjmp    _setaddr

    _write_ee_done:
        ret

