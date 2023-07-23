;+
; :Description:
;   Perform a spectral analysis following
;   Di Matteo, S., Viall, N., Kepko, L. (2020), 
;   "Power Spectral Density Background Estimate and 
;   Signals Detection via the Multitaper Method."
;   Journal of Geophysical Research Space Physics.
;   
;   PSD stands for Power Spectral Density
;     
; :Params:
;   INPUTS:
;      data - 2 column data: [time vector, time series]
;             N.B. The average value of the data is removed by default.
;             If the data are not evenly sampled, the average time step
;             is used when it is lower than its standard deviation.
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
;             'gft'(2) gamma and F test 
;             'gftm'(3) only max F value for each PSD enhancement
;             'all'(9) use all the selection procedures (DEFAULT)
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
;   OUTPUTS:
;   spec.         
;       .ff       Fourier frequencies
;       .raw      adaptive multitaper PSD
;       .back     best PSD background among the probed ones
;       .ftest    values of the F test
;       .resh     reshaped PSD (if resh in spd_mtm is imposed) 
;       .dof      degree of freedom at each Fourier frequency
;       .fbin     binned frequencies for the bin-smoothed PSD
;       .smth     smoothed PSD, spec.smth[#smth, *]:
;                 #smth = 0->'raw'; 1->'med'; 2->'mlog', 3->'bin'; 4->'but'
;       .modl     PSD background models, spec.modl[#smth, #modl, *]:
;                 #modl = 0->'wht'; 1->'pl'; 2->'ar1'; 3->'bpl'
;       .frpr     model parameters resulting from the fitting procedures
;                 spec.frpr[#smth, #modl, #par]:
;                 #par = 0->'c'; 1->'rho' or 'beta'; 2->'gamma'; 3->'fb'
;       .conf     confidence threshold values for the PSD (gamma test)
;       .fconf    confidence threshold values for the F statistic (F test)
;       .CKS      C_KS value for each probed model spec.CKS[#smth, #modl]
;       .AIC      AIC value for each probed model spec.AIC[#smth, #modl]
;       .MERIT    MERIT value for each probed model spec.MERIT[#smth, #modl]
;       .Ryk      real part of the eigenspectra spec.Ryk[#Ktpr,*]
;       .Iyk      imaginary part of the eigenspectra spec.Iyk[#Ktpr,*]
;       .psmooth  percentage of the frequency range defining
;                 the smoothing window spec.psmooth[#smth]
;       .muf      complex amplitude at each Fourier frequency
;       .indback  indices of the selected PSD background;
;                 smoothing/model = spec.indback[0]/spec.indback[1]
;       .poor_MTM flag for failed convergence of the adaptive MTM PSD
;     
;   peak.          
;       .ff       Fourier frequencies
;       .pkdf     for each peak selection method and confidence level 
;                 a value greater than zero at a specific frequency
;                 indicate the occurence of a signal at that frequency:
;                 peak.pkdf[#peakproc, #conf, #freq]
;                 'gamma test' -> peak.pkdf[0,*,*] contains the badwidth
;                 of the PSD enhancements at the identified frequencies
;                 'F test', 'gft', and 'gftm' -> peak.pkdf[1:3,*,*]
;                 is equal to par.df at the identified frequencies
;     
;    par.
;       .npts     time series number of points
;       .dt       average sampling time
;       .dtsig    standard deviation of the sampling time
;       .datavar  variance of the time series
;       .fray     Rayleigh frequency: fray = 1/(npts*dt)
;       .fny      Nyquist frequency: fny = 1/(2*dt)
;       .npad     time series number of points after padding
;       .nfreq    number of frequencies
;       .df       frequency resolution (after padding), it corresponds to
;                 the Rayleigh frequency for no padding (padding = 1)
;       .fbeg     beginning frequency of the interval under analysis
;       .fend     ending frequency of the interval under analysis
;       .psmooth  value imposed in spd_mtm
;       .conf     confidence thresholds percentages
;       .NW       time-halfbandwidth product
;       .Ktpr     number of tapers (max value is 2*NW - 1)
;       .tprs     discrete prolate spheroidal sequences (dpss)
;       .v        dpss eigenvalues
;      
;   ipar.
;       .hires    keyword /hires is selected (1) or not (0)
;       .power    keyword /power is selected (1) or not (0)
;       .specproc array[#smth,#modl] smoothing and model combinations
;                 1 (0) the smoothing + model combination is (not) probed
;       .peakproc array[4] referring to 'gt', 'ft', 'gft', and 'gftm'
;                 1 (0) peaks according to this procedure are (not) saved
;       .allpkwd  keyword /allpeakwidth is selected (1) or not (0)
;       .pltsm    keyword /pltsmooth is selected (1) or not (0)
;       .resh     confidence threshold percentage chosen to select the
;                 PSD enhancements to be removed in the PSD reshaping
;       .gof      criterium used to select the PSD background
;       
;   rshspec  provide the spec structures based on the reshaped PSD
;            (If it is not specified, the results are overwritten on spec)
;            
;   rshpeak  provide the peak structures based on the reshaped PSD
;            (If it is not specified, the results are overwritten on peak)
; 
; :Keywords:
;     /hires - spec.raw is the high-resolution PSD estimate
;     /power - spec.raw is the integrated PSD: df*PSD [##^2]
;     /quiet - do not display parameters and results
;     /allpeakwidth - no constrains on the PSD enhancements width
;     /pltsmooth - plot only the smoothed PSDs and stop
;     /makeplot - plot the results
;     /double - output in double precision
; 
; :Uses:
;     spd_mtm_dpss.pro
;     spd_mtm_spec.pro
;     spd_mtm_regre.pro
;     spd_mtm_smoothing.pro
;     spd_mtm_fitmodel.pro
;     spd_mtm_modelgof.pro
;     spd_mtm_conflvl.pro
;     spd_mtm_findpeaks.pro
;     spd_mtm_reshape.pro
;     spd_mtm_dispar.pro
;     spd_mtm_dbl2flt.pro
;     spd_mtm_makeplot.pro
; 
; :Example:
;     
;     t = [0:511] ; time vector, suppose dt = 1s
;     x = 0.5*cos(2.0*!pi*t/8.0) + randomn(3,512,1) ; time series
;     data = [[t],[x]]
;     
;     spd_mtm, data=data, NW=3, Ktpr=5, padding=1, dpss=dpss, $
;              flim=[0,1], smoothing=’all’, psmooth=2, $
;              model=’wht’, procpeak=[’gt’,'gft'], $
;              conf=[0.90,0.95d], $
;              /makeplot, $
;              x_label=’Time’, y_units=’##’, $ 
;              x_units=’min’, x_conv=1.0/60.0, $
;              f_units=’mHz’, f_conv=1d3, $
;              spec=spec, peak=peak, par=par, ipar=ipar
;
;     ; plot the adaptive MTM PSD
;     plot(spec.ff, spec.raw, /ylog)
;     
;     ; plot the selected PSD background
;     plot(spec.ff, spec.back, 'r', /overplot)
;
;     ; plot confidence threshold for the PSD
;     plot(spec.ff, spec.back*spec.conf[0], 'r--', /overplot)
;
;     ; plot a smoothed PSD
;     ; (N.B. The smoothing approach has to be present the inputs)
;     plot(spec.ff, spec.smth[1,*]) ; med
;     plot(spec.ff, spec.smth[2,*]) ; mlog
;     plot(spec.fbin, spec.smth[3,*]) ; bin
;     plot(spec.ff, spec.smth[4,*]) ; but
;
;     ; plot a fitted PSD model on a smoothed PSD
;     ; (N.B. The model has to be present the inputs)
;     plot(spec.ff, spec.modl[0,0,*]) ; raw/WHT
;     plot(spec.ff, spec.modl[3,1,*]) ; bin/PL
;     plot(spec.ff, spec.modl[2,2,*]) ; mlog/AR(1)
;     plot(spec.ff, spec.modl[3,3,*]) ; bin/BPL
;
;     ; to recover the identified peaks:
;     indices_peaks = where(peak.pkdf[0,0,*] gt 0)
;     
;     ; N.B.
;     ; peak.pkdf[0,0,*] -> gamma test, lowest confidence level (from conf)
;     ; peak.pkdf[2,0,*] -> gamma and F test, lowest confidence level (from conf)
;     ; peak.pkdf[0,-1,*] -> gamma test, highest confidence level (from conf)
;     
;     if (indices_peaks[0] ge 0) then begin
;       signals_frequency = peak.ff[indices_peaks]
;     endif
; 
; :Version:
;     Version 1.0
; 
; :Author:
;     Simone Di Matteo, Ph.D.
;     8800 Greenbelt Rd
;     Greenbelt, MD 20771 USA
;     E-mail: simone.dimatteo@nasa.gov
;- 
;*****************************************************************************;
;									                                                            ;
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
pro spd_mtm, data=data, NW=NW, Ktpr=Ktpr, padding=padding, dpss=dpss, $
  flim=flim, smoothing=smoothing, psmooth=psmooth, model=model, procpeak=procpeak, $
  conf=conf, resh=resh, gof=gof, $ ; INPUTS
  hires=hires, power=power, quiet=quiet, allpeakwidth=allpeakwidth, $
  pltsmooth=pltsmooth, makeplot=makeplot, double=double, $ ; KEYWORDS
  x_label=x_label, x_units=x_units, y_units=y_units, f_units=f_units, $ ; plot labels
  x_conv=x_conv, f_conv=f_conv, $ ; plot conversion factors
  spec=spec, peak=peak, par=par, ipar=ipar, rshspec=rshspec, rshpeak=rshpeak; OUTPUTS
  
  ;##################################################################################
  ;
  ; set variables
  ; 
  ;  Get the data in the right format - should be [2, npts]. 
  ;  [0, *] is time, [1, *] is data, npts is the number of points
  dataSize = size(data)
  if dataSize[2] eq 2 then begin
    data = transpose(data)
    dataSize = size(data)
  endif
  npts = double(dataSize[2])
  
  ;
  ; check for missing points and remove the mean value from the series
  data1 = data[1, *]
  check_data = total([finite(data1, /nan, sign=0), $
                      finite(data1, /infinity, sign=0)])
  if check_data gt 0.d then begin
    message, 'Missing values in the data.', /CONTINUE
    return
  endif
  demn = mean(data1, /double)
  demean0 = double(data1 - demn)
  ; variance of the data
  datavar = variance(demean0)
  
  ;
  ; calculate Rayleigh and Nyquist frequencies
  t_tmp = reform(data[0, *])
  dt_tmp = t_tmp[1:-1] - t_tmp[0:-2]
  dt = mean(dt_tmp, /double)
  dtsig = stddev(dt_tmp, /double)
  if (dtsig gt dt) then begin
    message, 'The data are not evenly sampled.', /continue
    print, 'Sampling rate average=', dt, ' and standard deviation=',dtsig
    return
  endif
  fray = 1.d / (npts * dt) ;Rayleigh Frequency
  fny = 0.5d / dt ;Nyquist Frequency
  
  ;
  ; user defined padding
  if padding eq !null then padding = 1
  if padding lt 1 then begin
    message, 'Padding must be equal to or greater than 1.', /continue
    return
  endif
  npad = double( round(npts * padding) )
  ; add zeros to the data
  if (npad-npts) gt 0 then begin
    addzero = make_array(1, (npad-npts), /double, value=0)
    demean = [[demean0], [addzero]]
  endif else demean = demean0
  
  ;
  ; determine number of frequency of the one-sided spectrum
  if npad mod 2 then begin ; npad is odd
    nfreq = (npad+1.d)/2.d
  endif else nfreq = npad/2.d + 1.d ; npad is even
  
  ;
  ; resolution/variance tradeoff
  if NW eq !null then NW = 3
  if Ktpr eq !null then begin
    Ktpr = 2*NW - 1
  endif else if (Ktpr gt (2*NW-1)) or (Ktpr lt 2) then begin
    message, 'The number of tapers is not valid, '+$
      'choose 2 <= Ktpr <= 2NW-1', /continue
    return
  endif
  NW = double(NW)
  Ktpr = double(Ktpr)
  bndwdth = 2.d * NW * fray
  
  ;
  ; frequency step
  df = 1.d / (npad * dt)
  
  ;
  ; determine frange for background and findpeaks analyses
  if flim eq !null then begin
    flim=[0.0, 1.0d]
  endif else if n_elements(flim) ne 2 then begin
    message, 'The flim input needs two values'+ $
      ', e.g. flim=[0,1]', /continue
    return
  endif else if total(abs(flim) gt 1) gt 0 then begin
    message, 'The flim values must be between 0 and 1.', /continue
    return
  endif
  ; do not consider zero
  if flim[0] eq 0 then begin
    fbeg = df ; df=fray when padding=1
  endif else fbeg = flim[0]*fny
  ; do not consider the Nyquist frequency if present
  if flim[1] eq 1 then begin
    if npad mod 2 then begin ; npad is odd
      fend = (nfreq-1.0)*df
    endif else fend = (nfreq-2.0)*df ; npad is even
  endif else fend = flim[1]*fny
  ; define frequency range
  frange = fend - fbeg
  
  ;
  ; ipower = 0 ; default
  if keyword_set(power) then power=1 else power=0
  
  ;
  ; hires = 0 ; default
  if keyword_set(hires) then hires=1 else hires=0
  
  ;
  ; allpeakwidth
  if keyword_set(allpeakwidth) then allpkwd=1 else allpkwd=0
  
  ;
  ; iplsmt = 0 ; default
  if keyword_set(pltsmooth) then begin
    makeplot = 1
    pltsm=1
  endif else pltsm=0
  
  ;
  ; conf --> generic array with confidence levels
  if conf eq !null then begin
    ; default confidence levels at 90%, 95%, and 99%
    conf = [.90d, .95d, .99d]
  endif else begin
    ; sort the input confidence levels in increasing order
    conf = double(conf[sort(conf)])
  endelse
  
  ;
  ; resh = 0 ; default
  if resh eq !null then begin
    resh=0 ; no reshaping
    if arg_present(rshspec) or arg_present(rshpeak) then begin
      message, 'To obtain rshspec or rshpeak, '+ $
      'set a reshaping confidence threshold, e.g resh=0.90', /continue
      return
    endif
  endif else begin
    if (resh lt 0.d) or (resh gt 1.d) then begin
      message, 'Reshape value not valid. Chose value between 0 and 1.', /continue
      return
    endif else resh=double(resh)
  endelse

  ;
  ; if rshspec is setted don't overlap on spec
  if arg_present(rshspec) then ovrwrt_spec=0 else ovrwrt_spec=1
  ;
  ; if rshpeak is setted don't overlap on spec
  if arg_present(rshpeak) then ovrwrt_peak=0 else ovrwrt_peak=1
  
  ;
  if gof eq !null then begin
    gof = 'MERIT' ; consider MERIT as default
  endif else begin
    if isa(gof,/string) then begin
      gof = strupcase(gof)
      if n_elements(gof) gt 1 then begin
        print, 'Only one criterium allowed for gof.'
        return
      endif else begin
        ;
        ; check if selected criterium is among the implemented ones
        gof_good = total(gof eq ['CKS','AIC','MERIT'])
        ;
        if not gof_good then begin
          print, 'The gof string is not valid.'
          return
        endif
      endelse
    endif else begin
      print, 'The gof entry must be a string.'
      return
    endelse
  endelse
  
  
  ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ;
  ; ; N.B. The following section could be extended  ; ;
  ; ;   adding other smoothing methods or models.   ; ;
  ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ;
  ; 
  ; number of smoothing procedure
  nsmooth = 5
  ;
  ; numer of models
  nmodels = 4
  ;
  asmooth = make_array(nsmooth,1, value=0) ; array of smooth
  amodels = make_array(1,nmodels, value=0) ; array of models
  ;
  ; define smoothings
  smth_label = ['raw spectrum (raw)', $
                'spectrum running median (med)', $
                'log-window spectrum running median (mlog)', $
                'binned spectrum (bin)', $
                'butterworth smoothed spectrum (but)']
  if smoothing eq !null then begin
    asmooth=[1,0,0,0,0] ; consider only raw as default
  endif else if isa(smoothing,/string) then begin
    smoothing = strlowcase(smoothing)
    if total(strcmp(smoothing,'all')) then begin
      asmooth++        
    endif else begin
      if total(strcmp('raw',smoothing)) then asmooth[0]++
      if total(strcmp('med',smoothing)) then asmooth[1]++
      if total(strcmp('mlog',smoothing)) then asmooth[2]++
      if total(strcmp('bin',smoothing)) then asmooth[3]++
      if total(strcmp('but',smoothing)) then asmooth[4]++
      if (total(asmooth) eq 0) then begin
        message, 'The smoothing selection is not valid.', /continue
        return
      endif
    endelse
  endif else if (min(smoothing) ge 0) and (max(smoothing) lt nsmooth) then begin
    asmooth[smoothing]++
  endif else if (smoothing eq 9) then begin
    asmooth++
  endif else begin
    message, 'The smoothing selection is not valid.', /continue
    return
  endelse
  if (pltsm eq 1) and (total(asmooth[1:-1]) eq 0) then begin
    message, 'Select at least one smoothing approach (not raw).', /continue
    return
  endif
  ;
  ; define models
  modl_label = ['white noise (wht)', $
                'power law (pl)', $
                'lag-one autoregressive process (ar1)', $
                'bending power law (bpl)']
  if model eq !null then begin
    amodels=[0,0,0,1] ; consider bpl as default
  endif else begin
    if isa(model,/string) then begin
      model = strlowcase(model)
      if total(strcmp(model,'all')) then begin
        amodels++
      endif else begin
        if total(strcmp('wht',model)) then amodels[0]++
        if total(strcmp('pl',model)) then amodels[1]++
        if total(strcmp('ar1',model)) then amodels[2]++
        if total(strcmp('bpl',model)) then amodels[3]++
        if (total(amodels) lt n_elements(model)) then begin
          message, 'The model selection is not valid.', /continue
          return
        endif
      endelse
    endif else begin
      if (min(model) ge 0) and (max(model) lt nmodels) then begin
        amodels[model]++
      endif else if (model eq 9) then begin
        amodels++
      endif else begin
        message, 'The model selection is not valid.', /continue
        return
      endelse
    endelse
  endelse
  specproc = asmooth # amodels
  
  ;
  ; smoothing percentage, set default to optimal window
  if psmooth eq !null then begin
    ; smooth the power spectral density with the optimal window
    ; according to the Kolmogorov-Smirnov test
    psmooth = 2
  endif else begin
    ; check if psmooth is valid
    if (psmooth lt 0.0) or (psmooth gt 1.0) then begin
      message, 'The psmooth value is not valid.', /continue
      return
    endif else begin
      ; check if the corresponding fsmooth is lower than the bandwidth
      fsmooth = double(frange * psmooth)
      if fsmooth lt bndwdth then psmooth = bndwdth/frange
    endelse
  endelse
  
  ;
  ; define the procedure in findpeaks
  peakproc = make_array(4,1, value=0)
  if procpeak eq !null then begin
    peakproc = [1,1,1,1] ; search for peaks with all procedures
  endif else begin
    ; if we pass the string
    if isa(procpeak,/string) then begin
      procpeak = strlowcase(procpeak)
      if total(strcmp('all',procpeak)) then begin
        peakproc++
      endif else begin
        if total(strcmp('gt',procpeak)) then peakproc[0]++
        if total(strcmp('ft',procpeak)) then peakproc[1]++
        if total(strcmp('gft',procpeak)) then peakproc[2]++
        if total(strcmp('gftm',procpeak)) then peakproc[3]++
        if (total(peakproc) lt n_elements(procpeak)) and $
          not(total(strcmp('',procpeak))) then begin
          message, 'The procpeak selection is not valid.', /continue
          return
        endif
      endelse
    endif else begin
      if (min(procpeak) ge 0) and (max(procpeak) lt 4) then begin
        peakproc[procpeak]++
      endif else if (procpeak eq 9) then begin
        peakproc++
      endif else begin
        message, 'The procpeak selection is not valid.', /continue
        return
      endelse
    endelse
  endelse
  
  if quiet eq !NULL then quiet = 0

  ;
  ;##################################################################################
  ;                         calculate the eigentapers
  ;##################################################################################
  ;
  ; If user has passed in dpss, then don't compute it again (for speed)
  if dpss eq !NULL then begin
    if not quiet then print, 'Calculating dpss ...'
    ;
    if npts gt 5000 then begin
      message, 'The current spd_dpss.pro module is computational expensive '+ $
        'when the time series have more than 5000 points. '+ $
        'Consider generating the dpss structure from the spd_dpss.pro module '+ $
        'and specify it as an input: spd_mtm, data=data, dpss=dpss', /continue
      return
    endif else if npts gt 1000 then begin
      print, 'The time series has more than 1000 points.' + $
        ' Consider saving the dpss structure to save time ...'
    endif
    ;
    ; evaluate dpss
    dpss = spd_mtm_dpss(npts, NW, Ktpr)
    ;
    if not quiet then print, 'Done. Number of points='+string(npts, format='(I0)')+ $
      ', NW='+string(NW, format='(I0.1)')+', K='+string(Ktpr, format='(I0)')
  endif else begin
    ;
    ; check if the windows are good for the data
    if npts ne dpss.N then begin
      print, 'Length of data and tapers does not match.'
      return
    endif
    NW = dpss.NW
    Ktpr = dpss.K
  endelse
  tprs = dpss.E
  V = dpss.V

  ;
  ;##################################################################################
  ;                                 SPD_MTM
  ;##################################################################################
  ;
  par = {npts:npts, dt:dt, dtsig:dtsig, datavar:datavar, fray:fray, fny:fny, $
    npad:npad, nfreq:nfreq, df:df, fbeg:fbeg, fend:fend, psmooth:psmooth, $
    conf:conf, NW:NW, Ktpr:Ktpr, tprs:tprs, V:V}
  
  ipar = {hires:hires, power:power, specproc:specproc, peakproc:peakproc, $
    allpkwd:allpkwd, pltsm:pltsm, resh:resh, gof:gof}
  
  ;
  ; power spectral density and F-test
  spd_mtm_spec, data = demean, par=par, ipar=ipar, spec=spec
  ; if NaN are present in the PSD, exit
  if total(finite(spec.raw, /NaN)) then begin
    print, 'Adaptive MTM PSD has invalid values. Check the time series.'
    return
  endif
  
  ;
  ; harmonic F test
  spd_mtm_regre, spec=spec, par=par
  
  ;
  ; smoothing of the power spectral density
  spd_mtm_smoothing, spec=spec, par=par, ipar=ipar
  
  ;
  ; if pltsmooth is not selected, procede with the analysis
  ; otherwise show only the smoothings
  if not ipar.pltsm then begin
    
    ;
    ; fit power spectral density models
    spd_mtm_fitmodel, spec=spec, par=par, ipar=ipar, demean=demean
  
    ;
    ; evaluate goodness of fit for multiple background models
    spd_mtm_modelgof, spec=spec, ipar=ipar
    
    ;
    ; define confidence level for the power spectral density
    ; and the harmonic F test
    spd_mtm_confthr, spec=spec, par=par
    
    ;
    ; find periodic signals
    spd_mtm_findpeaks, spec=spec, par=par, ipar=ipar, peak=peak
    
    ;
    ; reshape power spectral density
    if ipar.resh gt 0 then begin
      ;
      ; evaluate reshaped spectrum and the spectral peaks
      spd_mtm_reshape, spec=spec, par=par, ipar=ipar, peak=peak, $
        demean=demean, rshspec=rshspec, rshpeak=rshpeak
      ; 
      ; overwrite the results on spec and peak if selected
      if ovrwrt_spec then spec = rshspec
      if ovrwrt_peak then peak = rshpeak
      ;
    endif
    
    ;
    ; display parameters
    if not quiet then begin
      spd_mtm_dispar, smth_label, modl_label, par, ipar, spec
    endif
  
  endif
  
  ; output format
  if not keyword_set(double) then begin
    spd_mtm_dbl2flt, spec=spec, par=par, peak=peak, $
                     rshspec=rshspec, rshpeak=rshpeak
  endif
  
  ;
  ; plot result
  if keyword_set(makeplot) then begin
    ;
    if x_label eq !null then x_label='Time'
    ;
    spd_mtm_makeplot, data=[data[0,*], demean0], $
                  spec=spec, peak=peak, par=par, ipar=ipar, $
                  x_label=x_label, x_units=x_units, $
                  y_units=y_units, f_units=f_units, $
                  x_conv=x_conv, f_conv=f_conv
  endif
  
end