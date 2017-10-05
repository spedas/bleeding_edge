;+ 
;NAME:
;  poes_ui_load_data
;
;PURPOSE:
;  Generates the tab that loads poes data for the gui.
;
;
;HISTORY:
;$LastChangedBy: egrimes $
;$LastChangedDate: 2015-04-15 15:14:31 -0700 (Wed, 15 Apr 2015) $
;$LastChangedRevision: 17332 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/poes/spedas_plugin/poes_ui_load_data.pro $
;
;--------------------------------------------------------------------------------
pro poes_ui_load_data_event,event

  compile_opt hidden,idl2

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
      
      ;restore state
      Widget_Control, event.TOP, Set_UValue=state, /No_Copy
      
    endif
   

    widget_control, event.top,/destroy
  
    RETURN
  ENDIF

  widget_control, event.handler, Get_UValue=state, /no_copy
  
  ;Options
  widget_control, event.id, get_uvalue = uval
  ;not all widgets are assigned uvalues
  if is_string(uval) then begin
    case uval of
      'CLEARPROBE': begin
        probelist = widget_info(event.handler,find_by_uname='probelist')
        widget_control,probelist,set_list_select=-1
      end
      'CLEARTYPE': begin
        datalist = widget_info(event.handler,find_by_uname='datalist')
        widget_control,datalist,set_list_select=-1
      end
      'CLEARDATA': begin
        ok = dialog_message("This will delete all currently loaded data.  Are you sure you wish to continue?",/question,/default_no,/center)
        
        if strlowcase(ok) eq 'yes' then begin
          datanames = state.loadedData->getAll(/parent)
          if is_string(datanames) then begin
            for i = 0,n_elements(dataNames)-1 do begin
              result = state.loadedData->remove(datanames[i])
              if ~result then begin
                state.statusBar->update,'Unexpected error while removing data.'
                state.historyWin->update,'Unexpected error while removing data.'
              endif
            endfor
          endif
          state.loadTree->update
          state.callSequence->clearCalls
        endif
        
      end   
      'DEL': begin
        dataNames = state.loadTree->getValue()
        
        if ptr_valid(datanames[0]) then begin
          for i = 0,n_elements(dataNames)-1 do begin
            result = state.loadedData->remove((*datanames[i]).groupname)
            if ~result then begin
              state.statusBar->update,'Unexpected error while removing data.'
              state.historyWin->update,'Unexpected error while removing data.'
            endif else begin
              ; store deletion in the call sequence object
              state.callSequence->adddeletecall,(*datanames[i]).groupname
            endelse 
          endfor
        endif
        state.loadTree->update
       
   
      end
      'ADD': begin
      
        datalist = widget_info(event.handler,find_by_uname='datalist')
        typeSelect = widget_info(datalist,/list_select)
        
        if typeSelect[0] eq -1 then begin
          state.statusBar->update,'You must select at least one data type'
          state.historyWin->update,'POES add attempted without selecting data type'
          break
        endif

        types = state.typeArray[typeSelect]
       
        
        probelist = widget_info(event.handler,find_by_uname='probelist')
        probeSelect = widget_info(probelist,/list_select)
        
        if probeSelect[0] eq -1 then begin
          state.statusBar->update,'You must select at least one probe'
          state.historyWin->update,'POES add attempted without selecting probe'
          break
        endif
        
        probes = state.probeArray[probeSelect]
        
        timeRangeObj = state.timeRangeObj      
        timeRangeObj->getProperty,startTime=startTimeObj,endTime=endTimeObj
      
        startTimeObj->getProperty,tdouble=startTimeDouble,tstring=startTimeString
        endTimeObj->getProperty,tdouble=endTimeDouble,tstring=endTimeString
        
        if startTimeDouble ge endTimeDouble then begin
          state.statusBar->update,'Cannot add data unless end time is greater than start time.'
          state.historyWin->update,'POES add attempted with start time greater than end time.'
          break
        endif
        
        loadStruc = { probe:probes,    $
                      datatype:types,  $
                      timeRange:[startTimeString,endTimeString] }
        
        widget_control, /hourglass
        
        poes_ui_import_data,$
                      loadStruc, $
                      state.loadedData, $
                      state.statusBar, $
                      state.historyWin, $
                      state.baseid, $
                      overwrite_selections=overwrite_selections                            
      
        state.loadTree->update
        
        callSeqStruc = { type:'loadapidata',       $
                         subtype:'poes_ui_import_data',  $
                         loadStruc:loadStruc,     $
                         overwrite_selections:overwrite_selections }
                      
        state.callSequence->addSt, callSeqStruc
     
      end
      ;;; TODO: will need to implement once these two links are available for POES
      'CHECK_DATA_AVAIL': begin
        spd_ui_open_url, 'http://themis.ssl.berkeley.edu/data_products/#poes'
      end
      'RULESOFTHEROAD': begin
        spd_ui_open_url, 'http://spedas.org/wiki/index.php?title=POES_Rules_of_the_Road'
      end
      else:
    endcase
  endif
  
  Widget_Control, event.handler, Set_UValue=state, /No_Copy
  
  return
  
end


