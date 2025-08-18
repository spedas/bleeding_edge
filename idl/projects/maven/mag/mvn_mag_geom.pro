;+
;PROCEDURE:   mvn_mag_geom
;PURPOSE:
;  Given MAVEN magnetometer and ephemeris data, computes the azimuth,
;  elevation and clock angles of the magnetic field in the local 
;  horizontal plane at the spacecraft, and traces the magnetic
;  field in a straight line from the spacecraft to a specified
;  altitude (see ALT keyword).  This tracing calculation can be 
;  sigificantly in error when the distance to the central object is
;  large and the straight-line approximation becomes dubious.
;
;  The information is appended to the mag_pc structure with the 
;  following tags:
;
;      amp   : magnetic field amplitude (nT)
;      azim  : magnetic azimuth angle (deg)
;      elev  : magnetic elevation angle (deg)
;      clock : magnetic clock angle (deg)
;      dist  : distance along the magnetic field line between the
;              spacecraft and the trace location (km)
;      lon   : east longitude at the trace location (deg)
;      lat   : latitude at the trace location (deg)
;
;  Magnetic azimuth and elevation are defined as follows:
;
;      AZ =   0 --> East           EL =   0 --> horizontal
;      AZ =  90 --> North          EL = +90 --> radial outward (up)
;      AZ = 180 --> West           EL = -90 --> radial inward (down)
;      AZ = -90 --> South
;
;  Magnetic clock angle is an angle in the local horizontal plane
;  (like AZ) that is referenced to the azimuth of the Sun:
;
;      CLOCK =   0 --> azimuth of Sun
;      CLOCK = 180 --> opposite to azimuth of Sun
;
;USAGE:
;  mvn_mag_geom
;INPUTS:
;       None:      All data obtained from tplot variables.  The result is 
;                  stored in tplot variables.
;  
;KEYWORDS:
;       ALT:       Electron absorption altitude.  Default is 170 km for Mars
;                  and 0 km for Phobos and Deimos.
;
;       VAR:       Tplot variable name that contains the magnetic field data
;                  in payload coordinates.  Default = 'mvn_B_1sec'.  Variable
;                  names for MAG data in other frames are derived from this.
;
;       PHOBOS:    Set this keyword to trace magnetic field lines to Phobos.
;                  Good luck!  The moon is small and you have to get very
;                  close for a reasonable chance of intersection.
;
;       DEIMOS:    Set this keyword to trace magnetic field lines to Deimos.
;                  Good luck!  The moon is small and you have to get very
;                  close for a reasonable chance of intersection.
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2016-04-25 20:11:20 -0700 (Mon, 25 Apr 2016) $
; $LastChangedRevision: 20926 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/mag/mvn_mag_geom.pro $
;
;CREATED BY:	David L. Mitchell  2015-04-02
;-
pro mvn_mag_geom, alt=alt, var=var, phobos=phobos, deimos=deimos

  @maven_orbit_common

  if (size(var,/type) ne 7) then var = 'mvn_B_1sec'
  get_data, var, data=mag_pl, index=i
  if (i eq 0) then begin
    print,"No MAG data found: ", var
    return
  endif

  tmin = min(mag_pl.x, max=tmax) - 600D
  tmax += 600D

; Central object dimensions.  Use the radius of a sphere that has the same
; volume as the actual object.  This makes the geometry calculations easier,
; and is probably good enough, given the straight-line approximation for 
; magnetic field line tracing.

; Default central object is Mars.

  R_m = 3389.9D
  R_equ = 3396.2D
  R_pol = 3376.2D
  R_vol = (R_equ*R_equ*R_pol)^(1D/3D)
  if (size(alt,/type) eq 0) then alt = 170D
  to_frame = 'iau_mars'
  origin = 'Mars'

  if keyword_set(phobos) then begin
    print,"Calculating ephemeris w.r.t. Phobos ... "
    maven_orbit_makeeph, frame='PHO', origin='Phobos', eph=mpc, $
                         tstart=tmin, tstop=tmax, tstep=20D
    maven_orbit_makeeph, frame='MSO', origin='Phobos', eph=mss, $
                         tstart=tmin, tstop=tmax, tstep=20D
    moon = {pc:mpc, ss:mss}
    
    r = sqrt(mss.x^2. + mss.y^2. + mss.z^2.)
    store_data,'Phobos',data={x:mss.t, y:r}
    options,'Phobos','ytitle','Phobos Range!c(km)'
    ylim,'Phobos',0,0,1

    Rx = 13.1D
    Ry = 11.1D
    Rz =  9.3D
    R_m = (Rx*Ry*Rz)^(1D/3D)
    alt = 0D  ; no atmosphere
    to_frame = 'iau_phobos'
    origin = 'Phobos'
  endif

  if (size(deimos,/type) eq 8) then begin
    print,"Calculating ephemeris w.r.t. Deimos ... "
    maven_orbit_makeeph, frame='DEI', origin='Deimos', eph=mpc, $
                         tstart=tmin, tstop=tmax, tstep=20D
    maven_orbit_makeeph, frame='MSO', origin='Deimos', eph=mss, $
                         tstart=tmin, tstop=tmax, tstep=20D
    moon = {pc:mpc, ss:mss}
    
    r = sqrt(mss.x^2. + mss.y^2. + mss.z^2.)
    store_data,'Deimos',data={x:mss.t, y:r}
    options,'Deimos','ytitle','Deimos Range!c(km)'
    ylim,'Deimos',0,0,1

    Rx = 7.8D
    Ry = 6.0D
    Rz = 5.1D
    R_m = (Rx*Ry*Rz)^(1D/3D)
    alt = 0D  ; no atmosphere
    to_frame = 'iau_deimos'
    origin = 'Deimos'
  endif

  R_exo = R_m + alt

