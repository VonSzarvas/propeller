{{
┌───────────────────────────────┬───────────────────┬────────────────────┐
│    SPIN_TrigPack.spin v2.0    │ Author: I.Kövesdi │  Rel.: 17.10.2011  │
├───────────────────────────────┴───────────────────┴────────────────────┤
│                    Copyright (c) 2011 CompElit Inc.                    │               
│                   See end of file for terms of use.                    │               
├────────────────────────────────────────────────────────────────────────┤
│  This small Qs15-16 Fixed-point trig package is written entirely in    │
│ SPIN and provides you complete floating point math and the basic       │
│ trigonometric functions for robot and navigation projects. You can     │
│ do ATAN2 without enlisting extra COGs to run a full Floating-point     │
│ library. This object has StringToNumber, NumberToString conversion     │
│ utilities to make Fixed-point math easy for your applications.         │
│  This object contains the first True Random Number Generator (TRNG)    │
│ with the Propeller microcontroller using only SPIN code. This TRNG will│
│ repeat its sequence only after the End of Times.                       │
│                                                                        │ 
├────────────────────────────────────────────────────────────────────────┤
│ Background and Detail:                                                 │
│  32-bit Fixed-point arithmetic with SPIN is done in Qs15_16 format. The│
│ Qvalue numbers have a sign bit, 15 bits for the integer part and 16    │
│ bits for the fraction.                                                 │
│                                                                        │ 
├────────────────────────────────────────────────────────────────────────┤
│ Note:                                                                  │
│  The author thanks Timmoore and Chuck Taylor for bug reports and good  │
│ suggestions.                                                           │
│                                                                        │
└────────────────────────────────────────────────────────────────────────┘

}}


CON

'General constants
_64K             = 65_536
_32K             = _64K / 2
_MAXABS          = _32K * _64K

_Q1              = _64K

_SEED            = 2011 * _Q1

_MAXANGLE        = 94_388_224  'Max angle [deg] in Qvalue before conv.

_SQRTWO          = 92_682      'sqr(2) in Qvalue format

'ROM address constants----------------------------------------------------
_BASE_SINTABLE   = $E000
_PIHALF          = $0800

'Procedure IDs
_STR2QVAL        = 1
_QVAL2STR        = 2
_QVAL            = 3
_INTFRAC2QVAL    = 4
_IANG2QVAL       = 5
_QVAL2IANG       = 6 
_DEG2RAD         = 7 
_RAD2DEG         = 8
_MUL             = 9 
_DIV             = 10
_MULDIV          = 11
_SQR             = 12
_SIND            = 13
_COSD            = 14
_TAND            = 15
_DASIN           = 16
_DACOS           = 17
_DATAN           = 18
_DATAN2          = 19
_QRADIUS         = 20
_SINR            = 21
_COSR            = 22
_TRNG            = 23
_PRNG            = 24

'Error IDs
_OVERFLOW        = 1
_DIVZERO         = 2
_INVALID_ARG     = 3
_STRFORM_ERR     = 4        

'Error response
_CONTINUE        = 0
_NOTIFY          = 1
_ABORT           = 2

'String parameters
_MAX_STR_LEN     = 12

'Trig
_270D            = 270 << 16
_180D            = 180 << 16
_90D             = 90 << 16 

 
VAR

'Global error variables
LONG             e_action       'Action on error  
LONG             e_orig         'ID of procedure where error occured
LONG             e_kind         'Type of error
LONG             e_arg1         'Critical procedure argument 1
LONG             e_arg2         'Critical procedure argument 2

'64-bit results
LONG             dQval[2]       '64-bit result

'RND Seed
LONG             qSeedTRNG      'Seed for Real Random Generator
LONG             qSeedPRNG      'Seed for Pseudo random Generator     

'Strings
BYTE             strB[_MAX_STR_LEN]    'String Buffer



PUB Start_Driver
'-------------------------------------------------------------------------
'-----------------------------┌──────────────┐----------------------------
'-----------------------------│ Start_Driver │----------------------------
'-----------------------------└──────────────┘----------------------------
'-------------------------------------------------------------------------
''     Action: - Initializes error handling
''             - Initializes Seed of random number generators
'' Parameters: None                              
''     Result: None              
''+Reads/Uses: _CONTINUE, _SEED                            (CON/LONG)
''    +Writes: e_action, qSeedPRNG, qSeedTRNG              (VAR/LONG)                      
''      Calls: None
''       Note: It is up to the user to define actions on errors or change
''             _SEED in the CON section
'-------------------------------------------------------------------------
e_action := _CONTINUE
qSeedPRNG := _SEED                            
qSeedTRNG := _SEED                          
REPEAT 2010 
  qSeedTRNG := (?qSeedTRNG) * (CNT + 2012)  
'----------------------------End of Start_Driver---------------------------


DAT 'Conversions between Strings and Qvalues------------------------------ 


PUB StrToQval(strP) : qV | sg, ip, d, fp, r
'-------------------------------------------------------------------------
'-------------------------------┌───────────┐-----------------------------
'-------------------------------│ StrToQval │-----------------------------
'-------------------------------└───────────┘-----------------------------
'-------------------------------------------------------------------------
''     Action: Converts a String to Qs15_16 (Qvalue) format
'' Parameters: Pointer to zero terminated ASCII string                               
''     Result: Number in Qs15_16 Fixed-point Qvalue format              
''+Reads/Uses: - _MAX_STR_LENGTH                           (CON/LONG)
''             - _STR2QVAL, _STRFORM_ERR, _OVERFLOW        (CON/LONG) 
''             - _32K                                      (CON/LONG) 
''    +Writes: e_orig, e_kind                              (VAR/LONG)      
''      Calls: SPIN_TrigPack_Error
'-------------------------------------------------------------------------
sg~
ip~ 
d~ 
fp~ 
REPEAT _MAX_STR_LEN
  CASE BYTE[strP]
    "-":
      sg := 1
    "+":
        
    ".",",":
      d := 1
    "0".."9":
      IF (d == 0)                          'Collect integer part
        ip := ip * 10 + (BYTE[strP] - "0")
      ELSE                                 'Collect decimal part
        fp := fp * 10 + (BYTE[strP] - "0")
        d++
    0:
      QUIT                                 'End of string
    OTHER:
      e_orig := _STR2QVAL
      e_kind := _STRFORM_ERR
      SPIN_TrigPack_Error   'This will decide what to do:CONT/NOTIFY/ABORT
      RETURN 0
  ++strP
  
