;+
;PROCEDURE:   mvn_mars_terminator
;PURPOSE:
;  Given a time, uses SPICE to determine the location of the 
;  terminator and the subsolar point in IAU_MARS coordinates.
;  The terminator is calculated with 1-deg resolution (360 points).
;  The result is returned via keyword.
;
;  It is assumed that you have already initialized SPICE.  (See 
;  mvn_swe_spice_init for an example.)
;
;USAGE:
;  mvn_mars_terminator, time, result=dat
;
;INPUTS:
;       time:      Time for calculating the terminator
;
;KEYWORDS:
;       RESULT:    Structure containing the result:
;
;                    time  : unix time for used for calculation
;                    t_lon : terminator longitude (deg)
;                    t_lat : terminator latitude (deg)
;                    s_lon : sub-solar point longitude (deg)
;                    s_lat : sub-solar point latitude (deg)
;                    frame : coordinate frame ("IAU_MARS")
;
;       SHADOW:    Choose which "shadow" to calculate:
;                     0 : optical shadow at surface (default)
;                     1 : optical shadow at spacecraft altitude
;                     2 : EUV shadow at spacecraft altitude
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2017-03-01 14:56:42 -0800 (Wed, 01 Mar 2017) $
; $LastChangedRevision: 22890 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/maven_orbit_tplot/mvn_mars_terminator.pro $
;
;CREATED BY:	David L. Mitchell
;-
pro mvn_mars_terminator, time, result=result, shadow=shadow

; Terminator is the plane defined by X = 0 in the MSO frame

  if keyword_set(shadow) then begin
    R_m = 3389.9D
    if (shadow gt 1) then R_m += 300D
    get_data,'alt',data=alt
    dt = min(abs(alt.x - time), i)
    iref = (i > 3) < (n_elements(alt.x) - 4)
    indx = lindgen(7) + iref - 3L
    h = spline(alt.x[indx], alt.y[indx], time, /double)
    sza = acos(R_m/(R_m + h)) + !dpi/2D
    x = cos(sza)
    s = sqrt(1D - x*x)
  endif else begin
    x = 0D
    s = 1D
  endelse

  phi = dindgen(361)*!dtor
  t_mso = dblarr(3,361)
  t_mso[0,*] = x
  t_mso[1,*] = s*cos(phi)
  t_mso[2,*] = s*sin(phi)

  t = replicate(time_double(time), 361)

  from_frame = 'MAVEN_MSO'
  to_frame = 'IAU_MARS'

  t_geo = spice_vector_rotate(t_mso, t, from_frame, to_frame)
  t_lon = reform(atan(t_geo[1,*], t_geo[0,*])*!radeg)
  t_lat = reform(asin(t_geo[2,*])*!radeg)
  
  indx = where(t_lon lt 0., count)
  if (count gt 0L) then begin
    t_lon[indx] = t_lon[indx] + 360.
    indx = sort(t_lon)
    t_lon = t_lon[indx]
    t_lat = t_lat[indx]
  endif

; Sun is at MSO coordinates of [X, Y, Z] = [1, 0, 0]

  s_mso = [1D, 0D, 0D]
  s_geo = spice_vector_rotate(s_mso, time, from_frame, to_frame)
  s_lon = atan(s_geo[1], s_geo[0])*!radeg
  s_lat = asin(s_geo[2])*!radeg
  
  if (s_lon lt 0.) then s_lon = s_lon + 360.
  
  result = {time:t[0], tlon:t_lon, tlat:t_lat, slon:s_lon, slat:s_lat, frame:to_frame}

  return

end
