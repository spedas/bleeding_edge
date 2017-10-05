;+ 
;NAME:
;  fast_ui_load_data
;
;PURPOSE:
;  Generates the tab that loads fast data for the gui.
;
;
;HISTORY:
;$LastChangedBy: jimm $
;$LastChangedDate: 2016-10-24 12:13:12 -0700 (Mon, 24 Oct 2016) $
;$LastChangedRevision: 22190 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/fast/spedas_plugin/fast_ui_load_data.pro $
;
;--------------------------------------------------------------------------------

pro fast_ui_load_data_event,event

  compile_opt hidden,idl2

  common fast_ui_load_saved, pa, energy

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
      'INSTRUMENT': begin
        typelist = widget_info(event.handler,find_by_uname='typelist')
        widget_control,typelist,set_value=*state.typeArray[event.index],set_list_select=0
        paramList = widget_info(event.handler,find_by_uname='paramlist')
        widget_control,paramList,set_value=*(*state.paramArray[event.index])[0]
      end
      'TYPELIST': begin
        instrument = widget_info(event.handler,find_by_uname='instrument')
        text = widget_info(instrument,/combobox_gettext)
        idx = (where(text eq state.instrumentArray))[0]
        parameter = widget_info(event.handler,find_by_uname='paramlist')
        widget_control,parameter,set_value=*(*state.paramArray[idx])[event.index]
      end
      'CLEARPARAM': begin
        paramlist = widget_info(event.handler,find_by_uname='paramlist')
        widget_control,paramlist,set_list_select=-1
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
        instrument = widget_info(event.handler,find_by_uname='instrument')
        instrumentText = widget_info(instrument,/combobox_gettext)
        instrumentSelect = (where(instrumentText eq state.instrumentArray))[0]   
        type = widget_info(event.handler,find_by_uname='typelist')
        typeSelect = widget_info(type,/list_select)
        if typeSelect[0] eq -1 then begin
          state.statusBar->update,'You must select one type'
          state.historyWin->update,'FAST add attempted without selecting type'
          break
        endif
        typeText = (*state.typeArray[instrumentSelect])[typeSelect]
        parameter = widget_info(event.handler,find_by_uname='paramlist')
        paramSelect = widget_info(parameter,/list_select)
        if paramSelect[0] eq -1 then begin
          state.statusBar->update,'You must select at least one parameter'
          state.historyWin->update,'FAST add attempted without selecting parameter'
          break
        endif
        ;handle '*' type, if present, introduce all
        if in_set(0,paramSelect) then begin
          paramText = (*(*state.paramArray[instrumentSelect])[typeSelect])
        endif else begin
          paramText = (*(*state.paramArray[instrumentSelect])[typeSelect])[paramSelect]
        endelse
        ;CHeck time range
        timeRangeObj = state.timeRangeObj      
        timeRangeObj->getProperty,startTime=startTimeObj,endTime=endTimeObj
        startTimeObj->getProperty,tdouble=startTimeDouble,tstring=startTimeString
        endTimeObj->getProperty,tdouble=endTimeDouble,tstring=endTimeString
        if startTimeDouble ge endTimeDouble then begin
          state.statusBar->update,'Cannot add data unless end time is greater than start time.'
          state.historyWin->update,'FAST add attempted with start time greater than end time.'
          break
        endif
        ;Check pitch angle range
        If(state.pa[0] Lt 0.0) Then Begin
           state.statusBar->update,'Pitch angle minimum reset to 0 from negative value'
           state.historyWin->update, 'FAST ESA Pitch angle minimum reset to 0 from negative value'
           pa[0] = 0.0 & state.pa = pa
           widget_control, state.pa_min, set_value=0.0
        Endif
        If(state.pa[1] gt 360.0) Then Begin
           state.statusBar->update,'Pitch angle maximum reset to 360 from higher value'
           state.historyWin->update, 'FAST ESA Pitch angle maximum reset to 360 from higher value'
           pa[1] = 360.0 & state.pa = pa
           widget_control, state.pa_max, set_value=360.0
        Endif
        If(state.pa[1] Le state.pa[0]) Then Begin
           state.statusBar->update,'Pitch angle maximum Lt minimum, swapping'
           state.historyWin->update, 'FAST ESA Pitch angle maximum Lt minimum, swapping'
           pa = rotate(pa, 2) & state.pa = pa
           widget_control, state.pa_min, set_value=pa[0]
           widget_control, state.pa_max, set_value=pa[1]
        Endif
        ;Check energy range
        If(state.energy[0] Lt 0.0) Then Begin
           state.statusBar->update,'energy minimum reset to 0 from negative value'
           state.historyWin->update, 'FAST ESA energy minimum reset to 0 from negative value'
           energy[0] = 0.0 & state.energy = energy
           widget_control, state.energy_min, set_value=0.0
        Endif
        If(state.energy[1] gt 50000.0) Then Begin
           state.statusBar->update,'energy maximum reset to 50000 from higher value'
           state.historyWin->update, 'FAST ESA energy maximum reset to 50000 from higher value'
           energy[1] = 50000.0 & state.energy = energy
           widget_control, state.energy_max, set_value=50000.0
        Endif
        If(state.energy[1] Le state.energy[0]) Then Begin
           state.statusBar->update,'energy maximum Lt minimum, swapping'
           state.historyWin->update, 'FAST ESA energy maximum Lt minimum, swapping'
           energy = rotate(energy, 2) & state.energy = energy
           widget_control, state.energy_min, set_value=energy[0]
           widget_control, state.energy_max, set_value=energy[1]
        Endif

        widget_control, /hourglass
        loadStruc = { instrument:instrumentText  , $
                      datatype:typeText  , $
                      parameters:paramText, $
                      timeRange:[startTimeString, endTimeString],$
                      paRange:pa, energyRange:energy}   
        fast_ui_import_data, $
                                  loadStruc, $
                                  state.loadedData,$
                                  state.statusBar,$
                                  state.historyWin,$
                                  state.baseid,$
                                  overwrite_selections=overwrite_selections
        state.loadTree->update
        callSeqStruc = { type:'loadapidata', $
                         subtype:'fast_ui_import_data', $
                         loadStruc:loadStruc, $
                         overwrite_selections:overwrite_selections }
        state.callSequence->addSt, callSeqStruc
     end
