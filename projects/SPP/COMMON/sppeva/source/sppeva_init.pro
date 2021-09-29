PRO sppeva_init
  compile_opt idl2

  user_name = (get_login_info()).USER_NAME
  user = {id:user_name, fullname:user_name, $
    email:'N/A', team:'N/A'}
  fild = {sppfldsoc_id:'',sppfldsoc_pw:'',FLD_LOCAL_DATA_DIR:'./'}
  gene = {fom_max_value:25, basepos:0, split_size_in_sec:600, ROOT_DATA_DIR:''}
  dash = {widget:0}
  stack = {fld_i:0L, fld_list:list({Nsegs:0L}), swp_i:0L, swp_list:list({Nsegs:0L})}
  com   = {mode:'FLD', strTR:['',''], parameterset:'01_WIND_basic.txt', commDay:'5',$
    user_name:user_name, typeTR:0L, $
    fieldPTR:'spp_fld_f1_100bps_DCB_ARCWRPTR',$
    sweapPTR:'psp_swp_swem_dig_hkp_SW_SSRWRADDR'}
  def_struct = {user:user, gene:gene, fild:fild, dash:dash, com:com, stack:stack}
  defsysv,'!sppeva',exists=exists
  if not exists then begin
    defsysv,'!sppeva', def_struct
  endif


  ;--------------------------
  ; Import Saved Preferences
  ;--------------------------
  fname = 'sppeva_setting.sav'
  found = file_test(fname)
  if found then begin
    restore, fname
    sppeva_pref_import, 'USER', sppeva_user_values
    sppeva_pref_import, 'GENE', sppeva_gene_values
    sppeva_pref_import, 'FILD', sppeva_fild_values
  endif

  info = get_login_info()
  !SPPEVA.USER.ID = info.USER_NAME

  ;---------------------
  ; ID & PW for FIELDS
  ;---------------------
  ;  a = getenv('FIELDS_USER_PASS')
  ;  if strlen(a) eq 0 then begin
  ;    setenv,'FIELDS_USER_PASS='+!SPPEVA.FILD.SPPFLDSOC_ID+':'+!SPPEVA.FILD.SPPFLDSOC_PW
  ;  endif
  a = getenv('PSP_STAGING_ID')
  if (strlen(a) eq 0) and (strlen(!SPPEVA.FILD.SPPFLDSOC_ID) ne 0) then begin
    setenv,'PSP_STAGING_ID='+!SPPEVA.FILD.SPPFLDSOC_ID
  endif
  a = getenv('PSP_STAGING_PW')
  if (strlen(a) eq 0) and (strlen(!SPPEVA.FILD.SPPFLDSOC_PW) ne 0) then begin
    setenv,'PSP_STAGING_PW='+!SPPEVA.FILD.SPPFLDSOC_PW
  endif
  a = getenv('ROOT_DATA_DIR')
  if (strlen(a) eq 0) and (strlen(!SPPEVA.GENE.ROOT_DATA_DIR) ne 0) then begin
    setenv,'ROOT_DATA_DIR='+!SPPEVA.GENE.ROOT_DATA_DIR
  endif

END