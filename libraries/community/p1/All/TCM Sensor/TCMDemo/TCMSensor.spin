{{
  Propeller: TCMSensor.SPIN
  Written by: Earl Foster
  Original Date: 4/14/2009
  Version: 1.1

  Modified: 4/17/2009
            Added Orientation
            Added Power Up / Down
            Added Stop data transmission
            Changed Version to 1.1

  This program captures Heading, Temperature, Pitch, and Roll from the TCM 5 sensors.
  Acquisition Setting is set to Push with an Interval Time of 0.000 and no flushing.
  
  PNI Sensor Corporation - TCM5 360° tilt-compensated heading module.
  Specifications:
     High Resolution Field Measurement - 0.05 µT (0.0005 Gauss)
     High Precision Heading accuracy 0.3°
     High Tilt Repeatability - 0.05°
     Full Tilt Compensation - ± 90° pitch; ± 180° roll
     High Resolution Compass heading 0.1°
     Wide Field Measurement Range - ± 80 µT (± 0.8 Gauss) 

  Complete specifications available @ http://www.pnicorp.com/products/all/tcm-5
  The PNI is a +5vDC device and a 1K - 22K resistor should be connected to the Rx pin
  of the Propeller for voltage protection. The Transmit pin on the Propeller must be
  inverted to send to commands to the PNI sensor.  The following simple transistor
  circuit can be used to invert the signal in order to communicate with the sensor.
   
  
                  +3.3V
                     │
                      5K
                10K  ├───── PNI RX
       Prop TX ──
                     │
                     
}}
obj
   PNI:   "FullDuplexSerial"
   
var
   byte idx, SPSTR[24], readings[24], pni_stack[50], BLendian
   long kHeading, kTemperature, kPAngle, kRAngle, cog

Pub StartPNI(PNI_RX,PNI_TX,BAUDRATE, EndianMode) : Okay
{
    PNI_RX - PNI Receive pin
    PNI_TX - PNI Transmit pin
    BAUDRATE is the baudrate of the PNI unit.  Default is 38400 unless changed
    using TCMStudio program.

    EndianMode
    PNI set to Big Endian = 1
               Little Endian = 0  
}   

   okay := PNI.start(PNI_RX,PNI_TX,1,BAUDRATE)   'Start PNI RS232 communications
   BLendian := EndianMode            'Set Endian mode
   kSetAcqParams(0)                  'Override Studio settings
   kSetDataComponents                'Set output configuration
   kSetConfig(10,1)
   waitcnt(clkfreq/10 + cnt)
   kStartIntervalMode                'Start push mode
   waitcnt(clkfreq/4 + cnt)          'Provides time for PNI to respond

   return cog := cognew(readPNI,@pni_stack) + 1 

Pub readPNI

   repeat
      repeat while PNI.rx <> $1A             'Look for a byte count equal to 26
      idx := 0
      repeat while idx <> 22               
         SPSTR[idx++] := PNI.rx
      if SPSTR[0] == $05                     'Frame ID
         if SPSTR[1] == $04                  'Number of Components
            bytemove(@readings, @SPSTR, 24)
      parse_data(BLendian)

Pub kSetAcqParams(timer)
{
   This sets up the acquisition parameters to push the data out as soon
   as it is available and will override TCMStudio settings.
}
   PNI.tx($00)    'Total bytes of frame including CRC
   PNI.tx($0F)
   PNI.tx($18)    'Frame type (kSetAcqParams)
   PNI.tx($00)    'PollingMode set to False
   PNI.tx($00)    'FlushFilters set to False
   PNI.tx($00)    'SensorAcqTime set to 0.0
   PNI.tx($00)
   PNI.tx($00)
   PNI.tx($00)
   case timer
      0:   PNI.tx($00)    'IntervalRespTime set to 0.0.  Push data as soon as available
           PNI.tx($00)
           PNI.tx($00)
           PNI.tx($00)
           PNI.tx($E4)    'CRC-CCITT(xmodem)
           PNI.tx($50)
      1:   PNI.tx($3D)    '0.1 seconds
           PNI.TX($CC)
           PNI.TX($CC)
           PNI.TX($CD)
           PNI.TX($F9)
           PNI.TX($71)           
      3:   PNI.tx($3E)    '0.25 seconds
           PNI.TX($80)
           PNI.TX($00)
           PNI.TX($00)
           PNI.TX($51)
           PNI.TX($B9)           
      4:   PNI.tx($3F)    '0.5 seconds
           PNI.TX($00)
           PNI.TX($00)
           PNI.TX($00)
           PNI.TX($1C)
           PNI.TX($57)           
      5:   PNI.tx($3F)    '1 second
           PNI.TX($80)
           PNI.TX($00)
           PNI.TX($00)
           PNI.TX($27)
           PNI.TX($0D)           

Pub kSetDataComponents
{
   This frame sets the data components in the module's data output.  
   Sets up Heading, Temperature, Pitch, and Roll as the output.
}  
   PNI.tx($00)    'Total bytes of frame including CRC
   PNI.tx($0A)
   PNI.tx($03)    'Frame type (kSetDataComponents)
   PNI.tx($04)    'Number of components requested
   PNI.tx($05)    'Get heading
   PNI.tx($07)    'Get temperature (accuracy ±3°C / ±5.4°F)
   PNI.tx($18)    'Get pitch
   PNI.tx($19)    'Get roll
   PNI.tx($84)    'CRC-CCITT(xmodem)
   PNI.tx($BF)