;for ranges
      'PAMIN':Begin
         pa[0] = event.value
         state.pa = pa
      End
      'PAMAX':Begin
         pa[1] = event.value
         state.pa = pa
      End
      'EMIN':Begin
         energy[0] = event.value
         state.energy = energy
      End
      'EMAX':Begin
         energy[1] = event.value
         state.energy = energy
      End
      else:
    endcase
  endif
  Widget_Control, event.handler, Set_UValue=state, /No_Copy

  return
end

pro fast_ui_load_data,tabid,loadedData,historyWin,statusBar,treeCopyPtr,timeRangeObj,callSequence,loadTree=loadTree,timeWidget=timeWidget
  compile_opt idl2,hidden

  common fast_ui_load_saved, pa, energy

  ;load bitmap resources
  getresourcepath,rpath
  rightArrow = read_bmp(rpath + 'arrow_000_medium.bmp', /rgb)
  trashcan = read_bmp(rpath + 'trashcan.bmp', /rgb)
  
  spd_ui_match_background, tabid, rightArrow 
  spd_ui_match_background, tabid, trashcan
  
  topBase = Widget_Base(tabid, /Row, /Align_Top, /Align_Left, YPad=1,event_pro='fast_ui_load_data_event') 
  
  leftBase = widget_base(topBase,/col)
  middleBase = widget_base(topBase,/col,/align_center)
  rightBase = widget_base(topBase,/col)
  
  leftLabel = widget_label(leftBase,value='FAST Data Selection:',/align_left)
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
  
