{{

Autodatalogger test.

Uses a serial connection to the computer to provide current status.

SRLM 2009

}}

CON
    _clkmode = xtal1 + pll16x                           
    _xinfreq = 5_000_000

    rxpin       = 7             'Receive pin on the Propeller
    txpin       = 8             'Transmit pin on the Propeller
    ctspin      = 9

OBJ
  USB   :       "Autodatalogger"
  Debug :       "FullDuplexSerialPlus"

VAR
  long filenameaddr
  long num0, num1, num2, num3, num4, num5, num6, num7, num8, num9
  long num10, num11, num12, num13, num14, num15, num16, num17, num18, num19
PUB Main

  filenameaddr := string("samples.txt")
  num1 := num2 := num3 := 0


  

  debug.start(31, 30, 0, 57600)
  waitcnt(clkfreq*6 + cnt)

  debug.str(string("AutoDatalogger Test"))
  debug.tx(13)

  waitcnt(clkfreq*2 + cnt)
  debug.str(string("Starting test..."))  '}

  USB.init(rxpin, txpin, ctspin, filenameaddr, 10_000)


  'Set up the number of columns to log
  
  '           (address, digits, title)
  USB.addfield(@num0, 10, string("num0"))

  'Examples of adding more fields
 { USB.addfield(@num1, 10, string("num1"))
  USB.addfield(@num2, 10, string("num2"))
  USB.addfield(@num3, 10, string("num3"))
  USB.addfield(@num4, 10, string("num4"))
  USB.addfield(@num5, 10, string("num5"))
  USB.addfield(@num6, 10, string("num6"))
  USB.addfield(@num7, 10, string("num7"))
  USB.addfield(@num8, 10, string("num8"))
  USB.addfield(@num9, 10, string("num9"))
  USB.addfield(@num10, 10, string("num10"))
  USB.addfield(@num11, 10, string("num11"))
  USB.addfield(@num12, 10, string("num12"))
  USB.addfield(@num13, 10, string("num13"))
  USB.addfield(@num14, 10, string("num14"))
  USB.addfield(@num15, 10, string("num15"))
  USB.addfield(@num16, 10, string("num16"))
  USB.addfield(@num17, 10, string("num17"))
  USB.addfield(@num18, 10, string("num18"))
  USB.addfield(@num19, 10, string("num19"))}
  USB.start

  

  debug.str(string("Logging test data now"))
  debug.tx(13)

  

  repeat num0 from 1 to 20
    num0[num0] := 3_999_999_999

  num0 := cnt 


  'Log samples for some number of minutes
  repeat 1
    debug.tx("m")
    repeat 60                 '1 Minute
      debug.tx(".")
      waitcnt(num0 += clkfreq)  'Seconds
     
  USB.stop
  debug.str(string("Test Complete"))

  repeat

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