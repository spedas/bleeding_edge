;+
; :Description:
;   Determine the confidence thresholds for the gamma and F test.
;
; :Params:
;   INPUTS:
;       par.conf - confidence thresholds percentages
;       par.Ktpr - number of tapers (max value is 2*NW - 1)
;     
;   OUTPUTS:
;      spec.conf - confidence threshold values for the PSD (gamma test)
;     spec.fconf - confidence threshold values for the F statistic (F test)
;
;   COMMON VARIABLE:
;        gammaj
;             pp - confidence threshold percentage    
; :Uses:
;     spd_mtm_gammaj_cvf.pro
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
pro spd_mtm_confthr, spec=spec, par=par
;
common gammaj
;
; determine the confidence level for the spectrum and F-test
nconf = n_elements(par.conf)
;
for p = 0, nconf-1 do begin
  ;
  ; pp is defined in common gammaj
  pp = par.conf[p]
  ;
  ; p_gamma confidence levels
  spec.conf[p] = broyden(1.0d, 'spd_mtm_gammaj_cvf', /double, tolx=1.0d-12, tolf=1.0d-12)
  ;
  ; evaluate F-test thresholds
  if par.Ktpr gt 1 then spec.fconf[p] = double(f_cvf((1.d - pp), 2.0d, 2.0d*par.Ktpr-2.0d))
  ;
endfor
;
end