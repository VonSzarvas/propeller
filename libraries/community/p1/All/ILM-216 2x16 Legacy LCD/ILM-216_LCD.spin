'' Modified version of Parallax Serial LCD Driver
''
'' Supports Legacy ILM-216 2x16 Serial LCD Module
'' ILM-216 requires inverted data bits and has different control functions
'' ILM-216 is also very slow to respond to CLS
'' 31 Jan 2007


CON

  CURSOR_OFF    = $04                                   ' cursor off
  CURSOR_ULINE  = $05                                   ' show underline cursor
  CURSOR_BLOCK  = $06                                   ' show blinking-block cursor
  CURSOR_POS    = $10                                   ' position cursor
  LCD_BKSPC     = $08                                   ' move cursor left
  LCD_RT        = $09                                   ' move cursor right
  LCD_LF        = $0A                                   ' move cursor down 1 line
  LCD_CLS       = $0C                                   ' clear LCD (follow with Long delay)
  LCD_CR        = $0D                                   ' move pos 0 of next line
  LCD_BL_ON     = $0E                                   ' backlight on
  LCD_BL_OFF    = $0F                                   ' backlight off

   
  LCD_LINE0     = $40                                   ' line 0, column 0
  LCD_LINE1     = $50                                   ' line 0, column 0

VAR

  word  tx, bitTime, started 


PUB start(pin, baud)

'' Initializes tx pin and bitTime if valid pin and baud

  started~ 
  if lookdown(pin : 0..27)                              ' qualify tx pin
    if lookdown(baud : 2400, 9600)                      ' qualify baud rate setting
        tx := pin
        outa[tx]~                                       ' make tx pin output LOW
        dira[tx]~~
        bitTime := clkfreq / baud                       ' calculate serial bit time
        started~~                                       ' mark started 

  return started


PUB stop

'' Makes serial pin an input

  if started
    dira[tx]~                                           ' make pin an input
    started~                                            ' set to false


PUB putc(txByte) | t

'' Transmit a byte

  if started
    txByte := (txByte | $100) << 2                      ' add stop bit 
    t := cnt                                            ' sync t to system counter
    repeat 10                                           ' start + eight data bits + stop
      outa[tx] := !(txByte >>= 1) & 1                   ' output bit (inverted mode)
      waitcnt(t += bitTime)                             ' wait bit time

    

PUB str(strAddr)

'' Transmit z-string at strAddr

  if started
    repeat strsize(strAddr)                             ' for each character in string
      putc(byte[strAddr++])                             '   write the character


PUB cls

'' Clears LCD and moves cursor to home (0, 0) position

  if started
    putc(LCD_CLS)
    waitcnt(clkfreq  + cnt)                           ' delay
    putc(LCD_CLS)                                     ' do it again
    waitcnt(clkfreq  + cnt)    


PUB home

'' Moves cursor to 0, 0

  if started
    putc(CURSOR_POS)
    putc(LCD_LINE0)
  
  
PUB clrln(line)

'' Clears line

  if started
    if lookdown(line : 0, 1)
      if line == 0                                       ' first line
        home
          repeat 16
            putc(32)
        home
      else                                               ' second line
        putc(CURSOR_POS)
        putc(LCD_LINE1)
          repeat 16
            putc(32)
        putc(CURSOR_POS)
        putc(LCD_LINE1)                                                        

      
PUB newLine

'' Moves cursor to next line

  if started
    putc(LCD_CR)
  

PUB gotoxy(col, line) | pos

'' Moves cursor to col/line

  if started
      if lookdown(line : 0..1)                          ' qualify line input
        if lookdown(col : 0..15)                        ' qualify column input
          putc(CURSOR_POS)
          if line == 0
            putc(  LCD_LINE0 + col)                     ' move to target position
          else
            putc(  LCD_LINE1 + col)                     ' move to target position                    

PUB backLight(status)

'' Enable (true) or disable (false) LCD backlight

  if started
    if status
      putc(LCD_BL_ON)
    else
      putc(LCD_BL_OFF)

PUB cursorOff

'' Turns cursor off

  putc(CURSOR_OFF)

PUB cursorBlock

'' display blinking-block cursor

   putc(CURSOR_BLOCK)
    
PUB cursorUline

'' display underline cursor

   putc(CURSOR_ULINE)   
      
 