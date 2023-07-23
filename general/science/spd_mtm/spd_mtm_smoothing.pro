;+
; :Description:
;   Evaluate the smoothed PSD according to four different approach:
;   'med'(1) running median
;   'mlog'(2) running median (constant window on log(f) )
;   'bin'(3) binned PSD
;   'but'(4) low pass filtered PSD (Butterworth filter)
;
; :Params:
;   INPUTS:
;         spec.ff - Fourier frequencies
;        spec.raw - adaptive multitaper PSD
;        spec.dof - degree of freedom at each Fourier frequency
;        par.fbeg - beginning frequency of the interval under analysis
;        par.fend - ending frequency of the interval under analysis
;        par.Ktpr - number of tapers (max value is 2*NW - 1)
;     par.psmooth - value imposed in spd_mtm
;       par.nfreq - number of frequencies
;   ipar.specproc - array[#smth,#modl] smoothing and model combinations
;                   1 (0) the smoothing + model combination is (not) probed
;   
;   OUTPUTS:
;       spec.smth - smoothed PSD, spec.smth[#smth, *]:
;                   #smth = 0->'raw'; 1->'med'; 2->'mlog', 3->'bin'; 4->'but'
;       spec.fbin - binned frequencies for the bin-smoothed PSD
;    spec.psmooth - percentage of the frequency range defining
;                   the smoothing window spec.psmooth[#smth]
; 
;   COMMON VARIABLES:
;     max_lklh
;          psd_ml - PSD for the maximum likelihood model fit
;           ff_ml - frequency vector for the maximum likelihood model fit
;        alpha_ml - half degree of freedom of the PSD at each frequency
;             fny - Nyquist frequency
;            itmp - indices of the frequency interval of interest
;          n_itmp - number of frequencies in the interval of interest
;     gammaj
;        alpha_gj - half degree of freedom of the PSD at each frequency
;            Ktpr - number of tapers (max value is 2*NW - 1)
; 
; :Uses:
;     spd_mtm_med_ks.pro
;     spd_mtm_med.pro
;     spd_mtm_mlog_ks.pro
;     spd_mtm_mlog.pro
;     spd_mtm_bin_ks.pro
;     spd_mtm_bin.pro
;     spd_mtm_but_ks.pro
;     spd_mtm_but.pro
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
pro spd_mtm_smoothing, spec=spec, par=par, ipar=ipar
;
common max_lklh, psd_ml, ff_ml, alpha_ml, itmp, n_itmp
common gammaj, alpha_gj, Ktpr, pp, gamj_cdf_xx, xx
;
; select the frequency interval of interest
itmp = where( (spec.ff ge par.fbeg) and (spec.ff le par.fend) )
n_itmp = n_elements(itmp)
specsm = spec.raw[itmp]
;
; variables need to be defined for common gammaj
alpha_gj = spec.dof/2.d
Ktpr = par.Ktpr
; pp = []           defined in ???
; gamj_cdf_xx = []  defined in spd_mtm_gammaj_cdf.pro
; xx = []           defined in spd_mtm_gammaj_cdf.pro
;
; RAW
spec.smth[0,itmp] = specsm
;
; define common variable for max_lklh
psd_ml= spec.raw[itmp]
ff_ml = spec.ff[itmp]
alpha_ml = spec.dof[itmp]/2.0d
;
; RUNNING MEDIAN
if total(ipar.specproc[1,*]) gt 0 then begin
  ;
  ; adaptive smoothing
  if par.psmooth eq 2 then begin
    ; find the optimal value for psmooth
    ; starting index has to be odd
    smstart = 4.0*par.NW
    if not smstart mod 2 then smstart++
    med_par = [smstart/par.nfreq:0.50:2.0/par.nfreq]
    ;
    medKS = spd_mtm_med_ks(med_par)
    ; find local minima
    d_medKS = medKS[1:-1] - medKS[0:-2]
    di = float(d_medKS gt 0)
    d_di = di[1:-1] - di[0:-2]
    loc_min = where(d_di eq 1, n_loc_min) + 1
    if n_loc_min gt 0 then begin
      min_med_KS = min(medKS[loc_min], iloc, /nan)
      med_par0 = med_par[loc_min[iloc]]
    endif else begin
      print, 'Fixed med-psmooth.'
      wsmooth = round(par.nfreq*0.20) ; number of points
      if not (wsmooth mod 2.0d) then wsmooth = wsmooth+1.0
      med_par0 = wsmooth/par.nfreq
    endelse
    ;
    spec.psmooth[0] = med_par0
    wsmooth = round(par.nfreq*med_par0) ; number of points
    if not (wsmooth mod 2.0d) then wsmooth = wsmooth+1.0
    spec.smth[1,itmp] = spd_mtm_med(specsm, wsmooth)
  endif else begin
    ;
    ; user fixed window
    spec.psmooth[0] = par.psmooth
    wsmooth = round(par.nfreq*par.psmooth)
    if not (wsmooth mod 2.0d) then wsmooth = wsmooth+1.0
    spec.smth[1,itmp] = spd_mtm_med(specsm, wsmooth)
  endelse
endif
;
; RUNNING MEDIAN WITH UNIFORM WINDOW IN LOG-FREQUENCY SPACE
if total(ipar.specproc[2,*]) gt 0 then begin
  ;
  ; adaptive smoothing
  if par.psmooth eq 2 then begin
    ; find the optimal value for psmooth
    smstart = 4.0*par.NW/par.nfreq
    mlog_par = [smstart:0.50d:(0.50d - smstart)/100.d]
    ;
    mlogKS = spd_mtm_mlog_ks(mlog_par)
    min_logKS = min(mlogKS, imlog, /nan)
    ;
    spec.psmooth[1] = mlog_par[imlog]
    spec.smth[2,itmp] = spd_mtm_mlog(specsm, ff_ml, mlog_par[imlog])
  endif else begin
    ;
    ; user fixed window
    spec.psmooth[1] = par.psmooth
    spec.smth[2,itmp] = spd_mtm_mlog(specsm, ff_ml, par.psmooth)
  endelse
endif
;
; BINNED
if total(ipar.specproc[3,*]) gt 0 then begin
  ;
  ; adaptive smoothing
  if par.psmooth eq 2 then begin
    ; find the optimal value for psmooth
    ; starting index has to be odd
    smstart = 4.0*par.NW
    if not smstart mod 2 then smstart++
    bin_par = [smstart/par.nfreq:0.50:2.0/par.nfreq]
    ;
    binKS = spd_mtm_bin_ks(bin_par)
    ; find local minima
    d_binKS = binKS[1:-1] - binKS[0:-2]
    di = float(d_binKS gt 0)
    d_di = di[1:-1] - di[0:-2]
    loc_min = where(d_di eq 1, n_loc_min) + 1
    if n_loc_min gt 0 then begin
      min_bin_KS = min(binKS[loc_min], iloc, /nan)
      bin_par0 = bin_par[loc_min[iloc]]
    endif else begin
      print, 'Fixed bin-psmooth.'
      wsmooth = round(par.nfreq*0.20) ; number of points
      if not (wsmooth mod 2.0d) then wsmooth = wsmooth+1.0
      bin_par0 = wsmooth/par.nfreq
    endelse
    ;
    spec.psmooth[2] = bin_par0
    wsmooth = round(par.nfreq*bin_par0) ; number of points
    if not (wsmooth mod 2.0d) then wsmooth = wsmooth+1.0
    spec.smth[3,itmp] = spd_mtm_bin(specsm, ff_ml, wsmooth, fbin=fbin)
    spec.fbin[itmp] = fbin
  endif else begin
    ;
    ; user fixed window
    spec.psmooth[2] = par.psmooth
    wsmooth = round(par.nfreq*par.psmooth)
    if not (wsmooth mod 2.0d) then wsmooth = wsmooth+1.0
    spec.smth[3,itmp] = spd_mtm_bin(specsm, ff_ml, wsmooth, fbin=fbin)
    spec.fbin[itmp] = fbin
  endelse
endif
;
; BUTTERWORTH
if total(ipar.specproc[4,*]) gt 0 then begin
  ;
  ; adaptive smoothing
  if par.psmooth eq 2 then begin
    ; find the optimal value for psmooth
    ; n cutoff
    nbut = [1.0/par.nfreq:0.15:1.0/par.nfreq]
    nbp = n_elements(nbut)
    nbut_par = nbut
    ; order
    obut_par = fltarr(nbp,1) + 8.0
    ; parameter for the butterworth filter
    but_par = [[nbut_par],[obut_par]]
    ;
    butKS = spd_mtm_but_ks(but_par)
    ; find local minima
    d_butKS = butKS[2:-1] - butKS[0:-3]
    di = float(d_butKS gt 0)
    d_di = di[1:-1] - di[0:-2]
    loc_min = where(d_di eq 1, n_loc_min) + 2
    if n_loc_min gt 0 then begin
      if n_loc_min gt 1 then loc_min = loc_min[1:-1]
      ; the first minimum tend to be spurious
      min_but_KS = min(butKS[loc_min], iloc, /nan)
      but_par0 = but_par[*,loc_min[iloc]]
    endif else begin
      print, 'Fixed but'
      wsmooth = round(par.nfreq*0.02) ; number of points
      if not (wsmooth mod 2.0d) then wsmooth = wsmooth+1.0
      but_par0 = [wsmooth/par.nfreq, 8.d]
    endelse
    ;
    spec.psmooth[3:4] = but_par0
    wsmooth = round(par.nfreq*spec.psmooth[3]) ; number of points
    if not (wsmooth mod 2.0d) then wsmooth = wsmooth+1.0
    spec.smth[4,itmp] = spd_mtm_but(specsm, wsmooth, spec.psmooth[4])
  endif else begin
    ;
    ; user fixed window
    spec.psmooth[3] = par.psmooth ; 0.5*(1.d - par.psmooth)
    spec.psmooth[4] = 8.d
    wsmooth = round(par.nfreq*spec.psmooth[3])
    if not (wsmooth mod 2.0d) then wsmooth = wsmooth+1.0
    spec.smth[4,itmp] = spd_mtm_but(specsm, wsmooth, 8.d)
  endelse
endif
;
end