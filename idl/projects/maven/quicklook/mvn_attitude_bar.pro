;+
;PROCEDURE:   mvn_attitude_bar
;PURPOSE:
;  Creates a horizontal color bar for tplot, where the spacecraft attitude
;  is coded by color:
;
;    orange = Sun point
;    blue   = Earth point
;    green  = Fly +/- Y
;    red    = Fly-Z (including up and down variants)
;    purple = Fly+Z (including up and down variants)
;
;USAGE:
;  mvn_attitude_bar
;
;INPUTS:
;       none
;
;KEYWORDS:
;       FORCE:    Ignore the SPICE checks and forge ahead anyway.
;
;       KEY:      Print out the color key and return.
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2024-01-08 16:12:18 -0800 (Mon, 08 Jan 2024) $
; $LastChangedRevision: 32344 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/quicklook/mvn_attitude_bar.pro $
;
;CREATED BY:    David L. Mitchell
;-
pro mvn_attitude_bar, force=force, key=key

  noguff = keyword_set(force)

  if keyword_set(key) then goto, printkey

; Determine when the HGA points to the Sun or Earth

  mvn_sundir, dt=1D, frame='spacecraft', /pol, force=noguff, success=ok
  if (~ok and ~noguff) then return

  get_data, 'Sun_PL_The', data=sth, index=i
  if (i eq 0) then begin
    print, 'Missing tplot variable (Sun_PL_The): mvn_sundir not successful.'
    return
  endif
  npts = n_elements(sth.x)
  sun_th = sth.y

  et = time_ephemeris(sth.x)
  cspice_spkpos, 'Earth', et, 'MAVEN_MSO', 'NONE', 'Mars', pearth, ltime
  pearth = transpose(pearth)/1.495978707d8
  xearth = pearth[*,0]/sqrt(total(pearth*pearth,2))
  earth_th = 90D - acos(xearth)*!radeg  ; elongation of Earth from Mars

  y = replicate(!values.f_nan,npts,2)
  indx = where(abs(sun_th - 90.) lt 0.5, count)      ; HGA pointing at Sun
  if (count gt 0L) then y[indx,*] = 8.
  indx = where(abs(sun_th - earth_th) lt 0.5, count) ; HGA pointing at Earth
  if (count gt 0L) then y[indx,*] = 3.

; Identify Fly+-Y and Fly+-Z

  mvn_ramdir, minmax(sth.x) + [-10D, 10D], dt=1D, frame='spacecraft', pans=rampan, force=noguff, success=ok
  if (~ok and ~noguff) then return
  get_data, rampan[0], data=ram, index=i
  if (i gt 0) then begin
    indx = where(ram.x ge min(sth.x) and ram.x le max(sth.x), count)
    ram_x = ram.x[indx]
    ram_y = ram.y[indx,*]
    ram_v = sqrt(total(ram_y^2.,2))
    ram_y /= (ram_v # replicate(1.,3))

    z_phi = acos(ram_y[*,2])*!radeg

    get_data, 'alt', data=alt
    alt = spline(alt.x, alt.y, sth.x)

    indx = where((alt lt 800.) and (abs(abs(ram_y[*,1]) - 1.) lt 0.001), count)
    if (count gt 0L) then y[indx,*] = 4.85  ; Fly-Y or Fly+Y

    indx = where((alt lt 800.) and (abs(ram_y[*,1]) lt 0.001) and (z_phi gt 100.), count)
    if (count gt 0L) then y[indx,*] = 10.   ; Fly-Z

    indx = where((alt lt 800.) and (abs(ram_y[*,1]) lt 0.001) and (z_phi lt 80.), count)
    if (count gt 0L) then y[indx,*] = 1.4   ; Fly+Z
  endif

  bname = 'mvn_att_bar'
  store_data,bname,data={x:sth.x, y:y, v:[0,1]}
  ylim,bname,0,1,0
  zlim,bname,0,10,0
  options,bname,'spec',1
  options,bname,'panel_size',0.05
  options,bname,'ytitle',''
  options,bname,'yticks',1
  options,bname,'yminor',1
  options,bname,'x_no_interp',1
  options,bname,'xstyle',4
  options,bname,'ystyle',4
  options,bname,'no_color_scale',1
  options,bname,'color_table',43

; Print out the color key

printkey:

  print,''
  print,'Attitude bar color key:'
  print,'  orange = Sun point'
  print,'  blue   = Earth point'
  print,'  green  = Fly +/- Y'
  print,'  red    = Fly-Z (including up and down variants)'
  print,'  purple = Fly+Z (including up and down variants)'
  print,''

end
