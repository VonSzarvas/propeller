''******************************
''*   RPN 2-list Calc + Vars   *
''*   (C) 2006 Matteo K. Borri *
''******************************                                                                
''
obj
     m: "DynamicMathLib"  ' use your favorite math library here I guess...
     s: "FtoF" ' for int/float... MOVE THAT TO FTOF BECAUSE IT MAKES MORE SENSE THERE.
     
con
        NaN             =       $7FFF_FFFF ' used to mean invalid value in floating point
        TempStrSize = 64

var

        byte OpsList[32]
        long NumList[20]
        byte tempstr[TempStrSize]
        'long pcnt
        'byte ocnt
        'byte ncnt
        'byte pt
        'long tempnum
        'long stack[10]
        
' I take a string in and parse it into two lists, one contains constants, the other contains operation tokens
' for reverse polish notation. The # symbol means "get the next constant from the list and push it on the
' stack" and a letter A-Z means "get the corresponding variable and push it". Everything is floats.

' This thing can probably be optimized a lot.

pub fast
    m.lock
pub slow
    m.unlock
    m.forceslow
pub auto
    m.unlock
    m.allowfast
pub ExpressionParserRPN (InputStringAddr, InputVarAddr1, InputVarAddr2, Mark)        ' this shouldn't really get used much -- more efficient to tokenize separately

    ExpressionTokenizer(InputStringAddr, @OpsList, @NumList, Mark)
    return ExpressionParser(InputVarAddr1, InputVarAddr2, @OpsList, @NumList)

    
pub ExpressionTokenizer (InputStringAddr, OpsListAddr, NumListAddr, Mark) | pcnt, ocnt, ncnt, pt, tempnum

      'pcnt~

      bytemove(@tempstr+1, InputStringAddr, constant(TempStrSize-2))
      tempstr[0] := " "
      tempstr[constant(TempStrSize-1)]~' := 0
      
      'floatout := m.ffloat(pcnt)

      ncnt~
      
      repeat 
          ocnt := @tempstr  
          pcnt := s.ParseNextFloat(ocnt, @tempnum)

          if pcnt == -1
             quit
             
          long[NumListAddr + ncnt] := tempnum
          ncnt += 4
          ocnt += pcnt   ' should speed things up somewhat
             
'      until pcnt == -1    

      pcnt~
      ocnt~

      

      repeat

        case (tempstr[pcnt])

          13,10,"@":
              tempstr[++pcnt]~ 'ok, get out'
              if Mark
                   byte[InputStringAddr + pcnt]~

          " ":
              pcnt := pcnt' do nothing with spaces
          
          other:
              byte[OpsListAddr + ocnt++] := tempstr[pcnt]
              if tempstr[pcnt] == "#"
                 repeat until tempstr[++pcnt] <>  "#"
                 pcnt--
        pcnt++
        
      until ((tempstr[pcnt] == 0))
      
      if byte[OpsListAddr + --ocnt] <> 0
             byte[OpsListAddr + ++ocnt]~

' ok so far
    if (Mark)
        byte[InputStringAddr]~'  := 0 ' marks a string as already parsed, so don't do it twice -- erases first character of it.

con
   MORETHAN = 1
   LESSTHAN = -1
   EQUALS   = 0

pub ExpressionParser (InputVarAddr1, InputVarAddr2, OpsListAddr, NumListAddr) | padding, tempnum, stack[10], pcnt, ocnt, ncnt, pt

