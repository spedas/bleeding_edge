; Special Webinar on MMS/FIELDS Analysis with SPEDAS
; Eric Grimes, egrimes@igpp.ucla.edu
; 
; Please be sure to read the Data Rights and Rules before starting your analysis:
;     https://lasp.colorado.edu/mms/sdc/public/about/
;
; You can find more information on FIELDS (including the latest 
; data products guides/release notes) at the LASP SDC:
;     https://lasp.colorado.edu/mms/sdc/public/datasets/fields/
;
; FIELDS QL plots can be found at the SDC:
;     https://lasp.colorado.edu/mms/sdc/public/quicklook/
;
; Data availability status at the SDC:
;     https://lasp.colorado.edu/mms/sdc/public/about/processing/
;
; Browse the CDF files at the SDC:
;     https://lasp.colorado.edu/mms/sdc/public/data/
;

; --> be sure to mute your phone!
; --> feel free to ask questions anytime!
; 
; Agenda:
; - Introduction to load routines, keywords (FGM, SCM, EDP, EDI, DSP)
; - Coordinate transformations (cotrans / qcotrans)
; - Minimum variance analysis routines
; - Curlometer calculations
; - Wave polarization calculations
; - Dynamic power spectra
; - Poynting flux
; - FIELDS in the GUI


; ----------------------------------------------------------------------------
; ----------------------------------------------------------------------------
; Introduction
; ----------------------------------------------------------------------------
; ----------------------------------------------------------------------------

; we can load data from the fluxgate magnetometer (FGM)
mms_load_fgm, trange=['2015-10-16', '2015-10-17'], probe=4, cdf_filenames=fgm_filenames, versions=fgm_versions, /spdf
tplot, 'mms4_fgm_b_gse_srvy_l2_bvec'
stop

time_stamp, /off
tplot ; re-plot the previous figure without the time stamp in the bottom right
stop

; you can change any of the plot options for a single tplot variable using 'options'
options, 'mms4_fgm_b_gse_srvy_l2_bvec', charsize=1.5
tplot ; empty call to tplot replots the previous plot with the updated options
stop

; and the search-coil magnetometer (SCM)
mms_load_scm, trange=['2015-10-16', '2015-10-17'], probe=4, cdf_filenames=scm_filenames, versions=scm_versions, /spdf
tplot, 'mms4_scm_acb_gse_scsrvy_srvy_l2', /add
stop

; you can change the plot options for all variables using 'tplot_options'
tplot_options, 'charsize', 1.5
tplot
stop

; and the electric field data from SDP/ADP instruments (EDP)
mms_load_edp, trange=['2015-10-16', '2015-10-17'], probe=4, cdf_filenames=edp_filenames, versions=edp_versions, /spdf
tplot, 'mms4_edp_dce_gse_fast_l2', /add
stop

; load the data from the electron drift instrument (EDI)
mms_load_edi, trange=['2015-10-16', '2015-10-17'], probe=4, cdf_filenames=edi_filenames, versions=edi_versions, /spdf
tplot, ['mms4_edi_vdrift_gse_srvy_l2', 'mms4_edi_e_gse_srvy_l2'], /add
stop

; load the data from the digital siginal processor (DSP)
mms_load_dsp, trange=['2015-10-16', '2015-10-17'], probe=4, level='l2', datatype='epsd', data_rate='fast', cdf_filenames=dsp_filenames, versions=dsp_versions, /spdf
tplot, 'mms4_dsp_epsd_omni', /add
stop

; get data out of a tplot variable using 'get_data'
get_data, 'mms4_dsp_epsd_omni', data=d, dlimits=dl, limits=l
stop

; print the frequencies
print, d.V
stop

; print the metadata
help, dl
stop

; save the data back into a tplot variable using store_data
store_data, 'new_dsp_epsd_omni', data=d, dlimits=dl, limits=l
stop

; note: you can control the version # of the data loaded using the keywords: 
;     min_version='X.Y.Z' - only load versions vX.Y.Z and later; particularly useful if older files are temporarily still up at the SDC
;     /latest_version - only load the exact latest version found in the time range (e.g., if versions v6.0.0 and v6.0.1 files are found, only v6.0.1 is loaded)
;     /major_version - only load the latest major version found in the time range (e.g., if versions v5.9.1, v6.0.0 and v6.0.1 files are found, both v6 files are loaded, while v5.9.1 is ignored)

; the version #s are returned in an array, e.g., 
help, fgm_versions
stop

