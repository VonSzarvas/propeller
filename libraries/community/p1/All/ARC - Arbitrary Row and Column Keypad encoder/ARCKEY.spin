{{
**************************************************************************
*
*   ARCKEY.spin
*   ARC KEYBOARD SCANNER EMNCODER V1.0
*   October 2011 Peter Jakacki
*
**************************************************************************
}}
{
  ARBITRARY ROW & COLUMN KEYBOARD SCANNER

Description:
Here is a keyboard scanner that is not limited by the number or positions
of the rows and columns in a keyboard matrix. Essentially you can take a
bunch of unused pins from your Prop, even though they may be scattered here
and there, and use these to scan a keyboard/keypad.

My original implementation had all the rows and columns neatly together but
the keypad didn't match up. So this code will handle those different keypads
and/or allow you to use any combination of port pins for your matrix.

Any combination of row and column pins can be used, therefore any port pins
that are non-sequential can be used. This also means a change of keypad which
has different row and column conections can easily be accommodated. Matrix size
is only limited by the number of port pins available so it is possible for
instance to use 28 pins for scanning a 14x14 matrix of 196 keys and still have
I2C and RXD/TXD lines available.

Hardware requirments:
Each port pin has a optional current limit resistor (1K) along with a
corresponding pullup at least 5 times the value of the CLR.

                    Vdd
                     ┳
                      10K
Port•─────────────┴───────▶ ROW or COLUMN
           1K (optional)

The 1K resistor (Rcl) is optional as you may wish to drive an LCD module or
something else with these lines when it is not scanning. The resistor allows
the port pin to drive and LCD for instance without interference from any other
port pins due to buttons begin pushed. Without the Rcl the
pullup can be almost any value from 1K to 100K although 10K is fine.

Notes:
The row or column function is determined by the user software which supplies
the bit masks for both these two. An example is provided where we have a 4 x 8
matrix keypad but the column pins are scattered whereas the rows are all
contiguous.

        keypad.Initkeys(%00001011_00100000_00000000_00000000,%11111111)

If the connection stayed the same but the keypad changed so that we had a
6 x 6 matrix we might say:

        keypad.Initkeys(%00001011_00100000_00000000_11000000,%11111100)
thereby using two of the previous columns as rows which matched this keypad.

An optional scancode translation table
address may be supplied which will automatically translate scancodes into
a more friendly form such as standard ASCII.
The format for this table is:

DAT
keytbl  word    scancode,usercode
        word    scancode,usercode
        'etc etc
        word    0               ' marks the end of the table

To setup the table to use:
        keypad.translate(@keytbl)

}


var
  long rowmask,colmask,lastkey,debounce
  long  keytbl                  ' points to user keyboard translation table
                                '

'
' Application informs the keypad scanner of which pins it wants for rows and which for columns
' i.e.  InitKeys(%11001100,%100000110010) ' note that the pins are scattered
'
pub pins(rows,columns)      ' bitmasks of rows and columns - can be arbitrary
  rowmask := rows
  colmask := columns

'
' Supply an address to a translation table so that the keypad driver can
' translate the 10-bit scancode into a application friendly code such as ASCII
' Entries in the table are in words and the format of table is:
' scancode,usercode,scancode,usercode,.............0
' the last entry should be a zero for the scancode, no usercode is necessary

pub table(addr)
  keytbl := addr

pub translate(scancode) | i
    result := scancode
    i~                          ' scan through scancode to ASCII translation table
    repeat while word[keytbl][i]                       ' end of table?
      if result == word[keytbl][i]                     ' do we have a match?
         return word[keytbl][i+1]                      ' yes, return with ASCII (or 16-bit code)
      i += 2                                            ' jump to next table entry


' Application should poll "key" on a regular basis from 100 to 1000 times a second
' 'key' will return -1 if there is no new key
'
pub key
  result := scankeys
  if result+1 and keytbl        ' process as long as keycode is not -1
    result := translate(result)


' Application can also call scankeys which will return the scancode if a key is pressed
'
pub scankeys  | n,i,j                ' scan keypad and return with code else -1
  result := -1
  outa &= !colmask              ' drive all columns low with pullups
  dira |= colmask               ' all columns active
  n := ina & rowmask
  if n <> rowmask               ' active column detected if result does not match rowmask
    dira &= !colmask            ' return columns inactive
    debounce := 3              ' preset debounce for long enough time to cover debounce
    if lastkey == -1            ' process key as long as it's a new key press (must be idle before)
      repeat i from 0 to 31     ' check all possible mask positions
        if colmask & |<i        ' column in this position?
          dira[i]~~             ' drive this column low? (open-drain)
          n := ina & rowmask
          dira[i]~              ' release column
          if n <> rowmask         ' found the column yet?
                                ' yes, column found, now find row that's different
                                ' if rowmask = 110011 and n = 100011
                                ' 110011 xor 100011 = 10000
            n ^= rowmask        ' get active bit
            n := >|n            ' convert mask to a value+1
            n--                 ' zero based
            n += i<<5           ' merge row and column codes
            lastkey := n

            result := n         ' return with an intermediate 10-bit scan code
  else
    if debounce
      debounce--
    else
      lastkey := -1

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
