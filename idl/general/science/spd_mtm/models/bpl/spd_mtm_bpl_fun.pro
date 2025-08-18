;+
; :Description:
;   Bending Power Law (BPL) function values at the given frequencies
;   with the bpl_par parameters.
;
; :Params:
;   INPUTS:
;           f - frequency vector
;     bpl_par - bending power law parameters:
;               bpl_par[0] --> c, constant factor
;               bpl_par[1] --> beta, spectral index
;               bpl_par[2] --> gamma, spectral index
;               bpl_par[3] --> fb, frequency break
;   OUTPUTS:
;      bplfun - bending power law function
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
function spd_mtm_bpl_fun, f, bpl_par
    
  N = double(bpl_par[0])
  bet = double(bpl_par[1])
  gam = double(bpl_par[2])
  fb = double(bpl_par[3])
  f = double(f)
  
  ; In the range of the parameter defined in spd_mtm_spec this function
  ; diverge always at +Inf for f=0. This might change if the
  ; range of the parameters change.
  bplfun = make_array(n_elements(f),1,/double, value=0.0)
  not0 = where(f ne 0.0d, nf, complement=is0)
  bplfun[is0] = !values.d_nan
  ff = f[not0]
  
  fjfb = (gam - bet) * (alog10(ff) - alog10(fb))
  logq = alog10(1.0d + 10.0d^fjfb)
  logfun = alog10(N) - bet*alog10(ff) - logq
  ind_ovrflw = where(logfun gt 30, n_ovrflw)
  ind_undflw = where(logfun lt -30, n_undflw)
  if n_ovrflw gt 0 then logfun[ind_ovrflw] = 30.0
  if n_undflw gt 0 then logfun[ind_undflw] = -30.0
  bplfun[not0] = 10.0d^logfun
  
  return, bplfun
  
end