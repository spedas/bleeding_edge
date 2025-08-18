PRO spd_ui_rubber_band_box, info

      ; Catch any errors here
     
   Catch, theError
   IF theError NE 0 THEN BEGIN
      Catch, /Cancel
      ok = Error_Message(Traceback=1)
      RETURN
   ENDIF
     
   rubberBandXOnlyId = widget_info(info.master,find_by_uname='RUBBERBANDX')
   
     
   ; Get the position of the rubber band box
   rubberBandStruc = info.drawObject->GetRubberBandPos(xonly=widget_info(rubberBandXOnlyId,/button_set))

   IF Is_Num(rubberBandStruc) EQ 1 THEN BEGIN

      info.statusBar->update, 'Invalid rubber band box position information. Unable to complete rubber band operation.'
      info.historyWin->update, 'Invalid rubber band box position information. Unable to complete rubber band operation.'
      RETURN
      
   ENDIF ELSE BEGIN
   
     ; Get active window panels container
     activeWindow=info.windowStorage->GetActive()
     activeWindow->getProperty,locked=locked
     newLocked = -1
     newPanels=Obj_New('IDL_CONTAINER')
     numNewPanels=N_Elements(rubberBandStruc)
     panelId=0
     IF N_Elements(activeWindow) GT 0 && Obj_Valid(activeWindow[0]) THEN BEGIN
       activeWindow[0]->GetProperty, Panels=panels
       IF Obj_Valid(panels) THEN BEGIN
         panelObjs = panels->Get(/all)
         IF NOT Is_Num(panelObjs) THEN BEGIN
           ;see if we need to switch the locked panel  
           ; for each panel object, copy the panel, update
           ; the range, and add it to the newPanels container object
           newPanelList = panelObjs[rubberBandStruc[*].idx]
           for i = 0,numNewPanels-1 do begin
             ;update locked flag, if panel moved
             if locked eq rubberBandStruc[i].idx then begin
               newLocked = i
             endif
             newPanel=newPanelList[i]->Copy()
             newPanel->GetProperty, XAxis=xaxis,yaxis=yaxis
             xAxis->setProperty, rangeOption=2
             xaxis->UpdateRange, rubberBandStruc[i].xRange
             ;yAxis->setProperty, rangeOption=2
             
             ;if this option is set on front panel, rubber band will only constrain on x-range
             if ~widget_info(rubberBandXOnlyId,/button_set) then begin
               yAxis->setProperty, rangeOption=2
               yaxis->UpdateRange, rubberBandStruc[i].yRange
             endif
             
             newPanel->SetProperty, Id=panelId, XAxis=xaxis, YAxis=yaxis
             newPanels->Add, newPanel
             panelId=panelId+1         
           endfor        
           
           if locked ne -1 && newlocked eq -1 then begin
             newLocked = n_elements(newPanels)-1
           endif

         ENDIF ELSE BEGIN

           info.statusBar->update, 'No panels retrieved. Unable to complete rubber band operation.'         
           info.historyWin->update, 'No panels retrieved. Unable to complete rubber band operation.'         
           RETURN
           
         ENDELSE

      ENDIF ELSE BEGIN

         info.statusBar->update, 'Unable to retrieve panel information. Rubber band operation cancelled.'         
         info.historyWin->update, 'Unable to retrieve panel information. Rubber band operation cancelled.'         
         RETURN
         
       ENDELSE

     ENDIF ELSE BEGIN
    
       info.statusBar->update, 'Unable to retrieve active window information. Rubber band operation cancelled.'
       info.historyWin->update, 'Unable to retrieve active window information. Rubber band operation cancelled.'
       RETURN
       
     ENDELSE
      
     ; Create new window and object
     activeWindow->GetProperty, Settings=settings, Tracking=tracking, Locked=oldLocked
     result=info.windowStorage->Add(Settings=settings, Tracking=tracking, Panels=newPanels, $
        IsActive=1, Locked=newlocked)
        
     ; Update the window menu
     activeWindow=info.windowStorage->GetActive()
     activeWindow[0]->GetProperty, Name=name
     activeWindow[0]->RePack
     
     info.windowMenus->Add, name
     info.windowMenus->Update, info.windowStorage
     
     ; Update and draw
     info.drawObject->update,info.windowStorage, info.loadedData
     info.drawObject->draw
     ;info.drawObject->update,info.windowStorage, info.loadedData
     ;info.drawObject->draw
     info.statusBar->update, 'Rubber band operation successful. New page created.'
     info.historyWin->update, 'Rubber band operation successful. New page created.'

   ENDELSE      

END
