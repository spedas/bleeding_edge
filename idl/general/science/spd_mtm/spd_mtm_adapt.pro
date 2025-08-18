;+
; :Description:
;   Evaluate the adaptive multitaper spectrum from
;   Thomson, D. J. (1982). "Spectrum estimation and harmonic analysis."
;   Proceedings of the IEEE,70(9), 1055-1096. doi:10.1109/PROC.1982.12433
;
; :Params:
;   INPUTS:
;        spec.Ryk - real part of the multitaper eigenspectra
;        spec.Iyk - imaginary part of the multitaper eigenspectra
;           par.V - dpss eigenvalues
;        par.Ktpr - number of tapers to be used (max value is 2*NW - 1)  
;       par.nfreq - number of frequencies
;     par.datavar - variance of the data
;      ipar.power - keyword /power in spd_mtm is selected (1) or not (0)
;
;   OUTPUTS:
;        spec.raw - adaptive MTM spectrum
;        spec.dof - degree of freedom at each Fourier frequency
;   spec.poor_MTM - flag for failed convergence
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
pro spd_mtm_adapt, spec=spec, par=par, ipar=ipar
  
  ;
  ;   set tolerance for iterative scheme exit
  tol = 3.d-4 ; from Mann and Lees (1996) fortran code
  bias = 1.d - par.V ; remember that the bias is (1-lambda)*variance
  Sk = (spec.Ryk^2.0d + spec.Iyk^2.0d)/par.datavar
  
  n_V = n_elements(par.V)
  repV = double(rebin(par.V, [n_V, par.nfreq]))
  repBias = double(rebin(bias, [n_V, par.nfreq]))
  Smtm = make_array(1, par.nfreq, VALUE = 0.0d, /double)
  indTol = make_array(1, par.nfreq, VALUE = 1.0d, /double)
  ;
  ;  first guess is the average of the two lowest-order eigenspectral estimates
  Stmp = (double(Sk[0, *] + Sk[1, *]))/2.0d
  ;
  ;  find coefficients
  for k = 1, 100 do begin
    
    ; replicate temporary spectrum
    rebStmp = rebin(Stmp,[1,par.nfreq,par.Ktpr])
    repStmp = double(transpose(reform(rebStmp,[par.nfreq,par.Ktpr])))

    ; replicate the term dk
    repdk = (sqrt(repV) *repStmp)/(repV * repStmp + repBias)
    
    ; dk squared
    dksq = repdk ^ 2.d
    
    ; dk^2*Sk product
    dkSk = (dksq)*Sk
    
    ; variable summation
    totdkSk = total(dkSk, 1)
    totdk = total(dksq, 1)
    
    totdkSk = transpose(totdkSk)
    ; new temporary spectrum
    Stmp1 = totdkSk/totdk
    
    ; evaluate the difference at each frequency
    ; respect to the previous estimate
    das = abs(Stmp1-Stmp)
    
    ; check for portions of the spectrum satisfying the tolerance level
    indi = where((das/Stmp) lt tol, n_indi)
    if n_indi gt 0 then begin
      Smtm[indi] = (Smtm[indi] + indTol[indi] * Stmp1[indi])
      indTol[indi] = 0.d
    endif
    
    if total(indTol) lt 1 then begin
      k = 101 ; exit the cycle if all the points have already converged
    endif

    Stmp = Stmp1
  endfor
  
  if total(indTol) gt 0 then begin
    message, 'The adaptive spectrum estimate does not converge. ' + $
             'Try pre-whitening, increasing adwait iterations or NW.', /continue
    poor_MTM = 1
    ind = where(indTol eq 1.d)
    ; use last values even though they do not converge
    Smtm[ind] = Stmp[ind]
  endif else poor_MTM = 0
  
  ;  calculate half degrees of freedom: alpha
  rebSmtm = rebin(Smtm,[1,par.nfreq,par.Ktpr])
  repSmtm = double(transpose(reform(rebSmtm,[par.nfreq,par.Ktpr])))
  dk = (sqrt(repV) * repSmtm)/(repV * repSmtm + repBias)
  alpha = ((total(dk^2.d, 1))^2.d)/((total(dk^4.d, 1)))
  
 if (total(alpha lt 1) gt 0) then begin
  message, 'Some MTM degrees of freedom are lower than 2.' $
           + ' Try increasing NW.', /continue
  poor_MTM = 1
 endif
  
  ; recover the correct spectrum
  Smtm = Smtm * par.datavar
  
  ; define indices for the one-sided spectrum
  if par.npad mod 2 then begin ; npad is odd
    ipsd = [1:par.nfreq-1]
  endif else ipsd = [1:par.nfreq-2] ; npad is even
  
  ;determine if PSD or Power
  if ipar.power then nrml = par.df else nrml=1.0d
  
  ; determine the one-sided spectrum
  ; doubling the correct portion of the spectrum
  Smtm[ipsd] = 2.0d * Smtm[ipsd]
  
  ; assign value to the spec structure
  spec.raw = par.dt * Smtm * nrml
  spec.dof = 2.0d * alpha
  spec.poor_MTM = poor_MTM
  
end