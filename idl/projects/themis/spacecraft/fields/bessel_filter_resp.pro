;+
;function bessel_filter_resp(f, fc, N)
;purpose: Calculates the transfer function of an N-pole Bessel filter
;         with a given cutoff frequency Fc.
; Inputs: f    freqency in Hz
;         fc   Cutoff frequency in Hz
;         N    Number of poles (4 or 5)
; Output: complex transfer function at given frequencies
;-
function bessel_filter_resp, f, fc, N
  if n_elements(fc) eq 0 then fc=4d3
  case N of
    4: begin
         s = dcomplex( 0.0, 1.0)*(2.11391767490422d*f/fc)
         return,105/(s^4 + 10*s^3 + 45*s^2 + 105*s + 105)
       end
    5: begin
         s = dcomplex( 0.0, 1.0)*(2.42741070215263d*f/fc)
         return,945.0d/(s^5+15*s^4 + 105*s^3 + 420*s^2 + 945*s + 945.0d)
       end
    else: print, 'N must be 1, 2 or 4'
  endcase
  return,!values.f_nan
end
