;+
; Name:
;     spd_ui_neutral_sheet_models
;
; Purpose:
;     Panel for producing magnetic neutral sheet models in SPEDAS
;
;
;
;
;$LastChangedBy: jwl $
;$LastChangedDate: 2022-03-04 11:48:01 -0800 (Fri, 04 Mar 2022) $
;$LastChangedRevision: 30648 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/spedas_gui/panels/spd_ui_neutral_sheet_models.pro $
;-
; Name:
;    spd_ui_neutral_sheet_models_add_option
;
; Purpose:
;    Wrapper for spd_ui_add_variable, opens a dialog to allow the user to select a tplot variable
;    and adds the users selection to the GUI loadedData object
;
function spd_ui_neutral_sheet_models_add_option, statePtr, windowtitle = windowtitle
  state=*statePtr
  var_to_add = spd_ui_add_variable(state.tlb,state.loadedData,state.guiTree,state.historywin,state.statusBar,treemode=0,windowtitle=windowtitle)

  if ~keyword_set(var_to_add[0]) then begin
    return, -1
  endif else begin
    ; get the tvar group name
    ret_tvars = state.loadedData->GetTvarData((*var_to_add[0]).groupName)
  endelse
  return, ptr_new(ret_tvars)
end

; Name:
;     spd_ui_neutral_sheet_models_error
;
; Purpose:
;    Sends errors in this panel to dprint, status bar and history window
;
pro spd_ui_neutral_sheet_models_error, state, error
  if ~undefined(error) && error ne '' then begin
    dprint, dlevel=1, error
    state.historyWin->update, error
    state.statusBar->update, error
  endif else begin
    dprint, dlevel=0, 'Problem in the neutral sheet models panel error procedure, no error provided.'
  endelse
