;+
; Name: 
;     spd_ui_field_models
; 
; Purpose:
;     Panel for producing magnetic field models in SPEDAS
;
;
;
;
;$LastChangedBy: jwl $
;$LastChangedDate: 2022-09-16 17:07:17 -0700 (Fri, 16 Sep 2022) $
;$LastChangedRevision: 31100 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/spedas_gui/panels/spd_ui_field_models.pro $
;-

; Name:
;    spd_ui_field_models_add_option
;    
; Purpose:
;    Wrapper for spd_ui_add_variable, opens a dialog to allow the user to select a tplot variable
;    and adds the users selection to the GUI loadedData object
;
function spd_ui_field_models_add_option, statePtr, windowtitle = windowtitle
    state = *statePtr
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
;    spd_ui_field_models_ret_modelname
;    
; Purpose:
;    Returns the model name based on the tab ID
;
function spd_ui_field_models_ret_modelname, cur_tab
    ; the tabs are currently: 
    ; 0 - TS04, 1 - T01, 2 - T96, 3 - T89, 4 - IGRF
    if cur_tab eq 0 then field_model = 'TA15B'
    if cur_tab eq 1 then field_model = 'TA15N'
    if cur_tab eq 2 then field_model = 'TA16'
    if cur_tab eq 3 then field_model = 'TS07'
    if cur_tab eq 4 then field_model = 'T04S'
    if cur_tab eq 5 then field_model = 'T01'
    if cur_tab eq 6 then field_model = 'T96'
    if cur_tab eq 7 then field_model = 'T89'
    if cur_tab eq 8 then field_model = 'IGRF'
    if undefined(field_model) then field_model = 'none'
    return, field_model
end 
; Name:
;     spd_ui_field_models_error
;    
; Purpose:
;    Sends errors in this panel to dprint, status bar and history window
;
pro spd_ui_field_models_error, state, error
    if ~undefined(error) && error ne '' then begin
        dprint, dlevel=1, error
        state.historyWin->update, error
        state.statusBar->update, error
    endif else begin
        dprint, dlevel=0, 'Problem in the field models panel error procedure, no error provided.'
    endelse
end
; Name:
;    spd_ui_field_models_check_params
;    
; Purpose:
;    Verifies the input parameters, returns a tplot variable containing 
;    the n x 10 param array required by the Tsyganenko models
;
function spd_ui_field_models_check_params, state, field_model
    newname = field_model + '_field_model'
    parameter_input = newname+'_parm'

