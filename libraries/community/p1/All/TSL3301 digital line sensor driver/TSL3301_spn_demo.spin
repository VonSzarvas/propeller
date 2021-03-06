CON

  _clkmode = xtal1 + pll16x
  _xinfreq = 5_000_000

  
obj

  serial : "fullduplexserial.spin"
  tsl3301: "TSL3301_driver_spn_v1"

var
  long data_new_flg   'set to true when new data is written from ASM.
  byte line_data[102] 'byte array containing line data


pub main | C1, C2, idx, integration_time
{{ Simplest code to get lines from the TSL3301.
Just have it setup the chip and stream lines to the PC over the serial port.
This is a line by line translation of the code in the TAOS app-note.}}

  serial.start(31,30,0,115200) 'start up my serial port over the programming port
  
  integration_time := 80_000           '[clocks] set how long the electronic shutter will stay open.                       
  integration_time #>= (clkfreq/1000)  'Spin is slow, hence the 1mS minimum time 
  
  'show signs of life
  waitcnt(clkfreq*2 + cnt)      'pause untill PST is ready
  serial.str(string("line camera communication demo V0.1"))
  serial.tx($0D)                'carrage return in ASCII

  'setup TSL3301
  tsl3301.init                          'setup pins and variable of my code
  serial.str(string("init, "))
  tsl3301.reset                         'reset the TSL3301 to a known state
  serial.str(string("reset, "))
  tsl3301.set_gains(-15,0)              'set gain and offset of on-chip amplifiers
  serial.str(string("gains, "))

  'continuously read lines
  repeat                        
    C1 := cnt + 3000              'record the system counter
    C2 := C1 + integration_time       '1/1000th of a second is the shortest integration time this code can do.  
    waitcnt(C1)                   'wait for a known time
    tsl3301.start_int                     'start integrating photons
    waitcnt(C2)                   'wait for the stop time
    tsl3301.stop_int                      'stop integrating photons
    serial.str(string("ended integration, "))
    tsl3301.start_read                    'start the readout of pixels
    tsl3301.read_pix(@line_data)          'read the pixel data into my byte array
    'format and send the line back to the PC
    serial.str(string("sending a line"))
    serial.tx($0D)
    repeat idx from 0 to 101
      serial.dec(line_data[idx])  'output a pixel value
      serial.tx(",")              'comma
    serial.tx($0D)                'carrage return
    waitcnt(cnt+clkfreq/4)          'wait before next line

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