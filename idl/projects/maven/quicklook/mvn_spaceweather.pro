;+
;
;PROCEDURE:       MVN_SPACEWEATHER
;
;PURPOSE:         Creates tplot variables w.r.t the spaceweather events at Mars observed by MAVEN.
;                 It is anticipated that the result will be sent to the M2M/CCMC team.
;
;INPUTS:          Time range to be loaded.
;
;KEYWORDS:
;
;      PATH:      Spacifies the PATH where to output the result. Default is './' (i.e., current directory).
;
;     TPLOT:      If set, visualizes the result on the tplot window.
;                 This keyword is useful for C. Lee's spaceweather report at the MAVEN Thursday telecon.
;
;     PRINT:      If set, the result will be output to .dat file(s).
;
;   HALEKAS:      If set, J. Halekas's upstream driver file is downloaded and then used.
;
;    NOLOAD:      If users have already loaded tplot variables yet, users can skip the data loading section when it is on.
;
;      TEST:      If set, users can check whether it works well.
;
;CREATED BY:      Takuya Hara on 2022-11-04.
;
;LAST MODIFICATION:
; $LastChangedBy: hara $
; $LastChangedDate: 2023-10-18 15:16:24 -0700 (Wed, 18 Oct 2023) $
; $LastChangedRevision: 32202 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/quicklook/mvn_spaceweather.pro $
;
;-
FUNCTION mvn_spaceweather_header, swia=swia, swea=swea, sep_i=sep_i, sep_e=sep_e, swind=swind, tname=tname, alt=alt, total_sep_i=itot, total_sep_e=etot
  header = '# '
  IF KEYWORD_SET(swind) THEN BEGIN
     append_array, header, '#  Units: ' + ['Solar Wind Density (Nsw) p/cc', 'Solar Wind Velocity (Vsw) km/s']

     IF tname[3] EQ 'mvn_mag_imf_rtn_avg' THEN $
        append_array, header, '#  Units: IMF Strength (|B|), Radial (B_R), Tangential (B_T), Normal (B_N) nT' $
     ELSE append_array, header, '#  Units: IMF Strength (|B|), X_MSO (Bx), Y_MSO (By), Z_MSO (Bz) nT'

     ;append_array, header, '#  Units: ' + ['Solar Wind Density (Nsw) p/cc', 'Solar Wind Velocity (Vsw) km/s', 'IMF Strength (|B|), X_MSO (Bx), Y_MSO (By), Z_MSO (Bz) nT'] 

     append_array, header, '# Source: MAVEN - Solar Wind Ion Analyzer (SWIA), Magnetometer (MAG)'
     append_array, header, '# '
     append_array, header, '# Orbit Averaged Upstream Solar Wind Parameters at Mars'
     append_array, header, '# '

     append_array, header, '#   UT  Date   Time   Orbit   Density    Speed       IMF - '
     IF tname[3] EQ 'mvn_mag_imf_rtn_avg' THEN header[-1] += '    R        T        N' ELSE header[-1] += 'X_MSO    Y_MSO    Z_MSO'
     
     append_array, header, '# YYYY MM DD hhmmss  Number       Nsw      Vsw       |B|'
     IF tname[3] EQ 'mvn_mag_imf_rtn_avg' THEN header[-1] += '     B_R      B_T      B_N' ELSE header[-1] += '      Bx       By       Bz'
     
     ;append_array, header, '#   UT  Date   Time   Orbit   Density    Speed       IMF - X_MSO    Y_MSO    Z_MSO'
     ;append_array, header, '# YYYY MM DD hhmmss  Number       Nsw      Vsw       |B|      Bx       By       Bz'
     append_array, header, '#----------------------------------------------------------------------------------'
  ENDIF 

  IF KEYWORD_SET(swia) THEN BEGIN
     get_data, 'mvn_swis_en_eflux', data=d
     energy = REFORM(d.v[0, *])
     nene = N_ELEMENTS(energy)
     
     append_array, header, '#  Units: Ion Omni-directional Differential Energy Flux eV/(cm^2.s.str.eV)'
     append_array, header, '# Source: MAVEN - Solar Wind Ion Analyzer (SWIA)'
     append_array, header, '# '
     append_array, header, '#   UT  Date   Time      Energy - ' + roundst(nene) + ' bins (eV)'
     append_array, header, '# YYYY MM DD hhmmss      ' + STRING(STRING(energy, '(e8.2)'), '(' + roundst(nene) + '(A0, :, "      "))')

     length = STRLEN(header[-1])
     append_array, header, '#' + STRJOIN(REPLICATE('-', length)) 
  ENDIF 

  IF KEYWORD_SET(swea) THEN BEGIN
     get_data, 'mvn_swe_etspec', data=d
     energy = d.v
     nene = N_ELEMENTS(energy)
     
     append_array, header, '#  Units: Electron Omni-directional Differential Energy Flux eV/(cm^2.s.str.eV)'
     append_array, header, '# Source: MAVEN - Solar Wind Electron Analyzer (SWEA)'
     append_array, header, '# '
     append_array, header, '#   UT  Date   Time      Energy - ' + roundst(nene) + ' bins (eV)'
     append_array, header, '# YYYY MM DD hhmmss      ' + STRING(STRING(energy, '(e8.2)'), '(' + roundst(nene) + '(A0, :, "      "))')

     length = STRLEN(header[-1])
     append_array, header, '#' + STRJOIN(REPLICATE('-', length))
  ENDIF

  IF KEYWORD_SET(sep_i) THEN BEGIN
     get_data, 'mvn_sep1f_ion_eflux', data=d
     energy = d.v[0, *]
     nene = N_ELEMENTS(energy)
     
     append_array, header, '#  Units: Solar Energetic Ion Differential Energy Flux keV/(cm^2.s.str.keV)'
     append_array, header, '# Source: MAVEN - Solar Energetic Particle (SEP) instrument'
     append_array, header, '# '
     append_array, header, '#   UT  Date   Time      Energy - ' + roundst(nene) + ' bins (keV)'
     append_array, header, '# YYYY MM DD hhmmss      ' + STRING(STRING(energy, '(e8.2)'), '(' + roundst(nene) +'(A0, :, "      "))')

     length = STRLEN(header[-1])
     append_array, header, '#' + STRJOIN(REPLICATE('-', length))
  ENDIF

  IF KEYWORD_SET(sep_e) THEN BEGIN
     get_data, 'mvn_sep1f_elec_eflux', data=d
     energy = d.v[0, *]
     nene = N_ELEMENTS(energy)

     append_array, header, '#  Units: Solar Energetic Electron Differential Energy Flux keV/(cm^2.s.str.keV)'
     append_array, header, '# Source: MAVEN - Solar Energetic Particle (SEP) instrument'
     append_array, header, '# '
     append_array, header, '#   UT  Date   Time      Energy - ' + roundst(nene) + ' bins (keV)'
     append_array, header, '# YYYY MM DD hhmmss      ' + STRING(STRING(energy, '(e8.2)'), '(' + roundst(nene) + '(A0, :, "      "))')

     length = STRLEN(header[-1])
     append_array, header, '#' + STRJOIN(REPLICATE('-', length))
  ENDIF

  IF KEYWORD_SET(itot) THEN BEGIN
     append_array, header, '#  Units: Solar Energetic Total Flux 1/(cm^2.s.str.keV)'
     append_array, header, '# Source: MAVEN - Solar Energetic Particle (SEP) 1F instrument'
     append_array, header, '# '
     append_array, header, '#   UT  Date   Time      Energy range '
     append_array, header, '# YYYY MM DD hhmmss       1-6 MeV   100-900 keV    20-100 keV'

     length = STRLEN(header[-1])
     append_array, header, '#' + STRJOIN(REPLICATE('-', length))
  ENDIF
  
  IF KEYWORD_SET(etot) THEN BEGIN
     append_array, header, '#  Units: Solar Energetic Electron Total Flux 1/(cm^2.s.str.keV)'
     append_array, header, '# Source: MAVEN - Solar Energetic Particle (SEP) 1F instrument'
     append_array, header, '# '
     append_array, header, '#   UT  Date   Time      Energy range (keV)'
     append_array, header, '# YYYY MM DD hhmmss      100-200       20-100  '

     length = STRLEN(header[-1])
     append_array, header, '#' + STRJOIN(REPLICATE('-', length))
  ENDIF
  
  IF KEYWORD_SET(alt) THEN BEGIN
     append_array, header, '#  Units: Altitude (km)'
     append_array, header, '#  Units: Plasma Regime Indices (dimensionless)'
     append_array, header, '#         based on the Martian empirical boundary model (Trotignon et al., 2006): '
     append_array, header, '#         0: Upstream Solar Wind, 1: Sheath, 2: MPR, 3: EUV Shadow'
     append_array, header, '# Source: MAVEN'
     append_array, header, '# '
     append_array, header, '#   UT  Date   Time       Altitude    Plasma Regime Index'
     append_array, header, '# YYYY MM DD hhmmss   '
     append_array, header, '#----------------------------------------------------------------------------------'
  ENDIF 
  RETURN, header
