;+ 
;NAME:
;  elf_ui_load_data
;
;PURPOSE:
;  This routine builds a load data panel of widgets for and 
;  handles the widget events produces. 
;
;HISTORY:
;$LastChangedBy: jimm $
;$LastChangedDate: 2014-02-11 10:54:32 -0800 (Tue, 11 Feb 2014) $
;$LastChangedRevision: 14326 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/tags/spedas_1_00/spedas/gui/api_examples/load_data_tab/elf_ui_load_data.pro $
;
;--------------------------------------------------------------------------------

; This helper function queries the widgets and creates a structure based on the user selections
function elf_ui_get_user_selections, state, event

  ; retrieve the instrument selected
  instlist = widget_info(event.handler,find_by_uname='instrument')
  instrument = widget_info(instlist,/combobox_gettext)

  coordlist = widget_info(event.handler,find_by_uname='coordinate')
  coordinate = widget_info(coordlist,/combobox_gettext)
  
  ; retrieve the probe[s] selected 
  probelist = widget_info(event.handler,find_by_uname='probelist')
  probeSelect = widget_info(probelist,/list_select)
  if probeSelect[0] eq -1 then begin
    state.statusBar->update,'You must select at least one probe'
    state.historyWin->update,'elf add attempted without selecting probe'
    return, -1
  endif
  probes=state.probeArray[probeSelect]
  
  ; retrieve the level[s] selected
  levellist = widget_info(event.handler,find_by_uname='levellist')
  levelSelect = widget_info(levellist,/list_select)
  if levelSelect[0] eq -1 then begin
    state.statusBar->update,'You must select at least one level'
    state.historyWin->update,'elf add attempted without selecting level'
    return, -1
  endif
  level = state.levelArray[levelSelect]
 
  ; retrieve the data types (first need to determin which array to use
  if level EQ 'L1' then begin
    Case instrument of
      'fgm': setType = state.fgmL1TypeArray
      'epd': setType = state.epdL1TypeArray
      'mrma': setType = state.mrmaL1TypeArray
      'mrmi': setType = state.mrmiL1TypeArray
      'state': setType = state.stateTypeArray
      'eng': setType = state.engL1TypeArray
    Endcase
  endif else begin
    Case instrument of
      'fgm': setType = state.fgmL2TypeArray
      'epd': setType = state.epdL2TypeArray
      'mrma': setType = state.mrmaL2TypeArray
      'mrmi': setType = state.mrmiL2TypeArray
      'state': setType = state.stateTypeArray
      'eng': setType = state.engL2TypeArray
    Endcase
  endelse
  typelist = widget_info(event.handler,find_by_uname='typelist')
  typeSelect = widget_info(typelist, /list_select)
  if typeSelect[0] eq -1 then begin
    state.statusBar->update,'You must select at least one data type'
    state.historyWin->update,'elf add attempted without selecting data type'
    return, -1
  endif
  types = setType[typeSelect]

  ;get the start and stop times
  timeRangeObj = state.timeRangeObj
  timeRangeObj->getProperty,startTime=startTimeObj,endTime=endTimeObj
  startTimeObj->getProperty,tdouble=startTimeDouble,tstring=startTimeString
  endTimeObj->getProperty,tdouble=endTimeDouble,tstring=endTimeString
 
  ;report errors
  if startTimeDouble ge endTimeDouble then begin
    state.statusBar->update,'Cannot add data unless end time is greater than start time.'
    state.historyWin->update,'elf add attempted with start time greater than end time.'
    return, -1
  endif

  ;create a load structure to pass the parameters needed by the load
  ;procedure
  selections = { instrument:instrument, $
    coordinate:coordinate, $
    probes:probes, $
    level:strlowcase(level), $
    types:types, $
    timeRange:[startTimeString, endTimeString] }
    
  return, selections  
  
end

;----------------------
; START EVENT HANDLER
;----------------------
pro elf_ui_load_data_event,event

  compile_opt hidden,idl2

  ;handle and report errors, reset variables
  err_xxx = 0
  Catch, err_xxx
  IF (err_xxx NE 0) THEN BEGIN
    Catch, /Cancel
    Help, /Last_Message, Output = err_msg
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
    Print, 'Error--See history'
    ok=error_message('An unknown error occured and the window must be restarted. See console for details.',$
       /noname, /center, title='Error in Load Data')

    widget_control, event.top,/destroy
  
    RETURN
  ENDIF

  ;retrieve the state variable 
  widget_control, event.handler, Get_UValue=state, /no_copy
  
  ;retrieve event information and the uvalue (or widget name)
  ;note, not all widgets are assigned uvalues
  widget_control, event.id, get_uvalue = uval

  if is_string(uval) then begin
    case uval of

      'INSTRUMENT': begin
        ; based on instrument type set the approprate level
        levellist = widget_info(event.handler,find_by_uname='levellist')
        levelSelect = widget_info(levellist, /list_select)
        if event.index eq 4 then widget_control, levellist, set_value=['L1'] $
           else  widget_control, levellist, set_value=state.levelArray[levelSelect]
        if levelSelect LT 1 then begin
          if event.index eq 0 then setType = state.fgmL1TypeArray
          if event.index eq 1 then setType = state.epdL1TypeArray
          if event.index eq 2 then setType = state.mrmaL1TypeArray
          if event.index eq 3 then setType = state.mrmiL1TypeArray
          if event.index eq 4 then setType = state.stateTypeArray
          if event.index eq 5 then setType = state.engL1TypeArray
          widget_control, levelList, set_list_select=0
        endif else begin
          if event.index eq 0 then setType = state.fgmL2TypeArray
          if event.index eq 1 then setType = state.epdL2TypeArray
          if event.index eq 2 then setType = state.mrmaL2TypeArray
          if event.index eq 3 then setType = state.mrmiL2TypeArray
          if event.index eq 4 then setType = state.stateTypeArray
          if event.index eq 5 then setType = state.engL2TypeArray
          widget_control, levelList, set_list_select=0
        endelse
        typelist = widget_info(event.handler,find_by_uname='typelist')
        widget_control, typelist, set_value=setType
        widget_control, typelist, set_list_select=0
        coordlist = widget_info(event.handler, find_by_uname='coordinate')
        if event.index EQ 0 || event.index EQ 4 then widget_control, coordlist, sensitive=1 $
          else widget_control, coordlist, sensitive=0
         
      end    

      'LEVELLIST': begin
        ; retrieve the instrument selected
        instlist = widget_info(event.handler,find_by_uname='instrument')
        instrument = widget_info(instlist,/combobox_gettext)
        ; retrieve the level
        levellist = widget_info(event.handler,find_by_uname='levellist')
        level = widget_info(levellist,/list_select)
        ; Now, based on the type of instrument and the level set the data 
        ; type list to the appropriate values
        if n_elements(level) GT 1 then begin
          ; reset levels
          widget_control, levellist, set_list_select=0
          state.statusBar->update,'You may only select one level at a time. Defaulting to L1.'
          state.historyWin->update,'Error - only one level can be selected at a time.'
          break
        endif
        if level LT 1 then begin
          Case instrument of
            'fgm': setType = state.fgmL1TypeArray
            'epd': setType = state.epdL1TypeArray
            'mrma': setType = state.mrmaL1TypeArray
            'mrmi': setType = state.mrmiL1TypeArray
            'state': setType = state.stateTypeArray        
            'eng': setType = state.engL1TypeArray
          Endcase
        endif else begin
          Case instrument of
            'fgm': setType = state.fgmL2TypeArray
            'epd': setType = state.epdL2TypeArray
            'mrma': setType = state.mrmaL2TypeArray
            'mrmi': setType = state.mrmiL2TypeArray
            'state': setType = state.stateTypeArray
            'eng': setType = state.engL2TypeArray
          Endcase
        endelse
        typelist = widget_info(event.handler,find_by_uname='typelist')
        widget_control, typelist, set_value=setType        
      end


      'CLEARPARAMS': begin
        ;clear the level and type list widget of all selections
        probelist = widget_info(event.handler,find_by_uname='probelist')
        widget_control,probelist,set_list_select=-1
        levellist = widget_info(event.handler,find_by_uname='levellist')
        widget_control,levellist,set_list_select=-1
        typelist = widget_info(event.handler,find_by_uname='typelist')
        widget_control,typelist,set_list_select=-1
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
      
      'CHECK_DATA_AVAIL':  spd_ui_open_url, 'ftp://themis-data.igpp.ucla.edu/themis/data/elfin'

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
      
        ;retrieve the selections made by the user
        loadstruc = elf_ui_get_user_selections(state, event)

        if size(loadstruc, /type) NE 8 then begin
          ;report errors to the status bar for the user to see and log the
          ;error to the history window
          state.statusBar->update,'Not all parameters were selected.'
          state.historyWin->update,'Not all parameters were selected.'
        endif else begin             
          ;turn on the hour glass while the data is being loaded
          widget_control, /hourglass
      
          ;call the routine that loads the data and update the loaded data tree
          ;this routine is specific to each mission 
          elf_ui_load_data_load_pro, $
                           loadstruc,$
                           state.loadedData,$
                           state.statusBar,$
                           state.historyWin,$
                           state.baseid, $
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
                            subtype:'elf_ui_load_data_load_pro', $
                            loadStruc:loadStruc, $
                            overwrite_selections:overwrite_selections }
           ; add the information regarding this load to the call sequence object
           state.callSequence->addSt, callSeqStruc
           
           ;NOTE: In order to replay a session the user must save the sequence of
           ;commands by selecting 'Save SPEDAS document' under the 'File' 
           ;pull down menu prior to exiting the gui session. 
         endelse     
      end
      else:
    endcase
  endif
  
  ;set the state structure before returning to the panel
  ;stop
  Widget_Control, event.handler, Set_UValue=state, /No_Copy
  
  return
  
