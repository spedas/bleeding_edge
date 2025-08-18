; $LastChangedBy: moka $
; $LastChangedDate: 2023-08-28 12:07:00 -0700 (Mon, 28 Aug 2023) $
; $LastChangedRevision: 32070 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/sitl/eva/source/cw_sitl/eva_sitl_restore.pro $
FUNCTION eva_sitl_restore_check_obsset, fomstr
  compile_opt idl2
  if n_tags(fomstr) eq 0 then begin
    answer = dialog_message('No tag found in the FOMstr.',/center)
    return, 0
  endif
  tn = tag_names(fomstr)
  idx = where(tn eq 'OBSSET', ct)
  if ct eq 0 then begin
    answer = dialog_message('OBSSET tag not found in the FOMstr.',/center)
    return, 0
  endif
  if n_elements(fomstr.OBSSET) ne n_elements(fomstr.FOM) then begin
    answer = dialog_message('The number of segments in the OBSSET tag does not match with the number of defined segments.',/center)
    return, 0
  endif
  return, 1
END

PRO eva_sitl_restore, state_data, auto=auto, dir=dir
  compile_opt idl2

  if keyword_set(auto) then begin
    if n_elements(dir) eq 0 then dir = spd_default_local_data_dir() + 'mms/'
    fname = 'eva-fom-modified-most-recent.sav'
  endif else begin
    fname = dialog_pickfile(/READ)
    if strlen(fname) eq 0 then begin
      answer = dialog_message('Cancelled',/center,/info)
      return
    endif
  endelse
  found = file_test(fname)
  if ~found then begin
    answer = dialog_message('File not found!',/center,/error)
    return
  endif
  ;-----------------------------
  restore, fname; save, eva_lim, eva_dl, filename=fname
  ;-----------------------------
  
  
  msg = ['Overwrite existing FOM(SITL) ?']
  msg = [msg, ' ']
  msg = [msg, 'If "No" is selected, then the file will be restored ']
  msg = [msg, 'into a separate "FOM (Copy)" panel and you will not ']
  msg = [msg, 'be able to view comments of each segment.']
  
  answer = dialog_message(msg,/center,/question)
  tpname = (answer eq 'Yes') ? 'mms_stlm_fomstr' : 'mms_stlm_fomstr_copy'

  valid = 0
  if undefined(fomstr) then begin
    fomstr = eva_lim.UNIX_FOMSTR_MOD
    valid = eva_sitl_restore_check_obsset(fomstr)
    if valid then begin
      tfom = eva_sitl_tfom(fomstr)
      Dnew = eva_sitl_strct_read(fomstr,tfom[0])
      store_data,tpname,data=Dnew,lim=eva_lim,dl=eva_dl; update the tplot-variable
    endif
  endif else begin
    eva_sitl_load_soca_simple ; load 'mms_soca_fomstr' for skelton
    mms_convert_fom_tai2unix, FOMstr, s, start_string
    valid = eva_sitl_restore_check_obsset(fomstr)
    if valid then begin
      tfom = eva_sitl_tfom(s)
      Dnew=eva_sitl_strct_read(s,tfom[0])
      get_data,'mms_soca_fomstr',data=D,lim=lim,dl=dl; skelton
      store_data,tpname,data=Dnew,lim=lim,dl=dl
      options,   tpname,ytitle='FOM', ysubtitle='(SITL)', constant=[50,100,150,200]
      options,   tpname,'unix_FOMStr_mod', s; add unixFOMStr_mod
      options,   tpname,'unix_FOMStr_org'; remove unixFOMStr_org
    endif
  endelse
  

  if valid eq 0 then begin
;    answer = dialog_message('Not a valid FOMstr!',/center,/error)
    return
  endif
  
  eva_sitl_stack
  eva_sitl_strct_yrange,'mms_stlm_output_fom'
  eva_sitl_strct_yrange,tpname
  
  if answer eq 'No' then begin
    options, tpname, ysubtitle='(Copy)'
    ss = eva_data_load_and_plot(state_data, /cod)
  endif else begin
    tplot
  endelse
  
  answer = dialog_message('FOMstr successfully restored!',/center,/info)
END
