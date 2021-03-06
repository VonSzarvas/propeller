{{
┌───────────────────────────────┬───────────────────┬────────────────────┐
│   GPS_Float_Lite.spin v1.0    │ Author: I.Kövesdi │ Rel.: 24. jan 2009 │  
├───────────────────────────────┴───────────────────┴────────────────────┤
│                    Copyright (c) 2009 CompElit Inc.                    │               
│                   See end of file for terms of use.                    │               
├────────────────────────────────────────────────────────────────────────┤
│                                                                        │ 
│  The 'GPS_Float_Lite' driver object bridges a SPIN program to the      │
│ strings and longs provided by the basic 'GPS_Str_NMEA_Lite' driver and │
│ translates them into long and float values and checks errors wherever  │
│ appropriate.                                                           │
│                                                                        │  
├────────────────────────────────────────────────────────────────────────┤
│ Background and Detail:                                                 │
│   Using 32 bit floats gives you simpler and easier to debug programming│
│ of computation intensive tasks and much higher dynamic range (>10^60)  │
│ when compared with 32 bit integer calculations. However, you have to   │
│ pay for these advantages with much longer execution times and with more│
│ COGs to use. Even the precision digit count of IEEE-754 floats (>7, <8)│
│ can be easily beaten with a carefully designed 32 bit integer math. In │
│ spite of all these good features of integer arithmetic, when ease of   │
│ program maintenance, expandability and adherence to a well proven      │
│ industry standard are factors in your decision, then you may use this  │
│ 'float' driver successfully in GPS data processing.                    │
│  However, if you want to be very fast, or smart, you can use clever and│
│ efficient integer arithmetic. Even then you also can use the lower     │
│ level 'GPS_Str_NMEA' or 'GPS_Str_NMEA_Lite' drivers as  stable and     │
│ robust data providers for your integer algorithms.                     │
│                                                                        │ 
├────────────────────────────────────────────────────────────────────────┤
│ Note:                                                                  │
│  This driver has the "GPS_Float.spin v1.0" Driver as its heavy sibling │
│ but with much more features.                                           │
│                                                                        │
└────────────────────────────────────────────────────────────────────────┘


}}


CON

_CLKMODE         = XTAL1 + PLL16x
_XINFREQ         = 5_000_000


        
_RX_FM_GPS        = 7
_TX_TO_GPS        = 8

_GPS_SER_MODE     = %0000    '(Usual) serial comm mode with a GPS
'                    
'                    │││└─────Mode bit 0 = invert rx
'                    ││└──────Mode bit 1 = invert tx
'                    │└───────Mode bit 2 = open-drain/source tx
'                    └────────Mode bit 3 = ignore tx, echo on rx

 
_GPS_SER_BAUD     = 4_800    '(Usual) serial Baud rate with a GPS
                             'Cross-check this value with the actual
                             'setting of your GPS. If the unit supports
                             'higher baud rate switch to it!

'_GPS_SER_MODE     = %0001    'Serial comm mode with a Magellan 330 GPS                            
                             'One of the 3 different brand and type of GPS
                             'Talker used during testing and debugging


'_GPS_SER_BAUD     = 19_200   'GPS_NMEA.spin Driver were succesfully
'_GPS_SER_BAUD     = 38_400   'tested at these baud rates, as well
'_GPS_SER_BAUD     = 57_600
'_GPS_SER_BAUD     = 115_200

