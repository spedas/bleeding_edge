PRO mms_load_bss_fom, trange=trange
  compile_opt idl2
  
  if ~undefined(trange) && n_elements(trange) eq 2 $
    then trange = timerange(trange) $
  else trange = timerange()

  s = mms_bss_load(trange=trange)
  if n_tags(s) lt 10 then return
  D = eva_sitl_strct_read(s,trange[0])
  store_data,'mms_bss_fom',data=D
  options,'mms_bss_fom','ytitle','FOM'
  ;options,'mms_bss_fom','ysubtitle','(SOC)'
  options,'mms_bss_fom','colors',0;85
  options,'mms_bss_fom','unix_BAKStr',s
END
