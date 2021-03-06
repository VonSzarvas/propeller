{{

┌──────────────────────────────────────────┐
│ morse_code_demo                          │
│ Author: Thomas Earl McInnes              │               
│ See end of file for terms of use.        │                
└──────────────────────────────────────────┘


}}

CON

  _clkmode = xtal1 + pll16x
  _xinfreq = 6_250_000

  kdata = 26
  kclock = 27

  piezo = 0 

VAR

  Long stack[1000]

OBJ

  k     :       "Keyboard"
  mc    :       "morse_code"

PUB start_up                             
                                         
  k.start(kdata, kclock)                'Start the keyboard
  mc.start_up(piezo)
  cognew(program_code, @stack)          'Run main code

PUB program_code

  mc.str(@header)
  repeat
   mc.out(k.getkey)

DAT
     header   Byte      "Important message will follow", 0                       
     
{{
┌──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│                                                   TERMS OF USE: MIT License                                                  │                                                            
├──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation    │ 
│files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy,    │
│modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software│
│is furnished to do so, subject to the following conditions:                                                                   │
│                                                                                                                              │
│The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.│
│                                                                                                                              │
│THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE          │
│WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR         │
│COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,   │
│ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.                         │
└──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘
}}          