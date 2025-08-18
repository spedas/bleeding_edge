;+
; :Description:
;   Evaluate the log-likelihood of
;   the white noise (WHT) PSD model.
; 
; :Params:
;   INPUTS:
;         wht_par - power law PSD parameters:
;
;   OUTPUTS:
;               M - log-likelihood
;
;   COMMON VARIABLES:
;     max_lklh
;          psd_ml - PSD for the maximum likelihood model fit
;           ff_ml - frequency vector for the maximum likelihood model fit
;        alpha_ml - half degree of freedom of the PSD at each frequency
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
function spd_mtm_wht_lglk, wht_par
  
  common max_lklh
  
  aj = alpha_ml
  Sj = psd_ml
  nf = n_elements(ff_ml)
  Bj =  make_array(nf, 1, /double, value=wht_par)
  
  ; 2K degree of freedom
  Mj1 = (aj*Sj)/Bj + double(alog(gamma(aj) * Sj))
  Mj2 = aj * double( alog(Bj/(aj*Sj)) )
  M = 2.0d * total( Mj1 + Mj2 , /nan) 
  
  return, M

end