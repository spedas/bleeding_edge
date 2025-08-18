;+
;
;THIS CRIB IS DEPRECATED: see thm_crib_sst.pro instead
;
;PROCEDURE: thm_crib_sst_contamination
;Purpose: 1. Demonstrate the basic procedure for removal of sun contamination,
;            electronic noise, and masking.
;         2.. Demonstrate removal of suncontamination via various methods.  
;         3. Demonstrate the correction of inadvertant masking in SST data
;         4. Demonstrate scaling data for loss of solid angle in SST measurements.
;         5. Demonstrate substraction of electronic noise by selecting bins in a specific region
;         6. Show how to use these techniques for both angular spectrograms,energy spectrgrams, and moments.
;
;SEE ALSO:
;  thm_remove_sunpulse.pro(this routine has the majority of the documentation)
;  thm_part_moments.pro, thm_part_moments2.pro, thm_part_getspec.pro
;  thm_part_dist.pro, thm_sst_psif.pro, thm_sst_psef.pro,thm_sst_erange_bin_val.pro
;  thm_crib_part_getspec.pro
;
; To run this crib either copy and paste text into command line or use .run thm_crib_sst_contamination
;
; $LastChangedBy: pcruce $
; $LastChangedDate: 2016-04-15 11:02:08 -0700 (Fri, 15 Apr 2016) $
; $LastChangedRevision: 20831 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/examples/deprecated/thm_crib_sst_contamination.pro $
;-



probe='b'  ;set some variables
hrs = 3.0
sdate='2008-02-26/01:00:00' ;start time
edate=time_string(time_double(sdate)+hrs*3600) ;end time


timespan,sdate,hrs,/hour  ;set times and load data
thm_load_sst,probe=probe

;---------------------------------------------------------------------------------------------------------------------------
; BASIC KEYWORDS: Very basic removal of sun contamination. These examples use as few keywords as possible.
;---------------------------------------------------------------------------------------------------------------------------
; The sun contamination can be seen clearly in this example plot:
;(thb_psif_en_eflux_norm is the energy spectrum, thb_psif_an_eflux_phi_norm is the phi angular spectrum)
thm_part_getspec, probe=probe, trange=[sdate,edate], data_type='psif', suffix='_normal',/autoplot
stop

; To very simply remove the contamination, use the keyword method_clean='automatic'.
; Contaminated bins are filled via interpolation over phi
thm_part_getspec, probe=probe, trange=[sdate, edate], data_type='psif', suffix='_automatic', method_clean='automatic'

tplot,'th'+probe+'_psif_'+['an_eflux_phi_normal','an_eflux_phi_automatic','en_eflux_normal','en_eflux_automatic']
stop

;Basic description of the automatic sun decontamination process follows:
;Note that this is highly configurable. See thm_sst_remove_sunpulse.pro for detailed descriptions of options.
;Manual decontamination is recommended if you want detailed control.
;
;#1 SST Particle Data are summed over energy.(Test can be applied to ion & electron. Due to crosstalk, it will show up in both distributions, despite the film over the electron telescopes.) 
;#2 At each time a modified z-score(standard statistical outlier test) is calculated for each phi out of each group of phis for a particular theta.
;#3 A characteristic z-score is generated for each phi by taking the truncated mean of the z-scores at each phi across time.  
;    (A truncated mean is used instead of a normal mean, because there are single time glitches which create z-scores that are large enough to throw off the characteristic z-score for the entire date)
;#4 Individual phis which have z-scores which are larger than a ten times the characteristic z-score are removed and filled by interpolation across phi. 
;     If a phi fails, all times and energies for that phi are removed.
;#5 Steps 2-4 are repeated, except instead of summing over energy as in #1, the test is applied to energy bin 9 alone.  
;     For phis that fail the test, all energies are removed and interpolated.
;     The reason that a specific test is performed on bin 9 is because earth shine sometimes contaminates only energy bin 9 data.
;     

; To choose yourself which bins to remove, use edit3dbins.
; Plot the standard spectrum with sun contamination 
thm_part_getspec, probe=probe, trange=[sdate,edate], data_type='psif', suffix='_normal',/autoplot

