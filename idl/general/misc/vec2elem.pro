pro vec2elem, r_x, r_y, r_z, v_x, v_y, v_z, $
  ecc_mag, right_asce, inclination, argu_perigee, mean_anomaly, axis_a, $
  h_mag=h_mag, true_anomaly=true_anomaly

  mu = 398600d ;(km^3/s^2)
    
  ; h - angular moemtum  (km^2/s)
  r_mag = sqrt(r_x^2 + r_y^2 + r_z^2)
  v_mag = sqrt(v_x^2 + v_y^2 + v_z^2)
  h_x = r_y*v_z - r_z*v_y
  h_y = r_z*v_x - r_x*v_z
  h_z = r_x*v_y - r_y*v_x
  h_mag = sqrt(h_x^2 + h_y^2 + h_z^2)
  
  ; inclination (rad)
  inclination = acos(h_z/h_mag)

  ; node line (km^2/s)
  node_x = -h_y
  node_y = h_x
  node_z = 0d
  node_mag = sqrt(node_x^2 + node_y^2 +node_z^2)

  ;right_ascension  (rad)
  right_asce = acos(node_x/node_mag)
  index = where(node_y lt 0, count)
  if count gt 0 then right_asce(index) = 2*!dpi - right_asce(index)   ; ny < 0 quadrant
   
  ; ecc - eccentricity
  rdotv = r_x*v_x + r_y*v_y + r_z*v_z
  ecc_x = 1./mu*((v_mag^2 - mu/r_mag)*r_x - rdotv*v_x)
  ecc_y = 1./mu*((v_mag^2 - mu/r_mag)*r_y - rdotv*v_y)
  ecc_z = 1./mu*((v_mag^2 - mu/r_mag)*r_z - rdotv*v_z)
  ecc_mag = sqrt(ecc_x^2 + ecc_y^2 + ecc_z^2)

  ; argu_perigee - argument of perigee (rad)
  ndote = node_x*ecc_x + node_y*ecc_y + node_z*ecc_z
  argu_perigee = acos(ndote/node_mag/ecc_mag)
  index = where(ecc_z lt 0, count)
  if count gt 0 then argu_perigee(index)= 2*!dpi - argu_perigee(index)    ; ez < 0 quadrant
  
  ; true anomaly (rad)
  edotr = ecc_x*r_x + ecc_y*r_y + ecc_z*r_z
  ndotr = node_x*r_x + node_y*r_y + node_z*r_z
  true_anomaly = acos(edotr/ecc_mag/r_mag)
  index = where(rdotv lt 0, count)
  if count gt 0 then true_anomaly(index) = 2*!dpi - true_anomaly(index)
  
  ; a - semimajor axis (km)
  axis_a = h_mag^2/mu/(1.-ecc_mag^2)

  ; eccentric anomaly (rad)
  ecc_anomaly = acos((ecc_mag+cos(true_anomaly))/(1.+ecc_mag*cos(true_anomaly)))
  index = where(rdotv lt 0, count)
  if count gt 0 then ecc_anomaly(index) = 2*!dpi - ecc_anomaly(index)
  
  ; mean anomaly (rad)
  mean_anomaly = ecc_anomaly - ecc_mag*sin(ecc_anomaly)

  ; n - mean motion (rad/s)
  n = sqrt(mu/axis_a^3)

  ; T - orbit period (s)
  T = 2*!dpi*axis_a^1.5/sqrt(mu)
  ;T = 2*!dpi/n

  return

end





