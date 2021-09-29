;+
;PROCEDURE:   time_to_periapsis
;PURPOSE:
;  Calculates the time needed for the spacecraft to go from periapsis
;  to some higher altitude(s).  NAIF conventions are used:
;
;    Periapsis is defined as the minimum distance in the orbit to the 
;    center of Mars (a.k.a. "geometric periapsis").
;
;    Altitude is calculated with respect to the IAU 2000 Mars ellipsoid
;    (R_equator = 3396.19 km, R_pole = 3376.20 km).  This is known as
;    "areodetic altitude".
;
;  The spacecraft ephemeris is calculated using maven_orbit_tplot, which
;  in turn uses SPICE.  The ephemeris is refreshed daily at 3:30 am (Pacific)
;  using the latest available kernels from NAIF.  The ephemeris coverage
;  extends from Mars orbit insertion to about eight weeks into the future.
;
;USAGE:
;  time_to_periapsis, h
;
;INPUTS:
;       h:             An array of altitudes (units = km).
;
;KEYWORDS:
;       TIME:          Reference time for selecting the nearest orbit.
;                      Can be in any format accepted by time_double.
;                      If you supply an array of times, only the first
;                      element is used.  If not specified, the current
;                      UTC is used.
;
;       RESULT:        Named variable to hold the result structure.
;
;       VERBOSE:       Verbosity level.  See dprint.pro.
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2020-10-26 15:28:30 -0700 (Mon, 26 Oct 2020) $
; $LastChangedRevision: 29295 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/maven_orbit_tplot/time_to_periapsis.pro $
;
;CREATED BY:    David L. Mitchell
;-
pro time_to_periapsis, h, time=tref, result=dat, verbose=verbose

  @maven_orbit_common

; Check inputs

  nh = n_elements(h)
  if (nh lt 1) then begin
    print,"You must specify one or more altitudes."
    return
  endif

  if keyword_set(tref) then tref = time_double(tref[0]) else tref = systime(/utc,/sec)

  if not keyword_set(verbose) then verbose=0

; Load ephemeris (if necessary)

  R_m = 3389.50D  ; volumetric mean radius of Mars
  oneday = 86400D
  tsp = [tref - oneday, tref + oneday]

  if (size(time,/type) ne 5) then begin
    timespan, tsp
    maven_orbit_tplot, /loadonly, /shadow, datum='ell', verbose=verbose, success=ok
    if (not ok) then return
  endif

  if ((tsp[0] lt min(time)) or (tsp[1] gt max(time))) then begin
    timespan, tsp
    maven_orbit_tplot, /loadonly, /shadow, datum='ell', verbose=verbose, success=ok
    if (not ok) then return
    if ((tsp[0] lt min(time)) or (tsp[1] gt max(time))) then begin
      print,"Ephemeris end time: " + time_string(max(time))
      print,"Insufficient ephemeris coverage for reference time: " + $
            time_string(tref)
      return
    endif
  endif

  if (datum ne 'ellipsoid') then begin
    timespan, tsp
    maven_orbit_tplot, /loadonly, /shadow, datum='ell', verbose=verbose, success=ok
    if (not ok) then return
  endif

  get_data,'alt',data=alt,index=j
  if (j eq 0) then begin
    timespan, tsp
    maven_orbit_tplot, /loadonly, /shadow, datum='ell', verbose=verbose, success=ok
    if (not ok) then return
    get_data,'alt',data=alt,index=j
    if (j eq 0) then begin
      print,"Could not load ephemeris."
      return
    endif
  endif

  r = sqrt(total((double(state.mso_x)/R_m)^2D,2))
  str_element, alt, 'z', r, /add

; Find periapsis closest to reference time

  indx = where(alt.y lt 400.)
  dt = min(abs(alt.x[indx] - tref), j)
  i = indx[j]
  dy = (alt.y - shift(alt.y,1))[i]
  if (dy lt 0.) then begin
    t0 = alt.x[i]
    t1 = t0 + 1200D
  endif else begin
    t1 = alt.x[i]
    t0 = t1 - 1200D
  endelse

  indx = where((alt.x ge t0) and (alt.x le t1), count)
  t = t0 + dindgen(round(t1 - t0) + 1L)
  y = spline(alt.x[indx], alt.y[indx], t)
  z = spline(alt.x[indx], alt.z[indx], t)
  dt = min(z, j)
  ptime = t[j]  ; periapsis time to the nearest second
  palt = y[j]   ; periapsis altitude (km)

; Find preceding apoapsis

  get_data,'period',data=operiod
  dt = min(abs(operiod.x - tref), i)
  t0 = ptime - 0.55D*(operiod.y[i] * 3600D)

  indx = where((alt.x ge t0) and (alt.x le ptime), count)
  t = t0 + dindgen(round(ptime - t0) + 1L)
  y = spline(alt.x[indx], alt.y[indx], t)
  z = spline(alt.x[indx], alt.z[indx], t)
  dt = max(z, j)
  atime = t[j]  ; apoapsis time to the nearest second
  aalt = y[j]   ; apoapsis altitude (km)

; Get time to periapsis

  print,""
  print,"Periapsis time: ",time_string(ptime)
  print,"Periapsis altitude: ",round(palt),format='(a,i5)'
  print,""
  print,"Apoapsis time: ",time_string(atime)
  print,"Apoapsis altitude: ",round(aalt),format='(a,i5)'
  print,""
  print,"Altitude      Time to periapsis"
  print,"  [km]        [sec]  [hh:mm:ss]"
  print,"-------------------------------"

  indx = where((alt.x ge (atime - 60D)) and (alt.x le (ptime + 60D)))
  t = atime + dindgen(round(ptime - atime) + 1L)
  y = spline(alt.x[indx], alt.y[indx], t)

  dat = {alt   : h                            , $
         dt    : replicate(!values.d_nan, nh) , $
         ptime : ptime                        , $
         atime : atime                        , $
         palt  : palt                         , $
         aalt  : aalt                            }

  for i=0,(n_elements(h)-1) do begin
    if ((h[i] ge palt) and (h[i] le aalt)) then begin
      dh = min(abs(y - h[i]), j)
      dat.dt[i] = ptime - t[j]
      hhmmss = strmid(time_string(dat.dt[i]),11,8)
      print, round(h[i]), round(dat.dt[i]), hhmmss, format='(i6,6x,i6,4x,a)'
    endif else begin
      print, round(h[i]), format='(i6,10x,"out of range")'
    endelse
  endfor

  print,"-------------------------------"
  print,""

  return

end