Pub kStartIntervalMode
{
   This frame commands the module to output data at a fixed time interval
}
   PNI.tx($00)    'Total bytes of frame including CRC
   PNI.tx($05)
   PNI.tx($15)    'Frame type (KStartIntervalMode)
   PNI.tx($BD)    'CRC-CCITT(xmodem)
   PNI.tx($61)            

pub kStopIntervalMode
{{
   Stop data transmission
}}
   PNI.TX($00)    'Total bytes of frame including CRC
   PNI.TX($05)
   PNI.TX($16)    'Frame type (KStopIntervalMode)
   PNI.TX($8D)    'CRC-CCITT(xmodem)
   PNI.TX($02)

pub kSetConfig(confID, posID)
{{
   Currently this frame sets the orientation for the sensor.  Review TCM Studio
   user guide for available mounting options and corresponding position ID number.
   The procedure is only needed if orientation is other then default position.
}}

   PNI.TX($00)
   PNI.TX($07)
   PNI.TX($06)
   case confID          'Sets configuration ID
      10:   PNI.TX($0A)       'Sets kMountingRef
            case posID
                1:  PNI.TX($01)   'Standard/Default
                    PNI.TX($1C)
                    PNI.TX($67)
                2:  PNI.TX($02)   'X axis up
                    PNI.TX($2C)
                    PNI.TX($04)
                3:  PNI.TX($03)   'Y axis up
                    PNI.TX($3C)
                    PNI.TX($25)
                4:  PNI.TX($04)   '-90 heading offset
                    PNI.TX($4C)
                    PNI.TX($C2)
                5:  PNI.TX($05)   '-180 heading offset
                    PNI.TX($5C)
                    PNI.TX($E3)
                6:  PNI.TX($06)   '-270 heading offset
                    PNI.TX($6C)
                    PNI.TX($80)
                7:  PNI.TX($07)   'Z down
                    PNI.TX($7C)
                    PNI.TX($A1)
                8:  PNI.TX($08)   'X + 90
                    PNI.TX($8D)
                    PNI.TX($4E)
                9:  PNI.TX($09)   'X + 180
                    PNI.TX($9D)
                    PNI.TX($6F)
                10: PNI.TX($0A)   'X + 270
                    PNI.TX($AD)
                    PNI.TX($0C)
                11: PNI.TX($0B)   'Y + 90
                    PNI.TX($BD)
                    PNI.TX($2D)
                12: PNI.TX($0C)   'Y + 180
                    PNI.TX($CD)
                    PNI.TX($CA)
                13: PNI.TX($0D)   'Y + 270
                    PNI.TX($DD)   
                    PNI.TX($EB)
                14: PNI.TX($0E)   'Z down + 90
                    PNI.TX($ED)
                    PNI.TX($88)
                15: PNI.TX($0F)   'Z down + 180
                    PNI.TX($FD)
                    PNI.TX($A9)
                16: PNI.TX($10)   'Z down + 270
                    PNI.TX($1E)
                    PNI.TX($77)

pub kPowerDown
{{
   The unit should be powered down after making a configuration change such as
   sensor orientation.
}}
   PNI.TX($00)
   PNI.TX($05)
   PNI.TX($0F)
   PNI.TX($0E)
   PNI.TX($1A)

pub kPowerUp
{{
   Turns sensor on
}}
   PNI.TX($FF)
   waitcnt(clkfreq/10 + cnt)
   
pub parse_data(Endian) | i, j
{{
   Data from the device is settable to Big Endian or Little Endian.
   The Prop uses little Endian so the data needs to be normalized.
   Sending a 1 means the device is using Big Endian format.
   Sending a 0 means the device is using Little Endian format.
   Total ByteCount and CRC is always sent Bid Endian from the device.

   Comparison of the two formats are shown below.
   
   Big Endian
   31   24 23   16 15    8 7     0
   --------------------------------
   | msb  |       |       | lsb   |   : Endian = 1
   --------------------------------

   Little Endian
   7     0 15   8 23   16 31     24
   --------------------------------
   | lsb  |      |        | msb   |   : Endian = 0
   --------------------------------
}}
   if Endian == 0
         'PNI is setup in Little Endian Mode
          i:= 0
          repeat j from 3 to 6
             kHeading.byte[i++] := readings[j]
          i := 0
          repeat j from 8 to 11
             kTemperature.byte[i++] := readings[j]
          i := 0
          repeat j from 13 to 16
             kPAngle.byte[i++] := readings[j]
          i := 0
          repeat j from 18 to 21
             kRAngle.byte[i++] := readings[j]
   if Endian == 1
      'PNI is setup in Big Endian Mode
          i := 3
          repeat j from 3 to 6
             kHeading.byte[i--] := readings[j]
          i := 3
          repeat j from 8 to 11
             kTemperature.byte[i--] := readings[j]
          i := 3
          repeat j from 13 to 16
             kPAngle.byte[i--] := readings[j]
          i := 3
          repeat j from 18 to 21
             kRAngle.byte[i--] := readings[j]
   
pub get_heading
   return(kHeading)

pub get_temp
   return(kTemperature)

pub get_pitch
   return(kPAngle)

pub get_roll
   return(kRAngle)

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