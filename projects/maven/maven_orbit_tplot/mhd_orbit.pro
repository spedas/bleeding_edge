;+
;PROCEDURE:   mhd_orbit
;PURPOSE:
;  Plots 
;
;USAGE:
;  mhd_orbit, lon, lat
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
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2014-10-31 14:24:42 -0700 (Fri, 31 Oct 2014) $
; $LastChangedRevision: 16108 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/maven_orbit_tplot/mhd_orbit.pro $
;
;CREATED BY:	David L. Mitchell  04-02-03
;-
pro mhd_orbit, lon, lat, lon_sc, lat_sc, psym=psym, lstyle=lstyle, $
                 color=color, reset=reset, xy=xy, xz=xz, sc=sc

  common mhd_orb_com, img, ppos

  twin = !d.window
  owin = 30
  csize = 1.2
  
  if (size(psym,/type) eq 0)   then psym = 1   else psym = fix(psym)
  if (size(lstyle,/type) eq 0) then lstyle = 0 else lstyle = fix(lstyle)
  if (size(color,/type) eq 0)  then color = 2  else color = fix(color)

  a = 2.0
  phi = findgen(49)*(2.*!pi/49)
  usersym,a*cos(phi),a*sin(phi),/fill

  if (psym gt 7) then psym = 8

  if ((size(img,/type) eq 0) or keyword_set(reset)) then begin
    if keyword_set(xz) then fname = file_which('mhd_xz_c.bmp') $
                       else fname = file_which('mhd_xy_c.bmp')

    if (fname eq '') then begin
      print, "MHD model image not found!"
      return
    endif
    img = read_bmp(fname,/rgb)
    sz = size(img)

    xoff = round(34.*csize)
    yoff = round(30.*csize)
    i = sz[2] + (2*xoff)
    j = sz[3] + (2*yoff)

    window,owin,xsize=i,ysize=j

    px = [0.0, 1.0] * !d.x_vsize + xoff + 16
    py = [0.0, 1.0] * !d.y_vsize + yoff + 10
    ppos=[px[0],py[0],px[0]+sz[2]-1,py[0]+sz[3]-1]
  endif

  wset,owin
  tv,img,ppos[0],ppos[1],/true

  if keyword_set(xz) then ytitle = 'Z (Rm)' else ytitle = 'Y (Rm)'

  plot,[-10.,-12.],[-10.,-12.],position=ppos,/device, $
    xrange=[-4,2],yrange=[-4,4],xticks=3,xminor=5, $
    yticks=4,yminor=5,/xstyle,/ystyle,/noerase,charsize=csize, $
    xtitle = 'X (Rm)', ytitle = ytitle

  oplot,[lon],[lat],psym=psym,color=color,linestyle=lstyle,thick=2,symsize=1.4

  if (size(lon_sc,/type) gt 0) then begin
    oplot, [lon_sc], [lat_sc], psym=8, color=0
  endif

  wset,twin

  return

end
