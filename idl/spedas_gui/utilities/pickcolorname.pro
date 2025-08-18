;+
; NAME:
;       PICKCOLORNAME
;
; PURPOSE:
;
;       The purpose of this program is to provide a blocking
;       or modal widget interface for selecting a color "name".
;       The program uses colors familiar to the FSC_COLOR program,
;       and is often used to select a color name for passing to FSC_COLOR.
;
; AUTHOR:
;
;       FANNING SOFTWARE CONSULTING:
;       David Fanning, Ph.D.
;       1645 Sheely Drive
;       Fort Collins, CO 80526 USA
;       Phone: 970-221-0438
;       E-mail: davidf@dfanning.com
;       Coyote's Guide to IDL Programming: http://www.dfanning.com
;
; CATEGORY:
;
;       Graphics, Color Specification.
;
; CALLING SEQUENCE:
;
;       colorName = PickColorName(startColorName)
;
; OPTIONAL INPUT PARAMETERS:
;
;       startColorName: A string with the "name" of the color. Colors available are these:
;
;                Almond   Antique White      Aquamarine           Beige          Bisque           Black
;                  Blue     Blue Violet           Brown       Burlywood        Charcoal      Chartreuse
;             Chocolate           Coral        Cornsilk            Cyan  Dark Goldenrod       Dark Gray
;            Dark Green      Dark Khaki     Dark Orchid     Dark Salmon       Deep Pink     Dodger Blue
;             Firebrick    Forest Green            Gold       Goldenrod            Gray           Green
;          Green Yellow        Honeydew        Hot Pink      Indian Red           Ivory           Khaki
;              Lavender      Lawn Green     Light Coral      Light Cyan      Light Gray    Light Salmon
;          Light Yellow      Lime Green           Linen         Magenta          Maroon     Medium Gray
;         Medium Orchid        Moccasin            Navy           Olive      Olive Drab          Orange
;            Orange Red          Orchid  Pale Goldenrod      Pale Green          Papaya            Peru
;                  Pink            Plum     Powder Blue          Purple             Red            Rose
;            Rosy Brown      Royal Blue    Saddle Brown          Salmon     Sandy Brown       Sea Green
;              Seashell          Sienna        Sky Blue      Slate Gray            Snow    Spring Green
;            Steel Blue             Tan         Thistle          Tomato       Turquoise          Violet
;            Violet Red           Wheat           White          Yellow
;
;
;       The color WHITE is used if this parameter is absent.
;
; INPUT KEYWORD PARAMETERS:
;
;       BOTTOM: The colors used in the program must be loaded somewhere
;           in the color table. This keyword indicates where the colors
;           start loading. By default BOTTOM is set equal to !D.Table_Size-NCOLORS-1.
;
;       COLUMNS: Set this keyword to the number of columns the colors should
;           be arranged in.
;
;       FILENAME: The string name of an ASCII file that can be opened to read in
;           color values and color names. There should be one color per row
;           in the file. Please be sure there are no blank lines in the file.
;           The format of each row should be:
;
;              redValue  greenValue  blueValue  colorName
;
;           Color values should be between 0 and 255. Any kind of white-space
;           separation (blank characters, commas, or tabs) are allowed. The color
;           name should be a string, but it should NOT be in quotes. A typical
;           entry into the file would look like this:
;
;               255   255   0   Yellow
;
;       GROUP_LEADER: This identifies a group leader if the program is called
;           from within a widget program. Note that this keyword MUST be provided
;           if you want to guarantee modal widget functionality. (If you don't know
;           what this means, believe me, you WANT to use this keyword, always.)
;
;       INDEX: This keyword identifies a color table index where the selected color
;           is to be loaded when the program exits. The default behavior is to restore
;           the input color table and NOT load a color.
;
;       TITLE: This keyword accepts a string value for the window title. The default
;           is "Select a Color".
;
; OUTPUT KEYWORD PARAMETERS:
;
;       CANCEL: On exit, this keyword value is set to 0 if the user selected
;           the ACCEPT button. IF the user selected the CANCEL button, or
;           closed the window in any other way, this keyword value is set to 1.

