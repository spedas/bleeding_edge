; Analyzing MMS data with SPEDAS - EIS/FEEPS
;     Eric Grimes, egrimes@igpp.ucla.edu
;
; You can find more information on EIS and FEEPS at the LASP SDC:
;     https://lasp.colorado.edu/mms/sdc/public/datasets/epd/
;     
; EIS and FEEPS QL plots can be found at the SDC:
;     https://lasp.colorado.edu/mms/sdc/public/quicklook/
;
; Data availability status at the SDC:
;     https://lasp.colorado.edu/mms/sdc/public/about/processing/
; 
; Browse the CDF files at the SDC:
;     https://lasp.colorado.edu/mms/sdc/public/data/
; 

; Agenda:
; --> feel free to ask questions!
; 1) Introduction to standard routines and keywords
; 2) Loading and plotting the EIS Data
; 3) Calculating EIS pitch angle distributions
; 4) Generating EIS angle-angle (polar versus azimuthal) plots
; 5) Loading and plotting the FEEPS Data
; 6) Calculating FEEPS pitch angle distributions

;=============================================================================
; Relevant crib sheets
;     projects/mms/examples/basic/mms_load_eis_crib.pro
;     projects/mms/examples/basic/mms_load_eis_burst_crib.pro
;     projects/mms/examples/basic/mms_eis_angle_angle_crib.pro
;     projects/mms/examples/basic/mms_load_feeps_crib.pro
;     projects/mms/examples/basic/mms_feeps_sectspec_crib.pro
;     
;     (The following require an MMS username/password, but can produce figures 
;     with the latest data)
;     
;     projects/mms/examples/quicklook/mms_load_eis_crib_qlplots.pro
;     projects/mms/examples/quicklook/mms_load_feeps_crib_qlplots.pro 
;     projects/mms/examples/quicklook/mms_load_feeps-eis_crib_qlplots.pro
;     
;=============================================================================
;1) Introduction to standard routines and keywords
;   
; standard keywords: 
;    trange: time range of interest.
;    probe: spacecraft # (or array of S/C numbers - [1, 2, 3, 4])
;    data_rate: srvy or brst
;    level: L2 (also available: l1b, l1a - non-L2 requires MMS team user/password)
;    time_clip: clip the data down to the time range specified in trange
;
;    cdf_filenames: returns a list of CDF files loaded
;    versions: returns a list of CDF version #s for the loaded data
;    
;    cdf_version: only load this specific version
;    min_version: only load this version and later
;    latest_version: only load the latest version found in the trange
; 
; EIS - mms_load_eis
;    datatype: ExTOF, PHxTOF, electronenergy
; 
; FEEPS - mms_load_feeps
;    datatype: electron, ion

;=============================================================================
;2) Loading and plotting the EIS Data

mms_load_eis, probe=3, data_rate='srvy', trange=['2016-05-08', '2016-05-09']
stop

; show the variable names for the spin averaged, omni-directional fluxes:
tplot_names, '*_flux_omni_spin'
stop

; there's also a function for returning all tplot names that match a certain pattern
tplot, tnames('*_flux_omni_spin')
stop

get_data, 'mms3_epd_eis_extof_proton_flux_omni_spin', data=d
help, d, /structure
; d.X = the time values, in unix times
; d.Y = the data
; d.V = the energies
stop

; print the first time in the data as a string
print, time_string(d.X[0])
stop

; print the data at time index = 1000
print, d.Y[1000, *]
stop

; if you'd like to find the data at a specific time, but you're not sure of 
; the exact millisecond to specify, you can use find_nearest_neighbor to search
my_time = '2016-05-08/11:32:01'
closest_time = find_nearest_neighbor(d.X, time_double(my_time))
print, 'the closest time in the dataset to your time is: ' + time_string(closest_time, tformat='YYYY-MM-DD/hh:mm:ss.fff')
print, d.Y[where(d.X eq closest_time), *]
stop

; print the energies
print, d.V
stop

; resave the data as a new variable; this is how you create tplot variables
; from scratch
store_data, 'new_var', data={x: d.X, y: d.Y, v: d.V}
tplot, 'new_var'
stop

; use options to set the new_var to a spectra variable
options, 'new_var', spec=1
tplot, 'new_var'
stop

options, 'new_var', ytitle='MMS3!CExTOF!CProtons'
tplot
stop

options, 'new_var', ysubtitle='[keV]'
tplot
stop

options, 'new_var', /ylog, /zlog
tplot
stop

