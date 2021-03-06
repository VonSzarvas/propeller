{{

┌──────────────────────────────────────────┐
│ Demo program for MonVarsVGA              │
│ Author: Eric Ratliff                     │               
│ Copyright (c) 2008 Eric Ratliff          │               
│ See end of file for terms of use.        │                
└──────────────────────────────────────────┘

HexDisplayFunctions_SequentialDemo.spin, to show how to use functions that help showing binary strings and indifidual bytes
                                         also to show clearing of monitor and placing annotation labels
                                         sequence may optionally be controlled by a pushbutton wired to pull high when pressed
by Eric Ratliff 2008.12.26

}}

CON _clkmode = xtal1 + pll16x
  _xinfreq = 5_000_000
  DisplaySize_long = 288        ' count of longs in display area that we are using
  'CLEAR_BUTTON_PIN = 2         ' where 'pull up' button is connected for clearing buffer
  CLEAR_BUTTON_PIN = -1         ' code to show we have not wired a button, just let user see timed repeat forever
  SIMULATED_LIVE=4              ' base of some place in array we do not want to bother during screen clear process, as example
  
OBJ
  Monitor :     "MonVarsVGA"
  'ByteAccessory : "HexDisplayAccessory"                ' this is the object we are primarily testing here

VAR
  long MonArray[DisplaySize_long]
  'byte MonArray[DisplaySize_long << 2]                 ' this substitution seems to work well
  long Stack1[50]     ' space for new cog, no idea how much to allocate
  long Stack2[50]     ' space for new cog, no idea how much to allocate

