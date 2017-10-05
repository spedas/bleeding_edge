;+ 
;NAME: 
; spd_ui_axis_settings__define
;
;PURPOSE:  
; axis properties is an object that holds all of the settings necessary for 
; plotting a axis as specified in the Trace Properties Line panel
;
;CALLING SEQUENCE:
; axisSettings = Obj_New("SPD_UI_AXIS_SETTINGS")
;
;INPUT: 
; none
;
;ATTRIBUTES:
; rangeOption           range options (auto, floating, fixed)
; touchedRangeOption   has the user modified the rangeOption field
; scaling               axis scaling (linear, log10, natural)
; touchedScaling       has the user modified the scaling field
; equalXYScaling        flag set if equal X & Y axis scaled 
; isTimeAxis            flag set if axis is time based
; touchedIsTimeAxis    has the user modified the isTimeAxis field
; rangeMargin           if auto - range margin
; boundScaling          flag set if auto scaling is bound
; boundfloating         flag set if bounded floating range is used
; minFixedRange         min range value if fixed scaling
; touchedMinFixedRange  has the user modified the minFixedRange
; maxFixedRange         max range value if fixed scaling
; touchedMaxFixedRange  has the user modified the maxFixedRange
; minFloatRange         min range bound if floating range
; maxFloatRange         max range bound if floating range
; minBoundRange         min range bound if using bounded autoscaling
; maxBoundRange         max range bound if using bounded autoscaling
; floatingSpan          value of span if floating
; floatingCenter        floating center options (mean, median, appr. mean/median)
; majorTickEvery        display major ticks every 
; minorTickEvery        display major ticks every 
; majorTickUnits        major tick units (sec, hr, min, day, none)
; minorTickUnits        major tick units (sec, hr, min, day, none)
; majorTickAuto         set to automatically figure out major ticks
; minorTickAuto         set to automatically figure out minor ticks
; firstTickAuto         set to automatically figure out first tick
; numMajorTicks         number of major ticks
; numMinorTicks         number of major ticks
; firstTickAt           value where first tick should be
; firstTickUnits        first tick unit (sec, hr, min, day, none)
; tickStyle             style (inside, outside, both)
; bottomPlacement       flag set if ticks should be on bottom axis
; topPlacement          flag set if ticks should be on top axis
; majorLength           length of major tick
; minorLength           length of minor tick
; logMinorTickType      For Log minor ticks, log-full-interval,log-first-magnitude,log-last-magnitude,even-spacing 
; lineAtZero            flag set if line is drawn at zero
; showdate              flag set if date strings are shown
; dateString1           string format of date for line 1
; dateString2           string format of date for line 1                                         
; dateFormat1           format of date string for annotation - line 1
; dateFormat2           format of date string for annotation - line 2
;                       format options include 'Time', 'Date', 'Year', 'Mon', 'Day', 
;                       'Hours', 'Minutes', 'Seconds', 'Day of Year'
;                       respective commands are '%time', '%date', '%year', '%mon', 
;                       '%day', '%hours', '%minutes', '%seconds', '%doy'
; annotateAxis          flag set to annotate along axis                         
; placeAnnotation       placement of annotation (bottom or top)
; annotateMajorTicks    set flag if major ticks are annotated
; annotateEvery         value where annotations occur
; annotateUnits         units for annotation value (sec, min, hr, day,none)
; firstAnnotation       value where annotation of first major tick occurs
; firstAnnotateUnits    units for major tick value (sec, min, hr, day,none)
; annotateRangeMin     set flag to annotate range min tick  
; annotateRangeMax     set flag to annotate range max tick  
; annotateStyle         format style of tick 
;                       if IsTime
;                       ['date', 'date:doy' , 'date:doy:h:m', 'date:doy:h:m:s', 'date:doy:h:m:s.ms', $
;                        'h:m', 'h:m:s', 'h:m:s.ms', 'mo:day', 'mo:day:h:m', 'doy', 'doy:h:m', $
;                        'doy:h:m:s', 'doy:h:m:s.ms', 'year:doy', 'year:doy:h:m', 'year:doy:h:m:s', $
;                        'year:doy:h:m:s.ms']
;                       otherwise
;                       ['d(1234)', 'f0(1234)' , 'f1(123.4)', 'f2(12.34)', 'f3(1.234)', 'f4(0.1234)', $
;                        'f5(0.01234)', 'f6(0.001234)', 'e0(123e4)', 'e1(12.3e4)', 'e2(1.23e4)', 'e2(0.123e4)', $
;                        'e2(0.0123e4)', 'e2(0.00123e4)', 'e2(0.000123e4)']
;
; annotateOrientation   The orientation of the annotations: 0(horizontal) & 1(vertical)
; annotateTextObject    Text object that represents that textual style of annotations
; annotateExponent      Flag indicates whether to force annotations into an exponential format.  0: default behavior, 1: Always exponential, 2: Never exponential
; majorGrid=majorgrid   linestyle object of major grid 
; minorGrid=minorgrid   linestyle object of minor grid 
; orientation           orientation of labels 0=Horizontal, 1=Vertical
; margin                number of points for label margins
; showLabels            flag for whether or not labels are displayed
; labels                A container object that stores the text objects which represent each label
; stackLabels           A flag to determine whether labels should be stacked 
; lazyLabels           A flag to determine whether underscores will be converted to carriage returns (and stacking turned off)
; blackLabels           A flag to determine whether label colors are all black 
; autoticks             direct the draw object to make decisions about tick positioning automatically, and mutate axis object settings                                              
; titleobj              text object that contains the title for the axis
; subtitleobj           text object that contains the subtitle for the axis
; placeLabel            placement of labels (left/bottom or right/top)
; placeTitle            placement of title (left/bottom 0 or right/top 1)
; titleorientation      orientation for title (0=horizontal, 1=vertical)
; titlemargin           number of points for title margin
; showtitle             flag for whether the title should be displayed (mainly to allow us to turn off titles if panels are locked and titles would overlap panels)
; lazytitles            flag to determine whether underscores in titles should be converted to carriage returns   
;
;OUTPUT:
; axis property object reference
;
;METHODS:
; SetProperty    procedure to set keywords 
; GetProperty    procedure to get keywords 
; GetAll         returns the entire structure
;
; GetUnits        returns string array of unit options
; GetUnit         returns name of unit given an index
; GetOrientations returns string array of plot options
; GetOrientation  returns name of plot option given an index
; GetPlacements   returns string array of plot options
; GetPlacement    returns name of plot option given an index
; GetRangeOptions returns string array of plot options
; GetRangeOption  returns name of plot option given an index
; GetStyles       returns string array of plot options
; GetStyle        returns name of plot option given an index
; GetScalings     returns string array of plot options
; GetScaling      returns name of plot option given an index
; GetDateFormats  returns string array of date format options
; GetDateFormat   returns the name of the date format given an index
; GetDateCommands returns array of commands for date formats
; GetDateCommand  returns a string with the date command
; GetDateString   returns a string with the actual date formatted
;                 given an index. if a time object is provided it
;                 will format the time object, otherwise it will
;                 default to the current date.
;
;HISTORY:
;
;NOTES:
;  Methods: GetProperty,SetProperty,GetAll,SetAll are now managed automatically using the parent class
;  spd_ui_getset.  You can still call these methods when using objects of type spd_ui_axis_settings, and
;  call them in the same way as before
;
;$LastChangedBy:pcruce $
;$LastChangedDate:2009-09-10 09:15:19 -0700 (Thu, 10 Sep 2009) $
;$LastChangedRevision:6707 $
;$URL:svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/thmsoc/trunk/idl/spedas/spd_ui/objects/spd_ui_axis_settings__define.pro $
;-----------------------------------------------------------------------------------


