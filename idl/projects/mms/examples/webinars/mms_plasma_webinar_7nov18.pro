; Special MMS Plasma Webinar on FPI/HPCA Analysis using SPEDAS - Updated
; Eric Grimes - egrimes@igpp.ucla.edu
; 
; questions? feel free to unmute and ask during the presentation or email egrimes@igpp.ucla.edu after!
;
; note: a recent copy of the SPEDAS bleeding edge is required for some features in this script;
;       if you need to update, you can find the download link at the top of the SPEDAS changelog:
;       http://spedas.org/changelog/
;
; this file will be found in SPEDAS at:
;     projects/mms/examples/webinars/
;     
;Tentative agenda:
;  1) Introduction to FPI and HPCA load routines and keywords
;  2) Energy, PA, gyro phase spectra from distributions (mms_part_getspec)
;  3) 2D velocity/energy slices from distributions (mms_part_slice2d)
;  4) Combining time series moments/spectra with 2D slices (mms_flipbookify)
;  5) Visualizing the distributions in 3D (mms_part_isee3d)
;  
;====================================================================================
; 1) Introduction to load routines, keywords
;
; More information on the FPI and HPCA datasets can be found at:
;   https://lasp.colorado.edu/mms/sdc/public/datasets/fpi/
;   https://lasp.colorado.edu/mms/sdc/public/datasets/hpca/
;
;          Be sure to read the release notes!
;
; More examples can be found in the SPEDAS distribution at:
;   projects/mms/examples/
;
; Load routine standard keywords:
;   trange: [start, end]
;   probes: [1, 2, 3, 4]
;   datatype (see header of mms_load_fpi or mms_load_hpca)
;   level: l2
;   suffix: append a suffix to the variable names
;
;   center_measurement: adjust time stamps of the data so that each
;       timestamp corresponds to the center of the measurement
;
;   (many more available - see the header of each load routine)
;
;
; note: the load routines use defaults for keywords not explicitly provided;
;       to find which defaults are being used, check:
;        1) the header of the load routine
;        2) the first few lines of the procedure
;====================================================================================

trange = ['2017-09-10/09:30:20', '2017-09-10/09:34:20']

mms_load_fpi, datatype=['des-moms', 'dis-moms'], trange=trange, probe=1, /time_clip, /center_measurement

tplot, ['mms1_dis_numberdensity_fast', 'mms1_dis_energyspectr_omni_fast']
stop

options, 'mms1_dis_numberdensity_fast', colors=0
tplot
stop

mms_load_hpca, datatype='moments', trange=trange, probe=1, /time_clip, /center_measurement
tplot, 'mms1_hpca_hplus_number_density', /add
stop

mms_load_hpca, datatype='ion', trange=trange, probe=1, /time_clip, /center_measurement
stop

; since the HPCA data is multi-dimensional (i.e., function of both energy and anodes), we need to
; sum the data over the full field of view (all anodes) and average over the spin to get the omni-directional energy spectra
mms_hpca_calc_anodes, fov=[0, 360] ; can also specify anode #s individually via the 'anodes' keyword
mms_hpca_spin_sum, probe=1, /avg
stop

; to get data and metadata out of a tplot variable and store it into an IDL structure, use the get_data procedure
get_data, 'mms1_hpca_hplus_flux_elev_0-360_spin', data=d, dlimits=metadata
stop

; time data is stored in d.X, flux data is stored in d.Y, energies are stored in d.V
help, d
stop

help, metadata
stop

; we can convert to energy flux units by looping over time, multiplying each data point by the energy
for time_idx = 0, n_elements(d.X)-1 do append_array, eflux, d.Y[time_idx, *]*d.V
stop

; and store the data back to a tplot variable using store_data
store_data, 'hpca_eflux', data={x: d.X, y: eflux, v: d.V}
stop

tplot, ['mms1_dis_energyspectr_omni_fast', 'hpca_eflux', 'mms1_dis_numberdensity_fast', 'mms1_hpca_hplus_number_density']
stop

