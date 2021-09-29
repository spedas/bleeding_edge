; MMS Data in SPEDAS (IDL)
; Eric Grimes (egrimes@igpp.ucla.edu); ericgrimes@ucla.edu
; 
; Apr 8, 2020 10:00 AM Pacific Time
; 
; Notes:
;     - This webinar is being recorded and will be posted online after the webinar
;     - Everyone is muted by default, feel free to unmute and ask questions throughout, or email after
;     - This script will be available in the SPEDAS distribution at:
;           projects/mms/examples/webinars
; 
;     - Find a list of recent changes to SPEDAS, and a link to the nightly bleeding edge at:
;       http://spedas.org/changelog/
;     
;Tentative Agenda
;  1. Introduction to load routines and keywords
;  2. Ephemeris/coordinates examples (MEC)
;  3. FIELDS examples (FGM, SCM, EDP, EDI, DSP, ASPOC)
;  4. EPD examples (EIS, FEEPS)
;  5. Plasma examples (FPI, HPCA)

; ==============================================================
;  Introduction to load routines and keywords
; ==============================================================

; - Load routines:
;       mms_load_fgm - Fluxgate Magnetometer
;       mms_load_scm - Search-coil Magnetometer
;       mms_load_fsm - L3 FGM+SCM data 
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
;       datatype: depends on the instrument
;       level: L2 (also available: l1b, l1a, sitl, ql - non-L2 requires MMS team user/password)
;       time_clip: clip the data down to the time range specified in trange (e.g., /time_clip)
;       spdf: load data from SPDF instead of the LASP SDC (e.g., /spdf)
;       tplotnames: names of the tplot variables loaded (e.g., tplotnames=tnames)
;       available: returns a list of files available at the SDC for the requested parameters (e.g., /available)
;       tt2000: flag for preserving TT2000 timestamps found in CDF files (e.g., /tt2000)
;   
;  
;   To see a full list of the keywords supported for an instrument, check the header of the load routine you're interested in
;   e.g., ".edit mms_load_fgm" in the console
;  
;   To see more examples of keyword usage, check the crib sheets found at:
;         projects/mms/examples/basic
;         projects/mms/examples/advanced

; ==============================================================
;  Ephemeris/coordinates examples (MEC)
; ==============================================================

; load 12-hours of srvy-mode MEC data
mms_load_mec, probe=[1, 2, 3, 4], trange=['2015-10-16', '2015-10-16/12:00'], data_rate='srvy', /time_clip
tplot, ['mms1_mec_r_sm', 'mms1_mec_v_sm']
stop

; list the tplot variables loaded
tplot_names
stop

; list only the tplot variables containing _r_
tplot_names, '*_r_*'
stop

; store the list of tvars in a variable
r_vars = tnames('*_r_*')
stop

; convert the position data from km to Re
tkm2re, 'mms1_mec_r_sm'
tplot, 'mms1_mec_r_sm_re'
stop

; use get_data to take the data out of a tplot variable and store it into IDL data structures
get_data, 'mms1_mec_r_sm_re', data=data, dlimits=metadata, limits=l
help, data
; note:
;;; data.X = unix times
;;; data.Y = data values, in Earth Radii
stop

; plot and CDF metadata are stored in the variable retuned by 'dlimits' and 'limits'
help, metadata
help, metadata.cdf
stop

; you can use find_nearest_neighbor to perform a binary search on the time series
closest_time = find_nearest_neighbor(data.X, time_double('2015-10-16/6:00'))
print, closest_time ; note: stored in unix time
stop

; to print the time as a string, use time_string
print, time_string(closest_time, tformat='YYYY-MM-DD/hh:mm:ss.fff')
stop

; to turn a time_string back into unix time, use time_double
print, time_double('2015-10-16/6:00')
stop

; to print the position data at this point, use "where"
where_this_time = where(data.X eq closest_time)
print, data.Y[where_this_time, *] ; note: this is safe because closest_time is a time that exists in our time series (since we found it using find_nearest_neighbor)
stop

; use store_data to create a new variable
store_data, 'new_mec_var', data=data, dlimits=metadata, limits=l
tplot, 'new_mec_var'
stop

