;+
; :Description:
;   Display parameters and results of spd_mtm.pro on IDL console.
;
; :Params:
;   INPUTS:
;       smth_label - labels of the smoothing procedures
;       modl_label - labels of the PSD models
;           par.dt - average sampling time
;        par.dtsig - standard deviation of the sampling time
;         par.fray - Rayleigh frequency: fray = 1/(npts*dt)
;          par.fny - Nyquist frequency: fny = 1/(2*dt)
;         par.npts - time series number of points
;        ipar.resh - confidence threshold percentage chosen to select the
;                    PSD enhancements to be removed in the PSD reshaping
;       ipar.pltsm - keyword /pltsmooth is selected (1) or not (0)
;    spec.poor_MTM - flag for failed convergence of the adaptive MTM PSD
;     spec.indback - indices of the selected PSD background;
;                    smoothing/model = spec.indback[0]/spec.indback[1]
;        spec.frpr - model parameters resulting from the fitting procedures
;                    spec.frpr[#smth, #modl, #par]:
;                    #par = 0->'c'; 1->'rho' or 'beta'; 2->'gamma'; 3->'fb'
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
pro spd_mtm_dispar, smth_label, modl_label, par, ipar, spec
;
print, 'Sampling rate is ', par.dt
print, 'standard deviation of sampling rate is ', par.dtsig
print, 'Rayleigh frequency (lowest frequency) is (mHz) ', par.fray * 1000.
print, 'The Nyquist frequency (highest frequency) is (mHz) ', par.fny * 1000.
print, 'Number of points is ', par.npts
if spec.poor_MTM then print, 'Poor MTM estimate. Try pre-whitening ' + $
  'of the data or increasing NW.'
if ipar.resh gt 0 then begin
  resh_prct = string(ipar.resh*100.0, format='(g0.2)')
  print, 'PSD reshaping performed. Eventual signals identified according' + $
    ' to the gamma + F test with the '+resh_prct+'% confidence thresholds' + $
    ' have been removed.'
endif
;
if ipar.pltsm ne 1 then begin
  print, 'The selected smoothing is the ', smth_label[spec.indback[0]]
  print, 'The selected model is the ', modl_label[spec.indback[1]]
  ;
  ; display model parameters
  ; 
  ; 0 --> wht
  c0 = string(spec.frpr[spec.indback[0],0, 0], format='(g0.3)')
  ; 1 --> pl
  c1 = string(spec.frpr[spec.indback[0],1, 0], format='(g0.3)')
  bet1 = string(spec.frpr[spec.indback[0],1, 1], format='(g0.3)')
  ; 2 --> ar1
  c2 = string(spec.frpr[spec.indback[0],2, 0], format='(g0.3)')
  rho2 = string(spec.frpr[spec.indback[0],2, 1], format='(g0.3)')
  ; 3 --> bpl
  c3 = string(spec.frpr[spec.indback[0],3, 0], format='(g0.3)')
  bet3 = string(spec.frpr[spec.indback[0],3, 1], format='(g0.3)')
  gam3 = string(spec.frpr[spec.indback[0],3, 2], format='(g0.3)')
  fb3 = string(spec.frpr[spec.indback[0],3, 3], format='(g0.3)')
  ;
  ;
  case spec.indback[1] of
    0: print, 'c = ' + c0
    1: print, '[c, beta] = ['+c1+', '+bet1+']'
    2: print, '[c, rho] = ['+c2+', '+rho2+']'
    3: print, '[c, beta, gamma, fb] = [' + $
              c3+', '+bet3+', '+gam3+', '+fb3+']'
  endcase
  ;
endif
;
end