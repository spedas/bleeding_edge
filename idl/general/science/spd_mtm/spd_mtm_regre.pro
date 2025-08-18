;+
; :Description:
;   Perform the harmonic analysis (F test) according to
;   Thomson, D. J. (1982). "Spectrum estimation and harmonic analysis."
;   Proceedings of the IEEE,70(9), 1055-1096. doi:10.1109/PROC.1982.12433
; 
; :Params:
;   INPUTS:
;     spec.Ryk - real part of the eigenspectra
;     spec.Iyk - imaginary part of the eigenspectra
;     par.tprs - discrete prolate spheroidal sequences (dpss)
;     par.Ktpr - number of tapers to be used (max value is 2*NW - 1)
;    par.nfreq - number of frequencies
;
;   OUTPUTS:
;   spec.ftest - values of the F test
;     spec.muf - complex amplitude at each Fourier frequency
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
pro spd_mtm_regre, spec=spec, par=par

; perform F-test for phase coherence if indicated (i.e. Ktpr gt 1)
if par.Ktpr gt 1 then begin
  
  ; sum of each taper equivalent to Uk(0)
  ; DFT of Slepian eigentapers at zero frequency
  Uk0 = total(par.tprs, 2)
  Uk0[1:-1:2] = 0.0d ; set to zero the odd tapers
  
  ; Uk0 squared
  Uk0sq = (Uk0 * Uk0)
  
  ; Uk0 squared summation
  totUk0sq = total(Uk0sq, /double)
  
  ; replicate Uk0
  repUk0 = rebin(Uk0, [par.Ktpr,par.nfreq])
  
  ; mu(f) real and imaginary values
  Rmu = transpose(total(spec.Ryk * repUk0, 1, /double))
  Imu = transpose(total(spec.Iyk * repUk0, 1, /double))
  Rmu = Rmu/totUk0sq
  Imu = Imu/totUk0sq
  
  ; estimate of mu(f)
  muf = complex(Rmu, Imu, /double)
  ; estimate of |mu(f)|^2
  musq = Rmu^2.d + Imu^2.d
  
  rebRmu = rebin(Rmu,[1,par.nfreq,par.Ktpr])
  repRmu = transpose(reform(rebRmu,[par.nfreq,par.Ktpr]))
  rebImu = rebin(Imu,[1,par.nfreq,par.Ktpr])
  repImu = transpose(reform(rebImu,[par.nfreq,par.Ktpr]))

  sumR = spec.Ryk - repRmu * repUk0
  sumI = spec.Iyk - repImu * repUk0
  
  ; F-test numerator and denominator
  Fnum = (totUk0sq) * (double(par.Ktpr) - 1.d) * musq
  Fden = total(sumR^2.d + sumI^2.d,1, /double)
  
  Ftest =  Fnum / (transpose(Fden))
  
  ; assign values to the spec structure
  spec.ftest = Ftest
  spec.muf = muf

endif else message, 'For the Ftest, Ktpr must be greater than 1.', /continue

end