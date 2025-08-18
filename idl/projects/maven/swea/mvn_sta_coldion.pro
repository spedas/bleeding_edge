;+
;PROCEDURE:   mvn_sta_coldion
;PURPOSE:
;  Loads STATIC data and calculates density, temperature, and velocity of
;  H+, O+, and O2+.  The data are corrected for spacecraft potential and
;  spacecraft motion when transforming to the MSO frame.  Thermal electron
;  density from LPW is included as a check on the total ion density
;  measured by STATIC.  Topology information based on the two-stream shape
;  parameter (Xu) and PAD score (Weber) is attached to each measurement.
;  A variety of ephemeris and geometry information are also included.
;
;  This routine uses STATIC code developed by J. McFadden.
;
;  This routine uses velocity moment code developed by Y. Harada and
;  T. Hara.
;
;USAGE:
;  mvn_sta_coldion
;
;INPUTS:
;    None:          Data are loaded based on timespan.
;
;KEYWORDS:
;    BEAM:          Use the beam version of the moment calculation.  Provides
;                   the most accurate densities around periapsis.  Does not
;                   work at all away from periapsis.
;
;    POTENTIAL:     Use the composite spacecraft potential determined from
;                   SWEA, STATIC, and LPW.  See mvn_scpot.pro for details.
;                   This should always be set!  Default = 1.
;
;    DENSITY:       Calculate densities for O+ and O2+.  If BEAM = 0, then 
;                   H+ density is also determined.  Automatically sets 
;                   POTENTIAL = 1.
;
;    TEMPERATURE:   Calculate temperatures for O+ and O2+.  If BEAM = 0, then 
;                   H+ temperature is also determined.  Automatically sets 
;                   POTENTIAL = 1.
;
;    VELOCITY:      Calculate velocities of H+, O+, and/or O2+.
;
;                     VELOCITY = 1       --> calculate for all three species
;                     VELOCITY = [0,0,1] --> calculate only for O2+
;
;                   If you set this keyword, then you must load one of the
;                   following APID's, in order of preference:
;
;                      d1 -> 32E x  8M x 4D x 16A, burst time resolution
;                      d0 -> 32E x  8M x 4D x 16A, survey time resolution
;                      cf -> 16E x 16M x 4D x 16A, burst time resolution
;                      ce -> 16E x 16M x 4D x 16A, survey time resolution
;
;    BURST:         If set, try to use d1 if available, otherwise use d0.
;                   If not set, use d0.
;
;    FRAME:         Reference frame for velocities.  Default = 'mso'.  Try 'app'
;                   to get apparent flow direction in APP frame.
;
;    RESULT_H:      Result structure for H+.
;
;    RESULT_O1:     Result structure for O+.
;
;    RESULT_O2:     Result structure for O2+.
;
;    PARNG:         Pitch angle range for 2-stream shape parameter.
;                      1 : 0-30 deg  (default)
;                      2 : 0-45 deg
;                      3 : 0-60 deg
;
;    TAVG:          Time averaging window size.  Improves statistics and
;                   reduces run time.
;
;    NOLOAD:        Skip the step of loading data.
;
;    PANS:          Named variable to hold a space delimited string containing
;                   the tplot variable(s) created.
;
;    RESET:         Reinitialize the result structures.
;
;    DOPLOT:        Make tplot variables of the results.
;
;    SUCCESS:       Processing success flag.
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2021-08-25 09:07:29 -0700 (Wed, 25 Aug 2021) $
; $LastChangedRevision: 30246 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swea/mvn_sta_coldion.pro $
;
;CREATED BY:    David L. Mitchell
;-
pro mvn_sta_coldion, beam=beam, potential=potential, adisc=adisc, parng=parng, $
                     density=density, velocity=velocity, tavg=tavg, pans=pans, $
                     result_h=result_h, result_o1=result_o1, result_o2=result_o2, $
                     noload=noload, temperature=temperature, reset=reset, $
                     frame=frame, doplot=doplot, burst=burst, success=success, $
                     reload=reload

  common coldion, cio_h, cio_o1, cio_o2
  common mvn_sta_kk3_anode, kk3_anode
  common mvn_c6, mvn_c6_ind, mvn_c6_dat
  common mvn_c8, mvn_c8_ind, mvn_c8_dat
  common mvn_d0, mvn_d0_ind, mvn_d0_dat
  common mvn_d1, mvn_d1_ind, mvn_d1_dat

  success = 0
  cio_h = 0
  cio_o1 = 0
  cio_o2 = 0
  v_apid = ''