'RS-232 connection to GPS
'========================
'When you connect a GPS to the Propeller (or to a computer), you need to
'know something about the RS-232 serial ports since they are often used
'in GPS units or with active GPS antennas. GPSs usually have DBF-9 male 
'serial connectors configured as a DCE (see later). Active GPS antennas 
'can have special micro connectors or serial cables equipped with, for
'example, PS-2 male connector.
'Connection pinouts of DBF-9:
'----------------------------
'The RS-232 standard defines two classes of devices that may talk using
'RS-232 serial data - Data Terminal Equipment (DTE), and Data
'Communication Equipment (DCE). Computers and terminals are considered
'DTE, while peripherals, such as a GPS unit, are DCE. DTEs (PCs) transmit
'via Pin 3 and receive via Pin 2. DCEs (e.g. GPSs) transmit via Pin 2 and
'receive via Pin 3. So the standard defines pinouts for DTE and DCE such
'that a "straight through" cable (pin 2 to pin 2, 3 to 3, etc) can be used
'between a DTE and DCE. To connect two DTEs or two DCEs together, you need
'a "null modem" cable, that swaps pins between the two ends (e.g. pin 2 to
'3, 3 to 2). Unfortunately, there is sometimes disagreement whether a
'certain device is DTE or DCE. Consult carefully the description and data
'sheet of the GPS or use an oscilloscope to check pinout of the device to
'identify its Tx pin, voltage levels and baud rate.
'Voltages:
'---------
'RS-232 is single-ended, which means that the transmit and receive lines
'are referenced to a common ground. A typical RS-232 signal swings
'positive and negative. Standard RS-232 voltages, the MARK(1) and SPACE(0)
'signals on the line, are somewhere in the range -3 ...-15V and +3...+15V,
'respectively. So you may effectively kill your Prop or FPU if you just
'simply connect a Tx line directly to the pins. Many GPS devices, however,
'transmit and receive using only -5V/5V MARK(1)/SPACE(0) levels or just
'5V/0V TTL signal levels. Check this with a scope or read manual. The
'connection of the TTL level lines of a 5V/0V device is straightforward.
'You only need to use a 1-2K series resistor between the Tx line of the GPS
'and of the Rx Pin of the Prop. The TTL Rx line of the GPS can nicely
'accept the >3V output high level of the Prop directly. For standard RS-232
'connection use one of the MAX232(3) family of level converter chips.   
'Polarity:
'---------
'Standard RS-232 signals are inverted with respect to the TTL convention
'where 0V = Low and 5V = High. In RS232, for example,  -10V means High and
'+10V means Low. Fortunately, the RS-232 line drivers take us the favor
'and invert those signals. However, when you talk or listen through a
'custom made or home built level converter, you should be aware of this
'polarity inversion.
'Cable length and transmission speed:
'------------------------------------
'The standards for RS-232 and similar interfaces usually  restrict RS-232
'to 20K baud or less and line lengths of 15 m (50 ft) or less. These
'restrictions are mostly throwbacks to the days when 20K baud was             
'considered a very high line speed, and cables were thick, with high
'capacitance. However, in practice, RS-232 is far more robust than the 
'traditional specified limits of 20K baud over a 15 m line would imply.
'RS-232 is perfectly adequate at speeds up to 200K baud, if the cable is 
'well screened and grounded. The 15 m limitation for cable length can be
'stretched to about 100 m if the cable is low capacitance as well.
'Networking:
'-----------
'RS-232 is not Multi-drop. You can only connect one RS-232 device per 
'port. There are some devices designed to echo a command to a second unit
'of the same family of products, but this is very rare. This means that if
'you have 3 DCE peripherals to connect to a PC, which is a DTE as we know,
'you will need 3 ports on the PC.


OBJ

NMEA              : "GPS_Str_NMEA_Lite"
  
F                 : "FloatMath"


PUB Init : oKay 
'-------------------------------------------------------------------------
'-----------------------------------┌──────┐------------------------------
'-----------------------------------│ Init │------------------------------
'-----------------------------------└──────┘------------------------------
'-------------------------------------------------------------------------
''     Action: -Starts those drivers that will launch a COG directly or
''              implicitly
''             -Checks for a succesfull start
'' Parameters: None                                 
''    Results: TRUE if start is succesfull, else FALSE                     
''+Reads/Uses: NMEA serial interface hardware and software parameters:
''             _RX_FM_GPS,
''             _TX_TO_GPS,
''             _GPS_SER_MODE,
''             _GPS_SER_BAUD                                               
''    +Writes: None                                    
''      Calls: GPS_Str_NMEA-------->NMEA.Start (uses 2 COGs + COG0)
''             Float32Full--------->F.Start    (uses 2 COGs + COG0)                           
'-------------------------------------------------------------------------

'Start 'GPS_Str_NMEA' Driver object. This Driver will launch 2 COGs
oKay := NMEA.StartCOGs(_RX_FM_GPS,_TX_TO_GPS,_GPS_SER_MODE,_GPS_SER_BAUD)

RETURN oKay


PUB Stop
'-------------------------------------------------------------------------
'-----------------------------------┌──────┐------------------------------
'-----------------------------------│ Stop │------------------------------
'-----------------------------------└──────┘------------------------------
'-------------------------------------------------------------------------
''     Action: Stops drivers that use separate COG
'' Parameters: None                                 
''    Results: None                     
''+Reads/Uses: None                                               
''    +Writes: None                                    
''      Calls: GPS_Str_NMEA---------------->NMEA.StopCOGs
'-------------------------------------------------------------------------

