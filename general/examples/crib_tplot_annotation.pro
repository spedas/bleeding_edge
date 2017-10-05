;+
; NAME: crib_tplot_annotation
; 
; PURPOSE:  Crib to demonstrate tplot annotation commands  
;           You can run this crib by typing:
;           IDL>.compile crib_tplot_annotation
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
;
;
; NOTES:
;  1.  As a rule of thumb, "tplot_options" controls settings that are global to any tplot
;   "options" controls settings that are specific to a tplot variable
;   
;  2.  If you see any useful commands missing from these cribs, please let us know.
;   these cribs can help double as documentation for tplot.
;
; $LastChangedBy: crussell $
; $LastChangedDate: 2016-02-01 11:25:06 -0800 (Mon, 01 Feb 2016) $
; $LastChangedRevision: 19869 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/examples/crib_tplot_annotation.pro $
;-

;This function is a helper function used in an example below
function km2re_callback,axis,index,value,level
  return,strtrim(string(value/6471.2,format='(F6.2)'),2)
end


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

;use "title" to set the plot window title
tplot_options,title='HELLO WORLD'
tplot ;this just replots the previous plot with the new options


print,'  Set the plot title with "title"'
print,'Type ".c" to continue'
stop

;use x/y/ztitle & x/y/zsubtitle, to set individual axis titles
;by default, the variable name is used
options,'sta_SWEA_en',ytitle="I'm a ytitle",ztitle="I'm a ztitle"

;use options to set the ysubtitle
options,'sta_SWEA_mom_flux',ysubtitle="I'm a ysubtitle",xtitle="I'm an xtitle"

;replot
tplot


print,'  Use x/y/ztitle & x/y/zsubtitle, to set individual axis titles'
print,'Type ".c" to continue'
stop

;increase the whole plot charsize using "charsize"

tplot_options,'charsize',1.2  ;this value is a multiple of the default character size

tplot


print,'  Set the global character size using "charsize"'
print,'Type ".c" to continue'
stop

;change the charsize for each axis individually using xcharsize,ycharsize

options,'sta_SWEA_mom_flux',xcharsize=.6,ycharsize=1.4
options,'sta_SWEA_en',ycharsize=1.0
tplot


print,'  Change the charsize for each axis individually using "x/ycharsize"'
print,'Type ".c" to continue'
stop

;resetting sizes to more managable values
options,'sta_SWEA_mom_flux',xcharsize=1.0,ycharsize=1.0,xtitle=''


;valid inputs for "version" (date annotation | tick annotations)
; version = 1: UTC date boundaries | # of hours or days
;           2: month:day | UTC time (fewer ticks)
;           3: year(left margin) month:day | UTC time (default)
;           4: seconds after launch
;           5: supress time labels
;this option can also be set when calling tplot ( e.g. tplot, [variable], version=2 )
tplot_options, version=1

tplot

print,'  Use the global option "version" to control the x-axis style.'
print,'Type ".c" to continue'
stop



tplot_options, version=5
tplot

print,'  Example: "version=5", suppress time labeling'
print,'Type ".c" to continue'
stop

tplot_options,version=3 ;reset version to default

;use "labels" to set labels for a line plot

options,'sta_SWEA_mom_flux',labels=['Xcomp','Ycomp','Zcomp'] ;number of elements in labels should match number of components in line plot

tplot

print,'  Use "labels" to set labels for a line plot'
print,'Type ".c" to continue'
stop



;zooming in so feature is more visible
tlimit,'2008-03-23/12:00:00','2008-03-23/20:00:00'

;setting labflag will put axis labels where lines end, instead of evenly spacing labels along the axis
;labflag =  0: No labels
;           1: labels spaced equally
;          -1: labels placed equally but in reverse order
;           2: labels placed according to data end points on the plot
;           3: labels placed according to LABPOS (does not work for pseudo vars)
options,'sta_SWEA_mom_flux',labflag=1

;labels can be set or changed by using the LABELS option
options,'sta_SWEA_mom_flux', labels=['x','y','z']

tplot


print,'  Use "labflag" alone to control default positioning of labels'
print,'Type ".c" to continue'
stop


;specify label positions
;label positions are specified by value along the y-axis
options,'sta_SWEA_mom_flux',labflag=3, labpos=[0,-5e7,2e7]

