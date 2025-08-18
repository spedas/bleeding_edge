;a simple program to convert from spherical polar to Cartesian coordinates
;; INPUTS:
;   x,y,z are Cartesian vector components
;   r is the vector magnitude.
;   theta is the polar angle in RADIANS in spherical polar coordinates
;   phi is the azimuth angle in RADIANS in spherical polar coordinates
; Created by: Robert Lillis (rlillis@ssl.Berkeley.edu)

pro spc2cart, r, theta, phi, x, y, z
  x = r*sin(theta)*cos(phi)
  y = r*sin(theta)*sin(phi)
  z = r*cos(theta)
  
end
