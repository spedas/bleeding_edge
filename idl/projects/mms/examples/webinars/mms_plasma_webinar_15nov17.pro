; Special MMS plasma webinar on FPI/HPCA with SPEDAS
; 
; NOTE (11/16/2017): the dates/times in most of the examples were changed after the webinar
;                    due to some of the files for the previous dates/times not being 
;                    available to public users via the SDC. 
; 
; Please be sure to mute your phone during the webinar!
; 
; questions? feel free to unmute and ask during the presentation or email egrimes@igpp.ucla.edu after!
; 
; note: a recent copy of the SPEDAS bleeding edge is required for some features in this script; 
;       if you need to update, you can find the download link at the top of the SPEDAS changelog: 
;       http://spedas.org/changelog/
; 
; this file can be found on the web at:
;     http://spedas.org/mms/mms_plasma_webinar_nov17.pro
; 
; -----> Phone to use: 510-643-3817 
; 
; Tentative agenda:
; 1) Introduction to FPI and HPCA load routines and keywords
; 2) Energy, PA, gyro phase spectra from distributions (mms_part_getspec)
; 3) 2D velocity/energy slices from distributions (spd_slice2d)
; 4) Combining time series moments/spectra with 2D slices (mms_flipbookify)
; 5) Visualizing the distributions in 3D (isee_3d)
;
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

; to check when data is available, but without actually downloading the data, the load routines
; support the /available keyword, e.g., to find the available data for the month of Oct 2015
mms_load_hpca, trange=['2016-10-1', '2016-10-31'], /available
stop

; HPCA flux and PSD data are available via the datatype: 'ion'
mms_load_hpca, trange=['2016-10-1', '2016-10-31'], /available, datatype='ion'
stop

; to load 1 hour of HPCA ion distribution data on 16Oct2015
mms_load_hpca, trange=['2017-10-10/12', '2017-10-10/13'], datatype='ion', probe=1, /time_clip, /center_measurement
stop

; to list the variables loaded, use tplot_names or tnames(), e.g., 
tplot_names ; procedure prints the variables with their variable #s
tplot_variables = tnames() ; tnames is a function that returns the list of loaded variables
stop

; we can use print_tinfo to find information on a tplot variable
print_tinfo, 'mms1_hpca_hplus_flux'
stop

; we can also use tplot_names to find even more information on a tplot variable
; using the /verbose keyword
tplot_names, 'mms1_hpca_hplus_flux', /verbose
stop

; want to find the time range of a tplot variable? there's the /time_range keyword
tplot_names, 'mms1_hpca_hplus_flux', /time_range
stop

; tplot_names and tnames() also accept wildcard arguments for matching multiple 
; variables, e.g., to find the time range of the H+, O+, He+ and He++ variables,
; simply replace 'h' with '*':
tplot_names, 'mms1_hpca_*plus_flux', /time_range
stop

; since the HPCA data is multi-dimensional (i.e., function of both energy, anodes), we need to 
; sum the data over the full field of view (all anodes) to get the omni-directional energy spectra
mms_hpca_calc_anodes, fov=[0, 360] ; can also specify anode #s individually via the 'anodes' keyword

tplot, ['mms1_hpca_hplus_flux_elev_0-360', 'mms1_hpca_oplus_flux_elev_0-360', 'mms1_hpca_heplus_flux_elev_0-360', 'mms1_hpca_heplusplus_flux_elev_0-360']
stop


; NOTE/example added after webinar (11/16/2017) - to get a true omni-directional spectra, one must
; also sum over the spin period, e.g.,
mms_hpca_spin_sum, probe=1
stop

; now plot the omni-directional spectra
tplot, ['mms1_hpca_hplus_flux_elev_0-360_spin', 'mms1_hpca_oplus_flux_elev_0-360_spin', 'mms1_hpca_heplus_flux_elev_0-360_spin', 'mms1_hpca_heplusplus_flux_elev_0-360_spin']
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
for time_idx = 0, n_elements(d.X)-1 do begin
  append_array, eflux, d.Y[time_idx, *]*d.V
endfor
stop

; and store the data back to a tplot variable using store_data
store_data, 'eflux', data={x: d.X, y: eflux, v: d.V}
stop

; now plot the energy flux instead of flux; note that by default, store_data creates a line plot
tplot, 'eflux'
stop

; turn it into a spectra
options, 'eflux', spec=1, ylog=1, zlog=1
tplot ; empty call to tplot replots the current variable with updated metadata
stop

; valid datatypes for FPI: 
; electrons: des-moms, des-dist
; ions: dis-moms, dis-dist
mms_load_fpi, trange=['2017-10-10/12', '2017-10-10/13'], datatype='dis-moms', probe=1, /time_clip, /center_measurement

; the /add keyword adds the plot to the top panel of the current figure
tplot, 'mms1_dis_energyspectr_omni_fast', /add
stop

