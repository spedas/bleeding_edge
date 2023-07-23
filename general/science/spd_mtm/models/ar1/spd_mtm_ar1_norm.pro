;+
; :Description:
;   Constant normalization factor for the AR(1) model estimated with
;   the maximum likelihood theoretical solution.
;
; :Params:
;   INPUTS:
;       rho - lag-one autoregressive coefficient
;        ff - Fourier frequencies vector
;       psd - power spectral density
;     alpha - half degree of freedom of Smtm for each frequency
;       fny - Nyquist frequency
;
;   OUTPUTS:
;         c - constant factor
;
; :Author:
;     Simone Di Matteo, Ph.D.
;     8800 Greenbelt Rd
;     Greenbelt, MD 20771 USA
;     E-mail: simone.dimatteo@nasa.gov
;-
;*****************************************************************************;
;                                                                             ;
;   Copyright (c) 2020, by Simone Di Matteo                                   ;
;                                                                             ;
;   Licensed under the Apache License, Version 2.0 (the "License");           ;
;   you may not use this file except in compliance with the License.          ;
;   See the NOTICE file distributed with this work for additional             ;
;   information regarding copyright ownership.                                ;
;   You may obtain a copy of the License at                                   ;
;                                                                             ;
;       http://www.apache.org/licenses/LICENSE-2.0                            ;
;                                                                             ;
;   Unless required by applicable law or agreed to in writing, software       ;
;   distributed under the License is distributed on an "AS IS" BASIS,         ;
;   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.  ;
;   See the License for the specific language governing permissions and       ;
;   limitations under the License.                                            ;
;                                                                             ;
;*****************************************************************************;
;
function spd_mtm_ar1_norm, rho, ff, fny, psd, alpha
;
den = (1.0d - (2.0d * rho[0] * cos(!dpi*ff/fny)) + rho[0]^2.0d)
;
if total(den eq 0.0d) gt 0 then begin
  res = make_array(n_elements(f),1,/double, value=!values.d_nan)
  ind = where(den ne 0.0d, /null)
  res[ind] = 1.0d/den[ind]
endif else res = 1.0d/den
;
c = total(alpha*psd/res)/total(alpha)
;
return, c
;
end