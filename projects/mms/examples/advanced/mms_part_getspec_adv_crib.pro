;+
;Procedure:
;  mms_part_getspec_adv_crib
;
;
;Purpose:
;  Advanced example on how to use mms_part_getspec to generate particle
;  spectrograms and moments from level 2 MMS HPCA and FPI distributions.
;
;  see also: mms_part_getspec_crib
;  
;$LastChangedBy: egrimes $
;$LastChangedDate: 2018-09-20 14:44:56 -0700 (Thu, 20 Sep 2018) $
;$LastChangedRevision: 25834 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/examples/advanced/mms_part_getspec_adv_crib.pro $
;-

tplot_options, 'xmargin', [10, 20]

; limit the energy range
mms_part_getspec, energy=[10, 1000], probe=1, output='energy pa theta phi', trange=['2015-10-16/13:06:56', '2015-10-16/13:06:58'], data_rate='brst', species='e', instrument='fpi'

tplot, ['mms1_des_dist_brst_energy', 'mms1_des_dist_brst_pa']
stop

; limit the pitch angle range
mms_part_getspec, pitch=[150, 180], probe=1, output='energy pa', trange=['2015-10-16/13:06:56', '2015-10-16/13:06:58'], data_rate='brst', species='e', instrument='fpi'

tplot, ['mms1_des_dist_brst_energy', 'mms1_des_dist_brst_pa']
stop

; use PSD units instead of energy flux
mms_part_getspec, units='df_km', probe=1, output='energy', trange=['2015-10-16/13:06', '2015-10-16/13:07'], data_rate='brst', species='e', instrument='fpi'

tplot, 'mms1_des_dist_brst_energy'
stop

; compare HPCA flux generated with mms_part_getspec with the flux in the HPCA moments files
mms_part_getspec, instrument='hpca', units='flux', trange=['2017-08-12/23:20', '2017-08-12/23:35'], output='energy', probe=3
mms_load_hpca, datatype='moments', trange=['2017-08-12/23:20', '2017-08-12/23:35'], /time_clip, probe=3

; calculate the omni-directional flux for HPCA from the moments CDFs
mms_hpca_calc_anodes, fov=[0, 360], probe=3
mms_hpca_spin_sum, probe='3', /avg

; plot the fluxes for comparison
zlim, ['mms3_hpca_hplus_phase_space_density_energy', 'mms3_hpca_hplus_flux_elev_0-360_spin'], 0.1, 500, 1
tplot, ['mms3_hpca_hplus_phase_space_density_energy', 'mms3_hpca_hplus_flux_elev_0-360_spin']

; create a line plot of flux vs. energy 
flatten_spectra, /xlog, /ylog, time='2017-08-12/23:29:22'
stop

; compare electron moments generated with FPI team moments CDF files
; note: calculating moments for DES will include photoelectron corrections; see the 
;       header for information on the model
mms_part_getspec, energy=[10, 40000], probe=1, output='moments', trange=['2015-10-16/13:06:56', '2015-10-16/13:06:58'], data_rate='brst', species='e', instrument='fpi'
mms_load_fpi, probe=1, trange=['2015-10-16/13:06:56', '2015-10-16/13:06:58'], data_rate='brst', datatype='des-moms', /time_clip

; add error bars from the moments CDFs
get_data, 'mms1_des_numberdensity_err_brst', data=error_data
get_data, 'mms1_des_numberdensity_brst', data=data, dlimits=dl
store_data, 'mms1_des_numberdensity_brst_with_err', data={x: data.X, y: data.Y, dy: error_data.Y}, dlimits=dl

options, 'mms1_des_numberdensity_brst', labels='moments CDF'
options, 'mms1_des_dist_brst_density', labels='PGS'

; combine the 2 density products into a single panel
store_data, 'number_density', data='mms1_des_numberdensity_brst_with_err mms1_des_dist_brst_density'
options, 'number_density', labflag=-1
tplot, 'number_density'
stop

; add density of electrons >= 100 eV
mms_part_getspec, energy=[100, 35000], suffix='_100eV-35keV', probe=1, output='moments', trange=['2015-10-16/13:06:56', '2015-10-16/13:06:58'], data_rate='brst', species='e', instrument='fpi'

options, 'mms1_des_dist_brst_density_100eV-35keV', labels='PGS >100 eV', colors=6

store_data, 'number_density', data='mms1_des_numberdensity_brst_with_err mms1_des_dist_brst_density mms1_des_dist_brst_density_100eV-35keV'
options, 'number_density', labflag=-1
tplot, 'number_density'

stop
end