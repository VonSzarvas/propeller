'******************************************************************************
' C malloc written in Spin
' Author: Dave Hein
' Copyright (c) 2010
' See end of file for terms of use.
'******************************************************************************
'******************************************************************************
' Revison History
' v1.0 - 4/2/2010 First official release
'******************************************************************************
{
  This object contains the malloc, free and calloc routines used by clib.
}
CON
  NEXT_BLK = 0
  BLK_SIZE = 1
  HDR_SIZE = 4
  RAM_SIZE = $8000

DAT
  locknum word 0
  memfreelist word 0
  malloclist word 0

PUB mallocinit(stacksize) | currblk
'' Initialize the malloc heap "stacksize" longs after the current stack pointer
'' Allocate a lock and return the lock number plus one if successful, or zero if not
  locknum := locknew
  currblk := @stacksize + (stacksize << 2)
  memfreelist := currblk
  word[currblk]{NEXT_BLK} := 0
  word[currblk][BLK_SIZE] := RAM_SIZE - currblk
  return locknum + 1

PUB malloc(size) | prevblk, currblk, nextblk
'' Allocate a memory block of "size" bytes.  Return a pointer to the clock if
'' successful, or zero if a large enough memory block could not be found
  prevblk := 0
  if (size =< 0)
    return 0
  repeat until not lockset(locknum)
  currblk := memfreelist

  ' Adjust size to nearest long plus the header size
  size := ((size + 3) & (!3)) + HDR_SIZE

  ' Search for a block of memory
  repeat while (currblk)
    if (word[currblk][BLK_SIZE] => size)
      quit
    prevblk := currblk
    currblk := word[currblk]{NEXT_BLK}

  ' Return null if block not found
  if (currblk == 0)
    lockclr(locknum)
    return 0

  ' Split block if larger than needed
  if (word[currblk][BLK_SIZE] => size + HDR_SIZE + 4)
    nextblk := currblk + size
    word[nextblk]{NEXT_BLK} := word[currblk]
    word[nextblk][BLK_SIZE] := word[currblk][BLK_SIZE] - size
    word[currblk][BLK_SIZE] := size

  ' Otherwise, use space without splitting
  else
    nextblk := word[currblk]{NEXT_BLK}

  ' Remove from the memfreelist
  if (prevblk)
    word[prevblk]{NEXT_BLK} := nextblk
  else
    memfreelist := nextblk

  ' Add to the beginning of the malloc list
  word[currblk]{NEXT_BLK} := malloclist
  malloclist := currblk
  lockclr(locknum)
  return currblk + HDR_SIZE
  
PUB free(ptr) | prevblk, currblk, nextblk
'' Return the memory block at "ptr" to the free list.  Return a value of one
'' if successful, or zero if the memory block was not on the allocate list.
  prevblk := 0
  repeat until not lockset(locknum)
  nextblk := malloclist
  currblk := ptr - HDR_SIZE

  ' Search the malloclist for the currblk pointer
  repeat while (nextblk)
    if (currblk == nextblk)
      ' Remove from the malloc list
      if (prevblk)
        word[prevblk]{NEXT_BLK} := word[nextblk]{NEXT_BLK}
      else
        malloclist := word[nextblk]{NEXT_BLK}
      ' Add to the free list
      meminsert(nextblk)
      lockclr(locknum)
      return 1
    prevblk := nextblk
    nextblk := word[nextblk]{NEXT_BLK}

  ' Return a NULL value if not found
  lockclr(locknum)
  return 0

PRI meminsert(currblk) | prevblk, nextblk
'' Insert a memory block back into the free list.  Merge blocks together if
'' the memory block is contiguous with other blocks on the list.
  prevblk := 0
  nextblk := memfreelist

  ' Find Insertion Point
  repeat while (nextblk)
    if ((currblk => prevblk) and (currblk =< nextblk))
      quit
    prevblk := nextblk
    nextblk := word[nextblk]{NEXT_BLK}

  ' Merge with the previous block if contiguous
  if (prevblk and (prevblk + word[prevblk][BLK_SIZE] == currblk))
    word[prevblk][BLK_SIZE] += word[currblk][BLK_SIZE]
    ' Also merge with next block if contiguous
    if (prevblk + word[prevblk][BLK_SIZE] == nextblk)
      word[prevblk][BLK_SIZE] += word[nextblk][BLK_SIZE]
      word[prevblk]{NEXT_BLK} := word[nextblk]{NEXT_BLK}

  ' Merge with the next block if contiguous
  elseif (nextblk and (currblk + word[currblk][BLK_SIZE] == nextblk))
    word[currblk][BLK_SIZE] += word[nextblk][BLK_SIZE]
    word[currblk]{NEXT_BLK} := word[nextblk]{NEXT_BLK}
    if (prevblk)
      word[prevblk]{NEXT_BLK} := currblk
    else
      memfreelist := currblk

  ' Insert in the middle of the free list if not contiguous
  elseif (prevblk)
    word[prevblk]{NEXT_BLK} := currblk
    word[currblk]{NEXT_BLK} := nextblk

  ' Otherwise, insert at beginning of the free list
  else
    memfreelist := currblk
    word[currblk]{NEXT_BLK} := nextblk

PUB calloc(size) | ptr
'' Allocate a memory block of "size" bytes and initialize to zero.  Return
'' a pointer to the memory block if successful, or zero if a large enough
'' memory block could not be found.
  ptr := malloc(size)
  if (ptr)
    longfill(ptr, 0, (size + 3) >> 2)
  return ptr

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