;+
; :Description:
;   Power Law (PL) function values at the given frequencies
;   with the pl_par parameters.
;
; :Params:
;   INPUTS:
;          f - frequency vector
;     pl_par - power law parameters:
;              pl_par[0] --> c, constant factor
;              pl_par[1] --> beta, spectral index
;   OUTPUTS:
;      plfun - power law function
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
function spd_mtm_pl_fun, f, pl_par
    
  c = double(pl_par[0])
  bet = double(pl_par[1])
  
  fun = make_array(n_elements(f),1,/double, value=!values.d_nan)
  not0 = where(f ne 0.0d)
  fun[not0] = alog10(c) - bet*alog10(f[not0])
  plfun = 10.0d^fun

  return, plfun
  
end