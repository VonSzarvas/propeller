
{{program NCOburst.spin v1.0
author, Tracy Allen, 1/5/2011, 2/3/2011, 7/30/11 formatted for OBEX
 -- http://forums.parallax.com/showthread.php?128408  posts 73, 77, 100
 -- incorporates suggestions from Kuroneko
Generates burst of pulses, a certain number at a certain frequency.   Uses cog counters, from Spin.
Frequency can range from 1 Hertz up to 39.999999 MHz, burst length up to 26+ seconds. (at clkfreq = 80MHz, 2^31 cycles)
The companion demo program allows the frequency within burst and the number of pulses to be entered at the debug terminal.

Example uses:
 -- Generate a number of led pulses as a helpful indicator of status.
 -- Generate a burst of 40kHz for an ultrasonic transducer.
 -- Generate a burst with a certain number of pulses to move a stepper motor or actuator a desired distance.
    e.g. 57 pulses at 3 MHz to drive a stepper motor 57 steps
 -- Generate up/down pulses to set a digital potentiometer
 -- Generate a burst to refresh a high voltage in a DC to DC conversion scheme.
 -- Generate laser pulses for a sensor or communication scheme.
 -- Generate a radio frequency blip
All from Spin

Uses both ctra and ctrb in one cog to address a single output pin. The overlap creates the burst.
The two counters are in wired OR due to the Propeller hardware.

....  ctra at Fx
....  ctrb phase backed up an exact number of cycles

combined by Prop wired OR:
.....  output Nx pulses at frequency Fx
   xxxxxxxxxxxxxxxxxxxoooooooooo.....     
 start    run time       lax time about 25 seconds at clkfreq=80MHz, reset or re-trigger before then

Note that the pulses are always active low.

The supervising program can leave the counters to run autonomously during the run and lax time,
but has to come back to stop the process or re-trigger before ctrb goes low again at a 26+ second repeat rate.
Note also that the burst of pulses cannot last more than 26 seconds (exact is 26.8435456 seconds (2^31 / 80MHz) at 80MHz clkfreq.

The "make" method does it all, inits the pins, does the math, executes the burst, and suppresses an further burst.
It does not return until finished.
If the same burst is to be done repeatedly, then initialize the individual parts, "init" and "math", and  repeat
only the "execute" method to generate subsequent bursts with the same parameters.
The execute method does not block.  It returns immediately as the burst starts.
The repeat or stop must occur within 26 seconds (2^31 clock cycles).  When finished, use the "suppress" or "stop" method.

Other enhancements.
 -- An unused counter in another cog can be configured as an inverter, to give the complement, that is pulse high
   to complement pulse low.

}}

VAR
  long fa, pb
  byte bpin

PUB make(pin,Fx,Nx)   ' makes a burst on the given pin at frequency Fx and Nx number of pulses.
  init(pin)                     ' starts the counters, does not start the burst, pin is high
  math(Fx,Nx)                   ' computes the angular frequency corresponding to Fx and phase delay corresponding to Nx
  execute                       ' this actually generates the pulse stream
  repeat until phsb>>31         ' block until burst is finished.
  suppress                      ' surpress burst
  stop                     ' stop the counters on pin

PUB  init(pin)                  ' starts the counters, does not start burst, pin is high
  bpin := pin
  outa[pin]~~
  dira[pin]~~
  ctra := constant(%00100 << 26) + pin                ' this will be the high frequency output within the burst
  ctrb := constant(%00100 << 26) + pin                  ' this will be the blanking pulse, both cntr's to same pin
  suppress
  outa[pin]~             ' allow ctrs to control the pin, counters are primed but not running (both frqx=0, both pin outputs


PUB  math(Fx, Nx)               ' computes the angular frequency corresponding to Fx and phase delay corresponding to Nx
  fa := binNormal(Fx, clkfreq, 32, 0)
  pb := negx - 400 - ((clkfreq / Fx * Nx) + (binNormal(clkfreq // Fx, Fx, 31, 1) ** (Nx*2)))

{
  --Note, This computes Nx * clkfreq / Fx, the number of Prop clock cycles in a burst of Nx * Fx pulses.
    plus an additional 400 clock pulses to account for setting the frqa := fa.   This all is subtracted from
    negx to leave phsb(31) low for the exact number of cycles needed to generate the burst of Nx pulses at frequency Fx.
 -- note from Kuroneko, alternatively use Phil Pilgrim's umath.spin http://obex.parallax.com/objects/415/
     pb := negx - 400 - umath.multdiv(clkfreq,myBurstN,myHertz)
  -- Caveat: the resulting number of clock cycles has to be less than 2^31.  26.8435456 seconds when clkfreq=80MHz.
     E.g., 26 pulses at 1 Hz, but not 27, because 27 would take more than 26.84 seconds.
 }

PUB  execute                    ' execute the burst, or re-execute the same burst.
  phsb := pb
  frqb := 1
  frqa := fa

PUB suppress                    ' stops advance of the counters, otherwise, the burst will repeat after about  ~26 second lax time
  frqa~
  frqb~
  phsa := -1
  phsb := -1

PUB stop                       ' stops counters completely and makes the bpin a high output.  Need to init before stop.
  suppress
  outa[bpin]~~
  ctra~
  ctrb~

PUB binNormal(y, x, b, r) : f                  ' calculate f = y/x * 2^b, round off iff r=1, truncate if r=0
' b is number of bits
' enter with y,x: {x > y, x < 2^31, y <= 2^31}
' exit with f: f/(2^b) =<  y/x =< (f+1) / (2^b)
' that is, f / 2^b is the closest appoximation to y / x.
  f~
  repeat b
    y <<= 1
    f <<= 1
    if y => x    '
      y -= x
      f++
  if r == 1 and (y << 1) => x   ' round off if r=1, otherwise truncate
    f++

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

