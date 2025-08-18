;rotates any vector about the y-axis by an angle theta, where
;clockwise is from z towards x
;theta is in RADIANS!!
;
; Created by:  Robert Lillis (rlillis@SSL.Berkeley.edu)


pro rotate_y, theta, x, y, z, x1, y1, z1

  x1 = x*cos(theta) - z*sin(theta)
  y1 = y
  z1 = z*cos(theta) + x*sin(theta)
end
