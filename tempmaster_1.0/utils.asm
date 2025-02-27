
;;
;; Simple atoi function that assumes a correct string.
;; The address to the string is located in the X register.
;; The resulting integer is situated in RET3-RET0 afterwards.
;;
;; Integer value        LOC3, LOC2, LOC1, LOC0 (Copyed to RET3.. at the end)
;; Sign register        TMP5
;; String length        TMP4
;; Tmp                  TMP3
;; Decval               ARG3, ARG2, ARG1, ARG0
;; Current value        RET3, RET2, RET1, RET0
;;
atoi32:
        push    XL
        push    XH
        push    LOC3
        push    LOC2
        push    LOC1
        push    LOC0

        ;; Zero out Integer value
        clr     LOC3
        clr     LOC2
        clr     LOC1
        clr     LOC0
            
        ;; Zero out current value
        clr     RET3
        clr     RET2
        clr     RET1
        clr     RET0

        ;; Set Decval to 1
        clr     ARG3
        clr     ARG2
        clr     ARG1
        ldi     ARG0, 0x01
            
        ;; Set sign if string starts with '-'
        clr     TMP5
        ld      TMP3, X    
        cpi     TMP3, MINUS
        breq    set_sign

    ;; Get length of string
        clr     TMP4
    strlen:

        ;; Test if current char is a digit
        ld      TMP3, X
        subi    TMP3, ZERO
        brlt    atoi32_loop
        
        ld      TMP3, X
        subi    TMP3, (NINE+1)
        brge    atoi32_loop

        inc     XL
        inc     TMP4
        rjmp    strlen

    atoi32_loop:
        ;; Get current value
        eor     RET3, RET3
        eor     RET2, RET2
        eor     RET1, RET1
        ld      RET0, -X
        subi    RET0, ZERO

        ;; (Current value)*(Decval)
        push    TMP3
        rcall   mul32
        brvs    atoi32_overflow
        
        pop     TMP3

        ;; Add (Current value)*(Decval) to integer value
        add     LOC0, RET0
        adc     LOC1, RET1
        adc     LOC2, RET2
        adc     LOC3, RET3
    
        ;; Decval *= 10
        clr     RET3
        clr     RET2
        clr     RET1
        ldi     RET0, 10
        push    TMP3
        rcall   mul32
        brvs    atoi32_overflow
        
        pop     TMP3
        mov     ARG0, RET0
        mov     ARG1, RET1
        mov     ARG2, RET2
        mov     ARG3, RET3
    
        dec     TMP4
        breq    atoi32_done        ; We are finished
        rjmp    atoi32_loop

    set_sign:
        inc     TMP5
        inc     XL
        rjmp    strlen

    ;; Copy integer value and return
    atoi32_done:
        clv
        mov     RET3, LOC3
        mov     RET2, LOC2
        mov     RET1, LOC1
        mov     RET0, LOC0
        sbrs    TMP5, 0
        rjmp    atoi32_return

        cp      RET0, ZEROR
        cpc     RET1, ZEROR
        cpc     RET2, ZEROR
        cpc     RET3, ZEROR
        breq    atoi32_return

        ;; Change sign of integer
        com     RET3
        com     RET2
        com     RET1
        com     RET0
        subi    RET0, low(-1)
        sbci    RET0, high(-1)
        clv
           rjmp    atoi32_return
   
    ;; Restore stack and abort
    atoi32_overflow:
        pop     TMP3
        sev

    atoi32_return:
        pop     LOC0
        pop     LOC1
        pop     LOC2
        pop     LOC3
        pop     XH
        pop     XL
        ret