end

;this procedure is called by the main load data panel when this tab is 
;selected by the user. This is where the mission specific load data panel is
;created and initialized. This routine is an example only. Each mission may 
;choose to add or remove widgets as required by their data. The name of the
;load procedure (called later by the event handler) is the load procedure 
;in the spd_ui_load_data_config.txt file.
pro elf_ui_load_data,tabid,loadedData,historyWin,statusBar,treeCopyPtr,timeRangeObj,callSequence,loadTree=loadTree,timeWidget=timeWidget
  compile_opt idl2,hidden
  
  ;load bitmap resources
  getresourcepath,rpath
  rightArrow = read_bmp(rpath + 'arrow_000_medium.bmp', /rgb)
  trashcan = read_bmp(rpath + 'trashcan.bmp', /rgb)
  
  spd_ui_match_background, tabid, rightArrow 
  spd_ui_match_background, tabid, trashcan
  
  ;create all the bases needed for the widgets on the panel 
  topBase = Widget_Base(tabid, /Row, /Align_Top, /Align_Left, YPad=1,event_pro='elf_ui_load_data_event') 
  
  leftBase = widget_base(topBase,/col)
  middleBase = widget_base(topBase,/col,/align_center)
  rightBase = widget_base(topBase,/col)
  
  leftLabel = widget_label(leftBase,value='Data Selection:',/align_left)
  rightLabel = widget_label(rightBase,value='Data Loaded:',/align_left)
  
  selectionBase = widget_base(leftBase,/col,/frame)
  treeBase = widget_base(rightBase,/col,/frame)
  
  ;create the buttons to add or remove data to the gui. the bitmaps for 
  ;these buttons include a 'right arrow' for adding to the currently loaded 
  ;data, and a 'trashcan' for removing data from the data tree. 
  addButton = Widget_Button(middleBase, Value=rightArrow, /Bitmap,  UValue='ADD', $
              ToolTip='Load data selection')
  minusButton = Widget_Button(middleBase, Value=trashcan, /Bitmap, $
                Uvalue='DEL', $
                ToolTip='Delete data selected in the list of loaded data')
  
  ;this creates and copies the loaded data tree for use within this routine
  loadTree = Obj_New('spd_ui_widget_tree', treeBase, 'LOADTREE', loadedData, $
                     XSize=400, YSize=425, mode=0, /multi,/showdatetime)                   
  loadTree->update,from_copy=*treeCopyPtr
  
  ;create the buttons that removes all data
  clearDataBase = widget_base(rightBase,/row,/align_center)  
  clearDataButton = widget_button(clearDataBase,value='Delete All Data',uvalue='CLEARDATA',/align_center,ToolTip='Deletes all loaded data')
  
  ;the ui time widget handles all widgets and events that are associated with the 
  ;time widget and includes Start/Stop Time labels, text boxes, calendar icons, and
  ;other items associated with setting the time for the data to be loaded.
  if ~obj_valid(tr_obj) then begin
    st_text = '2018-09-17/00:00:00.0'
    et_text = '2018-09-18/00:00:00.0'
    tr_obj=obj_new('spd_ui_time_range',starttime=st_text,endtime=et_text)
  endif
  
  timeWidget = spd_ui_time_widget(selectionBase,$
                                  statusBar,$
                                  historyWin,$
                                  timeRangeObj=tr_obj,$
                                  uvalue='TIME_WIDGET',$
                                  uname='time_widget')
    
  ;create the dropdown menu that lists the various instrument types for this mission
  instrumentArray = ['fgm','epd','mrma','mrmi','state','eng']
  instrumentBase = widget_base(selectionBase,/row, xpad=3) 
  instrumentLabel = widget_label(instrumentBase,value='Instrument Type: ')
  instrumentCombo = widget_combobox(instrumentBase,$
                                       value=instrumentArray,$
                                       uvalue='INSTRUMENT',$
                                       uname='instrument')

  validCoords = ['GEI', 'MAG', 'SM']
  coordBase = widget_base(instrumentBase, /row, xpad=4)
  coordDroplistLabel = Widget_Label(coordBase, Value=' Output Coordinates:  ')
  coordDroplist = Widget_ComboBox(coordBase, Value=validCoords, $ ;XSize=165, $
                 Sensitive=0, uval='COORDINATE', uname='coordinate')
                                  
  selectionTypesBase = widget_base(selectionBase, /row)
  ;create the list box that lists all the probes that are associated with this 
  ;mission along with the clear all button
  probeArray = ['a', 'b']
  probeBase = widget_base(selectionTypesBase, /col)
  probeLabel = widget_label(probeBase,value='Probe:')
  probeList = widget_list(probeBase,$
    value=probeArray,$
    /multiple,$
    uname='probelist',$
    uvalue='PROBELIST',$
    xsize=16,$
    ysize=15)
  widget_control, probeList, set_list_select=0
 
  ; create the list box that lists the data processing levels  
  levelArray = ['L1', 'L2']
  levelBase = widget_base(selectionTypesBase,/col)
  levelLabel = widget_label(levelBase,value='Level:')
  levelList = widget_list(levelBase,$
                         value=levelArray,$
                         /multiple,$
                         uname='levellist',$
                         uvalue='LEVELLIST',$
                         xsize=16,$
                         ysize=15)   
   widget_control, levelList, set_list_select=0
                                               
   ;create the list box and a clear all button for the data types for a given
   ;instrument
   fgmL1TypeArray = ['fgs', 'fgf'] 
   fgmL2TypeArray = ['fgs_dsl','fgs_gei','fgs_sm','fgf_dsl','fgf_gei','fgf_sm']
   epdL1TypeArray = ['pif','pef']   ;['pis','pif','pes','pef']
   epdL2TypeArray = ['pis_enphi_eflux','pif_enphi_eflux','pes_enphi_eflux','pef_enphi_eflux']
   stateTypeArray = ['pos_gei','vel_gei', 'att_gei']
   valid_eng=['sips_5v0_voltage', $
     'sips_5v0_current', $
     'sips_input_voltage', $
     'sips_input_current', $
     'sips_input_temp', $
     'epd_biash', $
     'epd_biasl', $
     'epd_efe_temp', $
     'idpu_msp_version', $
     'fgm_3_3_volt', $
     'fgm_8_volt', $
     'fgm_analog_ground', $
     'fgm_sh_temp', $
     'fgm_eu_temp', $
     'fc_chassis_temp', $
     'fc_idpu_temp', $
     'fc_batt_temp_1', $
     'fc_batt_temp_2', $
     'fc_batt_temp_3', $
     'fc_batt_temp_4', $
     'fc_avionics_temp_1', $
     'fc_avionics_temp_2' $
     ]   
   engL1TypeArray=valid_eng
   engL2TypeArray=valid_eng
   mrmaL1TypeArray = ['mrma']
   mrmaL2TypeArray = ['mrma']
   mrmiL1TypeArray = ['mrmi']
   mrmiL2TypeArray = ['mrmi']
   typeBase = widget_base(selectionTypesBase,/col)
   typeLabel = widget_label(typeBase,value='Data Type:')
   typeList = widget_list(typeBase,$
     value=fgmL1TypeArray,$
     /multiple,$
     uname='typelist',$
     uvalue='TYPELIST',$
     xsize=16,$
     ysize=15)
  widget_control, typeList, set_list_select = 0
  
  clearBase = widget_base(selectionBase,/row, /align_center)
  clearTypeButton = widget_button(clearBase,value='Clear Parameter Selections',uvalue='CLEARPARAMS',/align_center,ToolTip='Deselect all parameter selections')

  davailabilitybutton = widget_button(selectionBase, val = ' Check Data Availability', $
    uval = 'CHECK_DATA_AVAIL', /align_center, $
    ToolTip = 'Check data availability on the web')

  ;create the state variable with all the parameters that are needed by this 
  ;panels event handler routine                                                               
  state = {baseid:topBase, $
           loadTree:loadTree, $
           treeCopyPtr:treeCopyPtr, $
           timeRangeObj:tr_obj, $
           statusBar:statusBar, $
           historyWin:historyWin, $
           loadedData:loadedData, $
           callSequence:callSequence, $
           probeArray:probeArray, $
           instrumentArray:instrumentArray, $
           levelArray:levelArray, $
           validCoords:validCoords, $
           fgmL1TypeArray:fgmL1TypeArray, $
           epdL1TypeArray:epdL1TypeArray, $
           stateTypeArray:stateTypeArray, $
           engL1TypeArray:engL1TypeArray, $
           engL2TypeArray:engL2TypeArray, $
           mrmaL1TypeArray:mrmaL1TypeArray, $
           mrmiL1TypeArray:mrmiL1TypeArray, $
           fgmL2TypeArray:fgmL2TypeArray, $
           epdL2TypeArray:epdL2TypeArray, $
           mrmaL2TypeArray:mrmaL2TypeArray, $
           mrmiL2TypeArray:mrmiL2TypeArray }
           
  widget_control,topBase,set_uvalue=state
                                  
  return

end
