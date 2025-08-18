
;+
;Procedure:
;  spd_ui_plugin_replay
;
;Purpose:
;  Replays data modification operations performed by GUI plugins when loading GUI documents.
;
;Calling Sequence:
;  spd_ui_plugin_replay, procedure, parameters, loaded_data, history_window, status_bar
;
;Input:
;  procedure: (string) name of plugin routine to be called
;  parameters: (stuct/int) Anonymous struct conforming to keywords for named routine
;                          or 0 if no keywords specified.
;  loaded_data: (obj) reference to loaded_data object
;  history_window: (obj) reference to history window object
;  status_bar: (obj) reference to status bar object
;
;Output:
;  none
;
;Notes:
;
;
;$LastChangedBy: egrimes $
;$LastChangedDate: 2014-05-05 13:39:26 -0700 (Mon, 05 May 2014) $
;$LastChangedRevision: 15050 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/spedas_gui/utilities/spd_ui_plugin_replay.pro $
;
;-

pro spd_ui_plugin_replay, procedure, $
                          parameters, $
                          loaded_data, $
                          infoptr, $ ;temporary until tracking reworked
                          history_window, $
                          status_bar

    compile_opt idl2, hidden


  if ~is_string(procedure) then begin
    return
  endif
  
  ;check that procedure is in path
  if ~spd_find_file(procedure+'.pro') then begin
    x = 'The plugin routine "'+procedure+'.pro" could not be located.  '+ $
        'Check that file exists in the current IDL path.'
    spd_ui_message, x, sb=status_bar, hw=history_window 
    return
  endif
  
  
  ;call the procedure
  ;  -"parameters" will allways be defined but must be a struct
  ;   to be passed through _extra
  ;  -if procedure the being called does not implement one or more
  ;   API keyword they will be added to the _extra structure
  if is_struct(parameters) then begin
    call_procedure, procedure, $
                    loaded_data=loaded_data, $
                    history_window=history_window, $
                    status_bar=status_bar, $
                    _extra=parameters
  
    ;Temporary kludge to replay single-panel tracking requests
    ;In the future, track should be tracked by object settings,
    ;which will then be saved directly in XML.
    if in_set('track_one',strlowcase(tag_names(parameters))) then begin
      if keyword_set(parameters.track_one) then begin
        spd_ui_track_one, *infoptr
      endif
    endif
  
  endif else begin
    call_procedure, procedure, $
                    loaded_data=loaded_data, $
                    history_window=history_window, $
                    status_bar=status_bar
  endelse
  
  
end
