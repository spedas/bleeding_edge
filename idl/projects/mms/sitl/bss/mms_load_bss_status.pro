PRO mms_load_bss_status, trange=trange, include_labels=include_labels
  compile_opt idl2
  
  if ~undefined(trange) && n_elements(trange) eq 2 $
    then trange = timerange(trange) $
  else trange = timerange()
  
  ;-------------------
  ; DATA
  ;-------------------
  s = mms_bss_load(trange=trange)
  if n_tags(s) lt 10 then return

  ;-------------------
  ; FIRST POINT
  ;-------------------
  bar_x = trange[0]
  bar_y_comp = !VALUES.F_NAN
  bar_y_icmp = !VALUES.F_NAN
  bar_y_over = !VALUES.F_NAN
  bar_y_pend =  !VALUES.F_NAN
  imax = 1
  
  ;-------------------
  ; MAIN LOOP
  ;-------------------
  nan = !VALUES.F_NAN
  nan4 = [!VALUES.F_NAN,!VALUES.F_NAN,!VALUES.F_NAN,!VALUES.F_NAN]
  Nsegs = n_elements(s.FOM)
  for n=0,Nsegs-1 do begin; for each segment
    ss = double(s.START[N])
    se = double(s.STOP[N]+10.d0)
    imax += 4
    bar_x = [bar_x, ss, ss, se, se]
    if (not strmatch(strlowcase(s.STATUS[n]),'*incomplete*')) and $
       (strmatch(strlowcase(s.STATUS[n]),'*complete*')) then begin
      bar_y_comp = [bar_y_comp, nan, 0.,0., nan]
    endif else begin
      bar_y_comp = [bar_y_comp,nan4]
    endelse
    if (strmatch(strlowcase(s.STATUS[n]),'*incomplete*')) then begin
      bar_y_icmp = [bar_y_icmp, nan, 0.,0., nan]
    endif else begin
      bar_y_icmp = [bar_y_icmp,nan4]
    endelse
    if (not strmatch(strlowcase(s.STATUS[n]),'*incomplete*')) and $
       (strmatch(strlowcase(s.STATUS[n]),'*demoted*') or $
        strmatch(strlowcase(s.STATUS[n]),'*derelict*') ) then begin
      bar_y_over = [bar_y_over, nan, 0.,0.,nan]
    endif else begin
      bar_y_over = [bar_y_over,nan4]
    endelse
    if (s.isPENDING[n] eq 1) then begin
      bar_y_pend = [bar_y_pend, nan,0.,0.,nan]
    endif else begin
      bar_y_pend = [bar_y_pend,nan4]
    endelse
  endfor

  ;-------------------
  ; TPLOT VARIABLE
  ;-------------------
  bar_y = fltarr(imax,4)
  bar_y[*,0] = bar_y_comp
  bar_y[*,1] = bar_y_icmp
  bar_y[*,2] = bar_y_over
  bar_y[*,3] = bar_y_pend 
  if undefined(include_labels) then panel_size= 0.01 else panel_size=0.09
  if undefined(include_labels) then labels='' else labels=['Status']
    
  store_data,'mms_bss_status',data={x:bar_x, y:bar_y, v:[0,1,2,3]}
  options,'mms_bss_status',thick=5,xstyle=4,ystyle=4,yrange=[-0.001,0.001],ytitle='',$
    ticklen=0,panel_size=panel_size,colors=[0,2,6,5], labels=labels, charsize=2.
     ; 0:black ... complete
    ; 2:blue ... incomplete
    ; 6:red ... overwritten
    ; 5:yellow... pending 
    
END
