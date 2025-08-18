;+
;PROCEDURE:   tsnap
;PURPOSE:
;  Tplot variables with two independent variables (time and some other
;  parameter) are often displayed as color spectrograms, where the Y
;  axis is the second independent variable and color represents the
;  dependent variable (Z).  Sometimes, the color scale does not 
;  accurately portray the variation in Z, or it is difficult to tell
;  whether a color gradient is significant.
;
;  This routine plots cuts of color spectrograms across the second
;  independent variable at time(s) selected by the mouse.  You can plot
;  error bars if DY is provided as a tag in the tplot variable structure.
;  This procedure can average in time (and propagate errors) to improve
;  statistics.
;
;  Unless keyword SUM is set, you can hold down the left mouse button 
;  and drag for a movie effect.  Click the right mouse button at any time
;  to exit.
;
;USAGE:
;  tsnap, var
;
;INPUTS:
;       var:    Tplot variable name or number.  If not specified, determine
;               based on which panel the mouse is in when clicked.
;
;               The selected variable must have two independent variables
;               X and Y (time and some other parameter) and one dependent 
;               variable Z (represented as color in the spectrogram).  This 
;               cannot be a compound variable (list of variables to be plotted 
;               in the same panel).  You must specify which variable within 
;               the list.
;
;KEYWORDS:
;       NAVG:   Number of times to average centered on the selected time.
;               This is forced to be an odd number.  Default = 1.
;
;       SUM:    Average all times between two selected times.
;
;       XSMO:   Number of points to smooth in the second independent variable
;               (which is the snapshot X axis).  Default = 1 (no smoothing).
;
;       KEEP:   Do not close the snapshot window on exit.
;
;       DERIV:  Plot the first (DERIV=1) or second (DERIV=2) derivative.
;               Default = 0 (just plot Y).
;
;       ERR:    If the tplot variable has a DY tag, then plot error bars for
;               each point.  Propagate uncertainties when NAVG or SUM is set.
;
;       Passes many keywords to WIN (e.g. MONITOR, DX, DY, etc.).  If WIN is
;       enabled (win, /config), then by default the snapshot window will be 
;       placed in the secondary monitor.
;
;       Passes many keywords to PLOT (e.g., XSIZE, YTITLE, etc.).  If not set,
;       TITLE becomes the time or time range of the snapshot.
;
;       KEY:    Alternate method for setting keywords.  Structure containing
;               keyword(s) for this routine, plus many keywords for WIN and
;               PLOT.  Unrecognized or ambiguous keywords are ignored, but 
;               they will generate error messages.
;
;                      {KEYWORD: value, KEYWORD: value, ...}
;
;               This allows you to gather keywords into a single structure and
;               use them multiple times without a lot of typing.  In case of 
;               conflict, keywords set explicitly take precedence over KEY.
;
;       LASTCUT:  Named variable to hold data for the last plot.
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2025-05-25 09:50:47 -0700 (Sun, 25 May 2025) $
; $LastChangedRevision: 33334 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/misc/tsnap.pro $
;
;CREATED BY:    David L. Mitchell
;-
pro tsnap, var, navg=navg, sum=sum, xsmo=xsmo, keep=keep, deriv=deriv, err=err, key=key, lastcut=lastcut, $

              ; WIN
                monitor=monitor, secondary=secondary, xsize=xsize, ysize=ysize, dx=dx, dy=dy, $
                corner=corner, center=center, xcenter=xcenter, ycenter=ycenter, norm=norm, $
                xpos=xpos, ypos=ypos, full=full, xfull=xfull, yfull=yfull, $

              ; PLOT
                title=title, xtitle=xtitle, ytitle=ytitle, xlog=xlog, ylog=ylog, xrange=xrange, $
                yrange=yrange, xstyle=xstyle, ystyle=ystyle, linestyle=linestyle, psym=psym, $
                symsize=symsize, thick=thick, ticklen=ticklen, charsize=charsize, xmargin=xmargin, $
                ymargin=ymargin, xminor=xminor, yminor=yminor, xthick=xthick, ythick=ythick, $
                xtickformat=xtickformat, ytickformat=ytickformat, xtickinterval=xtickinterval, $
                ytickinterval=ytickinterval, xticklen=xticklen, yticklen=yticklen, xticks=xticks, $
                yticks=yticks

