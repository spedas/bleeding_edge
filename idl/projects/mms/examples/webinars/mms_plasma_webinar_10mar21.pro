; Special MMS Plasma Webinar on FPI/HPCA Analysis using SPEDAS 
; Wednesday, March 10, 2021
; Eric Grimes - egrimes@igpp.ucla.edu
;
;
; *** warning: we will be recording this for users who can't make it today! ***
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
;        
; *** warning: we will be recording this for users who can't make it today! ***
;====================================================================================

trange = ['2016-12-09/09:00', '2016-12-09/09:50']

; find MMS events with 'current' in them in this time range
mms_event_search, 'current', trange=trange
stop

; find burst segments in this trange
spd_mms_load_bss, trange=trange, datatype='burst', /include_labels
stop

; load the DES and DIS moments data
mms_load_fpi, datatype=['des-moms', 'dis-moms'], trange=trange, probe=1, /time_clip, /center_measurement

tplot, ['mms_bss_burst', 'mms1_dis_numberdensity_fast', 'mms1_des_numberdensity_fast', 'mms1_dis_energyspectr_omni_fast', 'mms1_des_energyspectr_omni_fast']
stop

options, 'mms1_dis_numberdensity_fast', colors=0
tplot ; empty call to tplot re-plots the data with the updated metadata
stop

; add the FPI Data Quality Flags bar
; see: https://lasp.colorado.edu/galaxy/display/mms/FPI+Data+Quality+Flags
tplot, 'mms1_des_errorflags_fast_moms_flagbars', /add
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
get_data, 'mms1_hpca_hplus_flux_elev_0-360_spin', data=d, dlimits=metadata, limits=limits
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

; add error bars to a variable
get_data, 'mms1_dis_numberdensity_fast', data=dis_n, dlimits=dis_metadata, limits=dis_limits
get_data, 'mms1_dis_numberdensity_err_fast', data=dis_err

; note: multiplying the error by 100 so that it shows up on the figure
store_data, 'mms1_dis_numberdensity_with_err', data={x: dis_n.X, y: dis_n.Y, dy: 100*dis_err.Y}, dlimits=dis_metadata, limits=dis_limits
stop

tplot, ['mms1_dis_energyspectr_omni_fast', 'hpca_eflux', 'mms1_dis_numberdensity_with_err', 'mms1_hpca_hplus_number_density']
stop

; zoom into a trange
tlimit, ['2016-12-09/09:02', '2016-12-09/09:04']
stop

flatten_spectra, /xlog, /ylog, /bar
stop

tplot, 'mms1_dis_energyspectr_omni_fast'

flatten_spectra_multi, 4, /xlog, /ylog, /bar, /legend_left
stop

; flatten_spectra has keywords to put the units on the same scale
tplot, ['mms1_dis_energyspectr_omni_fast', 'mms1_hpca_hplus_flux_elev_0-360_spin']
stop

flatten_spectra, /to_kev, /to_flux, /xlog, /ylog, /bar
stop

; to create figures with panels that contain different types of variables
; with different axes, use tplot_multiaxis
tplot_multiaxis, ['mms1_dis_energyspectr_omni_fast', 'mms1_hpca_hplus_flux_elev_0-360_spin'], $ ; left plots
  ['mms1_dis_numberdensity_fast', 'mms1_hpca_hplus_number_density'], [1, 2] ; right plots
stop

; note: the density labels overlap with the ytitles on the right-hand side
; to turn these off, use options again
options, 'mms1_dis_numberdensity_fast', labels=''
options, 'mms1_hpca_hplus_number_density', labels=''

; now recreate the figure
tplot_multiaxis, ['mms1_dis_energyspectr_omni_fast', 'mms1_hpca_hplus_flux_elev_0-360_spin'], $ ; left plots
  ['mms1_dis_numberdensity_fast', 'mms1_hpca_hplus_number_density'], [1, 2] ; right plots
stop

; to get the colorbars back, increase the margin on the right side
; (the colorbars are still there, just moved outside of the margins)
; note: tplot_options is used to set global plot options (as opposed to 
;       'options' setting options on a single variable)
tplot_options, 'xmargin', [15, 25]
tplot_multiaxis, ['mms1_dis_energyspectr_omni_fast', 'mms1_hpca_hplus_flux_elev_0-360_spin'], $ ; left plots
  ['mms1_dis_numberdensity_fast', 'mms1_hpca_hplus_number_density'], [1, 2] ; right plots
