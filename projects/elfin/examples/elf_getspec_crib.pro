;
; Shows how to operate on EPDE data to get spectrograms (energy-time, angle-time) or E,A,time structures.
; It also shows how to obtain precipitating and trapped electron spectra. (EPDI can be treated similarly, but not done yet.)
; Code explains how to obtain uncertainty estimates on counts, enabling masking statistically insignificant bins
; 
; To execute type: elf_getspec_crib and hit .c at each stop to continue
;
; Revision: 2020/11/10 (VA) 
; - added calls to reload epd prior to elf_getspec when units changed!
; - changed event to the one published in ELFIN mission paper, publicly available
; Change history: First release, Vassilis 2020/11/01
;
pro elf_getspec_crib
;
  elf_init
  tplot_options, 'xmargin', [20,9]
;  cwdirname='C:\My Documents\ucla\Elfin\science\analysis' ; your directory here, if other than default IDL dir
;  cwd,cwdirname
;
; pick an event; here from 2019-09-27 storm on EL-A
; 
 tstart='2019-09-28/16:19:00' ; <- this is the ELFIN mission paper event, Fig. 21
 tend='2019-09-28/16:22:00'   ; <- this is the ELFIN mission paper event, Fig. 21
 ; tstart='2020-04-22/05:43:50' ; <--- uncommend this to plot a different event
 ; tend='2020-04-22/05:48:30'   ; <--- uncommend this to plot a different event
 time2plot=[tstart,tend]
 timeduration=time_double(tend)-time_double(tstart)
 timespan,tstart,timeduration,/seconds ; set the analysis time interval
;
 sclet='a'
