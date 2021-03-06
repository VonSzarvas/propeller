{{
┌───────────────────────────┬───────────────────┬────────────────────────┐
│ H48C_Sync_Demo.spin v1.0  │ Author: I.Kövesdi │ Release: 16 March 2009 │
├───────────────────────────┴───────────────────┴────────────────────────┤
│                    Copyright (c) 2009 CompElit Inc.                    │               
│                   See end of file for terms of use.                    │               
├────────────────────────────────────────────────────────────────────────┤
│                                                                        │
│  This PST terminal application proves the H48C_Sync_Driver.spin object.│
│ This driver object can synchronize the data readouts of H48C Tri-axis  │
│ accelerometer modules. In this demo four H48C sensors are synchronized.│
│ The precise timing and precise intervals of the synchronous readouts   │
│ are verified.                                                          │
│                                                                        │
├────────────────────────────────────────────────────────────────────────┤
│ Background and Detail:                                                 │
│  Synchronization is solved using the CounterA internal timer of COG0.  │
│ The frequency of the timer's square wave on a pin can be set up between│
│ 1-200 Hz.                                                              │
│                                                                        │    
├────────────────────────────────────────────────────────────────────────┤
│ Note:                                                                  │
│  The H48C_Sync_Driver can be used in 6DOF IMU projects where four H48C │
│ Tri-axis accelerometers are arranged in space to provide a cheap but   │
│ precise close equivalent of high dollar 6DOF IMU sensors. See attached │
│ PDF file for the mathematical details.                                 │
│  This SPIN demo uses 50 Hz Dwell Clock frequency. To transmit the data │
│ of the four sensors at 57_600 baud to the debug terminal can take about│
│ 10 msec. So, above 75 Hz operation cannot be well demonstrated with    │
│ this demo SPIN code. However, the driver was tested and verified with  │
│ simpler and faster SPIN code up to 200 Hz.                             │
│                                                                        │
└────────────────────────────────────────────────────────────────────────┘

Hardware:


                                   5V
              ┌──────────────────┐ │               
              │      H48C(1)     │ │
              │                  │ │
              │                  │ │
              │                  │ │                                                                        
           ┌──┤GND|3        6|VDD├─┘                                     
           │  │                  │                                             
             │ CS|5 DIO|2 CLK|1 │                                          
          GND └───┬─────┬─────┬──┘     
    │             │     │     │       
    ├A0───────────┘     │     │       
    │                   │     │
    ├A1─────────────────┘     │
    │                         │                   
    ├A2───────────────────────┘                  
    │ ---------------------------------------------  
  P ├A3───────────────────────> To  CS|5 of H48C(2)                                    
    │                                          
  8 ├A4───────────────────────> To DIO|2 of H48C(2)                                      
    │                                           
  X ├A5───────────────────────> To CLK|1 of H48C(2)                                     
    │ ---------------------------------------------
  3 ├A6───────────────────────> To  CS|5 of H48C(3)                                    
    │                                          
  2 ├A7───────────────────────> To DIO|2 of H48C(3)                                      
    │                                           
  A ├A8───────────────────────> To CLK|1 of H48C(3)     
    │ ---------------------------------------------
    ├A9───────────────────────> To  CS|5 of H48C(4)                                    
    │                                          
    ├A10──────────────────────> To DIO|2 of H48C(4)                                      
    │
    ├A11──────────────────────> To CLK|1 of H48C(4)
    │ --------------------------------------------
    ├A12─  Dwell Clock Line, internally connected to the COGs

    
}}


CON

_CLKMODE         = XTAL1 + PLL16X
_XINFREQ         = 5_000_000

'Hardware Pin assignments
_H48C1_CS        = 0                     'PROP pin to CS pin  of H48C1 SPI  
_H48C1_DIO       = 1                     'PROP pin to DIO pin of H48C1 SPI
_H48C1_CLK       = 2                     'Prop Pin to CLK pin of H48C1 SPI

_H48C2_CS        = 3                     'PROP pin to CS pin  of H48C2 SPI  
_H48C2_DIO       = 4                     'PROP pin to DIO pin of H48C2 SPI
_H48C2_CLK       = 5                     'Prop Pin to CLK pin of H48C2 SPI

