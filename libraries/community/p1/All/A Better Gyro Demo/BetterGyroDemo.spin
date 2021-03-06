'****************************************
'* A Better LISY300AL Gyroscope Demo    *
'* Originally Written By Parallax Staff *
'* Adapted, Diagramed, Remarked and     *
'* generally expanded explanation by    *
'* Jim Miller August 25, 2010           *
'* Cannibal Robotics inc. Rev 1.0       *
'*   See End of File for Terms of Use   *               
'****************************************

{{

This example code will read the ADC output of the LISY300 Gyroscope. The values
are displayed on an NTSC monitor. A stable ADC value with the gyro held still should
be approx 1/2 of 1024. If the sensor is turned, it will increase to ~1024 for CCW movements
and decrease to ~1 for CW movements. 

The Rate varaible is the current ADC reading minus the center point.
A negitive Rate indicates CW and a positive rate indicates CCW. The absolute
value of Rate indicates the turning rate. 

Directional maximums are also recorded and displayed.

The Compute routine that interprets the ADC results, determines direction and turns LED's
on and off to indicate movement and direction.
  Red= Still
  Green= CCW
  Yellow= CW

The offest variable is a noise band for the ADC - Rates of absolute value less
than 'offset' are not reacted to in the compute routine. 

Wiring of Circuit for this demo - 

       LISY300
       ┌─────┐         
       ┤1   6├+5vDC         
    P0┤2   5├P1        
   GND┤3   4├P2
       └─────┘
        
    P3───────GND     red LED
    P4───────GND     yellow LED
    P5───────GND     green LED

    P12-15──  video resistor array per/on demo board

Final Note: I observed that when turning the board by hand quickly, you'll get a bit of
backlash when you stop. I think this is due more to my hand than the gyro though.
}}


CON                                                     ' Propeller Setup

  _CLKMODE = XTAL1 + PLL16X
  _XINFREQ = 5_000_000
  
CON                                                    

  DOUT   = 0    ' to Pin 2 on Gyro                        ' Gyro I/O Pins
  SCLK   = 2    ' to Pin 4 on Gyro
  nCS    = 1    ' to Pin 5 on Gyro                                

  Vid    = 12   ' Video base port
  
VAR                                                     ' Gyro & Global    

  long ADC                                              ' 10-bit ADC value
  long Center,Deg,Rate                                  ' Work Vars
  long RateMaxCW,RateMaxCCW,offset                      ' 
  
OBJ                                                     ' Object References
         
  Num: "Numbers"
  TV : "TV_Text"
      
PUB Initialization              '' Initialize port directions, working varaibles and start video cog

  TV.Start(Vid)                'Vid is basepin for video on demo board
                               ' Initialize LED ports - for the demo board you can just use 16-18
                               '  so you don't have to wire but they are small and hard to see when moving.
  dira[3] ~~                   ' Standing still            RED LED
  dira[4] ~~                   ' Moving Clockwise          YELLOW LED
  dira[5] ~~                   ' Moving Counter clockwise  GREEN LED
  
  waitcnt(clkfreq + cnt)

  dira[SCLK..nCS]~~

  DisplayBase0
   
  Calibrate                     ' Calibrate gyro by finding center (only needed once per power cycle)
  
  Main                          ' Main loop in program


pub Main                        '' Main repeat loop call      
  repeat
    Measure                     ' Get ACD Data
    Compute                     ' Demo compute on value & action
    DisplayUpdate               ' Display results on TV
    
PUB Calibrate | Value, Sigma, Minimum, Maximum, Average '' Calibrate ADC and determine center/still value

  result~
  Sigma~                                       
  Minimum := Maximum := Measure
  repeat 50
    Sigma += Value := Measure                           ' Sum 50 Voltage Readings
    Minimum <#= Value                                   ' Find Minimum Voltage 
    Maximum #>= Value                                   ' Find Maximum Voltage
  Average := Sigma / 50                                 ' Find Average of Samples
  Center := Average
  
  RateMaxCW := RateMaxCCW := 0

