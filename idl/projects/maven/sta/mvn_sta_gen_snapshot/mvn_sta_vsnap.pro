;+
;PROCEDURE:   mvn_sta_vsnap
;PURPOSE:
;  Wrapper for mvn_sta_slice2d_snap that provides improved interactive use.
;
;USAGE:
;  mvn_sta_vsnap
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
; $LastChangedDate: 2026-01-31 18:27:13 -0800 (Sat, 31 Jan 2026) $
; $LastChangedRevision: 34092 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/sta/mvn_sta_gen_snapshot/mvn_sta_vsnap.pro $
;
;CREATED BY:    David L. Mitchell
;-
pro mvn_sta_vsnap, sum=sum, keep=keep, key=key, lastcut=result, tmark=tmark, xmax=xmax, $

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

              ; MVN_STA_SLICE2D_SNAP and SLICE2D
                archive=archive, window=window, mso=mso, bline=bline, mass=mass, m_int=m_int, $
                mmin=mmin, mmax=mmax, apid=apid, units=units, verbose=verbose, burst=burst, $
                dopot=dopot, sc_pot=sc_pot, vsc=vsc, showdata=showdata, erange=erange, v_esc=v_esc, $
                datplot=datplot, diag=diag, subtract=subtract, rot=rot, range=range, resolution=resolution

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

             'ARCHIVE','WINDOW','MSO','BLINE','MASS','M_INT','MMIN','MMAX','APID','UNITS','VERBOSE', $
             'BURST','DOPOT','SC_POT','VSC','SHOWDATA','ERANGE','V_ESC','DATPLOT','DIAG', $
             'SUBTRACT','ROT','RANGE','RESOLUTION']
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
  secondary = (n_elements(secondary) gt 0) ? keyword_set(secondary) : 1
  tmark = keyword_set(tmark)

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

    mvn_sta_slice2d_snap, tin, bline=bline, mass=minmax(mass), m_int=mass[1], $
                          mso=mso, rot=rot, xrange=xrange, dopot=dopot, $
                          vsc=vsc, units=units, charsize=charsize, range=range, $
                          resolution=resolution, showdata=showdata, apid=apid, /keep, $
                          v_esc=v_esc, subtract=subtract, window=Swin, erange=erange, $
                          result=result

    wset, Twin

    ctime,t,npoints=npts,/silent
    if (npts eq 2) then cursor,cx,cy,/norm,/up  ; make sure mouse button is released
    if (size(t,/type) eq 2) then keepgoing = 0

    if (tmark) then timebar, tin, /line, /transient

  endwhile

  if (~keep) then wdelete,Swin

end
