;+ 
;NAME: 
; spd_ui_zaxis_settings__define
;
;PURPOSE:  
; zaxis_settings is an object that holds all of the settings necessary for 
; spectral data plots that are common to the entire panel
;
;CALLING SEQUENCE:
; zaxisSettings = Obj_New("SPD_UI_ZAXIS_SETTINGS")
;
;INPUT:
; none
;
;KEYWORDS:

; xAxisIndex         flag to index x axis
; yAxisIndex         flag to index y axis
; colorTable         droplist value of color tables
; minRange           minimum range value 
; maxRange           maximum range value 
; fixed              flag to use fixed min/max values
; tickNum            the number of z-axis ticks
; minorTickNum       the number of minor ticks between majors
; logMinorTickType   full-interval,first-magnitude,last-magnitude,even-spacing 
; annotationStyle    droplist value for annotation style
; annotateTextObject a text object to indicate the size,color,font,format of the annotation text 
; annotationOrientation flag indicating horizontal or vertical annotations 0=horizontal, 1=vertical
; annotateExponent   Flag indicates whether to force annotations into an exponential format.  0: default behavior, 1: Always exponential, 2: Never exponential                   
; labelTextObject a text object to indicate the size,color,font,format of the label text - this is being treated as the z title
; subtitleTextObject a text object for the subtitle
; labelOrientation flag indicating horizontal/vertical text
; labelMargin in number of pts 
; lazylabels         flag indicating if underscores will be converted to carriage returns
; scaling            0=Linear, 1=Log10, 2= Natural Log
; placement          droplist value of placement location
; margin             number of points between plot & zaxis
; showFrequencies    flag to show frequencies
; frequencyMin       minimum value for showing frequencies 
; frequencyMax       maximum value for showing frequencies 
; autoticks          direct the draw object to make decisions about tick positioning automatically, and mutate axis object settings                                              
  
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
;  spd_ui_getset.  You can still call these methods when using objects of type spd_ui_zaxis_settings, and
;  call them in the same way as before
;
;$LastChangedBy:pcruce $
;$LastChangedDate:2009-09-10 09:15:19 -0700 (Thu, 10 Sep 2009) $
;$LastChangedRevision:6707 $
;$URL:svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/thmsoc/trunk/idl/spedas/spd_ui/objects/spd_ui_zaxis_settings__define.pro $
;-----------------------------------------------------------------------------------



FUNCTION SPD_UI_ZAXIS_SETTINGS::Copy
   out = Obj_New("SPD_UI_ZAXIS_SETTINGS", /nosave)
   selfClass = Obj_Class(self)
   outClass = Obj_Class(out)
   IF selfClass NE outClass THEN BEGIN
       dprint,  'Object classes not identical'
       RETURN, -1
   END
   Struct_Assign, self, out   
   ;newLabel=Obj_New("SPD_UI_TEXT")
   IF Obj_Valid(self.labelTextObject) THEN newLabel=self.labelTextObject->Copy() ELSE $
      newLabel=Obj_New()
   out->SetProperty, LabelTextObject=newLabel
   ;newsubtitle=Obj_New("SPD_UI_TEXT")
   IF Obj_Valid(self.subtitleTextObject) THEN newsubtitle=self.subtitleTextObject->Copy() ELSE $
      newsubtitle=Obj_New()
   out->SetProperty, subtitleTextObject=newsubtitle
   ;newAnnotate=Obj_New("SPD_UI_TEXT")
   IF Obj_Valid(self.annotateTextObject) THEN newAnnotate=self.annotateTextObject->Copy() ELSE $
      newAnnotate=Obj_New()
   out->SetProperty, AnnotateTextObject=newAnnotate  
   RETURN, out
END ;--------------------------------------------------------------------------------


PRO SPD_UI_ZAXIS_SETTINGS::Save

  copy = self->copy()
  if ptr_valid(self.origsettings) then begin
    ptr_free,self.origsettings
  endif
  self.origsettings = ptr_new(copy->getall()) 
  obj_destroy, copy