;this function integrates several different settings into a 5 element
;array with the following elements [tickStart,majorTickInterval,minorTickInterval,annotationStart,annotationInterval]
function spd_ui_axis_settings::getTickSpacing

  compile_opt idl2
  
 if self.firstTickUnits eq 1 then begin
    tickStart = self.firstTickAt*60D
  endif else if self.firstTickUnits eq 2 then begin
    tickStart = self.firstTickAt*60D*60D
  endif else if self.firstTickUnits eq 3 then begin
    tickStart = self.firstTickAt*60D*60D*24D
  endif else begin
    tickStart = self.firstTickAt
  endelse
  
  if self.majorTickUnits eq 1 then begin
    major = self.majorTickEvery*60D
  endif else if self.majorTickUnits eq 2 then begin
    major = self.majorTickEvery*60D*60D
  endif else if self.majorTickUnits eq 3 then begin
    major = self.majorTickEvery*60D*60D*24D
  endif else begin
    major = self.majorTickEvery
  endelse
  
  if self.minorTickUnits eq 1 then begin
    minor = self.minorTickEvery*60D
  endif else if self.minorTickUnits eq 2 then begin
    minor = self.minorTickEvery*60D*60D
  endif else if self.minorTickUnits eq 3 then begin
    minor = self.minorTickEvery*60D*60D*24D
  endif else begin
    minor = self.minorTickEvery
  endelse
  
  if self.firstAnnotateUnits eq 1 then begin
    first = self.firstAnnotation*60D
  endif else if self.firstAnnotateUnits eq 2 then begin
    first = self.firstAnnotation*60D*60D
  endif else if self.firstAnnotateUnits eq 3 then begin
    first = self.firstAnnotation*60D*60D*24D
  endif else begin
    first = self.firstAnnotation
  endelse
  
  if self.annotateUnits eq 1 then begin
    anno = self.annotateEvery*60D
  endif else if self.annotateUnits eq 2 then begin
    anno = self.annotateEvery*60D*60D
  endif else if self.annotateUnits eq 3 then begin
    anno = self.annotateEvery*60D*60D*24D
  endif else begin
    anno = self.annotateEvery
  endelse
  
  return, double([tickStart,major,minor,first,anno])


end

FUNCTION SPD_UI_AXIS_SETTINGS::Copy
   out = Obj_New("SPD_UI_AXIS_SETTINGS",/nosave)
   selfClass = Obj_Class(self)
   outClass = Obj_Class(out)
   IF selfClass NE outClass THEN BEGIN
       dprint,  'Object classes not identical'
       RETURN, -1
   END
   Struct_Assign, self, out
   
   if obj_valid(self.majorGrid) then begin
     newGrid=Obj_New("SPD_UI_LINE_STYLE")
     newGrid=self.majorGrid->Copy()
     out->SetProperty, MajorGrid=newGrid
   endif
   
   if obj_valid(self.minorGrid) then begin
     newGrid=Obj_New("SPD_UI_LINE_STYLE")
     newGrid=self.minorGrid->Copy()
     out->SetProperty, minorGrid=newGrid
   endif

   if obj_valid(self.annotateTextObject) then begin
      newText=Obj_New("SPD_UI_TEXT")
      newText=self.annotateTextObject->Copy()
      out->SetProperty, AnnotateTextObject=newText
   endif

   newLabels=Obj_New("IDL_Container")
   newLabel=Obj_New("SPD_UI_TEXT")
   IF Obj_Valid(self.labels) THEN origLabels=self.labels->Get(/all) 
   nLabels = N_Elements(origLabels)
   IF nLabels GT 0 THEN BEGIN
      FOR i=0, nLabels-1 DO BEGIN
         IF Obj_Valid(origLabels[i]) THEN BEGIN
            newLabel = origLabels[i]->Copy()
            newLabels->Add, newLabel
         ENDIF 
      ENDFOR
      out->SetProperty, Labels=newLabels
   ENDIF
   
   ; copy title object
   newTitle=Obj_New("SPD_UI_TEXT")
   IF Obj_Valid(self.titleObj) THEN newTitle=self.titleObj->Copy() ELSE $
      newTitle=Obj_New()
   out->SetProperty, TitleObj=newTitle
      ; copy title object
   newsubTitle=Obj_New("SPD_UI_TEXT")
   IF Obj_Valid(self.subtitleObj) THEN newsubTitle=self.subtitleObj->Copy() ELSE $
      newsubTitle=Obj_New()
   out->SetProperty, subTitleObj=newsubTitle
   
   RETURN, out