;;
;; Convert a 32 bit integer to a string
;; Address to start of string is in X.
;;
;; Integer value to convert in ARG3-ARG0
;;
;; Tmp                  TMP7, TMP6, TMP5, TMP4, 
;; Tmp2                 TMP3
;; Integer value        RET3, RET2, RET1, RET0
;; Tmp3                 ARG3, ARG2, ARG1, ARG0
;; Exponent             LOC3, LOC2, LOC1, LOC0
;;
itoa32:
        push    LOC3
        push    LOC2
        push    LOC1
        push    LOC0
      
        ;; Swap argument and return value to fit div32
        SWAPR   RET0, ARG0
        SWAPR   RET1, ARG1
        SWAPR   RET2, ARG2
        SWAPR   RET3, ARG3
       
        ;; Set Exponent to 1
        clr     LOC3
        clr     LOC2
        clr     LOC1
        clr     LOC0
        inc     LOC0

        ;; Neagate if integer is negative
        sbrs    RET3, 7    
        rjmp    sign_fixed

    ;; Negate integer value and write minus sign
        ldi     TMP3, MINUS
        st      X+, TMP3         ; Set minus sign
        com     RET3
        com     RET2
        com     RET1
        com     RET0
        subi    RET0, low(-1)
        sbci    RET0, high(-1)

    sign_fixed:
        ;; Save integer value
        mov     TMP7, RET3
        mov     TMP6, RET2
        mov     TMP5, RET1
        mov     TMP4, RET0

    ;; Get ten base high point
    calc_exp:

        ;; Set multiplicand/devisor to ten
        clr     ARG3
        clr     ARG2
        clr     ARG1
        ldi     ARG0, 10

        ;; Divide integer value with ten
        rcall   div32            

        ;; If result is zero, we are done here
        cp      RET0, ZEROR
        cpc     RET1, ZEROR
        cpc     RET2, ZEROR
        cpc     RET3, ZEROR
        breq    restore_val
    
    ;; Multiply exponent with ten
    continue:
        push    RET3
        push    RET2
        push    RET1
        push    RET0
        mov     RET3, LOC3
        mov     RET2, LOC2
        mov     RET1, LOC1
        mov     RET0, LOC0
        rcall   mul32
        mov     LOC3, RET3
        mov     LOC2, RET2
        mov     LOC1, RET1
        mov     LOC0, RET0
        
        pop     RET0
        pop     RET1
        pop     RET2
        pop     RET3
        rjmp    calc_exp
        
    restore_val:
        mov     RET3, TMP7
        mov     RET2, TMP6
        mov     RET1, TMP5
        mov     RET0, TMP4

    ;; Fill string with ASCII didgits
    dostring:

        ;; If exp is not zero, add another character
        cp      LOC3, ZEROR
        cpc     LOC2, ZEROR
        cpc     LOC1, ZEROR
        cpc     LOC0, ZEROR
        breq    itoa32_done

    add_char:
        
        ;; Divide integer value and exponent
        mov     RET3, TMP7
        mov     RET2, TMP6
        mov     RET1, TMP5
        mov     RET0, TMP4
        
        mov     ARG3, LOC3
        mov     ARG2, LOC2
        mov     ARG1, LOC1
        mov     ARG0, LOC0
        
        rcall   div32
    
        ;; Set digit in string
        ldi     TMP3, ZERO
        add     TMP3, RET0
        st      X+, TMP3

        ;; Multiply Exponent
        mov     ARG3, RET3
        mov     ARG2, RET2
        mov     ARG1, RET1
        mov     ARG0, RET0

        mov     RET3, LOC3
        mov     RET2, LOC2
        mov     RET1, LOC1
        mov     RET0, LOC0
        
        rcall   mul32

        ;; Subtract from integer value
        sub     TMP4, RET0
        sbc     TMP5, RET1
        sbc     TMP6, RET2
        sbc     TMP7, RET3

        ;; Divide exponent by ten
        mov     RET3, LOC3
        mov     RET2, LOC2
        mov     RET1, LOC1
        mov     RET0, LOC0

        clr     ARG3
        clr     ARG2
        clr     ARG1
        ldi     ARG0, 10
    
        rcall   div32

        mov     LOC3, RET3
        mov     LOC2, RET2
        mov     LOC1, RET1
        mov     LOC0, RET0
    
        rjmp    dostring
        
    itoa32_done:
        st      X, ZEROR
          pop       LOC0
        pop        LOC1
        pop        LOC2
        pop        LOC3
        ret