_H48C3_CS        = 6                     'PROP pin to CS pin  of H48C3 SPI  
_H48C3_DIO       = 7                     'PROP pin to DIO pin of H48C3 SPI
_H48C3_CLK       = 8                     'Prop Pin to CLK pin of H48C3 SPI

_H48C4_CS        = 9                     'PROP pin to CS pin  of H48C3 SPI  
_H48C4_DIO       = 10                    'PROP pin to DIO pin of H48C3 SPI
_H48C4_CLK       = 11                    'Prop Pin to CLK pin of H48C3 SPI

'Dwell Clock data
_DWELL_CLK_PIN   = 12
_DWELL_CLK_FREQ  = 50                    'In 1-200 Hz range

_RATE            = 50                    'Demo diplay rate
_SECS            = 10                    'Display seconds


OBJ

DBG       : "FullDuplexSerialPlus"   'From Parallax Inc.
                                     'Propeller Education Kit
                                     'Objects Lab v1.1 

H48C_1    : "H48C_Sync_Driver"       'v1.0
H48C_2    : "H48C_Sync_Driver"       'v1.0
H48C_3    : "H48C_Sync_Driver"       'v1.0
H48C_4    : "H48C_Sync_Driver"       'v1.0 

  
VAR

LONG  cog_ID
LONG  cntr, time, dTime
LONG  a1x, a1y, a1z, t1          
LONG  a2x, a2y, a2z, t2           
LONG  a3x, a3y, a3z, t3           
LONG  a4x, a4y, a4z, t4

BYTE  h48c1, h48c2, h48c3, h48c4
BYTE  dwellClock


PUB DoIt                     
'-------------------------------------------------------------------------
'----------------------------------┌──────┐-------------------------------
'----------------------------------│ DoIt │-------------------------------
'----------------------------------└──────┘-------------------------------
'-------------------------------------------------------------------------
''     Action: Demonstrates H48C_Sync_Driver options
'' Parameters: None
''    Results: None
''+Reads/Uses: /-H48C hardware constants from CON section
''             /-_RATE, _SECS from CON section
''    +Writes: -cog_ID global variable
''             -h48c1, h48c2, h48c3, h48c4 global variables
''      Calls: FullDuplexSerialPlus------>DBG.Start
''                                        DBG.Str
''                                        DBG.Dec 
''             H48C_Sync_Driver---------->H48C_1.StartCOG
''                                        H48C_1.Dwell_Clock_On
''                                        H48C_1.StopCOG
''             H48C_Sync_Driver---------->H48C_2.StartCOG
''                                        H48C_2.StopCOG
''             H48C_Sync_Driver---------->H48C_3.StartCOG
''                                        H48C_3.StopCOG
''             H48C_Sync_Driver---------->H48C_4.StartCOG
''                                        H48C_4.StopCOG
''             H48C_Demo0, H48C_Demo1, H48C_Demo2, H48C_Demo3 ,H48C_Demo4  
'-------------------------------------------------------------------------
'Start FullDuplexSerialPlus Dbg terminal
DBG.Start(31, 30, 0, 57600)
  
WAITCNT(6 * CLKFREQ + CNT)

DBG.Str(STRING(16, 1))
DBG.Str(STRING("H48C Synchron Driver Demo", 10, 13))
DBG.Str(STRING(10, 13))

WAITCNT(CLKFREQ + CNT)

'Start H48C 1 Driver
h48c1:=H48C_1.StartCOG(_H48C1_CS,_H48C1_DIO,_H48C1_CLK,_DWELL_CLK_PIN,@cog_ID)

IF (h48c1)
  DBG.Str(STRING("H48C 1 Driver started in COG "))
  DBG.Dec(cog_ID)
ELSE
  DBG.Str(STRING("H48C 1 Driver Start failed!"))
DBG.Str(STRING(10, 13, 13))

'Start H48C 2 Driver
h48c2:=H48C_2.StartCOG(_H48C2_CS,_H48C2_DIO,_H48C2_CLK,_DWELL_CLK_PIN,@cog_ID)

IF (h48c2)
  DBG.Str(STRING("H48C 2 Driver started in COG "))
  DBG.Dec(cog_ID)
ELSE
  DBG.Str(STRING("H48C 2 Driver Start failed!"))
DBG.Str(STRING(10, 13, 13))

'Start H48C 3 Driver
h48c3:=H48C_3.StartCOG(_H48C3_CS,_H48C3_DIO,_H48C3_CLK,_DWELL_CLK_PIN,@cog_ID)