END ;--------------------------------------------------------------------------------

FUNCTION SPD_UI_AXIS_SETTINGS::GetUnits
if self.scaling eq 0 then begin
  if self.isTimeAxis then begin
    units = ['seconds', 'minutes', 'hours', 'days']
  endif else begin
    units = ['n^1']
  endelse
endif else if self.scaling eq 1 then begin
  if self.isTimeAxis then begin
    units = ['10^n sec']
  endif else begin
    units = ['10^n']
  endelse
endif else if self.scaling eq 2 then begin
  if self.isTimeAxis then begin
    units = ['e^n sec']
  endif else begin
    units =['e^n']
  endelse
endif else begin
  units =['unknown']
endelse

RETURN, units
END ;--------------------------------------------------------------------------------



FUNCTION SPD_UI_AXIS_SETTINGS::GetUnit, index
   IF N_Elements(index) EQ 0 THEN RETURN, 0
   IF NOT Is_Numeric(index) THEN RETURN, 0   
   units=self->GetUnits()
   IF index GE 0 && index LE N_Elements(units)-1 THEN RETURN, units(index) ELSE RETURN, -1
END ;--------------------------------------------------------------------------------



FUNCTION SPD_UI_AXIS_SETTINGS::GetFloatingCenters
RETURN, ['mean', 'median', 'approximate mean', 'approximate median'] 
END ;--------------------------------------------------------------------------------



FUNCTION SPD_UI_AXIS_SETTINGS::GetFloatingCenter, index
   IF ~size(index,/type) THEN RETURN, 0
   IF NOT Is_Numeric(index) THEN RETURN, 0
   IF index LT 0 OR index GT 3 THEN RETURN, 0
   units=self->GetFloatingCenters()
RETURN, units(index)
END ;--------------------------------------------------------------------------------



FUNCTION SPD_UI_AXIS_SETTINGS::GetAnnotationFormats
IF self.isTimeAxis EQ 1 THEN $
formats = ['date', 'date:h:m', 'date:h:m:s', 'date:h:m:s.ms', $
'h:m', 'h:m:s', 'h:m:s.ms', 'mo:day', 'mo:day:h:m', 'doy', 'doy:h:m', $
'doy:h:m:s', 'doy:h:m:s.ms', 'year:doy', 'year:doy:h:m', 'year:doy:h:m:s', $
'year:doy:h:m:s.ms  '] ELSE $
formats = [ '1234 (rounded down)', '1.', '1.2', '1.23', '1.234', '1.1234', $
            '1.01234', '1.001234','1.0001234','1.00001234','1.000001234']
;formats = ['d(1234)', 'f0(1234.)' , 'f1(123.4)', 'f2(12.34)', 'f3(1.234)', 'f4(0.1234)', $
;'f5(0.01234)', 'f6(0.001234)', 'e0(1.e+04)', 'e1(1.2e+04)', 'e2(1.23e+04)', 'e3(0.123e+04)', $
;'e4(0.0123e+04)', 'e5(0.00123e+04)', 'e6(0.000123e+04)']
RETURN, FORMATS
END ;--------------------------------------------------------------------------------



FUNCTION SPD_UI_AXIS_SETTINGS::GetAnnotationFormat, index
   IF N_Elements(index) EQ 0 THEN RETURN, 0
   IF NOT Is_Numeric(index) THEN RETURN, 0
   IF index LT 0 THEN RETURN, 0
   formats=self->GetAnnotationFormats()
RETURN, formats(index)
END ;--------------------------------------------------------------------------------



FUNCTION SPD_UI_AXIS_SETTINGS::GetPlacements
RETURN, ['Bottom','Top'] 
END ;--------------------------------------------------------------------------------



FUNCTION SPD_UI_AXIS_SETTINGS::GetPlacement, index
   IF N_Elements(index) eq 0 THEN RETURN, 0
   IF NOT Is_Numeric(index) THEN RETURN, 0
   placements=self->GetPlacements()
   IF index LT 0 OR index Ge n_elements(placements) THEN RETURN, 0
RETURN, placements(index)
END ;--------------------------------------------------------------------------------



FUNCTION SPD_UI_AXIS_SETTINGS::GetOrientations
RETURN, ['Horizontal', 'Vertical'] 
END ;--------------------------------------------------------------------------------



FUNCTION SPD_UI_AXIS_SETTINGS::GetOrientation, index
   IF N_Elements(index) NE 0 THEN RETURN, 0
   IF NOT Is_Numeric(index) THEN RETURN, 0
   IF index LT 0 OR index GT 5 THEN RETURN, 0
   orientations=self->GetOrientations()
RETURN, orientations(index)
END ;--------------------------------------------------------------------------------



FUNCTION SPD_UI_AXIS_SETTINGS::GetStyles
RETURN, ['Inside', 'Outside', 'Both Inside and Outside'] 
END ;--------------------------------------------------------------------------------



FUNCTION SPD_UI_AXIS_SETTINGS::GetStyle, index
   IF N_Elements(index) eq 0 THEN RETURN, 0
   IF NOT Is_Numeric(index) THEN RETURN, 0
   IF index LT 0 OR index GT 3 THEN RETURN, 0
   styles=self->GetStyles()
RETURN, styles(index)
END ;--------------------------------------------------------------------------------



FUNCTION SPD_UI_AXIS_SETTINGS::GetRangeOptions
RETURN, ['Auto Range', 'Floating Center', 'Fixed Min/Max'] 
END ;--------------------------------------------------------------------------------



