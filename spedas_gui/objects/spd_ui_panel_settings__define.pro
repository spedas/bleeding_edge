;+ 
;NAME: 
; spd_ui_panel_settings__define
;
;PURPOSE:  
; Panel Settings object - holds the settings for panel traces, layout and grid
;
;CALLING SEQUENCE:
; panelTrace = Obj_New("SPD_UI_PANEL_SETTINGS")
;
;INPUT:
; none
;
;OUTPUT:
; panel setting object reference
;
;ATTRIBUTES:
; panelNames         list of panel names
; titleobj           titleobj panel
; titleMargin        the margin between the plot and the title in pts   
; overlay            set this flag to overlay title
; row                current row
; col                current column
; rSpan              number of rows to span
; cSpan              number of columns to span
; bottom             flag indicating value was set by user
; bvalue             value of bottom position
; bunit              unit of  position value 0=pt, 1=in, 2=cm, 3=mm
; left               flag indicating value was set by user
; lValue             value of left position
; lUnit              unit of  position value 0=pt, 1=in, 2=cm, 3=mm
; width              flag indicating value was set by user
; wValue             value of width position
; wUnit              unit of  position value 0=pt, 1=in, 2=cm, 3=mm
; height             flag indicating value was set by user
; hValue             value of height position
; hUnit              unit of  position value 0=pt, 1=in, 2=cm, 3=mm
; relVertSize        relative size (percentage)
; backgroundColor    background color
; framecolor         frame color
; framethick         framethickness
;
;METHODS:
; SetProperty  procedure to set keywords 
; GetProperty  procedure to get keywords 
; GetAll       returns the entire structure
; GetUnitNames returns a string array of possible unit values
; GetUnitName  returns a string containing the name of the unit
;
;NOTES:
;  Methods: GetProperty,SetProperty,GetAll,SetAll are now managed automatically using the parent class
;  spd_ui_getset.  You can still call these methods when using objects of type spd_ui_panel_settings, and
;  call them in the same way as before
;
;$LastChangedBy:pcruce $
;$LastChangedDate:2009-09-10 09:15:19 -0700 (Thu, 10 Sep 2009) $
;$LastChangedRevision:6707 $
;$URL:svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/thmsoc/trunk/idl/spedas/spd_ui/objects/spd_ui_panel_settings__define.pro $
;-----------------------------------------------------------------------------------



FUNCTION SPD_UI_PANEL_SETTINGS::Copy
   out = Obj_New("SPD_UI_PANEL_SETTINGS",/nosave)
   selfClass = Obj_Class(self)
   outClass = Obj_Class(out)
   IF selfClass NE outClass THEN BEGIN
       dprint,  'Object classes not identical'
       RETURN,-1
   END
   Struct_Assign, self, out
   ; copy title object
   ; newTitle=Obj_New("SPD_UI_TEXT")
   IF Obj_Valid(self.titleObj) THEN newTitle=self.titleObj->Copy() ELSE $
      newTitle=Obj_New()
   out->SetProperty, TitleObj=newTitle
   RETURN, out
END ;--------------------------------------------------------------------------------

;handles special cases for setProperty, the rest is handled by parent class: spd_ui_getset
pro spd_ui_panel_settings::setProperty,$
                             bunit=bunit,$
                             lunit=lunit,$
                             wunit=wunit,$
                             hunit=hunit,$
                             _extra=ex
                             
  if n_elements(bunit) gt 0 then begin
    self.bvalue = self->convertunit(self.bvalue,self.bunit,bunit)
  endif
  
  if n_elements(lunit) gt 0 then begin
    self.lvalue = self->convertunit(self.lvalue,self.lunit,lunit)
  endif

  if n_elements(wunit) gt 0 then begin
    self.wvalue = self->convertunit(self.wvalue,self.wunit,wunit)
  endif
  
  if n_elements(hunit) gt 0 then begin
    self.hvalue = self->convertunit(self.hvalue,self.hunit,hunit)
  endif
  
  ;Do all general purpose setPropery with parent class
  self->spd_ui_getset::setProperty,bunit=bunit,lunit=lunit,wunit=wunit,hunit=hunit,_extra=ex
  
end

