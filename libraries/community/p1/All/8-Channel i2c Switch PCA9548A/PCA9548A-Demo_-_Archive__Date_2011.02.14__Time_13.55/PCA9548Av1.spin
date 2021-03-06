{{
=================================================================================================
  File....... PCA9548Av1 (8-Channel I2C Switch with Reset)
  Purpose.... Propeller to control up to 8 I2C Devices
  Author..... MacTuxLin
                Copyright (c) 2011 
                -- see below for terms of use
  E-mail..... MacTuxLin@gmil.com
  Started.... 30 Jan 2011
  Updated....
        v0.1    1. Needed to connect 5 3AD (MMA7455L) to Prop. Initially got it to work but had to
                sacrifise 10 Prop-pins (Ouch). Found & Gotten samples for this Switch & tested out great!
                Started designing this code for use to comm with 5 accelerometers.
                Using the original Basic_I2C_Driver v1.1 & some from GG's PSB_i2cDriver,
                I've basically just added the comm portion to PCA9548A (PSelect), the rest of the I2C comm to the
                connected devices remains the same.

        v0.2    14 Feb 2011
                1. Add a number of descriptions to the PCA9548A functions
                2. Add more descriptions to the demo

        v1.0    14 Feb 2011
                1. Uploaded to OBEX  
=================================================================================================

                                    Prop
                                     ΔΔ
                 ┌------------┐      ||
       ┌-------A0|1         24|Vcc   | 10k
       |-------A1|2         23|SDA---┘ 10k           <-┐
      Gnd   Reset|3         22|SCL----┘               <--I'm assuming this is not connected to EEPROM/RTC SCL/SDA
              SD0|4         21|A2------┐
              SC0|5         20|SC7    Gnd
              SD1|6         19|SD7
              SC1|7         18|SC6
              SD2|8         17|SD6
              SC2|9         16|SC5
              SD3|10        15|SD5
              SC3|11        14|SC4
              Gnd|12        13|SD4
                 └────────────┘

}}

CON

  '*** *** *** *** PLEASE TAKE NOTE *** *** *** ***  
  '*** Please change the value to your setup
  '*** *** *** *** PLEASE TAKE NOTE *** *** *** ***  
  _PCA9548A_SCL = 26   'SCL
  _PCA9548A_SDA = 27   'SDA (must be increment of SCL            
  _PCA9548A_Rst = 25   'Reset line, Usually is High, 
  _totI2CDevices = 5

   _addPCA9548A = $70           'Address of PCA9548A - Hardwired A0, A1, A2
                                'Refer to datasheet, fixed MSB 1110 & A2, A1, A0 (L,L,L)
  '*** *** *** *** PLEASE TAKE NOTE *** *** *** ***  
 


CON
  'Originals from Basic_I2C_Driver v1.1
   ACK      = 0                        ' I2C Acknowledge
   NAK      = 1                        ' I2C No Acknowledge
   Xmit     = 0                        ' I2C Direction Transmit
   Recv     = 1                        ' I2C Direction Receive
   BootPin  = 28                       ' I2C Boot EEPROM SCL Pin
   EEPROM   = $A0                      ' I2C EEPROM Device Address

   

DAT
'PCA9548A Related
PUB PInit2
{{This is to initialise PCA9548A without connecting to Reset pin}}  
  return Initialize(_PCA9548A_SCL) 


PUB PReset
{{Resetting PCA9548A if it is connected to Prop, else Pull-Up this pin with a resistor}}

  'Reseting the PCA9548A
  OUTA[_PCA9548A_Rst]~~
  DIRA[_PCA9548A_Rst]~~
  OUTA[_PCA9548A_Rst]~
  OUTA[_PCA9548A_Rst]~~


PUB PInit
{{Initialise the I2C devices}}

  'Reseting the PCA9548A
  OUTA[_PCA9548A_Rst]~
  DIRA[_PCA9548A_Rst]~~
  DIRA[_PCA9548A_Rst]~

  'Init the PCA9548A 
  Initialize(_PCA9548A_SCL)
  waitcnt(cnt + clkfreq/100)  


PUB PSelect(I2CDevice, RWBit) : ackByte
{{I2CDevice = means which i2c device you are trying to switch to. It numbers from 0 to 7}}
{{RWBit = means 1 for Read and 0 for Write}}

  ackByte := 0
  
  Start(_PCA9548A_SCL)          'Start Condition
  ackByte := ackByte<<1 | PAddress(RWBit)               'Slave Address, ReadWriteBit: 1=Read, 0=Write
  ackByte := ackByte<<1 | PWriteDeviceSel(I2CDevice)    'Control Register
  Stop(_PCA9548A_SCL)           'Stop Condition


    
