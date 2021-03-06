{ 
********************************************
* ADC838  Analog to Digit Converter        *
* 8-bit, 8-channel         object v1.0     *
* (C) 2006  Jan Balewski                   *
* See end of file for terms of use.        *
********************************************
        

              ┌────────┳──────────DIDO
    ┳────────┼────────┼──┳──┐
  Vcc│     CS │    Busy│  SE │    AGND
     │ free DI CLK   DO │ Vref┌───┐
    ┌┴──┴──┴──┴──┴──┴──┴──┴──┴──┴─┐ │
    │20 19 18 17 16 15 14 13 12 11│ │
     ]           ADC838           │ │
    │1  2  3  4  5  6  7  8  9  10│ │
    └┬──┬──┬──┬──┬──┬──┬──┬──┬───┬┘ │
   ch0  1  2  3  4  5  6  7  └───┻──┻─ GND
                            COM  DGND
CS  - latch pin
CLK - clock pin
DIDI- data  pin used to set ch# & read 8-bit ADC value
Busy - optional output indicating ADC is still converting
ch0..7 - analog inputs to be digitized,
         ground unused inputs

USE:
  adc: "J-ADC838"
  adc.init(CS,clk,DIDA) 'provide pin IDs

  repeat
    val:=adc.read(ch) 'provide channal: 0-7
    ..do whatever ...
Note,
tested only @ 80 MHz, ADC clock frequency reduced by 'del'
}
con
  del=4_000 ' 50µs ==>x2=10kHz  @ 80MHz speed
  adrLen=5

var
  byte pCS,pCLK,pDIDA 'assign pins
  
pub init(CS,clk,dida) 'return error code
  pCS:=CS     
  pCLK:=clk
  pDIDA:=DIDA
  'check range of pins [0..31]
  if pCS&!$1f
    return -1
  if pCLK&!$1f
    return -2
  if pDIDA&!$1f
    return -3    

  'set output pins  
  dira[pCS]   := 1  
  dira[pDIDA] := 1  
  dira[pCLK]  := 1  

  outa[pCS]  := 1 'lock ADC  
  return 0
                
pub read(chan): adcVal |adr,temp 
  if pCS==pDIDA  'verify pins were assigned in ::init() 
    abort

  'prepare to sent the chan address to ADC838
  dira[pDIDA] := 1 'prepare to write address
  outa[pCLK] := 0  'set clk low
  outa[pCS]  := 1   'Bring CS high
  waitcnt(del + cnt) ' wait t_set-up   
  outa[pCS]  := 0     'enable ADC

  'convert chan# to MUXaddress
  adr:=%11000
  adr+=(chan//2)<<2
  adr+=(chan/2)&%11

  'sent address  MSB first                   
  temp := 1 << ( adrLen - 1 )
  repeat adrLen
      outa[pDIDA] := (adr & temp)/temp   'Set bit value
    waitcnt(del + cnt) ' wait half period
      outa[pCLK] := 1                    'Clock bit
    waitcnt(del + cnt) ' wait half period
    outa[pCLK] := 0                    'Clock bit
    temp := temp / 2

  'digitize & read value: MSB FIRTS
  dira[pDIDA] := 0 'switch to read mode  
  adcVal:=0 ' default                                               
  waitcnt(del + cnt)  '???

  REPEAT 8                                         ' for number of bits                    
    outa[pCLK] := 1                    'Clock bit
    waitcnt(del + cnt)  '???
    outa[pCLK] := 0                    'Clock bit
    waitcnt(del + cnt)  '??? 
    temp:= ina[pDIDA]                 
                                  ' get bit value                          
    adcVal := (adcVal << 1) + temp                  ' Add to  value shifted by position                                         
    
  outa[pCS]  := 1   'Deactivate ADC0838.
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