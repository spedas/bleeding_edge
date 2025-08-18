;+
;
;   $LastChangedDate: 2019-10-23 14:19:14 -0700 (Wed, 23 Oct 2019) $
;   $LastChangedRevision: 27922 $
;-
Function get_mepi_flux_angle_in_sga, debug = debug, looking_dir = looking_dir

  if undefined(debug) then debug = 0
  
  
  ;; --- starts from -Z(SGI) axis and increases toward -Y(SGI) axis.
  azi_0 = 11.25  ;;[deg] offset of channel 0 (anode 00) from -Z(SGI) axis
  d_azi = 22.5   ;;[deg] angula interval between the centers of neighboring ch
  phi = azi_0 + indgen(16) * d_azi
  ;; Inclination of apertures, based on visual inspection
  theta = replicate(1.6, 16)  ;;[deg] 
  
  ;; unit vector of looking direction 
  ;;   e is a 2-D array [azch, 3(x,y,z)] in SGA/SGI 
  e   = [  [-1 * sin(theta*!DTOR)] $
         , [-1 * cos(theta*!DTOR) * sin(phi*!DTOR)] $
         , [-1 * cos(theta*!DTOR) * cos(phi*!DTOR)]    ]  
  
  if undefined(looking_dir) then e = -1 * e ;;Flip the directions to be flux dirs
  
  
  ;; Note that xyz_to_polar gives a theta in latitude (-90 to 90 deg) by default.
  xyz_to_polar, e, theta=elev, phi=phi, /ph_0_360
  
  anglarr = fltarr( 2, 3, 16 )  ;[ elev/phi, min/cnt/max, apd_no ]

  for ch = 0, 15 do begin
    
    anglarr[ 0, *, ch ] = elev[ch] ;;currently filled with the center angle
    anglarr[ 1, *, ch ] = phi[ch]  ;;currently filled with the center angle

  endfor
  
  return,  anglarr

end

