; Analyzing MMS data with SPEDAS
;     Eric Grimes, egrimes@igpp.ucla.edu
;
; You can find more information on the MMS datasets at the LASP SDC:
;     https://lasp.colorado.edu/mms/sdc/public/datasets/
;
; QL plots can be found at the SDC:
;     https://lasp.colorado.edu/mms/sdc/public/quicklook/
;
; Data availability status at the SDC:
;     https://lasp.colorado.edu/mms/sdc/public/about/processing/
;
; Browse the CDF files at the SDC:
;     https://lasp.colorado.edu/mms/sdc/public/data/
;
;
; Agenda:
; --> feel free to ask questions!
;
;  1. Introduction to load routines and keywords
;  2. FIELDS examples (FGM, SCM, EDP, EDI)
;  3. EPD examples (EIS, FEEPS)
;  4. Plasma examples (FPI, HPCA)
;  5. Questions / Demo Requests?
;
;
;
;=============================================================================
; Introduction to load routines and keywords
; - Load routines:
;       mms_load_fgm - Fluxgate Magnetometer
;       mms_load_scm - Search-coil Magnetometer
;       mms_load_edp - Electric-field Double Probe
;       mms_load_aspoc - Active Spacecraft Potential Control
;       mms_load_edi - Electron Drift Instrument
;       mms_load_feeps - Fly’s Eye Energetic Particle Sensor
;       mms_load_eis - Energetic Ion Spectrometer
;       mms_load_fpi - Fast Plasma Investigation
;       mms_load_hpca - Hot Plasma Composition Analyzer
;       mms_load_mec - Ephemeris and Coordinates
;       mms_load_dsp - Digital Signal Processor
;       mms_load_tqf - Tetrahedron Quality Factor
;       mms_load_brst_segments, mms_load_fast_segments - Data Availability
;
; - Keywords:
;       trange: time range of interest.
;       probe: spacecraft # (or array of S/C numbers - [1, 2, 3, 4])
;       data_rate: srvy, fast or brst
;       level: L2 (also available: l1b, l1a - non-L2 requires MMS team user/password)
;       time_clip: clip the data down to the time range specified in trange (e.g., /time_clip)
;       spdf: load data from SPDF instead of the LASP SDC (e.g., /spdf)
;
;       cdf_filenames: returns a list of CDF files loaded
;       versions: returns a list of CDF version #s for the loaded data
;
;       cdf_version: only load this specific version (e.g., ='3.2.1')
;       min_version: only load this version and later (e.g., ='3.2.1')
;       latest_version: only load the latest version found in the trange (e.g., /latest_version)
;       major_version: only load the latest major version found in the trange (e.g., /major_version)
;=============================================================================

start_time = systime(/sec)

; simple example - load and plot the spacecraft position
mms_load_mec, probes=[1, 2, 3, 4], trange=['2017-05-28', '2017-05-29']
tplot, ['mms1_mec_r_gsm', 'mms2_mec_r_gsm', 'mms3_mec_r_gsm', 'mms4_mec_r_gsm']
stop

; list all of the loaded tplot variables
tplot_names
stop

; list only the quaternions for MMS1
tplot_names, 'mms1_*_quat_*'
stop

; convert the position data from km to Re
tkm2re, ['mms1_mec_r_gsm', 'mms2_mec_r_gsm', 'mms3_mec_r_gsm', 'mms4_mec_r_gsm']
tplot, ['mms1_mec_r_gsm_re', 'mms2_mec_r_gsm_re', 'mms3_mec_r_gsm_re', 'mms4_mec_r_gsm_re']
stop

; use get_data to take the data out of a tplot variable and store it into IDL data structures
get_data, 'mms1_mec_r_gsm_re', data=data, dlimits=metadata
help, data
; note:
;;; data.X = unix times
;;; data.Y = data values, in Earth Radii
stop

; you can use find_nearest_neighbor to perform a binary search on the time series
closest_time = find_nearest_neighbor(data.X, time_double('2017-05-28/12:00'))
print, closest_time ; note: stored in unix time
stop

; to print the time as a string, use time_string
print, time_string(closest_time, tformat='YYYY-MM-DD/hh:mm:ss.fff')
stop

; to turn a time_string back into unix time, use time_double
print, time_double('2017-05-28/12:00')
stop

; to print the position data at this point, use "where"
where_this_time = where(data.X eq closest_time)
print, data.Y[where_this_time, *] ; note: this is safe because closest_time is a time that exists in our time series (since we found it using find_nearest_neighbor)
stop

; use the timebar routine to draw a vertical line on the plot at 12:00
timebar, '2017-05-28/12:00'
stop

; you can also use timebar with the /databar keyword to draw horizontal lines
timebar, 0.0, /databar, varname='mms1_mec_r_gsm_re', linestyle=1
timebar, 0.0, /databar, varname='mms2_mec_r_gsm_re', linestyle=2
timebar, 0.0, /databar, varname='mms3_mec_r_gsm_re', linestyle=3
timebar, 0.0, /databar, varname='mms4_mec_r_gsm_re', linestyle=4
stop

