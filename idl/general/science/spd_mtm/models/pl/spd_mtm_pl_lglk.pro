;+
; :Description:
;   Evaluate the log-likelihood of
;   the power law (PL) PSD model.
; 
; :Params:
;   INPUTS:
;          pl_par - power law PSD parameters:
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
; :Uses:
;     spd_mtm_pl_norm.pro
;     spd_mtm_pl_fun.pro
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
function spd_mtm_pl_lglk, pl_par

  common max_lklh
  
  if n_elements(pl_par) eq 1 then begin
    c = spd_mtm_pl_norm(pl_par, ff_ml, psd_ml, alpha_ml)
    pl_par0 = [c, pl_par]
  endif else pl_par0 = pl_par
  
  aj = alpha_ml
  Sj = psd_ml
  Bj = spd_mtm_pl_fun(ff_ml, pl_par0)
  
  ; 2K degree of freedom
  Mj1 = (aj*Sj)/Bj + double(alog(gamma(aj) * Sj))
  Mj2 = aj * double( alog(Bj/(aj*Sj)) )
  M = 2.0d * total( Mj1 + Mj2 , /nan) 
  
  return, M

end