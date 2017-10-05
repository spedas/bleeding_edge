PRO eva_sitl_highlight, left_edges, right_edges, data, state, $
  color=color, rehighlight=rehighlight, noline=noline
  compile_opt idl2
  @xtplot_com
  @tplot_com
  @eva_sitl_com
  
  nmax = n_elements(left_edges)
  if (nmax ne n_elements(right_edges)) or (nmax ne n_elements(data)) then begin
    message,'edges and data must have the same number of elements'
    return
  endif
  if n_elements(color) eq 0 then color=1; 128

  var = state.pref.EVA_BAKSTRUCT ? 'mms_stlm_bakstr' : 'mms_stlm_fomstr'
  
  ind = where(strcmp(tplot_vars.SETTINGS.VARNAMES,var),ct)
  if ct eq 1 then begin 
    varID = ind[0]
    xs   = tplot_vars.SETTINGS.X.WINDOW[0]
    xe   = tplot_vars.SETTINGS.X.WINDOW[1]
    ys   = tplot_vars.SETTINGS.Y[varID].WINDOW[0]
    ye   = tplot_vars.SETTINGS.Y[varID].WINDOW[1]
    fmin = tplot_vars.SETTINGS.Y[varID].CRANGE[0]
    fmax = tplot_vars.SETTINGS.Y[varID].CRANGE[1]
    ts   = tplot_vars.SETTINGS.TRANGE_CUR[0]
    te   = tplot_vars.SETTINGS.TRANGE_CUR[1]
    time = timerange(/current)
    ts = time[0]
    te = time[1]
  ;  ; frange (data-y)
    eva_sitl_strct_yrange, var, yrange=frange
    fmin = frange[0]
    fmax = frange[1]
  
    ; coefficients
    xc = (xe-xs)/(te-ts)
    yc = (ye-ys)/(fmax-fmin)
    
    ; data points in normal coordinate
    for n=0,nmax-1 do begin
      x0 = (xc*(left_edges[n]-ts)+xs > xs) < xe
      x1 = xc*(right_edges[n]-ts)+xs < xe
      y0 = yc*(0.0-fmin)+ys > ys
      y1 = yc*(data[n]-fmin)+ys < ye
      if keyword_set(rehighlight) then begin
        polyfill, old_polygonx, old_polygony, color=color, /norm
        if ~keyword_set(noline) then begin
          plots,[old_polygonx[0],old_polygonx[0]],[0.0,1.0],color=color,/norm
          plots,[old_polygonx[2],old_polygonx[2]],[0.0,1.0],color=color,/norm
        endif
      endif
      polyfill, [x0,x0,x1,x1],[y0,y1,y1,y0],color=color, /norm
      if ~keyword_set(noline) then begin
        plots,[x0,x0],[0.0,1.0],color=color,/norm
        plots,[x1,x1],[0.0,1.0],color=color,/norm
      endif
      old_polygonx = [x0,x0,x1,x1]
      old_polygony = [y0,y1,y1,y0]
      old_tstart = ts
      old_tend   = te 
    endfor
  endif else begin
    print,'EVA: (eva_sitl_highlight) ',var,' not found'
  endelse
END