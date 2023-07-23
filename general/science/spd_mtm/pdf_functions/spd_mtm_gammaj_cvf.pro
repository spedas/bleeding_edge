;+
; :Description:
;   Return the cutting value at a given confidence threshold pp
;   for the distribution of the random variable gamma.
;
; :Params:
;   INPUTS:
;               x - gamma values
;
;   COMMON VARIABLES:
;     gammaj
;        alpha_gj - half degree of freedom of the PSD at each frequency
;            Ktpr - number of tapers (max value is 2*NW - 1)
;              pp - confidence threshold percentage
;     gamj_cdf_xx - CDF at fixed gamma values
;              xx - fixed gamma values (cover up to Ktpr=20)
;       
; :Uses:
;     spd_mtm_gammaj_cdf.pro
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
function spd_mtm_gammaj_cvf, x
 
 common gammaj

 return, spd_mtm_gammaj_cdf(x) - pp

end