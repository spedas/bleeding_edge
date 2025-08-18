;+
;NAME:
;  barrel_ui_load_data
;
;PURPOSE:
;  Generates the tab that loads BARREL data for the SPEDAS GUI.
;
;HISTORY:
;$LastChangedBy: egrimes $
;$LastChangedDate: 2015-04-15 15:14:31 -0700 (Wed, 15 Apr 2015) $
;$LastChangedRevision: 17332 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/barrel/spedas_plugin/barrel_ui_load_data.pro $
;
;--------------------------------------------------------------------------------

pro barrel_ui_load_data_event,event

  compile_opt hidden,idl2

  err_xxx = 0
  Catch, err_xxx
  IF (err_xxx NE 0) THEN BEGIN
    Catch, /Cancel
    Help, /Last_Message, Output = err_msg
    Print, 'Error--See history'
    ok=error_message('An unknown error occured and the window must be datatypetarted. See console for details.',$
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

      ;datatypetore state
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
        campaignyearlist = widget_info(event.handler,find_by_uname='campaignyearlist')
        widget_control,campaignyearlist,set_list_select=-1
      end
      'CLEARPAYLOAD': begin
        payloadlist = widget_info(event.handler,find_by_uname='payloadlist')
        widget_control,payloadlist,set_list_select=-1
      end
      'CLEARDATATYPE': begin
        datatypelist = widget_info(event.handler,find_by_uname='datatypelist')
        widget_control,datatypelist,set_list_select=-1
      end
      'CLEARDATA': begin
        ok = dialog_message("This will delete all currently loaded data.  Are you sure you wish to continue?",/question,/default_no,/center)

        if strlowcase(ok) eq 'yes' then begin
          datanames = state.loadedData->getAll(/parent)
          if is_string(datanames) then begin
            for i = 0,n_elements(dataNames)-1 do begin
              datatypeult = state.loadedData->remove(datanames[i])
              if ~datatypeult then begin
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
            datatypeult = state.loadedData->remove((*datanames[i]).groupname)
            if ~datatypeult then begin
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

        campaignyearlist = widget_info(event.handler,find_by_uname='campaignyearlist')
        campaignyearSelect = widget_info(campaignyearlist,/list_select)
        if campaignyearSelect[0] eq -1 then begin
          state.statusBar->update,'You must select at least one campaign year'
          state.historyWin->update,'BARREL add attempted without selecting campaign year'
          break
        endif

        payloadlist = widget_info(event.handler,find_by_uname='payloadlist')
        payloadSelect = widget_info(payloadlist,/list_select)
        if payloadSelect[0] eq -1 then begin
          state.statusBar->update,'You must select at least one payload ID'
          state.historyWin->update,'BARREL add attempted without selecting payload ID'
          break
        endif

        datatypelist = widget_info(event.handler,find_by_uname='datatypelist')
        datatypeSelect = widget_info(datatypelist,/list_select)
        if datatypeSelect[0] eq -1 then begin
          state.statusBar->update, 'You must select at least one data type'
          state.historyWin->update, 'BARREL add attempted without selecting data type'
          break
        endif

        campaignyears = state.campaignyearArray[campaignyearSelect]
        payloads = state.payloadArray[payloadSelect]
        datatypes = state.datatypeArray[datatypeSelect]

        timeRangeObj = state.timeRangeObj
        timeRangeObj->getProperty,startTime=startTimeObj,endTime=endTimeObj
        startTimeObj->getProperty,tdouble=startTimeDouble,tstring=startTimeString
        endTimeObj->getProperty,tdouble=endTimeDouble,tstring=endTimeString
        if startTimeDouble ge endTimeDouble then begin
          state.statusBar->update,'Cannot add data unless end time is greater than start time.'
          state.historyWin->update,'BARREL add attempted with start time greater than end time.'
          break
        endif

        loadStruc = { campaignyear:campaignyears,    $
          probe:payloads,  $
          datatype:datatypes, $
          timeRange:[startTimeString,endTimeString] }

        widget_control, /hourglass

        barrel_ui_import_data,$
          loadStruc, $
          state.loadedData, $
          state.statusBar, $
          state.historyWin, $
          state.baseid, $
          overwrite_selections=overwrite_selections

        state.loadTree->update

        callSeqStruc = { type:'loadapidata',       $
          subtype:'barrel_ui_import_data',  $
          loadStruc:loadStruc,     $
          overwrite_selections:overwrite_selections }

        state.callSequence->addSt, callSeqStruc

      end
      'CAMPAIGNYEARLIST': begin
        campaignyearlist = widget_info(event.handler,find_by_uname='campaignyearlist')
        campaignyearSelect = widget_info(campaignyearlist,/list_select)
        if campaignyearSelect[0] eq -1 then begin
          state.statusBar->update, 'You must select at least one data level'
          state.historyWin->update, 'BARREL add attempted without selecting data level'
        endif else if  campaignyearSelect[0] eq 0 then begin
          payloadArray = state.payloadArray12
          state.payloadArray = payloadArray
          payloadlist = widget_info(event.handler,find_by_uname='payloadlist')
          widget_control,payloadlist,set_value=payloadArray
        endif else if  campaignyearSelect[0] eq 1 then begin
          payloadArray = state.payloadArray13
          state.payloadArray = payloadArray
          payloadlist = widget_info(event.handler,find_by_uname='payloadlist')
          widget_control,payloadlist,set_value=payloadArray
        endif

      end
      else:
    endcase
  endif

  Widget_Control, event.handler, Set_UValue=state, /No_Copy

  return

end

pro barrel_ui_load_data,tabid,loadedData,historyWin,statusBar,treeCopyPtr,timeRangeObj,callSequence,loadTree=loadTree,timeWidget=timeWidget

  compile_opt idl2,hidden

  ;load bitmap datatypeources
  getresourcepath,rpath
  rightArrow = read_bmp(rpath + 'arrow_000_medium.bmp', /rgb)
  trashcan = read_bmp(rpath + 'trashcan.bmp', /rgb)

  spd_ui_match_background, tabid, rightArrow
  spd_ui_match_background, tabid, trashcan

  topBase = Widget_Base(tabid, /Row, /Align_Top, /Align_Left, YPad=1,event_pro='barrel_ui_load_data_event')

  leftBase = widget_base(topBase,/col)
  middleBase = widget_base(topBase,/col,/align_center)
  rightBase = widget_base(topBase,/col)

  leftLabel = widget_label(leftBase,value='BARREL Data Selection:',/align_left)
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

  campaignyearArrayValues = ['2012-2013', '2013-2014']
  campaignyearArrayDisplayed = ['2012-2013', '2013-2014']

  payloadArray12 = ['*', '1A', '1B', '1C', '1D', '1G', '1H', '1I', '1J', '1K', '1M', '1N', '1O', '1Q', '1R', '1S', '1T', '1U', '1V']
  payloadArray13 = ['*', '2A', '2B', '2C', '2D', '2E', '2F', '2I', '2K', '2L', '2M', '2N', '2O', '2P', '2Q', '2T', '2W', '2X', '2Y']
  payloadArray = payloadArray12

  ;typeArray = ['*', 'MAGN','FSPC','MSPC','SSPC','HKPG','GPS','PPS','RCNT']
  datatypeArray = ['*',  'EPHM', 'FSPC', 'MSPC', 'SSPC']

  ;create the list box that lists all the payload years
  dataBase = widget_base(selectionBase,/row)
  campaignyearBase = widget_base(dataBase,/col)
  campaignyearLabel = widget_label(campaignyearBase,value='Campaign Year: ')
  campaignyearList = widget_list(campaignyearBase,$
    value=campaignyearArrayDisplayed,$
    uname='campaignyearlist',$
    uvalue='CAMPAIGNYEARLIST',$
    xsize=16,$
    ysize=15)
  widget_control, campaignyearList, set_list_select = 0

  ;CLEARYEARSsButton = widget_button(campaignyearBase,value='Clear Campaign Year',uvalue='CLEARYEARS',ToolTip='Deselect all campaign years')

  ;create the list box and a clear all buttons for the data payloads for a given year
  payloadBase = widget_base(dataBase,/col)
  payloadLabel = widget_label(payloadBase,value='Payload ID:')
  payloadList = widget_list(payloadBase,$
    value=payloadArray,$
    uname='payloadlist',$
    uvalue='PAYLOADLIST',$
    multiple=1,$
    xsize=16,$
    ysize=15)
  CLEARPAYLOADButton = widget_button(payloadBase,value='Clear Payload ID',uvalue='CLEARPAYLOAD',ToolTip='Deselect all payload IDs')
  widget_control, payloadList, set_list_select = 0

  ;create the list box and a clear all button for the data type options
  datatypeBase = widget_base(dataBase,/col)
  datatypeLabel = widget_label(datatypeBase,value='Data Type:')
  datatypeList = widget_list(datatypeBase,$
    value=datatypeArray,$
    uname='datatypelist',$
    uvalue='DATATYPELIST',$
    multiple=1,$
    xsize=16,$
    ysize=15)
  widget_control, datatypeList, set_list_select = 0

  CLEARDATATYPEButton = widget_button(datatypeBase,value='Clear Data Type',uvalue='CLEARDATATYPE',ToolTip='Deselect all data types')

  availability_str = 'Data Availability Notes: ' +  string(10B) + string(10B) + $
    '2012-2013: data is available between 2013-01-01 and 2013-02-16'  +  string(10B) + string(10B) + $
    '2013-2014: data is available between 2013-12-27 and 2014-02-11'  +  string(10B) + string(10B) + '(also depends on payload ID)'
  availabilityLabel = widget_label(leftBase, value=availability_str, /align_center, scr_xsize=400, scr_ysize=100, UNITS=0)

  state = {baseid:topBase,$
    loadTree:loadTree,$
    treeCopyPtr:treeCopyPtr,$
    timeRangeObj:timeRangeObj,$
    statusBar:statusBar,$
    historyWin:historyWin,$
    loadedData:loadedData,$
    callSequence:callSequence,$
    campaignyearArray:campaignyearArrayValues,$
    datatypeArray:datatypeArray,$
    payloadArray:payloadArray,$
    payloadArray12:payloadArray12,$
    payloadArray13:payloadArray13}

  widget_control,topBase,set_uvalue=state

  return

end