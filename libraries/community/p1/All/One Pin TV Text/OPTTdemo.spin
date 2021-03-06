CON
  ' Set up the processor clock in the standard way for 80MHz
  _XINFREQ = 5_000_000 + 0000                           ' Demoboard
  _CLKMODE = XTAL1 + PLL16X                             ' Demoboard

  TEXTCOLS = 16
  TEXTROWS = 12                     

OBJ
   optt : "OnePinTVText"
   font1 : "AiChip_SmallFont_Atari_lsb_001"
   font2 : "hexfont"
   font3 : "hexfont2"

VAR
  BYTE text[TEXTROWS*TEXTCOLS]

PUB main | i, j

  op_charptr := @text
  op_fontptr := font2.GetPtrToFontTable
  if font2#AS_VIEWED
    op_mode |= CONSTANT( 1<<3 )
  optt.start( @op_mode )

  repeat i from 0 to CONSTANT(TEXTROWS*TEXTCOLS-1)
    text[i] := j?

  repeat
    repeat i from 0 to CONSTANT(TEXTROWS*TEXTCOLS-2)
      if text[i] > text[i+1]
        j := text[i+1]
        text[i+1] := text[i]
        text[i] := j

DAT
'' one pin parameters - 8 contiguous longs
''
op_mode       LONG      1+1<<2+9<<8             ' 0 = inactive
                                                ' [1..0] 1 = NTSC(262@60), 2 = PAL (312@50)
                                                ' [2] 0 = single line res, 1 = double line res
                                                ' [3] 0 = lsb first font, 1 = msb first font (slower)
                                                ' [6] 0 = default pixel clock, 1 = use op_pixelclk
                                                ' [7] 0 = default blank duty, 1 = use op_blankfrq
                                                ' [11..8] pixels per character 0 = default (8)
op_pin        LONG      14                      ' input  pin number     
op_charptr    LONG      0                       ' input  pointer to screen (bytes)
op_fontptr    LONG      0                       ' input  pointer to font (8 bytes/char)
op_cols       LONG      TEXTCOLS                ' input  number of columns
op_rows       LONG      TEXTROWS                ' input  number of rows
op_pixelclk   LONG      0_000_000               ' input  pixel clock frequency (Hz) 0=auto
op_blankfrq   LONG      $0000_0000              ' input  blank duty counter 0=default

{{
┌──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│                                 One Pin TV Text Driver demo (C) 2009-07-09 Eric Ball                                         │                                                            
├──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│                                    TERMS OF USE: Parallax Object Exchange License                                            │                                                            
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