FUNCTION SPD_UI_PANEL_SETTINGS::GetUnitNames
RETURN, ['pt', 'in', 'cm', 'mm']
END ;--------------------------------------------------------------------------------



FUNCTION SPD_UI_PANEL_SETTINGS::GetUnitName, index
names = self->GetUnitNames()
RETURN, names[index]
END ;--------------------------------------------------------------------------------

function SPD_UI_PANEL_SETTINGS::convertunit,value,oldunit,newunit

  
  in2cm = 2.54D
  cm2mm = 10D
  mm2pt = 360D/127D
 
  ;turn value into points
  case oldunit of
    0: pts=value
    1: pts=value*(in2cm*cm2mm*mm2pt)
    2: pts=value*(cm2mm*mm2pt)
    3: pts=value*(mm2pt)
  end
  
  ;turn points into new value
  case newunit of
    0: new=pts
    1: new=pts/(in2cm*cm2mm*mm2pt)
    2: new=pts/(cm2mm*mm2pt)
    3: new=pts/(mm2pt)
  end
  
  ;turn points into new value
  
  return,new

END ;--------------------------------------------------------------------------------


PRO SPD_UI_PANEL_SETTINGS::Save

  obj = self->copy()
  if ptr_valid(self.origsettings) then begin
      ptr_free,self.origsettings
   endif
   self.origsettings = ptr_new(obj->getall())
   obj_destroy, obj

RETURN
END ;--------------------------------------------------------------------------------

PRO SPD_UI_PANEL_SETTINGS::Reset

   if ptr_valid(self.origsettings) then begin
      self->SetAll,*self.origsettings
   endif

RETURN
END ;--------------------------------------------------------------------------------

;handles special case of getProperty, the rest is handled by parent class
pro spd_ui_panel_settings::getProperty,backgroundrgb=backgroundrgb,_ref_extra=ex

  IF Arg_Present(backgroundrgb) THEN backgroundrgb = GetColor(self.backgroundColor)
  
  ;call getproperty on parent class to handle all general purpose cases 
  self->spd_ui_getset::getProperty,_extra=ex
 
end

PRO SPD_UI_PANEL_SETTINGS::Cleanup
    ptr_free, self.origsettings
    obj_destroy, self.titleObj
END

