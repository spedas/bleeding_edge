;rotates any vector about the x-axis by an angle theta, where
;clockwise is from z towars y
;theta is in RADIANS!!

; Created by:  Robert Lillis (rlillis@SSL.Berkeley.edu)


pro rotate_x, theta, x, y, z, x1, y1, z1

  x1 = x
  y1 = y*cos(theta) - z*sin(theta)
  z1 = z*cos(theta) + y*sin(theta)
end
