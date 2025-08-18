; The input "state" is the DATA MODULE state.
function eva_data_load_sitl, state
  compile_opt idl2

  catch, error_status
  if error_status ne 0 then begin
    catch, /cancel
    eva_error_message, error_status
    message, /reset
    return, 'No'
  endif

  clock = eva_tic('EVA_DATA_LOAD_STLM', /profiler)

  str_tspan = [state.start_time, state.end_time] ; string array

  ; stlm  = {$; SITL Manu
  ; input: 'socs', $ ; input type (default: 'soca'; or 'socs','stla')
  ; update: 1 } ; update input data everytime plotting STLM variables

  widget_control, widget_info(state.parent, find = 'eva_sitl'), get_value = state_sitl
  stlm = {input: state_sitl.pref.eva_stlm_input, update: state_sitl.pref.eva_stlm_update}

  ; Check pre-loaded variables.
  ; Avoid reloading if already exists.
  tn = tnames('mms_stlm_fomstr', ct)
  str_element, /add, stlm, 'update', (ct eq 0)

  ; Should use "execute" to reduce number of codes?
  if stlm.update then begin
    eva_sitl_load_soca, state, str_tspan ; generates 'mms_soca_fom'(data=['mms_soca_fomstr','mms_soca_zero'])

    case stlm.input of
      'soca': ; Already done above; Do nothing
      'socs': eva_sitl_load_socs, state, str_tspan ; generates 'mms_socs_fom'(data=['mms_socs_fomstr','mms_socs_zero'])
      'stla': eva_sitl_load_stla, state ; generates 'mms_stla_fom'(data=['mms_stla_fomstr','mms_stla_zero'])
      else: stop
    endcase
    r = tnames()
    ysubtitle = '(SITL)'

    ; 'mms_stlm_fomstr'
    idx = where(strmatch(r, 'mms_' + stlm.input + '_fomstr', /fold_case), ct) ; Check if soca exists.
    codeFOM = (ct eq 1)
    if codeFOM then begin
      get_data, 'mms_' + stlm.input + '_fomstr', data = D, lim = lim, dl = dl
      store_data, 'mms_stlm_fomstr', data = D, lim = lim, dl = dl
      options, 'mms_stlm_fomstr', 'unix_FOMStr_mod', lim.unix_fomStr_org ; add unixFOMStr_mod
      options, 'mms_stlm_fomstr', 'unix_FOMStr_org' ; remove unixFOMStr_org
      options, 'mms_stlm_fomstr', 'ytitle', 'FOM'
      options, 'mms_stlm_fomstr', 'ysubtitle', ysubtitle
      options, 'mms_stlm_fomstr', 'constant', [50, 100, 150, 200]
      eva_sitl_copy_fomstr
      dgrand = ['mms_stlm_fomstr', 'mms1_stlm_fomstr', 'mms2_stlm_fomstr', 'mms3_stlm_fomstr', 'mms4_stlm_fomstr']
    endif else begin
      print, 'EVA: FOMStr was not found for the specified time period.'
      ; print, msg
      ; answer = dialog_message(msg,/center)
      return, 'No'
    endelse

    ; 'mms_soca_bakstr'
    idx = where(strmatch(r, 'mms_' + stlm.input + '_bakstr', /fold_case), ct)
    codeBAK = (ct eq 1)
    if codeBAK then begin
      get_data, 'mms_' + stlm.input + '_bakstr', data = D, lim = lim, dl = dl
      store_data, 'mms_stlm_bakstr', data = D, lim = lim, dl = dl
      options, 'mms_stlm_bakstr', 'unix_BAKStr_mod', lim.unix_bakStr_org ; add unix_BAKStr_mod
      options, 'mms_stlm_bakstr', 'unix_BAKStr_org' ; remove unix_BAKStr_org
      options, 'mms_stlm_bakstr', 'ytitle', 'BAK'
      options, 'mms_stlm_bakstr', 'ysubtitle', ysubtitle
      options, 'mms_stlm_bakstr', 'constant', [50, 100, 150, 200]
      dgrand = [dgrand, 'mms_stlm_bakstr']
    endif

    ; 'mms_stlm_input_fom'
    get_data, 'mms_' + stlm.input + '_fom', data = S, lim = lim, dl = dl
    store_data, 'mms_stlm_input_fom', data = S, lim = lim, dl = dl ; Just make a copy
    options, 'mms_stlm_input_fom', 'ytitle', 'FOM'
    options, 'mms_stlm_input_fom', 'ysubtitle', '(original)'
    options, 'mms_stlm_input_fom', 'constant', [50, 100, 150, 200]

    ; 'mms_stlm_output_fom'
    dgrand = [dgrand, 'mms_soca_zero']
    store_data, 'mms_stlm_output_fom', data = dgrand, lim = lim, dl = dl
    options, 'mms_stlm_output_fom', 'codeFOM', codeFOM
    options, 'mms_stlm_output_fom', 'codeBAK', codeBAK
    options, 'mms_stlm_output_fom', 'ytitle', 'FOM'
    options, 'mms_stlm_output_fom', 'ysubtitle', ysubtitle
    options, 'mms_stlm_output_fom', 'constant', [50, 100, 150, 200]
    eva_sitl_strct_yrange, 'mms_stlm_output_fom'
    eva_sitl_strct_yrange, 'mms_stlm_fomstr'

    ; 'mms_sroi'
    eva_sitl_sroi_bar, trange = time_double(str_tspan), sc_id = 'mms1'
    eva_sitl_sroi_bar, trange = time_double(str_tspan), sc_id = 'mms2'
    eva_sitl_sroi_bar, trange = time_double(str_tspan), sc_id = 'mms3'
    eva_sitl_sroi_bar, trange = time_double(str_tspan), sc_Id = 'mms4'

    ; Update the history
    eva_sitl_stack
  endif

  eva_toc, clock, str = str, report = report

  print, 'EVA: ' + str
  return, 'Yes'
end