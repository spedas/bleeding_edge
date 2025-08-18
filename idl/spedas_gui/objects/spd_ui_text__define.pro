;+ 
;NAME: 
; spd_ui_text__define
;
;PURPOSE:  
; generic object for character strings
;
;CALLING SEQUENCE:
; text = Obj_New("SPD_UI_TEXT")
;
;INPUT:
; none
;
;KEYWORDS:
;value     what's contained in the string 
;font      font names ('Time New Roman', etc...) 
;format    font formats ('bold', 'italic', etc..)
;color     name of color for text
;size      character size
;thickness character thickness 
;show      flag to display text

;OUTPUT:
; text object reference
;
;METHODS:
; GetProperty
; GetAll
; SetProperty
; GetFonts
; GetFont
; GetFontIndex
; GetFormats
; GetFormat
; GetFormatIndex
;
;HISTORY:
;
;$LastChangedBy: aaflores $
;$LastChangedDate: 2016-05-17 14:51:47 -0700 (Tue, 17 May 2016) $
;$LastChangedRevision: 21100 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/spedas_gui/objects/spd_ui_text__define.pro $
;-----------------------------------------------------------------------------------



FUNCTION SPD_UI_TEXT::Copy
   out = Obj_New('SPD_UI_TEXT')
   selfClass = Obj_Class(self)
   outClass = Obj_Class(out)
   IF selfClass NE outClass THEN BEGIN
       dprint,  'Object classes not identical'
       RETURN, -1
   END
   Struct_Assign, self, out
   RETURN, out
END ;--------------------------------------------------------------------------------

;Mainly uses spd_ui_getset setProperty method, just handles special case for color
PRO SPD_UI_TEXT::SetProperty,color=color, _extra=ex


  if n_elements(color) gt 0 then begin
    if is_string(color) then begin
      self.color = getColor(color)
    endif else begin
      self.color = color
    endelse
  endif
    
  ;call parent class setProperty method
  self->spd_ui_getset::setProperty,_extra=ex

RETURN
END ;--------------------------------------------------------------------------------



FUNCTION SPD_UI_TEXT::GetFormats
formats = [             $
        'Bold',         $
        'Italic',       $
        'Bold*Italic',  $
        'No Format']
RETURN, formats
END ;--------------------------------------------------------------------------------



FUNCTION SPD_UI_TEXT::GetFormat, Index=index
IF N_Elements(index) EQ 0 THEN index = self.format
IF NOT Is_Numeric(index) THEN RETURN, -1
IF index LT 0 OR index GT 5 THEN RETURN, -1 ELSE formats = self->GetFormats()

font = self->GetFont()

if font eq 'Symbol' || font eq 'Monospace Symbol' then return,-1

RETURN, formats[index]
END ;--------------------------------------------------------------------------------



FUNCTION SPD_UI_TEXT::GetFormatIndex, FormatName=formatname
IF N_Elements(formatname) EQ 0 THEN RETURN, self.format
IF Is_Numeric(formatname) THEN RETURN, -1
formats = self->GetFormats()
formatIndex = where(formats EQ formatname)
RETURN, formatIndex
END ;--------------------------------------------------------------------------------



FUNCTION SPD_UI_TEXT::GetFonts
  fonts = ['Times',         $
           'Courier',       $
           'Helvetica']       
  RETURN, fonts
END ;--------------------------------------------------------------------------------



FUNCTION SPD_UI_TEXT::GetFont, Index=index
IF N_Elements(index) EQ 0 THEN index = self.font
IF NOT Is_Numeric(index) THEN RETURN, -1
fonts = self->GetFonts()
IF index LT 0 OR index GT N_Elements(fonts)-1 THEN begin
  ;If the supplied index is out of range, then return the first font (Times)
  RETURN, fonts[0]
ENDIF
RETURN, fonts[index]
END ;--------------------------------------------------------------------------------



FUNCTION SPD_UI_TEXT::GetFontIndex, FontName=fontname
IF N_Elements(fontname) EQ 0 THEN RETURN, self.font
IF Is_Numeric(fontname) THEN RETURN, -1
fonts = self->GetFonts()
fontIndex = where(fonts EQ fontname)
RETURN, fontIndex
END ;--------------------------------------------------------------------------------


;returns an IDLgrFont object which is used for Fonts in IDL object graphics
;This routine should guarantee appropriate font format.
FUNCTION SPD_UI_TEXT::getGrFont

  font = self->getFont()
  format = self->getFormat()
  if is_string(format[0]) && format ne 'No Format' then grFont = font + '*' + format else grFont = font
  if self.size gt 0 then grSize = self.size
  if self.thickness gt 0 then grThick = self.thickness
  
  return,obj_new('IDLgrFont',grFont,size=grSize,thick=grThick)
  
end

;returns the text from the object, but with the appropriate 
;values replaced in %strings
FUNCTION SPD_UI_TEXT::GetValue

  return,self.value

end

  
FUNCTION SPD_UI_TEXT::Init,         $ ; The INIT method of the line style object
              Value=value,          $ ; what's contained in the string 
              Font=font,            $ ; font names ('Time New Roman', etc...) 
              Format=format,        $ ; font formats ('bold', 'italic', etc..)
              Color=color,          $ ; name of color for text
              Size=size,            $ ; character size
              Thickness=thickness,  $ ; character thickness 
              Show=show,            $ ; flag to display text
              Debug=debug             ; flag to debug

   Catch, theError
   IF theError NE 0 THEN BEGIN
      Catch, /Cancel
      ok = Error_Message(Traceback=Keyword_Set(debug))
      RETURN, 0
   ENDIF
  
   ; Check that all parameters have values
   
   IF N_Elements(value) EQ 0 THEN value = ''
   IF N_Elements(font) EQ 0 THEN font = 2
   IF N_Elements(format) EQ 0 THEN format = 3
   IF N_Elements(color)EQ 0 THEN color = [0,0,0]
   IF N_Elements(size)EQ 0 THEN size = 12.
   IF N_Elements(thickness) EQ 0 THEN thickness = 1
   IF N_Elements(show)EQ 0 THEN show = 1

  ; Set all parameters

   self.value = value
   self.font = font
   self.format = format
   self.color = color
   self.size = size
   self.thickness = thickness
   self.show = show
  
   RETURN, 1
END ;--------------------------------------------------------------------------------                 

PRO SPD_UI_TEXT__DEFINE

   struct = { SPD_UI_TEXT,            $

              value : '',        $ ; what's contained in the string 
              font : 0,          $ ; font names ('Time New Roman', etc...) 
              format : -1,       $ ; font formats ('bold', 'italic', etc..)
              color : [0,0,0],   $ ; name of color for text
              size : 0,          $ ; character size
              thickness : 0,     $ ; character thickness 
              show : 0,          $ ; flag to display text
              INHERITS spd_ui_readwrite,  $ ; use generalize read/write methods
              INHERITS spd_ui_getset $ ; generalized getProperty/setProperty/getAll/setAll methods
                                     
}

END
