;+ 
;NAME: 
; spd_ui_line_style__define
;
;PURPOSE:  
; generic object for IDL line styles
;
;CALLING SEQUENCE:
; lineStyle = Obj_New("SPD_UI_LINE_STYLE")
;
;INPUT:
; none
;
;KEYWORDS:
; name       name of line style (solid, dotted, dashed, dashdot, 
;                                dashdotdot,long dashes)
; id         IDL line style value (0-5)
; show       set this to display line (default = 1)
; color      name of the color for this line (default is black)
; rgb        [r, g, b] value for the color for this line  
; thickness  thickness of the line (default = 1)
; opacity    the opacity of the line
;
;OUTPUT:
; line style object reference
;
;METHODS:
; GetProperty
; GetAll
; SetProperty
; GetLineStyleName
; GetLineStyleId
; GetLineStyle
; Copy
;
;NOTES:
;  Methods: GetProperty,SetProperty,GetAll,SetAll are now managed automatically using the parent class
;  spd_ui_getset.  You can still call these methods when using objects of type spd_ui_line_style, and
;  call them in the same way as before
;
;$LastChangedBy: jimm $
;$LastChangedDate: 2014-02-11 10:54:32 -0800 (Tue, 11 Feb 2014) $
;$LastChangedRevision: 14326 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/spedas_gui/objects/spd_ui_line_style__define.pro $
;-----------------------------------------------------------------------------------



FUNCTION SPD_UI_LINE_STYLE::Copy
   out = Obj_New("SPD_UI_LINE_STYLE")
   Struct_Assign, self, out
   RETURN, out
END ;--------------------------------------------------------------------------------

FUNCTION SPD_UI_LINE_STYLE::GetLineStyleName, LineStyleId=linestyleid
   IF N_Elements(linestyleid) EQ 0 THEN RETURN, self.name 
   IF NOT Is_Numeric(linestyleid) THEN RETURN, -1
   lineStyleList = self->GetLineStyles()
   IF linestyleid LT 0 OR linestyleid GE n_elements(lineStyleList) THEN RETURN, -1 
   RETURN, lineStyleList[linestyleid]
END ;--------------------------------------------------------------------------------



FUNCTION SPD_UI_LINE_STYLE::GetLineStyleId, LineStyleName=linestylename
   IF N_Elements(linestylename) EQ 0 THEN RETURN, self.id 
   IF Is_Numeric(linestylename) THEN RETURN, -1
   lineStyleList = self->GetLineStyles()   
   lineStyleId=where(lineStyleList EQ linestylename)   
   RETURN, lineStyleId
END ;--------------------------------------------------------------------------------



FUNCTION SPD_UI_LINE_STYLE::GetLineStyles
RETURN, ['Solid', 'Dotted', 'Dashed', 'Dash Dot', 'Dash Dot Dot Dot', 'Long Dashes']
END ;--------------------------------------------------------------------------------

  
FUNCTION SPD_UI_LINE_STYLE::Init, $ ; The INIT method of the line style object
            Name=name,            $ ; name of line style (solid, dashed, ...)
            ID=id,                $ ; IDL line style value (0-5)
            Show=show,            $ ; flag to display line 
            Color=color,          $ ; name of color
            Thickness=thickness,  $ ; line thickness
            opacity=opacity,      $ ; line opacity
            Debug=debug             ; flag to debug

   Catch, theError
   IF theError NE 0 THEN BEGIN
      Catch, /Cancel
      ok = Error_Message(Traceback=Keyword_Set(debug))
      RETURN, 0
   ENDIF
  
   ; Check that all parameters have values
   
   IF N_Elements(name) EQ 0 THEN name = 'Solid'
   IF N_Elements(id) EQ 0 THEN BEGIN
    id = 0 
   ENDIF ELSE BEGIN
    IF id LT 0 OR id GT 5 THEN RETURN, 0
   ENDELSE 
   IF N_Elements(show) EQ 0 THEN show = 1
   IF N_Elements(color) EQ 0 THEN color = [0,0,0]
   IF N_Elements(thickness) EQ 0 THEN thickness = 1
   IF n_elements(opacity) eq 0 then opacity = 1D

  ; Set all parameters

   self.name = name
   self.id = id
   self.show = show
   self.color = color
   self.thickness = thickness
   self.opacity = opacity
  
   RETURN, 1
END ;--------------------------------------------------------------------------------                 

PRO SPD_UI_LINE_STYLE__DEFINE

   struct = { SPD_UI_LINE_STYLE,            $

              name      : ' ',        $ ; the name of the line style 
              id        : 0,          $ ; IDL line styles (0-5) 
              show      : 0,          $ ; flag to display line
              color     : [0,0,0],    $ ; name of line color
              thickness : 0,          $ ; line thickness
              opacity   : 0D,         $ ; how opaque is the line 
              INHERITS SPD_UI_READWRITE, $ ; generalized read/write methods
              inherits spd_ui_getset $ ; generalized setProperty/getProperty/getAll/setAll methods   
                                     
}

END