PUB go
''test main
        
  ' inhibit opening paint of numbers
  Monitor.PreBlankVariables(@MonArray,0,DisplaySize_long-1)                     
  ' start showing signed long ints on the VGA monitor in Hex format
  Monitor.UHexStart(Monitor#DevBoardVGABasePin,@MonArray,DisplaySize_long)
  Monitor.LiveString(STRING("immediate after start string"),4,10) ' this string does not work on the first loop, does later

  ' start cog to show that numbers are being updated live
  cognew(FastUptick,@Stack1)
  cognew(SlowUptick,@Stack2)

  repeat
    ' show raw put byte functions
    Monitor.LiveString(STRING("raw put byte functions"),4,3)
    ' expect byte in left position of first long on display
    Monitor.PutByte(@MonArray,0,$a0)                                            
    ' expect byte in right position of index 2 long
    Monitor.PutByte(@MonArray,11,$a1)                                           
    ' expect byte in left position of first long in 'line 1' (lines start at 'line 0')
    Monitor.PutByte(@MonArray,32,$a2)                                           

    ClearScreen ' clear screen on button press, proceed on button release
    ' show 'safe' put byte functions
    Monitor.LiveString(STRING("safe put byte functions"),4,7)
    ' expect byte in left position of first long on display on line 4
    Monitor.SafePutByte(@MonArray,DisplaySize_long,128,$b0)                     
    ' expect byte in right position of index 2 long on line 4
    Monitor.SafePutByte(@MonArray,DisplaySize_long,139,$b1)                     
    ' expect byte in left position of first long in 'line 5' (lines start at 'line 0')
    Monitor.SafePutByte(@MonArray,DisplaySize_long,160,$b2)                     
    
    ClearScreen ' clear screen on button press, proceed on button release
    ' show 'safe frontier' put byte functions
    Monitor.LiveString(STRING("safe put byte frontier functions"),4,11)
    ' expect byte in left position of first long on display on line 8
    Monitor.SafePutFrontierByte(@MonArray,DisplaySize_long,256,$c0)             
    ' expect byte in right position of index 2 long on line 8
    Monitor.SafePutFrontierByte(@MonArray,DisplaySize_long,267,$c1)             
    ' expect byte in left position of first long in 'line 9' (lines start at 'line 0')
    Monitor.SafePutFrontierByte(@MonArray,DisplaySize_long,288,$c2)             
    ' expect byte in next to right position of index 4 long on line 8
    ' note that neutral values NOT shown, this only happens if left byte in long is written
    ' this is to allow progressive filling of arrays one byte at a time with hiding of 'unlikely values' used to inhibit screen paint
    Monitor.SafePutFrontierByte(@MonArray,DisplaySize_long,274,$c3)             
    
    ClearScreen ' clear screen on button press, proceed on button release
    ' show string functions, start on line 12
    Monitor.LiveString(STRING("string functions"),60,15)
    ' expect string to start at first long of line 12 and see 'unlikely values' at end
    Monitor.SafePutMeasuredString(@MonArray,DisplaySize_long,384,@S0,9)
    ' expect string to start at first long of line 13 and see 'unlikely values' at end
    ' this shows how to define string length based on null termination
    Monitor.SafePutMeasuredString(@MonArray,DisplaySize_long,416,@S0,strsize(@S0))
    ' same as above two, but with 'neutral values' padded onto right end
    ' line 14
    Monitor.SafePutMeasuredFrontierString(@MonArray,DisplaySize_long,448,@S0,9)
    ' expect string to start at first long of line 13 and see 'unlikely values' at end
    ' this shows how to define string length based on null termination
    ' line 15
    Monitor.SafePutMeasuredFrontierString(@MonArray,DisplaySize_long,480,@S0,strsize(@S0))
    
    ClearScreen ' clear screen on button press, proceed on button release
    ' show same miscelaenous values starting on line 20
    Monitor.LiveString(STRING("safe put long function"),60,23)
    ' note that here indicies are offsets in longs, not bytes
    Monitor.SafePutLong(@MonArray,DisplaySize_long,160+0,-2_000_000_000)
    Monitor.SafePutLong(@MonArray,DisplaySize_long,160+1,10)
    Monitor.SafePutLong(@MonArray,DisplaySize_long,160+2,-15)
    Monitor.SafePutLong(@MonArray,DisplaySize_long,160+3,-25)
    Monitor.SafePutLong(@MonArray,DisplaySize_long,160+4,-2111111111)
    Monitor.SafePutLong(@MonArray,DisplaySize_long,160+5,2111111111)
    Monitor.SafePutLong(@MonArray,DisplaySize_long,160+6,32767)
    Monitor.SafePutLong(@MonArray,DisplaySize_long,160+7,-32768)
    Monitor.SafePutLong(@MonArray,DisplaySize_long,160+8,2_000_000_000)
    
    ' wait here until button is pressed
    ButtonWait(true)
    Monitor.PreBlankVariables(@MonArray,0,SIMULATED_LIVE-1)                     ' install unlikely values into array          
    Monitor.PreBlankVariables(@MonArray,SIMULATED_LIVE+2,DisplaySize_long-1)    ' install unlikely values into array          
    Monitor.LiveBlankScreen(0,DisplaySize_long) ' clear entire display

    ' wait here until button is released
    ButtonWait(false)
    

PRI ClearScreen
' blanks screen on button down, lets execcution proceed on button rise
  ' wait here until button is pressed
  ButtonWait(true)
  'Monitor.SafePutLong(@MonArray,DisplaySize_long,192,$7)                       ' tested the button wait routine

  Monitor.LiveBlankScreen(0,DisplaySize_long) ' clear entire display
  
  ' wait here until button is released
  ButtonWait(false)

PRI ButtonWait(DesiredState)
' waits for button pin to reach desired state
' if button pin's number is out of range, then just wait a fixed period of time, longer for press than release
  ' is button pin's number valid for Propeller chip?
  if CLEAR_BUTTON_PIN => 0 and CLEAR_BUTTON_PIN =< 31
    ' wait here until button reaches desired state
    repeat until ((ina & (1 << CLEAR_BUTTON_PIN)) == 0) <> DesiredState
    waitcnt((clkfreq >> 3)+cnt)                         ' wait a short time for contact bounce to die
  else
    ' invalid pin number
    if DesiredState
      waitcnt((clkfreq*5)+cnt)                          ' wait long time period
    else
      waitcnt((clkfreq)+cnt)                            ' wait short time period

PRI FastUptick|CountAtStart
' constantly update a particular variable, to simulate purpose of MonVarVGA, showing variable values for program debugging
' note that long variables are assigned different place in hub than byte variables, so be careful what you expect to be sequential
' interesting that last digit stays fixed, BUT! is not same digit with each program start, something is not deterministic
  CountAtStart := cnt
  repeat
    LONG[@MonArray][SIMULATED_LIVE] := cnt + CountAtStart
  
PRI SlowUptick
' slowly update a particular variable, to show that value is undisturbed because we did not call "PreBlankVariables" on this part of array
' note that sometimes number dissapears from screen because we DO blank the whole screen, and display update only happens when value CHANGES
  LONG[@MonArray][SIMULATED_LIVE+1] := 0
  repeat
    waitcnt(clkfreq + cnt)
    LONG[@MonArray][SIMULATED_LIVE+1]++
  
DAT

S0 byte $01,$02,$03,$04,$05,$00,$07,$08,$09
S1 byte $00,$01,$02,$03,   $04,$05,$06,$07,   $08,$09,$0a,$0b,   $0c,$0d,$0e,$0f,   $10,$11,$12,$13,   $14,$15,$16,$17,   $118,$19,$1a,$1b,  $1c,$1d,$1e,$1f

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







