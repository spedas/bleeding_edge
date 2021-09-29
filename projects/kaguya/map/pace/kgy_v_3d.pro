;+
;FUNCTION:	kgy_v_3d
;INPUT:	
;	dat:	structure,	2d data structure filled by get_eesa_surv, get_eesa_burst, etc.
;PURPOSE:
;	Returns the velocity, [Vx,Vy,Vz], km/s 
;CREATED BY:
;	Yuki Harada on 2018-05-09
;       modified from v_3d and v_3d_new
;-
function kgy_v_3d,dat2,_extra=_extra

vel = [0.,0.,0.]

if dat2.valid eq 0 then begin
	dprint, 'Invalid Data'
	return, vel
endif

flux = kgy_j_3d(dat2,_extra=_extra)
density = kgy_n_3d(dat2,_extra=_extra)
if density ne 0. then vel = 1.e-5*flux/density

return, vel

end

