; The input "state" is the DATA MODULE state.
FUNCTION eva_data_load_sitl, state
  compile_opt idl2
  
  catch, error_status
  if error_status ne 0 then begin
    catch, /cancel
    eva_error_message, error_status
    message,/reset
    return, 'No'
  endif
  
  clock = eva_tic('EVA_DATA_LOAD_STLM',/profiler) 
  
  str_tspan = [state.START_TIME, state.END_TIME]; string array
  
;  stlm  = {$; SITL Manu
;    input: 'socs', $ ; input type (default: 'soca'; or 'socs','stla')
;    update: 1 } ; update input data everytime plotting STLM variables

  widget_control, widget_info(state.PARENT,find='eva_sitl'), GET_VALUE=state_sitl
  stlm = {input: state_sitl.PREF.EVA_STLM_INPUT, update:state_sitl.PREF.EVA_STLM_UPDATE}
  
  ; Check pre-loaded variables.
  ; Avoid reloading if already exists.
  tn=tnames('mms_stlm_fomstr',ct)
  str_element,/add,stlm,'update',(ct eq 0) 
  
  ; Should use "execute" to reduce number of codes?
  if stlm.update then begin
    
    eva_sitl_load_soca,state, str_tspan; generates 'mms_soca_fom'(data=['mms_soca_fomstr','mms_soca_zero'])
    
    case stlm.input of
      'soca': ; Already done above; Do nothing
      'socs': eva_sitl_load_socs,state, str_tspan; generates 'mms_socs_fom'(data=['mms_socs_fomstr','mms_socs_zero'])
      'stla': eva_sitl_load_stla,state          ; generates 'mms_stla_fom'(data=['mms_stla_fomstr','mms_stla_zero'])
      else: stop
    endcase
    r=tnames()
    ysubtitle='(SITL)'
    

    ; 'mms_stlm_fomstr'
    idx=where(strmatch(r,'mms_'+stlm.input+'_fomstr',/fold_case),ct)
    codeFOM = (ct eq 1)
    if codeFOM then begin
      ;if (state.USER_FLAG ne 4) then begin; If not FPI, use FOMStr as is.
        get_data,'mms_'+stlm.input+'_fomstr',data=D,lim=lim,dl=dl
;      endif else begin; If FPI, hack FOMStr
;        get_data,'mms_soca_fomstr',data=D,lim=lim,dl=dl; Get orignal FOMStr
;        ; Here, add a dummy segment because a FOMstr has to have at least one segment.
;        ; But, FPIcal wants to start fresh from no segment.
;        s = lim.UNIX_FOMstr_org; Take out the original FOMstr "unix_FOMStr_org"
;        str_element,/add,s,'FOM',[0.]; FOM value = 0
;        str_element,/add,s,'START',[0L]; start of the 1st cycle
;        str_element,/add,s,'STOP',[1L]; end fo the 1st cycle
;        str_element,/add,s,'NSEGS',1L
;        str_element,/add,s,'NBUFFS',1L
;        str_element,/add,s,'SEGLENGTHS',1L
;        str_element,/add,s,'FPICAL',1L; Set 1 to indicate that a dummy segment exists.
;        str_element,/add,s,'SOURCEID', eva_sourceid()
;        str_element,/add,lim,'UNIX_FOMstr_org',s; put the hacked version back into "unix_FOMstr_org"
;        D = eva_sitl_strct_read(s,min(lim.unix_FOMstr_org.START,/nan)); change the tplot-data accordingly
;        ysubtitle = '(FPI)'
;      endelse

      store_data,'mms_stlm_fomstr',data=D,lim=lim,dl=dl
      options,   'mms_stlm_fomstr','unix_FOMStr_mod',lim.unix_FOMStr_org; add unixFOMStr_mod
      options,   'mms_stlm_fomstr','unix_FOMStr_org'; remove unixFOMStr_org
      options,   'mms_stlm_fomstr','ytitle','FOM'
      options,   'mms_stlm_fomstr','ysubtitle',ysubtitle
      options,   'mms_stlm_fomstr','constant',[50,100,150,200]
      dgrand = ['mms_stlm_fomstr']
    endif else begin 
      print, 'EVA: FOMStr was not found for the specified time period.'
      ;print, msg
      ;answer = dialog_message(msg,/center)
      return, 'No'
    endelse
    
    ; 'mms_soca_bakstr'
    idx=where(strmatch(r,'mms_'+stlm.input+'_bakstr',/fold_case),ct)
    codeBAK = (ct eq 1)
    if codeBAK then begin
      get_data,'mms_'+stlm.input+'_bakstr',data=D,lim=lim,dl=dl
      store_data,'mms_stlm_bakstr',data=D, lim=lim, dl=dl
      options,   'mms_stlm_bakstr','unix_BAKStr_mod',lim.unix_BAKStr_org; add unix_BAKStr_mod
      options,   'mms_stlm_bakstr','unix_BAKStr_org'; remove unix_BAKStr_org
      options,   'mms_stlm_bakstr','ytitle','BAK'
      options,   'mms_stlm_bakstr','ysubtitle',ysubtitle
      options,   'mms_stlm_bakstr','constant',[50,100,150,200]
      dgrand = [dgrand,'mms_stlm_bakstr']
    endif

    ; 'mms_stlm_input_fom'
    get_data,'mms_'+stlm.input+'_fom',data=S,lim=lim,dl=dl
    store_data, 'mms_stlm_input_fom',data=S,lim=lim,dl=dl; Just make a copy
    options, 'mms_stlm_input_fom','ytitle','FOM'
    options, 'mms_stlm_input_fom','ysubtitle','(original)'
    options, 'mms_stlm_input_fom','constant',[50,100,150,200]
    
    ; 'mms_stlm_output_fom'
    dgrand = [dgrand,'mms_soca_zero']
    store_data, 'mms_stlm_output_fom',data=dgrand,lim=lim,dl=dl
    options, 'mms_stlm_output_fom','codeFOM',codeFOM
    options, 'mms_stlm_output_fom','codeBAK',codeBAK
    options,'mms_stlm_output_fom','ytitle','FOM'
    options,'mms_stlm_output_fom','ysubtitle',ysubtitle
    options,'mms_stlm_output_fom','constant',[50,100,150,200]
    eva_sitl_strct_yrange,'mms_stlm_output_fom'
    eva_sitl_strct_yrange,'mms_stlm_fomstr'
    
    ; Update the history
    eva_sitl_stack
  endif

  eva_toc,clock,str=str,report=report
  
  print,'EVA: '+str
  return, 'Yes'
END