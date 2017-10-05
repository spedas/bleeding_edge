;+ 
;NAME: 
; spd_ui_panel__define
;
;PURPOSE:  
; generic object for a panel
;
;CALLING SEQUENCE:
; panel = Obj_New("SPD_UI_PANEL")
;
;INPUT:
; none
;
;ATTRIBUTES:

;traceSettings IDL_Container object storing trace settings for each set of data quantities to be plotted
;windowID    ID for parent window (defaults to -1)
;name        name for this panel
;id          unique identifier for this panel
;settings    property object for this panel
;xAxis       x axis properties object
;yAxis       y axis properties object
;zAxis       z axis properties object
;tracking    flag set if tracking is on
;isActive    flag set if panel is displayed
;syncflag    flag set if label and trace colors are synced
;variables   idl container of variable objects
;showvariables flag indicates whether variables should be displayed or not 
;markers     idl container of marker objects
;
;OUTPUT:
; panel object reference
;
;METHODS:
; GetProperty
; GetAll
; GetLayoutStructure
; SetLayoutStructure
; SetProperty
;
;NOTES:
;  Methods: GetProperty,SetProperty,GetAll,SetAll are now managed automatically using the parent class
;  spd_ui_getset.  You can still call these methods when using objects of type spd_ui_panel, and
;  call them in the same way as before
;
;$LastChangedBy: egrimes $
;$LastChangedDate: 2015-07-10 16:24:08 -0700 (Fri, 10 Jul 2015) $
;$LastChangedRevision: 18086 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/spedas_gui/objects/spd_ui_panel__define.pro $
;-----------------------------------------------------------------------------------

FUNCTION SPD_UI_PANEL::Copy
   out = Obj_New("SPD_UI_PANEL", self.id,/nosave)
   Struct_Assign, self, out
   ; copy panel settings
   ;newSettings=Obj_New("SPD_UI_PANEL_SETTINGS")
   IF Obj_Valid(self.Settings) THEN newSettings=self.settings->Copy() ELSE $
      newSettings=Obj_New()
   out->SetProperty, Settings=newSettings
   ; copy x axis
   ;newAxis=Obj_New("SPD_UI_AXIS_SETTINGS")
   IF Obj_Valid(self.xAxis) THEN newAxis=self.xAxis->Copy() ELSE $
      newAxis=Obj_New()
   out->SetProperty, XAxis=newAxis
   ; copy y axis
   ;newAxis=Obj_New("SPD_UI_AXIS_SETTINGS")
   IF Obj_Valid(self.yAxis) THEN newAxis=self.yAxis->Copy() ELSE $
      newAxis=Obj_New()
   out->SetProperty, YAxis=newAxis
   ; copy z axis
   ;newAxis=Obj_New("SPD_UI_ZAXIS_SETTINGS")
   IF Obj_Valid(self.zAxis) THEN newAxis=self.zAxis->Copy() ELSE $
      newAxis=Obj_New()
   out->SetProperty, ZAxis=newAxis
   ; copy trace settings
   IF Obj_Valid(self.traceSettings) THEN BEGIN
     origSettings=self.traceSettings->Get(/all)  
     newSettings=Obj_New("IDL_Container")
     nSettings = N_Elements(origSettings)
     IF nSettings GT 0 THEN BEGIN
       FOR i=0, nSettings-1 DO BEGIN
         IF Obj_Valid(origSettings[i]) THEN BEGIN
            newSetting=origSettings[i]->Copy()
            newSettings->Add, newSetting
         ENDIF 
       ENDFOR
     ENDIF
   ENDIF
   
   out->SetProperty, TraceSettings=newSettings
   ; copy variables
   newVariables=Obj_New("IDL_Container")
   newVariable=Obj_New("SPD_UI_VARIABLE")
   IF Obj_Valid(self.variables) THEN origVariables=self.variables->Get(/all)        
   nVariables = N_Elements(origVariables)
   IF nVariables GT 0 THEN BEGIN
      FOR i=0, nVariables-1 DO BEGIN
         IF Obj_Valid(origVariables[i]) THEN BEGIN
            newVariable=origVariables[i]->Copy()
            newVariables->Add, newVariable
         ENDIF 
      ENDFOR
   ENDIF
   out->SetProperty, Variables=newVariables
   ; copy markers
   newMarkers=Obj_New("IDL_Container")
   newMarker=Obj_New("SPD_UI_MARKER")
   IF Obj_Valid(self.markers) THEN origMarkers=self.markers->Get(/all)        
   numMarkers = N_Elements(origMarkers)
   IF numMarkers GT 0 THEN BEGIN
      FOR i=0, numMarkers-1 DO BEGIN
         IF Obj_Valid(origMarkers[i]) THEN BEGIN
            newMarker=origMarkers[i]->Copy()
            newMarkers->Add, newMarker
         ENDIF 
      ENDFOR
   ENDIF
   out->SetProperty, Markers=newMarkers
   RETURN, out
