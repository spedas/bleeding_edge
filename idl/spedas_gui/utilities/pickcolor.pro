;+
; NAME:
;       PICKCOLOR
;
; PURPOSE:
;
;       A modal dialog widget allowing the user to select
;       the RGB color triple specifying a color. The return
;       value of the function is the color triple specifying the
;       color or the "name" of the color if the NAME keyword is set.
;
; AUTHOR:
;       FANNING SOFTWARE CONSULTING:
;       David Fanning, Ph.D.
;       1645 Sheely Drive
;       Fort Collins, CO 80526 USA
;       Phone: 970-221-0438
;       E-mail: davidf@dfanning.com
;       Coyote's Guide to IDL Programming: http://www.dfanning.com
;
; NOTE: This software has been heavily modified for usage by the SPEDAS GUI.  Please direct any errors to the SPEDAS software team 
; team and we will contact David Fanning, as necessary.
;
; CATEGORY:
;
;       Graphics, Color Specification. See related program FSC_COLOR.
;
; CALLING SEQUENCE:
;
;       color = PickColor(colorindex)
;
; RETURN VALUE:
;
;       The return value of the function is a 1-by-3 array containing
;       the values of the color triple that specifies the selected color.
;       The color can be loaded, for example, in any color index:
;
;           color = PickColor(240)
;           TVLCT, color, 240
;
;       The return value is the original color triple if the user
;       selects the CANCEL button.
;
;       IF the NAMES keyword is set, the return value of the function is
;       the "name" of the selected color. This would be appropriate for
;       passing to the FSC_COLOR program, for example.
;
; OPTIONAL INPUT POSITIONAL PARAMETERS:
;
;       COLORINDEX: The color index of the color to be changed. If not
;              specified the color index !D.Table_Size - 2 is used.
;              The Current Color and the Color Sliders are set to the
;              values of the color at this color index.
;
; OPTIONAL INPUT KEYWORD PARAMETERS:
;
;       GROUP_LEADER: The group leader for this widget program. This
;              keyword is required for MODAL operation. If not supplied
;              the program is a BLOCKING widget. Be adviced, however, that
;              the program will NOT work if called from a blocking widget
;              program, unless a GROUP_LEADER is supplied.
;
;       NAMES: Set this keyword to return the "name" of the selected color
;              rather than its color triple.
;
;       STARTINDEX: 88 pre-determined colors are loaded The STARTINDEX
;              is the index in the color table where these 88 colors will
;              be loaded. By default, it is !D.Table_Size - 89.
;
;       TITLE: The title on the program's top-level base. By default the
;              title is "Pick a Color".
;
; OPTIONAL INPUT KEYWORD PARAMETERS:
;
;       CANCEL: A keyword that is set to 1 if the CANCEL button is selected
;              and to 0 otherwise.
;
; COMMON BLOCKS:
;
;       None.
;
; MODIFICATION HISTORY:
;       Written by: David Fanning, 28 Oct 99.
;       Added NAME keyword. 18 March 2000, DWF.
;       Fixed a small bug when choosing a colorindex less than !D.Table_Size-17. 20 April 2000. DWF.
;       Added actual color names to label when NAMES keyword selected. 12 May 2000. DWF.
;       Modified to use 88 colors and FSC_COLOR instead of 16 colors and GETCOLOR. 4 Dec 2000. DWF.
;       Now drawing small box around each color. 13 March 2003. DWF.
;       Added CURRENTCOLOR keyword. 3 July 2003. DWF.
;       Switched to object graphics, eliminated side-effects. 25 Jan 2011 pcruce.        
;-
;
;###########################################################################
;
; LICENSE
;
; This software is OSI Certified Open Source Software.
; OSI Certified is a certification mark of the Open Source Initiative.
;
; Copyright � 2000-2003 Fanning Software Consulting.
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


;PRO PickColor_CenterTLB, tlb
;
;Device, Get_Screen_Size=screenSize
;xCenter = screenSize(0) / 2
;yCenter = screenSize(1) / 2
;
;geom = Widget_Info(tlb, /Geometry)
;xHalfSize = geom.Scr_XSize / 2
;yHalfSize = geom.Scr_YSize / 2
;
;Widget_Control, tlb, XOffset = xCenter-xHalfSize, $
;   YOffset = yCenter-yHalfSize
;END ;---------------------------------------------------------------------------



