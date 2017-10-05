;+
; NAME: crib_tplot_export_print
; 
; PURPOSE:  Crib to demonstrate tplot export commands
;           You can run this crib by typing:
;           IDL>.compile crib_tplot_export
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
;           crib_tplot_annotation.pro  (how to control labels, titles, and colors of plots)
;
; NOTES:
;   If you see any useful commands missing from these cribs, please let us know.
;   these cribs can help double as documentation for tplot.
;
; $LastChangedBy: pcruce $
; $LastChangedDate: 2013-12-16 14:43:09 -0800 (Mon, 16 Dec 2013) $
; $LastChangedRevision: 13679 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/examples/crib_tplot_export_print.pro $
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

;increasing the xmargin so it is easier to see the labels
tplot_options,'xmargin',[15,15] ;15 characters on each side

;use this command to get the current directory
cd,current=c

;Image export options.

;Export to PNG

tplot,['sta_SWEA_mom_flux','sta_SWEA_en']

;makepng will export your most recent plot to a png file
makepng,'example'  ;extension appended automatically

print,'  Just exported "example.png" to : ' + c
print,'Type ".c" to continue crib examples.'
stop

;Export to GIF

tplot,['sta_SWEA_mom_flux','sta_SWEA_en']

;makegif will export your most recent plot to a png file
makegif,'example' ;extension appended automatically

print,'  Just exported "example.gif" to : ' + c
print,'Type ".c" to continue crib examples.'
stop

;Export to JPG

tplot,['sta_SWEA_mom_flux','sta_SWEA_en']

;makegif will export your most recent plot to a png file
makejpg,'example' ;extension appended automatically

print,'  Just exported "example.jpg" to : ' + c
print,'Type ".c" to continue crib examples.'
stop


;Export to Postscript(PS)

;First create your plot
tplot,['sta_SWEA_mom_flux','sta_SWEA_en']

;Next open a postscript with popen
popen,'example'  ;note /land option will output in landscape mode
tplot; use tplot with no arguments to redraw your plot to the postscript file
pclose ; close the postscript

print,'  Just exported "example.ps" to : ' + c
print,'Type ".c" to continue crib examples.'
stop

;Export to Encapsulated Postscript(EPS)

;First create your plot
tplot,['sta_SWEA_mom_flux','sta_SWEA_en']

;Next open a postscript with popen,/encapsulated
popen,'example',/encapsulated  ;note /land option will output in landscape mode
tplot; use tplot with no arguments to redraw your plot to the postscript file
pclose ; close the postscript

print,'  Just exported "example.eps" to : ' + c
print,'Type ".c" to continue crib examples.'
stop

;Data export options

;Export to ASCII

tplot_ascii,'sta_SWEA_mom_flux'

print,'  Just exported "sta_SWEA_mom_flux" to "sta_SWEA_mom_flux.txt" in directory : ' + c
print,'Type ".c" to continue crib examples.'
stop

;Export Line to IDL array

get_data,'sta_SWEA_mom_flux',data=d

times = d.x
data = d.y
data_x = d.y[*,0]
data_y = d.y[*,1]
data_z = d.y[*,2]

print,'  Just exported "sta_SWEA_mom_flux" to IDL arrays'
print,'Type ".c" to continue crib examples.'
stop

;Export Spectra to IDL array

get_data,'sta_SWEA_en',data=d

times = d.x ;x-position(sample time) of each point in plane
zdata = d.y ;height at each point in plane
ydata = d.v ;y-position(energy in this case) of each point in the plane.  If this component is 2-d then there is a different set of y-positions at each point in time.  Otherwise, y-scaling is constant across time.

print,' Just exported "sta_SWEA_en" to IDL arrays'
print,'Crib is done!


end
