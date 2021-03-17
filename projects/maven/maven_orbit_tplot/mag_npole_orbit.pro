;+
;PROCEDURE:   mag_npole_orbit
;PURPOSE:
;  Plots a set of [longitude,latitude] positions over a polar MAG map.
;
;USAGE:
;  mag_Npole_orbit, lon, lat
;
;INPUTS:
;       lon:       East longitude (0 to 360 degrees).
;
;       lat:       Latitude (-90 to 90 degrees).
;
;                  Note: lon and lat must have the same number
;                        of elements.
;
;KEYWORDS:
;       PSYM:      Symbol type (same as for plot).
;
;       LSTYLE:    Line style (same as for plot).
;
;       COLOR:     Line/symbol color (same as for plot).
;
;       RESET:     Read in the MAG-MOLA image and calculate the
;                  plot size and position.
;
;       NOERASE:   Do not refresh the plot for each [lon, lat] point.
;
;       TERMINATOR: Overlay the terminator.
;
;       SHADOW:     If TERMINATOR is set, specifies which "terminator" to
;                   plot.
;                      0 : Optical shadow boundary at surface.
;                      1 : Optical shadow boundary at s/c altitude.
;                      2 : EUV shadow boundary at s/c altitude.
;
;       MONITOR:   Place snapshot window in this monitor.  Only works if
;                  monitor configuration is defined (see putwin.pro).
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2021-02-28 12:46:30 -0800 (Sun, 28 Feb 2021) $
; $LastChangedRevision: 29710 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/maven_orbit_tplot/mag_npole_orbit.pro $
;
;CREATED BY:	David L. Mitchell  04-02-03
;-
pro mag_npole_orbit, lon, lat, psym=psym, lstyle=lstyle, color=color, $
                     reset=reset, noerase=noerase, title=title, $
                     terminator=ttime, shadow=shadow, alt=alt, monitor=monitor

  common magpole_orb_com, img, ppos
  @putwin_common

  twin = !d.window
  owin = 27
  csize = 1.2

  if not keyword_set(title) then title = ''
  if (~size(psym,/type)) then psym = 1 else psym = fix(psym)
  if (~size(lstyle,/type)) then lstyle = 0 else lstyle = fix(lstyle)
  if (~size(color,/type)) then color = 2 else color = fix(color)
  if not keyword_set(noerase) then eflg = 1 else eflg = 0
  if keyword_set(ttime) then doterm = 1 else doterm = 0
  if keyword_set(shadow) then sflg = shadow else sflg = 0

  if (psym gt 7) then psym = 8
  a = 0.8
  phi = findgen(49)*(2.*!pi/49)
  usersym,a*cos(phi),a*sin(phi),/fill

  if ((size(img,/type) eq 0) or keyword_set(reset)) then begin
    fname = file_which('MAG_Npole.jpg')

    if (fname eq '') then begin
      print, "MAG_Npole.jpg not found!"
      return
    endif
    read_jpeg, fname, img
    sz = size(img)

    xoff = 0
    yoff = 0
    xsize = sz[2] + (2*xoff)
    ysize = sz[3] + (2*yoff)

    undefine, mnum
    if (size(monitor,/type) gt 0) then begin
      if (size(windex,/type) eq 0) then putwin, /config $
                                   else if (windex eq -1) then putwin, /config
      mnum = fix(monitor[0])
    endif else begin
      if (size(secondarymon,/type) gt 0) then mnum = secondarymon
    endelse

    putwin, owin, mnum, xsize=xsize, ysize=ysize, dx=-10, dy=-10

    px = [0.0, 1.0] * !d.x_vsize + xoff
    py = [0.0, 1.0] * !d.y_vsize + yoff
    ppos=[px[0],py[0],px[0]+sz[2]-1,py[0]+sz[3]-1]
    
    eflg = 1
  endif

  wset,owin

  if (eflg) then tv,img,ppos[0],ppos[1],/true

  plot,[-100.],[-100.],position=[22,112,501,590],/device, $
    xrange=[-35,35],yrange=[-35,35],xticks=6,xminor=3, $
    yticks=6,yminor=3,xstyle=5,ystyle=5,/noerase,charsize=csize, $
    xtitle = 'This Way', ytitle = 'That Way', title=title
  
  if (doterm) then begin
    mvn_mars_terminator, ttime, result=tdat, shadow=sflg
    r = 90. - tdat.tlat
    phi = (tdat.tlon - 90.)*!dtor
    oplot,r*cos(phi),r*sin(phi),color=1,psym=4,symsize=1
  endif
  
  r = 90. - lat
  phi = (lon - 90.)*!dtor
  x = r*cos(phi)
  y = r*sin(phi)

  oplot,[x],[y],psym=psym,color=color,linestyle=lstyle,thick=2,symsize=1.4
  if keyword_set(alt) then xyouts,x+1,y+1,string(round(alt),format='(i4)'),color=color,charsize=1.2

  wset,twin

  return

end