end
; Name:
;    spd_ui_neutral_sheet_models_event
;
; Purpose:
;    Event handler for this panel
;
pro spd_ui_neutral_sheet_models_event, event
  compile_opt idl2, hidden

  Widget_Control, event.top, get_uvalue = ptrState
  state = *ptrState

  err_models_event = 0
  catch, err_models_event

  ; catch any errors thrown
  if err_models_event ne 0 then begin
    catch, /cancel
    help, /last_message, output = err_msg

    spd_ui_sbar_hwin_update, state, err_msg, /error, err_msgbox_title='Error in spd_ui_neutral_sheet_models.'

    widget_control, event.top,/destroy
    return
  endif

  ; handle kill requests
  if tag_names(event, /structure_name) eq 'WIDGET_KILL_REQUEST' then begin
    state.historyWin->Update, 'Neutral Sheet Models window closed'
    state.statusBar->Update, 'Neutral Sheet Models window closed'
    if obj_valid(state.neutralSheetSettings) then begin
      state.neutralSheetSettings->setProperty, pos_tvar = *state.positionVar, ns_model=state.modelName, $
        kp_index=state.kpIndex, magnetic_lat=state.magneticLat        
    endif
    if ptr_valid(ptrState) then ptr_free, ptrState
    Widget_Control, event.top, /destroy
    ; run the garbage collector if we're in IDL 6-7
    if double(!version.release) lt 8. then heap_gc
    return
  endif

  ; get the uvalue
  Widget_Control, event.id, get_uvalue=uval

  case uval of
    ; buttons for solar wind options
    'MODELNAME': begin
      state.modelName=event.str
      state.modelSelect=event.index
      state.neutralSheetSettings->SetProperty, ns_model=state.modelName
      state.historyWin->Update, 'Neutral Sheet Model updated'
      state.statusbar->Update, 'Neutral Sheet Model updated'
      if event.index NE 3 then sensitive=0 else sensitive=1
      widget_control, state.midBase, sensitive=sensitive
      widget_control, event.top, set_uvalue = ptr_new(state), /no_copy
      return
    end
    'KPINDEX': begin
      if is_numeric(event.value) && event.value GE 0 then begin
        state.kpIndex = event.value
        state.neutralSheetSettings->SetProperty, kp_index=state.kpIndex
        state.historyWin->Update, 'KP Index updated'
        state.statusbar->Update, 'KP Index updated'
        widget_control, event.top, set_uvalue = ptr_new(state), /no_copy
        return
      endif else begin
        spd_ui_neutral_sheet_models_error, state, 'KP Index must be numeric.'
        kp_id=widget_info(event.top, find_by_uname='kpindex')
        widget_control, kp_id, set_value=state.kpIndex
        return
      endelse
    end
    'MAGLAT': begin
      if is_numeric(event.value) && event.value GE -90 && event.value LE 90. then begin
        state.magneticLat = event.value
        state.neutralSheetSettings->SetProperty, magnetic_lat=state.magneticLat
        state.historyWin->Update, 'Magnetic Latitude updated'
        state.statusbar->Update, 'Magnetic Latitude updated'
        ; update the state structure in the tlb
        widget_control, event.top, set_uvalue = ptr_new(state), /no_copy
        return
      endif else begin
        spd_ui_neutral_sheet_models_error, state, 'Magnetic Latitude must be numeric (between -90 to 90).'
        mlt_id=widget_info(event.top, find_by_uname='maglat')
        widget_control, mlt_id, set_value=state.magneticLat
        return
      endelse
    end
    'ZNS': begin
      if event.select EQ 1 then state.outputzns=1 else state.outputzns=0
      ; update the state structure in the tlb
      widget_control, event.top, set_uvalue = ptr_new(state), /no_copy
      return
    end
    'DZ2NS': begin
      if event.select EQ 1 then state.outputdz2ns=1 else state.outputdz2ns=0
      ; update the state structure in the tlb
      widget_control, event.top, set_uvalue = ptr_new(state), /no_copy
      return
    end
    'SELECTPOSITION': begin
    
      ret_tvars = spd_ui_neutral_sheet_models_add_option(ptrState, windowtitle = 'Select a variable containing position data')

      if ~ptr_valid(ret_tvars) then begin
        return
      endif else begin
        pos_wid = widget_info(event.top, find_by_uname='selectposition')
        Widget_Control, pos_wid, set_value = *ret_tvars[0]

        ptr_free, state.positionVar
        state.positionVar = ret_tvars
        Widget_Control, event.top, set_uvalue = ptr_new(state), /no_copy
        return
      endelse

    end

    'GENNEUTRALSHEET': begin

      ; generate the neutral sheet
      if ptr_valid(state.positionVar) then begin
        model_errors = 0
        pos_input = *state.positionVar
        if (size(pos_input, /type) eq 2 && pos_input eq 0) || pos_input eq '' then begin
          spd_ui_neutral_sheet_models_error, state, 'Error, no GUI position variables selected.'
          return
        endif
        if state.outputzns EQ 0 && state.outputdz2ns EQ 0 then begin
          spd_ui_neutral_sheet_models_error, state, 'Error, no output type selected.'
          return
        endif
                  
        ; get the dlimits for checking the coordinates
        coord_sys = cotrans_get_coord(pos_input[0])

        ; convert to GSM if needed
        if strlowcase(coord_sys) ne 'gsm' then begin
          dprint, dlevel = 2, 'Coordinate system for input position not in GSM, transforming from ' + strupcase(coord_sys) + ' to GSM prior to calculating models'
          state.statusBar->update, 'Coordinate system for input position not in GSM, transforming from ' + strupcase(coord_sys) + ' to GSM prior to calculating models'
          state.historyWin->update, 'Coordinate system for input position not in GSM, transforming from ' + strupcase(coord_sys) + ' to GSM prior to calculating models'
          var_to_use = pos_input[0] + '_gsm'
          spd_cotrans, pos_input[0], var_to_use, out_coord = 'gsm'
        endif else var_to_use = pos_input[0]

        ; extract data
        get_data, var_to_use, data=pos_gsm, dlimits=pos_gsm_dl, limits=pos_gsm_l
        
        state.statusBar -> update, 'Generating the neutral sheet '+state.modelName+' model for: ' + string(var_to_use)
        state.historywin -> update, 'Generating the neutral sheet '+state.modelName+' model neutral sheet for: ' + string(var_to_use)         

        ; generate the neutral sheet model at the position in the tplot variable
        if state.outputzns then begin 
          neutral_sheet, pos_gsm.x, pos_gsm.y/6378., model=strlowcase(state.modelName), kp=state.kpIndex, $
            mlt=state.magneticLat, distance2NS=distance2NS
          data_att={coord_sys:'gsm', st_type:'zns_pos', units:'km', project:pos_gsm_dl.data_att.project, $
             observatory:pos_gsm_dl.data_att.observatory, instrument:'neutral_sheet'}
          zns_dl={spec:0, log:0, data_att:data_att, labels:'',ysubtitle:'[km]'}
          store_data, 'zns_'+strlowcase(state.modelName)+'_gsm', data={x:pos_gsm.x, y:distance2NS*6378.}, dlimits=zns_dl
        endif

       if state.outputdz2ns then begin
          neutral_sheet, pos_gsm.x, pos_gsm.y/6378., model=strlowcase(state.modelName), kp=state.kpIndex, $
            mlt=state.magneticLat, distance2NS=distance2NS, /sc2NS
          data_att={coord_sys:'gsm', st_type:'dz2ns_pos', units:'km', project:pos_gsm_dl.data_att.project, $
            observatory:pos_gsm_dl.data_att.observatory, instrument:'neutral_sheet'}
          dz2ns_dl={spec:0, log:0, data_att:data_att, labels:'',ysubtitle:'[km]'}
          store_data, 'dz2ns_'+strlowcase(state.modelName)+'_gsm', data={x:pos_gsm.x, y:distance2NS*6378.}, dlimits=dz2ns_dl          
        endif


        if tnames('zns_'+strlowcase(state.modelName)+'_gsm') ne '' then begin
          ; add the tplot variable to the loadedData object
          ret_loaded = state.loadedData->add('zns_'+strlowcase(state.modelName)+'_gsm')
          state.statusBar->update, 'Done calculating the z distance of the neutral_sheet_model using model '+state.modelName
          state.historyWin->update, 'Done calculating the z distance of the neutral_sheet_model using model '+state.modelName
        endif

        if tnames('dz2ns_'+strlowcase(state.modelName)+'_gsm') ne '' then begin
            ; add the tplot variable to the loadedData object
            ret_loaded = state.loadedData->add('dz2ns_'+strlowcase(state.modelName)+'_gsm')
            state.statusBar->update, 'Done calculating the z distance from '+var_to_use+' to the neutral sheet using model' + state.modelName
            state.historyWin->update, 'Done calculating the z distance from '+var_to_use+' to the neutral sheet using model' + state.modelName
        endif

      endif        
      return
    end
    'CLOSE': begin
      if obj_valid(state.neutralSheetSettings) then begin
        state.neutralSheetSettings->setProperty, pos_tvar = *state.positionVar, ns_model=state.modelName, $
          kp_index=state.kpIndex, magnetic_lat=state.magneticLat
      endif
      if ptr_valid(ptrState) then ptr_free, ptrState
      Widget_Control, event.top, /destroy
      return
    end
    'CLEAR': begin
      ; reset to defaults
      state.modelSelect = 0
      state.positionVar = ptr_new('')
      state.kpIndex=0
      state.magneticLat=0
      state.modelName='AEN'
      state.outputzns=0
      state.outputdz2ns=0
      
      info.neutralSheetSettings->SetProperty, pos_tvar=state.positionVar, ns_model=state.modelName, $
        kp_index=state.kpIndex, magnetic_lat=state.magneticLat
     
      ; update the displayed options
      mod_id = widget_info(event.top, find_by_uname='modelname')
      kp_id = widget_info(event.top, find_by_uname='kpindex')
      mlt_id = widget_info(event.top, find_by_uname='maglat')
      zns_id = widget_info(event.top, find_by_uname='zns')
      dz2ns_id = widget_info(event.top, find_by_uname='dz2ns')

      widget_control, (widget_info(tlb, find_by_uname='modelName')), set_combobox_select=state.modelSelect
      widget_control, (widget_info(tlb, find_by_uname='kpIndex')), set_value=state.kpIndex
      widget_control, (widget_info(tlb, find_by_uname='maglat')), set_value=state.magneticLat
      widget_control, (widget_info(tlb, find_by_uname='zns')), set_value=0
      widget_control, (widget_info(tlb, find_by_uname='dz2ns')), set_value=0
      
      ; update the state structure in the tlb
      widget_control, event.top, set_uvalue = ptr_new(state), /no_copy

      ; run the garbage collector
      if double(!version.release) lt 8.0d then heap_gc
    end
    'HELP': begin
      spd_ui_neutral_sheet_help, state
      return
    end
    else: begin
      dprint, dlevel = 0, 'Not implemented yet.'
      return
    end
  endcase
