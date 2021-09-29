; 'trange' and 'sc_id' are optional
;
PRO eva_sitl_sroi_bar,trange=trange,sc_id=sc_id,colors=colors,suffix=suffix
  compile_opt idl2

  ;-----------------
  ; LOAD DATA
  ;-----------------
  if undefined(trange) then begin
    trange = timerange(/current)
  endif else begin
    trange = time_double(trange)
  endelse
  str_trange = time_string(trange)
  sROIs = mms_get_srois(trange = str_trange, sc_id=sc_id)
  nan = !VALUES.F_NAN
  nan4 = [!VALUES.F_NAN,!VALUES.F_NAN,!VALUES.F_NAN,!VALUES.F_NAN]
  if n_tags(sROIs) lt 3 then return
    
  ;-------------------
  ; FIRST POINT
  ;-------------------
  bar_x = trange[0]
  bar_y = fltarr(1,2)
  bar_y[0,*] = [nan,nan]

  ;-------------------
  ; MAIN LOOP
  ;-------------------
  nROIs = n_elements(sROIs.starts)
  for n=0,nROIs-1 do begin; for each ROI
    ss = time_double(sROIs.starts[n])
    se = time_double(sROIs.stops[n])
    bar_x = [bar_x, ss, ss, se, se]
    bar_y_new = fltarr(4,2) ; v=0 and 1 for even and odd orbits, respectively.
    if((sROIs.orbits[n] mod 2) eq 0)then begin
      bar_y_new[*,0] = [nan, 0., 0.,nan]; even orbits
      bar_y_new[*,1] = [nan,nan,nan,nan]
    endif else begin
      bar_y_new[*,0] = [nan,nan,nan,nan]
      bar_y_new[*,1] = [nan, 0., 0.,nan]; odd orbits
    endelse
    bar_y = [bar_y, bar_y_new]
  endfor
    
  ;-------------------
  ; TPLOT VARIABLE
  ;-------------------
  if undefined(colors) then colors = [1,3]; pink(1) and blue(3) for even and odd orbits, respectively.
  
  ;////////////////////////
  panel_size=0.1
  labels = ['even','odd']
  ;////////////////////////
  
  dname = 'mms_sroi'
  if ~undefined(suffix) then dname += suffix
  
  store_data,dname,data={x:bar_x, y:bar_y, v:[0,1]}
  options,dname,thick=5,xstyle=4,ystyle=4,yrange=[-0.01,0.01],ytitle='',$
    ticklen=0,panel_size=panel_size,colors=colors, charsize=2.;,labels=labels, labflag=-1
END