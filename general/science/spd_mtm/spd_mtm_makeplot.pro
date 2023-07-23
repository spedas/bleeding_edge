;+
; :Description:
;   Plot the results from spd_mtm.pro.
; 
; :Params:
;   INPUTS:
;        data - 2 column data: [time vector, time series] = [x, y]
;               N.B. The average value of the data is removed by default.
;               If the data are not evenly sampled, the average time step
;               is used when it is lower than its standard deviation.
;        spec - structure with results of the spectral analysis
;               (as defined in spd_mtm.pro)
;        peak - identified signals (as defined in spd_mtm.pro)
;         par - properties of the time series and parameters defining
;               the spectral analysis (as defined in spd_mtm.pro)
;        ipar - indeces define the procedures for the identification
;               of PSD background and signals (as defined in spd_mtm.pro)
;     x_label - label for x-axis or defined set of choice
;               (default choice 'Time')
;     x_units - x variable unit of measures
;     y_units - y variable unit of measures
;     f_units - "frequency" variable unit of measures
;      x_conv - conversion factor for the x variable
;               (N.B. IS UP TO THE USER TO BE CONSISTENT WITH X_UNITS)
;      f_conv - conversion factor for the "frequency" variable
;               (N.B. IS UP TO THE USER TO BE CONSISTENT WITH F_UNITS)
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
pro spd_mtm_makeplot, data=data, $
  spec=spec, peak=peak, par=par, ipar=ipar, $
  x_label=x_label, x_units=x_units, $
  y_units=y_units, f_units=f_units, $
  x_conv=x_conv, f_conv=f_conv
  
  if x_label eq !null then begin
    x_label = '##'
    if x_units eq !null then x_units = '##'
    if y_units eq !null then y_units='##'
    if f_units eq !null then f_units = '##'
    if x_conv eq !null then x_conv = 1.0
    if f_conv eq !null then f_conv = 1.0
  endif else if x_label eq 'Time' then begin
    if x_units eq !null then x_units = 's'
    if y_units eq !null then y_units='##'
    if f_units eq !null then f_units = 'Hz'
    if x_conv eq !null then x_conv = 1.0
    if f_conv eq !null then f_conv = 1.0
  endif
  
  xdata = (data[0, *] - data[0, 0])*x_conv
  fny = par.fny * f_conv
  fbin_c = spec.fbin * f_conv
  ff_c = spec.ff * f_conv
  if ipar.power ne 1 then sp_conv = 1 else sp_conv = f_conv
  specraw = spec.raw / sp_conv
  specsmth = spec.smth / sp_conv
  specmodl = spec.modl / sp_conv
  specback = spec.back / sp_conv
  
  ; confidence string
  n_conf = n_elements(par.conf)
  if n_conf gt 3 then begin
    conf = par.conf[-3:-1]
    fconf = spec.fconf[-3:-1]
    conf_str = string(conf*100d, format='(f5.1)')
    n_conf = 3
  endif else begin
    conf = par.conf
    fconf = spec.fconf
    conf_str = string(conf*100d, format='(f5.1)')
  endelse
  conf_str = conf_str + '%'

  ;
  ; Plot 1 - data
  ;
  if ipar.pltsm eq 1 then $
    pos = [0.10, 0.60, 0.95, 0.95] else $ ; subpl [1,2,1]
    pos = [0.07, 0.60, 0.42, 0.95]        ; subpl [2,2,1]
  plot1 = plot( xdata, data[1, *], $
    TITLE = x_label + ' Series', $
    XTITLE = x_label + ' (' + x_units + ')', $
    YTITLE ='Amplitude [' + y_units + ']', $
    COLOR = 'blue', $
    XRANGE = [xdata[0], xdata[-1]], $
    POSITION = pos, $
    DIMENSION = [1300,900])

  ;
  ; plot 2 - F-test
  ;
  if ipar.pltsm ne 1 then begin
    ; plot only the lines for the last three greatest confidence
    ;
    ; title string
    title_str = 'F-test with the'
    for k = 0, n_conf-1 do begin
      title_str = title_str + conf_str[k]
    endfor
    ;
    plot2 = PLOT(ff_c, spec.ftest, /CURRENT, $
      TITLE = title_str + ' Conf. Threshold', $
      XTITLE = 'Frequency (' + f_units + ')', $
      YTITLE = 'F-test', $
      COLOR = 'blue', $
      XRANGE = [ff_c[0], ff_c[-1]], $
      POSITION = [0.57, 0.60, 0.92, 0.95]) ; subpl [2,2,2]
  
    bot_frange = min(ff_c)
    top_frange = max(ff_c)
    for k = 0, n_conf-1 do begin
      line0 = PLOT([bot_frange, top_frange], $
                   [fconf[k], fconf[k]], 'r:', /OVERPLOT)
    endfor
    ;
    ; F test peaks at the maximum confidence
    ind_peaks_ft = where(peak.pkdf[1,-1,*] gt 0, /null)
    if ind_peaks_ft ne [] then begin
      f_peaks_ft = ff_c[ind_peaks_ft]
      spec_peaks_ft = spec.ftest[ind_peaks_ft]
      pl_peaks_ft = plot(f_peaks_ft, 1.2*spec_peaks_ft, $
        'r|', /overplot)
    endif
    ;
  endif

  ;
  ; plot 3 - Power Spectral Density or Power Spectrum (ipower)
  ;          estimated by the adaptive or high-resolution
  ;          multitaper method (ihires)
  ; Title String
  ;
  smth_label = ['raw PSD', $
    'med-smoothed PSD', $
    'mlog-smoothed PSD', $
    'bin-smoothed PSD', $
    'but-smoothed PSD']
  ;
  if ipar.hires eq 1 then begin
    title_str = 'High-Res. MTM '
  endif else title_str = 'Adaptive MTM '
  if ipar.power eq 1 then begin
    t_str = 'Power Spectrum'
    y_str = 'Pow. Spec.' + ' [' + y_units + '^2]'
  endif else begin
    t_str = 'Power Spectral Density'
    y_str = 'P.S.D.' + ' [' + y_units +'^2/' + f_units + ']'
  endelse

  ;           
  if ipar.pltsm eq 1 then begin
    ;
    ; plot the raw spectrum
    title_str = [title_str + t_str, 'and selected smoothed PSD']
    plot3 = plot(ff_c, specraw, /YLOG, /CURRENT, $
      TITLE = title_str,$
      XTITLE = 'Frequency (' + f_units + ')', $
      YTITLE = y_str, $
      YTICKUNITS = 'Scientific', $
      COLOR = 'blue', $
      NAME = 'raw', $
      XRANGE = [ff_c[0], ff_c[-1]], $
      POSITION = [0.10, 0.05, 0.95, 0.40] ) ; subpl [1,2,2]
    ;
    legtar = plot3
    ;
    ; plot only the selected smoothed spectra;
    ;
    ; running median
    if total(ipar.specproc[1,*]) gt 0 then begin
      l_med = plot(ff_c, specsmth[1,*], /overplot, $
        'r-.', name='med', thick=3)
      legtar = [legtar, l_med]
    endif
    ;
    ; running log-window median
    if total(ipar.specproc[2,*]) gt 0 then begin
      l_mlog = plot(ff_c, specsmth[2,*], /overplot, $
        'g-:', name='mlog', thick=3)
      legtar = [legtar, l_mlog]
    endif
    ;
    ; binned
    if total(ipar.specproc[3,*]) gt 0 then begin
      l_bin = plot(fbin_c, specsmth[3,*], /overplot, $
        'm--', name='bin', thick=3)
      legtar = [legtar, l_bin]
    endif
    ;
    ; butterworth
    if total(ipar.specproc[4,*]) gt 0 then begin
      l_but = plot(ff_c, specsmth[4,*], /overplot, $
        'k', name='but', thick=2)
      legtar = [legtar, l_but]
    endif
    ;
    ; legend
    leg = LEGEND( TARGET=legtar, POSITION=[0.375,0.525], /AUTO_TEXT_COLOR, $
      shadow=0, thick=0, /orientation)
  endif else begin
    ;
    ; plot all the selected models for a given smoothing procedure
    title_str = [title_str + t_str, 'and PSD models with the' + $
      conf_str[-1] + ' Conf. Threshold', $
      'fitted on the ' +  smth_label[spec.indback[0]]]
    ;
    plot3 = plot(ff_c, specraw, /YLOG, /CURRENT, $
      TITLE = title_str,$
      XTITLE = 'Frequency (' + f_units + ')', $
      YTITLE = y_str, $
      YTICKUNITS = 'Scientific', $
      COLOR = 'blue', $
      NAME = 'raw', $
      XRANGE = [ff_c[0], ff_c[-1]], $
      POSITION = [0.07, 0.05, 0.42, 0.40] ) ; subpl [2,2,3]
    ;
    legtar = plot3
    ; 
    ; consider the smoothing procedure associated to the selected background
    ismoo = spec.indback[0]
    ;
    ; plot the selected smoothed spectrum
    sm_name = ['raw','med','mlog','bin','but']
    ;
    if ismoo eq 3 then fsmt = fbin_c else fsmt = ff_c
    ;
    l_smoo = plot(fsmt, specsmth[ismoo,*], /overplot, $
                    'b', name=sm_name[ismoo], thick=2)
    legtar = [legtar, l_smoo]
    ; 
    ; plot all the models fitted on the selected smoothed spectrum
    ; 
    ; white noise
    if ipar.specproc[ismoo,0] eq 1 then begin
      l_wht0 = plot(ff_c, specmodl[ismoo,0,*], /overplot, $
                    'm:', name='50%', thick=3)
      l_wht1 = plot(ff_c, specmodl[ismoo,0,*]*spec.conf[-1], /overplot, $
                    'm:', name = 'WHT', thick=2)
      legtar = [legtar, l_wht1]
    endif
    ;
    ; power law
    if ipar.specproc[ismoo,1] eq 1 then begin
      l_pl0 = plot(ff_c, specmodl[ismoo,1,*], /overplot, $
                   'k-:', name='50%', thick=3)
      l_pl1 = plot(ff_c, specmodl[ismoo,1,*]*spec.conf[-1], /overplot, $
                   'k-:', name = 'PL', thick=2)
      legtar = [legtar, l_pl1]
    endif
    ;
    ; lag-one autoregressive
    if ipar.specproc[ismoo,2] eq 1 then begin
      l_ar10 = plot(ff_c, specmodl[ismoo,2,*], /overplot, $
                    'g-.', name='50%', thick=3)
      l_ar11 = plot(ff_c, specmodl[ismoo,2,*]*spec.conf[-1], /overplot, $
                    'g-.', name = 'AR(1)', thick=2)
      legtar = [legtar, l_ar11]
    endif
    ;
    ; bending power law
    if ipar.specproc[ismoo,3] eq 1 then begin
      l_bpl0 = plot(ff_c, specmodl[ismoo,3,*], /overplot, $
                    'r--', name='50%', thick=3)
      l_bpl1 = plot(ff_c, specmodl[ismoo,3,*]*spec.conf[-1], /overplot, $
                    'r--', name = 'BPL', thick=2)
      legtar = [legtar, l_bpl1]
    endif
    ;
    ; legend
    leg = legend( TARGET=legtar, POSITION=[0.52,0.40], /AUTO_TEXT_COLOR, $
       shadow=0, sample_width=0.08)
    leg.scale, 0.8
  endelse
  
  ;
  ; plot 4
  ;
  if ipar.pltsm ne 1 then begin
    ;
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
      0: back_str = ['Selected PSD model: White Noise (WHT)', $
                     'c = ' + c0]
      1: back_str = ['Selected PSD model: Power Law (PL)', $
                     '[c, $\beta$] = ['+c1+', '+bet1+']']
      2: back_str = ['Selected PSD model: Lag-one Autoregressive (AR(1))', $
                     '[c, $\rho$] = ['+c2+', '+rho2+']']
      3: back_str = ['Selected PSD model: Bending Power Law (BPL)', $
                     '[c, $\beta$, $\gamma$, f!Lb!N] = [' + $
                     c3+', '+bet3+', '+gam3+', '+fb3+']']
    endcase
    ;
    plot4 = plot(ff_c, specraw, /YLOG, /CURRENT, $
      TITLE = ['Harmonic + Spectral Analysis with the' + $
               conf_str[-1] + ' Conf. Threshold', back_str], $
      XTITLE = 'Frequency (' + f_units + ')', $
      YTITLE = y_str, $
      YTICKUNITS = 'Scientific', $
      COLOR = 'blue', $
      XRANGE = [ff_c[0], ff_c[-1]], $
      POSITION = [0.57, 0.05, 0.92, 0.40] ); subpl [2,2,4]
    ;
    l_back0 =  plot(ff_c, specback, /overplot,'r', thick=3)
    l_bakc1 =  plot(ff_c, specback*spec.conf[-1], /overplot, 'r') 
    ;
    ; plot selected peaks according to 'gft' at the maximum confidence level
    ; 'gft' --> prakprocedure = 2
    ; maximum confidence level available --> -1
    ; 
    ; dummy parameters to let the legend appear
    f_pk = [2.0*fny, 2.0*fny]
    s_pk = [min(specraw), min(specraw)]
    ;
    legpks = []
    ;
    ; gamma test
    ind_peaks_gt = where(peak.pkdf[0,-1,*] gt 0, /null)
    if ind_peaks_gt ne !null then begin
      f_peaks_gt = [f_pk, ff_c[ind_peaks_gt] ]
      spec_peaks_gt = [s_pk, specraw[ind_peaks_gt] ]
      ;
      pl_peaks_gt = plot(f_peaks_gt, 2.0d*spec_peaks_gt, $
        'ro', sym_size=0.75, /overplot, name='gt')
      legpks = [legpks, pl_peaks_gt]
      p1 = 0.00
    endif else begin
      if ipar.peakproc[0] eq 1 then begin
        ; this is a dummy point to let
        ; the legend appear in the plot
        pl_peaks_gt = plot(f_pk, s_pk, $
          'ro', sym_size=0.75, /overplot, name='gt')
        legpks = [legpks, pl_peaks_gt]
        p1 = 0.00
      endif
    endelse
    ;
    ; gamma + F test
    ind_peaks_gft = where(peak.pkdf[2,-1,*] gt 0, /null)
    if (ind_peaks_gft ne !null) then begin
      f_peaks_gft = [f_pk, ff_c[ind_peaks_gft] ]
      spec_peaks_gft = [s_pk, specraw[ind_peaks_gft] ]
      ;
      pl_peaks_gft = plot(f_peaks_gft, 2.0d*spec_peaks_gft, $
        'r|', sym_size=1.2, /overplot, name='gft')
      legpks = [legpks, pl_peaks_gft]
      p1 = 0.01
    endif else begin
      if ipar.peakproc[2] eq 1 then begin
        ; this is a dummy point to let
        ; the legend appear in the plot
        pl_peaks_gft = plot(f_pk, s_pk, $
          'r|', sym_size=1.2, /overplot, name='gft')
        legpks = [legpks, pl_peaks_gft]
        p1 = 0.01
      endif
    endelse
    ;
    ; gamma + F test, only local F value maximum
    ind_peaks_gftm = where(peak.pkdf[3,-1,*] gt 0, /null)
    if (ind_peaks_gftm ne !null) then begin
      f_peaks_gftm = [f_pk, ff_c[ind_peaks_gftm] ]
      spec_peaks_gftm = [s_pk, specraw[ind_peaks_gftm] ]
      ;
      pl_peaks_gftm = plot(f_peaks_gftm, 2.0d*spec_peaks_gftm, $
        'rtu', sym_size=1.5, /overplot, name='gftm')
      legpks = [legpks, pl_peaks_gftm]
      p1 = 0.02
    endif else begin
      if ipar.peakproc[3] eq 1 then begin
        ; this is a dummy point to let
        ; the legend appear in the plot
        pl_peaks_gftm = plot(f_pk, s_pk, $
          'rtu', sym_size=1.5, /overplot, name='gftm')
        legpks = [legpks, pl_peaks_gftm]
        p1 = 0.02
      endif
    endelse
    ;
    ; legend
    if legpks ne [] then begin
      ;
      leg_peaks = legend( TARGET=legpks, POSITION=[1.0+p1,0.40], /AUTO_TEXT_COLOR, $
        shadow=0, SAMPLE_WIDTH=0.0, HORIZONTAL_SPACING=0.05)
      leg_peaks.scale, 0.7
    endif
    ;
  endif

end