'Process Integer part
IF (ip > _32K)
  e_orig := _STR2QVAL
  e_kind := _OVERFLOW
  SPIN_TrigPack_Error       'This will decide what to do:CONT/NOTIFY/ABORT
  RETURN 0

'Integer part ready  
ip := ip << 16

'Process Fractional part
r~  
IF (d > 1)
 fp := fp << (17 - d)
  REPEAT (d-1)
    r := fp // 5
    fp := fp / 5
    IF (r => 2)
      ++fp

'Get Qvalue      
qV := ip + fp

'Set sign
IF sg
  -qV

RETURN qV   
'-------------------------------End StrToQval-----------------------------


PUB QvalToStr(qV) : strP | ip, fp, d, nz, cp, c
'-------------------------------------------------------------------------
'-------------------------------┌───────────┐-----------------------------
'-------------------------------│ QvalToStr │-----------------------------
'-------------------------------└───────────┘-----------------------------
'-------------------------------------------------------------------------
''     Action: Converts a Qs15_16 (Qvalue) number into ASCII string
'' Parameters: Number in Qs15_16 format                              
''     Result: Pointer to zero terminated ASCII string             
''+Reads/Uses: None                   
''    +Writes: None                                    
''      Calls: None
'-------------------------------------------------------------------------
'Set pointer to string buffer
strP := @strB
cp~

'Check sign of Qvalue
IF (qV < 0)
  qV := ||qV
  BYTE[strP][cp++] := "-" 

'Round up
qV := qV + 1  

'Separate Integer and Fractional parts
ip := qV >> 16
fp := (qV << 16) >> 16  

d := 100_000                   '2^16 approx. 64K, 5 decimal
                               'digit range
nz~
REPEAT 6
  IF (ip => d)
    c := (ip / d) + "0"
    BYTE[strP][cp++] := c               
    ip //= d
    nz~~                                
  ELSEIF (nz OR (d == 1))
    c := (ip / d) + "0"                 
    BYTE[strP][cp++] := c      
  d /= 10

IF (fp > 0)
  BYTE[strP][cp++] := "."      'Add decimal point
  fp := (fp * 3125) >> 11      'Normalize fractional part

  d := 10_000                  '1/2^16 approx. 2E-5, 4 decimal
                               'digit range
 
  REPEAT 4
    IF (fp => d)
      c := (fp / d) + "0"
      BYTE[strP][cp++] := c               
      fp //= d                                
    ELSE
      c := (fp / d) + "0"                 
      BYTE[strP][cp++] := c      
    d /= 10

  'Remove trailing zeroes of decimal fraction
  REPEAT
    c := BYTE[strP][--cp]
    IF (c <> "0")
      QUIT
       
  BYTE[strP][++cp] := 0

  IF (BYTE[strP][cp-1] == ".")
    BYTE[strP][cp-1] := 0 
ELSE
  BYTE[strP][cp] := 0   

RETURN
'------------------------------End of QvalToStr---------------------------
 

DAT 'Conversions between number formats-----------------------------------


PUB Qval(intP) | s, qv 
'-------------------------------------------------------------------------
'----------------------------------┌──────┐-------------------------------
'----------------------------------│ QVal │-------------------------------
'----------------------------------└──────┘-------------------------------
'-------------------------------------------------------------------------
''     Action: Converts a LONG Integer into  Qs15_16 Fixed-point format
'' Parameters: LONG number               
''     Result: Number in Qs15_16 Fixed-point format                   
''+Reads/Uses: - _32K
''             - _QVAL, _OVERFLOW                   
''    +Writes: e_orig, e_kind
''      Calls: SPIN_TrigPack_Error                                    
'-------------------------------------------------------------------------
s:= FALSE
'Check sign
IF (intP < 0)
  -intP
  s := TRUE

'Check input and signal error
IF (intP > _32K)
  e_orig := _QVAL
  e_kind := _OVERFLOW
  SPIN_TrigPack_Error
  RETURN

'Shift integer part
qv := (intP << 16)

'Restore negative sign
IF s
  -qv

RETURN qv
'-------------------------------End of Qval-------------------------------


PUB IangleToQval(iA) | s, ip, fp, qv 
'-------------------------------------------------------------------------
'-----------------------------┌──────────────┐----------------------------
'-----------------------------│ IangleToQval │----------------------------
'-----------------------------└──────────────┘----------------------------
'-------------------------------------------------------------------------
''     Action: Converts iAngle (4K=2Pi) into Qs15_16 Fixed-point Qvalue
''             in degrees    
'' Parameters: Iangle as LONG integer (4096=2Pi)               
''     Result: Angle in degrees in Qs15_16 Fixed-point Qvalue format                   
''+Reads/Uses: None                   
''    +Writes: None
''      Calls: None                                 
'------------------------------------------------------------------------- 
s~

IF (iA < 0)
  -iA 
  s := 1

'Multiply back and shift + roundup
qv := ((iA * 45) << 6) + 1440

IF (s == 1)
  -qv

RETURN qv
'---------------------------End of IangleToQval---------------------------


PUB QvalToIangle(qV) | s, ip, fp, ia
'-------------------------------------------------------------------------
'-----------------------------┌──────────────┐----------------------------
'-----------------------------│ QvalToIangle │----------------------------
'-----------------------------└──────────────┘----------------------------
'-------------------------------------------------------------------------
''     Action: Converts Qs15_16 Qvalue Angle [deg] to iAngle format Angle
'' Parameters: Angle [deg] in Qs15_16 Fixed-point format                               
''     Result: Angle in iAngle (Index of Angle) format (4K=2Pi)                  
''+Reads/Uses: - _C_QVD2IA error constant                  (CON/LONG)
''             - _OVERFLOW error constant                  (CON/LONG)
''             - _94388224 overflow limit                  (CON/LONG)
''    +Writes: - e_orig    global error variable           (VAR/LONG)
''             - e_kind    global error variable           (VAR/LONG)                     
''      Calls: SPIN_TrigPack_Error
''       Note: - iAngle format is the index of the angle format for the 
''               ROM table reading procedures
''             - This procedure takes care of roundings
'-------------------------------------------------------------------------
s~ 
IF (qV < 0)
  -qV
  s := 1

