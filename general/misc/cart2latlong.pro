;This gives latitude and these longitude in degrees when you input x,y,z in
;planetocentric coordinates. 
; created by Robert Lillis

pro cart2latlong, x, y, z, r, lat, elon
  
  pi = 3.1415926535

  r = sqrt(x*x + y*y + z*z)

  ;azimuthal angle
  phi = acos(x/sqrt(x*x + y*y))
  elon = (180/pi)*phi
  elon = (y ge 0.0)*elon + (y lt 0.0)*(elon+(2*(180.0-elon)))

;polar angle
  theta = acos(z/sqrt(x*x + y*y +z*z))
  lat = 90 - (180/pi)*theta
  
  return
end
  
