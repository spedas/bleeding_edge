;+
;Procedure:
;  thm_crib_esa_bgnd_advanced
;
;
;Purpose:
;  Demonstrate application of advanced background removal routines.
;  These routines attempt to calculate and subtract ESA background
;  based on ESA count statistics and SST electron data.
;
;  Photo-electron and secondary backgrounds are also calculated 
;  for ESA electrons but are not currently subtracted. 
;
;  *** This is a work in progress, please report any bugs/issues! ***
;
;
;Notes:
;
;       
;See also:
;  thm_crib_esa_bgnd_remove
;  thm_crib_part_products
;
;  thm_load_esa_bgk (main routine to calculate background)
;  thm_pse_bkg_auto (calculate pser-based background)
;
;
;$LastChangedBy: aaflores $
;$LastChangedDate: 2016-07-13 18:54:23 -0700 (Wed, 13 Jul 2016) $
;$LastChangedRevision: 21461 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/examples/advanced/thm_crib_esa_bgnd_advanced.pro $
;-


del_data, '*'

probe = 'c'
datatype = 'peir'

timespan, '2011-07-14/08', 4, /hours
trange = timerange()


;load data for primary analysis
thm_part_load, probe=probe, trange=trange, datatype=datatype 


;calculate background
;  -peir, pser, peer, and state data will be auto-loaded as needed
;  -if both iesa and sst data sets are present the lower background estimate will be used 
;  -uses iesa data for background in the inner magnetosphere
;  -uses thm_pse_bkg_auto to calculate contribution from sst electrons
thm_load_esa_bkg, probe=probe, trange=trange


;get energy spectra and moments with and without background subtracted
;  -/esa_bgnd_advanced will disable default anode-based background subtraction
;  -/esa_bgnd_advanced can also be used with thm_part_combine and thm_part_slice2d
thm_part_products, probe=probe, trange=trange, datatype=datatype, outputs='energy moments'
thm_part_products, probe=probe, trange=trange, datatype=datatype, outputs='energy moments', $
                   /esa_bgnd_advanced, suffix='_sub'


prefix = 'th'+probe+'_'+datatype+'_'

;make pseudo-var for density
store_data, prefix + 'density_all', data = prefix + 'density' + ['','_sub']
options, '*density_sub', colors='b' 

options, '*eflux_energy*', zrange=[100,1e6]

window, xs=900, ys=1000
tplot, 'th'+probe+'_'+datatype+'_' + ['density_all','eflux_energy*']


end