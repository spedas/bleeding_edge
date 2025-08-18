;+ setall
;NAME: 
; spd_ui_line_settings__define
;
;PURPOSE:  
; line properties is an object that holds all of the settings necessary for 
; plotting a line as specified in the Trace Properties Line panel
;
;CALLING SEQUENCE:
; lineSettings = Obj_New("SPD_UI_LINE_SETTINGS")
;
;INPUT:
; none
;
;KEYWORDS:
; dataX             string naming X component of line
; dataY             string naming Y component of line
; mirrorLine        flag to mirror line
; lineStyle         line style object
; drawBetweenPts    flag set if separation attributes should be used(ie NOT drawBetweenpts)
; separatedBy       number of point separation
; separatedUnits    0=sec, 1=min, 2=hrs, 3=days 
; symbol            symbol object
; plotPoints,       all,1st/Last,1st,Last,MajorTick,EveryN                                      
; everyOther        number for every N points                         
; positiveEndPt     variable name for positive endPt
; negativeEndPt     variable name for negative endPt
; positiveEndRel    flag if relative to line
; negativeEndRel    flag if relative to line
; barLine           bar line style object
; MarkSymbol        mark symbol object
; debug=debug       set to debug 
;
;OUTPUT:
; line property object reference
;
;METHODS:
; SetProperty    procedure to set keywords 
; GetProperty    procedure to get keywords 
; GetAll         returns the entire structure
; GetPlotOptions returns string array of plot options
; GetPlotOption  returns name of plot option given an index
; GetUnits       returns string array of unit options
; GetUnit        returns name of unit given an index
;
;
;NOTES:
;  Methods: GetProperty,SetProperty,GetAll,SetAll are now managed automatically using the parent class
;  spd_ui_getset.  You can still call these methods when using objects of type spd_ui_line_settings, and
;  call them in the same way as before
;
;HISTORY:
;
;$LastChangedBy:pcruce $
;$LastChangedDate:2009-09-10 09:15:19 -0700 (Thu, 10 Sep 2009) $
;$LastChangedRevision:6707 $
;$URL:svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/thmsoc/trunk/idl/spedas/spd_ui/objects/spd_ui_line_settings__define.pro $
;-----------------------------------------------------------------------------------



FUNCTION SPD_UI_LINE_SETTINGS::Copy
   out = Obj_New("SPD_UI_LINE_SETTINGS",/nosave)
   selfClass = Obj_Class(self)
   outClass = Obj_Class(out)
   IF selfClass NE outClass THEN BEGIN
       dprint,  'Object classes not identical'
       RETURN, 1
   END
   Struct_Assign, self, out
   ;newLineStyle=Obj_New("SPD_UI_LINE_STYLE")
   IF Obj_Valid(self.lineStyle) THEN newLineStyle=self.LineStyle->Copy() ELSE $
      newLineStyle=Obj_New()
   out->SetProperty, LineStyle=newLineStyle
   ;newSymbol=Obj_New("SPD_UI_SYMBOL")
   IF Obj_Valid(self.symbol) THEN newSymbol=self.symbol->Copy() ELSE $
      newSymbol=Obj_New()
   out->SetProperty, Symbol=newSymbol
   ;newBarLine=Obj_New("SPD_UI_LINE_STYLE")
   IF Obj_Valid(self.barLine) THEN newBarLine=self.barLine->Copy() ELSE $
      newBarLine=Obj_New()
   out->SetProperty, BarLine=newBarLine
   ; newMarkSymbol=Obj_New("SPD_UI_SYMBOL")
   IF Obj_Valid(self.markSymbol) THEN newMarkSymbol=self.markSymbol->Copy() ELSE $
      newMarkSymbol=Obj_New()
   out->SetProperty, MarkSymbol=newMarkSymbol
   RETURN, out
END ;--------------------------------------------------------------------------------


function spd_ui_line_settings::getPtSpacing

  compile_opt idl2
  
  if self.separatedUnits eq 1 then begin
    return,self.separatedBy * 60D
  endif else if self.separatedUnits eq 2 then begin
    return,self.separatedBy * 60D * 60D
  endif else if self.separatedUnits eq 3 then begin
    return,self.separatedBy * 60D * 60D * 24D
  endif else begin
    return,self.separatedBy
  endelse

