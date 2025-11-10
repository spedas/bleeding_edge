;+
;
; Timespan for Orbit 1:
;
;   spp_fld_timespan, 1
;
; Timespan for Encounter 1:
;
;   spp_fld_timespan, 1, /encounter
;
; Timespan for Perihelion 1 +/- 1 week:
;
;   spp_fld_timespan, 1, days = 7
;
; Timespan for Perihelion 1 + 1 week (asymmetric):
;
;   spp_fld_timespan, 1, days = [0,7]
;
; Timespan for Orbits 1 through 3 (note that days and encounter don't work
; with this input type for the 'orbit' parameter:
;
;   spp_fld_timespan, [1,3]
;
; Timespan for Venus flyby (note that here, the input parameter is the
; Venus flyby number, not the orbit. The reference time is time of Venus
; close approach, and days is time plus/minus closest approach. Default
; is +/- 1 day):
;
;   spp_fld_timespan, 1, /venus
;
; $LastChangedBy: pulupalap $
; $LastChangedDate: 2025-11-04 11:26:44 -0800 (Tue, 04 Nov 2025) $
; $LastChangedRevision: 33821 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SPP/fields/util/spp_fld_timespan.pro $
;-

pro spp_fld_timespan, orbit, days = days, encounter = encounter, venus = venus, $
  peri = peri, timespan = timespan, no_set = no_set
  compile_opt idl2

  if n_elements(no_set) eq 0 then no_set = 0
  if n_elements(orbit) eq 0 then orbit = 1

  mde = spp_fld_read_mde_file(spp_fld_most_recent_mde())

  if keyword_set(venus) then begin
    venus_enc = orbit

    venus_orb_all = [1, 4, 5, 7, 10, 17, 21]

    mde_orbit_num = venus_orb_all[venus_enc - 1]

    mde_orbit = mde['Orbit' + string(mde_orbit_num, format = '(I02)')]

    flyby = mde_orbit['Venus Flyby ' + string(venus_enc, format = '(I1)')]

    print, 'Venus Flyby ' + string(venus_enc, format = '(I1)'), $
      ': ', time_string(flyby)

    peri = flyby

    if n_elements(days) eq 0 then days = 1

    if n_elements(days) eq 1 then days = [days, days]

    start = flyby - days[0] * 86400d
    stop = flyby + days[1] * 86400d
  endif else begin
    if n_elements(orbit) eq 2 then begin
      orbit_info_start = (mde['Orbit' + string(orbit[0], format = '(I02)')])
      orbit_info_stop = (mde['Orbit' + string(orbit[1], format = '(I02)')])

      start = orbit_info_start['start_t']
      stop = orbit_info_stop['stop_t']

      print, 'Orbit ' + string(orbit[0], format = '(I02)'), $
        ' Start: ', time_string(start)
      print, 'Orbit ' + string(orbit[1], format = '(I02)'), $
        ' Stop:  ', time_string(stop)
    endif else begin
      orbit_info = (mde['Orbit' + string(orbit, format = '(I02)')])

      start = orbit_info['start_t']
      stop = orbit_info['stop_t']

      if n_elements(encounter) eq 1 then begin
        start = orbit_info['Solar Encounter Start']
        stop = orbit_info['Solar Encounter Stop']

        print, 'Encounter ' + string(orbit, format = '(I02)'), $
          ' Start: ', time_string(start)
        print, 'Encounter ' + string(orbit, format = '(I02)'), $
          ' Stop:  ', time_string(stop)
      endif else begin
        print, 'Orbit ' + string(orbit, format = '(I02)'), $
          ' Start: ', time_string(start)
        print, 'Orbit ' + string(orbit, format = '(I02)'), $
          ' Stop:  ', time_string(stop)
      endelse

      if n_elements(days) eq 1 or n_elements(days) eq 2 then begin
        peri = orbit_info['Perihelion']

        print, 'Perihelion ' + string(orbit, format = '(I02)'), $
          ':  ', time_string(peri)

        if n_elements(days) eq 1 then days = [days, days]

        start = peri - days[0] * 86400d
        stop = peri + days[1] * 86400d
      endif
    endelse
  endelse

  days = (stop - start) / 86400d

  timespan = [start, stop]

  if no_set eq 0 then timespan, start, days
end
