;+ 
;NAME:
;  thm_ui_load_data_file
;
;PURPOSE:
;  A widget interface for loading THEMIS data into the SPEDAS GUI
;
;CALLING SEQUENCE:
;  thm_ui_load_data_file, tab_id, loadedData, historyWin, statusText, $
;                         treeCopyPtr, trObj, callSequence, $
;                         loadTree=loadList, timeWidget=timeid
;
;INPUT:
;  tab_id:  The widget id of the tab.
;  loadedData:  The loadedData object.
;  historyWin:  The history window object.
;  statusText:  The status bar object for the main Load window.
;  treeCopyPtr:  Pointer variable to a copy of the load widget tree.
;  trObj:  The GUI timerange object.
;  callSequence:  Reference to GUI call sequence object
;
;OUTPUT:
;  loadTree = The Load widget tree.
;  timeWidget = The time widget object.
;
;NOTES:
;  
;
;$LastChangedBy: jwl $
;$LastChangedDate: 2022-03-01 16:32:46 -0800 (Tue, 01 Mar 2022) $
;$LastChangedRevision: 30638 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/spedas_plugin/load_data/thm_ui_load_data_file.pro $
;
;-

Pro thm_ui_load_data_file_event, event;, info
  Compile_Opt idl2, hidden

  ; get the state structure from the widget
  base = event.handler
  widget_control, base, Get_UValue=state, /no_copy

  ; handle and report errors
  err_xxx = 0
  Catch, err_xxx
  IF (err_xxx NE 0) THEN BEGIN
    Catch, /Cancel
    Help, /Last_Message, Output = err_msg
    Print, 'Error--See history'
    ok=error_message('An unknown error occured and the window must be restarted. See console for details.',$
                     /noname, /center, title='Error in Load Data')
    if is_struct(state) then begin
      if obj_valid(state.historywin) then begin
        for j = 0, n_elements(err_msg)-1 do state.historywin->update,err_msg[j]
        if widget_valid(state.tab_id) then begin 
          spd_gui_error, state.tab_id, state.historywin
        endif
      endif
      Widget_Control, event.TOP, Set_UValue=state, /No_Copy
    endif
    widget_control, event.top, /destroy
    RETURN
  ENDIF

  ;kill request block
  IF (Tag_Names(event, /Structure_Name) EQ 'WIDGET_KILL_REQUEST') THEN BEGIN  
    exit_sequence:
    dprint,  'Load SPEDAS Data widget killed.' 
    state.historyWin->Update,'THM_UI_LOAD_DATA_FILE: Widget closed' 
    if obj_valid(state.loadList) then begin
      *state.treeCopyPtr = state.loadList->getCopy()
    endif 
    Widget_Control, event.TOP, Set_UValue=state, /No_Copy
    Widget_Control, event.top, /Destroy
    RETURN 
  ENDIF

  ; get the uval from this event so we know which widget was used 
  Widget_Control, event.id, Get_UValue=uval
  
  state.historywin->update,'THM_UI_LOAD_DATA_FILE: User value: '+uval  ,/dontshow

  CASE uval OF
    'ADD': BEGIN
      ; make sure valid times are set
      state.tr->getproperty, starttime=start_obj
      state.tr->getproperty, endtime=stop_obj
      start_obj->getProperty,tstring=startval
      stop_obj->getProperty,tstring=stopval
      startt=spd_ui_timefix(startval)
      stopt=spd_ui_timefix(stopval)
      ; temporarily change get_value func to get validity
      widget_control, state.timeid, get_value=valid, func_get_value='spd_ui_time_widget_is_valid'
      widget_control, state.timeid, func_get_value='spd_ui_time_widget_get_value'
      if is_string(startt) AND is_string(stopt) AND valid then begin
        ; make sure an observatory is selected - for gmag this is optional
        if ~array_equal(*state.observ, '', /no_typeconv) or (state.instr eq 'gmag') then begin
          widget_control, /hourglass
          suffix_txt = widget_info(event.top,find_by_uname='SUFFIXTEXT')
          WIDGET_CONTROL, suffix_txt, GET_VALUE=suffix
          state.suffix = suffix
          state.statusText->Update, 'Loading data...'
          thm_ui_load_data_file_load, state, event
        endif else begin
          if state.instr eq 'none' then begin
            h = 'No instrument selected.  Please select an instrument.'
          endif else begin
            h = 'No probe selected.  Please select one or more probes.'
          endelse
          
          state.statusText->Update, h
          state.historyWin->Update, 'THM_UI_LOAD_DATA_FILE: ' + h
        endelse
      endif else begin
        state.statusText->update, 'Invalid Start and/or Stop Time.  ' + $
                          'Please enter valid time before loading data.'
        break
      endelse
    END
    'CANC': BEGIN
       dprint,  'New File widget canceled' 
       state.historyWin->Update, 'THM_UI_LOAD_DATA_FILE: Widget closed.'
       if obj_valid(state.loadList) then begin
        *state.treeCopyPtr = state.loadList->getCopy()
       endif  
       Widget_Control, event.top, Set_UValue=state, /No_Copy
       Widget_Control, event.top, /Destroy
       RETURN
    END
    'CLEAR':BEGIN ; Clear all data (tplot vars)
      ; Should check whether there is any data first.
      val_data = state.loadeddata->getall();/times)
      if is_string(val_data[0]) then begin
        result = dialog_message("This will delete all data loaded into the GUI. Do you still want to proceed?", $
          /question, dialog_parent=state.tab_id, /default_no, /center)
        IF result EQ 'Yes' THEN BEGIN
          widget_control, /hourglass
          ;val_data = state.loadeddata->getall();/times)
          thm_ui_load_data_file_del, state
          state.callSequence->clearCalls
          h = 'All data deleted.'
          state.statusText->Update, h
          state.historyWin->Update, 'THM_UI_LOAD_DATA_FILE: ' + h
          state.loadedData->reset
          state.loadlist->update    ; update tree widget
        ENDIF
       endif
    END
    'CLEAR_DTYP':Begin
      if ptr_valid(state.dtyp1) then ptr_free, state.dtyp1
      if ptr_valid(state.dtyp2) then ptr_free, state.dtyp2
      if ptr_valid(state.dtyp) then ptr_free, state.dtyp
      widget_control, state.level1List, set_value=*state.dlist1
      widget_control, state.level2List, set_value=*state.dlist2
      h = 'No chosen data types'
      state.statusText->Update, h
    END
    'CLEAR_PRST':Begin
      If(state.instr Eq 'asi' Or state.instr Eq 'ask') Then Begin
        If(ptr_valid(state.astation)) Then ptr_free, state.astation
        h = 'No Chosen Asi_station'
        state.statusText->Update, h
      Endif Else If(state.instr Eq 'gmag') Then Begin
        If(ptr_valid(state.station)) Then ptr_free, state.station
        h = 'No Chosen Gmag_station'
        state.statusText->Update, h
      Endif Else Begin
        If(ptr_valid(state.probe)) Then ptr_free, state.probe      
        h = 'No Chosen Probe'
        state.statusText->Update, h
      Endelse
      widget_control,state.observlist, set_value=*state.validobservlist
    END
    'COORD_DLIST':BEGIN ; Output Coordinates dropdown list
      thm_ui_load_data_file_coord_sel, state    
    END
    'DELDATA':BEGIN ; Clear selected data (tplot vars)
      widget_control, /hourglass
      thm_ui_load_data_file_del, state
      state.loadlist->update
    END
    'ITYPE_DLIST':BEGIN ; Instrument Type dropdown list      
      thm_ui_load_data_file_itype_sel, state
      check_data_avail = widget_info(state.tab_id,find_by_uname='check_data_avail')
      if (state.instr eq 'gmag') then begin
        widget_control, check_data_avail, set_value=' Check GMAG names and data availability'
      endif else begin        
        widget_control, check_data_avail, set_value=' Check data availability'
      endelse    
    END
    'LEVEL1': BEGIN ; Level 1 data list
      thm_ui_load_data_file_l1_sel, state
    END
    'LEVEL2': BEGIN ; Level 2 data list
      thm_ui_load_data_file_l2_sel, state
    END
    'LOADLIST':BEGIN
      ;this isn't needed, this code spends a lot of time and effort maintain copies of lists already maintained by ui widgets
      ;thm_ui_load_data_file_loadlist, state, event
    END
    'OBSERV_LIST':BEGIN ; Observatory list (probes, ground stations, etc.)
      thm_ui_load_data_file_obs_sel, state
    END
    'CHECK_DATA_AVAIL': BEGIN ; launch browser to data availability page
      if (state.instr eq 'gmag') then begin
        spd_ui_open_url, 'http://themis.ssl.berkeley.edu/gmag/gmag_list.php?full=full'
      endif else begin
        spd_ui_open_url, 'http://themis.ssl.berkeley.edu/data_products/'
      endelse
    END
    ELSE:
  ENDCASE
  
  ; must ALWAYS reset the state value
  widget_control, base, set_uvalue=state, /NO_COPY

  RETURN
