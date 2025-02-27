;;
;; AVR Calculator Version 1.0 (HT 2002)
;; Author: Claes M. Nyberg <md0claes@mdstud.chalmers.se>
;; 


.NOLIST
.INCLUDE "2313def.inc"
.INCLUDE "ASCIIdef.inc"
.INCLUDE "avrcalc.inc"
.LIST

;; Target architecture
.DEVICE AT90S2313

;; EEPROM segment ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
.ESEG

; banner: 
; 'AT90S2313: AVRCalc V. 1.0'
; 'By Claes M. Nyberg <md0claes@mdstud.chalmers.se>'
banner:
icname:   .DB UC_A,UC_T,NINE,ZERO,UC_S,TWO,THREE,ONE,THREE,COLON,SPACE
progname: .DB UC_A,UC_V,UC_R,UC_C,LC_A,LC_L,LC_C,SPACE
version:  .DB UC_V,DOT,SPACE,ONE,DOT,ZERO,SPACE,UC_H,UC_T,ZERO,TWO,CR,LF
author:   .DB UC_B,LC_Y,SPACE,UC_C,LC_L,LC_A,LC_E,LC_S,SPACE,UC_M,DOT,SPACE,UC_N,LC_Y,LC_B,LC_E,LC_R,LC_G,SPACE
address:  .DB ARROWL,LC_M,LC_D,ZERO,LC_C,LC_L,LC_A,LC_E,LC_S,AT,LC_M,LC_D,LC_S,LC_T,LC_U,LC_D,DOT,LC_C,LC_H,LC_A,LC_L,LC_M,LC_E,LC_R,LC_S,DOT,LC_S,LC_E,ARROWR,CR,LF,0x00

; int_prompt: 'int> '
int_prompt:     .DB LC_I,LC_N,LC_T,ARROWR,SPACE,0x00

; op_prompt: ' op> '
op_prompt:      .DB SPACE,LC_O,LC_P,ARROWR,SPACE,0x00

; syntax_error: 'Syntax Error'
syntax_error:   .DB UC_S,LC_Y,LC_N,LC_T,LC_A,LC_X,SPACE,UC_E,LC_R,LC_R,LC_O,LC_R,CR,LF,0x00

; oflow_error: 'Overflow'
oflow_error:    .DB UC_O,LC_V,LC_E,LC_R,LC_F,LC_L,LC_O,LC_W,CR,LF,0x00

; New line, Carriage Return, Line Feed
newline:        .DB CR,LF,0x00

; Backspace, erase last character
bckspace:       .DB BS,SPACE,BS,0x00

;; Data segment ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; I wish that i could run code here ... ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.DSEG

; Input Buffer
buf: .BYTE (BUFSIZE +1)

; Integers
answer:      .BYTE 4    ; Answer to previous/current operation.
int_left:    .BYTE 4    ; Left side integer.
int_right:   .BYTE 4    ; Right side integer.

;; Code/Text segment ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
.CSEG
.ORG    0x00
        rjmp    init

;;
;; Set up STACK, PORTB and UART
;;
.ORG    0x0b
init:
        ldi        r16, RAMEND        ; Initiate stack pointer
        out        SPL, r16

        ldi        r16, 0xff          ; Port B as out
        out        DDRB, r16

        ldi        r16, 103           ; Initiate UART, 2400 baud
        out        UBRR, r16
        ldi        r16, 0b00011000    ; No interrupts, receiver on, sender on, 8 bits
        out        UCR, r16
        
        clr        r0                ; Always keep r0 zero

        ldi        r16, 0xff         ; Light port b to indicate successfull init
        out        PORTB, r16