end


pro spd_ui_neutral_sheet_models, info

  catch, err_neutral_sheet_models

  ; catch any errors opening the panel
  if err_neutral_sheet_models ne 0 then begin
    catch, /cancel
    help, /last_message, output=err_msg
    dprint, dlevel = 1, err_msg
    err_msgbox = error_message('An unknown error occured while opening the neutral sheet models window. See the console for details', /noname, /center, title='Error in Neutral Sheet Models')

    spd_gui_error, info.master, info.historyWin
    return
  endif

  ; create the base widget for the neutral models panel
  tlb = Widget_Base(/Col, Title='Neutral Sheet Models', Group_Leader=info.master, $
    /Floating, /tlb_kill_request_events, tab_mode = 1, /modal)
  mainBase = Widget_Base(tlb, /col)
  bottomBase = Widget_Base(tlb, /col)

  getresourcepath, resource_path
  palettebmp = read_bmp(resource_path + 'color.bmp', /rgb)
  cal = read_bmp(resource_path + 'cal.bmp', /rgb)
  helpbmp = read_bmp(resource_path + 'question.bmp', /rgb)

  spd_ui_match_background, tlb, helpbmp
  spd_ui_match_background, tlb, palettebmp
  spd_ui_match_background, tlb, cal

  if obj_valid(info.neutralSheetSettings) then begin
    info.neutralSheetSettings->getProperty, pos_tvar=pos_tvar, ns_model=ns_model, $
      kp_index=kp_index, magnetic_lat=magnetic_lat
  endif

  if pos_tvar eq '' then begin
    pos_tvar = 'Select a position variable'
    pos_var = ''
  endif else pos_var = pos_tvar

  positionBase = Widget_Base(mainBase, row=2)
  inputLabel = Widget_Label(positionBase, value='Input: ')
  posSelectButton = Widget_Button(positionBase, value=pos_tvar,/dynamic_resize, uname='selectposition', uval='SELECTPOSITION', tooltip='Select a variable containing the input position')
  label_width = 55

  ;;;;;;;;;;;;;;;;;;;;; Model Name selection ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  modelNames = ['AEN', 'DEN', 'FAIRFIELD', 'LOPEZ', 'THEMIS', 'SM']
  model_select = 0
  modelBase = Widget_Base(mainBase, /row, title='Model Name', ypad=4)
  modelLabel = Widget_Label(modelBase, value='Model Name: ', /align_left)
  modelCombo = Widget_Combobox(modelBase, value=modelNames, uvalue='MODELNAME', uname='modelName')