END ;--------------------------------------------------------------------------------


;returns [xpos,ypos,xsize,ysize] in points
FUNCTION SPD_UI_PANEL::GetPanelCoordinates

   ; get units and values for each coordinate, bottom, left, width, height
  
  coord = dblarr(4)
   
  self.settings->getProperty,lunit=unit,lvalue=value,left=flag
  coord[0] = (~flag || value eq -1)?-1:self.settings->convertunit(value,unit,0)
  
  self.settings->getProperty,bunit=unit,bvalue=value,bottom=flag
  coord[1] = (~flag || value eq -1)?-1:self.settings->convertunit(value,unit,0)
  
  self.settings->getProperty,wunit=unit,wvalue=value,width=flag
  coord[2] = (~flag || value eq -1)?-1:self.settings->convertunit(value,unit,0)

  self.settings->getProperty,hunit=unit,hvalue=value,height=flag
  coord[3] = (~flag || value eq -1)?-1:self.settings->convertunit(value,unit,0)

RETURN, coord 
END ;--------------------------------------------------------------------------------

;coord = [xpos,ypos,xsize,ysize] in points
pro SPD_UI_PANEL::setPanelCoordinates,coord
 
  self.settings->getProperty,lunit=lunit
  lvalue = self.settings->convertunit(coord[0],0,lunit)
  self.settings->setProperty,lvalue=lvalue
  
  self.settings->getProperty,bunit=bunit
  bvalue = self.settings->convertunit(coord[1],0,bunit)
  self.settings->setProperty,bvalue=bvalue
  
  self.settings->getProperty,wunit=wunit
  wvalue = self.settings->convertunit(coord[2],0,wunit)
  self.settings->setProperty,wvalue=wvalue
  
  self.settings->getProperty,hunit=hunit
  hvalue = self.settings->convertunit(coord[3],0,hunit)
  self.settings->setProperty,hvalue=hvalue
 

END ;--------------------------------------------------------------------------------

;function constructs a panel name for display in droplists
function spd_ui_panel::constructPanelName

  compile_opt idl2

  name = 'Panel '
  
  name += strtrim(string(self.id + 1),2)

  self.settings->getProperty,row=row,col=col,titleObj=panelTitle
  
  panelTitle->getProperty, value=title    
  if strlen(title) gt 45 then title = strmid(title, 0, 45) + ' ...'
  
  name += ' (' + strtrim(string(row),2) + ', ' + strtrim(string(col),2) + ')  -  ' + $
           title
   
  return,name

end

;function constructs an array of panel's trace names for display in droplists
function spd_ui_panel::constructTraceNames

  compile_opt idl2
  
  if obj_valid(self.traceSettings) AND $
       ~array_equal((self.traceSettings->get(/all)), -1, /no_typeconv) then begin
  
    objs = self.traceSettings->get(/all)
    names = strarr(n_elements(objs))
    
      for i = 0,n_elements(objs)-1 do begin
      
        if obj_isa(objs[i],'spd_ui_line_settings') then begin
          objs[i]->getProperty,dataX=dataX,dataY=dataY
          
          names[i] = '  - ' + dataX + ' -vs- ' + dataY
        
        endif else if obj_isa(objs[i],'spd_ui_spectra_settings') then begin
        
          objs[i]->getProperty,dataX=dataX,dataY=dataY,dataZ=dataZ
          
          names[i] = '  - ' + dataX + ' -vs- ' + dataY + ' -vs- ' + dataZ 
           
        endif
      
      endfor
  endif
  
  return,names

