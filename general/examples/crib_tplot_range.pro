;+
; NAME: crib_tplot_range
; 
; PURPOSE:  Crib to demonstrate tplot range commands  
;           You can run this crib by typing:
;           IDL>.compile crib_tplot_range
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
;           crib_tplot_annotation.pro  (how to control labels, titles, and colors of plots)
;           crib_tplot_export_print.pro (how to export images of plots into pngs and postscripts)
;
; NOTES:
;   If you see any useful commands missing from these cribs, please let us know.
;   these cribs can help double as documentation for tplot.
;
;
; $LastChangedBy: pcruce $
; $LastChangedDate: 2013-12-16 14:43:09 -0800 (Mon, 16 Dec 2013) $
; $LastChangedRevision: 13679 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/examples/crib_tplot_range.pro $
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

;you can control x-range using the tlimit routine
;This will set the x-range for all plots
tplot,'sta_SWEA_mom_flux'
tlimit,'2008-03-23/04:00:00','2008-03-23/16:00:00'

print,'Set x-range using tlimit'
print,'Type ".c" to continue'
stop

;you can reset x-range to the current timespan using the /full argument
tplot
tlimit,/full
print,'Set x-range using "tlimit,/full"'
print,'Type ".c" to continue'
stop

;you can set the yrange using the options routine
options,'sta_SWEA_mom_flux',yrange=[-1e8,5e7] ; Control yrange of a plot using "options"
tplot,'sta_SWEA_mom_flux'

print,'Control yrange of a plot using "options"'
print,'Type ".c" to continue'
stop

;reset the yrange by setting the min equal to the max
options,'sta_SWEA_mom_flux',yrange=[0,0]
tplot,'sta_SWEA_mom_flux'
print,'Reset yrange of a plot using "options"'
print,'Type ".c" to continue'
stop

;Control the yrange of multiple panels
options,'sta_SWEA_mom_flux',yrange=[-1e8,5e7]
options,'sta_SWEA_en',yrange=[10,2e3] 

tplot,['sta_SWEA_en','sta_SWEA_mom_flux']

print,'Control the yrange of multiple panels'
print,'Type ".c" to continue'
stop

;Turn logarithmic scaling on / off
options,'sta_SWEA_mom_t3',ylog=1,yrange=[10,100]  ;also reset range here so the plot centers better
options,'sta_SWEA_en',ylog=0
tplot,['sta_SWEA_en','sta_SWEA_mom_flux']

print,'Turn logarithmic scaling on / off'
print,'Type ".c" to continue'
stop

;You can control the z-axis using options as well
options,'sta_SWEA_en',zrange=[10,1e4],zlog=0
tplot,'sta_SWEA_en'

print,'Control range/scaling of z-axis'
print,'Type ".c" to continue'
stop

print,'Crib done, resetting limits'

store_data,'sta_SWEA_en',limits=0
store_data,'sta_SWEA_mom_flux',limits=0

end
