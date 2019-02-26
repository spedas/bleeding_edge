
;+
;PROCEDURE: thm_crib_part_products
;PURPOSE:
;  Demonstrate basic usage of routine for generating particle moments and spectra.
;    
;NOTES:
;  A lot of features aren't shown here.  This crib is intended to Keep It Simple.
;  
;  Examples on SST specific sun decontamination options can be found in thm_crib_sst.pro
;
;$LastChangedBy: jimm $
;$LastChangedDate: 2019-02-25 14:14:50 -0800 (Mon, 25 Feb 2019) $
;$LastChangedRevision: 26703 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/examples/basic/thm_crib_part_products.pro $
;-

 compile_opt idl2

;----------------------------------------------------------------------------------------------------------------------------
;Example 1, ESA energy eflux spectra
;----------------------------------------------------------------------------------------------------------------------------

probe='a'
datatype='peif'
trange=['2008-02-23','2008-02-24']
timespan,trange

;loads particle data for data type
thm_part_load,probe=probe,trange=trange,datatype=datatype

thm_part_products,probe=probe,datatype=datatype,trange=trange 

tplot,'tha_peif_eflux_energy'

stop

;----------------------------------------------------------------------------------------------------------------------------
;Example 2, SST energy eflux spectra
;----------------------------------------------------------------------------------------------------------------------------

probe='a'
datatype='psif'
trange=['2008-02-23','2008-02-23/6']
timespan,trange

;loads particle data for data type
thm_part_load,probe=probe,trange=trange,datatype=datatype

thm_part_products,probe=probe,datatype=datatype,trange=trange

tplot,'tha_psif_eflux_energy'

stop

;----------------------------------------------------------------------------------------------------------------------------
;Example 3, Energy, Theta, & Phi in one call
;----------------------------------------------------------------------------------------------------------------------------

probe='a'
datatype='peif'
trange=['2008-02-23','2008-02-24']
timespan,trange

;loads particle data for data type
thm_part_load,probe=probe,trange=trange,datatype=datatype

thm_part_products,probe=probe,datatype=datatype,trange=trange,outputs='energy phi theta'

tplot,['tha_peif_eflux_energy','tha_peif_eflux_theta','tha_peif_eflux_phi']

stop

;----------------------------------------------------------------------------------------------------------------------------
;Example 4:  pitch angle and gyrophase
;----------------------------------------------------------------------------------------------------------------------------

probe='a'
datatype='peif'
trange=['2008-02-23','2008-02-24']
timespan,trange

;load support data for pitch-angle and gyrophase rotation
thm_load_state,probe=probe,coord='gei',/get_support,trange=trange
thm_load_fit,probe=probe,coord='dsl',trange=trange

;load particle data
thm_part_load,probe=probe,trange=trange,datatype=datatype

thm_part_products,probe=probe,datatype=datatype,trange=trange,outputs='pa gyro'

tplot,['tha_peif_eflux_gyro','tha_peif_eflux_pa']

stop

;----------------------------------------------------------------------------------------------------------------------------
;Example 5: moments
;----------------------------------------------------------------------------------------------------------------------------

probe='a'
datatype='peef'
trange=['2008-02-23','2008-02-24']
timespan,trange

;load potential and magnetic field data
thm_load_mom,probe=probe,trange=trange,datatype='pxxm_pot' 
thm_load_fit,probe=probe,coord='dsl',trange=trange

;load particle data
thm_part_load,probe=probe,trange=trange,datatype=datatype

;Note ESA background removal is now enabled by default.
;Use esa_bgnd=0 keyword to thm_part_products to disable background removal
thm_part_products,probe=probe,datatype=datatype,trange=trange,outputs='moments'

tplot_options, 'xmargin', [16,10] ;bigger margin on the left, so you can see the labels
tplot,['tha_peef_density','tha_peef_velocity','tha_peef_t3']

stop

;----------------------------------------------------------------------------------------------------------------------------
;Example 6: ESA Background Removal
;  - For more examples see thm_crib_esa_bgnd_remove
;----------------------------------------------------------------------------------------------------------------------------

probe='a'
datatype='peef'
trange=['2008-02-23','2008-02-24']
timespan,trange
 
thm_load_mom,probe=probe,trange=trange,datatype='pxxm_pot' 
thm_load_fit,probe=probe,coord='dsl',trange=trange

thm_part_load,probe=probe,trange=trange,datatype=datatype

;ESA background removal keywords and their default values are shown below.
;See thm_crib_esa_bgnd_remove for more.
;  **note: Old routines used /bgnd_remove instead of /esa_bgnd_remove to control background removal.
thm_part_products,probe=probe,datatype=datatype,trange=trange,outputs='moments pa gyro', $
      /esa_bgnd_remove, bgnd_type='anode', bgnd_npoints=3, bgnd_scale=1

tplot_options, 'xmargin', [16,10] ;bigger margin on the left, so you can see the left-side labels
tplot,['tha_peef_density','tha_peef_velocity','tha_peef_t3','tha_peef_eflux_pa','tha_peef_eflux_gyro']

stop

;----------------------------------------------------------------------------------------------------------------------------
;Example 7: Specifying support parameters for moments(Spacecraft potential/ Mag & Position)
;----------------------------------------------------------------------------------------------------------------------------
 

probe='a'
datatype='peef'
trange=['2008-02-23','2008-02-24']
timespan,trange
 

thm_load_state,probe=probe,trange=trange ;this loads the spacecraft position