; Run edit3dbins: This will prompt you to use the cursor to select a time on the previous plot. The idea is to select a time
; where the signal is low so that the contaminated bins can be easily seen. e.g. between 2.30 and 2.40.
; Next a plot showing the flux in each angular bin will be displayed. Select the bins with contamination (those with unusually
; high flux) using mouse button 1 (in this case bins 32, 48 for example). The bin number will turn white. Once you have finished
; selecting the bins click mouse button 2 or double-click button 1 (note, the window will remain open even when the interactive mode has exited)
tm = gettime(/c)
edit3dbins,thm_part_dist('th'+probe+'_psif', tm), bins,/log

stop
; Replot the spectrum, passing the bins you have selected and using the keyword method_clean='manual' and sun_bins = the output from edit3dbins
edit3dbins,thm_part_dist('th'+probe+'_psif', tm,method_clean='manual',sun_bins=bins), bins,/log

stop

;You can also set the bins programmatically.  For this data set, this set of bins produces a very clean result. 
bins = dblarr(64)+1 ;allocate variable for bins, with all bins selected
bins[[0,16,30,32,33,34,48,58,55,56]] = 0 ;set of bins to remove

thm_part_getspec, probe=probe, trange=[sdate,edate], data_type='psif', suffix='_manual', method_clean='manual', sun_bins=bins

tplot, ['th'+probe+'_psif_an_eflux_phi_normal','th'+probe+'_psif_an_eflux_phi_automatic','th'+probe+'_psif_an_eflux_phi_manual']

stop

;The default behavior is to interpolate over sun bins.(across phi)
;You can, however, choose to have the data removed from the data set instead.
;To do this set fillin_method='blank'

thm_part_getspec, probe=probe, trange=[sdate,edate], data_type='psif', suffix='_blank', method_clean='automatic',fillin_method='blank'

tplot, ['th'+probe+'_psif_an_eflux_phi_normal','th'+probe+'_psif_an_eflux_phi_automatic','th'+probe+'_psif_an_eflux_phi_manual','th'+probe+'_psif_an_eflux_phi_blank']

stop


;By default data are rem

; Another basic option for removing sun contamination is to use the keyword all_angle_median.
; all_angle_median replaces data with the median calculated over all angles for each energy.
;  This will generally eliminate contamination in some of the moments, but will make 
;  analysis of angular plots impossible. It will also eliminate the velocity moment.

thm_part_moments,probe=probe,instrum=['psif'],mag_suffix='_peif_magf', $
  scpot_suffix='_peif_sc_pot',moments='*', /all_angle_median, $
  trange=[sdate,edate],tplotsuffix='_all_median'
  
tplot, 'th'+probe+'_psif_en_eflux_all_median'
stop

; There is one further basic keyword: scale_sphere. This keyword increases the value of all counts by 16%. 
; This compensates for the inability of the sst to measure directly along the probe geometric Z axis and the inability 
; to measure directly along the probe geometric xy plane.(ie X=0,Y=0,Z = n or X=n,Y=m,Z=0, are SST 'blind spots') 

thm_part_moments,probe=probe,instrum=['psif'],mag_suffix='_peif_magf', $
  scpot_suffix='_peif_sc_pot',moments='*', /scale_sphere, $
  trange=[sdate,edate],tplotsuffix='_scale',method_clean='automatic' ;include automatic keyword because the energy spectragram is extremely contaminated on this interval

tplot, 'th'+probe+'_psif_en_eflux_scale'
stop
;---------------------------------------------------------------------------------------------------------------------------
; ADVANCED KEYWORDS
; --------------------------------------------------------------------------------------------------------------------------

;normal calls to thm_part_getspec for comparison
;this sort of phi plot clearly shows both the 
;contamination and the mask that must be removed
thm_part_getspec, probe=probe, trange=[sdate,edate], theta=[-45,0], $
  data_type='ps?f', angle='phi',erange=[50000,100000], suffix='_norm_t1'  
     
thm_part_getspec, probe=probe, trange=[sdate,edate], theta=[0,45],  $
  data_type='ps?f', angle='phi',erange=[50000,100000], suffix='_norm_t2'
  
;normal call to generate moments for comparison
thm_part_moments,probe=probe,instrum=['ps?f'],mag_suffix='_peif_magf', $
  scpot_suffix='_peif_sc_pot',moments='*',trange=[sdate,edate],tplotsuffix='_norm'

;--------------------------------------------          
;basic sun contamination/electronic noise removal procedure
;NOTE: examples of the different options available are shown further down in the crib
;--------------------------------------------
;First call thm_part_getspec and remove sun contamination/masking

