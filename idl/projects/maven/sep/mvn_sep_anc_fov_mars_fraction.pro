; the purpose of this file is to calculate the fraction of each of the SEP fields of view (FOV) that is filled by planet Mars.

; Keyword DANG is the resolution, in DEGREES, of the mesh used to calculate this fraction

Function mvn_sep_anc_fov_mars_fraction, times,dang = dang, check_objects = check_objects
  if not keyword_set (dang) then dang = 1.5
  et = time_ephemeris(times)
  nt = n_elements (times)
  ; load the SEP fields of view
  FOV_ID = {SEP1A_front: -202126, SEP1B_front: -202127, SEP1A_back: -202128, SEP1B_back: -202129, $
            SEP2A_front: -202121, SEP2B_front: -202122, SEP2A_back: -202123, SEP2B_back: -202124}
  FOV_ID_array = [-202128, -202129, -202126, -202127, -202123, -202124, -202121, -202122]
  FOV_frame = [replicate ('MAVEN_SEP1', 4), replicate ('MAVEN_SEP2', 4)]
  FOV_names = tag_names (FOV_ID)
  max_bounds = 4; the maximum number of FOV boundary vectors to return.  For SEP, they are rectangles so 4 makes sense.
  
  fraction_FOV_Mars = fltarr(nt, 4)*sqrt(-5.5)
  fraction_FOV_sunlit_Mars = fltarr(nt, 4)*sqrt(-5.5)
  if keyword_set(check_objects) then begin
  time_valid = spice_valid_times(et,object=check_objects) 
    printdat,check_objects,time_valid
    ind = where(time_valid ne 0,nind)
  endif else begin
 ; nind = ns
    ind = lindgen((nind = nt))
  endelse
  for J = 0, 3 do begin
; get the boundaries of the FOV    
    cspice_getfov, FOV_ID_array [J*2], max_bounds, shape, frame, bsight, bounds
; convert to polar and azimuth angles    
    cart2spc, bounds[0,*], bounds [1,*], bounds [2,*], r, theta_bounds,phi_bounds
    print, phi_bounds
    theta_range = max (theta_bounds) - min (theta_bounds)
    ntheta = ceil(theta_range/(dang*!dtor))
    dtheta = theta_range/ntheta
    Theta_edges_array = Theta_bounds [0] + dtheta*dindgen(ntheta+1)
    theta_centers_array = bin_centers(theta_edges_array)
    if phi_bounds[0] lt phi_bounds[3] then begin
      phi_range = max (phi_bounds) - min (phi_bounds)
      nphi = ceil(phi_range/(dang*!dtor))
      dphi = phi_range/nphi
      phi_edges_array = phi_bounds [0] + dphi*dindgen(nphi+1)
      phi_centers_array = bin_centers(phi_edges_array)
    endif else begin
      phi_range = phi_bounds [3] + (2*!pi - phi_bounds[0])
      nphi = ceil(phi_range/(dang*!dtor))
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

    intercept_Mars = bytarr(nphi, ntheta) ; i.e. does it intercept Mars?
    ; print, intercept_Mars
    cos_sza_intercept = fltarr(nphi, ntheta) ; if it does, how well illuminated is the surface?
    for i = 0L, n_elements (ind) -1 do begin   
      for M = 0, ntheta*1L*nphi - 1 do begin & $
; 'intercept' is 1 if the ray intercepts the planet.  0 if not
        cspice_sincpt, 'Ellipsoid', 'MARS',et[ind[i]], 'IAU_MARS', 'NONE', 'MAVEN', FOV_frame [J*2], $
          [x2d[M], y2d[M],z2d [M]], spoint,trgepc, srfvec, intercept& $
        intercept_Mars [M] = intercept & $
        if intercept then begin 
          cspice_ilumin, 'Ellipsoid', 'MARS',et[i], 'IAU_MARS', 'NONE', 'MAVEN',$
            spoint, trgepc, srfvec, phase_angle, solar_zenith_angle,emission_angle
          cos_sza_intercept [M] = (solar_zenith_angle lt !pi/2)*cos(solar_zenith_angle)
        endif
      endfor  
      dprint, time_string (times[ind[i]]), ' done' 
      ; print, intercept_Mars
      fraction_FOV_Mars [ind[i],J] = total (intercept_Mars*weighting_array_2d)/total (weighting_array_2d)
      fraction_FOV_sunlit_Mars [ind[i], J] = total (cos_sza_intercept*weighting_array_2d)/total(weighting_array_2d)
    endfor
  endfor  
  answer = $
      {times: times, $
       FOV_order: ['SEP1_front', 'SEP1_back','SEP2_front', 'SEP1_back'], $
       fraction_FOV_Mars: fraction_FOV_Mars, fraction_FOV_sunlit_Mars: fraction_FOV_sunlit_Mars}
  return, answer
end