; Get the magnetic field in payload coordinates and rotate to the SS and PC
; frames with respect to Mars, Phobos or Deimos.  The origin does not matter,
; since the vectors are scaled to the magnetic field amplitude.  For the SS
; frame just use Mars-centered MSO.  For the PC frame, use the appropriate 
; central object, in case the magnetic field does intersect the object, and
; you would like to know where.  (The PC frame keeps track of the orientation
; of the central object as seen from the spacecraft.)
  
  spice_vector_rotate_tplot, var, 'maven_mso', check='MAVEN_SPACECRAFT'
  spice_vector_rotate_tplot, var, to_frame, check='MAVEN_SPACECRAFT'
 
  tplot_names,var+'*',names=mname

  ok = strmatch(mname,'*'+to_frame+'*',/fold)
  i = (where(ok))[0]
  if (i eq -1) then begin
    print,"You must first load MAG data in " + strupcase(to_frame) + " coordinates."
    return
  endif
  pcname = mname[i]
  get_data,pcname,data=mag_pc
  nsam = n_elements(mag_pc.x)

  ok = strmatch(mname,'*maven_mso*',/fold)
  i = (where(ok))[0]
  if (i eq -1) then begin
    print,"You must first load MAG data in MAVEN_MSO coordinates."
    return
  endif
  ssname = mname[i]
  get_data,ssname,data=mag_ss

; Unit vectors in direction of B in pc and ss frames

  B_mag = reform([sqrt(total(mag_ss.y*mag_ss.y,2))])
  str_element, mag_pc, 'amp', B_mag, /add

  B_pc = mag_pc.y
  B_pc[*,0] = B_pc[*,0]/B_mag
  B_pc[*,1] = B_pc[*,1]/B_mag
  B_pc[*,2] = B_pc[*,2]/B_mag

  B_ss = mag_ss.y
  B_ss[*,0] = B_ss[*,0]/B_mag
  B_ss[*,1] = B_ss[*,1]/B_mag
  B_ss[*,2] = B_ss[*,2]/B_mag