FUNCTION SPD_UI_AXIS_SETTINGS::GetRangeOption, index
   IF N_Elements(index) NE 0 THEN RETURN, 0
   IF NOT Is_Numeric(index) THEN RETURN, 0
   IF index LT 0 OR index GT 5 THEN RETURN, 0
   rangeOptions=self->GetRangeOptions()
RETURN, rangeOptions(index)
END ;--------------------------------------------------------------------------------



PRO SPD_UI_AXIS_SETTINGS::UpdateRange, xRange


      ; Update min and max ranges based on the type of range (auto, float, fixed)

   CASE self.rangeOption OF
     '0': BEGIN
       self.boundScaling = 1 
       self.minBoundRange = xRange[0]
       self.maxBoundRange = xRange[1]     
     END
     '1': BEGIN
        self.boundFloating = 1
        self.minFloatRange = xRange[0]
        self.maxFloatRange = xRange[1]
     END
     '2': BEGIN
        self.minFixedRange = xRange[0]
        self.maxFixedRange = xRange[1]
     END
   ENDCASE
   
END ;--------------------------------------------------------------------------------

;gets the current range setting,
;this may not be the actual range that is used in display
;returns 0 if autoscaling
function spd_ui_axis_settings::getRange

  if self.rangeOption eq 0 && self.boundscaling then begin
    return,[self.minBoundRange,self.maxBoundRange]
  endif else if self.rangeOption eq 1 && self.boundFloating then begin
    return,[self.minFloatRange,self.maxFloatRange]
  endif else if self.rangeOption eq 2 then begin
    return,[self.minFixedRange,self.maxFixedRange]
  endif else begin
    return,0
  endelse 
   
end

FUNCTION SPD_UI_AXIS_SETTINGS::GetScalings
RETURN, ['Linear', 'Log 10', 'Natural'] 
END ;--------------------------------------------------------------------------------



FUNCTION SPD_UI_AXIS_SETTINGS::GetScaling, index
   IF N_Elements(index) NE 0 THEN RETURN, 0
   IF NOT Is_Numeric(index) THEN RETURN, 0
   IF index LT 0 OR index GT 5 THEN RETURN, 0
   scalings=self->GetScalings()
RETURN, scalings(index)
END ;--------------------------------------------------------------------------------



FUNCTION SPD_UI_AXIS_SETTINGS::GetDateFormats
 dateNames = ['Time', 'Date', 'Year', 'Mon', 'Day', 'Hours', 'Minutes', 'Seconds', 'Day of Year']
RETURN, dateNames 
END ;--------------------------------------------------------------------------------



FUNCTION SPD_UI_AXIS_SETTINGS::GetDateFormat, index
IF index LT 0 OR index GT 8 THEN RETURN, -1 ELSE dateNames=self->GetDateFormats()
RETURN, dateNames[index]
END ;--------------------------------------------------------------------------------



FUNCTION SPD_UI_AXIS_SETTINGS::GetDateCommands
 dateCommands= ['%time', '%date', '%year', '%mon', '%day', '%hours', '%minutes', '%seconds', '%doy']
RETURN, dateCommands
END ;--------------------------------------------------------------------------------



FUNCTION SPD_UI_AXIS_SETTINGS::GetDateCommand, index
IF index LT 0 OR index GT 7 THEN RETURN, -1 ELSE dateCommands=self->GetDateCommands()
RETURN, dateCommands[index]
END ;--------------------------------------------------------------------------------



FUNCTION SPD_UI_AXIS_SETTINGS::GetDateString, index, TimeObject=timeObject
   Catch, theError
   IF theError NE 0 THEN BEGIN
      Catch, /Cancel
      ok = Error_Message(Traceback=1)
      RETURN, -1
   ENDIF
   IF N_Elements(index) EQ 0 THEN RETURN, -1
   
   IF NOT Obj_Valid(timeObject) THEN timeObject = Obj_New("SPD_UI_TIME")
   timeObject->GetProperty, TString=timeString
   timeStruc = timeObject->GetStructure()
   
   CASE index OF
      0: dateString = StrMid(timeString, 11, 5)   
      1: dateString = StrMid(timeString, 0, 10)   
      2: dateString = timeStruc.year   
      3: dateString = timeStruc.mon
      4: dateString = timeStruc.date
      5: dateString = timeStruc.hour
      6: dateString = timeStruc.min
      7: dateString = timeStruc.sec
      8: dateString = timeStruc.doy  
      ELSE:  
   ENDCASE
   
RETURN, dateString  
END ;--------------------------------------------------------------------------------


pro spd_ui_axis_settings::save

  obj = self->copy()
  if ptr_valid(self.origsettings) then begin
    ptr_free,self.origsettings
  endif
  self.origsettings = ptr_new(obj->getall())

RETURN
end
;*********************************************************

pro spd_ui_axis_settings::reset

   if ptr_valid(self.origsettings) then begin
      self->SetAll,*self.origsettings
      self->save
   endif

RETURN
end ;------------------------------------------------------------------

;;looks at saved settings and calculates what user modified
;pro spd_ui_axis_settings::setTouched
;
;
;
;  if ~ptr_valid(self.origsettings) then return
;  
;  if (*self.origsettings).rangeOption ne self.rangeOption then self.touchedRangeOption=1
;  if (*self.origsettings).scaling ne self.scaling then self.touchedScaling=1
;  if (*self.origsettings).istimeaxis ne self.istimeaxis then self.touchedistimeaxis=1
; 
;  if ~self->equalTolerance((*self.origsettings).rangeMargin,self.rangeMargin) then self.touchedrangeMargin=1  
;  if ~self->equalTolerance((*self.origsettings).minBoundRange,self.minBoundRange) then self.touchedMinBoundRange=1
;  if ~self->equalTolerance((*self.origsettings).maxBoundRange,self.maxBoundRange) then self.touchedmaxBoundRange=1
;  if ~self->equalTolerance((*self.origsettings).minfixedRange,self.minfixedRange) then self.touchedMinfixedRange=1
;  if ~self->equalTolerance((*self.origsettings).maxfixedRange,self.maxfixedRange) then self.touchedmaxfixedRange=1
;  if (*self.origsettings).lineAtZero ne self.lineAtZero then self.touchedLineAtZero = 1
;  if (*self.origsettings).annotaterangemax ne self.annotaterangemax then self.touchedannotaterangemax = 1  
; 
;  self->save
;
;end