thm_load_mom,probe=probe,trange=trange,datatype='pxxm_pot' ;this routine loads the spacecraft calculated spacecraft potential

thm_load_fit,probe=probe,coord='dsl',trange=trange ;this loads the fluxgate mag data(spacecraft generated spin-fit)

;load particle data
thm_part_load,probe=probe,trange=trange,datatype=datatype

;Note ESA background removal is now enabled by default.
;Use esa_bgnd=0 keyword to thm_part_products to disable background removal

;Note spacecraft potential must be loaded by the user.  If none is found, none will be used in products generation.
thm_part_products,probe=probe,datatype=datatype,trange=trange,outputs='moments pa gyro', $
      mag_name='tha_fgs',pos_name='tha_state_pos',sc_pot_name='tha_pxxm_pot'

tplot_options, 'xmargin', [16,10] ;bigger margin on the left, so you can see the left-side labels
tplot,['tha_peef_density','tha_peef_velocity','tha_peef_t3','tha_peef_eflux_pa','tha_peef_eflux_gyro']

stop

;----------------------------------------------------------------------------------------------------------------------------
;Example 8:  Specifying alternate field aligned coordinate systems
;----------------------------------------------------------------------------------------------------------------------------

probe='a'
datatype='peif'
trange=['2008-02-23','2008-02-24']
timespan,trange

;load support data for pitch-angle and gyrophase rotation
thm_load_state,probe=probe,coord='gei',/get_support,trange=trange
thm_load_fit,probe=probe,coord='dsl',trange=trange

thm_part_load,probe=probe,trange=trange,datatype=datatype

;options for fac_type are 'mphigeo','phigeo','xgse'
thm_part_products,probe=probe,datatype=datatype,trange=trange,outputs='pa gyro',fac_type='xgse'

tplot,['tha_peif_eflux_gyro','tha_peif_eflux_pa']

stop

;----------------------------------------------------------------------------------------------------------------------------
;Example 9:  Energy spectra with field aligned angle limits
;----------------------------------------------------------------------------------------------------------------------------

probe='a'
datatype='peef'
trange=['2008-02-23','2008-02-24']
timespan,trange

;load support data for pitch-angle and gyrophase rotation
thm_load_state,probe=probe,coord='gei',/get_support,trange=trange
thm_load_fit,probe=probe,coord='dsl',trange=trange

thm_part_load,probe=probe,trange=trange,datatype=datatype

;produce pitch angle and energy spectrograms from data in the specified pitch angle range
;use "gyro" keyword to set gyrophase range
thm_part_products,probe=probe,datatype=datatype,trange=trange,outputs='pa energy',pitch=[45,135]

tplot,['tha_peef_eflux_pa','tha_peef_eflux_energy']

stop

;----------------------------------------------------------------------------------------------------------------------------
;Example 10:  Product restricted to particular energy range 
;----------------------------------------------------------------------------------------------------------------------------

probe='a'
datatype='peif'
trange=['2008-02-23','2008-02-24']
timespan,trange

;loads particle data for data type
thm_part_load,probe=probe,trange=trange,datatype=datatype

thm_part_products,probe=probe,datatype=datatype,trange=trange,outputs='energy theta phi',energy=[10,40000] ;eV

tplot,['tha_peif_eflux_energy','tha_peif_eflux_theta','tha_peif_eflux_phi']

stop

;----------------------------------------------------------------------------------------------------------------------------
;Example 11:  Eclipse corrections
;----------------------------------------------------------------------------------------------------------------------------

probe='b'
datatype='peif'
trange='2010-02-13/'+['08:00','10:00']
timespan,trange

;load data as usual
thm_part_load,probe=probe,trange=trange,datatype=datatype

thm_part_products,probe=probe,datatype=datatype,trange=trange,outputs='phi moments'

;load data with eclipse corrections
;  use_eclipse_corrections = 0  No corrections are loaded (default).
;                          = 1  Load partial corrections (not recommended)
;                          = 2  Load full corrections.
thm_part_load,probe=probe,trange=trange,datatype=datatype, use_eclipse_corrections=2

thm_part_products,probe=probe,datatype=datatype,trange=trange,outputs='phi moments', suffix='_corrected'

tplot,['thb_peif_eflux_phi','thb_peif_eflux_phi_corrected', $
       'thb_peif_velocity', 'thb_peif_velocity_corrected']

stop

;----------------------------------------------------------------------------------------------------------------------------
;Example 12:  Moments with coord keyword set, new variables for
;velocity, flux, pressure and momentum flux tensors will appear
;with the coordinate system appended to the variables.
;----------------------------------------------------------------------------------------------------------------------------
probe='b'
datatype='peef'
trange=['2011-11-20','2011-11-21']
timespan,trange

;load potential and magnetic field data
thm_load_mom,probe=probe,trange=trange,datatype='pxxm_pot' 
thm_load_fit,probe=probe,coord='dsl',trange=trange

;load particle data
thm_part_load,probe=probe,trange=trange,datatype=datatype

;Note ESA background removal is now enabled by default.
;Use esa_bgnd=0 keyword to thm_part_products to disable background removal
thm_part_products,probe=probe,datatype=datatype,trange=trange,outputs='moments',$
                  coord = 'sm' ;SM coordinates

tplot_options, 'xmargin', [16,10] ;bigger margin on the left, so you can see the labels
tplot,['thb_peef_velocity','thb_peef_velocity_sm','thb_peef_mftens','thb_peef_mftens_sm']

stop

end
