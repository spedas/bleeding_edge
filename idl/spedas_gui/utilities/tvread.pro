;+
; NAME:
;       TVREAD
;
; PURPOSE:
;
;       To get accurate screen dumps with the IDL command TVRD on 24-bit
;       PC and Macintosh computers, you have to be sure to set color
;       decomposition on. This program adds that capability automatically.
;       In addition, the program will optionally write BMP, GIF, JPEG,
;       PICT, PNG, and TIFF color image files of the screen dump.
;
; AUTHOR:
;
;       FANNING SOFTWARE CONSULTING
;       David Fanning, Ph.D.
;       1645 Sheely Drive
;       Fort Collins, CO 80526 USA
;       Phone: 970-221-0438
;       E-mail: davidf@dfanning.com
;       Coyote's Guide to IDL Programming: http://www.dfanning.com
;
; CATEGORY:
;
;       Graphics
;
; CALLING SEQUENCE:
;
;       image = TVREAD(xstart, ystart, ncols, nrows)
;
;       The returned image will be a 2D image on 8-bit systems and
;       a 24-bit pixel interleaved true-color image on 24-bit systems.
;       A -1 will be returned if a file output keyword is used (e.g., JPEG, TIFF, etc.).
;
; OPTIONAL INPUTS:
;
;       XSTART -- The starting column index.  By default, 0.
;
;       YSTART -- The starting row index. By default, 0.
;
;       NCOLS -- The number of columns to read. By default, !D.X_Size - XSTART
;
;       NROWS -- The number of rows to read. By default, !D.Y_Size - YSTART.
;
; KEYWORD PARAMETERS:
;
;       BMP -- Set this keyword to write the screen dump as a color BMP file.
;
;       CANCEL -- An output keyword set to 1 if the user cancels out of a
;          filename dialog. Set to 0 otherwise.
;
;       COLORS -- If a 24-bit image has to be quantized, this will set the number
;          of colors in the output image. Set to 256 by default. Applies to BMP,
;          GIF, PICT, and PNG formats written from 24-bit displays.(See the
;          COLOR_QUAN documentation for details.)
;
;       CUBE -- If this keyword is set to a value between 2 and 6 the color
;          quantization will use a cubic method of quantization. Applies to BMP,
;          GIF, PICT, and PNG formats written from 24-bit displays.(See the
;          COLOR_QUAN documentation for details.)
;
;       DITHER -- If this keyword is set the quantized image will be dithered.
;          Applies to BMP, GIF, PICT, and PNG formats written from 24-bit displays.
;          (See the COLOR_QUAN documentation for details.)
;
;       FILENAME -- The base name of the output file. (No file extensions;
;           they will be added automatically.) This name may be changed by the user.
;
;              image = TVREAD(Filename='myfile', /JPEG)
;
;           No file will be written unless a file output keyword is used
;           (e.g., JPEG, TIFF, etc.) in the call. By default the FILENAME is
;           set to "idl". The file extension will be set automatically to match
;           the type of file created.
;
;       GIF -- Set this keyword to write the screen dump as a color GIF file.
;
;       JPEG -- Set this keyword to write the screen dump as a color JPEG file.
;
;       NODIALOG -- Set this keyword if you wish to avoid the DIALOG_PICKFILE
;           dialog that asks you to name the output file. This keyword should be
;           set, for example, if you are processing screens in batch mode.
;
;       ORDER -- Set this keyword to determine the image order for reading the
;           display. Corresponds to !Order and set to such as the default.
;
;       PICT -- Set this keyword to write the screen dump as a color PICT file.
;
;       PNG -- Set this keyword to write the screen dump as a color PNG file.
;
;       TIFF -- Set this keyword to write the screen dump as a color TIFF file.
;
;       TRUE -- Set this keyword to the type of interleaving you want. 1 = Pixel
;           interleaved, 2 = row interleaved, 3 = band interleaved.
;
;       QUALITY -- This keyword sets the amount of compression for JPEG images.
;           It should be set to a value between 0 and 100. It is set to 75 by default.
;           (See the WRITE_JPEG documentation for details.)
;
;       WID -- The index number of the window to read from. The current graphics window
;           (!D.Window) is selected by default. An error is issued if no windows are
;           currently open on a device that supports windows.
;
;       _EXTRA -- Any keywords that are appropriate for the WRITE_*** routines are
;           also accepted via keyword inheritance.
;
; COMMON BLOCKS:
;
;       None
;
; RESTRICTIONS:   Requires IDL 5.2 and higher.
;
; MODIFICATION HISTORY:
;
;       Written by David W. Fanning, 9 AUG 2000.
;       Added changes to make the program more device independent. 16 SEP 2000. DWF.
;       Removed GIF file support for IDL 5.4 and above. 18 JAN 2001. DWF.
;       Added NODIALOG keyword. 28 MAR 2001. DWF.
;       Added an output CANCEL keyword. 29 AUG 2001. DWF.
;       Added ERROR_MESSAGE code to file. 17 DEC 2001. DWF.
;       Added ORDER keyword. 25 March 2002. DWF.
;       Now create 24-bit PNG files if reading from a 24-bit display. 11 May 2002. DWF.
;       Now create 24-bit BMP files if reading from a 24-bit display. 23 May 2002. DWF.
;       Removed obsolete STR_SEP and replaced with STRSPLIT. 27 Oct 2004. DWF.
;-
;
;###########################################################################
;
; LICENSE
;
; This software is OSI Certified Open Source Software.
; OSI Certified is a certification mark of the Open Source Initiative.
;
; Copyright � 2000-2002 Fanning Software Consulting.
;
; This software is provided "as-is", without any express or
; implied warranty. In no event will the authors be held liable
; for any damages arising from the use of this software.
;
; Permission is granted to anyone to use this software for any
; purpose, including commercial applications, and to alter it and
; redistribute it freely, subject to the following restrictions:
;
; 1. The origin of this software must not be misrepresented; you must
;    not claim you wrote the original software. If you use this software
;    in a product, an acknowledgment in the product documentation
;    would be appreciated, but is not required.
;
; 2. Altered source versions must be plainly marked as such, and must
;    not be misrepresented as being the original software.
;
; 3. This notice may not be removed or altered from any source distribution.
;
; For more information on Open Source Software, visit the Open Source
; web site: http://www.opensource.org.
;
;###########################################################################


