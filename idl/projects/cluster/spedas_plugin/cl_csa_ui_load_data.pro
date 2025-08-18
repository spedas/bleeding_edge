;+ 
;NAME:
;  cl_csa_ui_load_data
;
;PURPOSE:
;  This routine builds a load data panel of widgets for the Cluster mission and 
;  handles the widget events produces. 
;
;HISTORY:
;$LastChangedBy: jimm $
;$LastChangedDate: 2014-02-11 10:54:32 -0800 (Tue, 11 Feb 2014) $
;$LastChangedRevision: 14326 $
;
;--------------------------------------------------------------------------------

; This helper function queries the widgets and creates a structure based on the user selections
function cl_csa_ui_get_user_selections, state, event

  ; retrieve the instrument selected
  datalist = widget_info(event.handler,find_by_uname='datatypelist')
  datatypeSelect = widget_info(datalist,/list_select)
  if datatypeSelect[0] eq -1 then begin
    state.statusBar->update,'You must select at least one data type'
    state.historyWin->update,'cl add attempted without selecting data type'
    return, -1
  endif
  datatypes=state.datatypeArray[datatypeSelect]

  ; retrieve the probe[s] selected 
  probelist = widget_info(event.handler,find_by_uname='probelist')
  probeSelect = widget_info(probelist,/list_select)
  if probeSelect[0] eq -1 then begin
    state.statusBar->update,'You must select at least one probe'
    state.historyWin->update,'cl add attempted without selecting probe'
    return, -1
  endif
  probes=state.probeArray[probeSelect]
  
  ; get the get_support_data flag
  ; retrieve the probe[s] selected
  getsupp = widget_info(event.handler,find_by_uname='getsupportdata')
  get_support_data = widget_info(getsupp,/button_set)
  
  ;get the start and stop times
  timeRangeObj = state.timeRangeObj
  timeRangeObj->getProperty,startTime=startTimeObj,endTime=endTimeObj
  startTimeObj->getProperty,tdouble=startTimeDouble,tstring=startTimeString
  endTimeObj->getProperty,tdouble=endTimeDouble,tstring=endTimeString
 
  ;report errors
  if startTimeDouble ge endTimeDouble then begin
    state.statusBar->update,'Cannot add data unless end time is greater than start time.'
    state.historyWin->update,'cl add attempted with start time greater than end time.'
    return, -1
  endif

  ;create a load structure to pass the parameters needed by the load
  ;procedure
  selections = { datatypes:datatypes, $
    probes:probes, $
    timeRange:[startTimeString, endTimeString],$
    get_support_data: get_support_data}
    
  return, selections  
  
end

;----------------------
; START EVENT HANDLER
;----------------------
pro cl_csa_ui_load_data_event,event

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

      'CLEARPARAMS': begin
        ;clear the level and type list widget of all selections
        probelist = widget_info(event.handler,find_by_uname='probelist')
        widget_control,probelist,set_list_select=-1
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
      
      ;'CHECK_DATA_AVAIL':  spd_ui_open_url, 'ftp://themis-data.igpp.ucla.edu/themis/data/elfin'

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
        loadstruc = cl_csa_ui_get_user_selections(state, event)

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

          cl_csa_ui_load_data_load_pro, $
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
                            subtype:'cl_csa_ui_load_data_load_pro', $
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
;created and initialized. The name of the
;load procedure (called later by the event handler) is the load procedure 
;in the spd_ui_load_data_config.txt file.
pro cl_csa_ui_load_data,tabid,loadedData,historyWin,statusBar,treeCopyPtr,timeRangeObj,callSequence,loadTree=loadTree,timeWidget=timeWidget
  compile_opt idl2,hidden
  
  ;load bitmap resources
  getresourcepath,rpath
  rightArrow = read_bmp(rpath + 'arrow_000_medium.bmp', /rgb)
  trashcan = read_bmp(rpath + 'trashcan.bmp', /rgb)
  
  spd_ui_match_background, tabid, rightArrow 
  spd_ui_match_background, tabid, trashcan
  
  ;create all the bases needed for the widgets on the panel 
  topBase = Widget_Base(tabid, /Row, /Align_Top, /Align_Left, YPad=1,event_pro='cl_csa_ui_load_data_event') 
  
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
    st_text = '2001-02-01/00:00:00.0'
    et_text = '2001-02-03/00:00:00.0'
    tr_obj=obj_new('spd_ui_time_range',starttime=st_text,endtime=et_text)
  endif
  
  timeWidget = spd_ui_time_widget(selectionBase,$
                                  statusBar,$
                                  historyWin,$
                                  timeRangeObj=tr_obj,$
                                  uvalue='TIME_WIDGET',$
                                  uname='time_widget')
 
  getsuppBase = widget_base(selectionBase, /nonexclusive, /col, /align_left)
  getsuppButton = widget_button(getsuppBase,value='Get Support Data', uname='getsupportdata',uvalue='GETSUPPORTDATA')
  get_support_data=0
  
  ;create the dropdown menu that lists the various instrument types for this mission
  ;
  ; Get lists of valid probe names and data types
  cl_load_csa,probes=probeArray,datatypes=datatypeArray,/valid_names
    
  datatypeArray=['*',datatypeArray]
  probeArray=['*',probeArray]
  
  selectionTypesBase = widget_base(selectionBase, /row)
  ;create the list box that lists all the probes that are associated with this 
  ;mission along with the clear all button
;  probeArray = ['1','2','3','4']
  probeBase = widget_base(selectionTypesBase, /col)
  probeLabel = widget_label(probeBase,value='Probe:')
  probeList = widget_list(probeBase,$
    value=probeArray,$
    /multiple,$
    uname='probelist',$
    uvalue='PROBELIST',$
    xsize=4,$
    ysize=15)
  widget_control, probeList, set_list_select=0
 
  datatypeBase = widget_base(selectionTypesBase, /col)
  datatypeLabel = widget_label(datatypeBase,value='Data Type:')
  datatypeList = widget_list(datatypeBase,$
    value=datatypeArray,$
    /multiple,$
    uname='datatypelist',$
    uvalue='DATATYPELIST',$
    xsize=45,$
    ysize=15)
  widget_control, datatypeList, set_list_select=0

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
           datatypeArray:datatypeArray, $
           get_support_data:get_support_data}
           
  widget_control,topBase,set_uvalue=state
                                  
  return

end
