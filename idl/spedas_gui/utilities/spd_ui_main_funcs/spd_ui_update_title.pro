;+
;
;Purpose:
;  Update the GUI's top level base title.
;
;Input:
;  INFO: Info structure from the main GUI
;
;Notes:
;  The base title should be stored in INFO, 
;  the current page's name will be appended. 
;
;-
pro spd_ui_update_title, info

    compile_opt idl2, hidden

  if n_params() lt 1 || ~is_struct(info) || ~obj_valid(info.windowStorage) then return

  ;get current window's name
  activeWindow = info.windowStorage->getactive()
  activeWindow[0]->getproperty, name=name
  
  ;set title to currently stored title + the current page's name 
  widget_control, info.master, base_set_title = info.gui_title + ' - ' + name
  
end
