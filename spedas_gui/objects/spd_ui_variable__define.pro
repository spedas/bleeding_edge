;+ 
;NAME: 
; spd_ui_variable__define
;
;PURPOSE:  
; Variable object, displayed at bottom of window
;
;CALLING SEQUENCE:
; variable = Obj_New("SPD_UI_VARIABLE")
;
;INPUT:
; none
;
;ATTRIBUTES:
; fieldName       name of variable to be displayed
; controlName     name of variable to be used for control
; text            text object for this variable
; symbol          numeric symbols 0=none, 1=degrees, 2=seconds, 3=minutes
; format          numeric formatting style (e.g. 12.34, 1.23e4)
; minRange        the minimum range for the variable
; maxRange        the maximum range for the variable 
; scaling         the type of scaling used with the variable 0:Linear,1 Log10, 2:LogN
; useRange        0 = auto,1= user defined,2 = xrange from panel
;
;OUTPUT:
; variable object reference
;
;METHODS:
; SetProperty   procedure to set keywords 
; GetProperty   procedure to get keywords 
; GetAll        returns the entire structure
; GetSymbols    returns array symbol names
; GetSymbol     returns a symbol name given an index
; Copy          clone the object
; 
;HISTORY:
;
;NOTES:
;  Methods: GetProperty,SetProperty,GetAll,SetAll are now managed automatically using the parent class
;  spd_ui_getset.  You can still call these methods when using objects of type spd_ui_variable, and
;  call them in the same way as before
;
;
;
;$LastChangedBy: egrimes $
;$LastChangedDate: 2015-07-13 16:07:09 -0700 (Mon, 13 Jul 2015) $
;$LastChangedRevision: 18115 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/spedas_gui/objects/spd_ui_variable__define.pro $
;-----------------------------------------------------------------------------------



FUNCTION SPD_UI_VARIABLE::Copy
   out = Obj_New("SPD_UI_VARIABLE",/nosave)
   selfClass = Obj_Class(self)
   outClass = Obj_Class(out)
   IF selfClass NE outClass THEN BEGIN
       dprint,  'Object classes not identical'
       RETURN, -1
   END
   Struct_Assign, self, out
   ; newText=Obj_New("SPD_UI_TEXT")
   IF Obj_Valid(self.text) THEN newText=self.text->Copy() ELSE $
      newText=Obj_New()
   if obj_valid(newText) then out->SetProperty, Text=newText
   RETURN, out
END ;--------------------------------------------------------------------------------


FUNCTION SPD_UI_VARIABLE::GetSymbols
RETURN, ['none', 'degrees', 'seconds', 'minutes']
END ;--------------------------------------------------------------------------------


;this routine will update references to a data quantity
;This should be used if a name has changed while traces are
;already in existence .
;arguments should be two arrays of strings, with the arrays being of equal length
;changed will be set to 1 if a value is changed
pro spd_ui_variable::updatedatareference,oldnames,newnames,changed=changed

  compile_opt idl2

  changed=0
  
  self->getProperty,fieldname=fieldname,controlname=controlname
  
  idx = where(fieldname eq oldnames,c)
  
  if c then begin
    changed = 1
    self->setProperty,fieldname=newnames[idx]
  endif
  
  idx = where(controlname eq oldnames,c)
  
  if c then begin
    changed = 1
    self->setProperty,controlname = newnames[idx]
  endif
  
end
  

FUNCTION SPD_UI_VARIABLE::GetFormats,istime=istime

if ~keyword_set(istime) then self->GetProperty,istime=istime

if ~istime then begin
formats = [ '1234 (rounded down)', '1.', '1.2', '1.23', '1.234', '1.1234', $
            '1.01234', '1.001234','1.0001234','1.00001234','1.000001234']
;  formats = ['d(1234)', 'f0(1234.)' , 'f1(123.4)', 'f2(12.34)', 'f3(1.234)', 'f4(0.1234)', $
;  'f5(0.01234)', 'f6(0.001234)', 'e0(1.e+04)', 'e1(1.2e+04)', 'e2(1.23e+04)', 'e3(0.123e+04)', $
;  'e4(0.0123e+04)', 'e5(0.00123e+04)', 'e6(0.000123e+04)']
endif else begin
  formats = ['date', 'date:h:m', 'date:h:m:s', $
  'date:h:m:s.ms', 'h:m', 'h:m:s', 'h:m:s.ms', 'mo:day', 'mo:day:h:m', 'doy', 'doy:h:m', $
  'doy:h:m:s', 'doy:h:m:s.ms', 'year:doy', 'year:doy:h:m', 'year:doy:h:m:s', 'year:doy:h:m:s.ms']
endelse
RETURN, FORMATS
END ;--------------------------------------------------------------------------------



FUNCTION SPD_UI_VARIABLE::GetFormat, index
   IF N_Elements(index) EQ 0 THEN RETURN, 0
   IF NOT Is_Numeric(index) THEN RETURN, 0
   IF index LT 0 THEN RETURN, 0
   formats=self->GetFormats()
RETURN, formats(index)
END ;--------------------------------------------------------------------------------