; COMMON BLOCKS:
;
;       None.
;
; SIDE EFFECTS:
;
;       Colors are loaded in the current color table. The input color table
;       is restored when the program exits. This will only be noticable on
;       8-bit displays. The startColorName is returned if the user cancels
;       or destroys the widget before a selection is made. Users should
;       check the CANCEL flag before using the returned color.
;
; EXAMPLE:
;
;       To call the program from the IDL comamnd line:
;
;         IDL> color = PickColorName("red") & Print, color
;
;       To call the program from within a widget program:
;
;         color = PickColorName("red", Group_Leader=event.top) & Print, color
;
; MODIFICATION HISTORY:
;
;       Written by: David Fanning, 31 August 2000.
;       Modified program to read colors from a file and to use more
;         colors on 24-bit platforms. 16 October 2000. DWF.
;       Added the COLUMNS keyword. 16 October 2000. DWF.
;       Fixed a small problem with mapping a modal widget. 2 Jan 2001. DWF
;       Now drawing small box around each color. 13 March 2003. DWF.
;-
;
;###########################################################################
;
; LICENSE
;
; This software is OSI Certified Open Source Software.
; OSI Certified is a certification mark of the Open Source Initiative.
;
; Copyright © 2000-2003 Fanning Software Consulting.
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


PRO PickColorName_CenterTLB, tlb

; Center the top-level base widget.

screenSize = Get_Screen_Size()
xCenter = screenSize(0) / 2
yCenter = screenSize(1) / 2

geom = Widget_Info(tlb, /Geometry)
xHalfSize = geom.Scr_XSize / 2
yHalfSize = geom.Scr_YSize / 2

Widget_Control, tlb, XOffset = xCenter-xHalfSize, $
   YOffset = yCenter-yHalfSize

END ;-------------------------------------------------------------------------------



FUNCTION PickColorName_RGB_to_24Bit, number

; Convert RGB values to 24-bit number values.

IF Size(number, /N_Dimensions) EQ 1 THEN BEGIN
   RETURN, number[0] + (number[1] * 2L^8) + (number[2] * 2L^16)
ENDIF ELSE BEGIN
   RETURN, number[*,0] + (number[*,1] * 2L^8) + (number[*,2] * 2L^16)
ENDELSE
END ;-------------------------------------------------------------------------------



FUNCTION PickColorName_Count_Rows, filename, MaxRows = maxrows

; This utility routine is used to count the number of
; rows in an ASCII data file.

IF N_Elements(maxrows) EQ 0 THEN maxrows = 500L
IF N_Elements(filename) EQ 0 THEN BEGIN
   filename = Dialog_Pickfile()
   IF filename EQ "" THEN RETURN, -1
ENDIF

OpenR, lun, filename, /Get_Lun

Catch, error
IF error NE 0 THEN BEGIN
   count = count-1
   Free_Lun, lun
   RETURN, count
ENDIF

RESTART:

count = 1L
line = ''
FOR j=count, maxrows DO BEGIN
   ReadF, lun, line
   count = count + 1

      ; Try again if you hit MAXROWS without encountering the
      ; end of the file. Double the MAXROWS parameter.

   IF j EQ maxrows THEN BEGIN
      maxrows = maxrows * 2
      Point_Lun, lun, 0
      GOTO, RESTART
   ENDIF

ENDFOR

RETURN, -1
END ;-------------------------------------------------------------------------------



PRO PickColorName_Select_Color, event

; This event handler permits color selection by clicking on a color window.

IF event.type NE 0 THEN RETURN

Widget_Control, event.top, Get_UValue=info, /No_Copy

   ; Get the color names from the window you clicked on and set it.

Widget_Control, event.id, Get_UValue=thisColorName
Widget_Control, event.top, Update=0
Widget_Control, info.labelID, Set_Value=thisColorName
Widget_Control, event.top, Update=1

   ; Get the color value and load it as the current color.

WSet, info.mixWID
info.theName = thisColorName
theIndex = Where(info.colorNames EQ StrUpCase(StrCompress(thisColorName, /Remove_All)))
theIndex = theIndex[0]
info.nameIndex = theIndex

IF info.theDepth GT 8 THEN BEGIN
   PolyFill, [0,0,1,1,0], [0,1,1,0,0], /Normal, Color=info.colors24[theIndex]
ENDIF ELSE BEGIN
   TVLCT, info.red[theIndex], info.green[theIndex], info.blue[theIndex], info.mixcolorIndex
   PolyFill, [0,0,1,1,0], [0,1,1,0,0], /Normal, Color=info.mixcolorIndex
ENDELSE

Widget_Control, event.top, Set_UValue=info, /No_Copy
END ;---------------------------------------------------------------------------