;;
;; Divide two 32 bit integers
;;
;; Divident/result RET3, RET2, RET1, RET0
;; Devisor         ARG3, ARG2, ARG1, ARG0
;; Reminder        RET7, RET6, RET5, RET4
;;
;; Loop counter    TMP0
;; Sign register   TMP1
;;
;; Algorithm Description
;; 1. XOR dividend and divisor High bytes 
;;    and store in a Sign register.
;;
;; 2. If MSB of dividend High set, negate dividend.
;; 3. If MSB of divisor High set, negate dividend.
;; 4. Clear remainder and carry.
;; 5. Load loop counter with 17.
;;
;; 6. Shift left dividend into carry.
;; 7. Decrement loop counter.
;; 8. If loop counter != 0, goto step 11.
;; 9. If MSB of Sign register set, negate result.
;; 10. Return
;; 11. Shift left carry (from dividend/result) into remainder
;; 12. Subtract divisor from remainder.
;; 13. If result negative, add back divisor, 
;;     clear carry and goto Step 6.
;; 14. Set carry and goto Step 6.
;;
div32:
        mov     TMP1, RET3        ; Copy dividend High to sign register
        eor     TMP1, ARG3        ; XOR divisor High with sign register
    
        sbrs    RET3, 7            ; MSB in dividend set
        rjmp    div32_1

        ;; Change sign of divident
        com     RET3    
        com     RET2
        com     RET1
        com     RET0
        subi    RET0, low(-1)
        sbci    RET0, high(-1)
    
    div32_1:    
        sbrs    ARG3,7            ; MSB in divisor set
        rjmp    div32_2

        ;; Change sign of divisor
        com     ARG3
        com     ARG2
        com     ARG1
        com     ARG0
        subi    ARG0, low(-1)
        sbci    ARG0, high(-1)

    div32_2:    
        ;; Clear reminder
        clr     RET7
        clr     RET6
        clr     RET5
        clr     RET4

        ;; Init loop counter and clear carry
        ldi     TMP0, 33

    div32_3:    
        ;; Shift divident left
        rol     RET0
        rol     RET1
        rol     RET2
        rol     RET3
        
        dec     TMP0                ; Decrement counter
        brne    div32_5        
        
        sbrs    TMP1, 7            ; MSB in sign register set
        rjmp    div32_4
            
        cp      RET3, ZEROR
        cpc     RET2, ZEROR
        cpc     RET1, ZEROR
        cpc     RET0, ZEROR
        breq    div32_4              ; Result is zero

        ;; Change sign of result/divident
        com     RET3
        com     RET2
        com     RET1
        com     RET0
        subi    RET0, low(-1)
        sbci    RET0, high(-1)
        
    div32_4:
        sbrc    TMP1, 7
        sen                ; Set negative flag
        ret            

    div32_5:    
        ;; Shift divident into reminder
        rol     RET4
        rol     RET5
        rol     RET6
        rol     RET7

        ;; Reminder -= devisor
        sub     RET4, ARG0 
        sbc     RET5, ARG1
        sbc     RET6, ARG2
        sbc     RET7, ARG3
        brcc    div32_6            ; Result negative, continue

        add     RET4, ARG0
        adc     RET5, ARG1
        adc     RET6, ARG2
        adc     RET7, ARG3
        
        clc                        ; Clear carry to be shifted into result
        rjmp    div32_3        

    div32_6:    
        sec                        ; Set carry to be shifted into result
        rjmp    div32_3


;;
;; Booth's algorithm: Multiply two signed 32 bit integers.
;; 
;; Result High           RET7, RET6, RET5, RET4
;; Result low/Multiplier RET3, RET2, RET1, RET0
;; Multiplicand          ARG3, ARG2, ARG1, ARG0
;;
;; Loop counter          TMP0
;;
;; Algorithm Description
;; 1. Clear result High word and carry.
;;
;; 2. Load loop counter with 32.
;;
;; 3. If carry (previous bit 0 of multiplier Low byte) set,
;;    add multiplicand to result High word.
;;
;; 4. If current bit 0 of multiplier Low byte set, subtract
;;    multiplicand from result High word.
;;
;; 5. Shift right result High word into result Low word/multiplier.
;; 6. Shift right Low word/multiplier.
;; 7. Decrement Loop counter.
;; 8. If loop counter not zero, goto Step 3.
;;
;; Note: If all 64 bit in answer is needed,
;; the algorithm fails when used with the most
;; negative number.
;;
mul32:
        ;; Clear result high
        clr     RET7
        clr     RET6
        clr     RET5
        clr     RET4

        clc                    ; Clear carry
        ldi     TMP0, 32        ; Loop counter

    mul32_loop:
        brcc    carry_done    ; Carry cleared

        ;; Add multiplicand to result High
        add     RET4, ARG0
        adc     RET5, ARG1
        adc     RET6, ARG2
        adc     RET7, ARG3
    
    ;; Check if bit 0 of multiplier set
    carry_done:
        sbrs    RET0, 0    
        rjmp    multiplier_bit0_done

        ;; Subtract multiplicand from result High
        sub     RET4, ARG0
        sbc     RET5, ARG1
        sbc     RET6, ARG2
        sbc     RET7, ARG3

    ;; Shift righ result (high and low)    
    multiplier_bit0_done:
        asr     RET7
        ror     RET6
        ror     RET5
        ror     RET4
        ror     RET3
        ror     RET2
        ror     RET1
        ror     RET0
            
        dec     TMP0
        brne    mul32_loop
        
        ;; Set overflow flag if result high is positive and not zero and > 0
        sbrc    RET7, 7
        ret
        cp      RET4, ZEROR
        cpc     RET5, ZEROR
        cpc     RET6, ZEROR
        cpc     RET7, ZEROR
        brne    mul32_overflow
        ret

    mul32_overflow:
        sev
        ret    
