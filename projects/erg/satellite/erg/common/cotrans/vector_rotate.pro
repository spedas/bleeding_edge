;+
; PRO vector_rotate 
; 
; :Description:
; To rotate a vector or vector array with Rodrigues' formula 
; 
; :Params:
; x0, y0, z0: each component of input vector(s) to be rotated 
; nx, ny, nz: the rotation axis vector around which the input vectors are rotated
; theta: the rotation angle in degree 
; 
; :History:
; 2016/9/10: drafted
;
; :Author: Tomo Hori, ISEE (tomo.hori at nagoya-u.jp)
;
;   $LastChangedDate: 2019-03-17 21:51:57 -0700 (Sun, 17 Mar 2019) $
;   $LastChangedRevision: 26838 $
;-
pro vector_rotate, x0, y0, z0, nx, ny, nz, theta, x1, y1, z1
  ;It is recommended that all arguments are given as double-precision for a better precision. 
  ;Of course this works with single-precision values, too. 
  
  ;Error check
  npar = n_params()
  if npar ne 10 then begin
    print, 'No. of arguments is invalid: vector_rotate.pro'
    return
  endif
  if n_elements(nx) ne n_elements(theta) then begin
    print, 'Array size is NOT identical: (nx,ny,nz) and theta  in vector_rotate.pro'
    return
  endif
  
  ;For (x0, y0, z0) and (nx,ny,nz) given as a single vector
  if n_elements(x0) eq 1 and n_elements(nx) eq 1 and n_elements(theta) eq 1 then begin
  
    ;Prepare sin/cos values for the rotation angle theta.
    dtor = !dpi / 180.d  ; deg --> rad
    the = theta * dtor
    costhe = cos(the)
    sinthe = sin(the)
    
    ;Normalize the rotation axis vector to the unit vector
    n = sqrt( nx^2 + ny^2 + nz^2 )
    nx /= n & ny /= n & nz /= n
    
    rodrigues_mat = [ $
      [ nx^2*(1.D -costhe) + costhe, nx*ny*(1.D -costhe)-nz*sinthe, nz*nx*(1.D -costhe)+ny*sinthe ], $
      [ nx*ny*(1.D -costhe)+nz*sinthe, ny^2*(1.D -costhe)+costhe, ny*nz*(1.D -costhe)-nx*sinthe ], $
      [nz*nx*(1.D -costhe)-ny*sinthe, ny*nz*(1.D -costhe)+nx*sinthe, nz^2*(1.D -costhe)+costhe ] $
      ]
      
    r1 = rodrigues_mat ## transpose( [ x0, y0, z0 ] ) 
    x1 = r1[0] & y1 = r1[1] & z1 = r1[2]
    
    return 
    
  ;For all of (x0, y0, z0), (nx, ny, nz), theta given as arrays. 
  ;This routine is called recursively to get (x1, y1, z1) as an array with the same dimension as (x0,y0,z0)
  endif else if n_elements(x0) gt 1 and n_elements(nx) gt 1 and n_elements(theta) gt 1 then begin 
    
    if n_elements(x0) ne n_elements(nx) or n_elements(nx) ne n_elements(theta) or $
      n_elements(x0) ne n_elements(theta) then begin 
      print, 'In vector_rotate, the array dimensions differ!! Skipped!'
      return
    endif 
    
    x1 = x0 & y1 = y0 & z1 = z0 
    x1[*] = 0. & y1[*] = 0. & z1[*] = 0. ;Initialize 
    
    for i=0L, n_elements(x0)-1 do begin 
      vector_rotate, x0[i], y0[i], z0[i], nx[i], ny[i], nz[i], theta[i], xt, yt, zt 
      x1[i] = xt & y1[i] = yt & z1[i] = zt 
    endfor
    
    return
    
  ;For (x0,y0,z0) given as an array with a vector nx and scalar theta. 
  ;x1,y1,z1 are returned in the same size of x0. 
  endif else if n_elements(x0) gt 1 and n_elements(nx) eq 1 and n_elements(theta) eq 1 then begin
  
    ;Prepare sin/cos values for the rotation angle theta.
    dtor = !dpi / 180.d  ; deg --> rad
    the = theta * dtor
    costhe = cos(the)
    sinthe = sin(the)
    
    ;Normalize the rotation axis vector to the unit vector
    n = sqrt( nx^2 + ny^2 + nz^2 )
    nx /= n & ny /= n & nz /= n
    x1 = x0 & x1[*] = 0. ;Initialize
    y1 = y0 & y1[*] = 0. 
    z1 = z0 & z1[*] = 0. 
    
    ;Normalize the rotation axis vector to the unit vector
    n = sqrt( nx^2 + ny^2 + nz^2 )
    nx /= n & ny /= n & nz /= n
    
    rodrigues_mat = [ $
      [ nx^2*(1.D -costhe) + costhe, nx*ny*(1.D -costhe)-nz*sinthe, nz*nx*(1.D -costhe)+ny*sinthe ], $
      [ nx*ny*(1.D -costhe)+nz*sinthe, ny^2*(1.D -costhe)+costhe, ny*nz*(1.D -costhe)-nx*sinthe ], $
      [nz*nx*(1.D -costhe)-ny*sinthe, ny*nz*(1.D -costhe)+nx*sinthe, nz^2*(1.D -costhe)+costhe ] $
      ]
      
    for i = 0L, n_elements(x0)-1 do begin
        
      r1 = rodrigues_mat ## transpose( [ x0[i], y0[i], z0[i] ] )
      x1[i] = r1[0] & y1[i] = r1[1] & z1[i] = r1[2]
      
    endfor
    
  endif
  
  
  
  return
end