stop

; another useful tool for loading and plotting FPI data is
; mms_fpi_ang_ang - with this, you can create angle-angle, angle-energy
; and pitch angle-energy plots from the distributions at a certain time
mms_fpi_ang_ang, '2016-12-09/09:03', data_rate='brst', species='i'
stop

; note: for HPCA angle-angle plots, the figures are for 1-half spin closest to the input time
mms_hpca_ang_ang, '2016-12-09/09:03', data_rate='brst', species='hplus'
stop

;====================================================================================
; 2) Energy, PA, gyro phase spectra from distributions (mms_part_getspec)
;
; relevant crib sheet: projects/mms/examples/advanced/mms_part_getspec_crib.pro
;====================================================================================

; shorter trange to save some time doing the calculations
trange = ['2016-12-09/09:00', '2016-12-09/09:05']

; by default, the FPI data are used
; note: use the /center_measurement keyword to center the FPI measurements
mms_part_getspec, trange=trange, species='i', probe=1, /center
tplot, ['mms1_dis_dist_fast_energy', 'mms1_dis_dist_fast_pa']
stop

; HPCA measurements are automatically centered
mms_part_getspec, trange=trange, instrument='hpca', species='hplus', probe=1
tplot, 'mms1_hpca_hplus_phase_space_density_energy', /add
stop

; limit the energy range from 100eV - 10000eV
mms_part_getspec, energy=[100, 10000], trange=trange, instrument='fpi', species='i', probe=1, /center
tplot, ['mms1_dis_dist_fast_energy']
stop

; limit the energy range from 100eV - 10000eV
mms_part_getspec, energy=[100, 10000], trange=trange, instrument='hpca', species='hplus', probe=1
tplot, 'mms1_hpca_hplus_phase_space_density_energy', /add
stop

; output the results in flux
mms_part_getspec, units='flux', trange=trange, instrument='hpca', species='hplus', probe=1
tplot, ['mms1_hpca_hplus_phase_space_density_energy', 'mms1_hpca_hplus_flux_elev_0-360_spin']
stop

; S/C ram direction (X)
; B-field direction (+, -) 
mms_part_getspec, /add_bfield_dir, /add_ram_dir, trange=trange, output=['phi', 'theta'], species='i', probe=1, /center
tplot, ['mms1_dis_dist_fast_theta_with_bv', 'mms1_dis_dist_fast_phi_with_bv']
stop

mms_part_getspec, dir_interval=10, /add_bfield_dir, /add_ram_dir, trange=trange, output='phi theta', species='i', probe=1, /center
tplot, ['mms1_dis_dist_fast_theta_with_bv', 'mms1_dis_dist_fast_phi_with_bv']
stop

trange = ['2016-12-09/09:03:54', '2016-12-09/09:04:54']
mms_part_getspec, output=['energy', 'pa', 'gyro', 'multipad'], data_rate='brst', trange=trange, instrument='fpi', species='i', probe=1, /center
tplot, ['mms1_dis_dist_brst_energy', 'mms1_dis_dist_brst_pa', 'mms1_dis_dist_brst_gyro']
stop

tlimit, ['2016-12-09/09:03:54', '2016-12-09/09:04:04']
stop

mms_part_getpad, energy=[0, 100], species='i', data_rate='brst'
mms_part_getpad, energy=[100, 1000], species='i', data_rate='brst'
mms_part_getpad, energy=[1000, 10000], species='i', data_rate='brst'
mms_part_getpad, energy=[10000, 20000], species='i', data_rate='brst'
mms_part_getpad, energy=[20000, 30000], species='i', data_rate='brst'
stop

tplot, 'mms1_dis_dist_brst_pad_'+['0eV_100eV', '100eV_1000eV', '1000eV_10000eV', '10000eV_20000eV', '20000eV_30000eV']
stop

flatten_spectra, /ylog, /bar
stop

; set the ysubtitle to '[deg]', and the units will work out on the flatten_spectra figure
options, 'mms1_dis_dist_brst_pad_'+['0eV_100eV', '100eV_1000eV', '1000eV_10000eV', '10000eV_20000eV', '20000eV_30000eV'], 'ysubtitle', '[deg]'
tplot
stop

flatten_spectra, /replot, /ylog, /bar
stop