; ystyle = 1 forces the y axis range to the exact yrange
options, 'new_var', yrange=minmax(d.V), ystyle=1
tplot
stop

; and finally, we can set the units on the colorbar
options, 'new_var', ztitle='1/(cm!U2!N-sr-s-keV)'
tplot
stop

; turn the time stamp off on the figure
time_stamp, /off
tplot
stop

copy_data, 'new_var', 'eis_extof_proton_flux'
tplot, 'eis_extof_proton_flux'
stop

del_data, 'new_var'
stop

; turn interpolation back on
options, 'eis_extof_proton_flux', y_nointerp=0, no_interp=0
tplot
stop

tprint, 'eis_extof_proton_flux', /landscape
stop

; default metadata are stored in 'dlimits'
get_data, 'mms3_epd_eis_extof_proton_flux_omni_spin', dlimits=dl
help, dl, /structure
stop

; CDF metadata is stored in the CDF structure in the dlimits
help, dl.cdf, /structure
stop

; interested in finding the burst intervals?
mms_load_brst_segments, trange=['2016-05-08', '2016-05-09'], start_times=starts, end_times=ends

; add the burst intervals to the top of the plot
tplot, /add, 'mms_bss_burst'
stop

; change the color of the burst mode bar, and the size of the label
options, 'mms_bss_burst', colors=2, charsize=1
tplot
stop

; use the IDL color palette tool to see or change the currently set colorbar
xpalette
stop

; we can load burst mode data by changing data_rate
mms_load_eis, probe=3, data_rate='brst', trange=['2016-05-08/10:28:54', '2016-05-08/11:23:04'], suffix='_burstmode', /time_clip
stop

; plot the burst mode data
tplot, tnames('*_flux_omni_burstmode_spin')
stop

; zoom into the plot
tlimit, '2016-05-08/10:40', '2016-05-08/10:50'
stop

; you can also zoom back out
tlimit, /full
stop

; and zoom in using a %
tlimit, zoom=0.5 ; 50% zoom
stop

; you can also load pulse height x time of flight data
mms_load_eis, datatype='phxtof', probe=3, data_rate='srvy', trange=['2016-05-08', '2016-05-09']
stop

tplot, '*_phxtof_proton_flux_omni_spin'
stop

; you can change the y/z limits using ylim and zlim:
ylim, '*_phxtof_proton_flux_omni_spin', 10, 100, 1 ; 1 here sets a log scale
tplot
stop

; you can change the y axis limits and turn off the log scale:
ylim, '*_phxtof_proton_flux_omni_spin', 10, 60, 0 ; 1 here sets a log scale
tplot
stop

; and change the colorbar to linear scaling using zlim:
; note: 0, 0 for the range tells ylim and zlim to use the current min/max of the data
zlim, '*_phxtof_proton_flux_omni_spin', 0, 0, 0
tplot 
stop

tlimit, /full ; reset to the full time range
stop

; By default, EIS spectra are interpolated on plots; we can load the same ExTOF 
; data as before, but this time turn off interpolation using the no_interp keyword
mms_load_eis, /no_interp, datatype='extof', probe=3, data_rate='srvy', trange=['2016-05-08', '2016-05-09']
tplot, '*_extof_*_flux_omni_spin'
stop

;=============================================================================
;3) Calculating EIS pitch angle distributions

mms_eis_pad, species='proton', datatype='phxtof', probe=3

tplot, 'mms3_epd_eis_phxtof_0-1000keV_proton_flux_omni_pad'+['', '_spin']
stop

; calculate the PAD in counts per second
mms_eis_pad, data_units='cps', species='proton', datatype='phxtof', probe=3

tplot, 'mms3_epd_eis_phxtof_0-1000keV_proton_cps_omni_pad'+['', '_spin']
stop

mms_eis_pad, energy=[30, 40], species='proton', datatype='phxtof', probe=3

tplot, 'mms3_epd_eis_phxtof_30-40keV_proton_flux_omni_pad'+['', '_spin']
stop

; bin_size is specified in degrees
mms_eis_pad, bin_size=5, datatype='phxtof', probe=3

tplot, 'mms3_epd_eis_phxtof_0-1000keV_proton_flux_omni_pad'+['', '_spin']
stop
  
;=============================================================================
;4) Generating EIS angle-angle (polar versus azimuthal) plots
; note: 1-column per spin if <= 16 spins; 16 columns over the time range if > 16 spins
eis_ang_ang, species='proton', probe=3, trange=['2016-05-08', '2016-05-09']
stop

