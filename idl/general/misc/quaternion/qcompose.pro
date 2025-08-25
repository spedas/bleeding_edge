;+
;Function: qcompose,v,theta
;
;Purpose: compose quaternions from vectors and angles
;
;Inputs: vec: 3 element array or an Nx3 element array
;        theta: an angle or an N element array of angles(in radians)
;
;Keywords: free: Flag to allow thetas outside [0,pi)
;
;Returns: a 4 element quaternion or an Nx4 element array of quaternions
;
;;Notes: Implementation largely copied from the euve c library for
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
; $LastChangedBy: jwl $
; $LastChangedDate: 2025-08-20 11:11:05 -0700 (Wed, 20 Aug 2025) $
; $LastChangedRevision: 33563 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/misc/quaternion/qcompose.pro $
;-

function qcompose,vec,theta, free=free

compile_opt idl2

;Constant indicating where sin(theta) is close enough to theta
EPSILON = double(1.0e-20)

vi = vec
thi = theta

;bunch of code to validate inputs
if(size(vi,/n_dim) eq 1) then begin
   if(n_elements(vi) ne 3) then begin
      message,'single vector input must have 3 elements'
      return,-1
   endif

   if(n_elements(thi) ne 1) then begin
      message,'angle must have only a single element'
      return,-1
   endif

   vi = reform(vi,1,3)

   thi = reform(thi,1)

endif else if(size(vi,/n_dim) eq 2) then begin

   if(size(thi,/n_dim) ne 1) then begin

      dprint,'theta must be a 1 dimensional array'
      
      return,-1L

   endif

   vdims = size(vi,/dimensions)

   if(n_elements(thi) ne vdims[0]) then begin

      dprint,'number of elements in theta must match number of vectors'

      return,-1L
      
   endif

endif else begin

   dprint,'wrong dimensions for input arrays'

   return,-1L

endelse

;this next block of code moves angles into the range [0,PI)
if ~keyword_set(free) then begin
  thi = thi mod !DPI
  
  idx = where(thi lt 0)
  
  if (idx[0] ne -1) then thi[idx] += !DPI
endif

;calculate the vector norm
;norm = total(vi*vi,2)
norm = sqrt(total(vi*vi,2)) ;10-1-2010 aflores

;decide which quaternions become identity vectors
idx1 = where(norm lt EPSILON)

idx2 = where(norm ge EPSILON)

out_arr = make_array(n_elements(norm),4,/DOUBLE)

if (idx1[0] ne -1) then begin

   out_arr[idx1,0] = 1.0D

   out_arr[idx1,1:3] = 0.0D

endif

if (idx2[0] ne -1) then begin

   out_arr[idx2,0] = cos(thi[idx2]/2.0D)

   stheta2 = sin(thi[idx2]/2.0D)

   out_arr[idx2,1] = (stheta2 * vi[idx2,0])/norm[idx2]
   out_arr[idx2,2] = (stheta2 * vi[idx2,1])/norm[idx2]
   out_arr[idx2,3] = (stheta2 * vi[idx2,2])/norm[idx2]
          
endif

return,reform(out_arr)

end