; create a line plot of the FPI and HPCA spectra at a certain time
; black line = top panel; blue line = second panel
flatten_spectra, /ylog, /xlog
stop

; another useful tool for loading and plotting FPI data is
; mms_fpi_ang_ang - with this, you can create angle-angle, angle-energy 
; and pitch angle-energy plots from the distributions at a certain time
mms_fpi_ang_ang, '2017-10-10/12:30', species='e'
stop

;====================================================================================
; 2) Energy, PA, gyro phase spectra from distributions (mms_part_getspec)
; note: variables produced by mms_part_getspec are controlled via the 'output' keyword
; 
; relevant crib sheet: projects/mms/examples/advanced/mms_part_products_crib.pro
;====================================================================================

mms_part_getspec, output='energy', trange=['2017-10-10/12', '2017-10-10/13'], probe=1, instrument='fpi', species='i'

; now we can compare the omni directional ion spectra found in the moments files
; with the ion spectra calculated directly from the distribution data using SPEDAS
tplot, ['mms1_dis_energyspectr_omni_fast', 'mms1_dis_dist_fast_energy']
stop

; energy keyword allows you to restrict the energy range; values are expected to be eV
mms_part_getspec, energy=[100, 1000], suffix='_100eV-1000eV', trange=['2017-10-10/12', '2017-10-10/13'], probe=1, instrument='fpi', species='i'

tplot, ['mms1_dis_dist_fast_energy', 'mms1_dis_dist_fast_energy_100eV-1000eV']
stop

; you can specify the output units via the keyword: 'units', e.g., to generate the HPCA ion eflux spectra directly
; from the ion phase space density
mms_part_getspec, units='eflux', trange=['2017-10-10/12', '2017-10-10/13'], probe=1, instrument='hpca', /center_measurement

; now we're plotting FPI energy spectra on top 2 panels, HPCA on bottom 2 panels
; first panel was generated from the PSD, second panel provided by team in CDF files
tplot, ['mms1_dis_dist_fast_energy', 'mms1_dis_energyspectr_omni_fast', 'mms1_hpca_hplus_phase_space_density_energy', 'eflux']
stop

; now we can plot all 4 spectra at a single time
flatten_spectra, /ylog, /xlog
stop

; output can also be energy, pa, gyro, theta and/or phi
mms_part_getspec, output='energy pa gyro theta phi', species='e', trange=['2017-10-10/12', '2017-10-10/13'], probe=1, instrument='fpi'
tplot, ['mms1_des_dist_fast_energy', 'mms1_des_dist_fast_pa', 'mms1_des_dist_fast_gyro', 'mms1_des_dist_fast_theta', 'mms1_des_dist_fast_phi']
stop

;====================================================================================
; 3) 2D velocity/energy slices from distributions (spd_slice2d)
; 
; relevant crib sheets:
;     projects/mms/examples/advanced/mms_slice2d_fpi_crib.pro
;     projects/mms/examples/advanced/mms_slice2d_hpca_crib.pro
;
;====================================================================================

mms_load_fpi, trange=['2017-10-10/12', '2017-10-10/13'], datatype='dis-dist', probe=1, /time_clip, /center_measurement

fpi_dist = mms_get_dist('mms1_dis_dist_fast', trange=['2017-10-10/12', '2017-10-10/13'])

slice = spd_slice2d(fpi_dist, time='2017-10-10/12:46', window=10, rotation='xy')
spd_slice2d_plot, slice

stop

; now let's plot the slice in the BV (magnetic field-velocity) frame
; note: we need the FPI ion velocity (from FPI moments files) and FGM data to transform into that frame
mms_load_fpi, trange=['2017-10-10/12', '2017-10-10/13'], datatype='dis-moms', probe=1, /time_clip, /center_measurement
mms_load_fgm, trange=['2017-10-10/12', '2017-10-10/13'], probe=1, /time_clip

; field data and velocity data are passed via keywords: 
;     mag_data, vel_data
slice = spd_slice2d(fpi_dist, time='2017-10-10/12:46', samples=10, rotation='bv', mag_data='mms1_fgm_b_dmpa_srvy_l2_bvec', vel_data='mms1_dis_bulkv_dbcs_fast')
;stop

; spd_slice2d_plot has many keywords for controlling / saving the output images, e.g., 
spd_slice2d_plot, slice, /plotbfield, /plotbulk, background_color_rgb=[0, 255, 0]
stop

mms_load_hpca, datatype='ion', trange=['2017-10-10/12', '2017-10-10/13'], probe=1, /time_clip, /center_measurement
hpca_dist = mms_get_dist('mms1_hpca_hplus_phase_space_density', trange=['2017-10-10/12', '2017-10-10/13'])
slice = spd_slice2d(hpca_dist, time='2017-10-10/12:46', samples=10, rotation='xy')
spd_slice2d_plot, slice