; create orbit plots
mms_orbit_plot, trange=['2015-10-16', '2015-10-16/12:00'], coord='sm'
stop

; create formation plots
mms_mec_formation_plot, '2015-10-16/06:00', /bfield_sc
stop

; note: several keywords for including various types of vectors
mms_mec_formation_plot, '2015-10-16/13:07:02.40', /dis_sc, /des_sc, /bfield_sc, fpi_data_rate='brst', fpi_normalization=0.02d, fgm_data_rate='brst', fgm_normalization=1.d, /projection, plotmargin=1.2, sc_size=1.5, sundir='left'
stop

; ==============================================================
;  FIELDS examples (FGM, SCM, EDP, EDI, DSP, ASPOC)
; ==============================================================
; load some FGM data; note: /get_fgm_ephemeris keyword loads the ephemeris data stored in the FGM CDF files
mms_load_fgm, probe=[1, 2, 3, 4], trange=['2015-10-16', '2015-10-16/12:00'], data_rate='srvy', /get_fgm_ephemeris, /time_clip
tplot, 'mms?_fgm_b_gsm_srvy_l2_bvec'
stop

; curlometer technique
fields = 'mms'+['1', '2', '3', '4']+'_fgm_b_gse_srvy_l2'
positions = 'mms'+['1', '2', '3', '4']+'_fgm_r_gse_srvy_l2'

; see header of mms_curl for reference on the curlometer technique
mms_curl, trange=['2015-10-16/6:00', '2015-10-16/12:00'], fields=fields, positions=positions
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

; load data from the search-coil magnetometer
mms_load_scm, trange=['2015-10-16', '2015-10-16/3:00'], data_rate='srvy', /time_clip
tplot, 'mms1_scm_acb_gse_scsrvy_srvy_l2'
stop

; calculate the dynamic power spectra of the SCM data
; note: there are more examples (including burst mode data) in the SCM crib sheet
tdpwrspc, 'mms1_scm_acb_gse_scsrvy_srvy_l2', nboxpoints=512, nshiftpoints=512, bin=1
stop

; note: tplot accepts unix-style wild cards * (match multiple characters) and ? (match one character)
tplot, 'mms1_scm_acb_gse_scsrvy_srvy_l2_?_dpwrspc', /add
stop

; load electric field and spacecraft potential data
mms_load_edp, probe=4, trange=['2015-10-16', '2015-10-16/12:00'], datatype=['dce', 'scpot'], /time_clip
tplot, ['mms4_edp_dce_gse_fast_l2', 'mms4_edp_scpot_fast_l2']
stop

; load the HF ACE E Field Spectral Density
mms_load_edp, probe='4', trange=['2015-10-16', '2015-10-16/12:00'], datatype='hfesp', data_rate='srvy', /time_clip
tplot, 'mms4_edp_hfesp_srvy_l2'
stop

; if you're unfamiliar with a variable, you can check the variable attributes from the CDF metadata
get_data, 'mms4_edp_hfesp_srvy_l2', dlimits=dl
help, dl.cdf.vatt
stop

; load the EPSD/BPSD data from the digital signal processor (DSP)
mms_load_dsp, probe=1, trange=['2015-10-16', '2015-10-17'], datatype=['epsd', 'bpsd'], data_rate='fast', level='l2', /time_clip
stop

; EPSD = electric power spectral density
; BPSD = magnetic power spectral density
tplot, '*_?psd_omni*
stop

; load data from the electron drift instrument
mms_load_edi, probe=4, trange=['2015-10-16', '2015-10-17']
tplot, ['mms4_edi_e_gsm_srvy_l2', 'mms4_edi_vdrift_gsm_srvy_l2']
stop

; load data from the ASPOC instrument
mms_load_aspoc, probe=4, trange=['2015-10-16', '2015-10-17'], /time_clip
tplot, 'mms4_aspoc_ionc_l2'
stop

