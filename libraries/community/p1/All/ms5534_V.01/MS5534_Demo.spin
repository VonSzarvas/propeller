{{File:    MS5534_Demo
  Author:  Justin Jordan (J^3) 
  Started: 12MAR11 
  Updated: 13MAR11

  Description: Top object for simple demonstration of the MS5534_v.01 object

  Revisions:
}}


CON

  _xinfreq = 5_000_000
  _clkmode = xtal1 + pll16x
  
  RX   = 31
  TX   = 30 
  MODE = 0      
  BAUD = 9600   

  DIN  = 0
  DOUT = 1
  MCLK = 2
  SCLK = 3

  
OBJ

  UART    : "FullDuplexSerialPlus"
  MS5534  : "MS5534_v.01"


VAR

 byte idx, cog
 long coeffs[6], d1, d2, temp, press


PUB Demo

  UART.start(RX, TX, MODE, BAUD)
  cog := MS5534.start(DIN, DOUT, MCLK, SCLK)

  UART.tx(UART#CLS)
  UART.str(@Display)
  UART.tx(UART#HOME)

  repeat idx from 1 to 6
    coeffs[idx - 1]  := MS5534.getCoef(idx)
    UART.tx(UART#CRSRXY)
    UART.tx(52)
    UART.tx(idx)
    UART.dec(coeffs[idx - 1])
    UART.tx(UART#CLREOL)

  repeat
    d1 :=  MS5534.getD1
    UART.tx(UART#CRSRXY)
    UART.tx(52)
    UART.tx(7)
    UART.dec(d1)
    UART.tx(UART#CLREOL)
     
    d2 :=  MS5534.getD2
    UART.tx(UART#CRSRXY)
    UART.tx(52)
    UART.tx(8)
    UART.dec(d2)
    UART.tx(UART#CLREOL)
     
    temp :=  MS5534.getCelsius
    UART.tx(UART#CRSRXY)
    UART.tx(52)
    UART.tx(9)
    UART.dec(temp)
    UART.tx(UART#CLREOL)
     
    press :=  MS5534.getMilliBar
    UART.tx(UART#CRSRXY)
    UART.tx(52)
    UART.tx(10)
    UART.dec(press)
    UART.tx(UART#CLREOL)
    



DAT

Display       byte      "***************************************************************", 13
              byte      "Calibration Coefficient 1                         = ", 13
              byte      "Calibration Coefficient 2                         = ", 13 
              byte      "Calibration Coefficient 3                         = ", 13 
              byte      "Calibration Coefficient 4                         = ", 13 
              byte      "Calibration Coefficient 5                         = ", 13 
              byte      "Calibration Coefficient 6                         = ", 13
              byte      "Data Word 1 (Pressure)                            = ", 13
              byte      "Data Word 2 (Temperature)                         = ", 13
              byte      "Calibrated Temperature (0.1 degrees C accuracy)   = ", 13
              byte      "Calibrated Pressure    (0.1 milliBar accuracy)    = ", 13
              byte      "***************************************************************", 13, 0
          
                        

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