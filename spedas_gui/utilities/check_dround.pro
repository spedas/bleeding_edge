
;helper function for formatannotation.pro
;checks if rounding will add a digit to double format

; lphilpott 6-mar-2012 
; When changes are made to this routine cases that have caused problems in the past should be rechecked
; eg. 1. Page Options margin spinners: 1.65 should be displayed as '1.65' not ' 1.65' or '1.6499999'
;     2. Plotting thd_peif_density for 2007-03-23 the highest default y axis tick is 10^4. Make sure it doesn't display as '******'

pro check_dround, val, neg, dec, precision

    compile_opt idl2, hidden

  ;get string of digit to be rounded
  z = val * 10d^precision
  ; NB: this doesn't always give the result you might expect
  ; eg. you might find that if z=6000.0 z_frac =0.99999999999909
  z_frac = abs(z mod 1.0)
  ; this is an attempt to avoid the problem described above
  ; we are really only interested in the first decimal place anyway - removing this because it causes other problems
  ; z_frac = float(z_frac)
  ;if finite(z_frac) && z_frac gt .5 then dec++

  if finite(z_frac) && z_frac gt .5 then begin 
  ; number will be rounded
    y = round(abs(z),/l64); in case we are dealing with something that can't be fit in 32bit integer
    ; only increase if rounding increases order of magnitude
    ; NB if abs(val) is less than 0 then number of digits left of decimal won't increase
    ; ie. 0.99 rounds to 1 but both have 1 digit left of decimal
    if (floor(alog10(y)) gt floor(alog10(abs(z)))) && abs(val) ge 1 then begin
      dec++
    ; the case below is to catch particular cases where the calculation of floor(alog10(abs(z)))3
    ; ends up rounding it eg. val = -9.9999999999999 with precision = 12 could otherwise 
    ; close with dec=1 
    endif else if floor(alog10(abs(z))) gt (floor(alog10(abs(val))) + precision) then dec++
  endif 
  
;  if z lt 0 then return
;  zs = strtrim(string(z, format='(D255.1)'),1)
;  zs1 = strmid(zs,strlen(zs)-3,1)
;
;  ;add length if rounding increases order of magnitude
;  if is_numeric(zs1) then begin
;    if double(zs1) ge 5 then begin
;      i = neg ? -1:1
;      if floor(alog10(abs( val +i*10d^(-precision) ))) ge dec then dec++
;    endif
;  endif
  
end