IF (h48c3)
  DBG.Str(STRING("H48C 3 Driver started in COG "))
  DBG.Dec(cog_ID)
ELSE
  DBG.Str(STRING("H48C 3 Driver Start failed!"))
DBG.Str(STRING(10, 13, 13))

'Start H48C 4 Driver
h48c4:=H48C_4.StartCOG(_H48C4_CS,_H48C4_DIO,_H48C4_CLK,_DWELL_CLK_PIN,@cog_ID)

IF (h48c4)
  DBG.Str(STRING("H48C 4 Driver started in COG "))
  DBG.Dec(cog_ID)
ELSE
  DBG.Str(STRING("H48C 4 Driver Start failed!"))
DBG.Str(STRING(10, 13, 13))

WAITCNT(4 * CLKFREQ + CNT) 

'Start Dwell Oscillator in COG0 by one of the drivers
IF (h48c1)
  dwellClock := H48C_1.Dwell_Clock_On(_DWELL_CLK_PIN, _DWELL_CLK_FREQ)

IF dwellClock
 
  IF (h48c1) AND (h48c2) AND (h48c3) AND (h48c4)
    DBG.Str(STRING(16, 1))
    H48C_Demo0(_RATE, _SECS)
    H48C_Demo1(_RATE, _SECS)

    DBG.Str(STRING(16, 1))
    DBG.Str(STRING("Dwell Clock runs at 50 Hz.", 10, 13, 13))
    WAITCNT(4 * CLKFREQ + CNT)
    
    H48C_Demo2(_RATE, _SECS)
    H48C_Demo3(_RATE, _SECS)
    H48C_Demo4(_RATE, _SECS)
    
    H48C_1.StopCOG
    H48C_2.StopCOG
    H48C_3.StopCOG
    H48C_4.StopCOG
  ELSE
    DBG.Str(STRING("Some error occured. Please check system."))  
    IF (h48c1)
      H48C_1.StopCOG
    IF (h48c2)
      H48C_2.StopCOG
    IF (h48c3)
      H48C_3.StopCOG
    IF (h48c4)
      H48C_4.StopCOG       
'-------------------------------------------------------------------------    


PRI H48C_Demo0(rate, secs) | i, n
'-------------------------------------------------------------------------
'-----------------------------┌────────────┐------------------------------
'-----------------------------│ H48C_Demo0 │------------------------------
'-----------------------------└────────────┘------------------------------
'-------------------------------------------------------------------------
'     Action: Demonstrates sequential, direct 3-axis readouts
' Parameters: -Rate
'             -Seconds
'    Results: None
'+Reads/Uses: -a1x, a1y, a1z, t1          
'             -a2x, a2y, a2z, t2           
'             -a3x, a3y, a3z, t3           
'             -a4x, a4y, a4z, t4
'    +Writes: None
'      Calls: FullDuplexSerialPlus-------------->DBG.Str
'                                                DBG.Dec
'             H48C_Sync_Driver------------------>H48C_1.Read_Acceleration
'                                                H48C_2.Read_Acceleration
'                                                H48C_3.Read_Acceleration
'                                                H48C_4.Read_Acceleration
'-------------------------------------------------------------------------
DBG.Str(STRING("Sequential, Direct 3-axis readouts of the H48C sensors."))
DBG.Str(STRING(10, 13))
DBG.Str(STRING("Dwell Clock not used at this kind of data collection."))
DBG.Str(STRING(10, 13, 13)) 
DBG.Str(STRING(" Ax  Ay  Az   Ax  Ay  Az   Ax  Ay  Az  Ax  Ay  Az  Cntr"))
DBG.Str(STRING(10, 13))
DBG.Str(STRING("======================================================="))      
DBG.Str(STRING(10, 13))

cntr := 0
time := CNT
dTime := CLKFREQ / rate
n := secs * rate

