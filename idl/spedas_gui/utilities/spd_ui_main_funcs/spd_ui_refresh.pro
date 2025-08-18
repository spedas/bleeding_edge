;+
;
;  Name: SPD_UI_REFRESH
;  
;  Purpose: Refreshes the draw area of the GUI
;  
;  Inputs: The info structure from the main gui
;   
;
;
;$LastChangedBy: jimm $
;$LastChangedDate: 2014-02-11 10:54:32 -0800 (Tue, 11 Feb 2014) $
;$LastChangedRevision: 14326 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/spedas_gui/utilities/spd_ui_main_funcs/spd_ui_refresh.pro $
;-

pro spd_ui_refresh,info

  compile_opt idl2
  
  if is_struct(info) then begin
   info.drawObject->Update, info.windowStorage, info.loadedData
   info.drawObject->Draw
   info.statusBar->Update, 'The active window has been refreshed.'
   info.historyWin->Update, 'Active window has been refreshed.'     
  ENDif
  
end
