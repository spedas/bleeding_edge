PRO mms_load_bss_fast, trange=trange, include_labels=include_labels
  compile_opt idl2
  
  if ~undefined(trange) && n_elements(trange) eq 2 $
    then trange = timerange(trange) $
  else trange = timerange()
  mms_init
  
  ;-------------------
  ; DATA
  ;-------------------
  mms_get_abs_fom_files, local_flist, pw_flag, pw_message

  if pw_flag eq 0 then begin
    qmax = n_elements(local_flist)
    bar_x = trange[0]
    bar_y = !VALUES.F_NAN
    for q=0,qmax-1 do begin
      restore, local_flist[q]
      tsu = mms_tai2unix(FOMstr.TIMESTAMPS)
      bar_x = [bar_x, tsu[0],tsu[0],tsu[FOMstr.NUMCYCLES-1],tsu[FOMstr.NUMCYCLES-1]]
      bar_y = [bar_y, !VALUES.F_NAN, 0., 0., !VALUES.F_NAN]
    endfor
    if n_elements(bar_x) gt 1 then begin
      bar_x = bar_x[1:*]
      bar_y = bar_y[1:*]
    endif
  endif
  
  ;-------------------
  ; TPLOT VARIABLE
  ;-------------------
  store_data,'mms_bss_fast',data={x:bar_x, y:bar_y}
  
  if undefined(include_labels) then panel_size= 0.01 else panel_size=0.09
  if undefined(include_labels) then labels='' else labels=['Fast']
  options,'mms_bss_fast',thick=5,xstyle=4,ystyle=4,yrange=[-0.001,0.001],$
    ticklen=0,panel_size=panel_size,colors=6, labels=labels, charsize=2.
END
