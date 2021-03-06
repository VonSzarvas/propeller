{{ SCA100T.spin }}
{
*************************************************
    SCA100T series Interface Object, for dual axis inclinometer series VTI technologies 

    Revision history:
    August 11, 2008
    v1.0: initial
    Rob van den Berg (robvdberg@kabelfoon.net)     
*************************************************
                  
  Init(cs,clk,sdi,sdo) : to be called first 
  GetValue(0)   : get 11 bits of X data MSB first
  GetValue(1)   : get 11 bits of Y data MSB first 

                                  Vcc +5V
                   SCA100T series    │                
               ┌──────────────────┐  │ 
 (P1) ───────┤1 SCK     Vcc   12├──┘         Vcc = 5V
               │2 NC      OUT_1 11│                  
 (P2) ───────┤3 MISO    ST_1  10├─ Vss       
 (P3) ───────┤4 MOSI    ST_2   9├─ Vss                 
               │5 OUT_2   NC     8│
             ┌─┤6 GND     CSB    7├───── (P0)
             │ └──────────────────┘             
            Vss                                Resisters are 1K, as per 5V to 3.3V interface thread.
          
Notes:

}

CON                                                                            
' data command to start reading X and Y value 
  ch_X = %00010000      'command RDAX, read X-channel acceleration through SPI
  ch_Y = %00010001      'command RDAY, read Y-channel acceleration through SPI
  
VAR
  byte SPI_CS   'Chip select out connected to SCA100T CSB pin
  byte SPI_CLK  'Clock out to SCA100T SCK pin
  byte SPI_SDI  'Data in connected to SCA100T MISO pin
  byte SPI_SDO  'Data out connected to SCA100T MOSI pin

PUB Init(cs,clk,sdi,sdo)
  SPI_CS  := cs
  SPI_CLK := clk
  SPI_SDI := sdi  
  SPI_SDO := sdo
  'setup lines
  outa[SPI_CS]~        'select normally low                           
  dira[SPI_CS]~~       'set to output
  
  outa[SPI_CLK]~       'clock normally low
  dira[SPI_CLK]~~      'set to output

  outa[SPI_SDO]~       'SDO normally low              
  dira[SPI_SDO]~~      'set to output

  outa[SPI_SDI]~       'SDI input
  dira[SPI_SDI]~                                   
  
PUB GetValue( chan ) : val

  if (chan == 0)
    val := write (ch_X) 'get X value 
  if (chan == 1)
    val := write (ch_Y) 'get Y value
  return val

PRI write( cmd ) : datar | i  
  datar := 0                    ' Clear the data storage LONG

  outa[SPI_CS]~                 ' set Chip Select Low          
  writeByte( cmd )              ' Write the command to start conversion 
  
 ' Ok now get the Conversion for this channel  
  repeat i from 10 to 0         ' read 11 bits 10-0 for MSB
    outa[SPI_CLK]~~             ' toggle clk pin High
    if ina[SPI_SDI] == 1         
      datar |= |< i             ' set bit i HIGH
    else
      datar &= !|< i            ' set bit i LOW
    outa[SPI_CLK]~              ' toggle clk pin Low

  outa[SPI_CS]~~                ' set Chip Select High
            
  return datar

PRI writeByte( cmd ) 
  repeat 8                      ' SPI interface use 8-bit instruction (or command) register     
    outa[SPI_SDO] := cmd >>7    ' send MSB bit by shifting it into b0
    outa[SPI_CLK]~~             ' toggle clk pin High, Chip reads on rising edge. 
    outa[SPI_CLK]~              ' toggle clk pin Low
    cmd <<= 1                   ' move next bit into MSB position
     