end

;this routine will update references to a data quantity
;This should be used if a name has changed while traces are
;already in existence .
pro spd_ui_panel::updatedatareference,oldnames,newnames

  compile_opt idl2
  
  ref_changed = 0
  
  self->getProperty,traceSettings=traceSettings,variables=variables
  
  if obj_valid(traceSettings) then begin
  
    traces = traceSettings->get(/all)
  
    if obj_valid(traces[0]) then begin
      for i = 0,n_elements(traces)-1 do begin
      
        traces[i]->updatedatareference,oldnames,newnames,changed=changed
        if changed then ref_changed = 1
        
      endfor
    endif
    
  endif

  if ref_changed then self->synclabelstolines, oldnames=oldnames, newnames=newnames
  
  if obj_valid(variables) then begin
  
    var_list = variables->get(/all)
    
    if obj_valid(var_list[0]) then begin
      for i = 0,n_elements(var_list)-1 do begin
      
        var_list[i]->updatedatareference,oldnames,newnames
        
      endfor
    endif
    
  endif
  
end

PRO SPD_UI_PANEL::SyncLinesToLabels
   IF ~Obj_Valid(self.traceSettings) THEN RETURN
   settings = self.traceSettings->Get(/All)
   nLines = N_Elements(settings)
   
   IF ~Obj_Valid(self.yAxis) THEN RETURN
   self.yAxis->GetProperty, Labels=labels
   if ~obj_valid(labels) then return
   labels1 = labels->Get(/All)
   nLabels = N_Elements(labels1)
   IF nLabels LT 1 THEN RETURN
   IF ~Obj_Valid(labels1[0]) THEN RETURN
   IF nLines GT nLabels THEN nlines = nLabels
   IF nLines LT 1 THEN RETURN
 
   FOR i=0,nLines-1 DO BEGIN

      IF Obj_Isa(settings[i], 'SPD_UI_LINE_SETTINGS') THEN BEGIN   ;is a line

         settings[i]->GetProperty, LineStyle=lineStyle
         IF Obj_Valid(lineStyle) THEN BEGIN
            labels1[i]->GetProperty, Color=color
            lineStyle->SetProperty, Color=color
        ENDIF
     ENDIF
      
       ;I'm not sure what this is supposed to do, but whatever it is, it doesn't work. 
       ;ELSE BEGIN  ; is a spectra
       ;IF ~Obj_Valid(self.zAxis) THEN RETURN
       ;self.zAxis->GetProperty, LabelTextObject=label
       ;IF ~Obj_Valid(label) THEN RETURN
       ;label->SetProperty, Color=color
       ; ENDELSE
   ENDFOR
END ;--------------------------------------------------------------------------------