PUB PReadByte(I2CDevice, I2CDeviceAdd, ackbit)
{{I2CDevice = Number from 0 to 7
Data = Byte-sized}}

  Start(_PCA9548A_SCL)          'Start Condition
  PAddress(1)                   'Slave Address, ReadWriteBit: 1=Read, 0=Write
  PWriteDeviceSel(I2CDevice)    'Control Register
  result := Read(_PCA9548A_SCL, ackbit)        'Read from Device  
  Stop(_PCA9548A_SCL)          'Stop Condition


''------------ Debugging Use Only ------------  
PUB PSelect_SlaveAdd(RWBit) : ackbit
{{I used this for testing the reply for debugging purposes}}
  Start(_PCA9548A_SCL)          'Start Condition
  ackbit := PAddress(RWBit)               'Slave Address, ReadWriteBit: 1=Read, 0=Write
  Stop(_PCA9548A_SCL)           'Stop Condition
''------------ Debugging Use Only ------------

 
PUB PWriteByte(I2CDevice, I2CDeviceAdd, Data)
{{I2CDevice = Number from 0 to 7
Data = Byte-sized}}

  Start(_PCA9548A_SCL)          'Start Condition
  PAddress(0)                   'Slave Address, ReadWriteBit: 1=Read, 0=Write
  PWriteDeviceSel(I2CDevice)    'Control Register
  Write(_PCA9548A_SCL, Data)    'Write to Device
  Stop(_PCA9548A_SCL)          'Stop Condition



PUB PWriteWord(I2CDevice, Data)
{{I2CDevice = Number from 0 to 7
Data = Word-sized}}

  Start(_PCA9548A_SCL)          'Start Condition
  PAddress(0)                   'Slave Address, ReadWriteBit: 1=Read, 0=Write
  PWriteDeviceSel(I2CDevice)    'Control Register
  Write(_PCA9548A_SCL, Data)    'Write to Device
  Stop(_PCA9548A_SCL)          'Stop Condition
    

 
PUB PAddress(ReadWriteBit)
{{ReadWriteBit: 1=Read, 0=Write}}

  return Write(_PCA9548A_SCL, _addPCA9548A<<1 | ReadWriteBit)
  
  

PUB PWriteDeviceSel(I2C_Device)
{{I2C_Device is from 0 to 7, which are 1 to 8 devices connected to PCA9548A}}

  return Write(_PCA9548A_SCL, 1<<I2C_Device)




DAT
'3AD Related (MMH7455A)
PUB PWriteAccelReg(I2CDevice, I2CDeviceAdd, cmdReg, data) | ackbit 

'  Start(_PCA9548A_SCL)          'Start Condition
'  PAddress(0)                   'Slave Address, ReadWriteBit: 1=Read, 0=Write
'  PWriteDeviceSel(I2CDevice)    'Control Register
'  Stop(_PCA9548A_SCL)           'Stop Condition

  PSelect(I2CDevice, 0)     '<- Start,SlaveAdd,CtrReg,Stop
  
  Start(_PCA9548A_SCL)          'Start Condition
  ackbit := Write(_PCA9548A_SCL, I2CDeviceAdd<<1)
  ackbit := (ackbit << 1) | ackbit:=Write(_PCA9548A_SCL, cmdReg)
  ackbit := (ackbit << 1) | ackbit:=Write(_PCA9548A_SCL, data)
  'return (ackbit==ACK)
  return ackbit
  Stop(_PCA9548A_SCL)           'Stop Condition


PUB Debug_PWriteAccelReg(I2CDeviceAdd, cmdReg, data) | ackbit

  'Debug
'  I2CDeviceAdd := $1D    

  Start(_PCA9548A_SCL)          'Start Condition
  ackbit := Write(_PCA9548A_SCL, I2CDeviceAdd<<1)
  'ackbit := (ackbit << 1) | ackbit:=Write(_PCA9548A_SCL, cmdReg)
  ackbit := (ackbit << 1) | Write(_PCA9548A_SCL, cmdReg)
  'ackbit := (ackbit << 1) | ackbit:=Write(_PCA9548A_SCL, data)
  ackbit := (ackbit << 1) | Write(_PCA9548A_SCL, data)
  'return (ackbit==ACK)
  return ackbit   'I want to see the ackbit  
  Stop(_PCA9548A_SCL)           'Stop Condition


