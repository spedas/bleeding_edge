;+
; PROCEDURE:
;
; get_fa_att_diag.pro
;
; PURPOSE:
;
; Calculates attitude quantites and loads them into tplot structures.
;
; INPUTS:
;
;   T1        Start time of the interval.
;   T2        End time of the interval.
;
; KEYWORDS:
;
; NOTES:      
;
;   Time resolution is 20 seconds.
;
;   Created: 
;   Creator: J.Rauchleiba
;-
pro get_fa_att_diag, t1, t2

; Convert time to double float

if data_type(t1) EQ 7 then start=str_to_time(t1) else start=t1
if data_type(t2) EQ 7 then finish=str_to_time(t2) else finish=t2

; Store orbit data for the specified input time
; This call is necessary to get model B-field data.

get_fa_orbit, start, finish, time_array=0, delta_t=20, $
  /all, /definitive, status=st
if st NE 0 then message, 'Error returned by get_fa_orbit.pro'

; Get exact time array for which orbit data just computed

get_data, 'ORBIT', data=orbit
time_pts = orbit.x
npts = n_elements(time_pts)

; Get the instantaneous rotation matrices to perform the conversion
; GEI -> FASTSPIN

get_fa_attitude, time_pts, /time_array, coord='GEI'
get_data, 'fa_rotmat_gei', data=fa_rotmat_gei
gei2spin = fa_rotmat_gei.y

; Get model magnetic field vectors in GEI (nT)

get_data, 'B_model', data=B_model
Bgei = B_model.y

; Transform magnetic field vectors from GEI to FASTSPIN system

Bspin = dblarr(npts, 3)
for i=0, npts-1 do Bspin(i,*) = reform(gei2spin(i,*,*)) ## reform(Bgei(i,*))

; B-angle out of spin plane

Borth = atan(Bspin(*,2), sqrt(Bspin(*,0)^2 + Bspin(*,1)^2))*!radeg
store_data, 'B_ortho', data={x:time_pts, y:Borth}

; Get the velocity vectors in GEI (km/s)

get_data, 'fa_vel', data=fa_vel
Vgei = fa_vel.y

; Transform velocity from GEI to FASTSPIN

Vspin = dblarr(npts, 3)
for i=0, npts-1 do Vspin(i,*) = reform(gei2spin(i,*,*)) ## reform(Vgei(i,*))

; V-angle out of spin plane

Vorth = atan(Vspin(*,2), sqrt(Vspin(*,0)^2 + Vspin(*,1)^2))*!radeg
store_data, 'V_ortho', data={x:time_pts, y:Vorth}

; Get the Sun pointers in GEI
; Sun pointers are e0 vectors in GSE converted into GEI

Sgse = dblarr(npts, 3)
Sgse(*,0) = 1
store_data, 'SUN_POS_GSE', data={x:time_pts, y:Sgse}
coord_trans, 'SUN_POS_GSE', 'SUN_POS_GEI', 'GSEGEI'
get_data, 'SUN_POS_GEI', data=sun_pos_gei
Sgei = sun_pos_gei.y

; Transform Sun pointer vectors from GEI to FASTSPIN

Sspin = dblarr(npts, 3)
for i=0, npts-1 do Sspin(i,*) = reform(gei2spin(i,*,*)) ## reform(Sgei(i,*))

; Sun angle out of spin plane

Sorth = atan(Sspin(*,2), sqrt(Sspin(*,0)^2 + Sspin(*,1)^2))*!radeg
store_data, 'S_ortho', data={x:time_pts, y:Sorth}


end
