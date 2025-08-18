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

pro mso2lt, xmso, ymso, zmso, latss, local_time
; the first thing to do is rotate the MSO coordinate system around the
; Y. axis by an amount equal to the subsolar latitude.  Reason for
; this is that local time is determined with respect to the planetary
; pole
  rotate_y, 1.0*latss*!dtor, xmso, ymso, zmso, x1, y1, z1
  cart2latlong, x1, y1, z1, r, solar_lat_rot, solar_elon_rot
; now rotate around the y-axis by the subsolar latitude.
  ;print,'rotated coordinates: ',solar_lat_rot, solar_elon_rot
  local_time = ((solar_elon_rot +180.0) mod 360)/15.0
end
