PRO spd_ui_delete_marker, info

statusBar=info.statusBar
historywin=info.historywin

count=0
activeWindow = info.windowStorage->GetActive()
IF NOT Obj_Valid(activeWindow) THEN BEGIN
  statusBar->Update, 'There is no active window. No markers to delete.'
  historywin->Update, 'There is no active window. No markers to delete.'
  RETURN  
ENDIF ELSE BEGIN
  activeWindow->GetProperty, Panels=panels
  IF NOT Obj_Valid(panels) THEN BEGIN
    statusBar->Update, 'There are no panels. No markers to delete.'
    historywin->Update, 'There are no panels. No markers to delete.'
    RETURN 
  ENDIF ELSE BEGIN
    panelObjs = panels->Get(/all)
    IF Is_Num(panelObjs) OR N_Elements(panelObjs) LT 1 THEN BEGIN
      statusBar->Update, 'There are no panels. No markers to delete.'
      historywin->Update, 'There are no panels. No markers to delete.'
      RETURN  
    ENDIF ELSE BEGIN
      numPanels=N_Elements(panelObjs)
      FOR i=0,numPanels-1 DO BEGIN
         panelObjs[i]->GetProperty, Markers=markers
         IF NOT Obj_Valid(markers) THEN CONTINUE 
         markerObjs = markers->Get(/All)
         IF Is_Num(markerObjs) OR N_Elements(markerObjs) LT 1 THEN BEGIN
           ;info.statusBar->Update, 'There are no markers to delete.'
           CONTINUE  
         ENDIF 
         FOR j=0, N_Elements(markerObjs)-1 DO BEGIN
             markerObjs[j]->GetProperty, IsSelected=isselected
             IF isselected EQ 1 THEN  BEGIN
               markers->Remove, Position=j
               count++
             ENDIF
         ENDFOR              
      ENDFOR
      
    ENDELSE
  ENDELSE
ENDELSE 

statusBar->update,strtrim(count,1)+' Marker(s) Deleted.'
historywin->update,strtrim(count,1)+' Marker(s) Deleted.'

info.drawObject->Update, info.windowStorage, info.loadedData
info.drawObject->Draw

END
