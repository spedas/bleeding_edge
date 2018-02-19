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
; $LastChangedDate: 2018-02-18 12:37:19 -0800 (Sun, 18 Feb 2018) $
; $LastChangedRevision: 24742 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swea/mvn_sta_coldion.pro $
;
;CREATED BY:    David L. Mitchell
;-
pro mvn_sta_coldion, beam=beam, potential=potential, adisc=adisc, parng=parng, $
                     density=density, velocity=velocity, tavg=tavg, pans=pans, $
                     result_h=cio_h, result_o1=cio_o1, result_o2=cio_o2, $
                     noload=noload, temperature=temperature, reset=reset, $
                     frame=frame, doplot=doplot, success=success

  common mvn_sta_kk3_anode, kk3_anode
  common mvn_coldi_com, result_h, result_o1, result_o2
  common mvn_c6, mvn_c6_ind, mvn_c6_dat
  common mvn_c8, mvn_c8_ind, mvn_c8_dat
  common mvn_d0, mvn_d0_ind, mvn_d0_dat
  common mvn_d1, mvn_d1_ind, mvn_d1_dat

  success = 0

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

; Load STATIC data

  get_data, 'mvn_sta_c6_M', index=i
  get_data, 'mvn_sta_d1_E', index=j
  get_data, 'mvn_sta_d0_E', index=k
  if ((i eq 0) or (j+k eq 0)) then noload = 0

  if ~keyword_set(noload) then begin
    mvn_sta_l2_load, sta_apid=['c0','c6','c8']
    str_element, mvn_c6_dat, 'valid', valid, success=ok
    if (ok) then indx = where(valid, count) else count = 0L
    if (count eq 0L) then begin
      print,"No STATIC c6 data."
      return
    endif

    mvn_sta_l2_load, sta_apid=['d1']
    str_element, mvn_d1_dat, 'valid', valid, success=ok
    if (ok) then indx = where(valid, count) else count = 0L
    if (count eq 0L) then begin
      print,"No STATIC d1 data."
      mvn_sta_l2_load, sta_apid=['d0']
      str_element, mvn_d0_dat, 'valid', valid, success=ok
      if (ok) then indx = where(valid, count) else count = 0L
      if (count eq 0L) then begin
        print,"No STATIC d0 data."
        return
      endif
    endif

    mvn_sta_l2_tplot, /replace
  endif

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

  get_data, 'mvn_sta_d1_E', data=dat4d, index=i
  if (i eq 0) then begin
    get_data, 'mvn_sta_d0_E', data=dat4d, index=i
    if (i eq 0) then begin
      print, "No STATIC d1 or d0 data loaded."
      return
    endif else v_apid = 'd0'
  endif else v_apid = 'd1'

  if keyword_set(tavg) then dt = double(tavg) else dt = 16D
  tmin = min(timerange(), max=tmax)
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
      kk = mvn_sta_get_kk3(mean(timerange()))
      isuppress = 'nbc_4d'
      tsuppress = 'tb_4d'  ; don't have experimental version of this
      print,'Using attenuator-dependent ion suppression correction.'
      print,'kk3 = ',kk
    endif else begin
      kk = mvn_sta_get_kk2(mean(timerange()))
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

      tsmooth_in_time, vname, dt
      get_data, (vname + '_smoothed'), data=tmp
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

      tsmooth_in_time, vname, dt
      get_data, (vname + '_smoothed'), data=tmp
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

        tsmooth_in_time, dnames[i], dt
        get_data, (dnames[i] + '_smoothed'), data=tmp
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

      tsmooth_in_time, vname, dt
      get_data, (vname + '_smoothed'), data=tmp
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

      tsmooth_in_time, vname, dt
      get_data, (vname + '_smoothed'), data=tmp
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

        tsmooth_in_time, dname[i], dt
        get_data, (dname[i] + '_smoothed'), data=tmp
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
                             erange=erange, /dopot, vsc=vsc, apid=v_apid, result=result
                if (result.valid) then v_bulk[j] = result
              endif
            endif else begin
              mvn_sta_v4d, time[j], mass=minmax(mass), m_int=mass[1], frame=frame, $
                           erange=erange, /dopot, vsc=vsc, apid=v_apid, result=result
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

    indx = nn(ttime, time)
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

    indx = nn(reg_id.x, time)
    result_h.region = region[indx]
    result_o1.region = region[indx]
    result_o2.region = region[indx]
  endif else print,'Could not get plasma region information.'

