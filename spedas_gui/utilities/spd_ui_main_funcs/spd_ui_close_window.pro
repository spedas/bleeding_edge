PRO spd_ui_close_window, info
    ; check if this is the last page
    ; if so, ask the user if they want to close it
    ids=info.windowMenus->GetIds()
    result = "Yes"
    IF N_Elements(ids) EQ 1 THEN  begin
          Result = DIALOG_MESSAGE("Do you want to close the last remaining page?", $
              TITLE="Close Page", DIALOG_PARENT=info.master, /CENTER, /QUESTION, /DEFAULT_NO) 
    ENDIF
    IF result EQ "Yes" THEN BEGIN
        IF info.marking EQ 0 && info.rubberbanding EQ 0 THEN BEGIN
            info.ctrl=0
            error=0
            ; remove the active window from window storage 
            windowObjs = info.windowStorage->GetObjects()
            prevNumWin = N_Elements(windowObjs)
            activeWindow = info.windowStorage->GetActive()
            activeWindow->GetProperty, Name=activeName
            result = info.windowStorage->RemoveObject(activeWindow)     
            IF RESULT EQ -1 THEN BEGIN
              statusMessage = 'An error occurred closing the page. ' + name + ' has not been closed.'
              info.statusBar->Update, statusMessage
            ENDIF ELSE BEGIN
              activeWindow = info.windowStorage->GetActive()
              IF ~Obj_Valid(activeWindow) THEN BEGIN
                ; check that this wasn't the last window, if so create a blank one
                info.windowMenus->Remove, activeName
                info.windowMenus->Update, info.windowStorage
                result=info.windowStorage->Add(Settings=info.pageSettings)
                activeWindow=info.windowStorage->GetActive()
                activeWindow[0]->GetProperty, Name=name
                info.windowMenus->Add, name
                info.windowMenus->Update, info.windowStorage
              ENDIF ELSE BEGIN
                ; remove the window from the window menus and update the screen
                info.windowMenus->Remove, activeName
                info.windowMenus->Update, info.windowStorage
              ENDELSE
              spd_ui_orientation_update,info.drawObject,info.windowStorage
              windowObjs = info.windowStorage->GetObjects()
              IF N_Elements(windowObjs) LE 1 && activeName EQ 'Page: 1' && prevNumWin EQ 1 THEN BEGIN
                statusMessage = activeName + ' has been cleared'
              ENDIF ELSE BEGIN
                statusMessage = activeName + ' has been closed'
              ENDELSE
              info.statusBar->Update, statusMessage  
              info.drawObject->update,info.windowStorage, info.loadedData
              info.drawObject->draw     
              info.scrollbar->update     
            ENDELSE  
           ;ENDIF 
       ENDIF
ENDIF
END
