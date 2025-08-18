;+
;Procedure:
;  yyy_ui_plugin
;
;Purpose:
;  A basic example menu plugin for the SPEDAS GUI API.
;
;Calling Sequence:
;  See instructions in spedas/gui/resources/spd_ui_plugin_config.txt
;  to enable the plugin in the GUI.
;
;Input:
;  gui_id:  The widget ID of the top level GUI base.
;  loaded_data:  The GUI loaded data object.  This object stores all
;                data and corresponding metadata currently loaded
;                into the GUI.
;  call_sequence:  The GUI call sequence object.  This object stores
;                  a list of calls to external routines.  These calls
;                  are replicated when a GUI document is opened to
;                  reproduce those operations.
;  history_window:  The GUI history window object.  This object 
;                   provides a viewable textual history of GUI
;                   operations and error reports. 
;  status_bar:  The GUI status bar object.  This object displays 
;               informational messages at the bottom of the main 
;               GUI window.
;  data_tree:  The GUI data tree object.  This object provides a 
;              graphical tree of all loaded data variables.
;              A copy of this object can be used to create a
;              tree display within the plugin.
;  time_trange:  The GUI's main time range object.  This object
;                stores the current time range for the GUI and
;                may be used/modified by the plugin.
;
;Input/Output:
;  data_structure: This keyword may be used to return a data structure
;                  that will be saved by the GUI and passed back to
;                  the plugin the next time it is called.  This can be 
;                  used to save any information that could be needed
;                  on subsequent calls (e.g. time ranges, previous 
;                  operations, plugin specific option selections, etc.)  
;
;API Requirements:
;  -Plugins must accept the GUI top widget ID, loaded data object, 
;   call sequence object, history window object, and status bar object
;   (in that order) and must include the _extra keyword.
;  -The GUI data tree and time range objects may also be accessed
;   via the corresponding keywords, but are not required.
;  -Information for subsequent calls can be stored using the
;   data_structure keyword (described above).
;  -All operations performed by a plugin must be executed in separate
;   helper routines to be compatible with GUI document files.  See
;   yyy_ui_plugin_add, yyy_ui_plugin_delete, and yyy_ui_plugin_randomize 
;   for examples.
;
;Notes:
;
;
;$LastChangedBy: egrimes $
;$LastChangedDate: 2015-05-22 15:25:24 -0700 (Fri, 22 May 2015) $
;$LastChangedRevision: 17678 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/spedas_gui/api_examples/plugin_menu/yyy_ui_plugin.pro $
;-


;+
;Purpose:
;  Get the names of all currently selected variables from the tree widget.
;
;-
function yyy_ui_plugin_getselection, state

    compile_opt idl2, hidden

  ;get current selectrion from data tree
  variables = state.data_tree->getvalue()

  if ~ptr_valid(variables[0]) then begin
    state.status_bar->update, 'No valid selection.'
    return, ''
  endif

  ;loop over selected variables to get list
  for i=0, n_elements(variables)-1 do begin
    names = array_concat( (*variables[i]).groupname, names)
  endfor
  
  return, names
  
end


;+
;Purpose:
;  Example plugin event handler.
;
;-
pro yyy_ui_plugin_event, event

    compile_opt idl2, hidden


  ;Extract structure holding important object references and widget IDs.
  ;------------------------------------------------------------
  ;  If /no_copy is used the uvalue must be re-set before 
  ;  the event handler returns.
  widget_control, event.top, get_uval=state, /no_copy

  
  ;Error catch block
  ;------------------------------------------------------------
  catch, error
  if error ne 0 then begin
    catch, /cancel
    
    ;notify user
    help, /last_message
    dummy = dialog_message('An unexpected error occured, see console output.', $
              /error, /center, title='Unknown Error') 
    
    ;close plugin if state structure is no longer defined, 
    ;otherwise attempt to continue running
    if is_struct(state) then begin
      widget_control, event.top, set_uval=state, /no_copy
      return
    endif else begin
      print, '**FATAL PLUGIN ERROR - Closing window**'
      if widget_valid(event.top) then begin
        widget_control, event.top, /destroy
      endif
      return
    endelse
    
  endif
  
  
  ;catch kill requests
  if tag_names(event, /structure_name) eq 'WIDGET_KILL_REQUEST' then begin
    widget_control, event.top, /destroy
    return
  endif
  
  
  ;process the event based on which widget generated it
  ;------------------------------------------------------------
  uname = strlowcase(widget_info(event.id, /uname))
  if ~is_string(uname) then uname = ''


  case uname of 
    
    ;exit
    ;----------------------------------
    'ok': begin
      state.status_bar->update, 'Closing test plugin.'
      widget_control, event.top, set_uval=state, /no_copy ;necessary?
      widget_control, event.top, /destroy
      return
    end
    
    ;add test variable
    ; -demostrates adding a new variable to loaded data object
    ;----------------------------------
    'add': begin
      
      ;call helper routine
      yyy_ui_plugin_add, loaded_data=state.loaded_data, $
                         history_window=state.history_window, $
                         status_bar = state.status_bar
      
      ;Add to call sequence for GUI document replay
      ;  -specify name of routine that was just called
      ;  -specify any non-API keywords (none for this example)
      state.call_sequence->addPluginCall, 'yyy_ui_plugin_add' 
    end
    
    ;multiply data by scaled random factor
    ; -demonstrates retrieving a variable from loaded data object and
    ;  storing modified variable with identical metadata 
    ;----------------------------------
    'randomize': begin
      
      ;get selected names from tree
      names = yyy_ui_plugin_getselection(state)
      if ~is_string(names) then break
      
      ;get time range from object
      trange = [ state.time_range->getstarttime(), $
                 state.time_range->getendtime()  ]
      
      ;call helper routine
      yyy_ui_plugin_randomize, loaded_data=state.loaded_data, $
                               history_window=state.history_window, $
                               status_bar = state.status_bar, $
                               names=names, trange=trange ;non-API keywords
      
      ;Add to call sequence for GUI document replay
      ;  -specify name of routine that was just called
      ;  -specify any non-API keywords
      state.call_sequence->addPluginCall, 'yyy_ui_plugin_randomize', $
                                          names=names, trange=trange
    end
    
    ;delete selected data
    ;----------------------------------
    'delete': begin
      
      ;get selected names from tree
      names = yyy_ui_plugin_getselection(state)
      if ~is_string(names) then break
      
      ;call helper routine
      yyy_ui_plugin_delete, loaded_data=state.loaded_data, $
                            status_bar = state.status_bar, $
                            names=names ;non-API keywords
      
      ;Add to call sequence for GUI document replay
      ;  -specify name of routine that was just called
      ;  -specify any non-API keywords
      state.call_sequence->addPluginCall, 'yyy_ui_plugin_delete', $
                                          names=names
    end
    
    else: ;ignore other widgets' events
    
  endcase
  
  
  ;update data tree for all non-tree events
  if uname ne 'tree' then begin
    state.data_tree->update
  endif
  
  ;re-set state structure
  widget_control, event.top, set_uval=state, /no_copy
  
