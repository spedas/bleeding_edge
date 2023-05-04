;+
;PROCEDURE:   skip
;PURPOSE:
;  Shifts the tplot plotting window forward/backward by a number of
;  orbits, days, hours, minutes, seconds, or "pages".  A page is 
;  defined as the currently displayed time range.
;
;  For maximum convenience, map this procedure to function keys:
;
;    define_key,'F7','skip,-1',/terminate
;    define_key,'F9','skip,1',/terminate
;
;USAGE:
;  skip, n
;
;INPUTS:
;       n:        Number of orbits, days, hours, minutes, seconds, or pages
;                 (positive or negative) to shift.  Default = +1.  Normally,
;                 this would be an integer, but it can also be a float.
;
;KEYWORDS:
;       PAGE:     (Default) Shift in units of the time range currently displayed.
;                 This keyword and the next 5 define the shift units.  Once you 
;                 set the units, it remains in effect until you explicitly select 
;                 different units.
;
;       DAY:      Shift in days.
;
;       HOUR:     Shift in hours.
;
;       MINUTE:   Shift in minutes.
;
;       SEC:      Shift in seconds.
;
;       ORB:      Shift in orbits.  Currently only works for MAVEN.
;
;       FIRST:    Go to the beginning of the loaded time range and
;                 plot the requested interval from there.  Do not
;                 collect $200.
;
;       LAST:     Go to end of loaded time range and plot the requested
;                 interval from there.
;
;       PERI:     If keyword FIRST or LAST is set, then go to first or last 
;                 periapsis and plot the requested interval from there.
;                 Shift units are assumed to be orbits.
;
;       APO:      If keyword FIRST or LAST is set, then go to first or last 
;                 apoapsis and plot the requested interval from there.
;                 Shift units are assumed to be orbits.
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2023-05-03 14:44:26 -0700 (Wed, 03 May 2023) $
; $LastChangedRevision: 31825 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/tplot/skip.pro $
;
;CREATED BY:    David L. Mitchell
;-
pro skip, n, orb=orb, day=day, sec=sec, minute=minute, hour=hour, page=page, $
             first=first, last=last, peri=peri, apo=apo

  common skip_com, ptime, atime, period, mode

; Determine skip units

  tplot_options, get=topt
  t = minmax(topt.trange_full)

  ok = 0
  if ((not ok) and keyword_set(sec)) then begin
    mode = 1
    ok = 1
  endif
  if ((not ok) and keyword_set(minute)) then begin
    mode = 2
    ok = 1
  endif
  if ((not ok) and keyword_set(hour)) then begin
    mode = 3
    ok = 1
  endif
  if ((not ok) and keyword_set(day)) then begin
    mode = 4
    ok = 1
  endif
  if ((not ok) and keyword_set(page)) then begin
    mode = 5
    ok = 1
  endif
  if ((not ok) and keyword_set(orb)) then begin
    mode = 6
    ok = 1
  endif
  if ((not ok) and (size(mode,/type) ne 2)) then mode = 5

  if keyword_set(peri) or keyword_set(apo) then mode = 6

; Get orbit data if needed

  if (mode eq 6) then begin
    if (size(period,/type) eq 0) then begin
      orb = mvn_orbit_num()
      period = orb.peri_time - shift(orb.peri_time,1)
      period[0] = period[1]
      ptime = orb.peri_time
      atime = orb.apo_time
    endif

    i = nn2(ptime,[t[0],mean(topt.trange),t[1]])
    p = period[i]
  endif else begin
    peri = 0
    apo = 0
  endelse

  case mode of
    1 : delta_t = 1D
    2 : delta_t = 60D
    3 : delta_t = 3600D
    4 : delta_t = 86400D
    5 : delta_t = topt.trange[1] - topt.trange[0]
    6 : begin
          delta_t = p[1]
          if keyword_set(first) then delta_t = p[0]
          if keyword_set(last) then delta_t = p[2]
        end
    else : begin
             print, "Mode = ", mode
             print, "This is impossible!"
             return
           end
  endcase

  if (size(n,/type) eq 0) then n = 1D else n = double(n[0])
  delta_t *= n

; Shift the time window

  if keyword_set(first) then begin
    t0 = t[0]
    if keyword_set(peri) then begin
      i = where(ptime gt t[0])
      t0 = ptime[i[0]]
    endif
    if keyword_set(apo) then begin
      i = where(atime gt t[0])
      t0 = atime[i[0]]
    endif
      
    tlimit, [t0, t0+abs(delta_t)]
    return
  endif

  if keyword_set(last) then begin
    t1 = t[1]
    if keyword_set(peri) then begin
      i = where(ptime lt t[1], n)
      t1 = ptime[i[n-1]]
    endif
    if keyword_set(apo) then begin
      i = where(atime lt t[1], n)
      t1 = atime[i[n-1]]
    endif

    tlimit, [t1-abs(delta_t), t1]
    return
  endif

  tlimit, topt.trange + delta_t
  return

end