;;
;; Main loop.
;; Read expressions from UART and evaluate them.
;;
main:
        ;; Wait for key to be pressed
        rcall   wait4uart_receive
        in      r16, UDR
        
        ;; Write banner
        WRITE_EESTR_UART banner

    calculate:
        ;; This is an ugly space saver.
        ;; Instead of restoring the stack on error,
        ;; we simply set it for each round.
        ldi     r16, RAMEND     
        out     SPL, r16
        
    ;; Read left side integer
    read_left_int:
        WRITE_EESTR_UART int_prompt
        READLN_UART buf, BUFSIZE
        cpi        r20, 0x00
        breq    read_left_int        ; Jump back if zero bytes read
        
        ;; Convert ASCII integer to binary
        rcall   atoi32        ; Integer in registers r17-r20
        brvs    overflow_error_message
        push    r17
        push    r18
        push    r19
        push    r20

    ;; Read operator
    read_operator:
        WRITE_EESTR_UART op_prompt
        READLN_UART buf, 1
        cpi        r20, 0x00
        breq    read_operator        ; Read again if zero bytes read

        ;; No need to read more if square root operator
        cpi     r25, OP_SQR
        breq    sqrt_op

        ;; Save operator
        push    r25

    ;; Read right side integer
    read_right_int:
        WRITE_EESTR_UART int_prompt
        ldi     r16, BUFSIZE
        rcall   readline_uart        ; Address is already in X
        cpi        r20, 0x00    
        breq    read_right_int         ; Read again

        ;; Convert ASCII integer to binary
        rcall   atoi32      ; Integers in registers r17-r20
        brvs    overflow_error_message

        ;; Restore operator
        pop     r25
        
        ;; left Integer 
        pop     r16
        pop     r15
        pop     r14
        pop     r13

        ;; Check for operator
        cpi     r25, OP_ADD
        breq    add_op
        cpi     r25, OP_SUB
        breq    sub_op
        cpi     r25, OP_MUL
        breq    mul_op
        cpi     r25, OP_DIV
        breq    div_op
        cpi     r25, OP_PWR
        breq    pwr_op
        cpi        r25, OP_MOD
        breq    mod_op
    
    ;; Syntax error
    syntax_error_message:
        WRITE_EESTR_UART syntax_error
        rjmp    calculate

    ;; Overflow error
    overflow_error_message:
        WRITE_EESTR_UART oflow_error
        rjmp    calculate

    ;; Square root
    sqrt_op:
        rjmp    sqrt_op_decimals
    
    ;; Addition
    add_op:
        add     r16, r20
        adc     r15, r19
        adc     r14, r18
        adc     r13, r17
        rjmp    write_answer
    
    ;; Subtraction
    sub_op:
        sub     r16, r20
        sbc     r15, r19
        sbc     r14, r18
        sbc     r13, r17
        rjmp    write_answer

    ;; Multiplication
    mul_op:
        mov     r24, r16
        mov     r23, r15
        mov     r22, r14
        mov     r21, r13
        rcall   mul32
        brvs    overflow_error_message
        
        mov     r16, r24
        mov     r15, r23
        mov     r14, r22
        mov     r13, r21
        rjmp    write_answer
    
    div_op:
        rjmp    div_op_decimals

    ;; Modulo
    mod_op:
        rcall    div32
        mov        r16, r24
        mov        r15, r23
        mov        r14, r22
        mov        r13, r21
        rjmp    write_answer

    ;; Enpower
    pwr_op:
        
        ;; Base
        mov     r24, r16
        mov     r23, r15
        mov     r22, r14
        mov     r21, r13

        ;; Exponent
        mov     r4, r20
        mov     r3, r19
        mov     r2, r18
        mov     r1, r17

        rcall   power32
        brvs    overflow_error_message

        mov     r16, r24
        mov     r15, r23
        mov     r14, r22
        mov     r13, r21

    ;; This label assumes that the integer to write
    ;; is in registers r13, r14, r15, r16
    write_answer:
        out        PORTB, r16
        ldi     XL, low(buf)
        ldi     XH, high(buf)
        rcall   itoa32
        rcall   write_asciiz_data_uart        
        WRITE_EESTR_UART newline
        rjmp    calculate

  ;; Square root with decimals.
  ;; Ugly quick-hack ..
  sqrt_op_decimals:
        ;; Restore first integer
        pop     r24
        pop     r23
        pop     r22
        pop     r21

        ;; .. And save it again
        push    r21
        push    r22
        push    r23
        push    r24
    
        ;; Negative number
        sbrc    r21, 7
        rjmp    syntax_error_message

        ;; Call sqrt to get integer result
        mov        r1, r21
        mov        r2, r22
        mov        r3, r23
        mov        r4, r24
        rcall    sqrt32
    
        ;; Get length of result by dividing
        ;; by ten until result is zero
        clr        r1
        mov        r13, r17
        mov        r14, r18
        mov        r15, r19
        mov        r16, r20
    
        clr        r17
        clr        r18
        clr        r19
        ldi        r20, 10
    
    sqrt_get_length:
        rcall    div32
        inc    r1
        
        cp        r16, r0
        cpc        r15, r0
        cpc        r14, r0
        cpc        r13, r0
        brne    sqrt_get_length

        ;; Restore number
        pop        r24
        pop        r23
        pop        r22
        pop        r21
    
        ;; Save length
        push    r1

        ;; Set r17-r20 to 10000
        clr        r17
        clr        r18
        ldi        r19, high(10000)
        ldi        r20, low(10000)
        
        ;; Multiply with 10000 to get two decimals
        rcall    mul32
        brvs    sqrt_error
        
        mov        r1, r21
        mov        r2, r22
        mov        r3, r23
        mov        r4, r24
        
        rcall   sqrt32        ; Answer in registers r17, r18, r19, r20
        mov     r16, r20
        mov     r15, r19
        mov     r14, r18
        mov     r13, r17

        ldi    XL, low(buf)
        ldi    XH, high(buf)
        rcall    itoa32
        
        ;; Restore length of integer
        pop        r1
        
    sqrt_printint:
          and        r1, r1
          breq    sqrt_write_decimals
   
           ld        r16, X+
           rcall    wait4uart_send
           out        UDR, r16 
   
           dec        r1
           rjmp    sqrt_printint
       
    sqrt_write_decimals:
          ldi        r16, DOT
          rcall    wait4uart_send
          out        UDR, r16
      
          rcall    write_asciiz_data_uart
          WRITE_EESTR_UART newline
        rcall    calculate
        
    sqrt_error:
          rcall    overflow_error_message

    ;; Division (prints decimals).
    ;; Since the stack pointer is initiated at the start of
    ;; calculate, we can use 'rcall' as a long-jump without
    ;; worrying about the saved return address on the stack.
    divide_by_zero: rcall    syntax_error_message ; Yes, this is ugly.
    div_op_decimals:

        ;; Divide by zero ?
        cp        r20, r0
        cpc        r19, r0
        cpc        r18, r0
        cpc        r17, r0
        breq    divide_by_zero

        ;; c = a/b + r
        rcall    div32
        brmi    write_minus
        out        PORTB, r16
        
    div_op_write_result:

        ;; Save b/devisor
        push    r17
        push    r18
        push    r19
        push    r20

        ;; Save reminder
        push    r21
        push    r22
        push    r23
        push    r24

        ldi     XL, low(buf)
        ldi     XH, high(buf)
        rcall   itoa32
        rcall   write_asciiz_data_uart

        ldi        r25, DECIMALS
        mov        r1, r25
        cp        r1, r0
        breq    decimals_done

        ;; Write '.' to UART
        ldi        r25, DOT
        rcall    wait4uart_send
        out        UDR, r25

        ;; Restore reminder
        pop        r24
        pop        r23
        pop        r22
        pop        r21

    write_decimals:

        clr        r17
        clr        r18
        clr        r19
        ldi        r20, 10
    
        ;; r = r*10
        rcall    mul32

        ;; c = r/b
        mov        r13, r21
        mov        r14, r22
        mov        r15, r23
        mov        r16, r24
        
        pop        r20
        pop        r19
        pop        r18
        pop        r17
    
        rcall    div32

        ;; Save b/devisor
        push    r17
        push    r18
        push    r19
        push    r20

        ;; Write c
        ldi        r25, ZERO
        add        r16, r25

        rcall    wait4uart_send
        out        UDR, r16

        ;; r = (r % b)
        mov        r13, r21
        mov        r14, r22
        mov        r15, r23
        mov        r16, r24

        dec        r1
        brne    write_decimals
    
    decimals_done:
        WRITE_EESTR_UART newline
        rcall    calculate

    write_minus:
        cp        r16, r0
        cpc        r15, r0
        cpc        r14, r0
        cpc        r13, r0
        brne    jmp_write_result

        ;; Reminder is zero?
        cp        r24, r0
        cpc        r23, r0
        cpc        r22, r0
        cpc        r21, r0
        breq    jmp_write_result
        
        ldi        r25, MINUS
        push    r17
        rcall    wait4uart_send
        out        UDR, r25
        pop        r17

    jmp_write_result:
        rcall    div_op_write_result