end


pro yyy_ui_plugin, gui_id=gui_id, $
                   loaded_data=loaded_data, $
                   call_sequence=call_sequence, $
                   data_tree=data_tree, $
                   time_range=time_range, $
                   data_structure=data_structure, $
                   history_window=history_window, $
                   status_bar=status_bar, $
                   _extra=_extra
                   


    compile_opt idl2, hidden


  ;top level base
  ;-------------------------------------------------------
  ; IMPORTANT: The top level base should always be modal and have its
  ;            group leader set to GUI_ID.  This will keep events from 
  ;            the main gui from conflicting with those from the plugin. 
  main_base = widget_base(title='Example Plugin.', /col, /base_align_center, $ 
               group_leader=gui_id, /modal, /tlb_kill_request_events, tab_mode=1)
  
  
  ;time widget
  ; -allows user to modify the current GUI time range
  ;-------------------------------------------------------
  
  time_base = widget_base(main_base, /row)
  
    ;create new time widget using time range from GUI
    time = spd_ui_time_widget(time_base, status_bar, history_window, $
               timerangeobj=time_range, uname='time', suppressoneday=1)

  
  ;data tree
  ; -allows user to select loaded data variables
  ;-------------------------------------------------------
  
  tree_base = widget_base(main_base, /row)

    ;The data tree requires a reference to the loaded data object
    ;and a copy of the GUI data tree.  Here we also specify the
    ;widget's size, allow for multiple selections, and set the
    ;widget to display each variable's time range.  
    tree = obj_new('spd_ui_widget_tree', tree_base, 'tree', loaded_data, $
           uname='tree', xsize=440, ysize=330, /multi, /showdatetime, $
           from_copy=long(*data_tree))
  
  
  ;buttons
  ;-------------------------------------------------------
  
  button_base = widget_base(main_base, /row)
    
    ok = widget_button(button_base, value=' OK ', uname='ok', $
           tooltip='Exit test widget.')

    add = widget_button(button_base, value='Add', uname='add', $
           tooltip='Add test variable.')
    
    randomize = widget_button(button_base, value='Randomize', uname='randomize', $
           tooltip='Multiply selected data within the current time range by scaled random factor.')
        
    delete = widget_button(button_base, value='Delete', uname='delete', $
           tooltip='Delete all selected variables')


  ;finalize & start
  ;-------------------------------------------------------
  
  ;Store important objects and widget IDs in a structure
  ;that can be retreived while processing widget events. 
  state = { $
           gui_id:gui_id, $
           loaded_data:loaded_data, $
           data_tree:tree, $
           time_range:time_range, $
           call_sequence:call_sequence, $
           history_window:history_window, $
           status_bar:status_bar $
           }
  
  ;Create/update output structure.  In general this structure can 
  ;contain any information that the plugin may need on subsequent calls.
  ;For the purpose of this example it will simply store the number of
  ;times the plugin has been opened.
  if is_struct(data_structure) then begin
    data_structure.count++
  endif else begin
    data_structure = {count:1}
  endelse
  
  status_bar->update, 'This plugin has been opened '+strtrim(data_structure.count,2)+' times.'
  
  ;center the window
  centertlb, main_base
  
  ;store state structure and realize widgets
  widget_control, main_base, set_uval=state, /no_copy
  widget_control, main_base, /realize
  
  ;keep windows in X11 from snaping back to center during tree widget events
  if !d.NAME eq 'X' then begin
    widget_control, main_base, xoffset=0, yoffset=0
  endif
  
  ;start IDL event manager
  xmanager, 'yyy_ui_plugin', main_base, /no_block
  
  return

end