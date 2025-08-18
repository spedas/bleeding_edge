;+
; FUNCTION get_sphcntr
;
; :DESCRIPTION:
;    Calculate the center position on the spherical coordinate system
;    from given points. The function returns a floating-point
;    array [latitude, longitude] for the center position.
;
; :PARAMS:
;    latarr, lonarr:
;    Arrays containing latitudes and longitudes, respectively, of
;    given points on the spherical coordinate system. Any dimension,
;    size is acceptable as long as both arrays have the same
;    dimension/size.
;
; :EXAMPLES:
;   To get the center of points [lat1,lon1], [lat2,lon2], and
;   [lat3,lon3],
;
;   pos = get_sphcntr( [lat1,lat2,lat3], [lon1,lon2,lon3] )
;
; :AUTHOR:
; 	Tomo Hori (E-mail: horit@isee.nagoya-u.ac.jp)
;
; :HISTORY:
; 	2011/01/07: Created
;
; $LastChangedDate: 2019-03-17 21:51:57 -0700 (Sun, 17 Mar 2019) $
; $LastChangedRevision: 26838 $
;-
FUNCTION get_sphcntr, latarr, lonarr

  ;Check the array size
  IF N_ELEMENTS(latarr) NE N_ELEMENTS(lonarr) THEN BEGIN
    PRINT, 'get_sphcntr: Array size does not match!'
    RETURN, [!values.f_nan,!values.f_nan]
  ENDIF
  
  phiarr = lonarr*!dtor
  thearr = (90.-latarr)*!dtor
  x = SIN(thearr)*COS(phiarr)
  y = SIN(thearr)*SIN(phiarr)
  z = COS(thearr)
  ave_x = TOTAL(x) & ave_y = TOTAL(y) & ave_z = TOTAL(z)
  xyz_to_polar, [ave_x,ave_y,ave_z], phi=lon, theta=lat, $
    /ph_0_360
    
  RETURN, [lat,lon]
END
