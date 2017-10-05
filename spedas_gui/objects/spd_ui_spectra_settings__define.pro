;+ 
;NAME: 
; spd_ui_spectra_settings__define
;
;PURPOSE:  
; spectra properties is an object that holds all of the settings necessary for 
; spectral data plots
;
;CALLING SEQUENCE:
; spectraSettings = Obj_New("SPD_UI_SPECTRA_SETTINGS")
;
;INPUT:
; none
;
;KEYWORDS:
; dataX              string naming the x component of the spectral plot
; dataY              string naming the y component of the spectral plot
; dataz              string naming the z component of the spectral plot
;
;OUTPUT:
; spectra property object reference
;
;METHODS:
; SetProperty    procedure to set keywords 
; GetProperty    procedure to get keywords 
; GetAll         returns the entire structure
; GetPlacements  returns string array of placement options
; GetPlacement   returns name of placement option given an index
; GetColorTables returns string array of color tables 
; GetColorTable  returns name of color table given an index
;
;NOTES:
;  Methods: GetProperty,SetProperty,GetAll,SetAll are now managed automatically using the parent class
;  spd_ui_getset.  You can still call these methods when using objects of type spd_ui_spectra_settings, and
;  call them in the same way as before
;
;$LastChangedBy:pcruce $
;$LastChangedDate:2009-09-10 09:15:19 -0700 (Thu, 10 Sep 2009) $
;$LastChangedRevision:6707 $
;$URL:svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/thmsoc/trunk/idl/spedas/spd_ui/objects/spd_ui_spectra_settings__define.pro $
;-----------------------------------------------------------------------------------



FUNCTION SPD_UI_SPECTRA_SETTINGS::Copy
   out = Obj_New("SPD_UI_SPECTRA_SETTINGS")
   selfClass = Obj_Class(self)
   outClass = Obj_Class(out)
   IF selfClass NE outClass THEN BEGIN
       dprint,  'Object classes not identical'
       RETURN, -1
   END
   Struct_Assign, self, out
   RETURN, out
END ;--------------------------------------------------------------------------------


;this routine will update references to a data quantity
;This should be used if a name has changed while traces are
;already in existence .
;arguments should be two arrays of strings, with the arrays being of equal length
;changed will be set to 1 if a value is changed
pro spd_ui_spectra_settings::updatedatareference,oldnames,newnames,changed=changed

  compile_opt idl2

  changed=0
  
  self->getProperty,datax=datax,datay=datay,dataz=dataz
  
  idx = where(datax eq oldnames,c)
  
  if c then begin
    changed = 1
    self->setProperty,datax=newnames[idx]
  endif
  
  idx = where(datay eq oldnames,c)
  
  if c then begin
    changed = 1
    self->setProperty,datay = newnames[idx]
  endif
  
  idx = where(dataz eq oldnames,c)
  
  if c then begin
    changed = 1
    self->setProperty,dataz = newnames[idx]
  endif
  
end

FUNCTION SPD_UI_SPECTRA_SETTINGS::Init,dataX=dataX,dataY=dataY,dataZ=dataZ

  if n_elements(dataX) eq 0 then dataX = ''
  if n_elements(dataY) eq 0 then dataY = ''
  if n_elements(dataZ) eq 0 then dataZ = ''
  
  self.dataX = dataX
  self.dataY = dataY
  self.dataZ = dataZ
                 
RETURN, 1
END ;--------------------------------------------------------------------------------

PRO SPD_UI_SPECTRA_SETTINGS__DEFINE

   struct = { SPD_UI_SPECTRA_SETTINGS,$
              dataX          : '',      $ ; string naming the x component of the spectral plot
              dataY          : '',      $ ; string naming the y component of the spectral plot
              dataZ          : '',      $ ; string naming the z component of the spectral plot
              INHERITS SPD_UI_READWRITE, $ ; generalized read/write methods
              inherits spd_ui_getset $ ; generalized setProperty/getProperty/getAll/setAll methods 
                                 
}

END