PRO SPD_UI_PANEL::SyncLabelsToLines, oldnames=oldnames, newnames=newnames

   ;label text
   IF ~Obj_Valid(self.traceSettings) THEN RETURN
   traceSettings = self.traceSettings->Get(/All)
   ntraces = n_elements(traceSettings)
     
   ;this block used only when a variable rename occurs
   if keyword_set(oldnames) && keyword_set(newnames) then begin
     ;loop overall the traces
     for i = 0,n_elements(traceSettings)-1 do begin
      
       dataX = ''
       dataY = '' 
       dataZ = ''
       
       ;trace is valid?
       if obj_valid(tracesettings[i]) then begin
       
         tracesettings[i]->getProperty,dataX=dataX
       
         ;x-element is valid?
         if is_string(dataX) then begin
         
           ;x element was changed?
           idx = where(dataX eq newnames,c)
           
           if c ge 1 then begin
         
             self.xaxis->getProperty,labels=xlabels
             
             ;xLabels are valid?
             if obj_valid(xlabels) then begin
             
               xLabelArray = xLabels->get(/all)
               
               ;sufficient number of labels to match this trace to label
               if i lt n_elements(xLabelArray) then begin
               
                 xLabelArray[i]->getProperty,value=xLabelText
                 subIdx = stregex(xLabelText,oldnames[idx[0]],length=subLen)
                              
                 if subIdx ne -1 then begin      
                   xlabelNew = strmid(xLabelText,0,subIdx) + newnames[idx[0]] + strmid(xLabelText,subIdx+subLen) 
                   xLabelArray[i]->setProperty,value=xlabelNew
                 endif
                 
               endif
               
             endif
             
           endif
         endif
      
         tracesettings[i]->getProperty,dataY=dataY
      
         ;y-element is valid?
         if is_string(dataY) then begin
         
           ;y element was changed?
           idx = where(dataY eq newnames,c)
           if c ge 1 then begin
         
             self.yaxis->getProperty,labels=ylabels
             
             ;yLabels are valid?
             if obj_valid(ylabels) then begin
             
               yLabelArray = yLabels->get(/all)
               
               ;sufficient number of labels to match this trace to label
               if i lt n_elements(yLabelArray) then begin
               
                 yLabelArray[i]->getProperty,value=yLabelText
                 subIdx = stregex(yLabelText,oldnames[idx[0]],length=subLen)
                              
                 if subIdx ne -1 then begin      
                   ylabelNew = strmid(yLabelText,0,subIdx) + newnames[idx[0]] + strmid(yLabelText,subIdx+subLen) 
                   yLabelArray[i]->setProperty,value=ylabelNew
                 endif
                 
               endif
               
             endif
             
           endif
         
         endif
       
         if obj_isa(tracesettings[i],'spd_ui_spectra_settings') then begin
           tracesettings[i]->getProperty,dataZ=dataZ
           
             ;x-element is valid?
           if is_string(dataZ) then begin
           
             ;x element was changed?
             idx = where(dataZ eq newnames,c)
             if c ge 1 then begin
             
               if obj_valid(self.zaxis) then begin
           
                 self.zaxis->getProperty,labelTextObject=zlabelarray
                 
                 ;zLabels are valid?
                 if obj_valid(zlabelarray) then begin
               
                   zLabelArray[0]->getProperty,value=zLabelText
                   subIdx = stregex(zLabelText,oldnames[idx[0]],length=subLen)
                                
                   if subIdx ne -1 then begin      
                     zlabelNew = strmid(zLabelText,0,subIdx) + newnames[idx[0]] + strmid(zLabelText,subIdx+subLen) 
                     zLabelArray[0]->setProperty,value=zlabelNew
                   endif
                   
                 endif 
               endif
               
               self.yaxis->getProperty,labels=ylabels
           
               ;for spectral plots, sometimes the z-axis value is made into the y-axis label
           
               ;yLabels are valid?
               if obj_valid(ylabels) then begin
               
                 yLabelArray = yLabels->get(/all)
                 
                 ;sufficient number of labels to match this trace to label
                 if i lt n_elements(yLabelArray) then begin
                 
                   yLabelArray[i]->getProperty,value=yLabelText
                   subIdx = stregex(yLabelText,oldnames[idx],length=subLen)
                                
                   if subIdx ne -1 then begin      
                     ylabelNew = strmid(yLabelText,0,subIdx) + newnames[idx] + strmid(yLabelText,subIdx+subLen) 
                     yLabelArray[i]->setProperty,value=ylabelNew
                   endif
                   
                 endif
               endif
                           
             endif
             
           endif   
         endif
       endif
     endfor
   endif
   
   ;label colors
   IF ~Obj_Valid(self.yAxis) THEN RETURN
   self.yAxis->GetProperty, Labels = labels
   if ~obj_valid(labels[0]) then return
   labels1 = labels->Get(/All)
   nLabels = N_Elements(labels1)
   IF nLabels LT 1 THEN RETURN
   IF ~Obj_Valid(labels1[0]) THEN RETURN
   IF nLabels GT ntraces THEN nlabels = ntraces
   IF nLabels LT 1 THEN RETURN
   FOR i=0,nLabels-1 DO BEGIN
     if obj_isa(tracesettings[i],'spd_ui_spectra_settings') then begin
    ;   labels1[i]->setProperty,color=[0,0,0]
     endif else begin
       traceSettings[i]->GetProperty, LineStyle=lineStyle
       traceSettings[i]->GetProperty, dataY=dataY
       IF Obj_Valid(lineStyle) THEN BEGIN
         lineStyle->GetProperty, Color=color
         labels1[i]->SetProperty, Color=color
       ENDIF
     endelse   
   ENDFOR