thm_part_getspec, probe=probe, trange=[sdate, edate], $
                  theta=[-45,0], phi=[0,360], $
                  data_type=['psif'], start_angle=0,$
                  angle='phi',method_sunpulse_clean='median',tplotsuffix='_ex1_t1',/mask_remove,/autoplot
                  
;now call edit3d bins with sun contamination removal options
;and select the region between 2:30 and 2:40
;generally you should try to select a region in this step that has low flux
;Now select the bins that have electrical contamination using mouse button 1.
;In this example I selected bins: 32,33,55,56,62
;After the bins have been marked(their bin number should turn white) you can
;exit the interactive mode using mouse button 2 or by double clicking button 1.
;A Caveat:  if you call edit3dbins a second time, the same bins will stay marked,  you can use mouse 1 to unmark marked bins.
edit3dbins,thm_sst_psif(probe=probe, gettime(/c),method_sunpulse_clean='median'), bins  ;thm_crib_part_getspec has more examples on the use of edit3dbins

;select the times from which electronic noise levels will be determined
;(these values must be within the trange argument passed to thm_part_getspec)
t1 = '2008-02-26/02:30:00'
t2 = '2008-02-26/02:40:00'
;If you want you can select a different time range for each bin separately
;The time array below can be either a 2xN where N is the number of elements in idx
;Or a 2 element array, where the same times are applied to all bins.
times=[t1,t2] ;


;now regenerate phi plot with the electronic noise from the selected bins subtracted.
thm_part_getspec, probe=probe, trange=[sdate, edate], $
                  theta=[-45,0], phi=[0,360], $
                  data_type=['psif'], start_angle=0,$
                  angle='phi',method_sunpulse_clean='median',tplotsuffix='_ex2_t1',$
                  enoise_bins = bins,enoise_bgnd_time=times,mask_remove=.99
                  
tplot,['th'+probe+'_psif_an_eflux_phi_norm_t1','th'+probe+'_psif_an_eflux_phi_ex1_t1','th'+probe+'_psif_an_eflux_phi_ex2_t1'],title='themis '+probe+' ion an eflux phi : theta = [-45,0]'
  
stop

;remove the data at it will be regenerated in the examples below
del_data,'th'+probe+'_psif_an_eflux_phi_ex*'

;-------------------------------------------------------------------------
;Example of the same process for electron burst data
;-------------------------------------------------------------------------

timespan,'2008-03-12/03:30:00',1,/hour

thm_part_getspec, probe='d', trange=['2008-03-12/03:30:00','2008-03-12/04:30:00'], theta=[-45,0], $
  data_type='pseb', angle='phi', suffix='_norm_t1',/autoplot
  

;now remove the mask and sun contamination
thm_part_getspec, probe='d', trange=['2008-03-12/03:30:00','2008-03-12/04:30:00'], theta=[-45,0], $
  data_type='pseb', angle='phi', suffix='_ex1_t1',mask_remove=.99,method_sunpulse_clean='median'

;You can also remove contamination/electrical noise using the enoise options

edit3dbins,thm_sst_pseb(probe='d', gettime(/c)), bins 

;now remove contamination using enoise_bin options
thm_part_getspec, probe='d', trange=['2008-03-12/03:30:00','2008-03-12/04:30:00'], theta=[-45,0], $
  data_type='pseb', angle='phi', suffix='_ex2_t1',mask_remove=.99,$
  enoise_bins=bins,enoise_bgnd_time=['2008-03-12/04:14:00','2008-03-12/04:14:30']
  
;the first plot here is unmodified, the second plot uses the automated method to remove the sun contamination
;the third plot uses enoise_bins to remove the sun contamination.
tplot,['thd_pseb_an_eflux_phi_norm_t1','thd_pseb_an_eflux_phi_ex1_t1','thd_pseb_an_eflux_phi_ex2_t1']
  
stop

timespan,sdate,hrs,/hour

