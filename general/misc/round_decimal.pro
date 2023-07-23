; this is when you want to round a number to the nearest 100, 10, 1,
; 0.1 etc. etc.

; Decimal_places should be an integer, positive or negative.  Negative
; means moving the decimal point to the left, positive to the right.
function round_decimal, x,  decimal_places
  base =  10.0 ^ decimal_places
  remainder = x mod base
  up =  (remainder ge base*0.5) 
  dn =  (remainder lt base*0.5)
  answer =  up*(x - remainder + base) + dn*(x - remainder)
  return,  answer
end