END ;--------------------------------------------------------------------------------



FUNCTION SPD_UI_PANEL::GetLayoutStructure
self.settings->GetProperty, Row=row, Col=col,rspan=rowspan,cspan=colspan
RETURN, {layout, row:row, col:col, id:self.id,rspan:rowspan,cspan:colspan}
END ;--------------------------------------------------------------------------------


pro SPD_UI_PANEL::SetLayoutStructure, Row=row, Col=col, Rspan=rspan, Cspan=cspan
self.settings->SetProperty, Row=row, Col=col, Rspan=rspan, Cspan=cspan
END ;--------------------------------------------------------------------------------

PRO SPD_UI_PANEL::Save

  copy = self->copy()
  if ptr_valid(self.origsettings) then begin
    ptr_free,self.origsettings
  endif
  self.origsettings = ptr_new(copy->getall())

RETURN
END ;--------------------------------------------------------------------------------

;Pro spd_ui_panel::setTouched
;
;  self.xAxis->setTouched
;  self.yAxis->setTouched
;  
;  if obj_valid(self.zAxis) then begin
;    self.zAxis->setTouched
;  endif
;  
;  self->save
;
;end 

PRO SPD_UI_PANEL::Reset

   if ptr_valid(self.origsettings) then begin
      ;fix for IDL 8.1 - removed in favour of fix to spd_ui_getset__define:SetAll
      ;str = *self.origsettings
      ;self->SetAll,str
      self->SetAll,*self.origsettings
      self->save
   endif

RETURN
END ;--------------------------------------------------------------------------------


