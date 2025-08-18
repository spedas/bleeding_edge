;+
;function butterworth_filter_resp(f, fc, N)
;purpose: Calculates the transfer function of an N-pole Butterworth filter
;         with a given cutoff frequency Fc.
; Inputs: f    freqency in Hz
;         fc   Cutoff frequency in Hz
;         N    Number of poles (must be 1, 2 or 4)
; Output: complex transfer function at given frequencies
;-
function butterworth_filter_resp, f, fc, N
  FreqRatio = f/fc
  FreqRatio2 = FreqRatio*FreqRatio
  resp = !values.f_nan
  case N of
     1: resp = 1.0/complex(1.0, FreqRatio)
     2: resp = 1.0/complex(1.0-FreqRatio2, 1.414214*FreqRatio)
     4: resp = 1.0/(complex(1.0-FreqRatio2, 1.847759*FreqRatio) * $
                    complex(1.0-FreqRatio2, 0.765367*FreqRatio))
     else:     print, 'N must be 1, 2 or 4'
  endcase
  return, resp
end

           
        
  
