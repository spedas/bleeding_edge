;+
;PROCEDURE:   mvn_cio_bar
;PURPOSE:
;  Creates a color bar showing when the cold ion configuration geometry is
;  partially of completely achieved:
;
;      blank  = neither is optimized or s/c not in CIO region of space
;      blue   = only SWEA is optimized
;      yellow = only STATIC is optimized
;      red    = both SWEA and STATIC are optimized
;
;  Assumes that SPICE is loaded and maven_orbit_tplot has been run.
;
;USAGE:
;  mvn_cio_bar
;
;INPUTS:
;
;KEYWORDS:
;       PANS:          Tplot panel name created.
;
;       COLOR_TABLE:   Color table for color bar.  Default = 43 (custom rainbow).
;                      This works for all color table files (STD, SPP, CSV).
;
;       COLOR_REVERSE: If set, reverse color table.  Default = 0 (no).
;
;       DELTA_T:       Time resolution for the bar.  Default = 10 sec.
;
;       KEY:           Print the color key and return.
;
;       Note: Color table is internal to the tplot variable and does not affect
;             the user's environment.
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2026-09-16 16:13:22 -0700 (Wed, 16 Sep 2026) $
; $LastChangedRevision: 34904 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/maven_orbit_tplot/mvn_cio_bar.pro $
;
;CREATED BY:    David L. Mitchell
;-
pro mvn_cio_bar, pans=bname, color_table=ctab, color_reverse=crev, delta_t=dt, key=key

  if keyword_set(key) then goto, printkey

; Color table and time resolution

  ctab = (n_elements(ctab) eq 0) ? 43 : fix(ctab[0])
  crev = (n_elements(crev) eq 0) ?  0 : fix(crev[0])
  dt = (n_elements(dt) eq 0) ? 10D : double(dt[0])

; Sun direction in the SWEA and APP frames

  mvn_sundir, frame=['swe','app'], /pol, dt=dt
  get_data, 'Sun_SWEA_The', data=sthe_swe
  get_data, 'Sun_APP_The', data=sthe_app

; MSO ram direction in the APP frame

  mvn_ramdir, frame='app', /mso, /pol, dt=dt
  get_data, 'V_sc_APP_The', data=rthe_app

; Get the altitude and MSO X position of the spacecraft

  eph = maven_orbit_eph()
  alt = spline(eph.time, eph.alt, sthe_swe.x)
  mso_x = spline(eph.time, eph.mso_x[*,0], sthe_swe.x)

; Test for the CIO configuration

  npts = n_elements(sthe_swe.x)
  y = replicate(!values.f_nan,npts,2)   ; blank = neither is optimized

  indx = where(abs(sthe_swe.y - 45) lt 5, count)
  if (count gt 0) then y[indx,*] = 1.   ; blue = only SWEA is optimized

  indx = where((abs(sthe_app.y) le 5) and (abs(rthe_app.y) le 10), count)
  if (count gt 0) then y[indx,*] = 2.   ; yellow = only STATIC is optimized (no twist)

  indx = where((abs(sthe_swe.y - 45) lt 5) and (abs(sthe_app.y) le 5) and $
               (abs(rthe_app.y) le 10), count)
  if (count gt 0) then y[indx,*] = 3.   ; red = both STATIC and SWEA are optimized

  indx = where((alt lt 1000.) or (mso_x gt 0.), count)
  if (count gt 0L) then y[indx,*] = !values.f_nan  ; spacecraft not in CIO region of space

; Make the CIO bar

  bname = 'mvn_cio_bar'
  store_data,bname,data={x:sthe_swe.x, y:y, v:[0,1]}
  ylim,bname,0,1,0
  zlim,bname,0,3,0
  options,bname,'color_table',ctab
  options,bname,'color_reverse',crev
  options,bname,'spec',1
  options,bname,'panel_size',0.05
  options,bname,'ytitle',''
  options,bname,'yticks',1
  options,bname,'yminor',1
  options,bname,'no_interp',1
  options,bname,'xstyle',4
  options,bname,'ystyle',4
  options,bname,'no_color_scale',1

; Print out the color key

printkey:

  print,''
  print,'Cold Ion Outflow bar color key:'
  print,'  blank  = neither is optimized or s/c not in CIO region of space'
  print,'  blue   = only SWEA is optimized'
  print,'  yellow = only STATIC is optimized'
  print,'  red    = both SWEA and STATIC are optimized'
  print,''

end