; commenting out checking of the position variables dlimits.data_att.st_type
; until we can figure out a way to add st_type to generic ephemeris data 
; loaded via CDAWeb
; 
;    thesttype = ''
;    
;    ; check that the position variable contains the appropriate 
;    ; st_type tag in the dlimits.data_att struct
;    get_data, *state.tvars_to_trace[0], dlimits=pos_dlimits
;    if is_struct(pos_dlimits.data_att) then begin
;        str_element, pos_dlimits.data_att, 'st_type', thesttype
;        if thesttype ne 'pos' then begin
;            ; position tplot variable doesn't have the required 
;            ; dlimits.data_att.st_type
;            spd_ui_field_models_error, state, 'Input variable doesn''t appear to be a valid position variable. Check that the ''st_type'' string in the dlimits.data_att structure is set to ''pos''.'
;            return, -1
;        endif
;    endif else begin
;        spd_ui_field_models_error, state, 'Input variable doesn''t appear to be a valid position variable. Check that the dlimits structure contains the appropriate data_att structure.'
;        return, -1
;    endelse 
    
    ; check the user's input data
    if strlowcase(field_model) eq 't89' || strlowcase(field_model) eq 'igrf' then begin
        parameter_input = state.t89_iopt
    endif else if (strlowcase(field_model) eq 'ta15b')  then begin
     if (tnames(*state.usersPressure) eq '') and (tnames(*state.usersDensity) eq '') then begin
        spd_ui_field_models_error, state, 'No solar wind (proton) density data selected. Solar wind density data is required for the '+field_model+' model if pressure variable not supplied.'
        spd_ui_field_models_error, state, 'Use the load data panel to load OMNI data for the time interval you''re trying to model'
        return, -1
      endif
      if (tnames(*state.userspressure) eq '') and (tnames(*state.usersSpeed) eq '') then begin
        spd_ui_field_models_error, state, 'No solar wind (proton) speed data selected. Solar wind speed data is required for the '+field_model+' model if pressure variable not supplied'
        spd_ui_field_models_error, state, 'Use the load data panel to load OMNI data for the time interval you''re trying to model'
        return, -1
      endif
      if (tnames(*state.usersbindex) eq '') and (tnames(*state.usersSpeed) eq '') then begin
        spd_ui_field_models_error, state, 'No solar wind (proton) speed data selected. Solar wind speed data is required for the '+field_model+' model if B-index variable not supplied'
        spd_ui_field_models_error, state, 'Use the load data panel to load OMNI data for the time interval you''re trying to model'
        return, -1
      endif
      if (tnames(*state.usersbindex) eq '') and (tnames(*state.usersDensity) eq '') then begin
        spd_ui_field_models_error, state, 'No solar wind (proton) speed data selected. Solar wind density data is required for the '+field_model+' model if B-index variable not supplied'
        spd_ui_field_models_error, state, 'Use the load data panel to load OMNI data for the time interval you''re trying to model'
        return, -1
      endif
      if tnames(*state.usersIMFBy) eq '' then begin
        spd_ui_field_models_error, state, 'No IMF By data selected. Interplanetary magnetic field data is required for the '+field_model+' model'
        spd_ui_field_models_error, state, 'Use the load data panel to load OMNI data for the time interval you''re trying to model'
        return, -1
      endif
      if tnames(*state.usersIMFBz) eq '' then begin
        spd_ui_field_models_error, state, 'No IMF Bz data selected. Interplanetary magnetic field data is required for the '+field_model+' model'
        spd_ui_field_models_error, state, 'Use the load data panel to load OMNI data for the time interval you''re trying to model'
        return, -1
      endif
      ; combine the selected IMF By and IMF Bz variables
      store_data, 'temp_imf_data', data=[*state.usersIMFBy, *state.usersIMFBz]
      
      ; Get trange from the IMFBy variable -- not the position variable, which may be too short to adequately seed the B-index calculation
      get_data,*state.usersIMFBy,trange=trange

     get_ta15_params,imf_tvar='temp_imf_data',Np_tvar=*state.usersDensity,Vp_tvar=*state.usersSpeed,xind_tvar=*state.usersbindex,pressure_tvar=*state.userspressure,model=field_model,newname=parameter_input,/speed,/imf_yz,$
        trange = trange
    endif else if strlowcase(field_model) eq 'ta15n' then begin
      if (tnames(*state.usersPressure) eq '') and (tnames(*state.usersDensity) eq '') then begin
        spd_ui_field_models_error, state, 'No solar wind (proton) density data selected. Solar wind density data is required for the '+field_model+' model if pressure variable not supplied.'
        spd_ui_field_models_error, state, 'Use the load data panel to load OMNI data for the time interval you''re trying to model'
        return, -1
      endif
      if (tnames(*state.userspressure) eq '') and (tnames(*state.usersSpeed) eq '') then begin
        spd_ui_field_models_error, state, 'No solar wind (proton) speed data selected. Solar wind speed data is required for the '+field_model+' model if pressure variable not supplied'
        spd_ui_field_models_error, state, 'Use the load data panel to load OMNI data for the time interval you''re trying to model'
        return, -1
      endif
      if (tnames(*state.usersnindex) eq '') and (tnames(*state.usersSpeed) eq '') then begin
        spd_ui_field_models_error, state, 'No solar wind (proton) speed data selected. Solar wind speed data is required for the '+field_model+' model if N-index variable not supplied'
        spd_ui_field_models_error, state, 'Use the load data panel to load OMNI data for the time interval you''re trying to model'
        return, -1
      endif

      if tnames(*state.usersIMFBy) eq '' then begin
        spd_ui_field_models_error, state, 'No IMF By data selected. Interplanetary magnetic field data is required for the '+field_model+' model'
        spd_ui_field_models_error, state, 'Use the load data panel to load OMNI data for the time interval you''re trying to model'
        return, -1
      endif
      if tnames(*state.usersIMFBz) eq '' then begin
        spd_ui_field_models_error, state, 'No IMF Bz data selected. Interplanetary magnetic field data is required for the '+field_model+' model'
        spd_ui_field_models_error, state, 'Use the load data panel to load OMNI data for the time interval you''re trying to model'
        return, -1
      endif
      ; combine the selected IMF By and IMF Bz variables
      store_data, 'temp_imf_data', data=[*state.usersIMFBy, *state.usersIMFBz]
      
      ; Get trange from the IMFBy variable -- not the position variable, which may be too short to adequately seed the N-index calculation
      get_data,*state.usersIMFBy,trange=trange


      get_ta15_params,imf_tvar='temp_imf_data',Np_tvar=*state.usersDensity,Vp_tvar=*state.usersSpeed,xind_tvar=*state.usersnindex,pressure_tvar=*state.userspressure,model=field_model,newname=parameter_input,/speed,/imf_yz,$
        trange = trange
    endif else if strlowcase(field_model) eq 'ta16' then begin
      if (tnames(*state.usersPressure) eq '') and (tnames(*state.usersDensity) eq '') then begin
        spd_ui_field_models_error, state, 'No solar wind (proton) density data selected. Solar wind density data is required for the '+field_model+' model if pressure variable not supplied.'
        spd_ui_field_models_error, state, 'Use the load data panel to load OMNI data for the time interval you''re trying to model'
        return, -1
      endif
      if (tnames(*state.userspressure) eq '') and (tnames(*state.usersSpeed) eq '') then begin
        spd_ui_field_models_error, state, 'No solar wind (proton) speed data selected. Solar wind speed data is required for the '+field_model+' model if pressure variable not supplied'
        spd_ui_field_models_error, state, 'Use the load data panel to load OMNI data for the time interval you''re trying to model'
        return, -1
      endif
      if (tnames(*state.usersnindex) eq '') and (tnames(*state.usersSpeed) eq '') then begin
        spd_ui_field_models_error, state, 'No solar wind (proton) speed data selected. Solar wind speed data is required for the '+field_model+' model if N-index variable not supplied'
        spd_ui_field_models_error, state, 'Use the load data panel to load OMNI data for the time interval you''re trying to model'
        return, -1
      endif
      if (tnames(*state.usersSymHC) eq '') and (tnames(*state.usersSymH) eq '') then begin
        spd_ui_field_models_error, state, 'No SYM-H variable selected.  Raw SYM-H data is required for the '+field_model+' model if corrected SYM-Hc variable not supplied'
        spd_ui_field_models_error, state, 'Use the load data panel to load OMNI data for the time interval you''re trying to model'
        return, -1
      endif

      if tnames(*state.usersIMFBy) eq '' then begin
        spd_ui_field_models_error, state, 'No IMF By data selected. Interplanetary magnetic field data is required for the '+field_model+' model'
        spd_ui_field_models_error, state, 'Use the load data panel to load OMNI data for the time interval you''re trying to model'
        return, -1
      endif
      if tnames(*state.usersIMFBz) eq '' then begin
        spd_ui_field_models_error, state, 'No IMF Bz data selected. Interplanetary magnetic field data is required for the '+field_model+' model'
        spd_ui_field_models_error, state, 'Use the load data panel to load OMNI data for the time interval you''re trying to model'
        return, -1
      endif
      ; combine the selected IMF By and IMF Bz variables
      store_data, 'temp_imf_data', data=[*state.usersIMFBy, *state.usersIMFBz]

      ; Get trange from the IMFBy variable -- not the position variable, which may be too short to adequately seed the N-index calculation
      get_data,*state.usersIMFBy,trange=trange


      get_ta16_params,imf_tvar='temp_imf_data',Np_tvar=*state.usersDensity,Vp_tvar=*state.usersSpeed,xind_tvar=*state.usersnindex,pressure_tvar=*state.userspressure,model=field_model,newname=parameter_input,/speed,/imf_yz,$
        symh=*state.usersSymH, symc=*state.usersSymHC,trange = trange
   
    endif else if strlowcase(field_model) eq 'ts07' then begin
      ; check the variables selected by the user
       if tnames(*state.usersPressure) eq '' and tnames(*state.usersDensity) eq '' then begin
        spd_ui_field_models_error, state, 'No solar wind (proton) density data selected. Solar wind density data is required for the '+field_model+' model if a pressure variable is not selected.'
        spd_ui_field_models_error, state, 'Use the load data panel to load OMNI data for the time interval you''re trying to model'
        return, -1
        endif
        if tnames(*state.usersPressure) eq '' and tnames(*state.usersSpeed) eq '' then begin
          spd_ui_field_models_error, state, 'No solar wind (proton) speed data selected. Solar wind speed data is required for the '+field_model+' model if a pressure variable is not selected.'
          spd_ui_field_models_error, state, 'Use the load data panel to load OMNI data for the time interval you''re trying to model'
          return, -1
        endif
        get_ts07_params, Np_tvar=*state.usersDensity,Vp_tvar=*state.usersSpeed,pressure_tvar=*state.usersPressure,newname=parameter_input,/speed,$
          trange = (~undefined(trange) ? trange : 0)

      endif else begin
        ; check the variables selected by the user
        if tnames(*state.usersIMFBy) eq '' then begin
            spd_ui_field_models_error, state, 'No IMF By data selected. Interplanetary magnetic field data is required for the '+field_model+' model'
            spd_ui_field_models_error, state, 'Use the load data panel to load OMNI data for the time interval you''re trying to model'
            return, -1
        endif
        if tnames(*state.usersIMFBz) eq '' then begin
            spd_ui_field_models_error, state, 'No IMF Bz data selected. Interplanetary magnetic field data is required for the '+field_model+' model'
            spd_ui_field_models_error, state, 'Use the load data panel to load OMNI data for the time interval you''re trying to model'
            return, -1
        endif 
        if tnames(*state.usersDensity) eq '' then begin
            spd_ui_field_models_error, state, 'No solar wind (proton) density data selected. Solar wind density data is required for the '+field_model+' model'
            spd_ui_field_models_error, state, 'Use the load data panel to load OMNI data for the time interval you''re trying to model'
            return, -1
        endif
        if tnames(*state.usersSpeed) eq '' then begin
            spd_ui_field_models_error, state, 'No solar wind (proton) speed data selected. Solar wind speed data is required for the '+field_model+' model'
            spd_ui_field_models_error, state, 'Use the load data panel to load OMNI data for the time interval you''re trying to model'
            return, -1
        endif 
        if tnames(*state.usersDst) eq '' then begin
            spd_ui_field_models_error, state, 'No Dst data selected. Dst index data is required for the '+field_model+' model'
            spd_ui_field_models_error, state, 'Use the load data panel to load Dst data for the time interval you''re trying to model'
            return, -1
        endif
        if strlowcase(field_model) eq 't01' && *state.UsersGs ne '' then begin
            g_coeff_tvar = *state.UsersGs
        endif 
        
        if strlowcase(field_model) eq 't04s' && *state.UsersWs ne '' then begin
            w_coeff_tvar = *state.UsersWs
        endif
        if strlowcase(field_model) eq 'ts04' && *state.UsersWs07 ne '' then begin
          w_coeff_tvar = *state.UsersWs07
        endif
        ; get the time range from the IMF_By variable (not the position variable, which may be too short to adequately seed 
        ; the model parameters
        get_data, *state.usersIMFBy, trange = trange

        ; combine the selected IMF By and IMF Bz variables
        store_data, 'temp_imf_data', data=[*state.usersIMFBy, *state.usersIMFBz]

        get_tsy_params, *state.usersDst,'temp_imf_data',*state.usersDensity,*state.usersSpeed,field_model,newname=parameter_input,/speed,/imf_yz,$
            g_coefficients=(~undefined(g_coeff_tvar) ? g_coeff_tvar : 0), w_coefficients=(~undefined(w_coeff_tvar) ? w_coeff_tvar : 0), $
            pressure_tvar=(*state.userspressure), trange = trange
    endelse
    
    return, parameter_input
end
; Name: 
;     spd_ui_field_models_model_params
; 
; Purpose: 
;     Updates the 'Current model parameters' section of the panel
;
pro spd_ui_field_models_model_params, tlb, field_model
    ; find the widget ids for the labels
    wcoef_wid = widget_info(tlb, find_by_uname='Wsbase')
    imfby_wid = widget_info(tlb, find_by_uname='imfbybase')
    imfbz_wid = widget_info(tlb, find_by_uname='imfbzbase')
    swdensity_wid = widget_info(tlb, find_by_uname='swdensitybase')
    swvel_wid = widget_info(tlb, find_by_uname='swvelbase')
    dst_wid = widget_info(tlb, find_by_uname='dstbase')
    symh_wid = widget_info(tlb, find_by_uname='symhbase')
    symhc_wid = widget_info(tlb, find_by_uname='symhcbase')
    coeffs_wid = widget_info(tlb, find_by_uname='selectedw')
    pressure_wid = widget_info(tlb, find_by_uname='pressurebase')
    nindex_wid = widget_info(tlb, find_by_uname='nindexbase')
    bindex_wid = widget_info(tlb, find_by_uname='bindexbase')


    
    case strlowcase(field_model) of 
        't89': begin
            Widget_Control, wcoef_wid, sensitive = 0
            Widget_Control, imfby_wid, sensitive = 0
            Widget_Control, imfbz_wid, sensitive = 0
            Widget_Control, swdensity_wid, sensitive = 0
            Widget_Control, swvel_wid, sensitive = 0
            Widget_Control, dst_wid, sensitive = 0
            Widget_Control, symh_wid, sensitive = 0
            Widget_Control, symhc_wid, sensitive = 0
            Widget_Control, pressure_wid, sensitive = 0
            Widget_Control, bindex_wid, sensitive = 0
            Widget_Control, nindex_wid, sensitive = 0

        end
        't96': begin
            Widget_Control, wcoef_wid, sensitive = 0
            Widget_Control, imfby_wid, sensitive = 1
            Widget_Control, imfbz_wid, sensitive = 1
            Widget_Control, swdensity_wid, sensitive = 1
            Widget_Control, swvel_wid, sensitive = 1
            Widget_Control, dst_wid, sensitive = 1
            Widget_Control, symh_wid, sensitive = 0
            Widget_Control, symhc_wid, sensitive = 0
            Widget_Control, pressure_wid, sensitive = 1
            Widget_Control, bindex_wid, sensitive = 0
            Widget_Control, nindex_wid, sensitive = 0
            
        end
        't01': begin
            Widget_Control, tlb, get_uvalue = ptrState
            state = *ptrState
            wid_wlabel = widget_info(tlb, find_by_uname='selectedwlabel')
            Widget_Control, wid_wlabel, set_value='G coefficients: '
            Widget_Control, coeffs_wid, set_value=(*state.usersGs eq '' ? '[calculate automatically]' : *state.usersGs)
            Widget_Control, wcoef_wid, sensitive = 1
            Widget_Control, imfby_wid, sensitive = 1
            Widget_Control, imfbz_wid, sensitive = 1
            Widget_Control, swdensity_wid, sensitive = 1
            Widget_Control, swvel_wid, sensitive = 1
            Widget_Control, dst_wid, sensitive = 1
            Widget_Control, symh_wid, sensitive = 0
            Widget_Control, symhc_wid, sensitive = 0
            Widget_Control, pressure_wid, sensitive = 1
            Widget_Control, bindex_wid, sensitive = 0
            Widget_Control, nindex_wid, sensitive = 0

        end
        't04s': begin
            Widget_Control, tlb, get_uvalue = ptrState
            state = *ptrState
            wid_wlabel = widget_info(tlb, find_by_uname='selectedwlabel')
            Widget_Control, wid_wlabel, set_value='W coefficients: '
            Widget_Control, coeffs_wid, set_value=(*state.usersWs eq '' ? '[calculate automatically]' : *state.usersWs)
            Widget_Control, wcoef_wid, sensitive = 1
            Widget_Control, imfby_wid, sensitive = 1
            Widget_Control, imfbz_wid, sensitive = 1
            Widget_Control, swdensity_wid, sensitive = 1
            Widget_Control, swvel_wid, sensitive = 1
            Widget_Control, dst_wid, sensitive = 1
            Widget_Control, symh_wid, sensitive = 0
            Widget_Control, symhc_wid, sensitive = 0
            Widget_Control, pressure_wid, sensitive = 1
            Widget_Control, bindex_wid, sensitive = 0
            Widget_Control, nindex_wid, sensitive = 0

        end
        'ts07': begin
          Widget_Control, tlb, get_uvalue = ptrState
          state = *ptrState
          Widget_Control, wcoef_wid, sensitive = 0
          Widget_Control, imfby_wid, sensitive = 0
          Widget_Control, imfbz_wid, sensitive = 0
          Widget_Control, swdensity_wid, sensitive = 1
          Widget_Control, swvel_wid, sensitive = 1
          Widget_Control, dst_wid, sensitive = 0
          Widget_Control, symh_wid, sensitive = 0
          Widget_Control, symhc_wid, sensitive = 0
          Widget_Control, pressure_wid, sensitive = 1
          Widget_Control, bindex_wid, sensitive = 0
          Widget_Control, nindex_wid, sensitive = 0

        end
        'ta15b': begin
          Widget_Control, tlb, get_uvalue = ptrState
          state = *ptrState
          Widget_Control, wcoef_wid, sensitive = 0
          Widget_Control, imfby_wid, sensitive = 1
          Widget_Control, imfbz_wid, sensitive = 1
          Widget_Control, swdensity_wid, sensitive = 1
          Widget_Control, swvel_wid, sensitive = 1
          Widget_Control, dst_wid, sensitive = 0
          Widget_Control, symh_wid, sensitive = 0
          Widget_Control, symhc_wid, sensitive = 0
          Widget_Control, pressure_wid, sensitive = 1
          Widget_Control, bindex_wid, sensitive = 1
          Widget_Control, nindex_wid, sensitive = 0

        end

        'ta15n': begin
          Widget_Control, tlb, get_uvalue = ptrState
          state = *ptrState
          Widget_Control, wcoef_wid, sensitive = 0
          Widget_Control, imfby_wid, sensitive = 1
          Widget_Control, imfbz_wid, sensitive = 1
          Widget_Control, swdensity_wid, sensitive = 1
          Widget_Control, swvel_wid, sensitive = 1
          Widget_Control, dst_wid, sensitive = 0
          Widget_Control, symh_wid, sensitive = 0
          Widget_Control, symhc_wid, sensitive = 0
          Widget_Control, pressure_wid, sensitive = 1
          Widget_Control, bindex_wid, sensitive = 0
          Widget_Control, nindex_wid, sensitive = 1

        end

        'ta16': begin
          Widget_Control, tlb, get_uvalue = ptrState
          state = *ptrState
          Widget_Control, wcoef_wid, sensitive = 0
          Widget_Control, imfby_wid, sensitive = 1
          Widget_Control, imfbz_wid, sensitive = 1
          Widget_Control, swdensity_wid, sensitive = 1
          Widget_Control, swvel_wid, sensitive = 1
          Widget_Control, dst_wid, sensitive = 0
          Widget_Control, symh_wid, sensitive = 1
          Widget_Control, symhc_wid, sensitive = 1
          Widget_Control, pressure_wid, sensitive = 1
          Widget_Control, bindex_wid, sensitive = 0
          Widget_Control, nindex_wid, sensitive = 1

        end

        'igrf': begin
            Widget_Control, wcoef_wid, sensitive = 0
            Widget_Control, imfby_wid, sensitive = 0
            Widget_Control, imfbz_wid, sensitive = 0
            Widget_Control, swdensity_wid, sensitive = 0
            Widget_Control, swvel_wid, sensitive = 0
            Widget_Control, dst_wid, sensitive = 0
            Widget_Control, symh_wid, sensitive = 0
            Widget_Control, symhc_wid, sensitive = 0
            Widget_Control, pressure_wid, sensitive = 0
            Widget_Control, bindex_wid, sensitive = 0
            Widget_Control, nindex_wid, sensitive = 0
       end
    endcase
end

pro spd_ui_help_ts07
  GETRESOURCEPATH, path ; start at the resources folder
  ts07_info = path + PATH_SEP() + 'ts07_info.txt'
  if file_test(ts07_info, /READ) then begin
    xdisplayfile, ts07_info, done_button='CLOSE', height=50, /modal, title='TS07 model coefficient files'
  endif else begin

  endelse

end

; Name:
;    spd_ui_field_models_event
;    
; Purpose:
;    Event handler for this panel
;
pro spd_ui_field_models_event, event
    compile_opt idl2, hidden
    
    Widget_Control, event.top, get_uvalue = ptrState
    state = *ptrState
    
    err_models_event = 0
    catch, err_models_event
    
    ; catch any errors thrown
    if err_models_event ne 0 then begin
        catch, /cancel
        help, /last_message, output = err_msg
        
        spd_ui_sbar_hwin_update, state, err_msg, /error, err_msgbox_title='Error in spd_ui_field_models.'
        
        widget_control, event.top,/destroy
        return
    endif

    ; handle kill requests
    if tag_names(event, /structure_name) eq 'WIDGET_KILL_REQUEST' then begin
        state.historyWin->Update, 'Field Models window closed'
        state.statusBar->Update, 'Field Models window closed'
        if obj_valid(state.fieldModelSettings) then begin
            state.fieldModelSettings->setProperty, pos_tvar = *state.tvars_to_trace, output_options = state.model_types, $
                imf_by_tvar = *state.usersIMFBy, imf_bz_tvar = *state.usersIMFBz, sw_density_tvar = *state.usersDensity, sw_speed_tvar = *state.usersSpeed, $
                dst_tvar = *state.usersDst, symh_tvar=*state.usersSymH, symhc_tvar=*state.usersSymHC, w_coeff_tvar = *state.usersWs, g_coeff_tvar = *state.usersGs, t89_kp = state.t89_iopt, $
                t89_set_tilt = *state.userSetTilt, t89_add_tilt = *state.userAddTilt, t01_storm = state.t01_storm, $
                pressure_tvar=*state.userspressure, bindex_tvar=*state.usersbindex, nindex_tvar=*state.usersnindex, geopack_2008=state.geopack_2008
        endif
        if ptr_valid(ptrState) then ptr_free, ptrState
        Widget_Control, event.top, /destroy
        ; run the garbage collector if we're in IDL 6-7
        if double(!version.release) lt 8. then heap_gc
        return
    endif
    
    ; handle tab events
    if (tag_names(event, /Structure_Name) eq 'WIDGET_TAB') then begin
        wid_curmodel = widget_info(event.top, find_by_uname='selectedmodel')
        tab_wid = widget_info(event.top, find_by_uname='currenttab')
        cur_tab = widget_info(tab_wid, /tab_current)
        
        ; determine the field model by the tab #
        field_model = spd_ui_field_models_ret_modelname(cur_tab)
        
        ; disable labels for any parameters not needed for this model
        spd_ui_field_models_model_params, event.top, field_model

        widget_control, wid_curmodel, set_value = field_model
        return
    endif 
    
    ; get the uvalue
    Widget_Control, event.id, get_uvalue=uval
    
    case uval of 
        ; buttons for solar wind options
        'PRESSURE': begin
          ret_pressure = spd_ui_field_models_add_option(ptrState, windowtitle = 'Select a variable containing solar wind pressure data')
          if ~ptr_valid(ret_pressure) then begin
            return
          endif else begin
            pos_wid = widget_info(event.top, find_by_uname='selectedpressure')
            Widget_Control, pos_wid, set_value = *ret_pressure[0]
            ptr_free, state.userspressure
            state.userspressure = ret_pressure
            Widget_Control, event.top, set_uvalue = ptr_new(state), /no_copy
            return
          endelse
        end

        'PROTONVELOCITY': begin
            ret_ionvel = spd_ui_field_models_add_option(ptrState, windowtitle = 'Select a variable containing solar wind speed data')
            if ~ptr_valid(ret_ionvel) then begin
                return
            endif else begin
                pos_wid = widget_info(event.top, find_by_uname='selectedswvel')
                Widget_Control, pos_wid, set_value = *ret_ionvel[0]
                ptr_free, state.usersSpeed
                state.usersSpeed = ret_ionvel
                Widget_Control, event.top, set_uvalue = ptr_new(state), /no_copy
                return
            endelse
        end
        'PROTONDENSITY': begin
            ret_iondens = spd_ui_field_models_add_option(ptrState, windowtitle = 'Select a variable containing solar wind density data')
            if ~ptr_valid(ret_iondens) then begin
                return
            endif else begin
                pos_wid = widget_info(event.top, find_by_uname='selectedswdens')
                Widget_Control, pos_wid, set_value = *ret_iondens[0]
                ptr_free, state.usersDensity
                state.usersDensity = ret_iondens
                Widget_Control, event.top, set_uvalue = ptr_new(state), /no_copy
                return
            endelse
        end
        'IMFBY': begin
            ret_imfb = spd_ui_field_models_add_option(ptrState, windowtitle = 'Select a variable containing IMF By data (in GSM coordinates)')
            if ~ptr_valid(ret_imfb) then begin
                return
            endif else begin
                pos_wid = widget_info(event.top, find_by_uname='selectedByimf')
                Widget_Control, pos_wid, set_value = *ret_imfb[0]
                ptr_free, state.usersIMFBy
                state.usersIMFBy = ret_imfb
                Widget_Control, event.top, set_uvalue = ptr_new(state), /no_copy
                return
            endelse
        end
        'IMFBZ': begin
            ret_imfb = spd_ui_field_models_add_option(ptrState, windowtitle = 'Select a variable containing IMF Bz data (in GSM coordinates)')
            if ~ptr_valid(ret_imfb) then begin
                return
            endif else begin
                pos_wid = widget_info(event.top, find_by_uname='selectedBzimf')
                Widget_Control, pos_wid, set_value = *ret_imfb[0]
                ptr_free, state.usersIMFBz
                state.usersIMFBz = ret_imfb
                Widget_Control, event.top, set_uvalue = ptr_new(state), /no_copy
                return
            endelse
        end
        ; buttons for magnetospheric options
        ; 
        'DST': begin
            ret_dst = spd_ui_field_models_add_option(ptrState, windowtitle = 'Select a variable containing Dst data')
            if ~ptr_valid(ret_dst) then begin
                return
            endif else begin
                pos_wid = widget_info(event.top, find_by_uname='selecteddst')
                Widget_Control, pos_wid, set_value = *ret_dst[0]
                ptr_free, state.usersDst
                state.usersDst = ret_dst
                Widget_Control, event.top, set_uvalue = ptr_new(state), /no_copy
                return
            endelse
        end
        'SYMH_INDEX': begin
          ret_symh = spd_ui_field_models_add_option(ptrState, windowtitle = 'Select a variable containing raw SYM-H data')
          if ~ptr_valid(ret_symh) then begin
            return
          endif else begin
            pos_wid = widget_info(event.top, find_by_uname='selectedsymh')
            Widget_Control, pos_wid, set_value = *ret_symh[0]
            ptr_free, state.usersSymH
            state.usersSymH = ret_symh
            Widget_Control, event.top, set_uvalue = ptr_new(state), /no_copy
            return
          endelse
        end

        'SYMHC_INDEX': begin
          ret_symh = spd_ui_field_models_add_option(ptrState, windowtitle = 'Select a variable containing corrected SYM-H data')
          if ~ptr_valid(ret_symhc) then begin
            return
          endif else begin
            pos_wid = widget_info(event.top, find_by_uname='selectedsymhc')
            Widget_Control, pos_wid, set_value = *ret_symhc[0]
            ptr_free, state.usersSymHC
            state.usersSymHC = ret_symhc
            Widget_Control, event.top, set_uvalue = ptr_new(state), /no_copy
            return
          endelse
        end

        'WCOEFF': begin
            ret_wcoeffs = spd_ui_field_models_add_option(ptrState, windowtitle = 'Select a variable containing the 6 W-coefficients')
            if ~ptr_valid(ret_wcoeffs) then begin
                return
            endif else begin
                pos_wid = widget_info(event.top, find_by_uname='selectedw')
                Widget_Control, pos_wid, set_value = *ret_wcoeffs[0]
                ptr_free, state.usersWs
                state.usersWs = ret_wcoeffs
                Widget_Control, event.top, set_uvalue = ptr_new(state), /no_copy
                return
            endelse
        end
        'B_INDEX': begin
          ret_bindex = spd_ui_field_models_add_option(ptrState, windowtitle = 'Select a variable containing the B-index')
          if ~ptr_valid(ret_bindex) then begin
            return
          endif else begin
            pos_wid = widget_info(event.top, find_by_uname='selectedbindex')
            Widget_Control, pos_wid, set_value = *ret_bindex[0]
            ptr_free, state.usersbindex
            state.usersbindex = ret_bindex
            Widget_Control, event.top, set_uvalue = ptr_new(state), /no_copy
            return
          endelse
        end
        'N_INDEX': begin
          ret_nindex = spd_ui_field_models_add_option(ptrState, windowtitle = 'Select a variable containing the N-index')
          if ~ptr_valid(ret_nindex) then begin
            return
          endif else begin
            pos_wid = widget_info(event.top, find_by_uname='selectednindex')
            Widget_Control, pos_wid, set_value = *ret_nindex[0]
            ptr_free, state.usersnindex
            state.usersnindex = ret_nindex
            Widget_Control, event.top, set_uvalue = ptr_new(state), /no_copy
            return
          endelse
        end

        'GCOEFF': begin
            ret_gcoeffs = spd_ui_field_models_add_option(ptrState, windowtitle = 'Select a variable containing the G-coefficients')
            if ~ptr_valid(ret_gcoeffs) then begin
                return
            endif else begin
                pos_wid = widget_info(event.top, find_by_uname='selectedw')
                Widget_Control, pos_wid, set_value = *ret_gcoeffs[0]
                ptr_free, state.usersGs
                state.usersGs = ret_gcoeffs
                Widget_Control, event.top, set_uvalue = ptr_new(state), /no_copy
                return
            endelse
        end
        ; model output buttons
        'MODEL_AT_POS': begin
            state.model_types = [state.model_types[0] ? 0b : 1b, state.model_types[1], state.model_types[2]]
            Widget_Control, event.top, set_uvalue = ptr_new(state)
        end
        'TRACE_EQUATOR': begin
            state.model_types = [state.model_types[0], state.model_types[1] ? 0b : 1b, state.model_types[2]]
            Widget_Control, event.top, set_uvalue = ptr_new(state)
        end
        'TRACE_IONOSPHERE': begin
            state.model_types = [state.model_types[0], state.model_types[1], state.model_types[2] ? 0b : 1b]
            Widget_Control, event.top, set_uvalue = ptr_new(state)
        end
        ;; end of model output buttons
        ; the user changed the iopt value
        'IOPTSELECTION': begin
            iopt_wid = widget_info(event.top, find_by_uname='ioptselection')
            iopt_selection = widget_info(iopt_wid, /droplist_select)
            state.t89_iopt = iopt_selection
            Widget_Control, event.top, set_uvalue=ptr_new(state), /no_copy
        end
        ; button for selecting the position GUI variable
        'SELECTPOSITION': begin
            ret_tvars = spd_ui_field_models_add_option(ptrState, windowtitle = 'Select a variable containing position data')

            if ~ptr_valid(ret_tvars) then begin
                return
            endif else begin
                pos_wid = widget_info(event.top, find_by_uname='selectposition')
                Widget_Control, pos_wid, set_value = *ret_tvars[0]
                
                ptr_free, state.tvars_to_trace
                state.tvars_to_trace = ret_tvars
                Widget_Control, event.top, set_uvalue = ptr_new(state), /no_copy
                return
            endelse
        
        end

        'GENMAGFIELD': begin
            ; check the user's settings
            model_types = state.model_types
            run_at_pos = model_types[0]
            trace_to_eq = model_types[1]
            trace_to_ion = model_types[2]
            
            ; make sure the user selected at least one output option
            if total(model_types) lt 1 then begin
                spd_ui_field_models_error, state, 'Cannot generate field model - no output options selected.'
                return
            endif
            
            ; find the current tab #
            tab_wid = widget_info(event.top, find_by_uname='currenttab')
            cur_tab = widget_info(tab_wid, /tab_current)

            ; determine the field model by the tab #
            field_model = spd_ui_field_models_ret_modelname(cur_tab)

            ; generate the fields
            if ptr_valid(state.tvars_to_trace) then begin
                model_errors = 0
                pos_input = *state.tvars_to_trace
                if (size(pos_input, /type) eq 2 && pos_input eq 0) || pos_input eq '' then begin
                    spd_ui_field_models_error, state, 'Error, no GUI position variables selected to model.'
                    return
                endif

                the_model_params = spd_ui_field_models_check_params(state, field_model)

                ; check for a problem in getting the model parameters
                if size(the_model_params, /type) ne 7 && the_model_params eq -1 then begin
                    spd_ui_field_models_error, state, 'Error generating the field model due to missing input parameters.'
                    return
                endif    
                
                ; get the dlimits for checking the coordinates
                coord_sys = cotrans_get_coord(pos_input[0])

                ; convert to GSM if needed
                if strlowcase(coord_sys) ne 'gsm' then begin
                    dprint, dlevel = 2, 'Coordinate system for input position not in GSM, transforming from ' + strupcase(coord_sys) + ' to GSM prior to calculating models'
                    state.statusBar->update, 'Coordinate system for input position not in GSM, transforming from ' + strupcase(coord_sys) + ' to GSM prior to calculating models'
                    state.historyWin->update, 'Coordinate system for input position not in GSM, transforming from ' + strupcase(coord_sys) + ' to GSM prior to calculating models'
                    var_to_map = pos_input[0] + '_gsm'
                    spd_cotrans, pos_input[0], var_to_map, out_coord = 'gsm'
                endif else var_to_map = pos_input[0]
 
                ; Get TS07 coefficient file and directory names if needed
                if strlowcase(field_model) eq 'ts07' then begin
                   paramfile = widget_info(event.top, find_by_uname='paramdir')
                   widget_control, paramfile, get_value = dirName
                   paramfile = widget_info(event.top, find_by_uname='paramfile')
                   widget_control, paramfile, get_value = fileName
                   
                   ; Call ts07_download here, to avoid repeated downloads if multiple modeling options are selected
                   ts07_download, local_dir=dirName[0]
                   GEOPACK_TS07_SETPATH, dirName[0]
                   GEOPACK_TS07_LOADCOEF, file_basename(fileName[0])

                endif
               
                state.statusBar -> update, 'Generating the ' + field_model + ' model field for: ' + string(var_to_map)
                state.historywin -> update, 'Generating the ' + field_model + ' model field for: ' + string(var_to_map)

                geopack_2008 = state.geopack_2008
                ; generate the magnetic field model at the position in the tplot variable
                if run_at_pos then begin
                    model_var = var_to_map+'_'+field_model+'_b'
                    
                    case strlowcase(field_model) of 
                        't89': begin
                            if *state.userSetTilt ne '' then begin
                                ; the user manually set the tilt angle
                                user_set_tilt = float(*state.userSetTilt)
                                tt89, var_to_map, newname=model_var[0], kp=state.t89_iopt, error=model_errors, set_tilt=user_set_tilt,geopack_2008=geopack_2008
                            endif else if *state.userAddTilt ne '' then begin
                                ; the user has an angle to be added to the model tilt
                                user_add_tilt = float(*state.userAddTilt)
                                tt89, var_to_map, newname=model_var[0], kp=state.t89_iopt, error=model_errors, add_tilt=user_add_tilt,geopack_2008=geopack_2008
                            endif else begin
                                ; no changes to the tilt angle
                                tt89, var_to_map, newname=model_var[0], kp=state.t89_iopt, error=model_errors,geopack_2008=geopack_2008
                            endelse
                        end
                        't96': begin
                            tt96, var_to_map, newname=model_var[0], parmod=the_model_params, error=model_errors,geopack_2008=geopack_2008
                        end
                        't01': begin
                            tt01, var_to_map, newname=model_var[0], parmod=the_model_params, error=model_errors, storm = state.t01_storm,geopack_2008=geopack_2008
                        end
                        't04s': begin
                            tt04s, var_to_map, newname=model_var[0], parmod=the_model_params, error=model_errors,geopack_2008=geopack_2008
                        end 
                        'ts07': begin                          
                           tts07, var_to_map, newname=model_var[0], parmod=the_model_params, error=model_errors, ts07_param_dir=dirName, ts07_param_file=fileName,geopack_2008=geopack_2008, /skip_ts07_load
                        end 
                        'ta15b': begin
                          tta15b, var_to_map, newname=model_var[0], parmod=the_model_params, error=model_errors,geopack_2008=geopack_2008
                        end
                        'ta15n': begin
                          tta15n, var_to_map, newname=model_var[0], parmod=the_model_params, error=model_errors,geopack_2008=geopack_2008
                        end
                        'ta16': begin
                          tta16, var_to_map, newname=model_var[0], parmod=the_model_params, error=model_errors,geopack_2008=geopack_2008
                        end
      
                        'igrf': begin
                            tt89, var_to_map, newname=model_var[0], /igrf_only, error=model_errors,geopack_2008=geopack_2008
                        end
                    endcase
                    if model_errors eq 0 then spd_ui_field_models_error, state, 'Unknown error calculating the magnetic field model'
                    
                    if tnames(model_var[0]) ne '' then begin
                        new_att = {coord_sys: 'gsm', st_type: 'none', units: 'nT'}
                        ; update the dlimits structure
                        options, model_var[0], 'data_att', new_att, /def
                        ; update the yaxis subtitle
                        options, model_var[0], 'ysubtitle', '[nT]', /def
                        options, model_var[0], labels=['Bx_gsm','By_gsm','Bz_gsm']
                        options, model_var[0], labflag=1
                        
                        ; add the tplot variable to the loadedData object
                        ret_loaded = state.loadedData->add(model_var[0])
                        state.statusBar->update, 'Done calculating the ' + field_model + ' model at ' + var_to_map 
                        state.historyWin->update, 'Done calculating the ' + field_model + ' model at ' + var_to_map 
                    endif
                endif

                ; trace the magnetic field to the equator
                if trace_to_eq then begin
                    state.statusBar -> update, 'Tracing from '+var_to_map+' to the equator (' + field_model + ')'
                    state.historyWin -> update, 'Tracing from '+var_to_map+' to the equator (' + field_model + ')'
                    eq_footprint = var_to_map+'_' + field_model + '_efoot'
                    ttrace2equator,var_to_map,trace_var_name=var_to_map+'_'+field_model+'_etrace', newname=eq_footprint,external_model=(field_model eq 'IGRF' ? 'none' : field_model), $
                        par=the_model_params,/km, error=trace_to_eq_error, storm = (strlowcase(field_model) eq 't01' ? state.t01_storm : 0), $
                        set_tilt = (~undefined(user_set_tilt) ? user_set_tilt : 0), add_tilt = (~undefined(user_add_tilt) ? user_add_tilt : 0), ts07_param_dir=dirName, ts07_param_file=fileName,geopack_2008=geopack_2008,/skip_ts07_load

                    ; add the newly created tplot variable (footprint) to the GUI variables
                    ; trace data is stored in tplot variables, but not loaded in the GUI
                    if tnames(eq_footprint) ne '' then begin
                        ret_loaded = state.loadedData->add(eq_footprint)
                        state.statusBar->update, 'Traced ' + var_to_map + ' to the equator (' + field_model + ')'
                        state.historyWin->update, 'Traced ' + var_to_map + ' to the equator (' + field_model + ')'
                    endif
                endif 
                ; trace the magnetic field to the ionosphere
                if trace_to_ion then begin
                    state.statusBar -> update, 'Tracing from ' + var_to_map + ' to the ionosphere (' + field_model + ')'
                    state.historyWin -> update, 'Tracing from ' + var_to_map + ' to the ionosphere (' + field_model + ')'
                    iono_footprint = var_to_map+'_' + field_model + '_ifoot'
                    ttrace2iono,var_to_map,trace_var_name = var_to_map+'_'+field_model+'_itrace', newname = iono_footprint,external_model=(field_model eq 'IGRF' ? 'none' : field_model), $
                        par=the_model_params,in_coord='gsm',out_coord='gsm',/km, storm = (strlowcase(field_model) eq 't01' ? state.t01_storm : 0), $
                        set_tilt = (~undefined(user_set_tilt) ? user_set_tilt : 0), add_tilt = (~undefined(user_add_tilt) ? user_add_tilt : 0), ts07_param_dir=dirName, ts07_param_file=fileName,geopack_2008=geopack_2008, /skip_ts07_load

                    ; add the newly created tplot variable (footprint) to the GUI variables
                    ; trace data is stored in tplot variables, but not loaded in the GUI
                    if tnames(iono_footprint) ne '' then begin
                        ret_loaded = state.loadedData->add(iono_footprint)
                        state.statusBar->update, 'Traced ' + var_to_map + ' to the ionosphere (' + field_model + ')'
                        state.historyWin->update, 'Traced ' + var_to_map + ' to the ionosphere (' + field_model + ')'
                    endif
                endif
            endif
            ; clean up params
            if tnames('temp_imf_data') ne '' then store_data, 'temp_imf_data', /delete
            return
        end 
        'HELPSETTILT': begin
            helptheuser = dialog_message('Use "Set tilt angle" to manually override the model tilt angle', /info)
        end
        'HELPADDTILT': begin
            helptheuser = dialog_message('Use "Add tilt angle" to add an additional angle to the model tilt angle. This option is ignored if you set the tilt angle manually.', /info)
        end
        'STORMBUTTON01': begin
            if state.t01_storm eq 0 then warn_about_using_this = dialog_message('The storm-time version of the T01 model is no longer maintained. Consider using the TS04 or TS07 model instead.', /info)
            state.t01_storm = state.t01_storm ? 0b : 1b
            Widget_Control, event.top, set_uvalue = ptr_new(state)
        end
        'USE_GEOPACK_2008': begin
          state.geopack_2008 = state.geopack_2008 ? 0b : 1b
          Widget_Control, event.top, set_uvalue = ptr_new(state)
        end
        'ADDTILTANGLE': begin
            addtilt_wid = widget_info(event.top, find_by_uname='addtiltangle')
            widget_control, addtilt_wid, get_value = tilt_to_add
            
            state.userAddTilt = ptr_new(tilt_to_add)
            Widget_Control, event.top, set_uvalue = ptr_new(state), /no_copy
        end
        'SETTILTANGLE': begin
            settilt_wid = widget_info(event.top, find_by_uname='settiltangle')
            widget_control, settilt_wid, get_value = tilt_to_set
            state.userSetTilt = ptr_new(tilt_to_set)
            Widget_Control, event.top, set_uvalue = ptr_new(state), /no_copy
        end
        'pdLabel': begin
          ; Select ts07 parameter directory
          dirName = Dialog_Pickfile(Title='Select TS07 parameters directory:', /directory, Filter='*.*', Path=!spedas.geopack_param_dir)
          paramdir = widget_info(event.top, find_by_uname='paramdir')
          widget_control, paramdir, set_value = dirName
        end
        'pfLabel': begin
          ; Select ts07 parameter file
          fileName = Dialog_Pickfile(Title='Select TS07 coefficients file:', Filter='*.*', Path=!spedas.geopack_param_dir)
          paramfile = widget_info(event.top, find_by_uname='paramfile')
          widget_control, paramfile, set_value = fileName
        end
        'ts07info': begin
            spd_ui_help_ts07
        end
        'CLOSE': begin
            if obj_valid(state.fieldModelSettings) then begin
                state.fieldModelSettings->setProperty, pos_tvar = *state.tvars_to_trace, output_options = state.model_types, $
                    imf_by_tvar = *state.usersIMFBy, imf_bz_tvar = *state.usersIMFBz, sw_density_tvar = *state.usersDensity, sw_speed_tvar = *state.usersSpeed, $
                    dst_tvar = *state.usersDst, symh_tvar=*state.usersSymH, symhc_tvar=*state.usersSymHC,w_coeff_tvar = *state.usersWs, g_coeff_tvar = *state.usersGs, t89_kp = state.t89_iopt, $
                    t89_set_tilt = *state.userSetTilt, t89_add_tilt = *state.userAddTilt, t01_storm = state.t01_storm, $
                    pressure_tvar=*state.userspressure, bindex_tvar=*state.usersbindex, nindex_tvar=*state.usersnindex, geopack_2008 = state.geopack_2008
            endif
            if ptr_valid(ptrState) then ptr_free, ptrState
            Widget_Control, event.top, /destroy
            return
        end
        'CLEAR': begin
            ; reset to defaults
            state.tvars_to_trace = ptr_new('')
            state.userSetTilt = ptr_new('')
            state.userAddTilt = ptr_new('')
            state.usersIMFBy = ptr_new('')
            state.usersIMFBz = ptr_new('')
            state.usersDensity = ptr_new('')
            state.usersSpeed = ptr_new('')
            state.usersDst = ptr_new('')
            state.usersSymH = ptr_new('')
            state.usersSymHC = ptr_new('')
            state.usersGs = ptr_new('')
            state.usersWs = ptr_new('')
            state.userspressure = ptr_new('')
            state.usersbindex = ptr_new('')
            state.usersnindex = ptr_new('')
            state.t01_storm = 0
            state.t89_iopt = 2
            
            ; update the displayed options
            sel_pos = widget_info(event.top, find_by_uname='selectposition')
            sel_By = widget_info(event.top, find_by_uname='selectedByimf')
            sel_Bz = widget_info(event.top, find_by_uname='selectedBzimf')
            sel_swdens = widget_info(event.top, find_by_uname='selectedswdens')
            sel_swvel = widget_info(event.top, find_by_uname='selectedswvel')
            sel_dst = widget_info(event.top, find_by_uname='selecteddst')
            sel_w = widget_info(event.top, find_by_uname='selectedw')
            sel_b = widget_info(event.top,find_by_uname='selectedbindex')
            sel_n = widget_info(event.top,find_by_uname='selectednindex')
            sel_pressure = widget_info(event.top,find_by_uname='selectedpressure')
            set_tilt_text = widget_info(event.top, find_by_uname='settiltangle')
            add_tilt_text = widget_info(event.top, find_by_uname='addtiltangle')
            iopt_droplist = widget_info(event.top, find_by_uname='ioptselection')
            t01_stormbutton = widget_info(event.top, find_by_uname='stormbutton01')
            
            widget_control, sel_pos, set_value='Select a position variable'
            widget_control, sel_By, set_value='[none]'
            widget_control, sel_Bz, set_value='[none]'
            widget_control, sel_swdens, set_value='[none]'
            widget_control, sel_swvel, set_value='[none]'
            widget_control, sel_dst, set_value='[none]'
            widget_control, sel_w, set_value='[calculate automatically]                      '
            widget_control, sel_n, set_value='[calculate automatically]                      '
            widget_control, sel_b, set_value='[calculate automatically]                      '
            widget_control, sel_pressure, set_value='[calculate automatically]               '

            widget_control, set_tilt_text, set_value = ''
            widget_control, add_tilt_text, set_value = ''
            widget_control, iopt_droplist, set_droplist_select=2
            widget_control, t01_stormbutton, set_button = 0
            
            ; update the state structure in the tlb
            widget_control, event.top, set_uvalue = ptr_new(state), /no_copy
            
            ; run the garbage collector
            if double(!version.release) lt 8.0d then heap_gc
        end
        else: begin
            dprint, dlevel = 0, 'Not implemented yet.' 
            return
        end
    endcase
end

             
pro spd_ui_field_models, info
    catch, err_field_models
    
    ; catch any errors opening the panel
    if err_field_models ne 0 then begin
        catch, /cancel
        help, /last_message, output=err_msg
        dprint, dlevel = 1, err_msg
        err_msgbox = error_message('An unknown error occured while opening the field models window. See the console for details', /noname, /center, title='Error in Field Models')

        spd_gui_error, info.master, info.historyWin
        return
    endif
    
    ; check that the GEOPACK DLM is loaded
    help, /dlm, output=dlm_output
    if strfilter(dlm_output, '*geopack*') eq '' then begin
        spd_ui_field_models_error, info, 'Error, Geopack DLM not found. Download and install it from http://ampere.jhuapl.edu/code/idl_geopack.html'
        return
    endif

    ; create the base widget for the field models panel
    spd_get_scroll_sizes,xfrac=0.35, yfrac=0.8,scroll_needed=scroll_needed,x_scroll_size=x_scroll_size,y_scroll_size=y_scroll_size
    if (scroll_needed) then begin
       tlb = Widget_Base(/Col, Title='Magnetic Field Models', Group_Leader=info.master, $
           /Floating, /tlb_kill_request_events, tab_mode = 1,/scroll,x_scroll_size=x_scroll_size,y_scroll_size=y_scroll_size)
    endif else begin
       tlb = Widget_Base(/Col, Title='Magnetic Field Models', Group_Leader=info.master, $
           /Floating, /tlb_kill_request_events, tab_mode = 1)
    endelse
    mainBase = Widget_Base(tlb, /col)
    tabBase = Widget_Tab(tlb, location=0, multiline=10, uname='currenttab')
    bottomBase = Widget_Base(tlb, /col)
    
    getresourcepath, resource_path
    palettebmp = read_bmp(resource_path + 'color.bmp', /rgb)
    cal = read_bmp(resource_path + 'cal.bmp', /rgb)
    helpbmp = read_bmp(resource_path + 'question.bmp', /rgb)
    
    spd_ui_match_background, tlb, helpbmp
    spd_ui_match_background, tlb, palettebmp
    spd_ui_match_background, tlb, cal
    
    if obj_valid(info.fieldModelSettings) then begin
        info.fieldModelSettings->getProperty, pos_tvar=pos_tvar, imf_by_tvar=imf_by_tvar, imf_bz_tvar=imf_bz_tvar, $
            sw_density_tvar=sw_density_tvar, sw_speed_tvar=sw_speed_tvar, dst_tvar=dst_tvar, symh_tvar=symh_tvar, symhc_tvar=symhc_tvar, w_coeff_tvar=w_coeff_tvar, $
            g_coeff_tvar=g_coeff_tvar, t89_kp=t89_kp, t89_set_tilt=t89_set_tilt, t89_add_tilt=t89_add_tilt, output_options=output_options, $
            t01_storm = t01_storm, pressure_tvar=pressure_tvar, bindex_tvar=bindex_tvar, nindex_tvar=nindex_tvar, geopack_2008=geopack_2008
    endif
    
    if pos_tvar eq '' then begin
        pos_tvar = 'Select a position variable'
        var_to_trace = ''
    endif else var_to_trace = pos_tvar
    
    positionBase = Widget_Base(mainBase, row=2)
    inputLabel = Widget_Label(positionBase, value='Input: ')
    posSelectButton = Widget_Button(positionBase, value=pos_tvar, /dynamic_resize, uname='selectposition', uval='SELECTPOSITION', tooltip='Select a variable containing the input position') 
    label_width = 55
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ;;;;;;;;;;;;;;;;;;;;; TA15Btab ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ta15bbase = Widget_Base(tabBase, col=2, title='TA15B', tab_mode = 1, event_pro='spd_ui_field_models_event')
    swBase15b = Widget_Base(ta15bbase, /col)
    swLabel = Widget_Label(swBase15b, value='Solar wind parameters:', /align_center)
    pressureButton = Widget_Button(swBase15b, value='Dynamic pressure (optional)', uname='pressure', uval='PRESSURE', tooltip = 'Select a variable containing solar wind pressure data. If not set, pressure will be calculated by SPEDAS.')
    imfByButton = Widget_Button(swBase15b, value='IMF By (GSM)', uname='imfby', uval='IMFBY', tooltip = 'Select a variable containing IMF By data')
    imfBzButton = Widget_Button(swBase15b, value='IMF Bz (GSM)', uname='imfbz', uval='IMFBZ', tooltip = 'Select a variable containing IMF Bz data')
    protonDensityButton = Widget_Button(swBase15b, value='Proton density', uname='protondensity', uval='PROTONDENSITY', tooltip = 'Select a variable containing solar wind density data')
    protonVelocityButton = Widget_Button(swBase15b, value='Proton speed', uname='protonvelocity', uval='PROTONVELOCITY', tooltip = 'Select a variable containing solar wind speed data')
    magBase15b = Widget_Base(ta15bbase, /col)
    magnetoPLabel = Widget_Label(magBase15b, value='Magnetospheric parameters:', /align_center)
    b_indexButton = Widget_Button(magBase15b, value='B-index (optional)', uname='b_index', uval='B_INDEX', tooltip = 'Select a variable containing the B-index. If not set, the appropriate B-index will be calculated by SPEDAS.')
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ;;;;;;;;;;;;;;;;;;;;; TA15N tab ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ta15nbase = Widget_Base(tabBase, col=2, title='TA15N', tab_mode = 1, event_pro='spd_ui_field_models_event')
    swBase15n = Widget_Base(ta15nbase, /col)
    swLabel = Widget_Label(swBase15n, value='Solar wind parameters:', /align_center)
    pressureButton = Widget_Button(swBase15n, value='Dynamic pressure (optional)', uname='pressure', uval='PRESSURE', tooltip = 'Select a variable containing solar wind pressure data. If not set, pressure will be calculated by SPEDAS.')
    imfByButton = Widget_Button(swBase15n, value='IMF By (GSM)', uname='imfby', uval='IMFBY', tooltip = 'Select a variable containing IMF By data')
    imfBzButton = Widget_Button(swBase15n, value='IMF Bz (GSM)', uname='imfbz', uval='IMFBZ', tooltip = 'Select a variable containing IMF Bz data')
    protonDensityButton = Widget_Button(swBase15n, value='Proton density', uname='protondensity', uval='PROTONDENSITY', tooltip = 'Select a variable containing solar wind density data')
    protonVelocityButton = Widget_Button(swBase15n, value='Proton speed', uname='protonvelocity', uval='PROTONVELOCITY', tooltip = 'Select a variable containing solar wind speed data')
    magBase15n = Widget_Base(ta15nbase, /col)
    magnetoPLabel = Widget_Label(magBase15n, value='Magnetospheric parameters:', /align_center)
    n_indexButton = Widget_Button(magBase15n, value='N-index (optional)', uname='n_index', uval='N_INDEX', tooltip = 'Select a variable containing the N-index. If not set, the appropriate N-index will be calculated by SPEDAS.')

    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ;;;;;;;;;;;;;;;;;;;;; TA16 tab ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    enable_ta16 = ta16_supported() ? 1 : 0
    ta16base = Widget_Base(tabBase, col=2, title='TA16', tab_mode = 1, event_pro='spd_ui_field_models_event', sensitive = enable_ta16)
    swBase16 = Widget_Base(ta16base, /col)
    swLabel = Widget_Label(swBase16, value='Solar wind parameters:', /align_center)
    pressureButton = Widget_Button(swBase16, value='Dynamic pressure (optional)', uname='pressure', uval='PRESSURE', tooltip = 'Select a variable containing solar wind pressure data. If not set, pressure will be calculated by SPEDAS.')
    imfByButton = Widget_Button(swBase16, value='IMF By (GSM)', uname='imfby', uval='IMFBY', tooltip = 'Select a variable containing IMF By data')
    imfBzButton = Widget_Button(swBase16, value='IMF Bz (GSM)', uname='imfbz', uval='IMFBZ', tooltip = 'Select a variable containing IMF Bz data')
    protonDensityButton = Widget_Button(swBase16, value='Proton density', uname='protondensity', uval='PROTONDENSITY', tooltip = 'Select a variable containing solar wind density data')
    protonVelocityButton = Widget_Button(swBase16, value='Proton speed', uname='protonvelocity', uval='PROTONVELOCITY', tooltip = 'Select a variable containing solar wind speed data')
    magBase16 = Widget_Base(ta16base, /col)
    magnetoPLabel = Widget_Label(magBase16, value='Magnetospheric parameters:', /align_center)
    n_indexButton = Widget_Button(magBase16, value='N-index (optional)', uname='n_index', uval='N_INDEX', tooltip = 'Select a variable containing the N-index. If not set, the appropriate N-index will be calculated by SPEDAS.')
    symhcButton = Widget_Button(magBase16,value='Corrected SYM-H index (optional)',uname='symhc_index', uval='SYMHC_INDEX',tooltip = 'Select a variable containing the corrected SYM-H index.  If not set, the appropriate correction will be applied by SPEDAS to the given SYM-H data.') 
    symhButton = Widget_Button(magBase16,value='(Raw) SYM-H index', uname='symh_index', uval='SYMH_INDEX',tooltip = 'Select a variable containing the SYM-H index.')
    
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ;;;;;;;;;;;;;;;;;;;;; Tsyganenko 07 tab ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    t07base = Widget_Base(tabBase, col=2, title='TS07', tab_mode = 1, event_pro='spd_ui_field_models_event')
    swBase07 = Widget_Base(t07base, /col)
    swLabel = Widget_Label(swBase07, value='Solar wind parameters:', /align_center)
    pressureButton = Widget_Button(swBase07, value='Dynamic presure (optional)',uname='pressure',uval='PRESSURE',tooltip = 'Select a variable containing solar wind dynamic pressure data (optional)')
    protonDensityButton = Widget_Button(swBase07, value='Proton density', uname='protondensity', uval='PROTONDENSITY', tooltip = 'Select a variable containing solar wind density data (optional if pressure variable selected)')
    protonVelocityButton = Widget_Button(swBase07, value='Proton speed', uname='protonvelocity', uval='PROTONVELOCITY', tooltip = 'Select a variable containing solar wind speed data (optional if pressure variable selected)')

    pdLabel1 = Widget_Label(swBase07, value='Directory with TS07 parameter files:', /align_left)
    t07pdbase = Widget_Base(swBase07, col=2)
    paramdir = Widget_text(t07pdbase, uname='paramdir', uval='paramdir', value=!spedas.geopack_param_dir, /editable, /align_left,xsize=30, units=0)     
    pdLabel = Widget_Button(t07pdbase, uname='pdLabel', uval='pdLabel', value='Select')  
            
    pfLabel1 = Widget_Label(swBase07, value='TS07 coefficients file:', /align_left)
    t07pfbase = Widget_Base(swBase07, col=2)
    paramfile = Widget_text(t07pfbase, uname='paramfile', uval='paramfile', value='ts07_sample_dyncoef.par', /editable, /align_left, xsize=30, units=0)
    pfLabel = Widget_Button(t07pfbase, uname='pfLabel', uval='pfLabel', value='Select')    
    
    swLabel3 = Widget_Label(swBase07, value='', /align_left)
    pfLabel4 = Widget_Button(swBase07, uname='ts07info', uval='ts07info', value=' Information', /align_left)    
    
    ;;;;;;;;;;;;;;;;;;;;; Tsyganenko-Sitnov 04 tab ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    t04base = Widget_Base(tabBase, col=2, title='TS04', tab_mode = 1, event_pro='spd_ui_field_models_event')
    swBase04 = Widget_Base(t04base, /col)
    swLabel = Widget_Label(swBase04, value='Solar wind parameters:', /align_center)
    pressureButton = Widget_Button(swBase04, value='Dynamic pressure (optional)', uname='pressure', uval='PRESSURE', tooltip = 'Select a variable containing solar wind pressure data. If not set, pressure will be calculated by SPEDAS.')
    imfByButton = Widget_Button(swBase04, value='IMF By (GSM)', uname='imfby', uval='IMFBY', tooltip = 'Select a variable containing IMF By data')
    imfBzButton = Widget_Button(swBase04, value='IMF Bz (GSM)', uname='imfbz', uval='IMFBZ', tooltip = 'Select a variable containing IMF Bz data')
    protonDensityButton = Widget_Button(swBase04, value='Proton density', uname='protondensity', uval='PROTONDENSITY', tooltip = 'Select a variable containing solar wind density data')
    protonVelocityButton = Widget_Button(swBase04, value='Proton speed', uname='protonvelocity', uval='PROTONVELOCITY', tooltip = 'Select a variable containing solar wind speed data')
    magBase04 = Widget_Base(t04base, /col)
    magnetoPLabel = Widget_Label(magBase04, value='Magnetospheric parameters:', /align_center)
    DstButton = Widget_Button(magBase04, value='Dst', uname='dst', uval='DST', tooltip = 'Select a variable containing Dst data')
    WcoeffButton = Widget_Button(magBase04, value='W-coefficients (optional)', uname='wcoeff', uval='WCOEFF', tooltip = 'Select a variable containing the W-coefficients. If not set, the appropriate W coefficients will be calculated by Geopack')

    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ;;;;;;;;;;;;;;;;;;;;; Tsyganenko 01 tab ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    t01base = Widget_Base(tabBase, col=2, title='T01', tab_mode = 1, event_pro='spd_ui_field_models_event')
    swBase01 = Widget_Base(t01base, /col)
    swLabel = Widget_Label(swBase01, value='Solar wind parameters:', /align_center)
    pressureButton = Widget_Button(swBase01, value='Dynamic pressure (optional)', uname='pressure', uval='PRESSURE', tooltip = 'Select a variable containing solar wind pressure data. If not set, pressure will be calculated by SPEDAS.')
    imfByButton = Widget_Button(swBase01, value='IMF By (GSM)', uname='imfby', uval='IMFBY', tooltip = 'Select a variable containing IMF By data')
    imfBzButton = Widget_Button(swBase01, value='IMF Bz (GSM)', uname='imfbz', uval='IMFBZ', tooltip = 'Select a variable containing IMF Bz data')
    protonDensityButton = Widget_Button(swBase01, value='Proton density', uname='protondensity', uval='PROTONDENSITY', tooltip = 'Select a variable containing solar wind density data')
    protonVelocityButton = Widget_Button(swBase01, value='Proton speed', uname='protonvelocity', uval='PROTONVELOCITY', tooltip = 'Select a variable containing solar wind speed data')
    magBase01 = Widget_Base(t01base, /col)
    magnetoPLabel = Widget_Label(magBase01, value='Magnetospheric parameters:', /align_center)
    DstButton = Widget_Button(magBase01, value='Dst', uname='dst', uval='DST', tooltip = 'Select a variable containing Dst data')
    GcoeffButton = Widget_Button(magBase01, value='G-coefficients (optional)', uname='gcoeff', uval='GCOEFF', tooltip = 'Select a variable containing the G-coefficients. If not set, the appropriate G coefficients will be calculated by Geopack')
    storm01base = Widget_Base(magBase01, /nonexclusive)
    stormButton = Widget_Button(storm01base, value='During a geomagnetic storm?', uname='stormbutton01', uval='STORMBUTTON01', tooltip='Specify the storm-time version of the T01 model. This option is no longer maintained - consider using TS04 or TS07 for storm-time models.')
    widget_control, stormButton, set_button = t01_storm

    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ;;;;;;;;;;;;;;;;;;;;; Tsyganenko 96 tab ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    t96base = Widget_Base(tabBase, col=2, title='T96', tab_mode = 1, event_pro='spd_ui_field_models_event')
    swBase96 = Widget_Base(t96base, /col)
    swLabel = Widget_Label(swBase96, value='Solar wind parameters:', /align_center)
    pressureButton = Widget_Button(swBase96, value='Dynamic pressure (optional)', uname='pressure', uval='PRESSURE', tooltip = 'Select a variable containing solar wind pressure data. If not set, pressure will be calculated by SPEDAS.')
    imfByButton = Widget_Button(swBase96, value='IMF By (GSM)', uname='imfby', uval='IMFBY', tooltip = 'Select a variable containing IMF By data')
    imfBzButton = Widget_Button(swBase96, value='IMF Bz (GSM)', uname='imfbz', uval='IMFBZ', tooltip = 'Select a variable containing IMF Bz data')
    protonDensityButton = Widget_Button(swBase96, value='Proton density', uname='protondensity', uval='PROTONDENSITY', tooltip = 'Select a variable containing solar wind density data')
    protonVelocityButton = Widget_Button(swBase96, value='Proton speed', uname='protonvelocity', uval='PROTONVELOCITY', tooltip = 'Select a variable containing solar wind speed data')
    magBase96 = Widget_Base(t96base, /col)
    magnetoPLabel = Widget_Label(magBase96, value='Magnetospheric parameters:', /align_center)
    DstButton = Widget_Button(magBase96, value='Dst', uname='dst', uval='DST', tooltip = 'Select a variable containing Dst data')

    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ;;;;;;;;;;;;;;;;;;;;; Tsyganenko 89 tab ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    t89base = Widget_Base(tabBase, row=2, title='T89', tab_mode = 1, event_pro='spd_ui_field_models_event')
    
    iOptLabel = Widget_Label(t89Base, value='Kp: ')
    iOptDropDown = Widget_DropList(t89base, value=['0, 0+','1-, 1, 1+','2-, 2, 2+','3-, 3, 3+','4-, 4, 4+','5-, 5, 5+','>= 6-'], uname='ioptselection', uval='IOPTSELECTION', event_pro='spd_ui_field_models_event')
    widget_control, iOptDropDown, SET_DROPLIST_SELECT = t89_kp
    
    newt89base = Widget_Base(t89base, /col)
    tiltLabel = Widget_Label(newt89base, value='Tilt angle (optional): ', /align_left)

    tiltBase = Widget_Base(newt89base, row=2, /align_left)
    setTiltLabel = Widget_Label(tiltBase, value='Set: ')
    setTiltText = Widget_Text(tiltBase, uname='settiltangle', uval='SETTILTANGLE', value=t89_set_tilt, /editable, /all_events)
    setTiltLabel = Widget_Label(tiltBase, value='deg')
    helpsettilt = Widget_Button(tiltBase, value=helpbmp, /bitmap, uname='helpsettilt', uval='HELPSETTILT')
    addTiltLabel = Widget_Label(tiltBase, value='Add: ')
    addTiltText = Widget_Text(tiltBase, uname='addtiltangle', uval='ADDTILTANGLE', value=t89_add_tilt, /editable, /all_events)
    setTiltLabel = Widget_Label(tiltBase, value='deg')
    helpaddtilt = Widget_Button(tiltBase, value=helpbmp, /bitmap, uname='helpaddtilt', uval='HELPADDTILT')
    
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ;;;;;;;;;;;;;;;;;;;;; IGRF tab ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    igrfbase = Widget_Base(tabBase, /row, title='IGRF', tab_mode = 1, event_pro='spd_ui_field_models_event')
    igrfLabel = Widget_Label(igrfbase, value='No additional input parameters required.')
    
    ; show the user their current selections
    modelinfoLabel = Widget_Label(bottomBase, value='Current model parameters:', /align_left)
    modelparamBase = Widget_Base(bottomBase, col=1)
    modelinfoBase = Widget_Base(modelparamBase, row=12, /align_left)
    colBaseModel = Widget_Base(modelinfoBase, col=2)
    modelLabel = Widget_Label(colBaseModel, value='Model: ', /align_left)
    selectedModelLabel = Widget_Label(colBaseModel, value='TA15B', /align_left, /dynamic_resize, uname='selectedmodel')
    colBasepressure = Widget_Base(modelinfoBase,  uname='pressurebase', row=1)
    pressureLabel = Widget_Label(colBasepressure, value='Dynamic pressure: ', /align_left)
    selectedpressureLabel = Widget_Label(colBasepressure, value=(pressure_tvar eq '' ? '[calculate automatically]' : pressure_tvar), /align_left, /dynamic_resize, uname='selectedpressure')
    colBaseimfy = Widget_Base(modelinfoBase,  uname='imfbybase', row=1)
    
    imfyLabel = Widget_Label(colBaseimfy, value='IMF By: ', /align_left)
    selectedByIMFLabel = Widget_Label(colBaseimfy, value=(imf_by_tvar eq '' ? '[none]' : imf_by_tvar), /align_left, /dynamic_resize,uname='selectedByimf')
    colBaseimfz = Widget_Base(modelinfoBase, row=1, uname='imfbzbase')
    imfzLabel = Widget_Label(colBaseimfz, value='IMF Bz: ', /align_left)
    selectedBzIMFLabel = Widget_Label(colBaseimfz, value=(imf_bz_tvar eq '' ? '[none]' : imf_bz_tvar), /align_left,/dynamic_resize, uname='selectedBzimf')
    colBaseDensity = Widget_Base(modelinfoBase, row=1, uname='swdensitybase')
    swdensLabel = Widget_Label(colBaseDensity, value='SW density: ', /align_left)
    selecteddensLabel = Widget_Label(colBaseDensity, value=(sw_density_tvar eq '' ? '[none]' : sw_density_tvar), /align_left,/dynamic_resize, uname='selectedswdens')
    colBaseVelocity = Widget_Base(modelinfoBase, row=1, uname='swvelbase')
    swvelLabel = Widget_Label(colBaseVelocity, value='SW flow speed: ', /align_left)
    selswvelLabel = Widget_Label(colBaseVelocity, value=(sw_speed_tvar eq '' ? '[none]' : sw_speed_tvar), uname='selectedswvel', /align_left, /dynamic_resize)
    colBaseDst= Widget_Base(modelinfoBase, row=1, uname='dstbase')
    dstLabel = Widget_Label(colBaseDst, value='Dst: ', /align_left)
    seldstLabel = Widget_Label(colBaseDst, value=(dst_tvar eq '' ? '[none]' : dst_tvar), uname='selecteddst', /align_left,/dynamic_resize)
    colBaseSymH= Widget_Base(modelinfoBase, row=1, uname='symhbase')
    symhLabel = Widget_Label(colBaseSymH, value='SYM-H: ', /align_left)
    selsymhLabel = Widget_Label(colBaseSymH, value=(symh_tvar eq '' ? '[none]' : symh_tvar), uname='selectedsymh', /align_left,/dynamic_resize)
    colBaseSymHC= Widget_Base(modelinfoBase, row=1, uname='symhcbase')
    symhcLabel = Widget_Label(colBaseSymHC, value='SYM-HC: ', /align_left)
    selsymhcLabel = Widget_Label(colBaseSymHC, value=(symhc_tvar eq '' ? '[calculate automatically]' : symhc_tvar), uname='selectedsymhc', /align_left,/dynamic_resize)
    colBaseWs= Widget_Base(modelinfoBase, row=1, uname='Wsbase')
    WcoeffLabel = Widget_Label(colBaseWs, value='W coefficients: ', /align_left, uname='selectedwlabel')
    selWLabel = Widget_Label(colBaseWs, value=(w_coeff_tvar eq '' ? '[calculate automatically]' : w_coeff_tvar), uname='selectedw', /align_left, /dynamic_resize)
    colBasebindex= Widget_Base(modelinfoBase, row=1, uname='bindexbase')
    bindexLabel = Widget_Label(colBasebindex, value='B-index: ', /align_left, uname='selectedblabel')
    selbindexLabel = Widget_Label(colBasebindex, value=(bindex_tvar eq '' ? '[calculate automatically]' : bindex_tvar), uname='selectedbindex', /align_left, /dynamic_resize)
    colBasenindex= Widget_Base(modelinfoBase, row=1, uname='nindexbase')
    nindexLabel = Widget_Label(colBasenindex, value='N-index: ', /align_left, uname='selectednlabel')
    selnindexLabel = Widget_Label(colBasenindex, value=(nindex_tvar eq '' ? '[calculate automatically]' : nindex_tvar), uname='selectednindex', /align_left, /dynamic_resize)
    
    ; buttons for output options
    labelmodel = Widget_Label(bottomBase, value='Output:', /align_left)
    geopack_2008Base = Widget_Base(bottomBase, row=1, /nonexclusive)
    geopack_2008Button = Widget_Button(geopack_2008Base,value='Use GEOPACK_2008 routines', uname='use_geopack_2008', uval='USE_GEOPACK_2008',tooltip='Use GEOPACK 2008 routines for tilt calculations, modeling, and tracing',/align_center)
    widget_control, geopack_2008Button, set_button = geopack_2008

    modelTypeBase = Widget_Base(bottomBase, row=1, /nonexclusive)
    modelatPosition = Widget_Button(modelTypeBase, value='Model at position', uname = 'model_at_pos', uval='MODEL_AT_POS', tooltip='Calculates the model field at the input position')
    trace_equator = Widget_Button(modelTypeBase, value = 'Trace to equator', uname = 'trace_equator', uval='TRACE_EQUATOR', tooltip='Traces the field line from the position to the equator')
    trace_ionosphere = Widget_Button(modelTypeBase, value='Trace to ionosphere', uname = 'trace_ionosphere', uval = 'TRACE_IONOSPHERE', tooltip='Traces the field line from the position to the ionosphere in the northern hemisphere') 

    ; start with model at position selected
    widget_control, modelatPosition, set_button=output_options[0]
    widget_control, trace_equator, set_button=output_options[1]
    widget_control, trace_ionosphere, set_button=output_options[2]
    
    buttonBase = Widget_Base(bottomBase, /row, /align_center)
    generateButton = Widget_Button(buttonBase, value='Generate', uval='GENMAGFIELD', tooltip='Generate the magnetic field model')
    clearButton = Widget_Button(buttonBase, value='Clear', uval='CLEAR', tooltip='Clear the current options')
    closeButton = Widget_Button(buttonBase, value='Close', uval='CLOSE', tooltip='Close this window')
   
    statusBase = Widget_Base(tlb, /Row, /align_center)
    statusBar = Obj_New('SPD_UI_MESSAGE_BAR', statusBase, XSize=55, YSize=1) 

    ; state structure for this widget
    state = {tlb: tlb, $
             fieldModelSettings: info.fieldModelSettings, $
             gui_id: info.master, $
             guiTree: info.guiTree, $
             loadedData: info.loadedData, $
             historyWin: info.historyWin, $
             statusBar: statusBar, $
             ; pointers to the user's currently selected:
             userSetTilt: ptr_new(t89_set_tilt), $ ; allow the user to set the tilt angle
             userAddTilt: ptr_new(t89_add_tilt), $ ; allow the user to add to the model tilt angle
             usersIMFBy: ptr_new(imf_by_tvar), $ ; IMF By variable
             usersIMFBz: ptr_new(imf_bz_tvar), $ ; IMF Bz variable
             usersDensity: ptr_new(sw_density_tvar), $ ; solar wind density variable
             usersSpeed: ptr_new(sw_speed_tvar), $ ; solar wind speed variable
             usersDst: ptr_new(dst_tvar), $ ; Dst variable
             usersSymH: ptr_new(symh_tvar),$ ; Sym-H variable
             usersSymHC: ptr_new(symhc_tvar),$ ; Sym-HC variable
             userspressure: ptr_new(pressure_tvar), $ ; Solar wind pressure
             usersbindex: ptr_new(bindex_tvar), $ ; B-index, for TA15B
             usersnindex: ptr_new(nindex_tvar), $ ; N-index, for TA15n, TA16
             usersWs: ptr_new(w_coeff_tvar), $ ; W coefficients, for TS04
             usersGs: ptr_new(g_coeff_tvar), $ ; W coefficients, for TS04
             usersWs07: ptr_new(w_coeff_tvar07), $ ; W coefficients, for TS07
             t01_storm: t01_storm, $ ; allow the user to specify the storm-time version of T01
             t89_iopt: t89_kp, $ ; default to Kp corresponding to 2-,2,2+
             model_types: output_options, $ ; output; [model at position, equatorial footprint, ionospheric footprint]
             geopack_2008: geopack_2008, $ ; Use Geopack 2008 routines
             tvars_to_trace: ptr_new(var_to_trace)}
             
     
    ptrState = ptr_new(state, /no_copy)
    Widget_Control, tlb, set_uvalue = ptrState, /no_copy
    centertlb, tlb
    Widget_Control, tlb, /realize
    spd_ui_field_models_model_params, tlb, 'ta15b'
    ;keep windows in X11 from snaping back to
    ;center during tree widget events
    if !d.NAME eq 'X' then begin
      widget_control, tlb, xoffset=0, yoffset=0
    endif

    XManager, 'spd_ui_field_models', tlb, /no_block
end