PRO SPD_UI_AXIS_SETTINGS::Cleanup 
   ;data format comment says it is object, but is declared numerical
   ;destroy?  
;   Obj_Destroy, self.majorGrid  
;   Obj_Destroy, self.minorGrid   

END ;--------------------------------------------------------------------------------



FUNCTION SPD_UI_AXIS_SETTINGS::Init,            $
      RangeOption=rangeOption,                  $ ; range options (auto, floating, fixed)
      touchedRangeOption=touchedRangeOption,    $ ;  has the user modified the rangeOption field
      Scaling=scaling,                          $ ; axis scaling (linear, log10, natural)
      touchedScaling=touchedscaling,            $ ; has the user modifed the scaling field
      EqualXYScaling=equalxyscaling,            $ ; flag set if equal X & Y axis scaled 
      IsTimeAxis=istimeaxis,                    $ ; flag set if axis is time based
      touchedIsTimeAxis=touchedIsTimeAxis,      $ ; has the user modified the isTimeAxis field
      RangeMargin=rangemargin,                  $ ; if auto - range margin
      BoundScaling=boundscaling,                $ ; flag set if auto scaling is bound
      BoundFloating=BoundFloating,              $ ; flag set if bounded floating range is used
      minFloatRange=minFloatRange,              $ ; minimum range bound if using floating range
      maxFloatRange=maxFloatRange,              $ ; maximum range bound if using floating range 
      minBoundRange=minBoundRange,              $ ; range for bounded autoscaling
      maxBoundRange=maxBoundRange,              $ ; max range for bounded autoscaling
      minFixedRange=minFixedRange,              $ ; min range value if fixed scaling
      touchedMinFixedRange=touchedMinFixedRange,$ ;  has the user modified the minFixedRange
      maxFixedRange=maxFixedRange,              $ ; max range value if fixed scaling
      touchedMaxFixedRange=touchedMaxFixedRange,$ ;  has the user modified the maxFixedRange
      FloatingSpan=floatingspan,                $ ; value of span if floating
      FloatingCenter=floatingcenter,            $ ; mean, median, apprx. mean, or apprx. median
      MajorTickEvery=majortickevery,            $ ; display major ticks every 
      MinorTickEvery=minortickevery,            $ ; display major ticks every 
      MajorTickUnits=majortickunits,            $ ; major tick units (sec, hr, min, day, none)
      MinorTickUnits=minortickunits,            $ ; major tick units (sec, hr, min, day, none)
      MajorTickAuto=majortickauto,              $ ; set to automatically figure out major ticks
      MinorTickAuto=minortickauto,              $ ; set to automatically figure out minor ticks
      FirstTickAuto=firsttickauto,              $ ; set to automatically figure out the first tick placement
      NumMajorTicks=nummajorticks,              $ ; number of major ticks
      NumMinorTicks=numminorticks,              $ ; number of major ticks
      FirstTickAt=firsttickat,                  $ ; value where first tick should be
      FirstTickUnits=firsttickunits,            $ ; first tick unit (sec, hr, min, day, none)
      TickStyle=tickstyle,                      $ ; style (inside, outside, both)
      BottomPlacement=bottomplacement,          $ ; flag set if ticks should be on bottom axis
      TopPlacement=topplacement,                $ ; flag set if ticks should be on top axis
      MajorLength=majorlength,                  $ ; length of major tick
      MinorLength=minorlength,                  $ ; length of minor tick
      logMinorTickType=logMinorTickType,        $ ; type of logarithmic minor tick
      LineAtZero=lineatzero,                    $ ; flag set if line is drawn at zero
      showdate=showdate,                        $ ; flag set if date strings are shown
      DateString1=datestring1,                  $ ; string format of date for line 1
      DateString2=datestring2,                  $ ; string format of date for line 1                                         
      DateFormat1=dateformat1,                  $ ; format of date for line 1 (annotation purposes)
      DateFormat2=dateformat2,                  $ ; format of date for line 2                                         
      AnnotateAxis=annotateaxis,                $ ; flag set to annotate along axis                         
      PlaceAnnotation=placeannotation,          $ ; placement of annotation (bottom or top)
      AnnotateMajorTicks=annotatemajorticks,    $ ; set flag if major ticks are annotated
      annotateEvery=annotateevery,              $ ; value where annotation of major ticks occur
      annotateUnits=annotateunits,              $ ; units for major tick value (sec, min, hr, day)
      FirstAnnotation=firstannotation,          $ ; value where annotation of first major tick occurs
      FirstAnnotateUnits=firstannotateunits,    $ ; units for major tick value (sec, min, hr, day)
      AnnotateRangeMin=annotaterangemin,        $ ; set flag to annotate range min tick  
      annotateRangeMax=annotaterangemax,        $ ; set flag to annotate range max tick  
      AnnotateStyle=annotatestyle,              $ ; format style of tick (h:m, doy, time, etc....)
      annotateOrientation=annotateOrientation,  $ ;orientation of the annotations: 0(horizontal) & 1(vertical)
      annotateTextObject=annotateTextObject,    $ ; Text object that represents that textual style of annotations
      annotateExponent=annotateExponent,        $ ;  Flag indicates whether to force annotations into an exponential format.  0: default behavior, 1: Always exponential, 2: Never exponential                    
      majorGrid=majorgrid,                      $ ; linestyle object of major grid 
      minorGrid=minorgrid,                      $ ; linestyle object of minor grid 
      Orientation=orientation,                  $ ; orientation of labels 0=Horizontal, 1=Vertical
      Margin=margin,                            $ ; number of points for label margins
      showLabels=showLabels,                    $ ; flag for whether or not labels are displayed
      labels=labels,                            $ ; A container object that stores the text objects which represent each label
      stackLabels=stackLabels,                  $ ; A flag to determine whether labels should be stacked                           
      lazyLabels=lazyLabels,                  $ ; A flag to determine whether underscores will be converted to carriage returns (and stacking turned off)
      blackLabels=blackLabels,                  $ ; A flag to determine whether labels are all black (not synced to line)
      titleObj=titleObj,                        $ ; title obj axis
      subtitleObj=subtitleObj,                  $ ; subtitle obj axis
      placeLabel=placeLabel,                    $ ; placement of label (left/bottom or right/top)
      placeTitle=placeTitle,                    $ ; placement of title (left/bottom or right/top)
      titleorientation=titleorientation,        $ ; orientation of title (0=horizontal, 1=vertical)
      titlemargin=titlemargin,                  $ ; number of points for title margin
      showtitle=showtitle,                      $ ; flag for whether the title should be displayed
      autoticks=autoticks,                      $ ; direct the draw object to make decisions about tick positioning automatically, and mutate axis object settings                  
      nosave=nosave                            ; don't save on start-up
   
   Catch, theError
   IF theError NE 0 THEN BEGIN
      Catch, /Cancel
      ok = Error_Message(Traceback=Keyword_Set(debug))
      RETURN, 0
   ENDIF
  
      ; Range Properties
    
   ; Check that all parameters have values 
   IF N_Elements(rangeoption) EQ 0 THEN rangeoption = 0 
   if n_elements(touchedrangeoption) eq 0 then touchedrangeoption=0
   IF N_Elements(scaling) EQ 0 THEN scaling = 0
   if n_elements(touchedscaling) eq 0 then touchedscaling = 0
   IF N_Elements(equalxyscaling) EQ 0 THEN equalxyscaling = 0
   IF N_Elements(istimeaxis) EQ 0 THEN istimeaxis = 1
   if n_elements(touchedistimeaxis) eq 0 then touchedistimeaxis=0
   IF N_Elements(rangemargin) EQ 0 THEN rangemargin = .05d
   IF N_Elements(boundscaling) EQ 0 THEN boundscaling = 0
   IF n_elements(boundfloating) eq 0 then boundfloating = 0
   IF n_elements(minfloatrange) eq 0 then minfloatrange = 0.0
   if n_elements(maxfloatrange) eq 0 then maxfloatrange = 0.0
   IF N_Elements(minboundrange) EQ 0 THEN minboundrange = 0.0
   IF N_Elements(maxboundrange) EQ 0 THEN maxboundrange = 0.0
   IF N_Elements(minfixedrange) EQ 0 THEN minfixedrange = 0.0
   if n_elements(touchedminfixedrange) eq 0 then touchedminfixedrange = 0
   IF N_Elements(maxfixedrange) EQ 0 THEN maxfixedrange = 0.0
   if n_elements(touchedmaxfixedrange) eq 0 then touchedmaxfixedrange = 0
   IF N_Elements(floatingspan) EQ 0 THEN floatingspan = 20
   IF N_Elements(floatingcenter) EQ 0 THEN floatingcenter = 0   
   
   ; Set all parameters 
   self.rangeOption = rangeoption
   self.touchedrangeoption = touchedrangeoption
   self.scaling = scaling
   self.touchedscaling = touchedscaling
   self.equalXYScaling = equalxyscaling
   self.isTimeAxis = istimeaxis
   self.touchedistimeaxis = touchedistimeaxis
   self.rangeMargin = rangemargin
   self.boundScaling = boundscaling
   self.boundFloating = boundfloating
   self.minFloatRange = minFloatrange
   self.maxFloatRange = maxFloatRange
   self.minboundRange = minboundrange
   self.maxboundRange = maxboundrange
   self.minfixedRange = minfixedrange
   self.touchedminfixedrange = touchedminfixedrange
   self.maxfixedRange = maxfixedrange
   self.touchedmaxfixedrange = touchedmaxfixedrange
   self.floatingSpan = floatingspan
   self.floatingCenter = floatingcenter

      ; Tick Properties
      
   ; Check that all parameters have values 
   IF N_Elements(majortickevery) EQ 0 THEN majortickevery = 1 
   IF N_Elements(minortickevery) EQ 0 THEN minortickevery = 1 
   IF N_Elements(majortickunits) EQ 0 THEN majortickunits = 2 
   IF N_Elements(minortickunits) EQ 0 THEN minortickunits = 2 
   IF N_Elements(majortickauto) EQ 0 THEN majortickauto  = 1 
   IF N_Elements(minortickauto) EQ 0 THEN minortickauto = 1 
   IF N_Elements(firsttickauto) EQ 0 THEN firsttickauto = 1 
   IF N_Elements(nummajorticks) EQ 0 THEN nummajorticks = 0 
   IF N_Elements(numminorticks) EQ 0 THEN numminorticks = 0 
   IF N_Elements(firsttickat) EQ 0 THEN firsttickat = 0 
   IF N_Elements(firsttickunits) EQ 0 THEN firsttickunits = 0 
   IF N_Elements(tickstyle) EQ 0 THEN tickstyle = 0 
   IF N_Elements(bottomplacement) EQ 0 THEN bottomplacement = 0 
   IF N_Elements(topplacement) EQ 0 THEN topplacement = 0 
   IF N_Elements(majorlength) EQ 0 THEN majorlength = 1 
   IF N_Elements(minorlength) EQ 0 THEN minorlength = 1 
   if n_elements(logMinorTickType) eq 0 then logMinorTickType = 1

  ; Set all parameters
   self.majorTickEvery = majortickevery
   self.minorTickEvery = minortickevery
   self.majorTickUnits = majortickunits 
   self.minorTickUnits = minortickunits 
   self.majorTickAuto = majortickauto  
   self.minorTickAuto = minortickauto 
   self.firstTickAuto = firsttickauto
   self.numMajorTicks = nummajorticks 
   self.numMinorTicks = numminorticks 
   self.firstTickAt = firsttickat 
   self.firstTickUnits = firsttickunits 
   self.tickStyle = tickstyle 
   self.bottomPlacement = bottomplacement 
   self.topPlacement = topplacement 
   self.majorLength = majorlength 
   self.minorLength = minorlength 
   self.logMinorTickType = logMinorTickType


      ; Annotation Properties

   ; Check that all parameters have values 
   IF N_Elements(lineatzero) EQ 0 THEN lineatzero = 0 
   IF N_Elements(showdate) EQ 0 THEN showdate = 0 
   IF N_Elements(datestring1) EQ 0 THEN datestring1 = 'DOY: %doy' 
   IF N_Elements(datestring2) EQ 0 THEN datestring2 = '%year-%mon-%day' 
   IF N_Elements(dateformat1) EQ 0 THEN dateformat1 = 0 
   IF N_Elements(dataformat2) EQ 0 THEN dateformat2 = 0 
   IF N_Elements(annotateaxis) EQ 0 THEN annotateaxis = 0 
   IF N_Elements(placeannotation) EQ 0 THEN placeannotation = 0 
   IF N_Elements(annotatemajorticks) EQ 0 THEN annotatemajorticks = 0 
   IF N_Elements(annotateevery) EQ 0 THEN annotateevery = 1 
   IF N_Elements(annotateunits) EQ 0 THEN annotateunits = 2 
   IF N_Elements(firstannotation) EQ 0 THEN firstannotation = 0 
   IF N_Elements(firstannotateunits) EQ 0 THEN firstannotateunits = 0 
   IF N_Elements(annotaterangemin) EQ 0 THEN annotaterangemin = 0 
   IF N_Elements(annotaterangemax) EQ 0 THEN annotaterangemax = 0 
   IF N_Elements(annotatestyle) EQ 0 THEN annotatestyle = 0 
   If n_elements(annotateOrientation) eq 0 then annotateOrientation = 0
   If n_elements(annotateTextObject) eq 0 then annotateTextObject = obj_new('spd_ui_text')
   If n_elements(annotateExponent) eq 0 then annotateExponent = 0
   
  ; Set all parameters
   self.lineAtZero = lineatzero 
   self.showDate = showDate
   self.dateString1 = datestring1 
   self.dateString2 = datestring2 
   self.dateFormat1 = dateformat1 
   self.dateFormat2 = dateformat2 
   self.annotateAxis = annotateaxis 
   self.placeAnnotation = placeannotation 
   self.annotateMajorTicks = annotatemajorticks 
   self.annotateEvery = annotateevery 
   self.annotateUnits = annotateunits 
   self.firstAnnotation = firstannotation 
   self.firstAnnotateUnits = firstannotateunits 
   self.annotateRangeMin = annotaterangemin 
   self.annotateRangeMax = annotaterangemax
   self.annotateOrientation = annotateOrientation
   self.annotateStyle = annotatestyle
   self.annotateTextObject = annotateTextObject 
   self.annotateExponent = annotateExponent


      ; Axes Properties

   ; Check that all parameters have values 
   IF NOT Obj_Valid(majorGrid) THEN majorgrid = Obj_New()  
   IF NOT Obj_Valid(minorGrid) THEN minorgrid = Obj_New()  

   ; Set all parameters
   self.majorGrid = majorgrid
   self.minorGrid = minorgrid

   
      ; Label Properties

   ; Check that all parameters have values 
   IF N_Elements(orientation) EQ 0 THEN orientation = 0 
   IF N_Elements(margin) EQ 0 THEN margin = 0 
   if n_elements(showlabels) eq 0 then showlabels = 1
   If n_elements(labels) eq 0 then labels = obj_new()
   if n_elements(stackLabels) eq 0 then stackLabels = 0
   if n_elements(lazyLabels) eq 0 then lazyLabels = 1
   if n_elements(blackLabels) eq 0 then blackLabels = 0
   IF N_Elements(titleObj) EQ 0 THEN titleObj = obj_new('spd_ui_text')
   if n_elements(subtitleObj) eq 0 then subtitleObj = obj_new('spd_ui_text')
   if n_elements(placeLabel) eq 0 then placeLabel = 0
   if n_elements(placeTitle) eq 0 then placeTitle = 0
   if n_elements(titleorientation) eq 0 then titleorientation = 1
   if n_elements(titlemargin) eq 0 then titlemargin = 0
   if n_elements(showtitle) eq 0 then showtitle = 1
   if n_elements(lazyTitles) eq 0 then lazyTitles = 1

  ; Set all parameters    
   self.orientation = orientation               
   self.margin = margin    
   self.showlabels = showlabels
   self.labels = labels
   self.stackLabels = stackLabels
   self.lazyLabels = lazyLabels
   self.blackLabels = blackLabels
   self.titleObj = titleObj
   self.subtitleObj = subtitleObj
   self.placeLabel = placelabel
   self.placeTitle = placetitle
   self.titleorientation = titleorientation
   self.titlemargin = titlemargin
   self.showtitle = showtitle
   self.lazytitles = lazyTitles
   
   if n_elements(autoticks) eq 0 then autoticks = 1  
   self.autoticks = autoticks 
 
   if ~keyword_set(nosave) then self->save
   
 
  