PUB Get3AD_X8(I2CDevice, I2CDeviceAdd)
  return Get3AD_1Byte(I2CDevice, I2CDeviceAdd, $06)
  

PUB Get3AD_1Byte(I2CDevice, I2CDeviceAdd, cmdReg) | v, m

  m := Get3AD(I2CDevice, I2CDeviceAdd, cmdReg)
  v := m>>8
  return (v<<24)~>24  'result is signed 8 bit...


PUB Get3AD(I2CDevice, I2CDeviceAdd, cmdReg) | ackbit, x   
  
  ifnot PSelect(I2CDevice, 0)>0     '<- Start,SlaveAdd,CtrReg,Stop 
    Start(_PCA9548A_SCL)          'Start Condition
    ackbit := Write(_PCA9548A_SCL, I2CDeviceAdd<<1)

    ackbit := Write(_PCA9548A_SCL, cmdReg)
    if ackbit > 0
      OUTA[19]~~
    else
      OUTA[19]~
    
    Stop(_PCA9548A_SCL)           'Stop Condition
     
    'x:=in(MMA7455_Address)
    x := PIn(I2CDevice, I2CDeviceAdd)
    'Debugging
    OUTA[20]~

  else
    'Debugging
    OUTA[20]~~
    
    x := -1
  
  return x


PUB PIn(I2CDevice, I2CDeviceAdd):data|ackbit

  PSelect(I2CDevice, 0)    '<- Function for Start,SlaveAdd,CtrReg,Stop


  Start(_PCA9548A_SCL)          'Start Condition
  ackbit:=Write(_PCA9548A_SCL, (I2CDeviceAdd<<1)+1)
  'ackbit:=Write(_PCA9548A_SCL, (I2CDeviceAdd<<1 | 1))
    if (ackbit==ACK)  
      'data:=Read(_PCA9548A_SCL, ACK)   '<--NOTE
      data:=Read3AD(_PCA9548A_SCL, ACK)   '<--NOTE
    else
      data:=-1   'return negative to indicate read failure
  Stop(_PCA9548A_SCL)           'Stop Condition
  return data


PUB Read3AD(SCL, ackbit): data | SDA
'' Read in i2c data, Data byte is output MSB first, SDA data line is
'' valid only while the SCL line is HIGH.  SCL and SDA left in LOW state.

   SDA := SCL + 1
   data := 0
   dira[SDA]~                          ' Make SDA an input
   repeat 8                            ' Receive data from SDA
      outa[SCL]~~                      ' Sample SDA when SCL is HIGH
      data := (data << 1) | ina[SDA]
      outa[SCL]~
   outa[SDA] := ackbit                 ' Output ACK/NAK to SDA
   dira[SDA]~~
   outa[SCL]~~                         ' Toggle SCL from LOW to HIGH to LOW
   outa[SCL]~
   dira[SDA]~
   repeat 8                            ' Receive data from SDA
      outa[SCL]~~                      ' Sample SDA when SCL is HIGH
      data := (data << 1) | ina[SDA]
      outa[SCL]~
   outa[SDA] := NAK'ackbit                 ' Output ACK/NAK to SDA
   
   dira[SDA]~~
   outa[SCL]~~                         ' Toggle SCL from LOW to HIGH to LOW
   outa[SCL]~
   outa[SDA]~                          ' Leave SDA driven LOW






DAT
'Original Basic_I2C_Driver
PUB Initialize(SCL) | SDA              ' An I2C device may be left in an
   SDA := SCL + 1                      '  invalid state and may need to be
   outa[SCL] := 1                       '   reinitialized.  Drive SCL high.
   dira[SCL] := 1
   dira[SDA] := 0                       ' Set SDA as input
   repeat 9
      outa[SCL] := 0                    ' Put out up to 9 clock pulses
      outa[SCL] := 1
      if ina[SDA]                      ' Repeat if SDA not driven high
         quit                          '  by the EEPROM

PUB Start(SCL) | SDA                   ' SDA goes HIGH to LOW with SCL HIGH
   SDA := SCL + 1
   outa[SCL]~~                         ' Initially drive SCL HIGH
   dira[SCL]~~
   outa[SDA]~~                         ' Initially drive SDA HIGH
   dira[SDA]~~
   outa[SDA]~                          ' Now drive SDA LOW
   outa[SCL]~                          ' Leave SCL LOW
  
