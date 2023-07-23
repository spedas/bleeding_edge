SPD_MTM: a spectral analysis tool for the SPEDAS framework.
© Simone Di Matteo, 2020

SPD_MTM is a stand-alone software developed at NASA - Goddard Space Flight Center using the IDL Version 8.4, (c) 2014, Exelis Visual Information Solutions, Inc.
This is a new spectral analysis method for the identification of periodic signals in geophysical time series. We evaluate the power spectral density with the adaptive multitaper method, a sophisticated non-parametric spectral analysis technique suitable for time series characterized by colored power spectral density. Our method provides a maximum likelihood estimation of the power spectral density background according to four different models. It includes the option for the models to be fitted on four smoothed versions of the power spectral density when there is a need to reduce the influence of power enhancements due to periodic signals. We use a statistical criterion to select the best background representation among the different smoothing+model pairs. Then, we define the confidence thresholds to identify the power spectral density enhancements related to the occurrence of periodic fluctuations. We combine the results with those obtained with the multitaper harmonic F test, an additional complex-valued regression analysis from which it is possible to estimate the amplitude and phase of the signals. The name SPD_MTM comes from the implementation of this software in the SPEDAS (Space Physics Environment Data Analysis Software) framework, but the code is stand alone and has no dependencies on the main repository.

This code is licensed under the Apache 2.0 license; you are free to use, modify, and redistribute it, but you must abide by the terms in this license.

In addition to that legal obligation, if you use this code in calculations for an academic publication, you have an academic obligation to cite it correctly. For that purpose, please cite the following publication and provide a direct citation to the code such as:

	Di Matteo, S., Viall, N., Kepko, L. (2020), Power Spectral Density Background Estimate and Signals Detection via the Multitaper Method. Journal of Geophysical Research-Space Physics.

	Di Matteo, S., Viall, N., Kepko, L. (2020), SPD_MTM: Multitaper spectral analysis tool for the SPEDAS framework. Zenodo. http://doi.org/record/3703168


The compressed file spd_mtm.zip contains:
- the software files;
- the README.txt file;
- the NOTICE.txt file,
- the License.txt file;
- the spd_mtm_v1_help.html help page.


