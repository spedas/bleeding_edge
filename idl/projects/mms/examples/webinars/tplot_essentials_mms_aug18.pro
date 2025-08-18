; Tplot Essentials
;     Eric Grimes, egrimes@igpp.ucla.edu
;
; -----> Phone to use: 510-643-3817
;
; Please be sure to mute your phone! This crib sheet can be found in SPEDAS at:
;   projects/mms/examples/webinars/tplot_essentials_mms_aug18.pro
;
;Tentative agenda:
; 1) Basics
; 2) Tplot options
; 3) Tplot tools
; 4) Export data
; 5) Saving figures

;-------------------------------------------------
; Basics
;-------------------------------------------------

mms_load_fgm, probe=1, trange=['2017-07-11/22:33:30', '2017-07-11/22:34:30'], data_rate='brst', /time_clip
mms_load_fpi, probe=1, datatype=['dis-moms', 'des-moms'], trange=['2017-07-11/22:33:30', '2017-07-11/22:34:30'], data_rate='brst', /time_clip
mms_load_mec, probe=1, data_rate='brst', /time_clip, trange=['2017-07-11/22:33:30', '2017-07-11/22:34:30']

; create a simple plot
tplot, 'mms1_fgm_b_gsm_brst_l2_bvec'
stop

; list the names and variable #s of the currently loaded data
tplot_names
stop

; limit the variables in the list to those that match FGM b-field data
; note: supports both * (multi-character matches) and ? (single character matches)
tplot_names, '*_fgm_b_*'
stop

; you can also refer to the tplot #s instead of the full names
tplot, [12, 14, 16]
stop

; another way to get the list of tplot variable names is the function tnames
tn = tnames()
print, tn
stop

; tnames also supports wild cards * and ?
tn = tnames('*_fgm_b_*')
print, tn
stop

; the /add keyword adds the variable to the current figure
tplot, 'mms1_dis_energyspectr_omni_brst', /add
stop

; extract data and metadata from a variable using get_data
; data/metadata are returned in IDL structures
; note: d.X are the times, d.Y are the data, d.V are the energies
; note: dlimits contains the metadata set by the load routine when loading the data, limits contains the metadata set by 'options'
get_data, 'mms1_dis_energyspectr_omni_brst', data=d, dlimits=dl, limits=l
help, d
stop

get_data, 'mms1_fgm_b_gsm_brst_l2_bvec', data=d, dlimits=dl, limits=l
help, d
stop

help, dl
stop

help, dl.cdf.vatt
stop

; create new variables using store_data
store_data, 'new_fgm_var', data={x: d.X, y: d.Y}, dlimits=dl, limits=l
stop

; you can add error bars to tplot variables with the 'dy' tag in the data structure
get_data, 'mms1_dis_numberdensity_brst', data=density, dlimits=dl, limits=l
get_data, 'mms1_dis_numberdensity_err_brst', data=error
stop

store_data, 'dis_numberdensity_with_error', data={x: density.X, y: density.y, dy: error.y}, dlimits=dl, limits=l
tplot, 'dis_numberdensity_with_error', trange=['2017-07-11/22:34:00', '2017-07-11/22:34:10']
stop

; you can copy data to another tplot variable with copy_data
copy_data, 'new_fgm_var', 'mms1_fgm_b_gsm_brst_l2_bvec_new'
stop

; you can delete tplot variables with del_data
del_data, 'new_fgm_var'
stop

; average data in a tplot variable with avg_data
avg_data, 'mms1_fgm_b_gsm_brst_l2_bvec_new', 1.0, newname='mms1_fgm_b_gsm_brst_l2_bvec_new'
tplot
stop

; split tplot vectors using split_vec
split_vec, 'mms1_fgm_b_gsm_brst_l2_bvec_new'
tplot, 'mms1_fgm_b_gsm_brst_l2_bvec_new_'+['x', 'y', 'z']
stop

; join tplot components back into a tplot vector with join_vec
join_vec, 'mms1_fgm_b_gsm_brst_l2_bvec_new_'+['x', 'y', 'z'], 'mms1_fgm_b_gsm'
tplot, ['mms1_fgm_b_gsm', 'mms1_fgm_b_gsm_brst_l2_bvec_new_'+['x', 'y', 'z']]
stop

;-------------------------------------------------
; Tplot options
;-------------------------------------------------

tplot, ['mms1_fgm_b_gsm', 'mms1_dis_energyspectr_omni_brst']
stop

; turn off the time stamp in the bottom right
time_stamp, /off
tplot
stop

; note: tplot_options sets the options for all tplot variables in the current session
tplot_options, 'xmargin', [30, 30]
tplot
stop

; the options command supports all options the PLOT procedure supports
options, ['mms1_fgm_b_gsm', 'mms1_dis_energyspectr_omni_brst'], 'charsize', 1.5
tplot
stop

; add titles to the panels
options, 'mms1_fgm_b_gsm', 'title', 'FGM'
options, 'mms1_dis_energyspectr_omni_brst', 'title', 'DIS'
tplot
stop

; add a gap between the panels so the DIS title shows up
tplot_options, 'ygap', 3.0
tplot
stop

; add a ymargin so the FGM title fits
tplot_options, 'ymargin', [5, 5]
tplot
stop

; change the plot label version (x-axis)
tplot_options, version=1
tplot
stop

tplot_options, version=2
tplot
stop

; show the current global tplot options
tplot_options, /help
stop

; make the FGM variable dashed
options, 'mms1_fgm_b_gsm', 'linestyle', 5
tplot
stop

