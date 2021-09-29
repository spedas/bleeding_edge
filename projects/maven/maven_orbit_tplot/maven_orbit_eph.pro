;+
;FUNCTION:   maven_orbit_eph
;PURPOSE:
;  Returns the MAVEN spacecraft ephemeris, consisting of the MSO and GEO state
;  vectors along with some derived quantities: altitude, GEO longitude, GEO
;  latitude, and solar zenith angle.  The reference surface for calculating
;  altitude ("datum") is specified.
;
;  The coordinate frames are:
;
;   GEO = body-fixed Mars geographic coordinates (non-inertial) = IAU_MARS
;
;              X ->  0 deg E longitude, 0 deg latitude
;              Y -> 90 deg E longitude, 0 deg latitude
;              Z -> 90 deg N latitude (= X x Y)
;              origin = center of Mars
;              units = kilometers
;
;   MSO = Mars-Sun-Orbit coordinates (approx. inertial)
;
;              X -> from center of Mars to center of Sun
;              Y -> opposite to Mars' orbital angular velocity vector
;              Z = X x Y
;              origin = center of Mars
;              units = kilometers
;
;USAGE:
;  eph = maven_orbit_eph()
;INPUTS:
;       none
;
;KEYWORDS:
;       none
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2019-03-15 12:33:21 -0700 (Fri, 15 Mar 2019) $
; $LastChangedRevision: 26801 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/maven_orbit_tplot/maven_orbit_eph.pro $
;-
function maven_orbit_eph

  @maven_orbit_common

  if (size(state,/type) eq 0) then begin
    print,"Ephemeris not defined.  Use maven_orbit_tplot first."
    return, 0
  endif
  
  eph = state
  str_element, eph, 'r', sqrt(total(state.mso_x^2.,2)), /add
  str_element, eph, 'r_m', 3389.5, /add
  str_element, eph, 'vmag_mso', sqrt(total(state.mso_v^2.,2)), /add
  str_element, eph, 'vmag_geo', sqrt(total(state.geo_v^2.,2)), /add
  str_element, eph, 'alt', hgt, /add
  str_element, eph, 'lon', lon, /add
  str_element, eph, 'lat', lat, /add
  str_element, eph, 'datum', datum, /add
  str_element, eph, 'sza', sza*!radeg, /add

  mvn_mars_localtime, result=lst
  if (size(lst,/type) eq 8) then begin
    str_element, eph, 'lst', lst.lst, /add
    str_element, eph, 'slon', lst.slon, /add
    str_element, eph, 'slat', lst.slat, /add
  endif

  return, eph

end
