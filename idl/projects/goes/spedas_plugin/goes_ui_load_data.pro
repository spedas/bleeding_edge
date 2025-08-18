;+ 
;NAME:
;  goes_ui_load_data
;
;PURPOSE:
;  Generates the tab that loads goes data for the gui.
;
;
;HISTORY:
;$LastChangedBy: egrimes $
;$LastChangedDate: 2015-04-15 15:14:31 -0700 (Wed, 15 Apr 2015) $
;$LastChangedRevision: 17332 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/goes/spedas_plugin/goes_ui_load_data.pro $
;
;--------------------------------------------------------------------------------
pro goes_ui_load_data_event,event

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
          state.historyWin->update,'GOES add attempted without selecting data type'
          break
        endif

        types = state.typeArray[typeSelect]
        
        reslist = widget_info(event.handler,find_by_uname='reslist')
        resSelect = widget_info(reslist,/list_select)

        if resSelect[0] eq -1 then begin
            state.statusBar->update, 'You must select at least one resolution'
            state.historyWin->update, 'GOES add attempted without selecting resolution'
            break
        endif 
        
        resolution = state.resArray[resSelect]
        
        probelist = widget_info(event.handler,find_by_uname='probelist')
        probeSelect = widget_info(probelist,/list_select)
        
        if probeSelect[0] eq -1 then begin
          state.statusBar->update,'You must select at least one probe'
          state.historyWin->update,'GOES add attempted without selecting probe'
          break
        endif
        
        probes = state.probeArray[probeSelect]
        
        timeRangeObj = state.timeRangeObj      
        timeRangeObj->getProperty,startTime=startTimeObj,endTime=endTimeObj
      
        startTimeObj->getProperty,tdouble=startTimeDouble,tstring=startTimeString
        endTimeObj->getProperty,tdouble=endTimeDouble,tstring=endTimeString
        
        if startTimeDouble ge endTimeDouble then begin
          state.statusBar->update,'Cannot add data unless end time is greater than start time.'
          state.historyWin->update,'GOES add attempted with start time greater than end time.'
          break
        endif
        
        loadStruc = { probe:probes,    $
                      datatype:types,  $
                      restype:resolution, $
                      timeRange:[startTimeString,endTimeString] }
        
        widget_control, /hourglass
        
        goes_ui_import_data,$
                      loadStruc, $
                      state.loadedData, $
                      state.statusBar, $
                      state.historyWin, $
                      state.baseid, $
                      overwrite_selections=overwrite_selections                            
      
        state.loadTree->update
        
        callSeqStruc = { type:'loadapidata',       $
                         subtype:'goes_ui_import_data',  $
                         loadStruc:loadStruc,     $
                         overwrite_selections:overwrite_selections }
                      
        state.callSequence->addSt, callSeqStruc
     
      end
      'CHECK_DATA_AVAIL': begin
        spd_ui_open_url, 'http://themis.ssl.berkeley.edu/data_products/#goes'
      end
      'RULESOFTHEROAD': begin
        spd_ui_open_url, 'http://spedas.org/wiki/index.php?title=GOES_Rules_of_the_Road'
      end
      else:
    endcase
  endif
  
  Widget_Control, event.handler, Set_UValue=state, /No_Copy
  
  return
  
end