end

;this routine will update references to a data quantity
;This should be used if a name has changed while traces are
;already in existence .
;arguments should be two arrays of strings, with the arrays being of equal length
;changed will be set to 1 if a value is changed
pro spd_ui_line_settings::updatedatareference,oldnames,newnames,changed=changed

  compile_opt idl2

  changed=0
  
  self->getProperty,datax=datax,datay=datay
  
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
  
end
  
  

FUNCTION SPD_UI_LINE_SETTINGS::GetUnits
RETURN, ['sec', 'minutes', 'hours', 'days', '', '<none>'] 
END ;--------------------------------------------------------------------------------



FUNCTION SPD_UI_LINE_SETTINGS::GetUnit, index
   IF N_Elements(index) EQ 0 THEN RETURN, 0
   IF NOT Is_Numeric(index) THEN RETURN, 0
   IF index LT 0 OR index GT 5 THEN RETURN, 0
   units=self->GetUnits()
RETURN, units(index)
END ;--------------------------------------------------------------------------------


FUNCTION SPD_UI_LINE_SETTINGS::GetPlotOptions
RETURN, ['All Points', 'First and Last Points', 'First Point', 'Last Point', 'Major Ticks', 'Every']
END ;--------------------------------------------------------------------------------



FUNCTION SPD_UI_LINE_SETTINGS::GetPlotOption, index
  IF N_Elements(index) EQ 0 THEN RETURN, 0
  IF NOT Is_Numeric(index) THEN RETURN, 0
  IF index LT 0 OR index GT 5 THEN RETURN, 0
  options=self->GetPlotOptions()
RETURN, options(index)
END ;--------------------------------------------------------------------------------

PRO SPD_UI_LINE_SETTINGS::Save

 copy = self->copy()
  if ptr_valid(self.origsettings) then begin
    ptr_free,self.origsettings
  endif
  self.origsettings = ptr_new(copy->getall())
      
RETURN
   END ;--------------------------------------------------------------------------------

PRO SPD_UI_LINE_SETTINGS::Reset

   if ptr_valid(self.origsettings) then begin
    self->setall,*self.origsettings
    self->save
   endif

END ;--------------------------------------------------------------------------------