;;
;; Calculate a 32 bit integer enpowered by another.
;; Negative exponents is not yet supported.
;; The integer/answer is in r21, r22, r23, r24
;; The exponent is in r1, r2, r3, r4
;; tmp: r25
;;
power32:
        ;; If exponent is negative, return zero
        sbrc    r1, 7
        rjmp    return_zero

        ;; If exponent is >= 31, there is a (possible) overflow.
        ;; We ignore the case when base is one since a user
        ;; with such low knowledge in math would probably need
        ;; to do some thinking anyway ..
        
        ldi        r25, 31
        cp        r4, r25    
        brge    power32_overflow

        ;; Copy base
        mov     r17, r21
        mov     r18, r22
        mov     r19, r23
        mov     r20, r24

        ;; Set base to one
        clr     r21
        clr     r22
        clr     r23
        ldi     r24, 1

    multiply:
        ;; Test if exponent is zero
        cp      r4, r0
        cpc     r3, r0
        cpc     r2, r0
        cpc     r2, r0
        brne    mul_continue
        ret

    mul_continue:
        rcall   mul32
        brvs    power32_overflow

        ldi     r16, 0x1
        sub     r4, r16
        sbc     r3, r0
        sbc     r2, r0
        sbc     r1, r0
        rjmp    multiply

    return_zero:
        clr     r21
        clr     r22
        clr     r23
        clr     r24

    power32_overflow:
        sev
        ret

