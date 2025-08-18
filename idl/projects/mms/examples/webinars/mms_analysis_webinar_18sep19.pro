;+
; ----------------------------------------------------------------------------
; ----------------------------------------------------------------------------
; 
; Analyzing MMS Data with SPEDAS
; Eric Grimes - egrimes@igpp.ucla.edu
; 
; Wednesday, September 18, 2019 at 10AM Pacific / 1PM Eastern
;
; Tentative agenda:
;   1) Ephemeris/Coordinates Data
;   2) FIELDS Data
;   3) EPD (FEEPS/EIS) Data
;   4) Plasma (FPI/HPCA) Data
; 
; Feel free to unmute and ask questions! You can also email me after: egrimes@igpp.ucla.edu
; 
; 
; Note: for detailed science questions about the data products, please see the Release Notes for 
;       the instrument you're interested in, then contact the instrument team
; 
; 
; 
; ----------------------------------------------------------------------------
; ----------------------------------------------------------------------------
;$LastChangedBy: egrimes $
;$LastChangedDate: 2019-09-19 08:56:55 -0700 (Thu, 19 Sep 2019) $
;$LastChangedRevision: 27785 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/examples/webinars/mms_analysis_webinar_18sep19.pro $
;-

; MMS event search
mms_event_search, 'current sheet', authors=authors, descriptions=descriptions, start_times=start_times, end_times=end_times
stop

tr = ['2016-11-23/07:49:32', '2016-11-23/07:49:35']

; ----------------------------------------------------------------------------
; ----------------------------------------------------------------------------
; Ephemeris/Coordinates Data
; 
; https://lasp.colorado.edu/mms/sdc/public/datasets/mec/
; 
; ----------------------------------------------------------------------------
; ----------------------------------------------------------------------------

; note: varformat is a useful keyword for speeding up the load routines
mms_load_mec, trange=tr, data_rate='brst', probes=[1, 2, 3, 4], /time_clip, varformat='*_?_sm'
stop

; list the variables loaded
tplot_names
stop

; plot the position
tplot, '*r_sm'
stop

; note: if ephts04d data aren't available for your time range, try the epht89d datatype
mms_load_mec, trange=tr, data_rate='brst', datatype='epht89d', /time_clip, varformat='*_?_sm'
stop

; convert to Re
tkm2re, '*r_sm'
stop

; set the var_label (position labels at the bottom)
tplot, 'mms1*r_sm', var_label='mms1*r_sm_re'
stop

; to fix the labels, split the vector into individual components and set the ytitle
split_vec, 'mms1_mec_r_sm_re'
options, 'mms1_mec_r_sm_re_x', ytitle='x (Re)'
options, 'mms1_mec_r_sm_re_y', ytitle='y (Re)'
options, 'mms1_mec_r_sm_re_z', ytitle='z (Re)'
stop

tplot, 'mms1*r_sm', var_label='mms1_mec_r_sm_re_'+['x', 'y', 'z']
stop

; move the time labels to the top row
tplot_options, version=6
tplot
stop

; turn off the time stamp in the bottom right
time_stamp, /off
tplot
stop

; create MMS orbit plots
mms_orbit_plot, trange=['2016-11-23', '2016-11-23/6'], probes=[1, 2, 3, 4], coord='sm'
stop

; create MMS formation plots
mms_mec_formation_plot, tr[0]
stop

; include XY projections and the tetrahedron quality factor
mms_mec_formation_plot, tr[0], /xy_projection, /quality, coord='sm'
stop

; ----------------------------------------------------------------------------
; ----------------------------------------------------------------------------
; FIELDS Data
; 
; https://lasp.colorado.edu/mms/sdc/public/datasets/fields/
; 
; ----------------------------------------------------------------------------
; ----------------------------------------------------------------------------
mms_load_fgm, trange=tr, data_rate='brst', probes=[1, 2, 3, 4], /time_clip
stop

tplot, 'mms1_fgm_b_gse_brst_l2_bvec', var_label='mms1_mec_r_sm_re_'+['x', 'y', 'z']
stop