; note: SPEDAS has load routines for many datasets; see the 'projects' and 'general/missions' folders
kyoto_load_dst, trange=['2017-05-28', '2017-05-29'], /apply_time_clip
tplot, 'kyoto_dst'
stop

;=============================================================================
; FIELDS examples (FGM, SCM, EDP, EDI, ASPOC)
;=============================================================================

; load some brst mode FGM data
mms_load_fgm, trange=['2017-05-28', '2017-05-29'], data_rate='brst'
tplot, 'mms1_fgm_b_gsm_brst_l2_bvec', /add
stop

; remove the gaps between burst segments
tdegap, 'mms1_fgm_b_gsm_brst_l2_bvec', /overwrite
tplot ; replot the data 
stop

; find the burst intervals
mms_load_brst_segments, trange=['2017-05-28', '2017-05-29'], start_times=start_times, end_times=end_times
tplot, 'mms_bss_burst', /add
stop

; get the CDF version numbers and filenames for these data
mms_load_fgm, versions=numbers, cdf_filenames=files, trange=['2017-05-28', '2017-05-29'], data_rate='brst'
help, numbers
print, numbers
help, files

; add the CDF version number to the plot (bottom right)
mms_add_cdf_versions, 'FGM', numbers, /right
stop

; load data from all 4 spacecraft for curlometer calculations
mms_load_fgm, trange=['2017-05-28/03:48', '2017-05-28/04:00'], /get_fgm_ephemeris, probes=[1, 2, 3, 4], data_rate='brst'

fields = 'mms'+['1', '2', '3', '4']+'_fgm_b_gse_brst_l2'
positions = 'mms'+['1', '2', '3', '4']+'_fgm_r_gse_brst_l2'

; see header of mms_curl for reference on the curlometer technique
mms_curl, trange=['2017-05-28/03:48', '2017-05-28/04:00'], fields=fields, positions=positions
tplot, 'jtotal'
stop

; split the total current into X, Y, Z components
split_vec, 'jtotal'
tplot, ['jtotal', 'jtotal_x', 'jtotal_y', 'jtotal_z']
stop

; join the components back into another tplot variable using join_vec
join_vec, ['jtotal_x', 'jtotal_y', 'jtotal_z'], 'jtotal_new'
tplot, 'jtotal_new'
stop

; add the divergence of the B-field
tplot, /add, 'divB'
stop

; load data from the search coil magnetometer
mms_load_scm, trange=['2017-05-28', '2017-05-29']
tplot, 'mms1_scm_acb_gse_scsrvy_srvy_l2'
stop

; calculate dynamic power spectra
tdpwrspc, 'mms1_scm_acb_gse_scsrvy_srvy_l2', nboxpoints=512, nshiftpoints=512, bin=1
tplot, ['mms1_scm_acb_gse_scsrvy_srvy_l2_x_dpwrspc', $
        'mms1_scm_acb_gse_scsrvy_srvy_l2_y_dpwrspc', $
        'mms1_scm_acb_gse_scsrvy_srvy_l2_z_dpwrspc']
stop

; load and plot the DC E-field calibrated for SDP and ADP
mms_load_edp, probe=1, trange=['2017-05-28', '2017-05-29']
tplot, 'mms1_edp_dce_gse_fast_l2'
stop

; plot the E-field, drift velocity from EDI
mms_load_edi, probe=1, trange=['2016-10-13', '2016-10-14']
tplot, ['mms1_edi_vdrift_gsm_srvy_l2', 'mms1_edi_e_gsm_srvy_l2']
stop

; we can extract the data and metadata from the tplot variable using the get_data routine
get_data, 'mms1_edi_vdrift_gsm_srvy_l2', data=data, dlimits=metadata
help, /st, metadata 
stop

; load and plot the ASPOC ion beam currents
mms_load_aspoc, trange=['2017-05-28', '2017-05-29']
tplot, ['mms1_aspoc_ionc_l2', 'mms1_asp1_ionc_l2', 'mms1_asp2_ionc_l2']
stop

; delete all of the loaded tplot variables
del_data, '*' ; note: accepts wildcards: * and ?
stop

;=============================================================================
; EPD examples (EIS, FEEPS)
;=============================================================================

; load some EIS proton / oxygen data
mms_load_eis, trange=['2015-10-16', '2015-10-17']
tplot, ['mms1_epd_eis_extof_proton_flux_omni', $
        'mms1_epd_eis_extof_oxygen_flux_omni']
stop

mms_eis_pad
tplot, /add, ['mms1_epd_eis_extof_0-1000keV_proton_flux_omni_pad', $
              'mms1_epd_eis_extof_0-1000keV_oxygen_flux_omni_pad']
stop

mms_eis_pad, num_smooth=20.0
tplot, /add, ['mms1_epd_eis_extof_0-1000keV_proton_flux_omni_pad_smth', $
              'mms1_epd_eis_extof_0-1000keV_oxygen_flux_omni_pad_smth']
stop


