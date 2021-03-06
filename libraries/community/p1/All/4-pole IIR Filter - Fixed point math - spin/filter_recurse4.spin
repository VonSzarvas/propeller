{{ recurse4.spin
┌─────────────────────────────────────┬────────────────┬─────────────────────┬───────────────┐
│ IIR 4-Element Recursive Filter v0.6 │ BR             │ (C)2009             │  4 Dec 2009   │
├─────────────────────────────────────┴────────────────┴─────────────────────┴───────────────┤
│ A 4-element infinite impulse response (IIR) digital filter with recursion,                 │
│ implemented in spin.   Also includes various supporting filter synthesis functions.        │
│ All calculations use integer math for speed.                                               │
│                                                                                            │
│ Recommended reading if you want to understand how this filter works: www.dspguide.com      │
│                                                                                            │
│ USAGE:                                                                                     │
│    filtered_msmnt_out := <filter_obj_name>.recurse4(raw_msmnt_in)                          │
│                                                                                            │
│    where: raw_msmnt_in       = the raw data to be filtered                                 │
│           filtername         = method name, e.g.: "ma4", "conv16", "kalman1", etc.         │
│           filter_obj_name    = instance name of this object                                │
│           filtered_msmnt_out = filtered output                                             │
│                                                                                            │
│ NOTES:                                                                                     │
│ •As presently implemented, this filter is best suited for low-to-moderate bandwidth        │
│  filtering applications (e.g. filtering accelerometer or Ping))) data).                    │
│ •The recurse4 filter requires the user to synthesize filter coefficients via the synth     │
│  functions provided in this object or by some independent means.                           │
│ •No integer overflow/underflow detection logic is provided.  It is up to the user to       │
│  ensure that filter kernels and filter data input are scaled appropriately.                │
│                                                                                            │
│ See end of file for terms of use.                                                          │
└────────────────────────────────────────────────────────────────────────────────────────────┘
}}
'FIXME: convert filter algorithms to use fixed point math...Ale: propwiki/math/fixed point
'FIXME: ...or provide some means of autoscaling the input
'FIXME: add integer overflow/underflow detection...how to check flags in spin?
'FIXME: add support for 64 bit integer in accumulator


pub recurse4(x_meas):x_rtn | i
''4-element IIR recursive filter. See www.dspguide.com, chapter 19
''Max filter update rate ~2000 samples/sec for 1 cog @ clkfreq=80

  ptr &= %00000011                         'mask off all but lower four bits
  x_buf4[ptr] := x_meas
  sum := 0
  repeat i from 0 to 3
    sum += a[i] * x_buf4[(ptr - i) & %00000011]
  repeat i from 0 to 2
    sum += b[i] * y_buf4[(ptr - i-1) & %00000011]
  x_rtn := y_buf4[ptr] := sum / recurse_norm
  ptr++


pub synth_low_pass(x,iscale)
''Synthesizes a single pole low-pass filter for use with recurse4.
''Input argument x, is the amount of decay between adjacent filter samples.
'It is related to the time constant of the filter as: x = exp(-1/d) where d
'the number of samples for the filter to decay to 38.6% of its steady state
'value.   In other words, d is the DSP equivalent of RC in an RC circuit.
'x is related to filter cutoff frequency as: x= exp(-2π*fc), fc = cutoff freq.
'expressed as a fraction of sampling frequency, where 0 <= fc <= 0.5.
'Input argument iscale is a scaling coefficient.        If this filter were
'implemented using floatmath, x would normally be limited to 0 <= x <= 1.
'iscale scales x such that it is expressed as a fraction of iscale.
'For example, x= 64, iscale=128 implies an effective x of 0.5.
'See www.dspguide.com, chapter 19 for more info.
'
'Typical values for a single pole low pass filter:
'# samples per   │  damping, │  (iscale=255)
'time constant   │  exp(-1/d)│    x      b1     a0
'       1        │   0.368   │   94      94    161
'       2        │   0.607   │  155     155    100
'       4        │   0.779   │  199     199     56
'       8        │   0.882   │  225     225     30
'      16        │   0.939   │  240     240     15
'      24        │   0.959   │  245     245     10
'      32        │   0.969   │  247     247      8
'
'The analog equivalent of this filter is:
'        filt_in ─────┳──── filt_out
'                   R     C
'                        

  b[0] := x
  a[0] := iscale - x
  b[1] := b[2] := b[3] := 0
  a[1] := a[2] := a[3] := 0
  recurse_norm := iscale
  return @a                            'return a pointer to filter coefficients

                                   
pub synth_high_pass(x,iscale)
''Synthesizes a single pole high-pass filter for use with recurse4.
''Input argument x, is the amount of decay between adjacent filter samples.
'The analog equivalent of this filter is:
'        filt_in ─────┳──── filt_out
'                   C    R
'                       
'See synth_low_pass for more info.

  b[0] := x
  a[0] := (iscale + x) / 2
  a[1] := -a[0]
  b[1] := b[2] := b[3] := 0
  a[2] := a[3] := 0
  recurse_norm := iscale
  return @a                            'return a pointer to filter coefficients

                                   