; turn it into a spectra
options, 'hpca_eflux', spec=1, ylog=1, zlog=1, ztitle='[keV/(cm^2 s sr keV)]', ytitle='HPCA H+', ysubtitle='[eV]'
tplot
stop

flatten_spectra, /xlog, /ylog, /bar
stop

tplot, 'mms1_dis_energyspectr_omni_fast'

flatten_spectra_multi, 4, /xlog, /ylog, /bar, /legend_left
stop

; another useful tool for loading and plotting FPI data is
; mms_fpi_ang_ang - with this, you can create angle-angle, angle-energy
; and pitch angle-energy plots from the distributions at a certain time
mms_fpi_ang_ang, '2017-09-10/09:32:20', species='i'
stop

;====================================================================================
; 2) Energy, PA, gyro phase spectra from distributions (mms_part_getspec)
;
; relevant crib sheet: projects/mms/examples/advanced/mms_part_getspec_crib.pro
;====================================================================================

mms_part_getspec, trange=trange, species='i', probe=1, /center
tplot, ['mms1_dis_dist_fast_energy', 'mms1_dis_energyspectr_omni_fast', 'mms1_des_dist_fast_pa']
stop

; HPCA measurements are automatically centered
mms_part_getspec, trange=trange, instrument='hpca', species='hplus', probe=1
tplot, 'mms1_hpca_hplus_phase_space_density_energy', /add
stop

mms_part_getspec, energy=[0, 300], trange=trange, instrument='fpi', species='i', probe=1
tplot, ['mms1_dis_dist_fast_energy']
stop

mms_part_getspec, energy=[0, 300], trange=trange, instrument='hpca', species='hplus', probe=1
tplot, 'mms1_hpca_hplus_phase_space_density_energy', /add
stop

mms_part_getspec, units='flux', trange=trange, instrument='hpca', species='hplus', probe=1
tplot, ['mms1_hpca_hplus_phase_space_density_energy', 'mms1_hpca_hplus_flux_elev_0-360_spin']
stop

mms_part_getspec, /add_bfield_dir, /add_ram_dir, trange=trange, output=['phi', 'theta'], species='i', probe=1, /center
tplot, ['mms1_dis_dist_fast_theta_with_bv', 'mms1_dis_dist_fast_phi_with_bv']
stop

mms_part_getspec, dir_interval=10, /add_bfield_dir, /add_ram_dir, trange=trange, output='phi theta', species='i', probe=1, /center
tplot, ['mms1_dis_dist_fast_theta_with_bv', 'mms1_dis_dist_fast_phi_with_bv']
stop

trange = ['2015-12-15/00:20', '2015-12-15/00:30']
tic
mms_part_getspec, output=['energy', 'pa', 'gyro', 'multipad'], trange=trange, instrument='fpi', species='e', probe=1
toc
tplot, ['mms1_des_dist_fast_energy', 'mms1_des_dist_fast_pa', 'mms1_des_dist_fast_gyro']
stop

mms_part_getpad, energy=[0, 100]
mms_part_getpad, energy=[100, 1000]
mms_part_getpad, energy=[1000, 10000]
mms_part_getpad, energy=[10000, 20000]
mms_part_getpad, energy=[20000, 30000]
stop

tplot, 'mms1_des_dist_fast_pad_'+['0eV_100eV', '100eV_1000eV', '1000eV_10000eV', '10000eV_20000eV', '20000eV_30000eV']
stop

flatten_spectra, /ylog, /bar
stop

trange = ['2016-12-06/11:35', '2016-12-06/11:37']
mms_part_getspec, trange=trange, instrument='fpi', species='i', probe=1
tplot, ['mms1_dis_dist_fast_energy']
stop

mms_part_getspec, /subtract_bulk, /subtract_spintone, /subtract_error, trange=trange, instrument='fpi', species='i', probe=1
tplot, ['mms1_dis_dist_fast_energy']
stop


