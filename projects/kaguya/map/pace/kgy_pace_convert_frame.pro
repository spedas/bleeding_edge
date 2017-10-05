;+
; FUNCTION:
;       kgy_pace_convert_frame
; PURPOSE:
;       Converts frame of 3d data using SPICE
;       Available frames: SELENE_M_SPACECRAFT, MOON_ME, SSE, GSE
;       'phi' and 'theta' tags will be converted
;       'dphi' and 'dtheta' tags will NOT be converted
; CALLING SEQUENCE:
;       dnew = kgy_pace_convert_frame(d,newframe='MOON_ME')
; INPUTS:
;       3d data structure created by kgy_*_get3d
; KEYWORDS:
;       oldframe: old frame (Def. frame defined in the input data)
;       newframe: new frame (Def. 'SSE')
;       vnew: returns new velocity vectors = {vx:vxnew,vy:vynew,vz:vznew}
; CREATED BY:
;       Yuki Harada on 2016-09-17
;
; $LastChangedBy: haraday $
; $LastChangedDate: 2016-09-17 14:37:45 -0700 (Sat, 17 Sep 2016) $
; $LastChangedRevision: 21850 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/kaguya/map/pace/kgy_pace_convert_frame.pro $
;-

function kgy_pace_convert_frame, dat, oldframe=oldframe, newframe=newframe, vnew=vnew, ph_0_360=ph_0_360

if size(ph_0_360,/type) eq 0 then ph_0_360 = 1

if ~keyword_set(newframe) then newframe = 'SSE' else newframe = strupcase(newframe)

if ~keyword_set(oldframe) then oldframe = strupcase(dat.spice_frame) else begin
   if tag_exist(d,'spice_frame') then begin
      if strupcase(dat.spice_frame) ne strupcase(oldframe) then begin
         dprint,'oldframe and spice_frame in the input data do not match'
         dprint,'Returning...'
         return, dat
      endif
   endif
endelse

newdat = dat
vabs = (2.*newdat.energy/newdat.mass)^.5
sphere_to_cart, vabs, newdat.theta, newdat.phi, vx, vy, vz

if oldframe eq newframe then begin
   vnew = {vx:vx,vy:vy,vz:vz}
   str_element,newdat,'spice_frame',newframe,/add
   return, newdat
endif

q = spice_body_att(oldframe, newframe, (newdat.time+newdat.end_time)/2d,/quaternion)

t2 =   q[0]*q[1]                ;- cf. quaternion_rotation.pro
t3 =   q[0]*q[2]
t4 =   q[0]*q[3]
t5 =  -q[1]*q[1]
t6 =   q[1]*q[2]
t7 =   q[1]*q[3]
t8 =  -q[2]*q[2]
t9 =   q[2]*q[3]
t10 = -q[3]*q[3]

vxn = 2*( (t8 + t10)*vx + (t6 -  t4)*vy + (t3 + t7)*vz ) + vx
vyn = 2*( (t4 +  t6)*vx + (t5 + t10)*vy + (t9 - t2)*vz ) + vy
vzn = 2*( (t7 -  t3)*vx + (t2 +  t9)*vy + (t5 + t8)*vz ) + vz

vnew = {vx:vxn,vy:vyn,vz:vzn}

cart_to_sphere,vxn,vyn,vzn,vabsn,thetan,phin,ph_0_360=ph_0_360

newdat.theta = thetan
newdat.phi = phin

str_element,newdat,'spice_frame',newframe,/add

if tag_exist(newdat,'magf') then begin
   bx = newdat.magf[0]
   by = newdat.magf[1]
   bz = newdat.magf[2]
   bxn = 2*( (t8 + t10)*bx + (t6 -  t4)*by + (t3 + t7)*bz ) + bx
   byn = 2*( (t4 +  t6)*bx + (t5 + t10)*by + (t9 - t2)*bz ) + by
   bzn = 2*( (t7 -  t3)*bx + (t2 +  t9)*by + (t5 + t8)*bz ) + bz
   newdat.magf = [bxn,byn,bzn]
endif

if tag_exist(newdat,'vsw') then begin
   vswx = newdat.vsw[0]
   vswy = newdat.vsw[1]
   vswz = newdat.vsw[2]
   vswxn = 2*( (t8 + t10)*vswx + (t6 -  t4)*vswy + (t3 + t7)*vswz ) + vswx
   vswyn = 2*( (t4 +  t6)*vswx + (t5 + t10)*vswy + (t9 - t2)*vswz ) + vswy
   vswzn = 2*( (t7 -  t3)*vswx + (t2 +  t9)*vswy + (t5 + t8)*vswz ) + vswz
   newdat.vsw = [vswxn,vswyn,vswzn]
endif


return, newdat

end
