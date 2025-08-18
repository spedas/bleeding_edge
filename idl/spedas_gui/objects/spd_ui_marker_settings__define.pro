;+ 
;NAME: 
; spd_ui_marker_settings__define
;
;PURPOSE:  
; Marker Settings object - used for the marker options panel, this object holds the
; settings used for markers
;
;CALLING SEQUENCE:
; marker = Obj_New("SPD_UI_MARKER_SETTINGS")
;
;INPUT:
; none
;
;ATTRIBUTES:
;label             marker title text object
;vertPlacement     vertical placement of marker label 
;fillColor         color used to shade marked area
;lineStyle         line style object for start/end points
;drawOpaque        opacity of the marker(floating pt between 0 & 1])
;
;OUTPUT:
; marker setting object reference
;
;METHODS:
; SetProperty  procedure to set keywords 
; GetProperty  procedure to get keywords 
; GetAll       returns the entire structure
;
;NOTES:
;  Methods: GetProperty,SetProperty,GetAll,SetAll are now managed automatically using the parent class
;  spd_ui_getset.  You can still call these methods when using objects of type spd_ui_marker_settings, and
;  call them in the same way as before
;
;$LastChangedBy:pcruce $
;$LastChangedDate:2009-09-10 09:15:19 -0700 (Thu, 10 Sep 2009) $
;$LastChangedRevision:6707 $
;$URL:svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/thmsoc/trunk/idl/spedas/spd_ui/objects/spd_ui_marker_settings__define.pro $
;-----------------------------------------------------------------------------------



FUNCTION SPD_UI_MARKER_SETTINGS::Copy
   out = Obj_New('SPD_UI_MARKER_SETTINGS',/nosave)
   Struct_Assign, self, out
   ;newLineStyle=Obj_New("SPD_UI_LINE_STYLE")
   IF Obj_Valid(self.lineStyle) THEN newLineStyle=self.lineStyle->Copy() ELSE $
      newLineStyle=Obj_New()
   out->SetProperty, LineStyle=newLineStyle
   
   ;newLabel = obj_new('spd_ui_text')
   If obj_valid(self.label) then newLabel = self.label->copy() else $
     newLabel=Obj_new()
   out->setProperty, label=newLabel
   
   return,out
   
END ;--------------------------------------------------------------------------------


FUNCTION SPD_UI_MARKER_SETTINGS::GetPlacements
RETURN, ['Top', 'Near Top', 'Above Middle', 'Middle', 'Below Middle', 'Near Bottom', 'Bottom']
END ;--------------------------------------------------------------------------------



FUNCTION SPD_UI_MARKER_SETTINGS::GetPlacement, index
   IF N_Elements(index) EQ 0 THEN RETURN, 0
   IF NOT Is_Numeric(index) THEN RETURN, 0
   IF index LT 0 OR index GT 6 THEN RETURN, 0
   placements = self->GetPlacements()
RETURN, placements(index)
END ;--------------------------------------------------------------------------------


PRO SPD_UI_MARKER_SETTINGS::Save

   obj = self->Copy()  
   if ptr_valid(self.origsettings) then begin
      ptr_free,self.origsettings
   endif
   self.origsettings = ptr_new(obj->getall())

RETURN
END ;--------------------------------------------------------------------------------

PRO SPD_UI_MARKER_SETTINGS::Reset

   if ptr_valid(self.origsettings) then begin
      self->setall,*self.origsettings
   endif

RETURN
END ;--------------------------------------------------------------------------------



PRO SPD_UI_MARKER_SETTINGS::Cleanup
    Obj_Destroy, self.lineStyle
    Obj_destroy, self.label
    ptr_free, self.origsettings
    RETURN
END ;--------------------------------------------------------------------------------



FUNCTION SPD_UI_MARKER_SETTINGS::Init,  $
      Label=label,                    $ ; marker label text object
      VertPlacement=vertplacement,    $ ; vertical placement of marker label
      FillColor=fillcolor,            $ ; color used to shade marked area
      LineStyle=linestyle,            $ ; line style object for start/end points
      DrawOpaque=drawopaque,          $ ; opacity of the marker(floating pt between 0 & 1]) 
      Debug=debug,                    $ ; flag to debug
      nosave=nosave                     ; don't save copy on startup

   Catch, theError
   IF theError NE 0 THEN BEGIN
      Catch, /Cancel
      ok = Error_Message(Traceback=Keyword_Set(debug))
      RETURN, 0
   ENDIF

      ; Check that all parameters have values
   
   IF N_Elements(label) EQ 0 THEN label = Obj_new('spd_ui_text')
   IF N_Elements(vertplacement) EQ 0 THEN vertplacement = 0 
   IF N_Elements(fillcolor) EQ 0 THEN fillcolor = [200,200,200]
   IF N_Elements(drawopaque) EQ 0 THEN drawopaque = .5
   IF NOT Obj_Valid(linestyle) THEN linestyle = Obj_New("SPD_UI_LINE_STYLE", Color=[255,0,0])

      ; Set all parameters

   self.label = label
   self.vertPlacement = vertplacement
   self.fillColor = fillcolor
   self.lineStyle = linestyle
   self.drawOpaque = drawopaque
  
   if ~keyword_set(nosave) then begin
      self->save
   endif
                 
RETURN, 1
END ;--------------------------------------------------------------------------------

PRO SPD_UI_MARKER_SETTINGS__DEFINE

   struct = { SPD_UI_MARKER_SETTINGS,  $

      label : Obj_new(),         $ ; marker label or title text object
      vertPlacement : 0,         $ ; vertical placement of marker label
      fillColor : [0,0,0],       $ ; color to shade marked area in
      lineStyle : Obj_New(),     $ ; line style object, start and end points 
      drawOpaque : 0D,           $ ; opacity of the marker 
      origsettings: ptr_new(),   $ ; original settings in case of reset      
      INHERITS SPD_UI_READWRITE, $ ; generalized read/write methods
      inherits spd_ui_getset     $ ; generalized setProperty/getProperty/getAll/setAll methods

}

END
