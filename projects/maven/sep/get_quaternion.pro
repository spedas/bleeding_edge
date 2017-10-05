

;+
; function get_quaternion(v1,new_v1)
; Purpose: Returns the quaternion that provides the smallest angle rotation that transforms V1 into V1_prime.
;      If V1_prime is not provided it is assumed to be [0,0,1]
;      Use QUATERNION_ROTATION to perform the rotaton.
;-
function get_quaternion,v1,newv,last_index=last_index
  if not keyword_set(newv) then newv = [0,0,1.d]      ; z-axis by default
  dim_v1 = size(/dimen,v1)
  if dim_v1[0] ne 3 then message,'First dimension of V must be 3'
  dim_newv = size(/dimen,newv)
  if dim_newv[0] ne 3 then message,'First dimension of V_prime must be 3'
  ;if ~keyword_set( last_index)  then dprint,'Only works if the last_index is set to 1'
  nd = size(/n_dimen,v1)
  n = nd eq 1 ? 1 : dim_v1[nd-1]
  ;printdat,n,dim_v1
  V1_norm = v1/ ( [1,1,1] # sqrt(total(v1^2,1)) )
  newv_ =  (size(/n_dimen,newv) eq 2) ? newv : (newv # replicate(1,n))
  newv_norm = newv_ / ([1,1,1] # sqrt(total(newv_^2,1)) )
  cos_angle = total( V1_norm * newv_norm ,1)
  c = crossp_trans(V1_norm,newv_norm)
  cl = sqrt( total(c^2,1) )             ; cl = sin_angle = cl
  sin_angle_2 = sqrt((1-cos_angle)/2)
  ;angle = asin( cl )
  ;e = c * ( [1,1,1] # ( sin(angle/2d)/cl) )
  w = where(cl eq 0 and cos_angle gt 0,nw)
  if nw ne 0 then begin
    dprint,dlevel=2,'Singular case 0'  ; Not a bad case
    cl[w] = 1
    sin_angle_2[w]  =  0.
  endif
  w = where(cl eq 0 and cos_angle lt 0,nw)
  if nw ne 0 then begin
    dprint,'Singular case 1' ; Bad -requires a 180 degree rotation
    ;   cl[w] = 1
    ;   sin_angle_2[w] =
    ;   c[*,w] =   !values.f_nan ;  [1,0,0] # replicate(1,nw)  ; Not correct!!!
  endif
  e = c * ( [1,1,1] # (sin_angle_2/cl) )
  ;e0 =  sign( dot ) * sqrt( 1 - total(e^2,1) )               ; these equations may not be optimized!
  e0 =  sqrt( 1 - total(e^2,1) )               ; these equations may not be optimized!
  ;e  =  ([1,1,1] # sign( dot ) ) * e
  ;rot_angle = acos(e0^2-e1^2-e2^2-e3^2)*180/!dpi   ;* sign(total(e*ev))
  eulerp = [transpose([e0]),e]
  return,eulerp
end

