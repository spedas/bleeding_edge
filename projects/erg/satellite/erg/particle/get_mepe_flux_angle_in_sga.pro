;+
;
;   $LastChangedDate: 2019-10-23 14:19:14 -0700 (Wed, 23 Oct 2019) $
;   $LastChangedRevision: 27922 $
;-
Function get_mepe_flux_angle_in_sga, debug = debug, looking_dir = looking_dir

  if undefined(debug) then debug = 0
  
  ;; unit vectors of flux dirs
  fluxdir = 1
  if keyword_set(looking_dir) then fluxdir = 0
  sgajdir = get_mepe_az_dir_in_sga(fluxdir=fluxdir) ;;[ ch, 3 ] 

  xyz_to_polar, sgajdir, theta=elev, phi=phi, /ph_0_360
  
  anglarr = fltarr( 2, 3, 16 )  ;[ elev/phi, min/cnt/max, apd_no ]

  for ch = 0, 15 do begin
    
    anglarr[ 0, *, ch ] = elev[ch] ;;currently filled with the center angle
    anglarr[ 1, *, ch ] = phi[ch]  ;;currently filled with the center angle

  endfor
  
  return,  anglarr

end

