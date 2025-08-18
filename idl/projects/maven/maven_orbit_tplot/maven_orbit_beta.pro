;+
;PROCEDURE:   maven_orbit_beta
;PURPOSE:
;  Calculates the MAVEN orbit beta angle, which is the angle between
;  the Sun direction and the orbit plane [-90 to 90 degrees].  When beta
;  is positive, the orbit normal (P x V, where P is position and V is 
;  velocity) points toward the Sun-facing hemisphere.
;
;  This routine requires SPICE.
;
;USAGE:
;  maven_orbit_beta
;
;INPUTS:
;       time:      [Optional] One or more UTC times, in any format accepted by
;                  time_double.  If not specified and MISSION is not set, then 
;                  try to get the periapsis times for all MAVEN orbits within 
;                  the tplot timespan (TRANGE_FULL).
;
;KEYWORDS:
;       RESULT:    Structure containing UTC (x) and beta angle (y).  Works as a
;                  tplot variable.
;
;       MISSION:   Ignore the time input, and calculate beta at periapsis for
;                  every orbit in the mission that has SPK coverage (including 
;                  up to several weeks into the future).
;
;                  Warning: This will likely require SPICE to be reinitialized.
;
;       TPLOT:     Store the tplot variable and set some tplot options.
;                  Default = 1.
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2021-09-15 11:55:02 -0700 (Wed, 15 Sep 2021) $
; $LastChangedRevision: 30296 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/maven_orbit_tplot/maven_orbit_beta.pro $
;-
pro maven_orbit_beta, time, result=result, mission=mission, tplot=tplot

  result = 0

; Initialize orbit numbers (quietly)

  dprint,' ', getdebug=bug, dlevel=4
  dprint,' ', setdebug=0, dlevel=4
  odat = mvn_orbit_num()
  dprint,' ', setdebug=bug, dlevel=4

; Process keywords and make sure SPICE coverage is sufficient

  if (size(tplot,/type) eq 0) then tplot = 1

  if keyword_set(mission) then begin
    t = odat.peri_time
    onum = odat.num
    mvn_spice_stat, summary=sinfo, check=minmax(t), /silent
    if (~sinfo.spk_check) then begin
      print,"SPK kernels for the entire mission must be loaded."
      mvn_swe_spice_init, trange=minmax(t), /nock
      mvn_spice_stat, summary=sinfo, check=minmax(t), /silent
      indx = where((t ge sinfo.spk_trange[0]) and (t le sinfo.spk_trange[1]), count)
      if (count eq 0L) then begin
        print,"No SPK coverage, which should be impossible, so check your SPICE configuration."
        return
      endif
      t = t[indx]
    endif
  endif else begin
    if (n_elements(time) eq 0) then begin
      tplot_options, get=topt
      time = topt.trange_full
      if (min(time) lt 1D) then begin
        print,"No time specified, and tplot timespan not set."
        print,"  -> You must provide a time."
        return
      endif
      indx = where((odat.peri_time ge time[0]) and (odat.peri_time le time[1]), count)
      if (count eq 0L) then begin
        print,"No MAVEN orbits within the tplot timespan."
        return
      endif
      time = odat[indx].peri_time
    endif
    t = time_double(time)
    mvn_spice_stat, summary=sinfo, check=t, /silent
    if (~sinfo.spk_exists) then begin
      print,"No SPK kernels are loaded."
      print,"  -> Initialize SPICE before using this routine."
      return
    endif
    if (~sinfo.spk_check) then begin
      print,"Insufficient SPK coverage for the requested time range."
      print,"  -> Reinitialize SPICE to include your time range."
      return
    endif
    onum = mvn_orbit_num(time=t)
  endelse

; MAVEN orbit normal (unit vector) in MME_2000 frame

  nt = n_elements(t)
  tstring = time_string(t,prec=3)
  to_frame = mvn_frame_name('mme')
  cspice_str2et, tstring, et
  cspice_spkezr, 'MAVEN', et, to_frame, 'NONE', 'Mars', state, ltime
  P = state[0:2,*]
  V = state[3:5,*]
  Phat = P/(replicate(1D,3) # sqrt(total(P*P,1)))
  Vhat = V/(replicate(1D,3) # sqrt(total(V*V,1)))

  N = dblarr(3,nt)
  for i=0L,(nt-1L) do N[*,i] = crossp(Phat[*,i], Vhat[*,i])
  Nhat = N/(replicate(1D,3) # sqrt(total(N*N,1)))

; Sun direction (unit vector) in MME_2000 frame

  from_frame = mvn_frame_name('mso')
  Smso = [1D, 0D, 0D] # replicate(1D, nt)
  S = spice_vector_rotate(Smso, t, from_frame, to_frame, check='MAVEN_SPACECRAFT')
  Shat = S/(replicate(1D,3) # sqrt(total(S*S,1)))

; Beta angle

  NdotS = reform(total(Nhat*Shat,1))
  beta = asin(NdotS < 1D)*!radeg

  result = {x:[t], y:[beta], onum:onum, x_note:'UTC', y_note:'orbit beta angle'}

  if keyword_set(tplot) then begin
    store_data, 'beta', data=result
    options, 'beta', 'ytitle', 'Orbit Beta (deg)'
    if keyword_set(mission) then begin
      ylim, 'beta', -90, 90, 0
      options, 'beta', 'yticks', 2
      options, 'beta', 'yminor', 3
      options, 'beta', 'constant', [0.]
    endif else options, 'beta', 'ynozero', 1
  endif

end
