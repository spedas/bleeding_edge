;+
; :Description:
;   Perform a spectral analysis via the spd_mtm.pro procedure
;   on a selected interval of a tplot variable.
;
; :Params:
;     vname - tplot variable name 
;    trange - time range
;  dec_step - decimation step: number of points between values to consider
;        NW - time-halfbandwidth product, DEFAULT: NW = 3
;      Ktpr - Number of tapers to apply, DEFAULT: Ktpr = 2*NW - 1
;   padding - Amount of padding to apply (proportional to the original data)
;             DEFAULT: padding=1 so that the frequency step (df)
;             equals the Rayleigh frequency [1/(N*dt)]
;      dpss - structure with tapers and eigenvalues
;             evaluated by spd_mtm_dpss.pro or previous call of spd_mtm.pro
;      flim - limits in percentages of the frequency range to be analyzed,
;             DEFAULT: [df,fny-df], where fny is the Nyquist frequency [1/(2*dt)]
; smoothing - possible smoothing:
;             'raw'(0) no smoothing (DEFAULT)
;             'med'(1) running median
;             'mlog'(2) running median (constant window on log(f) )
;             'bin'(3) binned PSD
;             'but'(4) low pass filtered PSD (Butterworth filter)
;             'all'(9) use all the smoothing procedures
;   psmooth - value between (0,0.5] defining the "smoothing window"
;             psmooth=2 -> search the optimum window according
;                          to the Kolmogorov-Smirnov test (DEFAULT)
;    model  - implemented models:
;             'wht'(0) white noise, [N]
;             'pl'(1) power law, [N, beta]
;             'ar1'(2) first order autoregressive process, [N, rho]
;             'bpl'(3) bending power law, [N, beta, gamma, fb] (DEFAULT)
;             'all'(9) use all the models
;  procpeak - possible choices:
;             '' do not search for peaks
;             'gt'(0) gamma test only
;             'ft'(1) F test only
;             'gft'(2) gamma and F test (DEFAULT)
;             'gftm'(3) only max F value for each PSD enhancement
;             'all'(9) use all the selection procedures
;      conf - confidence levels in increasing order
;             (DEFAULT is conf=[0.90,0.95,0.99])
;      resh - value between (0,1.0], reshape the PSD from peaks identified
;             according to the 'gft' procedure at the "resh" confidence level
;             (DEFAULT: resh=0, do not perform the reshaping)
;       gof - PSD background chosing criterium:
;             'MERIT' - MERIT function (DEFAULT)
;             'CKS' - Kolmogorov-Smirnov test
;             'AIC' - Akaike Information Criteria
;
;   x_label - label for x-axis or defined set of choice
;             (default choice 'Time', see spd_mtm_makeplot.pro)
;   x_units - x variable unit of measures
;   y_units - y variable unit of measures
;   f_units - "frequency" variable unit of measures
;    x_conv - conversion factor for the x variable
;             (N.B. IS UP TO THE USER TO BE CONSISTENT WITH X_UNITS)
;    f_conv - conversion factor for the "frequency" variable
;             (N.B. IS UP TO THE USER TO BE CONSISTENT WITH F_UNITS)
;             
; OUTPUTS:
;   spec. 
;      spec - structure with results of the spectral analysis
;             (as defined in spd_mtm.pro)
;      peak - identified signals (as defined in spd_mtm.pro)
;       par - properties of the time series and parameters defining
;             the spectral analysis (as defined in spd_mtm.pro)
;      ipar - indeces define the procedures for the identification
;             of PSD background and signals (as defined in spd_mtm.pro)
;   rshspec - provide the spec structures based on the reshaped PSD
;             (If it is not specified, the results are overwritten on spec)
;   rshpeak - provide the peak structures based on the reshaped PSD
;             (If it is not specified, the results are overwritten on peak)
;            
; :Keywords:
;     /hires - spec.raw is the high-resolution PSD estimate
;     /power - spec.raw is the integrated PSD: df*PSD [##^2]
;     /quiet - do not display parameters and results
;     /allpeakwidth - no constrains on the PSD enhancements width
;     /pltsmooth - plot only the smoothed PSDs and stop
;     /no_plot - do not plot the results
;     /double - output in double precision
;
; :Uses:
;     spd_mtm.pro
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
pro tplot_spd_mtm, vname=vname, trange=trange, NW = NW, Ktpr = Ktpr, $
  dec_step = dec_step, padding=padding, dpss=dpss, $
  flim=flim, smoothing=smoothing, psmooth=psmooth, model=model, procpeak=procpeak, $
  conf=conf, resh=resh, gof=gof, $ ; INPUTS
  hires=hires, power=power, quiet=quiet, allpeakwidth=allpeakwidth, $
  pltsmooth=pltsmooth, no_plot=no_plot, double=double, $ ; KEYWORDS
  x_label=x_label, x_units=x_units, y_units=y_units, f_units=f_units, $ ; plot labels
  x_conv=x_conv, f_conv=f_conv, $ ; plot conversion factors
  spec=spec, peak=peak, par=par, ipar=ipar, rshspec=rshspec, rshpeak=rshpeak; OUTPUTS

if not keyword_set(NW) then NW = 3
if not keyword_set(Ktpr) then Ktpr = 2 * NW - 1
if not keyword_set(padding) then padding = 1;
if dec_step eq [] then dec_step = 0
if keyword_set(no_plot) then makeplot=0 else makeplot=1

if ~keyword_set(vname) then begin
  ;
  print, '##################################'
  print, ''
  print, 'Select variable and/or start time.'
  print, ''
  print, '##################################'
  ctime, time, npoints = 1, vname = vname, /silent
  wait, 0.2
  ;
  ; if time range has been defined ask only for which variable
  if keyword_set(trange) then begin
    time = trange
  endif else begin
    print, '#################'
    print, ''
    print, 'Select stop time.'
    print, ''
    print, '#################'
    ctime, time, npoints = 1, vname = vname, /silent, /append
  endelse
  ;
endif else if ~keyword_set(trange) then begin
  ;
  ; ask for the time range if not defined
  print, '#####################################################'
  print, ''
  print, 'Click on 2 points to define the start and stop times.'
  print, ''
  print, '#####################################################'
  ctime, time, npoints = 2, /silent
  ;
endif else time = 0
;
; get the variable data
common tplot_com1
get_data, vname[0], data = d
;
; define the time range
if n_elements(time) eq 1 then time=[d.x[0], d.x[-1]]
;
print, 'SPD_MTM analysis is from ', time_string(time[0]), ' - ', time_string(time[1])
;
; start and stop indices
indi = where(d.x ge time(0) and d.x le time(1))
indi1 = indi[0]
indi2 = indi[-1]
print, vname(0), indi1, indi2
;
;  Do a check on zero and too many data points
if (indi2 - indi1) gt 2 and (indi2 - indi1) lt 5000 then begin
  ;
  ; decimate data if setted
  if dec_step then ut = d.x[indi1:indi2:dec_step]-d.x[indi1] $
              else ut = d.x[indi1:indi2]-d.x[indi1]
  if dec_step then the_data = d.y[indi1:indi2:dec_step] $
              else the_data = d.y[indi1:indi2]
  ;
  ; check for data gaps
  q = where(finite(the_data,/nan), /null)
  if q ne [] then begin
    the_data[q] = interpol(the_data, ut, ut[q], /nan)
    num_nans = n_elements(q)
    print, 'Data gaps: ', num_nans, ' point interpolated.'
  endif
  ;
  ; check for fixed sampling rate
  diff_ut = ut[1:-1] - ut[0:-2]
  dt_not_fixed = total( diff_ut[1:-1] - diff_ut[0:-2] )
  ;
  if dt_not_fixed then begin
    ;
    ; reduce to a common sampling rate
    deltaT = median(diff_ut)
    length_of_time = round(ut[-1] - ut[0])
    new_ut = findgen(length_of_time / deltaT) * deltaT
    new_data = interpol(the_data, ut, new_ut, /nan)
    intrvl = [[new_ut], [new_data]]
    ;
    print, 'Variable sampling rate. ', + $
           'Data interpolated with dt = ' + string(deltaT, format='(g10.4)')
    ;
    spd_mtm, data=intrvl, NW=NW, Ktpr=Ktpr, padding=padding, dpss=dpss, $
      flim=flim, smoothing=smoothing, psmooth=psmooth, model=model, procpeak=procpeak, $
      conf=conf, resh=resh, gof=gof, $ ; INPUTS
      hires=hires, power=power, quiet=quiet, allpeakwidth=allpeakwidth, $
      pltsmooth=pltsmooth, makeplot=makeplot, double=double, $ ; KEYWORDS
      x_label=x_label, x_units=x_units, y_units=y_units, f_units=f_units, $ ; plot labels
      x_conv=x_conv, f_conv=f_conv, $ ; plot conversion factors
      spec=spec, peak=peak, par=par, ipar=ipar, rshspec=rshspec, rshpeak=rshpeak; OUTPUTS
    ;
  endif else begin
    ;
    intrvl = [[ut],[the_data]]
    spd_mtm, data=intrvl, NW=NW, Ktpr=Ktpr, padding=padding, dpss=dpss, $
      flim=flim, smoothing=smoothing, psmooth=psmooth, model=model, procpeak=procpeak, $
      conf=conf, resh=resh, gof=gof, $ ; INPUTS
      hires=hires, power=power, quiet=quiet, allpeakwidth=allpeakwidth, $
      pltsmooth=pltsmooth, makeplot=makeplot, double=double, $ ; KEYWORDS
      x_label=x_label, x_units=x_units, y_units=y_units, f_units=f_units, $ ; plot labels
      x_conv=x_conv, f_conv=f_conv, $ ; plot conversion factors
      spec=spec, peak=peak, par=par, ipar=ipar, rshspec=rshspec, rshpeak=rshpeak; OUTPUTS
    ;
  endelse
;
endif else begin
  print, 'ERROR:tplot_spd_mtm - Too many points, try decimate.'
  spec = !NULL
  peak = !NULL
  par = !NULL
  ipar = !NULL
endelse
;
end