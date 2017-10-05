

PRO eva_sitl_load_soca, state, str_tspan, mdq=mdq
  compile_opt idl2
  tspan = time_double(str_tspan)
  print,'EVA: (eva_sitl_load_soca) tspan:'+str_tspan[0]+' - '+str_tspan[1]

  ;============
  ; FOM
  ;============
  ; Whatever tspan is, we retrieve the latest unix_FOMStr to get 'tfom'.
  unix_FOMstr = eva_sitl_load_soca_getfom(state.PREF, state.PARENT)
  sz = size(unix_FOMstr,/type)
  if sz[0] ne 8 then return
  
  ;------------------------
  ; 'mms_soca_fomstr'
  ;------------------------
  tfom = eva_sitl_tfom(unix_FOMstr)
  print,'EVA: tfom:'+time_string(tfom[0],prec=7)+' - '+time_string(tfom[1],prec=7)
  dgrand = ['mms_soca_fomstr']
  store_data,'mms_soca_fomstr',data=eva_sitl_strct_read(unix_FOMStr,tfom[0])
  options,'mms_soca_fomstr','ytitle','FOM'
  options,'mms_soca_fomstr','ysubtitle','(ABS)'
  options,'mms_soca_fomstr','unix_FOMStr_org',unix_FOMStr
  options,'mms_soca_fomstr','psym',0
  options,'mms_soca_fomstr','constant',[50,100,150,200]
  
  ;------------------------
  ; 'mms_soca_mdq'
  ;------------------------
  wavex = unix_FOMstr.TIMESTAMPS+5.d0; shift 5 seconds so that the bars (histograms) will be properly placed.
  D = {x:wavex, y:unix_FOMstr.MDQ} 
  store_data,'mms_soca_mdq',data=D
  options,'mms_soca_mdq','psym',10
  options,'mms_soca_mdq','ytitle','MDQ'
  
  ;---------------------
  ; 'mms_soca_zero'
  ;---------------------
  zerox = [tspan[0],tfom[0],tfom[0],tfom[0],tfom[1],tfom[1],tfom[1],tspan[1]]
  zeroy = [      0.,     0.,   255.,     0.,     0.,   255.,     0.,      0.]
  store_data,'mms_soca_zero',data={x:zerox, y:zeroy}
  options,'mms_soca_zero','linestyle',1

  ;==============
  ; Historic FOM
  ;==============
  ts = str2time(str_tspan[0])
  te = str2time(str_tspan[1])
  if (ts lt tfom[0]) then begin
    te = tfom[0]
    ;mms_get_abs_fom_files, local_flist, ts, te, pw_flag, pw_message
    ;stop
  endif
  
  ;=============
  ; BACK STRUCT
  ;=============
  mms_get_back_structure, tspan[0], tspan[1], BAKStr, pw_flag, pw_message; START,STOP are ULONG

  if pw_flag then begin
    ;rst=dialog_message(pw_message,/info,/center)
  endif else begin

    unix_BAKStr_org = BAKStr
    str_element,/add,unix_BAKStr_org,'START', mms_tai2unix(BAKStr.START); START,STOP are LONG
    str_element,/add,unix_BAKStr_org,'STOP',  mms_tai2unix(BAKStr.STOP)
    D = eva_sitl_strct_read(unix_BAKStr_org,tspan[0])
    store_data,'mms_soca_bakstr',data=D
    options,'mms_soca_bakstr','ytitle','BAK'
    options,'mms_soca_bakstr','ysubtitle','(SOC)'
    options,'mms_soca_bakstr','colors',85; 179
    options,'mms_soca_bakstr','unix_BAKStr_org',unix_BAKStr_org
    options,'mms_soca_bakstr','constant',[50,100,150,200]
    dgrand = [dgrand,'mms_soca_bakstr']
    
    idx = where(strmatch(unix_BAKStr_org.STATUS,"*trimmed*"),ct_trimmed)
    idx = where(strmatch(unix_BAKStr_org.STATUS,"*subsumed*"),ct_subsumed)
    if (ct_trimmed+ct_subsumed gt 0) then begin
      msg = ['Overlapped (TRIMMED or SUBSUMED) segments detected.','']
      msg = [msg,'Please notify super-SITL.']
      result = dialog_message(msg,/center)
    endif
  endelse
  
  ;--------------------------
  ; 'mms_soca_zero' (update)
  ;--------------------------
  dgrand = [dgrand,'mms_soca_zero']
  store_data, 'mms_soca_fom',data=dgrand
  options,    'mms_soca_fom','ytitle', 'FOM'

END