PUB Measure                     '' Clock data in for 13 bits.  (First three are zero, next ten are data)

  result~                                               ' Clear result
  outa[nCS]~                                            ' nCS = low

  repeat 13                                             ' repeat 13 times
    outa[SCLK]~                                         ' clk low
    outa[SCLK]~~                                        ' clk high
    ADC := result := result << 1 | ina[DOUT]            ' Save value in ADC variable
  outa[nCS]~~                                           ' cCS = high
      

PUB Compute                     '' Compute Turn Rate off of center  
  offset := 3                   ' Offset determines bound for action
                                ' Any movement less than offset in either direction is not responded.
  Rate := ADC - Center
  If RateMaxCCW < Rate
    RateMaxCCW := Rate
    
  Rate := ADC - Center
  If RateMaxCW > Rate
    RateMaxCW := Rate
    
  IF ADC > Center + offset
    Position(11,4)               ' TV display command
    TV.Str(string("CCW"))        ' TV display command
    
    outa[3] := 0                 ' Standing still
    outa[4] := 0                 ' Moving Clockwise
    outa[5] := 1                 ' Moving Counter clockwise
    
  IF ADC < Center - offset
    Position(11,4)               ' TV display command
    TV.Str(string("CW "))        ' TV display command
    
    outa[3] := 0                 ' Standing still
    outa[4] := 1                 ' Moving Clockwise
    outa[5] := 0                 ' Moving Counter clockwise
     
  IF ADC > Center - offset AND ADC < Center + offset  
    Position(11,4)               ' TV display command
    TV.Str(string(" - "))        ' TV display command
    
    outa[3] := 1                 ' Standing still
    outa[4] := 0                 ' Moving Clockwise
    outa[5] := 0                 ' Moving Counter clockwise

pub DisplayUpdate                '' TV Display - writes updated data to screen  
    TV.out($0C)                  ' set color command (color follows)
    TV.Out(0)                    ' home TV Terminal
    
    DisplayData(18,2,Center)
    DisplayData(32,2,Offset)
    
    DisplayData(18,3,ADC) 
    DisplayData(30,3,Rate) 

    DisplayData(12,5,RateMaxCW) 
    DisplayData(23,5,RateMaxCCW) 

    
Pub DisplayBase0                '' TV Basic Display - labels for all data shown 
    TV.out($0C)                 ' set color command (color follows)
    TV.Out(1)  
    TV.Out(00)                  'home TV Terminal
    TV.Str(string("======== Cannibal Robotics Inc ========"))
    TV.Out(13)
    TV.Str(string("-------- Gyro Feedback System  --------"))
    TV.Out(13)
    TV.Str(string("Calibrated Center:       Offset:"))    
    TV.Out(13)
    TV.Str(string("Current Reading:        Rate:"))
    TV.Out(13)
    TV.Str(string("Direction:"))    
    TV.Out(13)
    TV.Str(string("Rate Max CW:       CCW:"))

   
Pri Position(X,Y)               '' TV basic function Position cursor at X,Y
  TV.out($0B)                   'set Y position (Y follows)
  Tv.out(Y)
  TV.out($0A)                   'set X position (X follows)
  Tv.out(X)
  
Pri DisplayData (X,Y,Data)      '' TV basic function Display DEC data at X,Y position 
  TV.out($0B)                   'set Y position (Y follows)
  Tv.out(Y)
  TV.out($0A)                   'set X position (X follows)
  Tv.out(X)
  TV.Str(string("    "))        ' Blank old number
  TV.out($0A)                   'set X position (X follows)
  Tv.out(X)
  TV.Str(Num.ToStr (Data, Num#DDEC))
                                                                                                                                           
Pri DisplayBinData (X,Y,Data)   '' TV basic function Display BIN data at X,Y position
  TV.out($0B)                   'set Y position (Y follows)
  Tv.out(Y)
  TV.out($0A)                   'set X position (X follows)
  Tv.out(X)
  TV.Str(Num.ToStr (Data, Num#DBIN10))                     
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