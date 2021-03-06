{{┌──────────────────────────────────────────┐
  │ 1-pin 4 x 4 keypad reader                │      
  │ Author: Chris Gadd                       │     
  │ Copyright (c) 2014 Chris Gadd            │     
  │ See end of file for terms of use.        │     
  └──────────────────────────────────────────┘

  4 x 4 keypad reader using a single I/O pin, four 7.5K resistors, four 30K resistors, and a 1000pF capacitor
  
  PUB methods:
   Start(pin)       : I/O pin connected to the keypad circuit
   Poll             : Returns the key pressed in ASCII when key is pressed initially
                       Returns false if no key is pressed or if a key is held down
   Check_Keypad     : Returns key even if held down

                                         
    ┌────────────┐                             The keypad that I tested with has an 8-pin header:
    │ 1  2  3  A │─┳──────┐                     1 - row 2    (4,5,6,B)                          
    │            │  30K   │                     2 - row 3    (7,8,9,C)                          
    │ 4  5  6  B │─┫                           3 - column 1 (1,4,7,*)                          
    │            │  30K                         4 - row 4    (*,0,#,D)                          
    │ 7  8  9  C │─┫                            5 - column 2 (2,5,8,0)                          
    │            │  30K                         6 - column 3 (3,6,9,#)                          
    │ *  0  #  D │─┫                            7 - column 4 (A,B,C,D)  
    └────────────┘  30K                         8 - row 1    (1,2,3,A)          
                │                                                                            
      ┣┻┻┻────┘                       
       7.5K                                
      ┣─────────────────── I/O pin         
     1000pF                      
                                   
    
}}                                                                                           
CON
_clkmode = xtal1 + pll16x                            
_xinfreq = 5_000_000

VAR
  long  rc
  long  offset
  long  delta
  byte  flag

OBJ
  FDS : "FullDuplexSerial"
  
PUB Demo | key
{{
  stand-alone demo routine
}}
  fds.start(31,30,0,115200)
  waitcnt(cnt + clkfreq)
  fds.tx($00)
  
  Start(24)                                             ' Keypad connected to I/O pin 24

  repeat
    if key := poll
      fds.tx(key)
    waitcnt(cnt + clkfreq / 100)

PUB Start(pin)

  rc := pin

  ctra := %01000 << 26 | rc                             ' increment phsa every tick that pin is high
  frqa := 1
  outa[rc] := 1                                         ' rc pin is toggled between input and output, output is always high
  offset := 0                                           ' offset and delta are overwritten in the check_keypad method
  delta := 1                                            '  initial values ensure that any reading above 16 causes an update
                                                        '  typical readings are between 1000 and 11000

PUB Poll | k
{ Returns the ASCII value of the key pressed, the first time it's pressed
  Returns false if no key is pressed or if a key is held down
}

  if k := Check_Keypad                                  ' Check for a valid keypress
    if not flag                                         ' Check to determine if key is being held down
      flag := 1                                         '  Set flag if new key press
      return k                                          '  and return key
  else
    flag := 0                                           ' Clear the flag if no key is pressed

PUB Check_Keypad | t, k

  t := Get_reading
  k := (t - offset) / delta
  k := (lookupz(k:"1","2","3","A","4","5","6","B","7","8","9","C","*","0","#","D"))
  if k
    return k
  else                            
    delta := t / 21                                     ' Update the delta and offset if no valid reading is returned
    offset := delta + (delta / 2)                      

PRI Get_reading | A, B

  A := 0                                                ' Readings are likely to be incorrect when a key is pressed 
  B := posx                                             '  or released in the middle of a measurement
  repeat until || (A - B := Measure_RC) < 100           ' To compensate, multiple readings are taken and a value only
    A := B                                              '  returned when the latest two are close                                                             
  return B

PRI Measure_RC

  dira[rc] := 1                                         ' Set to output to charge the capacitor
  waitcnt(cnt + clkfreq / 2000)                         ' Wait a bit for the capacitor to charge
  phsa := 0                                             ' Reset counter
  dira[rc] := 0                                         ' Set to input to allow the capacitor to discharge
  waitpne(|<rc,|<rc,0)                                  ' Wait until capacitor discharges to below I/O pin threshold
  return phsa                                           ' Return the count

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