;;
;; A naive square-root algorithm.
;; Square an increasing number until we find the root. 
;;
;; Integer in r1, r2, r3, r4
;; The answer is in registers r17, r18, r19, r20
;;
sqrt32:
        ;; Try zero first
        clr     r17
        clr     r18
        clr     r19
        clr     r20
        
    square:
        mov     r21, r17
        mov     r22, r18
        mov     r23, r19
        mov     r24, r20

        rcall   mul32

        cp      r24, r4
        cpc     r23, r3
        cpc     r22, r2
        cpc     r21, r1
        breq    found_root
        brge    decrease_one

        ldi     r16, 1
        add     r20, r16
        adc     r19, r0
        adc     r18, r0
        adc     r17, r0
        rjmp    square

    decrease_one:
        clr     r1
        subi    r20, 1
        sbc     r19, r1
        sbc     r18, r1
        sbc     r17, r1
    
    found_root:
        ret

;;
;; Read one Carriage Return terminated string, or at most as many bytes
;; as the value of register r16 into buffer pointed to by register X.
;; Note that there will be a NULL written on position r16+1.
;;
readline_uart:
        push    XL
        push    XH              ; Save for later
        eor     r20, r20        ; Buffer position

    readln_uart:
        rcall   wait4uart_receive
        in      r19, UDR

        cpi     r19, BS         ; Backspace
        breq    backspace
        
        cpi     r19, CR
        breq    read_done       ; End of line

        and     r16, r16
        breq    readln_uart     ; No space left, wait for CR or BS
        
        rcall   wait4uart_send
        out     UDR, r19        ; Echo character back
        st      X+, r19
        dec     r16
        inc     r20
        rjmp    readln_uart

    backspace:                  ; Erase last character received
        and     r20, r20
        breq    readln_uart     ; Start all over if on position 0
        dec     r20
        st      -X, r0
        inc     r16
        WRITE_EESTR_UART bckspace
        rjmp    readln_uart

    read_done:
        ld      r25, -X        ; Save last char as operator
        inc     XL
        st      X, r0          ; Set end of string.
        WRITE_EESTR_UART newline
        pop     XH
        pop     XL
        ret