pro goes_ui_load_data,tabid,loadedData,historyWin,statusBar,treeCopyPtr,timeRangeObj,callSequence,loadTree=loadTree,timeWidget=timeWidget
  compile_opt idl2,hidden

  ;load bitmap resources
  getresourcepath,rpath
  rightArrow = read_bmp(rpath + 'arrow_000_medium.bmp', /rgb)
  trashcan = read_bmp(rpath + 'trashcan.bmp', /rgb)
  
  spd_ui_match_background, tabid, rightArrow 
  spd_ui_match_background, tabid, trashcan
  
  topBase = Widget_Base(tabid, /Row, /Align_Top, /Align_Left, YPad=1,event_pro='goes_ui_load_data_event') 
  
  leftBase = widget_base(topBase,/col)
  middleBase = widget_base(topBase,/col,/align_center)
  rightBase = widget_base(topBase,/col)
  
  leftLabel = widget_label(leftBase,value='GOES Data Selection:',/align_left)
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
                                  startyear=1995)
    
 ; probeArrayValues = ['*','g10','g11','g12']
 ; probeArrayDisplayed = ['*(All)','GOES 10','GOES 11','GOES 12']
  probeArrayValues = ['8', '9', '10', '11', '12', '13', '14', '15']
  probeArrayDisplayed = ['GOES 8', 'GOES 9', 'GOES 10', 'GOES 11', 'GOES 12', 'GOES 13', 'GOES 14', 'GOES 15']
  
  typeArray = ['xrs', 'fgm', 'eps', 'maged', 'magpd', 'epead', 'hepad']
  ;typeArray = ['*','b_gsm','b_gei','b_enp','b_total','pos_gsm','pos_gei','vel_gei','t1_counts','t2_counts','dataqual','longitude','mlt']
  
  resArray = ['full', '1-m', '5-m']

  ;create the list box that lists all the probes
  dataBase = widget_base(selectionBase,/row)
  probeBase = widget_base(dataBase,/col)
  probeLabel = widget_label(probeBase,value='Probe: ')
  probeList = widget_list(probeBase,$
                          value=probeArrayDisplayed,$
                          uname='probelist',$
                          uvalue='PROBELIST',$
                          xsize=16,$
                          ysize=15)
  ; default the index list should be AE
  widget_control, probeList, set_list_select = 0
  
  clearprobesButton = widget_button(probeBase,value='Clear Probe',uvalue='CLEARPROBE',ToolTip='Deselect all spacecraft')
                          
  ;create the list box and a clear all buttons for the data types for a given index       
  typeBase = widget_base(dataBase,/col)
  typeLabel = widget_label(typeBase,value='Data Type:')
  typeList = widget_list(typeBase,$
                         value=typeArray,$
                         uname='datalist',$
                         uvalue='DATALIST',$
                         xsize=16,$
                         ysize=15)                         
  clearTypeButton = widget_button(typeBase,value='Clear Data Type',uvalue='CLEARTYPE',ToolTip='Deselect all datatypes')

  ; default of the data type list should be *
  widget_control, typeList, set_list_select = 0
  
  ;create the list box and a clear all button for the resolution options
  resBase = widget_base(dataBase,/col)
  resLabel = widget_label(resBase,value='Resolution:')
  resList = widget_list(resBase,$
                         value=resArray,$
                         uname='reslist',$
                         uvalue='RESLIST',$
                         xsize=16,$
                         ysize=15)
                         
  ; set the default resolution to full
  widget_control, resList, set_list_select = 0
           
  clearResButton = widget_button(resBase,value='Clear Resolution',uvalue='CLEARRES',ToolTip='Deselect all resolutions')

  davailabilitybutton = widget_button(leftBase, val = ' Check data availability', $
                                      uval = 'CHECK_DATA_AVAIL', /align_center, $
                                      ToolTip = 'Check data availability on the web')
  davaRoRbutton = widget_button(leftBase, val = 'Rules of the Road', $
                                      uval = 'RULESOFTHEROAD', /align_center, $
                                      ToolTip = 'See the GOES Rules of the Road on the web')
                                                                
  state = {baseid:topBase,$
           loadTree:loadTree,$
           treeCopyPtr:treeCopyPtr,$
           timeRangeObj:timeRangeObj,$
           statusBar:statusBar,$
           historyWin:historyWin,$
           loadedData:loadedData,$
           callSequence:callSequence,$
           probeArray:probeArrayValues,$
           resArray:resArray,$
           typeArray:typeArray}
           
  widget_control,topBase,set_uvalue=state
                                  
  return

end
