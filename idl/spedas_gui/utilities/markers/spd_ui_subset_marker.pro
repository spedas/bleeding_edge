PRO spd_ui_subset_marker, info

     activeWindow = info.windowStorage->GetActive()
     IF NOT Obj_Valid(activeWindow) THEN BEGIN
        info.statusBar->Update, 'There is no active window, unable to create a marker subset'
        RETURN
     ENDIF
     activeWindow->GetProperty, Panels=panels
     IF NOT Obj_Valid(panels) THEN BEGIN
        info.statusBar->Update, 'There are no panels or markers to create a marker subset'
        RETURN
     ENDIF
     ; get all the panels and determine which one has the active marker
     panelObjs = panels->Get(/all)
     IF Is_Num(panelObjs) THEN BEGIN
        info.statusBar->Update, 'There are no panels or markers to create a marker subset'
        RETURN
     ENDIF
     panelIdx=-1
     FOR i=0, N_Elements(panelObjs)-1 DO BEGIN
         panelObjs[i]->GetProperty, Id=id, Markers=markers
         IF ~Obj_Valid(markers) THEN BEGIN
            ;info.statusBar->Update, 'There are no markers on this panel to create a marker subset'
            continue
         ENDIF
         ; retrieve all the markers and determine which one mataches the clickStruc
         markerObjs = markers->Get(/All)
         IF ~obj_valid(markerObjs[0]) THEN BEGIN
            ;info.statusBar->Update, 'There are no markers on this panel to create a marker subset'
            continue
         ENDIF
         FOR j=0,N_Elements(markerObjs)-1 DO BEGIN 
             markerObjs[j]->GetProperty, IsSelected=isselected
             IF isselected EQ 1 THEN BEGIN
                selectedMarker=markerObjs[j]
                newPanel=panelObjs[i]->Copy()
                panelIdx=i
                BREAK
             ENDIF
         ENDFOR
         IF panelIdx NE -1 THEN BREAK
      ENDFOR
      
      IF ~Obj_Valid(selectedMarker) THEN BEGIN
         info.statusBar->Update, 'No selected marker was found. Subset not created.' 
         RETURN
      ENDIF
      
      ;if made it here then the panel and marker have been identified
      ;create a new panel container for the new window with the new marker range
      newPanels = Obj_New("IDL_CONTAINER")
      newPanel->GetProperty, XAxis=xaxis, Settings=settings, Id=id
      selectedMarker->GetProperty, Range=range
      panelStruc = info.drawObject->GetPanelInfo(panelIdx)
      IF id NE 0 THEN id = 0   ;New panel's ID should be zero
      IF panelStruc.xScale EQ 1 THEN range = alog10(range)
      IF panelStruc.xScale EQ 2 THEN range = alog(range)
      ;set fixed range to guarantee exact ranging
      xaxis->setProperty,rangeOption=2
      xaxis->UpdateRange, range
      settings->SetProperty, Row=1, Col=1
      
      markerContainer = obj_new('IDL_Container')
      
      ;copy all markers but the selected marker
      ;into the new object.
      for i = 0,n_elements(markerObjs)-1 do begin
      
        ;No longer removes out of bounds markers from the list, draw object now disqualifies based on internal criterion
        ;if markerObjs[i] ne selectedMarker then begin
        ;markerContainer->add,markerObjs[i]->copy()
        ;endif
        
        markerContainer->add,markerObjs[i]->copy()
      endfor
      
      newPanel->SetProperty, Markers=markerContainer, id=id                    
      newPanels->Add, newPanel           
      
      ;create new window for the marker subset    
      activeWindow->GetProperty, NRows=nrows, NCols=ncols, Panels=panels, Settings=settings, $
        Tracking=tracking,locked=locked
        
      ;since we're pulling only one panel at most.
      ;This makes sure that if anything was locked
      ;the locked flag is propagated to the new panel
      if locked ne -1 then begin
        locked = 0
      endif
        
      result = info.windowStorage->Add(NRows=nrows, NCols=ncols, Panels=newPanels, Settings=settings, $
        Tracking=tracking,locked=locked) 
        
      ;update the window menus
      activeWindow = info.windowStorage->GetActive()
      activeWindow->GetProperty, Name=name 
      
      activeWindow[0]->RePack
      
      info.windowMenus->Add, name
      info.windowMenus->Update, info.windowStorage
      
      ;update the draw window
      info.drawObject->update,info.windowStorage, info.loadedData
      info.drawObject->draw
      info.scrollbar->update
            
;      lockObj = obj_new('spd_ui_lock_axes',info.windowStorage,info.drawObject,info.loadedData)
;     
;      if locked then begin
;        lockObj->lock
;      endif
     
      info.drawObject->update,info.windowStorage, info.loadedData
      info.drawObject->draw
      
END