;====================================================================================
; 3) 2D velocity/energy slices from distributions (mms_part_slice2d)
;
;
;====================================================================================

mms_part_slice2d, time='2017-09-10/09:30:20', instrument='fpi', species='i', probe=1
stop

mms_part_slice2d, erange=[0, 300], time='2017-09-10/09:30:20', instrument='fpi', species='i', probe=1
stop

mms_part_slice2d, rotation='bv', erange=[0, 300], time='2017-09-10/09:30:20', instrument='fpi', species='i', probe=1
stop

mms_part_slice2d, rotation='bv', erange=[0, 300], time='2017-09-10/09:30:20', instrument='hpca', species='hplus', probe=1
stop

mms_part_slice2d, units='flux', rotation='bv', erange=[0, 300], time='2017-09-10/09:30:20', probe=1
stop

mms_part_slice2d, time='2016-12-06/11:36', probe=4, species='i'
stop

mms_part_slice2d, time='2016-12-06/11:36', probe=4, species='i', /subtract_bulk
stop

mms_part_slice2d, time='2016-12-06/11:36', probe=4, species='i', /subtract_bulk, /subtract_error
stop

;====================================================================================
; 4) Combining time series moments/spectra with 2D slices (mms_flipbookify)
; mms_flipbookify turns your current tplot window into a flipbook style series of
; images containing the line/spectra plots and 2D slices
;
; relevant crib sheet: projects/mms/examples/advanced/mms_flipbook_crib.pro
;
;====================================================================================

trange = ['2017-09-10/09:30:20', '2017-09-10/09:34']

mms_load_fgm, trange=trange, probe=1, /time_clip
mms_load_fpi, datatype=['des-moms', 'dis-moms'], trange=trange, probe=1, /time_clip, /center_measurement

tplot, ['mms1_fgm_b_gsm_srvy_l2_bvec', 'mms1_dis_numberdensity_fast', 'mms1_dis_bulkv_gse_fast', 'mms1_dis_energyspectr_omni_fast']
stop

mms_flipbookify, seconds=10, species='i', probe=1, erange=[0, 300], data_rate='fast'
stop

mms_load_hpca, datatype='moments', trange=trange, probe=1, /time_clip, /center_measurement
tplot, ['mms1_fgm_b_gsm_srvy_l2_bvec', 'mms1_hpca_hplus_number_density', 'mms1_hpca_hplus_ion_bulk_velocity', 'mms1_hpca_hplus_phase_space_density_energy']
mms_flipbookify, seconds=10, trange=['2017-09-10/09:30:30', '2017-09-10/09:34'], species='hplus', probe=1, erange=[0, 300], data_rate='srvy', instrument='hpca'
stop

tplot, ['mms1_fgm_b_gsm_srvy_l2_bvec', 'mms1_dis_numberdensity_fast', 'mms1_dis_bulkv_gse_fast', 'mms1_dis_energyspectr_omni_fast']
mms_flipbookify, seconds=10, slices=['bv', 'perp', 'perp_xy'], species='i', probe=1, erange=[0, 300], data_rate='fast', xrange=[-100, 100], yrange=[-100, 100]
stop

tplot, ['mms1_fgm_b_gsm_srvy_l2_bvec', 'mms1_dis_numberdensity_fast', 'mms1_dis_bulkv_gse_fast', 'mms1_dis_energyspectr_omni_fast']
mms_flipbookify, seconds=10, /video, slices=['bv', 'perp', 'perp_xy'], species='i', probe=1, erange=[0, 300], data_rate='fast', xrange=[-100, 100], yrange=[-100, 100]
stop

;====================================================================================
; 5) Visualizing the distributions in 3D (mms_part_isee3d)
;
; relevant crib sheet: projects/mms/examples/advanced/mms_isee_3d_crib_basic.pro
;
;====================================================================================

timespan, '2015-11-18/02:10:00', 30, /sec

mms_part_isee3d, species='i'
stop

mms_part_isee3d, species='hplus', instrument='hpca'
stop

end