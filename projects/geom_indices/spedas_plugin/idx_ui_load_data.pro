;+ 
;NAME:
;  idx_ui_load_data
;
;PURPOSE:
;  Widget interface for loading Geomagnetic/Solar indices data into the GUI
;
;HISTORY:
;$LastChangedBy: egrimes $
;$LastChangedDate: 2015-04-16 16:09:24 -0700 (Thu, 16 Apr 2015) $
;$LastChangedRevision: 17344 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/geom_indices/spedas_plugin/idx_ui_load_data.pro $
;
;--------------------------------------------------------------------------------
pro idx_ui_load_data_event,event
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
       /noname, /center, title='Error in Load Geomagnetic Indices Data')

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
      'DATALIST': begin
        rlistparam = widget_info(event.handler, find_by_uname='reslist')
        dlistparam = widget_info(event.handler, find_by_uname='datalist')
        curvalue = widget_info(dlistparam, /list_select)
        ilistparam = widget_info(event.handler, find_by_uname='indexlist')
        ; index of current indexlist selection
        ilistselect = widget_info(ilistparam, /list_select) 
        widget_control, rlistparam, set_value=*(*state.ptrindexResolutions[ilistselect])[curvalue]
      end
      'INDEXLIST': begin 
        ; user clicked inside index list
        ilistparam = widget_info(event.handler, find_by_uname='indexlist')
        ; index of current indexlist selection
        ilistselect = widget_info(ilistparam, /list_select) 
        dlistparam = widget_info(event.handler,find_by_uname='datalist')
        widget_control, dlistparam, set_value=*state.typeArray[event.index]
        rlistparam = widget_info(event.handler,find_by_uname='reslist')
        widget_control, rlistparam, set_value=*(*state.ptrindexResolutions[ilistselect])[0]
        
        ; use the top option as the default data type
        widget_control, dlistparam, set_list_select=0
        ; use the top option as the default resolution
        widget_control, rlistparam, set_list_select=0
        
        ; set the labels so the user knows where the data comes from
        sourcelabel1 = widget_info(event.handler, find_by_uname='dataSource1')
        sourcelabel2 = widget_info(event.handler, find_by_uname='dataSource2')
        widget_control, sourcelabel1, set_value=(*state.dsourceLabels[event.index])[0]
        widget_control, sourcelabel2, set_value=(*state.dsourceLabels[event.index])[1]
      end
      'CLEARINDEX': begin 
        ;clear the index list widget of any selections
        indexlist = widget_info(event.handler,find_by_uname='indexlist')
        widget_control,indexlist,set_list_select=-1
      end
      'CLEARTYPE': begin
        ;clear the data type list widget of all selections
        datalist = widget_info(event.handler,find_by_uname='datalist')
        widget_control,datalist,set_list_select=-1
      end
      'CLEARRES': begin
        ;clear the data type list widget of all selections
        reslist = widget_info(event.handler,find_by_uname='reslist')
        widget_control,reslist,set_list_select=-1
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
            endif else begin
              ; store deletion in the call sequence object
              state.callSequence->adddeletecall,(*datanames[i]).groupname
            endelse
          endfor
        endif
        state.loadTree->update      
   
      end
      'ADD': begin
        ;retrieve the data types that were selected by the user
        datalist = widget_info(event.handler,find_by_uname='datalist')
        typeSelect = widget_info(datalist,/list_select)
        
        ;if no selections were made, report this to the user via the 
        ;status bar and log the error to the history window
        if typeSelect[0] eq -1 then begin
          state.statusBar->update,'You must select at least one data type'
          state.historyWin->update,'Load Geomagnetic Indices add attempted without selecting data type'
          break
        endif
        
        ;retrieve the indices that were selected by the user
        indexlist = widget_info(event.handler,find_by_uname='indexlist')
        indexSelect = widget_info(indexlist,/list_select)        

        ;if no selections were made, report this to the status bar and 
        ;history window
        if indexSelect[0] eq -1 then begin
          state.statusBar->update,'You must select at least one index'
          state.historyWin->update,'Load Geomagnetic Indices add attempted without selecting index'
          break
        endif
        
        reslist = widget_info(event.handler, find_by_uname='reslist')
        resSelect = widget_info(reslist, /list_select)
        
        if resSelect[0] eq -1 then begin
          state.statusBar->update,'You must select at least one resolution'
          state.historyWin->update,'Load Geomagnetic Indices add attempted without selecting resolution'
          break
        endif 
        
        ; index to load
        indices = state.indexArray[indexSelect]
        ; datatype to load
        types = (*state.typeArray[indexSelect])[typeSelect]
        ; resolution to load
        resolution = (*(*state.ptrindexResolutions[indexSelect])[typeSelect])[resSelect]

        ;get the start and stop times 
        timeRangeObj = state.timeRangeObj      
        timeRangeObj->getProperty,startTime=startTimeObj,endTime=endTimeObj      
        startTimeObj->getProperty,tdouble=startTimeDouble,tstring=startTimeString
        endTimeObj->getProperty,tdouble=endTimeDouble,tstring=endTimeString
        
        ;report errors
        if startTimeDouble ge endTimeDouble then begin
          state.statusBar->update,'Cannot add data unless end time is greater than start time.'
          state.historyWin->update,'Load Geomagnetic Indices add attempted with start time greater than end time.'
          break
        endif
        
        ;turn on the hour glass while the data is being loaded
        widget_control, /hourglass

        ;create a load structure to pass the parameters needed by the load procedure
        loadStruc = { index:indices, $
                      datatypes:types, $
                      resolution:resolution, $
                      timeRange:[startTimeString, endTimeString] }

        ;call the routine that loads the indices
        idx_ui_import_data, $
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
         ;later session. 
         callSeqStruc = { type:'loadapidata', $
                          subtype:'idx_ui_import_data', $
                          loadStruc:loadStruc, $
                          overwrite_selections:overwrite_selections }
                          
         ; add the information regarding this load to the call sequence object
         state.callSequence->addSt, callSeqStruc
         
      end
      else:
    endcase
  endif
  
  ;set the state structure before returning to the panel
  Widget_Control, event.handler, Set_UValue=state, /No_Copy
  
  return
