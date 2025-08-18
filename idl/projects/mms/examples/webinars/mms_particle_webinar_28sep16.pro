

; Tentative agenda:
; 1) Introduction to FPI, HPCA load routines, standard keywords
; 2) Loading and Plotting the Particle Data
; 3) Spectra from the Particle Distributions
; 4) Particle Slices (2D/3D slices)
; 
; 
;====================================================================================
; 1) Introduction to the FPI load routine, standard keywords
; 
; More information on the FPI dataset can be found at:
;   https://lasp.colorado.edu/mms/sdc/public/datasets/fpi/
;   
; More examples can be found at:
;   mms_load_fpi_crib, mms_load_fpi_burst_crib, and mms_load_fpi_crib_qlplots
; 
; Load routine standard keywords:
;   trange: [start, end]
;   probes: [1, 2, 3, 4]
;   datatype: electrons: des-dist, des-moms; ions: dis-dist, dis-moms
;   level: l2
;   data_rate: fast, brst
;   suffix: append a suffix to the variable names
;   
;   
;   center_measurement: adjust time stamps of the data so that each 
;       timestamp corresponds to the center of the measurement


; note: default data_rate is fast survey
mms_load_fpi, trange=['2015-12-15', '2015-12-16'], datatype='des-moms', probe=2, /center_measurement

; show the variables that were loaded
tplot_names
stop

; plot the electron energy spectra and average pitch angle distribution
tplot, ['mms2_des_energyspectr_omni_avg', 'mms2_des_pitchangdist_avg']
stop

; note: interpolating through gaps by default; you can stop this by removing gaps
; using tdegap:
tdegap, ['mms2_des_energyspectr_omni_avg', 'mms2_des_pitchangdist_avg'], /overwrite
tplot ; empty call to tplot tells it to replot the current window
stop

; Introduction to the HPCA load routine, standard keywords
;
; More information on the HPCA dataset can be found at:
; https://lasp.colorado.edu/mms/sdc/public/datasets/hpca/
;
; Load routine standard keywords:
;   same as FPI, except:
;   datatype: ion, moments
;   data_rate: srvy, brst
;

; load the HPCA ion data (note: default data_rate is srvy)
mms_load_hpca, trange=['2015-12-15', '2015-12-16'], datatype='ion', probe=2, /center_measurement
stop

; the data hasn't been summed over the anodes yet (note the anodes dimension in the tplot variable)
print_tinfo, 'mms2_hpca_hplus_flux'
stop

mms_hpca_calc_anodes, fov=[0, 360], probe=2
tplot, 'mms2_hpca_hplus_flux_elev_0-360'
stop

; now sum the fluxes for each spin
mms_hpca_spin_sum, probe='2'

tplot, ['mms2_hpca_hplus_flux_elev_0-360_spin', $
  'mms2_hpca_oplus_flux_elev_0-360_spin', $
  'mms2_hpca_heplus_flux_elev_0-360_spin', $
  'mms2_hpca_heplusplus_flux_elev_0-360_spin']
stop

; There are quite a few other useful keywords, e.g., /available allows you
; to see which files would be downloaded, as well as the total download size,
; without actually going out to download the data:
mms_load_hpca, probes=[1, 2, 3, 4], trange=['2015-12-1', '2015-12-31/23:59'], datatype='ion', /available
; Total download size: 57658.2 MB
stop

; This is very useful for answering questions like: how much data would be downloaded 
; if we were to request brst data instead of srvy?
mms_load_hpca, probe=2, trange=['2015-12-1', '2016-1-1'], datatype='ion', /available, data_rate='brst'
; Total download size: 711.4 MB
stop

; All MMS load routines in SPEDAS also have a keyword (/spdf) for downloading the data
; from SPDF instead of the MMS SDC:
mms_load_fpi, trange=['2015-12-15', '2015-12-16'], datatype='des-moms', probe=2, /spdf

tdegap, ['mms2_des_energyspectr_omni_avg', 'mms2_des_pitchangdist_avg'], /overwrite
tplot, ['mms2_des_energyspectr_omni_avg', 'mms2_des_pitchangdist_avg']
stop

; There's a routine for finding where the burst segments are:
spd_mms_load_bss, trange=['2015-12-15', '2015-12-16'], datatype=['fast', 'burst'], /include_labels
tplot, ['mms_bss_fast','mms_bss_burst'], /add
stop