stop

;====================================================================================
; 4) Combining time series moments/spectra with 2D slices (mms_flipbookify)
; mms_flipbookify turns your current tplot window into a flipbook style series of
; images containing the line/spectra plots and 2D slices
; 
; relevant crib sheet: projects/mms/examples/advanced/mms_flipbook_crib.pro
; 
; note: this won't work if the previous 2D slices are still plotted; 
; --> so .full_reset_session is required here!
;====================================================================================
mms_load_fpi, trange=['2017-10-10/13', '2017-10-10/13:07'], data_rate='brst', datatype='dis-moms', probe=1, /time_clip, /center_measurement

; combine 2 tplot variables using store_data
store_data, 'fpi_temp', data=['mms1_dis_temppara_brst', 'mms1_dis_tempperp_brst']
options, 'fpi_temp', labflag=1
stop

; by default, tplot interpolates through gaps in the data; you can remove this with tdegap, e.g., 
tdegap, /overwrite, ['mms1_dis_energyspectr_omni_brst', 'mms1_dis_bulkv_gse_brst', 'mms1_dis_numberdensity_brst', 'mms1_dis_temppara_brst', 'mms1_dis_tempperp_brst']
stop

tplot, ['mms1_dis_energyspectr_omni_brst', 'mms1_dis_bulkv_gse_brst', 'mms1_dis_numberdensity_brst', 'fpi_temp']
stop

; note: default instrument is FPI
mms_flipbookify, species='i', time_step=10, data_rate='brst'
stop

; this also works for HPCA
mms_load_hpca, /latest_version, trange=['2017-10-10/12', '2017-10-10/13'], data_rate='srvy', datatype='moments', probe=1, /time_clip, /center_measurement

mms_part_getspec, trange=['2017-10-10/12', '2017-10-10/13'], probe=1, instrument='hpca', units='eflux', data_rate='srvy'

; since mms_flipbookify works with any tplot window, you can use other SPEDAS load routines to 
; load and plot data from other missions to include in the plot, e.g., 
omni_load_data, trange=['2017-10-10/12', '2017-10-10/13']
stop

tplot, ['mms1_hpca_hplus_phase_space_density_energy', 'mms1_hpca_hplus_ion_bulk_velocity', 'mms1_hpca_hplus_number_density', 'OMNI_HRO_1min_SYM_H', 'OMNI_HRO_1min_proton_density', 'OMNI_HRO_1min_BZ_GSM']

; /video keyword turns the images into a video; see the header of mms_flipbookify for keywords
; that allow you to control the video options (format, FPS, bit rate)
mms_flipbookify, instrument='hpca', species='hplus', time_step=10, /video
stop

;====================================================================================
; 5) Visualizing the distributions in 3D (isee_3d)
; 
; relevant crib sheet: projects/mms/examples/advanced/mms_isee_3d_crib_basic.pro
; 
;====================================================================================

mms_load_fpi, trange=['2017-10-10/02:31', '2017-10-10/02:33'], data_rate='brst', datatype=['dis-dist', 'dis-moms'], probe=1, /time_clip, /center_measurement
mms_load_fgm, trange=['2017-10-10/02:31', '2017-10-10/02:33']

fpi_dist = mms_get_dist('mms1_dis_dist_brst' , trange=['2017-10-10/02:31', '2017-10-10/02:33'])

; convert structures to isee_3d data model
isee3d_data = spd_dist_to_hash(fpi_dist)
stop

; very important note: once the GUI is open, select PSD from Units menu, and 'Volume' as plot type (upper left)
isee_3d, data=isee3d_data, trange=['2017-10-10/02:31', '2017-10-10/02:33'], bfield='mms1_fgm_b_gse_srvy_l2_bvec', velocity='mms1_dis_bulkv_gse_brst'
stop

; ISEE 3D works with HPCA data as well
mms_load_hpca, trange=['2017-10-10/02:31', '2017-10-10/02:33'], datatype='ion', probe=1, /time_clip, /center_measurement
mms_load_hpca, trange=['2017-10-10/02:31', '2017-10-10/02:33'], datatype='moments', probe=1, /time_clip, /center_measurement
mms_load_fgm, trange=['2017-10-10/02:31', '2017-10-10/02:33']

hpca_dist = mms_get_dist('mms1_hpca_hplus_phase_space_density' , trange=['2017-10-10/02:31', '2017-10-10/02:33'])

; convert structures to isee_3d data model
isee3d_data = spd_dist_to_hash(hpca_dist)
stop

; again, once the GUI is open, select PSD from Units menu, and 'Volume' as plot type
isee_3d, data=isee3d_data, trange=['2017-10-10/02:31', '2017-10-10/02:33'], bfield='mms1_fgm_b_gse_srvy_l2_bvec', velocity='mms1_hpca_hplus_ion_bulk_velocity'
stop

end