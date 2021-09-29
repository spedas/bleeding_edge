;+
;NAME:
;   icon_ui_load_data
;
;PURPOSE:
;   Creates the SPEDAS GUI tab for loading ICON data.
;
;KEYWORDS:
;
;
;HISTORY:
;$LastChangedBy: nikos $
;$LastChangedDate: 2019-03-02 16:20:46 -0800 (Sat, 02 Mar 2019) $
;$LastChangedRevision: 26743 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/icon/spedas_plugin/icon_ui_load_data.pro $
;
;-------------------------------------------------------------------

pro icon_ui_load_data_event,event

  compile_opt hidden,idl2

  err_xxx = 0
  Catch, err_xxx
  IF (err_xxx NE 0) THEN BEGIN
    Catch, /Cancel
    Help, /Last_Message, Output = err_msg
    Print, 'Error--See history'
    ok=error_message('An unknown error occured and the window must be datal2typetarted. See console for details.',$
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

      ;datal2typetore state
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
      'CLEARYEARS': begin
        instrumentlist = widget_info(event.handler,find_by_uname='instrumentlist')
        widget_control,instrumentlist,set_list_select=-1
      end
      'CLEARdatal1type': begin
        datal1typelist = widget_info(event.handler,find_by_uname='datal1typelist')
        widget_control,datal1typelist,set_list_select=-1
      end
      'CLEARdatal2type': begin
        datal2typelist = widget_info(event.handler,find_by_uname='datal2typelist')
        widget_control,datal2typelist,set_list_select=-1
      end
      'CLEARDATA': begin
        ok = dialog_message("This will delete all currently loaded data.  Are you sure you wish to continue?",/question,/default_no,/center)

        if strlowcase(ok) eq 'yes' then begin
          datanames = state.loadedData->getAll(/parent)
          if is_string(datanames) then begin
            for i = 0,n_elements(dataNames)-1 do begin
              datal2typeult = state.loadedData->remove(datanames[i])
              if ~datal2typeult then begin
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
            datal2typeult = state.loadedData->remove((*datanames[i]).groupname)
            if ~datal2typeult then begin
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

        instrumentlist = widget_info(event.handler,find_by_uname='instrumentlist')
        instrumentSelect = widget_info(instrumentlist,/list_select)
        if instrumentSelect[0] eq -1 then begin
          state.statusBar->update,'You must select at least one instrument'
          state.historyWin->update,'ICON add attempted without selecting an instrument'
          break
        endif

        datal1typelist = widget_info(event.handler,find_by_uname='datal1typelist')
        datal1typeSelect = widget_info(datal1typelist,/list_select)
        datal2typelist = widget_info(event.handler,find_by_uname='datal2typelist')
        datal2typeSelect = widget_info(datal2typelist,/list_select)
        if (datal1typeSelect[0] eq -1) and (datal2typeSelect[0] eq -1) then begin
          state.statusBar->update,'You must select at least one data type, either L1 or L2'
          state.historyWin->update,'ICON add attempted without selecting datal1type'
          break
        endif

        instruments = state.instrumentArray[instrumentSelect]
        if datal1typeSelect[0] ne -1 then datal1types = state.datal1typeArray[datal1typeSelect] else datal1types=''
        if datal2typeSelect[0] ne -1 then datal2types = state.datal2typeArray[datal2typeSelect] else datal2types=''

        timeRangeObj = state.timeRangeObj
        timeRangeObj->getProperty,startTime=startTimeObj,endTime=endTimeObj
        startTimeObj->getProperty,tdouble=startTimeDouble,tstring=startTimeString
        endTimeObj->getProperty,tdouble=endTimeDouble,tstring=endTimeString
        if startTimeDouble ge endTimeDouble then begin
          state.statusBar->update,'Cannot add data unless end time is greater than start time.'
          state.historyWin->update,'ICON add attempted with start time greater than end time.'
          break
        endif

        loadStruc = { instrument:instruments,    $
          datal1type:datal1types,  $
          datal2type:datal2types, $
          timeRange:[startTimeString,endTimeString] }

        widget_control, /hourglass

        icon_ui_import_data,$
          loadStruc, $
          state.loadedData, $
          state.statusBar, $
          state.historyWin, $
          state.baseid, $
          overwrite_selections=overwrite_selections

        state.loadTree->update

        callSeqStruc = { type:'loadapidata',       $
          subtype:'icon_ui_import_data',  $
          loadStruc:loadStruc,     $
          overwrite_selections:overwrite_selections }

        state.callSequence->addSt, callSeqStruc

      end
      'instrumentLIST': begin
        instrumentlist = widget_info(event.handler,find_by_uname='instrumentlist')
        instrumentSelect = widget_info(instrumentlist,/list_select)
        if instrumentSelect[0] eq -1 then begin
          state.statusBar->update, 'You must select at least one data level'
          state.historyWin->update, 'ICON add attempted without selecting data level'
        endif else if  instrumentSelect[0] eq 0 then begin
          datal1typeArray = state.datal1typeArray0
          state.datal1typeArray = datal1typeArray
          datal1typelist = widget_info(event.handler,find_by_uname='datal1typelist')
          widget_control,datal1typelist,set_value=datal1typeArray
          datal2typeArray = state.datal2typeArray0
          state.datal2typeArray = datal2typeArray
          datal2typelist = widget_info(event.handler,find_by_uname='datal2typelist')
          widget_control,datal2typelist,set_value=datal2typeArray
        endif else if  instrumentSelect[0] eq 1 then begin
          datal1typeArray = state.datal1typeArray1
          state.datal1typeArray = datal1typeArray
          datal1typelist = widget_info(event.handler,find_by_uname='datal1typelist')
          widget_control,datal1typelist,set_value=datal1typeArray
          datal2typeArray = state.datal2typeArray1
          state.datal2typeArray = datal2typeArray
          datal2typelist = widget_info(event.handler,find_by_uname='datal2typelist')
          widget_control,datal2typelist,set_value=datal2typeArray
        endif else if  instrumentSelect[0] eq 2 then begin
          datal1typeArray = state.datal1typeArray2
          state.datal1typeArray = datal1typeArray
          datal1typelist = widget_info(event.handler,find_by_uname='datal1typelist')
          widget_control,datal1typelist,set_value=datal1typeArray
          datal2typeArray = state.datal2typeArray2
          state.datal2typeArray = datal2typeArray
          datal2typelist = widget_info(event.handler,find_by_uname='datal2typelist')
          widget_control,datal2typelist,set_value=datal2typeArray
        endif else if  instrumentSelect[0] eq 3 then begin
          datal1typeArray = state.datal1typeArray3
          state.datal1typeArray = datal1typeArray
          datal1typelist = widget_info(event.handler,find_by_uname='datal1typelist')
          widget_control,datal1typelist,set_value=datal1typeArray
          datal2typeArray = state.datal2typeArray3
          state.datal2typeArray = datal2typeArray
          datal2typelist = widget_info(event.handler,find_by_uname='datal2typelist')
          widget_control,datal2typelist,set_value=datal2typeArray
        endif

      end
      else:
    endcase
  endif

  Widget_Control, event.handler, Set_UValue=state, /No_Copy

  return

end

pro icon_ui_load_data,tabid,loadedData,historyWin,statusBar,treeCopyPtr,timeRangeObj,callSequence,loadTree=loadTree,timeWidget=timeWidget

  compile_opt idl2,hidden

  ;load bitmap datal2typeources
  getresourcepath,rpath
  rightArrow = read_bmp(rpath + 'arrow_000_medium.bmp', /rgb)
  trashcan = read_bmp(rpath + 'trashcan.bmp', /rgb)

  spd_ui_match_background, tabid, rightArrow
  spd_ui_match_background, tabid, trashcan

  topBase = Widget_Base(tabid, /Row, /Align_Top, /Align_Left, YPad=1,event_pro='icon_ui_load_data_event')

  leftBase = widget_base(topBase,/col)
  middleBase = widget_base(topBase,/col,/align_center)
  rightBase = widget_base(topBase,/col)

  leftLabel = widget_label(leftBase,value='ICON Data Selection:',/align_left)
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

  instrumentArrayValues = ['FUV', 'IVM', 'EUV', 'MIGHTI']  ; ['FUV', 'IVM', 'INST2', 'INST3']
  instrumentArrayDisplayed = ['FUV', 'IVM', 'EUV', 'MIGHTI']  ; ['FUV', 'IVM', 'INST2', 'INST3']
  
  ;Level 1
  datal1typeArray0 = ['*', 'lwp', 'sli', 'ssi', 'swp'] ;fuv
  datal1typeArray1 = ['*'] ;ivm
  datal1typeArray2 = ['*'] ;inst2
  datal1typeArray3 = ['*'] ;inst3
  datal1typeArray = datal1typeArray0

  ;Level 2
  datal2typeArray0 = ['*', 'O-daytime', 'O-nighttime'];fuv
  datal2typeArray1 = ['*'] ;ivm
  datal2typeArray2 = ['*'] ;inst2
  datal2typeArray3 = ['*'] ;inst3
  datal2typeArray = datal2typeArray0 

  ;create the list box that lists all the instruments
  dataBase = widget_base(selectionBase,/row)
  instrumentBase = widget_base(dataBase,/col)
  instrumentLabel = widget_label(instrumentBase,value='Instrument: ')
  instrumentList = widget_list(instrumentBase,$
    value=instrumentArrayDisplayed,$
    uname='instrumentlist',$
    uvalue='instrumentLIST',$
    xsize=16,$
    ysize=15)
  widget_control, instrumentList, set_list_select = 0

  ;create the list box and a clear all buttons for the L1 data types for a given instrument
  datal1typeBase = widget_base(dataBase,/col)
  datal1typeLabel = widget_label(datal1typeBase,value='Level 1:')
  datal1typeList = widget_list(datal1typeBase,$
    value=datal1typeArray,$
    uname='datal1typelist',$
    uvalue='datal1typeLIST',$
    multiple=1,$
    xsize=16,$
    ysize=15)
  CLEARdatal1typeButton = widget_button(datal1typeBase,value='Clear Selection',uvalue='CLEARdatal1type',ToolTip='Deselect all datal1type IDs')
  widget_control, datal1typeList, set_list_select = 0

  ;create the list box and a clear all buttons for the L2 data types for a given instrument
  datal2typeBase = widget_base(dataBase,/col)
  datal2typeLabel = widget_label(datal2typeBase,value='Level 2:')
  datal2typeList = widget_list(datal2typeBase,$
    value=datal2typeArray,$
    uname='datal2typelist',$
    uvalue='datal2typeLIST',$
    multiple=1,$
    xsize=16,$
    ysize=15)
  widget_control, datal2typeList, set_list_select = 0

  CLEARdatal2typeButton = widget_button(datal2typeBase,value='Clear Selection',uvalue='CLEARdatal2type',ToolTip='Deselect all data types')

  availability_str = 'Data Availability Notes: ' +  string(10B) + string(10B) + $
    'Data is available for dates between 2010-05-20 and 2010-05-29.'
  availabilityLabel = widget_label(leftBase, value=availability_str, /align_center, scr_xsize=400, scr_ysize=100, UNITS=0)

  state = {baseid:topBase,$
    loadTree:loadTree,$
    treeCopyPtr:treeCopyPtr,$
    timeRangeObj:timeRangeObj,$
    statusBar:statusBar,$
    historyWin:historyWin,$
    loadedData:loadedData,$
    callSequence:callSequence,$
    instrumentArray:instrumentArrayValues,$    
    datal1typeArray:datal1typeArray,$
    datal1typeArray0:datal1typeArray0,$
    datal1typeArray1:datal1typeArray1,$
    datal1typeArray2:datal1typeArray2,$
    datal1typeArray3:datal1typeArray3,$      
    datal2typeArray:datal2typeArray,$
    datal2typeArray0:datal2typeArray0,$
    datal2typeArray1:datal2typeArray1,$
    datal2typeArray2:datal2typeArray2,$
    datal2typeArray3:datal2typeArray3}

  widget_control,topBase,set_uvalue=state

  return

end