;;
;; Booth's algorithm: Multiply two signed 32 bit integers.
;; 
;; Result High           r13, r14, r15, r16
;; Multiplicand          r17, r18, r19, r20
;; Result low/multiplier r21, r22, r23, r24
;;
;; Loop counter          r25
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
        clr     r13
        clr     r14
        clr     r15
        clr     r16

        clc                    ; Clear carry
        ldi     r25, 32        ; Loop counter

    mul32_loop:
        brcc    carry_done    ; Carry cleared

        ;; Add multiplicand to result High
        add     r16, r20
        adc     r15, r19
        adc     r14, r18
        adc     r13, r17
    
    ;; Check if bit 0 of multiplier set
    carry_done:
        sbrs    r24, 0    
        rjmp    multiplier_bit0_done

        ;; Subtract multiplicand from result High
        sub     r16, r20
        sbc     r15, r19
        sbc     r14, r18
        sbc     r13, r17

    ;; Shift righ result (high and low)    
    multiplier_bit0_done:
        asr     r13
        ror     r14
        ror     r15
        ror     r16
        ror     r21
        ror     r22
        ror     r23
        ror     r24
            
        dec     r25
        brne    mul32_loop
        
        ;; Set overflow flag if result high is positive and not zero and > 0
        sbrc    r13, 7
        ret
        cp      r16, r0
        cpc     r15, r0
        cpc     r14, r0
        cpc     r13, r0
        brne    mul32_overflow
        ret

    mul32_overflow:
        sev
        ret    

;;
;; Divide two 32 bit integers
;;
;; Divident/result r13, r14, r15, r16
;; Devisor         r17, r18, r19, r20
;; Reminder        r21, r22, r23, r24
;;
;; Sign register   r11
;; Loop counter    r25
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
        mov     r11, r13        ; Copy dividend High to sign register
        eor     r11, r17        ; XOR divisor High with sign register
    
        sbrs    r13, 7            ; MSB in dividend set
        rjmp    div32_1

        ;; Change sign of divident
        com     r13    
        com     r14
        com     r15
        com     r16
        subi    r16, low(-1)
        sbci    r16, high(-1)
    
    div32_1:    
        sbrs    r17,7            ; MSB in divisor set
        rjmp    div32_2

        ;; Change sign of divisor
        com     r17
        com     r18
        com     r19
        com     r20
        subi    r20, low(-1)
        sbci    r20, high(-1)

    div32_2:    
        ;; Clear reminder
        eor     r21, r21
        eor     r22, r22
        eor     r23, r23
        eor     r24, r24

        ;; Init loop counter and clear carry
        ldi     r25, 33

    div32_3:    
        ;; Shift divident left
        rol     r16
        rol     r15
        rol     r14
        rol     r13
        
        dec     r25                ; Decrement counter
        brne    div32_5        
        
        sbrs    r11, 7            ; MSB in sign register set
        rjmp    div32_4
            
        cp        r13, r0
        cpc        r14, r0
        cpc        r15, r0
        cpc        r16, r0
        breq    div32_4              ; Result is zero

        ;; Change sign of result/divident
        com     r13
        com     r14
        com     r15
        com     r16
        subi    r16, low(-1)
        sbci    r16, high(-1)
        
    div32_4:
        sbrc    r11, 7
        sen                ; Set negative flag
        ret            

    div32_5:    
        ;; Shift divident into reminder
        rol     r24
        rol     r23
        rol     r22
        rol     r21

        ;; Reminder -= devisor
        sub     r24, r20 
        sbc     r23, r19
        sbc     r22, r18
        sbc     r21, r17
        brcc    div32_6            ; Result negative, continue

        add     r24, r20
        adc     r23, r19
        adc     r22, r18
        adc     r21, r17
        
        clc                        ; Clear carry to be shifted into result
        rjmp    div32_3        

    div32_6:    
        sec                        ; Set carry to be shifted into result
        rjmp    div32_3