NMEA.StopCOGs
'-------------------------------------------------------------------------


PUB Long_Year | p, y
'-------------------------------------------------------------------------
'---------------------------------┌───────────┐---------------------------
'---------------------------------│ Long_Year │---------------------------
'---------------------------------└───────────┘---------------------------
'-------------------------------------------------------------------------
''     Action: It returns UTC year                  
'' Parameters: None                                 
''    Results: UTC year as long, for example 2009                                  
''+Reads/Uses: None                                               
''    +Writes: None                                    
''      Calls: GPS_Str_NMEA------------->NMEA.Str_UTC_Date                           
'-------------------------------------------------------------------------

p := NMEA.Str_UTC_Date

CASE y := 10 * BYTE[p + 4] + BYTE[p + 5] + $5C0
  2008..2020:
  OTHER: y := -1
  
RETURN y  
'-------------------------------------------------------------------------


PUB Long_Month | p, m
'-------------------------------------------------------------------------
'--------------------------------┌────────────┐---------------------------
'--------------------------------│ Long_Month │---------------------------
'--------------------------------└────────────┘---------------------------
'-------------------------------------------------------------------------
''     Action: It returns UTC month                 
'' Parameters: None                                 
''    Results: UTC month as long, for example 2 for February                       
''+Reads/Uses: None                                               
''    +Writes: None                                    
''      Calls: GPS_Str_NMEA------------->NMEA.Str_UTC_Date                           
'-------------------------------------------------------------------------

p := NMEA.Str_UTC_Date

CASE m := 10 * BYTE[p + 2] + BYTE[p + 3] - $210 
  1..12:
  OTHER: m := -1

RETURN m
'-------------------------------------------------------------------------
  

PUB Long_Day | p, d            
'-------------------------------------------------------------------------
'---------------------------------┌──────────┐----------------------------
'---------------------------------│ Long_Day │----------------------------
'---------------------------------└──────────┘----------------------------
'-------------------------------------------------------------------------
''     Action: It returns UTC day                   
'' Parameters: None                                 
''    Results: UTC day as long                                                     
''+Reads/Uses: None                                               
''    +Writes: None                                    
''      Calls: GPS_Str_NMEA------------->NMEA.Str_UTC_Date                           
'-------------------------------------------------------------------------

p := NMEA.Str_UTC_Date 

CASE d :=  10 * BYTE[p] + BYTE[p + 1] - $210
  1..31:
  OTHER: d := -1

RETURN d
'-------------------------------------------------------------------------


PUB Long_Hour | p, h
'-------------------------------------------------------------------------
'--------------------------------┌───────────┐----------------------------
'--------------------------------│ Long_Hour │----------------------------
'--------------------------------└───────────┘----------------------------
'-------------------------------------------------------------------------
''     Action: It returns UTC hour                  
'' Parameters: None                                 
''    Results: UTC hour as long
''+Reads/Uses: None                                               
''    +Writes: None                                    
''      Calls: GPS_Str_NMEA------------->NMEA.Str_UTC_Time                           
'-------------------------------------------------------------------------

p := NMEA.Str_UTC_Time

CASE h := 10 * BYTE[p] + BYTE[p + 1] - $210
  0..24:
  OTHER: h := -1

RETURN h  
'-------------------------------------------------------------------------


PUB Long_Minute | p, m
'-------------------------------------------------------------------------
'-------------------------------┌─────────────┐---------------------------
'-------------------------------│ Long_Minute │---------------------------
'-------------------------------└─────────────┘---------------------------
'-------------------------------------------------------------------------
''     Action: It returns UTC minute                
'' Parameters: None                                 
''    Results: UTC minute as long
''+Reads/Uses: None                                               
''    +Writes: None                                    
''      Calls: GPS_Str_NMEA------------->NMEA.Str_UTC_Time                           
'-------------------------------------------------------------------------

p := NMEA.Str_UTC_Time

CASE m := 10 * BYTE[p + 2] + BYTE[p + 3] - $210
  0..59:
  OTHER: m := -1

RETURN m
'-------------------------------------------------------------------------


PUB Long_Second | p, s
'-------------------------------------------------------------------------
'-------------------------------┌─────────────┐---------------------------
'-------------------------------│ Long_Second │---------------------------
'-------------------------------└─────────────┘---------------------------
'-------------------------------------------------------------------------
''     Action: It returns UTC second                
'' Parameters: None                                 
''    Results: UTC second as long
''+Reads/Uses: None                                               
''    +Writes: None                                    
''      Calls: GPS_Str_NMEA------------->NMEA.Str_UTC_Time
''       Note: Fractions of seconds are ingnored
'-------------------------------------------------------------------------

