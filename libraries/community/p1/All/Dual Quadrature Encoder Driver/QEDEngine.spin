{{
┌─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐               
│ Quadrature Encoder Engine                                                                                                   │
│                                                                                                                             │
│ Author: Kwabena W. Agyeman                                                                                                  │                              
│ Updated: 2/28/2010                                                                                                          │
│ Designed For: P8X32A - No Port B.                                                                                           │
│                                                                                                                             │
│ Copyright (c) 2010 Kwabena W. Agyeman                                                                                       │              
│ See end of file for terms of use.                                                                                           │               
│                                                                                                                             │
│ Driver Info:                                                                                                                │
│                                                                                                                             │ 
│ The driver is only guaranteed and tested to work at an 80Mhz system clock or higher.                                        │
│ Also this driver uses constants defined below to setup pin input and output ports.                                          │
│                                                                                                                             │
│ Additionally the driver spin function library is designed to be acessed by only one spin interpreter at a time.             │
│ To acess the driver with multiple spin interpreters at a time use hub locks to assure reliability.                          │
│                                                                                                                             │
│ Finally the driver is designed to be included only once in the object tree.                                                 │  
│ Multiple copies of this object require multiple copies of the source code.                                                  │
│                                                                                                                             │
│ Nyamekye,                                                                                                                   │
└─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘ 
}}

CON                     
                      ''
  Encoder_A_Pin_A = 4 '' ─ Quadrature encoder A channel A active high input.
                      ''
  Encoder_A_Pin_B = 5 '' ─ Quadrature encoder A channel B active high input. 
                      ''
  Encoder_B_Pin_A = 6 '' ─ Quadrature encoder B channel A active high input. 
                      ''
  Encoder_B_Pin_B = 7 '' ─ Quadrature encoder B channel B active high input.

  Encoder_Frequency = 100_000 ' Maximum ticks per second. Adjusting this value does nothing. It is here for reference.

VAR

  long channelADeltaTicks
  long channelBDeltaTicks

  long channelATickFrequency
  long channelBTickFrequency

PUB getDeltaA '' 3 Stack Longs

'' ┌──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
'' │ Returns the currently accumulated position delta since the last call.                                                    │
'' │                                                                                                                          │
'' │ Ticks relate to the number of "ticks" on the wheel of the encoder disk.                                                  │
'' └──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘

  return channelADeltaTicks~

PUB getSpeedA '' 3 Stack Longs

'' ┌──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
'' │ Returns the current tick speed per second. This value updates per tick encoder tick. Takes a while to see zero speed.    │
'' │                                                                                                                          │
'' │ This value is recalculated each encoder tick. So it takes a second literally to see when the speed drops to zero.        │
'' └──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘
             
  return (clkfreq / channelATickFrequency)  

PUB getDeltaB '' 3 Stack Longs

'' ┌──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
'' │ Returns the currently accumulated position delta since the last call.                                                    │
'' │                                                                                                                          │
'' │ Ticks relate to the number of "ticks" on the wheel of the encoder disk.                                                  │
'' └──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘

  return channelBDeltaTicks~

PUB getSpeedB '' 3 Stack Longs

'' ┌──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
'' │ Returns the current tick speed per second. This value updates per tick encoder tick. Takes a while to see zero speed.    │
'' │                                                                                                                          │
'' │ This value is recalculated each encoder tick. So it takes a second literally to see when the speed drops to zero.        │
'' └──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘

  return (clkfreq / channelBTickFrequency)

PUB QEDEngine '' 3 Stack Longs

'' ┌──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
'' │ Initializes the quadrature encoder driver to run on a new cog.                                                           │
'' │                                                                                                                          │
'' │ Returns the new cog's ID on sucess or -1 on failure.                                                                     │
'' └──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘

  CHADTAddress := @channelADeltaTicks
  CHATFAddress := @channelATickFrequency 

  CHBDTAddress := @channelBDeltaTicks
  CHBTFAddress := @channelBTickFrequency

  return cognew(@initialization, 0)

DAT

' /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////  
'                       Quadrature Encoder Driver
' /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////  

initialization          mov     ctra,              channelASetup ' Setup counters.
                        mov     ctrb,              channelBSetup '
                        mov     frqa,              #1            '
                        mov     frqb,              #1            '

' //////////////////////Channel A//////////////////////////////////////////////////////////////////////////////////////////////