; print the version of the first FGM file loaded:
print, fgm_versions[0, *]
stop

; add CDF version #s to your current figure
mms_add_cdf_versions, 'FGM', fgm_versions, /right_align
mms_add_cdf_versions, 'SCM', scm_versions, /right_align
mms_add_cdf_versions, 'EDP', edp_versions, /right_align
mms_add_cdf_versions, 'EDI', edi_versions, /right_align
mms_add_cdf_versions, 'DSP EPSD', dsp_versions, /right_align
stop

; save the plot to a PNG file
makepng, 'some-fields-data'
stop

; ----------------------------------------------------------------------------
; ----------------------------------------------------------------------------
; Coordinate transformations
; ----------------------------------------------------------------------------
; ----------------------------------------------------------------------------
; important routines: mms_cotrans, mms_qcotrans
; crib sheets:
;       projects/mms/examples/basic/mms_cotrans_crib.pro
;       projects/mms/examples/basic/

; load the support data (quaternions/right ascension/declination) from the MEC files
; these are required for coordinate transformations
mms_load_mec, trange=['2015-10-16', '2015-10-17'], probe=4, /spdf
stop

; you can find the coordinate system of a tplot variable programmatically using cotrans_get_coord
print, cotrans_get_coord('mms4_mec_r_sm')
stop

; transform the FGM, SCM, and EDP data to SM coordinates
mms_cotrans, ['mms4_fgm_b_gse_srvy_l2_bvec', 'mms4_scm_acb_gse_scsrvy_srvy_l2', 'mms4_edp_dce_gse_fast_l2'], out_coord='sm', out_suffix='_sm'
tplot, ['mms4_fgm_b_gse_srvy_l2_bvec_sm', 'mms4_scm_acb_gse_scsrvy_srvy_l2_sm', 'mms4_edp_dce_gse_fast_l2_sm']
stop

print, 'Coordinate system after transforming to SM: ' + cotrans_get_coord('mms4_fgm_b_gse_srvy_l2_bvec_sm')
stop

mms_qcotrans, ['mms4_fgm_b_gse_srvy_l2_bvec', 'mms4_scm_acb_gse_scsrvy_srvy_l2', 'mms4_edp_dce_gse_fast_l2'], out_coord='gsm', out_suffix='_qgsm'
tplot, ['mms4_fgm_b_gse_srvy_l2_bvec_qgsm', 'mms4_scm_acb_gse_scsrvy_srvy_l2_qgsm', 'mms4_edp_dce_gse_fast_l2_qgsm']
stop

print, 'Coordinate system after transforming to GSM: ' + cotrans_get_coord('mms4_fgm_b_gse_srvy_l2_bvec_qgsm')
stop

; ----------------------------------------------------------------------------
; ----------------------------------------------------------------------------
; Transforming to minimum variance analysis coordinates
; ----------------------------------------------------------------------------
; ----------------------------------------------------------------------------
; important routines: minvar_matrix_make, tvector_rotate
; crib sheets: 
;       projects/mms/examples/advanced/mms_mva_crib.pro


; the default call makes a single transformation matrix that covers the entire interval
;   -use TSTART and TSTOP keywords to limit the rime range considered
;   -use NEWNAME keyword to specify a name for the output, otherwise
;    matrices are stored as input_name + "_mva_mat"
minvar_matrix_make, 'mms1_fgm_b_gse_srvy_l2_bvec', newname='mva_mat_day', $
  tstart='2015-10-16/13:00', tstop='2015-10-16/14:00'

; apply transformation to tplot variable
;   -applies a right handed rotation
tvector_rotate, 'mva_mat_day', 'mms1_fgm_b_gse_srvy_l2_bvec', newname='mva_data_day'

; update the labels for the transformed variable
options, 'mva_data_day', labels='B'+['i', 'j', 'k']+' GSE'

; update the ysubtitle for the transformed variable
options, 'mva_data_day', ysubtitle='single transformation!C[nT]'

;limit time range to plot
timespan, '2015-10-16/13:00', 1, /hour
tplot, 'mms1_fgm_b_gse_srvy_l2_bvec mva_data_day'

stop

; ----------------------------------------------------------------------------
; ----------------------------------------------------------------------------
; Curlometer calculations
; ----------------------------------------------------------------------------
; ----------------------------------------------------------------------------
; important routines: mms_curl, mms_lingradest
; crib sheets:
;       projects/mms/examples/basic/mms_curlometer_crib.pro