;PRO SPD_UI_PANEL::Cleanup 
;   Obj_Destroy, self.settings
;   Obj_Destroy, self.xAxis
;   Obj_Destroy, self.yAxis
;   Obj_Destroy, self.zAxis
;   Obj_Destroy, self.traceSettings
;   Obj_Destroy, self.variables 
;   Obj_Destroy, self.markers 
;RETURN    
;END ;--------------------------------------------------------------------------------


  
FUNCTION SPD_UI_PANEL::Init,    $ ; The INIT method of the line style object
        id,                     $ ; numerical identifier for this panel     
        traceSettings=traceSettings, $ ; IDL_Container object storing trace settings for each set of data quantities to be plotted
        windowID=windowID,      $ ; ID for parent window (now optional, defaults to -1)
        Name=name,              $ ; name for this panel
        Settings=settings,      $ ; property object for this panel
        legendSettings=legendSettings, $ ; legend settings object for this panel
        XAxis=xaxis,            $ ; x axis properties object
        YAxis=yaxis,            $ ; y axis properties object
        zAxis=zaxis,            $ ; z axis properties object
        Tracking=tracking,      $ ; flag set if tracking is on
        Variables=variables,    $ ; idl container of variable objects
        showvariables=showvariables, $ ; flag indicates whether variables should be displayed or not
        Markers=markers,        $ ; idl container of variable objects
        labelmargin=labelmargin,$ ; label margin for panel
        IsActive=isactive,      $ ; flag set if panel is displayed
        SyncFlag=syncflag,      $ ; flag set if labels and trace colors are synced
        Debug=debug,            $ ; flag to debug
        nosave=nosave             ; won't save a copy on startup 

   Catch, theError
   IF theError NE 0 THEN BEGIN
      Catch, /Cancel
      ok = Error_Message(Traceback=Keyword_Set(debug))
      RETURN, 0
   ENDIF
  
   ; Check that all parameters have values

   IF N_Elements(id) EQ 0 THEN id = -1
   IF N_Elements(windowid) EQ 0 THEN windowid = -1
   IF N_Elements(name) EQ 0 THEN name = 'Panel: ' + strtrim(id+1, 2) 
   IF N_Elements(labelmargin) EQ 0 THEN labelmargin = 0
   IF NOT Obj_Valid(settings) THEN settings = Obj_New('SPD_UI_PANEL_SETTINGS')
   if not obj_valid(legendSettings) then legendSettings = obj_new('SPD_UI_LEGEND')
   if ~obj_valid(xaxis) then xaxis = Obj_New()
   if ~obj_valid(yaxis) then yaxis = Obj_New()
   if ~obj_valid(zaxis) then zaxis = obj_new()
   if ~obj_valid(traceSettings) then traceSettings = obj_new('IDL_Container')
   IF N_Elements(tracking) EQ 0 THEN tracking = 1
   IF N_Elements(isactive) EQ 0 THEN isactive = 1
   IF N_Elements(syncflag) EQ 0 THEN syncflag = 1
   IF NOT Obj_Valid(variables) THEN variables = Obj_New('IDL_Container')
   IF NOT Obj_Valid(markers) THEN markers = Obj_New('IDL_Container')
   if n_elements(showvariables) eq 0 then showvariables = 1

  ; Set all parameters

   self.traceSettings = traceSettings
   self.windowID = windowid
   self.name = name
   self.id = id
   self.settings = settings
   self.legendSettings = legendSettings
   self.xAxis = xaxis
   self.yAxis = yaxis
   self.zAxis = zaxis
   self.tracking = tracking
   self.isActive = isactive
   self.syncFlag = syncflag
   self.variables = variables
   self.markers = markers
   self.showvariables = showvariables
   self.labelmargin = labelmargin
   
   if ~keyword_set(nosave) then begin
      self->save
   endif
  
   RETURN, 1
END ;--------------------------------------------------------------------------------                 

PRO SPD_UI_PANEL__DEFINE

  ;note that id is no longer unique, if we want to add code to make it unique, 
  ;I think we can use shmmap & shmvar, or get_var & set_var
   struct = { SPD_UI_PANEL,           $

              name: '',               $ ; name for this panel              
              id: 0,                  $ ; numerical identifier for this panel
              windowID: 0,            $ ; ID for window this panel is displayed on
              settings: Obj_New(),    $ ; setting object for this panel           
              traceSettings:Obj_New(),$ ; IDL_Container object storing trace settings for each set of data quantities to be plotted
              xAxis: Obj_New(),       $ ; x axis properties object
              yAxis: Obj_New(),       $ ; y axis properties object
              zAxis: Obj_new(),       $ ; z axis properties object
              tracking: 0,            $ ; flag set if tracking is on
              isActive: 0,            $ ; flag set if panel is displayed
              variables: Obj_New(),   $ ; idl container of variables
              markers: Obj_New(),     $ ; idl container of markers
              showvariables:0,        $ ; flag indicates whether variables should be displayed or not
              labelmargin: 0,         $ ; label margin for panel
              syncFlag: 0,            $ ; flag indicating whether to sync labels and traces
              origsettings: ptr_new(),$ ; pointer to original settings in case of reset
              legendSettings: Obj_New(), $ ; legend settings object for this panel
              INHERITS SPD_UI_READWRITE, $ ; generalized read/write methods
              inherits spd_ui_getset $ ; generalized setProperty/getProperty/getAll/setAll methods   
                                     
}

END
