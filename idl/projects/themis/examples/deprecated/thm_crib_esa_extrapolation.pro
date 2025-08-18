;-
;Name: thm_crib_esa_extrapolation
;
;Purpose: Demonstrates code to perform energy extrapolation on ESA data.
;This code uses a new system for loading and calibrating particle data.
;This system is designed to provide more flexibility for scientists
;and more modularity for programmers.
;
;Usage:
; To run this crib, compile and type .go
; Or alternatively, copy & paste
;
;See Also:
;  thm_crib_sst_calibration.pro
;  thm_crib_sst_extrapolation.pro
;  thm_part_dist_array.pro
;  thm_part_conv_units.pro
;  thm_esa_energy_extrapolate.pro
;  thm_sst_energy_extrapolate.pro
;  thm_part_moments.pro
;  thm_part_getspec.pro
;  thm_part_copy.pro
;
; $LastChangedBy: pcruce $
; $LastChangedDate: 2013-09-19 10:56:58 -0700 (Thu, 19 Sep 2013) $
; $LastChangedRevision: 13080 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/examples/deprecated/thm_crib_esa_extrapolation.pro $
;-


  del_data,'*'
  heap_gc ;New system uses pointers.  This call clears any dangling pointers from earlier sessions

  ;This loads the particle data into a data structure for users.
  ;This data struture consists of an array of pointers to arrays of structures.  
  ;Each array of structures contains all the particle data that spans a particular mode.
  ;Because structure definitions change between modes, structures from different modes cannot be concatenated.
  ;Thus, the array of pointers allows the time-series grouping of different mode structure arrays within the same data structure/variable.
  ;2012-02-08/tha_peef is a good test date because it spans an ESA mode change   
  dist_data_eesa = thm_part_dist_array(probe='a',type='peef',trange=['2012-02-08/09','2012-02-08/12'])

    
  ;This call converts the units for esa & sst data.  By default in converts to eflux.  But like low-level routines
  ;Other units can be specified. (e.g. counts,flux, etc...) 
  ;thm_part_conv_units,dist_data_eesa,error=e,units='rate'  ;convert to counts/sec
  
;Smooths particle data across time.  (better for extrapolated data)
  ;thm_part_smooth,dist_data_eesa,width=10,/nan,/edge_truncate,/center

  
  ;Extrapolate to the provided list of energies.  In this case, the end user provides an array of energies
  ;thm_esa_energy_extrapolate,dist_data_eesa,[100000.,70000,50000]  
  
  ;uncomment this line and comment the line above to use least squares extrapolation with polyfit
  thm_esa_energy_extrapolate,dist_data_eesa,[100000.,70000,50000],lsquares=5   ;argument for lsquares is the number of bins to use in the fit


  thm_part_conv_units,dist_data_eesa,error=e,units='eflux'  ;convert to eflux
  
 ;generate energy eflux arrays from extrapolated data
  thm_part_moments,inst='peef',probe='a',suffix='_new',dist_array=dist_data_eesa;,trange=time_double(['2012-02-08/9:30:00','2012-02-08/10:00:00'])
  thm_load_sst,probe='a'
  thm_part_moments,inst='peef',probe='a',suffix='_old'
  
  options,['tha_peef_en_eflux_old','tha_peef_en_eflux_new'],zrange=[1e5,1e11]
  tplot,['tha_peef_en_eflux_*','tha_peef_density_*','tha_peef_velocity_*','tha_peef_t3_*']

  ;Now we just generate angle data from the extrapolated energies
  ;thm_part_getspec,data_type='peef',probe='a',dist_array=dist_data_eesa,/energy,angle='phi'
  
  ;copy_data,'tha_peef_an_eflux_phi','tha_peef_an_eflux_phi_comp'
  
  ;thm_part_getspec,data_type='peef',probe='a',/energy,angle='phi'
  ;options,'*',yrange=[0,0]
  ;tplot,['tha_peef_an_eflux_phi','tha_peef_an_eflux_phi_comp']
  
  stop
 
end