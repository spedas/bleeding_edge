; the following function converts Mars-solar-orbital (MSO) coordinates to Mars solar local
; time.  
; The inputs are:
; xmso, ymso, zmso are the Cartesian components in MSO coordinates
; latss is the latitude of the subsolar point in degrees
;
; The outputs are:
; local time, in the usual 0 to 24 hours
; 
; Created by:  Robert Lillis (rlillis@SSL.Berkeley.edu)

pro mso2lt, xmso, ymso, zmso, ls, local_time
; the first thing to do is rotate the MSO coordinate system so that
; the rotation axis is perpendicular to the Mars-sun line.  This
; amount will be zero at the equinoxes and equal to the planetary
; obliquity at the solstices.
  obliquity = 25.19; degrees
  
  rotate_y, 1.0*obliquity*sin(ls*!dtor)*!dtor, xmso, ymso, zmso, x1, y1, z1
  
; next need to rotate to make the rotation axis both perpendicular to
; the Mars-sun line and to the ecliptic plane.
  Rotate_x, 1.0*obliquity*cos(ls*!dtor)*!dtor, x1,y1,z1, xf,yf,zf

  cart2latlong, xf, yf, zf, r, solar_lat_rot, solar_elon_rot

  ;print,'rotated coordinates: ',solar_lat_rot, solar_elon_rot
  local_time = ((solar_elon_rot +180.0) mod 360)/15.0
end
