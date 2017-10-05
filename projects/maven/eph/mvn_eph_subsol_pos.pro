;+
;
;PROCEDURE:       MVN_EPH_SUBSOL_POS
;
;PURPOSE:         Computes Mars subsolar points in the geographic
;                 latitude and east longitude, and makes tplot variables. 
;
;INPUTS:          
;
;       TRANGE:   An array in any format accepted by time_double().
;                 The minimum and maximum pairs for the time array specify
;                 the time range to compute.
;
;KEYWORDS:
;
;        ORBIT:   Specifies the time range by orbit number or range of
;                 orbit numbers (trange is ignored). Orbits are numbered
;                 using the NAIF convention, where the orbit number 
;                 increments at periapsis. Data are loaded from the 
;                 apoapsis preceding the first orbit (periapsis) number  
;                 to the apoapsis following the last orbit number.
;
;   RESOLUTION:   Sets the time resolution to compute in sec. 
;                 Default = 1 sec.   
;
;         DATA:   Returns the conputed result as a structure.
;
;       RADIAN:   If set, the computed unit set to be radian.
;                 Default is degree.
;
;           LS:   Computes also the Martian solar longitude (=Ls).
;
;CREATED BY:      Takuya Hara on 2015-03-27.
;
;LAST MODIFICATION:
; $LastChangedBy: hara $
; $LastChangedDate: 2015-04-12 17:04:33 -0700 (Sun, 12 Apr 2015) $
; $LastChangedRevision: 17298 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/eph/mvn_eph_subsol_pos.pro $
;
;-
PRO mvn_eph_subsol_pos, var, orbit=orbit, verbose=verbose, $
                        resolution=resolution, data=data,  $
                        radian=radian, ls=ls 

  nan = !values.f_nan
  dnan = !values.d_nan
  tplot_options, get_opt=topt
  IF SIZE(var, /type) NE 0 THEN BEGIN
     trange = time_double(var)
     IF N_ELEMENTS(trange) LT 2 THEN BEGIN
        dprint, 'The time range must be two elements array like [tmin, tmax].'
        RETURN
     ENDIF ELSE BEGIN
        IF N_ELEMENTS(trange) GT 2 THEN BEGIN
           utc = trange
           trange = minmax(trange)
        ENDIF 
     ENDELSE 
  ENDIF ELSE BEGIN
     IF keyword_set(orbit) THEN BEGIN
        imin = MIN(orbit, max=imax)
        trange = mvn_orbit_num(orbnum=[imin-0.5, imax+0.5])
        undefine, imin, imax
     ENDIF

     tspan_exists = (MAX(topt.trange_full) GT 0.d0)
     IF (tspan_exists) THEN trange = topt.trange_full
     undefine, tspan_exists
  ENDELSE

  IF SIZE(trange, /type) EQ 0 THEN BEGIN
     dprint, 'You must set the specified time interval to load.'
     RETURN
  ENDIF

  IF keyword_set(resolution) THEN dt = resolution ELSE dt = 1.d0

  mk = spice_test('*')
  idx = WHERE(mk NE '', nidx)
  IF nidx EQ 0 THEN mvn_spice_load, trange=trange, verbose=verbose, /download_only
  undefine, idx, nidx
 
  IF ((SIZE(utc, /type) NE 0) AND (keyword_set(resolution))) OR $ 
     SIZE(utc, /type) EQ 0 THEN utc = dgen(range=trange, resolution=dt) 
  ndat = N_ELEMENTS(utc)

  cspice_bodvrd, 'MARS', 'RADII', 3, radii
  re = radii[0]
  rp = radii[2]
  f = (re - rp) / re
  method = 'Near point: ellipsoid'
  
  IF keyword_set(radian) THEN unit = 'rad' ELSE unit = 'deg'
  data = {time: REPLICATE(dnan, ndat), lat: REPLICATE(nan, ndat), $
          elon: REPLICATE(nan, ndat), unit: unit}
  data.time = utc
  et = time_ephemeris(utc)

  FOR i=0L, ndat-1L DO BEGIN
     cspice_subslr, method, 'MARS', et[i], 'IAU_MARS', 'LT+S', 'MAVEN', spoint, trgepc, srfvec
     cspice_recpgr, 'MARS', spoint, re, f, lon, lat, spgalt
     lon = lon * cspice_dpr()
     lat = lat * cspice_dpr()
     lon = 360. - lon         ; Changed on East longitude.
     IF unit EQ 'rad' THEN BEGIN
        lat = lat * !DTOR
        lon = lon * !DTOR
     ENDIF 
     data.lat[i] = lat
     data.elon[i] = lon
     undefine, spoint, trgepc, srfvec
     undefine, lon, lat, spgalt
  ENDFOR 

  IF keyword_set(ls) THEN BEGIN
     sl = FLTARR(ndat)
     FOR i=0L, ndat-1 DO $
        sl[i] = cspice_dpr() * cspice_lspcn('MARS', et[i], 'LT+S')
     IF unit EQ 'rad' THEN sl *= !DTOR
     str_element, data, 'ls', sl, /add
  ENDIF 

  tit = '[' + unit + ']'
  store_data, 'mvn_eph_subsol_lat', data={x: utc, y: data.lat}, $
              dlim={ytitle: 'Subsolar Lat', ysubtitle: tit, yticks: 4, yminor: 3}
  IF unit NE 'rad' THEN ylim, 'mvn_eph_subsol_lat', -90., 90., /def $
  ELSE ylim, 'mvn_eph_subsol_lat', -0.5*!PI, 0.5*!PI, /def
  store_data, 'mvn_eph_subsol_elon', data={x: utc, y: data.elon}, $
              dlim={ytitle: 'Subsolar Elon', ysubtitle: tit, yticks: 4, yminor: 3}
  IF unit NE 'rad' THEN ylim, 'mvn_eph_subsol_elon', 0., 360., /def $
  ELSE ylim, 'mvn_eph_subsol_elon', 0., 2.*!PI, /def 
  IF keyword_set(ls) THEN BEGIN
     store_data, 'mvn_eph_ls', data={x: utc, y: data.ls}, $
                 dlim={ytitle: 'Mars Ls', ysubtitle: tit, yticks: 4, yminor: 3}
     IF unit NE 'rad' THEN ylim, 'mvn_eph_ls', 0., 360., /def $
     ELSE ylim, 'mvn_eph_ls', 0., 2.*!PI, /def
  ENDIF 
  tplot_options, option=topt
  RETURN
END