END

FUNCTION mvn_spaceweather_regid, pos
  rm = 3389.50D
  ;;;rm = 3389.9
  x = pos[*, 0] / rm
  y = pos[*, 1] / rm
  z = pos[*, 2] / rm

  r = (x^2 + y^2 + z^2)^.5
  s = (y^2 + z^2)^.5
  
  idx = REPLICATE(0, N_ELEMENTS(x)) ;- 0: SW
  
  x0 = 0.600  &  ecc = 1.026  &  L = 2.081
  phm   = 160. * !DTOR
  phi   = ATAN(s, (x - x0))
  rho_s = SQRT((x - x0)^2. + s*s)
  shock = L / (1. + ecc*COS(phi < phm))
  w = WHERE(rho_s LT shock, nw)
  IF nw GT 0 THEN idx[w] = 1    ;- 1: sheath
  undefine, w, nw
  
  x0 = 0.640  &  ecc = 0.770  &  L = 1.080
  phi   = ATAN(s, (x - x0))
  rho_p = SQRT((x - x0)^2. + s*s)
  mpb   = L / (1. + ecc*COS(phi))
  w = WHERE(x GT 0 AND rho_p LT mpb, nw)
  IF nw GT 0 THEN idx[w] = 2    ;- 2: MPR
  undefine, w, nw
  
  x0 = 1.600  &  ecc = 1.009  &  L = 0.528
  phi   = ATAN(s, (x - x0))
  phm   = 160. * !DTOR
  rho_p = SQRT((x - x0)^2. + s*s)
  mpb   = L / (1. + ecc*COS(phi < phm))
  w = WHERE(x LE 0 AND rho_p LT mpb, nw)
  IF nw GT 0 THEN idx[w] = 2    ;- 2: MPR
  undefine, w, nw

  shadow = 1. + (150.d0/rm)
  w = WHERE(x LE 0 AND s LE shadow, nw )
  IF nw GT 0 THEN idx[w] = 3    ;- 3: EUV shadow

  RETURN, idx
END 

PRO mvn_spaceweather_plasma_regime, tname, verbose=verbose, only_swind=only_swind, above_msph=above_msph, min_alt=min_alt
  ntplot = N_ELEMENTS(tname)

  IF KEYWORD_SET(only_swind) THEN rmin = 0
  IF KEYWORD_SET(above_msph) THEN rmin = 1
  IF undefined(min_alt) THEN amin = 0.d0 ELSE amin = DOUBLE(min_alt)

  eph = maven_orbit_eph()
  
  FOR i=0, ntplot-1 DO BEGIN
     get_data, tname[i], data=d
     time = d.x
     tinterpol_mxn, {x: eph.time, y: eph.mso_x}, time, out=mso
     tinterpol_mxn, {x: eph.time, y: eph.alt}, time, out=alt

     mso = mso.y
     alt = alt.y
     regid = mvn_spaceweather_regid(mso)

     w = WHERE(regid LE rmin AND alt GE amin, nw, complement=v)
     d.y[v, *] = !values.f_nan
     store_data, tname[i], data=d
     ;IF nw GT 0 THEN store_data, tname[i], data={x: d.x[w], y: d.y[w, *], v: (ndimen(d.v) EQ 2 ? d.v[w, *] : d.v)} $
     ;ELSE dprint, dlevel=2, verbose=verbose, 'No data found.'
          
     undefine, d, time, mso, alt, regid, w, nw
  ENDFOR
  
  RETURN
END 