p := NMEA.Str_UTC_Time
CASE s := 10 * BYTE[p + 4] + BYTE[p + 5] - $210
  0..59:
  OTHER: s := -1

RETURN s  
'-------------------------------------------------------------------------
  

PUB Float_Latitude_Deg : floatVal | p, d, m, mf, fd
'-------------------------------------------------------------------------
'--------------------------┌────────────────────┐-------------------------
'--------------------------│ Float_Latitude_Deg │-------------------------
'--------------------------└────────────────────┘-------------------------
'-------------------------------------------------------------------------
''     Action: It returns Latitude in decimal degrees
'' Parameters: None                                 
''    Results: Latitude in signed float as decimal degrees
''+Reads/Uses: floatNaN                                               
''    +Writes: None                                    
''      Calls: GPS_Str_NMEA-------------->NMEA.Str_Latitude
''                                        NMEA.Str_Lat_N_S 
''             Float32Full--------------->F.FFloat
''                                        F.FAdd
''                                        F.FDiv
'-------------------------------------------------------------------------

p := NMEA.Str_Latitude

'Check for not "D", I.e. data received
IF BYTE[p] == "D"
  RETURN floatNaN
'Cross check decimal point to be sure
IF BYTE[p + 4] <> "."
  RETURN floatNaN
  
d := 10 * BYTE[p] + BYTE[p + 1] - $210
m := 10 * BYTE[p + 2] + BYTE[p + 3] - $210

CASE STRSIZE(p)
  8:
    mf := 10*(10*BYTE[p+5]+BYTE[p+6])+BYTE[p+7]-$14D0
    fd := 1000.0 
  9:
    mf := 10*(10*(10*BYTE[p+5]+BYTE[p+6])+BYTE[p+7])+BYTE[p+8]-$D050
    fd := 10_000.0
    
m := F.FAdd(F.FFloat(m),F.FDiv(F.FFloat(mf),fd))
d := F.Fadd(F.FFloat(d),F.FDiv(m,60.0))

'Check N S hemispheres
p := NMEA.Str_Lat_N_S
IF BYTE[p] == "S"
  d ^= $8000_0000           'Negate it

RETURN d
'-------------------------------------------------------------------------


PUB Float_Longitude_Deg : floatVal | p, d, m, mf, fd
'-------------------------------------------------------------------------
'------------------------┌─────────────────────┐--------------------------
'------------------------│ Float_Longitude_Deg │--------------------------
'------------------------└─────────────────────┘--------------------------
'-------------------------------------------------------------------------
''     Action: It returns Longitude in decimal degrees
'' Parameters: None                                 
''    Results: Longitude in signed float as decimal degrees
''+Reads/Uses: floatNaN                                               
''    +Writes: None                                    
''      Calls: GPS_Str_NMEA-------------->NMEA.Str_Longitude
''                                        NMEA.Str_Lon_E_W
''             Float32Full--------------->F.FFloat
''                                        F.FAdd
''                                        F.FDiv                  
'-------------------------------------------------------------------------

p := NMEA.Str_Longitude

'Check for not "D", I.e. data received
IF BYTE[p] == "D"
  RETURN floatNaN
'Cross check decimal point to be sure
IF BYTE[p + 5] <> "."
  RETURN floatNaN
  
d := 10 * ( 10 * BYTE[p] + BYTE[p + 1]) + BYTE[p + 2] - $14D0
m := 10 * BYTE[p + 3] + BYTE[p + 4] - $210
 
CASE STRSIZE(p)
  9:
    mf := 10*(10*BYTE[p+6]+BYTE[p+7])+BYTE[p+8]-$14D0
    fd := 1000.0 
  10:
    mf := 10*(10*(10*BYTE[p+6]+BYTE[p+7])+BYTE[p+8])+BYTE[p+9]-$D050
    fd := 10_000.0
    
m := F.FAdd(F.FFloat(m),F.FDiv(F.FFloat(mf),fd))
d := F.Fadd(F.FFloat(d),F.FDiv(m,60.0))

'Check E W hemispheres
p := NMEA.Str_Lon_E_W
IF BYTE[p] == "W"
  d ^= $8000_0000           'Negate it

RETURN d
'-------------------------------------------------------------------------


