;+ 
;NAME: 
; spd_ui_marker_title__define
;
;PURPOSE:  
; Marker object, displayed whenever user ctrl-click-drags to highlight an area
;
;CALLING SEQUENCE:
; markerTitle = Obj_New("SPD_UI_MARKER_TITLE")
;
;INPUT:
; none
;
;KEYWORDS:
; name             name for this marker
; useDefault       flag set if using default name
; defaultName      default name for marker
; cancelled        flag set if window cancelled
; 
;
;OUTPUT:
; marker object reference
;
;METHODS:
; SetProperty   procedure to set keywords 
; GetProperty   procedure to get keywords 
; GetAll        returns the entire structure
;
;NOTES:
;  Methods: GetProperty,SetProperty,GetAll,SetAll are now managed automatically using the parent class
;  spd_ui_getset.  You can still call these methods when using objects of type spd_ui_marker_title, and
;  call them in the same way as before
;
;$LastChangedBy: jimm $
;$LastChangedDate: 2014-02-11 10:54:32 -0800 (Tue, 11 Feb 2014) $
;$LastChangedRevision: 14326 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/spedas_gui/objects/spd_ui_marker_title__define.pro $
;-----------------------------------------------------------------------------------



FUNCTION SPD_UI_MARKER_TITLE::Copy
   out = Obj_New("SPD_UI_MARKER_TITLE")
   selfClass = Obj_Class(self)
   outClass = Obj_Class(out)
   IF selfClass NE outClass THEN BEGIN
       dprint,  'Object classes not identical'
       RETURN, -1
   END
   Struct_Assign, self, out
   RETURN, out
END ;--------------------------------------------------------------------------------

FUNCTION SPD_UI_MARKER_TITLE::Init,     $
      Name=name,                  $ ; name for this marker
      UseDefault=usedefault,      $ ; flag set if user want to use default name
      DefaultName=defaultname,    $ ; default name of marker 
;      DoNotAsk=donotask,          $ ; flag set is user does not want to be asked every time
      Cancelled=cancelled,        $ ; flag set is cancelled the page
      Debug=debug                   ; flag to debug
      
   Catch, theError
   IF theError NE 0 THEN BEGIN
      Catch, /Cancel
      ok = Error_Message(Traceback=Keyword_Set(debug))
      RETURN, 0
   ENDIF

      ; Check that all parameters have values
   
   IF N_Elements(name) EQ 0 THEN name = ''
   IF N_Elements(usedefault) EQ 0 THEN useDefault = 0
   IF N_Elements(defaultname) EQ 0 THEN defaultname = ''
   IF N_Elements(cancelled) EQ 0 THEN cancelled = 1
;   IF N_Elements(donotask) EQ 0 THEN donotask = 0  

      ; Set all parameters

   self.name = name
   self.useDefault = usedefault
   self.defaultName = defaultname
   self.cancelled = cancelled
;   self.doNotAsk = donotask

                  
RETURN, 1
END ;--------------------------------------------------------------------------------



PRO SPD_UI_MARKER_TITLE__DEFINE

   struct = { SPD_UI_MARKER_TITLE,  $

        name:'',               $ ; name for this marker
        useDefault: 0,         $ ; flag set if user want to use default name
        defaultName: '',       $ ; default name of marker
        cancelled: 0,          $ ; flag to indicate whether the window was canceled
        inherits spd_ui_getset $ ; generalized setProperty/getProperty/getAll/setAll methods

}

END ;--------------------------------------------------------------------------------