RETURN    
END ;--------------------------------------------------------------------------------



PRO SPD_UI_ZAXIS_SETTINGS::Reset

   if ptr_valid(self.origsettings) then begin
    self->setall,*self.origsettings
    self->Save
   endif

END ;--------------------------------------------------------------------------------


FUNCTION SPD_UI_ZAXIS_SETTINGS::GetPlacements
RETURN, ['Top', 'Bottom', 'Left', 'Right', 'Do Not Show ColorBar']
END ;--------------------------------------------------------------------------------



FUNCTION SPD_UI_ZAXIS_SETTINGS::GetPlacement, index
   IF N_Elements(index) EQ 0 THEN RETURN, 0
   IF NOT Is_Numeric(index) THEN RETURN, 0
   IF index LT 0 OR index GT 5 THEN RETURN, 0
   placements = self->GetPlacements()
RETURN, placements[index]
END ;--------------------------------------------------------------------------------



FUNCTION SPD_UI_ZAXIS_SETTINGS::GetColorTables
RETURN, ['Rainbow', 'Cool', 'Hot', 'Copper', 'Extreme Hot-Cold', 'Gray','SPEDAS']
END ;--------------------------------------------------------------------------------



FUNCTION SPD_UI_ZAXIS_SETTINGS::GetColorTableNumber, index
   IF N_Elements(index) EQ 0 THEN index = self.colorTable
   IF NOT Is_Numeric(index) THEN RETURN, 0
   IF index LT 0 OR index GT 6 THEN RETURN, 0
   RETURN, index
END ;--------------------------------------------------------------------------------




FUNCTION SPD_UI_ZAXIS_SETTINGS::GetColorTable, index
   IF N_Elements(index) EQ 0 THEN RETURN, 0
   IF NOT Is_Numeric(index) THEN RETURN, 0
   IF index LT 0 OR index GT 5 THEN RETURN, 0
   colorTables = self->GetColorTables()
RETURN, colorTables[index]
END ;--------------------------------------------------------------------------------



FUNCTION SPD_UI_ZAXIS_SETTINGS::GetAnnotations
return, [ '1234 (rounded down)', '1.', '1.2', '1.23', '1.234', '1.1234', $
            '1.01234', '1.001234','1.0001234','1.00001234','1.000001234']
;RETURN, ['d(1234)', 'f0(1234)', 'f1(123.4)', 'f2(12.34)', 'f3(1.234)', 'f4(0.1234)', $
;   'f5(0.01234)', 'f6(0.001234)', 'e0(123e4)', 'e1(12.3e4)', 'e2(1.23e4)', $
;   'e3(0.123e4)', 'e4(0.01234)', 'e5(0.001234)', 'e6(0.0001234)']
END ;--------------------------------------------------------------------------------



FUNCTION SPD_UI_ZAXIS_SETTINGS::GetAnnotation, index
   IF N_Elements(index) EQ 0 THEN RETURN, 0
   IF NOT Is_Numeric(index) THEN RETURN, 0
   IF index LT 0 OR index GT 5 THEN RETURN, 0
   annotations = self->GetAnnotations()
RETURN, annotations[index]
END ;--------------------------------------------------------------------------------

;pro spd_ui_zaxis_settings::setTouched
;
;  if ~self->equalTolerance((*self.origsettings).minRange,self.minRange) then self.touchedMinRange=1  
;  if ~self->equalTolerance((*self.origsettings).maxRange,self.maxRange) then self.touchedmaxRange=1
;  if (*self.origsettings).fixed ne self.fixed then self.touchedfixed = 1
;  if (*self.origsettings).ticknum ne self.ticknum then self.touchedticknum = 1
;  if (*self.origsettings).minorticknum ne self.minorticknum then self.touchedminorticknum = 1
;  if (*self.origsettings).touchedautoticks ne self.minorticknum then self.touchedminorticknum = 1
;  
;end
PRO SPD_UI_ZAXIS_SETTINGS::Cleanup
    obj_destroy, self.annotateTextObject
    obj_destroy, self.labelTextObject
    obj_destroy, self.subtitleTextObject
    ptr_free, self.origsettings
    RETURN