;-------------------------------------------------------------------------
;Examples of different options and detailed explanations of their behavior
;-------------------------------------------------------------------------            
;This call will generate spectrograms but remove the sun contamination.
;It calculates a modified Z-score for each bin across phi. 
;All points that have a modified z-score(calculated across phi) greater than 3.5 will
;be considered outliers and removed. 
;The modified z-score is a normalized outlier detection test defined as follows:  
;#1 X_Bar = median(X+1)
;#2 Sigma = MAD = Median Absolute Deviation = median(abs(X-X_Bar))
;#3 Z_Score_Mod = .6745*(X - X_Bar)/Sigma
;This test can often get excellent results because it is insensitive to variation in standard deviation
; and skew in the distributions.  
;
thm_part_getspec, probe=probe, trange=[sdate,edate], theta=[-45,0], $
  data_type='ps?f', angle='phi',erange=[50000,100000], suffix='_int_z_t1',$
  method_sunpulse_clean='z_score_mod'
thm_part_getspec, probe=probe, trange=[sdate,edate], theta=[0,45], $
  data_type='ps?f', angle='phi',erange=[50000,100000], suffix='_int_z_t2', $
  method_sunpulse_clean='z_score_mod'
;
;this call will generate spectrograms but remove the sun contamination.
;It removes all the points that are more than 2.0(default) of standard deviations
;from a spin-fit. The fitting is done with the idl function svdfit and the function
;that is being fit is A + B*Sin(phi)+C*Cos(phi)
;After the points are removed they are filled via linear interpolation
;along phi.  This interpolation is done using the TDAS function: interp_gap
;if you want to specify a different number of standard deviations you can
;use the keyword limit_sunpulse_clean, for example: limit_sunpulse_clean=1.3
;NOTE: the median option is much faster than the spin_fit option for sun contamination
;removal
;
thm_part_getspec, probe=probe, trange=[sdate,edate], theta=[-45,0], $
  data_type='ps?f', angle='phi',erange=[50000,100000], suffix='_int_fit_t1',$
  method_sunpulse_clean='spin_fit'
thm_part_getspec, probe=probe, trange=[sdate,edate], theta=[0,45], $
  data_type='ps?f', angle='phi',erange=[50000,100000], suffix='_int_fit_t2', $
  method_sunpulse_clean='spin_fit' 
                  
;the next call will remove the on-board masking by finding all the phis and
; thetas that are 0 for some proportion of times and at all energies for the
; specified time range.  The identified points will be removed and replaced via linear 
; interpolation along phi. This is done with the TDAS function: interp_gap
; The input to mask_remove keyword is the proportion of times that must have 0 at all values
; to be considered the mask.  Generally .99 is a good choice, although it may vary
; between data sets.

thm_part_getspec, probe=probe, trange=[sdate,edate], theta=[-45,0], $
  data_type='ps?f', angle='phi',erange=[50000,100000], mask_remove=.99, $
  suffix='_int_mask_t1'
thm_part_getspec, probe=probe, trange=[sdate,edate], theta=[0,45],$
  data_type='ps?f', angle='phi',erange=[50000,100000], mask_remove=.99,$
  suffix='_int_mask_t2'
                  
;this call will perform both spin fit sun contamination removal and mask filling.  
;The removed points will be filled via interpolation along phi.  The points
;removed via 'mask_fill=.99' and the points removed via 'spin_fit=' will be filled
;at the same time.  This example also requests a points a user specified number
;of standard deviations from the spin_fit be removed rather than the default of 2.0
;Note also that you can specify the fillin method, but since interpolation
;is the default, you do not need to specify it, if that is the method
;you want to use.

thm_part_getspec, probe=probe, trange=[sdate,edate], theta=[-45,0], $
  data_type='ps?f',angle='phi',erange=[50000,100000], mask_remove=.99,$
  suffix='_int_mask_fit_t1',method_sunpulse_clean='spin_fit',$
  limit_sunpulse_clean=1.8,fillin_method='interpolation'
thm_part_getspec, probe=probe, trange=[sdate,edate], theta=[0,45],$
  data_type='ps?f', angle='phi',erange=[50000,100000], mask_remove=.99,$
  suffix='_int_mask_fit_t2',method_sunpulse_clean='spin_fit',$
  limit=1.8 

                  
;this transformation will remove the same points as in the previous transformation,
;but the points will be filled by using a second spin fit after the problematic points
;have been identified.  The appropriate phis for the removed points will then be plugged
;into the second spin fit to fill them with values derived from the 2nd spin-fit.

thm_part_getspec, probe=probe, trange=[sdate,edate], theta=[-45,0], $
  data_type='ps?f', angle='phi',erange=[50000,100000], mask_remove=.99,$
  suffix='_fit_mask_fit_t1',method_sunpulse_clean='spin_fit', $
  limit_sunpulse_clean=1.8,fillin_method='spin_fit'