FUNCTION TVREAD_ERROR_MESSAGE, theMessage, Traceback=traceback, $
   NoName=noName, _Extra=extra

On_Error, 2

   ; Check for presence and type of message.

IF N_Elements(theMessage) EQ 0 THEN theMessage = !Error_State.Msg
s = Size(theMessage)
messageType = s[s[0]+1]
IF messageType NE 7 THEN BEGIN
   Message, "The message parameter must be a string.", _Extra=extra
ENDIF

   ; Get the call stack and the calling routine's name.

Help, Calls=callStack
callingRoutine = (StrSplit(StrCompress(callStack[1])," ", /Extract))[0]

   ; Are widgets supported? Doesn't matter in IDL 5.3 and higher.

widgetsSupported = ((!D.Flags AND 65536L) NE 0) OR Float(!Version.Release) GE 5.3
IF widgetsSupported THEN BEGIN
   IF Keyword_Set(noName) THEN answer = Dialog_Message(theMessage, _Extra=extra) ELSE BEGIN
      IF StrUpCase(callingRoutine) EQ "$MAIN$" THEN answer = Dialog_Message(theMessage, _Extra=extra) ELSE $
         answer = Dialog_Message(StrUpCase(callingRoutine) + ": " + theMessage, _Extra=extra)
   ENDELSE
ENDIF ELSE BEGIN
      Message, theMessage, /Continue, /NoPrint, /NoName, /NoPrefix, _Extra=extra
      Print, '%' + callingRoutine + ': ' + theMessage
      answer = 'OK'
ENDELSE

   ; Provide traceback information if requested.

