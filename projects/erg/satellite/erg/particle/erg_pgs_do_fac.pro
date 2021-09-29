;+
;Procedure:
;  erg_pgs_do_fac
;
;Purpose:
;  Applies field aligned coordinate transformation to input data
;
;Input:
;  data: The struct to be rotated
;  mat: The fac rotation matrix
;       mat should be a 3x3 array if by_spin_phase is NOT set,
;       otherwise a 3x3x32 array containing the matrices
;       for all spin phases separately
;
;Output:
;  output=output:  The struct of rotated data
;  error=error: 1 indicates error occured, 0 indicates no error occured
;
;
;$LastChangedDate: 2019-10-23 14:19:14 -0700 (Wed, 23 Oct 2019) $
;$LastChangedRevision: 27922 $
;-


pro erg_pgs_do_fac,data,mat,output=output,error=error, by_spin_phase=by_spin_phase

  compile_opt idl2,hidden

  if undefined(by_spin_phase) then by_spin_phase = 0
  
  error = 1

  output_t=data
  ;identity matrix for testing
  ;mat = [[1,0,0],[0,1,0],[0,0,1]]

  ;if nans are in the transform matrix, replace data with NANs instead.
  ;Downstream code is not really equipped to properly handle NaNs in angles
  if total(finite(mat)) lt n_elements(mat) then begin
    output_t.data = !values.d_nan
  endif else begin

    r = replicate(1., n_elements(data.data)) 
    sphere_to_cart, r, reform(data.theta, n_elements(data.theta)), reform(data.phi, n_elements(data.phi)), vec=cart_data
    
    x = mat[0, 0]*cart_data[*, 0] + mat[0, 1]*cart_data[*, 1] + mat[0, 2]*cart_data[*, 2]
    y = mat[1, 0]*cart_data[*, 0] + mat[1, 1]*cart_data[*, 1] + mat[1, 2]*cart_data[*, 2]
    z = mat[2, 0]*cart_data[*, 0] + mat[2, 1]*cart_data[*, 1] + mat[2, 2]*cart_data[*, 2]
    
    cart_to_sphere, x, y, z, r, theta, phi, /ph_0_360
    
    output_t.theta = theta
    output_t.phi = phi
    
    error = 0
    
    
  endelse
  
  output = output_t
  
end
