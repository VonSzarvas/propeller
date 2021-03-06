CON                                                                                    
        _clkmode = xtal1 + pll8x       ' BEWARE: my test propeller is overclocked at 96 MHz !!!!!!!!!!!!!!!!!!!!
        _xinfreq = 12_000_000

'        _clkmode = xtal1 + pll16x    
'        _xinfreq = 5_000_000
OBJ
  pst:          "Parallax serial terminal" 
  pulse:        "stretcher"

pub main  | i
   pst.start(115200)

   repeat 4                                             ' give enough time to switch to terminal
    waitcnt(cnt+80000000)
   pst.clear
   pst.str(string("--- we start ---"))
   pst.newline
    
   pst.str(string("negative pin : "))                   ' 
   i := pulse.set(-1,100)
   pst.dec(i)
   pst.newline

   pst.str(string("too high pin : "))
   i := pulse.set(35,100)
   pst.dec(i)
   pst.newline
  
   pst.str(string("negative duration : "))
   i := pulse.set(20,-100)
   pst.dec(i)
   pst.newline
 
   pst.str(string("too high duration : "))
   i := pulse.set(20,$03FFFFFF+1)
   pst.dec(i)
   pst.newline
   
   repeat  
         i := pulse.set(20,500)         ' set pin 20 ON for 500 msec
         i :=pulse.set(21,500)          ' same for pin 21
         waitcnt(8_000_000+cnt)         ' after 100 msec ...
         i := pulse.set(21,0)           ' ... reset pin 21 to OFF
         waitcnt(80_000_000+cnt)        ' and loop after one second more

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