loop                    cmp     channelADelta,     phsa wz       ' Check for edge and accumulate.                                                                                                          
if_nz                   test    channelADirection, ina wc        ' 

                        mov     channelADelta,     phsa          ' Update delta.

if_nz                   rdlong  buffer,            CHADTAddress  ' Add in delta direction.
if_nz                   sumc    buffer,            #1            '
if_nz                   wrlong  buffer,            CHADTAddress  '

if_nz_and_c             movi    speedAFlip,        #%101001_001  ' Flip mov to neg if direction is negative. 
if_nz_and_nc            movi    speedAFlip,        #%101000_001  '

if_nz                   mov     lockA,             #0            ' Lock down final value to prevent false overflow triggering.
                        tjnz    lockA,             #skip         '

                        mov     buffer,            cnt           ' Get time difference.
                        sub     buffer,            outa          '

if_nz                   mov     outa,              cnt           ' Reset time difference on tick.                       

                        rdlong  counter,           #0            ' Check if difference greater than clock freqeuncy.
                        cmp     buffer,            counter wc    '

if_nc                   neg     lockA,             #1            ' Set false trigger lock.
            
speedAFlip if_nz_or_nc  mov     buffer,            buffer        ' Update final value.                       
if_nz_or_nc             wrlong  buffer,            CHATFAddress  '

' //////////////////////Channel B//////////////////////////////////////////////////////////////////////////////////////////////
   
skip                    cmp     channelBDelta,     phsb wz       ' Check for edge and accumulate.                                                                                                          
if_nz                   test    channelBDirection, ina wc        ' 

                        mov     channelBDelta,     phsb          ' Update delta.
 
if_nz                   rdlong  buffer,            CHBDTAddress  ' Add in delta direction.
if_nz                   sumc    buffer,            #1            '
if_nz                   wrlong  buffer,            CHBDTAddress  '

if_nz_and_c             movi    speedBFlip,        #%101001_001  ' Flip mov to neg if direction is negative. 
if_nz_and_nc            movi    speedBFlip,        #%101000_001  '

if_nz                   mov     lockB,             #0            ' Lock down final value to prevent false overflow triggering.
                        tjnz    lockB,             #loop         '

                        mov     buffer,            cnt           ' Get time difference.
                        sub     buffer,            outb          '

if_nz                   mov     outb,              cnt           ' Reset time difference on tick.                       

                        rdlong  counter,           #0            ' Check if difference greater than clock freqeuncy.
                        cmp     buffer,            counter wc    '

if_nc                   neg     lockB,             #1            ' Set false trigger lock.

speedBFlip if_nz_or_nc  mov     buffer,            buffer        ' Update final value.                       
if_nz_or_nc             wrlong  buffer,            CHBTFAddress  '
                                                                      
                        jmp     #loop                            ' Loop.
                        
' ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////// 
'                       Data
' ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////// 

channelADelta           long    0
channelBDelta           long    0

' //////////////////////Configuration//////////////////////////////////////////////////////////////////////////////////////////

channelASetup           long    ((%01010 << 26) + ((Encoder_A_Pin_A <# 31) #> 0)) ' Counter edge detection setup.           
channelBSetup           long    ((%01010 << 26) + ((Encoder_B_Pin_A <# 31) #> 0)) ' Counter edge detection setup.

' //////////////////////Pins///////////////////////////////////////////////////////////////////////////////////////////////////

ChannelADirection       long    (|<((Encoder_A_Pin_B <# 31) #> 0)) ' Pin to sample to determine direction.
ChannelBDirection       long    (|<((Encoder_B_Pin_B <# 31) #> 0)) ' Pin to sample to determine direction.

' //////////////////////Addresses//////////////////////////////////////////////////////////////////////////////////////////////
 
CHADTAddress            long    0
CHATFAddress            long    0
CHBDTAddress            long    0
CHBTFAddress            long    0

' //////////////////////Run Time Variables/////////////////////////////////////////////////////////////////////////////////////

buffer                  res     1
counter                 res     1

lockA                   res     1
lockB                   res     1

{{

┌─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│                                                   TERMS OF USE: MIT License                                                 │                                                            
├─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation   │ 
│files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy,   │
│modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the        │
│Software is furnished to do so, subject to the following conditions:                                                         │         
│                                                                                                                             │
│The above copyright notice and this permission notice shall be included in all copies or substantial portions of the         │
│Software.                                                                                                                    │
│                                                                                                                             │
│THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE         │
│WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR        │
│COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,  │
│ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.                        │
└─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘
}}                           