; curlometer calculations
; method #1
mms_curl, trange=tr, fields='mms'+['1', '2', '3', '4']+'_fgm_b_gse_brst_l2_bvec', positions='mms'+['1', '2', '3', '4']+'_mec_r_gse'
stop

; method #2
mms_lingradest, fields='mms'+['1', '2', '3', '4']+'_fgm_b_gse_brst_l2_bvec', positions='mms'+['1', '2', '3', '4']+'_mec_r_gse', suffix='_lingradest'
stop

tplot, ['jtotal_lingradest', 'jtotal', 'jpar']
stop

; widen the margin
tplot_options, 'xmargin', [20, 15]
tplot
stop

; fill from 0 to the line with a color
tplot_fill_color, 'jpar', spd_get_color('blue')
stop

; load data from the search-coil magnetometer (SCM)
mms_load_scm, trange=['2015-10-16', '2015-10-16/3'], data_rate='srvy', /time_clip
stop

; calculate the dynamic power spectra
tdpwrspc, 'mms1_scm_acb_gse_scsrvy_srvy_l2', nboxpoints=512, nshiftpoints=512, bin=1
stop

tplot, '*scsrvy*_dpwrspc'
stop

; load the EPSD/BPSD data from the digital signal processor (DSP)
mms_load_dsp, probe=1, trange=['2015-10-16', '2015-10-17'], datatype=['epsd', 'bpsd'], data_rate='fast', level='l2', /time_clip
stop

; BPSD = magnetic power spectral density
; EPSD = electric power spectral density
tplot, '*_?psd_omni*
stop

; load the electric field data
mms_load_edp, trange=tr, data_rate='brst', probe=1
stop

tplot, 'mms1_edp_dce_gse_brst_l2'
stop

; Display colors for parallel E (black) and error (pink)
; Large error bars signifies possible presence of cold plasma
; or spacecraft charging, which can make axial electric field
; measurements difficult. Please always use error bars on e-parallel!!
options, 'mms?_edp_dce_par_epar_brst_l2', colors = [1, 0]
options, 'mms?_edp_dce_par_epar_brst_l2', labels = ['Error', 'E!D||!N']

; Since the electric field is often close to zero in multiple components, label spacing tends to get bunched together
options, '*', 'labflag', -1

tplot, ['mms?_edp_dce_dsl_brst_l2', 'mms?_edp_dce_par_epar_brst_l2']
stop

; load the spacecraft potential data
mms_load_edp, trange=tr, datatype='scpot', data_rate='brst', probe=1
stop

tplot, 'mms1_edp_scpot_brst_l2', /add
stop

; load data from the electron drift instrument (EDI)
mms_load_edi, trange=['2016-11-23', '2016-11-24']
stop

; plot the ExB drift velocity in GSE coordinates
tplot, 'mms1_edi_vdrift_gse_srvy_l2'
stop

; coordinate transformations:
;   projects/mms/examples/basic/mms_qcotrans_crib.pro
;   
; calculate Poynting vector/flux:
;   projects/mms/examples/advanced/mms_poynting_flux_crib.pro
;   
; transform to minimum variance analysis coordinates:
;   projects/mms/examples/advanced/mms_mva_crib.pro

; ----------------------------------------------------------------------------
; ----------------------------------------------------------------------------
; EPD (FEEPS/EIS) Data
; 
; https://lasp.colorado.edu/mms/sdc/public/datasets/epd/
; 
; ----------------------------------------------------------------------------
; ----------------------------------------------------------------------------

tr = ['2016-11-23', '2016-11-24']

eis_ang_ang, probe=4, trange=tr
stop

; .full_reset_session

tr = ['2016-11-23', '2016-11-24']

mms_load_feeps, datatype='electron', trange=tr, data_rate='srvy', /time_clip, probe=4

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

; flatten_spectra works on PADs as well
flatten_spectra, time='2016-11-23/2:00', /ylog
stop

mms_load_eis, datatype=['extof', 'phxtof'], trange=tr, data_rate='srvy', probe=4;, /time_clip
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