'Check magnitude of input  to be < 1440.25 degrees
IF (qV => _MAXANGLE)
  e_orig := _IANG2QVAL
  e_kind := _OVERFLOW
  e_arg1 := qV
  SPIN_TrigPack_Error    'This will decide what to do: CONT/NOTIFY/ABORT
  qV //= 23592960        'Try to respond, when error handler doesn't care
                         'Take Mod 360 deg of large argument 
    
'Scale up integer part of Qvalue.
ip := qV >> 7   'This includes now a hefty part of the orig. fraction

'Multiply up this scaled-up integer part
ia := ip * 2912

'Get fraction of the product
fp := ia & $0000_FFFF

'Calculate integer part of the product, this is unrounded iAngle
ia := ia >> 16

'Round iAngle
IF (fp => $8000)
  ia++

'Set sign
IF (s == 1)
  -ia

RETURN ia
'-------------------------------------------------------------------------


DAT 'Conversions between angle formats------------------------------------


PUB DegToRad(dg) | qV 
'-------------------------------------------------------------------------
'--------------------------------┌──────────┐-----------------------------
'--------------------------------│ DegToRad │-----------------------------
'--------------------------------└──────────┘-----------------------------
'-------------------------------------------------------------------------
''     Action: Converts an angle in degrees into radians   
'' Parameters: Angle as Qs15_16 Fixed-point format Qvalue              
''     Result: Angle in radians in Qs15_16 Fixed-point format                   
''+Reads/Uses: None                   
''    +Writes: None
''      Calls: Qmuldiv, Qval
''       Note: Pi as 355/113, so Pi/180=71/4068                                 
'------------------------------------------------------------------------- 
RETURN Qmuldiv(dg, Qval(71), Qval(4068))
'-------------------------------------------------------------------------


PUB RadToDeg(dg) | qV 
'-------------------------------------------------------------------------
'--------------------------------┌──────────┐-----------------------------
'--------------------------------│ RadToDeg │-----------------------------
'--------------------------------└──────────┘-----------------------------
'-------------------------------------------------------------------------
''     Action: Converts an angle in radians into degrees   
'' Parameters: Angle in radians as Qs15_16 Fixed-point format Qvalue              
''     Result: Angle in degrees in Qs15_16 Fixed-point format                   
''+Reads/Uses: None                   
''    +Writes: None
''      Calls: Qmuldiv, Qval
''       Note: Pi as 355/113, so 180/Pi=4068/71                                 
'------------------------------------------------------------------------- 
RETURN Qmuldiv(dg, Qval(4068), Qval(71))
'-------------------------------------------------------------------------


DAT 'Relaxed comparisons (Tight ones work with SPIN's ==, =>, =<)---------  


PUB Q_EQ(arg1, arg2, eps)
'-------------------------------------------------------------------------
'----------------------------------┌──────┐-------------------------------
'----------------------------------│ Q_EQ │-------------------------------
'----------------------------------└──────┘-------------------------------
'-------------------------------------------------------------------------
''     Action: Checks equality of two Qvalues within epsilon                                                    
'' Parameters: - Value1
''             - Value2
''             - Epsilon    
''     Result: True if (ABS(Value1-Value2) < Epsilon) else False           
''+Reads/Uses: None                   
''    +Writes: None
''      Calls: None
'-------------------------------------------------------------------------
RESULT := (||(arg1 - arg2) =< ||eps)
'-------------------------------------------------------------------------


PUB Q_GT(arg1, arg2, eps)
'-------------------------------------------------------------------------
'-----------------------------------┌──────┐------------------------------
'-----------------------------------│ Q_GT │------------------------------
'-----------------------------------└──────┘------------------------------
'-------------------------------------------------------------------------
''     Action: Checks that Value1 is greater or not than Value2 with a
''             margin of Epsilon                                                    
'' Parameters: - Value1
''             - Value2
''             - Epsilon    
''     Result: TRUE if (Value1-Value2)>Epsilon else FALSE               
''+Reads/Uses: None                   
''    +Writes: None
''      Calls: None
'-------------------------------------------------------------------------
RESULT := (arg1 > arg2) AND (NOT (||(arg1 - arg2) =< ||eps))
'-------------------------------------------------------------------------


DAT 'Fixed-point arithmetic (+, -, ABS can be done with SPIN's +, -, ||)--


PUB Qmul(arg1, arg2) : qV | s, h, l, r
'-------------------------------------------------------------------------
'----------------------------------┌──────┐-------------------------------
'----------------------------------│ Qmul │-------------------------------
'----------------------------------└──────┘-------------------------------
'-------------------------------------------------------------------------
''     Action: Multiplies Qs15_16 Fixed-point numbers
'' Parameters: Multiplicand and Multiplier in Qs15_16 Fixed-point format                               
''     Result: Product in Qs15_16 Fixed-point format                   
''+Reads/Uses: - _32K
''             - _MUL, _OVERFLOW                 
''    +Writes: e_orig, e_kind                                    
''      Calls: SPIN_TrigPack_Error
''       Note: - Fixed-point addition and subtraction goes directly with
''               the + - operators of SPIN. 
''             - Intermediate results are in Qs31_32 double precision
''               Fixed-point format in (h, l), notated as dQvalue
'-------------------------------------------------------------------------
'Check sign
s~
IF (arg1 < 0)
  s := 1
  arg1 := ||arg1
IF (arg2<0)
  s := s ^ 1
  arg2 := ||arg2
  
'Multiply (Upper 32-bit) 
h := arg1 ** arg2

IF (||h > _32K)          'Check for overflow when ABS(dQvalue)>32K
  e_orig := _MUL
  e_kind := _OVERFLOW
  SPIN_TrigPack_Error    'This will decide what to do: CONT/NOTIFY/ABORT
  RETURN
  
'Multiply (Lower 32-bit)
l := arg1 * arg2

'Convert Qs31_32 double precision Fixed-point dQvalue in (h, l) into
'Qs15_16 Qvalue number
h := h << 16 

r := (l & (|<15)) >> 15

l := l >> 16

qV :=  h + l + r 

'Set sign
IF s
  -qV

RETURN
'-------------------------------------------------------------------------