; ==============================================================
;  EPD examples (EIS, FEEPS)
;  
;  For more examples, please see the following crib sheets:
;     projects/mms/examples/basic/mms_load_eis_crib.pro
;     projects/mms/examples/basic/mms_load_eis_burst_crib.pro
;     projects/mms/examples/basic/mms_eis_angle_angle_crib.pro
;     projects/mms/examples/basic/mms_load_feeps_crib.pro
;     projects/mms/examples/basic/mms_feeps_sectspec_crib.pro
; ==============================================================

; load data from the FEEPS instrument
mms_load_feeps, trange=['2015-10-16', '2015-10-16/12:00'], /time_clip
tplot, ['mms1_epd_feeps_srvy_l2_electron_intensity_omni', 'mms1_epd_feeps_srvy_l2_electron_intensity_omni_spin']
stop

; we've seen how to extract the data for line plots, the process is similar for energy spectra
get_data, 'mms1_epd_feeps_srvy_l2_electron_intensity_omni_spin', data=d
help, d
print, d.v ; print the energies - note that these vary with time for some data (e.g., FPI burst mode energy spectra)
stop

; select a time to plot intensity vs. energy
flatten_spectra
stop

; use the /replot keyword to re-use the previously selected time
flatten_spectra, /replot, /xlog, /ylog, /png, filename='spectra' ; /postscript also works
stop

; add a vertical bar on the tplot panel at the requested time
flatten_spectra, time='2015-10-16/6:00', /xlog, /ylog, /bar
stop

; calculate the FEEPS electron pitch angle distribution
mms_feeps_pad
tplot, ['mms1_epd_feeps_srvy_l2_electron_intensity_70-600keV_pad', 'mms1_epd_feeps_srvy_l2_electron_intensity_70-600keV_pad_spin']
stop

; calculate the pitch angle distribution for 100-200 keV, 200-300 keV, 300-400 keV electrons:
mms_feeps_pad, energy=[100, 200]
mms_feeps_pad, energy=[200, 300]
mms_feeps_pad, energy=[300, 400]
stop

tplot, ['mms1_epd_feeps_srvy_l2_electron_intensity_100-200keV_pad', 'mms1_epd_feeps_srvy_l2_electron_intensity_200-300keV_pad', 'mms1_epd_feeps_srvy_l2_electron_intensity_300-400keV_pad']
stop

; flatten_spectra also works on PAD variables (or any other type of spectra, and it ignores line plots on the same figure)
flatten_spectra, /ylog
stop

; load the EIS data
; note: extof: energy by time of flight; phxtof: pulse-height by time of flight
mms_load_eis, trange=['2015-10-16', '2015-10-16/12:00'], datatype=['phxtof', 'extof']
tplot, ['mms1_epd_eis_extof_proton_flux_omni_spin', 'mms1_epd_eis_phxtof_proton_flux_omni_spin']
stop

; calculate the EIS pitch angle distributions for ExTOF
mms_eis_pad, datatype='extof'
stop

tplot, ['mms1_epd_eis_extof_56-535keV_proton_flux_omni_pad', 'mms1_epd_eis_extof_56-535keV_proton_flux_omni_pad_spin']
stop

; ==============================================================
;  Plasma examples (FPI, HPCA)
;     
;  For more examples, please see the following crib sheets:
;     projects/mms/examples/basic/mms_load_fpi_crib.pro
;     projects/mms/examples/basic/mms_load_fpi_burst_crib.pro
;     projects/mms/examples/basic/mms_load_hpca_crib.pro
;     projects/mms/examples/basic/mms_load_hpca_burst_crib.pro
;     projects/mms/examples/basic/mms_fpi_angle_angle_crib.pro
;     projects/mms/examples/advanced/mms_part_getspec_crib.pro
;     projects/mms/examples/advanced/mms_part_getspec_adv_crib.pro
;     projects/mms/examples/advanced/mms_slice2d_fpi_crib.pro
;     projects/mms/examples/advanced/mms_slice2d_hpca_crib.pro
;     projects/mms/examples/advanced/mms_isee_3d_crib_basic.pro
;     projects/mms/examples/advanced/mms_flipbook_crib.pro
;     
; ==============================================================

; load the ion and electron moments for FPI (burst mode)
mms_load_fpi, /center_measurement, probe=4, datatype=['des-moms', 'dis-moms'], data_rate='brst', trange=['2015-10-16/13:00', '2015-10-16/13:10'];, /time_clip
stop