IF Keyword_Set(traceback) THEN BEGIN
   Help, /Last_Message, Output=traceback
   Print,''
   Print, 'Traceback Report from ' + StrUpCase(callingRoutine) + ':'
   Print, ''
   FOR j=0,N_Elements(traceback)-1 DO Print, "     " + traceback[j]
ENDIF

RETURN, answer
END ; ----------------------------------------------------------------------------


FUNCTION TVREAD, xstart, ystart, ncols, nrows, $
   BMP=bmp, $
   Cancel=cancel, $
   Colors=colors, $
   Cube=cube, $
   Dither=dither, $
   _Extra=extra, $
   Filename=filename, $
   GIF=gif, $
   JPEG=jpeg, $
   NoDialog=nodialog, $
   Order=order, $
   PICT=pict, $
   PNG=png, $
   TIFF=tiff, $
   True=true, $
   Quality=quality, $
   WID=wid

   ; Error handling.

Catch, theError
IF theError NE 0 THEN BEGIN
   Catch, /Cancel
   ok = TVRead_Error_Message(Traceback=1, /Error)
   IF N_Elements(thisWindow) EQ 0 THEN RETURN, -1
   IF thisWindow GE 0 THEN WSet, thisWindow
   RETURN, -1
ENDIF

cancel = 0

   ; Check for availability of GIF files.

thisVersion = Float(!Version.Release)
IF thisVersion LT 5.3 THEN haveGif = 1 ELSE haveGIF = 0

   ; Go to correct window.

IF N_Elements(wid) EQ 0 THEN wid =!D.Window
thisWindow = !D.Window
IF (!D.Flags AND 256) NE 0 THEN WSet, wid

   ; Check keywords and parameters. Define values if necessary.

IF N_Elements(xstart) EQ 0 THEN xstart = 0
IF N_Elements(ystart) EQ 0 THEN ystart = 0
IF N_Elements(ncols) EQ 0 THEN ncols = !D.X_Size - xstart
IF N_Elements(nrows) EQ 0 THEN nrows = !D.Y_Size - ystart
IF N_Elements(order) EQ 0 THEN order = !Order
IF N_Elements(true) EQ 0 THEN true = 1
dialog = 1 - Keyword_Set(nodialog)

   ; Do you want to write an image file instead of
   ; capturing an image?

writeImage = 0
fileType = ""
extention = ""
IF Keyword_Set(bmp) THEN BEGIN
   writeImage = 1
   fileType = 'BMP'
   extension = 'bmp'
ENDIF
IF Keyword_Set(gif) THEN BEGIN
   IF havegif THEN BEGIN
      writeImage = 1
      fileType = 'GIF'
      extension = 'gif'
    ENDIF ELSE BEGIN
       ok = Dialog_Message('GIF files not supported in this IDL version. Replacing with JPEG.')
       writeImage = 1
      fileType = 'JPEG'
      extension = 'jpg'
   ENDELSE
ENDIF
IF Keyword_Set(jpeg) THEN BEGIN
   writeImage = 1
   fileType = 'JPEG'
   extension = 'jpg'
ENDIF
IF Keyword_Set(PICT) THEN BEGIN
   writeImage = 1
   fileType = 'PICT'
   extension = 'pict'
ENDIF
IF Keyword_Set(png) THEN BEGIN
   writeImage = 1
   fileType = 'PNG'
   extension = 'png'
ENDIF
IF Keyword_Set(tiff) THEN BEGIN
   writeImage = 1
   fileType = 'TIFF'
   extension = 'tif'
ENDIF

IF N_Elements(colors) EQ 0 THEN colors = 256
IF N_Elements(quality) EQ 0 THEN quality = 75
dither = Keyword_Set(dither)

   ; On 24-bit displays, make sure color decomposition is ON.

IF (!D.Flags AND 256) NE 0 THEN BEGIN
   Device, Get_Decomposed=theDecomposedState, Get_Visual_Depth=theDepth
   IF theDepth GT 8 THEN BEGIN
      Device, Decomposed=1
      truecolor = true
   ENDIF ELSE truecolor = 0
   IF thisWindow LT 0 THEN $
      Message, 'No currently open windows. Returning.', /NoName
