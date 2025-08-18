; output: unix_FOMstr
PRO eva_sitl_load_soca_simple, unix_FOMstr=unix_FOMstr,no_gui=no_gui, fom_file=fom_file
  compile_opt idl2
  
  ;------------------------------------
  ; Initialize
  ;------------------------------------
  mms_init
  widget_note = 'You must have a valid MMS/SITL account in order to use EVA.'
  connected = mms_login_lasp(username = username, widget_note = widget_note)
  if (connected eq 0) then begin
    print, pname+': not logged in.'
    return
  endif
  pname=strupcase('EVA')

  ;------------------------------------
  ; Fetch FOMstr (AUTO)
  ;------------------------------------
  get_latest_fom_from_soc, fom_file, error_flag, error_msg
  if error_flag then begin
    print,'EVA: '+error_msg
    if ~keyword_set(no_gui) then result=dialog_message(error_msg,/center)
    return
  endif
  
  restore, fom_file
  
  if FOMstr.VALID eq 0 then begin
    print,'==============================='
    print,' WARNING: FOMstr not valid '
    print,'==============================='
    print, FOMstr
    unix_FOMstr = 0.
    return
  endif
  mms_convert_fom_tai2unix, FOMstr, unix_FOMstr, start_string
  sz = size(unix_FOMstr,/type)
  if sz[0] ne 8 then stop
  print, pname+': unixFOMstr (AUTO)'

  ;--------------------
  ; 'mms_soca_fomstr'
  ;--------------------
  tfom = eva_sitl_tfom(unix_FOMstr)
  store_data,'mms_soca_fomstr',data=eva_sitl_strct_read(unix_FOMStr,tfom[0])
  options,'mms_soca_fomstr',ytitle='FOM', ysubtitle='(ABS)',psym=0
  options,'mms_soca_fomstr','unix_FOMStr_org',unix_FOMStr
  options,'mms_soca_fomstr','constant',[50,100,150,200]

  ;----------------
  ; 'mms_soca_mdq'
  ;----------------
  wavex = unix_FOMstr.TIMESTAMPS+5.d0; shift 5 seconds so that the bars (histograms) will be properly placed.
  store_data,'mms_soca_mdq',data={x:wavex, y:unix_FOMstr.MDQ}
  options,'mms_soca_mdq',psym=10, ytitle='MDQ'

END