PRO mvn_spaceweather_tplot, data=data, limits=limits
  lim = limits
  
  IF ~tag_exist(lim, 'ystyle', /quiet) THEN BEGIN
     str_element, lim, 'yrange', /delete
     yflg = 1
  ENDIF ELSE yflg = 0
  
  IF tag_exist(lim, 'y2axis', /quiet) THEN BEGIN
     str_element, lim, 'y2axis', y2axis
     get_data, tnames(y2axis), alim=alim2
     ;IF tag_exist(alim2, 'ysubtitle', /quiet) THEN BEGIN
     ;   IF tag_exist(alim2, 'ytitle', /quiet) THEN str_element, alim2, 'ytitle', alim2.ytitle + '!C' + alim2.ysubtitle, /add_replace $
     ;   ELSE str_element, alim2, 'ytitle', alim2.ysubtitle, /add
     ;ENDIF 
     str_element, alim2, 'ytitle', alim2.ysubtitle, /add_replace
     extract_tags, lim, alim2, /axis

     str_element, lim, 'xstyle', 5, /add_replace
     str_element, lim, 'ystyle', ystyle
     IF undefined(ystyle) THEN ystyle = 0
     str_element, lim, 'ystyle', 4 + ystyle, /add_replace
     str_element, lim, 'overplot', 0, /add_replace

     str_element, lim, 'color', color
     str_element, lim, 'colors', color
     IF undefined(color) THEN str_element, lim, 'color', 1, /add
     
     IF (yflg) THEN BEGIN
        mplot, data=data, lim=lim
        yrange = !y.crange
        extract_tags, alim, lim, /axis
        alim.ystyle = 1
        IF ~undefined(color) THEN str_element, alim, 'color', color, /add
        axis, /yaxis, _extra=alim, yrange=yrange
     ENDIF ELSE BEGIN
        extract_tags, alim, lim, /axis
        str_element, alim, 'yaxis', 1, /add
        str_element, alim, 'ystyle', 1, /add_replace
        IF ~undefined(color) THEN str_element, alim, 'color', color, /add
        str_element, lim, 'axis', alim, /add
        mplot, data=data, lim=lim
     ENDELSE 
  ENDIF ELSE BEGIN
     str_element, lim, 'ystyle', ystyle
     IF undefined(ystyle) THEN ystyle = 0
     str_element, lim, 'ystyle', 8 + ystyle, /add_replace
     mplot, data=data, limits=lim
  ENDELSE 
  RETURN
END 

PRO mvn_spaceweather_sep_load
  t0 = SYSTIME(/sec)
  mvn_sep_load, /lowres
  t1 = SYSTIME(/sec)
  
  get_data, 'mvn_5min_SEP1F_ion_flux', data=flux1fion
  hi = [20:27]
  md = [12:19]
  lo = [0:11]

  store_data, 'mvn_sep1f_5min_ion_flux_total', data={x: flux1fion.x, y: [ [TOTAL(flux1fion.y[*, hi], 2)], [TOTAL(flux1fion.y[*, md], 2)], [TOTAL(flux1fion.y[*, lo], 2)] ]}, $
              dlimits={ylog:1, ytickunits: 'scientific', ytitle: 'SEP 1F!CIon FLUX', ysubtitle: '[#/cm!E2!N/sr/s/keV]', colors: 'rbx', yrange: [1.e-3, 1.e6], ystyle: 1, $
                       labels: ['1-6 MeV', '100-900 keV', '20-100 keV'], labflag: 1}, lim={ysubtitle: 'Intensity'}

  get_data, 'mvn_5min_SEP1F_elec_flux', data=flux1felec
  md = [7:12]
  hi = [11:14]
  store_data, 'mvn_sep1f_5min_elec_flux_total', data={x: flux1felec.x, y: [ [TOTAL(flux1felec.y[*, hi], 2)], [TOTAL(flux1felec.y[*, md], 2)] ]}, $
              dlimits={ylog:1, ytickunits: 'scientific', ytitle: 'SEP 1F!Ce!E-!N FLUX', ysubtitle: '[#/cm!E2!N/sr/s/keV]', colors: 'bx', yrange: [1.e-2, 1.e6], ystyle: 1, $
                       labels: ['100-200 keV', '20-100 keV'], labflag: 1}, lim={ysubtitle: 'Intensity'}

  all_tplots = tnames('*', create_time=ctime)
  w = WHERE(ctime GT t0 AND ctime LT t1, nw)
  IF nw GT 0 THEN store_data, all_tplots[w], /delete
  
  RETURN
END 

