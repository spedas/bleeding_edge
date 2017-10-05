;+
; NAME: crib_tplot_layout
; 
; PURPOSE:  Crib to demonstrate tplot layout commands  
;           You can run this crib by typing:
;           IDL>.compile crib_tplot_layout
;           IDL>.go
;           
;           When you reach a stop, press
;           IDL>.c
;           to continue
;           
;           Or you can copy and paste commands directly onto the command line
;
; SEE ALSO: crib_tplot.pro  (basic tplot commands)
;           crib_tplot_range.pro   (how to control the range and scaling of plots)
;           crib_tplot_annotation.pro  (how to control labels, titles, and colors of plots)
;           crib_tplot_export_print.pro (how to export images of plots into pngs and postscripts)
;           crib_tplot_overlay.pro(how to overlay spectral plots)
;
; NOTES:
;   If you see any useful commands missing from these cribs, please let us know.
;   these cribs can help double as documentation for tplot.
;
; $LastChangedBy: pcruce $
; $LastChangedDate: 2013-12-16 14:43:09 -0800 (Mon, 16 Dec 2013) $
; $LastChangedRevision: 13679 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/examples/crib_tplot_layout.pro $
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

tplot,['sta_SWEA_mom_flux','sta_SWEA_en']

print,'Plot multiple quantities in separate panels using an array'
print,'Type ".c" to continue'
stop 

;to plot multiple quantities in separate windows use the "window" keyword

window,0
window,1

tplot,'sta_SWEA_mom_flux',window=1
tplot,'sta_SWEA_en',window=0

print,'Plot multiple quantities in separate windows using the "window" keyword'
print,'Type ".c" to continue'
stop

;to plot multiple quantities in the same plot use a pseudo-variable

;Use store_data to create a pseudo_variable
store_data,'t_pseudo_var',data=['sta_SWEA_mom_t3','sta_SWEA_mom_avgtemp']

;change colors, so we can tell them apart
options,'sta_SWEA_mom_t3',colors=['c','m','y']

;Plot it
tplot,'t_pseudo_var'
;zoom in so that you can see the two quantities
tlimit,'2008-03-23/11:00:00','2008-03-23/15:00:00' 

print,'Plot multiple quantities in the same plot using a pseudo-variable, created with "store_data"'
print,'Type ".c" to continue'
stop

;You can put pseudo-variables in multiple panels

;change colors, so we can tell them apart
options,'sta_SWEA_mom_eflux',colors=['c','m','y']

store_data,'flux_pvar',data=['sta_SWEA_mom_flux','sta_SWEA_mom_eflux']

tplot,['t_pseudo_var','flux_pvar']

print,'Plot multiple pseudo variables in separate panels'
print,'Type ".c" to continue'
stop

;Use tplot with no arguments to replot the last plot you plotted with tplot

tplot

print,'Use tplot with no arguments to replot the last plot you plotted with tplot'
print,'Type ".c" to continue'
stop

;To control the range on a pseudo variable, set the range on it
;not its component data
options,'t_pseudo_var',yrange=[18,38]
options,'flux_pvar',yrange=[1e9,-1e9]

tplot

print,'Control the yrange of pseudo variable, using options on pseudo-var'

stop


;Use the 'xmargin' option to control the size of the left/right plot margin
;Margin size units measured in characters

tplot_options,'xmargin',[20,40] ;This command sets a left margin of 20 characters and a right margin of 40 characters
tplot

print,"Use the 'xmargin' option to control the size of the left/right plot margin"
print,'Type ".c" to continue'
stop

;Use the 'ymargin' option to control the size of the bottom/top plot margin
;Margin size units measured in characters

tplot_options,'ymargin',[5,10] ;This command sets a bottom margin of 5 characters and a top margin of 10 characters
tplot

print,"Use the 'ymargin' option to control the size of the bottom/top plot margin"
print,'Type ".c" to continue'
stop

;Use the "window" procedure to change the size of a particular window
; size parameters given in pixels

window, 0, xsize=800, ysize=700

tplot

print, 'Use the "window" procedure to change the size of a particular window.' 
print,'Type ".c" to continue'
stop

print,'Resetting margins to something more reasonable'
tplot_options,'xmargin',[15,15]
tplot_options,'ymargin',[5,5]

;Use ygap to control the vertical space between plots
;You can also eliminate the gap by setting ygap=0

tplot_options,'ygap',10
tplot

print,'Change gap between panels using y-gap
print,'Type ".c" to continue'
stop

print,'Resetting ygap to something more reasonable'
tplot_options,'ygap',1

tplot

stop

options,'t_pseudo_var',panel_size=0.3 ;0.3, means 3/10 of normal panel height(1.0 is normal)
tplot
print,'Change the relative vertical height of a panel using panel_size'

stop
 
print,'Crib Done!'
 
end
