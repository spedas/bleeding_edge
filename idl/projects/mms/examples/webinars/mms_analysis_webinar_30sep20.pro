;+
; ============================================================================
; ============================================================================
;
; Analyzing MMS Data with SPEDAS
; Eric Grimes - egrimes@igpp.ucla.edu
;
; Wednesday, September 30, 2020 at 10AM Pacific / 1PM Eastern
;
; Tentative agenda:
;   1) Ephemeris/Coordinates Data
;   2) FIELDS Data
;   3) EPD (FEEPS/EIS) Data
;   4) Plasma (FPI/HPCA) Data
;
; Feel free to unmute and ask questions! You can also email me after: egrimes@igpp.ucla.edu
;
; Notes: 
;   For detailed science questions about the data products, please see the Release Notes for
;   the instrument you're interested in, then contact the instrument team
;
;   We're be recording this and posting it to Youtube! This script will also be available in 
;   the SPEDAS distribution at:
;   
;       projects/mms/examples/webinars/mms_analysis_webinar_30sep20.pro
;
;
; the load routines all follow the syntax: mms_load_xxx, where xxx is the instrument, e.g.,
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
;       mms_load_state - Ephemeris and Coordinates (ASCII)
;       mms_load_dsp - Digital Signal Processor
;       mms_load_tqf - Tetrahedron Quality Factor
;       mms_load_brst_segments, mms_load_fast_segments - Data Availability
;
; - Some of the standard keywords:
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
;    there are more keywords; please see the header of the load routine you're interested in for a full list
;       e.g., ".edit mms_load_fgm" in the console
;    
;    
;    To see more examples of keyword usage, check the crib sheets found at:
;         projects/mms/examples/basic
;         projects/mms/examples/advanced
;         projects/mms/examples/webinars (note: some of the these might be out of date!)
;         
; ============================================================================
; ============================================================================
;$LastChangedBy: egrimes $
;$LastChangedDate: 2020-09-30 12:00:18 -0700 (Wed, 30 Sep 2020) $
;$LastChangedRevision: 29197 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/examples/webinars/mms_analysis_webinar_30sep20.pro $
;-

; ============================================================================
; ============================================================================
; Ephemeris/Coordinates Data
; ============================================================================
; ============================================================================

; to get started, let's load some MEC (MMS Ephemeris and Coordinates data) for all 4 probes
; note: if you don't set the probes keyword, data for probe 1 will be loaded
mms_load_mec, trange=['2015-10-16', '2015-10-17'], probes=[1, 2, 3, 4]
stop

; now plot the position data in SM coordinates
; note: tplot accepts the unix-style wildcards: ? (match a single character) and * (match multiple characters)
tplot, 'mms?_mec_r_sm'
stop

; list the tplot variables loaded
tplot_names
stop

; return the list of variables loaded to an IDL variable
vars = tnames()
stop

; extract the data from a tplot variable
; the data values are returned with the 'data' keyword
; the default metadata are returned with the 'dlimits' keyword
; the metadata set by the user with options are returned with the 'limits' keyword
get_data, 'mms1_mec_r_sm', data=d, dlimits=dl, limits=l
stop

; time values (stored as unix times) are stored in d.X
; y-values are stored in d.Y
help, d
stop 

help, dl
stop

; create a variable from IDL data structures using store_data
store_data, 'position_data', data={x: d.X, y: d.Y}, dlimits=dl, limits=l
stop

tplot, 'position_data'
stop

; note: if ephts04d data aren't available for your time range, try the epht89d datatype
mms_load_mec, trange=['2015-10-16', '2015-10-17'], datatype='epht89d'
stop

; we have a tool for quickly converting variables in Km to Re, e.g., 
tkm2re, 'mms?_mec_r_sm'
stop

; note: this assumes 6371.2 km in 1 Re

; replot the position data in Re
tplot, 'mms?_mec_r_sm_*'
stop

; to change plot options, use the 'options' procedure
; the 'labels' are on the right-hand side of the figure
options, 'mms1_mec_r_sm_re', labels=['x', 'y', 'z']
options, 'mms2_mec_r_sm_re', labels=['x', 'y', 'z']
options, 'mms3_mec_r_sm_re', labels=['x', 'y', 'z']
options, 'mms4_mec_r_sm_re', labels=['x', 'y', 'z']
stop

tplot ; replot the current plot with an empty call to tplot
stop

