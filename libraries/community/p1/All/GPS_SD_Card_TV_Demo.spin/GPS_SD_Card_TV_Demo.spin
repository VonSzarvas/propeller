{{
GPS_SD_Card_TV_Demo_V2.spin

*****  THIS VERSION IS BUILT ON MY FIRST PROGRAM TO SUCCESSFULLY READ THE PARALLAX GPS UNIT'S NMEA MESSAGES AND SAVE THEM TO THE SD CARD  *****
*****  Use this program as a template for future work with GPS, NMEA, TV, and SD Cards                                                    *****

Giving credit to the folks that really make all this work...
(1)  The fsrw 2.6 routine that is called below as an OBJ file is Copyright 2009  Tomas Rokicki and Jonathan Dummer

(2)  The termial program that is called below is Parallax Serial Terminal.spin Version: 1.0
     It is Copyright (c) 2009 Parallax, Inc. - Authors: Jeff Martin, Andy Lindsay, Chip Gracey  

(3)  SD Card routine is based on a tutorial at:  http://gadgetgangster.com/tutorials/331
     The SD Card Routine was created by Jeff Ledger

(4)  The TV_Terminal.spin v1.1 program, by Chip Gracey, was used to send video to the Parallax TV Monitor

The Overall GPS_SD_Card_06.spin program was built on Jeff Ledger's SD Card routines and was modified as follow:
Greg Denson, 2011-05-30 To run SD Card Routine with my PPD Board and SD card holder.
Greg Denson, 2011-06-11 To begin adding routine to collect GPS NMEA strings and store them on SD Card
Greg Denson, 2011-06-11 Beginning to work on the write to the SD Card - Other routines are working OK.
Greg Denson, 2011-06-11 Had trouble with SD Cards, so cut this back to just reading NMEA and sending to PST.
Greg Denson, 2011-06-11 Solved the SC Card issues and came back to finally get the whole package working.
Greg Denson, 2011-06-11 Cleaned up some of the garbage characters in the SD Card text file, and moved the sdfat.popen and
                        sdfat.pclose statements outside of the main repeat loop that reads and writes the data.
Greg Denson, 2011-06-12 Added the TV Terminal Object to send all the messages to the small Parallax TV Monitor.                        
                         
NOTES:
This program works with the SD Card holder used with femtoBASIC on the Demo Board.

Use the pin numbers shown below in "CON" since they match the SD Card holder, too.

This program uses the Parallax Serial Terminal program to allow the user to input data.
When using this SD Card Routine in another program, I noticed on at least one occasion that
I had to restart the terminal and re-compile the program after removing the SD Card to read
the data on my PC.  Wasn't sure at first why this happened, but later learned that Pin 31,
used to receive data from the GPS conflicts with the loading and verification of the program via
the USB connector.  If GPS is connected to Pin 31 while loading and verifying the program, there
is a conflict.

So, my process to load and run the program is as follows:
 - Ensure that 4800 baud is set on the correct COM port for the PPDB Board.
 - Ensure all connections are correct for GPS and SD Card holder.
 - Be sure the Professional Development Board is switched off.
 - Insert SD Card in holder.
 - Connect USB and power cables if not already connected.
 - Turn on the PPDB Board's power switch.
 - Ensure that the GPS connection to Pin 31 is disconnected.
 - Use Propeller Tool to load the program into EEPROM.
 - Switch the PPDB Board off.
 - Connect GPS line that goes to Pin 31.
 - Switch the PPDB Board back on.
 - Start the Parallax Serial Terminal software, and be sure it is set for 4800 baud.
 - After a few seconds you should get a message in the Terminal that the SD Card is mounted.
 - A few more seconds, and you should start seeing NMEA sentences appear in th terminal.
 - After set number of NMEA msgs are processed, a message tells you the data is saved to your file.
 - Length of above delays, name of text file, message text, baud rate, etc., are set in the main program.
 - Make changes to these settings if necessary to give you more/less time for delays, etc.

 The Propeller Demo Board has a pre-wired RCA jack for TV output.  The TV_Terminal.spin program is also
 set up to work with the Demo board with no changes.  The Display.spin program in the Propeller Manual
 uses the TV_Terminal.spin program as an object, and no adjustments are necessary.

 Other boards may or may not have any built-in facilities for a TV signal.  The Propeller Professional
 Development Board had the RCA jack, and a 4-pin header with built-in resistors to use for your video signal.
 However, you still need to connect the header to the appropriate pins on the Propeller chip.

 I used the Propeller Demo Board's schematic to show me which Propeller pins are connected to the RCA TV jack.
 By following that example, and using Chip Gracey's TV_Terminal.spin program as an object in my main program,
 I had to make no changes to the TV setup, and the program put the data on my TV monitor on the second try.  I
 forgot to use call the Start method the first time, so NOTHING happened on that try (live and learn)!

 Finally, a few more words for beginners like me.  If you're new to using Spin and the Propeller Tool, and want
 to make changes to my program below, here are a few hints:

 - First, don't be afraid to experiment.  What you see below is the result of experimenting and finding SOMETHING
   that worked.  It's not always the best solution, but it worked.  That leaves plenty of room for you to
   improve on it. Please do, and please remember to share your improvements with everyone else.

 - After working with a number of microcontrollers, on a very irregular schedule, for a few years, there was
   one thing I badly needed to learn about the programming that other people talked about a little bit, but
   not enough for it to stick with me.  That is that this is object-oriented programming.  I was very
   familiar with it in other programming scenarios, but for some reason it just didn't hit home with me at
   first in relation to these microcontrollers.  And, if anyone actually explained it to me with examples in
   any literature I read, again, it just didn't make much of an impression.  So, I finally GOT IT, on my own.
   When you stick in the name of a Propeller spin program in the "OBJ" section below (as I did with TV), you
   have at your disposal ALL of the "PUB" methods that are in that added object.  You can call them up and
   pass them the variables they need, and they will do things for you.  Here's an example from my program below:

      sdfat.pwrite(@NMEA_STR,strsize(@NMEA_STR))

   When I started trying to figure out how to grab a string of data out of a buffer (variable) and send it to
   my SD Card, I didn't have an actual example that I could copy from where someone else had done that.  So, I
   opened up the fsrw.sping program an went looking through all its PUB methods to find one that sounded like
   it would do what I want.  Then I experimented with it until I got it to do what I wanted.  It's description
   didn't give me all the details a rank newcomer like me really needed, so I fed it bad information on the
   first few tries.  Guess what, nothing exploded, nothing was harmed, so I just kept hammering away until I
   found what I needed.  I doubt it is the best, cleanest, most efficient way to do it, but it worked.  That
   bit of early success gave me confidence that I could figure out how to use other objects that folks a lot
   smarter than me had shared with us.  And, for the most part, I've also found out that those smart folks
   are glad to answer a question or two for you if you just can't figure something out on your own. Asking,
   and getting help are far better than giving up and learning nothing.
   
 - Last, everybody tells you to comment everything you write in programming.  It seems a waste of time to
   the intelligent folks that know what they are doing.  But for us "newbies" they are a treasure.  The more
   of them the better.  Nobody appreciates you going overboard on comments more than someone who's really
   struggling to learn how to do something new.  So, if you write and share a new object, do go overboard
   with your comments.  Explain it all!  Somebody will appreciate it.
}}