tplot, '*79-766keV_proton_flux_omni_pad_spin'
stop

flatten_spectra_multi, /ylog, time=['2016-11-23/6:00', '2016-11-23/7:00', '2016-11-23/8:00']
stop

; ----------------------------------------------------------------------------
; ----------------------------------------------------------------------------
; Plasma (FPI/HPCA) Data
; 
; https://lasp.colorado.edu/mms/sdc/public/datasets/fpi/
; https://lasp.colorado.edu/mms/sdc/public/datasets/hpca/
; 
; ----------------------------------------------------------------------------
; ----------------------------------------------------------------------------
tr = ['2016-11-23', '2016-11-24']
mms_load_fpi, /center_measurement, datatype=['dis-moms', 'des-moms'], trange=tr, probe=4;, /time_clip

; use the error bars to find potential problems with the data
tplot, ['mms4_des_errorflags_fast_moms_flagbars_full', $
        'mms4_des_numberdensity_fast', $
        'mms4_dis_errorflags_fast_moms_flagbars_full', $
        'mms4_dis_numberdensity_fast']
stop

tr = ['2016-11-23/12', '2016-11-23/12:20']

mms_load_hpca, /center_measurement, datatype=['ion', 'moments'], trange=tr, probe=4;, /time_clip
stop

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
mms_part_getspec, output=['energy', 'pa'], trange=tr, instrument='fpi', species='i', probe=4 ;, energy=[1000, 20000], /spdf
stop

tplot, ['mms4_dis_dist_fast_energy', 'mms4_dis_dist_fast_pa']
stop

; plot the calculated energy spectra compared to the energy spectra in the moments CDF files
tplot, ['mms4_dis_dist_fast_energy', 'mms4_dis_energyspectr_omni_fast']
stop

; generate the HPCA energy spectra/PAD from the H+ distribution functions
mms_part_getspec, output=['energy', 'pa'], trange=tr, instrument='hpca', species='hplus', probe=4
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

; 2D slice rotations available via the rotation keyword:
;     'BV':  The x axis is parallel to B field; the bulk velocity defines the x-y plane
;     'BE':  The x axis is parallel to B field; the B x V(bulk) vector defines the x-y plane
;     'xy':  (default) The x axis is along the data's x axis and y is along the data's y axis
;     'xz':  The x axis is along the data's x axis and y is along the data's z axis
;     'yz':  The x axis is along the data's y axis and y is along the data's z axis
;     'xvel':  The x axis is along the data's x axis; the x-y plane is defined by the bulk velocity
;     'perp':  The x axis is the bulk velocity projected onto the plane normal to the B field; y is B x V(bulk)
;     'perp_xy':  The data's x & y axes are projected onto the plane normal to the B field
;     'perp_xz':  The data's x & z axes are projected onto the plane normal to the B field
;     'perp_yz':  The data's y & z axes are projected onto the plane normal to the B field

; combine 2D slices with tplot windows
window, xsize=1000, ysize=650
tplot, ['mms4_dis_numberdensity_fast', 'mms4_dis_bulkv_gse_fast', 'mms4_dis_energyspectr_omni_fast']
mms_flipbookify, seconds=60, instrument='fpi', species='i', probe=4, data_rate='fast', trange=tr, /video
stop

tplot, ['mms4_hpca_hplus_number_density', 'mms4_hpca_hplus_ion_bulk_velocity_GSM', 'mms4_hpca_hplus_tperp', 'mms4_hpca_hplus_tparallel', 'mms4_hpca_hplus_flux_elev_0-360_spin']
mms_flipbookify, seconds=60, instrument='hpca', species='hplus', probe=4, data_rate='srvy', trange=tr, /video
stop

; FPI angle-angle/angle-energy/pa-energy plots
mms_fpi_ang_ang, '2016-11-23/12:10:30', species='i', probe=4, /png
stop

; HPCA angle-angle/angle-energy plots
mms_hpca_ang_ang, '2016-11-23/12:10:30', probe=4, data_rate='srvy', /png, filename_suffix='_hpca'
stop

end