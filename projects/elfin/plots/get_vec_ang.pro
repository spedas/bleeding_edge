;+
;FUNCTION 
;  get_vec_angle
;
;PURPOSE: 
;  determines angle between two vectors
;
;INPUT:
;  vec1, vec2: either 2d or 3d vectors, arrays possible, 
;              one array, one vector also possible
;              vec[0,*]-x component
;              vec[1,*]-y component
;              vec[2,*]-z component
;             
;OUTPUT:             
;  ang:        angle between vec1,vec2 
; mag1,mag2:   Optional output of magnitude of vectors
; dot_product: scalar product between the two vectors (Optional)
;
;sfrey v1.0
;05-19-08 sfrey added dot_product
;02-23-16 sfrey made it work for 2 or 3 dimensions with one being a vector and theother an array
;               this did only work for 3 dims in the past
;03-03-16 sfrey replaced !d.radeg by 180.d/!dpi
;               moved header to top of file
;01-09-17 sfrey No more return of modified input
;-
function get_vec_ang,vec1,vec2,mag1=mag1,mag2=mag2,dot_product=dot_product

ddradeg=180.d/!dpi
sz1=size(vec1)
sz2=size(vec2)
if sz1[1] ne sz2[1] then begin
 print,'Vec1,vec2 must have vectors of same size.'
 return,-1
endif
vec_1=vec1
vec_2=vec2
if sz1[0] eq 1 and sz2[0] eq 2 then begin
     n=n_elements(vec2[0,*])
     if sz1[1] eq 3 then vec_1=transpose([[replicate(vec1[0],n)],[replicate(vec1[1],n)], $
                                        [replicate(vec1[2],n)]])
     if sz1[1] eq 2 then vec_1=transpose([[replicate(vec1[0],n)],[replicate(vec1[1],n)]])                                    
endif 

if sz1[0] eq 2 and sz2[0] eq 1 then begin
     n=n_elements(vec1[0,*])
     if sz2[1] eq 3 then vec_2=transpose([[replicate(vec2[0],n)],[replicate(vec2[1],n)], $
                                        [replicate(vec2[2],n)]])
     if sz2[1] eq 2 then vec_2=transpose([[replicate(vec2[0],n)],[replicate(vec2[1],n)]])                                   
endif

mag1=sqrt(total(vec_1^2,1))
mag2=sqrt(total(vec_2^2,1))
dummy=total(vec_1*vec_2,1)/(mag1*mag2)  ;here we do need the same size arrays otherwise total does not work

idx=where( dummy lt -1.d,cnt)
if cnt ne 0 then dummy[idx]= -1.d 
idy=where( dummy gt 1.d,cmt)
if cmt ne 0 then  dummy[idy]=1.d

ang=acos(dummy)*ddradeg

dot_product=mag1*mag2*cos(ang*!dtor)

return, ang

end