eis_ang_ang, species='oxygen', probe=3, trange=['2016-05-08', '2016-05-09']
stop

eis_ang_ang, energy_chan=[1, 2, 3, 4, 5], probe=3, trange=['2016-05-08', '2016-05-09']
stop

; interested in saving it?
eis_ang_ang, png='eis_angle_angle_plot', probe=3, trange=['2016-05-08', '2016-05-09']
stop

 ; high quality postscript file?
eis_ang_ang, p_filename='eis_angle_angle_plot.ps', /i_print, probe=3, trange=['2016-05-08', '2016-05-09']
stop

; should .full_reset_session to reset the current plot options

;=============================================================================
;5) Loading and plotting the FEEPS Data
; note: some extra processing happens on loading the FEEPS data into SPEDAS,
; including: 
;   1) The 500 keV integral channel is removed from spectra products 
;      These variable names end in: "_clean"
;   2) Sun contamination is removed from the "_clean" variables produced in (1)
;      These variable names end in: "_clean_sun_removed"
;   3) omni-directional and spin averages are then calculated from the 
;      "_clean_sun_removed" variables

mms_load_feeps, data_rate='srvy', trange=['2016-05-08', '2016-05-09']
tplot, 'mms1_epd_feeps_srvy_l2_electron_intensity_omni_spin'
stop

; You can also smooth the data using the num_smooth keyword
; number of seconds
mms_load_feeps, num_smooth=30, trange=['2016-05-08', '2016-05-09']
; num_smooth creates a variable that ends in "_smth" with the smoothed spectrogram
tplot, 'mms1_epd_feeps_srvy_l2_electron_intensity_omni_smth'
stop

; You can grab the CDF filenames and the version #s for the files using keywords:
mms_load_feeps, trange=['2016-05-08', '2016-05-09'], cdf_filenames=filenames, versions=versions
print, filenames
stop
print, versions
stop

; to get a list of files, their download sizes, as well as the total download size, 
; use the /available keyword (note: no data are downloaded when this keyword is set)
mms_load_feeps, /available, data_rate='brst', trange=['2016-05-01', '2016-06-30']
; Total download size: 11549.9 MB
stop

; if you're having trouble grabbing the data from the SDC, you can use the /spdf keyword
; to load the data from the SPDF instead
mms_load_feeps, /spdf, trange=['2016-05-08', '2016-05-09']
stop

;=============================================================================
;6) Calculating FEEPS pitch angle distributions
mms_feeps_pad
stop

tplot, 'mms1_epd_feeps_srvy_l2_electron_intensity_0-1000keV_pad_spin', /add
stop

; as with EIS PADs, you can specify the size of the PA bins
mms_feeps_pad, bin_size=3
tplot
stop

; calculate the pitch angle distribution for 100-200 keV electrons:
mms_feeps_pad, energy=[100, 200]
mms_feeps_pad, energy=[200, 300]
mms_feeps_pad, energy=[300, 400]

; set the colorbar to the same scale for all the PADs before plotting
zlim, '*_electron_intensity_?00-?00keV_pad', 0.1, 671708., 1
tplot, '*_electron_intensity_?00-?00keV_pad'
stop

; as with the load routine, the FEEPS PAD routine also supports the num_smooth keyword
mms_feeps_pad, num_smooth=30
stop

options, 'mms1_epd_feeps_srvy_l2_electron_radius', ytitle='Radius [Re]'
tplot_options, var_label='mms1_epd_feeps_srvy_l2_electron_radius'

tplot, ['mms1_epd_feeps_srvy_l2_electron_intensity_omni_smth', $
       'mms1_epd_feeps_srvy_l2_electron_intensity_0-1000keV_pad_smth']
stop

; add Dst to the top of the plot
kyoto_load_dst, trange=['2016-05-08', '2016-05-09'], /apply_time_clip
tplot, /add, 'kyoto_dst'
stop

; add a vertical bar at minimum Dst
timebar, '2016-05-08/08:00:00', thick=2
stop

; you can use tplot_names to see when the variables were created
tplot_names, /create_time
stop

; you can also use tplot_names to see the time range of each tplot variable in memory
tplot_names, /time_range
stop

; save the current tplot data to be used later
tplot_save, '*', filename='saved_data' ; appends .tplot to the filename
stop

; .full_reset_session to delete all of the data

tplot_restore, filename='saved_data.tplot'
stop

tplot, [95, 104]
stop


end
