;+
;procedure: spd_epv00
;
;Purpose: Earth heliocentric position and velocity using the ERFA EPV00
;         simplified VSOP2000 solution.
;
;Inputs:
;  time: SPEDAS Unix time (UTC), scalar or array.  With /JD_TT, Julian date TT.
;
;Outputs:
;  position: Sun-to-Earth J2000 equatorial position, AU, [n,3].
;  velocity: Sun-to-Earth J2000 equatorial velocity, AU/day, [n,3].
;
;Keywords:
;  JD_TT: input is Julian date TT rather than SPEDAS Unix time.
;  STATUS: 0 where date is within 1900-2100; 1 otherwise.
;
;Notes:
;  TT can be used in place of TDB for this model.  The ERFA comparison with
;  DE405 over 1900-2100 gives 3.7 km RMS and 11.2 km maximum position error.
;  Only the heliocentric portion of ERFA eraEpv00 is included.
;-
function spd_epv00_tt_minus_utc, time
  compile_opt idl2
  ; Effective dates after the initial TAI-UTC=10 s on 1972-01-01.
  leap_dates = time_double(['1972-07-01', '1973-01-01', '1974-01-01', $
    '1975-01-01', '1976-01-01', '1977-01-01', '1978-01-01', '1979-01-01', $
    '1980-01-01', '1981-07-01', '1982-07-01', '1983-07-01', '1985-07-01', $
    '1988-01-01', '1990-01-01', '1991-01-01', '1992-07-01', '1993-07-01', $
    '1994-07-01', '1996-01-01', '1997-07-01', '1999-01-01', '2006-01-01', $
    '2009-01-01', '2012-07-01', '2015-07-01', '2017-01-01'])
  tai_minus_utc = replicate(10d, n_elements(time))
  for i=0, n_elements(leap_dates)-1 do begin
    indices = where(time ge leap_dates[i], count)
    if count gt 0 then tai_minus_utc[indices] = 11d + i
  endfor
  return, tai_minus_utc + 32.184d
end


pro spd_epv00, time, position, velocity, JD_TT=JD_TT, STATUS=status
  compile_opt idl2

  if n_params() lt 3 then message, 'Syntax: spd_epv00, time, position, velocity'

  ntime = n_elements(time)
  if keyword_set(JD_TT) then begin
    t = (double(time) - 2451545d) / 365.25d
  endif else begin
    utc = double(time)
    jd_tt = 2440587.5d + (utc+spd_epv00_tt_minus_utc(utc))/86400d
    t = (jd_tt-2451545d)/365.25d
  endelse
  t = reform(t, ntime)
  status = byte(abs(t) gt 100d)

  c = spd_epv00_coefficients()
  position_ecl = dblarr(ntime, 3)
  velocity_ecl = dblarr(ntime, 3)
  for component=0,2 do begin
    c0 = c.(component)
    c1 = c.(component+3)
    c2 = c.(component+6)
    for sample=0L, ntime-1L do begin
      ts = t[sample]
      ts2 = ts*ts

      p = c0[1,*] + c0[2,*]*ts
      xyz = total(c0[0,*]*cos(p), /double)
      xyzd = -total(c0[0,*]*c0[2,*]*sin(p), /double)

      ct = c1[2,*]*ts
      p = c1[1,*] + ct
      cp = cos(p)
      xyz += total(c1[0,*]*ts*cp, /double)
      xyzd += total(c1[0,*]*(cp-ct*sin(p)), /double)

      ct = c2[2,*]*ts
      p = c2[1,*] + ct
      cp = cos(p)
      xyz += total(c2[0,*]*ts2*cp, /double)
      xyzd += total(c2[0,*]*ts*(2d*cp-ct*sin(p)), /double)

      position_ecl[sample,component] = xyz
      velocity_ecl[sample,component] = xyzd/365.25d
    endfor
  endfor

  ; Orient the analytical ecliptic model to DE405/BCRS, matching ERFA.
  position = position_ecl
  velocity = velocity_ecl
  position[*,0] = position_ecl[*,0] + 0.000000211284d*position_ecl[*,1] - $
    0.000000091603d*position_ecl[*,2]
  position[*,1] = -0.000000230286d*position_ecl[*,0] + $
    0.917482137087d*position_ecl[*,1] - 0.397776982902d*position_ecl[*,2]
  position[*,2] = 0.397776982902d*position_ecl[*,1] + $
    0.917482137087d*position_ecl[*,2]
  velocity[*,0] = velocity_ecl[*,0] + 0.000000211284d*velocity_ecl[*,1] - $
    0.000000091603d*velocity_ecl[*,2]
  velocity[*,1] = -0.000000230286d*velocity_ecl[*,0] + $
    0.917482137087d*velocity_ecl[*,1] - 0.397776982902d*velocity_ecl[*,2]
  velocity[*,2] = 0.397776982902d*velocity_ecl[*,1] + $
    0.917482137087d*velocity_ecl[*,2]
end
