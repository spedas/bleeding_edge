;+
; :Description:
;   Constant normalization factor for the BPL model estimated with
;   the maximum likelihood theoretical solution.
;
; :Params:
;   INPUTS:
;          ff - Fourier frequencies vector
;     bpl_par - bending power law parameters:
;               bpl_par[0] --> beta, spectral index
;               bpl_par[1] --> gamma, spectral index
;               bpl_par[2] --> fb, frequency break
;               
;         bet - spectral index
;          ff - Fourier frequencies vector
;         psd - power spectral density
;       alpha - half degree of freedom of Smtm for each frequency
;
;   OUTPUTS:
;           c - constant factor
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
function spd_mtm_bpl_norm, bpl_par, ff, psd, alpha
;
bet = bpl_par[0]
gam = bpl_par[1]
fb = bpl_par[2]

fjfb = (gam - bet) * (alog10(ff) - alog10(fb))
logq = alog10(1.0d + 10.0d^fjfb)
logfun = - bet*alog10(ff) - logq
ind_ovrflw = where(logfun gt 30, n_ovrflw)
ind_undflw = where(logfun lt -30, n_undflw)
if n_ovrflw gt 0 then logfun[ind_ovrflw] = 30.0
if n_undflw gt 0 then logfun[ind_undflw] = -30.0
res = 10.0d^logfun
c = total(alpha*psd/res)/total(alpha)
;
return, c
;
end