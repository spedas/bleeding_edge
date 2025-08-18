; This program controls the history of all the changes made to the FOMstr/BAKstr.
; Usually called immediately after 'eva_sitl_strct_update' (After the "Edit"
; button is pressed.)
;
PRO eva_sitl_stack
  @eva_sitl_com

  get_data,'mms_stlm_fomstr',data=Df,lim=Lf,dl=dl
  rst = tnames()
  idx = where(strmatch(rst,'mms_stlm_bakstr'),ct_bak)
  if ct_bak gt 0 then begin
    get_data,'mms_stlm_bakstr',data=Db,lim=Lb,dl=dl
    data = {f:Lf.UNIX_FOMSTR_MOD, b:Lb.UNIX_BAKSTR_MOD}
  endif else begin
    data = {f:Lf.UNIX_FOMSTR_MOD, b:0.}
  endelse

  ptr = ptr_new(data)
  fmax = n_elements(fom_stack)
  if fmax eq 0 then fom_stack = ptr else fom_stack = [ptr, fom_stack]
  i_fom_stack = 0
END