; Process keywords

  if (size(potential,/type) eq 0) then potential = 1
  dopot = keyword_set(potential)

  case n_elements(velocity) of
       0   : dovel = [0, 0, 0]
       1   : dovel = [velocity, 0, 0]
       2   : dovel = [velocity, 0]
      else : dovel = velocity[0:2]
  endcase

  doden = keyword_set(density)
  dotmp = keyword_set(temperature)

  kk3_anode = keyword_set(adisc)
  if (kk3_anode) then begin
    uinfo = get_login_info()
    if (uinfo.user_name ne 'mitchell') then begin
      print,"Please contact DLM if you want to use this option."
      kk3_anode = 0
    endif
  endif

  species = ['H+','O+','O2+']
  m_arr = fltarr(3,3)
  m_arr[*,0] = [ 0, 1, 4]   ; H+
  m_arr[*,1] = [14,16,20]   ; O+
  m_arr[*,2] = [25,32,40]   ; O2+

  e_arr = fltarr(2,3)
  e_arr[*,0] = [0.,30000.]  ; H+
  e_arr[*,1] = [0., 3000.]  ; O+
  e_arr[*,2] = [0., 3000.]  ; O2+

  cols = get_colors()
  icols = [cols.blue,cols.green,cols.red]  ; color for each species

  if (size(parng,/type) eq 0) then parng = 1

  if not keyword_set(frame) then frame = 'mso'
  frame = mvn_frame_name(frame)

  if (frame eq 'MAVEN_APP') then begin
    vsc = 0
    print,'Calculating apparent flow in APP frame - no s/c velocity correction.'
  endif else vsc = 1

; Load STATIC data (if needed)

  trange = timerange()
  replot = 0

  eph = maven_orbit_eph()
  if (size(eph,/type) ne 8) then return
  if ((trange[0] lt min(eph.time)) or (trange[1] gt max(eph.time))) then begin
    print,"Insufficient state vector coverage for the requested time range."
    print,"  -> Rerun maven_orbit_tplot to include your time range."
    return
  endif

  str_element, mvn_c6_dat, 'time', time, success=ok
  if (ok) then indx = where((time gt trange[0]) and (time lt trange[1]), npts) else npts = 0
  if keyword_set(reload) then npts = 0
  if (npts lt 10) then begin
    mvn_sta_l2_load, sta_apid=['c0','c6','c8'], iv_level=2
    str_element, mvn_c6_dat, 'time', time, success=ok
    if (ok) then indx = where((time gt trange[0]) and (time lt trange[1]), npts) else npts = 0
    if (npts lt 10) then begin
      print,"No STATIC c6 data."
      return
    endif else replot = 1
  endif

  if keyword_set(burst) then begin
    str_element, mvn_d1_dat, 'time', time, success=ok
    if (ok) then indx = where((time gt trange[0]) and (time lt trange[1]), npts) else npts = 0
    if keyword_set(reload) then npts = 0
    if (npts lt 10) then begin
      mvn_sta_l2_load, sta_apid=['d1'], iv_level=2
      str_element, mvn_d1_dat, 'time', time, success=ok
      if (ok) then indx = where((time gt trange[0]) and (time lt trange[1]), npts) else npts = 0
      if (npts lt 10) then print,"No STATIC d1 data." else replot = 1
    endif
  endif

  if (v_apid eq '') then begin
    v_apid = 'd0'
    str_element, mvn_d0_dat, 'time', time, success=ok
    if (ok) then indx = where((time gt trange[0]) and (time lt trange[1]), npts) else npts = 0
    if keyword_set(reload) then npts = 0
    if (npts lt 10) then begin
      mvn_sta_l2_load, sta_apid=['d0'], iv_level=2
      str_element, mvn_d0_dat, 'time', time, success=ok
      if (ok) then indx = where((time gt trange[0]) and (time lt trange[1]), npts) else npts = 0
      if (npts lt 10) then begin
        print,"No STATIC d0 data."
        v_apid = ''
        return
      endif else replot = 1
    endif
  endif

  print,"Using APID ",v_apid," to calculate velocity moments."

  if (replot) then mvn_sta_l2_tplot, /replace

  pans = ['']
  
  get_data, 'mvn_sta_c0_E', index=i
  if (i gt 0) then begin
    pans = [pans,'mvn_sta_c0_E']
    ylim,'mvn_sta_c0_E',4e-1,4e4
    options,'mvn_sta_c0_E','ytitle','sta c0!CEnergy!CeV'
  endif

  get_data, 'mvn_sta_c6_M', index=i
  if (i gt 0) then begin
    pans = [pans,'mvn_sta_c6_M']
    options,'mvn_sta_c6_M','ytitle','sta c6!CMass!Camu'
  endif

  pans = pans[1:*]

  if (~doden and ~dotmp and (max(dovel) eq 0)) then return

  var4d = 'mvn_sta_' + v_apid + '_E'
  get_data, var4d, data=dat4d, index=i
  if (i eq 0) then begin
    mvn_sta_l2_tplot, /replace
    get_data, var4d, data=dat4d, index=i
    if (i eq 0) then begin
      print,"Can't generate tplot variables for apid ", v_apid
      return
    endif
  endif

  if keyword_set(tavg) then dt = double(tavg) else dt = 16D
  tmin = min(trange, max=tmax)
  npts = ceil((tmax-tmin)/dt)
  time = tmin + dt*dindgen(npts)

; Initialize the result structures

  if ((size(result_h,/type) ne 8) or keyword_set(reset)) then begin    
    v_bulk = mvn_sta_cio_struct(npts)
    v_bulk.time = time
    result_h = v_bulk
    result_o1 = v_bulk
    result_o2 = v_bulk
  endif

; Spacecraft potential

  mvn_scpot

