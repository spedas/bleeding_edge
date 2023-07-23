;+
; :Description:
;   Evaluate the binned PSD.
;
; :Params:
;   INPUTS:
;        PSD - Power Spectral Density
;         ff - frequency vector
;        win - running window number of points
;        
;   OUTPUTS:
;     binPSD - bin-smoothed PSD
;       fbin - binned frequencies
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
function spd_mtm_bin, PSD, ff, win, fbin=fbin
  
  ; allocate
  nPSD = n_elements(PSD)
  nwin = n_elements(win)
  lbinPSD = make_array(nPSD, nwin, /double, value=!values.f_NaN)
  lfbin = make_array(nPSD, nwin, /double, value=!values.f_NaN)

  ; set the first frequency point to Inf if zero
  if ff[0] eq 0.d then begin
    logf = [-!values.D_INFINITY, double(alog10(ff[1:-1]))]
  endif else logf = double(alog10(ff))
  
  ; log(PSD) 
  lPSD = double(alog10(PSD))
  ;
  halfwin = (win-1.0)/2.0
  ; index to assign values to binned array
  imd = [[halfwin], [(nPSD-halfwin-1)]]
  ;
  ; perform running median for each window
  for k = 0, nwin -1 do begin
    ;
    fintr = [imd[k,0]:imd[k,1]]
    ;
    lbPSD = smooth(lPSD, win[k], /nan)
    lbinPSD[fintr,k] = lbPSD[fintr]
    ;
    lfb = smooth(logf, win[k], /nan)
    lfbin[fintr,k] = lfb[fintr]
    ;
  endfor
  
  binPSD = 10.d ^ lbinPSD
  fbin = 10.d ^ lfbin
  
  return, binPSD
  
end