FUNCTION SPD_UI_LINE_SETTINGS::Init,           $
              dataX=dataX,                       $ ; string x component of trace
              dataY=dataY,                       $ ; string y component of trace 
              MirrorLine=mirrorline,             $ ; flag to mirror line
              LineStyle=linestyle,               $ ; line style object
              DrawBetweenPts=drawbetweenpts,     $ ; flag to draw line between points 
              SeparatedBy=separatedby,           $ ; number of point separation
              SeparatedUnits=separatedunits,     $ ; 0=sec, 1=min, 2=hrs, 3=days, 4=none 
              Symbol=symbol,                     $ ; symbol object
              PlotPoints=plotpoints,             $ ; 0=All,1=1st/Last,2=1st,3=Last,4=MajorTick,5=EveryN                                      
              EveryOther=everyother,             $ ; number for every N points                         
              PositiveEndPt=positiveendpt,       $ ; variable name for positive endPt
              NegativeEndPt=negativeendpt,       $ ; variable name for negative endPt
              PositiveEndRel=positiveendrel,     $ ; flag if relative to line
              NegativeEndRel=negativeendrel,     $ ; flag if relative to line
              BarLine=barline,                   $ ; line style object for bar line
              MarkSymbol=marksymbol,             $ ; mark symbol object 
              Debug=debug,                       $ ; flag to debug
              nosave=nosave                        ; will not save copy on startup

   Catch, theError
   IF theError NE 0 THEN BEGIN
      Catch, /Cancel
      ok = Error_Message(Traceback=Keyword_Set(debug))
      RETURN, 0
   ENDIF
  
   ; Check that all parameters have values
   
   IF N_Elements(dataX) EQ 0 THEN dataX = ''
   IF N_Elements(dataY) EQ 0 THEN dataY = '' 
   
   IF N_Elements(separatedby) EQ 0 THEN separatedby = 0
   IF N_Elements(separatedunits) EQ 0 THEN BEGIN
      separatedunits = 0
   ENDIF ELSE BEGIN
      IF separatedunits LT 0 OR separatedunits GT 4 THEN RETURN, 0
   ENDELSE
   IF N_Elements(plotpoints) EQ 0 THEN BEGIN
      plotpoints = 0
   ENDIF ELSE BEGIN
      IF plotpoints LT 0 OR plotpoints GT 5 THEN RETURN, 0
   ENDELSE
   IF N_Elements(everyother) EQ 0 THEN everyother=1
   IF N_Elements(positiveendpt) EQ 0 THEN positiveendpt=''
   IF N_Elements(negativeendpt) EQ 0 THEN negativeendpt=''
   
   mirrorline = Keyword_Set(mirrorline)
   
   if n_elements(drawbetweenpts) eq 0 then drawBetweenpts = 0
   positiveendrel = Keyword_Set(positiveendrel)
   negativeendrel = Keyword_Set(negativeendrel)
   
   IF NOT Obj_Valid(linestyle)THEN linestyle = Obj_New("SPD_UI_LINE_STYLE")
   IF NOT Obj_Valid(symbol)THEN symbol = Obj_New("SPD_UI_SYMBOL")
   IF NOT Obj_Valid(barline)THEN barline = Obj_New("SPD_UI_LINE_STYLE", show=0)
   IF NOT Obj_Valid(marksymbol)THEN marksymbol = Obj_New("SPD_UI_LINE_STYLE")

  ; Set all parameters

   self.dataX = dataX
   self.dataY = dataY
   self.mirrorLine = mirrorline             
   self.lineStyle = linestyle               
   self.drawBetweenPts = drawbetweenpts    
   self.separatedBy = separatedby          
   self.separatedUnits = separatedunits     
   self.symbol = symbol                  
   self.plotPoints = plotpoints                                      
   self.everyOther = everyother                              
   self.positiveEndPt = positiveendpt       
   self.negativeEndPt = negativeendpt       
   self.positiveEndRel = positiveendrel 
   self.negativeEndRel =negativeendrel
   self.barLine = barline                   
   self.markSymbol = marksymbol            
  
   
   if ~keyword_set(nosave) then begin      
      self->save
   endif 
  
   RETURN, 1
                 
END ;--------------------------------------------------------------------------------

PRO SPD_UI_LINE_SETTINGS__DEFINE

   struct = { SPD_UI_LINE_SETTINGS, $

              dataX : '',             $ ; string naming x component of line
              dataY : '',             $ ; string naming y component of line
                 ; Line Properties
                 
              lineStyle : Obj_New(),  $ ; line style object
              mirrorLine : 0,         $ ; flag to mirror line
              drawBetweenPts: 0,      $ ; flag set if separation arguments should be used
              separatedBy: 0D,         $ ; number of point separation
              separatedUnits: 0,      $ ; 0=sec, 1=min, 2=hrs, 3=days, 4=none 
                    
                  ; Symbol Properties
                  
              symbol : Obj_New(),     $ ; symbol style, size, color
              plotPoints: 0,          $ ; 0=all,1=1st/Last,2=1st,3=Last,4=MajorTick,5=EveryN                                      
              everyOther: 0,          $ ; number for every N points                         
              
                   ; Bar Properties

              barLine : Obj_New(),    $ ; line style of bar 
              positiveEndPt: '',      $ ; variable name for positive endPt
              negativeEndPt: '',      $ ; variable name for negative endPt
              positiveEndRel: 0,      $ ; flag if relative to line
              negativeEndRel: 0,      $ ; flag if relative to line
              markSymbol: Obj_New(),  $ ; bar, circle, diamond, triangle, cross
              
                   ;Original Settings
              
              origsettings: ptr_New(), $  ;pointer to original settings in case of reset
              INHERITS SPD_UI_READWRITE, $ ; generalized read/write methods
              inherits spd_ui_getset $  ;generalized getProperty,setProperty,getAll,setAll methods
                     
}

END