; Spacecraft position at each MAG sample time in PC and SS coordinates.
; Here the origin does matter, since the vectors are scaled by the radial 
; distance to the central object.

  print,"Interpolating ephemeris ... ",format='(a,$)'

  case origin of
    'Mars' :   begin
                 if (size(state,/type) ne 8) then maven_orbit_tplot,/load
                 if ((min(state.time) gt tmin) or (max(state.time) lt tmax)) then maven_orbit_tplot,/load

                 indx = where((state.time ge tmin) and (state.time le tmax), count)
                 if (count eq 0L) then begin
                   print,"Insufficient ephemeris data."
                   return
                 endif

                 S_pc = fltarr(nsam,3)
                 S_pc[*,0] = spline(state.time[indx], state.geo_x[indx,0], mag_pc.x)
                 S_pc[*,1] = spline(state.time[indx], state.geo_x[indx,1], mag_pc.x)
                 S_pc[*,2] = spline(state.time[indx], state.geo_x[indx,2], mag_pc.x)

                 S_ss = fltarr(nsam,3)
                 S_ss[*,0] = spline(state.time[indx], state.mso_x[indx,0], mag_pc.x)
                 S_ss[*,1] = spline(state.time[indx], state.mso_x[indx,1], mag_pc.x)
                 S_ss[*,2] = spline(state.time[indx], state.mso_x[indx,2], mag_pc.x)
               end

    'Phobos' : begin
                 jndx = where((moon.pc.t ge tmin) and (moon.pc.t le tmax), jcnt)
                 if (jcnt eq 0L) then begin
                   print,"Insufficient Phobos ephemeris data."
                   return
                 end

                 S_pc = fltarr(nsam,3)
                 S_pc[*,0] = spline(moon.pc.t[jndx], moon.pc.x[jndx], mag_pc.x)
                 S_pc[*,1] = spline(moon.pc.t[jndx], moon.pc.y[jndx], mag_pc.x)
                 S_pc[*,2] = spline(moon.pc.t[jndx], moon.pc.z[jndx], mag_pc.x)

                 S_ss = fltarr(nsam,3)
                 S_ss[*,0] = spline(moon.ss.t[jndx], moon.ss.x[jndx], mag_pc.x)
                 S_ss[*,1] = spline(moon.ss.t[jndx], moon.ss.y[jndx], mag_pc.x)
                 S_ss[*,2] = spline(moon.ss.t[jndx], moon.ss.z[jndx], mag_pc.x)
               end
    
    'Deimos' : begin
                 jndx = where((moon.pc.t ge tmin) and (moon.pc.t le tmax), jcnt)
                 if (jcnt eq 0L) then begin
                   print,"Insufficient Deimos ephemeris data."
                   return
                 end

                 S_pc = fltarr(nsam,3)
                 S_pc[*,0] = spline(moon.pc.t[jndx], moon.pc.x[jndx], mag_pc.x)
                 S_pc[*,1] = spline(moon.pc.t[jndx], moon.pc.y[jndx], mag_pc.x)
                 S_pc[*,2] = spline(moon.pc.t[jndx], moon.pc.z[jndx], mag_pc.x)

                 S_ss = fltarr(nsam,3)
                 S_ss[*,0] = spline(moon.ss.t[jndx], moon.ss.x[jndx], mag_pc.x)
                 S_ss[*,1] = spline(moon.ss.t[jndx], moon.ss.y[jndx], mag_pc.x)
                 S_ss[*,2] = spline(moon.ss.t[jndx], moon.ss.z[jndx], mag_pc.x)
               end
  endcase

  S_mag = sqrt(total(S_ss*S_ss,2))
  
  S_pc[*,0] = S_pc[*,0]/S_mag
  S_pc[*,1] = S_pc[*,1]/S_mag
  S_pc[*,2] = S_pc[*,2]/S_mag
  
  S_ss[*,0] = S_ss[*,0]/S_mag
  S_ss[*,1] = S_ss[*,1]/S_mag
  S_ss[*,2] = S_ss[*,2]/S_mag
  
  print," "

; Calculate the azimuth and elevation angles

  print,"Calculating azimuth, elevation, and clock angles ... ",format='(a,$)'

  slon = atan(S_pc[*,1],S_pc[*,0])
  slat = asin(S_pc[*,2] < 1.)

  sinlon = sin(slon)
  coslon = cos(slon)
  sinlat = sin(slat)
  coslat = cos(slat)

  rot = fltarr(3, 3, nsam)

  rot[0,0,*] = -sinlon
  rot[0,1,*] =  coslon
  rot[0,2,*] =  0.

  rot[1,0,*] = -coslon*sinlat
  rot[1,1,*] = -sinlon*sinlat
  rot[1,2,*] =  coslat

  rot[2,0,*] =  coslon*coslat
  rot[2,1,*] =  sinlon*coslat
  rot[2,2,*] =  sinlat

  B_lg = B_pc
  for i=0L,(nsam-1L) do B_lg[i,*] = rot[*,*,i]#reform(B_pc[i,*])

  B_azim = atan(B_lg[*,1],B_lg[*,0])*!radeg
  indx = where(B_azim lt 0., count)
  if (count gt 0L) then B_azim[indx] += 360.
  B_elev = asin(B_lg[*,2] < 1.)*!radeg
  
  str_element, mag_pc, 'azim', B_azim, /add
  str_element, mag_pc, 'elev', B_elev, /add

; Calculate clock angle
;
;    The tangent plane is orthogonal to the line connecting
;    Mars' center of mass with the spacecraft.
;
;    SxB is a unit vector in the tangent plane orthogonal to B.
;    SxSun is a unit vector in the tangent plane orthogonal to Sun.
;
;    The angle between these two vectors is the clock angle
;    (0 to 180 degrees), between the azimuths of B and Sun.
;

  SxB = fltarr(nsam,3)
  SxSun = SxB

  for i=0L,(nsam-1L) do $
    SxB[i,0:2] = crossp(reform(S_ss[i,0:2]), reform(B_ss[i,0:2]))

  SxB_mag = sqrt(total(SxB*SxB,2))
  SxB[*,0] = SxB[*,0]/SxB_mag
  SxB[*,1] = SxB[*,1]/SxB_mag
  SxB[*,2] = SxB[*,2]/SxB_mag

  SxSun[*,0] = 0.
  SxSun[*,1] = S_ss[*,2]
  SxSun[*,2] = -S_ss[*,1]

  Sun_mag = sqrt(total(SxSun*SxSun,2))
  SxSun[*,0] = SxSun[*,0]/Sun_mag
  SxSun[*,1] = SxSun[*,1]/Sun_mag
  SxSun[*,2] = SxSun[*,2]/Sun_mag

  B_clock = acos(total(SxB * SxSun, 2))*!radeg
  
  str_element, mag_pc, 'clock', B_clock, /add

  print," "