CON
  _clkmode = xtal1 + pll16x                             ' Set up the clock frequencies
  _xinfreq = 5_000_000

            ' Prop Chip Hookup: 
  D0  = 0   ' Connect to Pin 0                          ' I've set these pins to match the SD card holder connections
  CLK = 1   ' Connect to Pin 1                          ' These are the correct pin numbers for my SD Card holder
  DI  = 2   ' Connect to Pin 2                          ' In addition, connect the first pin (VDD) to +3.3 Volts, and
  CS  = 3   ' Connect to Pin 3                          ' connect the second pin (VSS) to ground.
                                                        ' My card holder has 6 pins (the 4 data lines, and 2 power lines.)
                                                        ' I got it from uController.com and it works very well.
                                                                             
{{ CONNECTING THE HARDWARE:

(1)  Connections to the SD Card holder from uController.com are simple:                                                       

   SD Card     PROPELLER (Professional Development Board)
     ───┐      ┌───
  P3    │─────│ P3
  P2    │─────│ P2
  P1    │─────│ P1
  P0    │─────│ P0
  VSS   │─────│ GND
  VDD   │─────│ +3.3 Volts
     ───┘      └───
                                                        
                                                        
(2) The Parallax GPS Unit's hookup is also very simple:
      - It has a 'GND' pin that must be connected to ground,
      - A 'VCC' pin that must be connected to +5V,
      - A 'SIO' pin that must be connected to Pin 31 of the Propeller chip for data,
      - And a '/RAW' pin that is usually connected to ground. (I haven't yet used it in any other way.)

     GPS       PROPELLER (Professional Development Board)
     ───┐      ┌───  
  GND   │─────│ GND
  VCC   │─────│ +5 Volts
  SIO   │─────│ Pin 31
 /RAW   │─────│ GND
     ───┘      └─── 

(3) Here are the connections for the Parallax TV Monitor using the Professional Development Boards TV connections header:
    The Professional Development Board has the resistors in place, but you must connect the header to the Propeller chip.
    If you are making your own resistor network, just use the values shown below for each pin on the Propeller.
 
  TV Hdr       PROPELLER (Professional Development Board)
     ───┐      ┌───  
  V0    │─────│ Pin 12  1.1K Ohm - This one connects to the 1.1K Ohm resistor
  V1    │─────│ Pin 13  560 Ohm  - This one to the 560 Ohm resistor
  V2    │─────│ Pin 14  270 Ohm  - And this one to the 270 Ohm resistor
     ───┘      └─── 

}}
      
VAR
  long NMEA_STR[20]                                     ' Buffer of 20 longs to hold each NMEA sentence.
   
OBJ
  sdfat : "fsrw"
  pst   : "Parallax Serial Terminal"
  TV    : "TV_Terminal"

PUB demo | mount, data
  
  'Start the required code to communicate with the Parallax Serial Terminal.
  'Wait about 8 seconds for the user to launch PST and press the Enable button.  Change the time if you need to.

  pst.Start(4800)                       ' Starts the Parallax Serial Terminal at 4800 baud to communicate with GPS module
                                        ' Most GPS units communicate at 4800 baud, yours could be different.

  TV.Start(12)                          'Start TV Terminal
                                          
  waitcnt(clkfreq*8 + cnt)              ' Increase/decrease the 8 if more/less time is required.
                                        ' If you leave this at 8, don't get in a hurry - be prepared to wait several seconds for data to appear in Terminal.

                                        
  'Now, attempt to mount the SD card.
  'Report a failure to mount if the card is not found.
  'Halt if the card fails to mount. (Happens if you fail to put the card in the holder, make wrong connections, leave Pin 31 connected during loads, etc.)

  mount := \sdfat.mount_explicit(D0, CLK, DI, CS)
  if mount < 0
    pst.str(string(13, "SD card failed to mount.", 13))    'Send message to Serial Terminal
    TV.Str(string("SD card failed to mount"))              'Send message to TV Terminal
    TV.Out(13)
    abort
        
  'Report a message that the card was found and mounted.  This is first thing you want to see in the Terminal window.
  pst.str(string(13, "SD card was found and mounted.", 13))
  TV.Str(string("SD card was found and mounted."))        'Send message to TV Terminal
  TV.Out(13)

  waitcnt(clkfreq*8 + cnt)  ' Wait a few more seconds...I put this in to give me time to watch the Terminal while developing this program.
                            ' Once you've gotten the hang of running it, you may want to reduce or eliminate this delay. (Or, comment it out.)


  'Here's the main loop that runs to read each NMEA sentence in via the serial terminal, print it to the terminal, and the write it to the SD Card.
  'I put a limit of 20 times on the loop while I was debugging it.  You can change or eliminate this limit if you wish to allow the program to run
  'longer.  I wanted to put a definite limit on it since I wanted to be sure that the SD Card file was actually closed, and the card dismounted
  'cleanly at the end of my testing sessions.  If you decide to eliminate the '20' limit altogether, be sure to check and see what is happening to
  'your file saved on the SD Card (Is it closing and saving correctly, etc?).  If you aren't satisfied with the result, try coming back here and
  'just adding a large limit at this point.  If you want to branch out even more, try limiting the types of messages and how frequently they are
  'written out to the SD Card.  For example, while moving around with your GPS, you may only want to store a position reading every minute. This
  'would cut down on the number of lines written to the card, and a repeat limit of 600, using one line per minute, would allow you to save a position
  'every minute for 10 hours.

  'Other potential improvements in this section could include moving the sdfat.popen and sdfat.pclose statements outside the repeat loop.  This may
  'make the whole repeat loop more efficient.
  sdfat.popen(string("NMEA.txt"), "a")                  'Open the SD Card file to append data.  

  repeat 20                                             'Loop through 20 times and then quit.  Change this if you want more than 20 lines.
    pst.StrInMax(@NMEA_STR, 200)                        'Receive NMEA sentences from the GPS, up to a maximum of 100 bytes.
    pst.Str(@NMEA_STR)                                  'Print the NMEA sentence to the Parallax Serial Terminal window.
    pst.Str(string(13))                                 'Print a carriage return to the Terminal, in preparation for your next NMEA sentence.
    sdfat.pwrite(@NMEA_STR,strsize(@NMEA_STR))          'Write the NMEA sentence out to the SD Card, up to a length of 'strsize' bytes.
    sdfat.pputc(13)                                     'Add a carriage return.
    TV.Str(@NMEA_STR)                                   'And...print it on the TV terminal.
    TV.Out(13)                                          'Then, print a carriage return on the TV

  sdfat.pclose                                          'Close the file on the SD Card.  

    
  'Display a friendly notification that the file was written.
  pst.str(string(13,"Data written to:  NMEA.txt", 13))
  TV.Str(string("Data written to:  NMEA.txt"))              'Send message to TV Terminal
      
  'Unmount the card and end program.
  sdfat.unmount

'-----------------------------------------------------------------------------
'I hope I also got this license included in the right way and the right place.
'Thanks,
'Greg Denson
  
{{
                            TERMS OF USE: MIT License

 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:

 The above copyright notice and this permission notice shall be included in
 all copies or substantial portions of the Software.

 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 THE SOFTWARE.
}}       
  