end
; creates 'data is provided by' acknowledgements to display under data list boxes
function spd_ui_index_source_data
  ; each element in the pointer array points to a list containing 2 strings
  ; that describe the data type and availability
  dsourceLabels = ptrarr(11)
  dsourceLabels[0] = ptr_new(['Ap data is provided by the NOAA National Geophysical Data Center',' '])
  dsourceLabels[1] = ptr_new(['Auroral Electrojet (AE) data is provided by the WDC for Geomagnetism,','Kyoto (Japan)'])
  dsourceLabels[2] = ptr_new(['Cp data is provided by the NOAA National Geophysical Data Center',' '])
  dsourceLabels[3] = ptr_new(['C9 data is provided by the NOAA National Geophysical Data Center',' '])
  dsourceLabels[4] = ptr_new(['Disturbance storm-time (Dst) index data is provided by the WDC ','for Geomagnetism, Kyoto (Japan).'])
  dsourceLabels[5] = ptr_new(['10.7-cm solar radio flux data is provided by the NOAA ','National Geophysical Data Center'])
  dsourceLabels[6] = ptr_new(['Kp data is provided by the NOAA National Geophysical Data Center',' '])
  dsourceLabels[7] = ptr_new(['Solar rotation data is provided by the NOAA National Geophysical','Data Center'])
  dsourceLabels[8] = ptr_new(['Solar rotation data is provided by the NOAA National Geophysical','Data Center'])
  dsourceLabels[9] = ptr_new(['International sunspot number data is provided by the NOAA','National Geophysical Data Center'])
  dsourceLabels[10] = ptr_new(['SYM/ASY data are loaded from the OMNI dataset, provided','by NASA ISTP/SPDF'])
  return, dsourceLabels
end
; create an array of pointers to datatype lists
; each index has its own list of datatypes
function spd_ui_index_data_types
  paramArray = ptrarr(11)
  paramArray[0] = ptr_new(['*', 'ap', 'Ap (ap mean)'])
  paramArray[1] = ptr_new(['*','AE prov','AO prov','AU prov','AL prov','AX prov']) ; AE
  paramArray[2] = ptr_new(['Cp'])
  paramArray[3] = ptr_new(['C9'])
  paramArray[4] = ptr_new(['Dst']) ; Dst
  paramArray[5] = ptr_new(['F10.7'])
  paramArray[6] = ptr_new(['*','Kp', 'Kp sum']) ; Kp/Ap
  paramArray[7] = ptr_new(['Solar rotation #']) 
  paramArray[8] = ptr_new(['Solar rotation day'])
  paramArray[9] = ptr_new(['Sunspot #'])
  paramArray[10] = ptr_new(['*','Sym-H', 'Sym-D', 'Asy-H', 'Asy-D' ])
  return, paramArray
end
; create an array of pointers to available resolutions
function spd_ui_index_resolutions
  resArray = ptrarr(11)
  apRes = ptrarr(3)
  aeRes = ptrarr(6)
  cpRes = ptrarr(1)
  c9Res = ptrarr(1)
  dstRes = ptrarr(1)
  f107Res = ptrarr(1)
  kpRes = ptrarr(3)
  solrotRes = ptrarr(1)
  soldayRes = ptrarr(1)
  sunspotRes = ptrarr(1)
  symRes = ptrarr(5)
  
  apRes[0] = ptr_new('*')
  apRes[1] = ptr_new('3-hour')
  apRes[2] = ptr_new('daily')
  aeRes[0] = ptr_new('*')
  for i=1,n_elements(aeRes)-1 do aeRes[i] = ptr_new('1-min')
  cpRes[0] = ptr_new('daily')
  c9Res[0] = ptr_new('daily')
  dstRes[0] = ptr_new('1-hour')
  f107Res[0] = ptr_new('daily')
  kpRes[0] = ptr_new('*')
  kpRes[1] = ptr_new('3-hour')
  kpRes[2] = ptr_new('daily')
  solrotRes[0] = ptr_new('daily')
  soldayRes[0] = ptr_new('daily')
  sunspotRes[0] = ptr_new('daily')
  ;symRes[0] = ptr_new('*')
  for i=0,n_elements(symRes)-1 do symRes[i] = ptr_new(['*', '1-min','5-min'])

  resArray[0] = ptr_new(apRes)
  resArray[1] = ptr_new(aeRes)
  resArray[2] = ptr_new(cpRes)
  resArray[3] = ptr_new(c9Res)
  resArray[4] = ptr_new(dstRes)
  resArray[5] = ptr_new(f107Res)
  resArray[6] = ptr_new(kpRes)
  resArray[7] = ptr_new(solrotRes)
  resArray[8] = ptr_new(soldayRes)
  resArray[9] = ptr_new(sunspotRes)
  resArray[10] = ptr_new(symRes)
  return, resArray
