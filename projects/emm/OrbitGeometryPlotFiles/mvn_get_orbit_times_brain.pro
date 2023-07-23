;+
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; mvn_get_orbit_times_brain.pro
;
; Function to return a trange corresponding to the start and stop
; times (measured apoapsis to apoapsis) of a single MAVEN orbit
; containing the timestamp passed to the function
;
; Syntax:
;      trange = mvn_get_orbit_times( time )
;
; Inputs:
;      time              - single timestamp. If an array is passed
;                          the function only acts on the first element
;
; Dependencies:
;      none outside of Berkeley MAVEN software (I think)
;
; Dave Brain
; 12 January, 2017 -Initial version
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;-
function mvn_get_orbit_times_brain, time


;;; Some parameters
  orbit_period = 4.5d0 * 3600d0
  res = 1d0

;;; Load a little more than an orbit
  t0 = time_double(time[0])
  trange = t0 + [-1.1d0, 1.1d0] * orbit_period

;;; Load spice kernels 
  spice_kernel_load, /clear
  s = spice_file_source()
  s.no_server = 1
  mk = mvn_spice_kernels( /all, /load, source = s, trange = trange )

;;; Make array every 1 second
  dur = time_double(trange[1]) - time_double(trange[0])
  num = floor(dur/double(res)) + 1
  t = dindgen(num)*res + time_double(trange[0])

;;; Load cartesian position and convert to spherical
  geo_cart = spice_body_pos( 'MAVEN', 'MARS', frame='IAU_MARS', utc=t )
  geo_sph = cv_coord( from_rect=geo_cart, /to_sphere, /double )
  lon = ( reform( geo_sph[0,*] ) * !radeg + 360. ) mod 360.
  lat = reform( geo_sph[1,*] ) * !radeg
  rad = reform( geo_sph[2,*] )

;;; Find the altitude  
  mav_get_altitude, lon, lat, rad, a, /areoid

;;; Find max alt moment closest to this time on either side
  ans = extrema( a, maxima=locmax )
  ans = min( t-t0, ind, /abs )
  tmp = where( locmax lt ind )
  trange[0] = t[locmax[max(tmp)]]
  tmp = where( locmax gt ind )
  trange[1] = t[locmax[min(tmp)]]

;;; Return the timerange
  return, trange

  
end

