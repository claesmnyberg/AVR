;;
;; 4x4 keypad (35-678-31 on www.elfa.se) driver definitions and
;; macros.
;;
;; Author: Claes M Nyberg <md0claes@mdstud.chalmers.se>
;;

;; Row bits
.EQU ROW1 = 4  
.EQU ROW2 = 5
.EQU ROW3 = 6
.EQU ROW4 = 7

;; Row masks
.EQU ROW1_MASK = 0x10
.EQU ROW2_MASK = 0x20
.EQU ROW3_MASK = 0x40
.EQU ROW4_MASK = 0x80

;; Column bits
.EQU COL1 = 0    
.EQU COL2 = 1     
.EQU COL3 = 2     
.EQU COL4 = 3     

;; Hexadecimal key values
.EQU KEY_0 = 0x00
.EQU KEY_1 = 0x01
.EQU KEY_2 = 0x02
.EQU KEY_3 = 0x03
.EQU KEY_4 = 0x04
.EQU KEY_5 = 0x05
.EQU KEY_6 = 0x06
.EQU KEY_7 = 0x07
.EQU KEY_8 = 0x08
.EQU KEY_9 = 0x09
.EQU KEY_A = 0x0a
.EQU KEY_B = 0x0b
.EQU KEY_C = 0x0c
.EQU KEY_D = 0x0d
.EQU KEY_STAR = 0x0e
.EQU KEY_NUM = 0x0f

;; Hexadecimal key values
.EQU AKEY_0 = 48 ; '0'
.EQU AKEY_1 = 49 ; '1'
.EQU AKEY_2 = 50 ; '2'
.EQU AKEY_3 = 51 ; '3'
.EQU AKEY_4 = 52 ; '4'
.EQU AKEY_5 = 53 ; '5'
.EQU AKEY_6 = 54 ; '6' 
.EQU AKEY_7 = 55 ; '7'
.EQU AKEY_8 = 56 ; '8'
.EQU AKEY_9 = 57 ; '9'
.EQU AKEY_A = 65 ; 'A'
.EQU AKEY_B = 66 ; 'B'
.EQU AKEY_C = 67 ; 'C'
.EQU AKEY_D = 68 ; 'D'
.EQU AKEY_STAR = 42 ; '*'
.EQU AKEY_NUM = 35 ; '#'


