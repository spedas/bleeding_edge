PRO xtplot_timebar,t1,color=color,linestyle=linestyle,thick=thick,verbose=verbose,$
            varname=varname,between=between,transient=transient,databar=databar
;+
;NAME:                  timebar
;PURPOSE:
;                       plot vertical (or horizontal) lines on TPLOTs at specified times (or values)
;CALLING SEQUENCE:      timebar,t
;INPUTS:                t: dblarr of times at which to draw vertical lines,
;                       seconds since Jan, 1, 1970.  (Or a single datavalue at which to draw a horizontal
;                       line in units of the TPLOT variable named in VARNAME).
;KEYWORD PARAMETERS:
;      DATABAR:    Set to plot horizontal lines.  *** Must set VARNAME also (for the time being) ***.
;      COLOR:      byte or bytarr of color values
;      LINESTYLE:  int or intarr of linestyles
;      THICK:      int or intarr of line thicknesses
;   for any of the above keywords, a scalar input will apply to all times
;      VERBOSE: print more error messages; useful for debugging
;      VARNAME: TPLOT variable name or index indicating panel in which to plot bar
;      BETWEEN: array of two TPLOT variable names indicating
;           between which two panels to plot timebar
;                       TRANSIENT:  timebar,t,/transient called once plots a
;           timebar. Called twice, it deletes the timebar.
;                                Note:  1) all other keywords except VERBOSE
;                                be the same for both calls. 2) COLOR will most
;                                likely not come out what you ask for, but
;                                since it's transient anyway, shouldn't matter.
;OUTPUTS:
;OPTIONAL OUTPUTS:
;COMMON BLOCKS:         tplot_com
;EXAMPLE:
;      load_3dp_data,'95-01-01',2 & get_pmom
;      tplot,['Np','Tp','Vp']
;      t=time_double('95-01-01/1:12')
;      timebar,t             ;put a white line at 1:12 am, Jan, 1, 1995
;      ctime,t1,t2           ;select two times from the plot
;      timebar,[t1,t2],color=!d.n_colors-2 ;plot them in red
;SEE ALSO:
;  "CTIME","TPLOT"
;CREATED BY:            Frank V. Marcoline
;LAST MODIFICATION:     2009/05/14, W.M.Feuerstein
;FILE:                  timebar.pro
;VERSION:               1.91
;-
@tplot_com

  ; Validate parameter according to whether it is a timebar or a databar:
  ;
  if undefined(t1) then begin
    case keyword_set(databar) of
      0: t = time_double(t1)
      1: begin
        t1 = 0d
        read, prompt = 'Please provide numeric value for databar: ', t1
        t = t1
      end
    endcase
  endif else begin
    case keyword_set(databar) of
      0: t = time_double(t1)
      1: t = double(t1)
    endcase
  endelse

  nt = n_elements(t)
  if not keyword_set(color) then begin
    if !p.background eq 0 then color = !d.n_colors-1 else color = 0
  endif
  if n_elements(color) ne nt then color = make_array(nt,value=color)
  if not keyword_set(linestyle) then linestyle = 0
  if n_elements(linestyle) ne nt then linestyle = make_array(nt,value=linestyle)
  if not keyword_set(thick) then thick = 1
  if n_elements(thick) ne nt then thick = make_array(nt,value=thick)

  if !d.name eq 'X' or !d.name eq 'WIN' then begin
    current_window= !d.window > 0
    wset,tplot_vars.settings.window
;    wshow,icon=0
  endif
  str_element,tplot_vars,'settings.x.window',xp
  str_element,tplot_vars,'settings.x.crange',xr
;  if keyword_set(databar) then begin                                              ;databar
;    str_element,tplot_vars,'settings.y.window',yp
;    str_element,tplot_vars,'settings.y.crange',yr
;  endif
  nd1 = n_elements(tplot_vars.settings.y)-1
  nd0 = 0
  if keyword_set(varname) then begin
     nd = where( tnames(varname[0]) eq tplot_vars.options.varnames)
     nd0=nd[0]
     nd1=nd[0]
  endif else if keyword_set(databar) then begin
     dprint, 'VARNAME is requred when DATABAR is set.  Returning,...',dlevel=2
     ;message,/info,'VARNAME is requred when DATABAR is set.  Returning,...'
     return
  endif
  nt = n_elements(t)
  yp = fltarr(2)
  yr = fltarr(2)

  if keyword_set(between) eq 0 then begin
    yp(0) = tplot_vars.settings.y(nd1).window(0)
    yp(1) = tplot_vars.settings.y(nd0).window(1)
    if keyword_set(databar) then begin
      yr(0) = tplot_vars.settings.y(nd1).crange(0)
      yr(1) = tplot_vars.settings.y(nd0).crange(1)
    endif
  endif else begin
    nd0 = (where(between[0] eq tplot_vars.options.varnames))(0)
    nd1 = (where(between[1] eq tplot_vars.options.varnames))(0)
    yp(0) = tplot_vars.settings.y(nd1).window(1)
    yp(1) = tplot_vars.settings.y(nd0).window(0)
  endelse

  if keyword_set(transient) then $
    device, get_graphics = ograph, set_graphics = 8 ;set to copy

  if ~keyword_set(databar) then begin                           ;timebar
    for i=0l,nt-1 do begin
      tp = t(i) - tplot_vars.settings.time_offset
      tp = xp(0) + (tp-xr(0))/(xr(1)-xr(0)) * (xp(1)-xp(0))
      if tp ge xp(0) and tp le xp(1) then begin
	plots,[tp,tp],yp,color=color(i),linestyle=linestyle(i),thick=thick(i),/normal
      endif else if keyword_set(verbose) then $
	dprint, 'Time '+time_string(t(i))+' is out of trange.'
    endfor
  endif else begin

;    for i=0l,nt-1 do begin                                      ;databar
    for i=0l,0l do begin                                      ;databar    ;for now work only on first element.
      dp = t(i)
;      if tplot_vars.settings.y[nd[i]].type then dp = yp[0,i] + (( alog10(dp) - yr[0,i] )/(yr[1,i]-yr[0,i]) * (yp[1,i]-yp[0,i])) else $
;        dp = yp[0,i] + (dp-yr[0,i])/(yr[1,i]-yr[0,i]) * (yp[1,i]-yp[0,i])
      if tplot_vars.settings.y[nd[i]].type then dp = yp[0] + (( alog10(dp) - yr[0] )/(yr[1]-yr[0]) * (yp[1]-yp[0])) else $
        dp = yp[0] + (dp-yr[0])/(yr[1]-yr[0]) * (yp[1]-yp[0])
;      if dp ge yp[0] and dp le yp[1] then begin
      if dp ge yp[0,i] and dp le yp[1,i] then begin
	plots,xp,[dp,dp],color=color(i),linestyle=linestyle(i),thick=thick(i),/normal
      endif else if keyword_set(verbose) then $
	dprint, 'Data value '+string(t(i))+' is out of trange.'
    endfor
  endelse

  if keyword_set(transient) then device,set_graphics=ograph

  if !d.name eq 'X' or !d.name eq 'WIN' then begin
    wset,current_window
  endif
  return
END