PRO mvn_spaceweather_swind, itime, verbose=verbose, no_delete=no_delete, regid=regid, npo=npo
  trange = itime
  IF is_string(trange) THEN trange = time_double(trange)
  psym = 8

  mvn_spice_load, trange=trange, /download_only, verbose=verbose

  ; SWIA
  mvn_swia_load_l2_data, /loadall, trange=trange, tplot=0
  
  ; MAG
  mvn_mag_load, trange=trange, spice_frame='MAVEN_MSO'
  get_data, 'mvn_B_1sec', alim=alim
  lvl = alim.level
  store_data, 'mvn_B_1sec', /delete, verbose=verbose
  mvn_mag_load, 'L2_full'

  ; S/C Ephemeris in MSO coordiates
  spice_position_to_tplot, 'MAVEN', 'Mars', frame='MSO', /res, /scale, $
                           basename='mvn_eph_mso', trange=trange
  bdata = 'mvn_B_1sec_MAVEN_MSO'
  fbdata = 'mvn_B_full'
  pdata = 'mvn_eph_mso'
  IF undefined(regid) THEN mvn_swia_regid, bdata=bdata, fbdata=fbdata, pdata=pdata, regid, tr=trange
  store_data, [fbdata, pdata], /delete, verbose=verbose

  IF undefined(npo) THEN npo = 1
   
  mvn_swia_swindave, reg=regid, npo=npo, /imf, bdata=bdata

  options, 'regid', ytitle='', yticks=1, yminor=1, labels='regid', spec=1, $
           no_color_scale=1, ytickname=[' ', ' '], labflag=1, /def

  get_data, bdata, data=b
  append_array, levels, REPLICATE(LONG(STRMID(lvl, 1)), N_ELEMENTS(b.x))
  store_data, 'mvn_mag_level_1sec', data={x: b.x, y: levels}, $
              dlim={panel_size: 0.2, yrange: [-0.5, 2.5], ytickinterval: 1, ystyle: 1, $
                    psym: 10, yminor: 1, ytitle: 'MAG', ysubtitle: 'Level'}
  undefine, b, alim

  swim = SCOPE_VARFETCH('swim', common='mvn_swia_data')
  ureg = INTERPOL(regid.y[*, 0], regid.x, swim.time_unix+2.0)
  indx = WHERE(ureg EQ 1, nindx)
  IF nindx EQ 0 THEN BEGIN
     dprint, 'Data not found in the solar wind region.'
     status = 0
     RETURN
  ENDIF
  time = swim.time_unix + 2.0
  uswim = swim[indx]
  tinterpol_mxn, bdata, time

  get_data, bdata + '_interp', data=b, dl=dl, lim=lim
  store_data, bdata + '_interp', /delete, verbose=verbose
  store_data, 'mvn_mag_imf_mso_all', data=b, dl=dl, lim=lim
  store_data, 'mvn_mag_imf_tot_all', data={x: b.x, y: SQRT(TOTAL(b.y*b.y, 2))}
  options, 'mvn_mag_imf_' + ['mso', 'tot'] + '_all', psym=3, ytitle='MAG', /def
  options, 'mvn_mag_imf_mso_all', ysubtitle='Bsw [nT]', /def
  options, 'mvn_mag_imf_tot_all', ysubtitle='|Bsw| [nT]', /def
  undefine, b, dl, lim

  get_data, 'bsw', data=d
  store_data, 'bsw', /delete, verbose=verbose
  get_data, 'bswstd', data=dev
  store_data, 'bswstd', /delete, verbose=verbose
  str_element, d, 'dy', dev.y, /add
  store_data, 'mvn_mag_imf_mso_avg', data=d, verbose=verbose
  undefine, d, dev

  options, 'mvn_mag_imf_mso_avg', colors='bgr', psym=psym
  get_data, 'mvn_mag_imf_tot_all', dlim=dl, data=b
  mvn_swia_upstream_ave, 'mvn_mag_imf_tot_all', regid=regid, newname='mvn_mag_imf_tot_avg', npo=npo

  get_data, 'mvn_mag_imf_tot_avg', data=b
  store_data, 'mvn_mag_imf_tot_avg', data=b, dlim=dl, lim={psym: psym}
  store_data, 'mvn_mag_imf_mso', data='mvn_mag_imf_mso_' + ['all', 'avg'], dlim={costant: 0}
  store_data, 'mvn_mag_imf_tot', data='mvn_mag_imf_tot_' + ['all', 'avg'], $
              dlim={colors: [5, 0], labels: ['All', 'Avg'], labflag: 1, color_table: 0}
  undefine, b, dl, lim

  get_data, 'mvn_mag_imf_tot_all', data=b
  store_data, 'mvn_mag_imf_tot_all', data={x: b.x[indx], y: b.y[indx]}
  get_data, 'mvn_mag_imf_mso_all', data=b
  store_data, 'mvn_mag_imf_mso_all', data={x: b.x[indx], y: b.y[indx, *]}
  undefine, b, indx
  
  time = uswim.time_unix + 2.0
  v = SQRT(TOTAL(uswim.velocity*uswim.velocity, 1))
  n = uswim.density

  store_data, 'mvn_swi_nsw_all', data={x: time, y: n}, dlim={psym: 3, ytitle: 'SWIA', ysubtitle: 'Nsw [#/cm!E3!N]'}

  get_data, 'nsw', data=d
  get_data, 'nswstd', data=dn
  store_data, ['nsw', 'nswstd'], /delete, verbose=verbose
  dn = dn.y
  str_element, d, 'dy', dn, /add
  store_data, 'mvn_swi_nsw_avg', data=d, verbose=verbose, dlim={psym: psym, ytitle: 'SWIA', ysubtitle: 'Nsw [#/cm!E3!N]'}
  undefine, d

  store_data, 'mvn_swi_nsw', data='mvn_swi_nsw_' + ['all', 'avg'], $
              dlim={colors: [175, 0], labels: ['All', 'Avg'], labflag: 1, color_table: 0}

  store_data, 'mvn_swi_vsw_all', data={x: time, y: v}, dlim={psym: 3, ytitle: 'SWIA', ysubtitle: 'Vsw [km/s]'}

  get_data, 'vsw', data=d
  get_data, 'vswstd', data=dv
  store_data, ['vsw', 'vswstd'], /delete, verbose=verbose
  dv = dv.y
  str_element, d, 'dy', dv, /add
  store_data, 'mvn_swi_vsw_avg', data=d, verbose=verbose, dlim={psym: psym, ytitle: 'SWIA', ysubtitle: 'Vsw [km/s]'}
  undefine, d

  store_data, 'mvn_swi_vsw', data='mvn_swi_vsw_' + ['all', 'avg'], $
              dlim={colors: [175, 0], labels: ['All', 'Avg'], labflag: 1, color_table: 0}

  options, 'mvn_swi_' + ['n', 'v'] + 'sw_avg', psym=psym, /def

  mp = 1.672d-27
  store_data, 'mvn_swi_pdyn_all', data={x: time, y: n * 1.d6 * v * v * 1.d6 * 1.d9 * mp}, $
              dlim={ytitle: 'SWIA', ysubtitle: 'Pdyn [nPa]', psym: 3}
  undefine, n, v
  get_data, 'mvn_swi_nsw_avg', data=n
  get_data, 'mvn_swi_vsw_avg', data=v

  dev = SQRT( (v.y^4.)*(dn^2.) + 2.d*n.y*v.y*(dv^2.) ) * 1.d21 * mp ; Error propagation
  store_data, 'mvn_swi_pdyn_avg', data={x: n.x, y: n.y * 1.d6 * v.y * v.y * 1.d6 * 1.d9 * mp, dy: dev}, $
              dlim={ytitle: 'SWIA', ysubtitle: 'Pdyn [nPa]', psym: psym}

  undefine, dev, dn, dv
  store_data, 'mvn_swi_pdyn', data='mvn_swi_pdyn_' + ['all', 'avg'], $
              dlim={colors: [175, 0], labels: ['All', 'Avg'], labflag: 1, color_table: 0}

  tinterpol_mxn, 'mvn_mag_level_1sec', time
  store_data, 'mvn_mag_level_1sec_interp', newname='mvn_mag_imf_level'
  store_data, 'mvn_mag_level_1sec', /delete, verbose=verbose
  options, 'mvn_mag_imf_level', psym=3, /def

  store_data, ['orbnum', bdata, $
               'magave', 'magstd', 'magstd2'], /delete, verbose=verbose
  
  RETURN
END

