;+
; returns 3-point derivative of a 1-d array.
;-
function deltas,x

if idl_type(x) eq 'double' then begin
    nan = !values.d_nan
    two = 2.d
endif else begin
    nan = !values.f_nan
    two = 2.
endelse
    
nx = n_elements(x)
dx = fltarr(nx)

fi = where(finite(x),nfi)

if nfi eq 0 then begin
    dx(*) = nan
endif

dx(fi(1:nfi-2l)) = (x(fi(2:nfi-1l))-x(fi(0:nfi-3l)))/two
dx(0) = dx(1)
dx(nx-1l) = dx(nx-2l)

return,dx
end


