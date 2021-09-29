pro elem2vec, ecc_mag, right_asce, inclination, argu_perigee, mean_anomaly, axis_a, $
  r_x, r_y, r_z, v_x, v_y, v_z

  mu = 398600. ;(km^3/s^2)
  err= 1d-8

  ; transformation matrix
  RA=right_asce
  inc=inclination
  w=argu_perigee
  Matrix_11 = -sin(RA)*cos(inc)*sin(w) + cos(RA)*cos(w)
  Matrix_12 = -sin(RA)*cos(inc)*cos(w) - cos(RA)*sin(w)
  Matrix_21 =  cos(RA)*cos(inc)*sin(w) + sin(RA)*cos(w)
  Matrix_22 =  cos(RA)*cos(inc)*cos(w) - sin(RA)*sin(w)
  Matrix_31 =  sin(inc)*sin(w)
  Matrix_32 =  sin(inc)*cos(w)
  
  ; initialize
  zero = 0*ecc_mag
  rx_orbit = zero
  ry_orbit = zero
  vx_orbit = zero
  vy_orbit = zero
  
  for j = 0l, n_elements(ecc_mag) - 1 do begin 
     ; eccentric anomaly (rad)
     EA=kepler_solver(mean_anomaly[j], ecc_mag[j], err)
     cosEA = cos(EA)
     sinEA = sin(EA)

     ; coordinates in orbit frame
     rx_orbit[j] = axis_a[j]*(cosEA - ecc_mag[j])
     ry_orbit[j] = axis_a[j]*sqrt(1d - ecc_mag[j]^2)*sinEA
     r_mag = axis_a[j]*(1d - ecc_mag[j]*cosEA)
     vx_orbit[j] = -sqrt(mu*axis_a[j])*sinEA/r_mag
     vy_orbit[j] = sqrt(mu*axis_a[j])*sqrt( 1d - ecc_mag[j]^2 )*cosEA/r_mag
  endfor

  ; transform to geocentric equatprial frame
  r_x = Matrix_11*rx_orbit + Matrix_12*ry_orbit 
  r_y = Matrix_21*rx_orbit + Matrix_22*ry_orbit
  r_z = Matrix_31*rx_orbit + Matrix_32*ry_orbit
  v_x = Matrix_11*vx_orbit + Matrix_12*vy_orbit
  v_y = Matrix_21*vx_orbit + Matrix_22*vy_orbit
  v_z = Matrix_31*vx_orbit + Matrix_32*vy_orbit


  return
end