END

pro thm_ui_load_data_file, tab_id, loadedData, historyWin, statusText, $
                           treeCopyPtr, trObj, callSequence, $
                           loadTree=loadList, $
                           timeWidget=timeid
  
  compile_opt idl2, hidden
  
  widget_control, /hourglass

  ; initialize variables
  dtyp1='' & dtyp2='' & dtyp10='' & dtyp20='' & dtype='' & observ0='' & dtyp=''
  outCoord0=' DSL' ; default output coordinates
;  astation0 = '*' ; default all-sky station
;  station0 = '*' ; default ground mag station
;  probe0 = '*' ; default probe
  astation0 = '' ; default all-sky station
  station0 = '' ; default ground mag station
  probe0 = '' ; default probe
  probes = ['*', 'a', 'b', 'c', 'd', 'e', 'f']


  If(ptr_valid(dtyp)) Then ptr_free, dtyp
  dtyp = ptr_new(dtyp)
  If(ptr_valid(dtyp1)) Then ptr_free, dtyp1
  dtyp1 = ptr_new(dtyp1)
  If(ptr_valid(dtyp2)) Then ptr_free, dtyp2
  dtyp2 = ptr_new(dtyp2)
 
  
  observ_labels=['All-Sky Ground Station','GMAG Networks','Probes']
  observ_label=observ_labels[0]+':' ; default instrument label
