

AVRCalc Version 1.0 (HT 2002)
Author: Claes M. Nyberg <md0claes@mdstud.chalmers.se>

Description -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

This is a calculator written for AT90S2313.

It uses the serial port for communications, so you need either mincom(1) 
if you are on a UNIX machine, or Hyperterminal on Window$.

One thing to bear in mind is that this implementation lacks intelligent
error messages since the existing memory where prioritized for the calculator
itself, rather than error handling.
Since 32 bits is used to represent numbers, the memory is consumed fast.

Compiling -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

Either type 'make' if you are on a UNIX machine that has avra(1) installed, or
use AVRASM on Window$.

Usage -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=--=-


The supported operations:
Addition:        '+'
Subtraction:     '-'
Multiplication:  '*'
Division:        '/'
Square root:     'r'
Enpower:         '^'
Modulo:          '%'

Plug in the serial cable and fire up either mindterm(1) or Hyperterminal.
A banner will appear, and after that a prompt looking like 'int> '.
Feed it with an integer.
If this succeded, you will get another prompt that looks like ' op> '.
Enter the desired operation, and press enter.
If you selected the square root operation, the result will be printed.
If not, you will have to enter another integer and press enter again
to receive the result.

