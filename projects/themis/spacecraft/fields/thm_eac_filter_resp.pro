;+
;function thm_eac_filter_resp(f)
;purpose: Calculates the transfer function of the DFB EAC anti-aliasing filter.
; Inputs: f    freqency in Hz
; Output: complex transfer function at input frequencies
;-
function thm_eac_filter_resp,f
  fc=8192.d/2
  flo=47.0d
  s = dcomplex( 0.0, 1.0)*(2.11391767490422d*f/fc)
  resp=105/(s^4 + 10*s^3 + 45*s^2 + 105*s + 105)
  s = dcomplex( 0.0, 1.0)*(f/flo)
return,resp*s/(s+1)
end