END

FUNCTION SPD_UI_ZAXIS_SETTINGS::Init, $
                                  xAxisIndex=xAxisIndex, $
                                  yAxisIndex=yAxisIndex, $
                                  colorTable=colorTable,$
                                  minRange=minRange,$
                                  maxRange=maxRange,$
                                  fixed=fixed,$
                                  tickNum=tickNum,$
                                  minorTickNum=minorTickNum,$
                                  logMinorTickType=logMinorTickType,$
                                  annotationStyle=annotationStyle,$
                                  annotateTextObject=annotateTextObject,$
                                  annotationOrientation=annotationOrientation,$
                                  annotateExponent=annotateExponent,     $ ;  Flag indicates whether to force annotations into an exponential format.  0: default behavior, 1: Always exponential, 2: Never exponential                   
                                  labelTextObject=labelTextObject,$
                                  subtitleTextObject=subtitleTextObject,$
                                  labelOrientation=labelOrientation,$
                                  labelMargin=labelMargin,$
                                  lazylabels=lazylabels,$
                                  scaling=scaling,$
                                  placement=placement,$
                                  margin=margin,$
                                  showFrequencies=showFrequencies,$
                                  frequencyMin=frequencyMin,$
                                  frequencyMax=frequencyMax, $       
                                  autoticks=autoticks,       $       ; direct the draw object to make decisions about tick positioning automatically, and mutate axis object settings                                                                      
                                  nosave=nosave
                                  
  if n_elements(xAxisIndex) eq 0 then xAxisIndex = 0
  if n_elements(yAxisIndex) eq 0 then yAxisIndex = 0
  if n_elements(colorTable) eq 0 then colorTable = 0
  if n_elements(minRange) eq 0 then minRange = 0
  if n_elements(maxRange) eq 0 then maxRange = 0
  if n_elements(fixed) eq 0 then fixed = 0
  if n_elements(tickNum) eq 0 then tickNum = 0
  if n_elements(minorTickNum) eq 0 then minorTickNum = 0
  if n_elements(logMinorTickType) eq 0 then logMinorTickType = 1
  if n_elements(annotationStyle) eq 0 then annotationStyle = 0
  if n_elements(annotateTextObject) eq 0 then annotateTextObject = obj_new()
  if n_elements(annotationOrientation) eq 0 then annotationOrientation = 0
  if n_elements(annotateExponent) eq 0 then annotateExponent = 0
  if n_elements(labelTextObject) eq 0 then labelTextObject = obj_new()
  if n_elements(subtitleTextObject) eq 0 then subtitleTextObject = obj_new()
  if n_elements(labelOrientation) eq 0 then labelOrientation = 0
  if n_elements(labelMargin) eq 0 then labelMargin = 0
  if n_elements(lazylabels) eq 0 then lazylabels = 1
  if n_elements(scaling) eq 0 then scaling = 0
  if n_elements(placement) eq 0 then placement = 0
  if n_elements(margin) eq 0 then margin = 0
  if n_elements(showFrequencies) eq 0 then showFrequencies = 0
  if n_elements(frequencyMin) eq 0 then frequencyMin = 0
  if n_elements(frequencyMax) eq 0 then frequencyMax = 0
  
  self.xAxisIndex = xAxisIndex
  self.yAxisIndex = yAxisIndex
  self.colorTable = colorTable
  self.minRange = minRange
  self.maxRange = maxRange
  self.fixed = fixed
  self.tickNum = tickNum
  self.minorTickNum = minorTickNum
  self.logMinorTickType = logMinorTickType
  self.annotationStyle = annotationStyle
  self.annotateTextObject = annotateTextObject
  self.annotationOrientation = annotationOrientation
  self.annotateExponent = annotateExponent
  self.labelTextObject = labelTextObject
  self.subtitleTextObject = subtitleTextObject
  self.labelOrientation = labelOrientation
  self.labelMargin = labelMargin
  self.lazylabels = lazylabels
  self.scaling = scaling
  self.placement = placement
  self.margin = margin
  self.showFrequencies = showFrequencies
  self.frequencyMin = frequencyMin
  self.frequencyMax = frequencyMax
  
  if n_elements(autoticks) eq 0 then autoticks = 1
  self.autoticks = autoticks

  if n_elements(nosave) EQ 0 then begin      
      self->save
  endif 
                
