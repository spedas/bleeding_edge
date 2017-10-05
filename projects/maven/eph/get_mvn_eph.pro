;+
;
;PROCEDURE:       GET_MVN_EPH
;
;PURPOSE:         Loads the MAVEN ephemeris data. The result is
;                 packaged into a common block structure and returned.
;
;                 The available coordinate frames are:
;
;                 GEO = body-fixed Mars geographic coordinates (non-inertial) = IAU_MARS
;                 (sometimes called planetocentric (PC) coordinates)
;                 X ->  0 deg E longitude, 0 deg latitude
;                 Y -> 90 deg E longitude, 0 deg latitude
;                 Z -> 90 deg N latitude (= X x Y)
;                 origin = center of Mars
;                 units = kilometers
;
;                 MSO = Mars-Sun-Orbit coordinates (approx. inertial)
;
;                 X -> from center of Mars to center of Sun
;                 Y -> opposite to Mars' orbital angular velocity vector
;                 Z = X x Y
;                 origin = center of Mars
;                 units = kilometers
;
;USAGE:           get_mvn_eph, trange, eph
;
;INPUTS:
;
;    tvar:        An array in any format accepted by time_double().
;                 You explicitly input the specified time you want to get.
;
;    eph:         A named variable to hold the result.
;
;KEYWORDS:
;
;    resolution:  The time resolution with which you want to get
;                 the ephemeris data can be determined.
;
;    silent:      Minimizes the information shown in the terminal.
;
;    make_array:  Even if you do not use the "resolution" keyword,  
;                 10,000 elements structure array is automatically returned.
;
;    status:      Returns the calculation status:
;                 0 = no data found
;                 1 = partial data found
;                 2 = complete data found
;
;    load:        If set, it forces to compute the ephemeris data,
;                 i.e., 'mvn_eph_resample' is not used.
;
;    no_download: If set, the SPICE/kernels stored in the local platform
;                 are loaded.
;
;    lst:         Specifies whether it computes the local time or not, 
;                 because 'FOR' loop is used. Default is lst = 1.
;
;CREATED BY:	  Takuya Hara on 2014-10-07.
;
;LAST MODIFICATION:
; $LastChangedBy: hara $
; $LastChangedDate: 2017-02-22 16:18:59 -0800 (Wed, 22 Feb 2017) $
; $LastChangedRevision: 22853 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/eph/get_mvn_eph.pro $
;
;-
PRO get_mvn_eph, tvar, eph, resolution=res, silent=sil, load=load, lst=local_time, $
                 make_array=make_array, status=status, verbose=vb, no_download=no_download

  @mvn_eph_com
  R_m = 3389.9d0
  nan = !values.f_nan
  IF keyword_set(sil) THEN silent = sil ELSE silent = 0
  IF keyword_set(vb) THEN verbose = vb ELSE verbose = 0 
  verbose -= silent

  IF SIZE(trange, /type) EQ 0 THEN trange = tvar
  IF SIZE(trange, /type) EQ 7 THEN trange = time_double(trange)

  IF (SIZE(res, /type) EQ 0) AND (keyword_set(make_array)) THEN $
     res = 1 > (trange[1]-trange[0])/10000d < 86400
  IF SIZE(res, /type) NE 0 THEN $     
     utc = dgen(range=trange, resolution=res) $
  ELSE utc = trange

  IF SIZE(local_time, /type) EQ 0 THEN sflg = 1 ELSE sflg = FIX(local_time)

  lflg = 0
  IF SIZE(mvn_eph_dat, /type) NE 8 THEN lflg = 1 $
  ELSE IF (MIN(utc) LT MIN(mvn_eph_dat.time)) OR $
     (MAX(utc) GT MAX(mvn_eph_dat.time)) THEN lflg = 1
  IF keyword_set(load) THEN lflg = 1
  IF (lflg) THEN BEGIN
     mvn_eph_dat = 0.
     mk = mvn_spice_kernels(/load, /all, trange=trange, verbose=verbose, no_download=no_download)

     dformat = {t: 0D, x: 0D,  y: 0D, z: 0D, vx: 0D, vy: 0D, vz: 0D}

     object = ['MARS', 'MAVEN_SPACECRAFT'] 
     valid = spice_valid_times(time_ephemeris(utc), object=object)
     idx = WHERE(valid NE 0, ndat)
     dprint, dlevel=2, verbose=verbose, ndat, ' Valid times from:', object
     IF ndat EQ 0 THEN BEGIN
        dprint, 'Insufficient SPICE/kernels data.'
        status = 0
        RETURN
     ENDIF 

     IF ndat NE N_ELEMENTS(utc) THEN BEGIN
        dprint, 'SPICE/kernels data is partially available.'
        status = 1
     ENDIF 
     undefine, idx, ndat 
     ;pos_ss = spice_body_pos('MAVEN', 'MARS', utc=utc, frame='MSO')
     vss    = spice_body_vel('MAVEN', 'MARS', utc=utc, frame='MSO', pos=pos_ss)
     pos_pc = spice_body_pos('MAVEN', 'MARS', utc=utc, frame='IAU_MARS')

     maven = REPLICATE(dformat, N_ELEMENTS(utc))
     maven_g = maven
  
     maven.t = utc
     maven.x = REFORM(pos_ss[0, *])
     maven.y = REFORM(pos_ss[1, *])
     maven.z = REFORM(pos_ss[2, *])
     maven.vx = REFORM(vss[0, *])
     maven.vy = REFORM(vss[1, *])
     maven.vz = REFORM(vss[2, *])
     maven_g.t = utc
     maven_g.x = REFORM(pos_pc[0, *])
     maven_g.y = REFORM(pos_pc[1, *])
     maven_g.z = REFORM(pos_pc[2, *])
     undefine, pos_ss, vss, dformat
     
     time = maven.t
     xss = maven.x
     yss = maven.y
     zss = maven.z
     vx  = maven.vx
     vy  = maven.vy
     vz  = maven.vz

     r = SQRT(xss*xss + yss*yss + zss*zss)
     s = SQRT(yss*yss + zss*zss)
     sza = ATAN(s, xss)
     
     xpc = maven_g.x
     ypc = maven_g.y
     zpc = maven_g.z

     cspice_bodvrd, 'MARS', 'RADII', 3, radii
     re = TOTAL(radii[0:1])/2
     rp = radii[2]
     f = (re-rp)/re

     cspice_recgeo, pos_pc, re, f, lon, lat, hgt
     undefine, pos_pc
    
     idx = WHERE(lon LE 0., count)
     IF (count GT 0L) THEN lon[idx] += 2.*!DPI
     undefine, idx

     ndat = N_ELEMENTS(time)

     IF (sflg) THEN BEGIN
        lst = FLTARR(ndat)
        FOR i=0L, ndat-1L DO BEGIN
           cspice_et2lst, time_ephemeris(utc[i]), 499, lon[i], 'PLANETOCENTRIC', $
                          hr, min, sec, ltm, ampm
           lst[i] = FLOAT(hr) + (FLOAT(min)/60.) + (FLOAT(sec)/3600.)
           undefine, hr, min, sec, ltm, ampm
        ENDFOR 
     ENDIF 
     eph = mvn_eph_struct(ndat, init=nan)
     eph.time = time
     eph.x_ss = xss
     eph.y_ss = yss
     eph.z_ss = zss
     eph.vx_ss = vx
     eph.vy_ss = vy
     eph.vz_ss = vz
     eph.x_pc = xpc
     eph.y_pc = ypc
     eph.z_pc = zpc
     eph.elon = lon
     eph.lat = lat
     eph.alt = hgt
     eph.sza = sza
     IF (sflg) THEN eph.lst = lst
     mvn_eph_dat = eph
  ENDIF ELSE $
     mvn_eph_resample, utc, mvn_eph_dat, eph 

  IF SIZE(status, /type) EQ 0 THEN status = 2
  RETURN
END 
