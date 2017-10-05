;+
;Procedure:
;  spd_ui_call_plugin
;
;Purpose:
;  Opens specified GUI plugin window.
;
;Calling Sequence:
;  spd_ui_call_plugin, event, info
;
;Input:
;  event: event structure from plugin menu
;  info: Main storage structure from GUI
;
;Output:
;  none
;
;Notes:
;
;
;$LastChangedBy: nikos $
;$LastChangedDate: 2014-07-25 10:45:13 -0700 (Fri, 25 Jul 2014) $
;$LastChangedRevision: 15610 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/spedas_gui/utilities/spd_ui_call_plugin.pro $
;
;-

pro spd_ui_call_plugin, event, info


    compile_opt idl2, hidden

    widget_control, event.id, get_uvalue=plugin
  
    ; handle and report errors
    err_xxx = 0
    Catch, err_xxx
    IF (err_xxx NE 0) THEN BEGIN
      Catch, /Cancel
      spd_ui_message, 'The plugin "'+plugin.procedure+'" could not be found.  '+ $
        'Check that file exists in the current IDL path.', $
        sb=status_bar, hw=history_window, $
        /dialog, /error, /center, title='Plugin not found.'     
      RETURN
    ENDIF
    resolve_routine, plugin.procedure
    catch, /cancel
    info.statusBar->Update, 'Loaded plugin '+plugin.procedure 
    
  ;-------------------------------------------------------
  ; Call procedure
  ;-------------------------------------------------------
   
  if ptr_valid(plugin.data) && is_struct(*plugin.data) then begin
    data_structure = *plugin.data
  endif
  
  ;call sequence is stored in the window object (gui doc support) 
  info.windowStorage->getProperty,callSequence=call_Sequence
  
  ;Required inputs are passed as arguments, optional inputs use keywords
  call_procedure, plugin.procedure, $
                  gui_id = event.top, $
                  loaded_data = info.loadeddata, $
                  call_sequence = call_sequence, $
                  data_tree = info.guitree, $
                  time_range = info.loadtr, $
                  window_storage = info.windowStorage, $
                  history_window = info.historywin, $
                  status_bar = info.statusbar, $
                  data_structure = data_structure
                  
                  
  ;-------------------------------------------------------
  ; Update objects and other stored quantities
  ;-------------------------------------------------------
  
  if ~undefined(data_structure) && is_struct(data_structure) then begin
    plugin.data = ptr_new(data_structure)
    
    if in_set('track_one',strlowcase(tag_names(data_structure))) then begin
      if keyword_set(data_structure.track_one) then begin
        spd_ui_track_one, info
      endif
    endif
  endif
  
  widget_control, event.id, set_uvalue=plugin
  
  info.windowMenus->sync, info.windowStorage
  
  
  ;-------------------------------------------------------
  ; Update draw object and draw
  ;-------------------------------------------------------
  
;    ;needed for overview plots?
;    spd_ui_orientation_update,drawObject,windowStorage
    
    info.drawObject->Update,info.windowStorage,info.loadedData 
    info.drawObject->Draw
    spd_ui_update_title, info
end
