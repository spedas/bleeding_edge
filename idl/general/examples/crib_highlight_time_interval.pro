;+
; NAME: crib_fill_time_intv
; 
; PURPOSE:  Crib to demonstrate thte fill_time_intv option for tplot
;           You can run this crib by typing:
;           IDL>.compile crib_fill_time_intv
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
; $LastChangedDate: 2019-11-15 11:21:00 -0800 (Fri, 15 Nov 2019) $
; $LastChangedRevision: 28024 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/examples/crib_highlight_time_interval.pro $
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

;To create an interval with a different background color for a given
;time range, use the HIGHLIGHT_TIME_INTERVAL command
;Highlight_time_interval allows clicking on the interval, and input
;via the time_interval keyword
print, 'highlight a time interval by clicking, twice, to establish time interval'
print, 'color = 2, is blue'
highlight_time_interval, 'sta_SWEA_mom_flux', color = 2

tplot
print,'Type ".c" to continue'
stop

;Use the time_interval keyword:
print,'Highlight interval, using the time_interval keyword'
highlight_time_interval, 'sta_SWEA_mom_flux', time_interval = ['2008-03-23/02:00','2008-03-23/04:00'], color = 2

tplot
print,'Type ".c" to continue'
stop


;Multiple time intervals can be input, by setting the n_intervals keyword
;multiple colors are optional:
print,'Add different intervals with different colors, using highlight_time_interval, for the flux variable'
print,'Set n_intervals to 3 and click twice, 3 times, to create the three intervals.'
print, 'Set color = ''rgb'' for color input for the 3 different intervals.'
c1 = 'rgb' ;you can use string color values in addition to absolute numbers 

highlight_time_interval, 'sta_SWEA_mom_flux', n_intervals = 3, color = c1

tplot
print,'Type ".c" to continue'
stop

;Multiple time intervals can be marked, using a 2Xntimes array input,
print,'Set 3 intervals using time_Interval keyword' 
t1 = '2008-03-23/'+[['02:00','04:00'],['07:00','09:00'],['16:24','22:00']]
c1 = 'rgb' ;you can use string color valuse in addition to absolute numbers 

highlight_time_interval, 'sta_SWEA_mom_flux', time = t1, color = c1

tplot
print,'Type ".c" to continue'
stop


;Some other highlight_time_interval for the 'polyfill' routine can be used, including
;line_fill (parallel lines instead of solid colors), linestyle, thick,
;and orientation for the line_fill highlight_time_interval. Here set the
;line_fill, and orientation for the energy spectrum. 
print, 'The POLYFILL solid color option does not work well for the energy '
print, 'spectrum, set {line_fill = 1,orientation = 45} to use angled '
print, 'parallel lines and not solid colors; times are set via keyword.'
;2Xn_times intervals

c1 = 'rgb' ;you can use string color values in addition to absolute numbers 
t1 = '2008-03-23/'+[['02:00','04:00'],['07:00','09:00'],['16:24','22:00']]
highlight_time_interval, 'sta_SWEA_en', $
         time_interval = t1, color = c1, line_fill = 1, orientation = 45.0

tplot
print,'Type ".c" to continue'
stop

; You can also pass in for different polyfill options for different
; intervals. Here set three intervals on the
; flux variable, three different line orientations, all
; slightly overlapped
print, 'You can also pass in an array of polyfill options, for different'
print, 'time intervals. Here set three intervals for the'
print, 'flux variable, three different line orientations, all slightly overlapped'

t2 = '2008-03-23/'+[['02:00','06:00'],['05:00','09:00'],['8:24','12:00']]
c2 = [6, 2, 2]
l2 = 1 ;lines for all intervals
o2 = [0.0, 45.0, 135.0] ;3 different orientations
highlight_time_interval, 'sta_SWEA_mom_flux', time_interval = t2, color = c2, $
                         line_fill = l2, orientation = o2

tplot
print,'Type ".c" to continue'
stop

print, 'Set line_fill = 0 for the solid color, only here; this is not a POLYFILL default.'
print, 'So now there is a solid color for the first interval'
l2 = [0, 1, 1]
highlight_time_interval, 'sta_SWEA_mom_flux', time_interval = t2, $
                         color = c2, line_fill = l2, orientation = o2

tplot
print,'Type ".c" to continue'
stop

print, 'Cross-hatch? use the same time interval, with different orientations, '
print, '[45, 135] for the energy spectrum.'
t3 = '2008-03-23/'+[['02:00','06:00'],['02:00','06:00']]
c3 = [3, 3]

highlight_time_interval, 'sta_SWEA_en', time_interval = t3, color = c3, $
                         line_fill = 1, orientation = [45.0, 135.0]

tplot
print,'Type ".c" to continue'
stop

;For some reason, there is no "delete" keyword in highlight_time_interval.pro, so to
;delete an option, pass in an undefine variable (no kidding)
print, 'Delete the highlight_time_intervals, setting /delete'

highlight_time_interval, 'sta_SWEA_en', /delete
highlight_time_interval, 'sta_SWEA_mom_flux', /delete
tplot

print, 'The polyfill options ''linestyle'' and ''thick'' can also be used, so '
print, 'try them out. '

print, 'Done.'

end
