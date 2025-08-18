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
;  The returned structure contains the following tags:
;
;       TIME            DOUBLE    unix time (essentially the same as UTC)
;       MSO_X           FLOAT     position in the MSO frame (km)
;       MSO_V           FLOAT     velocity in the MSO frame (km/s)
;       GEO_X           FLOAT     position in the IAU_MARS frame (km)
;       GEO_V           FLOAT     velocity in the IAU_MARS frame (km/s)
;       R               FLOAT     radial distance from Mars' center (km)
;       R_M             FLOAT     Mars volumetric mean radius (3389.50 km)
;       VMAG_MSO        FLOAT     magnitude of MSO_V (km/s)
;       VMAG_GEO        FLOAT     magnitude of GEO_V (km/s)
;       ALT             DOUBLE    altitude relative to the DATUM (km)
;       LON             DOUBLE    IAU_MARS longitude of spacecraft (deg)
;       LAT             DOUBLE    IAU_MARS latitude of spacecraft (deg)
;       DATUM           STRING    reference surface* for calculating altitude
;       SZA             DOUBLE    solar zenith angle (deg)
;       LST             DOUBLE    local solar time (0-24 Mars hours)
;       SLON            DOUBLE    IAU_MARS longitude of sub-solar point (deg)
;       SLAT            DOUBLE    IAU_MARS latitude of sub-solar point (deg)
;
;    * The datum can be one of: 'sphere', 'ellipsoid', 'areoid', or 'surface'.
;      See mvn_altitude.pro for details.  The default is 'ellipsoid'.
;
;USAGE:
;  eph = maven_orbit_eph()
;
;INPUTS:
;       none
;
;KEYWORDS:
;       none
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2023-07-07 10:48:05 -0700 (Fri, 07 Jul 2023) $
; $LastChangedRevision: 31942 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/maven_orbit_tplot/maven_orbit_eph.pro $
;-
function maven_orbit_eph

  @maven_orbit_common

  eph = 0

  if (size(state,/type) eq 0) then begin
    print,"Ephemeris not defined.  Use maven_orbit_tplot first."
    return, eph
  endif

; Calculate additional parameters derived from state vectors

  eph = state
  str_element, eph, 'r', sqrt(total(state.mso_x^2.,2)), /add
  str_element, eph, 'r_m', 3389.5, /add
  str_element, eph, 's', sqrt(total((state.mso_x[*,[1,2]])^2.,2))
  str_element, eph, 'vmag_mso', sqrt(total(state.mso_v^2.,2)), /add
  str_element, eph, 'vmag_geo', sqrt(total(state.geo_v^2.,2)), /add
  str_element, eph, 'alt', hgt, /add
  str_element, eph, 'lon', lon, /add
  str_element, eph, 'lat', lat, /add
  str_element, eph, 'datum', datum, /add
  str_element, eph, 'sza', sza*!radeg, /add
  str_element, eph, 'lst', lst, /add
  str_element, eph, 'slon', slon, /add
  str_element, eph, 'slat', slat, /add

  return, eph

end