thm_part_getspec, probe=probe, trange=[sdate,edate], theta=[0,45],$
  data_type='ps?f', angle='phi',erange=[50000,100000], mask_remove=.99, $
  suffix='_fit_mask_fit_t2', method_sunpulse_clean='spin_fit', $
  limit_sunpulse_clean=1.8,fillin_method='spin_fit' 
                  
;the example will remove the sun contamination using a different technique. 
;Rather than using a spin fit, it will remove all the points that are greater than 
;a user specified number of standard deviations(default 2.0) from the median along each
;phi at  each theta,energy, & time.  By default filling is done with the interpolation
; method,but you may also request spin filling with fillin_method='spin_fit'
thm_part_getspec, probe=probe, trange=[sdate,edate], theta=[-45,0],$
  data_type='ps?f', angle='phi',erange=[50000,100000], mask_remove=.99, $
  suffix='_fit_mask_med_t1',method_sunpulse_clean='median', $
  limit_sunpulse_clean=1.8,fillin_method='spin_fit'
thm_part_getspec, probe=probe, trange=[sdate,edate], theta=[0,45],$
  data_type='ps?f', angle='phi',erange=[50000,100000], mask_remove=.99, $
  suffix='_fit_mask_med_t2',method_sunpulse_clean='median', $
  limit_sunpulse_clean=1.8,fillin_method='spin_fit'
                  
;Any of the options used above may also be called with thm_part_moments or thm_part_moments2
thm_part_moments,probe=probe,instrum=['ps?f'],mag_suffix='_peif_magf', $
  scpot_suffix='_peif_sc_pot',moments='*', mask_remove=.99, $
  trange=[sdate,edate],tplotsuffix='_int_mask_med', $
  method_sunpulse_clean='median'
  
;the /scale_sphere option will increase measurements by 16%  this
;is to account for the loss of solid angle that occurs from the
;inability of the SST to measure in all directions.  The SST is unable to
;measure directly along the probe geometric Z-axis and directly along the probe
;geometric XY plane (ie Z=n,X=0,Y=0 & Z=0,X=n,Y=m are SST 'blind spots'). 
;This option may be combined with any of the other available options.
;This option may also be used with thm_part_getspec.
thm_part_moments,probe=probe,instrum=['ps?f'],mag_suffix='_peif_magf', $
  scpot_suffix='_peif_sc_pot',moments='*', /scale_sphere, $
  trange=[sdate,edate],tplotsuffix='_scale'
 
;you may also choose to replace all angles with the median across all angles
;for each particular energy and time by using the all_angle_median option.
;This simple transformation will remove the sun contamination/masking from many
;moments, but will result in a 0 velocity moment, and more isotropic temperatures 
;than normal. This option may also be used with thm_part_getspec.
;It is possible to combine this option with other sun contamination options, but
;the result may not be meaningful because this option removes all
;variation across angles.
thm_part_moments,probe=probe,instrum=['ps?f'],mag_suffix='_peif_magf', $
  scpot_suffix='_peif_sc_pot',moments='*', /all_angle_median, $
  trange=[sdate,edate],tplotsuffix='_all_median'

stop

;The options below will show the different options for removal of electrical contamination
;First we generate the arguments to the enoise options.  Note that the first example
;in this crib sheet shows how to generate the bin indexes interactively using edit3dbins

bins = intarr(64)

bins[*] = 1

idx = [32,33,55,56,62]

bins[idx] = 0

times = strarr(2,n_elements(idx))
times[0,*] = t1
times[1,*] = t2

;this example shows the basic call to remove electronic noise
;the values of the selected bins at the user specified time range
;will be subtracted from the selected bins at all times 
;the value over the range is determined by some function over the user
;specified range.  A separate value is calculated and subtracted for each
;different energy range.
;  
;This example shows the default enoise removal function 'fit_median'
;This option was used in the original example as well.(since it is the default
;whether you specify it or not is optional)
;The 'fit_median' function removes all the selected bins.  Then it interpolates
;across phi to fill in the removed bins.  After this, the median of the interpolated difference of the
;interpolated values and the selected bins over the user specified time range is subtracted from
; the bins over the entire time range  
thm_part_getspec, probe=probe, trange=[sdate, edate], $
                  theta=[-45,0], phi=[0,360], $
                  data_type=['psif'], start_angle=0,$
                  angle='phi',/autoplot,method_sunpulse_clean='median', $
                  tplotsuffix='_enoise_fit_med_t1',enoise_remove_method='fit_median',$
                  enoise_bins = bins,enoise_bgnd_time=times,mask_remove=.99
                 
