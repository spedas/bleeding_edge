;+
; :Description:
;   First order autoregressive (AR(1)) function values
;   at the given frequencies with the ar1_par parameters.
;
; :Params:
;   INPUTS:
;          f - frequency vector
;     pl_par - power law parameters:
;              ar1_par[0] --> c, constant factor
;              ar1_par[1] --> rho, lag one autoregressive coefficient
;        fny - Nyquist frequency
;        
;   OUTPUTS:
;     ar1fun - first order autoregressive function
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
function spd_mtm_ar1_fun, f, ar1_par, fny
  
  c = double(ar1_par[0])
  rho = double(ar1_par[1])
  f = double(f)
  
  den = (1.0d - (2.0d * rho * cos(!dpi*f/fny)) + rho^2.0d)
  if total(den eq 0.0d) gt 0 then begin
    ar1fun = make_array(n_elements(f),1,/double, value=!values.d_nan)
    ind = where(den ne 0.0d, /null)
    ar1fun[ind] = c/den[ind]
  endif else ar1fun = c/den
  
  return, ar1fun
  
end