; ephemeris data were added to the FGM files to allow for quick/easy curlometer calculations
mms_load_fgm, trange=['2015-10-16/13', '2015-10-16/13:10'], /get_fgm_ephemeris, probes=[1, 2, 3, 4], data_rate='brst', /time_clip, /spdf

; method #1: mms_curl; code provided by Dr. Jonathan Eastwood
mms_curl, trange=['2015-10-16/13', '2015-10-16/13:10'], $
          fields='mms'+['1', '2', '3', '4']+'_fgm_b_gse_brst_l2', $
          positions='mms'+['1', '2', '3', '4']+'_fgm_r_gse_brst_l2', $
          suffix='_mms_curl'

tplot, ['divB','curlB','jtotal','jperp','jpar','baryb']+'_mms_curl'
stop

; zoom into the region of interest using tlimit
tlimit, ['2015-10-16/13:02', '2015-10-16/13:10']
stop

; method #2: mms_lingradest; code provided by Dr. Andrei Runov
mms_lingradest, fields='mms'+['1', '2', '3', '4']+'_fgm_b_gse_brst_l2', $
                positions='mms'+['1', '2', '3', '4']+'_fgm_r_gse_brst_l2', $
                suffix='_lingradest'

; now we can plot the calculated currents from both methods
tplot, ['jtotal_mms_curl', 'jtotal_lingradest']
stop

; you can use 'calc' to quickly change between the different units by multiplying a constant
calc, '"jtotal_mms_curl"="jtotal_mms_curl"*1e9'
tplot
stop

; ----------------------------------------------------------------------------
; ----------------------------------------------------------------------------
; Wave polarization analysis
; ----------------------------------------------------------------------------
; ----------------------------------------------------------------------------
; important routines: twavpol
; crib sheets:
;       projects/mms/examples/advanced/mms_wavpol_crib.pro

mms_load_scm, probe='4', trange=['2015-10-16/1', '2015-10-16/2'], /spdf

; check the header of twavpol for more details on the data products produced
twavpol, 'mms4_scm_acb_gse_scsrvy_srvy_l2', nopfft=512

; zoom into the region of interest
tlimit, ['2015-10-16/1', '2015-10-16/2']

tplot, 'mms4_scm_acb_gse_scsrvy_srvy_l2_'+['powspec', 'degpol', 'waveangle', 'elliptict', 'helict']
stop

; set the y-axis limits and change the y-axis scale to log
ylim, 'mms4_scm_acb_gse_scsrvy_srvy_l2_'+['powspec', 'degpol', 'waveangle', 'elliptict', 'helict'], .4, 16, 1

; set the colorbar to a log scale on the power spectra
zlim, 'mms4_scm_acb_gse_scsrvy_srvy_l2_powspec', 0, 0, 1

; and the colorbar to a linear scale on the others
zlim, 'mms4_scm_acb_gse_scsrvy_srvy_l2_'+['degpol', 'waveangle', 'elliptict', 'helict'], 0, 0, 0
tplot
stop

; you can change the color table using 'options'
options, 'mms4_scm_acb_gse_scsrvy_srvy_l2_powspec', color_table=65
options, 'mms4_scm_acb_gse_scsrvy_srvy_l2_degpol', color_table=49
options, 'mms4_scm_acb_gse_scsrvy_srvy_l2_waveangle', color_table=70
options, 'mms4_scm_acb_gse_scsrvy_srvy_l2_elliptict', color_table=50
options, 'mms4_scm_acb_gse_scsrvy_srvy_l2_helict', color_table=67
tplot
stop


; ----------------------------------------------------------------------------
; ----------------------------------------------------------------------------
; Dynamic power spectra
; ----------------------------------------------------------------------------
; ----------------------------------------------------------------------------
; important routines: tdpwrspc
; crib sheets:
;       projects/mms/examples/basic/mms_load_scm_crib.pro

mms_load_scm, probe='4', trange=['2015-10-16/1', '2015-10-16/2'], /spdf

tdpwrspc, 'mms4_scm_acb_gse_scsrvy_srvy_l2', nboxpoints=512

tplot, ['mms4_scm_acb_gse_scsrvy_srvy_l2_x_dpwrspc', $
        'mms4_scm_acb_gse_scsrvy_srvy_l2_y_dpwrspc', $
        'mms4_scm_acb_gse_scsrvy_srvy_l2_z_dpwrspc']
stop