; remove the minor axis ticks from the FGM panel
options, 'mms1_fgm_b_gsm', 'yminor', 1
tplot
stop

; manually update the labels on the FGM variable
options, 'mms1_fgm_b_gsm', labels=['Bx', 'By', 'Bz']
tplot
stop

; update the FGM labels so that Bx is first in the list
options, 'mms1_fgm_b_gsm', labflag=-1
tplot
stop

; update the y-axis title with 'ytitle'
options, 'mms1_dis_energyspectr_omni_brst', 'ytitle', 'MMS1!CDIS!CEnergy Spectra'
tplot
stop

; and the colorbar title with 'ztitle'
; note the !U2!N to make the superscript 2 in the cm units
options, 'mms1_dis_energyspectr_omni_brst', ztitle='keV/(cm!U2!N s sr keV)'
tplot
stop

; you can change the colorbar with the 'color_table' attribute
options, 'mms1_dis_energyspectr_omni_brst', 'color_table', 74
tplot
stop

; you can reverse the colorbar using reverse_color_table
options, 'mms1_dis_energyspectr_omni_brst', 'reverse_color_table', 1
tplot
stop

; change the y-axis range shown with 'ylim'
; note: the last argument is 0 for linear scale, 1 for log scale
ylim, 'mms1_dis_energyspectr_omni_brst', 1000, 30000, 1
tplot
stop

; you can use zlim to change from log scale to linear scale
; by leaving the x/y range arguments as 0
zlim, 'mms1_dis_energyspectr_omni_brst', 0, 0, 0
tplot
stop

; change back to log scale
zlim, 'mms1_dis_energyspectr_omni_brst', 0, 0, 1
tplot
stop

; tplot also supports the ? wild cards
tplot, 'mms1_des_energyspectr_????_brst'
tplot, 'mms1_des_energyspectr_???_brst', /add
stop

;-------------------------------------------------
; Tplot tools
;-------------------------------------------------

; create a line plot at a specific time using flatten_spectra
flatten_spectra, /ylog, /xlog
stop

flatten_spectra, samples=10, /ylog, /xlog, xrange=[1e2, 1e5]
stop

; use tlimit to zoom into a tplot figure using your mouse
tplot, ['mms1_fgm_b_gsm', 'mms1_dis_energyspectr_omni_brst']
tlimit
stop

tlimit, ['2017-07-11/22:34:00', '2017-07-11/22:34:08']
stop

; reset to the full time range with /full
tlimit, /full
stop

; add a vertical line 
timebar, '2017-07-11/22:34:03'
timebar, '2017-07-11/22:34:06'
stop

; add a horizontal line 
timebar, 0.0, /databar, varname='mms1_fgm_b_gsm', linestyle=3
stop

; interpolate the energy spectra to match the FGM timestamps
tinterpol, 'mms1_dis_energyspectr_omni_brst', 'mms1_fgm_b_gsm'
stop

; find if data exists in a tplot variable
print, spd_data_exists('mms1_dis_energyspectr_omni_brst_interp', '2017-07-11/22:34:00', '2017-07-11/22:34:08')
stop

tsmooth2, 'mms1_fgm_b_gsm', 6
tplot, ['mms1_fgm_b_gsm_sm', 'mms1_dis_energyspectr_omni_brst']
stop

average_density = spd_tplot_average('mms1_dis_numberdensity_brst', ['2017-07-11/22:33:30', '2017-07-11/22:34:30'])
print, average_density
stop

tsub_average, 'mms1_dis_numberdensity_brst', /median
stop

; use calc to do calculations on tplot variables without having to extract the IDL structures
; see: general/examples/crib_calc.pro for more
calc, '"mms1_mec_r_sm_re" = "mms1_mec_r_sm"/6371.2'
tplot, ['mms1_fgm_b_gsm', 'mms1_dis_energyspectr_omni_brst'], var_label='mms1_mec_r_sm_re'
stop

options, 'mms1_mec_r_sm_re', 'ytitle','R (Re)'
tplot
stop

;-------------------------------------------------
; Tplot export
;-------------------------------------------------

; send the data to the SPEDAS GUI
tplot_gui, ['mms1_fgm_b_gsm', 'mms1_dis_energyspectr_omni_brst']
stop

; save tplot variables to a SAV file
tplot_save, ['mms1_fgm_b_gsm', 'mms1_dis_energyspectr_omni_brst'], filename = 'mms_data'
stop

del_data, '*'
stop

; restore tplot variables from a SAV file
tplot_restore, filenames = 'mms_data.tplot'
stop

; save tplot variables to ASCII files
tplot_ascii, ['mms1_fgm_b_gsm', 'mms1_dis_energyspectr_omni_brst']
stop

; use trange keyword to limit the output to a specific time range
tplot_ascii, trange=['2017-07-11/22:33:30', '2017-07-11/22:34:30'], ['mms1_fgm_b_gsm', 'mms1_dis_energyspectr_omni_brst']
stop

; save tplot variables to a CDF file
tplot2cdf, /default, filename='mms_data', tvars=['mms1_fgm_b_gsm', 'mms1_dis_energyspectr_omni_brst']
stop

; send tplot variables to Autoplot
tplot2ap, ['mms1_fgm_b_gsm', 'mms1_dis_energyspectr_omni_brst']
stop

;-------------------------------------------------
; Tplot image files
;-------------------------------------------------

makepng, 'mms_data' ; saves mms_data.png
makegif, 'mms_data' ; saves mms_data.gif
makejpg, 'mms_data' ; saves mms_data.jpg
stop

; tprint saves postscript files
tprint, 'mms_data', /landscape

stop
end