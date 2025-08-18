; need a really simple integrator, should work the same way as
; int_tabulated
;Hacked from mvn_euv_ionization_hires.pro, jmm, 2025-07-23
function emm_int_simple, x, f, df = df, dx = dx, error= error
  nx = n_elements (x)
  deltax = x [1:*] -x [0: nx -2]
  area =  deltax*0.5*(f [1:*] +f [0: nx -2])
  
  if keyword_set (df) or keyword_set (dx) then begin
     if not keyword_set (df) then df = fltarr(nx)
     if not keyword_set (dx) then dx = fltarr(nx)

     integral = 0
     error = 0.0
     for K = 1, nx-1 do begin
        fterm = 0.5*(f[k-1] + f[k])
        xterm = x[k] - x[k-1]
        ferr = 0.5*sqrt(df[k-1]^2 + df[k]^2)
        xerr = sqrt(dx[k-1]^2 + dx[k]^2)
        z = xterm*fterm
        zerr = abs(z)*sqrt((xerr/xterm)^2 + (ferr/fterm)^2)
        integral = integral + z
        error = sqrt(error^2.0 + zerr^2)
     endfor
     return, integral
  endif else return,  total (area,/nan)
end