;data availability labels
  timeLabel = widget_label(selectionBase,value='FAST HR DCB data available from 1996-09-28 to 1998-10-09')
  timeLabel1 = widget_label(selectionBase,value='FAST ESA L2 data available from 1996-08-30 to 1998-01-01')
  
  timeWidget = spd_ui_time_widget(selectionBase,$
                                  statusBar,$
                                  historyWin,$
                                  timeRangeObj=timeRangeObj,$
                                  uvalue='TIME_WIDGET',$
                                  uname='time_widget',$
                                  startyear=1995)

  instrumentBase = widget_base(selectionBase,/row) 
  
  instrumentLabel = widget_label(instrumentBase,value='Instrument Type: ')
  
  instrumentArray = ['MAG', 'ESA']
  ninstruments = n_elements(instrumentArray)
  
  instrumentCombo = widget_combobox(instrumentBase,$
                                       value=instrumentArray,$
                                       uvalue='INSTRUMENT',$
                                       uname='instrument')
                                              
  typeArray = ptrarr(ninstruments)
  
  typeArray[0] = ptr_new(['HR_DCB'])
  typeArray[1] = ptr_new(['ESA_L2'])
                                     
  dataBase = widget_base(selectionBase,/row)
  typeBase = widget_base(dataBase,/col)
  typeLabel = widget_label(typeBase,value='Data Type: ')
  typeList = widget_list(typeBase,$
                          value=*typeArray[0],$
                          uname='typelist',$
                          uvalue='TYPELIST',$
                          xsize=16,$
                          ysize=15)
  
  widget_control,typeList,set_list_select=0
  
  mag_datatypes = ['DeltaB_DSC','DeltaB_GEI','DeltaB_SM','DeltaB_FAC','DeltaB_FAC_V','DeltaB_FAC_SP','B_GEI','DEL_MAG_FLAG','Torquer','Tweaker','MAG_QUAL_FLAG','B_DSC','B_SSC','Bharmonic_DSC','Spin_Freq','Spin_Phase','Orbit','pos_gei','vel_gei','B_model_gei','alt','lat','lng','ilat','ilng','mlt','flat','flng','B_foot_gei','sun_dir_gei','dip_orient_gei','Orbit_Value','Coupling_Matrix','Offsets','Spin_Axis','Spin_Phase_Delta']
  esa_datatypes = ['Ion_eflux_survey', 'Electron_eflux_survey', 'Ion_pad_survey', 'Electron_pad_survey', $
                   'Ion_eflux_burst', 'Electron_eflux_burst', 'Ion_pad_burst', 'Electron_pad_burst']
  paramArray = ptrarr(ninstruments)
  paramArray[0] = ptr_new(ptrarr(1))
  paramArray[1] = ptr_new(ptrarr(1))
  (*paramArray[0])[0] = ptr_new(['*',mag_datatypes])
  (*paramArray[1])[0] = ptr_new(['*',esa_datatypes])
                                                                
  paramBase = widget_base(dataBase,/col)
  paramLabel = widget_label(paramBase,value='Parameter(s):')
  paramList = widget_list(paramBase,$
                         value=*((*paramArray[0])[0]),$
                         /multiple,$
                         uname='paramlist',$
                         xsize=24,$
                         ysize=15)
                         

  clearTypeButton = widget_button(paramBase,value='Clear Parameter',uvalue='CLEARPARAM',ToolTip='Deselect all parameters types')
                                                           
  
;------------------------------------------------------------------------------
; Angle Range Limits, hacked from thm_ui_part_getspec_options
;------------------------------------------------------------------------------
  If(n_elements(pa) Ne 2) Then pa = [0,360]
        
  angle_range_label_base = widget_base(selectionBase, /row, /align_left)
  angle_range_base = widget_base(selectionBase, /col, /frame, ypad=8, xpad=5)

  angle_range_label = widget_label(angle_range_label_base, value='ESA Eflux Pitch Angle Range (min/max):')
  pa_range_base = widget_base(angle_range_base, /row, uname='pa_base')
  pa_min = spd_ui_spinner(pa_range_base, label='', value=pa[0], uvalue = 'PAMIN', $
                          tooltip = 'Minimum pitch angle used for energy distribution spectrograms.')
  pa_max = spd_ui_spinner(pa_range_base, label='', value=pa[1], uvalue = 'PAMAX',$
                          tooltip = 'Maximum pitch angle used for energy distribution spectrograms.')

;------------------------------------------------------------------------------
; Energy Range Limits
;------------------------------------------------------------------------------
  If(n_elements(energy) Ne 2) Then energy = [0,5.0e4]
  
  energy_range_label_base = widget_base(selectionBase, /row, xpad=0, ypad=0)
  energy_range_base = widget_base(selectionBase, /col, /frame, ypad=8, xpad=5 )
  energy_range_label = widget_label(energy_range_label_base, value='ESA PADist Energy Range (min/max):')
  energy_range_base2 = widget_base(energy_range_base, /row, uname='er_base2')
  energy_min = spd_ui_spinner(energy_range_base2, label='', value=energy[0], uvalue='EMIN', $
                              tooltip = 'Minimum energy used for ESA L2 Pitch Angle Distributions.', inc=100)
  energy_max = spd_ui_spinner(energy_range_base2, label='', value=energy[1], uvalue='EMAX', $
                              tooltip = 'Maximum energy used for ESA L2 Pitch Angle Distributions.', inc=100)

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
           paramArray:paramArray,$
           pa:pa, energy:energy, $
           pa_min:pa_min, pa_max:pa_max, $
           energy_min:energy_min, energy_max:energy_max}
           
           
  widget_control,topBase,set_uvalue=state
                                  
  return

end