PUB Float_Course_Over_Ground 
'-------------------------------------------------------------------------
'-----------------------┌──────────────────────────┐----------------------
'-----------------------│ Float_Course_Over_Ground │----------------------
'-----------------------└──────────────────────────┘----------------------
'-------------------------------------------------------------------------
''     Action: It returns course over ground in decimal degrees
'' Parameters: None                                 
''    Results: course in float as decimal degrees (0.00 - 359.99)
''+Reads/Uses: None                                               
''    +Writes: None                                    
''      Calls: GPS_Str_NMEA------------->NMEA.Str_Course_Over_Ground
''             S2F                 
'-------------------------------------------------------------------------

RESULT := S2F(NMEA.Str_Course_Over_Ground)
'-------------------------------------------------------------------------


PUB Float_Speed_Over_Ground 
'-------------------------------------------------------------------------
'-----------------------┌─────────────────────────┐-----------------------
'-----------------------│ Float_Speed_Over_Ground │-----------------------
'-----------------------└─────────────────────────┘-----------------------
'-------------------------------------------------------------------------
''     Action: It returns speed over ground in knots
'' Parameters: None                                 
''    Results: speed in knots as float
''+Reads/Uses: None                                               
''    +Writes: None                                    
''      Calls: GPS_Str_NMEA------------->NMEA.Str_Speed_Over_Ground
''             S2F
''       Note: Some GPS units does not calculate speed over a given limit.
''             Check manual                                                           
'-------------------------------------------------------------------------

RESULT := S2F(NMEA.Str_Speed_Over_Ground)
'-------------------------------------------------------------------------


PUB Float_Altitude_Above_MSL
'-------------------------------------------------------------------------
'----------------------┌──────────────────────────┐-----------------------
'----------------------│ Float_Altitude_Above_MSL │-----------------------
'----------------------└──────────────────────────┘-----------------------
'-------------------------------------------------------------------------
''     Action: It returns altitude above MSL in a given unit
'' Parameters: None                                 
''    Results: float altitude usually in [m], but it can be in [ft], too
''+Reads/Uses: None                                               
''    +Writes: None                                    
''      Calls: GPS_Str_NMEA------------->NMEA.Str_Altitude_Above_MSL
''             S2F                               
'-------------------------------------------------------------------------

RESULT := S2F(NMEA.Str_Altitude_Above_MSL)
'-------------------------------------------------------------------------


PUB Str_Altitude_Unit
'-------------------------------------------------------------------------
'---------------------------┌───────────────────┐-------------------------
'---------------------------│ Str_Altitude_Unit │-------------------------
'---------------------------└───────────────────┘-------------------------
'-------------------------------------------------------------------------
''     Action: It returns the unit of the altitude data
'' Parameters: None                                 
''    Results: [m] or [ft]
''+Reads/Uses: None                                               
''    +Writes: None                                    
''      Calls: GPS_Str_NMEA------------->NMEA.Str_Altitude_Unit                                                                            
'-------------------------------------------------------------------------

RESULT := NMEA.Str_Altitude_Unit
'-------------------------------------------------------------------------


PUB Float_Geoid_Height
'-------------------------------------------------------------------------
'--------------------------┌────────────────────┐-------------------------
'--------------------------│ Float_Geoid_Height │-------------------------
'--------------------------└────────────────────┘-------------------------
'-------------------------------------------------------------------------
''     Action: It returns the Geoid Height to WGS84 ellipsoid
'' Parameters: None                                 
''    Results: Float Geoid Height (usually in [m])
''+Reads/Uses: None                                               
''    +Writes: None                                    
''      Calls: GPS_Str_NMEA------------->NMEA.Str_Geoid_Height
''             S2F   
''       Note: Geoid Height is, in a very good approximation, the Mean See
''             Level (MSL) referred to the WGS84 ellipsoid                                                                                     
'-------------------------------------------------------------------------

RESULT := S2F(NMEA.Str_Geoid_Height)
'-------------------------------------------------------------------------


PUB Str_Geoid_Height_U
'-------------------------------------------------------------------------
'--------------------------┌────────────────────┐-------------------------
'--------------------------│ Str_Geoid_Height_U │-------------------------
'--------------------------└────────────────────┘-------------------------
'-------------------------------------------------------------------------
''     Action: It returns the unit of the Geoid Height
'' Parameters: None                                 
''    Results: Pointer to the string
''+Reads/Uses: None                                               
''    +Writes: None                                    
''      Calls: GPS_Str_NMEA------------->NMEA.Str_Geoid_Height_U                                                             
'-------------------------------------------------------------------------