PRO mvn_spaceweather, itime, reset=reset, verbose=verbose, path=path, tplot=tplot, window=window, psym=psym,    $
                      print=print, test=test, noload=noload, halekas=halekas, rtn=rtn, no_download=no_download, $
                      only_swind=only_swind, above_msph=above_msph, min_alt=min_alt, tavg=tavg, _extra=extra,   $
                      smooth=smooth, empirical=empirical, rawmag=rawmag, npo=npo, overplot=overplot, png=png

  t0 = SYSTIME(/sec)

  oneday = 86400.d0
  IF undefined(itime) THEN get_timespan, trange ELSE trange = itime
  IF is_string(trange) THEN trange = time_double(trange)
  IF undefined(window) THEN wnum = 0 ELSE wnum = FIX(window)
  IF undefined(path) THEN path = './' ; current directory
  IF KEYWORD_SET(print) THEN pflg = 1 ELSE pflg = 0
  IF KEYWORD_SET(noload) THEN lflg = 0 ELSE lflg = 1
  
  IF KEYWORD_SET(only_swind) THEN sflg = 1 ELSE sflg = 0
  IF KEYWORD_SET(above_msph) THEN mflg = 1 ELSE mflg = 0
  IF KEYWORD_SET(empirical) THEN eflg = 1 ELSE eflg = 0
  IF KEYWORD_SET(rawmag) THEN rflg = 1 ELSE rflg = 0
  
  phi = FINDGEN(36) * (!PI * 2 / 36.)
  phi = [ phi, phi[0] ]
  usersym, COS(phi), SIN(phi), /fill
  undefine, phi
  IF undefined(psym) THEN psym = 8

  swind_name = 'mvn_' + ['swi_' + ['nsw_', 'vsw_'], 'mag_imf_' + ['tot_', 'mso_'] ] + 'avg'
  IF (lflg) THEN BEGIN
     IF KEYWORD_SET(reset) THEN store_data, '*', /delete  
     mvn_ql_pfp_tplot, /spaceweather, euv=0

     mvn_spaceweather_sep_load
     
     ylim, 'mvn_swis_en_eflux', 20., 30.e3, 1
     ylim, 'mvn_sep*_ion_eflux', 20., 7000., 1
     ylim, 'mvn_sep*_elec_eflux', 20., 200., 1

     tnow = SYSTIME(/sec)
     
     IF KEYWORD_SET(halekas) THEN BEGIN
        jasper = spd_download(remote_file='https://homepage.physics.uiowa.edu/~jhalekas/drivers/drivers_merge_l2.tplot', local_path=path, /last, /valid)

        IF jasper[0] EQ '' THEN BEGIN
           dprint, dlevel=2, verbose=verbose, "No Halekas's Upstream Driver file found."
           RETURN
        ENDIF
        
        tplot_restore, filename=jasper[0]
        get_data, 'bsw', data=b
        store_data, 'mvn_mag_imf_mso_avg', data={x: b.x, y: b.y[*, 0:2]}
        store_data, 'mvn_mag_imf_tot_avg', data={x: b.x, y: b.y[*, 3]}
        undefine, b
        store_data, 'npsw', newname='mvn_swi_nsw_avg'
        store_data, 'vpsw', newname='mvn_swi_vsw_avg'
        store_data, ['nasw', 'tp', 'vvec', 'bsw'], /delete

        time_clip, tnames(swind_name), trange[0] - oneday, trange[1] + oneday, /replace
     ENDIF ELSE BEGIN
        IF (eflg) THEN BEGIN
           mvn_swia_load_l2_data, /loadmom, tplot=0, trange=trange
           swim = SCOPE_VARFETCH('swim', common='mvn_swia_data')
           swim = swim[WHERE(swim.time_unix GE trange[0] AND swim.time_unix LE trange[1])].time_unix + 2.d0
           regid = mvn_spaceweather_regid(TRANSPOSE(spice_body_pos('MAVEN', 'MARS', utc=swim, frame='MSO')))
           regid = {x: TEMPORARY(swim), y: regid + 1.0}
           dprint, dlevel=2, verbose=verbose, 'Using the Martian empirical plasma boundary model (Trotignon+, 2006).'
        ENDIF 
        mvn_spaceweather_swind, trange, /no_delete, regid=regid, npo=npo
        store_data, tnames(['orb*num', 'MAVEN_VEL_(Mars-MSO)', 'regid']), /delete
     ENDELSE 

     options, 'mvn_swi_nsw_avg', ytitle='MAVEN/SWIA', ysubtitle='Nsw [cm!E-3!N]'
     options, 'mvn_swi_vsw_avg', ytitle='MAVEN/SWIA', ysubtitle='Vsw [km/s]'
     options, 'mvn_mag_imf_mso_avg', ytitle='MAVEN/MAG', ysubtitle='IMF Bmso [nT]', constant=0., labels=['X', 'Y', 'Z'], labflag=-1
     options, 'mvn_mag_imf_tot_avg', ytitle='MAVEN/MAG', ysubtitle='IMF |B| [nT]'
     options, tnames('mvn_' + ['swi_' + ['nsw', 'vsw', 'pdyn'], 'mag_imf_' + ['tot', 'mso']] + '_avg'), psym=-psym
     options, swind_name[3], colors='bgr'

     IF KEYWORD_SET(rtn) THEN BEGIN
        mvn_spice_stat, summary=kernels, check=minmax(trange), /silent
        IF ~(kernels.all_check) THEN mk = mvn_spice_kernels(/all, /clear, /load, trange=minmax(trange), verbose=verbose, no_download=no_download)

        options, 'mvn_mag_imf_mso_avg', spice_frame='MAVEN_MSO'