; Determine the ion suppression method.  Anode-dependent ion suppression
; uses experimental code and is for testing purposes only.

  if (doden or dotmp) then begin
    kk3_anode = keyword_set(adisc)
    if (kk3_anode) then begin
      uinfo = get_login_info()
      if (uinfo.user_name ne 'mitchell') then begin
        print,"This option uses unreleased, experimental code."
        kk3_anode = 0
      endif
    endif

    kk = 0.
    if (kk3_anode) then begin
      kk = mvn_sta_get_kk3(mean(trange))
      isuppress = 'nbc_4d'
      tsuppress = 'tb_4d'  ; don't have experimental version of this
      print,'Using attenuator-dependent ion suppression correction.'
      print,'kk3 = ',kk
    endif else begin
      kk = mvn_sta_get_kk2(mean(trange))
      isuppress = 'nb_4d'
      tsuppress = 'tb_4d'
      print,'Using basic ion suppression correction.'
      print,'kk2 = ',kk
    endelse

    if (max(kk) gt 4.) then begin
      msg = string("Warning: STATIC ion suppression factor = ",kk,format='(16(a,f3.1))')
      print,msg
      tplot_options,'title',msg
    endif
  endif

; Calculate H+, O+, and O2+ densities

  if (doden) then begin
    print, "Calculating densities ..."

    if keyword_set(beam) then begin

      get_data, 'mvn_sta_c6_mode', data=c6_mode
      wrong_mode = where((c6_mode.y ne 1) and (c6_mode.y ne 2), nwrong)
      erange = [0.,100.]
      mincts = 25

; There is no H+ density calculation for the beam approx.

; Calculate the O+ density with the beam approx.

      getap = 'mvn_sta_get_c6'
      vname = 'mvn_sta_O+_raw_density'
      mass = m_arr[*,1]
    
	  get_4dt, isuppress, getap, mass=minmax(mass), m_int=mass[1], $
	           energy=erange, name=vname

	  get_data, vname, data=tmp
	  if (nwrong gt 0L) then tmp.y[wrong_mode] = !values.f_nan
	  store_data, vname, data=tmp
	  options, vname, ytitle='sta c6 O+!cDensity (1/cc)', colors=icols[1]
	  ylim, vname, 10, 100000, 1

      get_data, vname, data=tmp
      dx = tmp.x - shift(tmp.x,1)
      dx[0] = dx[1]
      if (min(dx) lt (2D*dt)) then begin
        tsmooth_in_time, vname, dt
        get_data, (vname + '_smoothed'), data=tmp
      endif

      result_o1.den_i = interp(tmp.y, tmp.x, time)

; Calculate the O2+ density with the beam approx.

      getap = 'mvn_sta_get_c6'
      vname = 'mvn_sta_O2+_raw_density'
      mass = m_arr[*,2]

      get_4dt, isuppress, getap, mass=minmax(mass), m_int=mass[1], $
               energy=erange, name=vname

      get_data, vname, data=tmp
      if (nwrong gt 0L) then tmp.y[wrong_mode] = !values.f_nan
      store_data, vname, data=tmp
      options, vname, ytitle='sta c6 O2+!cDensity (1/cc)', colors=icols[2]
      ylim, vname, 10, 100000, 1

      get_data, vname, data=tmp
      dx = tmp.x - shift(tmp.x,1)
      dx[0] = dx[1]
      if (min(dx) lt (2D*dt)) then begin
        tsmooth_in_time, vname, dt
        get_data, (vname + '_smoothed'), data=tmp
      endif

      result_o2.den_i = interp(tmp.y, tmp.x, time)

    endif else begin

; Calculate H+, O+, and O2+ densities without beam approx.

      getap = 'mvn_sta_get_c6'
      dnames = 'mvn_sta_' + ['p+','o+','o2+','i+'] + '_c6_den'
      erange = [0.,30000.]
      mincts = 25

      for i=0,2 do begin
        mass = m_arr[*,i]

        get_4dt, 'n_4d', getap, mass=minmax(mass), m_int=mass[1], $
                 energy=erange, name=dnames[i]

        get_data, dnames[i], data=tmp
        dx = tmp.x - shift(tmp.x,1)
        dx[0] = dx[1]
        if (min(dx) lt (2D*dt)) then begin
          tsmooth_in_time, dnames[i], dt
          get_data, (dnames[i] + '_smoothed'), data=tmp
        endif

        case i of
          0 : result_h.den_i = interp(tmp.y, tmp.x, time)
          1 : result_o1.den_i = interp(tmp.y, tmp.x, time)
          2 : result_o2.den_i = interp(tmp.y, tmp.x, time)
        endcase

      endfor

; Make a tplot variable for the unsmoothed data

      get_data, dnames[0], data=tmp1
      get_data, dnames[1], data=tmp2
      get_data, dnames[2], data=tmp3
      store_data, dnames[3], data={x:tmp1.x, y:(tmp1.y+tmp2.y+tmp3.y)}

      store_data,'mvn_sta_c6_den',data=dnames[[3,0,1,2]]
      ylim,'mvn_sta_c6_den',.1,100,1
      options,'mvn_sta_c6_den','ytitle','Ion Density!c1/cc'

    endelse
  endif

