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
;                 different units.  The units are all minimum matching, so you only
;                 need to specify the first 1 or 2 letters.
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
;       TREF:     Reference time to start (instead of the beginning of the
;                 loaded time range).
;
;       UNITS:    Skip units to use after the first call.
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2024-08-07 08:03:17 -0700 (Wed, 07 Aug 2024) $
; $LastChangedRevision: 32783 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/tplot/skip.pro $
;
;CREATED BY:    David L. Mitchell
;-
pro skip, n, orb=orb, day=day, sec=sec, minute=minute, hour=hour, page=page, $
             first=first, last=last, peri=peri, apo=apo, tref=tref, units=units

  common skip_com, ptime, atime, period, mode, torb

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
    refresh = size(torb,/type) ne 5
    if (~refresh) then if (systime(/ut,/sec) gt torb) then refresh = 1B

    if (refresh) then begin
      print, "Getting orbit numbers ... ", format='(a,$)'
      dprint,' ', getdebug=bug, dlevel=4
      dprint,' ', setdebug=0, dlevel=4
      odat = mvn_orbit_num()
      dprint,' ', setdebug=bug, dlevel=4

      period = odat.peri_time - shift(odat.peri_time,1)
      period[0] = period[1]
      ptime = odat.peri_time
      atime = odat.apo_time

      print, "done"
      torb = systime(/ut,/sec) + 86400D
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

; Set the units for the next time window (optional)

  if (size(units,/type) eq 7) then begin
    unames = ['SEC','MINUTE','HOUR','DAY','PAGE','ORB']
    i = strmatch(unames, '*'+units[0]+'*', /fold)
    case (total(i)) of
       0   : print, "New units '",units[0],"' not recognized"
       1   : mode = (where(i eq 1))[0] + 1
      else : print, "New units '",units[0],"' ambiguous: ", unames[where(i eq 1)]
    endcase
  endif

; Shift the time window

  if (n_elements(tref) gt 0L) then begin
    t0 = time_double(tref[0])      
    tlimit, [t0, t0+abs(delta_t)]
    return
  endif

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