PRO PickColor_Select_Color, event

; This event handler permits color selection by clicking on a color window.

Widget_Control, event.top, Get_UValue=info, /No_Copy

   ; Get the color names from the window you clicked on.

Widget_Control, event.id, Get_UValue=thisColorName

IF info.needsliders EQ 0 THEN Widget_Control, info.labelID, Set_Value=thisColorName

   ; Get the color value and load it as the current color.

thisColor = FSC_Color(thisColorName, /Triple)
info.currentName = thisColorName
info.scene->setProperty,color=reform(thisColor)
info.currentWid->draw,info.scene
info.currentColor=reform(thisColor)


IF info.needSliders THEN BEGIN

      ; Update the slider values to this color value.

   Widget_Control, info.redID, Set_Value=thisColor[0,0]
   Widget_Control, info.greenID, Set_Value=thisColor[0,1]
   Widget_Control, info.blueID, Set_Value=thisColor[0,2]

ENDIF

Widget_Control, event.top, Set_UValue=info, /No_Copy
END ;---------------------------------------------------------------------------


PRO PickColor_Sliders, event

; This event handler allows the user to mix their own color.

Widget_Control, event.top, Get_UValue=info, /No_Copy

   ; Get the color slider values.

Widget_Control, info.redID, Get_Value=red
Widget_Control, info.greenID, Get_Value=green
Widget_Control, info.blueID, Get_Value=blue

   ; Load the new color as the current color.
color=[red,green,blue]
info.scene->setProperty,color=color
info.currentWid->draw,info.scene
info.currentColor=color

Widget_Control, event.top, Set_UValue=info, /No_Copy
END ;---------------------------------------------------------------------------



PRO PickColor_Buttons, event

; This event handler responds to CANCEL and ACCEPT buttons.

Widget_Control, event.top, Get_UValue=info, /No_Copy
Widget_Control, event.id, Get_Value=buttonValue
CASE buttonValue OF

   'Cancel': BEGIN
      Widget_Control, event.top, /Destroy       ; Exit.
      ENDCASE

   'Accept': BEGIN
   
         ; Save the new color in the form info pointer.

      *(info.ptr) = {cancel:0.0, r:info.currentColor[0], g:info.currentColor[1], $
         b:info.currentColor[2], name:info.currentName}
      Widget_Control, event.top, /Destroy ; Exit

      ENDCASE
ENDCASE
END ;---------------------------------------------------------------------------



FUNCTION PickColor, currentColorIndex, Title=title, $
   Group_Leader=groupLeader, Cancel=cancelled, Names=name, CurrentColor=currentColor

NCOLORS = 88

   ; Check parameters.

IF N_Elements(title) EQ 0 THEN title = 'Pick a Color'

IF Keyword_Set(name) THEN needSliders = 0 ELSE needSliders = 1

if n_elements(currentColor) eq 0 then currentColor = [255,255,255]

   ; Load the new drawing colors and get their names.

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

colorNames = colors
currentName =""

oPalette = get_thm_palette()
oPalette->getProperty,red_values=r,blue_values=b,green_values=g
obj_destroy,oPalette

IF Keyword_Set(name) THEN labelTitle = currentName ELSE labelTitle = 'Current Color'

   ; Create the widgets. TLB is MODAL or BLOCKING.

IF N_Elements(groupLeader) EQ 0 THEN BEGIN
   tlb = Widget_Base(Title=title, Column=1, /Base_Align_Center)
ENDIF ELSE BEGIN
   tlb = Widget_Base(Title=title, Column=1, /Base_Align_Center, /Modal, $
      Group_Leader=groupLeader)
ENDELSE

;  lcolorWindow = WIDGET_DRAW(lcolorBase,graphics_level=2,renderer=1, $
;                             retain=1, XSize=50, YSize=19, units=0, frame=1, /expose_events)