thm_part_getspec, probe=probe, trange=[sdate, edate], $
                  theta=[0,45], phi=[0,360], $
                  data_type=['psif'], start_angle=0,$
                  angle='phi',/autoplot,method_sunpulse_clean='median',$
                  tplotsuffix='_enoise_fit_med_t2',enoise_remove_method='fit_median',$
                  enoise_bins = bins,enoise_bgnd_time=times,mask_remove=.99         
                  
                  
;This example shows the enoise removal function 'fit_average'
;The 'fit_average' function removes all the selected bins.  Then it interpolates
;across phi to fill in the removed bins.  After this, the average of the interpolated difference of the
;interpolated values and the selected bins over the user specified time range is subtracted from
; the bins over the entire time range  

thm_part_getspec, probe=probe, trange=[sdate, edate], $
                  theta=[-45,0], phi=[0,360], $
                  data_type=['psif'], start_angle=0,$
                  angle='phi',/autoplot,method_sunpulse_clean='median', $
                  tplotsuffix='_enoise_fit_avg_t1',enoise_remove_method='fit_average',$
                  enoise_bins = bins,enoise_bgnd_time=times,mask_remove=.99
                 
thm_part_getspec, probe=probe, trange=[sdate, edate], $
                  theta=[0,45], phi=[0,360], $
                  data_type=['psif'], start_angle=0,$
                  angle='phi',/autoplot,method_sunpulse_clean='median',$
                  tplotsuffix='_enoise_fit_avg_t2',enoise_remove_method='fit_average',$
                  enoise_bins = bins,enoise_bgnd_time=times,mask_remove=.99    
                  
;This example shows the enoise removal function 'median'
;This function subtracts the median over time of each bin and energy.
thm_part_getspec, probe=probe, trange=[sdate, edate], $
                  theta=[-45,0], phi=[0,360], $
                  data_type=['psif'], start_angle=0,$
                  angle='phi',/autoplot,method_sunpulse_clean='median', $
                  tplotsuffix='_enoise_med_t1',enoise_remove_method='median',$
                  enoise_bins = bins,enoise_bgnd_time=times,mask_remove=.99
                 
thm_part_getspec, probe=probe, trange=[sdate, edate], $
                  theta=[0,45], phi=[0,360], $
                  data_type=['psif'], start_angle=0,$
                  angle='phi',/autoplot,method_sunpulse_clean='median',$
                  tplotsuffix='_enoise_med_t2',enoise_remove_method='median',$
                  enoise_bins = bins,enoise_bgnd_time=times,mask_remove=.99   
                  
;This example shows the enoise removal function 'average'
;This function subtracts the average over time of each bin and energy.
thm_part_getspec, probe=probe, trange=[sdate, edate], $
                  theta=[-45,0], phi=[0,360], $
                  data_type=['psif'], start_angle=0,$
                  angle='phi',/autoplot,method_sunpulse_clean='median', $
                  tplotsuffix='_enoise_avg_t1',enoise_remove_method='average',$
                  enoise_bins = bins,enoise_bgnd_time=times,mask_remove=.99
                 
thm_part_getspec, probe=probe, trange=[sdate, edate], $
                  theta=[0,45], phi=[0,360], $
                  data_type=['psif'], start_angle=0,$
                  angle='phi',/autoplot,method_sunpulse_clean='median',$
                  tplotsuffix='_enoise_avg_t2',enoise_remove_method='average',$
                  enoise_bins = bins,enoise_bgnd_time=times,mask_remove=.99   
                  
;This example shows the enoise removal function 'min'
;This function subtracts the minimum over time of each bin and energy.
thm_part_getspec, probe=probe, trange=[sdate, edate], $
                  theta=[-45,0], phi=[0,360], $
                  data_type=['psif'], start_angle=0,$
                  angle='phi',/autoplot,method_sunpulse_clean='median', $
                  tplotsuffix='_enoise_min_t1',enoise_remove_method='min',$
                  enoise_bins = bins,enoise_bgnd_time=times,mask_remove=.99
                 