PUB Stop(SCL) | SDA                    ' SDA goes LOW to HIGH with SCL High
   SDA := SCL + 1
   outa[SCL]~~                         ' Drive SCL HIGH
   outa[SDA]~~                         '  then SDA HIGH
   dira[SCL]~                          ' Now let them float
   dira[SDA]~                          ' If pullups present, they'll stay HIGH

PUB Write(SCL, data) : ackbit | SDA
'' Write i2c data.  Data byte is output MSB first, SDA data line is valid
'' only while the SCL line is HIGH.  Data is always 8 bits (+ ACK/NAK).
'' SDA is assumed LOW and SCL and SDA are both left in the LOW state.
   SDA := SCL + 1
   ackbit := 0 
   data <<= 24
   repeat 8                            ' Output data to SDA
      outa[SDA] := (data <-= 1) & 1
      outa[SCL]~~                      ' Toggle SCL from LOW to HIGH to LOW
      outa[SCL]~
   dira[SDA]~                          ' Set SDA to input for ACK/NAK
   outa[SCL]~~
   ackbit := ina[SDA]                  ' Sample SDA when SCL is HIGH
   outa[SCL]~
   outa[SDA]~                          ' Leave SDA driven LOW
   dira[SDA]~~

PUB Read(SCL, ackbit): data | SDA
'' Read in i2c data, Data byte is output MSB first, SDA data line is
'' valid only while the SCL line is HIGH.  SCL and SDA left in LOW state.
   SDA := SCL + 1
   data := 0
   dira[SDA]~                          ' Make SDA an input
   repeat 8                            ' Receive data from SDA
      outa[SCL]~~                      ' Sample SDA when SCL is HIGH
      data := (data << 1) | ina[SDA]
      outa[SCL]~
   outa[SDA] := ackbit                 ' Output ACK/NAK to SDA
   dira[SDA]~~
   outa[SCL]~~                         ' Toggle SCL from LOW to HIGH to LOW
   outa[SCL]~
   outa[SDA]~                          ' Leave SDA driven LOW

PUB ReadPage(SCL, devSel, addrReg, dataPtr, count) : ackbit
'' Read in a block of i2c data.  Device select code is devSel.  Device starting
'' address is addrReg.  Data address is at dataPtr.  Number of bytes is count.
'' The device select code is modified using the upper 3 bits of the 19 bit addrReg.
'' Return zero if no errors or the acknowledge bits if an error occurred.
   devSel |= addrReg >> 15 & %1110
   Start(SCL)                          ' Select the device & send address
   ackbit := Write(SCL, devSel | Xmit)
   ackbit := (ackbit << 1) | Write(SCL, addrReg >> 8 & $FF)
   ackbit := (ackbit << 1) | Write(SCL, addrReg & $FF)          
   Start(SCL)                          ' Reselect the device for reading
   ackbit := (ackbit << 1) | Write(SCL, devSel | Recv)
   repeat count - 1
      byte[dataPtr++] := Read(SCL, ACK)
   byte[dataPtr++] := Read(SCL, NAK)
   Stop(SCL)
   return ackbit

PUB ReadByte(SCL, devSel, addrReg) : data
'' Read in a single byte of i2c data.  Device select code is devSel.  Device
'' starting address is addrReg.  The device select code is modified using the
'' upper 3 bits of the 19 bit addrReg.  This returns true if an error occurred.
   if ReadPage(SCL, devSel, addrReg, @data, 1)
      return -1

PUB ReadWord(SCL, devSel, addrReg) : data
'' Read in a single word of i2c data.  Device select code is devSel.  Device
'' starting address is addrReg.  The device select code is modified using the
'' upper 3 bits of the 19 bit addrReg.  This returns true if an error occurred.
   if ReadPage(SCL, devSel, addrReg, @data, 2)
      return -1

PUB ReadLong(SCL, devSel, addrReg) : data
'' Read in a single long of i2c data.  Device select code is devSel.  Device
'' starting address is addrReg.  The device select code is modified using the
'' upper 3 bits of the 19 bit addrReg.  This returns true if an error occurred.
'' Note that you can't distinguish between a return value of -1 and true error.
   if ReadPage(SCL, devSel, addrReg, @data, 4)
      return -1