i~
REPEAT n
  cntr++   
  WAITCNT(time + dTime)
  time := time + dTime 
  'Read acceleration values from H48C
  H48C_1.Read_Acceleration(@a1x, @a1y, @a1z, @t1)
  H48C_2.Read_Acceleration(@a2x, @a2y, @a2z, @t2)
  H48C_3.Read_Acceleration(@a3x, @a3y, @a3z, @t3)
  H48C_4.Read_Acceleration(@a4x, @a4y, @a4z, @t4)
  i++
  IF i > 9
    i~
    DBG.Dec(a1x)
    DBG.Str(STRING(" "))
    DBG.Dec(a1y)
    DBG.Str(STRING(" "))
    DBG.Dec(a1z)
    DBG.Str(STRING(" ")) 
    DBG.Dec(a2x)
    DBG.Str(STRING(" "))
    DBG.Dec(a2y)
    DBG.Str(STRING(" "))
    DBG.Dec(a2z)
    DBG.Str(STRING(" "))
    DBG.Dec(a3x)
    DBG.Str(STRING(" "))
    DBG.Dec(a3y)
    DBG.Str(STRING(" "))
    DBG.Dec(a3z)
    DBG.Str(STRING(" "))
    DBG.Dec(a4x)
    DBG.Str(STRING(" "))
    DBG.Dec(a4y)
    DBG.Str(STRING(" "))
    DBG.Dec(a4z)
    DBG.Str(STRING("  "))
    DBG.Dec(cntr)
    DBG.Str(STRING("          ", 13, 5))

WAITCNT(4 * CLKFREQ + CNT)    
'-------------------------------------------------------------------------


PRI H48C_Demo1(rate, secs) | i, n
'-------------------------------------------------------------------------
'-----------------------------┌────────────┐------------------------------
'-----------------------------│ H48C_Demo1 │------------------------------
'-----------------------------└────────────┘------------------------------
'-------------------------------------------------------------------------
'     Action: Demonstrates timing of sequential 3-axis readouts
' Parameters: -Rate
'             -Seconds
'    Results: None
'+Reads/Uses: -a1x, a1y, a1z, t1                 global variables
'             -a2x, a2y, a2z, t2                 global variables
'             -a3x, a3y, a3z, t3                 global variables
'             -a4x, a4y, a4z, t4                 global variables
'    +Writes: None
'      Calls: FullDuplexSerialPlus-------------->DBG.Str
'                                                DBG.Dec
'             H48C_Sync_Driver------------------>H48C_1.Read_Acceleration
'                                                H48C_2.Read_Acceleration
'                                                H48C_3.Read_Acceleration
'                                                H48C_4.Read_Acceleration
'-------------------------------------------------------------------------
DBG.Str(STRING(10, 13, 13))
DBG.Str(STRING("CNT timings of 3-axis sequential readouts of the sensors."))
DBG.Str(STRING(10, 13))
DBG.Str(STRING("Check the increasing CNT time points of the measurements."))
DBG.Str(STRING(10, 13, 13)) 
DBG.Str(STRING("     t1        t2        t3        t4      Cntr"))
DBG.Str(STRING(10, 13))
DBG.Str(STRING("================================================"))   
DBG.Str(STRING(10, 13))

cntr := 0
time := CNT
dTime := CLKFREQ / rate
n := secs * rate

i~
REPEAT n
  cntr++   
  WAITCNT(time + dTime)
  time := time + dTime 
  'Read acceleration values from H48C
  H48C_1.Read_Acceleration(@a1x, @a1y, @a1z, @t1)
  H48C_2.Read_Acceleration(@a2x, @a2y, @a2z, @t2)
  H48C_3.Read_Acceleration(@a3x, @a3y, @a3z, @t3)
  H48C_4.Read_Acceleration(@a4x, @a4y, @a4z, @t4)
  i++
  IF i > 9
    i~
    DBG.Dec(t1)
    DBG.Str(STRING(" "))
    DBG.Dec(t2)
    DBG.Str(STRING(" "))
    DBG.Dec(t3)
    DBG.Str(STRING(" ")) 
    DBG.Dec(t4)
    DBG.Str(STRING(" "))  
    DBG.Dec(cntr)
    DBG.Str(STRING("                   ", 13, 5))

WAITCNT(8 * CLKFREQ + CNT)    
'-------------------------------------------------------------------------


