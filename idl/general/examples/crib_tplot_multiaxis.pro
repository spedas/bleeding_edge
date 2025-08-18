;+
; NAME: crib_tplot_multiaxis
; 
; PURPOSE:  Demonstrate how to create plots with two y axes.

;           You can run this crib by typing:
;           IDL>.compile crib_tplot_multiaxis
;           IDL>.go
;           
;           When you reach a stop, press
;           IDL>.c
;           to continue
;           
;           Or you can copy and paste commands directly onto the command line
;
; SEE ALSO: crib_tplot.pro             (basic tplot commands)
;           crib_tplot_range.pro       (how to control the range and scaling of plots)
;           crib_tplot_layout.pro      (how to arrange plots within a window, and data within a plot)
;           crib_tplot_annotation.pro  (how to control labels, titles, and colors of plots)
;           crib_tplot_overlay.pro     (how to overlay spectral plots)
;
; NOTES:
;   If you see any useful commands missing from these cribs, please let us know.
;   these cribs can help double as documentation for tplot.
;
;
;
;$LastChangedBy: aaflores $
;$LastChangedDate: 2016-05-25 16:37:13 -0700 (Wed, 25 May 2016) $
;$LastChangedRevision: 21212 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/examples/crib_tplot_multiaxis.pro $
;-


;============================================
; Setup
;============================================

;clear tplot variables
store_data,'*',/delete

;first we set a time and load some data.
timespan,'2008-03-23'

;loading spectral data
st_swea_load, /all

;loading line plot data (stereo moments)
st_part_moments, probe='a', /get_mom

;set new color scheme (for aesthetics)
init_crib_colors


;============================================
; Single plot
;============================================

;set plot colors and lavels for easy viewing
options, 'sta_SWEA_mom_avgtemp', colors='b'

;the first argument's y axis is placed on the left
;the second's is placed on the right
tplot_multiaxis, 'sta_SWEA_mom_density', 'sta_SWEA_mom_avgtemp'

print, 'Plot two variables on a single plot with separate y axes'

stop


;============================================
; Mulitple plots
;============================================

options, 'sta_SWEA_mom_avgtemp', colors='b'
options, 'sta_SWEA_mom_t3', colors=['c','y','m']

;the first arguments' y axes are placed on the left
;each list may be an array or a space separated list
tplot_multiaxis, ['sta_SWEA_mom_density','sta_SWEA_mom_vthermal'], $
                 'sta_SWEA_mom_avgtemp  sta_SWEA_mom_t3'

print, 'Create multiple plots with two y axes'

stop


;============================================
; Specify positions
;============================================

options, 'sta_SWEA_mom_avgtemp', colors='b'
options, 'sta_SWEA_mom_velocity', colors=['b','g','r']

;A third argument can be used to specify which plot the corresponding
;entry from the right-aligned list will be added to.
tplot_multiaxis, ['sta_SWEA_mom_velocity','sta_SWEA_mom_density','sta_SWEA_en'], $
                 ['sta_SWEA_mom_avgtemp','sta_SWEA_mom_vthermal'], [2,1]

print, 'Specify a subset of plots to have two y axes'

stop


print, 'Done!'

end