; MSO and GEO ephemerides v 

  get_data,'alt',data=alt,index=i
  if (i eq 0) then begin
    maven_orbit_tplot, /shadow, /load
    get_data,'alt',data=alt,index=i
  endif
  maven_orbit_tplot, eph=eph, /noload

  result_h.alt = spline(alt.x, alt.y, time)
  result_o1.alt = result_h.alt
  result_o2.alt = result_h.alt

  result_h.mso[0] = spline(eph.time, eph.mso_x[*,0], time)
  result_h.mso[1] = spline(eph.time, eph.mso_x[*,1], time)
  result_h.mso[2] = spline(eph.time, eph.mso_x[*,2], time)
  result_o1.mso = result_h.mso
  result_o2.mso = result_h.mso

  result_h.geo[0] = spline(eph.time, eph.geo_x[*,0], time)
  result_h.geo[1] = spline(eph.time, eph.geo_x[*,1], time)
  result_h.geo[2] = spline(eph.time, eph.geo_x[*,2], time)
  result_o1.geo = result_h.geo
  result_o2.geo = result_h.geo

; Escape velocity

  M = 6.4171d26    ; https://nssdc.gsfc.nasa.gov/planetary/factsheet/index.html
  G = 6.673889d-8  ; Anderson, J.D., et al., EPL 110 (2015) 10002, doi:10.1209/0295-5075/110/10002

  Vesc = sqrt(2D*G*M/(1.d15*sqrt(total(eph.mso_x^2.,2))))
  store_data,'Vesc',data={x:alt.x, y:Vesc}
  options,'Vesc','linestyle',2

  result_h.v_esc = spline(alt.x, Vesc, time)
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

  get_data,'Sun_SWEA_The',data=sthe,index=i
  if (i eq 0) then begin
    mvn_sundir, frame='swe', /polar
    get_data,'Sun_SWEA_The',data=sthe,index=i
  endif
  if (i gt 0) then begin
    result_h.sthe = spline(sthe.x, sthe.y, time)
    result_o1.sthe = result_h.sthe
    result_o2.sthe = result_h.sthe
  endif else print,'MVN_STA_COLDION: Failed to get Sun (PL) direction!'

; Elevation angle of the Sun in the APP frame
;   0 deg = i-j plane ; +90 deg = +k
;   cold-ion configuration is ~0 deg

  get_data,'Sun_APP_The',data=sthe,index=i
  if (i eq 0) then begin
    mvn_sundir, frame='app', /polar
    get_data,'Sun_APP_The',data=sthe,index=i
  endif
  if (i gt 0) then begin
    result_h.sthe_app = spline(sthe.x, sthe.y, time)
    result_o1.sthe_app = result_h.sthe
    result_o2.sthe_app = result_h.sthe
  endif else print,'MVN_STA_COLDION: Failed to get Sun (APP) direction!'

; Elevation angle of MSO RAM in the APP frame
;   0 deg = i-j plane ; +90 deg = +k
;   cold-ion configuration is ~0 deg

  mvn_ramdir, /mso, frame='app', /polar, pans=rpans
  i = where(stregex(rpans,'The') ne -1, count)
  if (count gt 0) then begin
    get_data, rpans[i], data=rthe
    result_h.rthe_app = spline(rthe.x, rthe.y, time)
    result_o1.rthe_app = result_h.rthe_app
    result_o2.rthe_app = result_h.rthe_app
  endif else print,'MVN_STA_COLDION: Failed to get MSO RAM direction!'

; Transform ion bulk velocity to the APP frame
;   For [-V,0,0], flow is directed into NGIMS aperture.

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

; Make tplot variables

  if keyword_set(doplot) then begin

    a = 0.8
    phi = findgen(49)*(2.*!pi/49)
    usersym,a*cos(phi),a*sin(phi),/fill