PRI H48C_Demo2(rate, secs) | i, n
'-------------------------------------------------------------------------
'-----------------------------┌────────────┐------------------------------
'-----------------------------│ H48C_Demo2 │------------------------------
'-----------------------------└────────────┘------------------------------
'-------------------------------------------------------------------------
'     Action: Demonstrates synchronous 3-axis readouts of H48C sensors
' Parameters: -Rate
'             -Seconds
'    Results: None
'+Reads/Uses: -a1x, a1y, a1z, t1                 global variables
'             -a2x, a2y, a2z, t2                 global variables
'             -a3x, a3y, a3z, t3                 global variables
'             -a4x, a4y, a4z, t4                 global variables
'    +Writes: None
'      Calls: FullDuplexSerialPlus-------------->DBG.Str
'                                                DBG.Dec
'             H48C_Sync_Driver------------------>H48C_1.Dwell_Mode_On
'                                                H48C_2.Dwell_Mode_On
'                                                H48C_3.Dwell_Mode_On
'                                                H48C_4.Dwell_Mode_On
'             H48C_Sync_Driver------------------>H48C_1.Dwell_Acceleration
'                                                H48C_2.Dwell_Acceleration
'                                                H48C_3.Dwell_Acceleration
'                                                H48C_4.Dwell_Acceleration
'             H48C_Sync_Driver------------------>H48C_1.Dwell_Mode_Off
'                                                H48C_2.Dwell_Mode_Off
'                                                H48C_3.Dwell_Mode_Off
'                                                H48C_4.Dwell_Mode_Off
'       Note: Dwell Clock should be started before this procedure
'-------------------------------------------------------------------------
H48C_1.Dwell_Mode_On
H48C_2.Dwell_Mode_On
H48C_3.Dwell_Mode_On
H48C_4.Dwell_Mode_On 

DBG.Str(STRING("Synchronized 3-axis readouts of the sensors at 50 Hz."))
DBG.Str(STRING(10, 13))
DBG.Str(STRING("All data collections start at L to H transition at A12."))
DBG.Str(STRING(10, 13, 13)) 
DBG.Str(STRING(" Ax  Ay  Az   Ax  Ay  Az   Ax  Ay  Az  Ax  Ay  Az  Cntr"))
DBG.Str(STRING(10, 13))
DBG.Str(STRING("======================================================="))      
DBG.Str(STRING(10, 13))

cntr := 0
time := CNT
dTime := CLKFREQ / rate
n := secs * rate

i~
REPEAT n
  cntr++   
  WAITCNT(time + dTime)
  time := time + dTime 
  'Read acceleration values from H48C in Dwell mode. Sensors are accessed
  'one after the other, but time of measurement will be the same, since it
  'is synchronized to the Dwell Clock signal
  H48C_1.Dwell_Acceleration(@a1x, @a1y, @a1z, @t1)
  H48C_2.Dwell_Acceleration(@a2x, @a2y, @a2z, @t2)
  H48C_3.Dwell_Acceleration(@a3x, @a3y, @a3z, @t3)
  H48C_4.Dwell_Acceleration(@a4x, @a4y, @a4z, @t4)
  i++
  IF i > 9
    i~
    DBG.Dec(a1x)
    DBG.Str(STRING(" "))
    DBG.Dec(a1y)
    DBG.Str(STRING(" "))
    DBG.Dec(a1z)
    DBG.Str(STRING(" ")) 
    DBG.Dec(a2x)
    DBG.Str(STRING(" "))
    DBG.Dec(a2y)
    DBG.Str(STRING(" "))
    DBG.Dec(a2z)
    DBG.Str(STRING(" "))
    DBG.Dec(a3x)
    DBG.Str(STRING(" "))
    DBG.Dec(a3y)
    DBG.Str(STRING(" "))
    DBG.Dec(a3z)
    DBG.Str(STRING(" "))
    DBG.Dec(a4x)
    DBG.Str(STRING(" "))
    DBG.Dec(a4y)
    DBG.Str(STRING(" "))
    DBG.Dec(a4z)
    DBG.Str(STRING("  "))
    DBG.Dec(cntr)
    DBG.Str(STRING("          ", 13, 5))

H48C_1.Dwell_Mode_Off
H48C_2.Dwell_Mode_Off
H48C_3.Dwell_Mode_Off
H48C_4.Dwell_Mode_Off

WAITCNT(4 * CLKFREQ + CNT)
'-------------------------------------------------------------------------