;check for no data here, jmm, 2023-09-07
        get_data, 'mvn_mag_imf_mso_avg', data = ddd
        If(is_struct(ddd) && ddd.x[0] Gt 0) Then Begin
           spice_vector_rotate_tplot, 'mvn_mag_imf_mso_avg', 'MAVEN_SUN_RTN' ;, check_obj=['MAVEN_SPACECRAFT', 'MAVEN_MSO', 'MAVEN_SUN_RTN']
           store_data, 'mvn_mag_imf_mso_avg_MAVEN_SUN_RTN', newname='mvn_mag_imf_rtn_avg'
        
           options, 'mvn_mag_imf_rtn_avg', ysubtitle='IMF B!DRTN!N [nT]', labels=['R', 'T', 'N']
           swind_name[3] = 'mvn_mag_imf_rtn_avg'
        Endif Else dprint, dlevel = 0, 'Bad SPICE rotation data'
     ENDIF

     all_tplot = tnames('*', create_time=ctime)
     w = WHERE(ctime GT tnow, nw)
     IF nw GT 0 THEN options, all_tplot[w], datagap=8.d0 * 3600.d0

     IF KEYWORD_SET(rflg) THEN BEGIN
        mvn_mag_load, trange=trange, spice_frame='MAVEN_MSO'
        store_data, 'mvn_B_1sec', /delete
        store_data, 'mvn_B_1sec_MAVEN_MSO', newname='mvn_mag_mso'

        options, 'mvn_mag_mso', labels=['X', 'Y', 'Z'], labflag=-1, colors='bgr', /def, ytitle='Bmso [nT]'
        ylim, 'mvn_mag_mso', -20., 20., 0., /def
        xyz_to_polar, 'mvn_mag_mso', /ph_0_360
        options, 'mvn_mag_mso_mag', ytitle='|B| [nT]'
        ylim, 'mvn_mag_mso_mag', 0., 20., 0., /def
        ylim, 'mvn_mag_mso_th', -90., 90., 0, /def
        ylim, 'mvn_mag_mso_phi', 0., 360., 0, /def
        options, 'mvn_mag_mso_' + ['th', 'phi'], yticks=4, yminor=3, /def
        options, 'mvn_mag_mso_th', ytitle='Bthe [deg]', /def
        options, 'mvn_mag_mso_phi', ytitle='Bphi [deg]', /def
     ENDIF

     IF KEYWORD_SET(overplot) THEN BEGIN
        get_data, swind_name[0], index=i_nsw
        get_data, swind_name[1], index=i_vsw

        IF (i_nsw + i_vsw) EQ 0 THEN BEGIN
           ; Creating blank panels
           store_data, swind_name[0], data={x: trange, y: REPLICATE(!values.f_nan, 2)}, dlim={yrange: [0., 4.], ystyle: 1, ytitle: 'MAVEN/SWIA', ysubtitle: 'Nsw [cm!E-3!N]'}
           store_data, swind_name[1], data={x: trange, y: REPLICATE(!values.f_nan, 2)}, dlim={yrange: [0., 1000.], ystyle: 1, ytitle: 'MAVEN/SWIA', ysubtitle: 'Vsw [km/s]', colors: 2}
        ENDIF 
        
        store_data, 'mvn_swi_nv_sw_avg', data=swind_name[0:1], dlim={tplot_routine: 'mvn_spaceweather_tplot'}
        options, swind_name[1], y2axis=swind_name[1], colors=2
        get_data, swind_name[-1], data=bmso, alim=blim
        get_data, swind_name[-2], data=btot

        IF is_struct(bmso) && is_struct(btot) THEN BEGIN
           store_data, 'mvn_mag_imf_avg', data={x: bmso.x, y: [ [bmso.y], [btot.y] ]}, dlim=blim
           options, 'mvn_mag_imf_avg', labels=[blim.labels, '|B|'], colors='bgrx', /def
        ENDIF ELSE BEGIN
           ; Crating blank panels
           store_data, 'mvn_mag_imf_avg', data={x: trange, y: REFORM(REPLICATE(!values.f_nan, 8), 2, 4)}, dlim={labflag: -1, colors: 'bgrx', ytitle: 'MAVEN/MAG', constant: 0.}
           IF KEYWORD_SET(rtn) THEN options, 'mvn_mag_imf_avg', labels=['R', 'T', 'N', '|B|'], ysubtitle='IMF B!DRTN!N [nT]', /def $
           ELSE options, 'mvn_mag_imf_avg', labels=['X', 'Y', 'Z', '|B|'], ysubtitle='IMF Bmso [nT]', /def
           ylim, 'mvn_mag_imf_avg', -4., 4., /def
        ENDELSE 
     ENDIF 
  ENDIF
  
  pname = ['mvn_sep1f_ion_eflux', 'mvn_sep1f_elec_eflux', 'mvn_swis_en_eflux', 'mvn_swe_etspec']

  store_data, 'alt2', newname='mvn_eph_alt'
  options, 'mvn_eph_alt', ytickinterval=2000., ytitle='Altitude', ysubtitle='[km]'
  IF (rflg) THEN append_array, pname, 'mvn_mag_mso_' + ['mag', 'th', 'phi']
  append_array, pname, 'mvn_eph_alt'
  IF KEYWORD_SET(overplot) THEN append_array, pname, ['mvn_swi_nv_sw_avg', 'mvn_mag_imf_avg'] ELSE append_array, pname, swind_name

  IF (sflg) OR (mflg) THEN mvn_spaceweather_plasma_regime, pname[0:3 + 3 * rflg], verbose=verbose, only_swind=sflg, above_msph=mflg, min_alt=min_alt

  IF ~undefined(tavg) THEN BEGIN
     get_data, 'mvn_swe_etspec', data=d
     str_element, d, 'v', TRANSPOSE(REBIN(d.v, dimen1(d.v), dimen1(d.x), /sample)), /add_replace
     store_data, 'mvn_swe_etspec', data=TEMPORARY(d)

     IF KEYWORD_SET(smooth) THEN FOR ip=0, 3 DO tsmooth_in_time, pname[ip], DOUBLE(tavg), newname=pname[ip] $
     ELSE FOR ip=0, 3 DO avg_data, pname[ip], DOUBLE(tavg), newname=pname[ip]

     get_data, 'mvn_swe_etspec', data=d
     str_element, d, 'v', REFORM(d.v[0, *]), /add_replace
     store_data, 'mvn_swe_etspec', data=TEMPORARY(d)

     options, ['mvn_swis_en_eflux', 'mvn_swe_etspec'], 'datagap', /def
  ENDIF

  suffix = time_string(trange[0], tformat='_YYYYMMDD_') + roundst((trange[1]-trange[0])/oneday) + 'd'
  IF KEYWORD_SET(tplot) THEN BEGIN
     IF !d.name NE 'PS' THEN wi, wnum, wsize=[900, 1000]
     ;tplot_options, 'title', time_string(trange[0], tformat='YYYY-MM-DD') + ' -> ' + time_string(trange[1], tformat='YYYY-MM-DD')
     line_colors, 5

     tplot_options, 'xmargin', [14, 14]
     tplot_options, 'ymargin', [3, 1]
     ;tplot, pname, window=wnum
     tplot, [pname[0:1], tnames('mvn_sep*_total'), pname[2:*]], window=wnum

     IF KEYWORD_SET(png) THEN makepng, path + 'mvn_spaceweather' + suffix, window=wnum
  ENDIF

  suffix += '.dat'
  IF (pflg) THEN BEGIN
     h = mvn_spaceweather_header(/swind, tname=swind_name)
     
     get_data, 'mvn_swi_nsw_avg', data=nsw
     get_data, 'mvn_swi_vsw_avg', data=vsw
     get_data, 'mvn_mag_imf_tot_avg', data=btot
     get_data, swind_name[3], data=bmso

     time  = nsw.x
     w = WHERE(time GE trange[0] AND time LE trange[1], ndat)
     IF ndat GT 0 THEN BEGIN
        ;ndat = N_ELEMENTS(time)
        time = time[w]
        swind = TRANSPOSE([ [nsw.y], [vsw.y], [btot.y], [bmso.y] ])
        swind = swind[*, w]
        orbit = ROUND(mvn_orbit_num(time=time))
     ENDIF ELSE BEGIN
        dprint, dlevel=2, verbose=verbose, 'No upstream solar wind data found in the specified time range.'
        GOTO, skip_swind
     ENDELSE
     
     prefix = 'mvn_swi_mag_swind'
     IF KEYWORD_SET(test) THEN BEGIN
        l = 0L
        PRINT, ''
        dprint, 'Upstream Driver file: ', dlevel=2, verbose=verbose
        PRINT, TRANSPOSE(h)
        FOR l=0L, 4 DO $        ; Printing the first 5 data.
           PRINT, time_string(time[l], tformat='  YYYY MM DD hhmmss   ') + STRING(orbit[l], '(I5)') + '    ' + STRING(STRING(swind[*, l], '(F6.1)'), '(6(A0, :, "   "))')
        PRINT, '  ...'
        PRINT, ''
     ENDIF ELSE BEGIN
        dprint, dlevel=2, verbose=verbose, 'Creating data file: ' + prefix + suffix

        OPENW, unit, path + prefix + suffix, /get_lun
        PRINTF, unit, TRANSPOSE(TEMPORARY(h))
        FOR l=0L, ndat-1 DO $
           PRINTF, unit, time_string(time[l], tformat='  YYYY MM DD hhmmss   ') + STRING(orbit[l], '(I5)') + '    ' + STRING(STRING(swind[*, l], '(F6.1)'), '(6(A0, :, "   "))')
        CLOSE, unit
        FREE_LUN, unit
     ENDELSE 
     skip_swind:
     
     ; SWIA E-t
     h = mvn_spaceweather_header(/swia)
     get_data, 'mvn_swis_en_eflux', data=inst
     time  = inst.x
     ndat  = N_ELEMENTS(time)  
     eflux = TRANSPOSE(inst.y)
     nene  = dimen1(eflux)
     undefine, inst

     prefix = 'mvn_swi_eflux'
     IF KEYWORD_SET(test) THEN BEGIN
        l = 0L
        dprint, 'SWIA E-t: ', dlevel=2, verbose=verbose
        PRINT, STRMID(TRANSPOSE(h), 0, 100) 
        FOR l=0L, 4 DO $        ; Printing the first 5 data.
           PRINT, STRMID(time_string(time[l], tformat='  YYYY MM DD hhmmss      ') + STRING(STRING(eflux[*, l], '(e8.2)'), '(' + roundst(nene) + '(A0, :, "      "))'), 0, 100) + '    ... '
        PRINT, '  ...'
        PRINT, ''
     ENDIF ELSE BEGIN
        dprint, dlevel=2, verbose=verbose, 'Creating data file: ' + prefix + suffix

        OPENW, unit, path + prefix + suffix, /get_lun
        PRINTF, unit, TRANSPOSE(TEMPORARY(h))
        FOR l=0L, ndat-1 DO $
           PRINTF, unit, time_string(time[l], tformat='  YYYY MM DD hhmmss      ') + STRING(STRING(eflux[*, l], '(e8.2)'), '(' + roundst(nene) + '(A0, :, "      "))')
        CLOSE, unit
        FREE_LUN, unit
     ENDELSE 

     ; SWEA E-t
     h = mvn_spaceweather_header(/swea)
     get_data, 'mvn_swe_etspec', data=inst
     time  = inst.x
     ndat  = N_ELEMENTS(time)
     eflux = TRANSPOSE(inst.y)
     nene  = dimen1(eflux)
     undefine, inst

     prefix = 'mvn_swe_eflux'
     IF KEYWORD_SET(test) THEN BEGIN
        l = 0L
        dprint, 'SWEA E-t: ', dlevel=2, verbose=verbose
        PRINT, STRMID(TRANSPOSE(h), 0, 100)
        FOR l=0L, 4 DO $        ; Printing the first 5 data.
           PRINT, STRMID(time_string(time[l], tformat='  YYYY MM DD hhmmss      ') + STRING(STRING(eflux[*, l], '(e8.2)'), '(' + roundst(nene) + '(A0, :, "      "))'), 0, 100) + '    ... '
        PRINT, '  ...'
        PRINT, ''
     ENDIF ELSE BEGIN
        dprint, dlevel=2, verbose=verbose, 'Creating data file: ' + prefix + suffix
        
        OPENW, unit, path + prefix + suffix, /get_lun
        PRINTF, unit, TRANSPOSE(TEMPORARY(h))
        FOR l=0L, ndat-1 DO $
           PRINTF, unit, time_string(time[l], tformat='  YYYY MM DD hhmmss      ') + STRING(STRING(eflux[*, l], '(e8.2)'), '(' + roundst(nene) + '(A0, :, "      "))')
        CLOSE, unit
        FREE_LUN, unit
     ENDELSE 

     ; SEP 1F Ion E-t
     h = mvn_spaceweather_header(/sep_i)
     get_data, 'mvn_sep1f_ion_eflux', data=inst
     time  = inst.x
     ndat  = N_ELEMENTS(time)  
     eflux = TRANSPOSE(inst.y)
     nene = dimen1(eflux)
     undefine, inst

     prefix = 'mvn_sep1f_ion_eflux'
     IF KEYWORD_SET(test) THEN BEGIN
        l = 0L
        dprint, 'SEP 1F Ion E-t: ', dlevel=2, verbose=verbose
        PRINT, STRMID(TRANSPOSE(h), 0, 100)
        FOR l=0L, 4 DO $        ; Printing the first 5 data.
           PRINT, STRMID(time_string(time[l], tformat='  YYYY MM DD hhmmss      ') + STRING(STRING(eflux[*, l], '(e8.2)'), '(' + roundst(nene) + '(A0, :, "      "))'), 0, 100) + '    ... '
        PRINT, '  ...'
        PRINT, ''
     ENDIF ELSE BEGIN
        dprint, dlevel=2, verbose=verbose, 'Creating data file: ' + prefix + suffix
        
        OPENW, unit, path + prefix + suffix, /get_lun
        PRINTF, unit, TRANSPOSE(TEMPORARY(h))
        FOR l=0L, ndat-1 DO $
           PRINTF, unit, time_string(time[l], tformat='  YYYY MM DD hhmmss      ') + STRING(STRING(eflux[*, l], '(e8.2)'), '(' + roundst(nene) + '(A0, :, "      "))')
        CLOSE, unit
        FREE_LUN, unit
     ENDELSE 

     ; SEP 1F e- E-t
     h = mvn_spaceweather_header(/sep_e)
     get_data, 'mvn_sep1f_elec_eflux', data=inst
     time  = inst.x
     ndat  = N_ELEMENTS(time)
     eflux = TRANSPOSE(inst.y)
     nene = dimen1(eflux)
     undefine, inst

     prefix = 'mvn_sep1f_elec_eflux'
     IF KEYWORD_SET(test) THEN BEGIN
        l = 0L
        dprint, 'SEP 1F e- E-t: ', dlevel=2, verbose=verbose
        PRINT, STRMID(TRANSPOSE(h), 0, 100)
        FOR l=0L, 4 DO $        ; Printing the first 5 data.
           PRINT, STRMID(time_string(time[l], tformat='  YYYY MM DD hhmmss      ') + STRING(STRING(eflux[*, l], '(e8.2)'), '(' + roundst(nene) + '(A0, :, "      "))'), 0, 100) + '    ... '
        PRINT, '  ...'
        PRINT, ''
     ENDIF ELSE BEGIN
        dprint, dlevel=2, verbose=verbose, 'Creating data file: ' + prefix + suffix
        
        OPENW, unit, path + prefix + suffix, /get_lun
        PRINTF, unit, TRANSPOSE(TEMPORARY(h))
        FOR l=0L, ndat-1 DO $
           PRINTF, unit, time_string(time[l], tformat='  YYYY MM DD hhmmss      ') + STRING(STRING(eflux[*, l], '(e8.2)'), '(' + roundst(nene) + '(A0, :, "      "))')
        CLOSE, unit
        FREE_LUN, unit
     ENDELSE

     ; SEP 1F Ion Total
     h = mvn_spaceweather_header(/total_sep_i)
     get_data, 'mvn_sep1f_5min_ion_flux_total', data=inst
     time  = inst.x
     ndat  = N_ELEMENTS(time)
     flux = TRANSPOSE(inst.y)
     nene = dimen1(flux)
     undefine, inst

     prefix = 'mvn_sep1f_ion_flux_total'
     IF KEYWORD_SET(test) THEN BEGIN
        l = 0L
        dprint, 'SEP 1F Ion Total: ', dlevel=2, verbose=verbose
        PRINT, STRMID(TRANSPOSE(h), 0, 100)
        FOR l=0L, 4 DO $
           PRINT, STRMID(time_string(time[l], tformat='  YYYY MM DD hhmmss      ') + STRING(STRING(flux[*, l], '(e8.2)'), '(' + roundst(nene) + '(A0, :, "      "))'), 0, 100) + '    ... '
        PRINT, '  ...'
        PRINT, ''
     ENDIF ELSE BEGIN
        dprint, dlevel=2, verbose=verbose, 'Creating data file: ' + prefix + suffix

        OPENW, unit, path + prefix + suffix, /get_lun
        PRINTF, unit, TRANSPOSE(TEMPORARY(h))
        FOR l=0L, ndat-1 DO $
           PRINTF, unit, time_string(time[l], tformat='  YYYY MM DD hhmmss      ') + STRING(STRING(flux[*, l], '(e8.2)'), '(' + roundst(nene) + '(A0, :, "      "))')
        CLOSE, unit
        FREE_LUN, unit
     ENDELSE

     ; SEP 1F e- Total
     h = mvn_spaceweather_header(/total_sep_e)
     get_data, 'mvn_sep1f_5min_elec_flux_total', data=inst
     time  = inst.x
     ndat  = N_ELEMENTS(time)
     flux = TRANSPOSE(inst.y)
     nene = dimen1(flux)
     undefine, inst

     prefix = 'mvn_sep1f_elec_flux_total'
     IF KEYWORD_SET(test) THEN BEGIN
        l = 0L
        dprint, 'SEP 1F Electron Total: ', dlevel=2, verbose=verbose
        PRINT, STRMID(TRANSPOSE(h), 0, 100)
        FOR l=0L, 4 DO $
           PRINT, STRMID(time_string(time[l], tformat='  YYYY MM DD hhmmss      ') + STRING(STRING(flux[*, l], '(e8.2)'), '(' + roundst(nene) + '(A0, :, "      "))'), 0, 100) + '    ... '
        PRINT, '  ...'
        PRINT, ''
     ENDIF ELSE BEGIN
        dprint, dlevel=2, verbose=verbose, 'Creating data file: ' + prefix + suffix

        OPENW, unit, path + prefix + suffix, /get_lun
        PRINTF, unit, TRANSPOSE(TEMPORARY(h))
        FOR l=0L, ndat-1 DO $
           PRINTF, unit, time_string(time[l], tformat='  YYYY MM DD hhmmss      ') + STRING(STRING(flux[*, l], '(e8.2)'), '(' + roundst(nene) + '(A0, :, "      "))')
        CLOSE, unit
        FREE_LUN, unit
     ENDELSE
     
     ; Altitude Indices
     h = mvn_spaceweather_header(/alt)
     eph = maven_orbit_eph()
     regid = mvn_spaceweather_regid(eph.mso_x)
     w = WHERE(eph.time GE trange[0] AND eph.time LE trange[1], nw)
     prefix = 'mvn_eph_alt_indices'
     IF KEYWORD_SET(test) THEN BEGIN
        l = 0L
        dprint, 'MAVEN ALT Indices: ', dlevel=2, verbose=verbose
        PRINT, TRANSPOSE(h)
        FOR l=0L, 4 DO $        ; Printing the first 5 data.
           PRINT, time_string(eph.time[w[l]], tformat='  YYYY MM DD hhmmss      ') + STRING(eph.alt[w[l]], '(f8.2)') + '     ' + roundst(regid[w[l]])
        PRINT, '  ...'
        PRINT, ''
     ENDIF ELSE BEGIN
        dprint, dlevel=2, verbose=verbose, 'Creating data file: ' + prefix + suffix
        
        OPENW, unit, path + prefix + suffix, /get_lun
        PRINTF, unit, TRANSPOSE(TEMPORARY(h))
        FOR l=0L, nw-1 DO $
           PRINTF, unit, time_string(eph.time[w[l]], tformat='  YYYY MM DD hhmmss      ') + STRING(eph.alt[w[l]], '(f8.2)') + '     ' + roundst(regid[w[l]])
        CLOSE, unit
        FREE_LUN, unit
     ENDELSE 
  ENDIF 

  dprint, dlevel=2, verbose=verbose, 'Processing is completed: ' + time_string(SYSTIME(/sec) - t0, tformat='hh:mm:ss.fff')
  RETURN
END
