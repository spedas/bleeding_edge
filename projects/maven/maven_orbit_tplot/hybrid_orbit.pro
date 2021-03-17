;+
;PROCEDURE:   hybrid_orbit
;PURPOSE:
;  Plots the MAVEN orbit over a hybrid model of the Mars-solar wind interaction.
;
;USAGE:
;  hybrid_orbit, lon, lat
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
;       MONITOR:   Place snapshot window in this monitor.  Only works if
;                  monitor configuration is defined (see putwin.pro).
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2021-03-02 11:51:00 -0800 (Tue, 02 Mar 2021) $
; $LastChangedRevision: 29730 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/maven_orbit_tplot/hybrid_orbit.pro $
;
;CREATED BY:	David L. Mitchell  04-02-03
;-
pro hybrid_orbit, lon, lat, lon_sc, lat_sc, psym=psym, lstyle=lstyle, $
                 color=color, reset=reset, xy=xy, xz=xz, sc=sc, flip=flip, $
                 monitor=monitor

  common hybrid_orb_com, img, ppos

  twin = !d.window
  owin = 31
  csize = 1.2

  if keyword_set(flip) then begin
    fname = file_which('hybrid_flip.bmp')
    yrange = [-4.35, 4.42]
  endif else begin
    fname = file_which('hybrid.bmp')
    yrange = [-4.42, 4.35]
  endelse

  if (size(psym,/type) eq 0)   then psym = 1   else psym = fix(psym)
  if (size(lstyle,/type) eq 0) then lstyle = 0 else lstyle = fix(lstyle)
  if (size(color,/type) eq 0)  then color = 2  else color = fix(color)

  a = 2.0
  phi = findgen(49)*(2.*!pi/49)
  usersym,a*cos(phi),a*sin(phi),/fill

  if (psym gt 7) then psym = 8

  if ((size(img,/type) eq 0) or keyword_set(reset)) then begin

    if (fname eq '') then begin
      print, "Hybrid model image not found!"
      return
    endif
    img = read_bmp(fname,/rgb)
    sz = size(img)

    xoff = round(34.*csize)
    yoff = round(30.*csize)
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

    putwin, owin, mnum, xsize=xsize, ysize=ysize, dx=-983, dy=-10

    px = [0.0, 1.0] * !d.x_vsize + xoff + 16
    py = [0.0, 1.0] * !d.y_vsize + yoff + 10
    ppos=[px[0],py[0],px[0]+sz[2]-1,py[0]+sz[3]-1]
  endif

  wset,owin
  tv,img,ppos[0],ppos[1],/true

  plot,[-10.,-12.],[-10.,-12.],position=ppos,/device, $
    xrange=[-3.74,3.7],yrange=yrange,xticks=0,xminor=0, $
    yticks=0,yminor=0,/xstyle,/ystyle,/noerase,charsize=csize, $
    xtitle = 'X (Rm)', ytitle = 'Z (Rm)'

  oplot,[lon],[lat],psym=psym,color=color,linestyle=lstyle,thick=2,symsize=1.4

  if (size(lon_sc,/type) gt 0) then oplot, [lon_sc], [lat_sc], psym=8, color=0

  wset,twin

  return

end