colorbaseID = Widget_Base(tlb, Column=11, Event_Pro='PickColor_Select_Color')
drawID = LonArr(88)
FOR j=0,NCOLORS-1 DO BEGIN
   drawID[j] = Widget_Draw(colorbaseID, XSize=20, YSize=15, frame=1,$
      UValue=colorNames[j], Button_Events=1,graphics_level=2,renderer=1,retain=1)
ENDFOR

currentID = Widget_Base(tlb, Column=1, Base_Align_Center=1)
labelID = Widget_Label(currentID, Value=labelTitle, /Dynamic_Resize)
currentColorID = Widget_Draw(currentID, XSize=60, YSize=15,graphics_level=2,renderer=1,retain=1,frame=1)

IF needSliders THEN BEGIN

   sliderbase = Widget_Base(tlb, COLUMN=1, FRAME=1, BASE_ALIGN_CENTER=1, $
      EVENT_PRO='PickColor_Sliders')
   label = Widget_Label(sliderbase, Value='Specify a Color')

      ; Set the current color values in sliders.

   redID = Widget_Slider(sliderbase, Scr_XSize=200, Value=currentColor[0], $
      Max=255, Min=0, Title='Red')
   greenID = Widget_Slider(sliderbase, Scr_XSize=200, Value=currentColor[1], $
      Max=255, Min=0, Title='Green')
   blueID = Widget_Slider(sliderbase, Scr_XSize=200, Value=currentColor[2], $
      Max=255, Min=0, Title='Blue')

ENDIF ELSE BEGIN

   redID = 0L
   greenID = 0L
   blueID = 0L

ENDELSE

buttonbase = Widget_Base(tlb, ROW=1, Align_Center=1, Event_Pro='PickColor_Buttons')
cancelID = Widget_Button(buttonbase, VALUE='Cancel')
acceptID = Widget_Button(buttonbase, VALUE='Accept')

   ; Center the TLB.

;PickColor_CenterTLB, tlb
Widget_Control, tlb, /Realize

   ; Load the drawing colors.

wids = IntArr(NCOLORS)
scene = obj_new('IDLgrScene')
FOR j=0, NCOLORS-1 DO BEGIN
   Widget_Control, drawID[j], Get_Value=thisWID
   scene->SetProperty,color=[red[j],green[j],blue[j]]
   thisWid->draw,scene
   ;wids[j] = thisWID
   ;WSet, thisWID
   ;PolyFill, [0,0,1,1,0], [0,1,1,0,0], /Normal, Color=startIndex + j
  ; Erase, Color=startIndex + j
   ;black = Where(colornames EQ 'Black')
   ;black = black[0]
   ;PlotS, [0,0,19,19,0], [0,14,14,0,0], /Device, Color=startIndex + black
ENDFOR

   ; Load the current color.

WIDGET_CONTROL, CURRENTCOLORID, GET_VALUE=CURRENTWID

;
;
scene->SetProperty,color=reform(currentColor)
currentwid->draw,scene
   ; Pointer to hold the form information.
ptr = ptr_new({cancel:0.0, r:currentColor[0],g:currentColor[1],b:currentColor[2]})

   ; Info structure for program information.

info = { ptr:ptr, $ ;return value
         r:r, $                        ; The new color table.
         g:g, $
         b:b, $
         scene:scene,$
         labelID:labelID, $
         needSliders:needSliders, $    ; A flag that indicates if sliders are needed.
         redID:redID, $                ; The IDs of the color sliders.
         greenID:greenID, $
         blueID:blueID, $
         currentName:currentName, $    ; The current color name.
         currentColor:reform(currentColor),$
         currentWID:currentWID, $      ; The current color window index number.
         wids:wids $                   ; The window index number of the drawing colors.
       }

Widget_Control, tlb, Set_UValue=info, /No_Copy
XManager, 'pickcolor', tlb ; Block here until widget program is destroyed.

   ; Retrieve the color information.
colorInfo = *ptr
Ptr_Free, ptr

obj_destroy,scene
cancelled = colorInfo.cancel

   ; Restore decomposed state if possible.

   ; Return the color triple.

IF Keyword_Set(name) THEN return,"Color Name No Longer Supported." ELSE $
   RETURN, Reform([colorInfo.r, colorInfo.g, colorInfo.b], 1, 3)
END
