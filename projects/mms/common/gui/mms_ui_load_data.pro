;+
;NAME:
;      mms_ui_load_data
;
;PURPOSE:
;      The SPEDAS Load Data plugin for the MMS mission
;
; NOTES:
;      Need to add multiple select capabilities to probes and types
;      mms_load_state can handle '*' for probes rates and types
;      mms_load_data may not yet have this implemented
;
;HISTORY:
;$LastChangedBy: egrimes $
;$LastChangedDate: 2018-03-02 10:00:15 -0800 (Fri, 02 Mar 2018) $
;$LastChangedRevision: 24821 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/common/gui/mms_ui_load_data.pro $
;
;--------------------------------------------------------------------------------

;+
;Purpose:
;  Dynamically populate rate, level, and datatypes widgets
;  for science instruments.
;
;Keywords:
;  rate: force rate widget to be updated
;  level: force level widget to be updated 
;
;Usage:
;  Called by mms_ui_load_data_update_widgets
;
;-
pro mms_ui_load_data_update_science, state, $
                                     rate=get_rate, $
                                     level=get_level

    compile_opt idl2, hidden

  ;get widget ids
  instrument_id = widget_info(state.baseid, find_by_uname='instrument')
  rate_id = widget_info(state.baseid, find_by_uname='ratelist')
  level_id = widget_info(state.baseid, find_by_uname='levellist')
  datatype_id = widget_info(state.baseid, find_by_uname='datatypelist')
  
  ;prepare inputs
  instrument = widget_info(instrument_id, /combobox_gettext)
  
  rate_idx = widget_info(rate_id, /list_select)
  if ~keyword_set(get_rate) && rate_idx ne -1 then begin
    widget_control, rate_id, get_uvalue=current_rates
    rate = current_rates[rate_idx]
  endif
  
  level_idx = widget_info(level_id, /list_select)
  if ~keyword_set(get_level) && level_idx ne -1 then begin
    widget_control, level_id, get_uvalue=current_levels
    level = current_levels[level_idx]
  endif

  ;retrieve valid types based on selections
  datatypes = mms_gui_datatypes(instrument, rate, level)

;  mms_load_options, instrument, rate=rate, level=level, datatype=datatype, valid=valid

  ;just in case
  if size(datatypes[0], /type) eq 2 then begin
    spd_ui_message, 'WARNING: Invalid input selected, please report to SPEDAS development team', $
                    sb=state.statusbar, hw=state.historywin
    return
  endif

  ;update rate/level fields as needed/requested
  if keyword_set(get_rate) || rate_idx eq -1 then begin
    rates = mms_gui_datarates(instrument)
    widget_control, rate_id, set_value=rates, set_uvalue=rates
  endif
  
  if keyword_set(get_level) || level_idx eq -1 then begin
    levels = mms_gui_levels(instrument)
    widget_control, level_id, set_value=levels, set_uvalue=levels
  endif
  
  widget_control, datatype_id, set_value=datatypes, set_uvalue=datatypes

end


;+
;Purpose:
;  Update rate, level, and datatype widgets when state is selected. 
;
;Usage:
;  Called by mms_ui_load_data_update_widgets
;-
pro mms_ui_load_data_update_state, state

    compile_opt idl2, hidden

  rateArray=state.stateRateArray
  levelArray=state.stateLevelArray
  datatypeArray=state.stateDatatypeArray

  rateList = widget_info(state.baseid, find_by_uname='ratelist')
  levelList = widget_info(state.baseid, find_by_uname='levellist')
  datatypelist = widget_info(state.baseid, find_by_uname='datatypelist') 

  widget_control, rateList, set_value=rateArray, set_uvalue=rateArray
  widget_control, levelList, set_value=levelArray, set_uvalue=levelArray
  widget_control, datatypelist, set_value=datatypeArray, set_uvalue=datatypeArray

end


;+
;Purpose:
;  Dynamically update rate, level, and datatype widgets as needed 
;  based on instrument and any rate and level selections.  
;
;Calling Sequence:
;  mms_ui_load_data_update_widgets, state, [,/rate] [,/level] [,/set_state]
;
;Usage:
;  This should be called any time the instrument, rate, or level
;  widgets are updated.
;
;  Widgets with valid selections will be queried for input and 
;  those without will be populated. Datatype will always be
;  populated.
;
;  Widget with valid selections can be forced to repopulate via 
;  the corresponding keyword.
;
;Notes:
;  Science instruments are populated dynamically, state is static
;  and has its own special case.
;
;-
pro mms_ui_load_data_update_widgets, state, rate=rate, level=level, set_state=set_state

    compile_opt idl2, hidden

  if state.currentInstrument ne 'STATE' then begin
    mms_ui_load_data_update_science, state, rate=rate, level=level    
  endif else if keyword_set(set_state) then begin
    mms_ui_load_data_update_state, state
  endif

