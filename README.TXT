     Oh well, might as well write a text file on this since I'd be explaining 
this to more than one person sooner or later.  Here goes -


                     Writing (Graphic) VGA Intros/Loaders
                                     By
                                Fred Nietzche
                                  07/30/91


     I'm assuming that you don't understand the concept of video memory, so 
I'll start off from the basics then.  Video memory is defined (for our own 
purposes) as the memory that the video board scans in determining what signals
(analog) to send to the monitor.  In graphics mode, the segment of the location
of this is determined by what type of video mode you are on -
VGA/EGA modes = $A000 ($=hex), CGA modes = $B800, and Herc = $B000.  The
offsets always start off at $0.

     Now, what type of organization are the pixels (since we're in graphics 
mode) stored in?  Because of the simplicity of Mode $13 (320x200x256), most
VGA intros are written using this.  I'm not about to go ahead and explain to
you the other VGA modes dealing in the color planes, EGA/VGA registers,etc in
the higher resolution modes, there are a couple of good books out there that
can handle those of you interested in that.  Try your local bookstores and look 
for Power Graphics Programming by Michael Abrash, which contains his articles 
about higher resolution VGA programming from Programmer's Journal.  HIGHLY 
recommendable.  In any case, in this mode, each pixel on the screen 
corresponds to exactly 1 byte on the video memory.  For example, location
(0,0) = Mem[$A000:0], (1,0) = Mem[$A000:1], (2,0) = Mem[A000:2], and so on.
Fairly easy eh?  Because the memory map is linear, the next line would just be
the next byte AFTER the previous line's last pixel.  For example, location
(0,319) = Mem[$A000:319], AND THEN location (1,0) = Mem[$A000:320].  And the 
formula for determining the video memory location is

     Video Mem Offset = YPos*320 + XPos

     The actual color of the byte values stored in the video memory is
flexible and can be changed to any color of the 256,000 palette of the VGA.
This can be accomplished by altering the VGA Video DAC registers at port
addresses $3C6 through $3C9.  To read the current settings, set the Table
Read Index (port $3C7) to the color value you want, and then read the three
values from the Table Data Register (port $3C9) (one each for Red, Green, and
Blue).  Once three values have been read from that port, the current read
index is incremented by one and the next three 6 bit (range of 2^6, or 0 to 63)
values read are for the next color value.  Writing the to the Video DAC is
similar, except the Table Write Index is port $3C8.  Again, after writing
three successive 6 bit values to the Table Data Registers increments the Write
Index by one.  By the way, all the reference information about the Video DAC's
can be obtained from any EGA/VGA reference book.  I recommend getting
Advanced Programmer's Guide to the EGA/VGA by George Sutty and Steve Blair.

     Waiting for the vertical retrace start signal before updating the video
memory is the key to smooth animation (with a quick memory update too of
course).  The idea is to have the screen changes "pop up" before your eyes, and
to do this, you need to make your changes just before the the screen trace
of the video memory occurs.  For this reason, updating the video memory had
better fast enough, and generally this is the part done in assembly.  The
important port and bit locations, and a sample implementation are as follows:

       In Pascal:

         Repeat Until (Port[$3DA] And $08) = 0;
         Repeat Until (Port[$3DA] And $08) <> 0;

       And in Assembly:

                   MOV   DX,3DAh
         Wait:     IN    AL,DX
                   TEST  AL,08h
                   JZ    Wait
         Retr:     IN    AL,DX
                   TEST  AL,08h
                   JNZ   Retr


     And finally, how to get the characters on the screen.  I used the old
character set that's stored in BIOS because it saves time and space (instead
of capturing a graphical message).  The memory address for this is
$F000:$FA6E.  Because the character set is 8 bits by 8 bits, each character
takes up 8 bytes, each byte representing a horizontal slice of the character.
It's really not that confusing after fiddling around with it.

     There's also the special effect that palette cycling can do.  For
example, the color bars seen on Amiga and ST programs, although on the IBM,
it's more laborous.  What you do is simply fill each and every horizontal line
along the width of the movement of the bars with a separate color value.
Then blank out (with whatever color you desire) all of those values using the
DAC registers.  To move the bars, just change the color of the values that
need to be blanked out and the ones that need to be "filled in" with the bar
colors (again, through the DAC registers).  That's about it.  You may want to
make the movement of the bars in some pattern, like in the motion of a sine
function for effects.

     Another neat idea that palette cycling can accomplish is a shifting
checkerboard.  This one is a little bit more difficult, and I'll let you go
and figure it out on your own.

     That's all there is to it in terms of the basics and effects.  I wrote
for myself a screen capturing TSR (very crude, but what it does is dump the
video memory and palette to a file, and that's all I need.  I couldn't find
any PD programs which stored their captured screens in this format,
surprisingly!) to add painted pictures to the loaders, so that may be
something you might want to pursue for yourself.  Compress the executable
you've just created and you're done.

     Oh, I've included some sample intros (of my own board) with the ZIP.
I haven't really optimized them fully, but they'll do.  And the TDT/TRSI logo
was captured from one of their loaders.  I've got to admit, they've got some
nice artists working over there.

     About a good five minutes of reading eh?  Hope it was some help...


No greets, just trying to advertise my board around more..  Give it a ring.
CenterPoint! BBS (301) 309-0144, 9600+ only, Sysop - Fred Nietzche.