end
pro idx_ui_load_data,tabid,loadedData,historyWin,statusBar,treeCopyPtr,timeRangeObj,callSequence,loadTree=loadTree,timeWidget=timeWidget
  compile_opt idl2,hidden
  
  ;load bitmap resources
  getresourcepath,rpath
  rightArrow = read_bmp(rpath + 'arrow_000_medium.bmp', /rgb)
  trashcan = read_bmp(rpath + 'trashcan.bmp', /rgb)
  
  spd_ui_match_background, tabid, rightArrow 
  spd_ui_match_background, tabid, trashcan
  
  ;create all the bases needed for the widgets on the panel 
  topBase = Widget_Base(tabid, /Row, /Align_Top, /Align_Left, YPad=1,event_pro='idx_ui_load_data_event') 
  
  leftBase = widget_base(topBase,/col)
  middleBase = widget_base(topBase,/col,/align_center)
  rightBase = widget_base(topBase,/col)
  
  leftLabel = widget_label(leftBase,value='Geomagnetic & Solar Indices Data:',/align_left)
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
  timeWidget = spd_ui_time_widget(selectionBase,$
                                  statusBar,$
                                  historyWin,$
                                  timeRangeObj=timeRangeObj,$
                                  uvalue='TIME_WIDGET',$
                                  uname='time_widget')
    
  ; populate the index listbox
  indexArrayValues = ['Ap', 'AE', 'Cp', 'C9', 'Dst', 'F10.7', 'Kp', 'Solar rotation #', 'Solar rotation day', 'Sunspot #', 'SYM/ASY']
  ; create array of pointers to datatype lists
  paramArray = spd_ui_index_data_types()
  ; create 'data is provided by' acknowledgements to display under data list boxes
  ptrSourceLabels = spd_ui_index_source_data()
  ; create array of pointers to available resolution lists for every datatype
  ptrindexResolutions = spd_ui_index_resolutions()

  ;create the list box that lists all the indices
  dataBase = widget_base(selectionBase,/row)
  indexBase = widget_base(dataBase,/col)
  indexLabel = widget_label(indexBase,value='Index: ')
  indexList = widget_list(indexBase,$
                          value=indexArrayValues,$
                          uname='indexlist',$
                          uvalue='INDEXLIST',$
                          xsize=16,$
                          ysize=15)
  ; default the index list should be AE
  widget_control, indexList, set_list_select = 0
  
  clearindexButton = widget_button(indexBase,value='Clear Indices',uvalue='CLEARINDEX',ToolTip='Deselect all indices')
                          
  ;create the list box and a clear all buttons for the data types for a given index       
  typeBase = widget_base(dataBase,/col)
  typeLabel = widget_label(typeBase,value='Data Type:')
  typeList = widget_list(typeBase,$
                         value=*paramArray[0],$
                         uname='datalist',$
                         uvalue='DATALIST',$
                         xsize=16,$
                         ysize=15)                         
  clearTypeButton = widget_button(typeBase,value='Clear Data Type',uvalue='CLEARTYPE',ToolTip='Deselect all index types')

  ; default of the data type list should be *
  widget_control, typeList, set_list_select = 0
  
  ;create the list box and a clear all button for the resolution options
  resBase = widget_base(dataBase,/col)
  resLabel = widget_label(resBase,value='Resolution:')
  resList = widget_list(resBase,$
                         value=*(*ptrindexResolutions[0])[0],$
                         uname='reslist',$
                         xsize=16,$
                         ysize=15)                         
  clearResButton = widget_button(resBase,value='Clear Resolution',uvalue='CLEARRES',ToolTip='Deselect all resolutions')

  ; data source/acknowledgement labels
  dataSourceLabel1 = widget_label(leftBase, value=(*ptrSourceLabels[0])[0], uname='dataSource1', /align_left, /dynamic_resize)
  dataSourceLabel2 = widget_label(leftBase, value=(*ptrSourceLabels[0])[1], uname='dataSource2', /align_left, /dynamic_resize)
  
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
           indexArray:indexArrayValues,$
           typeArray:paramArray,$
           dsourceLabels:ptrSourceLabels,$
           ptrindexResolutions:ptrindexResolutions }            
  widget_control,topBase,set_uvalue=state

  return

end