PUB Qdiv(arg1, arg2) : qV | s, cf, h, l, q
'-------------------------------------------------------------------------
'---------------------------------┌──────┐--------------------------------
'---------------------------------│ Qdiv │--------------------------------
'---------------------------------└──────┘--------------------------------
'-------------------------------------------------------------------------
''     Action: Divides Qs15_16 Fixed-point Qvalue numbers
'' Parameters: Divider and Dividant are in Qs15_16 Fixed-point format                               
''     Result: Quotient in Qs15_16 Fixed-point format                   
''+Reads/Uses: _DIV, _DIVZERO                    
''    +Writes: e_orig, e_kind                                    
''      Calls: - SPIN_TrigPack_Error
''             - Div64
''       Note: - This precision division uses 64-bit form division inside 
'-------------------------------------------------------------------------
IF (arg2 == 0)            'Check divison by zero
  e_orig := _DIV
  e_kind := _DIVZERO
  SPIN_TrigPack_Error    'This will decide what to do: CONT/NOTIFY/ABORT
  RETURN 

'Check sign
s~
IF (arg1 < 0)
  s := 1
  arg1 := ||arg1
IF (arg2 < 0)
  s := s ^ 1
  arg2 := ||arg2

'Convert dividend into 64-bit Fixed-point dQvalue
h := arg1 >> 16
l := arg1 << 16

'Perform division of 64-bit dQvalue [[h][l]] with 32-bit Qvalue [arg2]
qV := Div64(h, l, arg2)

'Set sign    
IF s
  -qV
  
RETURN qV 
'-------------------------------------------------------------------------


PUB Qmuldiv(arg1, arg2, arg3) : qV | s, h, l, cf 
'-------------------------------------------------------------------------
'--------------------------------┌─────────┐------------------------------
'--------------------------------│ Qmuldiv │------------------------------
'--------------------------------└─────────┘------------------------------
'-------------------------------------------------------------------------
''     Action: Multiplies 2 Qvalues and divides the result with a Qvalue
''
''                                        Arg1 * Arg2
''                              Result = -------------
''                                            Arg3     
''
'' Parameters: Multiplier, multiplicand and divisor in Qs15_16 Fixed-point
''             format    
''     Result: Result in Qs15_16 Fixed-point format                   
''+Reads/Uses: _MULDIV, _DIVZERO                   
''    +Writes: e_orig, e_kind                                    
''      Calls: SPIN_TrigPack_Error
''       Note: The reason for this procedure is that the product and so
''             the divident is represented with 64-bit Fixed-point
''             dQvalue (double Qvalue) and the result of the division
''             is more precise than the result of the
'' 
''                              x   := Qmul(arg1, arg2)
''                              res := Qdiv(x, arg3)
''
''             sequence of procedures, where x is shrinked into 32-bit,
''             before the division
'-------------------------------------------------------------------------
IF (arg3 == 0)            'Check divison by zero
  e_orig := _MULDIV
  e_kind := _DIVZERO
  SPIN_TrigPack_Error    'This will decide what to do: CONT/NOTIFY/ABORT
  RETURN

'Check signs
s~
IF (arg1 < 0)
  s := 1
  arg1 := ||arg1
IF (arg2 < 0)
  s := s ^ 1
  arg2 := ||arg2
IF (arg3 < 0)
  s := s ^ 1
  arg3 := ||arg3  

'Multiply  
h := arg1 ** arg2
l := arg1 * arg2

'Perform division of 64-bit dQvalue [[h][l]] with 32-bit Qvalue [arg3]
qV := Div64(h, l, arg3)

'Set sign
IF s
  -qV

RETURN qV
'-------------------------------End of Qmuldiv----------------------------


PUB Qsqr(arg) : qV | ls, fs, o, iv 
'-------------------------------------------------------------------------
'----------------------------------┌──────┐-------------------------------
'----------------------------------│ Qsqr │-------------------------------
'----------------------------------└──────┘-------------------------------
'-------------------------------------------------------------------------
''     Action: Calculates the square root of a Qs15_16 Fixed-point number
'' Parameters: Argument in Qs15_16 Fixed-point format                                               
''     Result: Square-root of argument in Qs15_16 Fixed-point format    
''+Reads/Uses: - _SQR, _INVALID_ARG                         (CON/LONG)
''             - _SQRTWO (1.4142 in Qvalue format)          (CON/LONG)
''    +Writes: e_orig, e_kind                               (VAR/LONG)     
''      Calls: - SPIN_TrigPack_Error
''             - Qdiv, StrToQval
'-------------------------------------------------------------------------
IF (arg =< 0)             'Check for negative argument
  e_orig := _SQR
  e_kind := _INVALID_ARG
  SPIN_TrigPack_Error    'This will decide what to do: CONT/NOTIFY/ABORT
  RETURN 

ls := 32 - (>| arg)
arg := arg << ls
iv := ^^arg
o := ls // 2
ls := ls / 2
IF ( ls =< 8)
  qV := iv << (8 - ls)
ELSE
  qV := iv >> (ls - 8)
  
IF (o == 1)
  qV := Qdiv(qV, _SQRTWO) 
'------------------------------- End of Qsqr------------------------------


PUB Qint(qV)
'-------------------------------------------------------------------------
'---------------------------------┌──────┐--------------------------------
'---------------------------------│ Qint │--------------------------------
'---------------------------------└──────┘--------------------------------
'-------------------------------------------------------------------------
''     Action: Returns the integer part of a Qvalue
'' Parameters: Qvalue                                              
''     Result: Integer part of a Qvalue    
''+Reads/Uses: None
''    +Writes: None                                 
''      Calls: None
''       Note: Result is in Qvalue format
'-------------------------------------------------------------------------
IF (qV => 0)
  RESULT := qV & $FFFF_0000 
ELSE
  RESULT := -((||qV) & $FFFF_0000) 
'--------------------------------End of Qint------------------------------


PUB Qfrac(qV)
'-------------------------------------------------------------------------
'---------------------------------┌───────┐-------------------------------
'---------------------------------│ Qfrac │-------------------------------
'---------------------------------└───────┘-------------------------------
'-------------------------------------------------------------------------
''     Action: Returns the fractional part of a Qvalue
'' Parameters: Qvalue                                              
''     Result: Fractional part of a Qvalue    
''+Reads/Uses: None
''    +Writes: None                                 
''      Calls: None
'-------------------------------------------------------------------------
IF (qV => 0)
  RESULT := qV & $0000_FFFF 
ELSE
  RESULT := -(||qV & $0000_FFFF) 
'-------------------------------End of Qfrac------------------------------


