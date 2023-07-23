function getAngle, x, y, DEGREE=DEGREE

;  if n_elements(x) ne n_elements(y) then return, !null
;  if (n_elements(x) lt 2) or (n_elements(y) lt 2) then return, !null
;  
;  tol = total(x*y)
;  xc = sqrt(total(x^2))
;  yc = sqrt(total(y^2))
;  
;  rad = acos(tol/(xc*yc))
;  
;  if keyword_set(degree) then begin
;    return, rad*!RADEG
;  endif else begin
;    return, rad
;  endelse

  ;; CALCULATE VECTOR LENGTH. 
  ;; ベクトルの長さを求める
  vec1_length = (x[0]^2 + x[1]^2 + x[2]^2) ^ 0.5
  vec2_length = (y[0]^2 + y[1]^2 + y[2]^2) ^ 0.5
  if vec1_length eq 0 or vec2_length eq 0 then message, 'The length of the vector is zero.'
  
  ; CALCULATE COS(THETA) 
  ; 内積とベクトル長さを使ってcosθを求める
  cos_sita = (x[0]*y[0] + x[1]*y[1] + x[2]*y[2]) / (vec1_length*vec2_length)
  
  ; CALCULATE THETA 
  ;cosθからθを求める
  sita = acos(cos_sita)
  sita = sita * !RADEG

  return, sita

end
;
;pro test_getAngle
;  
;  x=[0,1,0]
;  y=[1,1,1]
;  
;  print, getAngle(x, y, /DEG)
;
;end