#################################################################
#################################################################
###							      ###
###   INPUTS and OUTPUTS for the main procedure SPD_MTM.pro   ###
###							      ###
#################################################################
#################################################################
spd_mtm.pro

 ;;;;;;;;;;;;
 ;; inputs ;;
 ;;;;;;;;;;;;
      data - 2 column data: [time vector, time series]
             N.B. The average value of the data is removed by default.
             If the data are not evenly sampled, the average time step
             is used when it is lower than its standard deviation.
        NW - time-halfbandwidth product, DEFAULT: NW = 3
      Ktpr - Number of tapers to apply, DEFAULT: Ktpr = 2*NW - 1
   padding - Amount of padding to apply (proportional to the original data)
             DEFAULT: padding=1 so that the frequency step (df)
             equals the Rayleigh frequency [1/(N*dt)]
      dpss - structure with tapers and eigenvalues
             evaluated by spd_mtm_dpss.pro or previous call of spd_mtm.pro
      flim - limits in percentages of the frequency range to be analyzed,
             DEFAULT: [df,fny-df], where fny is the Nyquist frequency [1/(2*dt)]
 smoothing - possible smoothing:
             'raw'(0) no smoothing (DEFAULT)
             'med'(1) running median
             'mlog'(2) running median (constant window on log(f) )
             'bin'(3) binned PSD
             'but'(4) low pass filtered PSD (Butterworth filter)
             'all'(9) use all the smoothing procedures
   psmooth - value between (0,0.5] defining the "smoothing window"
             psmooth=2 -> search the optimum window according
                          to the Kolmogorov-Smirnov test (DEFAULT)
    model  - implemented models:
             'wht'(0) white noise, [N]
             'pl'(1) power law, [N, beta]
             'ar1'(2) first order autoregressive process, [N, rho]
             'bpl'(3) bending power law, [N, beta, gamma, fb] (DEFAULT)
             'all'(9) use all the models
  procpeak - possible choices:
             '' do not search for peaks
             'gt'(0) gamma test only
             'ft'(1) F test only
             'gft'(2) gamma and F test
             'gftm'(3) only max F value for each PSD enhancement
             'all'(9) use all the selection procedures (DEFAULT)
      conf - confidence levels in increasing order
             (DEFAULT is conf=[0.90,0.95,0.99])
      resh - value between (0,1.0], reshape the PSD from peaks identified
             according to the 'gft' procedure at the "resh" confidence level
             (DEFAULT: resh=0, do not perform the reshaping)
       gof - PSD background chosing criterium:
             'MERIT' - MERIT function (DEFAULT)
             'CKS' - Kolmogorov-Smirnov test
             'AIC' - Akaike Information Criteria
     
   x_label - label for x-axis or defined set of choice
             (default choice 'Time', see spd_mtm_makeplot.pro)
   x_units - x variable unit of measures
   y_units - y variable unit of measures
   f_units - "frequency" variable unit of measures
    x_conv - conversion factor for the x variable
             (N.B. IS UP TO THE USER TO BE CONSISTENT WITH X_UNITS)
    f_conv - conversion factor for the "frequency" variable
             (N.B. IS UP TO THE USER TO BE CONSISTENT WITH F_UNITS)
 
 ;;;;;;;;;;;;;;;;;;;;;;
 ;; COMMON VARIABLES ;;
 ;;;;;;;;;;;;;;;;;;;;;;

     max_lklh
          psd_ml - PSD for the maximum likelihood model fit
           ff_ml - frequency vector for the maximum likelihood model fit
        alpha_ml - half degree of freedom of the PSD at each frequency
             fny - Nyquist frequency
            itmp - indices of the frequency interval of interest
          n_itmp - number of frequencies in the interval of interest

     gammaj
        alpha_gj - half degree of freedom of the PSD at each frequency
            Ktpr - number of tapers (max value is 2*NW - 1)
	      pp - confidence threshold percentage
     gamj_cdf_xx - CDF at fixed gamma values
              xx - fixed gamma values (cover up to Ktpr=20)

 ;;;;;;;;;;;;;;
 ;; Keywords ;;
 ;;;;;;;;;;;;;;
     /hires - spec.raw is the high-resolution PSD estimate
     /power - spec.raw is the integrated PSD: df*PSD [##^2]
     /quiet - do not display parameters and results
     /allpeakwidth - no constrains on the PSD enhancements width
     /pltsmooth - plot only the smoothed PSDs and stop
     /makeplot - plot the results
     /double - output in double precision
 
 ;;;;;;;;;;;;;;;;;;;;;;;
 ;; output structures ;;
 ;;;;;;;;;;;;;;;;;;;;;;;

   spec.         
       .ff       Fourier frequencies
       .raw      adaptive multitaper PSD
       .back     best PSD background among the probed ones
       .ftest    values of the F test
       .resh     reshaped PSD (if resh in spd_mtm is imposed) 
       .dof      degree of freedom at each Fourier frequency
       .fbin     binned frequencies for the bin-smoothed PSD
       .smth     smoothed PSD, spec.smth[#smth, *]:
                 #smth = 0->'raw'; 1->'med'; 2->'mlog', 3->'bin'; 4->'but'
       .modl     PSD background models, spec.modl[#smth, #modl, *]:
                 #modl = 0->'wht'; 1->'pl'; 2->'ar1'; 3->'bpl'
       .frpr     model parameters resulting from the fitting procedures
                 spec.frpr[#smth, #modl, #par]:
                 #par = 0->'c'; 1->'rho' or 'beta'; 2->'gamma'; 3->'fb'
       .conf     confidence threshold values for the PSD (gamma test)
       .fconf    confidence threshold values for the F statistic (F test)
       .CKS      C_KS value for each probed model spec.CKS[#smth, #modl]
       .AIC      AIC value for each probed model spec.AIC[#smth, #modl]
       .MERIT    MERIT value for each probed model spec.MERIT[#smth, #modl]
       .Ryk      real part of the eigenspectra spec.Ryk[#Ktpr,*]
       .Iyk      imaginary part of the eigenspectra spec.Iyk[#Ktpr,*]
       .psmooth  percentage of the frequency range defining
                 the smoothing window spec.psmooth[#smth]
       .muf      complex amplitude at each Fourier frequency
       .indback  indices of the selected PSD background;
                 smoothing/model = spec.indback[0]/spec.indback[1]
       .poor_MTM flag for failed convergence of the adaptive MTM PSD
     
   peak.          
       .ff       Fourier frequencies
       .pkdf     for each peak selection method and confidence level 
                 a value greater than zero at a specific frequency
                 indicate the occurence of a signal at that frequency:
                 peak.pkdf[#peakproc, #conf, #freq]
                 'gamma test' -> peak.pkdf[0,*,*] contains the badwidth
                 of the PSD enhancements at the identified frequencies
              	  'F test', 'gft', and 'gftm' -> peak.pkdf[1:3,*,*]
                 is equal to par.df at the identified frequencies
     		  
    par.	  
       .npts     time series number of points
       .dt       average sampling time
       .dtsig    standard deviation of the sampling time
       .datavar  variance of the time series
       .fray     Rayleigh frequency: fray = 1/(npts*dt)
       .fny      Nyquist frequency: fny = 1/(2*dt)
       .npad     time series number of points after padding
       .nfreq    number of frequencies
       .df       frequency resolution (after padding), it corresponds to
                 the Rayleigh frequency for no padding (padding = 1)
       .fbeg     beginning frequency of the interval under analysis
       .fend     ending frequency of the interval under analysis
       .psmooth  value imposed in spd_mtm
       .conf     confidence thresholds percentages
       .NW       time-halfbandwidth product
       .Ktpr     number of tapers (max value is 2*NW - 1)
       .tprs     discrete prolate spheroidal sequences (dpss)
       .v        dpss eigenvalues
      
   ipar.
       .hires    keyword /hires is selected (1) or not (0)
       .power    keyword /power is selected (1) or not (0)
       .specproc array[#smth,#modl] smoothing and model combinations
                 1 (0) the smoothing + model combination is (not) probed
       .peakproc array[4] referring to 'gt', 'ft', 'gft', and 'gftm'
                 1 (0) peaks according to this procedure are (not) saved
       .allpkwd  keyword /allpeakwidth is selected (1) or not (0)
       .pltsm    keyword /pltsmooth is selected (1) or not (0)
       .resh     confidence threshold percentage chosen to select the
                 PSD enhancements to be removed in the PSD reshaping
       .gof      criterium used to select the PSD background
       
   rshspec  provide the spec structures based on the reshaped PSD
            (If it is not specified, the results are overwritten on spec)
            
   rshpeak  provide the peak structures based on the reshaped PSD
            (If it is not specified, the results are overwritten on peak)
 

################
################
##            ##
##  Examples  ##
##            ##
################
################

     t = [0:511] ; time vector, suppose dt = 1s
     x = 0.5*cos(2.0*!pi*t/8.0) + randomn(3,512,1) ; time series
     data = [[t],[x]]
     
     spd_mtm, data=data, NW=3, Ktpr=5, padding=1, dpss=dpss, $
              flim=[0,1], smoothing=’all’, psmooth=2, $
              model=’wht’, procpeak=[’gt’,'gft'], $
              conf=[0.90,0.95d], $
              /makeplot, $
              x_label=’Time’, y_units=’##’, $ 
              x_units=’min’, x_conv=1.0/60.0, $
              f_units=’mHz’, f_conv=1d3, $
              spec=spec, peak=peak, par=par, ipar=ipar
     
     ; plot the adaptive MTM PSD
     plot(spec.ff, spec.raw, /ylog)
     
     ; plot the selected PSD background
     plot(spec.ff, spec.back, 'r', /overplot)

     ; plot confidence threshold for the PSD
     plot(spec.ff, spec.back*spec.conf[0], 'r--', /overplot)

     ; plot a smoothed PSD
     ; (N.B. The smoothing approach has to be present the inputs)
     plot(spec.ff, spec.smth[1,*]) ; med
     plot(spec.ff, spec.smth[2,*]) ; mlog
     plot(spec.fbin, spec.smth[3,*]) ; bin
     plot(spec.ff, spec.smth[4,*]) ; but

     ; plot a fitted PSD model on a smoothed PSD
     ; (N.B. The model has to be present the inputs)
     plot(spec.ff, spec.modl[0,0,*]) ; raw/WHT
     plot(spec.ff, spec.modl[3,1,*]) ; bin/PL
     plot(spec.ff, spec.modl[2,2,*]) ; mlog/AR(1)
     plot(spec.ff, spec.modl[3,3,*]) ; bin/BPL

     ; to recover the identified peaks:
     indices_peaks = where(peak.pkdf[0,0,*] gt 0)
     
     ; N.B.
     ; peak.pkdf[0,0,*] -> gamma test, lowest confidence level (from conf)
     ; peak.pkdf[2,0,*] -> gamma and F test, lowest confidence level (from conf)
     ; peak.pkdf[0,-1,*] -> gamma test, highest confidence level (from conf)
     
     if (indices_peaks[0] ge 0) then begin
       signals_frequency = peak.ff[indices_peaks]
     endif

#########################
#########################
## 		       ##
## Additional Comments ##
##                     ##
#########################
#########################
 
1."Slepian sequences"
  The current spd_dpss.pro module is computational expensive
  when the time series have more than 5000 points. Consider
  generating the dpss structure from the spd_dpss.pro module
  and specify it as an input:
  spd_mtm, data=data, dpss=dpss

2."Model parameter intervals"
  The default intervals for the model parameters are:
  PL: 0 < beta < 10
  AR(1): 0 < rho < 1
  BPL: -5 < beta < 10; 0 < gamma < 15; 0 < f_b < 1.0
  (N.B. f_b is expressed in units of Nyquist frequency,
  that is f_b=1 corresponds to f_b=f_Ny)
  
  These intervals can be modified in the
  spd_mtm_fitmodel.pro module.
  (N.B. The constant factor is evaluated with the
  analytical solution for the log-likelihood minimization.)

