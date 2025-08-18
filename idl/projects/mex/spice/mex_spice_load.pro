;+
;
;PROCEDURE:       MEX_SPICE_LOAD
;
;PURPOSE:         
;                 Loads MEX SPICE kernels and creates a few tplot variables.
;
;INPUTS:          
;
;KEYWORDS:
;
;     STORE:      If set, the computed MEX ephemeris is stored into the common blocks.
;
;       DEG:      If set, the unit of ephemeris angles (LAT, LON, SZA) is converted to be degree.
;
;NOTE:            This routine was initially based on 'mvn_spice_load'.
;
;CREATED BY:      Takuya Hara on 2015-04-04.
;
;LAST MODIFICATION:
; $LastChangedBy: hara $
; $LastChangedDate: 2023-11-09 16:59:57 -0800 (Thu, 09 Nov 2023) $
; $LastChangedRevision: 32228 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mex/spice/mex_spice_load.pro $
;
;-
PRO mex_spice_load, trange=time, kernels=kernels, pos=pos, notplot=notplot, _extra=extra, $
                    download_only=download_only, verbose=verbose, resolution=resolution, deg=deg, store=store, clear=clear

  IF SIZE(time, /type) EQ 0 THEN get_timespan, trange $
  ELSE BEGIN
     trange = time
     IF SIZE(trange, /type) EQ 7 THEN trange = time_double(trange)
     trange = minmax(trange)
  ENDELSE

  IF undefined(clear) THEN cflg = 1 ELSE cflg = FIX(clear)
  kernels = mex_spice_kernels(/all, clear=cflg, /load, trange=trange, verbose=verbose, _extra=extra)

  IF KEYWORD_SET(download_only) THEN RETURN
  
  IF SIZE(resolution, /type) EQ 0 THEN res = 60d ELSE res = DOUBLE(resolution)  
  times = dgen(range=timerange(trange), res=res) ; 60 second time resolution is default.
  
  IF SIZE(time, /type) NE 0 THEN IF N_ELEMENTS(time) GT 2 THEN times = time
  IF SIZE(times, /type) EQ 7 THEN times = time_double(times)

  mso = spice_body_pos('MEX', 'MARS', frame='MSO', utc=times, check_obj='MEX')
  geo = spice_body_pos('MEX', 'MARS', frame='IAU_MARS', utc=times, check_obj='MEX')
  cspice_bodvrd, 'MARS', 'RADII', 3, radii
  re = TOTAL(radii[0:1])/2
  rp = radii[2]
  f= (re-rp)/re
  dprint, dlevel=3, /phelp, radii, re, f, verbose=verbose

  cspice_recgeo, geo, re, f, lon, lat, alt

  w = WHERE(lon LT 0., nw)
  IF nw GT 0 THEN lon[w] += 2. * !PI
  undefine, w, nw

  pos = {time: 0.d0, x_ss: 0., y_ss: 0., z_ss: 0., x_pc: 0., y_pc: 0., z_pc: 0., $
         alt: 0., lat: 0., elon: 0., sza: 0.}
  pos = REPLICATE(pos, N_ELEMENTS(times))
  pos.time = times
  pos.x_ss = REFORM(mso[0, *])
  pos.y_ss = REFORM(mso[1, *])
  pos.z_ss = REFORM(mso[2, *])
  pos.x_pc = REFORM(geo[0, *])
  pos.y_pc = REFORM(geo[1, *])
  pos.z_pc = REFORM(geo[2, *])
  pos.alt  = alt
  pos.lat  = lat
  pos.elon = lon
  pos.sza  = ATAN(SQRT(TOTAL(mso[1:2, *]*mso[1:2, *], 1)), mso[0, *]) 

  IF KEYWORD_SET(deg) THEN BEGIN
     pos.lat  *= !RADEG
     pos.elon *= !RADEG
     pos.sza  *= !RADEG
     pos.elon = (pos.elon + 360. MOD 360.)
  ENDIF 

  IF KEYWORD_SET(store) THEN BEGIN
     COMMON mex_eph_dat, mex_eph
     mex_eph = {time: 0.d0, mso: REPLICATE(0.d0, 3), geo: REPLICATE(0.d0, 3), alt: 0.d0, lat: 0.d0, lon: 0.d0, sza: 0.d0}
     mex_eph = REPLICATE(mex_eph, N_ELEMENTS(times))
     mex_eph.time = pos.time
     mex_eph.mso  = TRANSPOSE([ [pos.x_ss], [pos.y_ss], [pos.z_ss] ])
     mex_eph.geo  = TRANSPOSE([ [pos.x_pc], [pos.y_pc], [pos.z_pc] ])
     mex_eph.alt  = pos.alt
     mex_eph.lat  = pos.lat
     mex_eph.lon  = pos.elon
     mex_eph.sza  = pos.sza
  ENDIF 

  IF KEYWORD_SET(notplot) THEN RETURN
  
  lon *= !RADEG
  lat *= !RADEG
  sza  = pos.sza * !RADEG

  store_data, 'mex_eph_mso', data={x: times, y: TRANSPOSE(mso)}, $
              dlimit={ytitle: 'MEX', ysubtitle: 'MSO [km]', constant: 0, labels: ['X', 'Y', 'Z'], labflag: -1, colors: 'bgr'}
  store_data, 'mex_eph_lat', data={x: times, y: lat}, $
              dlimit={ytitle: 'MEX', ysubtitle: 'LAT [deg]', yticks: 4, yminor: 3, constant: 0, psym: 3}
  ylim, 'mex_eph_lat', -90, 90, 0, /def
  store_data, 'mex_eph_lon', data={x: times, y: lon}, $
              dlimit={ytitle: 'MEX', ysubtitle: 'LON [deg]', yticks: 4, yminor: 3, psym: 3}
  ylim, 'mex_eph_lon', 0, 360, 0, /def
  store_data, 'mex_eph_alt', data={x: times, y: alt}, $
              dlimit={ytitle: 'MEX', ysubtitle: 'ALT [km]', ylog: 1}
  store_data, 'mex_eph_sza', data={x: times, y: sza}, $
              dlimit={ytitle: 'MEX', ysubtitle: 'SZA [deg]', yticks: 4, yminor: 3, psym: 3}
  ylim, 'mex_eph_sza', 0, 180, 0, /def
  RETURN 
END 