end



;+
;Purpose:
;  Widget event handler for mms_ui_load_data.
;
;-
pro mms_ui_load_data_event,event
  compile_opt hidden,idl2

  ;handle and report errors, reset variables
  err_xxx = 0
  Catch, err_xxx
  IF (err_xxx NE 0) THEN BEGIN
    Catch, /Cancel
    Help, /Last_Message, Output = err_msg
    Print, 'Error--See history'
    ok=error_message('An unknown error occured and the window must be restarted. See console for details.',$
      /noname, /center, title='Error in Load Data')
    if is_struct(state) then begin
      ;send error message
      FOR j = 0, N_Elements(err_msg)-1 DO state.historywin->update,err_msg[j]
      
      if widget_valid(state.baseID) && obj_valid(state.historyWin) then begin 
        spd_gui_error,state.baseid,state.historyWin
      endif
      
      ;update central tree, if possible
      if obj_valid(state.loadTree) then begin
        *state.treeCopyPtr = state.loadTree->getCopy()
      endif  
      
      ;restore the state structure 
      Widget_Control, event.TOP, Set_UValue=state, /No_Copy
    endif
  
    widget_control, event.top,/destroy
    RETURN
  ENDIF

  ;retrieve the state variable 
  widget_control, event.handler, Get_UValue=state, /no_copy
  
  ;retrieve event information and the uname (or widget name)
  ;note, not all widgets are assigned unames
  uname = widget_info(event.id, /uname)

  if is_string(uname) then begin
    case strupcase(uname) of
      'INSTRUMENT': begin
        ;retrieve the instrument type 
        instrList = widget_info(state.baseid,find_by_uname='instrument')
        instrument = widget_info(instrList, /combobox_gettext)
        if instrument NE state.currentInstrument then begin
          state.currentInstrument = instrument
          mms_ui_load_data_update_widgets, state, /rate, /level, /set_state
        endif
      end
      'RATELIST': begin
        mms_ui_load_data_update_widgets, state, /level
      end
      'LEVELLIST': begin
        mms_ui_load_data_update_widgets, state
      end
      'CLEARPROBE': begin
        ;clear the proble list widget of any selections
        probeList = widget_info(event.handler,find_by_uname='probelist')
        widget_control,probeList,set_list_select=-1
      end
      'CLEARRATE': begin
        ;clear the data level list widget of all selections
        rateList = widget_info(event.handler,find_by_uname='ratelist')
        widget_control,rateList,set_list_select=-1
        mms_ui_load_data_update_widgets, state, /rate, /level
      end
      'CLEARLEVEL': begin
        ;clear the data level list widget of all selections
        levelList = widget_info(event.handler,find_by_uname='levellist')
        widget_control,levelList,set_list_select=-1
        mms_ui_load_data_update_widgets, state, /level
      end
      'CLEARDATATYPE': begin
        ;clear the data level list widget of all selections
        levelList = widget_info(event.handler,find_by_uname='datatypelist')
        widget_control,levelList,set_list_select=-1
      end
      'CLEARDATA': begin
        ;clear the actual data that has been loaded. this will delete all 
        ;data loaded into the gui memory so warn user first
        ok = dialog_message("This will delete all currently loaded data.  Are you sure you wish to continue?",/question,/default_no,/center)
        
        if strlowcase(ok) eq 'yes' then begin
          datanames = state.loadedData->getAll(/parent)
          if is_string(datanames) then begin
            for i = 0,n_elements(dataNames)-1 do begin
              result = state.loadedData->remove(datanames[i])
              if ~result then begin
                ;report errors to the status bar for the user to see and log the
                ;error to the history window
                state.statusBar->update,'Unexpected error while removing data.'
                state.historyWin->update,'Unexpected error while removing data.'
              endif
            endfor
          endif
          ;update the data tree and add the delete commands to the callSequence
          ;object which tracks sequences of calls during the gui session
          state.loadTree->update
          state.callSequence->clearCalls
        endif
        
      end   
      'DEL': begin
        ;get the current list of loaded data
        dataNames = state.loadTree->getValue()
        
        if ptr_valid(datanames[0]) then begin
          for i = 0,n_elements(dataNames)-1 do begin
            ;delete the selected data from the gui memory and loaded data tree
            result = state.loadedData->remove((*datanames[i]).groupname)
            if ~result then begin
              ;report errors to the status bar for the user to see and log the
              ;error to the history window
              state.statusBar->update,'Unexpected error while removing data.'
              state.historyWin->update,'Unexpected error while removing data.'
            endif
          endfor
        endif
        state.loadTree->update      
   
      end
      'ADD': begin

        probelist = widget_info(event.handler,find_by_uname='probelist')
        probeSelect = widget_info(probelist,/list_select)
        ;if no selections were made, report this to the status bar and
        ;history window
        if probeSelect[0] eq -1 then begin
          state.statusBar->update,'You must select at least one probe'
          state.historyWin->update,'MMS add attempted without selecting probe'
          break
        endif
        probes = state.probeArray[probeSelect]

        ;retrieve the instruments selected by the user
        instlist = widget_info(event.handler,find_by_uname='instrument')
        instrument = widget_info(instlist,/combobox_gettext)
        instNum = widget_info(instlist,/combobox_number)
        ;report errors to status bar and history window
        if  instNum eq -1 then begin
          state.statusBar->update,'You must select at least one instrument'
          state.historyWin->update,'MMS add attempted without selecting an instrument'
          break
        endif

        ;retrieve the data rate that were selected by the user
        ratelist = widget_info(event.handler,find_by_uname='ratelist')
        rateSelect = widget_info(ratelist,/list_select)
        widget_control, ratelist, get_uvalue=currentRates 
        ;if no selections were made, report this to the user via the
        ;status bar and log the error to the history window
        ; Currently there are no rates for science types so for now only check state data
        if instrument eq 'STATE' then begin
          rates = '' ;placeholder, not used
        endif else begin
          if rateSelect[0] eq -1 then begin
            state.statusBar->update,'You must select at least one rate'
            state.historyWin->update,'MMS add attempted without selecting rate'
            break
          endif
          rates = currentRates[rateSelect]
        endelse 

        ;retrieve the data levels that were selected by the user
        levellist = widget_info(event.handler,find_by_uname='levellist')
        levelSelect = widget_info(levellist,/list_select)
        widget_control, levellist, get_uvalue=currentLevels
        ;if no selections were made, report this to the user via the 
        ;status bar and log the error to the history window
        if levelSelect[0] eq -1 then begin
          state.statusBar->update,'You must select at least one data level'
          state.historyWin->update,'MMS add attempted without selecting data level'
          break
        endif
        levels = currentLevels[levelSelect]
        
        ;retrieve datatype
        datatypelist = widget_info(event.handler,find_by_uname='datatypelist')
        datatypeSelect = widget_info(datatypelist,/list_select)
        widget_control, datatypelist, get_uvalue=currentDatatypes
        if ~array_equal(currentDatatypes,'') then begin
          if datatypeSelect[0] eq -1 then begin
            state.statusBar->update,'You must select at least one data type'
            state.historyWin->update,'MMS add attempted without selecting data type'
            break
          endif
          datatypes = currentDatatypes[datatypeSelect]
        endif else begin
          datatypes = ''
        endelse
        
        ;get the start and stop times 
        timeRangeObj = state.timeRangeObj      
        timeRangeObj->getProperty,startTime=startTimeObj,endTime=endTimeObj      
        startTimeObj->getProperty,tdouble=startTimeDouble,tstring=startTimeString
        endTimeObj->getProperty,tdouble=endTimeDouble,tstring=endTimeString
        
        ;report errors
        if startTimeDouble ge endTimeDouble then begin
          state.statusBar->update,'Cannot add data unless end time is greater than start time.'
          state.historyWin->update,'MMS add attempted with start time greater than end time.'
          break
        endif
        
        state.statusBar->update,'Loading MMS data... (this may take several minutes to complete)'
        state.historyWin->update,'Loading MMS data... (this may take several minutes to complete)'
        
        spdf_download = widget_info(event.handler,find_by_uname='spdfdownload')
        spdf_set = widget_info(spdf_download, /button_set)
        
        ;turn on the hour glass while the data is being loaded
        widget_control, /hourglass
        
        ;create a load structure to pass the parameters needed by the load procedure
        loadStruc =  { probes:probes, $
                       spdf: spdf_set, $
                       instrument:instrument, $
                       level:levels, $
                       rate:rates, $
                       datatype:datatypes, $
                       trange:[startTimeString, endTimeString] }
                       
        ;call the routine that loads the data and update the loaded data tree
        mms_ui_load_data_import, $
                         loadStruc,$
                         state.loadedData,$
                         state.statusBar,$
                         state.historyWin,$
                         state.baseid,$  ;needed for appropriate layering and modality of popups
                         replay=replay,$
                         overwrite_selections=overwrite_selections ;allows replay of user overwrite selections from spedas 

         ;update the loaded data object
         state.loadTree->update

         ;create a structure that will be used by the call sequence object. the
         ;call sequence object tracks the sequences of dprocs that have been 
         ;executed during a gui session. This is so it can be replayed in a 
         ;later session. The callSeqStruc.type for ALL new missions is 
         ;'loadapidata'.
         callSeqStruc = { type:'loadapidata', $
                          subtype:'mms_ui_load_data_import', $
                          loadStruc:loadStruc, $
                          overwrite_selections:overwrite_selections }
         ; add the information regarding this load to the call sequence object
         state.callSequence->addSt, callSeqStruc
         
         ;NOTE: In order to replay a session the user must save the sequence of
         ;commands by selecting 'Save SPEDAS document' under the 'File' 
         ;pull down menu prior to exiting the gui session. 
              
      end
      else:
    endcase
  endif
  
  ;set the state structure before returning to the panel
  Widget_Control, event.handler, Set_UValue=state, /No_Copy
  
  return
  
