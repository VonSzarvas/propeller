{{
┌──────────────────────────────────────────────────────────┐
│ Nintendo Game Boy Printer                                │
│ Interface Object                                         │
│                                                          │
│ Author: Joe Grand                                        │
│ Copyright (c) 2011 Grand Idea Studio, Inc.               │
│ Web: http://www.grandideastudio.com                      │ 
│                                                          │
│ Distributed under a Creative Commons                     │
│ Attribution 3.0 United States license                    │
│ http://creativecommons.org/licenses/by/3.0/us/           │
└──────────────────────────────────────────────────────────┘

Program Description:

This object provides the communication interface to a Nintendo Game Boy Printer.

The object is inspired by furrtek's GBLink/PC interface project
(http://furrtek.free.fr/index.php?p=crea&a=gbpcable&i=2) and Reversing the Game Boy
Printer page (http://furrtek.free.fr/index.php?p=crea&a=gbprinter).

The SIN pin (serial input TO Propeller) must be pulled up to VCC via a 15k resistor.
Refer to the LRFCam project on Grand Idea Studio's Laser Range Finder page
(http://www.grandideastudio.com/portfolio/laser-range-finder/) for a hardware
connection example.   
  

Revisions:
1.0 (November 30, 2011): Initial release
 
}}


CON
  ' SPI configuration
'  SPIClockDelay   = 9           ' Clock delay (set for Gameboy serial transmit speed of ~120uS/bit) @ 80MHz Propeller clock
  SPIClockDelay   = 8           '                                                                   @ 96MHz Propeller clock 
  SPIClockState   = 1           ' Initial clock state (HIGH or LOW)
  
  
VAR
  long  inPin                   ' SPI master interface, IN from Gameboy printer (GBP)
  long  outPin                  '                       OUT to printer
  long  clkPin                  '                       CLOCK to printer

  
OBJ
  spi           : "SPI_Spin"    ' SPI engine (written in Spin) (Beau Schwabe, http://obex.parallax.com/objects/433/)


PUB start(in, out, clk)         ' Configure object
  inPin := in                   ' Set SPI pins
  outPin := out
  clkPin := clk
  
  SPI.start(SPIClockDelay, SPIClockState) ' Initialize SPI engine


PUB printbuffer(bufptr, num) : err | data, index
  ' bufptr = pointer to buffer that contains image data
  ' num = number of 640-byte chunks of image data that need to be passed to the GBP = sizeof(bufptr) / 640
   
  if init                   ' Initialize Game Boy Printer
    return true
                                
  repeat index from 0 to (num - 1) 
    if imagetransfer(bufptr + (index * 640))  ' Transfer image data to GBP (640 bytes at a time)
      return true
    
  if emptypacket            ' Send empty data packet
    return true
    
  if print                  ' Print
    return true

  ' Wait until the print starts
  repeat 
    waitcnt(clkfreq / 10 + cnt)  ' 100ms delay
  until (status & $02)

  ' Wait until the print is complete
  repeat 
    waitcnt(clkfreq / 10 + cnt)  ' 100ms delay
  while (status & $02) 


PRI init : err | data           ' Initialize Game Boy Printer
  serialout($88)                ' Header (16 bits)
  serialout($33)             
  serialout($01)                ' Command: Initialize
  serialout($00)                ' Argument: None
  serialout($00)                ' Length (16 bits: LSB, MSB)
  serialout($00)
  serialout($01)                ' Checksum (16 bits: LSB, MSB)
  serialout($00)
  
  data := serialin
  serialin  
  if (data <> $81)              ' Check for a valid response from the Game Boy Printer
    err := 1                    ' If not, error

    
PRI imagetransfer(bufptr) : err | index, data, CRC      ' Transfer image data to GBP
  ' GBP horizontal resolution of 160 pixels @ 2 bit/pixel greyscale
  ' Each tile = 8 pixels * 8 pixels 
  ' 20 tiles horizontal per band
  ' 2 bands per buffer
  ' => 640 bytes to the GBP in a single call
                                
  serialout($88)                ' Header (16 bits)
  serialout($33)             
  serialout($04)                ' Command: Image transfer
  serialout($00)                ' Argument: None
  serialout($80)                ' Length (16 bits: LSB, MSB) = 0x0280 (640 bytes)
  serialout($02)
  CRC := $86                    ' Current CRC value (Command + Argument + Length) before adding variable data 

  repeat index from 0 to 639
    data := BYTE[bufptr][index]
    serialout(data)             ' Send byte to printer
    CRC += data                 ' Update checksum

  serialout(CRC.BYTE[0])        ' Checksum (16 bits: LSB, MSB)
  serialout(CRC.BYTE[1])  
  
  data := serialin
  serialin  
  if (data <> $81)              ' Check for a valid response from the Game Boy Printer
    err := 1                    ' If not, error

    
PRI emptypacket : err | data    ' Send Empty Data Packet
  serialout($88)                ' Header (16 bits)
  serialout($33)             
  serialout($04)                ' Command: Image transfer
  serialout($00)                ' Argument: None
  serialout($00)                ' Length (16 bits: LSB, MSB)
  serialout($00)
  serialout($04)                ' Checksum (16 bits: LSB, MSB)
  serialout($00) 

  serialin
  data := serialin

  ifnot (data & $08)            ' Check if Game Boy Printer is ready to print
    err := 1                    ' If not, error


PRI print : err | data          ' Print
  serialout($88)                ' Header (16 bits)
  serialout($33)             
  serialout($02)                ' Command: Start printing
  serialout($00)                ' Argument: None
  serialout($04)                ' Length (16 bits: LSB, MSB)
  serialout($00)
  serialout($01)                ' Data:
  serialout($13)                ' Margins (1 nibble before, 3 after)
  serialout($E4)                ' Palette (11100100: Black, Dark, Light, White)
  serialout($40)                ' Exposure (7 bits), 64 / 128 = 50%
  serialout($3E)                ' Checksum (16 bits: LSB, MSB)
  serialout($01) 

  data := serialin
  serialin  
  if (data <> $81)              ' Check for a valid response from the Game Boy Printer
    err := 1                    ' If not, error

  
PRI status : data               ' Get Game Boy Printer Status
  '  Bit 7               Bit 6        Bit 5    Bit 4              Bit 3             Bit 2              Bit 1            Bit 0
  '  Too hot or cold?    Paper Jam    ?        Voltage too low    Ready to print    Print requested    Current print    Bad checksum
  serialout($88)             ' Header (16 bits)
  serialout($33)             
  serialout($0F)                ' Command: Read status
  serialout($00)                ' Argument: None
  serialout($00)                ' Length (16 bits: LSB, MSB)
  serialout($00) 
  serialout($0F)                ' Checksum (16 bits: LSB, MSB)
  serialout($00)   

  serialin
  data := serialin

  
PRI serialout(data)       ' send byte to Gameboy Printer
  spi.shiftout(outPin, clkPin, spi#MSBFIRST, 8, data) ' send 8 bits of data

  
PRI serialin | data       ' receive byte from Gameboy Printer
  data := spi.shiftin(inPin, clkPin, spi#MSBPOST, 8)  ' receive 8 bits of data ($00 is sent on output pin)
  return data

      