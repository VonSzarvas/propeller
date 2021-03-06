{{

┌──────────────────────────────────────────┐
│ dservo                              v1.0 │
│ Author: Diego Pontones                   │               
│ Copyright (c) 2010 Diego Pontones        │               
│ See end of file for terms of use.        │                
└──────────────────────────────────────────┘

INTRODUCTION

This object allows the control of up to 14 standard servos.
It requires 1 cog.
2 cogs required for Accelerated/Decelerated Moves.

This object is based on the Servos for PE Kit.spin but incorporates many new features like:

a) Three different type of movements: Immediate, Gradual and Accelerated/Decelerated

Immediate Moves: One or more servos are moved to the new positions as fast as they allow it.

Gradual Moves: One or more servos are moved to the new positions in a predetermined number of pulses.

Accelerated/Decelerated Moves: One or more servos are moved to the new position using the sine function
to achieve a gradual acceleration at the beginning of the move and a gradual deceleration at the end of
the move. Please note that if Accelerated/Decelerated moves are used an additional cog is required to
run the Float32 object used for the sin function.

All movements are executed during a certain number of pulses, where 50 pulses equal one second.


b) Option to send pulses while in holding position.

When a movement is completed there is the option to keep sending pulses to hold the servo in the
last position or to stop sending pulses.

Sending hold pulses helps keep the servo firmly in position (useful for robotic arms or walking robots) but
increases the power consumption. Not sending hold pulses leaves the servo idle so power consumption is
reduced, this is normally used for servos that do not require a high holding torque.

c) Servos can be moved individually or in combined moves.

All parameters, like type of movement, number of pulses and optional holding pulse can be set
individually for each servo so very complex movements can be executed. For example different movement
durations can be set for each servo or some servos can be moved many times while other servos are still
completing a long move.


USAGE

Please see file "dServo_use_6_Servos_Example.spin" as an example on how to control up to 6 servos
used in a robotic arm and "dServo_use_1_Servo_Example.spin" as an example on how to control just 1 servo.

Servo positions are controlled by the NewPos array. Each array element should contain values in
the -1000 to 1000 range, which maps to 0.5 ms to 2.5 ms pulses for the Pulse Width Modulation (PWM).
This makes 0 the center pulse duration of 1.5 ms.

Warning: some servos may have a smaller range of pulses and may be damaged if forced.

Variables used from the calling object:
 
  NumServos = 1 to 14     Number of servos to control 1 to 14

  pin[NumServos]          pin numbers for each servo 
  CurrPos[NumServos]      Contains the current Pulse Width (Position) for each servo, -1000 to 1000
  NewPos[NumServos]       Enter the desired New Pulse Width (Position) for each servo, -1000 to 1000 
  NumPulses[NumServos]    Number of Pulses to be sent for each servo. (pulse period is 20 ms, 50 pulses = 1 sec)
                          When NumPulses[servo] == 0 then the movement has been completed for that servo.
  GradMove                One bit for each servo. If bit is set then movement will be gradual.
  AccDecMove              One bit for each servo. If bit is set then movement will have Acceleration/Deceleration.
                          If GradMove and AccDecMove are not set then the movement will be as fast as the servo
                          allows it.
  HoldPulse               One bit for each servo. If bit is set then pulses will be sent continuously to
                          hold the new position.

Warning: It is recommended to run this object with a 80mhz master clock. This object has not
been tested below 80mhz master clock. 


HISTORY
  v1.0  2010-03-24  Beta release

                                                      
}}

CON

  CTR = 8            ' CTRA spr array index
  FRQ = 10           ' FRQA spr array index
  PHS = 12           ' PHSA spr array index

  MaxServos = 14

  MinPulses = 10     ' Don't allow movements with less than 10 pulses
  ExtraPulses = 2    ' Extra pulses to be sent at the end of a gradual or accelerated movements to help the servo complete fast movements
  
  pidiv2 = pi/2.0
  pimul2 = pi*2.0
  
VAR

  long pinAddr,CurrPosAddr,NewPosAddr,NumPulsesAddr,GradMoveAddr,AccDecMoveAddr,HoldPulseAddr,NumServos        'Don't change the order of the previous variables
  long pulses[MaxServos], CurrPosInCycles[MaxServos], u[MaxServos] ,angle[MaxServos] , v[MaxServos] , angleDelta[MaxServos], StartPosInCycles[MaxServos]                 
  long stackServos[32], cogServos           'Servo Object Variables. Note: Max stack size calculated with "Stack Length" object was 18.
  long cogFloat32                            'Float32 Object variables 
  long us, center, frame, cycleEnd           'Timing variables

  
OBJ

  F : "Float32"                             ' Used for the Acceleration and Deceleration sin function Calcs
  
PUB start(pinAddrLV, CurrPosAddrLV, NewPosAddrLV, NumPulsesAddrLV,GradMoveAddrLV,AccDecMoveAddrLV,HoldPulseAddrLV, NumServosLV) : okay

  us       := clkfreq / 1_000_000            ' 1 microsecond
  center   := 1500 * us                      ' Center pulse = 1.5 ms
  frame    := 2700 * us                      ' Pulse frame to 2.7 ms
  cycleEnd := 1100 * us                      ' (2.7 ms * 7) + 1.1 ms = 20 ms
  
  NumServosLV-- 'Decrement by one the number of servos. To get servo numbers from 0 to 13
  longmove(@pinAddr, @pinAddrLV, 8)         ' Copy local variables from method start to global object vars
  okay := cogServos := cognew(servos, @stackServos) + 1  ' Launch Servos method into new cog
  if okay                               
       oKay := cogFloat32 :=  F.Start   'Comment out this line if no Accelerated/Decelerated moves are required so the extra cog is not used.
                                        'If no Accelerated/Decelerated moves are required all lines containing F.xxx commands bellow will need
                                        'to be commented out.     
