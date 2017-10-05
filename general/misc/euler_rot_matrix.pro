
;Produces a rotation matrix given the Euler parameters
;Written by Davin Larson
; See also: quaternion_rotation.pro  

function  euler_rot_matrix,ev,rot_angle=rot_angle,set_angle=sa,parameters=par
if arg_present(par) and size(/type,par) ne 8 then $
    par = {func:'euler_rot_matrix',eulpar:[1d,0,0,0]}
if keyword_set(par) then ev=par.eulpar
rot = dblarr(3,3)
e=double(ev)
if n_elements(ev) eq 3 then begin
  if n_elements(sa) eq 1 then begin
     length = sqrt(total(e^2))
     if length gt 0 then e= e / length
     e = e * sind(sa/2d)
  endif
;  if total(e^2) gt 1 then begin
;      e  /= sqrt(total(e^2))
;      ev=e
;      dprint,'constraining rotation'
;  endif
  e0 = sqrt( 1 - total(e^2) )
  e1 = e[0]
  e2 = e[1]
  e3 = e[2]
endif else begin
  ev /= sqrt(total(ev^2))
  e0 = ev[0]
  e1 = ev[1]
  e2 = ev[2]
  e3 = ev[3]
endelse
rot[0,0] = e0^2+e1^2-e2^2-e3^2
rot[0,1] = 2*(e1*e2 + e0*e3)
rot[0,2] = 2*(e1*e3 - e0*e2)
rot[1,0] = 2*(e1*e2 - e0*e3)
rot[1,1] = e0^2-e1^2+e2^2-e3^2
rot[1,2] = 2*(e2*e3 + e0*e1)
rot[2,0] = 2*(e1*e3 + e0*e2)
rot[2,1] = 2*(e2*e3 - e0*e1)
rot[2,2] = e0^2-e1^2-e2^2+e3^2
rot_angle = acos(e0^2-e1^2-e2^2-e3^2)*180/!dpi * sign(total(e*ev))         ; this can't be correct!!
;rot_angle2 = 2*asin(sqrt(e1^2+e2^2+e3^2)) * 180/!dpi * sign(total(e*ev))
;dprint,dlevel=4,rot_angle,rot_angle2,ev
return,set_zeros(rot,3e-16)
end





;function fit_euler_rot_matrix,dummy,parameters=par
;if not keyword_set(par) then par={func:'fit_euler_rot_matrix',eul:dblarr(3)}
;return,reform(euler_rot_matrix(par.eul),9)
;end


; r= rt ## reform( tsample(),3,3)  & par=0
; help,euler_rot_matrix(dummy,param=par)   ; get parameter structure par
; fit,eulp,r,param=par
; end