; labflag allows you to set where the labels are placed
; labflag =  0: No labels
;            1: labels spaced equally
;           -1: labels placed equally but in reverse order
;            2: labels placed according to data end points on the plot
;            3: labels placed according to LABPOS (does not work for pseudo vars)
options, 'mms1_mec_r_sm_re', labflag=-1
options, 'mms2_mec_r_sm_re', labflag=-1
options, 'mms3_mec_r_sm_re', labflag=-1
options, 'mms4_mec_r_sm_re', labflag=-1
tplot
stop

; set the title of each panel on the left-hand side
; note: !C = new line
options, 'mms1_mec_r_sm_re', ytitle='MMS1!Cposition'
options, 'mms2_mec_r_sm_re', ytitle='MMS2!Cposition'
options, 'mms3_mec_r_sm_re', ytitle='MMS3!Cposition'
options, 'mms4_mec_r_sm_re', ytitle='MMS4!Cposition'
tplot 
stop

; change some global plot options
; note: options and tplot_options should allow you to control all options 
; on a figure available as graphics keywords to the PLOT procedure:
;       https://www.harrisgeospatial.com/docs/PLOT_Procedure.html
tplot_options, 'xmargin', [25, 25]
tplot_options, 'charsize', 1.5
tplot_options, 'title', 'MMS Position'
tplot
stop

; get the current plot options
tplot_options, get_options=opt
help, opt
stop

; turn off the time stamp in the bottom right
time_stamp, /off
tplot
stop

; save the figure as a PNG file
makepng, 'mms_position_data'
stop

; save the figure as a PS file
tprint, 'mms_position_data', /landscape
stop

; create MMS orbit plots
mms_orbit_plot, trange=['2016-11-23', '2016-11-23/6'], probes=[1, 2, 3, 4], coord='sm'
stop

; create MMS formation plots
mms_mec_formation_plot, '2015-10-16/13:06'
stop

; see the header of the formation plot code and the formation crib sheet 
; for more examples
mms_mec_formation_plot, '2015-10-16/13:07:02.40', $
                        fpi_data_rate='brst', $
                        fpi_normalization=0.02d, $
                        fgm_data_rate='brst', $
                        fgm_normalization=1.d, $
                        /dis_center, $
                        /des_center, $
                        /bfield_center, $
                        /projection, $
                        plotmargin=0.3, $
                        sc_size=2, $
                        sundir='left'
stop

; ============================================================================
; ============================================================================
; FIELDS Data
; ============================================================================
; ============================================================================

; load some burst-mode FGM data 
mms_load_fgm, trange=['2016-11-23/07:49:32', '2016-11-23/07:49:35'], data_rate='brst', probes=[1, 2, 3, 4], /time_clip

; and some burst-mode position data (GSE coordinates)
mms_load_mec, trange=['2016-11-23/07:49:32', '2016-11-23/07:49:35'], data_rate='brst', probes=[1, 2, 3, 4], /time_clip, varformat='*_?_gse'
stop

; need to reset the title of the figure before plotting the FGM data
tplot_options, 'title', ''

tplot, ['mms1_fgm_b_gse_brst_l2_bvec', 'mms2_fgm_b_gse_brst_l2_bvec', 'mms3_fgm_b_gse_brst_l2_bvec', 'mms4_fgm_b_gse_brst_l2_bvec']
stop

; curlometer calculations
mms_curl, trange=['2016-11-23/07:49:32', '2016-11-23/07:49:35'], $
          fields='mms'+['1', '2', '3', '4']+'_fgm_b_gse_brst_l2_bvec', $
          positions='mms'+['1', '2', '3', '4']+'_mec_r_gse'
stop

tplot, /add, 'jtotal'
stop

; load data from the search-coil magnetometer (SCM) onboard MMS1
mms_load_scm, trange=['2015-10-16', '2015-10-16/3'], data_rate='srvy', /time_clip
stop

tplot, 'mms1_scm_acb_gse_scsrvy_srvy_l2'
stop

; calculate the dynamic power spectra using the SCM data
; note: see the SCM crib sheet for values to use for nboxpoints, nshiftpoints for different data rates
tdpwrspc, 'mms1_scm_acb_gse_scsrvy_srvy_l2', nboxpoints=512, nshiftpoints=512, bin=1
stop

tplot, /add, '*scsrvy*_dpwrspc'
stop

; highlight a time interval in a panel
highlight_time_interval, 'mms1_scm_acb_gse_scsrvy_srvy_l2', time_interval=['2015-10-16/1:30', '2015-10-16/1:50'], color=164
tplot
stop

; load the electric field data and spacecraft potential
mms_load_edp, datatype=['scpot', 'dce'], trange=['2016-11-23/07:49:32', '2016-11-23/07:49:35'], data_rate='brst', probe=1
stop