PRO PickColorName_Buttons, event

; This event handler responds to CANCEL and ACCEPT buttons.

Widget_Control, event.top, Get_UValue=info, /No_Copy

   ; Which button is this?

Widget_Control, event.id, Get_Value=buttonValue

   ; Branch on button value.

CASE buttonValue OF

   'Cancel': BEGIN

         ; Simply destroy the widget. The pointer info is already
         ; set up for a CANCEL event.

      Widget_Control, event.top, /Destroy
      ENDCASE

   'Accept': BEGIN

         ; Get the new color table after the color has been selected.

      TVLCT, r, g, b, /Get

         ; Save the new color and name in the pointer.

      *(info.ptr) = {cancel:0.0, r:info.red[info.nameIndex], g:info.green[info.nameIndex], $
         b:info.blue[info.nameIndex], name:info.theName}

         ; Destoy the widget.

      Widget_Control, event.top, /Destroy

      ENDCASE
ENDCASE
END ;---------------------------------------------------------------------------



FUNCTION PickColorName, theName, $         ; The name of the starting color.
   Bottom=bottom, $                        ; The index number where the colors should be loaded.
   Cancel=cancelled, $                     ; An output keyword set to 1 if the user cancelled or an error occurred.
   Columns = ncols, $                      ; The number of columns to display the colors in.
   Filename=filename, $                    ; The name of the file which contains color names and values.
   Group_Leader=group_leader, $            ; The group leader of the TLB. Required for modal operation.
   Index=index, $                          ; The color index number where the final selected color should be loaded.
   Title=title                             ; The title of the top-level base widget.

   ; Error handling for this program module.

Catch, theError
IF theError NE 0 THEN BEGIN
   Catch, /Cancel
   ok = Error_Message(/Traceback)
   cancel = 1
   IF N_Elements(theName) NE 0 THEN RETURN, theName ELSE RETURN, 'White'
ENDIF

   ; Get depth of visual display.

IF (!D.Flags AND 256) NE 0 THEN Device, Get_Visual_Depth=theDepth ELSE theDepth = 8

   ; Is there a filename? If so, get colors from there.

IF N_Elements(filename) NE 0 THEN BEGIN

      ; Count the number of rows in the file.

   NCOLORS = PickColorName_Count_Rows(filename)

      ; Read the data.

   OpenR, lun, filename, /Get_Lun
   red = BytArr(NCOLORS)
   green = BytArr(NCOLORS)
   blue = BytArr(NCOLORS)
   colors = StrArr(NCOLORS)
   redvalue = 0B
   greenvalue = 0B
   bluevalue = 0B
   namevalue = ""
   FOR j=0L, NCOLORS-1 DO BEGIN
      ReadF, lun, redvalue, greenvalue, bluevalue, namevalue
      colors[j] = namevalue
      red[j] = redvalue
      green[j] = greenvalue
      blue[j] = bluevalue
   ENDFOR

      ; Trim the colors array of blank characters.

   colors = StrTrim(colors, 2)

      ; Calculate the number of columns to display colors in.

   IF N_Elements(ncols) EQ 0 THEN ncols = Fix(Sqrt(ncolors))
   Free_Lun, lun
