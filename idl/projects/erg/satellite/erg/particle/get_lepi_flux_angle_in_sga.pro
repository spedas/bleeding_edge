;+
;
; $LastChangedDate: 2019-10-23 14:19:14 -0700 (Wed, 23 Oct 2019) $
; $LastChangedRevision: 27922 $
;-
Function get_lepi_flux_angle_in_sga, debug = debug, looking_dir = looking_dir

  if undefined(debug) then debug = 0
  
  ;; Here, phi is the angles of the flux directions in the SGA Y-Z plane
  ;; as defined to be angles from the +Y axis increasing toward the +Z axis. 
  ;; Please see Asamura+, EPS, 2018 for the details. 
  phi = [ 101.25, 123.75, 146.25, 168.75, 191.25, 213.75, 236.25, 258.75, $
          281.25, 303.75, 326.25, 348.75, 33.75, 56.25, 78.75 ] ;; [deg]
  ;; Inclination of apertures = 0.0 deg
  theta = replicate(0., 15)  ;;[deg] 
  
  ;; unit vector of looking direction 
  ;;   e is a 2-D array [azch, 3(x,y,z)] in SGA/SGI 
  e   = [  [1. * sin(theta*!DTOR)] $
         , [1. * cos(theta*!DTOR) * cos(phi*!DTOR)] $
         , [1. * cos(theta*!DTOR) * sin(phi*!DTOR)]    ]  
  
  if defined(looking_dir) then e = -1 * e ;;Flip the directions to be looking dirs
  
  
  ;; Note that xyz_to_polar gives a theta in latitude (-90 to 90 deg) by default.
  xyz_to_polar, e, theta=elev, phi=phi, /ph_0_360
  
  anglarr = fltarr( 2, 3, 15 )  ;[ elev/phi, min/cnt/max, apd_no ]

  for ch = 0, 14 do begin
    
    anglarr[ 0, *, ch ] = elev[ch] ;;currently filled with the center angle
    anglarr[ 1, *, ch ] = phi[ch]  ;;currently filled with the center angle

  endfor
  
  return,  anglarr

end