thm_part_getspec, probe=probe, trange=[sdate, edate], $
                  theta=[0,45], phi=[0,360], $
                  data_type=['psif'], start_angle=0,$
                  angle='phi',method_sunpulse_clean='median',$
                  tplotsuffix='_enoise_min_t2',enoise_remove_method='min',$
                  enoise_bins = bins,enoise_bgnd_time=times,mask_remove=.99   
                  
;setting a couple labels
;note that you may want to set the ranges so that all the plots scale evenly
                  
options,'th'+probe+'_ps?f_magt3_*',labels=['Tprp1FA', 'Tprp2FA', 'TparFA'],labflag=1
options,'th'+probe+'_ps?f_velocity_*',labels=['Vx', 'Vy', 'Vz'],labflag=1

tplot_options,'xmargin',[20,15]
 
stop

window,xsize=600,ysize=900

;the next few tplot calls will plot the phi spectrograms made above
;These plots allow comparisons of the different techniques

tplot,['th'+probe+'_psif_an_eflux_phi_norm*_t1','th'+probe+'_psif_an_eflux_phi_int*_t1','th'+probe+'_psif_an_eflux_phi_fit*_t1'],title='themis '+probe+' ion an eflux phi : theta = [-45,0]'

stop

tplot,['th'+probe+'_psif_an_eflux_phi_norm*_t2','th'+probe+'_psif_an_eflux_phi_int*_t2','th'+probe+'_psif_an_eflux_phi_fit*_t2'],title='themis '+probe+' ion an eflux phi : theta = [0,45]'

stop

tplot,['th'+probe+'_psef_an_eflux_phi_norm*_t1','th'+probe+'_psef_an_eflux_phi_int*_t1','th'+probe+'_psef_an_eflux_phi_fit*_t1'],title='themis '+probe+' electron an eflux phi : theta = [-45,0]'

stop

tplot,['th'+probe+'_psef_an_eflux_phi_norm*_t2','th'+probe+'_psef_an_eflux_phi_int*_t2','th'+probe+'_psef_an_eflux_phi_fit*_t2'],title='themis '+probe+' electron an eflux phi : theta = [0,45] '

stop

tplot,['th'+probe+'_psif_an_eflux_phi_norm*_t1','th'+probe+'_psif_an_eflux_phi_enoise*_t1'],title='themis '+probe+' ion an eflux phi : theta = [-45,0] '

stop

tplot,['th'+probe+'_psif_an_eflux_phi_norm*_t2','th'+probe+'_psif_an_eflux_phi_enoise*_t2'],title='themis '+probe+' ion an eflux phi : theta = [0,45] '

stop

;these calls will plot the moments generated by calls to thm_part_moments
;these plots allow comparisons of the different techniques
tplot,'th'+probe+'_psif_en_eflux*',title='themis '+probe+' ion eflux'

stop

tplot,'th'+probe+'_psef_en_eflux*',title='themis '+probe+' electron eflux'

stop

tplot,'th'+probe+'_psif_density*',title='themis '+probe+' ion density'

stop

tplot,'th'+probe+'_psef_density*',title='themis '+probe+' electron density'
  
stop

tplot,'th'+probe+'_psif_magt3*',title='themis '+probe+' ion magt3'

stop

tplot,'th'+probe+'_psef_magt3*',title='themis '+probe+' electron magt3'

stop

tplot,'th'+probe+'_psif_velocity*',title='themis '+probe+' ion velocity'

stop

tplot,'th'+probe+'_psef_velocity*',title='themis '+probe+' electron velocity'

stop


;you can also use median,spin_fit,spin_fill,scale_sphere, & all_angle_median
;arguments directly with thm_sst_psif,thm_sst_psef. You may NOT use the
;mask_fill option, as it only makes sense to use when looping over several
;time stamps.  

;heres an example before the correction:
edit3dbins,thm_sst_psif(probe=probe, time_double(sdate))


;here's an example after the correction
edit3dbins,thm_sst_psif(probe=probe, time_double(sdate),method_sunpulse_clean='spin_fit')


;If you want to see how to use the mask_fill option directly with
;thm_sst_ps?f,  you can use thm_find_masking to generate the appropriate
;arguments, but doing this is not recommended.  Also note that while
;using all_angle_median and scale_sphere is possible it doesn't
;necessarily make sense when looking at the data individually.
           
end