tplot

print,'  Use "labflag" and "labpos" to control positioning of labels'
print,'Type ".c" to continue'
stop


;control label spacing on pseudo variables

; labels must be added to individual components in this case,
; this is not necessary if the variables already have labels
options, 'sta_SWEA_mom_ptens', labels = 'p_' + strsplit('xx yy zz xy xz yz',/extract)
options, 'sta_SWEA_mom_t3', labels = 't_'+['x','y','z']

;set labels to be evenly spaced
;the LABFLAG option for pseudo variables can be set to 0,+-1, or 2
options,'pseudo_var', labflag=-1

tplot, 'pseudo_var'

print, '  Control labels on pseudo variable by setting the "labflag" option'
print,'Type ".c" to continue'

stop


;set specific labels on pseudo variable

;labels set on the pseudo variable itself will be used preferentially
options, 'pseudo_var', labels = 'var_' + strtrim(indgen(9),2)

tplot

print, '  Set the labels on a pseudo variable by setting the "labels" option'
print, 'Type ".c" to continue'

stop


;use blank options call to remove these labels later
;  NOTE: This works to remove ANY option that is no longer desired
options, 'pseudo_var', 'labels'

tplot

print, '  Remove an option with a blank call to "options"'
print, 'Type ".c" to continue'

stop

timebar,'2008-03-23/14:00:00'

print,'Add a vertical bar or bars to mark regions with the "timebar" routine'
print,'Type ".c" to continue"

stop


;"colors" option controls line/label color
; if the number of elements is less than the number of components the color sequence
; will be repeated
options,'sta_SWEA_mom_flux',colors=['b','m','c'] 
;valid values for colors include
;'x','m','b','c','g','y','r','w', 'd','z', and 0-255
;'x' or 0 is black
;'m' or 1 is magenta
;'b' or 2 is blue
;'c' or 3 is cyan
;'g' or 4 is green
;'y' or 5 is yellow
;'r' or 6 is red
;'w' or 255 is white
;'d' is foreground color(!p.color)
;'z' is background color(!p.background)
;10-255 are elements in a continuous color table. (The default is a basic rainbow table)

tplot, 'sta_SWEA_mom_flux'


print,'  The "colors" option controls line/label color'
print,'Type ".c" to continue'

stop

; add a dashed line at zero
timebar, 0.0, /databar, varname='sta_SWEA_mom_flux', linestyle=2

print,'Add a horizontal bar to mark data with the "timebar" routine and keyword /databar'
print,'Type ".c" to continue"

stop


;set the colors on a pseudo variable
;colors set on pseudo variables will be used instead of those set on the constituent variables
options, 'pseudo_var', colors = [15, 44, 74, 103, 133, 162, 191, 221, 250]

tplot, 'pseudo_var'

print,'  The "colors" option may be directly set on pseudo variables'
print,'Type ".c" to continue'

stop


;reset colors
options,'sta_SWEA_mom_flux',colors=[2,4,6]


;use !p.color and !p.background to change background & foreground colors
;can only use numerical color indexes (not letters)

!p.color = 1
!p.background=3

tplot


print,'  "!p.color" and "!p.background" can change foreground & background colors
print,'Type ".c" to continue'
stop

;resetting foreground & background
!p.color = 0
!p.background = 255


;label the x-axis using a single variable(distance in re)

calc,'"sta_pos_re" = "sta_pos_GSE"/6371.2',/verbose ;convert km into RE
calc,'"sta_dist_re" = sqrt(total(abs("sta_pos_re"),2))',/verbose  ;euclidean norm

options,'sta_dist_re',ytitle="Dist(RE)"  ;ytitle is used to label variables

tplot,var_label='sta_dist_re'


print,'  "var_label" can be used to label the x-axis 
print,'Type ".c" to continue'
stop


;label the x-axis using multiple single variables(state position gsm in re)

split_vec,'sta_pos_re' ;split tplot variable into individual components

;used to set label for var_label option
options,'sta_pos_re_x',ytitle='X Pos(RE)'
options,'sta_pos_re_y',ytitle='Y Pos(RE)'
options,'sta_pos_re_z',ytitle='Z Pos(RE)'