; Density

    store_data,'den_h',data={x:result_h.time, y:result_h.den_i}
    store_data,'den_o1',data={x:result_o1.time, y:result_o1.den_i}
    store_data,'den_o2',data={x:result_o2.time, y:result_o2.den_i}
    store_data,'den_e',data={x:result_h.time, y:result_h.den_e}

    den_h = result_h.den_i
    indx = where(~finite(den_h), count)
    if (count gt 0L) then den_h[indx] = 0.
    den_o = result_o1.den_i
    indx = where(~finite(den_o), count)
    if (count gt 0L) then den_o[indx] = 0.
    den_o2 = result_o2.den_i
    indx = where(~finite(den_o2), count)
    if (count gt 0L) then den_o2[indx] = 0.
    den_t = den_h + den_o + den_o2
    store_data,'den_t',data={x:result_h.time, y:den_t}

    store_data,'den_i+',data=['den_t','den_e','den_h','den_o1','den_o2']
    ylim,'den_i+',0.1,100,1
    options,'den_i+','constant',[1,10]
    options,'den_i+','ytitle','Ion Density!c1/cc'
    options,'den_i+','colors',[!p.color,1,icols]
    options,'den_i+','labels',['i+','e-',species]
    options,'den_i+','labflag',1
    pans = ['den_i+']

; Temperature

    store_data,'temp_h',data={x:result_h.time, y:result_h.temp}
    store_data,'temp_o1',data={x:result_o1.time, y:result_o1.temp}
    store_data,'temp_o2',data={x:result_o2.time, y:result_o2.temp}
    store_data,'temp_i+',data=['temp_h','temp_o1','temp_o2']
    ylim,'temp_i+',0.1,100,1
    options,'temp_i+','constant',[1,10]
    options,'temp_i+','ytitle','Ion Temp!ceV'
    options,'temp_i+','colors',icols
    options,'temp_i+','labels',species
    options,'temp_i+','labflag',1
    pans = [pans, 'temp_i+']

; Bulk Velocity

    store_data,'vel_h',data={x:result_h.time, y:result_h.vbulk}
    store_data,'vel_o1',data={x:result_o1.time, y:result_o1.vbulk}
    store_data,'vel_o2',data={x:result_o2.time, y:result_o2.vbulk}
    store_data,'Vesc',data={x:result_h.time, y:result_h.v_esc}
    store_data,'vel_i+',data=['vel_h','vel_o1','vel_o2','Vesc']
    ylim,'vel_i+',1,500,1
    options,'vel_i+','constant',[10,100]
    options,'vel_i+','ytitle','Ion Vel!ckm/s'
    options,'vel_i+','colors',[icols,!p.color]
    options,'vel_i+','labels',[species,'ESC']
    options,'vel_i+','labflag',1
    pans = [pans, 'vel_i+']

; Kinetic Energy of Bulk Flow

    store_data,'engy_h',data={x:result_h.time, y:result_h.energy}
    store_data,'engy_o1',data={x:result_o1.time, y:result_o1.energy}
    store_data,'engy_o2',data={x:result_o2.time, y:result_o2.energy}
    store_data,'engy_i+',data=['engy_h','engy_o1','engy_o2']
    ylim,'engy_i+',0.1,100,1
    options,'engy_i+','constant',[1,10]
    options,'engy_i+','ytitle','Ion Energy!ceV'
    options,'engy_i+','colors',icols
    options,'engy_i+','labels',species
    options,'engy_i+','labflag',1
    pans = [pans, 'engy_i+']

; Angle between V and B

    store_data,'VB_phi_h',data={x:result_h.time, y:result_h.VB_phi}
    store_data,'VB_phi_o1',data={x:result_o1.time, y:result_o1.VB_phi}
    store_data,'VB_phi_o2',data={x:result_o2.time, y:result_o2.VB_phi}
    store_data,'VB_phi',data=['VB_phi_h','VB_phi_o1','VB_phi_o2']
    ylim,'VB_phi',0,180,0
    options,'VB_phi','colors',icols
    options,'VB_phi','yticks',2
    options,'VB_phi','yminor',3
    options,'VB_phi','constant',[30,60,90,120,150]
    options,'VB_phi','labels',species
    options,'VB_phi','labflag',1
    pans = [pans, 'VB_phi']