'' it is very worthwhile to optimize the shit out of this!!!!

          longfill(@padding, 0, 16) ' clear the stack k?

          pt := -4
          repeat
             case byte[OpsListAddr + ocnt]
             
               0, 13, 10, "@" :
                           if (pt < 0)
                              return NaN     ' return not-a-number in case we screwed up (will be caught by the parse parameter, must be caught by the servo handler)
                           else
                              return stack[pt]              '           that's all folks!

               "#": pt += 4' := pt + 4              ' read in next numeric operator
                    stack[pt] := long[NumListAddr + ncnt]      
                    ncnt += 4 ':= ncnt + 4

               "A".."Z": 'if (InputVarAddr1)     
                                pt += 4' := pt + 4
                                stack[pt] := long[InputVarAddr1 + (byte[OpsListAddr + ocnt] - "A")*4]  ' A is 0, B is 1 (4), C is 2 (8) etc.

               "a".."z": 'if (InputVarAddr2)     
                                pt += 4' := pt + 4
                                stack[pt] := long[InputVarAddr2 + (byte[OpsListAddr + ocnt] - "a")*4]  ' A is 0, B is 1 (4), C is 2 (8) etc.

               "+": pt -= 4' := pt - 4
                    stack[pt] := m.fadd(stack[pt], stack[pt + 4])                                       ' addition
               "*": pt -= 4' pt := pt - 4
                    stack[pt] := m.fmul(stack[pt], stack[pt + 4])                                       ' multiplication
               "/": pt -= 4' pt := pt - 4
                    stack[pt] := m.fdiv(stack[pt], stack[pt + 4])                                       ' division
               "\": pt -= 4' pt := pt - 4
                    stack[pt] := m.fdiv(stack[pt + 4], stack[pt])                                       ' flipped division 
               "-": pt -= 4' pt := pt - 4
                    stack[pt] := m.fsub(stack[pt], stack[pt + 4])                                       ' subtraction
               "_": pt -= 4' pt := pt - 4
                    stack[pt] := m.fsub(stack[pt + 4], stack[pt])                                       ' flipped subtraction
               "^": pt -= 4' pt := pt - 4
                    stack[pt] := m.fpow(stack[pt], stack[pt + 4])                                       ' power 
               "%": pt -= 4' pt := pt - 4
                    stack[pt] := m.fmod(stack[pt], stack[pt + 4])
                                                           ' modulus

               ' thanks to Amy Felty for extension

               ' ~ is somewhat ambiguous: if used on the only # on the stack, acts as boolean negation; otherwise acts as angle difference
               
               "~":
                    if pt < 2 ' no numbers on stack
                       if stack[pt] == 0.0
                          stack[pt] := 1.0
                       else
                          stack[pt] := 0.0
                    else            
                       pt -= 4' pt := pt - 4
                       stack[pt] := m.FMathTurnAmount(stack[pt], stack[pt + 4])                           ' angle difference

                    
               
               

               
               ">": pt -= 4' pt := pt - 4    
                    stack[pt] := m.fabs(m.ffloat(m.fcmp(stack[pt], stack[pt + 4]) > 0))                 ' returns 1 if greater, 0 otherwise
               "<": pt -= 4' pt := pt - 4    
                    stack[pt] := m.fabs(m.ffloat(m.fcmp(stack[pt], stack[pt + 4]) < 0))                 ' returns 1 if lesser, 0 otherwise
               "=": pt -= 4'p_cnt := p_cnt - 4 
                    stack[pt] := (m.ffloat( m.fround(m.fmul(100.0,stack[pt + 4])) == m.fround(m.fmul(100.0,stack[pt])) ) ) & $7FFF_FFFF    ' compares to nearest 0.01 otherwise it's unusable
               "?": pt -= 4' pt := pt - 4                                                 
                    stack[pt] := m.ffloat(m.fcmp(stack[pt], stack[pt + 4]))                             ' general compare operation, returns -1 0 +1

                    
              
               
               ":": tempnum := stack[pt - 4]                                                            ' swaps X and Y instead (thanks Dave!)
                    stack[pt - 4] := stack[pt]
                    stack[pt] := tempnum~
                    'tempnum~


                    
               "`": stack[pt] := m.FMathAngle(stack[pt])

               "|": stack[pt] &= $7FFF_FFFF':= m.fabs(stack[pt])    

               "!": stack[pt] ^= $8000_0000':= m.fneg(stack[pt]) ' warning: triple-negativing something will trigger a nav packet... but how often does that happen?    

               "$": 'stack[pt] ':= M_fsqr2(stack[pt]) 'm.fmul(m.fsign(stack[pt]), m.fsqr(m.fabs(stack[pt]))) ' symmetric square root: for example, $( -9) = -3 this makes sense for servos
                              if (stack[pt] & $8000_0000) ' if neg
                                  stack[pt] &= $7FFF_FFFF ' absval
                                  stack[pt] := m.fsqr(stack[pt]) | $8000_0000 'then sqrt, then neg
                              else
                                  stack[pt] := m.fsqr(stack[pt]) ' if pos, just sqrt     


               ' why did I just write a function generator? sine wave / tri wave / square wave. Use for whatever

               
               "(": stack[pt] := m.fsinD(stack[pt]) ' remember that we're in RPN so this is actually NOT a parenthesis, but it looks curvy so let's use it

               ")": stack[pt] := m.fcosD(stack[pt]) ' remember that we're in RPN so this is actually NOT a parenthesis, but it looks curvy so let's use it

               "[": if (m.fcmp(m.fmod(m.fadd(stack[pt], 360.0), 360.0), 180.0) < 0) ' square wave, same period as sine/cosine 0... 180: up   270...360: dn
                        stack[pt] := 1.0
                    else
                        stack[pt] := -1.0
               "]": if (m.fcmp(m.fmod(m.fadd(stack[pt], 450.0), 360.0), 180.0) < 0) ' square wave, same period as sine/cosine 0... 180: up   270...360: dn
                        stack[pt] := 1.0
                    else
                        stack[pt] := -1.0


'' @EX U 0 U | 30 > &     " if mag(U) >30, U (meaning slam pretty much), else 0)
'' can become
'' U 30 [       
'' maybe?
                      

               "{": pt -= 4      ' curly [' deadzone operation
                    if(m.fcmp(m.fabs(stack[pt]), stack[pt + 4]) < 0)
                       stack[pt]~
                    'else stack[pt] := stack[pt]



               "}": pt -= 4      ' curly ]' clamp operation
               
                    if m.fcmpi((stack[pt] & $7FFF_FFFF), MORETHAN, (stack[pt + 4] & $7FFF_FFFF) )
                       stack[pt] := stack[pt + 4] | (stack[pt] & $8000_0000)
                       
                       

{  ' triangle waves we're not using                                                          4
               "{": tempnum := m.fmod(m.fsub(stack[pt], 450.0),360.0)
                    case m.ftrunc(tempnum) ' triangle wave: 0 = 0, 90 = 1, 180 = 0, 270 = 1, 360 = 0
                        0 .. 179 : stack[pt] := m.fadd(-1.0, m.fdiv(tempnum,90.0))
                      180 .. 360 : stack[pt] := m.fsub(1.0, m.fdiv(m.fsub(tempnum, 180.0),90.0))
                    tempnum~  
               "}": tempnum := m.fmod(m.fsub(stack[pt], 540.0),360.0)
                    case m.ftrunc(tempnum) ' triangle wave: 0 = 0, 90 = 1, 180 = 0, 270 = 1, 360 = 0
                        0 .. 179 : stack[pt] := m.fadd(-1.0, m.fdiv(tempnum,90.0))
                      180 .. 360 : stack[pt] := m.fsub(1.0, m.fdiv(m.fsub(tempnum, 180.0),90.0))
                    tempnum~
}
             
             if (pt < -4)   ' stack sanity check
                 pt := -4
                 
             ocnt++

                                      