;  widget_control, modelCombo, set_combobox_select=model_select
  
  if model_select NE 3 then sensitive=0 else sensitive =1
  midBase=Widget_Base(mainbase, /col, /frame, xpad=5, ypad=5, sensitive=sensitive)
  ;;;;;;;;;;;;;;;;;;;;; KP Index selection ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  titleBase=Widget_base(midBase, /row)
  titleLabel=Widget_Label(titleBase, value='Parameters:', /align_left)
  kpBase = Widget_Base(midBase, /row, title='KP Index')
  kpLabel = Widget_Label(kpBase, value='KP Index:               ', /align_left)
  kpSpinner = spd_ui_spinner(kpbase, increment=1, uvalue='KPINDEX', uname='kpindex', min_value=0)
  widget_control, kpSpinner, set_value=kp_Index

  ;;;;;;;;;;;;;;;;;;;;; Magnetic Lat selection ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  mltBase = Widget_Base(midBase, /row, title='Magnetic Latitude')
  mltLabel = Widget_Label(mltBase, value='Magnetic Latitude: ', /align_left)
  mltSpinner = spd_ui_spinner(mltbase, increment=1, uvalue='MAGLAT', uname='maglat', min_value=-90, max_value=90)
  widget_control, mltspinner, set_value=magnetic_lat

  tempbase=Widget_Base(mainbase, /col, ypad=5)
  outputBase=Widget_Base(mainbase, /col, /frame, xpad=5, ypad=5)
  outputLabel=Widget_Label(outputBase, value='Output: ', /align_left) 
  outbutBase=Widget_Base(outputbase, /col, /nonexclusive)
  outputzns=1
  outputdz2ns=0
  znsButton = Widget_Button(outbutBase, Value='  zNS', uval='ZNS', uname='zns', $
    tooltip='NS position along the zaxis at a specific x and y location, in gsm coordinates')
  dz2nsButton = Widget_Button(outbutBase, Value='  dz2NS', uval='DZ2NS', uname='dz2ns', $
    tooltip='Distance of position to neutral sheet along the z axis, in gsm coordinates')
  widget_control, znsButton, set_button=outputzns
     
  buttonBase = Widget_Base(bottomBase, /row, /align_center)
  generateButton = Widget_Button(buttonBase, value='Generate', uval='GENNEUTRALSHEET', tooltip='Generate the neutral sheet model')
  clearButton = Widget_Button(buttonBase, value='Clear', uval='CLEAR', tooltip='Clear the current options')
  closeButton = Widget_Button(buttonBase, value='Close', uval='CLOSE', tooltip='Close this window')
  help_button = Widget_Button(buttonBase, value='Help', uval='HELP', tooltip='Descriptions of neutral sheet models')
  
  statusBase = Widget_Base(tlb, /Row, /align_center)
  statusBar = Obj_New('SPD_UI_MESSAGE_BAR', statusBase, XSize=55, YSize=1)

;end

  ; state structure for this widget
  state = {tlb: tlb, $
    neutralSheetSettings: info.neutralSheetSettings, $
    gui_id: info.master, $
    guiTree: info.guiTree, $
    loadedData: info.loadedData, $
    historyWin: info.historyWin, $
    statusBar: statusBar, $
    modelName: ns_model, $
    modelSelect: model_select, $
    kpIndex: kp_index, $
    magneticLat: magnetic_lat, $
    prevmaglat:magnetic_lat, $
    prevkpindex:kp_index, $
    outputzns: outputzns, $
    outputdz2ns: outputdz2ns, $ 
    midBase: midBase, $
    positionVar: ptr_new(pos_var)}

  ptrState = ptr_new(state, /no_copy)
  Widget_Control, tlb, set_uvalue = ptrState, /no_copy
  centertlb, tlb
  Widget_Control, tlb, /realize
  XManager, 'spd_ui_neutral_sheet_models', tlb, /no_block
end