PUB Qround(qV)
'-------------------------------------------------------------------------
'--------------------------------┌────────┐-------------------------------
'--------------------------------│ Qround │-------------------------------
'--------------------------------└────────┘-------------------------------
'-------------------------------------------------------------------------
''     Action: Returns the rounded value of a Qvalue number
'' Parameters: Qvalue                                              
''     Result: Fractional part of a Qvalue    
''+Reads/Uses: None
''    +Writes: None                                 
''      Calls: None
''       Note:  1.47 will be rounded to 1.00 and
''             -1.53 will be rounded to -2.0
''             - Now works properly after Chuck Taylor's modification
'-------------------------------------------------------------------------
IF (qV == 0)
  RESULT := 0
ELSE
  IF (qV > 0)
    RESULT := (qV + $0000_8000) & $FFFF_0000 
  ELSE
    RESULT := _Q1 + (qV - $0000_8000) & $FFFF_0000 
'------------------------------End of Qround------------------------------


DAT 'Trig functions-------------------------------------------------------


PUB SIN_Deg(qVd)
'-------------------------------------------------------------------------
'--------------------------------┌─────────┐------------------------------
'--------------------------------│ SIN_Deg │------------------------------
'--------------------------------└─────────┘------------------------------
'-------------------------------------------------------------------------
''     Action: Calculates sine of Angle 
'' Parameters: Angle [deg] in Qs15_16 Fixed-point format (Qvalue)                              
''     Result: Sine of Angle in Qs15_16 Fixed-point format (Qvalue)                  
''+Reads/Uses: None                   
''    +Writes: None                                    
''      Calls: QvalToIangle, SIN_ROM 
'-------------------------------------------------------------------------
RESULT := SIN_ROM(QvalToIangle(qVd))
'------------------------------End of SIN_Deg-----------------------------


PUB COS_Deg(qVd)
'-------------------------------------------------------------------------
'--------------------------------┌─────────┐------------------------------
'--------------------------------│ COS_Deg │------------------------------
'--------------------------------└─────────┘------------------------------
'-------------------------------------------------------------------------
''     Action: Calculates cosine of Angle 
'' Parameters: Angle [deg] in Qs15_16 format                                
''     Result: Cosine of Angle in Qs15_16 format                   
''+Reads/Uses: None                   
''    +Writes: None                                    
''      Calls: QvalToIangle, COS_ROM
'-------------------------------------------------------------------------
RESULT := COS_ROM(QvalToIangle(qVd))
'-------------------------------End of COS_Deg----------------------------


PUB TAN_Deg(qVd) | sg, s, c, t
'-------------------------------------------------------------------------
'--------------------------------┌─────────┐------------------------------
'--------------------------------│ TAN_Deg │------------------------------
'--------------------------------└─────────┘------------------------------
'-------------------------------------------------------------------------
''     Action: Calculates tangent of Angle [deg] 
'' Parameters: Angle [deg] in Qs15_16 Fixed-point format                                
''     Result: Tangent of Angle in Qs15_16 Fixed-point format                   
''+Reads/Uses: _TAND, _DIVZERO                   
''    +Writes: e_orig, e_kind                                    
''      Calls: - SPIN_TrigPack_Error
''             - SIN_Deg, COS_Deg
'-------------------------------------------------------------------------
IF (qVd < 0)
  -qVd
  sg := 1

'Calculate SIN and COS in Qs15_16 iValue format 
s := SIN_Deg(qVd)
c := COS_Deg(qVd)

IF (c == 0)
  e_orig := _TAND
  e_kind := _DIVZERO
  SPIN_TrigPack_Error    'This will decide what to do: CONT/NOTIFY/ABORT
  t := $7FFF_FFFF        'Try to respond, when error handler doesn't care
  RETURN t 

'Inline Qs15_16 division of sine with cosine
t := ((s << 15) / c) << 1

IF (sg == 1)
  -t

RETURN t 
'------------------------------End of TAN_Deg-----------------------------


DAT 'Inverse Trig functions-----------------------------------------------


PUB Deg_ASIN(qVs) : qV | x
'-------------------------------------------------------------------------
'-------------------------------┌──────────┐------------------------------
'-------------------------------│ Deg_ASIN │------------------------------
'-------------------------------└──────────┘------------------------------
'-------------------------------------------------------------------------
''     Action: Calculates Angle of a Sine
'' Parameters: Sine input value Qs15_16 Fixed-point format                                
''     Result: Angle in degrees in Qs15_16 Fixed-point format                   
''+Reads/Uses: - _DASIN, _INVALID_ARG                        (CON/LONG)
''             - _64K                                        (CON/LONG)
''             - _90D                                        (CON/LONG)
''    +Writes: e_orig, e_kind                                (VAR/LONG)    
''      Calls: - SPIN_TrigPack_Error
''             - Deg_ACOS
''       Note: Computes the principal value of the arc sine of Input in
''             the interval [-90,90] degrees for Input in the interval
''             [-1,1] 
'-------------------------------------------------------------------------
'Check argument
x := ||qVs   
IF (x > _64K)
  e_orig := _DASIN
  e_kind := _INVALID_ARG
  SPIN_TrigPack_Error    'This will decide what to do: CONT/NOTIFY/ABORT
  RETURN 0               'Try to respond, when error handler doesn't care
    
RETURN (_90D - Deg_ACOS(qVs)) 
'-----------------------------End of Deg_ASIN-----------------------------


PUB Deg_ACOS(qVc) | x
'-------------------------------------------------------------------------
'-------------------------------┌──────────┐------------------------------
'-------------------------------│ Deg_ACOS │------------------------------
'-------------------------------└──────────┘------------------------------
'-------------------------------------------------------------------------
''     Action:Calculates Angle of a Cosine 
'' Parameters: Cosine input value Qs15_16 Fixed-point format                                
''     Result: Angle in degrees in Qs15_16 Fixed-point format                   
''+Reads/Uses: - _DACOS, _INVALID_ARG                         (CON/LONG)
''             - _64K                                         (CON/LONG)
''             - _90D, _180D                                  (CON/LONG)
''    +Writes: e_orig, e_kind                                 (VAR/LONG)                                    
''      Calls: - SPIN_TrigPack_Error
''             - Qdiv, Qsqr, Qmul
''             - Deg_ATAN2
''       Note: Computes the principal value of the arc cosine of Input in
''             the interval [0,180] degrees for Input in the interval
''             [-1,1] 
'-------------------------------------------------------------------------
'Check argument
x := ||qVc   
IF (x > _64K)
  e_orig := _DACOS
  e_kind := _INVALID_ARG
  SPIN_TrigPack_Error    'This will decide what to do: CONT/NOTIFY/ABORT
  RETURN 0               'Try to respond, when error handler doesn't care

