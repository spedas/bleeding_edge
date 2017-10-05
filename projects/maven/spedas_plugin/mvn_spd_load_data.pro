;+ 
;NAME:
;  mvn_spd_load_data
;
;PURPOSE:
;  Generates the tab that loads MAVEN KP data for the gui.
;
;
;HISTORY:
;$LastChangedBy: jimm $
;$LastChangedDate: 2016-01-22 10:16:32 -0800 (Fri, 22 Jan 2016) $
;$LastChangedRevision: 19789 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/spedas_plugin/mvn_spd_load_data.pro $
;
;--------------------------------------------------------------------------------

pro mvn_spd_load_data_event,event

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
                                ;not all widgets are assigned uvalue

  if is_string(uval) then begin
     case uval of
        'INSTRUMENT': begin
           typeList = widget_info(event.handler,find_by_uname='typelist')
           widget_control,typeList,set_value=*state.typeArray[event.index]
           paramList = widget_info(event.handler,find_by_uname='paramlist')
           widget_control,paramList,set_value=*(*state.paramArray[event.index])[0]
        end
        'TYPELIST': begin
           instrument = widget_info(event.handler,find_by_uname='instrument')
           text = widget_info(instrument,/combobox_gettext)
           idx = (where(text eq state.instrumentArray))[0]
           paramList = widget_info(event.handler,find_by_uname='paramlist')
           widget_control,paramList,set_value=*(*state.paramArray[idx])[event.index]
        end
        'CLEARPARAM': begin
           paramlist = widget_info(event.handler,find_by_uname='paramlist')
           widget_control,paramlist,set_list_select=-1
        end
        'CLEARDATA': begin
           ok = dialog_message("This will delete all currently loaded data.  Are you sure you wish to continue?",$
                               /question,/default_no,/center)
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
           instrument = widget_info(event.handler,find_by_uname='instrument')
           instrumentText = widget_info(instrument,/combobox_gettext)
           instrumentSelect = (where(instrumentText eq state.instrumentArray))[0]   
           type = widget_info(event.handler,find_by_uname='typelist')
           typeSelect = widget_info(type,/list_select)
           if typeSelect[0] eq -1 then typeSelect= 0
           typeText = (*state.typeArray[instrumentSelect])[typeSelect]

           parameter = widget_info(event.handler,find_by_uname='paramlist')
           paramSelect = widget_info(parameter,/list_select)
           if paramSelect[0] eq -1 then begin
              state.statusBar->update,'You must select at least one parameter'
              state.historyWin->update,'MAVEN KP add attempted without selecting parameter'
              break
           endif

                                ;handle '*' type, if present, introduce all
           if in_set(0,paramSelect) then begin
              paramText = *(*state.paramArray[instrumentSelect])[typeselect]
           endif else begin
              paramText = (*(*state.paramArray[instrumentSelect])[typeselect])[paramSelect]
           endelse
           timeRangeObj = state.timeRangeObj      
           timeRangeObj->getProperty,startTime=startTimeObj,endTime=endTimeObj
           startTimeObj->getProperty,tdouble=startTimeDouble,tstring=startTimeString
           endTimeObj->getProperty,tdouble=endTimeDouble,tstring=endTimeString
           if startTimeDouble ge endTimeDouble then begin
              state.statusBar->update,'Cannot add data unless end time is greater than start time.'
              state.historyWin->update,'MAVEN KP add attempted with start time greater than end time.'
              break
           endif
           widget_control, /hourglass
           loadStruc = {instrument:instrumentText  , $
                        parameters:paramText, $
                        timeRange:[startTimeString, endTimeString] }   
           mvn_kp_ui_import_data, loadStruc, $
                                  state.loadedData,$
                                  state.statusBar,$
                                  state.historyWin,$
                                  state.baseid,$
                                  overwrite_selections=overwrite_selections
           state.loadTree->update
           callSeqStruc = { type:'loadapidata', $
                            subtype:'mvn_kp_ui_import_data', $
                            loadStruc:loadStruc, $
                            overwrite_selections:overwrite_selections }
           state.callSequence->addSt, callSeqStruc
        end
        else:
     endcase
  endif
  
  Widget_Control, event.handler, Set_UValue=state, /No_Copy
  
  return
  