; Determine if/where the projected magnetic field line intersects the
; atmosphere at 170 km altitude and the spacecraft is above 170 km.
; (or 0 km altitude for Phobos and Deimos).

  S = S_pc * (S_mag # replicate(1.,3))  ; scaled vector
  S2 = S_mag*S_mag
  B = B_pc                              ; unit vector

  SdotB = reform([total(S*B,2)])
  SdotB2 = SdotB*SdotB

  S2mR2 = S2 - (R_exo*R_exo)

  indx = where((SdotB2 ge S2mR2) and (S2mR2 gt 0), count)

  if (count gt 0L) then begin
  
    T = replicate(!values.f_nan, nsam, 3)

    SdotB = SdotB[indx]
    SdotB2 = SdotB2[indx]
    S2mR2 = S2mR2[indx]

    S = S[indx,*]
    B = B[indx,*]

    sign = replicate(1., count)
    jndx = where(SdotB lt 0., jcnt)
    if (jcnt gt 0L) then sign[jndx] = -1.

    dist = -SdotB + sign*sqrt(SdotB2 - S2mR2)

    loc = S + (dist # replicate(1.,3))*B

    tlon = atan(loc[*,1], loc[*,0])/!dtor
    jndx = where(tlon lt 0., jcnt)
    if (jcnt gt 0L) then tlon[jndx] = tlon[jndx] + 360.
    tlat = asin((loc[*,2] / R_exo) < 1.)/!dtor

    T[indx,0] = reform(dist)
    T[indx,1] = reform(tlon)
    T[indx,2] = reform(tlat)
    result = {x:mag_pc.x, y:T}
    
    str_element, mag_pc, 'dist', T[*,0], /add
    str_element, mag_pc, 'lon',  T[*,1], /add
    str_element, mag_pc, 'lat',  T[*,2], /add
    
    polarity = replicate(!values.f_nan, nsam, 2)
    jndx = where(dist lt 0., count)
    if (count gt 0L) then polarity[indx[jndx],*] = -1.
    jndx = where(dist ge 0., count)
    if (count gt 0L) then polarity[indx[jndx],*] = 1.
    jndx = where(S2 le (R_exo*R_exo), count)
    if (count gt 0L) then polarity[jndx,*] = 0.
    store_data,'B_trace_pol',data={x:mag_pc.x, y:polarity, v:[0,1]}
    ylim,'B_trace_pol',0,1,0
    zlim,'B_trace_pol',-1,1,0
    options,'B_trace_pol','spec',1
    options,'B_trace_pol','panel_size',0.05
    options,'B_trace_pol','ytitle',''
    options,'B_trace_pol','yticks',1
    options,'B_trace_pol','yminor',1
    options,'B_trace_pol','no_interp',1
    options,'B_trace_pol','xstyle',4
    options,'B_trace_pol','ystyle',4
    options,'B_trace_pol','no_color_scale',1
    
    store_data,'B_trace_dist',data={x:mag_pc.x, y:abs(T[*,0])}
    options,'B_trace_dist','ytitle','Dist (km)'
    store_data,'B_trace_lon',data={x:mag_pc.x, y:T[*,1]}
    options,'B_trace_lon','ytitle','Trace Lon (deg)'
    ylim,'B_trace_lon',0,360,0
    options,'B_trace_lon','yticks',4
    options,'B_trace_lon','yminor',3
    store_data,'B_trace_lat',data={x:mag_pc.x, y:T[*,2]}
    options,'B_trace_lat','ytitle','Trace Lat (deg)'
    ylim,'B_trace_lat',-90,90,0
    options,'B_trace_lat','yticks',3
    options,'B_trace_lat','yminor',3

  endif else begin
    print,"Crikey!  The magnetic field never intersects " + origin + "!"
    get_data,'B_trace_pol',index=i
    if (i gt 0L) then store_data,'B_trace_pol',/delete
    get_data,'B_trace_dist',index=i
    if (i gt 0L) then store_data,'B_trace_dist',/delete
  endelse
  
  store_data, pcname, data=mag_pc

  return

end
