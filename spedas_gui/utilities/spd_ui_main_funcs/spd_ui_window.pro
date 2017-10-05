 ;+
;
;  Name: SPD_UI_WINDOW
;  
;  Purpose: Opens a new window
;  
;  Inputs: The info structure from the main gui
;
;
;$LastChangedBy: jimm $
;$LastChangedDate: 2014-02-11 10:54:32 -0800 (Tue, 11 Feb 2014) $
;$LastChangedRevision: 14326 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/spedas_gui/utilities/spd_ui_main_funcs/spd_ui_window.pro $
;-
pro spd_ui_window,info

  compile_opt idl2
   
       result=info.windowStorage->Add(Settings=info.pageSettings)
       activeWindow=info.windowStorage->GetActive()
       activeWindow[0]->GetProperty, Name=name
       info.windowMenus->Add, name
       info.windowMenus->Update, info.windowStorage
       spd_ui_orientation_update,info.drawObject,info.windowStorage
       info.drawObject->update,info.windowStorage, info.loadedData
       info.drawObject->draw
       info.scrollbar->update
       info.historywin->update,name + ' has been created.
RETURN
end