tplot, ['mms1_edp_scpot_brst_l2', 'mms1_edp_dce_gse_brst_l2']
stop

; add a horizontal line 
timebar, 0.0, /databar, varname='mms1_edp_dce_gse_brst_l2', linestyle=5
stop

; add vertical lines to a panel
timebar, '2016-11-23/07:49:33', thick=3
timebar, '2016-11-23/07:49:34', thick=3
stop

; load data from the electron drift instrument (EDI)
mms_load_edi, trange=['2016-11-23', '2016-11-24']
stop

; plot the ExB drift velocity in GSE coordinates
tplot, 'mms1_edi_vdrift_gse_srvy_l2'
stop

; load the EPSD/BPSD data from the digital signal processor (DSP)
mms_load_dsp, probe=1, trange=['2015-10-16', '2015-10-17'], datatype=['epsd', 'bpsd'], data_rate='fast', level='l2', /time_clip
stop

; BPSD = magnetic power spectral density
; EPSD = electric power spectral density
tplot, '*_?psd_omni*
stop

ylim, 'mms1_dsp_bpsd_omni_fast_l2', 30., 10000., 0
tplot
stop

; some useful crib sheets:
; 
; - coordinate transformations:
;       projects/mms/examples/basic/mms_qcotrans_crib.pro
;
; - LMN transformations: 
;       projects/mms/examples/advanced/mms_cotrans_lmn_crib.pro
;   
; - calculate Poynting vector/flux:
;       projects/mms/examples/advanced/mms_poynting_flux_crib.pro
;
; - transform to minimum variance analysis coordinates:
;       projects/mms/examples/advanced/mms_mva_crib.pro
;

; ============================================================================
; ============================================================================
; EPD (FEEPS/EIS) Data
; ============================================================================
; ============================================================================

mms_load_feeps, datatype='electron', trange=['2016-11-23', '2016-11-24'], data_rate='srvy', probe=4

tplot, 'mms4_epd_feeps_srvy_l2_electron_intensity_omni'+['', '_spin']
stop

; select a time to plot intensity vs. energy
flatten_spectra
stop

; use the /replot keyword to re-use the previously selected time
flatten_spectra, /replot, /xlog, /ylog, /png, filename='spectra' ; /postscript also works
stop

; you can use the time keyword instead of selecting a time
flatten_spectra, time='2016-11-23/2:00', /xlog, /ylog
stop

; add a vertical bar on the tplot panel at the requested time
flatten_spectra, time='2016-11-23/2:00', /xlog, /ylog, /bar
stop

; calculate FEEPS pitch angle distributions
mms_feeps_pad, probe=4
stop

tplot, '*70-600keV_pad*'
stop

mms_load_eis, datatype=['extof', 'phxtof'], trange=['2016-11-23', '2016-11-24'], data_rate='srvy', probe=4
stop

tplot, 'mms4_epd_eis_extof_proton_flux_omni_spin'
stop

; plot flux vs. energy for 3 different times
flatten_spectra_multi, 3
stop

; as before, you can use the time keyword instead of selecting the times
flatten_spectra_multi, /xlog, /ylog, time=['2016-11-23/6:00', '2016-11-23/7:00', '2016-11-23/8:00']
stop

; calculate the EIS pitch angle distributions
mms_eis_pad, probe=4
stop

tplot, 'mms4_epd_eis_extof_44-979keV_proton_flux_omni_pad_spin'
stop

flatten_spectra_multi, /ylog, time=['2016-11-23/6:00', '2016-11-23/7:00', '2016-11-23/8:00']
stop

; ============================================================================
; ============================================================================
; Plasma (FPI/HPCA) Data
; ============================================================================
; ============================================================================

mms_load_fpi, /center_measurement, datatype=['dis-moms', 'des-moms'], trange=['2016-11-23', '2016-11-24'], probe=4;, /time_clip

; use the error bars to find potential problems with the data
tplot, ['mms4_des_errorflags_fast_moms_flagbars_full', $
  'mms4_des_numberdensity_fast', $
  'mms4_dis_errorflags_fast_moms_flagbars_full', $
  'mms4_dis_numberdensity_fast']
stop

; add error bars to a tplot variable
get_data, 'mms4_dis_numberdensity_fast', data=d, dlimits=dl, limits=l
get_data, 'mms4_dis_numberdensity_err_fast', data=err
error_data = err.Y*100. ; multiplying the errors by 100 so that they're clear on the figure
store_data, 'dis_density_with_errs', data={x: d.x, y: d.y, dy: error_data}, dlimits=dl, limits=l
stop