PUB stop
'Free servos and cogFloat32 cogs
  if cogServos
    cogstop(cogServos~ - 1)
  if cogFloat32
    cogstop(cogFloat32~ - 1)

PRI servos |   t, i, j, ch
           
  'Repeat loop initializes A and B counter modules.  
  'ch = 0 → counter A, ch = 1 → counter B.
  'Set counter A and B to NCO mode (for PWM)
    
  repeat ch from 0 to 1
        spr[FRQ + ch] := spr[PHS + ch] := 1      
        spr[CTR + ch] := (%000100 << 26) + byte[pinAddr][ch]

  'Set all servo I/O pins to output.
  
  repeat i from 0 to NumServos
        dira[byte[pinAddr][i]]~~

  t := cnt    ' Mark current clock tick count
  
  'Sends pulses to servos (up to 14 pulses per 20 ms cycle).
  repeat
        i := -1
  '     'Deliver up to two pulses per frame, incrementing i with each pulse.
        'start by sending pulses to both servos and then do the calcs, that way there is more time for the calcs to happen while the pulses are sent.
        repeat until i == 13 
              j:= i
              repeat ch from 0 to 1

                    if ++j =< NumServos
                          if (pulses[j] and u[j]) or (long[HoldPulseAddr] & |<j)  'If movement has finished but need to hold then send hold pulses or if u has been calculated and there are pulses left then send pulses
                                spr[CTR + ch] := spr[CTR + ch] & $FFFFFF00 | byte[pinAddr][j]
                                spr[PHS + ch] := -(CurrPosInCycles[j] + center)

              repeat ch from 0 to 1  'A pulse is only sent if i is less than or equal to the number of servos.
                    if ++i =< NumServos
                    'Check for changes in NumPulsesAddr, if Pulses was cero and a new number appears at NumPulsesAddr
                    'means a movement has been requested and have to work it out. When finished set NumPulsesAddr to 0
                    'to indicate the calling method that the movement for that servo has finished.
                          if long[NumPulsesAddr][i] and (pulses[i]==0) 'means there is a new movement request so do initial calculations
                                pulses[i] :=  (long[NumPulsesAddr][i] +1) #> MinPulses
                                long[NewPosAddr][i] := long[NewPosAddr][i] #> -1000 <# 1000
                                CurrPosInCycles[i]:=long[currPosAddr][i] * us
                                if (long[GradMoveAddr]& |<i) or (long[AccDecMoveAddr] & |<i)
                                      pulses[i] := pulses[i] + ExtraPulses
                          if pulses[i]  
                                if long[GradMoveAddr]& |<i 'Gradual Move
                                      if u[i]==0
                                            u[i]:= (long[newPosAddr][i] - long[CurrPosAddr][i])* us  / long[NumPulsesAddr][i]  'if utility value u has not been calculated yet then calculate it
                                            'Because u is calculated with integers and not reals it may be not too precise for very slow movements
                                      if pulses[i]>ExtraPulses    'Only add delta u for the movement pulses not for the extra ones sent at the end
                                            CurrPosInCycles[i] += u[i]
                                elseif long[AccDecMoveAddr] & |<i  'Accelerated/Decelerated Move. Comment out this section if second cog for Float32 not used.
                                      if u[i]==0
                                            u[i]:=F.FSub(F.FFloat(long[newPosAddr][i]),F.FFloat(long[CurrPosAddr][i]))
                                            u[i]:=F.FMul(u[i],F.FFloat(us))
                                            u[i]:=F.FDiv(u[i],F.FFloat(long[NumPulsesAddr][i]))
                                            angleDelta[i]:=F.FDiv(pimul2,F.FFloat(long[NumPulsesAddr][i]))
                                            angle[i]:=pidiv2
                                            v[i]~
                                            StartPosInCycles[i]:=CurrPosInCycles[i]
                                      elseif pulses[i]>ExtraPulses    'Only add delta u for the movement pulses not for the extra ones sent at the end. Elseif is used so this only happens on the next cycle and leave the first cycle to calc u[i] which takes a long of time because of the floating point calcs
                                            angle[i] := F.FAdd(angle[i],angleDelta[i])
                                            v[i]:= F.FAdd(v[i],1.0)
                                            v[i]:= F.FSub(v[i],  F.Sin(angle[i]))
                                            CurrPosInCycles[i] := StartPosInCycles[i] + F.FRound(F.FMul(u[i],v[i]))
                                else 'it is not a gradual or accelerated/decelerated move so then send fixed pulses
                                      if u[i]==0
                                            u[i]:=1
                                            long[currPosAddr][i]:= long[NewPosAddr][i]
                                            CurrPosInCycles[i] := long[NewPosAddr][i]*us  
                                pulses[i]-- 'If there are still pulses decrement by one
                                if pulses[i]==0
                                      long[currPosAddr][i]:= long[NewPosAddr][i]      
                                      u[i]~  'set utility value to cero so we know it has not been calculated
                                      long[NumPulsesAddr][i]~   
        'Wait for the next 2.7 ms frame.
              waitcnt(t += frame) 
                               
        'After all seven frames are completed, (18.9 ms), wait 1.1 more ms for a 20 ms cycle
        waitcnt(t += cycleEnd)


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