eis_ang_ang, trange=['2015-10-16', '2015-10-17']
stop

eis_ang_ang, trange=['2015-10-16', '2015-10-17'], species='oxygen'
stop

mms_load_feeps, trange=['2015-10-16', '2015-10-17']
tplot, 'mms1_epd_feeps_srvy_l2_electron_intensity_omni'
stop

; tplot used the previous EIS angle-angle plot to plot the FEEPS spectra;
; you can create new windows using the window procedure
window, 0, xsize=800, ysize=500
tplot, 'mms1_epd_feeps_srvy_l2_electron_intensity_omni'
stop

mms_feeps_pad
tplot, /add, 'mms1_epd_feeps_srvy_l2_electron_intensity_70-1000keV_pad'
stop

del_data, '*' ; delete the loaded tplot variables, again
stop

;=============================================================================
; Plasma examples (FPI, HPCA)
;=============================================================================

; load the FPI data (all datatypes), plot the energy spectra from the moments files
mms_load_fpi, probe=1, trange=['2017-05-28/03:48', '2017-05-28/03:56'], datatype=['des-dist', 'des-moms', 'dis-dist', 'dis-moms'], data_rate='brst', /time_clip
tplot, 'mms1_dis_energyspectr_omni_brst' 
stop

; calculate the energy spectra from the ion distribution functions
mms_part_getspec, output='energy', probe=1, trange=['2017-05-28/03:48', '2017-05-28/03:56'], data_rate='brst', species='i'
tplot, 'mms1_dis_dist_brst_energy', /add
stop

; limit the energy range when you calculate the energy spectra from the ion distribution functions
mms_part_getspec, energy=[1000, 10000], suffix='_en_limited', output='energy', probe=1, trange=['2017-05-28/03:48', '2017-05-28/03:56'], data_rate='brst', species='i'
tplot, 'mms1_dis_dist_brst_energy_en_limited', /add
stop

options, 'mms1_dis_numberdensity_brst', color=2 ; turn the color of the density blue

; you can use tplot_multiaxis to create a figure with 2 tplot variables on the same panel (e.g., spectra + line)
tplot_multiaxis, ['mms1_dis_dist_brst_energy_en_limited', 'mms1_dis_dist_brst_energy', 'mms1_dis_energyspectr_omni_brst'], $
                 ['mms1_dis_numberdensity_brst'], [3]
stop

; you can use spd_tplot_average to calculate the average of a tplot variable
average_density = spd_tplot_average('mms1_dis_numberdensity_brst', ['2017-05-28/03:48', '2017-05-28/03:56'])
print, average_density
stop

mms_load_hpca, trange=['2015-10-16', '2015-10-17'], datatype='moments'
tplot, ['mms1_hpca_hplus_ion_bulk_velocity', 'mms1_hpca_hplus_number_density']
stop

mms_load_hpca, trange=['2015-10-16/17:00', '2015-10-16/19:00'], datatype='ion', /time_clip
mms_hpca_calc_anodes, fov=[0, 360]
tplot, ['mms1_hpca_hplus_flux_elev_0-360', 'mms1_hpca_oplus_flux_elev_0-360', 'mms1_hpca_heplus_flux_elev_0-360', 'mms1_hpca_heplusplus_flux_elev_0-360']
stop

mms_part_getspec, instrument='hpca', units='flux', output='energy', probe=1, trange=['2015-10-16/17:00', '2015-10-16/19:00'], data_rate='srvy'
tplot, ['mms1_hpca_hplus_flux_elev_0-360', 'mms1_hpca_hplus_phase_space_density_energy']
stop

; should probably .full_reset_session here; angle-angle and slice plots have trouble 
; with the colors if we don't

; 2D FPI velocity distribution slices
mms_load_fpi, probe=1, trange=['2017-05-28/03:48', '2017-05-28/03:56'], datatype=['dis-dist'], data_rate='brst', /time_clip
;reformat the FPI data from tplot variable into compatible 3D structures
dist = mms_get_dist('mms1_dis_dist_brst', trange=['2017-05-28/03:48', '2017-05-28/03:56'])
slice = spd_slice2d(dist, time='2017-05-28/03:53')
spd_slice2d_plot, slice
stop

; 2D HPCA velocity distribution slices
mms_load_hpca, probe=1, trange=['2015-10-16/17:00', '2015-10-16/19:00'], datatype='ion', /time_clip
;reformat the HPCA data from tplot variable into compatible 3D structures
dist = mms_get_dist('mms1_hpca_hplus_phase_space_density', trange=['2015-10-16/17:00', '2015-10-16/19:00'])
slice = spd_slice2d(dist, time='2015-10-16/18:00')
spd_slice2d_plot, slice
stop

mms_fpi_ang_ang, '2017-05-28/03:50', species='i', data_rate='brst'
stop

;=============================================================================
; Any Questions / Demo Requests?
;=============================================================================

dprint, dlevel = 0, 'Webinar script took ' + strcompress(string(systime(/sec)-start_time), /rem) + ' seconds to complete.'


end

