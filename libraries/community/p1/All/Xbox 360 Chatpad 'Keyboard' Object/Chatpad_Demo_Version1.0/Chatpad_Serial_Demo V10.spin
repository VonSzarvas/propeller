{
*******************************************************************
                   Chatpad Demo Version 1.0
*******************************************************************

 DESCRIPTION:   This spin code demonstrates how to interface
                to a XBOX 360 Chatpad keyboard. The Parallax
                Serial Terminal software may be used to view
                the keyboard characters typed.

                Communication with the PC is at 115.2kbaud.

                The Chatpad object communicates serially
                @ 19.2Kbaud with the Chatpad. It handles
                device initialization as well the need to
                send the Chatpad a "stay awake" message
                every few seconds. A key press will trigger
                an 8-byte 'keycode' message. The object
                will internally translate this message into
                the selected character.

                Note: keys were translated to closely match
                the Parallax Serial Terminal. The 'people'
                button was selected to permit some special
                screen operations like Clear Screen, etc.
                
*******************************************************************
}

CON

    _clkmode = xtal1 + pll16x   'Oscillator freq is multiplied x16 by PLL.                      
    _xinfreq = 5_000_000        'Note: Select correct osc frequency !!
                                'In this case, an ext. 5 Mhz crystal.
        
  'PC Serial interface pins
  '------------------------  
    SerRxPin  = 31  'input  - data from PC (PC-TX, DB-9, pin 3, thru inverter)
    SerTxPin  = 30  'output - data to PC (PC-RX, DB-9, pin 2, thru inverter)             
    BaudRate_PC = 115200     'PC serial baud rate
       
  'NOTE:  Propeller's RESETn (physical pin# 11) connected to serial PC-DTR (pin 4) via an inverter.
  
  'ChatPad Serial interface pins
  '------------------------------
    ChatRxPin = 1   'Propeller serial input   (from Chatpad's 'ChatTx' serial output pin 5)
    ChatTxPin = 0   'Propeller serial output  (to Chatpad's 'ChatRx' serial input pin 6)


{ '==============================================================================

       To:ChatRxPin                  From: ChatTxPin
                                                  ┌──── Tested with separate 3.3v regulator
            Chat                             Chat        
        Gnd  Tx       Audio Plug              Rx   +3v
       ‣‣       -shield      ‣‣   
                            -ring(spk?)
                              -tip (mic?)

  Internal to the ChatPad, the 7 electrical connections above are routed to the
  PCB board via a 7-pin connector:

      pin 1 : shield
      pin 2 : ring   (speaker ~250 ohms)
      pin 3 : tip    (microphone) 
      pin 4 : pwr gnd
      pin 5 : chatTx  ( to ChatRxPin @ Propeller)
      pin 6 : chatRx  ( from ChatTxPin @ Propeller)
      pin 7 : pwr +3.3v

  NOTE:  Please confirm speaker & microphone connections.
         I have not yet experimented with them, so proceed with caution.
         I believe the speaker/mic headset when attached makes a direct
         feed-through connection to the Audio Plug above.
         
'==================================================================================
    
  }
      
OBJ

    SER_PC :   "FullDuplexSerial6"   'PC serial communication
    SER_CHAT:  "ChatPad_ObjectV10"   '19.2Kbaud Chatpad serial interface
  
PUB Command_Processor | temp

   '.Start(rxpin, txpin, mode, baudrate)
    SER_PC.Start(SerRxPin,SerTxPin,0,Baudrate_PC)

   '.Start(rxpin, txpin)
    SER_CHAT.Start(ChatRxPin,ChatTxPin)  
        
   '############################################
   
    repeat 'forever ...

       if (temp:= SER_CHAT.rxcheck) => 0    'From ChatPad @ 19.2 Kbaud
           SER_PC.tx(temp)                  'To PC @ 115.2 Kbaud

      
   '###########################################

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