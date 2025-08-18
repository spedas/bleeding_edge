;+
; Procedure:
;         goes_load_crib_sheet
;         
; Purpose:
;         Example of loading GOES data using the command line
;              
;        
; Notes:
;     The GOES routines have their own configuration routines,
;     since the data products are in a different location than the
;     THEMIS products.  goes_init will create a reasonable default
;     configuration and save it in a file. goes_read_config and
;     goes_write_config let you customize !goes in case you 
;     are at SSL and don't need HTTP downloads, or if you have
;     an alternate source for GOES products (e.g. a local mirror)
; 
;  
; $LastChangedBy: egrimes $
; $LastChangedDate: 2014-02-28 14:10:44 -0800 (Fri, 28 Feb 2014) $
; $LastChangedRevision: 14467 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/goes/goes_load_crib_sheet.pro $
;-

; initialize the GOES configuration
goes_init, /reset

; we'll be making a lot of windows, so let's use a variable to keep track
windownum = 0

; set the default time span of 21 days
timespan, '2012-01-01', 21, /days

; start by loading some 1-m averaged magnetometer data for GOES-15. Note that you can see the 
; tplot variables created by the load routine in 'tplotnames'
goes_load_data, trange = trange, datatype = 'fgm', probes = '15', /avg_1m, tplotnames = tplotnames

; make a plot of H from both FGM sensors in ENP coordinates 
; (note: ENP coordinates is the native GOES coordinate system)
tplot, ['g15_H_enp_1', 'g15_H_enp_2'], window=windownum

stop

; we can transform the FGM data into other coordinate systems as well,
; first by making a transformation matrix, using the position data loaded from the load routine. 
; the new transformation matrix should be named 'g15_pos_gei_enp_mat'
enp_matrix_make, 'g15_pos_gei'

; rotate the FGM data from ENP coordinates to GEI coordinates
tvector_rotate, 'g15_pos_gei_enp_mat', 'g15_H_enp_1', /invert

; that rotation gives a tplot variable with the horrible name 'g15_b_enp_rot', we can copy
; it to a new variable with a better name, 'g15_H_gei'
copy_data, 'g15_H_enp_1_rot', 'g15_H_gei'

; and now we can set the labels and title appropriately
options,'g15_H_gei',labels=['x_gei','y_gei','z_gei'],ytitle='g15_H_gei'

; and finally plot H, from the first sensor, in both ENP coordinates and GEI coordinates
window, ++windownum
tplot, ['g15_H_enp_1', 'g15_H_gei'], window=windownum
stop

; load some 1-m averaged data from the magnetospheric electron detector onboard GOES-15
; using the /noephem keyword because we've already loaded the ephemeris data for this time range
goes_load_data, trange = trange, datatype = 'maged', probes = '15', /avg_1m, tplotnames = tplotnames, /noephem

; plot the flux of mangetospheric electrons at 40 keV
; note that the name of the tplot variable containing the flux loaded can take a variety of forms, 
; depending on the data. This example shows 40keV electrons, corrected for dead times and other 
; sources of contamination
window, ++windownum
tplot, 'g15_maged_40keV_dtc_cor_flux', window=windownum

; open another window for plotting the uncorrected data 
window, ++windownum
; for this time (first 21 days of 2012), we also have MAGED data that has been corrected for dead times,
; but not other forms of contamination
tplot, 'g15_maged_40keV_dtc_uncor_flux', window=windownum

stop

; now, we can calculate the pitch angles for each of the telescopes using FGM data
goes_lib ; compiles GOES post processing library routines

; this should create a new tplot variable named 'goes_pitch_angles' with the center pitch angle
; for each of the 9 telescopes
goes_pitch_angles, 'g15_H_enp_1', 'g15_HT_1', prefix = 'g15'
window, ++windownum
tplot, 'g15_pitch_angles', window=windownum

stop


; load some 5-m averaged data from the magnetospheric proton detector onboard GOES-15
; note that 1-m averaged data is also available here, we choose to show 5-m averages here 
; so that the user knows both 1-m and 5-m averages are available for most GOES instruments
goes_load_data, trange = trange, datatype = 'magpd', probes = '15', /avg_5m, tplotnames = tplotnames, /noephem

; open a new window for plotting the MAGPD data
window, ++windownum
; plot the magnetospheric proton flux at 95 keV, corrected for dead times but not other sources of
; contamination (electrons)
tplot, 'g15_magpd_95keV_dtc_cor_flux', window=windownum

stop

; load some 1-m averaged X-ray flux from the XRS instrument
goes_load_data, trange = trange, datatype = 'xrs', probes = '15', /avg_1m, tplotnames = tplotnames, /noephem

; open a new window for plotting GOES XRS data
window, ++windownum
tplot, 'g15_xrs_avg', window=windownum

stop

; load some 1-m averaged data from the electron, proton and alpha detector (EPEAD)
goes_load_data, trange = trange, datatype = 'epead', probes = '15', /avg_1m, tplotnames = tplotnames, /noephem

; open a new window for plotting proton data from the GOES EPEAD instrument
; the center energy for this bin is 2.5 MeV
window, ++windownum
tplot, 'g15_prot_2.5MeV_uncor_flux', window=windownum

; open a window for plotting electron data from the GOES EPEAD instrument
; the center energy for this bin is 0.6 MeV
window, ++windownum
tplot, 'g15_elec_0.6MeV_uncor_flux', window=windownum

; open a window for plotting alpha particle data from the GOES EPEAD instrument
; the center energy for this bin is 6.8 MeV
window, ++windownum
tplot, 'g15_alpha_6.8MeV_flux', window=windownum

stop

; load some 1-m averaged data from the high energy proton and alpha detector 
goes_load_data, trange = trange, datatype = 'hepad', probes = '15', /avg_1m, tplotnames = tplotnames, /noephem

; open a new window for plotting high energy proton data from HEPAD
window, ++windownum
; the center energy for this bin is 375 MeV
tplot, 'g15_hepadp_375MeV_flux', window=windownum

; open a new window for plotting high energy alpha data from HEPAD
window, ++windownum
; the center energy for this bin is 2980 MeV
tplot, 'g15_hepada_2980MeV_flux', window=windownum

stop

; finally, we load some data for the energetic particle sensor (EPS) onboard the GOES spacecraft
; prior to GOES-13 (the EPS instrument is valid for GOES-12 and below)
; set a new time span for loading GOES-12 EPS data
timespan, '2008-01-01', 21, /days

; note that only averaged data (1-m, 5-m) is available for the EPS instrument 
goes_load_data, datatype = 'eps', probes = '12', /avg_1m

; open a new window for plotting the electron integral flux for GOES-12 EPS at 0.6MeV
window, ++windownum
tplot, 'g12_elec_0.6MeV_iflux', window=windownum

; open a new window for plotting the proton flux at 2.4 MeV
window, ++windownum
tplot, 'g12_prot_2.4MeV_flux', window=windownum

stop
end