PRI H48C_Demo3(rate, secs) | i, n
'-------------------------------------------------------------------------
'-----------------------------┌────────────┐------------------------------
'-----------------------------│ H48C_Demo3 │------------------------------
'-----------------------------└────────────┘------------------------------
'-------------------------------------------------------------------------
'     Action: Demonstrates timing of synchronous 3-axis readouts of H48Cs
' Parameters: -Rate
'             -Seconds
'    Results: None
'+Reads/Uses: -a1x, a1y, a1z, t1                 global variables
'             -a2x, a2y, a2z, t2                 global variables
'             -a3x, a3y, a3z, t3                 global variables
'             -a4x, a4y, a4z, t4                 global variables
'    +Writes: None
'      Calls: FullDuplexSerialPlus-------------->DBG.Str
'                                                DBG.Dec
'             H48C_Sync_Driver------------------>H48C_1.Dwell_Mode_On
'                                                H48C_2.Dwell_Mode_On
'                                                H48C_3.Dwell_Mode_On
'                                                H48C_4.Dwell_Mode_On
'             H48C_Sync_Driver------------------>H48C_1.Dwell_Acceleration
'                                                H48C_2.Dwell_Acceleration
'                                                H48C_3.Dwell_Acceleration
'                                                H48C_4.Dwell_Acceleration
'             H48C_Sync_Driver------------------>H48C_1.Dwell_Mode_Off
'                                                H48C_2.Dwell_Mode_Off
'                                                H48C_3.Dwell_Mode_Off
'                                                H48C_4.Dwell_Mode_Off
'       Note: Dwell Clock should be started before this procedure
'-------------------------------------------------------------------------
H48C_1.Dwell_Mode_On
H48C_2.Dwell_Mode_On
H48C_3.Dwell_Mode_On
H48C_4.Dwell_Mode_On 

DBG.Str(STRING(10, 13, 13))
DBG.Str(STRING("Timing of 3-axis synchronous readouts of the sensors."))
DBG.Str(STRING(10, 13))
DBG.Str(STRING("Check the identical CNT time points of the measurements."))
DBG.Str(STRING(10, 13, 13)) 
DBG.Str(STRING("     t1        t2        t3        t4      Cntr"))
DBG.Str(STRING(10, 13))
DBG.Str(STRING("================================================"))   
DBG.Str(STRING(10, 13))

cntr := 0
time := CNT
dTime := CLKFREQ / rate
n := secs * rate

i~
REPEAT n
  cntr++   
  WAITCNT(time + dTime)
  time := time + dTime 
  'Read acceleration values from H48C in Dwell mode. Sensors are accessed
  'one after the other, but time of measurement will be the same, since it
  'is synchronized to the Dwell Clock signal
  H48C_1.Dwell_Acceleration(@a1x, @a1y, @a1z, @t1)
  H48C_2.Dwell_Acceleration(@a2x, @a2y, @a2z, @t2)
  H48C_3.Dwell_Acceleration(@a3x, @a3y, @a3z, @t3)
  H48C_4.Dwell_Acceleration(@a4x, @a4y, @a4z, @t4)
  i++
  IF i > 9
    i~
    DBG.Dec(t1)
    DBG.Str(STRING(" "))
    DBG.Dec(t2)
    DBG.Str(STRING(" "))
    DBG.Dec(t3)
    DBG.Str(STRING(" ")) 
    DBG.Dec(t4)
    DBG.Str(STRING(" "))  
    DBG.Dec(cntr)
    DBG.Str(STRING("                   ", 13, 5))

H48C_1.Dwell_Mode_Off
H48C_2.Dwell_Mode_Off
H48C_3.Dwell_Mode_Off
H48C_4.Dwell_Mode_Off

WAITCNT(8 * CLKFREQ + CNT) 
'-------------------------------------------------------------------------



