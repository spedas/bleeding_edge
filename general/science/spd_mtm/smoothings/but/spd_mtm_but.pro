;+
; :Description:
;   Low pass filter of the PSD with the
;   butterworth filter.
; 
; :Params:
;   INPUTS:
;         PSD - Power Spectral Density
;     ncutoff - number of the frequency cutoff [1,nfreq/2]
;      norder - order of the filter
;      
;   OUTPUTS:
;      butPSD - but-smoothed PSD
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
function spd_mtm_but, PSD, ncutoff, norder
  
  ; to account for strong variations in the PSD,
  ; we consider the log PSD.
  lPSD = double( alog10(PSD) )
  nPSD = n_elements(lPSD)
  
  ; replicate PSD to avoid problems at boundaries
  rep_lPSD = [lPSD[-1:1:-1], lPSD, lPSD[-2:0:-1]]
  
  ; define dimensions
  ncut = n_elements(ncutoff)
  nreplPSD = n_elements(rep_lPSD)
  
  ; rebin to match the number of ncut
  reb_lPSD = rebin(rep_lPSD, [nreplPSD,ncut])
  
  ; generate butterworth filter
  distarr = (dist(nreplPSD))[*,0]
  reb_distarr = double(rebin(distarr, [nreplPSD, ncut]))
  reb_ncutoff = double(transpose(rebin([ncutoff], [ncut, nreplPSD])))
  reb_norder = transpose(rebin([norder], [ncut, nreplPSD]))
  ; (n/n_cutoff)^(2order)
  nnco = dblarr(nreplPSD,ncut)
  no0 = where(reb_distarr ne 0, complement=is0)
  lreb_distarr = double(alog10(reb_distarr[no0]))
  lreb_ncutoff = double(alog10(reb_ncutoff[no0]))
  nnco[no0] = 2.0d * reb_norder[no0] * (lreb_distarr - lreb_ncutoff)
  log_butfil = -0.5d * double(alog10(1.0d + 10.0d^nnco))
  butfil = 10.0d^log_butfil
  butfil[is0] = 1.0d
  
  if ncut gt 1 then begin
    ; forward filter
    filtered_lPSD_1 = FFT( FFT(reb_lPSD, -1, dimension=1) * butfil, 1, dimension=1)
    ; backward filter
    filtered_lPSD_2 = FFT( FFT(reverse(filtered_lPSD_1), -1, dimension=1) * butfil, 1, dimension=1)
  endif else begin
    ; forward filter
    filtered_lPSD_1 = FFT( FFT(reb_lPSD, -1) * butfil, 1)
    ; backward filter
    filtered_lPSD_2 = FFT( FFT(reverse(filtered_lPSD_1), -1) * butfil, 1)
  endelse
  
  filtered_PSD = 10.d^( real_part(reverse(filtered_lPSD_2)) )
  
  ; recover central interval
  int_PSD = [ nPSD-1 : (2*nPSD - 2) ]
  butPSD = filtered_PSD[int_PSD, *]
  
  return, butPSD
  
end