;+
;
;  Name: SPD_UI_SCROLLF
;  
;  Purpose: Scrolls the current window forwards
;  
;  Inputs: The info structure from the main gui
;
;
;$LastChangedBy: jimm $
;$LastChangedDate: 2014-02-11 10:54:32 -0800 (Tue, 11 Feb 2014) $
;$LastChangedRevision: 14326 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/spedas_gui/utilities/spd_ui_main_funcs/spd_ui_scrollf.pro $
;-

pro spd_ui_scrollf,info

  compile_opt idl2
  
  dataNames = info.loadedData->GetAll()
  IF Is_Num(dataNames) THEN BEGIN
    info.statusBar->Update, 'The scroll forward function is not available until data has been loaded.'
  ENDIF ELSE BEGIN
    spd_ui_scroll, info.windowStorage, info.drawObject, 0
    info.drawObject->Update, info.windowStorage, info.loadedData
    info.drawObject->Draw
    info.scrollbar->update
    info.statusBar->Update, 'The active window has been scrolled forward.'
    info.historyWin->Update, 'Active window has been scrolled forward.'     
  ENDELSE
  
end