calc, '"w_ci"='+string(!const.E)+'*"mms4_fgm_b_gse_srvy_l2_btot"/'+string(!const.MP)

; divide by 1e9 because the field is in nT
calc, '"w_ci"="w_ci"/1e9'

; convert to frequency by dividing by 2pi
calc, '"f_ci"="w_ci"/(2*'+string(!dpi)+')'
stop

store_data, 'x_dpwrspc_with_f', data='mms4_scm_acb_gse_scsrvy_srvy_l2_x_dpwrspc f_ci'
;store_data, 'x_dpwrspc_with_f', data=['mms4_scm_acb_gse_scsrvy_srvy_l2_x_dpwrspc', 'f_ci']
store_data, 'y_dpwrspc_with_f', data='mms4_scm_acb_gse_scsrvy_srvy_l2_y_dpwrspc f_ci'
store_data, 'z_dpwrspc_with_f', data='mms4_scm_acb_gse_scsrvy_srvy_l2_z_dpwrspc f_ci'

ylim, ['x_dpwrspc_with_f', 'y_dpwrspc_with_f', 'z_dpwrspc_with_f'], 0.1, 16, 1

; remove labels and units stored in ysubtitle that were taken from the B-field
options, ['x_dpwrspc_with_f', 'y_dpwrspc_with_f', 'z_dpwrspc_with_f'], labels='', ysubtitle=''

tplot, ['x_dpwrspc_with_f', 'y_dpwrspc_with_f', 'z_dpwrspc_with_f']

; zoom into the region of interest
tlimit, ['2015-10-16/1', '2015-10-16/2']
stop

; ----------------------------------------------------------------------------
; ----------------------------------------------------------------------------
; Poynting flux calculations
; ----------------------------------------------------------------------------
; ----------------------------------------------------------------------------
; crib sheets:
;       projects/mms/examples/advanced/mms_poynting_flux_crib.pro

mms_load_scm, trange=['2015-10-16/13', '2015-10-16/14'], probe=4, data_rate='brst', /spdf
mms_load_edp, trange=['2015-10-16/13', '2015-10-16/14'], probe=4, data_rate='brst', /spdf

tinterpol, 'mms4_scm_acb_gse_scb_brst_l2', 'mms4_edp_dce_gse_brst_l2'

get_data, 'mms4_edp_dce_gse_brst_l2', data=edp_data
get_data, 'mms4_scm_acb_gse_scb_brst_l2_interp', data=scm_data

Fmin = 200.
Fmax = 8192.

edp_filtered = time_domain_filter(edp_data, Fmin, Fmax)
scm_filtered = time_domain_filter(scm_data, Fmin, Fmax)

E = edp_filtered.y
B = scm_filtered.y

; S = 1/mu_0*(E x B)
S = dblarr(n_elements(edp_data.X),3)

; calculate the cross product, E x B
S[*,0]= E[*,1]*B[*,2]-E[*,2]*B[*,1]
S[*,1]=-E[*,0]*B[*,2]+E[*,2]*B[*,0]
S[*,2]= E[*,0]*B[*,1]-E[*,1]*B[*,0]

; mV->V, nT->T, W->uW, divide by mu_0
S_conversion=1d-3*1d-9*1d6/(4d-7*!dpi)

S *= S_conversion

store_data, 'poynting_flux', data={x:edp_filtered.x, y:S}
options, 'poynting_flux', ytitle='S', ysubtitle='[!4l!3W/m!U2!N]', colors=[2, 4, 6], labels=['Sx', 'Sy', 'Sz'], labflag=-1

; reset the trange for our tplot windows
tlimit, /full

tplot, 'poynting_flux'
stop

; Question from the webinar: how to change the linestyle for a single component of the vector
; split the vector into its components (each component with its own tplot variable)
split_vec, 'poynting_flux'

; change the linestyle using options
options, 'poynting_flux_x', linestyle=4

; now recombine the components into another tplot variable
store_data, 'new_pf', data=['poynting_flux_x', 'poynting_flux_y', 'poynting_flux_z']

; replot with the X-component has a linestyle set
tplot, 'new_pf'
stop

; ----------------------------------------------------------------------------
; ----------------------------------------------------------------------------
; FIELDS in the GUI
; ----------------------------------------------------------------------------
; ----------------------------------------------------------------------------

; import some CL data into the GUI
tplot_gui, ['mms4_edp_dce_gse_brst_l2', 'mms4_scm_acb_gse_scb_brst_l2', 'poynting_flux']

stop
end