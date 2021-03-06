{{
***************************************************************
*  Demo for Debug_Cog v1.1                                    *
*  Author: Brandon Nimon                                      *
*  Copyright (c) 2008 Parallax, Inc.                          *
*  See end of file for terms of use.                          *
***************************************************************
}}
CON

  _CLKMODE      = XTAL1 + PLL16X                     ' 80MHz clock (for 19200 baud)
  _XINFREQ      = 5_000_000                          ' 5MHz Crystal

OBJ

  DEBUG : "Debug_Cog"                                ' load Debug_Cog object completed in only      45,442 cycles
  'DEBUG : "Debug_Cog10"                              ' Debug_Cog version 1.0, faster, but still 1,472,048 cycles
  'DEBUG : "Debug_Lcd"                                ' Debug_Lcd object took                    2,363,072 cycles

PUB Main | start, end
  DEBUG.init(0, 19200, 4)                            ' 4 line LCD on pin 0 at 19200 baud

  start := cnt                                       ' start time
  DEBUG.cls                                          ' clear screen
  DEBUG.str(string("1234567890abcdefgjh"))
  DEBUG.putc($0D)                                    
  DEBUG.str(string("1234567890abcdefgjh"))
  end := cnt                                         ' end time

  DEBUG.cr                                           ' alternate carriage return: putc($0D)
  DEBUG.dec(end - start)                             ' display cycles taken in above debugging

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