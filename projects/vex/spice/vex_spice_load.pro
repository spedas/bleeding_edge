;+
;
;PROCEDURE:       VEX_SPICE_LOAD
;
;PURPOSE:         
;                 Loads VEX SPICE kernels and creates a few tplot variables.
;
;INPUTS:          
;
;KEYWORDS:
;
;NOTE:            This routine imitates 'mvn_spice_load' and 'mex_spice_load'.
;
;CREATED BY:      Takuya Hara on 2016-07-12.
;
;LAST MODIFICATION:
; $LastChangedBy: hara $
; $LastChangedDate: 2018-04-05 23:07:21 -0700 (Thu, 05 Apr 2018) $
; $LastChangedRevision: 25007 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/vex/spice/vex_spice_load.pro $
;
;-
PRO vex_spice_load, trange=time, kernels=kernels, pos=pos, _extra=extra, $
                    download_only=download_only, verbose=verbose, resolution=resolution
  
  IF SIZE(time, /type) EQ 0 THEN get_timespan, trange $
  ELSE BEGIN
     trange = time
     IF SIZE(trange, /type) EQ 7 THEN trange = time_double(trange)
     trange = minmax(trange)
  ENDELSE
  
  kernels = vex_spice_kernels(/all, /clear, /load, trange=trange, verbose=verbose, _extra=extra)
  
  IF SIZE(resolution, /type) EQ 0 THEN res = 60d ELSE res = DOUBLE(resolution)
  times = dgen(range=timerange(trange), res=res) ; 60 second time resolution is default.

  IF SIZE(time, /type) NE 0 THEN IF N_ELEMENTS(time) GT 2 THEN times = time
  IF SIZE(times, /type) EQ 7 THEN times = time_double(times)

  vso = spice_body_pos('VEX', 'VENUS', frame='VSO', utc=times)
  geo = spice_body_pos('VEX', 'VENUS', frame='IAU_VENUS', utc=times)
  cspice_bodvrd, 'VENUS', 'RADII', 3, radii
  re = TOTAL(radii[0:1])/2
  rp = radii[2]
  f = (re-rp)/re
  dprint, dlevel=3, /phelp, radii, re, f, verbose=verbose

  cspice_recgeo, geo, re, f, lon, lat, alt

  w = WHERE(lon LT 0., nw)
  IF nw GT 0 THEN lon[w] += 2. * !PI
  undefine, w, nw

  pos = {time: 0.d0, x_ss: 0., y_ss: 0., z_ss: 0., x_pc: 0., y_pc: 0., z_pc: 0., $
         alt: 0., lat: 0., elon: 0., sza: 0.}
  pos = REPLICATE(pos, N_ELEMENTS(times))
  pos.time = times
  pos.x_ss = REFORM(vso[0, *])
  pos.y_ss = REFORM(vso[1, *])
  pos.z_ss = REFORM(vso[2, *])
  pos.x_pc = REFORM(geo[0, *])
  pos.y_pc = REFORM(geo[1, *])
  pos.z_pc = REFORM(geo[2, *])
  pos.alt  = alt
  pos.lat  = lat
  pos.elon = lon
  pos.sza  = ATAN(SQRT(TOTAL(vso[1:2, *]*vso[1:2, *], 1)), vso[0, *]) 

  IF KEYWORD_SET(download_only) THEN RETURN

  lon *= !RADEG
  lat *= !RADEG
  sza  = pos.sza * !RADEG

  store_data, 'vex_eph_vso', data={x: times, y: TRANSPOSE(vso)}, $
              dlimit={ytitle: 'VEX', ysubtitle: 'VSO [km]', constant: 0, labels: ['X', 'Y', 'Z'], labflag: -1, colors: 'bgr'}
  store_data, 'vex_eph_lat', data={x: times, y: lat}, $
              dlimit={ytitle: 'VEX', ysubtitle: 'LAT [deg]', yticks: 4, yminor: 3, constant: 0, psym: 3}
  ylim, 'vex_eph_lat', -90, 90, 0, /def
  store_data, 'vex_eph_lon', data={x: times, y: lon}, $
              dlimit={ytitle: 'VEX', ysubtitle: 'LON [deg]', yticks: 4, yminor: 3, psym: 3}
  ylim, 'vex_eph_lon', 0, 360, 0, /def
  store_data, 'vex_eph_alt', data={x: times, y: alt}, $
              dlimit={ytitle: 'VEX', ysubtitle: 'ALT [km]', ylog: 1}
  store_data, 'vex_eph_sza', data={x: times, y: sza}, $
              dlimit={ytitle: 'VEX', ysubtitle: 'SZA [deg]', yticks: 4, yminor: 3, psym: 3}
  ylim, 'vex_eph_sza', 0, 180, 0, /def
  RETURN 
END 
