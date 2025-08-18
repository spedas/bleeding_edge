
;+
;NAME:
; thm_crib_sst_calibrations
;PURPOSE:
;  This crib demonstrates how to use of the development branch SST calibration code.  
;  (WARNING: the SST calibration code is in development, it is changing quickly!)
;
;See Also:
;  themis/spacecraft/particles/SST/SST_cal_workdir.pro
;  thm_sst_convert_units2.pro
;
;$LastChangedBy: pcruce $
;$LastChangedDate: 2013-09-19 10:56:58 -0700 (Thu, 19 Sep 2013) $
;$LastChangedRevision: 13080 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/examples/deprecated/thm_crib_sst_calibration.pro $
;-


;--------------------------------------------------------------------------------------------------
;Description of the SST(code below, if you want to skip ahead):
;---------------------------------------------------------------------------------------------------
; The SST on each spacecraft includes 2 units split into two nearly identical halves,
; with the two halves arranged anti-parallel to each other.
; Each half contains a stack of 3 silicon detectors. 
; Each half unit is open at both ends and includes filters such that one end accepts ions
; and the other end accepts electrons.  Electrons and ions are measured on the same 3 detector stack.
; 
; Each of these openings is called an anode or telescope.
; This means that each spacecraft has eight telescopes, four for each unit, 2 electron telescopes and 2 proton telescopes per unit. 
;
; Filtering:
; Each telescope has a collimator(also called an aperture) which limits the set of angles from which an telescope may accept particles.  
; Each collimator is designed to create a nominal .1 cm2/sr g-factor. 
; 
; Each ion telescope contains a dipole magnet(~2 kgauss) designed to create a nearly uniform field across the aperture.  
; The magnet in the ion telescope of the other half of the unit is place next to this magnetic but with its orientation flipped.
; This means that each unit as a whole forms a quadropole configuration which cancels the field outside of each aperture effectively.  
; Since electrons are much less massive than ions, electrons are deflected away from the detectors while ions are largely unaffected.
; 
; Each electron telescope contains a thin aluminized kapton foil which covers the aperture.(~4.2 um thick)  Because electrons penetrate much more easily into
; matter than protons, this effectively stops protons below a certain energy from entering through the electron apertures.
; (This also makes the electron apertures light-tight)
; 
; Each aperture(electron & ion) has a mechanical attenuator.  When closed(active) a plate with a small hole moves in front of the aperture.
; This hole is designed to reduce the geometric factor by a nominal factor of 64.  This reduces the flux into the instrument and thus can be used to increase
; the measurable range of fluxes of the SST.  The plate is swiveled into place(closed, active) when in high fluence regions near the earth.   
;
;Coincidence & Energy:
;
; Each of the three detectors in a detector stack has a name. Foil, Thick, or Open.  The Foil detector, is the detector from the electron side of the stack, which
; is filtered using the foil.  The Thick detector is in the middle.  It is called Thick because it has double the thickness of the other two detectors. The Open
; detector is from the ion side, called Open because the aperture is open to space.  The Open and Foil detectors are 300 um thick, the Thick detector is 600 um thick.
;
; When particles interact with a detector, the energy that they deposit on the detector is measured.  This is done by measuring the height of the
; charge pulse created by the particle from its impact with the detector.  
; 
; When a particle enters an aperture it is called an Event.
; Each event is by the pattern of detectors that it interacts with.  For example, if a particle deposits energy on the Foil detector only, this is called an F event.
; If a particle deposits energy on the Foil detector and the Thick detector, this is called an FT event.  The full set of events is:
; F,FT,FTO,O,OT,T.  An FO event is theoretically possible, but the possiblility that it was caused by a single particle is remote.  Instead, FO events aret treated as
; two separate simulataneous events, an F & an O.
; 
; The total energy deposited on all detectors during an event is summed, and then the appropriate bin in an energy histogram is incremented.  While it is possible
; that there be 16 different energy bins for each event type, only a small subset of these are downloaded from the spacecraft.
; (12 F bins,12 O bins,3 FT bins,2 OT bins,1 Thick bin, 2 FTO bins)
; 
; It is the classification of these events that allows particle species to be inferred.  At a first approximation, F & FT events are considered electrons.  O events 
; are considered protons.  Other event types are used as noise measures.  When downlinked from the spacecraft, different events are concatenated into 
; arrays of 16 energy bins per species. Electrons combined into (F,FT,FTO(low)) Protons are combined into (O,OT,T,FTO(high)). 
;
; Angle measurement:
; 
; Each of the two units is oriented at a different inclination with respect to the spacecraft spin plane.  This angle is called theta.  One unit has a 25 degree inclination
; and the other has a 52 degree inclination.  Because the units are open at both ends, this means that they can also measure at -25 and -52 degree inclinations.  The 
; angle between the sun direction and the look direction of the SST is called phi.  As the spacecraft spins, 16 measurements are taken across phi.  This
; results in a total of 4 theta * 16 phis = 64 different angle bins.  Since there are 16 energies per species, each species will have an array of 16x64 different
; count measures per spin.   
; 
; Distribution types:
;
; There are three types of distribution for SST which combine different compromises between angle resolution, time resolution, and orbit coverage.
; 
; Burst distribution: spin time resolution(3-second) and maximum angle resolution(64 angles), but it is only available for very short periods during an orbit.
; When it is turned on is determined by triggers set by mission scientists and the PI.
; 
; Full distribution: 3-minute resolution and full angle resolution, available at all times.  On-board values are averaged across time over 60 spins.  Note that at some times during the 
; mission, full distribution was reconfigured to switch back and forth between 3-minute and 3-second time resolution.   
;
; Reduced distribution: Spin time resolution(3-second) and reduced angle resolution, available at all times.  The angles are averaged down to either 6 or 1 angle(the number of angles will change
; due to various triggers across an orbit)  In the event of a 6-angle distribution, 
; 4 angles divide the spin-plane into quarters and one angle covers each pole.
;
;Calibration Parameters:
;
;Calibration parameters are stored in the year 0000 subdirectory of the L1 SST data directory.
;e.g. C:\data\themis\tha\l1\sst\0000\
;
;They're also stored in the TDAS in the SST_cal_workdir,for reference, but these copies are not used for calibrating. 
;
;If you want to edit the calibration parameters just modify the copies in your data directory.
;The calibration file format supports comments and descriptions of the parameters can be found in the files themselves.
;
;
;------------------------------------------------------------------------------------------

