;+
; :Description:
;   Kolmogorov-Smirnov test.
; 
; :Params:
;   INPUTS:
;           Sj - Power Spectral Density
;   
;   OUTPUTS:
;           KS - distance between the estimated and theoretical
;                cumulative distribution function of gamma_j   
;
;   COMMON VARIABLES:
;     max_lklh
;       psd_ml - PSD for the maximum likelihood model fit
;          
; :Uses:
;     spd_mtm_gammaj_cdf.pro
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
function spd_mtm_ks, Sj
  
  common max_lklh
  
  n_psd = n_elements(psd_ml)
  sizeSj = size(Sj)
  if sizeSj[0] eq 2 then begin
    ; 
    ; number of Sj to be probed
    n_Sj = sizeSj[2]
    ; replicate psd_ml accordingly
    reb_psd = rebin(psd_ml, [n_psd, n_Sj])
    ;
  endif else begin
    reb_psd = psd_ml
    n_Sj = 1
  endelse
  
  ; define the ratio gammaj
  gamj = reform(reb_psd / reform(Sj))
  ;
  ; sort gamj for each Sj
  for k = 0, n_Sj - 1 do begin
    gamj[*,k] = gamj[ sort(gamj[*,k]) ,k]
  endfor
  ;
  ; check that gamj has not equal values
  bin = total(abs(gamj[1:-1,*] - gamj[0:-2,*]), 1)
  good_bin = where(bin ne 0, ngood)
  ;
  KS = make_array(n_Sj,1, /double, value=1.0d)
  
  gamj_cdf_low = rebin(dindgen(n_psd) / n_psd, [n_psd,ngood])
  gamj_cdf_upp = rebin((dindgen(n_psd) + 1.0d) / n_psd, [n_psd,ngood])
  
  ; reform gamj to an array with a single dimension
  gamj_bin = reform(gamj[*,good_bin], [n_psd*(ngood)])
  gamj_cdf_thry = spd_mtm_gammaj_cdf(gamj_bin)
  ; reform the CDF to the original gamj size
  gamj_cdf_thry = reform(gamj_cdf_thry, [n_psd,(ngood)])
  
  ; evaluate max and min along the Sj dimension
  KS_low = max( abs(gamj_cdf_low - gamj_cdf_thry), dim=1, /nan)
  KS_upp = max( abs(gamj_cdf_upp - gamj_cdf_thry), dim=1, /nan)
  KS[good_bin] = max( [[KS_low], [KS_upp]], dim=2, /nan)

  return, KS

end