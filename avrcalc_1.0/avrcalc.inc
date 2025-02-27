;;
;; AVRCalc 1.0 specific macros and values.
;; 
;; (C) Claes M. Nyberg <md0claes@mdstud.chalmers.se>
;;

; Operator values
.SET OP_ADD = PLUS    ; '+'
.SET OP_SUB = MINUS   ; '-'
.SET OP_MUL = STAR    ; '*'
.SET OP_DIV = SLASH   ; '/'
.SET OP_PWR = POWER   ; '^'
.SET OP_SQR = LC_R    ; 'r'
.SET OP_MOD = PERCNT  ; '%'

; Size of input buffer in bytes
.SET BUFSIZE = 10

; Number of decimals to write when dividing
.SET DECIMALS = 3

;;
;; Write NULL terminated string stored in EEPROM to UART.
;; Argument 0 is the label/address of the string to write.
;;
.MACRO WRITE_EESTR_UART
        ldi     YL, low(@0)
        ldi     YH, high(@0)
        rcall   write_asciiz_eeprom_uart
.ENDMACRO

;;
;; Write NULL terminated string stored in DATA/CODE segment to UART.
;; Argument 0 is the label/address of the string to write.
;;
.MACRO WRITE_DTSTR_UART
        ldi     XL, low(@0)
        ldi     XH, high(@0)
        rcall    write_asciiz_data_uart
.ENDMACRO

;;
;; Read one newline terminated string, or at
;; most aas many bytes as argument 1 says into
;; buffer/lablel/address of argument 0.
;;
.MACRO  READLN_UART
        ldi     XL, low(@0)
        ldi     XH, high(@0)
        ldi     r16, @1
        rcall   readline_uart
.ENDMACRO

