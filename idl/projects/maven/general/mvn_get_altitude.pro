;+
;FUNCTION: mvn_get_altitude
;PURPOSE:
;  Calculates the altitude of the MAVEN spacecraft above the Martian
;  surface (either the solid planet or the constant-pressure surface
;  known as the 'areoid').  This routine is called by the more general
;  mvn_altitude, which has other possible definitions for altitude.
;
;USAGE:
;  mav_get_altitude, elon_sc, lat_sc,r_sc, alt_sc
;
;INPUTS:
;       xpc: a 1-dimensional array of values of the east longitude
;                of the spacecraft. UNITS: km
;
;       ypc:  a 1-dimensional array of values of the latitude
;                of the spacecraft. UNITS: km
;
;       zpc:    a 1-dimensional array of values of the radial
;                distance of the spacecraft from the planet's center
;                of mass. UNITS: kilometers
;OUTPUT:                
;       The output array of spacecraft altitudes. 
;                UNITS: kilometers
;
;KEYWORDS:
;       TOPOGRAPHIC: Set this keyword to anything nonzero if the spacecraft
;                    altitude above the planet's topography is
;                    desired.  If this keyword is not specified, the
;                    altitude will be above the constant-pressure
;                    surface known as the areoid (the equivalent of
;                    sea level) and the relevant altitude for most
;                    MAVEN studies.
;
;       MOLA_STRUC:  Depreciated.  Structure now stored in a common block.
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2017-05-29 15:49:17 -0700 (Mon, 29 May 2017) $
; $LastChangedRevision: 23361 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/general/mvn_get_altitude.pro $
;
;CREATED BY:	Robert J. Lillis 2013-01-22
;-

function mvn_get_altitude, xpc, ypc, zpc, topographic = topographic

  common mgs_mola, mola_struc

  if (size(mola_struc,/type) eq 0) then begin
    rootdir = 'maven/anc/spice/sav/'
    pathname = rootdir + 'mola_save_file_0.25deg.idl'
    file = mvn_pfp_file_retrieve(pathname)
    if (findfile(file[0]) eq '') then begin
      print,"File not found: ",pathname
      return, !values.f_nan
    endif
    restore, file[0]
  endif

;  cart2latlong, xpc,ypc,zpc, r_sc, lat_sc,elon_sc
  cart_to_sphere, xpc, ypc, zpc, r_sc, lat_sc, elon_sc, /ph_0_360

  nelon = n_elements (mola_struc.elon)
  nlat = n_elements (mola_struc.lat)
  elon_fractional_indices = elon_sc*(nelon/360.0) - 1.0
  lat_fractional_indices = (90.0+lat_sc)*(nlat/180.0) -1.0

  if keyword_set (topographic) then r = mola_struc.r_pl else r = $
    mola_struc.r_areoid

  r_surface_km = 0.001*interpolate (r,elon_fractional_indices, $
                                    lat_fractional_indices)
  alt_sc = r_sc - r_surface_km
  return, alt_sc
end
  
  
