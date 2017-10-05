;rotates any vector about the z-axis by an angle theta, where
;clockwise is from x towards y, just like the azimuth angle in spc
;theta is in RADIANS!!
;
; Created by:  Robert Lillis (rlillis@SSL.Berkeley.edu)


pro rotate_z, theta, x, y, z, x1, y1, z1

  x1 = x*cos(theta) - y*sin(theta)
  y1 = y*cos(theta) + x*sin(theta)
  z1 = z
end