;  instr_in0 = 'ASI' ; default data type
  instr_in0 = 'ASK' ; default data type
;  thm_load_asi, /valid_names, site=asi_stations
  thm_load_ask, /valid_names, site=asi_stations
  validobservlist = ['* (All)', asi_stations]
  validobserv = validobservlist
  validobserv = ptr_new(validobserv)
  observ = ptr_new(observ0) 

  instr=strlowcase(instr_in0)
  
  outCoord = strcompress(strlowcase(outCoord0),/remove_all)
  ;outCoord = 'N/A'

 ; Get valid datatypes, probes, etc for different data types  
  dlist = thm_ui_valid_datatype(instr, ilist, llist)
  dlist1_all = ['*', dlist]
  dlist2_all = 'None'
  dlist1 = ptr_new(dlist1_all) & dlist2 = ptr_new(dlist2_all)
  ;dlist1 = dlist1_all & dlist2 = dlist2_all
  
                   
  ; create base widgets
  topBase = Widget_Base(tab_id, /Row, /Align_Top,  tab_mode=1, /Align_Left, YPad=1, $
                        event_pro='thm_ui_load_data_file_event') 
  dataBase = Widget_Base(topBase, /Col, /Align_Left, YPad=1)
  data_label = Widget_Label(dataBase, Value='Data Selection:', /Align_Left)  
  dlistBase = Widget_Base(dataBase, /Col, XPad=2, Frame=3)     
      top1Base = Widget_Base(dlistBase, /Col)
          droplistBase = Widget_Base(top1Base, /Row)
              itypeBase = Widget_Base(droplistBase, /Row) ; instrument type dropdown list
              coordBase = Widget_Base(droplistBase, /Row) ; output coordinates dropdown list
          dbottomBase = Widget_Base(top1Base, /Col)
          observBase = Widget_Base(top1Base, /Row)
              observBase2 = Widget_Base(observBase, /Col)
                  o1Base = Widget_Base(observBase2, /Col)
                      o1ListBase = Widget_Base(o1Base, /Col)
              o2Base = Widget_Base(observBase, /Col)
                  levelBase = Widget_Base(o2Base, /Row)
                      llabelBase = Widget_Base(levelBase, /Row)
                      level1Base = Widget_Base(levelBase, /Col)
                      level2Base = Widget_Base(levelBase, /Col)
  
  ldBase = Widget_Base(topBase, /Col)
      toploadBase= Widget_Base(ldBase, /Row)
          addBase = Widget_Base(toploadBase, /Col, /Align_Left, YPad=175, XPad=5)
          loadBase = Widget_Base(toploadBase, /Col, /Align_Left, YPad=1)    
      bottomloadBase = Widget_Base(ldBase, /Row, YPad=2, /Align_Center)  

  validIType = [' ASK', ' ESA', ' EFI', ' FBK', ' FFT', ' FGM', $
                ' FIT ', ' GMAG', ' MOM', ' GMOM', ' SCM', ' SST', ' STATE']
                
  itypeDroplistLabel = Widget_Label(itypeBase, Value='Instrument Type:  ')
  itypeDroplist = Widget_ComboBox(itypeBase, Value=validIType, $ 
                                 uval='ITYPE_DLIST')
                                 
  widget_control, itypeDroplist, set_combobox_select=0 ; default selection is the first in the list (currently ASK)
  
  validProbes = [' * (All)', ' A (P5)', ' B (P1)', ' C (P2)', ' D (P3)', $
                 ' E (P4)', ' F (Flatsat)']
  
  observLabel = Widget_Label(o1ListBase, Value=observ_label, /align_left)
  observList = Widget_List(o1ListBase, Value=*validobserv, uval='OBSERV_LIST', $
                         /Multiple, xsize=25, ysize=16,/align_left)
  
  level1Label = Widget_Label(level1Base, Value='Level 1:', /align_left, uname="level1Label")
  level1List = Widget_List(level1Base, Value=*dlist1, /Multiple, xsize=27,ysize=16, $
                           Uvalue='LEVEL1')
  
  level2Label = Widget_Label(level2Base, Value='Level 2:', /align_left)
  level2List = Widget_List(level2Base, Value=*dlist2, /Multiple, xsize=24,ysize=16, $
                           Uvalue='LEVEL2')
                           
  validCoords = [ 'GSM','GSE', 'GEI', 'GEO', 'SM', 'DSL', 'SPG', 'SSL']
  ; make a list of valid coordinate systems 