FUNCTION SPD_UI_PANEL_SETTINGS::Init,     $
      TitleObj=titleObj,                  $ ; title obj panel
      titleMargin=titleMargin,            $ ; the margin between the plot and the title in pts 
      Row=row,                            $ ; current row
      Col=col,                            $ ; current column
      RSpan=rspan,                        $ ; number of rows to span
      CSpan=cspan,                        $ ; number of columns to span
      Bottom=bottom,                      $ ; flag indicating value was set by user
      BValue=bvalue,                      $ ; value of bottom position
      BUnit=bunit,                        $ ; unit of  position value 0=pt, 1=in, 2=cm, 3=mm
      Left=left,                          $ ; flag indicating value was set by user
      LValue=lvalue,                      $ ; value of left position
      LUnit=lunit,                        $ ; unit of  position value 0=pt, 1=in, 2=cm, 3=mm
      Width=width,                        $ ; flag indicating value was set by user
      WValue=wvalue,                      $ ; value of width position
      WUnit=wunit,                        $ ; unit of  position value 0=pt, 1=in, 2=cm, 3=mm
      Height=height,                      $ ; flag indicating value was set by user
      HValue=hvalue,                      $ ; value of height position
      HUnit=hunit,                        $ ; unit of  position value 0=pt, 1=in, 2=cm, 3=mm
      RelVertSize=relvertsize,            $ ; relative vertical size (percentage)
      BackgroundColor=backgroundcolor,    $ ; background color
      framecolor=framecolor,              $ ; color of panel frame
      framethick=framethick,              $ ; value indicating the thickness of the frame
      nosave=nosave                         ; don't save on start
 
    

   Catch, theError
   IF theError NE 0 THEN BEGIN
      Catch, /Cancel
      ok = Error_Message(Traceback=1)
      RETURN, 0
   ENDIF
   
      ; Check that all parameters have values
   
   IF N_Elements(titleObj) EQ 0 THEN titleObj = obj_new('spd_ui_text', size=10)
   IF n_elements(titleMargin) eq 0 then titleMargin = 5.
   IF N_Elements(row) EQ 0 THEN row = 1 
   IF N_Elements(col) EQ 0 THEN col = 1 
   IF N_Elements(rspan) EQ 0 THEN rspan = 1 
   IF N_Elements(cspan) EQ 0 THEN cspan = 1 
   ;IF N_Elements(bvalue) EQ 0 THEN bvalue = 15
   IF n_elements(bvalue) eq 0 then bvalue = -1.
   IF N_Elements(bunit) EQ 0 THEN bunit = 0   
   ;IF N_Elements(lvalue) EQ 0 THEN lvalue = 49
   if n_elements(lvalue) eq 0 then lvalue = -1.
   IF N_Elements(lunit) EQ 0 THEN lunit = 0   
   ;IF N_Elements(wvalue) EQ 0 THEN wvalue = 756
   if n_elements(wvalue) eq 0 then wvalue = -1. 
   IF N_Elements(wunit) EQ 0 THEN wunit = 0   
   ;IF N_Elements(hvalue) EQ 0 THEN hvalue = 150
   if n_elements(hvalue) eq 0 then hvalue = -1.
   IF N_Elements(hunit) EQ 0 THEN hunit = 0   
   IF N_Elements(relvertsize) EQ 0 THEN relvertsize = 100 
   IF N_Elements(backgroundcolor) EQ 0 THEN backgroundcolor = [255,255,255]  
   if n_elements(framecolor) eq 0 then framecolor = [0,0,0]
   if n_elements(framethick) eq 0 then framethick = 1.0

      ; Set all parameters

   self.titleObj = titleObj
   self.titleMargin = titleMargin
   self.row = row
   self.col = col
   self.rSpan = rspan
   self.cSpan = cspan 
   self.bottom = Keyword_Set(bottom)
   self.bValue = bvalue 
   self.bUnit = bunit
   self.left = Keyword_Set(left)
   self.lValue = lvalue 
   self.lUnit = lunit  
   self.width = Keyword_Set(width)
   self.wValue = wvalue 
   self.wUnit = wunit
   self.height = Keyword_Set(height)
   self.hValue = hvalue
   self.hUnit = hunit
   self.relVertSize = relvertsize
   self.backgroundColor = backgroundcolor
   self.framecolor = framecolor
   self.framethick = framethick

   if ~keyword_set(nosave) then begin
     self->Save
   endif

RETURN, 1
END ;--------------------------------------------------------------------------------

PRO SPD_UI_PANEL_SETTINGS__DEFINE

   struct = { SPD_UI_PANEL_SETTINGS, $

          ; layout settings

      titleObj: obj_new(),       $ ; text object for panel title
      titleMargin:0,             $ ; the margin between the plot and the title in pts 
      row: 0,                    $ ; current row
      col: 0,                    $ ; current column 
      rSpan: 0,                  $ ; number of rows to span
      cSpan: 0,                  $ ; number of columns to span
      bottom: 0.,                $ ;  flag indicating whether explicit positioning is used
      bValue: 0D,                 $ ; numerical value of the explicit position
      bUnit: 0,                  $ ; 0=pt, 1=in, 2=cm, 3=mm, units of numerical value
      left: 0.,                  $ ;
      lValue: 0D,                 $ ;
      lUnit: 0,                  $ ;
      width: 0.,                 $ ;
      wValue: 0D,                 $ ;
      wUnit: 0,                  $ ;
      height: 0.,                $ ;
      hValue: 0D,                 $ ;
      hUnit: 0,                  $ ;
      relVertSize: 0,            $ ; relative size (percentage)
      backgroundColor:[0,0,0],   $ ; background color
      framecolor:[0,0,0],        $ ; color of panel frame
      framethick:0,              $ ; thickness of panel frame
      origsettings: ptr_new(),   $ ; original settings for reset
      INHERITS SPD_UI_READWRITE,  $ ; generalized read/write methods
      inherits spd_ui_getset $ ; generalized setProperty/getProperty/getAll/setAll methods   
      }
      

END ;--------------------------------------------------------------------------------
