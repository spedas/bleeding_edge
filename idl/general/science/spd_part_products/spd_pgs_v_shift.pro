;+
;Procedure:
;  spd_pgs_v_shift
;
;Purpose:
;  Shift a single distribution strucure by a specified velocity vector
;
;Input:
;  data:  Sanitized particle data structure to be operated on
;  vector:  3-vector in km/s
;  matrix:  (optional) rotation matrix to apply to vector before shift
;
;Output:
;  error:  flag, 1 indicates error, 0 none
;
;Notes:
;  -Particle velocities are assumed to be small enough 
;   to use classical calculation.
;
;
;$LastChangedBy: aaflores $
;$LastChangedDate: 2016-09-30 17:28:46 -0700 (Fri, 30 Sep 2016) $
;$LastChangedRevision: 21990 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/science/spd_part_products/spd_pgs_v_shift.pro $
;-

pro spd_pgs_v_shift, data, vector, matrix=matrix, error=error

  compile_opt idl2, hidden


error = 1

if n_elements(vector) ne 3 then return

if n_elements(matrix) eq 9 then begin
  vector = matrix # reform(vector)
endif

;calculate bin velocities
;distribution mass in eV/(km/s)^2
v = sqrt(2d * data.energy/data.mass)

sphere_to_cart, v, data.theta, data.phi, v_x, v_y, v_z

;subtract input vector
v_x -= vector[0]
v_y -= vector[1]
v_z -= vector[2]

cart_to_sphere, v_x, v_y, v_z, v_new, theta, phi, /ph_0_360

;convert back to E and store
data.energy = .5 * data.mass * v_new^2
data.phi = phi
data.theta = theta

error = 0

end