end


pro mms_ui_load_data,tabid,loadedData,historyWin,statusBar,treeCopyPtr,timeRangeObj,callSequence,loadTree=loadTree,timeWidget=timeWidget
  compile_opt idl2,hidden
  
  ;load bitmap resources
  getresourcepath,rpath
  rightArrow = read_bmp(rpath + 'arrow_000_medium.bmp', /rgb)
  trashcan = read_bmp(rpath + 'trashcan.bmp', /rgb)
  
  spd_ui_match_background, tabid, rightArrow 
  spd_ui_match_background, tabid, trashcan
  
  ;create all the bases needed for the widgets on the panel 
  topBase = Widget_Base(tabid, /Row, /Align_Top, /Align_Left, YPad=1,event_pro='mms_ui_load_data_event') 
  
  leftBase = widget_base(topBase,/col)
  middleBase = widget_base(topBase,/col,/align_center)
  rightBase = widget_base(topBase,/col)
  
  leftLabel = widget_label(leftBase,value='MMS Data Selection:',/align_left)
  rightLabel = widget_label(rightBase,value='Data Loaded:',/align_left)
  
  selectionBase = widget_base(leftBase,/col,/frame)
  treeBase = widget_base(rightBase,/col,/frame)
  
  ;create the buttons to add or remove data to the gui. the bitmaps for 
  ;these buttons include a 'right arrow' for adding to the currently loaded 
  ;data, and a 'trashcan' for removing data from the data tree. 
  addButton = Widget_Button(middleBase, Value=rightArrow, /Bitmap, uname='add', $
              ToolTip='Load data selection')
  minusButton = Widget_Button(middleBase, Value=trashcan, /Bitmap, $
                uname='del', $
                ToolTip='Delete data selected in the list of loaded data')
  
  ;this creates and copies the loaded data tree for use within this routine
  loadTree = Obj_New('spd_ui_widget_tree', treeBase, 'LOADTREE', loadedData, $
                     XSize=400, YSize=425, mode=0, /multi,/showdatetime)                   
  loadTree->update,from_copy=*treeCopyPtr
  
  ;create the buttons that removes all data
  clearDataBase = widget_base(rightBase,/row,/align_center)  
  clearDataButton = widget_button(clearDataBase,value='Delete All Data',$
        uname='cleardata',/align_center,ToolTip='Deletes all loaded data')
  
  ;the ui time widget handles all widgets and events that are associated with the 
  ;time widget and includes Start/Stop Time labels, text boxes, calendar icons, and
  ;other items associated with setting the time for the data to be loaded.
  timeWidget = spd_ui_time_widget(selectionBase,$
                                  statusBar,$
                                  historyWin,$
                                  timeRangeObj=timeRangeObj,$
                                  uname='time_widget')
    
  probeArrayValues = ['1', '2', '3', '4']
  probeArrayDisplayed = ['MMS 1', 'MMS 2', 'MMS 3', 'MMS 4']
 ; instrumentArray = ['FGM', 'EIS', 'FEEPS', 'FPI', 'HPCA', 'SCM', 'EDI', 'EDP', 'DSP', 'ASPOC', 'STATE', 'MEC']
 ; egrimes, disabled state, 4/1/16
  instrumentArray = ['FGM', 'EIS', 'FEEPS', 'FPI', 'HPCA', 'SCM', 'EDI', 'EDP', 'DSP', 'ASPOC', 'MEC']

  ; these are only for FGM, as it's the first instrument in the list
  currentRateArray = ['srvy', 'brst']
  currentLevelArray = ['L2']
  currentDatatypeArray = [''] ; none for FGM
  
  stateRateArray = [''] ;placeholder, no data rate for state
  stateLevelArray = ['def', 'pred']
  stateDataTypeArray = ['*','pos', 'vel', 'spinras', 'spindec']


  ;create the dropdown menu that lists the various instrument types for MMS
  instrumentBase = widget_base(selectionBase,/row) 
  instrumentLabel = widget_label(instrumentBase,value='Instrument Type: ')
  instrumentCombo = widget_combobox(instrumentBase,$
                                       value=instrumentArray,$
                                       uname='instrument')
                                  
  ;create the list box that lists all the probes that are associated with MMS
  dataBase = widget_base(selectionBase,/row)
  probeBase = widget_base(dataBase,/col)
  probeLabel = widget_label(probeBase,value='Probe: ')
  probeList = widget_list(probeBase,$
                          value=probeArrayDisplayed,$
                        ;  /multiple,$ ; not actually allowed by loadedData->add()?
                          uvalue=probeArrayValues, $
                          uname='probelist',$
                          xsize=12,$
                          ysize=15)
  clearProbeButton = widget_button(probeBase,value='Clear Probe', $
       uname='clearprobe',ToolTip='Deselect all probes/stations')
                          
  ;create the list box aand a clear all button for the data rates for a given 
  ;instrument           
  rateBase = widget_base(dataBase,/col)
  rateLabel = widget_label(rateBase,value='Data Rate:')
  rateList = widget_list(rateBase,$
                         value=currentRateArray,$
;                         /multiple,$
                         uvalue=currentRateArray,$ ;can't use get_value on list
                         uname='ratelist',$
                         xsize=12,$
                         ysize=15) 
  clearRateButton = widget_button(rateBase,value='Clear Rate', $
       uname='clearrate',ToolTip='Deselect all rates')

  ;create the list box and a clear all button for the data levels for a given
  ;instrument
  levelBase = widget_base(dataBase,/col)
  levelLabel = widget_label(levelBase,value='Level:')
  levelList = widget_list(levelBase,$
                         value=currentLevelArray,$
;                         /multiple,$
                         uvalue=currentLevelArray,$ ;can't use get_value on list
                         uname='levellist',$
                         xsize=12,$
                         ysize=15)
  clearLevelButton = widget_button(levelBase,value='Clear Levels', $
       uname='clearlevel', ToolTip='Deselect all data levels')

  ;create the list box and a clear all button for datatype
  datatypeBase = widget_base(dataBase,/col)
  datatypeLabel = widget_label(datatypeBase,value='Data Type:')
  datatypeList = widget_list(datatypeBase,$
                         value=currentDatatypeArray,$
                         /multiple,$
                         uvalue=currentDatatypeArray,$ ;can't use get_value on list
                         uname='datatypelist',$
                         xsize=12,$
                         ysize=15)
  clearButton = widget_button(datatypeBase,value='Clear Type', $
       uname='cleardatatype', ToolTip='Deselect all datatypes')

  spdfButtonBase = widget_base(leftBase,/row,/NONEXCLUSIVE)
  spdfButton = widget_button(spdfButtonBase, value='Download from SPDF', uname='spdfdownload')

  ;create the state variable with all the parameters that are needed by this 
  ;panels event handler routine                                                               
  state = {baseid:topBase,$
           loadTree:loadTree,$
           treeCopyPtr:treeCopyPtr,$
           timeRangeObj:timeRangeObj,$
           statusBar:statusBar,$
           historyWin:historyWin,$
           loadedData:loadedData,$
           callSequence:callSequence,$
           probeArray:probeArrayValues,$
           instrumentArray:instrumentArray,$
           currentInstrument:instrumentArray[0],$
;now stored as uvalue so array size can change
;           sciRateArray:sciRateArray, $
;           sciLevelArray:sciLevelArray, $
;           sciDataTypeArray:sciDataTypeArray, $
           stateRateArray:stateRateArray, $
           stateLevelArray:stateLevelArray, $
           stateDataTypeArray:stateDataTypeArray, $
           currentLevelArray:currentLevelArray, $
           currentRateArray:currentRateArray}
  widget_control,topBase,set_uvalue=state
                                  
  return

end