;;
;; Simple atoi function that assumes a correct string.
;; The address to the string is located in the X register.
;; The integer is situated in r17, r18, r19, r20 afterwards.
;;
;; Integer value        r5, r6, r7, r8 (Copyed to r17.. at the end)
;; Sign register        r9
;; String length        r10
;; Tmp                    r11, r25
;; Decval               r17, r18, r19, r20
;; Current value        r21, r22, r23, r24
;;
atoi32:
        ;; Zero out Integer value
        eor     r5, r5
        eor     r6, r6
        eor     r7, r7
        eor     r8, r8
            
        ;; Zero out current value
        eor     r21, r21
        eor     r22, r22
        eor     r23, r23
        eor     r24, r24

        ;; Set Decval to 1
        eor     r17, r17
        eor     r18, r18
        eor     r19, r19
        ldi     r20, 0x01
            
        ;; Set sign if string starts with '-'
        eor     r9, r9
        ld      r25, X    
        cpi     r25, MINUS
        breq    set_sign

    ;; Get length of string
        eor     r10, r10
    strlen:

        ;; Test if current char is a digit
        ld      r25, X
        subi    r25, ZERO
        brlt    atoi32_loop
        
        ld      r25, X
        subi    r25, (NINE+1)
        brge    atoi32_loop

        inc     XL
        inc     r10
        rjmp    strlen

    atoi32_loop:
        ;; Get current value
        eor     r21, r21
        eor     r22, r22
        eor     r23, r23
        ld      r24, -X
        subi    r24, ZERO

        ;; (Current value)*(Decval)
        push    r25
        rcall   mul32
        brvs    atoi32_overflow
        
        pop     r25

        ;; Add (Current value)*(Decval) to integer value
        add     r8, r24
        adc     r7, r23
        adc     r6, r22
        adc     r5, r21
    
        ;; Decval *= 10
        eor     r21, r21
        eor     r22, r22
        eor     r23, r23
        ldi     r24, 10
        push    r25
        rcall   mul32
        brvs    atoi32_overflow
        
        pop     r25
        mov     r20, r24
        mov     r19, r23
        mov     r18, r22
        mov     r17, r21
    
        dec     r10
        breq    atoi32_done        ; We are finished
        rjmp    atoi32_loop

    set_sign:
        inc     r9
        inc     XL
        rjmp    strlen

    ;; Copy integer value and return
    atoi32_done:
        clv
        mov     r17, r5
        mov     r18, r6
        mov     r19, r7
        mov     r20, r8
        sbrs    r9, 0
        rjmp    atoi32_return

        cp      r20, r0
        cpc     r19, r0
        cpc     r18, r0
        cpc     r17, r0
        breq    atoi32_return

        ;; Change sign of integer
        com     r17
        com     r18
        com     r19
        com     r20
        subi    r20, low(-1)
        sbci    r20, high(-1)
        clv
        ret
    
    ;; Restore stack and abort
    atoi32_overflow:
        pop     r25
        sev
    atoi32_return:
        ret

