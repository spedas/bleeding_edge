;+
; :Description:
;   Kolmogorov-Smirnov test for the smoothing procedure:
;   running median.
; 
; :Params:
;   INPUTS:
;     smo_par - percentages of the frequency range
;               defining the smoothing window
;   OUTPUTS:
;          KS - distance between the estimated and theoretical
;               cumulative distribution function of gamma_j
; 
;   COMMON VARIABLES:
;   max_lklh
;      psd_ml - PSD for the maximum likelihood model fit
;       ff_ml - frequency vector for the maximum likelihood model fit
;         
; :Uses:
;     spd_mtm_med.pro
;     spd_mtm_ks.pro
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
function spd_mtm_med_ks, smo_par
  
  common max_lklh
  
  ; allocate memory
  KS = 1.0d + smo_par^2.0d
  ; define df
  nfreq = n_elements(ff_ml)
  
  ; admit only 0<smo_par<0.5
  good_smo = where( (smo_par gt 0.0d) and (smo_par lt 0.5d), ngood)
  
  if ngood gt 0 then begin
    ; get number of points
    wsmooth = round(nfreq*smo_par[good_smo])
    eve_smo = where(not (wsmooth mod 2.0d), n_eve)
    if n_eve gt 0 then wsmooth[eve_smo] = wsmooth[eve_smo] + 1.0
    ;
    Sj = spd_mtm_med(psd_ml, wsmooth)
    KS[good_smo] = spd_mtm_ks(Sj)
    ;
  endif

  return, KS
  
end