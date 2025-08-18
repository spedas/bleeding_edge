;+
;NAME:
; mms_transform_velocity_lorentz
;
;PROCEDURE:   mms_transform_velocity_lorentz,  vel, theta, phi,  deltav
;PURPOSE:  used by the convert_vframe routine to transform arrays of velocity
;    thetas and phis by the offset deltav
;INPUT:
;  vel:  array of velocities
;  theta: array of theta values
;  phi:   array of phi values
;  deltav: [vx,vy,vz]  (transformation velocity)
;KEYWORDS:
; vx,vy,vz: return vx,vy,vz separately as well as in vector form
;
;$LastChangedBy: egrimes $
;$LastChangedDate: 2018-12-12 14:04:37 -0800 (Wed, 12 Dec 2018) $
;$LastChangedRevision: 26316 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/common/util/mms_transform_velocity_lorentz.pro $
;-

pro mms_transform_velocity_lorentz, vel,theta,phi,deltav, $
  VX=vx,VY=vy,VZ=vz,sx=sx,sy=sy,sz=sz

  cs = cos(!dpi/180.*theta)
  sx = cs * cos(!dpi/180.*phi)
  sy = cs * sin(!dpi/180.*phi)
  sz = sin(!dpi/180.*theta)

  vx = vel*sx
  vy = vel*sy
  vz = vel*sz

  spd_slice2d_const, c=c
  c = float(c)

  ;lorentz factor
  gamma_u = 1. / sqrt( 1 - total(vel^2)/c^2 )

  ;dot product
  ; -index ensures a scalar so that other array's
  ;  elements are not clipped when multiplied by this
  u_dot_v = vx * deltav[0]  +  vy * deltav[1]  +  vz * deltav[2]

  vx =  vx  -  deltav[0]/gamma_u  +  gamma_u * u_dot_v * vx / ( c^2 * (1 + gamma_u) )
  vy =  vy  -  deltav[1]/gamma_u  +  gamma_u * u_dot_v * vy / ( c^2 * (1 + gamma_u) )
  vz =  vz  -  deltav[2]/gamma_u  +  gamma_u * u_dot_v * vz / ( c^2 * (1 + gamma_u) )

  ;common factor
  vx *= 1./(1 + (u_dot_v)/c^2)
  vy *= 1./(1 + (u_dot_v)/c^2)
  vz *= 1./(1 + (u_dot_v)/c^2)

  vxxyy = vx*vx + vy*vy

  vel = sqrt(vxxyy + vz*vz)
  phi = 180./!dpi*atan(vy,vx)
  phi = phi + 360.d*(phi lt 0)
  theta = 180./!dpi*atan(vz/sqrt(vxxyy))

  return
end