end


pro mvn_spd_load_data,tabid,loadedData,historyWin,statusBar,treeCopyPtr,timeRangeObj,$
                        callSequence,loadTree=loadTree,timeWidget=timeWidget
  compile_opt idl2,hidden
  
                                ;load bitmap resources
  getresourcepath,rpath
  rightArrow = read_bmp(rpath + 'arrow_000_medium.bmp', /rgb)
  trashcan = read_bmp(rpath + 'trashcan.bmp', /rgb)
  
  spd_ui_match_background, tabid, rightArrow 
  spd_ui_match_background, tabid, trashcan
  
  topBase = Widget_Base(tabid, /Row, /Align_Top, /Align_Left, YPad=1,event_pro='mvn_spd_load_data_event') 
  
  leftBase = widget_base(topBase,/col)
  middleBase = widget_base(topBase,/col,/align_center)
  rightBase = widget_base(topBase,/col)
  
  leftLabel = widget_label(leftBase,value='MAVEN Data Selection:',/align_left)
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
  
  clearDataButton = widget_button(clearDataBase,value='Delete All Data',uvalue='CLEARDATA',$
                                  /align_center,ToolTip='Deletes all loaded data')
  
  timeLabel = widget_label(selectionBase,value='MAVEN PFP data ')
 
  timeWidget = spd_ui_time_widget(selectionBase,$
                                  statusBar,$
                                  historyWin,$
                                  timeRangeObj=timeRangeObj,$
                                  uvalue='TIME_WIDGET',$
                                  uname='time_widget',$
                                  startyear=2014)
  
  instrumentBase = widget_base(selectionBase,/row) 
  
  instrumentLabel = widget_label(instrumentBase,value='Instrument Type: ')
  
  instrumentArray = ['LPW-EUV', 'LPW', 'MAG','NGIMS','SEP','STATIC','SWEA','SWIA','SPICE']
  ninstruments = n_elements(instrumentArray)

  instrumentCombo = widget_combobox(instrumentBase,$
                                    value=instrumentArray,$
                                    uvalue='INSTRUMENT',$
                                    uname='instrument')
                                              

  dataBase = widget_base(selectionBase,/row)

  typeArray = ptrarr(ninstruments)
  For j = 0, ninstruments-1 Do typeArray[j] = ptr_new(['KP']) ;so far only 1 type of data
  typeBase = widget_base(dataBase,/col)
  typeLabel = widget_label(typeBase,value='Data Type: ')
  typeList = widget_list(typeBase,$
                         value=*typeArray[0],$
                         uname='typelist',$
                         uvalue='TYPELIST',$
                         xsize=16,$
                         ysize=15)
  
  widget_control,typeList,set_list_select=0
  
  datatype_ptr = mvn_kp_ui_datatypes()       ;but right now there's only 1, so this is an ptrarr of ninstruments
  paramArray = ptrarr(ninstruments)
  For j = 0, ninstruments-1 Do paramArray[j] = ptr_new(datatype_ptr[j])

  paramBase = widget_base(dataBase,/col)
  paramLabel = widget_label(paramBase,value='Parameter(s):')
  paramList = widget_list(paramBase,$
                          value=*(*paramarray[0])[0],$
                          /multiple,$
                          uname='paramlist',$
                          xsize=24,$
                          ysize=15)
                         
  clearTypeButton = widget_button(paramBase,value='Clear Parameter',uvalue='CLEARPARAM',$
                                  ToolTip='Deselect all parameters types')
                                                           
  
  state = {baseid:topBase,$
           loadTree:loadTree,$
           treeCopyPtr:treeCopyPtr,$
           timeRangeObj:timeRangeObj,$
           statusBar:statusBar,$
           historyWin:historyWin,$
           loadedData:loadedData,$
           callSequence:callSequence,$
           instrumentArray:instrumentArray,$
           typeArray:typeArray,$
           paramArray:paramArray}
           
  widget_control,topBase,set_uvalue=state
                                  
  return

end