RETURN, 1
END ;--------------------------------------------------------------------------------

;*********************************************************

PRO SPD_UI_AXIS_SETTINGS__DEFINE

  

   struct = { SPD_UI_AXIS_SETTINGS, $

                 ; Range Properties
                 
              rangeOption: 0,         $ ; range options (auto, floating, fixed)
              touchedRangeOption: 0b,  $ ; has the user modified the rangeOption field
              scaling: 0,             $ ; axis scaling (linear, log10, natural)
              touchedScaling: 0b,     $ ; has the user modifed the scaling field
              equalXYScaling: 0b,      $ ; flag set if equal X & Y axis scaled 
              isTimeAxis: 0,          $ ; flag set if axis is time based
              touchedIsTimeAxis:0b,    $ ; has the user modified the isTimeAxis field   
              rangeMargin: 0D,        $ ; if auto - range margin
              touchedRangeMargin:0b,  $ ;has the user modified the range margin
              boundScaling: 0b,        $ ; flag set if auto scaling is bound
              boundFloating: 0b,       $ ; flag set if floating range is bounded
              minFloatRange: 0.0D,    $ ; min range bound if using floating range
              maxFloatRange: 0.0D,    $ ; max range bound if using floating range 
              minBoundRange: 0.0D,    $ ; min range value if bounded auto scaling
              touchedMinBoundRange:0b,  $ ;has the user modified the min bound range  
              maxBoundRange: 0.0D,    $ ; max range value if bounded auto scaling
              touchedMaxBoundRange:0b,  $ ;has the user modified the max bound range     
              minFixedRange: 0.0D,    $ ; min range value if fixed scaling
              touchedMinFixedRange: 0b, $;  has the user modified the minFixedRange
              maxFixedRange: 0.0D,    $ ; max range value if fixed scaling
              touchedMaxFixedRange: 0b,$; has the user modified the maxFixedRange
              floatingSpan: 0.0D,       $ ; value of span if floating
              floatingCenter: 0,      $ ; mean, median, apprx. mean, apprx. median
                   
                  ; Tick Properties

              majorTickEvery: 0D,     $ ; display major ticks every 
              minorTickEvery: 0D,     $ ; display major ticks every 
              majorTickUnits: 0,      $ ; major tick units (sec, hr, min, day, none)
              minorTickUnits: 0,      $ ; major tick units (sec, hr, min, day, none)
              majorTickAuto: 0,       $ ; set to automatically figure out major ticks
              minorTickAuto: 0,       $ ; set to automatically figure out minor ticks
              firstTickAuto: 0,       $ ; set to automatically figure out the first tick
              numMajorTicks: 0LL,       $ ; number of major ticks
              numMinorTicks: 0LL,       $ ; number of major ticks
              firstTickAt: 0D,         $ ; value where first tick should be
              firstTickUnits: 0,      $ ; first tick unit (sec, hr, min, day, none)
              tickStyle: 0,           $ ; style (inside, outside, both)
              bottomPlacement: 0,     $ ; flag set if ticks should be on bottom axis
              topPlacement: 0,        $ ; flag set if ticks should be on top axis
              majorLength: 0LL,         $ ; length of major tick
              minorLength: 0LL,         $ ; length of minor tick
              logMinorTickType:0L,     $ ; type of minor tick (0,1,2,3)

                  
                  ; Annotation Properties

              lineAtZero: 0,          $ ; flag set if line is drawn at zero
              touchedLineAtZero:0b,   $ ; has the user modified line at zero
              showDate:0,             $ ; flag to indicate whether date should be displayed
              dateString1: '',        $ ; string with annotation format                           
              dateString2: '',        $ ; string with annotation format                                
              dateFormat1: 0,         $ ; time object for annotation                                   
              dateFormat2: 0,         $ ; time object for annotation                                   
              annotateAxis: 0,        $ ; flag set to annotate along axis                         
              placeAnnotation: 0,     $ ; placement of annotation (bottom or top)
              annotateMajorTicks: 0,  $ ; set flag if major ticks are annotated
              annotateEvery: 1D,      $ ; value where annotation of major ticks occur
              annotateUnits: 2,       $ ; units for major tick value (sec, min, hr, day)
              firstAnnotation: 0D,     $ ; value where annotation of first major tick occurs
              firstAnnotateUnits: 0,  $ ; units for major tick value (sec, min, hr, day)
              annotateRangeMin: 0,    $ ; set flag to annotate range min tick 
              annotateRangeMax: 0,    $ ; set flag to annotate range max tick
              touchedAnnotateRangeMax:0b, $ ; has the user modified annotate range max tick 
              annotateStyle: 0,       $ ; format style of tick (h:m, doy, time, etc....)
              annotateOrientation: 0, $ ;specify the orientation of the annotations with a number:  0(horizontal) or 1(vertical)
              annotateTextObject: Obj_new(), $ ; an object that stores the text style information for the annotations
              annotateExponent: 0 , $   ;  Flag indicates whether to force annotations into an exponential format.  0: default behavior, 1: Always exponential, 2: Never exponential                    
                   ; Axes Properties

              majorGrid: Obj_New(),       $ ;linestyle object for major grid 
              minorGrid: Obj_New(),       $ ;linestyle object for minor grid

                   ; Label Properties

              orientation: 0,         $ ; orientation of labels 0=Horizontal, 1=Vertical
              margin: 0L,             $ ; number of points for label margins
              showLabels:0b,          $ ; flag for not labels are displayed
              labels: Obj_new(),      $ ; An IDL_Container with text objects for each label
              stackLabels:0,          $ ; This flag determines whether labels are stacked or are a row
              lazyLabels:0,           $ ; This flag determines if underscores will be converted to carriage returns (and stacking turned off)
              blackLabels:0,          $ ; This flag determines if the labels are all colored black (not synced to line)
              origsettings: ptr_new(),$ ;To save settings, if reset is needed.
              autoticks:0,            $ ; directs the draw object to make decisions about tick positioning automatically, and mutate axis object settings
              titleobj: obj_new(),    $ ; text object for axis title
              subtitleobj: obj_new(), $ ; text object for axis subtitle
              placeLabel: 0,          $ ; placement of labels (left/bottom or right/top)
              placeTitle: 0,          $ ; placement of title (left/bottom or right/top)
              titleorientation: 0,    $ ; orientation of title 0=horizontal, 1=vertical
              titlemargin: 0,         $ ; number of points for title margins
              showtitle: 0b,          $ ; flag for whether the titles should be displayed
              lazyTitles:0,           $ ; This flag determines if underscores will be converted to carriage returns for titles
              INHERITS SPD_UI_READWRITE, $ ; generalized read/write methods
              INHERITS spd_ui_getset $ ; generalized setProperty/getProperty/getAll/setAll methods
                     
}

END
