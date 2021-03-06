'' File: InjectorOnOffP4Tester80MHz.spin

' Original Author: Miro Kefurt
' Version: 1.2  2017-05-29
' Copyright (c) MIROX Corporation
' www.mirox.us
' mirox@aol.com
' See end of file for Terms of Use.

{{
    This program generates 1.5 millisecond power pulse for one minute at 1,200 RPM to test Automotive Fuel Injectors.
    The P4 is connected to signal input on Injector Driver Module (available from www.okaauto.com)
    When injector is directed to callibrated cylinder the fuel delivery can be tested and the spray pattern can be observed.

}}

CON
_xinfreq = 5_000_000            'external crystal frequency
_clkmode = xtal1 + pll16x       'Set System frequency to 5*16 = 80MHz

VAR
   word InjectorON    ' Time Fuel Injector is ON in Milliseconds*10
   word RPM           ' Rotational Speed in Rotations per Minute
   word RPs           ' Rotational Speed in Rotations per Second 
   word Rt            ' Time for One Crankshaft Revolution in ms*10
   word DelayOFF      ' Time for Injector OFF during one Revolution in ms*10

PUB InjectorOnTest                       ' Method declaration

   InjectorON := 1_5      ' in Milliseconds*10     (1_5 = 1.5 milliseconds) 
   RPM := 1_200           ' Rotations per Minute
   RPs := (RPM/60)        ' Rotations per Second
   Rt := 10_000/RPs       ' Time for One Crankshaft Revolution in ms*10
   DelayOFF := Rt-InjectorON 
   dira[4] := 1           ' Set P4 to output

   repeat  RPM            ' loop for one Minute   
          outa[4] := 1                                 ' Set P4 high (HI=ON)
          waitcnt(((clkfreq/10_000)*InjectorON) + cnt)      ' wait for delay.

          outa[4] := 0                                 ' Set P4 low  LO=OFF)
          waitcnt(((clkfreq/10_000)*DelayOFF) + cnt)     ' wait for delay.

        
DAT

{{

┌──────────────────────────────────────────────────────────────────────────────────────┐
│                           TERMS OF USE: MIT License                                  │                                                            
├──────────────────────────────────────────────────────────────────────────────────────┤
│Permission is hereby granted, free of charge, to any person obtaining a copy of this  │
│software and associated documentation files (the "Software"), to deal in the Software │ 
│without restriction, including without limitation the rights to use, copy, modify,    │
│merge, publish, distribute, sublicense, and/or sell copies of the Software, and to    │
│permit persons to whom the Software is furnished to do so, subject to the following   │
│conditions:                                                                           │                                            │
│                                                                                      │                                               │
│The above copyright notice and this permission notice shall be included in all copies │
│or substantial portions of the Software.                                              │
│                                                                                      │                                                │
│THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,   │
│INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A         │
│PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT    │
│HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION     │
│OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE        │
│SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.                                │
└──────────────────────────────────────────────────────────────────────────────────────┘
}}
        
        