;
; first you may wish to load the state data (position and attitude); this is not required
; for plotting spectra but may be needed for plotting X-axis annotations (MLT, LAT etc).
; elf_load_state, probes=[sclet]
;
; This shows the simplest form of the call sequence which takes advantage of default settings
;
elf_load_state,probe=sclet ; you must load ELFIN's position and attitude data the first time (probe='a' which is also the default)
elf_load_epd,probe=sclet,datatype='pef' ; you must first load the EPD data, here, for further use (default is ELFIN-A 'a', 'e', and 'nflux'
elf_getspec,probe=sclet,datatype='pef' ; get some spectra (default is 'a',species='e' (or datatype='pef'),type='nflux'  <- note these MUST match the previous call
; 
tplot,['*en_spec2plot*','*pa_spec2plot_ch?LC']
;
print,'*********************************************************************************'
print,'This shows how to introduce and plot energy and pitch-angle spectra the fastest way'
print,'Default ch[1-3] energy ranges are [[50.,160.],[160.,345.],[345.,900.],[900.,7000.]]'
print,'Default quantities introduced are in units of !!!number flux!!!, as shown here          '
print,'*********************************************************************************'
;
stop
;
; if you want another type you MUST reload the data and call elf_getspec again!
elf_load_epd, probes=sclet, datatype='pef', level='l1', type = 'eflux' ; loads energy flux (could be 'raw', 'cps', or default: 'nflux')
; get regularized spectra (at fixed, regular pitch angles) at half-spin (max) resolution
elf_getspec,/regularize,probe=sclet,type = 'eflux' ; note, you must use getspec for the same type as loaded!!
;
; plot the non-regularized data 
zlim,'el?_p?f_en*spec*',1e4,1e9,1
zlim,'el?_pef_pa_*spec2plot_ch0*',5.e5,1.e9,1
zlim,'el?_pef_pa_*spec2plot_ch1*',5.e5,5.e8,1
zlim,'el?_pef_pa_*spec2plot_ch2*',5.e5,2.5e8,1
zlim,'el?_pef_pa_*spec2plot_ch3*',1.e5,1.e7,1
ylim,'*pa*spec2plot*',-5.,185.,0
;
tplot,'ela_pef_'+['en_spec2plot_omni','en_spec2plot_anti','en_spec2plot_perp','en_spec2plot_para', + $
  'pa_spec2plot_ch[0-3]LC']
;
print,'*********************************************************************************'
print,'This shows how to plot energy spectra and pitch-angle spectra at Tspin/2 resolution'
print,'without angle interpolation (not regularized). Here data were read in !!!eflux!!! units'
print,'*********************************************************************************'
;
stop
;
; plot the regularized quantities (obtained with keyword regularized in elf_getspec)
; Note that you need not use the regularized keyword above, and the routine will go faster)
; 
; The spin sector centers are also shifted by an angle that is read from the
; calibration file. The values, as used, can be plotted for reference in the title
; and compared with the online plots to ensure consistency. This is also shown here.
; 
myphasedelay = elf_find_phase_delay(probe=sclet, instrument='epde', trange=[tstart,tend])
mysect2add=myphasedelay.DSECT2ADD
mydSpinPh2add=myphasedelay.DPHANG2ADD
mytitle='el'+sclet+'_pef dSect='+strtrim(mysect2add,1)+' dSpinPh='+strtrim(mydSpinPh2add,1)
;
tplot,'ela_pef_'+['en_reg_spec2plot_omni','en_reg_spec2plot_anti','en_reg_spec2plot_perp','en_reg_spec2plot_para', + $
  'pa_reg_spec2plot_ch[0-3]LC'],title=mytitle
;
print,'****************************************************************************************'
print,'This shows regularized energy and pitch-angle spectra at Tspin/2 resolution
print,'(pitch-angle inter/extrapolated at regular angles), pre-computed also in the same call.'
print,'This option may result in artificial values, especially poorly constrained for low counts'
print,'******************************************************************************************'
;
stop
;
; You can calculate and plot the normalized para-to-perp and anti-to-perp ratios (for either reg or non-reg)
; 
calc," 'ela_pef_en_reg_spec2plot_paraovrperp' = 'ela_pef_en_reg_spec2plot_para' / 'ela_pef_en_reg_spec2plot_perp' "
zlim,'ela_pef_en_reg_spec2plot_paraovrperp',0.01,2.,1.
calc," 'ela_pef_en_reg_spec2plot_antiovrperp' = 'ela_pef_en_reg_spec2plot_anti' / 'ela_pef_en_reg_spec2plot_perp' "
zlim,'ela_pef_en_reg_spec2plot_antiovrperp',0.01,2.,1.
;
tplot,'ela_pef_'+['en_reg_spec2plot_omni','en_reg_spec2plot_anti','en_reg_spec2plot_perp','en_reg_spec2plot_para', + $
  'en_reg_spec2plot_paraovrperp','en_reg_spec2plot_antiovrperp', + $
  'pa_reg_spec2plot_ch[0-3]LC']
;
print,'*********************************************************************************'
print,'Now para/perp and anti/perp spectrograms are also shown in the middle two panels'
print,'*********************************************************************************'
stop
;
; You can change the energies included in the energy spectra 
; and the range of pitch-angle angles included in the para and perp spectra and their ratios
; to non-default ones...
; note: you do not have to reload the data again as they were loaded with type='eflux' last.
myenergies=[[50.,100.],[100.,150.],[150.,250.],[250.,400.],[400.,600.],[600.,900.]] ; these are the energies I want
myLCpartol=22.5+11.25 ; my tolerance to use in para and anti: excludes pitch-angles that are closer than myLCpartol from the Loss Cone Edge
elf_getspec,probe=sclet,type = 'eflux',energies=myenergies,/regularize,LCpartol2use=myLCpartol; note, you must use getspec for the same type as loaded!!
;
; recalculate normalized spectra for new limits
calc," 'ela_pef_en_reg_spec2plot_paraovrperp' = 'ela_pef_en_reg_spec2plot_para' / 'ela_pef_en_reg_spec2plot_perp' "
zlim,'ela_pef_en_reg_spec2plot_paraovrperp',0.01,2.,1.
calc," 'ela_pef_en_reg_spec2plot_antiovrperp' = 'ela_pef_en_reg_spec2plot_anti' / 'ela_pef_en_reg_spec2plot_perp' "
zlim,'ela_pef_en_reg_spec2plot_antiovrperp',0.01,2.,1.
;
; show quantities
tplot_names,'*pa_reg_spec2plot_ch?LC*'
print,'*********************************************************************************'
print,'Showing new quantities...
print,'*********************************************************************************'
;
stop
; replot all energy and angle spectrograms (here for regularized)
;
zlim,'el?_pef_pa_*spec2plot_ch0*',5.e5,1.e9,1
zlim,'el?_pef_pa_*spec2plot_ch1*',5.e5,5.e8,1
zlim,'el?_pef_pa_*spec2plot_ch2*',5.e5,2.5e8,1
zlim,'el?_pef_pa_*spec2plot_ch3*',2.e5,5.e7,1
zlim,'el?_pef_pa_*spec2plot_ch4*',1.e5,2.e7,1
zlim,'el?_pef_pa_*spec2plot_ch5*',5.e4,1.e7,1
tplot,'ela_pef_'+['en_reg_spec2plot_omni','en_reg_spec2plot_anti','en_reg_spec2plot_perp','en_reg_spec2plot_para', + $
  'en_reg_spec2plot_paraovrperp','en_reg_spec2plot_antiovrperp', + $
  'pa_reg_spec2plot_ch?LC']
;
print,'*********************************************************************************'
print,'Shows multiple energies and user-controled loss-cone restrictions'
print,'*********************************************************************************'
;
stop
;
; You can roughly double the angular resolution at the expense of halfing the time resolution
; This is done using keyword /fullspin which produces max number of sectors (typ. 16) each full spin
; This only "roughly" doubles the angles because the pitch angles up-going (0->180) are not half-way
; of those down-going (180 -> 0) during the spin because the sectors are not starting always at 0 or 90.
; This is because of a quirk of the design that introduces some unknown time offset each time the
; instrument is turned ON, and the offset is computed on the ground by matching the up and down spectra near PA=90deg.
; Worst case, the up and down sets of pitch angles could be identical, which gives no benefit.
; As of ~Feb 2020 it was found that by controlling the spin rate we could make the offset vary only a few degrees
; and we set an offset in space to control the start time to be within the most probable sector. Since then the
; variation is on the order of +/-6deg (assuming spin rate is operationally kept to within +/- 0.25RPM, as it typically is).
; So using /fullspin you get sometimes angles that are separated by less than 22.5deg, maybe even 11.25deg but typically
; alternate between x and (22.5-x), where x can be 0 to 11.25. Another reason why /fullspin is useful is that it
; produces each spin supplementary parallel and antiparallel pitch-angles (their sum is 180.) which is useful for
; comparing up-and-down fluxes of exactly opposing pitch-angles (you do not have to rely on regularization for that).
; 
; However if you use /fulspn at times of rapid flux variations (when time-resolution is important) the up-ward and down-ward
; halfs of the spin will have different fluxes and alternating pitch-angles can have vastly different flux since they were 
; acquired at 1.5s apart, a large time compared to the timescale of flux variation. This will be evident as a picket-fence
; look in the fulspn plots, which is not unphysical but just represents time-aliasing. This picketfence look is absent
; from half-spin data not because the time-aliasing is not there (between up-and-down fluxes there is still significant time-difference)
; but because (1) consecutive sectors are obtained in close time-proximity to each other and (2) there is no way to tell how much
; of the difference at distant sectors (say 0. and 180. deg) is due to true instantaneous anisotropy as opposed to time-variability.
; 
; note: you do not have to reload the data again as they were loaded with type='eflux' last.
elf_getspec,probe=sclet,type = 'eflux',/fullspin,/regularize ; (default energies) produces quantities: '*_fulspn_*'
;
tplot_names,'*_fulspn_*'
;
tplot,'ela_pef_'+['en_fulspn_spec2plot_omni','en_fulspn_spec2plot_anti','en_fulspn_spec2plot_perp','en_fulspn_spec2plot_para', + $
  'pa_fulspn_spec2plot_ch[0-3]LC']
;
print,'*********************************************************************************'
print,'Shows use of fulspin keyword providing high-angle resolution spectra - not regularized.
print,'*********************************************************************************'
;
stop
;
; You can also use the /regularized keyword in the above call (you get both _reg_ and non-reg spectra at the same time
; The regularized spectra result in even distribution of angles at twice the angular resulution relative to half-spin spectra
; They have been regularized in spin-phase and the center pitch-angles are appropriately determined
; These now mask any evidence of time-alias but they appear smooth. At times of rapid variations this gives false sense of security
; At times of medium or low flux variation the regularization produces more evenly-spaced data in pitch-angle spectra
; Notice, however, that regularization of low fluxes produces non-zero values which is not real and below confidence level.
;
tplot,'ela_pef_'+['en_reg_fulspn_spec2plot_omni','en_reg_fulspn_spec2plot_anti','en_reg_fulspn_spec2plot_perp','en_reg_fulspn_spec2plot_para', + $
  'pa_reg_fulspn_spec2plot_ch[0-3]LC']
;
print,'*********************************************************************************'
print,'Shows use of fulspin keyword providing high-angle resolution spectra, regularized.
print,'*********************************************************************************'
stop
;
; The low count fluxes can be and should be removed by putting limits on what count level is acceptable based on number of counts.
; Here we show how this is done for the last plotted products (*reg_fulspn*). First load the raw counts (not cps but tot.counts per bin).
; For the products of interest compute fractional error in each bin =1/sqrt(counts in bin). Then use that to constrain the data
; and make low-count points NaNs so they dont appear on the plot.
;
elf_load_epd,probe=sclet,datatype='pef',type='raw'
elf_getspec,probe=sclet,type='raw',/fullspin,/regularize ; now the tplot variables contain raw counts, not eflux
; Use these raw counts to produce the df/f error estimate = 1/sqrt(counts) for all quantities you need to. Use calc with globing:
calc," 'ela_pef_en_reg_fulspn_spec2plot_????_err' = 1/sqrt('ela_pef_en_reg_fulspn_spec2plot_????') " ; <-- what I will use later, err means df/f
calc," 'ela_pef_pa_reg_fulspn_spec2plot_ch?_err' = 1/sqrt('ela_pef_pa_reg_fulspn_spec2plot_ch?') " ; <-- same for angle spectrograms
; reload in eflux units now (two calls: first load data, then compute spectra)
elf_load_epd,probe=sclet,datatype='pef',type='eflux'
elf_getspec,probe=sclet,type = 'eflux',/fullspin,/regularize ; reload eflux... 
; now clean up quantities
quants2clean='ela_pef_en_reg_fulspn_spec2plot_'+['perp','omni','para','anti'] ; array of tplot names of energy spectrograms
quants2clean=[quants2clean,'ela_pef_pa_reg_fulspn_spec2plot_ch'+['0','1','2','3']] ; append array of angle spectrograms
errmax2use=0.5 ; this means % max error is df/f=100*errmax2use 
foreach element, quants2clean do begin
  error2use=element+'_err'
  copy_data,element,'quant2clean'
  copy_data,error2use,'error2use'
  get_data,'quant2clean',data=mydata_quant2clean,dlim=mydlim_quant2clean,lim=mylim_quant2clean
  ntimes=n_elements(mydata_quant2clean.y[*,0])
  nsectors=n_elements(mydata_quant2clean.y[0,*])
  mydata_quant2clean_temp=reform(mydata_quant2clean.y,ntimes*nsectors)
  get_data,'error2use',data=mydata_error2use
  mydata_error2use_temp=reform(mydata_error2use.y,ntimes*nsectors)
  ielim=where(abs(mydata_error2use_temp) gt errmax2use, jelim) ; this takes care of NaNs and +/-Inf's as well!
  if jelim gt 0 then mydata_quant2clean_temp[ielim] = !VALUES.F_NaN ; make them NaNs, not even zeros
  mydata_quant2clean.y = reform(mydata_quant2clean_temp,ntimes,nsectors) ; back to the original array
  store_data,'quant2clean',data=mydata_quant2clean,dlim=mydlim_quant2clean,lim=mylim_quant2clean
  copy_data,'quant2clean',element ; overwrites the previous data in the tplot variable
endforeach
;
tplot ; this replots the previous plot but now the low-count points (fractional err> 100.*errmax2use %) have been removed
; same as above just verbose:
;tplot,'ela_pef_'+['en_reg_fulspn_spec2plot_omni','en_reg_fulspn_spec2plot_anti','en_reg_fulspn_spec2plot_perp','en_reg_fulspn_spec2plot_para', + $
;  'pa_reg_fulspn_spec2plot_ch[0-3]LC']
;
print,'*********************************************************************************'
print,'Shows use of raw counts for removing low-confidence points.
print,'*********************************************************************************'
;
;
stop
;
end
