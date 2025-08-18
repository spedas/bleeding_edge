
; +
; 
; Name: thm_part_slice_trans.pro
; 
; Purpose: Helper function for the slices routines
;          Returns rotaion matrix to new coordinates based on
;          specified z and x axes.  Will add a translation if
;          the CENTER argument is included
; 
; Calling sequence: thm_part_slice_trans, z0, x0, [center,] fail=fail
; 
; Input: z0: 3 vector specifying new z-axis
;        x0: 3 vector specifying new x-axis
;        Center: 3 vector specifying the center of the new coordinates
; 
; Output: 3x3 rotation matrix
;         4x4 transformation matrix (if CENTER specified)
;
;-

function thm_part_slice_trans, z0, x0, center, fail=fail

    compile_opt idl2, hidden
  

  tolerance = 10.0 * 1.19209290e-07
  
  
  ;Get new x, y, and z axes
  ;------------------------
  
  ;z
  z = z0 / sqrt(total(z0^2))
  
  ;x
  x_tmp = x0 / sqrt(total(x0^2))
  x = crossp(z0,crossp(x_tmp, z0))
  if total(abs(x)) lt tolerance then begin
    xstr = '('+strjoin(strtrim(x0,2),',')+')'
    fail = 'Specified x-axis '+xstr+' has no projection into plane.'
    dprint, fail
    return, -1
  endif else begin
    x = x  / sqrt(total(x^2))
  endelse
  
  ;y
  y = crossp(z, x)
  
  
  ;Create rotation matrix
  ;----------------------
  
  tm = [[x],[y],[z]]
  
  
  ;Add transformation
  ;------------------
  if keyword_set(center) then begin

    tm = fltarr(4,4) 
    tm[0:2,0:2] = [[x],[y],[z]] 
    tm[3,3] = 1

    orig_pt = !p.t ;save current
    
    t3d, /reset
  
    !p.t = tm ## !p.t
    
    t3d, translate = float(-center)
    
    tm = float(!p.t) 
    
    !p.t = orig_pt ;reset
  endif

  ;return matrix
  return, tm
  
end
 