; Set up filtering based on density

  igud = replicate(0,npts,3)  ; start by assuming all data bad

  indx = where(result_h.den_i gt 0.1, ngud)
  if (ngud gt 0L) then igud[indx,0] = 1 else print,"H+ density is never above 0.1/cc!"

  indx = where(result_o1.den_i gt 0.1, ngud)
  if (ngud gt 0L) then igud[indx,1] = 1 else print,"O+ density is never above 0.1/cc!"

  indx = where(result_o2.den_i gt 0.1, ngud)
  if (ngud gt 0L) then igud[indx,2] = 1 else print,"O2+ density is never above 0.1/cc!"

; Filter density

  ibad = where(~igud[*,0], nbad)
  if (nbad gt 0L) then result_h[ibad].den_i = !values.f_nan

  ibad = where(~igud[*,1], nbad)
  if (nbad gt 0L) then result_o1[ibad].den_i = !values.f_nan

  ibad = where(~igud[*,2], nbad)
  if (nbad gt 0L) then result_o2[ibad].den_i = !values.f_nan

; Calculate H+, O+, and O2+ temperatures

  if keyword_set(temperature) then begin
    print, "Calculating temperatures ..."

    if keyword_set(beam) then begin

      get_data,'mvn_sta_c6_mode',data=tmp7
      ind_mode = where(tmp7.y ne 1 and tmp7.y ne 2, count)
	  erange = [0.,100.]
	  mincnts = 25

; There is no H+ temperature calculation for the beam approx.

; Calculate the O+ temperature with the beam approx.

      getap = 'mvn_sta_get_c6'
      vname = 'mvn_sta_O+_raw_temp'
      mass = m_arr[*,1]

	  get_4dt, tsuppress, getap, mass=minmax(mass), m_int=mass[1], $
	           energy=erange, name=vname

	  options, vname, ytitle='sta c6 O+!cTemp (eV)', colors=icols[1]
	  ylim, vname, 10, 100000, 1
	  get_data, vname, data=tmp
	  if (nwrong gt 0L) then tmp.y[wrong_mode] = !values.f_nan
	  store_data, vname, data=tmp

      dx = tmp.x - shift(tmp.x,1)
      dx[0] = dx[1]
      if (min(dx) lt (2D*dt)) then begin
        tsmooth_in_time, vname, dt
        get_data, (vname + '_smoothed'), data=tmp
      endif

      result_o1.temp = interp(tmp.y, tmp.x, time)

; Calculate the O2+ temperature with the beam approx.

      getap = 'mvn_sta_get_c6'
      vname = 'mvn_sta_O2+_raw_temp'
      mass = m_arr[*,2]

	  get_4dt, tsuppress, getap, mass=minmax(mass), m_int=mass[1], $
	           energy=erange, name=vname

      options, vname, ytitle='sta c6 O2+!cTemp (eV)', colors=icols[2]
      ylim, vname, 10, 100000, 1
      get_data, vname, data=tmp
      if (nwrong gt 0L) then tmp.y[wrong_mode] = !values.f_nan 
      store_data, vname, data=tmp

      dx = tmp.x - shift(tmp.x,1)
      dx[0] = dx[1]
      if (min(dx) lt (2D*dt)) then begin
        tsmooth_in_time, vname, dt
        get_data, (vname + '_smoothed'), data=tmp
      endif

      result_o2.temp = interp(tmp.y, tmp.x, time)

    endif else begin

; Calculate H+, O+, and O2+ temperatures without beam approx.

      getap = 'mvn_sta_get_' + v_apid
      dname = 'mvn_sta_' + ['p+','o+','o2+'] + '_' + v_apid + '_temp'
	  mincnts = 25

      for i=0,2 do begin
        mass = m_arr[*,i]
        erange = e_arr[*,i]

        get_4dt, 't_4d', getap, mass=minmax(mass), m_int=mass[1], $
                 energy=erange, name=dname[i]

        get_data, dname[i], data=tmp
        dx = tmp.x - shift(tmp.x,1)
        dx[0] = dx[1]
        if (min(dx) lt (2D*dt)) then begin
          tsmooth_in_time, dname[i], dt
          get_data, (dname[i] + '_smoothed'), data=tmp
        endif

        case i of
          0 : result_h.temp = interp(tmp.y[*,3], tmp.x, time)
          1 : result_o1.temp = interp(tmp.y[*,3], tmp.x, time)
          2 : result_o2.temp = interp(tmp.y[*,3], tmp.x, time)
        endcase
      endfor

    endelse

; Filter temperature

    ibad = where(~igud[*,0], nbad)
    if (nbad gt 0L) then result_h[ibad].temp = !values.f_nan

    ibad = where(~igud[*,1], nbad)
    if (nbad gt 0L) then result_o1[ibad].temp = !values.f_nan

    ibad = where(~igud[*,2], nbad)
    if (nbad gt 0L) then result_o2[ibad].temp = !values.f_nan

  endif