pub synth_band_stop(x,iscale, f, bw)|dum1,dum2
''Synthesizes a band-stop filter for use with recurse4.  x, is the amount of decay
''between adjacent filter samples, where typically 0 <= x <= 1 in floatmath. f is
''band stop center frequency, bw is band stop bandwidth. f, and bw are all relative 
''to the sampling frequency, fs, and therefore 0 <= f,bw <= 0.5. iscale is a      
''scaling parameter on x, f, and bw. E.G. for x = 0.5, use x = 50 and iscale = 100.
''To get f = 0.25*fs, use f=25.  For bw=0.1*fs, use bw=10, etc.         
'See www.dspguide.com, chapter 19 for more info.

  dum1 := iscale - 3 * bw
  dum2 := iscale * iscale - 2 * dum1 * cos(360*f/iscale, iscale) + dum1 * dum1
  dum2 /= (2 * iscale - 2 * cos(360*f/iscale, iscale))
  a[0] := dum2 * iscale
  a[1] := -2 * dum2 * cos(360*f/iscale, iscale)
  a[2] := dum2 * iscale
  a[3] := 0
  b[0] := 2 * dum1 * cos(360*f/iscale, iscale)
  b[1] := -dum1 * dum1
  b[2] := b[3] := 0
  recurse_norm := iscale * iscale
  return @a                            


pub synth_band_pass(x,iscale, f, bw)|dum1,dum2
''Synthesizes a band-pass filter for use with recurse4.  x, is the amount of decay
''between adjacent filter samples, where typically 0 <= x <= 1 in floatmath. f is
''band pass center frequency, bw is band pass bandwidth. f, and bw are all relative 
''to the sampling frequency, fs, and therefore 0 <= f,bw <= 0.5. iscale is a      
''scaling parameter on x, f, and bw. E.G. for x = 0.5, use x = 50 and iscale = 100.
''To get f = 0.25*fs, use f=25.  For bw=0.1*fs, use bw=10, etc.         
'See www.dspguide.com, chapter 19 for more info.

  dum1 := iscale - 3 * bw
  dum2 := iscale * iscale - 2 * dum1 * cos(360*f/iscale, iscale) + dum1 * dum1
  dum2 /= (2 * iscale - 2 * cos(360*f/iscale, iscale))
  a[0] := (iscale - dum2) * iscale
  a[1] := 2 * (dum2 - dum1) * cos(360*f/iscale, iscale)
  a[2] := dum1 * dum1 - dum2 * iscale
  a[3] := 0
  b[0] := 2 * dum1 * cos(360*f/iscale, iscale)
  b[1] := -dum1 * dum1
  b[2] := b[3] := 0
  recurse_norm := iscale * iscale
  return @a                            


pub synth_fslp(x,iscale)
''Synthesizes a four stage low-pass filter for use with recurse4.
''Input argument x, is the amount of decay between adjacent filter samples.
'See synth_low_pass for more info.
'FIXME: this filter is very sensitive to startup transients and also seems
'to be prone to instability for values of x/iscale > 0.4 or so.
'Probably better if implemented using floatmath.

  b[0] := 4 * x * iscale * iscale * iscale
  b[1] := -6 * x * x * iscale * iscale
  b[2] := 4 * x * x * x * iscale
  b[3] := -x * x * x * x
  a[0] := (iscale - x) * (iscale - x) * (iscale - x) * (iscale - x)
  a[1] := a[2] := a[3] := 0
  recurse_norm := iscale * iscale * iscale * iscale
  return @a                            


PUB sin(degree, mag) : s | c,z,angle
''Returns scaled sine of an angle: rtn = mag * sin(degree)
'Function courtesy of forum member Ariba
'http://forums.parallax.com/forums/default.aspx?f=25&m=268690

  angle //= 360
  angle := (degree*91)~>2 ' *22.75
  c := angle & $800
  z := angle & $1000
  if c
    angle := -angle
  angle |= $E000>>1
  angle <<= 1
  s := word[angle]
  if z
    s := -s
  return (s*mag)~>16       ' return sin = -range..+range


pub cos(degree, mag) : s
''Returns scaled cosine of an angle: rtn = mag * cos(degree)

  return sin(degree+90,mag)

  
dat                                
'-----------[ Predefined variables and constants ]-----------------------------
x_buf4         long      0,0,0,0           '4-place filter input history buffer
sum            long      0                 'accumulator
ptr            byte      0                 'pointer (set up as ring buffer)
a              long      28,0,0,0          'recurse4 filter coefficients a[0], a[1],...
b              long      99,0,0,0          'recurse4 filter coefficients b[1], b[2],...
y_buf4         long      0,0,0,0           'recurse4 filter output history buffer
recurse_norm   long      127               'scale factor applied to filter coefficients


DAT

{{

┌─────────────────────────────────────────────────────────────────────────────────────────────────────┐
│                                     TERMS OF USE: MIT License                                       │                                                            
├─────────────────────────────────────────────────────────────────────────────────────────────────────┤
│Permission is hereby granted, free of charge, to any person obtaining a copy of this software and    │
│associated documentation files (the "Software"), to deal in the Software without restriction,        │
│including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense,│
│and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so,│
│subject to the following conditions:                                                                 │
│                                                                                                     │                        │
│The above copyright notice and this permission notice shall be included in all copies or substantial │
│portions of the Software.                                                                            │
│                                                                                                     │                        │
│THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT│
│LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  │
│IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER         │
│LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION│
│WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.                                      │
└─────────────────────────────────────────────────────────────────────────────────────────────────────┘
}}  