;;
;; Convert an integer to a string
;; Address to start of string is in X.
;; Integer value is in r13, r14, r15, r16
;;
;; Tmp                  r1, r2, r3, r4, 
;; Tmp2                 r5, r25
;; Integer value        r13, r14, r15, r16
;; Tmp3                 r17, r18, r19, r20
;; Exponent             r6, r7, r8, r9
;;
itoa32:
        push    XL
        push    XH        ; Save for main routine
        
        ;; Set Exponent to 1
        eor     r6, r6
        eor     r7, r7
        eor     r8, r8 
        eor     r9, r9
        inc     r9

        ;; Neagate if integer is negative
        sbrs    r13, 7    
        rjmp    sign_fixed

    ;; Negate integer value and write minus sign
        ldi     r25, MINUS
        st      X+, r25         ; Set minus sign
        com     r13
        com     r14
        com     r15
        com     r16
        subi    r16, low(-1)
        sbci    r16, high(-1)

    sign_fixed:
        ;; Save integer value
        mov     r1, r13
        mov     r2, r14
        mov     r3, r15
        mov     r4, r16

    ;; Get ten base high point
    calc_exp:

        ;; Set multiplicand/devisor to ten
        eor     r17, r17
        eor     r18, r18
        eor     r19, r19
        ldi     r20, 10

        ;; Divide integer value with ten
        rcall   div32            

        ;; If result is zero, we are done here
        cp      r16, r0
        cpc     r15, r0
        cpc     r14, r0
        cpc     r13, r0
        breq    restore_val
    
    ;; Multiply exponent with ten
    continue:
        push    r13
        push    r14
        push    r15
        push    r16
        mov     r21, r6
        mov     r22, r7
        mov     r23, r8
        mov     r24, r9
        rcall   mul32
        mov     r6, r21
        mov     r7, r22
        mov     r8, r23
        mov     r9, r24
        
        pop     r16
        pop     r15
        pop     r14
        pop     r13
        rjmp    calc_exp
        
    restore_val:
        mov     r13, r1
        mov     r14, r2
        mov     r15, r3
        mov     r16, r4

    ;; Fill string with ASCII didgits
    dostring:

        ;; If exp is not zero, add another character
        cp      r6, r0
        cpc     r7, r0
        cpc     r8, r0
        cpc     r9, r0
        breq    itoa32_done

    add_char:
        
        ;; Divide integer value and exponent
        mov     r13, r1
        mov     r14, r2
        mov     r15, r3
        mov     r16, r4
        
        mov     r17, r6
        mov     r18, r7
        mov     r19, r8
        mov     r20, r9
        
        rcall   div32
    
        ;; Set didgit in string
        ldi     r25, ZERO
        add     r25, r16
        st      X+, r25

        ;; Multiply Exponent
        mov     r17, r13
        mov     r18, r14
        mov     r19, r15
        mov     r20, r16

        mov     r21, r6
        mov     r22, r7
        mov     r23, r8
        mov     r24, r9
        
        rcall   mul32

        ;; Subtract from integer value
        sub     r4, r24
        sbc     r3, r23
        sbc     r2, r22
        sbc     r1, r21

        ;; Divide exponent by ten
        mov     r13, r6
        mov     r14, r7
        mov     r15, r8
        mov     r16, r9

        eor     r17, r17
        eor     r18, r18
        eor     r19, r19
        ldi     r20, 10
    
        rcall   div32

        mov     r6, r13
        mov     r7, r14
        mov     r8, r15
        mov     r9, r16
    
        rjmp    dostring
        
    itoa32_done:
        st      X, r0
        pop     XH
        pop     XL
        ret

;;
;; Write a NULL terminated ASCII string stored in EEPROM 
;; to UART.
;; Address of string is assumed to be in register Y.
;;
write_asciiz_eeprom_uart:

    _setaddr:
        out     EEAR, YL        ; Set address of next char to output

    _poll_eeprom:                ; Wait for EEPROM
        in      r17, EECR
        andi    r17, 0b00000010
        brne    _poll_eeprom
        
        ldi     r17, 0x01        ; Tell EEPROM to output char
        out     EECR, r17
        
        in      r18, EEDR        ; Get char from EEPROM
        and     r18, r18
        breq    write_ee_done    ; Char is NULL, we are done
    
        rcall   wait4uart_send
        out     UDR, r18        ; Write char to UART
        inc     YL                ; Next byte
        rjmp    _setaddr
    
    write_ee_done:
        ret

;;
;; Write a NULL terminated ASCII string stored in data
;; segment to UART.
;; Address of string is assumed to be in register X.
;;
write_asciiz_data_uart:

        ld      r18, X+
        and     r18, r18
        breq    write_dt_done

        rcall   wait4uart_send
        out     UDR, r18
        rjmp    write_asciiz_data_uart

    write_dt_done:
        ret

;;
;; Wait until character is received by UART.
;; 
wait4uart_receive:
        in      r17, USR
        sbrc    r17, 7        ; Return if bit 7 is set
        ret
        rjmp    wait4uart_receive
        
;;
;; Wait for UART to become ready for sending.
;;
wait4uart_send:
        in      r17, USR
        sbrc    r17, 5       ; Return if bit 5 is set 
        ret
        rjmp    wait4uart_send
