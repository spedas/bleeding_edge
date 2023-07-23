;+
; :Description:
;   Evaluate the PSD background according to four different models:
;   'wht'(0) white noise, [c]
;   'pl'(1) power law, [c, beta]
;   'ar1'(2) first order autoregressive process, [c, rho]
;   'bpl'(3) bending power law, [c, beta, gamma, fb]
;
; :Params:
;   INPUTS:
;         spec.ff - Fourier frequencies
;        spec.raw - adaptive multitaper PSD
;        spec.dof - degree of freedom at each Fourier frequency
;       spec.smth - smoothed PSD, spec.smth[#smth, *]:
;                   #smth = 0->'raw'; 1->'med'; 2->'mlog', 3->'bin'; 4->'but'
;       spec.fbin - binned frequencies for the bin-smoothed PSD
;    spec.psmooth - percentage of the frequency range defining
;                   the smoothing window spec.psmooth[#smth]
;       par.nfreq - number of frequencies
;        par.npts - time series number of points
;          par.df - frequency resolution (after padding), it corresponds to
;                   the Rayleigh frequency for no padding (padding = 1)
;     par.datavar - variance of the time series
;         par.fny - Nyquist frequency: fny = 1/(2*dt)
;   ipar.specproc - array[#smth,#modl] smoothing and model combinations
;                   1 (0) the smoothing + model combination is (not) probed
;   
;   OUTPUTS:
;       spec.modl - PSD background models, spec.modl[#smth, #modl, *]:
;                   #modl = 0->'wht'; 1->'pl'; 2->'ar1'; 3->'bpl'
;       spec.frpr - model parameters resulting from the fitting procedures
;                   spec.frpr[#smth, #modl, #par]:
;                   #par = 0->'c'; 1->'rho' or 'beta'; 2->'gamma'; 3->'fb'
; 
;   COMMON VARIABLES:
;     max_lklh
;          psd_ml - PSD for the maximum likelihood model fit
;           ff_ml - frequency vector for the maximum likelihood model fit
;        alpha_ml - half degree of freedom of the PSD at each frequency
;             fny - Nyquist frequency
;            itmp - indices of the frequency interval of interest
;          n_itmp - number of frequencies in the interval of interest
;          
; :Uses:
;     spd_mtm_pl_fun.pro
;     spd_mtm_pl_lglk.pro
;     spd_mtm_pl_norm.pro
;     spd_mtm_ar1_fun.pro
;     spd_mtm_ar1_lglk.pro
;     spd_mtm_ar1_norm.pro
;     spd_mtm_bpl_fun.pro
;     spd_mtm_bpl_lglk.pro
;     spd_mtm_bpl_norm.pro
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
pro spd_mtm_fitmodel, spec=spec, par=par, ipar=ipar, demean=demean
;
common max_lklh
;
spectmp = spec.raw[itmp]
fftmp = spec.ff[itmp]
;
; minimization with CONSTRAINED_MIN
;
; lower and upper boundaries for the log-likelihood
; are zero since is the value to minimize
L_bnd = [0.0d, 0.0d]
;
; Define the stopping criteria for constrained_min
; EPSTOP = 1.0e-4 by default in IDL
epst = 1.0d-6
;
; in case constrained_min does not converge
no_fit = make_array(par.nfreq,1,/double,value=-1)
;
; define starting point and range of the model's parameters
;
; WHT: white noise
; for the white noise we have the theoretical solution
;
; PL: power law
pl_bnd = make_array(1,2, /double, value = 0)
beta0 = alog(spectmp[0]/spectmp[-1])/alog(fftmp[-1]/fftmp[0])
; free param. [  beta]
pl_par0 =     [ beta0] ; initial guess
; here define the boundaries for the beta parameter
pl_bnd[*,0] = [  0.0d] ; lower boundaries
pl_bnd[*,1] = [ 10.0d] ; upper boundaries
;
;
; AR1: first order autoregressive process
ar1_bnd = make_array(1,2, /double, value = 0)
; estimate lag 1 autocorrelation coefficient (for rho)
; Yule-Walker direct estimate for an AR(1) process
i = [1:par.npts-1]
c1 = total(demean[i-1] * demean[i])
rho0 = c1 / total(demean[i-1]^2.0d)
; free param.  [  rho]
ar1_par0 =     [ rho0] ; initial guess
; here define the boundaries for the rho parameter
ar1_bnd[*,0] = [ 0.0d] ; lower boundaries
ar1_bnd[*,1] = [ 1.0d] ; upper boundaries
;
;
; BPL: bending power law
bpl_bnd = make_array(3,2, /double, value = 0)
ifb = fix(n_itmp/2.0)
fb0 = fftmp[ifb]
bet0 = alog(spectmp[0]/spectmp[ifb-1])/alog(fftmp[ifb-1]/fftmp[0])
gam0 = alog(spectmp[ifb]/spectmp[-1])/alog(fftmp[-1]/fftmp[ifb])
; free param.  [  beta,  gamma,      fb]
bpl_par0 =     [  bet0,   gam0,     fb0] ; initial guess
; here define the boundaries for the beta, gamma, and the fb parameters
bpl_bnd[*,0] = [ -5.0d,   0.0d, 1.0d-12] ; lower boundaries
bpl_bnd[*,1] = [ 10.0d,  15.0d,    1.0d] ; upper boundaries
;
;
for k = 0, 4 do begin
  ;
  ; k = 0->raw, 1->specmed, 2->medlog, 3->binned, 4->butterworth
  ;
  ; for the maximum likelihood (defined in "common max_lklh")
  ;   psd_ml --> power spectral density
  ;    ff_ml --> frequency vector
  ; alpha_ml --> half degree of freedom
  ;
  ; for the binned spectrum the frequency vector is different
  if (k eq 3) and (total(ipar.specproc[3,*]) gt 0) then begin
    ;
    ; for the bin smoothing there are additional missing points
    ; equal to half the smoothing window
    wsmo = round(par.nfreq*spec.psmooth[2]) ; number of points
    hsmo = (wsmo - 1.0)/2.0
    itmp_bin = itmp[hsmo:-hsmo-1]
    ; bin smoothing has his fbin, we have to interpolate
    psd_tmp = spec.smth[k,itmp_bin]
    ff_tmp = spec.fbin[itmp_bin]
    min_ff_tmp = min(ff_tmp)
    max_ff_tmp = max(ff_tmp)
    intrp = where((spec.ff gt min_ff_tmp) and $
                  (spec.ff lt max_ff_tmp))
    fintrp = spec.ff[intrp]
    binintrp = interpol(psd_tmp, ff_tmp, fintrp)
    ; define common variable
    psd_ml = binintrp*par.df/par.datavar
    ff_ml = fintrp/par.fny
    alpha_ml = spec.dof[itmp_bin]/2.0d
    ;
  endif else begin
    ; define common variable
    psd_ml= spec.smth[k,itmp]*par.df/par.datavar
    alpha_ml = spec.dof[itmp]/2.0d
    ff_ml = spec.ff[itmp]/par.fny
  endelse
  
  ; we scale the spectrum and the frequency
  ; using the variance of the time series
  ; and the Nyquist frequency, so we need a scale factor
  scl = par.datavar/par.df
  
  ; ######################
  ; ## WHT: White noise ##
  ; ######################
  if ipar.specproc[k,0] eq 1 then begin
    ;
    ; theoretical solution
    wht_par = scl*total(alpha_ml*psd_ml)/total(alpha_ml)
    spec.modl[k,0,*] = make_array(par.nfreq, 1, /double, value=wht_par)
    ;
    ; save the value for next steps
    spec.frpr[k,0,0] = wht_par
    ;
  endif
  
  
  ; ###################
  ; ## PL: Power law ##
  ; ###################
  if ipar.specproc[k,1] eq 1 then begin
    ;
    ; minimization of the log-likelihood
    constrained_min, pl_par0, pl_bnd, L_bnd, 0, 'spd_mtm_pl_lglk', inform, epstop=epst
    if inform gt 1 then $
      print,'PL: inform = '+string(inform, format='(I0)')+' (constrained_min.pro). '+ $
            'Bad fit, check bounds for consistency.'
    ; recover constant factor
    c = spd_mtm_pl_norm(pl_par0, ff_ml, psd_ml, alpha_ml)
    ;
    ; check that c is greater than zero
    if (c gt 0.d) then begin
      c = scl * c * (par.fny^pl_par0)
      pl_par = [c, pl_par0]
      spec.modl[k,1,*] = spd_mtm_pl_fun(spec.ff, pl_par)
    endif else begin
      spec.modl[k,1,*]=no_fit
      pl_par = [c, pl_par0]*!values.d_nan
    endelse
    ;
    ; save the values for next steps
    spec.frpr[k,1,0:1] = pl_par
    ;
  endif
  
  
  ; ###########################################
  ; ## AR1: 1st order autoregressive process ##
  ; ###########################################
  if ipar.specproc[k,2] eq 1 then begin
    ;
    ; minimization of the log-likelihood
    constrained_min, ar1_par0, ar1_bnd, L_bnd, 0, 'spd_mtm_ar1_lglk', inform, epstop=epst
    if inform gt 1 then $
      print,'AR1: inform = '+string(inform, format='(I0)')+' (constrained_min.pro). '+ $
            'Bad fit, check bounds for consistency.'
    ; recover constant factor
    c = spd_mtm_ar1_norm(ar1_par0, ff_ml, 1.0d, psd_ml, alpha_ml)
    ;
    ; check that the normalization is greater than zero
    if (c gt 0.d) then begin
      c = scl * c
      ar1_par = [c, ar1_par0]
      spec.modl[k,2,*] = spd_mtm_ar1_fun(spec.ff, ar1_par, par.fny)
    endif else begin
      spec.modl[k,2,*]=no_fit
      ar1_par = [c, ar1_par0]*!values.d_nan
    endelse
    ;
    ; save the value for next steps
    spec.frpr[k,2,0:1] = ar1_par
    ;
  endif
  
  
  ; ############################
  ; ## BPL: Bending Power Law ##
  ; ############################
  if ipar.specproc[k,3] eq 1 then begin
    ;
    ; minimization of the log-likelihood
    constrained_min, bpl_par0, bpl_bnd, L_bnd, 0, 'spd_mtm_bpl_lglk', inform, epstop=epst
    if inform gt 1 then $
      print,'BPL: inform = '+string(inform, format='(I0)')+' (constrained_min.pro). '+ $
            'Bad fit, check bounds for consistency.'
    ; recover constant factor
    c = spd_mtm_bpl_norm(bpl_par0, ff_ml, psd_ml, alpha_ml)
    ;
    ; check that the normalization is greater than zero
    if (c gt 0.d) then begin
      c = scl * c * (par.fny^bpl_par0[0])
      bpl_par0[2] = bpl_par0[2]*par.fny
      bpl_par = [c, bpl_par0]
      spec.modl[k,3,*] = spd_mtm_bpl_fun(spec.ff, bpl_par)
    endif else begin
      spec.modl[k,3,*]=no_fit
      bpl_par = [c, bpl_par0]*!values.d_nan
    endelse
    ;
    ; save the value for next steps
    spec.frpr[k,3,0:3] = bpl_par
    ;
  endif

endfor
;
end