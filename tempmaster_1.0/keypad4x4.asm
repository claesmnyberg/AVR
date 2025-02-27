;;
;; 4x4 keypad (35-678-31 on www.elfa.se) routines.
;;
;; Author: Claes M Nyberg <md0claes@mdstud.chalmers.se>
;; Date: Tue Dec 10 00:50:23 CET 2002
;;

;;
;; Scans until a key is pressed and returns its
;; ASCII value.
;;
scan4x4_ascii:
        rcall   scan4x4
        mov     TMP0, RET0
        sbrc    TMP0, ROW1
        rjmp    scan4x4_ascii_row1
        sbrc    TMP0, ROW2
        rjmp    scan4x4_ascii_row2
        sbrc    TMP0, ROW3
        rjmp    scan4x4_ascii_row3
        sbrc    TMP0, ROW4
        rjmp    scan4x4_ascii_row4

    ;; First row: 1, 2, 3 or A
    scan4x4_ascii_row1:
        sbrc    TMP0, COL1
        ldi     RET0, AKEY_1
        sbrc    TMP0, COL2
        ldi     RET0, AKEY_2
        sbrc    TMP0, COL3
        ldi     RET0, AKEY_3
        sbrc    TMP0, COL4
        ldi     RET0, AKEY_A
        ret

    ;; Second row: 4, 5, 6 or B
    scan4x4_ascii_row2:
        sbrc    TMP0, COL1
        ldi     RET0, AKEY_4
        sbrc    TMP0, COL2
        ldi     RET0, AKEY_5
        sbrc    TMP0, COL3
        ldi     RET0, AKEY_6
        sbrc    TMP0, COL4
        ldi     RET0, AKEY_B
        ret

    ;; Theird row: 7, 8, 9 or C
    scan4x4_ascii_row3:
        sbrc    TMP0, COL1
        ldi     RET0, AKEY_7
        sbrc    TMP0, COL2
        ldi     RET0, AKEY_8
        sbrc    TMP0, COL3
        ldi     RET0, AKEY_9
        sbrc    TMP0, COL4
        ldi     RET0, AKEY_C
        ret

    ;; Fourth row: *, 0, # or D
    scan4x4_ascii_row4:
        sbrc    TMP0, COL1
        ldi     RET0, AKEY_STAR
        sbrc    TMP0, COL2
        ldi     RET0, AKEY_0
        sbrc    TMP0, COL3
        ldi     RET0, AKEY_NUM
        sbrc    TMP0, COL4
        ldi     RET0, AKEY_D
        ret

;;
;; Scans until a key is pressed and return its
;; hexadecimal value in the RET0 register (defined above).
;;
scan4x4_hex:
        rcall   scan4x4
        mov     TMP0, RET0
        sbrc    TMP0, ROW1
        rjmp    scan4x4_hex_row1
        sbrc    TMP0, ROW2
        rjmp    scan4x4_hex_row2
        sbrc    TMP0, ROW3
        rjmp    scan4x4_hex_row3
        sbrc    TMP0, ROW4
        rjmp    scan4x4_hex_row4
    
    ;; First row: 1, 2, 3 or A
    scan4x4_hex_row1:
        sbrc    TMP0, COL1
        ldi     RET0, KEY_1
        sbrc    TMP0, COL2
        ldi     RET0, KEY_2
        sbrc    TMP0, COL3
        ldi     RET0, KEY_3
        sbrc    TMP0, COL4
        ldi     RET0, KEY_A
        ret

    ;; Second row: 4, 5, 6 or B    
    scan4x4_hex_row2:
        sbrc    TMP0, COL1
        ldi     RET0, KEY_4
        sbrc    TMP0, COL2
        ldi     RET0, KEY_5
        sbrc    TMP0, COL3
        ldi     RET0, KEY_6
        sbrc    TMP0, COL4
        ldi     RET0, KEY_B
        ret

    ;; Theird row: 7, 8, 9 or C
    scan4x4_hex_row3:
        sbrc    TMP0, COL1
        ldi     RET0, KEY_7
        sbrc    TMP0, COL2
        ldi     RET0, KEY_8
        sbrc    TMP0, COL3
        ldi     RET0, KEY_9
        sbrc    TMP0, COL4
        ldi     RET0, KEY_C
         ret

    ;; Fourth row: *, 0, # or D
    scan4x4_hex_row4:
        sbrc    TMP0, COL1
        ldi     RET0, KEY_STAR
        sbrc    TMP0, COL2
        ldi     RET0, KEY_0
        sbrc    TMP0, COL3
        ldi     RET0, KEY_NUM
        sbrc    TMP0, COL4
        ldi     RET0, KEY_D
        ret

;;
;; Scans until a key is pressed and return 
;; the bits representing its position.
;;
scan4x4:
        
        ;; First row
        ldi     TMP0, ROW1_MASK
        out     PORTB, TMP0
        in      TMP0, PINB
        mov     TMP1, TMP0
        andi    TMP1, 0x0f    ; Mask out columns    
        brne    scan4x4_done  ; Key pressed 

        ;; Second row
        ldi     TMP0, ROW2_MASK
        out     PORTB, TMP0
        in      TMP0, PINB
        mov     TMP1, TMP0
        andi    TMP1, 0x0f    ; Mask out columns
        brne    scan4x4_done  ; Key pressed

        ;; Theird row
        ldi     TMP0, ROW3_MASK
        out     PORTB, TMP0
        in      TMP0, PINB
        mov     TMP1, TMP0
        andi    TMP1, 0x0f    ; Mask out columns
        brne    scan4x4_done  ; Key pressed

        ;; Fourth row
        ldi     TMP0, ROW4_MASK
        out     PORTB, TMP0
        in      TMP0, PINB
        mov     TMP1, TMP0
        andi    TMP1, 0x0f    ; Mask out columns
        brne    scan4x4_done  ; Key pressed
        rjmp    scan4x4

    ;; Shut down PORTB and return
    scan4x4_done:
        mov     RET0, TMP0
        out     PORTB, ZEROR
        ret