tplot, 'dis_density_with_errs'
stop

; zoom in to see the error bars
tlimit, ['2016-11-23/13:00', '2016-11-23/13:05']
stop

; reset the time range
tlimit, /full
stop

mms_load_hpca, /center_measurement, datatype=['ion', 'moments'], trange=['2016-11-23/12:00', '2016-11-23/13:00'], probe=4, /time_clip

; calculate the omni-directional energy spectra for HPCA
mms_hpca_calc_anodes, fov=[0, 360]
mms_hpca_spin_sum, probe=4, /avg
stop

; note: different units in various places
tplot, ['mms4_dis_energyspectr_omni_fast', $
  'mms4_hpca_hplus_flux_elev_0-360_spin', $
  'mms4_epd_eis_phxtof_proton_flux_omni', $
  'mms4_epd_eis_extof_proton_flux_omni']
stop

; convert the units to keV and flux automatically
flatten_spectra, /to_flux, /to_kev, /xlog, /ylog, time='2016-11-23/12:10:30'
stop

; change the legend names
options, 'mms4_dis_energyspectr_omni_fast', 'legend_name', 'FPI DIS'
options, 'mms4_hpca_hplus_flux_elev_0-360_spin', 'legend_name', 'HPCA'
options, 'mms4_epd_eis_phxtof_proton_flux_omni', 'legend_name', 'EIS PHxTOF'
options, 'mms4_epd_eis_extof_proton_flux_omni', 'legend_name', 'EIS ExTOF'
flatten_spectra, /to_flux, /to_kev, /xlog, /ylog, /replot
stop

; plot temperature and density on the same plot
options, 'mms4_des_numberdensity_fast', labels='', colors=0 ; black
options, 'mms4_des_tempperp_fast', labels='', colors=2 ; blue

tplot_multiaxis, ['mms4_des_numberdensity_fast', 'mms4_des_bulkv_gse_fast', 'mms4_des_energyspectr_omni_fast'], $ ; left plots
  'mms4_des_tempperp_fast', $ ; right plots
  1 ; panel of the right plot (starts at 1)
stop

; you can also plot line plots over spectra
tplot_multiaxis, ['mms4_des_numberdensity_fast', 'mms4_des_bulkv_gse_fast', 'mms4_des_energyspectr_omni_fast'], $ ; left plots
  'mms4_des_tempperp_fast', 3
stop

; generate the spectra/PAD from the DIS distribution functions
mms_part_getspec, output=['energy', 'pa'], trange=['2016-11-23/12', '2016-11-23/12:20'], instrument='fpi', species='i', probe=4 ;, energy=[1000, 20000], /spdf
stop

tplot, ['mms4_dis_dist_fast_energy', 'mms4_dis_dist_fast_pa']
stop

; plot the calculated energy spectra compared to the energy spectra in the moments CDF files
tplot, ['mms4_dis_dist_fast_energy', 'mms4_dis_energyspectr_omni_fast']
stop

; generate the HPCA energy spectra/PAD from the H+ distribution functions
mms_part_getspec, output=['energy', 'pa'], trange=['2016-11-23/12', '2016-11-23/12:20'], instrument='hpca', species='hplus', probe=4
stop

tplot, ['mms4_hpca_hplus_phase_space_density_energy', 'mms4_hpca_hplus_phase_space_density_pa']
stop

; create 2D slices
mms_part_slice2d, instrument='fpi', species='i', probe=4, time='2016-11-23/12:10:30'
stop

mms_part_slice2d, instrument='hpca', species='hplus', probe=4, time='2016-11-23/12:10:30'
stop

; note: mms_part_slice2d accepts all of the keywords of spd_slice2d and spd_slice2d_plot
; e.g., rotation, custom_rotation, background_color_index, etc.
mms_part_slice2d, instrument='fpi', species='i', probe=4, time='2016-11-23/12:10:30', units='eflux', background_color_rgb=[230, 230, 230]
stop

mms_part_slice2d, instrument='hpca', species='hplus', probe=4, time='2016-11-23/12:10:30', units='eflux', samples=10
stop

; combine 2D slices with tplot windows
window, xsize=1000, ysize=650
tplot, ['mms4_dis_numberdensity_fast', 'mms4_dis_bulkv_gse_fast', 'mms4_dis_energyspectr_omni_fast']
mms_flipbookify, seconds=60, instrument='fpi', species='i', probe=4, data_rate='fast', trange=['2016-11-23/12', '2016-11-23/12:20'], /video
stop

end