ENDIF ELSE BEGIN

   IF theDepth GT 8 THEN BEGIN

      ; The colors with their names.

   NCOLORS = 88
   IF N_Elements(ncols) EQ 0 THEN ncols = 11
   colors= ['White']
   red =   [ 255]
   green = [ 255]
   blue =  [ 255]
   colors= [ colors,      'Snow',     'Ivory','Light Yellow',   'Cornsilk',      'Beige',   'Seashell' ]
   red =   [ red,            255,          255,          255,          255,          245,          255 ]
   green = [ green,          250,          255,          255,          248,          245,          245 ]
   blue =  [ blue,           250,          240,          224,          220,          220,          238 ]
   colors= [ colors,     'Linen','Antique White',    'Papaya',     'Almond',     'Bisque',  'Moccasin' ]
   red =   [ red,            250,          250,          255,          255,          255,          255 ]
   green = [ green,          240,          235,          239,          235,          228,          228 ]
   blue =  [ blue,           230,          215,          213,          205,          196,          181 ]
   colors= [ colors,     'Wheat',  'Burlywood',        'Tan', 'Light Gray',   'Lavender','Medium Gray' ]
   red =   [ red,            245,          222,          210,          230,          230,          210 ]
   green = [ green,          222,          184,          180,          230,          230,          210 ]
   blue =  [ blue,           179,          135,          140,          230,          250,          210 ]
   colors= [ colors,      'Gray', 'Slate Gray',  'Dark Gray',   'Charcoal',      'Black', 'Light Cyan' ]
   red =   [ red,            190,          112,          110,           70,            0,          224 ]
   green = [ green,          190,          128,          110,           70,            0,          255 ]
   blue =  [ blue,           190,          144,          110,           70,            0,          255 ]
   colors= [ colors,'Powder Blue',  'Sky Blue', 'Steel Blue','Dodger Blue', 'Royal Blue',       'Blue' ]
   red =   [ red,            176,          135,           70,           30,           65,            0 ]
   green = [ green,          224,          206,          130,          144,          105,            0 ]
   blue =  [ blue,           230,          235,          180,          255,          225,          255 ]
   colors= [ colors,      'Navy',   'Honeydew', 'Pale Green','Aquamarine','Spring Green',       'Cyan' ]
   red =   [ red,              0,          240,          152,          127,            0,            0 ]
   green = [ green,            0,          255,          251,          255,          250,          255 ]
   blue =  [ blue,           128,          240,          152,          212,          154,          255 ]
   colors= [ colors, 'Turquoise', 'Sea Green','Forest Green','Green Yellow','Chartreuse', 'Lawn Green' ]
   red =   [ red,             64,           46,           34,          173,          127,          124 ]
   green = [ green,          224,          139,          139,          255,          255,          252 ]
   blue =  [ blue,           208,           87,           34,           47,            0,            0 ]
   colors= [ colors,     'Green', 'Lime Green', 'Olive Drab',     'Olive','Dark Green','Pale Goldenrod']
   red =   [ red,              0,           50,          107,           85,            0,          238 ]
   green = [ green,          255,          205,          142,          107,          100,          232 ]
   blue =  [ blue,             0,           50,           35,           47,            0,          170 ]
   colors =[ colors,     'Khaki', 'Dark Khaki',     'Yellow',       'Gold','Goldenrod','Dark Goldenrod']
   red =   [ red,            240,          189,          255,          255,          218,          184 ]
   green = [ green,          230,          183,          255,          215,          165,          134 ]
   blue =  [ blue,           140,          107,            0,            0,           32,           11 ]
   colors= [ colors,'Saddle Brown',       'Rose',       'Pink', 'Rosy Brown','Sandy Brown',      'Peru']
   red =   [ red,            139,          255,          255,          188,          244,          205 ]
   green = [ green,           69,          228,          192,          143,          164,          133 ]
   blue =  [ blue,            19,          225,          203,          143,           96,           63 ]
   colors= [ colors,'Indian Red',  'Chocolate',     'Sienna','Dark Salmon',    'Salmon','Light Salmon' ]
   red =   [ red,            205,          210,          160,          233,          250,          255 ]
   green = [ green,           92,          105,           82,          150,          128,          160 ]
   blue =  [ blue,            92,           30,           45,          122,          114,          122 ]
   colors= [ colors,    'Orange',      'Coral', 'Light Coral',  'Firebrick',      'Brown',  'Hot Pink' ]
   red =   [ red,            255,          255,          240,          178,          165,          255 ]
   green = [ green,          165,          127,          128,           34,           42,          105 ]
   blue =  [ blue,             0,           80,          128,           34,           42,          180 ]
   colors= [ colors, 'Deep Pink',    'Magenta',     'Tomato', 'Orange Red',        'Red', 'Violet Red' ]
   red =   [ red,            255,          255,          255,          255,          255,          208 ]
   green = [ green,           20,            0,           99,           69,            0,           32 ]
   blue =  [ blue,           147,          255,           71,            0,            0,          144 ]
   colors= [ colors,    'Maroon',    'Thistle',       'Plum',     'Violet',    'Orchid','Medium Orchid']
   red =   [ red,            176,          216,          221,          238,          218,          186 ]
   green = [ green,           48,          191,          160,          130,          112,           85 ]
   blue =  [ blue,            96,          216,          221,          238,          214,          211 ]
   colors= [ colors,'Dark Orchid','Blue Violet',     'Purple']
   red =   [ red,            153,          138,          160 ]
   green = [ green,           50,           43,           32 ]
   blue =  [ blue,           204,          226,          240 ]

   ENDIF ELSE BEGIN

   NCOLORS = 16
   IF N_Elements(ncols) EQ 0 THEN ncols = 8
   colors  = ['Black', 'Magenta', 'Cyan', 'Yellow', 'Green']
   red =     [  0,        255,       0,      255,       0  ]
   green =   [  0,          0,     255,      255,     255  ]
   blue =    [  0,        255,     255,        0,       0  ]
   colors  = [colors,  'Red', 'Blue', 'Navy', 'Pink', 'Aqua']
   red =     [red,     255,     0,      0,    255,    112]
   green =   [green,     0,     0,      0,    127,    219]
   blue =    [blue,      0,   255,    115,    127,    147]
   colors  = [colors,  'Orchid', 'Sky', 'Beige', 'Charcoal', 'Gray','White']
   red =     [red,     219,      0,     245,       80,      135,    255  ]
   green =   [green,   112,    163,     245,       80,      135,    255  ]
   blue =    [blue,    219,    255,     220,       80,      135,    255  ]

   ENDELSE


