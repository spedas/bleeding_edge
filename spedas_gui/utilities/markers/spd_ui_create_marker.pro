
;+ 
;NAME:  
; spd_ui_create_marker
;
;PURPOSE:
; creates a marker
;
;CALLING SEQUENCE
; spd_ui_create_marker,infostruct
;
;Inputs:
; info - the main information structure
; 
;HISTORY:
;
;$LastChangedBy: jimm $
;$LastChangedDate: 2014-02-11 10:54:32 -0800 (Tue, 11 Feb 2014) $
;$LastChangedRevision: 14326 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/spedas_gui/utilities/markers/spd_ui_create_marker.pro $
;-
PRO spd_ui_create_marker, info

  compile_opt idl2,hidden
   
  windowStorage = info.windowStorage
  drawObject = info.drawObject
  pageSettings = info.pageSettings
  statusBar = info.statusBar
  historywin = info.historywin
  
  newMarkers = drawObject->GetMarkers()

  if info.markerfail eq 1 then begin
    statusBar->update,'Marker was not created: Invalid Click'
    historywin->update,'Marker was not created: Invalid Click'
    return
  endif
  
  IF Is_Num(newMarkers) && newMarkers EQ 0 THEN BEGIN
    statusBar->update,'Marker was not created'
    historywin->update,'Marker was not created'
    dprint,  'Marker was not created'
    return
  ENDIF 
  
  activeWindow = windowStorage->GetActive()
  IF NOT Obj_Valid(activeWindow) THEN BEGIN
    statusBar->update,'Marker not created: no active window'
    historywin->update,'Marker not created: no active window'
    dprint,  'Marker not created: no active window'
    return  
  ENDIF
  
  activeWindow->GetProperty, Panels=panels
  IF ~Obj_Valid(panels) THEN BEGIN
    statusBar->update,'Marker not created: no panels'
    historywin->update,'Marker not created: no panels'
    dprint,  'Marker not created: no panels'
    return  
  ENDIF
  
  panelObjs = panels->Get(/all)
  IF Is_Num(panelObjs) || ~obj_valid(panelObjs[0]) THEN BEGIN
    statusBar->update,'Marker not created: no panels'
    historywin->update,'Marker not created: no panels'
    dprint,  'Marker not created: no panels'
    return  
  ENDIF

  invalidList = ''
  windowdims = drawobject->getdim()
    
  markerPanels = panelObjs[newMarkers[*].idx]
  
;  if info.markerTitleOn then begin
;    markerTitle = spd_ui_marker_title( info.master,info.historywin, info.statusbar) 
;  endif else begin
;    markerTitle=obj_new('SPD_UI_MARKER_TITLE', cancelled = 0) ; cancelled is set by default
;  endelse
;    
;  markerTitle->getProperty,cancelled=cancelled
;  if keyword_set(cancelled) then begin
;    markerTitle=obj_new('spd_ui_marker_title')
;    return
;  endif
  
        
  ; only prompt for marker title if we've decided the marker is wide enough to draw
  ; at least on the first panel... don't' want it to prompt for title for
  ; each panel, only the first panel. This check is to avoid it prompting for title 
  ; if the user ctrl-clicks without dragging.
  markerPanels[0]->GetProperty, Markers=markerstmp
  newMarkers[0].marker->GetProperty, Settings=markerSettingstmp,range=rangetmp
    
  panelInfotmp = drawObject->getPanelInfo(newMarkers[0].idx)
  if ~is_struct(panelInfotmp) then begin
      statusBar->update,'Marker not created: panel error'
      historywin->update,'Marker not created: panel error'
      return
  endif
  panelxrangetmp=panelinfotmp.xrange
  
  if windowdims[0]*(rangetmp[1]-rangetmp[0])/(panelxrangetmp[1]-panelxrangetmp[0]) ge 2D then begin
      if info.markerTitleOn then begin
        markerTitle = spd_ui_marker_title( info.master,info.historywin, info.statusbar) 
      endif else begin
        markerTitle=obj_new('SPD_UI_MARKER_TITLE', cancelled = 0) ; cancelled is set by default
      endelse
    
      markerTitle->getProperty,cancelled=cancelled
      if keyword_set(cancelled) then begin
        markerTitle=obj_new('spd_ui_marker_title')
        return
      endif
  endif
  
  
  for i = 0,n_elements(markerPanels)-1 do begin
      
    markerPanels[i]->GetProperty, Markers=markers
    newMarkers[i].marker->GetProperty, Settings=markerSettings,range=range
    
    panelInfo = drawObject->getPanelInfo(newMarkers[i].idx)
    if ~is_struct(panelInfo) then begin
      statusBar->update,'Marker not created: panel error'
      historywin->update,'Marker not created: panel error'
      return
    endif

   

;Marker width test should be in visual display units not physical units.  
;So this conversion to physical units from below should not be used
;    if panelInfo.xscale eq 1 then begin
;      panelxrange=10D^panelinfo.xrange
;    endif else if panelinfo.xscale eq 2 then begin
;      panelxrange=exp(panelinfo.xrange)
;    endif else begin
;      panelxrange = panelinfo.xrange
;    endelse 

    panelxrange=panelinfo.xrange

    ;check marker width prior to adding
    if windowdims[0]*(range[1]-range[0])/(panelxrange[1]-panelxrange[0]) ge 2D then begin
       
      markerSettings->GetProperty, Label=label
      markerTitle->GetProperty, name=name, UseDefault=usedefault, DefaultName=defaultname  
      IF UseDefault EQ 1 THEN markerName=defaultname ELSE markerName=name      
      pageSettings->GetProperty, Marker=markerTextObject
      markerTextObject->GetProperty, Size=size, Font=font, Format=format, Color=color, $
        Thickness=thickness, Show=show
      label->SetProperty, Value=markername, Size=size, Font=font, Format=format, Color=color, $
        Thickness=thickness, Show=show
      markerSettings->SetProperty, VertPlacement=0
      newMarkers[i].marker->SetProperty, Name=markername
      markers->Add, newMarkers[i].marker
    endif else begin
      if ~keyword_set(invalidlist) then begin
        invalidlist = markerPanels[i]->constructPanelName()
      endif else begin
        invalidList = [invalidList,markerPanels[i]->constructPanelName()]
      endelse
    endelse
  endfor
 
  if keyword_set(invalidList) then begin
    outlist = strjoin(invalidList,' , ')
    statusBar->update,'Marker not wide enough. Could not be added to panel(s): ' + outlist
    historyWin->update,'Marker not wide enough. Could not be added to panel(s): ' + outlist
  endif else begin
    statusBar->update,'Marker(s) created.'
    historywin->update,'Marker(s) created.'
  endelse

END
