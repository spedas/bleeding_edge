;+
;NAME:
; mms_transform_velocity
;
;PROCEDURE:   mms_transform_velocity,  vel, theta, phi,  deltav
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
;CREATED BY:  Davin Larson
;
;Forked for MMS by egrimes, 12/12/2018
;
;$LastChangedBy: egrimes $
;$LastChangedDate: 2018-12-12 14:03:56 -0800 (Wed, 12 Dec 2018) $
;$LastChangedRevision: 26315 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/common/util/mms_transform_velocity.pro $
;-

pro mms_transform_velocity, vel,theta,phi,deltav, $
  VX=vx,VY=vy,VZ=vz,sx=sx,sy=sy,sz=sz

  c = cos(!dpi/180.*theta)
  sx = c * cos(!dpi/180.*phi)
  sy = c * sin(!dpi/180.*phi)
  sz = sin(!dpi/180.*theta)

  vx = (vel*sx) - deltav[0]
  vy = (vel*sy) - deltav[1]
  vz = (vel*sz) - deltav[2]

  vxxyy = vx*vx + vy*vy
  vel = sqrt(vxxyy + vz*vz)
  phi = 180./!dpi*atan(vy,vx)
  phi = phi + 360.d*(phi lt 0)
  theta = 180./!dpi*atan(vz/sqrt(vxxyy))

  return
end