IF (x == 0)
  RETURN (_90D)
  
IF (x == _64K)
  IF (qVc=<0)
    RETURN (_180D)  
  ELSE
    RETURN 0
    
x := Qdiv(qVc, Qsqr((_Q1 - Qmul(qVc, qVc))))  

RETURN  (_90D - Deg_ATAN2(_Q1, x))
'-----------------------------End of Deg_ACOS-----------------------------


PUB Deg_ATAN(qVt)
'-------------------------------------------------------------------------
'-------------------------------┌──────────┐------------------------------
'-------------------------------│ Deg_ATAN │------------------------------
'-------------------------------└──────────┘------------------------------
'-------------------------------------------------------------------------
''     Action: Calculates Angle of a Tangent 
'' Parameters: Tangent value in Qs15_16 Fixed-point format                                
''     Result: Angle in degrees in Qs15_16 Fixed-point format                   
''+Reads/Uses: _Q1                                           (CON/LONG)                 
''    +Writes: None                                    
''      Calls: Deg_ATAN2
'-------------------------------------------------------------------------
RETURN Deg_ATAN2(_Q1, qVt)
'-----------------------------End of Deg_ATAN-----------------------------


DAT 'Polar coordinate functions-------------------------------------------


PUB Deg_ATAN2(qX,qY):qV|ix,iy,x,y,xy,sh,n,d,ia,fa,iv,r,c,s,cr
'-------------------------------------------------------------------------
'------------------------------┌───────────┐------------------------------
'------------------------------│ Deg_ATAN2 │------------------------------
'------------------------------└───────────┘------------------------------
'-------------------------------------------------------------------------
''     Action: Calculates Arc Tangent of an Angle in [deg] between
''             [-180,180] from the X, Y rectangular coordinates
'' Parameters: X, Y rectangular coordinates in Qs15_16 iValue format                                
''     Result: Angle [deg] in Qs15_16 format                   
''+Reads/Uses: - _DATAN2, _INVALID_ARG                       (CON/LONG)
''             - _90D, _180D                                 (CON/LONG)
''    +Writes: e_orig, e_kind                                (VAR/LONG)
''      Calls: -SPIN_TrigPack_Error,
''             - Qdiv, Qmul, Qsqr, COS_Deg, SIN_Deg
''       Note: - This function is used mostly to convert from rectangular 
''               (X,Y) to  polar (R,Angle) coordinates that must satisfy
''
''                        X = R*COS(Angle) and Y = R*SIN(Angle)
''
''             - The ATAN2 function takes into account the signs of both
''               vector components, and places the angle in the correct
''               quadrant. For example
''                                                     
''                     ATAN2( .707, .707) =    pi/4 =>   45 degrees
''                     ATAN2(-.707, .707) =   -pi/4 =>  135 degrees    
''                     ATAN2( .707,-.707) =  3*pi/4 =>  -45 degrees
''                     ATAN2(-.707,-.707) = -3*pi/4 => -135 degrees
''
''                    (where the Qs15_16 iValue of 0.707 is 46333)
''
''             - The sign of ATAN2 is the same as the sign of Y.
''             - The ATAN2 function is useful in many applications
''               involving vectors in Euclidean space, such as finding the
''               direction from one point to another. A principal use is
''               in computer graphics rotations or in INS computations,
''               for converting rotation matrix representations into Euler
''               angles. For inclinometers it is used to calculate tilt
''               angles and with magnetometers to find heading. 
''             - Precision of this procedure is always better than 0.02
''               degrees over the[-180,180] range
''             - Average absolute precision is about 0.01 degrees
''             - It uses only a single parameter (0.28) in the equation
''
''                      Angle = (X * Y) / (X * X + 0.28 * Y * Y)
''
''               and that is followed by a Newton-Raphson refinement step 
'-------------------------------------------------------------------------
'Check arguments
IF ((qX == 0) AND (qY == 0))
  e_orig := _DATAN2
  e_kind := _INVALID_ARG
  SPIN_TrigPack_Error    'This will decide what to do: CONT/NOTIFY/ABORT
  RETURN 0               'Try to respond, when error handler doesn't care

IF (qX==0)
  IF (qY>0)
    RETURN (_90D)
  ELSE
    RETURN (-(_90D))

IF (qY==0)
  IF (qX=>0)
    RETURN 0
  ELSE
    RETURN (_180D)        

ix := ||qX
iy := ||qY

x := >| ix
y := >| iy

sh := (19 - x - y)
IF (sh=>0)
  sh := sh / 2
  ix := ix << sh
  iy := iy << sh
ELSE
  sh := (||sh) / 2
  ix := ix >> sh
  iy := iy >> sh
xy := ix * iy

IF (xy =< 292812)
  REPEAT
    --sh
    xy := xy << 2
    IF (xy => 292812)
      ++sh
      QUIT
ELSE
  REPEAT
    ++sh
    xy := xy >> 2
    IF (xy =< 292812)
      QUIT

'x := (||qX) >> sh            'Original, but does not work with (-1,-256)
'y := (||qY) >> sh

x := (||qX) >> (sh+1)         'Timmoore's improved version, that not only
y := (||qY) >> (sh+1)         'works, but increases precision noticeably

n := 7334 * x * y  
IF (iy =< ix)
 'ia := (7334 * x * y) / (128 * x * x + 35 * y * y)
  y := y * y
  d := ((x * x) << 7) + (y << 5) + (y << 1) + y 
  ia := n / d
  fa := n // d
  'Normalize fractional part
  d := d >> 16
  fa := fa / d
  'Convert to iValue
  'Integer part
  iv := ia << 16
  'Combine with fractional part    
  qV := iv + fa
ELSE
  'ia := 90 - (7334 * x * y) / (128 * y * y + 35 * x * x)
  x := x * x
  d := ((y * y) << 7) + (x << 5) + (x << 1) + x 
  ia := n / d
  fa := n // d
  'Normalize fractional part
  d := d >> 16
  fa := fa / d
  'Convert to iValue
  'Integer part
  iv := ia << 16
  'Combine with fractional part    
  qV := iv + fa
  'Final result
  qV := _90D - qV
