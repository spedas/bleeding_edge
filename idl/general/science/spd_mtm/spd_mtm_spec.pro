;+ 
; :Description:
;   This procedure evaluates the Power Spectral Density.
; 
; :Params:
;   INPUTS:
;     data          time series
;                         
;      par.
;         .npts     time series number of points
;         .dt       average sampling time
;         .npad     time series number of points after padding
;         .nfreq    number of frequencies
;         .df       frequency resolution (after padding), it corresponds to
;                   the Rayleigh frequency for no padding (padding = 1)
;         .psmooth  value imposed in spd_mtm
;         .conf     confidence thresholds percentages
;         .Ktpr     number of tapers (max value is 2*NW - 1)
;         .tprs     discrete prolate spheroidal sequences (dpss)
;         .v        dpss eigenvalues 
;               
;     ipar.          
;         .hires    keyword /hires is selected (1) or not (0)
;         .power    keyword /power is selected (1) or not (0)
;         .specproc array[#smth,#modl] smoothing and model combinations
;                   1 (0) the smoothing + model combination is (not) probed
;               
;   OUTPUTS:
;     spec.         
;         .ff       Fourier frequencies
;         .raw      adaptive multitaper PSD
;         .dof      degree of freedom at each Fourier frequency
;         .Ryk      real part of the eigenspectra spec.Ryk[#Ktpr,*]
;         .Iyk      imaginary part of the eigenspectra spec.Iyk[#Ktpr,*]
;         .poor_MTM flag for failed convergence of the adaptive MTM PSD
;               
; :Uses:
;     spd_mtm_adapt.pro
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
pro spd_mtm_spec, data = data, par=par, ipar=ipar, spec=spec
 
 ; define the Fourier frequencies
 ff = dindgen(par.nfreq,1)*par.df
 
 ; allocate output structure
 szpr = size(ipar.specproc,/dimension); size of procedure
 nsmth = szpr[0]
 nmodl = szpr[1]
 nconf = n_elements(par.conf)
 ; N.B. The first half of Ryk and Iyk is sufficient to evaluate the PSD, but
 ;      their real length is "npad" for the two-sided spectrum.
 Ryk = make_array(par.Ktpr, par.nfreq, /double, value=0)
 Iyk = make_array(par.Ktpr, par.nfreq, /double, value=0)
 raw = make_array(par.nfreq, 1, /double, value=0)
 smth = make_array(nsmth, par.nfreq, /double, value=!values.d_nan)
 modl = make_array(nsmth, nmodl, par.nfreq, /double, value=!values.d_nan)
 frpr = make_array(nsmth, nmodl, 4, /double, value=!values.d_nan)
 conf = make_array(nconf, 1, /double, value=0)
 speccrtr = make_array(nsmth, nmodl, /double, value=0) ; spec criteria
 psmooth = double([0.d,0.d,0.d,0.d,0.d]) ; the last term is the order for the butterworth filter
 spec = {ff:ff, raw:raw, back:raw, ftest:raw, resh:raw, dof:raw, $
         fbin:ff*!values.f_nan, smth:smth, modl:modl, frpr:frpr, $
         conf:conf, fconf:conf, $
         CKS:speccrtr, AIC:speccrtr, MERIT:speccrtr, $
         Ryk:Ryk, IyK:Iyk, psmooth:psmooth, muf:complex(raw, /double), $
         indback:[0,0], poor_MTM:0}
 
 ;
 ;##########################################################################
 ;   MTM estimation of the power spectral density and the harmonic F test
 ;##########################################################################
 ;
 ipts = [0:par.npts-1]
 ifreq = [0:par.nfreq-1]
 
 ; determine zero padding if npad gt npts
 dattpr = make_array(par.npad,1,/double,value=0.0d)
 
 ; perform convolution of the series with each datataper and compute yk(f)
 for itpr = 0, par.Ktpr-1 do begin
  ;
  ; a series of zeros remains if npad gt npts
  dattpr[ipts] = transpose(data) * par.tprs[itpr, *]
  ;
  ; Fourier transform
  ; fft in IDL has a normalization factor
  ; that we have to remove for our analysis
  yk = par.npad*fft(dattpr, -1, /double)
  Ry = real_part(yk)
  Iy = imaginary(yk)
  Ryk[itpr, ifreq] = (Ry[ifreq])
  Iyk[itpr, ifreq] = (Iy[ifreq])
  ;
 endfor
 
 ;
 ; assigne values to the spec structure
 spec.Ryk = Ryk
 spec.Iyk = Iyk
 
 ;
 if ipar.hires then begin
  ;
  ; high-resolution spectrum as defined in Mann and Lees (1996)
  vK = 1.d/(par.V*par.Ktpr)
  diagv = diag_matrix(vK)
  hires = diagv # (Ryk^2 + Iyk^2)
  hires = total(hires, 1) ; two-sided spectrum
  ;
  ; define indices for the one-sided spectrum
  if par.npad mod 2 then begin ; npad is odd
    ipsd = [1:par.nfreq-1]
  endif else ipsd = [1:par.nfreq-2] ; npad is even
  ;
  ;determine if PSD or Power
  if ipar.power then nrml = par.df else nrml=1.0d
  ;
  ; determine the one-sided spectrum
  hires[ipsd] = 2.d * hires[ipsd]
  spec.raw = par.dt * hires * nrml
  dk = make_array(par.Ktpr,par.nfreq, /double, value=1)
  alphaj = total(dk*dk, 1)
  spec.dof = 2.0d * alphaj
  
 endif else begin
  ;
  ; calculate adaptively weighted spectrum (Thomson, 1982)
  spd_mtm_adapt, spec=spec, par=par, ipar=ipar
  ;
 endelse

end