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
;      See mvn_altitude.pro for details.  This function uses the 'ellipsoid'.
;
;  The last three parameters are only calculated if the frames and planet kernels
;  are loaded, or if you use the MISSION keyword.  Any of the following will work:
;
;    Option 1: Initialize SPICE first
;
;      kernels = mvn_spice_kernels(/load)
;      eph = maven_orbit_eph()
;
;    Option 2: For long time spans, for which loading all the kernels would be
;              cumbersome:
;
;      mvn_swe_spice_init, /baseonly
;      eph = maven_orbit_eph()
;
;    Option 3: For the entire mission to date:
;
;      eph = maven_orbit_eph(/mission)
;
;USAGE:
;  eph = maven_orbit_eph()
;
;INPUTS:
;       none
;
;KEYWORDS:
;
;       MISSION:  Restore an ephemeris for the entire mission.  Currently, the
;                 ephemeris spans 2014-09-21 (orbit insertion) to 2023-07-01.
;                 The file is 3.4 GB in size, so it could take a while to 
;                 download it, and that is how much RAM it will consume.  The
;                 time resolution is 10 seconds, and there are >27 million points.
;
;                 You can use the WHERE command to identify geometric situations
;                 of interest.
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2023-05-11 10:04:19 -0700 (Thu, 11 May 2023) $
; $LastChangedRevision: 31850 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/maven_orbit_tplot/maven_orbit_eph.pro $
;-
function maven_orbit_eph, mission=mission

  @maven_orbit_common

  if keyword_set(mission) then begin
    rootdir = 'maven/anc/spice/sav/'
    ssrc = mvn_file_source(archive_ext='')  ; don't archive old files
    fname = 'maven_eph_20140921_*.sav'
    file = mvn_pfp_file_retrieve(rootdir+fname,last_version=0,source=ssrc,verbose=2)
    nfiles = n_elements(file)
    if (nfiles eq 1) then restore, file
    return, eph
  endif

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
