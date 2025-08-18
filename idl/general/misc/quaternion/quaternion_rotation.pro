;+
;Function quaternion_rotation,v,q
;Usage:  v_prime = quaternion_rotation(v,q)
;
;Purpose: Rotate a vector v using the quaternion q
;
;Inputs: v: a 3 element array, or an Nx3 element array, representing the vectors
;        q: a 4 element array, or an Nx4 element array, representing UNIT quaternion(s)
;
;Alternatively- If last_index=1 then:
;              arrays can be v: 3xN element array
;                            Q: 4xN element array
;
;Written by: Davin Larson
;
; $LastChangedBy: davin-mac $
; $LastChangedDate: 2020-12-16 13:29:21 -0800 (Wed, 16 Dec 2020) $
; $LastChangedRevision: 29514 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/misc/quaternion/quaternion_rotation.pro $
;-
function quaternion_rotation,v,q,last_index=last_index


if n_elements(last_index) eq 0 then begin
    dim_v = size(/dimen,v)
    dim_q = size(/dimen,q)
    wv = where(dim_v eq 3,nwv)
    wq = where(dim_q eq 4,nwq)
    if nwv eq 0 then message,'At least one of V dimensions must be 3'
    if nwq eq 0 then message,'At least one of Q dimensions must be 4'    
    last_index = (dim_v[0] eq 3) and (dim_q[0] eq 4)
    dprint,'Please supply last_index!  should be: ',last_index
endif

if keyword_set(last_index) then begin
    a = q[0,*]
    b = q[1,*]
    c = q[2,*]
    d = q[3,*]
  if size(/n_dimen,v) eq 1 then begin
    v1 = v[0]
    v2 = v[1]
    v3 = v[2]
  endif else begin
    v1 = v[0,*]
    v2 = v[1,*]
    v3 = v[2,*]
  endelse


endif else begin
  if size(/n_dimen,q) eq 1 then begin
    a = q[0]
    b = q[1]
    c = q[2]
    d = q[3]
  endif else begin
    a = q[*,0]
    b = q[*,1]
    c = q[*,2]
    d = q[*,3]
  endelse
  if size(/n_dimen,v) eq 1 then begin
    v1 = v[0]
    v2 = v[1]
    v3 = v[2]
  endif else begin
    v1 = v[*,0]
    v2 = v[*,1]
    v3 = v[*,2]
  endelse
endelse


t2 =   a*b
t3 =   a*c
t4 =   a*d
t5 =  -b*b
t6 =   b*c
t7 =   b*d
t8 =  -c*c
t9 =   c*d
t10 = -d*d


v1new = 2*( (t8 + t10)*v1 + (t6 -  t4)*v2 + (t3 + t7)*v3 ) + v1
v2new = 2*( (t4 +  t6)*v1 + (t5 + t10)*v2 + (t9 - t2)*v3 ) + v2
v3new = 2*( (t7 -  t3)*v1 + (t2 +  t9)*v2 + (t5 + t8)*v3 ) + v3

if keyword_set(last_index) then return, [v1new,v2new,v3new]
return,[[v1new],[v2new],[v3new]]
end



;
;  ; check  rotations:
;
;  alpha = 30d
;  norm = [0.,0.,0.2]  & norm /= sqrt(total(norm^2))
;  eulp = sind(alpha/2) * norm
;  q = transpose( [cosd(alpha/2),eulp] )
;  rot = euler_rot_matrix(eulp)
;  print,euler_rot_matrix(q)
;
;  vec = randomn(seed,1,3)
;
;  printdat,q
;  print,rot
;  printdat,vec
;  vp1 = rot ## vec
;  vp2 = quaternion_rotation(vec,q)
;  printdat,vp1
;  printdat,vp2-vp1
;
;end
;
