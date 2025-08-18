;+
;FUNCTION:  quaternion_to_euler_angles,quaternion  
;PURPOSE:
;  returns euler angles
;  (This function may be used with the "fit" curve fitting procedure.)
;
;KEYWORDS:
;  PARAMETERS: a structure that contain the parameters that define the gaussians
;     If this parameter is not a structure then it will be created.
;
;Written by: Davin Larson  2020-11-28
;
; $LastChangedBy:  $
; $LastChangedDate: 2020-11-29 17:03:26 -0800 (Wed, 10 Jan 2018) $
; $LastChangedRevision:  $
; $URL: svn+/general/m.pro $
;-
;
;
;function quaternion_add_spatial,q3,last_index=last_index
;  q0 =sqrt( 1-total(q3^2))
;return,[q0,q3]
;end


function quaternion_to_euler_angles,q   ,last_index=last_index ;,parameters=par


  dim_q = size(/dimen,q)
  ndim_q = size(/n_dimen,q)
  if ndim_q eq 1 then begin
    q0 = q[0]
    q1 = q[1]
    q2 = q[2]
    q3 = q[3]    
  endif else begin
    if n_elements(last_index) eq 0 then begin
      dim_q = size(/dimen,q)
      dprint,'Please supply last_index'
      wq = where(dim_q eq 4,nwq)
      if nwq eq 0 then message,'At least one of Q dimensions must be 4'
      last_index =  (dim_q[0] eq 4)
    endif
    if keyword_set(last_index) then begin
      q0 = q[0,*]
      q1 = q[1,*]
      q2 = q[2,*]
      q3 = q[3,*]
    endif else begin
      q0 = q[*,0]
      q1 = q[*,1]
      q2 = q[*,2]
      q3 = q[*,3]
    endelse
  endelse

  phi = atan(2*(q0*q1+q2*q3),1-2*(q1^2+q2^2) )   ; roll  (rotation about x)
  theta = asin(2*(q0*q2-q3*q1) )                 ; pitch (rotation about y)
  psi = atan(2*(q0*q3 + q1*q2),1-2*(q2^2+q3^2))  ; yaw   (rotation about z)
  
  if ndim_q eq 1 then begin
    euler_angs = [ phi,theta,psi ] 
  endif else begin
    euler_angs = [[phi],[theta],[psi]]
    if keyword_set(last_index) then begin
      euler_angs = transpose(euler_angs)
    endif else begin
      ; do nothing
    endelse
  endelse
  
return,euler_angs
end