pro poes_ui_load_data,tabid,loadedData,historyWin,statusBar,treeCopyPtr,timeRangeObj,callSequence,loadTree=loadTree,timeWidget=timeWidget
  compile_opt idl2,hidden

  ;load bitmap resources
  getresourcepath,rpath
  rightArrow = read_bmp(rpath + 'arrow_000_medium.bmp', /rgb)
  trashcan = read_bmp(rpath + 'trashcan.bmp', /rgb)
  
  spd_ui_match_background, tabid, rightArrow 
  spd_ui_match_background, tabid, trashcan
  
  topBase = Widget_Base(tabid, /Row, /Align_Top, /Align_Left, YPad=1,event_pro='poes_ui_load_data_event') 
  
  leftBase = widget_base(topBase,/col)
  middleBase = widget_base(topBase,/col,/align_center)
  rightBase = widget_base(topBase,/col)
  
  leftLabel = widget_label(leftBase,value='POES Data Selection:',/align_left)
  rightLabel = widget_label(rightBase,value='Data Loaded:',/align_left)
  
  selectionBase = widget_base(leftBase,/col,/frame)
  treeBase = widget_base(rightBase,/col,/frame)
  
  addButton = Widget_Button(middleBase, Value=rightArrow, /Bitmap,  UValue='ADD', $
              ToolTip='Load data selection')
  minusButton = Widget_Button(middleBase, Value=trashcan, /Bitmap, $
                Uvalue='DEL', $
                ToolTip='Delete data selected in the list of loaded data')

  loadTree = Obj_New('spd_ui_widget_tree', treeBase, 'LOADTREE', loadedData, $
                     XSize=400, YSize=425, mode=0, /multi,/showdatetime)
                     
  loadTree->update,from_copy=*treeCopyPtr
  
  clearDataBase = widget_base(rightBase,/row,/align_center)
  
  clearDataButton = widget_button(clearDataBase,value='Delete All Data',uvalue='CLEARDATA',/align_center,ToolTip='Deletes all loaded data')
  
  timeWidget = spd_ui_time_widget(selectionBase,$
                                  statusBar,$
                                  historyWin,$
                                  timeRangeObj=timeRangeObj,$
                                  uvalue='TIME_WIDGET',$
                                  uname='time_widget',$
                                  startyear=2000)
    

  probeArrayValues = ['metop1', 'metop2', 'noaa15', 'noaa16', 'noaa18', 'noaa19']
  probeArrayDisplayed = ['MetOp 1', 'MetOp 2', 'NOAA 15', 'NOAA 16', 'NOAA 18', 'NOAA 19']
  
  typeArray = ['*', 'ted_ele_flux', 'ted_pro_flux', 'ted_ele_eflux', 'ted_pro_eflux', 'ted_ele_eflux_atmo', 'ted_pro_eflux_atmo', $
               'ted_total_eflux_atmo', 'ted_ele_energy', 'ted_pro_energy', 'ted_ele_max_flux', $
               'ted_pro_max_flux', 'ted_ele_eflux_bg', 'ted_pro_eflux_bg', 'ted_pitch_angles', 'ted_ifc_flag', $
               'mep_ele_flux', 'mep_pro_flux', 'mep_pro_flux_p6', 'mep_omni_flux', 'mep_pitch_angles', 'mep_ifc_flag']
 

  ;create the list box that lists all the probes
  dataBase = widget_base(selectionBase,/row)
  probeBase = widget_base(dataBase,/col)
  probeLabel = widget_label(probeBase,value='Probe: ')
  probeList = widget_list(probeBase,$
                          value=probeArrayDisplayed,$
                          uname='probelist',$
                          uvalue='PROBELIST',$
                          xsize=26,$
                          ysize=15)

  ; default to the first probe in the list 
  widget_control, probeList, set_list_select = 0
  
  clearprobesButton = widget_button(probeBase,value='Clear Probe',uvalue='CLEARPROBE',ToolTip='Deselect all spacecraft')
                          
  ;create the list box and a clear all buttons for the data types for a given index       
  typeBase = widget_base(dataBase,/col)
  typeLabel = widget_label(typeBase,value='Data Type:')
  typeList = widget_list(typeBase,$
                         value=typeArray,$
                         uname='datalist',$
                         uvalue='DATALIST',$
                         xsize=26,$
                         ysize=15,$
                         /multiple)                         
  clearTypeButton = widget_button(typeBase,value='Clear Data Type',uvalue='CLEARTYPE',ToolTip='Deselect all datatypes')

  ; default of the data type list should be *
  widget_control, typeList, set_list_select = 0
  
  contamination_label = widget_label(leftBase, value='These data have known contamination problems: please consult')
  contamination_label2 = widget_label(leftBase, value='Rob Redmon (sem.poes@noaa.gov) for usage recommendations')

                                                                
  state = {baseid:topBase,$
           loadTree:loadTree,$
           treeCopyPtr:treeCopyPtr,$
           timeRangeObj:timeRangeObj,$
           statusBar:statusBar,$
           historyWin:historyWin,$
           loadedData:loadedData,$
           callSequence:callSequence,$
           probeArray:probeArrayValues,$
           typeArray:typeArray}
           
  widget_control,topBase,set_uvalue=state
                                  
  return

end
