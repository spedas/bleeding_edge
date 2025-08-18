;+
; :Description:
;   Return the cumulative distribution funtion (CDF) value at a given point
;   for the distribution of the random variable gamma.
;
; :Params:
;   INPUTS:
;              x - gamma values
;   
;   OUTPUTS:
;       gamj_cdf - CDF at the x values
;   
;   COMMON VARIABLES:
;     gammaj
;       alpha_gj - half degree of freedom of the PSD at each frequency
;           Ktpr - number of tapers (max value is 2*NW - 1)
;    gamj_cdf_xx - CDF at fixed gamma values
;             xx - fixed gamma values (cover up to Ktpr=20)
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
function spd_mtm_gammaj_cdf, x

common gammaj

if gamj_cdf_xx eq !null then begin
  ;
  ; d(dof) step to estimate the probability distribution function
  bnsz = 0.2d
  ;
  ; The correction on the max value take in account the oscillations of alpha
  p_alpha0 = histogram( alpha_gj, locations=alpha_bin, binsize=bnsz, $
                        min=0.0d , max=Ktpr)
  ;
  ; simple histogram
  ; this correspond to p(alpha)*d(alpha)
  p_alpha = double(p_alpha0) / n_elements(alpha_gj)
  ; the use of more sophisticated method for the estimation of p_alpha
  ; (like the nearest neighbour or the kernel methods [Silverman, 1986])
  ; determines a difference in the confidence levels lower than the 1.0%.
  
  ; xx value between 0 and 55 cover up to Ktpr=20
  xx = [0.d:55.d:0.001d]
  if Ktpr gt 20.0 then print, $
   'Extend xx range of the Gamma_j Cumulative Distribution Function'
  n_xx = n_elements(xx)
  n_a = n_elements(alpha_bin)
  ;
  ; allocate array
  yy = make_array(n_a, n_xx, /double, value=0)
  ;
  for k = 0, n_a-1 do begin
    ax = alpha_bin[k]*xx
    yy[k,*] = igamma(alpha_bin[k],ax, /double)
  endfor
  ;
  rep_palpha = rebin(p_alpha, [n_a, n_xx])
  ;
  yy = yy * rep_palpha
  y_trap =  ( yy[0:n_a-2,*] + yy[1:n_a-1,*] ) / 2.0d
  gamj_cdf_xx = total(y_trap,1)
  ;
 endif
 ;
 ; allocate array
 n_x = n_elements(x)
 gamj_cdf = make_array(n_x,1, /double, value=!values.d_nan)
 ;
 ; value greater than 55 are 1
 ind_int = where(x lt 55, complement=ind_1, /null)
 gamj_cdf[ind_1] = 1.0d
 ;
 ; interpolate using gamj_cdf_fit defined over the xx values
 if ind_int ne !null then begin
   gamj_cdf[ind_int] = interpol(gamj_cdf_xx, xx, x[ind_int])
 endif

 return, gamj_cdf

end