; Set keywords using the KEY structure

  if (size(key,/type) eq 8) then begin
    ktag = tag_names(key)
    tlist = ['NAVG','SUM','XSMO','KEEP','DERIV','ERR','LASTCUT', $
             'MONITOR','SECONDARY','XSIZE','YSIZE','DX','DY','CORNER','CENTER','XCENTER','YCENTER', $
             'NORM','XPOS','YPOS','FULL','XFULL','YFULL', $
             'TITLE','XTITLE','YTITLE','XLOG','YLOG','XRANGE','YRANGE','XSTYLE','YSTYLE','LINESTYLE', $
             'PSYM','SYMSIZE','THICK','TICKLEN','CHARSIZE','XMARGIN','YMARGIN','XMINOR','YMINOR', $
             'XTHICK','YTHICK','XTICKFORMAT','YTICKFORMAT','XTICKINTERVAL','YTICKINTERVAL', $
             'XTICKLEN','YTICKLEN','XTICKS','YTICKS']
    for j=0,(n_elements(ktag)-1) do begin
      i = strmatch(tlist, ktag[j]+'*', /fold)
      case (total(i)) of
          0  : print, "Keyword unrecognized: ", ktag[j]
          1  : begin
                 kname = (tlist[where(i eq 1)])[0]
                 ok = execute('kset = size(' + kname + ',/type) gt 0',0,1)
                 if (not kset) then ok = execute(kname + ' = key.(j)',0,1)
               end
        else : print, "Keyword ambiguous: ", ktag[j]
      endcase
    endfor
  endif

; Set some defaults

  if (n_elements(navg) gt 0) then k = (round(navg[0]) - 1)/2 > 0 else k = 0
  npts = keyword_set(sum) ? 2 : 1
  keep = keyword_set(keep)
  xsmo = (n_elements(xsmo) gt 0) ? fix(xsmo[0]) > 1 : 1
  if (size(deriv,/type) eq 0) then deriv = 0 else deriv = fix(deriv[0]) < 2 > 0
  dx = (n_elements(dx) gt 0) ? fix(dx[0]) : 10
  dy = (n_elements(dy) gt 0) ? fix(dy[0]) : 10
  secondary = (n_elements(secondary) gt 0) ? keyword_set(secondary) : 1
  tiny = 1.e-31

; Make sure the tplot variable exists and has the standard tags and correct dimensions

  ctime,t,panel=p,npoints=npts,/silent
  if (npts eq 2) then cursor,cx,cy,/norm,/up  ; make sure mouse button is released
  if (size(t,/type) eq 2) then return

  if (n_elements(var) eq 0) then begin
    tplot_options, get=topt
    var = topt.varnames[p[0]]
  endif

  get_data, var, data=dat, alim=lim, index=i
  if (i eq 0) then begin
    print,"Tplot variable not found: ",var
    return
  endif

  if (size(dat,/type) ne 8) then begin
    print,"Compound variable: ",var
    n = n_elements(dat) - 1
    for i=0,n do print,i,dat[i],format='("  ",i2," : ",a)'
    read, i, prompt='Variable to plot [0-' + strtrim(string(n),2) + ']: '
    var = dat[i > 0 < n]
    get_data, var, data=dat, alim=lim, index=i
    if (i eq 0) then begin
      print,"Tplot variable not found: ",var
      return
    endif
  endif

  str_element, dat, 'x', success=ok
  if (ok) then str_element, dat, 'y', success=ok
  if (ok) then begin
    if ((size(dat.y))[0] ne 2) then begin
      print,"Not a 2-D tplot variable: ",var
      return
    endif
    str_element, dat, 'v', success=ok
  endif
  if (not ok) then begin
    print,"Cannot interpret tplot variable: ",var
    return
  endif

  str_element, dat, 'dy', success=ok
  err = keyword_set(err) and ok

