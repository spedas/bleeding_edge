;a simple program to convert from Cartesian to spherical polar coordinates
;; INPUTS:
;   x,y,z are Cartesian vector components
;   r is the vector magnitude.
;   theta is the polar angle in RADIANS in spherical polar coordinates
;   phi is the azimuth angle in RADIANS in spherical polar coordinates
; Created by: Robert Lillis (rlillis@ssl.Berkeley.edu)

pro cart2spc, x, y, z, r, theta, phi
  r = sqrt(x*x + y*y + z*z)
  phi = (2*!pi - acos(x/sqrt(x*x + y*y)))*(y lt 0.0) +$
    acos(x/sqrt(x*x + y*y))*(y ge 0.0)
  theta = acos(z/sqrt(x*x + y*y +z*z))
end
 