PRI H48C_Demo4(rate, secs) | i, n, pt1, pt2, pt3, pt4, dt1, dt2, dt3, dt4
'-------------------------------------------------------------------------
'-----------------------------┌────────────┐------------------------------
'-----------------------------│ H48C_Demo4 │------------------------------
'-----------------------------└────────────┘------------------------------
'-------------------------------------------------------------------------
'     Action: Demonstrates timing interval of synchronous 3-axis readouts 
' Parameters: -Rate
'             -Seconds
'    Results: None
'+Reads/Uses: -a1x, a1y, a1z, t1                 global variables
'             -a2x, a2y, a2z, t2                 global variables
'             -a3x, a3y, a3z, t3                 global variables
'             -a4x, a4y, a4z, t4                 global variables
'    +Writes: None
'      Calls: FullDuplexSerialPlus-------------->DBG.Str
'                                                DBG.Dec
'             H48C_Sync_Driver------------------>H48C_1.Dwell_Mode_On
'                                                H48C_2.Dwell_Mode_On
'                                                H48C_3.Dwell_Mode_On
'                                                H48C_4.Dwell_Mode_On
'             H48C_Sync_Driver------------------>H48C_1.Dwell_Acceleration
'                                                H48C_2.Dwell_Acceleration
'                                                H48C_3.Dwell_Acceleration
'                                                H48C_4.Dwell_Acceleration
'             H48C_Sync_Driver------------------>H48C_1.Dwell_Mode_Off
'                                                H48C_2.Dwell_Mode_Off
'                                                H48C_3.Dwell_Mode_Off
'                                                H48C_4.Dwell_Mode_Off
'       Note: Dwell Clock should be started before this procedure
'-------------------------------------------------------------------------
H48C_1.Dwell_Mode_On
H48C_2.Dwell_Mode_On
H48C_3.Dwell_Mode_On
H48C_4.Dwell_Mode_On 

DBG.Str(STRING(10, 13, 13))
DBG.Str(STRING("Time intervals between 3-axis synchronous readouts."))
DBG.Str(STRING(10, 13))
DBG.Str(STRING("Check the intervals to be 20(+-0.005) msec at 80 MHz."))
DBG.Str(STRING(10, 13, 13)) 
DBG.Str(STRING("   t1      t2      t3      t4   Cntr"))
DBG.Str(STRING(10, 13))
DBG.Str(STRING("===================================="))  
DBG.Str(STRING(10, 13))

cntr := 0
time := CNT
dTime := CLKFREQ / rate
n := secs * rate

i~
REPEAT n
  cntr++   
  WAITCNT(time + dTime)
  time := time + dTime 
  'Read acceleration values from H48C in Dwell mode. Sensors are accessed
  'one after the other, but time of measurement will be the same, since it
  'is synchronized to the Dwell Clock signal
  pt1 := t1
  pt2 := t2
  pt3 := t3
  pt4 := t4
  H48C_1.Dwell_Acceleration(@a1x, @a1y, @a1z, @t1)
  H48C_2.Dwell_Acceleration(@a2x, @a2y, @a2z, @t2)
  H48C_3.Dwell_Acceleration(@a3x, @a3y, @a3z, @t3)
  H48C_4.Dwell_Acceleration(@a4x, @a4y, @a4z, @t4)
  dt1 := t1 - pt1
  dt2 := t2 - pt2
  dt3 := t3 - pt3
  dt4 := t4 - pt4
  i++
  IF i > 9
    i~
    DBG.Dec(dt1)
    DBG.Str(STRING(" "))
    DBG.Dec(dt2)
    DBG.Str(STRING(" "))
    DBG.Dec(dt3)
    DBG.Str(STRING(" ")) 
    DBG.Dec(dt4)
    DBG.Str(STRING(" "))  
    DBG.Dec(cntr)
    DBG.Str(STRING("                   ", 13, 5))

H48C_1.Dwell_Mode_Off
H48C_2.Dwell_Mode_Off
H48C_3.Dwell_Mode_Off
H48C_4.Dwell_Mode_Off        
'-------------------------------------------------------------------------


{{
┌────────────────────────────────────────────────────────────────────────┐
│                        TERMS OF USE: MIT License                       │                                                            
├────────────────────────────────────────────────────────────────────────┤
│  Permission is hereby granted, free of charge, to any person obtaining │
│ a copy of this software and associated documentation files (the        │ 
│ "Software"), to deal in the Software without restriction, including    │
│ without limitation the rights to use, copy, modify, merge, publish,    │
│ distribute, sublicense, and/or sell copies of the Software, and to     │
│ permit persons to whom the Software is furnished to do so, subject to  │
│ the following conditions:                                              │
│                                                                        │
│  The above copyright notice and this permission notice shall be        │
│ included in all copies or substantial portions of the Software.        │  
│                                                                        │
│  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND        │
│ EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF     │
│ MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. │
│ IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY   │
│ CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,   │
│ TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE      │
│ SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.                 │
└────────────────────────────────────────────────────────────────────────┘
}}                  