PUB WritePage(SCL, devSel, addrReg, dataPtr, count) : ackbit
'' Write out a block of i2c data.  Device select code is devSel.  Device starting
'' address is addrReg.  Data address is at dataPtr.  Number of bytes is count.
'' The device select code is modified using the upper 3 bits of the 19 bit addrReg.
'' Most devices have a page size of at least 32 bytes, some as large as 256 bytes.
'' Return zero if no errors or the acknowledge bits if an error occurred.  If
'' more than 31 bytes are transmitted, the sign bit is "sticky" and is the
'' logical "or" of the acknowledge bits of any bytes past the 31st.
   devSel |= addrReg >> 15 & %1110
   Start(SCL)                          ' Select the device & send address
   ackbit := Write(SCL, devSel | Xmit)
   ackbit := (ackbit << 1) | Write(SCL, addrReg >> 8 & $FF)
   ackbit := (ackbit << 1) | Write(SCL, addrReg & $FF)          
   repeat count                        ' Now send the data
      ackbit := ackbit << 1 | ackbit & $80000000 ' "Sticky" sign bit         
      ackbit |= Write(SCL, byte[dataPtr++])
   Stop(SCL)
   return ackbit

PUB WriteByte(SCL, devSel, addrReg, data)
'' Write out a single byte of i2c data.  Device select code is devSel.  Device
'' starting address is addrReg.  The device select code is modified using the
'' upper 3 bits of the 19 bit addrReg.  This returns true if an error occurred.
   if WritePage(SCL, devSel, addrReg, @data, 1)
      return true
   ' james edit - wait for 5ms for page write to complete (80_000 * 5 = 400_000)      
   waitcnt(400_000 + cnt)      
   return false

PUB WriteWord(SCL, devSel, addrReg, data)
'' Write out a single word of i2c data.  Device select code is devSel.  Device
'' starting address is addrReg.  The device select code is modified using the
'' upper 3 bits of the 19 bit addrReg.  This returns true if an error occurred.
'' Note that the word value may not span an EEPROM page boundary.
   if WritePage(SCL, devSel, addrReg, @data, 2)
      return true
   ' james edit - wait for 5ms for page write to complete (80_000 * 5 = 400_000)
   waitcnt(400_000 + cnt)      
   return false

PUB WriteLong(SCL, devSel, addrReg, data)
'' Write out a single long of i2c data.  Device select code is devSel.  Device
'' starting address is addrReg.  The device select code is modified using the
'' upper 3 bits of the 19 bit addrReg.  This returns true if an error occurred.
'' Note that the long word value may not span an EEPROM page boundary.
   if WritePage(SCL, devSel, addrReg, @data, 4)
      return true
   ' james edit - wait for 5ms for page write to complete (80_000 * 5 = 400_000)      
   waitcnt(400_000 + cnt)      
   return false

PUB WriteWait(SCL, devSel, addrReg) : ackbit
'' Wait for a previous write to complete.  Device select code is devSel.  Device
'' starting address is addrReg.  The device will not respond if it is busy.
'' The device select code is modified using the upper 3 bits of the 18 bit addrReg.
'' This returns zero if no error occurred or one if the device didn't respond.
   devSel |= addrReg >> 15 & %1110
   Start(SCL)
   ackbit := Write(SCL, devSel | Xmit)
   Stop(SCL)
   return ackbit


' *************** JAMES'S Extra BITS *********************
   
PUB devicePresent(SCL,deviceAddress) : ackbit
  ' send the deviceAddress and listen for the ACK
   Start(SCL)
   ackbit := Write(SCL,deviceAddress | 0)
   Stop(SCL)
   if ackbit == ACK
     return true
   else
     return false

PUB writeLocation(SCL,device_address, register, value)
  start(SCL)
  write(SCL,device_address)
  write(SCL,register)
  write(SCL,value)  
  stop (SCL)

PUB readLocation(SCL,device_address, register) : value
  start(SCL)
  write(SCL,device_address | 0)
  write(SCL,register)
  start(SCL)
  write(SCL,device_address | 1)  
  value := read(SCL,NAK)
  stop(SCL)
  return value     
                       



dat

{{

  Terms of Use: MIT License

  Permission is hereby granted, free of charge, to any person obtaining a copy of this
  software and associated documentation files (the "Software"), to deal in the Software
  without restriction, including without limitation the rights to use, copy, modify,
  merge, publish, distribute, sublicense, and/or sell copies of the Software, and to
  permit persons to whom the Software is furnished to do so, subject to the following
  conditions:

  The above copyright notice and this permission notice shall be included in all copies
  or substantial portions of the Software.

  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
  INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A
  PARTICULAR PURPOSE AND NON-INFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
  HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF
  CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE
  OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

}}