tplot,var_label=['sta_pos_re_x','sta_pos_re_y','sta_pos_re_z']

print,'Use an array of strings with var_label to create labels from multiple variables'
print,'Type ".c" to continue'
stop

options,'sta_pos_GSE',format='km2re_callback' ;callback function is at the top of the file, allows custom unit conversions just before output.
                                              ;works very similar to the plot format callback. (see IDL plot documentation x/y/ztickformat)
tplot,var_label='sta_pos_GSE'
print,'Use a callback function to format var_labels into custom unit labels for the x-axis'
print,'Type ".c" to continue'
stop


time_stamp,/off
tplot,'sta_SWEA_mom_flux'

print,'A timestamp is added to all tplot plots by default.  You can disable this behavior using the time_stamp routine'
stop

print,'You can also, re-enable timestamping using time_stamp,/on'
time_stamp,/on
tplot,'sta_SWEA_mom_flux'
stop


;decimate data to 100 points for the whole day
tr = gettime() + [ 0, 24*3600.] 
tinterpol, 'sta_SWEA_mom_flux', interpol(tr,100), suffix='_low'

options,'sta_SWEA_mom_flux_low', psym = 4


;other options (use -# to also draw a line between points)
; 1 Plus sign (+)
; 2 Asterisk (*) 
; 3 Period (.)  
; 4 Diamond  
; 5 Triangle
; 6 Square  
; 7 X  
; 8 User-defined (See examples below)  
; 10 Histogram mode

tplot,['sta_SWEA_en','sta_SWEA_mom_flux_low']

print, ' "psym" can be used to plot symbols at each datapoint,'
print, ' each point is plotted with a symbol so we will first decimate the data for this example' 
print,'Type ".c" to begin'
stop

; You can use the ssl_set_symbol routine to set pre-defined custom symbols 
; or you can set them yourself by using the IDL routine "USERSYM".

;set custom symbol to be circles
; other custom options
; 1 Plus sign
; 2 Star
; 3 Circle
; 4 Diamond
; 5 Triangle
; 6 Square
; 7 X
ssl_set_symbol, 3

options, 'sta_SWEA_mom_flux_low', psym=8
tplot


print, ' Use "PSYM = 8" options to use the user-defined symbol'
print, ' The "ssl_set_symbol" routine can be used to pick from a list of pre-defined symbols'
print, ' The IDL routine "usersym" will draw a custom symbol from a given set of points' 
print,'Type ".c" to continue'
stop


;set custom symbol to large filled triangle
ssl_set_symbol, 5, /fill, size=2.5
tplot

print, ' Set the /fill keyword on "ssl_set_symbol" or "usersym" to fill the symbol'
print, ' Set the SIZE opotion on "set_ssl_symbol" to change the size of the symbol (default=1.0) 
print, 'Type ".c" to continue' 
stop



;set custom symbol to filled horizontal diamon
x = [2, 0, -2,  0]
y = [0, 1,  0, -1]
usersym, x, y, /fill

tplot

print, ' Any custom symbol may be made by passing a list of points to "usersym"
print, 'Type ".c" to continue' 
stop


tplot,['sta_SWEA_en','sta_SWEA_mom_flux']

print, ' return to the original variables'
print,'Type ".c" to continue'
stop

;Control line thickness using 'thick'
options,'sta_SWEA_mom_flux',thick=2.0

tplot


print,'You can control line thickness using thick'
print,'Type ".c" to continue'
stop

;You can create your own custom annotations using the get_plot_pos keyword to return the corners of the plots generated by tplot in normalized coordinates.
tplot,['sta_SWEA_mom_flux','sta_SWEA_en'],get_plot_pos=p


;p is a 4xNpanels variable.  Each 4-element segment is p[*,panel_num] = [lower_left_corner_x,lower_left_corner_y,upper_right_corner_x,upper_right_corner_y]
;You can use this with built in IDL routines like plots to add your own lines.  
plots,[p[0,0],p[2,0]],[p[1,0],p[3,0]],/normal  ;Draws a line from the lower left corner of the top panel to the upper right of the top panel
print,'You can create custom annotations with the help from get_plot_pos'

stop
;Change the x-axis left hand title using the vtitle option
tplot_options,'vtitle','hello!Cworld!'
tplot

stop
print,"We're done!"


end