;-----------------------------------------------------
;Preliminary Junk
;If you want to skip down to an example further down in the cribsheet,
;Make sure you still do this stuff.
;-----------------------------------------------------
  ;set time of interest
  timespan,'2009-11-14/04:00:00',12,/hour
  
  ;probe variable for convienience
  probe = 'a'
  
  ;more legible y-axis labels
  tplot_options,'charsize',1.2
  
  ;inits themis routines(not strictly necessary as most TDAS routines will call it anyway if you haven't)
  thm_init
  
  ;specify bins for suncontamination removal
  sun_bins = dblarr(64)+1
  sun_bins[[30,39,40,46,55,56,61,62]] = 0  ;if used, removes and fills bins 30,39,40,46,55,56,61,62
  ;see crib thm_crib_sst_contamination.pro for more information on how you can choose sun contamination bins.
  
  ;If you have local mods to calibrations files that you don't want to be accidentally overwritten
  ;Set this:
 ; !themis.no_update=1
  
  ;The new calibration code uses a new load routine
  ;The big different with thm_load_sst2 is that all its data is 
  ;stored in tplot variables, whereas the original thm_load_sst
  ;stored data in a common block.
  thm_load_sst2,probe=probe
 
   ;Load the old SST data for comparison
  thm_load_sst,probe=probe
 
  ;Generate SST full ion distribution moments using unit conversion with nominal parameters but no calibration or decontamination
  ;(Old code for comparison)
 ; thm_part_moments,probe=probe,inst='psif',moments='*',tplotsuffix='_old'
  
  ;Generate SST angular spectra and energy spectra using unit conversion with nominal parameters but no calibration or decontamination
  ;(Old code for comparison) 
  thm_part_getspec, probe=probe, $
                  theta=[-45,45], phi=[0,450], $
                  data_type=['psif','psef'], angle='phi',suffix='_old',/energy
 
  
 
  ;------------------------------------------------------------------------
  ;SST full ion distribution calibrated.
  ;/sst_cal keyword for ions and electrons
  ;--------------------------------------------------------------------------
  ;
  ;At the moment, this calibration includes energy efficiencies and 
  ;intercalibrations between telescopes at different thetas on the same spacecraft
  thm_part_getspec, probe=probe, $
                  theta=[-45,45], phi=[0,450], $
                  data_type=['psif'], angle='phi',suffix='_new',$
                  method_clean='manual',sun_bins=sun_bins,/sst_cal,/energy
 
  ;NOTE: The sun contamination removal slows down the calibration substantially(roughly 4x), remove the method_clean & sun_bins keyword to disable sun contamination removal 
   
  ;Uncomment this line to get moments  
  ;thm_part_moments,probe=probe,inst='psif',moments='*',/sst_cal,tplotsuffix='_new',method_clean='manual',sun_bins=sun_bins
 
                                     
  ;convience variable, ion energy eflux distributions with old and new code
  psif_flux_tvars = ['th'+probe+'_psif_en_eflux_old','th'+probe+'_psif_en_eflux_new']
  
   
  ;set the same range so that they can be easily compared
 ; options,psif_flux_tvars,yrange=[1e4,1e7],zrange=[1e2,1e7]
  
  ;plot the data
  tplot,psif_flux_tvars
  
  stop
  
  ;---------------------------------------------------------------
  ;edit3dbins example
  ;---------------------------------------------------------------
  
  
  edit3dbins,thm_part_dist('th'+probe+'_psif',time_double('2009-11-14/06:00:00'),/sst_cal) 
  ;right click to exit
 
  
  ;------------------------------------------------------------------------------
  ;SST full distribution electrons, calibrated.
  ;/sst_cal keyword for electrons
  ;------------------------------------------------------------------------------
  ;This code merges F & FT channel data into a single data set.
  ;Energy efficiencies are applied and relative geometric factors for each telescope are applied.  
  thm_part_getspec, probe=probe, $
                  theta=[-45,45], phi=[0,450], $
                  data_type=['psef'], angle='phi',suffix='_new',$
                  method_clean='manual',sun_bins=sun_bins,/sst_cal,/energy
   
   ;NOTE: The sun contamination removal slows down the calibration substantially(roughly 4x), remove the method_clean & sun_bins keyword to disable sun contamination removal 
  

   ;Uncomment this line to get moments  
  ;thm_part_moments,probe=probe,inst='psef',moments='*',/sst_cal,tplotsuffix='_new',method_clean='manual',sun_bins=sun_bins
     
  psef_flux_tvars=['th'+probe+'_psef_en_eflux_old','th'+probe+'_psef_en_eflux_new']
  ;options,psef_flux_tvars,yrange=[2e4,3e6],zrange=[1e2,1e7],ystyle=1
  tplot,psef_flux_tvars
  
  stop
 
  ;--------------------------------------------------------------------
  ;OT channel ,  /FT_OT keyword
  ;--------------------------------------------------------------------
  ;This code loads moments and energy spectra using OT channel data
  ;Efficiencies and relative geometric factors for each telescope are applied.
  thm_part_moments,probe=probe,inst='psif',moments='*',/sst_cal,tplotsuffix='_new',/ft_ot  ;The ft_ot keyword can also be used with thm_part_getspec
  
  tplot,['th'+probe+'_psif_en_eflux_old','th'+probe+'_psif_en_eflux_new']
  
  stop
  
  ;----------------------------------------------------------------------------------
  ;FT channel , /FT_OT keyword
  ;-----------------------------------------------------------------------------------  
  ;This code loads moments and energy spectra using FT channel data, only.(Not the merged F/FT data.)
  ;Efficiencies and relative geometric factors for each telescope are applied.
  thm_part_moments,probe=probe,inst='psef',moments='*',/sst_cal,tplotsuffix='_new',/ft_ot
  
  tplot,['th'+probe+'_psef_en_eflux_old','th'+probe+'_psef_en_eflux_new']
  
  stop
  
  
  ;------------------------------------------------------------------------
  ;F channel,/F_O keyword
  ;------------------------------------------------------------------------
  
  ;This code loads moments and energy spectra using F channel datam, only. (Not the merged F/FT data.)
  ;Efficiencies and relative geometric factors for each telescope are applied.
  ;Note that the /f_o keyword doesn't change ion data since you always get O data, only
  thm_part_moments,probe=probe,inst='psef',moments='*',/sst_cal,tplotsuffix='_new',/f_o  ;The f_o keyword can also be used with thm_part_getspec
    
  tplot,['th'+probe+'_psef_en_eflux_old','th'+probe+'_psef_en_eflux_new']
  
  stop

  ;------------------------------------------------------------------------
  ;FTO channel(low energy range),/FTO keyword
  ;------------------------------------------------------------------------
 
  ;This code loads moments and energy spectra using FTO channel data for the lower FTO energy bin.
  ;Efficiencies and relative geometric factors for each telescope are applied.
  thm_part_moments,probe=probe,inst='psef',moments='*',/sst_cal,tplotsuffix='_new',/fto
  
  ;note that the fto channel won't plot correctly as a spectral plot since specplot can't properly draw single channels
  ;Instead, we plot as a lineplot
  options,'th'+probe+'_psef_en_eflux_new',spec=0
  tplot,['th'+probe+'_psef_en_eflux_old','th'+probe+'_psef_en_eflux_new']
  
  stop
  
  ;------------------------------------------------------------------------
  ;FTO channel(high energy range),/FTO keyword
  ;------------------------------------------------------------------------
 
  ;This code loads moments and energy spectra using FTO channel data for the high FTO energy bin.
  ;Efficiencies and relative geometric factors for each telescope are applied.
  thm_part_moments,probe=probe,inst='psif',moments='*',/sst_cal,tplotsuffix='_new',/fto
  
  ;note that the fto channel won't plot correctly as a spectral plot since specplot can't properly draw single channels
  ;Instead, we plot as a lineplot
  tplot,['th'+probe+'_psef_en_eflux_old','th'+probe+'_psef_en_eflux_new']
  
  stop
 
  ;------------------------------------------------------------------------
  ;Angular spectra, /sst_cal keyword
  ;-------------------------------------------------------------------------
                  
  ;This code generates angular spectra for ions and electrons using the new calibrations.   
  ;Efficiencies and relative geometric factors for each telescope are applied.     
  ;Electrons use the merged F/FT distribution.
  ;Note that any of the keywords demonstrated above should work with this routine (/sst_cal,/f_o,/ft_ot,/fto)          
  thm_part_getspec, probe=[probe], $
                  theta=[-45,45], phi=[0,450],erange=[1,1e7], $
                  data_type=['psif','psef'], angle='phi',suffix='_new',$
                  /sst_cal

  tplot,['th'+probe+'_ps?f_an_eflux_phi_*']

  stop

  ;------------------------------------------------------------------------
  ;Disable partial calibration: Energy Efficiency
  ;-------------------------------------------------------------------------
                  
  ;The /no_energy_efficiency keyword runs the new calibrations without the energy efficiency corrections       
  thm_part_getspec, probe=[probe], $
                  theta=[-45,45], phi=[0,450],erange=[1,1e7], $
                  data_type=['psif','psef'], angle='phi',suffix='_new',$
                  /sst_cal,/no_energy_efficiency

  tplot,['th'+probe+'_ps?f_an_eflux_phi_*']

  stop
  
  
  ;------------------------------------------------------------------------
  ;Disable partial calibration: Relative telescope efficiency
  ;-------------------------------------------------------------------------
                  
  ;The /no_geom_efficiency disables the calibrations for the relative efficiencies of different telescopes
  thm_part_getspec, probe=[probe], $
                  theta=[-45,45], phi=[0,450],erange=[1,1e7], $
                  data_type=['psif','psef'], angle='phi',suffix='_new',$
                  /sst_cal,/no_geom_efficiency

  tplot,['th'+probe+'_ps?f_an_eflux_phi_*']


end