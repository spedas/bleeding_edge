;+
;PROCEDURE:   mvn_sta_msnap
;PURPOSE:
;  Plots mass/energy snapshots of STATIC c6 data.  Wrapper for mvn_sta_get('c6') 
;  and contour_4d that provides improved interactive use.
;
;USAGE:
;  mvn_sta_msnap
;
;INPUTS:
;       none
;
;KEYWORDS:
;       SUM:    Average all times between two selected times.
;
;       KEEP:   Do not close the snapshot window on exit.
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
;       TMARK:    On the time series window, mark the currently selected 
;                 time interval with transient timebars that show the start
;                 and end times.
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2026-01-31 09:38:42 -0800 (Sat, 31 Jan 2026) $
; $LastChangedRevision: 34089 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/sta/mvn_sta_gen_snapshot/mvn_sta_msnap.pro $
;
;CREATED BY:    David L. Mitchell
;-
pro mvn_sta_msnap, sum=sum, keep=keep, key=key, lastcut=result, tmark=tmark, xmax=xmax, $

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
                yticks=yticks, $

              ; CONTOUR4D
                mass=mass, units=units, ncont=ncont, levels=levels, fill=fill, points=points, $
                label=label, vel=vel, limits=limits

; Set keywords using the KEY structure

  if (size(key,/type) eq 8) then begin
    ktag = tag_names(key)
    tlist = ['SUM','KEEP','LASTCUT','TMARK','XMAX', $

             'MONITOR','SECONDARY','XSIZE','YSIZE','DX','DY','CORNER','CENTER','XCENTER','YCENTER', $
             'NORM','XPOS','YPOS','FULL','XFULL','YFULL', $

             'TITLE','XTITLE','YTITLE','XLOG','YLOG','XRANGE','YRANGE','XSTYLE','YSTYLE','LINESTYLE', $
             'PSYM','SYMSIZE','THICK','TICKLEN','CHARSIZE','XMARGIN','YMARGIN','XMINOR','YMINOR', $
             'XTHICK','YTHICK','XTICKFORMAT','YTICKFORMAT','XTICKINTERVAL','YTICKINTERVAL', $
             'XTICKLEN','YTICKLEN','XTICKS','YTICKS', $

             'MASS','UNITS','NCONT','LEVELS','FILL','POINTS','LABEL','VEL','LIMITS']

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

  npts = keyword_set(sum) ? 2 : 1
  keep = keyword_set(keep)
  xsize = (n_elements(xsize) gt 0) ? fix(xsize[0]) : 1000
  ysize = (n_elements(ysize) gt 0) ? fix(ysize[0]) : 800
  dx = (n_elements(dx) gt 0) ? fix(dx[0]) : 10
  dy = (n_elements(dy) gt 0) ? fix(dy[0]) : 10
  xrange = (n_elements(xrange) ge 2) ? minmax(xrange) : [0.3, 3000.]
  zrange = (n_elements(zrange) ge 2) ? minmax(zrange) : [1e4,1e8]
  secondary = (n_elements(secondary) gt 0) ? keyword_set(secondary) : 1
  fill = (n_elements(fill) gt 0) ? keyword_set(fill) : 1
  mass = (n_elements(mass) gt 0) ? keyword_set(mass) : 1
  points = (n_elements(points) gt 0) ? keyword_set(points) : 1
  label = (n_elements(label) gt 0) ? keyword_set(label) : 1
  vel = keyword_set(vel)
  tmark = keyword_set(tmark)

  limits = {xrange:xrange, zrange:zrange, charsize:charsize}

; Create a snapshot window

  Twin = !d.window
  win, /free, monitor=monitor, secondary=secondary, xsize=xsize, ysize=ysize, dx=dx, dy=dy, $
       corner=corner, center=center, xcenter=xcenter, ycenter=ycenter, xpos=xpos, ypos=ypos, $
       norm=norm, full=full, xfull=xfull, yfull=yfull
  Swin = !d.window

; Make snapshot(s)

  ctime,t,npoints=npts,silent=2
  if (npts gt 1) then cursor,cx,cy,/norm,/up  ; make sure mouse button is released
  if (size(t,/type) eq 2) then begin
    wdelete, Swin  ; delete never used window
    return
  endif

  keepgoing = 1

  while (keepgoing) do begin

    tin = minmax(t)
    if (tmark) then timebar, tin, /line, /transient

    wset, Swin
      dat = mvn_sta_get('c6', tt=tin)
      contour4d,dat,mass=mass,fill=fill,points=points,label=label,vel=vel,limits=limits
      oplot,[0.01,10000],[16,16],line=2,color=1  ; NH3+ (17)
      oplot,[0.01,10000],[32,32],line=2,color=1  ; N2+ (28)
      oplot,[0.01,10000],[2,2],line=2,color=1    ; H2+, He++ (2)
    wset, Twin

    ctime,t,npoints=npts,/silent
    if (npts eq 2) then cursor,cx,cy,/norm,/up  ; make sure mouse button is released
    if (size(t,/type) eq 2) then keepgoing = 0

    if (tmark) then timebar, tin, /line, /transient

  endwhile

  if (~keep) then wdelete,Swin

end