; Calculate MSO velocity moments for H+, O+, and O2+, corrected for spacecraft
; potential and motion.
;   (turn off messages: setdebug=0)

  if (max(dovel) eq 1) then begin

    dprint, "Calculating velocities ...", getdebug=old_dbug, setdebug=0

    v_names = 'mvn_sta_' + ['p+','o+','o2+'] + '_' + v_apid + '_vmso'
    mvn_sta_v4d, result=r_str, /template

    for i=0,2 do begin
      if (dovel[i]) then begin
        mass = m_arr[*,i]
        erange = e_arr[*,i]
        v_bulk = replicate(r_str, npts)
        v_bulk.time = time

        jskip = npts/100L
        for j=0L,(npts-1L) do begin
          if (igud[j,i]) then begin
            if keyword_set(dt) then begin
              tsp = double([j, j+1])*dt + tmin
              indx = where((dat4d.x ge tsp[0]) and (dat4d.x lt tsp[1]), k)
              if (k gt 0L) then begin
                mvn_sta_v4d, tsp, mass=minmax(mass), m_int=mass[1], frame=frame, $
                             erange=erange, /dopot, vsc=vsc, apid=v_apid, result=result, $
                             /no_spice_check
                if (result.valid) then v_bulk[j] = result
              endif
            endif else begin
              mvn_sta_v4d, time[j], mass=minmax(mass), m_int=mass[1], frame=frame, $
                           erange=erange, /dopot, vsc=vsc, apid=v_apid, result=result, $
                           /no_spice_check
              if (result.valid) then v_bulk[j] = result
            endelse
          endif
          if (~(j mod jskip)) then print,string(13b),species[i],round(100.*j/npts),$
                                         format='(a,a3,1x,i3," %",$)'
        endfor
        print,''

        case (i) of
          0 : begin
                result_h.v_sc   = v_bulk.v_sc
                result_h.v_tot  = v_bulk.v_tot
                result_h.v_mso  = v_bulk.vel
                result_h.vbulk  = v_bulk.vbulk
                result_h.magf   = v_bulk.magf
                result_h.energy = v_bulk.energy
                result_h.VB_phi = v_bulk.VB_phi
                result_h.sc_pot = v_bulk.sc_pot
                result_h.mass   = v_bulk.mass
                result_h.mrange = v_bulk.mrange
                result_h.erange = v_bulk.erange
                result_h.frame  = v_bulk.frame
                result_h.apid   = v_bulk.apid
                result_h.valid  = v_bulk.valid
              end
          1 : begin
                result_o1.v_sc   = v_bulk.v_sc
                result_o1.v_tot  = v_bulk.v_tot
                result_o1.v_mso  = v_bulk.vel
                result_o1.vbulk  = v_bulk.vbulk
                result_o1.magf   = v_bulk.magf
                result_o1.energy = v_bulk.energy
                result_o1.VB_phi = v_bulk.VB_phi
                result_o1.sc_pot = v_bulk.sc_pot
                result_o1.mass   = v_bulk.mass
                result_o1.mrange = v_bulk.mrange
                result_o1.erange = v_bulk.erange
                result_o1.frame  = v_bulk.frame
                result_o1.apid   = v_bulk.apid
                result_o1.valid  = v_bulk.valid
              end
          2 : begin
                result_o2.v_sc   = v_bulk.v_sc
                result_o2.v_tot  = v_bulk.v_tot
                result_o2.v_mso  = v_bulk.vel
                result_o2.vbulk  = v_bulk.vbulk
                result_o2.magf   = v_bulk.magf
                result_o2.energy = v_bulk.energy
                result_o2.VB_phi = v_bulk.VB_phi
                result_o2.sc_pot = v_bulk.sc_pot
                result_o2.mass   = v_bulk.mass
                result_o2.mrange = v_bulk.mrange
                result_o2.erange = v_bulk.erange
                result_o2.frame  = v_bulk.frame
                result_o2.apid   = v_bulk.apid
                result_o2.valid  = v_bulk.valid
              end
        endcase

        y = fltarr(npts,4)
        y[*,0:2] = transpose(v_bulk.vel)
        y[*,3] = v_bulk.vbulk
        store_data, v_names[i], data={x:v_bulk.time, y:y, v:[0,1,2,3]}
        options, v_names[i], spice_frame=frame, spice_master_frame='MAVEN_SPACECRAFT'
        options, v_names[i], 'ytitle', (species[i] + ' V_MSO!ckm/s')
        options, v_names[i], 'labels', ['X','Y','Z','']
        options, v_names[i], 'colors', [icols,!p.color]
        options, v_names[i], 'labflag', 1
      endif

    endfor

    dprint, "Done", setdebug=old_dbug

  endif

