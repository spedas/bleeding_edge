;NAME: 
; spd_ui_document__define
;
;PURPOSE:
; Helper object for save/load SPEDAS document.  
;
;CALLING SEQUENCE:
;
;OUTPUT:
;
;ATTRIBUTES:
; Active window object
; callSequence object
;
;METHODS:
; GetDOMElement        (inherited from spd_ui_readwrite)
; BuildFromDOMElement  (inherited from spd_ui_readwrite)
;
;HISTORY:
;
;$LastChangedBy: egrimes $
;$LastChangedDate: 2015-07-09 15:04:29 -0700 (Thu, 09 Jul 2015) $
;$LastChangedRevision: 18054 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/spedas_gui/objects/spd_ui_document__define.pro $
;-----------------------------------------------------------------------------------

; spd_ui_document owns the windowContainer object, and the container
; (but not the windows it contains) should be destroyed at cleanup time 
; to prevent a memory leak.
;
; The callSequence object will have other outstanding references
; and should not be destroyed at cleanup time.

pro spd_ui_document::cleanup
   ; Without the following line, it seems that the objects in 
   ; windowContainer get destroyed when the container is destroyed,
   ; invalidating the window object references held by the original
   ; windowStorage object.  So we need to ensure that the container
   ; gets emptied before destroying it.

   self.windowContainer->Remove,/all

   obj_destroy,self.windowContainer
end

pro spd_ui_document::onLoad,ptr_to_info

    ; get the objects we need from the pointer to the main info struct
    windowStorage = (*ptr_to_info).windowStorage
    windowMenus = (*ptr_to_info).windowMenus
    loadedData = (*ptr_to_info).loadedData
    historywin = (*ptr_to_info).historyWin
    statusbar = (*ptr_to_info).statusBar
    guiID = (*ptr_to_info).master
    
    
    historywin->Update,'spd_ui_document::onLoad: setting loadedData attribute of call_sequence object', dontshow=1
    dprint, 'spd_ui_document::onLoad: setting loadedData attribute of call_sequence object'
    ; Set loadedData attribute of call_sequence object
    self.callSequence->setLoadedData,loadedData
    
    historywin->Update,'spd_ui_document::onLoad: Resetting windowStorage object', dontshow=1
    dprint, 'spd_ui_document::onLoad: Resetting windowStorage object'
    ; Reset windowStorage object, passing the new callSequence object
    windowStorage->Reset,callSequence=self.callSequence
    
    historywin->Update,'spd_ui_document::onLoad: Replaying callSequence data loading calls', dontshow=1
    dprint, 'spd_ui_document::onLoad: Replaying callSequence data loading calls'
    ; Replay callSequence calls
    self.callSequence->reCall,historywin=historywin,statustext=statusbar,guiId=guiID,infoptr=ptr_to_info,windowstorage=windowstorage
    
    ; Remove everything from windowMenus object
    historywin->Update,'spd_ui_document::onLoad: Removing old windows from windowMenus object', dontshow=1
    dprint, 'spd_ui_document::onLoad: Removing old windows from windowMenus object'
    
    wm_names=windowMenus->GetNames()
    
    for i=0,n_elements(wm_names)-1 do begin
       windowMenus->Remove,wm_names[i]
    endfor
    
    historywin->Update,'spd_ui_document::onLoad: Adding new windows to windowStorage object', dontshow=1
    dprint, 'spd_ui_document::onLoad: Adding new windows to windowStorage object'
    ; Add each new window to the windowstorage object
    window_array=self.windowContainer->Get(/all,count=window_count)
    
    for i=0,window_count-1 do begin
       w=window_array[i]
       result = windowStorage->AddNewObject(w)
       if (result EQ 0) then begin
         message,'Unknown failure adding window object to windowStorage.'
       endif
       ; Update the window menus
       w->GetProperty, Name=name
       windowMenus->Add, name
     ;  windowMenus->Update, windowStorage  ; FIXME: is this necessary here? NO, in fact due to bug in update method, will sometimes cause a crash.
    endfor
    
    
    ; Set first window active in windowStorage
    historywin->Update,'spd_ui_document::onLoad: Setting window 1 active in windowStorage', dontshow=1
    dprint, 'spd_ui_document::onLoad: Setting window 1 active in windowStorage'
    
    windowStorage->SetActive,id=1
    
    ; Update windowMenus again (FIXME: is this necessary?)
    historywin->Update,'spd_ui_document::onLoad: Updating windowMenus with newly loaded windows', dontshow=1
    dprint, 'spd_ui_document::onLoad: Updating windowMenus with newly loaded windows'
    
    ;note, this will crash if the wrong number of names were added to windowMenus
    windowMenus->Update, windowStorage


end

FUNCTION SPD_UI_DOCUMENT::Init,windowStorage

   Catch, theError
   IF theError NE 0 THEN BEGIN
      Catch, /Cancel
      ok = Error_Message(Traceback=1)
      RETURN, 0
   ENDIF

   ; We may initialize this object with a windowStorage object
   ; (when saving a document), or with no arguments (when loading
   ; a document)

   if (n_elements(windowStorage) NE 0) then begin
      ; Initialize windowContainer from windowStorage object

      self.windowContainer=obj_new('IDL_CONTAINER')
      windowStorage->GetProperty,windowObjs=ptr_window_array
      ; Deference pointer and store each array element in windowContainer
      if (ptr_valid(ptr_window_array) NE 0) then begin
         window_array=*ptr_window_array
         for i=0,n_elements(window_array)-1 do begin
           self.windowContainer->Add,window_array[i]
         endfor
      endif

      ; Initialize callSequence from windowStorage object
      windowStorage->GetProperty,callSequence=ws_call_sequence
      self.callSequence=ws_call_sequence
   endif else begin
      ; Initialize windowContainer to empty container
      self.windowContainer=obj_new('IDL_CONTAINER')

      ; Initialize callSequence to null object
      self.callSequence = obj_new();
   endelse
       
   RETURN, 1
END ;--------------------------------------------------------------------------------


PRO SPD_UI_DOCUMENT__DEFINE

   struct = { SPD_UI_DOCUMENT,    $

              windowContainer: obj_new(), $ 
              callSequence: obj_new(), $
              INHERITS spd_ui_readwrite $ 
}

END