ENDIF ELSE BEGIN
   truecolor = 0
   theDepth = 8
ENDELSE

   ; Get the screen dump. 2D image on 8-bit displays. 3D image on 24-bit displays.

image = TVRD(xstart, ystart, ncols, nrows, True=truecolor, Order=order)

   ; Need to set color decomposition back?

IF theDepth GT 8 THEN Device, Decomposed=theDecomposedState

   ; If we need to write an image, do it here.

IF writeImage THEN BEGIN

      ; Get the name of the output file.

   IF N_Elements(filename) EQ 0 THEN BEGIN
      filename = 'idl.' + StrLowCase(extension)
   ENDIF ELSE BEGIN
      filename = filename + "." + StrLowCase(extension)
   ENDELSE
   IF dialog THEN filename = Dialog_Pickfile(/Write, File=filename)

   IF filename EQ "" THEN BEGIN
      cancel = 1
      RETURN, image
   ENDIF

      ; Write the file.

   CASE fileType OF

      'BMP': BEGIN
         IF truecolor THEN BEGIN
            ; BMP files assume blue, green, red planes.
            temp = image[0,*,*]
            image[0,*,*] = image[2,*,*]
            image[2,*,*] = temp
            Write_BMP, filename, image, _Extra=extra
         ENDIF ELSE BEGIN
            TVLCT, r, g, b, /Get
            Write_BMP, filename, image, r, g, b, _Extra=extra
         ENDELSE
         END

      'GIF': BEGIN
         IF truecolor THEN BEGIN
            CASE Keyword_Set(cube) OF
               0: image2D = Color_Quan(image, 1, r, g, b, Colors=colors, Dither=dither)
               1: image2D = Color_Quan(image, 1, r, g, b, Cube=2 > cube < 6)
            ENDCASE
         ENDIF ELSE BEGIN
            TVLCT, r, g, b, /Get
            image2D = image
         ENDELSE
         Write_GIF, filename, image2D, r, g, b, _Extra=extra
         END

      'JPEG': BEGIN
         IF truecolor THEN BEGIN
            image3D = image
         ENDIF ELSE BEGIN
            s = Size(image, /Dimensions)
            image3D = BytArr(3, s[0], s[1])
            TVLCT, r, g, b, /Get
            image3D[0,*,*] = r[image]
            image3D[1,*,*] = g[image]
            image3D[2,*,*] = b[image]
         ENDELSE
         Write_JPEG, filename, image3D, True=1, Quality=quality, _Extra=extra
         END

      'PICT': BEGIN
         IF truecolor THEN BEGIN
            CASE Keyword_Set(cube) OF
               0: image2D = Color_Quan(image, 1, r, g, b, Colors=colors, Dither=dither)
               1: image2D = Color_Quan(image, 1, r, g, b, Cube=2 > cube < 6)
            ENDCASE
         ENDIF ELSE BEGIN
            TVLCT, r, g, b, /Get
            image2D = image
         ENDELSE
         Write_PICT, filename, image2D, r, g, b
         END

      'PNG': BEGIN
         IF truecolor THEN BEGIN
            Write_PNG, filename, image, _Extra=extra
         ENDIF ELSE BEGIN
            TVLCT, r, g, b, /Get
            image2D = image
            Write_PNG, filename, Reverse(image2D,2), r, g, b, _Extra=extra
         ENDELSE
         END

      'TIFF': BEGIN
         IF truecolor THEN BEGIN
            image3D = Reverse(image,3)
         ENDIF ELSE BEGIN
            s = Size(image, /Dimensions)
            image3D = BytArr(3, s[0], s[1])
            TVLCT, r, g, b, /Get
            image3D[0,*,*] = r[image]
            image3D[1,*,*] = g[image]
            image3D[2,*,*] = b[image]
            image3D = Reverse(Temporary(image3D), 3)
         ENDELSE
         Write_TIFF, filename, image3D, 1, _Extra=extra
         END
   ENDCASE
   RETURN, -1
ENDIF

   ; Return the screen dump image.

RETURN, image
END ;-------------------------------------------------------------------------------
