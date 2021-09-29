;+
; PRO/FUN
;
; :Description:
;    Describe the procedure.
;
; :Params:
; ${parameters}
;
; :Keywords:
; ${keywords}
;
; :Examples:
;
; :History:
; 2016/9/10: drafted
;
; :Author: Tomo Hori, ISEE (tomo.hori at nagoya-u.jp)
;
;   $LastChangedDate: 2019-03-17 21:51:57 -0700 (Sun, 17 Mar 2019) $
;   $LastChangedRevision: 26838 $
;
;-
pro cart_trans_matrix_make, x, y, z, mat_out=mat_out
  ;Assuming x,y,z are arrays with dimension of Nx3.

  npar = n_params()
  if npar ne 3 then return

  ndim = ( size(x) )[0]
  mat_out = 0 ;Initialize
  
  if ndim eq 2 then begin

    tnormalize, x, out=ex
    tnormalize, y, out=ey
    tnormalize, z, out=ez

    n = n_elements(ex[*,0])
    mat_out = make_array( n, 3, 3, value=0.D )

    for i=0L, n-1 do begin

      mat = [ [ transpose(ex[i,*]) ], [ transpose(ey[i,*]) ], [ transpose(ez[i,*]) ] ]
      mat_out[i,0:2,0:2] = reform( transpose(mat), 1, 3, 3 )

    endfor

  endif else if ndim eq 1 then begin
    
    ex = x / sqrt( total( x^2 ) ) & ey = y / sqrt( total( y^2 ) ) & ez = z / sqrt( total( z^2 ) ) 
    mat_out = transpose( [ [ex], [ey], [ez] ] ) 

  endif


  return
end
