;+
; NAME: crib_tplot_window
; 
; PURPOSE:  Crib to demonstrate tplot layout commands, using
;           tplot_window instead of tplot
;           You can run this crib by typing:
;           IDL>.compile crib_tplot_window
;           IDL>.go
;           
;           When you reach a stop, press
;           IDL>.c
;           to continue
;           
;           Or you can copy and paste commands directly onto the command line
;
; SEE ALSO: crib_tplot_window.pro  (basic tplot commands)
;           crib_tplot_range.pro   (how to control the range and scaling of plots)
;           crib_tplot_annotation.pro  (how to control labels, titles, and colors of plots)
;           crib_tplot_export_print.pro (how to export images of plots into pngs and postscripts)
;           crib_tplot_overlay.pro(how to overlay spectral plots)
;
; NOTES:
;   If you see any useful commands missing from these cribs, please let us know.
;   these cribs can help double as documentation for tplot.
;
; $LastChangedBy: jimm $
; $LastChangedDate: 2016-10-21 11:06:02 -0700 (Fri, 21 Oct 2016) $
; $LastChangedRevision: 22186 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/examples/crib_tplot_window.pro $
;-

;this line deletes data so we start the crib fresh
store_data,'*',/delete

;first we set a time and load some data.
timespan,'2008-03-23'

;loading spectral data
st_swea_load, /all

;loading line plot data (stereo moments)
st_part_moments, probe='a', /get_mom

;set new color scheme (for aesthetics)
init_crib_colors

;To plot multiple quantities in separate panels, use an array with the names

tplot_window,['sta_SWEA_mom_flux','sta_SWEA_en']

print," Used 'tplot_window,name' for plotting data."
print," Try out some keyboard commands, first click on the window, then: "
print,"      'z' for zoom in by 50%; "
print,"      'o' for zoom out by200%; "
print,"      'r' for reset to initial time range; "
print,"      't' for interactive tlimit, which allows you to set the plotted"
print,"          time range by clicking same as in a regular window;"
print,"      'b' for shift back by 25%;"
print,"      'f' for shift forward by 25%;"
print,"      'c' centers the plot on the cursor, without zooming"
print," Arrow keys work too, up zooms in, down zooms out, left shifts back,"
print," right shifts forwards."
print," Resize the window by dragging the corner of the window."
print," Note that the window does not respond, if the cursor is off the window"

print,'Type ".c" to continue'
stop 

tplot_window, 'sta_SWEA_mom_flux'
tplot_window, 'sta_SWEA_en'

print,"Plot multiple quantities in separate windows, TPLOT_WINDOW always "
print,"creates a new window. Note that the keyboard commands only work on "
print,"the most recent window (in this case window 34). "
print,'Type ".c" to continue'
stop 

tplot_options, 'window', 32

print,"Call tplot_options, 'window', 32 to reset to the original window. "
print,"Note that the original window has no 'memory' of the original "
print,"variables that you plotted. Therefore, when you now operate on "
print,"the current window (now window 32), only one variable, 'sta_SWEA_en' "
print,"is plotted. This is consistent with TPLOT behavior."
print,"You can kill the other two widgets by clicking on the 'X' in the "
print,"upper right hand corner"
print,'Type ".c" to continue'
stop

tplot, 'sta_SWEA_mom_flux', /add

print, "Execpt with the window command, all of the regular tplot commands "
print, "are acceptable; add the variable 'sta_SWEA_mom_flux' using tplot, /add:"
print,'Type ".c" to continue'
stop


print, "Execpt with the window command, all of the regular tplot commands "
print, "are acceptable, try tlimit:"

tlimit

print,'Type ".c" to continue'
stop


print, "Execpt with the window command, all of the regular tplot commands "
print, "are acceptable, try ctime:"

ctime, time, y, z
print, 'time:' , time_string(time)
print, 'y, z: ', y, z

print,'Type ".c" to continue'
stop
 
print,'Crib Done!'
 
end