ENDELSE

   ; Save decomposed state and restore it, if possible.

IF Float(!Version.Release) GE 5.2 THEN BEGIN
   Device, Get_Decomposed=decomposedState
ENDIF ELSE decomposedState = 0

   ; Different color decomposition based on visual depth.

IF theDepth GT 8 THEN BEGIN
   Device, Decomposed=1
   colors24 = PickColorName_RGB_to_24Bit([[red], [green], [blue]])
ENDIF ELSE BEGIN
   IF NCOLORS GT !D.Table_Size THEN $
      Message, /NoName, 'Number of colors exceeds color table size. Returning...'
   Device, Decomposed=0
   colors24 = -1
ENDELSE

   ; Check argument values. All arguments are optional.

IF N_Elements(theName) EQ 0 THEN theName = 'White'
IF Size(theName, /TName) NE 'STRING' THEN $
   Message, 'Color name argument must be STRING type.', /NoName
theName = StrCompress(theName, /Remove_All)

IF N_Elements(bottom) EQ 0 THEN bottom = 0 > (!D.Table_Size - (NCOLORS + 2))
mixcolorIndex = bottom
IF N_Elements(title) EQ 0 THEN title='Select a Color'

   ; We will work with all uppercase names.

colorNames = StrUpCase(StrCompress(colors, /Remove_All))

   ; Get the current color table vectors before we change anything.
   ; This will allow us to restore the color table when we depart.

TVLCT, r_old, g_old, b_old, /Get

   ; Load the colors if needed. The "bottom" index is reserved as the "mixing color" index.

IF theDepth LE 8 THEN TVLCT, red, green, blue, bottom+1

   ; Can you find the color name in the colors array?

nameIndex = WHERE(colorNames EQ StrUpCase(theName), count)
IF count EQ 0 THEN BEGIN
   Message, 'Unable to resolve color name: ' + StrUpCase(theName) + '. Replacing with WHITE.', /Informational
   theName = 'White'
   nameIndex = WHERE(colorNames EQ StrUpCase(theName), count)
   IF count EQ 0 THEN Message, /NoName, 'Unable to resolve color name: ' + StrUpCase(theName) + '. Returning...'
ENDIF
nameIndex = nameIndex[0]

   ; Who knows how the user spelled the color? Make it look nice.

theName = colors[nameIndex]

   ; Load the mixing color in the mixcolorIndex.

IF theDepth LE 8 THEN TVLCT, red[nameIndex], green[nameIndex], blue[nameIndex], mixcolorIndex

   ; Create the widgets. TLB is MODAL or BLOCKING, depending upon presence of
   ; Group_Leader variable.

IF N_Elements(group_leader) EQ 0 THEN BEGIN
   tlb = Widget_Base(Title=title, Column=1, /Base_Align_Center)
ENDIF ELSE BEGIN
   tlb = Widget_Base(Title=title, Column=1, /Base_Align_Center, /Modal, $
      Group_Leader=group_leader)
ENDELSE

   ; Draw widgets for the possible colors. Store the color name in the UVALUE.

colorbaseID = Widget_Base(tlb, Column=ncols, Event_Pro='PickColorName_Select_Color')
drawID = LonArr(NCOLORS)
FOR j=0,NCOLORS-1 DO BEGIN
   drawID[j] = Widget_Draw(colorbaseID, XSize=20, YSize=15, $
      UValue=colors[j], Button_Events=1)