; If you need the exact dates and times of the burst intervals instead:
mms_load_brst_segments, trange=['2015-12-15', '2015-12-16'], start_times=starts, end_times=ends
print, time_string(starts[0]) ; prints the start time of the first burst segment
print, time_string(ends[0]) ; prints the end time of the first burst segment
stop

; Downloading FPI burst data is just a matter of specifying the data rate:
mms_load_fpi, data_rate='brst', trange=['2015-12-15/11:30', '2015-12-15/11:40'], datatype='des-moms', probe=2
tplot, ['mms2_des_energyspectr_omni_avg', 'mms2_des_numberdensity_dbcs_brst']
tlimit, ['2015-12-15/11:30', '2015-12-15/11:40']
stop

; add the FPI Data Quality Flags bar
; see: https://lasp.colorado.edu/galaxy/display/mms/FPI+Data+Quality+Flags
tplot, 'mms2_des_errorflags_brst_moms_flagbars', /add
stop

; add the compressionloss bar to the figure
tplot, 'mms2_des_compressionloss_brst_moms_flagbars', /add
stop

; The load routines can also return a list of CDF filenames, as well as the CDF version #s
; of the loaded data:
mms_load_fpi, trange=['2015-12-15', '2015-12-16'], datatype='des-moms', probe=2, cdf_filenames=filenames, versions=version_numbers
print, filenames 
stop

print, version_numbers
stop

; There are also keywords for controlling which CDF versions to load and which to 
; ignore, e.g., 
;       cdf_version: specify a specific CDF version # to load, all others are ignored
;       min_version: specify a minimum CDF version # to load, all below are ignored
;       latest_version: only load the latest version found
;       
; note: format *must* match X.Y.Z, e.g., 2.1.0 for v2.1.0 files:
mms_load_fpi, trange=['2015-12-15', '2015-12-16'], datatype='des-moms', probe=2, min_version='2.1.0'
stop

; There's also a keyword for returning the list of variable names that were loaded:
mms_load_fpi, trange=['2015-12-15', '2015-12-16'], datatype='des-moms', probe=2, tplotnames=tplotnames_list
print, tplotnames_list
stop

; To see all of the keywords available, as well as their documentation, 
; see the header of the load routines using:
; .edit mms_load_fpi 
;     or
; .edit mms_load_hpca
; from the IDL command prompt

;====================================================================================
; 2) Loading and Plotting the Particle Data

; the best place to start in SPEDAS is usually the 'examples' folder
; FPI:
;   projects/mms/examples/advanced/
;     mms_load_fpi_summary_crib: creates summary plots with FPI data
;     mms_fpi_dist_slice_comparison_crib_l2: comparison of 2D slices in a single window
; 
;

del_data, '*'

;====================================================================================
; 3) Spectra from the Particle Distributions
; 
; in addition to loading the spectra from the FPI and HPCA files
; you can also use SPEDAS tools to generate the energy, pitch angle and gyrophase spectra
; directly from the distributions

; The main tool here is: mms_part_products

trange = time_double(['2015-10-16/13:06', '2015-10-16/13:08'])
; note, including an extra +- 60 seconds for support data
trange_support_data = trange+[-60, 60] 

; load some FPI distribution data
mms_load_fpi, datatype='des-dist', trange=trange, probe=3, data_rate='brst', /time_clip

; load some state data (needed for coordinate transforms and field aligned coordinates) 
mms_load_state, trange=trange_support_data, probe=3

; we also need FGM data (for field-aligned spectra)
mms_load_fgm, trange=trange_support_data, probe=3, data_rate='brst'

; do the calculation
mms_part_products, 'mms3_des_dist_brst', trange=trange, mag_name='mms3_fgm_b_gse_brst_l2_bvec', pos_name='mms3_defeph_pos', $
  outputs=['phi','theta','energy','pa','gyro']

tplot, ['mms3_des_dist_brst_energy', 'mms3_des_dist_brst_pa', 'mms3_des_dist_brst_gyro']
stop

; you can limit the energy range using the energy keyword:
mms_part_products, 'mms3_des_dist_brst', output='energy', energy=[15,1e4] ; eV

tplot, ['mms3_des_dist_brst_energy', 'mms3_des_dist_brst_pa', 'mms3_des_dist_brst_gyro']
stop

