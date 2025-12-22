function fa_mean,x

not_nan = where(x eq x,nnn)

nan = !values.f_nan
denom = float(nnn)
if strmid(idl_type(x),0,6) eq 'double' then begin
    nan = !values.d_nan
    denom = double(nnn)
endif

if nnn gt 0 then begin
    return,total(x(not_nan))/denom
endif else begin
    return,nan
endelse

end
