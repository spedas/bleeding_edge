;+
;Procedure:
;  spd_slice2d_subtract
;
;Purpose:
;  Shift velocities by specified vector
;
;Calling Sequence:
;  spd_slice2d_subtract, vectors=vectors, velocity=velocity, fail=fail
;
;Input:
;  vectors:  Nx3 array of vectors in km/s
;  velocity:  3-vector to shift by in km/s
;
;Output:
;  fail:  contains error message if error occurs
;
;Notes:
;
;
;$LastChangedBy: aaflores $
;$LastChangedDate: 2015-09-18 18:17:56 -0700 (Fri, 18 Sep 2015) $
;$LastChangedRevision: 18847 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/science/spd_slice2d/core/spd_slice2d_subtract.pro $
;-

pro spd_slice2d_subtract, vectors=u, velocity=v_in, fail=fail

    compile_opt idl2, hidden


if undefined(u) then return
if undefined(v_in) then return

if dimen2(u) ne 3 or n_elements(v_in) ne 3 then begin
  fail = 'Invalid vector dimensions, cannot subtract velocity'
  dprint, dlevel=0, fail 
  return
endif

if total( ~finite(v_in) ) gt 0 then begin
  fail = 'Invalid bulk velocity data, cannot perform subtractions'
  dprint, dlevel=0, fail
  return
endif

v = -v_in

u[0,0] = u[*,0] + v[0]
u[0,1] = u[*,1] + v[1]
u[0,2] = u[*,2] + v[2]


;;relativistic calc in cases it's needed
;;---------------------------------------
;
;spd_slice2d_const, c=c
;c = float(c)
;
;;lorentz factor
;gamma_u = 1. / sqrt( 1 - total(u^2,2)/c^2 )
;
;;dot product
;; -index ensures a scalar so that other array's 
;;  elements are not clipped when multiplied by this
;u_dot_v = (u[*,0] * v[0]  +  u[*,1] * v[1]  +  u[*,2] * v[2])[0]
;
;u[0,0] =  u[*,0]  +  v[0]/gamma_u  +  gamma_u * u_dot_v * u[*,0] / ( c^2 * (1 + gamma_u) )
;u[0,1] =  u[*,1]  +  v[1]/gamma_u  +  gamma_u * u_dot_v * u[*,1] / ( c^2 * (1 + gamma_u) )
;u[0,2] =  u[*,2]  +  v[2]/gamma_u  +  gamma_u * u_dot_v * u[*,2] / ( c^2 * (1 + gamma_u) )
;
;;common factor
;u *= 1./(1 + (u_dot_v)/c^2) 


end