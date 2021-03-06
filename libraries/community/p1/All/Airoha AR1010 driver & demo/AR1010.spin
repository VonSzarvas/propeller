''****************************************
''*  AR1010                              *
''*  Authors: Nikita Kareev              *
''*  See end of file for terms of use.   *
''****************************************
''
'' Arioha AR1010 driver
'' Uses Basic_I2C_Driver by Michael Green
''
'' http://www.sparkfun.com/commerce/product_info.php?products_id=8770
''
'' Updated... 14 JUN 2009
''
OBJ 

  TIME  : "Clock"                                       'Clock
  I2C   : "Basic_I2C_Driver"                            'I2C driver

VAR

  long AR1010_addr
  long I2C_Clk
  long I2C_Dat 
  long Regs[17]

PUB Init (addr, i2c_scl, i2c_sda) 

  I2C_Clk := i2c_scl
  I2C_Dat := i2c_sda
  AR1010_addr := addr

  'Initialize clock object
  TIME.Init(5_000_000)

  ' Initialize I2C driver
  I2C.Initialize(I2C_Clk)
  
  ' Load default register settings to register array
  LoadDefaultRegs
  
  ' Startup calibration
  InitAR1010

PRI InitAR1010 | idx, status

  WriteReg(0, Regs[0] & $FFFE)

  repeat idx from 1 to 17
    WriteReg(idx, Regs[idx])

  WriteReg(0, Regs[0])

  status := ReadReg(19)
  status &= $0020
  
  repeat while status == 0
    status := ReadReg(19)
    status &= $0020
    TIME.PauseMSec(100)  

PRI WriteReg(reg, data)

{{
    1. Master (Host processor) initiates a START condition.
    2. Master writes the device address of the slave (AR1000), and then followed
       a WRITE bit. Slave sends back an ACK.
    3. Master writes the register address of AR1000. Slave sends back an ACK.
    4. Master writes 2-byte data to complete a register, and then sends a STOP
       condition to end the write procedure.
}}

  I2C.Start(I2C_Clk)
  I2C.Write(I2C_Clk, AR1010_addr | 0)
  I2C.Write(I2C_Clk, reg)  
  I2C.Write(I2C_Clk, (data & $FF00) >> 8)
  I2C.Write(I2C_Clk, data & $00FF)
  I2C.Stop(I2C_Clk)

PRI ReadReg(reg) : data

{{
    1. Master (Host processor) initiates a START condition.
    2. Master writes the device address of the slave (AR1000), and then followed
       a WRITE bit. Slave sends back an ACK.
    3. Master writes the register address of AR1000. Slave sends back an ACK.
    4. Master re-initiates a start condition.
    5. Master writes the device address of the slave (AR1000) again, and then
       followed a READ bit. Slave sends back an ACK.
    6. Master sends CLOCK signal into slave, and slave outputs associated bit
       data at DATA pin. Master sends ACK at the end of each byte data.
    7. After 2 bytes data read from slave, master sends a STOP condition to end
       the read procedure.
}}

  I2C.Start(I2C_Clk)
  I2C.Write(I2C_Clk, AR1010_addr | 0)
  I2C.Write(I2C_Clk, reg)
  I2C.Start(I2C_Clk)
  I2C.Write(I2C_Clk, AR1010_addr | 1)
  data := I2C.Read(I2C_Clk, 0)
  data := data << 8
  data |= I2C.Read(I2C_Clk, 1)

PRI LoadDefaultRegs | idx

  repeat idx from 0 to 17
    Regs[idx] := AR1010DefRegs[idx]  

PUB Mute(mut)

  if mut
    WriteReg(1, $5B17)
  else
    WriteReg(1, $5B15)

PUB SetVolume(vol) | regData

  vol := 0 #> vol <# 21

  Mute(true)

  Regs[3] := (Regs[3] & $0780) | (AR1010Vol1[vol] << 7) 
  WriteReg(3, Regs[3])
        
  Regs[14] := (Regs[14] & $F000)| (AR1010Vol2[vol] << 12)
  WriteReg(14, Regs[14])
        
  Mute(false)

PUB SetFrequency(freq) | status

{{
    1. Set hmute Bit
    2. Clear TUNE Bit
    3. Clear SEEK Bit
    4. Set BAND/SPACE/CHAN Bits
    5. Enable TUNE Bit
    6. Wait STC flag (Seek/Tune Complete, in "Status" register)
    7. Clear hmute Bit
    8. Update Functions (optional)

    Frequency is specified in MHz without the decimal point
    Example: 93.1MHz is 931
    Subtract 690 to get the value for CHAN

    Set CHAN
    Set TUNE bit
}}

   freq -= 690
   Mute(true)
   
   'Clear tune bit and chan bits
   Regs[2] := %0000000000000000       
        
   'Set chan bits
   Regs[2] := freq

   'Clear seek bit
   Regs[3] &= (1 << 14)
        
   'Set space = 100k (seek stepping increments in 100k steps)
   Regs[3] |= (1 << 13)
 
   'Send the registers to the chip
   WriteReg(2,Regs[2])
   WriteReg(3,Regs[3])
        
   'Set tune bit
   Regs[2] |= $0200
   WriteReg(2,Regs[2])

   status := ReadReg(19)
   status &= $0020 ' Check STC flag
   
   repeat while status == 0
     status := ReadReg(19)
     status &= $0020 ' Check STC flag
     TIME.PauseMSec(100) 
   
   Mute(false) 

DAT

AR1010DefRegs long  $FFFF, $5B15, $D0B9, $A010, $0780, $28AB, $6400, $1EE7, $7141, $007D, $82C6, $4F55, $970C, $B845, $FC2D, $8097, $04A1, $DF6A 
AR1010Vol2 byte $0, $C, $D, $E, $F, $E, $F, $E, $F, $F, $F, $F, $F, $E, $F, $E, $F, $E, $F, $F, $F, $F
AR1010Vol1 byte $F, $F, $F, $F, $F, $E, $E, $D, $D, $B, $A, $9, $7, $6, $6, $5, $5, $3, $3, $2, $1, $0

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