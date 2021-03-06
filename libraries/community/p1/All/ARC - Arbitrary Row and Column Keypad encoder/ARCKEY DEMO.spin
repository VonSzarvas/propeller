{{
**************************************************************************
*
*   ARCKEY.spin
*   ARC KEYBOARD SCANNER EMNCODER V1.0
*   October 2011 Peter Jakacki
*
**************************************************************************
}}
' See ARCKEY.spin for more information

' Demo setup - attach keypad to P0..P7 and set rows and columns accordingly

con
  _CLKMODE = XTAL1 + PLL16X
  _XINFREQ = 8_000_000
  clockfreq = ((_CLKMODE - XTAL1) >> 6) * _XINFREQ


  columns       = %00001111     ' assume columns are on P0..P3
  rows          = %11110000     ' assume columns are on P4..P7
  txd           = 30
  rxd           = 31

obj
  serial :      "FullDuplexSerial"
  keypad :      "ARCKEY"

pub start                    ' insert startup method demo or demo2
  demo

' Demo will display the scancode and try to translate this code as well

pub demo | ch
    keypad.pins(%110000000101,%1101010000) '(rows,columns)
    keypad.table(@keytbl)
    serial.start(rxd,txd,0,9600)
    serial.str(@SPLASH)
    repeat
      ch := keypad.scankeys
      if ch+1
        serial.str(string(13,10,"Scancode = "))
        serial.hex(ch,4)
        serial.str(string(" : Keycode = "))
        ch := keypad.translate(ch)
        serial.hex(ch,4)

' This method demonstrate how the application would normally access the keypad
'
pub demo2 | ch
    keypad.pins(rows,columns)
    keypad.table(@keytbl)
    serial.start(rxd,txd,0,9600)
    serial.str(@SPLASH)
    repeat
      ch := keypad.key                                  ' read a key, translate if possible
      if ch+1                                           ' quick way of saying if ch <> -1
        serial.str(string(13,10,"Keycode = "))
        serial.hex(ch,4)


dat
'
' Sample scancode translation table.
' Find the scancodes by running the Demo and then include this scancode
' in the table along with the desired keycode
'
keytbl
        word $012b,"1"
        word $010b,"2"
        word $00cb,"3"
        word $012a,"4"
        word $010a,"5"
        word $00ca,"6"
        word $0120,"7"
        word $0100,"8"
        word $00c0,"9"
        word $0122,"*"
        word $0102,"0"
        word $00c2,"#"
        word  0

SPLASH
        byte  13,10,"ARCKEY DEMO - arbitrary row and column keyboard encoding",0


DAT
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