ENDFOR

   ; Set up the current or mixing color draw widget.

currentID = Widget_Base(tlb, Column=1, Base_Align_Center=1)
labelID = Widget_Label(currentID, Value=theName, /Dynamic_Resize)
mixColorID = Widget_Draw(currentID, XSize=60, YSize=15)

   ; CANCEL and ACCEPT buttons.

buttonbase = Widget_Base(tlb, ROW=1, Align_Center=1, Event_Pro='PickColorName_Buttons')
cancelID = Widget_Button(buttonbase, VALUE='Cancel')
acceptID = Widget_Button(buttonbase, VALUE='Accept')

   ; Center the TLB.

PickColorName_CenterTLB, tlb
Widget_Control, tlb, /Realize

   ; Load the drawing colors.

wids = IntArr(NCOLORS)
IF theDepth GT 8 THEN BEGIN
   FOR j=0,NCOLORS-1 DO BEGIN
      Widget_Control, drawID[j], Get_Value=thisWID
      wids[j] = thisWID
      WSet, thisWID
      ;PolyFill, [0,0,1,1,0], [0,1,1,0,0], /Normal, Color=colors24[j]
      Erase, Color=colors24[j]
      black = Where(colornames EQ 'BLACK')
      black = black[0]
      PlotS, [0,0,19,19,0], [0,14,14,0,0], /Device, Color=colors24[black]
   ENDFOR
ENDIF ELSE BEGIN
   FOR j=1,NCOLORS DO BEGIN
      Widget_Control, drawID[j-1], Get_Value=thisWID
      wids[j-1] = thisWID
      WSet, thisWID
      ;PolyFill, [0,0,1,1,0], [0,1,1,0,0], /Normal, Color=bottom + j
      Erase, Color=bottom + j
      black = Where(colors EQ 'BLACK')
      PlotS, [0,0,19,19,0], [0,14,14,0,0], /Device, Color=bottom + black
   ENDFOR
ENDELSE

   ; Load the current or mixing color.

Widget_Control, mixColorID, Get_Value=mixWID
WSet, mixWID
IF theDepth GT 8 THEN BEGIN
   ;PolyFill, [0,0,1,1,0], [0,1,1,0,0], /Normal, Color=colors24[nameIndex]
   Erase, Color=colors24[nameIndex]
   black = Where(colornames EQ 'BLACK')
   black = black[0]
   PlotS, [0,0,59,59,0], [0,14,14,0,0], /Device, Color=colors24[black]
ENDIF ELSE BEGIN
   ;PolyFill, [0,0,1,1,0], [0,1,1,0,0], /Normal, Color=mixcolorIndex
   Erase, Color=mixcolorIndex
   black = Where(colors EQ 'BLACK')
   PlotS, [0,0,59,59,0], [0,14,14,0,0], /Device, Color=black
ENDELSE

   ; Pointer to hold the color form information.

ptr = Ptr_New({cancel:1.0, r:0B, g:0B, b:0B, name:theName})

   ; Info structure for program information.

info = { ptr:ptr, $                    ; The pointer to the form information.
         mixColorIndex:mixColorIndex, $
         colorNames:colorNames, $
         nameIndex:nameIndex, $
         red:red, $
         green:green, $
         blue:blue, $
         colors24:colors24, $
         mixWid:mixWid, $
         theDepth:theDepth, $
         labelID:labelID, $
         theName:theName $
       }

   ; Store the info structure in the UVALUE of the TLB.

Widget_Control, tlb, Set_UValue=info, /No_Copy

   ; Set up program event loop. This will be blocking widget
   ; if called from the IDL command line. Program operation
   ; will stop here until widget interface is destroyed.

XManager, 'pickcolor', tlb

   ; Retrieve the color information from the pointer and free
   ; the pointer.

colorInfo = *ptr
Ptr_Free, ptr

   ; Set the Cancel flag.

cancelled = colorInfo.cancel

   ; Restore color table, taking care to load the color index if required.

IF N_Elements(index) NE 0 AND (NOT cancelled) THEN BEGIN
   r_old[index] = colorInfo.r
   g_old[index] = colorInfo.g
   b_old[index] = colorInfo.b
ENDIF
TVLCT, r_old, g_old, b_old

   ; Restore decomposed state if possible.

IF Float(!Version.Release) GE 5.2 THEN Device, Decomposed=decomposedState

   ; Return the color name.

RETURN, colorInfo.name
END