tplot, ['mms4_des_energyspectr_omni_brst', 'mms4_dis_energyspectr_omni_brst', 'mms4_des_bulkv_gse_brst', 'mms4_dis_bulkv_gse_brst', 'mms4_des_numberdensity_brst', 'mms4_dis_numberdensity_brst']
stop

; remove the gaps in the spectra
tdegap, ['mms4_des_energyspectr_omni_brst', 'mms4_dis_energyspectr_omni_brst'], /overwrite
stop

tplot ; replot the data
stop

; load the burst mode HPCA moments data
mms_load_hpca, /center_measurement, probe=4, datatype='moments', data_rate='brst', trange=['2015-10-16/13:00', '2015-10-16/13:10'];, /time_clip
stop

tplot, ['mms4_hpca_hplus_number_density', 'mms4_hpca_hplus_scalar_temperature', 'mms4_hpca_hplus_ion_bulk_velocity']
stop

; load the HPCA flux data
mms_load_hpca, /center_measurement, probe=4, datatype='ion', data_rate='brst', trange=['2015-10-16/13:00', '2015-10-16/13:10'];, /time_clip
stop

; since the HPCA data is multi-dimensional (i.e., function of both energy, anodes), we need to
; sum the data over the full field of view (all anodes), and average over the spin to get the omni-directional energy spectra
mms_hpca_calc_anodes, fov=[0, 360] ; can also specify anode #s individually via the 'anodes' keyword
mms_hpca_spin_sum, probe=4, /avg
stop

tplot, ['mms4_hpca_hplus_flux_elev_0-360_spin', 'mms4_hpca_oplus_flux_elev_0-360_spin', 'mms4_hpca_heplus_flux_elev_0-360_spin', 'mms4_hpca_heplusplus_flux_elev_0-360_spin']
stop

; you can use tplot_multiaxis to create a figure with 2 tplot variables on the same panel (e.g., spectra + line)
tplot_multiaxis, ['mms4_des_energyspectr_omni_brst', 'mms4_dis_bulkv_gse_brst', 'mms4_dis_energyspectr_omni_brst'], $
  ['mms4_des_numberdensity_brst'], [3]
stop

; calculate the spectra (PAD and energy spectra) and moments directly from the FPI distribution data
mms_part_getspec, probe=4, output=['pa', 'energy', 'moments'], instrument='fpi', species='i', data_rate='brst', trange=['2015-10-16/13:06', '2015-10-16/13:07']
stop

; plot the DIS energy spectra calculated directly from the DFs, along with the DIS energy spectra stored in the moments CDF files
tplot, ['mms4_dis_dist_brst_energy', 'mms4_dis_energyspectr_omni_brst']
stop

; create slices of the 2D distribution functions
mms_part_slice2d, time='2015-10-16/13:06', probe=4, instrument='fpi', species='i', data_rate='brst'
stop

mms_part_slice2d, time='2015-10-16/13:06', probe=4, instrument='hpca', species='hplus', data_rate='brst'
stop

; plot the 2D slice in energy flux units instead
mms_part_slice2d, units='eflux', time='2015-10-16/13:06', probe=4, instrument='fpi', species='i', data_rate='brst'
stop

; combine tplot windows with 2D slices using mms_flipbookify
window, xsize=1000, ysize=650
tplot, ['mms4_dis_energyspectr_omni_brst', 'mms4_dis_numberdensity_brst', 'mms4_dis_temppara_brst', 'mms4_dis_tempperp_brst']
mms_flipbookify, trange=['2015-10-16/13:06', '2015-10-16/13:07'], probe=4, instrument='fpi', species='i', seconds=3, /video
stop

; FPI angle-angle/angle-energy/pa-energy plots
mms_fpi_ang_ang, '2015-10-16/13:06', data_rate='brst', species='i', probe=4, /png
stop

; HPCA angle-angle/angle-energy plots
mms_hpca_ang_ang, '2015-10-16/13:06', data_rate='brst', probe=4, /png, filename_suffix='_hpca'

stop
end