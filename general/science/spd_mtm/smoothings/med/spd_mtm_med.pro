;+
; :Description:
;   Evaluate the running median of the PSD.
; 
; :Params:
;   INPUTS:
;        PSD - Power Spectral Density
;        win - running window number of points
;        
;   OUTPUTS:
;     medPSD - med-smoothed PSD
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
function spd_mtm_med, PSD, win
  
  ; allocate memory
  nPSD = n_elements(PSD)
  n_win = n_elements(win)
  medPSD = make_array(nPSD,n_win, /double, value=!values.d_nan)
  halfwin = (win-1.0)/2.0
  imd = [[halfwin], [(-halfwin-1)]] ; index to assign values to medPSD
  ;
  ; perform running median for each window
  for k = 0, n_win -1 do begin
    ;
    if halfwin[k] gt 1 then begin
      ;
      ; extend PSD with NaN
      ; at the beginning and end
      ; to allow the running median
      nan_arr = make_array(halfwin[k], 1, value=!values.d_nan)
      ext_PSD = [nan_arr, PSD, nan_arr]
      ;
      mPSD = median(ext_PSD, win[k])
      medPSD[*,k] = mPSD[imd[k,0]:imd[k,1]]
      ;
    endif else medPSD[*,k] = PSD
    ;
  endfor
  
  return, medPSD
  
end