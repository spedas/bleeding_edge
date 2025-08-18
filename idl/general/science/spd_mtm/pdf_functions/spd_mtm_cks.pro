;+
; :Description:
;   Kolmogorov-Smirnov significance.
; 
; :Params:
;   INPUTS:
;     psd - power spectral density
;   
;   OUTPUTS:
;     CKS - confidence level
;          
; :Uses:
;     spd_mtm_ks.pro
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
function spd_mtm_cks, psd
  
  DKS = spd_mtm_ks(psd)
  
  ; define even and odd steps to avoid the term (-1)^(j - 1)
  j = dindgen(1001)
  jodd = j[1:-1:2]
  jeve = j[2:-1:2]
  
  ; define lambda
  n_psd = n_elements(psd)
  lam = sqrt(n_psd) * DKS
  
  ; evaluate exponent term
  expodd = -2.0d * (jodd^2.0d) * (lam^2.0d)
  expeve = -2.0d * (jeve^2.0d) * (lam^2.0d)
  
  ; limit term of the sum exp(-30)
  iodd = where(expodd gt -30, nodd)
  if nodd gt 0 then QKSjodd = exp(expodd[iodd]) else QKSjodd = 0.0d
  ieve = where(expeve gt -30, neve)
  if neve gt 0 then QKSjeve = exp(expeve[ieve]) else QKSjeve = 0.0d
  
  totQKSj = total(QKSjodd) - total(QKSjeve)
  CKS = 1.0d - 2.0d*totQKSj
  
  return, CKS

end