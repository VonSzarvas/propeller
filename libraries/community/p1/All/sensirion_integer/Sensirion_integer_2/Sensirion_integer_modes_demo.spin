''=============================================================================
'' @file     sensirion_integer_modes_demo.spin
'' @target   Propeller with Sensirion SHT1x or SHT7x   (not SHT2x)
'' @author   Thomas Tracy Allen, EME Systems
'' Copyright (c) 2013 EME Systems LLC
'' See end of file for terms of use.
'' version 1.3
'' uses integer math to return values directly in degC*100 and %RH*10
'' and show values on the terminal screen.
'' no floating point required
'' This demo shows how to switch from hi resolution mode to low resolution mode.
'' HiRes is slower than LoRes, and the demo prints out the conversion times in milliseconds.
'' The demo also turns on the heater for a bit to observe its effect on the readings.
''=============================================================================


CON
  _clkmode = xtal1 + pll8x                '
  _xinfreq = 5_000_000

' pins for data and clock.
' Note sht1x and sht7x protocol is like i2c, but not exactly
' Assumes power = 3.3V
  DPIN = 13    ' needs pullup resistor
  CPIN = 14    ' best use pulldown resistor for reliable startup, ~100k okay.


OBJ
  pst : "parallax serial terminal"
  sht : "sensirion_integer"

PUB Demo | ticks, tocks
 sht.Init(DPIN, CPIN)
 sht.WriteStatus(0)                                     ' be sure sensor is in the hiRes mode, heater off
 pst.Start(9600)
 waitcnt(clkfreq/10+cnt)
 ticks~                                                 ' this
 pst.str(string(13,10,"starting in hiRes mode, heater off"))

 repeat
   pst.str(string(13,10,"degC: "))
   tocks := cnt
   result := sht.ReadTemperature
   tocks := cnt - tocks
 '  if (result := sht.ReadTemperature) == negx          ' read temperature and trap error
   if result == negx
     pst.str(string("NA"))
   else
     result /= 10                                       ' reduce degC from 1/100ths to tenths of a degree
     pst.dec(result/10)
     pst.char(".")
     pst.dec(||result//10)
   pst.str(string("   mS: "))                           ' temperature conversion time in milliseconds
   pst.dec(tocks/(clkfreq/1000))
   pst.str(string("     %RH: "))
   tocks := cnt
   result := sht.ReadHumidity
   tocks := cnt - tocks
   if result == negx                                    ' get RH and trap error
     pst.str(string("NA"))
   else
     pst.dec(result/10)                                 ' RH is in unit of tenths of a %RH
     pst.char(".")
     pst.dec(||result//10)
   pst.str(string("   mS: "))                           ' RH conversion time in milliseconds
   pst.dec(tocks/(clkfreq/1000))
   if ticks == 5                                        ' change the operating mode at times for illustration
     sht.WriteStatus(%1)
     pst.str(string(13,10,"changing to fast loRes mode"))
   if ticks == 15
     sht.WriteStatus(%101)  ' heater on, loRes
     pst.str(string(13,10,"heater on"))
   if ticks == 30
     sht.WriteStatus(%1)
     pst.str(string(13,10,"heater off"))
   if ticks++ == 40
     sht.WriteStatus(%0)
     pst.str(string(13,10,"finally, changing back to slower hiRes mode"))
   waitcnt(clkfreq+cnt)


' Always read temperature shortly before humidity!   RH temperature compensation depends on valid temperature reading.
' The routines return NEGX if the sensor times out, or if the readings are grossly out of range.
' Due to sensor tolerances, it is still possible to get readings <0 or >100.


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