'Normalize x and y so that x^2 + y^2 = 1.
ix := ||qX
iy := ||qY
r := Qradius(ix, iy)

'One-shot Newton-Raphson refinement of angle (Timmoore's improved version)
c := QMul(COS_Deg(qV),r) 'Approx. Cosine
s := QMul(SIN_Deg(qV),r) 'Approx. Sine
IF (ix =< iy)
  cr := -Qdiv(ix - c, s)
ELSE
  cr := Qdiv(iy - s, c)

qV := qV + RadToDeg(cr) 


'Calc magnitude of angle
IF (qX < 0)
  qV := (_180D) - qV

'Set sign of Angle
IF (qY < 0)
  -qV
  
RETURN
'-----------------------------End of Deg_ATAN2----------------------------


PUB Qradius(qX, qY) : qR | hx, lx, hy, ly, h, l, cf, ap
'-------------------------------------------------------------------------
'--------------------------------┌─────────┐------------------------------
'--------------------------------│ QRadius │------------------------------
'--------------------------------└─────────┘------------------------------
'-------------------------------------------------------------------------
''     Action: Calculates Distance of point (X,Y) from the origo  
'' Parameters: X, Y Descartes coordinates in Qs15_16 Fixed-point format                                
''     Result: Distance from the origo in Qs15_16 Fixed-point format                   
''+Reads/Uses: None                   
''    +Writes: None                                    
''      Calls: Add64, Div64
''       Note: QAngle(qX, qY) is encrypted as Deg_ATAN2(qX, qY)
'-------------------------------------------------------------------------
qX := ||qX
qY := ||qY
hx := qX ** qX
lx := qX * qX
hy := qY ** qY
ly := qY * qY

Add64(hx, lx, hy, ly, @dQval)
hx := dQval[0]
lx := dQval[1]

'Check for zero hx
IF (hx == 0)
  RETURN (Qsqr(lx) >> 8)  
ELSE
  'Prepare SQR iteration loop
  qR := (^^hx) << 16                   
  'Do iteration 3 times
  REPEAT 3
    'Perform 64-bit division
    ap := Div64(hx, lx, qR)
    'Calculate next approximation as qR
    qR := (qR + ap) >> 1
    IF (qR == ap)
      QUIT

RETURN qR  
'------------------------------End of Qradius-----------------------------


DAT 'Random numbers-------------------------------------------------------


PUB Q_TRNG(qMin, qMax) | r, rn
'-------------------------------------------------------------------------
'---------------------------------┌────────┐------------------------------
'---------------------------------│ Q_TRNG │------------------------------
'---------------------------------└────────┘------------------------------
'-------------------------------------------------------------------------
''     Action: Calculates a True Random Qvalue between  Max. and Min.
''             limit (See note) 
'' Parameters: - Minimum in Qs15_16 format
''             - Maximum in Qs15_16 format
''     Result: True random Qvalue from the intervall [Min, Max]. The
''             consecutive results of this procedure are uniformly
''             distributed over the [Min, Max] intervall.        
''+Reads/Uses: _TRNG, _INVALID_ARG     
''    +Writes: e_orig, e_kind, qSeedTRNG                         
''      Calls: SPIN_TrigPack_Error
''       Note: - True Random property means here two things: First is
''             that after each reboot you will get different outcomes
''             from this TRNG. The second is that the sequence will
''             repeat itself only after about 7 thousand years for a
''             given,strictly periodic application, that works
''             uniterrupted during those 7 milleniums. For aplications
''             collecting some entropy (e.g. readings of sensors with data
''             ready line, waiting for keyboard hits...), the sequence
''             repeats itself only after the End of Time.
''             - A feature of 'Linear Feedback Shift Register' (LFSRs) and
''             of 'Linear Congruential Generators' (LCGs) is that the
''             lower digits tend to be 'less random' than the higher
''             digits. Because of this I used here only the upper 16 bits 
''             of the LFSRs' outcome.
'-------------------------------------------------------------------------
IF (qMin == qMax)
  e_orig := _TRNG
  e_kind := _INVALID_ARG
  SPIN_TrigPack_Error      'This will decide what to do: CONT/NOTIFY/ABORT
  RETURN

IF (qMin > qMax)           'Let us allow for this
  r := qMax
  qMax := qMin
  qMin := r

r := qMax - qMin
  
qSeedTRNG := (?qSeedTRNG) + CNT
qSeedTRNG := (?qSeedTRNG) * CNT

rn := qSeedTRNG >> 16      'Transform the 'more' random upper digits into 
                           'the [0, 1] Qvalue interval

RESULT := qMin + Qmul(r, rn)
'-------------------------------End of Q_TRNG-----------------------------


PUB Q_PRNG(qMin, qMax) | r, rn
'-------------------------------------------------------------------------
'--------------------------------┌────────┐-------------------------------
'--------------------------------│ Q_PRNG │-------------------------------
'--------------------------------└────────┘-------------------------------
'-------------------------------------------------------------------------
''     Action: Calculates a Pseudo Random Qvalue between  Max. and Min.
''             limit (See note) 
'' Parameters: - Minimum in Qs15_16 format
''             - Maximum in Qs15_16 format
''     Result: Pseudo random Qvalue from the intervall [Min, Max]. The
''             consecutive results of this procedure are uniformly
''             distributed over the [Min, Max] intervall.        
''+Reads/Uses: _TRNG, _INVALID_ARG     
''    +Writes: e_orig, e_kind, qSeedTRNG                         
''      Calls: SPIN_TrigPack_Error
'------------------------------End of Q_PRNG------------------------------
IF (qMin == qMax)
  e_orig := _PRNG
  e_kind := _INVALID_ARG
  SPIN_TrigPack_Error      'This will decide what to do: CONT/NOTIFY/ABORT
  RETURN

IF (qMin > qMax)           'Let us allow for this
  r := qMax
  qMax := qMin
  qMin := r

r := qMax - qMin
  
qSeedPRNG := ?qSeedPRNG
qSeedTRNG := ?qSeedTRNG + CNT  'To keep True Random Generator on alert

rn := qSeedPRNG >> 16      'Transform more 'random' upper digits into the
                           '[0, 1] Qvalue interval

RESULT := qMin + Qmul(r, rn)
'------------------------------End of Q_PRNG------------------------------