RETURN, 1
END ;--------------------------------------------------------------------------------

PRO SPD_UI_ZAXIS_SETTINGS__DEFINE

   struct = { SPD_UI_ZAXIS_SETTINGS,$
              xAxisIndex     : 0,       $ ; flag to index x axis
              yAxisIndex     : 0,       $ ; flag to index y axis
              colorTable     : 0,       $ ; droplist value of color tables
              minRange       : 0.0D,    $ ; minimum range value 
              touchedminrange : 0b,      $ ; indicated minrange field has been explicitly modified by the user     
              maxRange       : 0.0D,    $ ; maximum range value 
              touchedmaxrange : 0b,      $ ; indicated maxrange field has been explicitly modified by the user   
              fixed          : 0,       $ ; flag to indicate that fixed range is being used
              touchedfixed : 0b,      $ ; indicated fixed field has been explicitly modified by the user   
              tickNum        : 0,       $ ; the number of ticks on the z-axis
              touchedticknum : 0b,      $ ; indicated ticknum field has been explicitly modified by the user
              minorTickNum   : 0,       $ ; the number of minor ticks between major ticks
              logMinorTickType:0l,      $ ; type of logarithmic minor tick 0,1,2, or 3
              touchedminorticknum : 0b,      $ ; indicated minorticknum field has been explicitly modified by the user
              annotationStyle: 0,       $ ; droplist value for annotation style
              annotateTextObject:Obj_new(), $ ;text object for style of zaxis annotations
              annotationOrientation: 0, $ ; flag indicating horizontal or vertical annotation orientation
              annotateExponent:0 ,      $ ; Flag indicates whether to force annotations into an exponential format.  0: default behavior, 1: Always exponential, 2: Never exponential                   
              labelTextObject: Obj_new(), $ ; a text object indicating the text/color/font/format/size of the label - this is now treated as the title for the z axis
              subtitleTextObject: Obj_new(), $ ; a text object indicating the text/color/font/format/size of the subtitle
              labelOrientation: 0,      $ ; flag indicating horizontal or vertical label orientation
              labelMargin: 0,           $ ; the margin between the label and the axis in points 
              lazylabels: 0,            $ ; flag indicating if underscores will be converted to carriage returns
              scaling        : 0,       $ ; 0=Linear, 1=Log10, 2 = Natural Log
              touchedscaling : 0b,      $ ; indicated scaling field has been explicitly modified by the user       
              placement      : 0,       $ ; droplist value of placement location
              touchedplacement: 0b,     $ ; Indicates whether placement field was explicitly modified by the user
              margin         : 0,       $ ; margin of spacing between plot and zaxis in pts
              showFrequencies: 0,       $ ; flag to show frequencies
              frequencyMin   : 0,       $ ; minimum value for showing frequencies 
              frequencyMax   : 0,       $ ; maximum value for showing frequencies
              autoticks      : 0,       $ ; direct the draw object to make decisions about tick positioning automatically, and mutate axis object settings     
              touchedautoticks : 0b,      $ ; indicated autoticks field has been explicitly modified by the user                               
              origsettings: ptr_New(),  $ ;pointer to original settings in case of reset
              INHERITS SPD_UI_READWRITE, $ ; generalized read/write methods
              inherits spd_ui_getset $ ; generalized setProperty/getProperty/getAll/setAll methods
                                     
}

END
