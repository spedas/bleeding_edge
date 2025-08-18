;+
;PROCEDURE: mav_get_altitude
;PURPOSE:
;  Calculates the altitude of the MAVEN spacecraft above the Martian
;  surface (either the solid planet or the constant-pressure surface
;  known as the 'areoid')
;
;USAGE:
;  mav_get_altitude, elon_sc, lat_sc,r_sc, alt_sc

;INPUTS:
;       elon_sc: a 1-dimensional array of values of the east longitude
;                of the spacecraft. UNITS: Degrees! 
;
;       lat_sc:  a 1-dimensional array of values of the latitude
;                of the spacecraft. UNITS: Degrees! 
;
;       r_sc:    a 1-dimensional array of values of the radial
;                distance of the spacecraft from the planet's center
;                of mass. UNITS: kilometers
;                
;       alt_sc:  The output array of spacecraft altitudes. 
;                UNITS: kilometers
        
;KEYWORDS:
;       TOPOGRAPHIC: Set this keyword to anything nonzero if the spacecraft
;                    altitude above the planet's topography is desired
;
;       AREOID:      Set this keyword to anything nonzero if desired
;                    is the spacecraft altitude above the
;                    constant-pressure surface known as the areoid
;                    (the equivalent of sea level).  This will be the
;                    relevant altitude for most MAVEN studies and is
;                    the default if neither the topographic or areoid
;                    keywords are specified.
;
;CREATED BY:	Robert J. Lillis 2013-01-22
;FILE:  mav_get_altitude
;VERSION:  1.1
; Change made to enable loading of mola file

pro mav_get_altitude, elon_sc, lat_sc,r_sc, alt_sc, mola_struc = mola_struc, $
                      topographic = topographic, areoid = areoid
  if not keyword_set (mola_struc) then begin
  ; Here we find out where the source code is, knowing that the file to be restored is in that same folder
    traceinfo = scope_traceback(/structure)
    nlevels = n_elements(traceinfo) 
    thisfile = traceinfo[nlevels-1].filename
    eph_folder = file_dirname(thisfile)
    restore, eph_folder + '/mola_save_file_0.25deg.sav'
    endif 
  if keyword_set (topographic) and keyword_set (areoid) then message, 'Must choose either altitude to be above the topographic or areoid surfaces, not both!!'

  nelon = n_elements (mola_struc.elon)
  nlat = n_elements (mola_struc.lat)
  elon_fractional_indices = elon_sc*(nelon/360.0) - 1.0
  lat_fractional_indices = (90.0+lat_sc)*(nlat/180.0) -1.0

  ;stop

  if keyword_set (topographic) then r = mola_struc.r_pl else r = $
    mola_struc.r_areoid

  r_surface_km = 0.001*interpolate(r,elon_fractional_indices, $
                                    lat_fractional_indices)
  alt_sc = r_sc - r_surface_km
end
  
  
