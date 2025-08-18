;
; get rotation angles
;
function stel3d_get_rotation_angles, mat, DEGREE=degree
  
;  print, '---------------'
;  print, mat
  if n_elements(mat) ne 16 then message, 'invalid input'
;  thresh = 0.001d
  
;  if (mat[2,1]-1d) lt thresh then begin
;    angle_x = !dpi/2
;    angle_y = 0d
;    angle_z = atan2(mat[1,0], mat[0,0])
;  endif else if (abs(mat[2,1] + 1.0) lt thresh) then begin
;      angle_x = (-1*!DPI)/2
;      angle_y = 0d
;      angle_z = atan2(mat[1,0], mat[0,0])
;  endif else begin
      angle_x = asin(mat[2,1])
      angle_y = atan(-1*mat[2,0], mat[2,2])
      angle_z = atan(-1*mat[0,1], mat[1,1])
;      
;  endelse
  if keyword_set(degree) then begin
    return, [angle_x, angle_y, angle_z] * !RADEG ;To Degrees
  endif else begin
    return, [angle_x, angle_y, angle_z]
  endelse

end