;This takes lat, long in degrees.

pro latlong2cart, lat, elon, r, x, y, z

  pi = 3.1415926535
  phi = elon*(pi/180.0)
  theta = (pi/2)-(pi/180.0)*lat
  
  
  x = r*sin(theta)*cos(phi)
  y = r*sin(theta)*sin(phi)
  z = r*cos(theta)

  return
end