; you can also limit the PA range with the pitch keyword:
; (note: gyro and pa limits do not affect phi/theta spectra)
; (note 2: output accepts an array or string separated by spaces)
mms_part_products, 'mms3_des_dist_brst', mag_name='mms3_fgm_b_gse_brst_l2_bvec', pos_name='mms3_defeph_pos', $
  output='energy pa', pitch=[45,135] ; deg

; set the options so that tplot doesn't automatically adjust 
; the plot to 45-135 deg
options, 'mms3_des_dist_brst_pa', ystyle=1, yrange=[0, 180.] 

tplot, ['mms3_des_dist_brst_energy', 'mms3_des_dist_brst_pa', 'mms3_des_dist_brst_gyro']
stop

; all of this also works with HPCA distributions as well
mms_load_hpca, probe=1, datatype='ion', trange=['2015-10-16', '2015-10-17']
mms_part_products, 'mms1_hpca_hplus_phase_space_density', output='energy'

tplot, 'mms1_hpca_hplus_phase_space_density_energy'
stop

;====================================================================================
; 4) Particle Slices (2D/3D slices)

; lets load some ion distribution data for FPI
mms_load_fpi, probe=1, data_rate='brst', datatype='dis-dist', trange=['2015-10-16/13:06', '2015-10-16/13:07'] 
mms_load_fgm, trange=['2015-10-16/13:06', '2015-10-16/13:07'], probe=1, data_rate='brst'

; reformat the data from tplot variable into compatible 3D structures
dist = mms_get_dist('mms1_dis_dist_brst', trange=['2015-10-16/13:06', '2015-10-16/13:07'] )

; plot using the default of 3D interpolation
; (The entire 3-dimensional distribution is linearly interpolated onto a
;  regular 3d grid and a slice is extracted from the volume.)
slice = spd_slice2d(dist, time='2015-10-16/13:06:00') 

spd_slice2d_plot, slice
stop

; plot using the default of 3D interpolation, this time
; with a custom rotation
evec=fltarr(3,3)
evec[*,0]= [0.33796266 , -0.082956984 , 0.93749634]
evec[*,1]= [0.64217210 , -0.70788234 , -0.29413872]
evec[*,2]= [0.68803796 , 0.70144189 , -0.18596514]

slice = spd_slice2d(dist, time='2015-10-16/13:06:00', custom_rotation=evec)

spd_slice2d_plot, slice
stop

; you can change to 2d interpolation:
; (Datapoints within the specified theta or z-axis range are projected onto
;  the slice plane and linearly interpolated onto a regular 2D grid.)
slice = spd_slice2d(dist, time='2015-10-16/13:06:00', /two)

spd_slice2d_plot, slice
stop

; you can also change to geometric interpolation
;  (Each point on the plot is given the value of the bin it instersects.
;   This allows bin boundaries to be drawn at high resolutions.)
slice = spd_slice2d(dist, time='2015-10-16/13:06:00', /geo)

spd_slice2d_plot, slice
stop

; 
mms_load_hpca, probe=1, data_rate='brst', datatype='ion', trange=['2015-10-16/13:06', '2015-10-16/13:07'] 

dist = mms_get_dist('mms1_hpca_hplus_phase_space_density', trange=['2015-10-16/13:06', '2015-10-16/13:07'] )

; average all data in specified time window
; window (sec) starts at TIME
slice = spd_slice2d(dist, time='2015-10-16/13:06:30', /geo, window=15) 

spd_slice2d_plot, slice
stop

; average all data in specified time window
; window centered on TIME
slice = spd_slice2d(dist, time='2015-10-16/13:06:30', /geo, window=15, /center_time)  

spd_slice2d_plot, slice
stop

;average specific number of distributions (uses N closest to specified time)
slice = spd_slice2d(dist, time='2015-10-16/13:06:30', /geo, samples=3)

spd_slice2d_plot, slice
stop

; you can specify a number of different rotations using the rotation keyword

; first, we'll need the velocity stored as a vector - we can load that from 
; the moments file
mms_load_hpca, probe=1, data_rate='brst', datatype='moments', trange=['2015-10-16/13:06', '2015-10-16/13:07'] 

slice = spd_slice2d(dist, time='2015-10-16/13:06:00', rotation='BE', mag_data='mms1_fgm_b_gse_brst_l2_bvec', vel_data='mms1_hpca_oplus_ion_bulk_velocity')

spd_slice2d_plot, slice
stop
; rotations available via the rotation keyword:
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

end