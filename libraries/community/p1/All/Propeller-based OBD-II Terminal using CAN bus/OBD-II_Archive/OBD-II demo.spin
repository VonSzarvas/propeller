{{┌────────────────────────────────────────────────────┐
  │ OBD-II Demo using the CANbus controller OBD object │
  │ Author: Chris Gadd                                 │
  │ Copyright (c) 2015 Chris Gadd                      │
  │ See end of file for terms of use.                  │
  └────────────────────────────────────────────────────┘

  This object uses the serial terminal at 115,200bps to receive commands and display the response
    Supported commands are:
      List: Interrogates the on-board computer to determine which PIDs are supported, queries all of those PIDs, and displays the PID number, a description, and the current value
      Query: Accepts a two hexadecimal digit PID, queries the computer, and displays the response
      Poll:  Same as query, but updates once a second
      Direct: Allows any Mode from 0 to 9 and any PID from $00 to $FF to be queried.  Not fully tested.
    The commands are case-insensitive, only letters and numbers, backspace and enter are recognized

                 5V                                  OBD-II connector (Vehicle side)
                     MCP 2551                       
                  │ ┌───────┐                                        ┌Gnd        
  Tx_pin ────────┼─┤TxD    Rs├─┐                                      │ ┌CANH     
                ┌─┼─┤Vss  CANH├─┼─────┳──             
           10KΩ │ └─┤Vdd  CANL├─┼───┳─┼──            \   ┌┐┌┐┌┐┌┐┌┐┌┐┌┐┌┐┌┐┌┐   /   
  Rx_pin ────┼───┤RxD  Vref├ │   │ │                \  └┘└┘└┘└┘└┘└┘└┘└┘└┘└┘  /    
                │   └─────────┘ │   │ │                 \ ┌┐┌┐┌┐┌┐┌┐┌┐┌┐┌┐┌┐┌┐ /     
                │            1KΩ    61Ω               \└┘└┘└┘└┘└┘└┘└┘└┘└┘└┘/      
                │               │   └┳┘                          
                │               │   0.1nF                             │   └+12V   
                                                                      └CANL       
}}                                    
CON
  _clkmode = xtal1 + pll16x
  _xinfreq = 5_000_000

  CAN_rx   = 25
  CAN_tx   = 24

VAR
  word  Rx_buffer
  word  String_address
  byte  Command[10]             ' List / Query xx / Poll xx

OBJ
  fds: "FullDuplexSerial"
  obd: "OBD-II main"

DAT                     org
help      byte          "OBD-II Serial Terminal Commands",$0D,{
                       }"  List",$09,$09,"Lists all of the PIDs supported by your on-board computer, with descriptions and current values",$0D,{
                       }"  Query $01",$09,"Reads the PID identified by the two hexadecimal digits (spaces and $ are ignored and can be omitted)",$0D,{
                       }"  Poll $01",$09,"Reads the PID identified by the two hexadecimal digits once per second",$0D,{
                       }"  Direct",$09,"Allows mode and PID to be entered directly (Responses are not fully supported)",$0D,$00  
                       
PUB Main 

  Rx_buffer := obd.Start(can_rx,can_tx)
  String_address := Rx_buffer + 8
  
  fds.Start(31,30,0,115200)
  waitcnt(clkfreq + cnt)

  fds.Tx($00)
  fds.Str(@help)

  repeat
    fds.Tx($0D)
    fds.Str(string("Enter command: "))
    getString(@command)
    case command
      "L": List
      "Q": Query(parse(@command))
      "P": Poll(parse(@command))
      "D": Direct
      "H": fds.Str(@Help)
      other: fds.Str(string("Type 'help' for commands"))

PRI getString(ptr) | rx_byte, i                                                 '' Stores characters from the serial terminal into a string

  i~
  repeat
    rx_byte := fds.Rx
    case rx_byte
      $0D               : quit                                  
      $08               : i := i - 1 #> 0                       
      "A".."Z","0".."9" : byte[ptr][i++ <#9] := rx_byte         
      "a".."z"          : byte[ptr][i++ <#9] := rx_byte - $20   
  byte[ptr][i] := $00

PRI parse(ptr) | i                                                              '' Converts the final two ASCII characters of a string into a hex value

  i := strsize(ptr) - 2 #> 0
  repeat until i == strsize(ptr)
    result := result << 4 | lookdownz(byte[ptr][i] : "0".."9", "A".."F")
    i++

PUB Direct | rx_byte, mode, pid                                                 '' Send any mode and pid and display the response

  fds.Str(string("Enter Mode: "))
  getString(@mode)
  mode := parse(@mode)

  fds.Str(string("Enter PID: "))
  getString(@pid)
  pid := parse(@pid)

  if obd.Query_s(mode,pid)
    fds.Str(OBD.PID_lookup(pid))
    fds.Tx($09)
    fds.Str(string_address)
    fds.Tx($0D)

PUB Query(pid) | i                                                              '' Send a single query and display the response
  if obd.Query_s(1,pid)                                                                                       
    fds.Str(obd.pid_lookup(pid))                                                                              
    fds.Tx($09)                                                                                               
    fds.Str(String_address)                                                                                   
    fds.Tx($0D)                                                                                               

PUB Poll(pid) | i, t                                                            '' Repeatedly poll and display the response
  fds.Str(string("Polling - press any key to stop",$0D))                         
  fds.Str(obd.pid_lookup(pid))                                                   
  t := cnt                                                                       
  repeat while fds.RxCheck == -1                                                 
    if cnt - t > clkfreq                                                         
      t += clkfreq                                                               
      if obd.Query_s(1,pid)                                                      
        fds.Str(string($0E,50))                                                  
        fds.Str(string_address)                                                  

PUB List | pid, pids_supported                                                  '' List every pid supported and display the current values

  pid := 0
  repeat
    if obd.Query(1,pid)
      pids_supported := byte[Rx_buffer + 3] << 24 + byte[Rx_buffer + 4] << 16 + byte[Rx_buffer + 5] << 8 + byte[Rx_buffer + 6]
      repeat 32
        if pids_supported <- pid & 1 or not pid // $20
          obd.Query_s(1,pid)
          fds.Hex(pid,2)                  
          fds.Tx($09)                     
          fds.Str(obd.pid_lookup(pid))    
          fds.Str(string($0E,50))         
          fds.Str(string_address)         
          fds.Tx($0D)
        pid++
      if pids_supported & 1 == 0
        fds.Str(string("Finished",$0D))
        quit
    else
      fds.Str(string("None found",$0D))
      quit

DAT                     
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