; Thermal electron density from LPW (using C.F.'s quality filter)

  mvn_swe_addlpw, mincur=1.e-7
  get_data,'mvn_lpw_lp_ne_l2',index=i
  if (i gt 0) then begin
    tsmooth_in_time, 'mvn_lpw_lp_ne_l2', dt
    get_data, 'mvn_lpw_lp_ne_l2_smoothed', data=n_e
    result_h.den_e = interpol(n_e.y, n_e.x, time)
    result_o1.den_e = result_h.den_e
    result_o2.den_e = result_h.den_e
  endif

; Spacecraft potential (fill in missing values)

  indx = where(~finite(result_h.sc_pot), count)
  if (count gt 0L) then result_h[indx].sc_pot = mvn_get_scpot(time[indx])
  indx = where(~finite(result_o1.sc_pot), count)
  if (count gt 0L) then result_o1[indx].sc_pot = mvn_get_scpot(time[indx])
  indx = where(~finite(result_o2.sc_pot), count)
  if (count gt 0L) then result_o2[indx].sc_pot = mvn_get_scpot(time[indx])

; Magnetic field (fill in missing values)

  get_data, 'mvn_B_1sec_maven_mso', index=i
  if (i gt 0) then begin
    tsmooth_in_time, 'mvn_B_1sec_maven_mso', dt
    get_data, 'mvn_B_1sec_maven_mso_smoothed', data=mag, alim=alim

    indx = where(~finite(result_h.magf[0]), count)
    if (count gt 0L) then begin
      result_h[indx].magf[0] = interpol(mag.y[*,0], mag.x, time[indx])
      result_h[indx].magf[1] = interpol(mag.y[*,1], mag.x, time[indx])
      result_h[indx].magf[2] = interpol(mag.y[*,2], mag.x, time[indx])
    endif

    indx = where(~finite(result_o1.magf[0]), count)
    if (count gt 0L) then begin
      result_o1[indx].magf[0] = interpol(mag.y[*,0], mag.x, time[indx])
      result_o1[indx].magf[1] = interpol(mag.y[*,1], mag.x, time[indx])
      result_o1[indx].magf[2] = interpol(mag.y[*,2], mag.x, time[indx])
    endif

    indx = where(~finite(result_o2.magf[0]), count)
    if (count gt 0L) then begin
      result_o2[indx].magf[0] = interpol(mag.y[*,0], mag.x, time[indx])
      result_o2[indx].magf[1] = interpol(mag.y[*,1], mag.x, time[indx])
      result_o2[indx].magf[2] = interpol(mag.y[*,2], mag.x, time[indx])
    endif

  endif

; Reference frame

  result_h.frame = frame
  result_o1.frame = frame
  result_o2.frame = frame

; Shape parameter (Xu method)

  mvn_swe_shape_restore, /tplot, parng=parng, result=shape
  if (size(shape,/type) eq 8) then begin
    shp = smooth_in_time(transpose(shape.shape[0:1,parng]), shape.t, dt)
    result_h.shape[0] = interpol(shp[*,0], shape.t, result_h.time)
    result_h.shape[1] = interpol(shp[*,1], shape.t, result_h.time)
    result_o1.shape = result_h.shape
    result_o2.shape = result_h.shape

    f40 = smooth_in_time(shape.f40, shape.t, dt)
    result_h.flux40 = interpol(f40, shape.t, result_h.time)/1.e5
    result_o1.flux40 = result_h.flux40
    result_o2.flux40 = result_h.flux40

    frat40 = smooth_in_time(shape.fratio_a2t[0,parng], shape.t, dt)
    result_h.ratio = 1./interpol(frat40, shape.t, result_h.time)
    result_o1.ratio = result_h.ratio
    result_o2.ratio = result_h.ratio
  endif else print,'Could not get shape parameter.'

; Topology Index (Xu-Weber method)
;   All types of closed loops (DD, DN, NN, TRP) are combined into one.
;   0 = unknown, 1 = closed, 2 = open to day, 3 = open to night, 4 = draped

  mvn_swe_topo, result=topo, /filter_reg, /storeTplot
  if (size(topo,/type) eq 8) then begin
    ttime = topo.time
    topo = round(topo.topo)
    indx = where((topo ge 1) and (topo le 4), count)  ; closed loops
    if (count gt 0) then topo[indx] = 1
    indx = where(topo eq 5, count)       ; open to day
    if (count gt 0) then topo[indx] = 2
    indx = where(topo eq 6, count)       ; open to night
    if (count gt 0) then topo[indx] = 3
    indx = where(topo eq 7, count)       ; draped
    if (count gt 0) then topo[indx] = 4

    dtt = ttime - shift(ttime,1)
    dtt = median(dtt[1:*])
    nfilter = round(dt/dtt)
    if ~(nfilter mod 2) then nfilter++
    topo = round(median(topo, nfilter))  ; dt-width median filter

    indx = nn2(ttime, time)
    result_h.topo = topo[indx]
    result_o1.topo = topo[indx]
    result_o2.topo = topo[indx]
  endif else print,'Could not get topology information.'

; Plasma Region (Halekas method)
;   Both ionosphere indices are combined into one.
;   0 = unknown, 1 = solar wind, 2 = sheath, 3 = ionosphere, 4 = tail lobe

  get_data,'reg_id',data=reg_id
  if (size(reg_id,/type) eq 8) then begin
    dtt = reg_id.x - shift(reg_id.x,1)
    dtt = median(dtt[1:*])
    nfilter = round(dt/dtt)
    if ~(nfilter mod 2) then nfilter++
    region = round(median(reg_id.y, nfilter))  ; dt-width median filter

    indx = nn2(reg_id.x, time)
    result_h.region = region[indx]
    result_o1.region = region[indx]
    result_o2.region = region[indx]
  endif else print,'Could not get plasma region information.'

; Upstream drivers (direct and proxy)

  path = root_data_dir() + 'maven/data/sci/swe/l3/'
  tplot_restore, file=(path + 'drivers_merge_l2.tplot')  ; direct (Halekas)

  ngud = 0L
  get_data, 'bsw', data=imf, index=i
  if (i gt 0) then begin
    dtmax = 5D*3600D  ; within 5 hours of sw measurement
    By = interp(imf.y[*,1], imf.x, time, int=dtmax)
    Bz = interp(imf.y[*,2], imf.x, time, int=dtmax)

    gap = where(~finite(By) or ~finite(Bz), ngap)
    if (ngap gt 0) then begin
      restore, (path + 'mag_sheath.sav')                 ; proxy (Y. Dong)
      if (size(mag_sheath,/type) eq 8) then begin
        By[gap] = interp(mag_sheath.mag[*,1], mag_sheath.time, time[gap], int=dtmax)
        Bz[gap] = interp(mag_sheath.mag[*,2], mag_sheath.time, time[gap], int=dtmax)
      endif else print,'Could not get solar wind proxy database.'
    endif

    Bclk = atan(Bz,By)  ; radians (0 = east, pi = west)
    result_h.imf_clk = Bclk
    result_o1.imf_clk = Bclk
    result_o2.imf_clk = Bclk

    igud = where(finite(Bclk), ngud)
    if (ngud gt 0L) then begin
      cosclk = cos(Bclk)
      sinclk = sin(Bclk)

      result_h[igud].v_mse[0] = result_h[igud].v_mso[0]
      result_h.v_mse[1] = cosclk*result_h.v_mso[1] + sinclk*result_h.v_mso[2]
      result_h.v_mse[2] = cosclk*result_h.v_mso[2] - sinclk*result_h.v_mso[1]

      result_o1[igud].v_mse[0] = result_o1[igud].v_mso[0]
      result_o1.v_mse[1] = cosclk*result_o1.v_mso[1] + sinclk*result_o1.v_mso[2]
      result_o1.v_mse[2] = cosclk*result_o1.v_mso[2] - sinclk*result_o1.v_mso[1]

      result_o2[igud].v_mse[0] = result_o2[igud].v_mso[0]
      result_o2.v_mse[1] = cosclk*result_o2.v_mso[1] + sinclk*result_o2.v_mso[2]
      result_o2.v_mse[2] = cosclk*result_o2.v_mso[2] - sinclk*result_o2.v_mso[1]
    endif

    get_data, 'npsw', data=npsw, index=i
    Np = interp(npsw.y, npsw.x, time, int=dtmax)  ; cm-3
    get_data, 'vpsw', data=vpsw, index=i
    Vp = interp(vpsw.y, vpsw.x, time, int=dtmax)  ; km/s

    Psw = (1.67e-6) * (Np*Vp*Vp)  ; nPa
    result_h.sw_press = Psw
    result_o1.sw_press = Psw
    result_o2.sw_press = Psw

  endif else print,'Could not get upstream drivers database.'

; MSO, MSE and GEO ephemerides

  result_h.alt = spline(eph.time, eph.alt, time)
  result_o1.alt = result_h.alt
  result_o2.alt = result_h.alt

  result_h.mso[0] = spline(eph.time, eph.mso_x[*,0], time)
  result_h.mso[1] = spline(eph.time, eph.mso_x[*,1], time)
  result_h.mso[2] = spline(eph.time, eph.mso_x[*,2], time)
  result_o1.mso = result_h.mso
  result_o2.mso = result_h.mso

  if (ngud gt 0L) then begin
    result_h[igud].mse[0] = result_h[igud].mso[0]
    result_h.mse[1] = cosclk*result_h.mso[1] + sinclk*result_h.mso[2]
    result_h.mse[2] = cosclk*result_h.mso[2] - sinclk*result_h.mso[1]
    result_o1.mse = result_h.mse
    result_o2.mse = result_h.mse
  endif

  result_h.geo[0] = spline(eph.time, eph.geo_x[*,0], time)
  result_h.geo[1] = spline(eph.time, eph.geo_x[*,1], time)
  result_h.geo[2] = spline(eph.time, eph.geo_x[*,2], time)
  result_o1.geo = result_h.geo
  result_o2.geo = result_h.geo

; Escape velocity

  M = 6.4171d26    ; https://nssdc.gsfc.nasa.gov/planetary/factsheet/index.html
  G = 6.673889d-8  ; Anderson, J.D., et al., EPL 110 (2015) 10002, doi:10.1209/0295-5075/110/10002

  Vesc = sqrt(2D*G*M/(1.d15*sqrt(total(eph.mso_x^2.,2))))
  store_data,'Vesc',data={x:eph.time, y:Vesc}
  options,'Vesc','linestyle',2

  result_h.v_esc = spline(eph.time, Vesc, time)
  result_o1.v_esc = result_h.v_esc
  result_o2.v_esc = result_h.v_esc

; Direction of Sun in IAU_MARS frame (orientation of crustal fields)

  s_mso = [1D, 0D, 0D] # replicate(1D, n_elements(time))
  s_geo = spice_vector_rotate(s_mso, time, 'MAVEN_MSO', 'IAU_MARS')
  s_lon = reform(atan(s_geo[1,*], s_geo[0,*])*!radeg)
  s_lat = reform(asin(s_geo[2,*])*!radeg)

  result_h.slon = s_lon
  result_h.slat = s_lat
  result_o1.slon = s_lon
  result_o1.slat = s_lat
  result_o2.slon = s_lon
  result_o2.slat = s_lat

; Mars season (Ls)

  L_s = mvn_ls(time)
  result_h.L_s = L_s
  result_o1.L_s = L_s
  result_o2.L_s = L_s

; Mars-Sun distance

  au = 1.495978707d8  ; Astronomical Unit (km)
  odat = mvn_orbit_num()
  Mdist = interp(odat.sol_dist, odat.peri_time, time)/au

  result_h.Mdist = Mdist
  result_o1.Mdist = Mdist
  result_o2.Mdist = Mdist

; Elevation angle of the Sun in the spacecraft frame
;   0 deg = x-y plane ; +90 deg = +z
;   cold-ion configuration is +45 deg for twist, +90 deg for no-twist

  get_data,'Sun_SWEA_The',data=sthe_swe,index=i
  if (i eq 0) then begin
    mvn_sundir, frame='swe', /polar
    get_data,'Sun_SWEA_The',data=sthe_swe,index=i
  endif
  if (i gt 0) then begin
    indx = where(finite(sthe_swe.y), count)
    if (count gt 0) then begin
      result_h.sthe = spline(sthe_swe.x[indx], sthe_swe.y[indx], time)
      result_o1.sthe = result_h.sthe
      result_o2.sthe = result_h.sthe
    endif else print,'MVN_STA_COLDION: Failed to get Sun (PL) direction!'
  endif else print,'MVN_STA_COLDION: Failed to get Sun (PL) direction!'

; Elevation angle of the Sun in the APP frame
;   0 deg = i-j plane ; +90 deg = +k
;   cold-ion configuration is ~0 deg

  mvn_sundir, frame='app', /polar
  get_data,'Sun_APP_The',data=sthe_app,index=i
  if (i gt 0) then begin
    indx = where(finite(sthe_app.y), count)
    if (count gt 0) then begin
      result_h.sthe_app = spline(sthe_app.x[indx], sthe_app.y[indx], time)
      result_o1.sthe_app = result_h.sthe_app
      result_o2.sthe_app = result_h.sthe_app
    endif else print,'MVN_STA_COLDION: Failed to get Sun (APP) direction!'
  endif else print,'MVN_STA_COLDION: Failed to get Sun (APP) direction!'

; Elevation angle of MSO RAM in the APP frame
;   0 deg = i-j plane ; +90 deg = +k
;   cold-ion configuration is ~0 deg

  mvn_ramdir, /mso, frame='app', /polar
  get_data,'V_sc_APP_The',data=rthe_app,index=i
  if (i gt 0) then begin
    indx = where(finite(rthe_app.y), count)
    if (count gt 0) then begin
      result_h.rthe_app = spline(rthe_app.x[indx], rthe_app.y[indx], time)
      result_o1.rthe_app = result_h.rthe_app
      result_o2.rthe_app = result_h.rthe_app
    endif else print,'MVN_STA_COLDION: Failed to get MSO RAM direction!'
  endif else print,'MVN_STA_COLDION: Failed to get MSO RAM direction!'

; Transform ion bulk velocity to the APP frame
;   For [-V,0,0], flow is directed into NGIMS aperture.
;   Want the velocity out of the i-j plane to be small (well within STATIC fov)

  dV = result_h.v_mso - result_h.v_sc
  V_app = spice_vector_rotate(dV,result_h.time,'MAVEN_MSO','MAVEN_APP',check='MAVEN_SPACECRAFT')
  result_h.v_app = V_app
  phi = atan(sqrt(V_app[1,*]^2. + V_app[2,*]^2.), V_app[0,*])*!radeg
  result_h.VI_phi = reform(phi)
  phi = atan(sqrt(V_app[0,*]^2. + V_app[1,*]^2.), V_app[2,*])*!radeg - 90.
  result_h.VK_the = reform(phi)

  dV = result_o1.v_mso - result_o1.v_sc
  V_app = spice_vector_rotate(dV,result_o1.time,'MAVEN_MSO','MAVEN_APP',check='MAVEN_SPACECRAFT')
  result_o1.v_app = V_app
  phi = atan(sqrt(V_app[1,*]^2. + V_app[2,*]^2.), V_app[0,*])*!radeg
  result_o1.VI_phi = reform(phi)
  phi = atan(sqrt(V_app[0,*]^2. + V_app[1,*]^2.), V_app[2,*])*!radeg - 90.
  result_o1.VK_the = reform(phi)

  dV = result_o2.v_mso - result_o2.v_sc
  V_app = spice_vector_rotate(dV,result_o2.time,'MAVEN_MSO','MAVEN_APP',check='MAVEN_SPACECRAFT')
  result_o2.v_app = V_app
  phi = atan(sqrt(V_app[1,*]^2. + V_app[2,*]^2.), V_app[0,*])*!radeg
  result_o2.VI_phi = reform(phi)
  phi = atan(sqrt(V_app[0,*]^2. + V_app[1,*]^2.), V_app[2,*])*!radeg - 90.
  result_o2.VK_the = reform(phi)

; Put copies of the results into the common block

  cio_h  = result_h
  cio_o1 = result_o1
  cio_o2 = result_o2
  success = 1

; Make tplot variables

  if keyword_set(doplot) then mvn_sta_cio_tplot

  return
  
end
