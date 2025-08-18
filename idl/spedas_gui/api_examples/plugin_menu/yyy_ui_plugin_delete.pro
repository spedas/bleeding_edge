;+
;Procedure:
;  yyy_ui_plugin_delete
;
;Purpose:
;  This is an example of a helper routine for GUI plugins.
;  Plugin helper routines perform operations on GUI data
;  and allow those operations to be reproduced when loading
;  GUI documents (see API requirements below).
;
;Calling Sequence:
;  yyy_ui_plugin_delete, loaded_data, history_window, status_bar, 
;                        names=names
;
;API Input:
;  loaded_data:  GUI loaded data object
;  status_bar:  GUI status bar object
;
;Other Input:
;  names:  (string) Array of names of specifying which variables in
;                   the loaded data object are to be operated on.  
;
;Output:
;  none
;
;API Requirements:
;  -GUI objects must be passed by keyword.
;  -Routine must include the _extra keyword.
;
;See Also:
;   yyy_ui_plugin
;   yyy_ui_plugin_add
;   yyy_ui_plugin_randomize
;
;Notes:  
;
;
;$LastChangedBy: aaflores $
;$LastChangedDate: 2014-03-18 18:27:19 -0700 (Tue, 18 Mar 2014) $
;$LastChangedRevision: 14584 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/spedas_gui/api_examples/plugin_menu/yyy_ui_plugin_delete.pro $
;
;-
pro yyy_ui_plugin_delete,$ ;API Inputs 
                          loaded_data=loaded_data, $
                          status_bar=status_bar, $
                           ;Inputs specific to this routine
                          names=names, $
                           ;API Required
                          _extra=_extra

                          

  compile_opt idl2, hidden


  status_bar->update, 'Deleting selected variables...'


  ;loop over variables to remove them from the loaded data object
  for i=0, n_elements(names)-1 do begin

    ok = loaded_data->remove(names[i])

  endfor

  status_bar->update, 'Variables deleted.'

end
