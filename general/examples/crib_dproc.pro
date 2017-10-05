
;+
;procedure:  crib_dproc.pro
;
;purpose: demonstrate basic data processing operations
;
;usage:
; .run crib_dproc
;
;
;Warning: this crib uses some data from the THEMIS branch.  You'll require those routines to run this crib
;
; $LastChangedBy: pcruce $
; $LastChangedDate: 2013-12-16 16:55:27 -0800 (Mon, 16 Dec 2013) $
; $LastChangedRevision: 13680 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/ssl_general/trunk/examples/crib_calc.pro $
;
;-


print, 'Test with GMAG'

;Load GMAG data from ccnv site:
timespan, '2007-03-23', 1
thm_load_gmag, site = 'ccnv'
var = tnames('thg_mag_ccnv')
var = var[0]
;plot for verification
tplot, var
stop

print,  'Test Subtract Average:'
;run the following IDL commands:
tsub_average, var, new_var, new_name = var+'-avg'
;For verification, plot should look as if average was subtacted
print, 'plot should look as if average was subtacted'
tplot, var+'-avg'
stop

print,  'Test Subtract Median:'
;run the following IDL commands:
tsub_average, var, new_var, new_name = var+'-med'
;For verification, plot should look as if median was subtacted
print, 'plot should look as if median was subtacted'
tplot, var+'-med'
stop

;Use the median-subtracted version from here on:
print, 'Use the median-subtracted version from here on:'
var = var+'-med'
print,  'Test Smooth Data:'
;run the following IDL commands:
smooth_res = 51                 ;choose smoothing resolution
tsmooth2, var, smooth_res, newname = var+'_smoothed'
print, 'For verification, data should look smoothed'
tplot, var+'_smoothed'
stop

print,  'Test Time Average:'
;run the following IDL commands:
time_res = 600                  ;choose averaging time, in seconds
avg_data, var, time_res, newname = var+'_tavg'
print, 'For verification, it should look like 10 minute averages'
tplot, var+'_tavg'
stop

print,  'Test Clip:'
amin = -10.0 & amax = +10.0 ;not physically realistic clips for testing
tclip, var, amin, amax, newname = var+'_clip'
print, 'For verification, data should look clipped'
ylim, var+'_clip', -20.0, 20.0, 0 ;to see clipping
tplot, var+'_clip'
stop

print,  'a. Test Deflag: Linear'
;Use clipped data from above:
tdeflag, var+'_clip', 'linear', newname = var+'_deflag_lin'
print, 'For verification, gaps should have lines across'
ylim, var+'_deflag_lin', -20.0, 20.0, 0 ;to see clipping
tplot, var+'_deflag_lin'
stop

print,  'b. Test Deflag: Repeat'
tdeflag, var+'_clip', 'repeat', newname = var+'_deflag_rep'
print, 'For verification,gaps should have lines across'
ylim, var+'_deflag_rep', -20.0, 20.0, 0 ;to see clipping
tplot, var+'_deflag_rep'
stop

print,  'Test Degap:'
;add a gap
get_data, var, data = d
ss = lindgen(n_elements(d.x))
gap_ss = 3100+lindgen(10000)
notgap_ss = sswhere_arr(ss, gap_ss, /notequal)
x = d.x[notgap_ss] & y = d.y[notgap_ss, *]
str_element, d, 'x', x, /add_replace
str_element, d, 'y', y, /add_replace
store_data, var+'-test', data = d
tplot, var+'-test'              ;will show gap, as a line
print, 'Note the line across the gap'
stop
;run the following commands:
dt = 1.0 & margin = 0.25 & maxgap = 10000
tdegap, var+'-test', dt = dt, margin = margin, $
  maxgap = maxgap, newname = var+'_degap'
print, 'For verification, the plot will have a gap, not a line across the gap'
tplot, var+'_degap'
;plot will have a gap, and not a line across the gap
stop

print,  'Test Clean Spikes:'
;Create a dataset with spikes:
get_data, var, data = d
d.y[1400, 0] = 1.0e5            ;should work
d.y[1600, 1] = -1.0e5
store_data, var+'-test', data = d
tplot, var+'-test'              ;will show spikes
print, 'Note the Spikes'
stop
;run the following command:
clean_spikes, var+'-test', new_name = var+'_despiked'
print, 'For verification, No spikes'
tplot, var+'_despiked'          ;no spikes
stop

print,  'Test Time Derivative:'
;run the following command:
deriv_data, var, newname = 'ddt_'+var
print, 'For verification, looks like a derivative'
tplot, 'ddt_'+var
stop

print,  'Test Wavelet Transform:'
;run the following command:
tplot, var
spd_ui_wavelet, var, new_var,  ['2007-03-23 06:00', '2007-03-23 9:00']
print, 'For verification, spectrograms of wavelet transforms'
tplot, new_var
stop

print,  'Test Dpwrspec:'
;run the following command:
tplot, var
thm_ui_pwrspc, var, var_new, /dynamic
print, 'For verification, spectrograms of power spectra'
tplot, var_new
stop

print,  'Test Rename:'
;run the following commands:
store_data, var, newname = var+'_renamed'
print, 'For verification, should look the same'
tplot, var+'_renamed'
stop

print,  'Test Save:'
;Oops, rename back:
store_data, var+'_renamed', newname = var
;run the following command:
tplot_save, var, filename = 'tha_mag_ccnv_test'
print, 'For verification, check to see if the file tha_mag_ccnv_test.tplot was written.'
stop

print,  'Test Restore:'
;Run the following commands: 
files = 'tha_fgl_test.tplot'
tplot_restore, filenames = files, /get_tvars, restored_varnames = var
Print, 'For verification, plot should look the same'
tplot, var
stop

print,  'Test Save_ascii:'
;run the following IDL command:
tplot_ascii, var
Print, 'Verify that the file has been created by looking for a file with the filename: thg_mag_ccnv.txt'

End