RESULT := NMEA.Str_Geoid_Height_U
'-------------------------------------------------------------------------



PUB Float_Mag_Var_Deg | p, v
'-------------------------------------------------------------------------
'---------------------------┌───────────────────┐-------------------------
'---------------------------│ Float_Mag_Var_Deg │-------------------------
'---------------------------└───────────────────┘-------------------------
'-------------------------------------------------------------------------
''     Action: Returns magnetic variation value in decimal degrees                                                                 
'' Parameters: None                                 
''    Results: Magnetic variation as a signed float                                                                
''+Reads/Uses: None                                               
''    +Writes: None                                    
''      Calls: GPS_Str_NMEA------------->NMEA.Str_Mag_Variation
''                                       NMEA.Str_MagVar_E_W
''             S2F                                                                  
'-------------------------------------------------------------------------
'To calculate Magnetic heading from True heading

p := NMEA.Str_Mag_Variation

'Check for not "M", I.e., data received
IF BYTE[p] == "M"
  RETURN floatNaN

v := S2F(p)

IF v <> floatNaN 
  IF BYTE[NMEA.Str_MagVar_E_W] := "E"
    v ^= $8000_0000           'Remember: 'IF EAST MAGNETIC IS LEAST' 

RETURN v 
'-------------------------------------------------------------------------

 
    

PRI S2L(strPtr) | c, s
'-------------------------------------------------------------------------
'-----------------------------------┌─────┐-------------------------------
'-----------------------------------│ S2L │-------------------------------
'-----------------------------------└─────┘-------------------------------
'-------------------------------------------------------------------------
'     Action: Converts a string to long                                 
' Parameters: Pointer to the string                                
'    Results: Long value                                                               
'+Reads/Uses: floaNaN                                               
'    +Writes: None                                    
'      Calls: None
'       Note: No syntax check except for null strings. It assumes a
'             perfect string to describe small signed decimal integers
'-------------------------------------------------------------------------

IF STRSIZE(strPtr)           'Not a null string
  s~
  REPEAT WHILE c := BYTE[strPtr++]
    IF c == "-"
      s := -1
    ElSE      
      RESULT := RESULT * 10 + c - $30
  IF s
    RESULT := -1 * RESULT     
ELSE
  RESULT := floatNaN         'To signal invalid value since -1 can be a
                             'valid result in some proprietary sentence
'-------------------------------------------------------------------------


PRI S2F(strPtr) | i, e, s, b, sg
'-------------------------------------------------------------------------
'-----------------------------------┌─────┐-------------------------------
'-----------------------------------│ S2F │-------------------------------
'-----------------------------------└─────┘-------------------------------
'-------------------------------------------------------------------------
'     Action: Converts a string to float                                 
' Parameters: Pointer to the string                                 
'    Results: Float value                                                                
'+Reads/Uses: floatNaN                                               
'    +Writes: None                                    
'      Calls: None
'       Note: -It can handle only small numbers with max. 4 decimal digits
'             and no exponent. This is enough for the fields in NMEA data
'             where the field contains a string for a float value.
'             -No syntax check except for null strings. It assumes a
'             perfect string that represents small signed float value                                                             
'-------------------------------------------------------------------------
'NMEA String to Float routine. 

IF s := STRSIZE(strPtr)        'Not a null string
  i~                           'Value accumulator
  e~                           'Exponent counter
  sg~                          'Sign

  REPEAT s
    CASE b := BYTE[strPtr++]   'Actual character
      "-":
        sg := 1                'To remember negative sign
      ".":
        e := 1                 'Decimal  point detected. Actuate divider's
                               'accumulation
      "0".."9":
        i := 10 * i + b - $30  'Increment sum total
        IF e
          e++                  'Increment divider's exponent

  CASE --e                     'CASE used to avoid repeated float division
    -1, 0: RESULT := F.FFloat(i)
    1:     RESULT := F.FDIV(F.FFloat(i), 10.0)
    2:     RESULT := F.FDIV(F.FFloat(i), 100.0)
    3:     RESULT := F.FDIV(F.FFloat(i), 1000.0)
    4:     RESULT := F.FDIV(F.FFloat(i), 10_000.0)

  'Check for signum
  IF sg  
    RESULT ^= $8000_0000       'Negate it 
    
ELSE
  RESULT := floatNaN           'To signal invalid value
'-------------------------------------------------------------------------


DAT

floatNaN       LONG $7FFF_FFFF       'Not a Number code for invalid data
 

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