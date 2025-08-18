;+ 
;NAME:
;  wind_ui_load_data
;
;PURPOSE:
;  Generates the tab that loads wind data for the gui.
;
;
;HISTORY:
;$LastChangedBy: egrimes $
;$LastChangedDate: 2015-04-15 15:14:31 -0700 (Wed, 15 Apr 2015) $
;$LastChangedRevision: 17332 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/wind/spedas_plugin/wind_ui_load_data.pro $
;
;--------------------------------------------------------------------------------
pro wind_ui_load_data_event,event

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
          state.historyWin->update,'WIND add attempted without selecting type'
          break
        endif
        
        typeText = (*state.typeArray[instrumentSelect])[typeSelect]
        
        parameter = widget_info(event.handler,find_by_uname='paramlist')
        paramSelect = widget_info(parameter,/list_select)
        
        if paramSelect[0] eq -1 then begin
          state.statusBar->update,'You must select at least one parameter'
          state.historyWin->update,'WIND add attempted without selecting parameter'
          break
        endif
        
        ;handle '*' type, if present, introduce all
        if in_set(0,paramSelect) then begin
          paramText = (*(*state.paramArray[instrumentSelect])[typeSelect])
        endif else begin
          paramText = (*(*state.paramArray[instrumentSelect])[typeSelect])[paramSelect]
        endelse
              
        timeRangeObj = state.timeRangeObj      
        timeRangeObj->getProperty,startTime=startTimeObj,endTime=endTimeObj
      
        startTimeObj->getProperty,tdouble=startTimeDouble,tstring=startTimeString
        endTimeObj->getProperty,tdouble=endTimeDouble,tstring=endTimeString
        
        if startTimeDouble ge endTimeDouble then begin
          state.statusBar->update,'Cannot add data unless end time is greater than start time.'
          state.historyWin->update,'WIND add attempted with start time greater than end time.'
          break
        endif
        
        widget_control, /hourglass

        loadStruc = { instrument:instrumentText  , $
                      datatype:typeText  , $
                      parameters:paramText, $
                      timeRange:[startTimeString, endTimeString] }   
        
        wind_ui_import_data, $
                                  loadStruc,$
                                  state.loadedData,$
                                  state.statusBar,$
                                  state.historyWin,$
                                  state.baseid,$
                                  overwrite_selections=overwrite_selections
                                  
      
      
        state.loadTree->update
        
        callSeqStruc = { type:'loadapidata', $
                         subtype:'wind_ui_import_data', $
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


pro wind_ui_load_data,tabid,loadedData,historyWin,statusBar,treeCopyPtr,timeRangeObj,callSequence,loadTree=loadTree,timeWidget=timeWidget
  compile_opt idl2,hidden
  
  ;load bitmap resources
  getresourcepath,rpath
  rightArrow = read_bmp(rpath + 'arrow_000_medium.bmp', /rgb)
  trashcan = read_bmp(rpath + 'trashcan.bmp', /rgb)
  
  spd_ui_match_background, tabid, rightArrow 
  spd_ui_match_background, tabid, trashcan
  
  topBase = Widget_Base(tabid, /Row, /Align_Top, /Align_Left, YPad=1,event_pro='wind_ui_load_data_event') 
  
  leftBase = widget_base(topBase,/col)
  middleBase = widget_base(topBase,/col,/align_center)
  rightBase = widget_base(topBase,/col)
  
  leftLabel = widget_label(leftBase,value='Wind Data Selection:',/align_left)
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
                                  uname='time_widget')
  
  instrumentBase = widget_base(selectionBase,/row) 
  
  instrumentLabel = widget_label(instrumentBase,value='Instrument Type: ')
  
  instrumentArray = ['or','mfi','swe','3dp']
  
  instrumentCombo = widget_combobox(instrumentBase,$
                                       value=instrumentArray,$
                                       uvalue='INSTRUMENT',$
                                       uname='instrument')
                                              
  typeArray = ptrarr(4)
  
  typeArray[0] = ptr_new(['pre','def'])
  typeArray[1] = ptr_new(['k0','h0'])
  typeArray[2] = ptr_new(['k0','h0','h1'])
  typeArray[3] = ptr_new(['k0','pm','elpd','elsp','sfpd','sfsp'])
                                     
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
  
  paramArray = ptrarr(4)
  paramArray[0] = ptr_new(ptrarr(2))
  paramArray[1] = ptr_new(ptrarr(2))
  paramArray[2] = ptr_new(ptrarr(3))
  paramArray[3] = ptr_new(ptrarr(6))
  
  ;'def_or_GSE_POS'
  ;'h0_mfi_B3GSE'
  ;'swe_THERMAL_SPD'
  ;'3dp_k0_ion_density'
  
  (*paramArray[0])[0] = ptr_new(['*','Time_PB5','GCI_POS','GCI_VEL','GSE_POS','GSE_VEL','GSM_POS','GSM_VEL','SUN_VECTOR','HEC_POS','HEC_VEL',$
                                 'CRN_EARTH','LONG_EARTH','LAT_EARTH','LONG_SPACE','LAT_SPACE'])
  (*paramArray[0])[1] = ptr_new(['*','Time_PB5','GCI_POS','GCI_VEL','GSE_POS','GSE_VEL','GSM_POS','GSM_VEL','SUN_VECTOR','HEC_POS','HEC_VEL',$
                                 'CRN_EARTH','LONG_EARTH','LAT_EARTH','LONG_SPACE','LAT_SPACE'])
  (*paramArray[1])[0] = ptr_new(['*','Time_PB5','MODE','N','BF1','RMS','BGSMc','BGSMa','BGSEc','BGSEa','DIST','PGSM','PGSE','DQF','Gap_Flag'])
  (*paramArray[1])[1] = ptr_new(['*','Time_PB5','NUM_PTS','BF1','BRMSF1','BGSM','BRMSGSM','BGSE','BRGSGSE','DIST',$
                                 'PGSM','PGSE','SGSM','SGSE','DB_SC','TILTANG','RANGE_I','RANGE_O','SPC_MODE','MAG_MODE',$
                                 'Time3_PB5','NUM3_PTS','B3F1','B3RMSF1','B3GSM','B3RMSGSM','B3GSE','B3RMSGSE','Time1_PB5',$
                                 'NUM1_PTS','B1F1','B1RMSF1','B1GSM','B1RMSGSM','B1GSE','B1RMSGSE','DIST1','P1GSM','P1GSE',$
                                 'S1GSM','S1GSE'])
  (*paramArray[2])[0] = ptr_new(['*','Delta_time','Time_PB5','GAP_FLAG','MODE','SC_pos_gse','SC_pos_GSM','SC_pos_R','DQF','QF_V','QD_Vth',$
                                 'QF_Np','QF_a/p','V_GSE','V_GSM','V_GSE_p','THERMAL_SPD','Np','Alpha_Percent'])
                                 
  (*paramArray[2])[1] = ptr_new(['*',['time_PB5','Te','Te_anisotropy','average_energy','pa_press_tensor','pa_dot_B',$
                                 'heat_flux_magn','heat_flux_el','heat_flux_az','Q_dot_B','sc_position','el_bulk_vel_magn',$
                                 'el_bulk_vel_el','el_bulk_vel_az','el_density','sc_pot','flag','major_fr_rec','major_fr_spin_number']])
                                 
  (*paramArray[2])[2] = ptr_new(['*','Proton_' + ['V','sigmaV','VX','sigmaVX','VY','sigmaVY','VZ','sigmaVZ','W',$
                                 'sigmaW','Wperp','sigmaWperp','Wpar','sigmaWpar'] + '_nonlin','swe_'+['EW','flowangle','NS','SigmaNS'] + '_flowangle',$
                                 'Alpha_'+ ['Np','sigmaNp','V','sigmaV','VX','sigmaVX','VY','sigmaVY','VZ','sigmaVZ','W','sigmaW','Na','sigmaNa'] + '_nonlin',$
                                 'ChisQ_DOF_nonlin','swe_Proton_' + ['V','VX','VY','VZ','W','Wperp','Wpar','Np'] + '_moment', $
                                 ['BX','BY','BZ','Ang_dev','dev','Xgse','Ygse','Zgse','Ygsm','Zgsm']])
                                 
  (*paramArray[3])[0] = ptr_new(['*','Time_PB5','DQ_Flag','PG_Flag','instr_mode','sc_position','sc_velocity','elect_flux','elect_density',$
                                 'elect_vel','elect_temp','elect_qdotb','ion_flux','ion_density','ion_vel','ion_temp'])
  (*paramArray[3])[1] = ptr_new(['*','TIME','SPIN','P_DENS','P_VELS','P_TENS','P_TEMP','A_DENS','A_VELS','A_TENS','A_TEMP',$
                                 'E_RANGE','VC','GAP','VALID'])
                                 
  (*paramArray[3])[2] = ptr_new(['*','TIME','ENERGY','PANGLE','INTEG_T','EDENS','TEMP',$
                                   'QP','QM','QT','REDF','VSW','MAGF'])
  (*paramArray[3])[3] = ptr_new(['*',['TIME','FLUX','ENERGY']])                        
  (*paramArray[3])[4] = ptr_new(['*',['TIME','ENERGY','PANGLE','INTEG_T','MAGF']])
  (*paramArray[3])[5] = ptr_new(['*',['TIME','FLUX','ENERGY']])
                                                                           
  paramBase = widget_base(dataBase,/col)
  paramLabel = widget_label(paramBase,value='Parameter(s):')
  paramList = widget_list(paramBase,$
                         value=*((*paramArray[0])[0]),$
                         /multiple,$
                         uname='paramlist',$
                         xsize=24,$
                         ysize=15)
                         
  clearTypeButton = widget_button(paramBase,value='Clear Parameter',uvalue='CLEARPARAM',ToolTip='Deselect all parameters types')
                                                             
  
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
