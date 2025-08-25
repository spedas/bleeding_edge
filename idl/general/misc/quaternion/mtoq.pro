;+
;Function: mtoq
;
;Purpose: transforms a rotation matrix into a quaternion.  If the
;matrix does not perform a rotation, then its behavior may be ill-
;defined
;
;WARNING!!!! - this routine does not conform to the wikipedia definition.  see warning for qtom.pro
;
;Inputs: m: a 3x3 element array or an Nx3x3 element array
;
;Returns: q
;
;Notes: Implementation largely copied from the euve c library for
;quaternions
;Represention has q[0] = scalar component
;                 q[1] = vector x
;                 q[2] = vector y
;                 q[3] = vector z
;
;The vector component of the quaternion can also be thought of as
;an eigenvalue of the rotation the quaterion performs
;
;
;Written by: Patrick Cruce(pcruce@igpp.ucla.edu)
;
;
; $LastChangedBy: jwl $
; $LastChangedDate: 2025-08-20 11:11:05 -0700 (Wed, 20 Aug 2025) $
; $LastChangedRevision: 33563 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/misc/quaternion/mtoq.pro $
;-

function mtoq,m

compile_opt idl2

dims = size(/dimensions,m)

mi = m

if(n_elements(dims) eq 2) then begin
   if((dims[0] ne 3) or (dims[1] ne 3)) then begin
      dprint,'Wrong dimensions in input matrix'
      return,-1
   endif

   mi = reform(m,1,3,3)

   dims = [1,dims]

endif else if(n_elements(dims) eq 3) then begin
   if((dims[1] ne 3) or (dims[2] ne 3)) then begin
      dprint,'Wrong dimensions in input matrix'
      return,-1
   endif
endif else begin
   dprint,'Wrong dimensions in input matrix'
   return,-1
endelse

;the code below is copied almost verbatim out of the euve 
;quaternion library, with the exception of the fact that this code is
;vectorized...something seems a little odd with this code, however...

qout = dblarr(dims[0],4)

arg = 1D + mi[*,0,0] + mi[*,1,1] + mi[*,2,2]

idx = where(arg lt 0.0D)

if(idx[0] ne -1) then arg[idx] = 0.0D

qout[*,0] = 0.5D * sqrt(arg)

arg = 1D + mi[*,0,0] - mi[*,1,1] - mi[*,2,2]

idx = where(arg lt 0.0D)

if(idx[0] ne -1) then arg[idx] = 0.0D

qout[*,1] = 0.5D * sqrt(arg)

arg = 1D - mi[*,0,0] + mi[*,1,1] - mi[*,2,2]

idx = where(arg lt 0.0D)

if(idx[0] ne -1) then arg[idx] = 0.0D

qout[*,2] = 0.5D * sqrt(arg)

arg = 1D - mi[*,0,0] - mi[*,1,1] + mi[*,2,2]

idx = where(arg lt 0.0D)

if(idx[0] ne -1) then arg[idx] = 0.0D

qout[*,3] = 0.5D * sqrt(arg)

imax = intarr(dims[0])
dmax = dblarr(dims[0])

for i=0,3 do begin
   idx = where(abs(qout[*,i]) gt dmax)
   if(idx[0] ne -1) then begin
      imax[idx] = i
      dmax[idx] = qout[idx,i]
   endif
endfor

idx = where(imax eq 0)

if idx[0] ne -1 then begin
   qout[idx,1] = (mi[idx,2,1]-mi[idx,1,2])/(4*qout[idx,0])
   qout[idx,2] = (mi[idx,0,2]-mi[idx,2,0])/(4*qout[idx,0])
   qout[idx,3] = (mi[idx,1,0]-mi[idx,0,1])/(4*qout[idx,0])
endif
   
idx = where(imax eq 1)

if idx[0] ne -1 then begin
   qout[idx,2] = (mi[idx,1,0]+mi[idx,0,1])/(4*qout[idx,1])
   qout[idx,3] = (mi[idx,2,0]+mi[idx,0,2])/(4*qout[idx,1])
   qout[idx,0] = (mi[idx,2,1]-mi[idx,1,2])/(4*qout[idx,1])
endif
   
idx = where(imax eq 2)

if idx[0] ne -1 then begin
   qout[idx,3] = (m[idx,2,1]+m[idx,1,2])/(4*qout[idx,2])
   qout[idx,0] = (m[idx,0,2]-m[idx,2,0])/(4*qout[idx,2])
   qout[idx,1] = (m[idx,1,0]+m[idx,0,1])/(4*qout[idx,2])
endif
   
idx = where(imax eq 3)

if idx[0] ne -1 then begin
   qout[idx,0] = (mi[idx,1,0]-mi[idx,0,1])/(4*qout[idx,3])
   qout[idx,1] = (mi[idx,2,0]+mi[idx,0,2])/(4*qout[idx,3])
   qout[idx,2] = (mi[idx,2,1]+mi[idx,1,2])/(4*qout[idx,3])
endif

idx = where(qout[*,0] < 0D)

if idx[0] ne -1 then qout[idx,*] = -qout[idx,*]

qret = qnormalize(qout)

return, reform(qret)

   
end