; Get the axis labels and ranges from the variable's limits structure (Y -> X, Z -> Y).
; Use these to set any keywords that are missing.

  str_element, lim, 'ytitle', msg, success=ok
  if (not ok) then str_element, dat, 'ytitle', msg, success=ok
  if (ok && n_elements(xtitle) eq 0) then xtitle = msg

  str_element, lim, 'yrange', rng, success=ok
  if (not ok) then str_element, dat, 'yrange', msg, success=ok
  if (ok && n_elements(xrange) eq 0) then xrange = rng

  str_element, lim, 'ylog', i, success=ok
  if (not ok) then str_element, dat, 'ylog', i, success=ok
  if (ok && n_elements(xlog) eq 0) then xlog = i

  str_element, lim, 'ystyle', i, success=ok
  if (not ok) then str_element, dat, 'ystyle', i, success=ok
  if (ok && n_elements(xstyle) eq 0) then xstyle = i

  str_element, lim, 'ztitle', msg, success=ok
  if (not ok) then str_element, dat, 'ztitle', msg, success=ok
  if (ok && n_elements(ytitle) eq 0) then ytitle = msg

  str_element, lim, 'zrange', rng, success=ok
  if (not ok) then str_element, dat, 'zrange', rng, success=ok
  if (ok && n_elements(yrange) eq 0) then yrange = rng

  str_element, lim, 'zlog', i, success=ok
  if (not ok) then str_element, dat, 'zlog', i, success=ok
  if (ok && n_elements(ylog) eq 0) then ylog = i

  str_element, lim, 'zstyle', i, success=ok
  if (not ok) then str_element, dat, 'zstyle', i, success=ok
  if (ok && n_elements(ystyle) eq 0) then ystyle = i

; Create a snapshot window

  Twin = !d.window
  win, /free, monitor=monitor, secondary=secondary, xsize=xsize, ysize=ysize, dx=dx, dy=dy, $
       corner=corner, center=center, xcenter=xcenter, ycenter=ycenter, xpos=xpos, ypos=ypos, $
       norm=norm, full=full, xfull=xfull, yfull=yfull
  Swin = !d.window

; Make snapshot(s)

  nmax = n_elements(dat.x) - 1L
  keepgoing = 1

  while (keepgoing) do begin
    i = nn2(dat.x, t)
    if ((size(dat.v))[0] eq 2) then x = reform(mean(dat.v[i,*],dim=1)) else x = dat.v
    if (npts eq 1) then begin
      imin = (i-k) > 0L
      imax = (imin + 2L*k) < nmax
      y = reform(dat.y[imin:imax,*])
      if (err) then dy = reform(dat.dy[imin:imax,*])
    endif else begin
      y = reform(dat.y[min(i):max(i),*])
      if (err) then dy = reform(dat.dy[min(i):max(i),*])
    endelse

    if ((size(y))[0] eq 2) then begin
      nrm = y
      nrm[*] = 1.
      bndx = where(~finite(y), count)
      if (count gt 0L) then begin
        nrm[bndx] = 0.
        dy[bndx] = !values.f_nan
      endif
      nrm = total(nrm,1)

      y = total(y, 1, /nan)/nrm
      if (err) then dy = sqrt(total(dy*dy, 1, /nan))/nrm
    endif

    y = smooth(y, xsmo, /nan, /edge_truncate)

    case deriv of
        1  : y = deriv(x,y)
        2  : y = deriv(x,deriv(x,y))
      else : ; do nothing
    endcase

    wset, Swin
      if (size(title,/type) ne 7) then begin
        if (npts eq 1) then begin
          tsp = minmax(dat.x[imin:imax])
          msg = time_string(tsp[0])
          if (k gt 0) then msg +=  ' - ' + strmid(time_string(tsp[1]),11)
        endif else begin
          tsp = minmax(dat.x[min(i):max(i)])
          msg = time_string(tsp[0]) + ' - ' + strmid(time_string(tsp[1]),11)
        endelse
      endif else msg = title[0]
      plot, x, y, title=msg, xtitle=xtitle, ytitle=ytitle, xrange=xrange, yrange=yrange, $
                  xlog=xlog, ylog=ylog, xstyle=xstyle, ystyle=ystyle, linestyle=linestyle, $
                  psym=psym, symsize=symsize, thick=thick, ticklen=ticklen, charsize=charsize, $
                  xmargin=xmargin, ymargin=ymargin, xminor=xminor, yminor=yminor, xthick=xthick, $
                  ythick=ythick, xtickformat=xtickformat, ytickformat=ytickformat, $
                  xtickinterval=xtickinterval, ytickinterval=ytickinterval, xticklen=xticklen, $
                  yticklen=yticklen, xticks=xticks, yticks=yticks
      if (err) then if (ylog) then errplot,x,(y-dy)>tiny,y+dy,width=0 else errplot,x,y-dy,y+dy,width=0

      lastcut = {x:x, y:y, dy:!values.f_nan, time:tsp, deriv:deriv}
      if (err) then str_element, lastcut, 'dy', dy, /add_replace
    wset, Twin

    ctime,t,npoints=npts,/silent
    if (npts eq 2) then cursor,cx,cy,/norm,/up  ; make sure mouse button is released
    if (size(t,/type) eq 2) then keepgoing = 0
  endwhile

  if (~keep) then wdelete,Swin

end