FUNCTION SPD_UI_VARIABLE::GetSymbol, index
   IF NOT Is_Numeric(index) THEN RETURN, 0
   IF index LT 0 OR index GT 3 THEN RETURN, 0
   units=self->GetSymbols()
RETURN, units(index)
END ;--------------------------------------------------------------------------------

PRO SPD_UI_VARIABLE::Save             

  copy = self->copy()
  if ptr_valid(self.origsettings) then begin
    ptr_free,self.origsettings
  endif
  self.origsettings = ptr_new(copy->getAll())
  obj_destroy, copy
      
  RETURN
END ;--------------------------------------------------------------------------------

PRO SPD_UI_VARIABLE::Reset

  if ptr_valid(self.origsettings) then begin
    self->setAll,*self.origsettings
    self->save
  endif

RETURN
END ;--------------------------------------------------------------------------------



PRO SPD_UI_VARIABLE::Cleanup
    Obj_Destroy, self.text
    RETURN
END ;--------------------------------------------------------------------------------



FUNCTION SPD_UI_VARIABLE::Init,    $
      FieldName=fieldname,         $ ; name of variable to be displayed
      ControlName=controlname,     $ ; name of variable used as control
;      color=color,                 $ ; color to display variable
      includeUnits=includeUnits,   $ ; flag to display units
      Text=text,                   $ ; text object for this variable
      Symbol=symbol,               $ ; numeric symbols 0=none, 1=degrees, 2=seconds, 3=minutes
      Format=format,               $ ; numeric formatting style (e.g. 12.34, 1.23e4)
      isTime=isTime,               $ ; flag indicates whether numeric format code or time format code is used
      minRange=minRange,           $ ; the minimum range for the variable control
      maxRange=maxRange,           $ ; the maximum range for the variable control
      scaling=scaling,             $ ; the type of scaling used with the variable 0:Linear,1 Log10, 2:LogN
      useRange=useRange,           $ ; 0 = auto,1= user defined,2 = xrange from panel
      annotateExponent=annotateExponent, $;0=default annotation, 1=always double format, 2 = always exp format
      Debug=debug,                 $ ; flag to debug
      nosave=nosave                  ; don't save copy on startup
      
   Catch, theError
   IF theError NE 0 THEN BEGIN
      Catch, /Cancel
      ok = Error_Message(Traceback=Keyword_Set(debug))
      RETURN, 0
   ENDIF

      ; Check that all parameters have values

   IF N_Elements(fieldname) EQ 0 THEN fieldname = ''
   IF N_Elements(controlname) EQ 0 THEN controlname = ''
;   IF N_Elements(color) EQ 0 THEN color = [0,0,0]
   IF N_Elements(includeunits) EQ 0 THEN includeunits = 0
   IF NOT Obj_Valid(text) THEN text = Obj_New("SPD_UI_TEXT")
   IF N_Elements(symbol) EQ 0 THEN symbol = 0
   if n_elements(isTime) eq 0 then isTime = 0
   
   IF N_Elements(format) EQ 0 THEN begin
   
     if isTime then begin
       format = 5
     endif else begin
       format = 2
     endelse
   
   endif
   
   if n_elements(minRange) eq 0 then minRange = 0D
   if n_elements(maxRange) eq 0 then maxRange = 0D
   if n_elements(scaling) eq 0 then scaling = 0B
   if n_elements(useRange) eq 0 then useRange = 2B
   if n_elements(annotateExponent) eq 0 then annotateExponent=0

      ; Set all parameters

   self.fieldName = fieldname
   self.controlName = controlname
;   self.color = color 
   self.includeunits = includeunits
   self.text = text
   self.symbol = symbol
   self.format = format
   self.isTime = isTime
   self.minRange = minRange
   self.maxRange = maxRange
   self.scaling = scaling
   self.useRange = useRange
           
   if ~keyword_set(nosave) then begin      
     self->save
   endif 
   
RETURN, 1
END ;--------------------------------------------------------------------------------

PRO SPD_UI_VARIABLE__DEFINE

   struct = { SPD_UI_VARIABLE,  $

        fieldName: '',      $ ; name of variable
        controlName: '',    $ ; name of variable to be used for control
;        color : [0,0,0],    $ ; color to display variable
        includeUnits : 0,   $ ; flag to display units
        text: Obj_New(),    $ ; text object for this variable
        symbol: 0,          $ ; numeric symbols 0=none, 1=degrees, 2=seconds, 3=minutes 
        format: 0,          $ ; numeric formatting style (e.g. 12.34, 1.23e4)
        isTime:0B,          $ ; flag indicates whether numeric format code or time format code is used
        origSettings: ptr_New(), $ ; saves the original values of this object
        minRange:0D,        $ ; the minimum range for the variable control
        maxRange:0D,        $ ; the maximum range for the variable control
        scaling:0B,         $ ; the type of scaling used with the variable 0:Linear,1 Log10, 2:LogN
        useRange:0B,         $ ; 0 = auto,1= user defined,2 = xrange from panel
        annotateExponent:0, $;0=default annotation, 1=always double format, 2 = always exp format
        INHERITS SPD_UI_READWRITE, $ ; generalized read/write methods
        inherits spd_ui_getset $ ; generalized getProperty,setProperty,getAll,setAll methods
}

END ;--------------------------------------------------------------------------------
