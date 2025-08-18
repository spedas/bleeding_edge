;+
;Procedure:
;  yyy_ui_plugin_add
;
;Purpose:
;  This is an example of a helper routine for GUI plugins.
;  Plugin helper routines perform operations on GUI data
;  and allow those operations to be reproduced when loading
;  GUI documents (see API requirements below).
;  
;  This example demostrates adding a new variable to the
;  loaded data object.
;
;Calling Sequence:
;  yyy_ui_plugin_add, loaded_data, history_window, status_bar
;
;API Required Input:
;  loaded_data:  GUI loaded data object
;  history_window:  GUI history window object
;  status_bar:  GUI status bar object

;Other Input:
;  none
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
;   yyy_ui_plugin_randomize
;   yyy_ui_plugin_delete
;
;Notes:  
;
;
;$LastChangedBy: aaflores $
;$LastChangedDate: 2014-03-18 18:27:19 -0700 (Tue, 18 Mar 2014) $
;$LastChangedRevision: 14584 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/spedas_gui/api_examples/plugin_menu/yyy_ui_plugin_add.pro $
;
;-
pro yyy_ui_plugin_add,$ ;API Inputs 
                       loaded_data=loaded_data, $
                       history_window=history_window, $
                       status_bar=status_bar, $
                        ;API Required
                       _extra=_extra

  compile_opt idl2, hidden

  
  ;Create simple test variable
  ;----------------------------------------------
  test_var = 'test_var'
  status_bar->update, 'Adding test variable: '+test_var

  seed = dindgen(1e4)

  t = seed + time_double('2007-03-23/00')

  d = [ [sin( seed/360 )], $
        [cos( seed/360 )], $
        [sin( seed/180 )]  ]

  ;Add new variable to loaded data object
  ;----------------------------------------------
  ;  Data is added in structure format as in tplot.  Metadata can be specified
  ;  with keyword and/or via the limit and dlimit structures (see yyy_ui_plugin_randomize).
  ;  Here example values are added for tree placement and coordinates.
  ok = loaded_data->addData(test_var, {x:t, y:d}, $
                      mission='TEST MISSION', observatory='TEST OBS', $
                      instrument='TEST INST', coordsys='gsm', units='eV')

  if ~ok then begin
    ;send message to status bar and history window and display a dialog message
    spd_ui_message, 'Error adding "'+test_var+'".', sb=status_bar, hw=history_window, /dialog, /dontshow
  endif else begin
    status_bar->update, 'Added "'+test_var+'".'
  endelse


end