;  coord_sys_obj = obj_new('thm_ui_coordinate_systems')
; validCoords = coord_sys_obj->makeCoordSysList(/uppercase)
;  obj_destroy, coord_sys_obj



  coordDroplistLabel = Widget_Label(coordBase, Value=' Output Coordinates:  ')
  coordDroplist = Widget_ComboBox(coordBase, Value=validCoords, $ ;XSize=165, $
                                  Sensitive=0, uval='COORD_DLIST')
                                  

                                 
  getresourcepath,rpath
  
  midRowBase = Widget_Base(dbottomBase, /row)
  
 ttextBase = Widget_Base(midRowBase, /Col, YPad=0)
 timeid = spd_ui_time_widget(ttextBase,$
                            statusText,$
                            historyWin,$
                            timeRangeObj=trObj,$
                            uvalue='TIME_WIDGET',$
                            uname='time_widget')
  
  midRowBase1 = Widget_Base(midRowBase, /col)                         
  midRowButtonBase = widget_base(midRowBase1,/col,ypad=2,space=2,/nonexclusive,/align_top)
  eclipse_button = widget_button(midRowButtonBase,val='Apply Eclipse Corrections', $
                    uname='eclipse',uvalue='ECLIPSE',sensitive=0, $
                    tooltip='Apply eclipse corrections to calibrated level 1 data')
  raw_button = widget_button(midRowButtonBase,val='Uncalibrated/Raw', $
                 uname='raw_data',uvalue='RAW_DATA',sensitive=0)
                 
  ;suffix               
  suffixBase = widget_base(midRowBase1,/row)
  suffix_label = Widget_Label(suffixBase, Value="GUI Suffix: ")
  suffix_txt = Widget_Text(suffixBase, Value="", /editable, uname='SUFFIXTEXT', scr_xsize=70)
  
  ;clear buttons
  clearbuts = Widget_Base(dbottomBase, /Row)
  clearbut1 = Widget_Button(observBase2, val = ' Clear Probe/Station ', $
                            uval = 'CLEAR_PRST', /align_center, $
                            ToolTip='Deselect all probes/stations')
  clearbut2 = Widget_Button(o2Base, val = ' Clear Data Type ', $
                            uval = 'CLEAR_DTYP', /align_center, $
                            ToolTip='Deselect all data types')

  davailabilitybutton = widget_button(dataBase, val = ' Check data availability', $
                                      uval = 'CHECK_DATA_AVAIL', /align_center, scr_xsize=250, $
                                      ToolTip = 'Check data availability on the web', uname='check_data_avail')
  rightArrow = read_bmp(rpath + 'arrow_000_medium.bmp', /rgb)
  trashcan = read_bmp(rpath + 'trashcan.bmp', /rgb)
  
  spd_ui_match_background, tab_id, rightArrow 
  spd_ui_match_background, tab_id, trashcan
  
  
  addButton = Widget_Button(addBase, Value=rightArrow, /Bitmap,  UValue='ADD', $
              ToolTip='Load data selection')
  minusButton = Widget_Button(addBase, Value=trashcan, /Bitmap, $
                Uvalue='DELDATA', $
                ToolTip='Delete data selected in the list of loaded data')

  ; ============== Setup loaded data list ======================================
  if obj_valid(loadedData) then begin
    val_data = loadedData->getall(/times)
    if array_equal(val_data,0,/no_typeconv) then val_data = 'None' $
      else begin
        ndata = n_elements(val_data[0,*])
        val_data_temp = strarr(ndata)
        ; would like to vectorize this but need loaded data to be vectorized.
        lastParent = ''
        for i=0, ndata-1 do begin
          ;child = loadedData->isChild(val_data[0,i])
          
          parent = loadedData->isParent(val_data[0,i])
          
          ;this logic is in-case parent and child have the same name
          if parent && val_data[0,i] ne lastParent then begin
            lastParent =val_data[0,i]
            val_data_temp[i] = val_data[0,i]+':    '+val_data[1,i]+' to '+val_data[2,i]
          endif else begin
            val_data_temp[i] = '  - '+val_data[0,i]+':    '+val_data[1,i]+' to '+val_data[2,i]
          endelse

        endfor
        val_data = val_data_temp
      endelse
  endif else val_data = 'None'

  loadLabel  = Widget_Label(loadBase, Value='Data Loaded: ', /Align_Left)
  loadList = Obj_New('spd_ui_widget_tree', loadBase, 'LOADLIST', loadedData, $
                     XSize=380, YSize=380, mode=0, /multi,/showdatetime)
                     
  loadList->update,from_copy=*treeCopyPtr

  ; ============== End setup loaded data list =================================


  clearButton = Widget_Button(bottomloadBase, Value='Delete All Data', UValue='CLEAR', $
    ToolTip='Deletes all loaded data')
    
  WIDGET_CONTROL, suffix_txt, GET_VALUE=suffix

  ;main structure for this panel (to be filled in as items are needed)
  state = {tab_id:topbase, $ ;TODO: spd_ui_load_data_file_itype_sel will 
                             ;      fail if this tag is renamed 
           itypeDroplist:itypeDroplist, observBase:observBase, $
           observ_label:observ_label, timeID:timeID, $
           observ_labels:observ_labels, observLabel:observLabel, observ:observ, $
           observList:observList, validobserv:validobserv, $
           validobservlist:ptr_new(validobservlist), validIType:validIType, $
           level1List:level1List, probe:ptr_new(probe0), probes:probes, $
           validProbes:validProbes, $
           station:ptr_new(station0), astation:ptr_new(astation0), $
           level2List:level2List, dlist1:dlist1, dlist2:dlist2, instr:instr, $
           dtyp10:dtyp10, dtyp20:dtyp20, dtyp1:dtyp1, dtyp2:dtyp2, dtype:dtype, $
           dtyp:dtyp, dtyp_pre:ptr_new(), $
           coordDroplist:coordDroplist, validCoords:ptr_new(validCoords), $
           outCoord:outCoord, tr:trObj, $
           addButton:addButton, minusButton:minusButton, loadlist:loadList, $
           loadedData:loadedData, historyWin:historyWin, $
           validData:ptr_new(val_data), $
           statusText:statusText, callSequence:callSequence, $
           treeCopyPtr:treeCopyPtr, suffix:suffix}


  Widget_Control, topbase, Set_UValue=state, /No_Copy

  ;widget will be centered and realized in caller procedure
  
  RETURN
END