; Angle between V and APP-i

    VI_phi = fltarr(npts,2)
    VI_phi[*,0] = result_o1.VI_phi
    VI_phi[*,1] = result_o2.VI_phi
    store_data,'VI_phi',data={x:result_o1.time, y:VI_phi, v:[0,1]}
    ylim,'VI_phi',0,180
    options,'VI_phi','ytitle','VI Phi!cAPP'
    options,'VI_phi','colors',icols[1:2]
    options,'VI_phi','yticks',2
    options,'VI_phi','yminor',3
    options,'VI_phi','constant',[30,60,90,120,150]
    options,'VI_phi','labels',species[1:2]
    options,'VI_phi','labflag',1
    pans = [pans, 'VI_phi']

; Angle between V and APP-k

    VK_the = fltarr(npts,3)
    VK_the[*,0] = result_h.VK_the
    VK_the[*,1] = result_o1.VK_the
    VK_the[*,2] = result_o2.VK_the
    store_data,'VK_the',data={x:result_h.time, y:VK_the, v:[0,1,2]}
    ylim,'VK_the',-45,45,0
    options,'VK_the','ytitle','VK The!cAPP'
    options,'VK_the','colors',icols
    options,'VK_the','yticks',2
    options,'VK_the','yminor',3
    options,'VK_the','constant',0
    options,'VK_the','labels',species
    options,'VK_the','labflag',1
    pans = [pans, 'VK_the']

; Shape Parameter

    store_data,'Shape_PAD2',data={x:result_h.time, y:transpose(result_h.shape^2.), v:[0,1]}
    ylim,'Shape_PAD2',0,5,0
    options,'Shape_PAD2','yminor',1
    options,'Shape_PAD2','constant',1
    options,'Shape_PAD2','ytitle','Shape'
    options,'Shape_PAD2','colors',[cols.blue,cols.red]
    options,'Shape_PAD2','labels',['away','toward']
    options,'Shape_PAD2','labflag',1

    store_data,'flux40',data={x:result_h.time, y:result_h.flux40}
    ylim,'flux40',0.1,1000,1
    options,'flux40','ytitle','Eflux/1e5!c40 eV'
    options,'flux40','constant',1
    options,'flux40','colors',cols.green

    store_data,'ratio',data={x:result_h.time, y:result_h.ratio}
    ylim,'ratio',0,2.5,0
    options,'ratio','ytitle','Flux Ratio!caway/twd!cPA 0-30'
    options,'ratio','constant',[0.75,1]
    options,'ratio','colors',cols.green

    pans = [pans, 'Shape_PAD2', 'flux40', 'ratio']

; Topology and Plasma Region

    store_data,'topo',data={x:result_h.time, y:result_h.topo}
    options,'topo','colors',cols.blue
    store_data,'topo_lab',data={x:minmax(result_h.time), y:replicate(-1,2,5), v:findgen(5)}
    options,'topo_lab','labels',['?','Closed','Open-D','Open-N','Draped']
    options,'topo_lab','labflag',1
    options,'topo_lab','colors',!p.color
    store_data,'topology',data=['topo','topo_lab']
    ylim,'topology',-0.5,4.5,0
    options,'topology','ytitle','Topology'
    options,'topology','yminor',1
    options,'topology','psym',8
    options,'topology','symsize',1
    options,'topology','constant',[1.5,3.5]

    y = replicate(0,npts,2)
    y[*,0] = 5 - reform(result_h.topo)
    y[*,1] = y[*,0]
    indx = where(y eq 5, count)
    if (count gt 0) then y[indx] = 0
    bname = 'topo_bar'
    store_data,bname,data={x:result_h.time, y:y, v:[0,1]}
    ylim,bname,0,1,0
    zlim,bname,0,4,0
    options,bname,'spec',1
    options,bname,'panel_size',0.05
    options,bname,'ytitle',''
    options,bname,'yticks',1
    options,bname,'yminor',1
    options,bname,'no_interp',1
    options,bname,'xstyle',4
    options,bname,'ystyle',4
    options,bname,'no_color_scale',1

    store_data,'reg_id',data={x:result_h.time, y:result_h.region}
    options,'reg_id','psym',8
    options,'reg_id','symsize',1
    y = replicate(0,n_elements(reg_id.x),2)
    y[*,0] = reform(reg_id.y)
    y[*,1] = y[*,0]
    bname = 'reg_bar'
    store_data,bname,data={x:reg_id.x, y:y, v:[0,1]}
    ylim,bname,0,1,0
    zlim,bname,0,4,0
    options,bname,'spec',1
    options,bname,'panel_size',0.05
    options,bname,'ytitle',''
    options,bname,'yticks',1
    options,bname,'yminor',1
    options,bname,'no_interp',1
    options,bname,'xstyle',4
    options,bname,'ystyle',4
    options,bname,'no_color_scale',1

    pans = [pans, 'topology', 'reg_ids']

