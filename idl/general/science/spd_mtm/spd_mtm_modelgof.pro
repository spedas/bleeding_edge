;+
; :Description:
;   Determine the best PSD background model according to a 
;   statistical criterium among the MERIT, AIC, and C_KS
;   when comparing multiple smoothing+model pairs.
;
; :Params:
;   INPUTS:
;         spec.ff - Fourier frequencies
;        spec.raw - adaptive multitaper PSD
;        spec.dof - degree of freedom at each Fourier frequency
;       spec.modl - PSD background models, spec.modl[#smth, #modl, *]:
;                   #modl = 0->'wht'; 1->'pl'; 2->'ar1'; 3->'bpl'
;       spec.frpr - model parameters resulting from the fitting procedures
;                   spec.frpr[#smth, #modl, #par]:
;                   #par = 0->'c'; 1->'rho' or 'beta'; 2->'gamma'; 3->'fb'
;   ipar.specproc - array[#smth,#modl] smoothing and model combinations
;                   1 (0) the smoothing + model combination is (not) probed
;        ipar.gof - criterium used to select the PSD background
;       
;   OUTPUTS:
;        spec.CKS - C_KS value for each probed model
;        spec.AIC - AIC value for each probed model
;      spec.MERIT - MERIT value for each probed model
;    spec.indback - indices of the selected PSD background;
;                   smoothing/model = spec.indback[0]/[1]
;       spec.back - best PSD background among the probed model
; 
;   COMMON VARIABLES:
;     max_lklh
;          psd_ml - PSD for the maximum likelihood model fit
;           ff_ml - frequency vector for the maximum likelihood model fit
;        alpha_ml - half degree of freedom of the PSD at each frequency
;            itmp - indices of the frequency interval of interest
;          n_itmp - number of frequencies in the interval of interest    
;
; :Uses:
;     spd_mtm_cks.pro
;     spd_mtm_wht_lglk.pro
;     spd_mtm_pl_lglk.pro
;     spd_mtm_ar1_lglk.pro
;     spd_mtm_bpl_lglk.pro
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
pro spd_mtm_modelgof, spec=spec, ipar=ipar
;
common max_lklh
;
; determine the best model according to the selected criterium,
; only in the case of multiple selection of smoothings and/or models,
; and set it as the background
;
if total(ipar.specproc) gt 1 then begin
  ;
  ; number of smoothings and models
  szpr = size(ipar.specproc,/dimension)
  nsmth = szpr[0]
  nmodl = szpr[1]
  ;
  ff_ml = spec.ff[itmp]
  psd_ml = spec.raw[itmp]
  alpha_ml = spec.dof[itmp]/2.0d
  ;
  ; initialize MERIT, merit value related to the sum of square errors
  MERIT = make_array(nsmth,nmodl, /double, value=!values.f_NaN)
  ;
  ; initialize CKS, Kolmogorov-Smirnov confidence
  CKS = make_array(nsmth,nmodl, /double, value=!values.f_NaN)
  ;
  ; initialize AIC, Akaine Information Criteria
  ; comparing not-nested models
  AIC = make_array(nsmth,nmodl, /double, value=!values.f_NaN)
  ;
  ; number of free parameters for each model
  nfrpr = [0,1,1,3]
  ;
  ; models free parameter
  wht_frpr = spec.frpr[*,0,0]
  pl_frpr = reform(spec.frpr[*,1,0:1])
  ar1_frpr = reform(spec.frpr[*,2,0:1])
  bpl_frpr = reform(spec.frpr[*,3,0:3])
  ;
  ; choosing criteria
  for k = 0, nsmth -1 do begin
    for h = 0, nmodl -1 do begin
      if (ipar.specproc[k,h] eq 1) and (spec.modl[k,h,0] ne -1.0d) then begin
        ;
        ; MERIT
        dspectmp = psd_ml - spec.modl[k,h,itmp]
        MERITratio_sq = (dspectmp/psd_ml)^2.0d
        MERITdof = n_itmp - nfrpr[h] - n_elements(ind)
        MERIT[k,h] = total( 0.5d*spec.dof[itmp]*(dspectmp/spec.modl[k,h,itmp])^2.0d , /nan) / MERITdof
        ;
        ; Kolmogorov-Smirnov
        CKS[k,h] = spd_mtm_cks(spec.modl[k,h,itmp])
        ;
        ; AIC
        case h of
          0: if wht_frpr[k] ne 0 then AIC[k,h] = spd_mtm_wht_lglk(wht_frpr[k]) + 2.0d*nfrpr[h]
          1: if pl_frpr[k,0] ne 0 then AIC[k,h] = spd_mtm_pl_lglk(pl_frpr[k,*]) + 2.0d*nfrpr[h]
          2: if ar1_frpr[k,0] ne 0 then AIC[k,h] = spd_mtm_ar1_lglk(ar1_frpr[k,*]) + 2.0d*nfrpr[h]
          3: if bpl_frpr[k,0] ne 0 then AIC[k,h] = spd_mtm_bpl_lglk(bpl_frpr[k,*]) + 2.0d*nfrpr[h]
        endcase
      endif
    endfor
  endfor
  ;
  spec.MERIT = MERIT
  spec.CKS = CKS
  spec.AIC = AIC
  ;
  ; define criterium to use
  void = execute('score = ' + ipar.gof)
  locback = where(score eq min(score,/nan))
  ;
  ; select the best background according to the score
  indback = array_indices(score, locback[0])
  spec.indback = indback
  
endif else begin
  ; only one combination of smoothing and model is available
  score = ipar.specproc
  locback = where(score eq 1)
  indback = array_indices(score, locback)
  spec.indback = indback
endelse
;
spec.back = spec.modl[indback[0],indback[1],*]
;
end