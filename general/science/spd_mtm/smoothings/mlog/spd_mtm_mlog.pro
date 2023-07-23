;+
; :Description:
;   Evaluate the running median of the PSD
;   with a uniform moving window in the log-frequency space.
; 
; :Params:
;   INPUTS:
;            PSD - Power Spectral Density
;             ff - frequency vector
;        psmooth - percentage of the frequency range defining
;                  the smoothing window
;   OUTPUTS:
;        mlogPSD - mlog-smoothed PSD
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
function spd_mtm_mlog, PSD, ff, psmooth
  
  nPSD = n_elements(PSD)
  nsmo = n_elements(psmooth)
  mlogPSD = make_array(nPSD, nsmo, /double, value=!values.f_NaN)
  
  ; set the first frequency point to Inf if zero
  if ff[0] eq 0.d then begin
    logf = [-!values.D_INFINITY, double(alog10(ff[1:nPSD-1]))]
    ibeg=1 
  endif else begin
    logf = double(alog10(ff))
    ibeg=0
  endelse
    
  logfrange = logf[nPSD-1] - logf[ibeg]
  
  for k = 0, nsmo - 1 do begin
    ;
    ; define log window
    logfsmooth = psmooth[k] * logfrange
    ;
    for j = ibeg, nPSD - 1 do begin

      logf1 = logf[j] - logfsmooth/ 2.d
      logf2 = logf[j] + logfsmooth/ 2.d

      ind = where( (logf ge logf1[0]) and (logf le logf2[0]) ,/null)

      mlogPSD[j,k] = median(PSD[ind])

    endfor
    ;
  endfor
    
  return, mlogPSD

end