; Escape Flux

    flx_o2 = result_o2.den_i * result_o2.vbulk * 1.e5
    store_data,'mvn_sta_o2+_flux',data={x:result_o2.time, y:flx_o2}

    flx_o1 = result_o1.den_i * result_o1.vbulk * 1.e5
    store_data,'mvn_sta_o+_flux',data={x:result_o1.time, y:flx_o1}

    flx_h = result_h.den_i * result_h.vbulk * 1.e5
    store_data,'mvn_sta_p+_flux',data={x:result_h.time, y:flx_h}

    store_data,'flux_i+',data=['mvn_sta_p+_flux','mvn_sta_o+_flux','mvn_sta_o2+_flux']
    ylim,'flux_i+',1e4,1e10,1
    options,'flux_i+','ytitle','Ion Flux!ccm!u-2!ns!u-1!n'
    options,'flux_i+','colors',icols
    options,'flux_i+','labels',species
    options,'flux_i+','labflag',1
    pans = [pans, 'flux_i+']

; CIO Geometry

    store_data,'sthe',data={x:result_h.time, y:result_h.sthe}
    options,'sthe','colors',cols.magenta
    options,'sthe','ytitle','Sun The!cSWEA'
    options,'sthe','constant',45     ; nominal value for SWEA CIO twist

    store_data,'sthe_app',data={x:result_h.time, y:result_h.sthe_app}
    ylim,'sthe_app',-45,45,0
    options,'sthe_app','yticks',2
    options,'sthe_app','yminor',3
    options,'sthe_app','colors',cols.magenta
    options,'sthe_app','ytitle','Sun The!cAPP'
    options,'sthe_app','constant',0  ; nominal value for STATIC CIO configuration

    store_data,'rthe_app',data={x:result_h.time, y:result_h.rthe_app}
    ylim,'rthe_app',-45,45,0
    options,'rthe_app','yticks',2
    options,'rthe_app','yminor',3
    options,'rthe_app','colors',cols.magenta
    options,'rthe_app','ytitle','MSO RAM The!cAPP'
    options,'rthe_app','constant',0  ; nominal value for STATIC CIO configuration

    y = replicate(0,npts,2)
    indx = where((result_h.sthe ge 40) and (result_h.sthe le 50), count)
    if (count gt 0) then y[indx,*] = 1
    indx = where((abs(result_h.sthe_app) le 5) and $
                 (abs(result_h.rthe_app) le 10), count)
    if (count gt 0) then y[indx,*] = 2
    indx = where((result_h.sthe ge 40) and (result_h.sthe le 50) and $
                 (abs(result_h.sthe_app) le 5) and $
                 (abs(result_h.rthe_app) le 10), count)
    if (count gt 0) then y[indx,*] = 3
    bname = 'cio_bar'
    store_data,bname,data={x:result_h.time, y:y, v:[0,1]}
    ylim,bname,0,1,0
    zlim,bname,0,3,0
    options,bname,'spec',1
    options,bname,'panel_size',0.05
    options,bname,'ytitle',''
    options,bname,'yticks',1
    options,bname,'yminor',1
    options,bname,'no_interp',1
    options,bname,'xstyle',4
    options,bname,'ystyle',4
    options,bname,'no_color_scale',1

  endif

; Make copies of the results

  cio_h  = result_h
  cio_o1 = result_o1
  cio_o2 = result_o2

  success = 1

  return
  
end
