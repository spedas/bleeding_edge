;+
; :Description:
;   Reshaping of the power spectral density as described in:
;   Thomson, D. J. (1982). "Spectrum estimation and harmonic analysis."
;   Proceedings of the IEEE,70(9), 1055-1096. doi:10.1109/PROC.1982.12433
; 
; :Params:
;   INPUTS:
;        spec - structure with results of the spectral analysis
;               (as defined in spd_mtm.pro)
;         par - properties of the time series and parameters defining
;               the spectral analysis (as defined in spd_mtm.pro)
;        ipar - indeces define the procedures for the identification
;               of PSD background and signals (as defined in spd_mtm.pro)
;        peak - identified signals (as defined in spd_mtm.pro)
;      demean - time series with average value removed
;   
;   OUTPUTS:
;     rshspec - provide the spec structures based on the reshaped PSD
;     rshpeak - provide the peak structures based on the reshaped PSD
; 
; :Uses:
;     spd_mtm_findpeaks.pro
;     spd_mtm_adapt.pro
;     spd_mtm_smoothing.pro
;     spd_mtm_fitmodel.pro
;     spd_mtm_modelgof.pro
;     spd_mtm_confthr.pro
;     
; :File_comments:
;   We perform the PSD reshaping removing the contribute of the identified
;   monochromatic signals from the PSD along the entire frequency range.
;   The code for the local reshaping of the PSD, that is in a frequency
;   interval with the same width of the spectral window main lobe,
;   is provided as comment lines. 
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
pro spd_mtm_reshape, spec=spec, par=par, ipar=ipar, peak=peak, $
                     demean=demean, rshspec=rshspec, rshpeak=rshpeak

; define new structures for the reshaping results
rshspec = spec
reshipar = ipar
reshpar = par

; reshape peaks identified only according to
; the gamma+F test procedure at the given confidence level
reshipar.peakproc = [0,0,1,0]
reshpar.conf = ipar.resh
spd_mtm_findpeaks, spec=rshspec, par=reshpar, ipar=reshipar, peak=rshpeak0
;
; select peaks to be reshaped
index_pks = where(rshpeak0.pkdf[2,-1,*] gt 0, n_resh)

if n_resh gt 0 then begin
  ;
  ; evaluate the discrete prolate spheroidal functions U_k(f)
  ; (Fourier transform of the dpss)
  ; take in account the eventual zero-padding
  ipts = [0:par.npts-1]
  tprs = make_array(par.Ktpr, par.npad, /double, value=0.0d)
  tprs[*,ipts] = par.tprs
  ; additional factor needed for dpsf normalization
  Ukf = double(par.npad)*fft(tprs, -1, dimension=2, /double)
  ;
  ; reshape all the peaks found
  for k = 0, n_resh-1 do begin
    ;
    ipks = index_pks[k]
    ;    
    ; Perform global reshaping.
    ; reshape all the spectrum
    shiftU = ipks
    nband = par.nfreq
    irsh = [0: nband - 1.0]
    ;
;    ; Perform local reshaping.
;    ; half bandwidth of the main lobe of the spectral window
;    ; expressed in number of frequency points
;    nhlfbnd = floor(par.NW*par.fray/par.df)
;    nband = 2.0*nhlfbnd + 1.0
;    shiftU = nhlfbnd
;    irsh = [ipks-nhlfbnd:ipks+nhlfbnd]
    ;
    ; shift to match ipks
    Ukff0 = shift(Ukf, [0, shiftU])
    ;
    ; reduce Ukff0 and yk to the frequency interval of interest
    redUkff0 = Ukff0[*,0:(nband-1)]
    redRyk = rshspec.Ryk[*,irsh]
    redIyk = rshspec.Iyk[*,irsh]
    ;
    ; consider mu(f) at pks
    muf = rshspec.muf[ipks]
    ;
    ; remove from the real and imaginary part of the psd
    ; the contribute of mu(f0):
    ; [y_k(f) - mu(f0)*U_k(f-f0)]
    rshspec.Ryk[*,irsh] = redRyk - real_part(muf*redUkff0)
    rshspec.Iyk[*,irsh] = redIyk - imaginary(muf*redUkff0)
    ;
    ; estimate of signal contribute to the total variance: |mu(f)|^2/2.0
    varmu = ( abs(muf)^2.0d )/2.0d
    ;
    ; remove the contribute of the signal to the total variance
    par.datavar = par.datavar - varmu
    ;
  endfor
  ;
endif

; calculate the reshaped adaptively weighted spectrum
spd_mtm_adapt, spec=rshspec, par=par, ipar=ipar
; rshspec.raw is the reshaped spectrum at this point
rshspec.resh = rshspec.raw
reshpar.conf = par.conf
spec.resh = rshspec.raw
;
; smoothing of the reshaped power spectral density
spd_mtm_smoothing, spec=rshspec, par=par, ipar=ipar
;
; fit power spectral density models
spd_mtm_fitmodel, spec=rshspec, par=par, ipar=ipar, demean=demean
;
; evaluate goodness of fit for multiple background models
spd_mtm_modelgof, spec=rshspec, ipar=ipar
;
; define confidence level for the power spectral density
; and the harmonic F test
spd_mtm_confthr, spec=rshspec, par=par
;
; find periodic signals with respect the original psd
rshspec.raw = spec.raw
;
; assign the original peak procedures
spd_mtm_findpeaks, spec=rshspec, par=par, ipar=ipar, peak=rshpeak
;
end