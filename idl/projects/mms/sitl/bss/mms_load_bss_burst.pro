PRO mms_load_bss_burst, trange=trange, include_labels=include_labels
  compile_opt idl2
  
  if ~undefined(trange) && n_elements(trange) eq 2 $
    then trange = timerange(trange) $
  else trange = timerange()
  mms_init
  
  ;-------------------
  ; DATA
  ;-------------------
  s = mms_bss_load(trange=trange)
  if n_tags(s) lt 10 then return
  
  ;-------------------
  ; FIRST POINT
  ;-------------------
  bar_x = trange[0]
  bar_y = !VALUES.F_NAN

  ;-------------------
  ; MAIN LOOP
  ;-------------------
  nan = !VALUES.F_NAN
  Nsegs = n_elements(s.FOM)
  for n=0,Nsegs-1 do begin; for each segment
    ss = double(s.START[N])
    se = double(s.STOP[N]+10.d0)
    bar_x = [bar_x, ss, ss, se, se]
    bar_y = [bar_y, nan, 0.,0., nan]
  endfor
  if n_elements(bar_x) gt 1 then begin
    bar_x = bar_x[1:*]
    bar_y = bar_y[1:*]
  endif
  
  ;-------------------
  ; TPLOT VARIABLE
  ;-------------------
  store_data,'mms_bss_burst',data={x:bar_x, y:bar_y}

  if undefined(include_labels) then panel_size= 0.01 else panel_size=0.09
  if undefined(include_labels) then labels='' else labels=['Burst']
  options,'mms_bss_burst',thick=5,xstyle=4,ystyle=4,yrange=[-0.001,0.001],ytitle='',$
    ticklen=0,panel_size=panel_size,colors=4, labels=labels, charsize=2.

END



