; this function should take as input time vectors and an angular resolution.
;  mvn_sep_get_fov
;INPUTS:
;       TIMES:   scalar or array of double precision UNIX time
;KEYWORDS:
;       NPHI:     number of angular bins across the FOV in the phi direction. The total glint FOV is 51 degrees
;
;       NTHETA:   number of angular bins across the FOV in the theta direction. The total glint FOV is 38 degrees
;       
;       COORDINATE_FRAME: The frame in which the FOVs are desired. The default is 'MAVEN_MSO'
;       
;       CARTESIAN:        If the output is wanted in cartesian form (the default is spherical polar coordinates)
;          
; The output is a structure  containing arrays characterizing each of the fields of view in any coordinate frame

;

Function mvn_sep_get_fov, times,nphi = nphi, ntheta=ntheta, check_objects = check_objects, coordinate_frame = coordinate_frame, $
  Cartesian = Cartesian
  
  if not keyword_set (coordinate_frame) then coordinate_frame = 'MAVEN_MSO'
  ;if not keyword_set (dang) then dang = 1.5
  if not keyword_set (nphi) then nphi = 51
  if not keyword_set (ntheta) then ntheta = 38
  et = time_ephemeris(times)
  nt = n_elements (times)
  if nt le 1 then message,'times must be an array with more than onre element.'
  ; load the SEP fields of view
  FOV_ID = {SEP1A_front: -202121, SEP1B_front: -202122, SEP1A_back: -202123, SEP1B_back: -202124, $
            SEP2A_front: -202126, SEP2B_front: -202127, SEP2A_back: -202128, SEP2B_back: -202129}
  FOV_ID_array = [ -202121, -202122, -202123, -202124, -202126, -202127,-202128, -202129]
  FOV_frame = [replicate ('MAVEN_SEP1', 4), replicate ('MAVEN_SEP2', 4)]
  nfov = n_elements (FOV_ID_array)
  FOV_names = tag_names (FOV_ID)
  max_bounds = 4; the maximum number of FOV boundary vectors to return.  For SEP, they are rectangles so 4 makes sense.
  
  FOV = fltarr  (nt,nfov,3,nphi*1L*ntheta)
 
  if keyword_set(check_objects) then begin
  time_valid = spice_valid_times(et,object=check_objects) 
    printdat,check_objects,time_valid
    ind = where(time_valid ne 0,nind)
  endif else begin
 ; nind = ns
    ind = lindgen((nind = nt))
  endelse
  for J = 0, 7 do begin
; get the boundaries of the FOV    
    cspice_getfov, FOV_ID_array [J], max_bounds, shape, frame, bsight, bounds
; convert to polar and azimuth angles    
    cart2spc, bounds[0,*], bounds [1,*], bounds [2,*], r, theta_bounds,phi_bounds
    ;print, phi_bounds
    theta_range = max (theta_bounds) - min (theta_bounds)
    dtheta = theta_range/ntheta
    Theta_edges_array = Theta_bounds [0] + dtheta*dindgen(ntheta+1)
    theta_centers_array = bin_centers(theta_edges_array)
    if phi_bounds[0] lt phi_bounds[3] then begin
      phi_range = max (phi_bounds) - min (phi_bounds)
      dphi = phi_range/nphi
      phi_edges_array = phi_bounds [0] + dphi*dindgen(nphi+1)
      phi_centers_array = bin_centers(phi_edges_array)
    endif else begin
      phi_range = phi_bounds [3] + (2*!pi - phi_bounds[0])
      dphi = phi_range/nphi
      phi_edges_array = (phi_bounds [0] + dphi*dindgen(nphi+1)) 
      phi_centers_array = bin_centers(phi_edges_array) mod (2*!pi)
      phi_edges_array = phi_edges_array mod (2*!pi)
    endelse
; define a two-dimensional array of phi, theta
    phi_array_2d = phi_centers_array#replicate (1.0,ntheta)
    theta_array_2d = theta_centers_array##replicate (1.0,nphi)
; pixels are smaller the further from 90 degrees.  Need weighting function
    weighting_array_2d = sin(theta_array_2d)
; transform back to Cartesian coordinates (still in the SEP sensor coordinate frame)
    spc2cart, 1.0, theta_array_2d, phi_array_2d, x2d, y2d, z2d

; before transforming to MSO, need to get the vectors in the form 3XN
    FOV_instrument_frame =  reform (replicate_array (transpose([[[x2d]],[[y2d]], [[z2d]]], [2, 0, 1]),nt), 3, nt*1L*nphi*ntheta)
    times_extended = reform (replicate_array (times,nphi*1L*ntheta),nt*1L*nphi*ntheta)
; calculate the position in Cartesian MSO coordinates of every  spot in the FOV
    FOV_full_rotated = spice_vector_rotate(FOV_instrument_frame,times_extended,FOV_frame [J],$
      coordinate_frame,check_objects='MAVEN_SC_BUS')
    if keyword_set (Cartesian) then FOV[*,J,*,*] = transpose (reform  (FOV_full_rotated,3,nt,nphi*ntheta), [1, 0, 2]) Else begin
; transform to spherical polar coordinates
      cart2spc, FOV_full_rotated [0,*], FOV_full_rotated [1,*], FOV_full_rotated [2,*], FOV_full_radial, FOV_full_theta, FOV_full_phi
; now reform the original array
      FOV[*, J,*,*] = transpose(reform(transpose([[reform (FOV_full_radial)], [reform (FOV_full_theta)], $
                                      [reform (FOV_full_phi)]]), 3,nt, nphi*ntheta), [1, 0, 2])
    endelse
  endfor
   output = {coordinate_frame: coordinate_frame, coordinate_type: ' ', $
     time: times,SEP_FOV_name: ['SEP1'+  ['A_forward', 'B_forward', 'A_reverse', 'B_reverse'], $
                     'SEP2'+  ['A_forward', 'B_forward', 'A_reverse', 'B_reverse']], $
      SEP_nearest_detector: ['SEP1'+  ['A-F', 'B-O', 'A-O', 'B-F'], $
                             'SEP2'+  ['A-F', 'B-O', 'A-O', 'B-F']], $
      FOV: FOV,  order_indices: 'time, aperture, xyz (or r_theta_phi), individual spots within FOV'}
  if keyword_set (Cartesian) then output.coordinate_type = 'Cartesian XYZ' else output.coordinate_type = 'Spherical polar r theta phi'
  return, output
end  