DAT '64-bit utilities-----------------------------------------------------


PRI Add64(ah, al, bh, bl, res_) | la, lb 
'-------------------------------------------------------------------------
'---------------------------------┌───────┐-------------------------------
'---------------------------------│ Add64 │-------------------------------
'---------------------------------└───────┘-------------------------------
'-------------------------------------------------------------------------
'     Action: Adds 64-bit numbers
' Parameters: - Hi and Lo part of Arg1
'             - Hi and Lo part of Arg2
'             - HUB address of 64-bit dQvalue                                                                        
'     Result: None                                                                    
'+Reads/Uses: None                    
'    +Writes: 64-bit result into LONG[address]                                    
'      Calls: None
'       Note: Result is passed by reference
'-------------------------------------------------------------------------
LONG[res_][0] := ah + bh
LONG[res_][1] := al + bl

IF ((al < 0) AND (bl < 0))
  LONG[res_][0]++
  RETURN
ELSEIF ((al => 0) AND (bl => 0))
  RETURN
ELSE
  la := al &  $7FFF_FFFF
  lb := bl &  $7FFF_FFFF
  IF ((la + lb) < 0)
    LONG[res_][0]++
RETURN
'-------------------------------End of Add64------------------------------


PRI Div64(dh, dl, dr) : qQ | cf, hb
'-------------------------------------------------------------------------
'---------------------------------┌───────┐-------------------------------
'---------------------------------│ Div64 │-------------------------------
'---------------------------------└───────┘-------------------------------
'-------------------------------------------------------------------------
'     Action: Divides a 64-bit dQvalue with q 32-bit Qvalue
' Parameters: - Hi and Lo part of dividend
'             - Divisor                                                                                     
'     Result: Quotient in Qs15_16 Fixed-point Qvalue format                                                                    
'+Reads/Uses: None                    
'    +Writes: None                                    
'      Calls: None
'       Note: - Assumes positive arguments
'-------------------------------------------------------------------------
qQ~
REPEAT 32
  cf := dh < 0
  dh := (dh << 1) + (dl >> 31)
  dl <<= 1
  qQ <<= 1
  IF ((dh > dr) OR cf)
    ++qQ
    dh -= dr

RETURN qQ    
'-------------------------------End of Div64------------------------------


DAT 'Functions to access ROM Tables---------------------------------------


PRI SIN_ROM(iA)
'-------------------------------------------------------------------------
'--------------------------------┌─────────┐------------------------------
'--------------------------------│ SIN_ROM │------------------------------
'--------------------------------└─────────┘------------------------------
'-------------------------------------------------------------------------
'     Action: - Reads value from SIN Table according to iAngle address
' Parameters: Angle in iAngle (Index of Angle) units                                 
'     Result: Sine value for Angle in Qs15_16 Qvalue format                    
'+Reads/Uses: - _BASE_SINTABLE   (= $E000)                   (CON/LONG)
'             - qValue from ROM SIN Table                    (ROM/WORD)
'    +Writes: None                                    
'      Calls: None
'       Note: - SIN table contains 2K 16-bit word data for the 1st
'               quadrant in [$E000-$F000] 4KB locations
'             - Word index goes up and down and up and down in quadrants
'                  [0, 90]      [90, 180]      [180, 270]     [270, 380]
'                    up            down            up            down
'
'   quadrant:        1              2              3              4
'   angle:     $0000...$07FF  $0800...$0FFF  $1000...$17FF  $1800...$1FFF
'   w.index:   $0000...$07FF  $0800...$0001  $0000...$07FF  $0800...$0001
'       (The above 3 lines were taken after the Propeller Manual v1.1)
'
'             - The returned value from the table is a Qs15_16 fraction
'-------------------------------------------------------------------------
CASE (iA & %1_1000_0000_0000)
  %0_0000_0000_0000:                             '1st quadrant
    RETURN WORD[_BASE_SINTABLE][iA & $7FF]
  %0_1000_0000_0000:                             '2nd quadrant according
    IF (iA & $7FF)                               'to Chuck Taylor's
      RETURN WORD[_BASE_SINTABLE][(-iA & $7FF)]  'modification
    ELSE
      RETURN _Q1                                       
  %1_0000_0000_0000:                             '3rd quadrant
    RETURN -WORD[_BASE_SINTABLE][iA & $7FF]
  %1_1000_0000_0000:                             '4th quadrant according
    IF (iA & $7FF)                               'to Chuck Taylor's
      RETURN -WORD[_BASE_SINTABLE][(-iA & $7FF)] 'modification
    ELSE
      RETURN -_Q1      
'------------------------------End of SIN_ROM-----------------------------


PRI COS_ROM(iA)
'-------------------------------------------------------------------------
'--------------------------------┌─────────┐------------------------------
'--------------------------------│ COS_ROM │------------------------------
'--------------------------------└─────────┘------------------------------
'-------------------------------------------------------------------------
'     Action: Reads COS value from ROM SIN Table
' Parameters: Angle in iAngle (Index of Angle) units                               
'     Result: Cosine value for Angle in Qs15_16 Fixed-point format               
'+Reads/Uses: _PIHALF                                        (CON/LONG)
'    +Writes: None                                    
'      Calls: SIN_ROM
'-------------------------------------------------------------------------
RETURN SIN_ROM(iA + _PIHALF)
'------------------------------End of COS_ROM-----------------------------


DAT 'Error handler--------------------------------------------------------


PRI SPIN_TrigPack_Error
'-------------------------------------------------------------------------
'--------------------------┌─────────────────────┐------------------------
'--------------------------│ SPIN_TrigPack_Error │------------------------
'--------------------------└─────────────────────┘------------------------
'-------------------------------------------------------------------------
'     Action: Handels errors. User defines here what to do.
' Parameters: None                                 
'     Result: None                    
'+Reads/Uses: - _CONTINUE, _NOTIFY, _ABORT                     (CON/LONG)
'             - e_action                                       (VAR/LONG)
'              (e_orig, e_kind , e_arg1,2 globals can be used here.too)                
'    +Writes: None                                    
'      Calls: None
'       Note: Any further action should be user defined here
'-------------------------------------------------------------------------
CASE e_action
  _CONTINUE: 
  _NOTIFY:
  _ABORT:
    ABORT     

RETURN 
'-------------------------End of SPIN_TrigPack_Error----------------------


DAT '---------------------------MIT License-------------------------------


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