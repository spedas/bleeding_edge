;+
; NAME: crib_tplot_timebar_databar
; 
; PURPOSE:  Crib to demonstrate tplot timebar and databar commands  
;           You can run this crib by typing:
;           IDL>.compile crib_tplot_timebar_databar
;           IDL>.go
;           
;           When you reach a stop, press
;           IDL>.c
;           to continue
;           
;           Or you can copy and paste commands directly onto the command line
;
; SEE ALSO: crib_tplot.pro  (basic tplot commands)
;           crib_tplot_layout.pro  (how to arrange plots within a window, and data within a plot)
;           crib_tplot_range.pro   (how to control the range and scaling of plots)
;           crib_tplot_export_print.pro (how to export images of plots into pngs and postscripts)
;           crib_tplot_annotation.pro  (how to control labels, titles, and colors of plots)
;
; NOTES:
;  1.  As a rule of thumb, "tplot_options" controls settings that are global to any tplot
;   "options" controls settings that are specific to a tplot variable
;   
;  2.  If you see any useful commands missing from these cribs, please let us know.
;   these cribs can help double as documentation for tplot.
;
; $LastChangedBy: jimm $
; $LastChangedDate: 2016-08-29 12:56:08 -0700 (Mon, 29 Aug 2016) $
; $LastChangedRevision: 21765 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/examples/crib_tplot_timebar_databar.pro $
;-

;Setup
;-------------------------------------------------

;this line deletes data so we start the crib fresh
store_data,'*',/delete

;first we set a time and load some data.
timespan,'2008-03-23'

;loading spectral data
st_swea_load, /all

;loading line plot data (stereo moments)
st_part_moments, probe='a', /get_mom

st_position_load, probe='a'

;set new color scheme (for aesthetics)
init_crib_colors

;make sure we're using window 0
tplot_options, window=0
window, 0, xsize=700, ysize=800

;increasing the xmargin so it is easier to see the labels
tplot_options, 'xmargin', [18,18] ;18 characters on left side, 12 on right
tplot_options, 'ymargin', [8,4]   ;8 characters on the bottom, 4 on the top

;-------------------------------------------------


;basic plot for comparision
tplot,['sta_SWEA_en','sta_SWEA_mom_flux']


print,'  This first plot is the default, for reference. '
print,'Type ".c" to continue crib examples.'
stop

; Time and databars can be added directly to plots using the timebar
; routine, as shown in the first two examples:
; timebar, 0.0, /databar, varname='sta_SWEA_mom_flux', linestyle=2
; adds a dashed line at zero, using the timebar routine with the
; /databar keyword

print,'Add a horizontal bar to mark data with the "timebar" routine and '
print, 'keyword /databar, for the flux variable'

timebar, 0.0, /databar, varname='sta_SWEA_mom_flux', linestyle=2

print,'Type ".c" to continue'
stop

; The second example adds a colored line at midday, using timebar
print,'Add a vertical bar to mark data with the "timebar" routine'

timebar, '2008-03-23/12:00', varname='sta_SWEA_mom_flux', color = 6

print,'Type ".c" to continue'
stop

; Note that the time and databars are not persistent, and will
; disappear on successive tplot calls, in order to have persistence,
; you have the options to set up these timebars and databars in the
; limits or dilimts structures for different variables using the
; options command, then call tplot_apply_timebar, tplot_apply_databar
; to plot:

print, 'NEW!!!: Use options to add time and databars, and tplot_apply_timebar, '
print, 'tplot_apply_databar to plot. This is especially useful for updating plots '
print, 'if multiple variables need the time and/or databars'

; The first example sets up two timebars for two variables, and plots
print, 'First, two timebars for both variables'

options, ['sta_SWEA_en','sta_SWEA_mom_flux'], 'timebar', $
         ['2008-03-23/12:00', '2008-03-23/18:00']
tplot
tplot_apply_timebar

print,'Type ".c" to continue'
stop

; This next example sets up the two time bars with color, linestyle
; and thicknesses set. The input to the options command is a structure
; that sets up the parameters. The color, linestyle and thickness
; options can be arrays (one for each timebar value) or scalars. Here
; the lines are the same for both timebars. The input structure, if
; used, has the tags {TIME, COLOR, LINESTYLE, THICK}, only the TIME tag
; is required.

print, 'Two timebars for both variables, with color, linestyle and thick set. '
print, 'Note that the input to options is a structure, this is necessary '
print, 'for setting color, linestyle and thick'

options, ['sta_SWEA_en','sta_SWEA_mom_flux'], 'timebar', $
         {time: ['2008-03-23/12:00', '2008-03-23/18:00'], $
          color: 2, linestyle: 2, thick:2.0}
tplot
tplot_apply_timebar

print,'Type ".c" to continue'
stop

; Next set up databars. The databar options are set up the same way as
; the timebar options. This example sets up datbars for two variables
; separately.
print, 'Use options and tplot_apply_databar to  set up horizontal lines'

options, 'sta_SWEA_en', 'databar', {yval:100, color:0, thick:2.0}
options, 'sta_SWEA_mom_flux','databar', 0.0
tplot_apply_databar

print,'Type ".c" to continue'
stop

; Everything resets on a tplot (or tlimit) call
tplot
print, 'Reset, using tplot:'
print,'Type ".c" to continue'
stop

; But the time and databars that have been set up are still there, and
; you can call tplot_apply_timebar/databar to get them back
tplot_apply_timebar
tplot_apply_databar

print, 'Reapply time and databars:'
print,'Type ".c" to continue'
stop

;To clear out the time and databar values, use the /clear keyword in
;tplot_apply_timebar/databar

tplot_apply_timebar, /clear
tplot_apply_databar, /clear
tplot

print, 'The options persist, to clear, use tplot_apply_timebar, or '
print, 'tplot_apply_databar, /clear (Use the varnames keyword for '
print, 'individual variables), and call tplot'
print,'Type ".c" to continue'
stop

;Look at some THEMIS data now, we will apply thick red zero lines for
;THEMIS EFS and FGS data, Note that globbing will work, so that you
;can apply the same time and databars to multiple variables. The input
;structure for databars, if used, has the tags {YVAL, COLOR, LINESTYLE, THICK},
;only the YVAL tag is required.

print, "THEMIS EXAMPLE, set up zero lines for EFS, FGS data"

del_data, '*'
timespan, '2016-08-01'
thm_load_fit, probe='a'

tplot, 'tha_??s'

options, 'tha_??s', 'databar', {yval:0.0, color:6, thick:2}
tplot_apply_databar

print,'Type ".c" to continue'
stop

;A tlimit call will reset the plot without the databars, so after
;tlimit, call tplot_apply_databar to show them
print, 'Use tlimit to reset the time range, then reapply databars'

tlimit
tplot_apply_databar

print,'Type ".c" to continue'
stop

;The next example sets up multiple values for FGS data, with different
;colors, but the same thicknesses
print, 'Set up multiple databars for FGS data'
options, 'tha_fgs', 'databar', {yval:[-10, 0, 10], color:[2,4,6], thick:2}

tplot_apply_databar

print,'Type ".c" to continue'
stop


;In the next plot, the red bar for EFS data, is deleted. This requres
;a clear command to be sent to tplot_apply_databar, a tplot, to replot
;without databars, and another tplot_apply_databar to replot the
;remaining databars.
print, 'Drop the zero line for tha_efs, and update'

tplot_apply_databar, varname = 'tha_efs', /clear
tplot
tplot_apply_databar

stop
print,"We're done!"


end
