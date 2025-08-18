;+
; :Description:
;   Constant normalization factor for the PL model estimated with
;   the maximum likelihood theoretical solution.
;
; :Params:
;   INPUTS:
;       bet - spectral index
;        ff - Fourier frequencies vector
;       psd - power spectral density
;     alpha - half degree of freedom of Smtm for each frequency
;   
;   OUTPUTS:
;         c - constant factor
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
function spd_mtm_pl_norm, bet, ff, psd, alpha
;
lres = -bet[0]*alog10(ff)
res = 10.0d^lres
;
c = total(alpha*psd/res)/total(alpha)
;
return, c
;
end