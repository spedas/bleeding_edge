
;helper function for formatannotation.pro
;checks if rounding will add a digit to exponential format
pro check_eround, val, neg, dec, precision, exponent, expsign

  compile_opt idl2, hidden

  ;get string of digit to be rounded
  z = val * 10d^precision
  z_frac = abs(z mod 1.0)
  if finite(z_frac) && z_frac gt .5 then begin ;see if number rounds
     i = neg ? -1:1
     if abs(val +i*10d^(-precision)) ge 10 then begin  ; see if rounding increases order of magnitude
       if expsign eq -1 then begin
         exponent--
       endif else begin
         exponent++
       endelse
       val=val * 10d^(-1) ;if exponent is incremented or decremeneted by rounding then shift abcissa
     endif  
  endif
  
;  zs = strtrim(string(z, format='(D255.1)'),1)
;  zs1 = strmid(zs,strlen(zs)-3,1)
;
;  ;add length and shift if rounding increases order of magnitude
;  if is_numeric(zs1) then begin
;    if double(zs1) ge 5 then begin
;        i = neg ? -1:1
 ;    if abs(val +i*10d^(-precision)) ge 10 then begin
 ;      if expsign eq -1 then begin
 ;        exponent--
 ;      endif else begin
 ;        exponent++
 ;      endelse
 ;      val=val * 10d^(-1)
;    endif
;  endif
  
end