; subtract_bulk: subtract the bulk velocity prior to doing the calculations
; subtract_error: subtract the distribution error prior to doing the calculations
; subtract_spintone: subtract the spin-tone from the velocity vector prior to bulk velocity subtraction
mms_part_getspec, /subtract_bulk, /subtract_spintone, /subtract_error, trange=trange, data_rate='brst', instrument='fpi', species='i', probe=1
tplot, ['mms1_dis_dist_brst_energy']
stop

;====================================================================================
; 3) 2D velocity/energy slices from distributions (mms_part_slice2d)
;
;
;====================================================================================

;   3D Interpolation:
;     The entire 3-dimensional distribution is linearly interpolated onto a
;     regular 3d grid and a slice is extracted from the volume.
;
;   2D Interpolation:
;     Datapoints within the specified theta or z-axis range are projected onto
;     the slice plane and linearly interpolated onto a regular 2D grid.
;
;   Geometric (default):
;     Each point on the plot is given the value of the bin it intersects.
;     This allows bin boundaries to be drawn at high resolutions.
mms_part_slice2d, time='2017-09-10/09:30:20', instrument='fpi', species='i', probe=1, /two_d_interp
stop

; limit the energy range to 0-300 eV
mms_part_slice2d, erange=[0, 300], time='2017-09-10/09:30:20', instrument='fpi', species='i', probe=1, /two_d_interp
stop

; align the data relative to the magnetic field and/or bulk velocity using the 'rotation' keyword
; 
; the following is copy+pasted from the header of mms_part_slice2d:
;            'BV':  The x axis is parallel to B field; the bulk velocity defines the x-y plane
;            'BE':  The x axis is parallel to B field; the B x V(bulk) vector defines the x-y plane
;            'xy':  (default) The x axis is along the data's x axis and y is along the data's y axis
;            'xz':  The x axis is along the data's x axis and y is along the data's z axis
;            'yz':  The x axis is along the data's y axis and y is along the data's z axis
;            'xvel':  The x axis is along the data's x axis; the x-y plane is defined by the bulk velocity
;            'perp':  The x axis is the bulk velocity projected onto the plane normal to the B field; y is B x V(bulk)
;            'perp_xy':  The data's x & y axes are projected onto the plane normal to the B field
;            'perp_xz':  The data's x & z axes are projected onto the plane normal to the B field
;            'perp_yz':  The data's y & z axes are projected onto the plane normal to the B field
mms_part_slice2d, rotation='bv', erange=[0, 300], time='2017-09-10/09:30:20', instrument='fpi', species='i', probe=1, /two_d_interp
stop

; create the same figure for HPCA H+
mms_part_slice2d, rotation='bv', erange=[0, 300], time='2017-09-10/09:30:20', instrument='hpca', species='hplus', probe=1, /two_d_interp
stop

; now create the figure in flux units
mms_part_slice2d, units='flux', species='i', rotation='bv', erange=[0, 300], time='2017-09-10/09:30:20', probe=1, /two_d_interp
stop

; now create slices in the solar wind
mms_part_slice2d, time='2016-12-06/11:36', probe=4, species='i', /two_d_interp
stop

; subtract the bulk velocity
mms_part_slice2d, time='2016-12-06/11:36', probe=4, species='i', /subtract_bulk, /two_d_interp
stop

; subtract the error and the bulk velocity prior to creating the slice
mms_part_slice2d, time='2016-12-06/11:36', probe=4, species='i', /subtract_bulk, /subtract_error, /two_d_interp
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
mms_load_fpi, datatype='dis-moms', trange=trange, probe=1, /time_clip, /center_measurement
mms_load_hpca, datatype='moments', trange=trange, probe=1, /time_clip, /center_measurement

window, xsize=1000, ysize=650
tplot, ['mms1_fgm_b_gsm_srvy_l2_bvec', 'mms1_dis_numberdensity_fast', 'mms1_dis_bulkv_gse_fast', 'mms1_dis_energyspectr_omni_fast']
stop

tlimit, /full
stop

mms_flipbookify, seconds=10, species='i', probe=1, erange=[0, 300], data_rate='fast'
stop

tplot, ['mms1_fgm_b_gsm_srvy_l2_bvec', 'mms1_hpca_hplus_number_density', 'mms1_hpca_hplus_ion_bulk_velocity']
mms_flipbookify, seconds=10, species='hplus', probe=1, erange=[0, 300], data_rate='srvy', instrument='hpca'
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

stop
end