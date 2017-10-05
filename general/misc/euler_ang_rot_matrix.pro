;+
;FUNCTION:  euler_ang_rot_matrix,eulerang  [parameters=par]
;PURPOSE:
;  returns rotation matrix given the euler angles
;  (This function may be used with the "fit" curve fitting procedure.)
;
;KEYWORDS:
;  PARAMETERS: a structure that contain the parameters that define the gaussians
;     If this parameter is not a structure then it will be created.
;
;Written by: Davin Larson
;
; $LastChangedBy: davin-win $
; $LastChangedDate: 2011-02-15 15:58:20 -0800 (Tue, 15 Feb 2011) $
; $LastChangedRevision: 8223 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/misc/euler_ang_rot_matrix.pro $
;-
function euler_ang_rot_matrix,eulerang,parameters=par
if arg_present(par) and size(/type,par) ne 8 then $
    par = {func:'euler_ang_rot_matrix',phi:0d,the:0d,psi:0d}
if keyword_set(par) then eulerang=[par.phi,par.the,par.psi]
rot = dblarr(3,3)
e=double(eulerang)
scale = !dpi/180
phi = e[0]
the = e[1]
psi = e[2]
e0 = cos((phi+psi)/2d * scale) * cos(the/2d * scale)
e1 = cos((phi-psi)/2d * scale) * sin(the/2d * scale)
e2 = sin((phi-psi)/2d * scale) * sin(the/2d * scale)
e3 = sin((phi+psi)/2d * scale) * cos(the/2d * scale)

rot[0,0] = e0^2+e1^2-e2^2-e3^2
rot[0,1] = 2*(e1*e2 + e0*e3)
rot[0,2] = 2*(e1*e3 - e0*e2)
rot[1,0] = 2*(e1*e2 - e0*e3)
rot[1,1] = e0^2-e1^2+e2^2-e3^2
rot[1,2] = 2*(e2*e3 + e0*e1)
rot[2,0] = 2*(e1*e3 + e0*e2)
rot[2,1] = 2*(e2*e3 - e0*e1)
rot[2,2] = e0^2-e1^2-e2^2+e3^2
rot_angle = acos(e0^2-e1^2-e2^2-e3^2)*180/!dpi ;* sign(total(e*ev))
rot_angle2 = 2*asin(sqrt(e1^2+e2^2+e3^2)) * 180/!dpi ;* sign(total(e*ev))
dprint,dlevel=5,rot_angle,rot_angle2,eulerang
return,set_zeros(rot,3e-16)
end


; r= rt ## reform( tsample(),3,3)  & par=0
; r=  reform( tsample(),3,3)  & par=0
; help,euler_ang_rot_matrix(dummy,param=par)   ; get parameter structure par
; fit,eulp,r,param=par
; end
