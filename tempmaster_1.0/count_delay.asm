.CSEG

;;
;; Delay by counting a register
;;
delay:
        ldi     TMP0, 0xff
    delay_loop:
        dec     TMP0
        brne    delay_loop
        ret

;;
;; "Key repeat" delay
;;
delay_long:
        ldi     TMP1, 0x70
    delay255_loop:
        rcall   delay10
        dec     TMP1
        brne    delay255_loop
        ret

delay10:
        rcall   delay5
        rcall   delay5
        ret

delay5:
        rcall   delay
        rcall   delay
        rcall   delay
        rcall   delay
        rcall   delay
        ret

