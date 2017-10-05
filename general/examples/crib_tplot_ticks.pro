;+
; NAME: crib_tplot_ticks
; 
; PURPOSE:  Crib to demonstrate tplot annotation commands  
;           You can run this crib by typing:
;           IDL>.compile crib_tplot_ticks
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
;           crib_tplot_ticks.pro (how to control plot tick settings, thickness,length, number, etc...)
;
;
; NOTES:
;  1.  As a rule of thumb, "tplot_options" controls settings that are global to any tplot
;   "options" controls settings that are specific to a tplot variable
;   
;  2.  If you see any useful commands missing from these cribs, please let us know.
;   these cribs can help double as documentation for tplot.
;
; $LastChangedBy: pcruce $
; $LastChangedDate: 2013-12-16 14:43:09 -0800 (Mon, 16 Dec 2013) $
; $LastChangedRevision: 13679 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/examples/crib_tplot_ticks.pro $
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

;create pseudo variable to use later
store_data, 'pseudo_var', data='sta_SWEA_mom_ptens sta_SWEA_mom_t3'

;-------------------------------------------------

;basic plot for comparision
tplot,['sta_SWEA_en','sta_SWEA_mom_flux']

print,'  This first plot is the default, for reference. 
print,'Type ".c" to continue crib examples.'
stop

;use x/y ticklen to control length of major ticks

options,'sta_SWEA_mom_flux',xticklen=.15,yticklen=.05 ;value is a proportion of panel occupied by ticks, ie 1 = 100%, so we create a grid with this call
options,'sta_SWEA_en',xticklen=.20,yticklen=.25 ;these ticks are 25% and 35% of the panel size, respectively

;var_label = '' turns off variable labels
tplot,var_label=''


print,'  "x/yticklen" can be used to control tick length'
print,'Type ".c" to continue'
stop

;use ticklen to create a grid
options,'sta_SWEA_mom_flux',xticklen=1,yticklen=1 ;value is a proportion of panel occupied by ticks, ie 1 = 100%, so we create a grid with this call
options,'sta_SWEA_en',xticklen=1,yticklen=1;these ticks are 25% and 35% of the panel size, respectively

tplot

print,'You can set long ticks to create a grid on major ticks.'
print,'Type ".c" to continue'
stop

;resetting tick-len
options,'sta_SWEA_mom_flux',xticklen=.1,yticklen=.05
options,'sta_SWEA_en',xticklen=.1,yticklen=.05

;Control thickness of borders & ticks with y/x-thick

options,'sta_SWEA_mom_flux',xthick=2.0,ythick=2.0
options,'sta_SWEA_en',xthick=5.0,ythick=1.0

tplot


print,'You can control border/tick/grid thickness using x/y thick'
print,'Type ".c" to continue'
stop

;reset thickness
options,'sta_SWEA_mom_flux',xthick=1.0,ythick=1.0
options,'sta_SWEA_en',xthick=1.0,ythick=1.0

;control number of y-axis major & minor ticks

options,'sta_SWEA_mom_flux',yticks=10,yminor=3
options,'sta_SWEA_en',yticks=5,yminor=5

print,'You can control number of y-axis ticks with yticks/yminor'
print,'Type ".c" to continue'
stop

;control spacing of x-axis major ticks and number of minor ticks
;
;since plots are time-stacked, x-ticks treated as a plot global so we tplot_options(not options)
tplot_options,'tickinterval',3600 ;seconds => 3600=1hour per tick
tplot_options,'xminor',6

print,'You can control number of y-axis ticks with yticks/yminor'
print,'Type ".c" to continue'
stop

;reset tickinterval & xminors to autoscaling
tplot_options,'tickinterval',0
tplot_options,'xminor',-1

print,"We're done!"


end
