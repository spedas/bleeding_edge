;+
; NAME: crib_tplot
; 
; PURPOSE:  Updated crib to demonstrate tplot basics. 
;           You can run this crib by typing:
;           IDL>.compile crib_tplot
;           IDL>.go
;           
;           When you reach a stop, press
;           IDL>.c
;           to continue
;           
;           Or you can copy and paste commands directly onto the command line
;           
;           
;
;
; SEE ALSO: crib_tplot_layout.pro  (how to arrange plots within a window, and data within a plot)
;           crib_tplot_range.pro   (how to control the range and scaling of plots)
;           crib_tplot_annotation.pro  (how to control labels, titles, and colors of plots)
;           crib_tplot_export_print.pro (how to export images of plots into pngs and postscripts)
;
; NOTES:
;   If you see any useful commands missing from these cribs, please let us know.
;   these cribs can help double as documentation for tplot.
;
; $LastChangedBy: jimm $
; $LastChangedDate: 2019-03-25 14:31:57 -0700 (Mon, 25 Mar 2019) $
; $LastChangedRevision: 26896 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/examples/crib_tplot.pro $
;-

;---------------------------------------------------------------------------------------------------
; Set Up 
;---------------------------------------------------------------------------------------------------

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

;Use 'tplot_names' to see the names of the loaded quantities and their indexes
tplot_names

print,"Use 'tplot_names' to see what quantities are loaded"
print,'Type ".c" to continue'
stop

;---------------------------------------------------------------------------------------------------
; Plot Variables
;---------------------------------------------------------------------------------------------------

;use 'tplot' to plot some moments line data
tplot,'sta_SWEA_mom_flux'


print,"Use 'tplot,name' plot line data."
print,'Type ".c" to continue'
stop

;use tplot to plot spectral data
tplot,'sta_SWEA_en'

print,"Or Use 'tplot,name' to plot spectal data."
print,'Type ".c" to continue'
stop

;you can also plot quantities by number
tplot,6

print,"Use 'tplot,number' to select a quantity to plot by number."
print,'Type ".c" to continue'
stop

;you can plot multiple quantities in the same window by grouping with brackets.
tplot,['sta_SWEA_mom_flux','sta_SWEA_en']

print,"Use 'tplot,[name,name,...]' to put multiple plots in the same window."
print,'Type ".c" to continue'
stop

;you can also group quantities by number
tplot,[3,14]

print,"Use 'tplot,[number,number,...]' to put multiple plots in the same window."
print,'Type ".c" to continue'
stop

;compount variables will graph their constituents on a single plot
store_data, 'compound_var', data = 'sta_SWEA_mom_avgtemp sta_SWEA_mom_t3'
tplot, 'compound_var'

print, 'Use "store_data, ''new_name'', data = ''var1 var2 var3...''" to create a compound variable'
print, 'Type ".c" to continue'

;---------------------------------------------------------------------------------------------------
; Plot Variables Using "Globbing"
;---------------------------------------------------------------------------------------------------

;you can also select multiple quantities using "globbing" characters('*' & '?')
;Use '?' to select any tplot names that match all characters except
;a single character at '?'
;Use '*' to match multiple characters at the '*'

;this example matches sta_SWEA_en and stb_SWEA_en with '?'
tplot,'st?_SWEA_en'

print,'Use "?" to match multiple quantities with a single character'
print,'Type ".c" to continue'
stop

;this example matches stb_SWEA_Distribution, stb_SWEA_V0, and stb_SWEA_en 
tplot,'stb_*'

print,'Use "*" to match multiple quantities with multiple characters'
print,'Type ".c" to continue'
stop

;you can also combine globbing with explicit names,
;(this example matches sta_SWEA_mom_flux & sta_SWEA_mom_eflux)

tplot,['*flux','sta_SWEA_en']

print,'Example combining globbing and explicit names'
print,'Type ".c" to continue'
stop

;---------------------------------------------------------------------------------------------------
; Options and Features
;---------------------------------------------------------------------------------------------------

;--------------------------------------------------------------------------
;  Most tplot options can be set globally or on indivitual tplot variables.
;  Use the "options" routine to set a property of an indivitual variable
;  and the "tplot_options" routine to set the property for all plots.
;--------------------------------------------------------------------------


;You can bring the plot window to the front with the WSHOW keyword 

tplot,['*flux','sta_SWEA_en'], /wshow

print,'Example of how to bring plot window to front when plotting.'
print,'type ".c" to continue'
stop


;You can set all windows to automatically pop to the front by 
;setting the global WSHOW option

tplot_options, 'wshow', 1
tplot

tplot_options, 'wshow', 0 ;reset

print,'Example of how to automatically bring plot window(s) to front.'
print,'type ".c" to continue'
stop


;You can zoom in on a specific time range interactively, using tlimit
print,"Use 'tlimit' to select a specific range interactively"
print,"Click two locations on the screen to zoom in"

tplot,['sta_SWEA_mom_flux','sta_SWEA_en']
tlimit

print,'Type ".c" to continue'
stop


;you can change the time range without clicking using this command
tlimit,'2008-03-23/12:00:00','2008-03-23/20:00:00'

print,"Use 'tlimit,starttime,stoptime' to select a specific range without clicking"
print,'Type ".c" to continue'
stop


;revert to the previous time range
tlimit, /last

print,'Use tlimit, /last to revert to the previous time range'
print,'Type ".c" to continue'
stop


;use full time range of loaded data
tlimit, /full

print,'Use tlimit, /full to use the full time range of loaded data'
print,'Type ".c" to continue'
stop


;Spectrogram interpolation can be controlled with 3 options.
;These options can be set on a specific variables or globally.
;  x_no_interp:  disables interpolation along the x axis
;  y_no_interp:  disables interpolation along the y axis
;    no_interp:  disables all interpolation (overrides x/y options if set) 

;Note:  Some missions will set no_interp globally and set [xy]_no_interp
;       when creating spectrograms of their data.

;plot interpolated spectrogram
tplot_options, 'no_interp', 0   ;ensure global is off 

options, 'sta_SWEA_en', no_interp=0

tplot, 'sta_SWEA_en'

print,'Example of how to turn off interpolation on spectrograms.'
print,'type ".c" to continue'
stop

;plot spectrogram without interpolation
options, 'sta_SWEA_en', no_interp=1

tplot, 'sta_SWEA_en'

print,'Example of how to globally turn off interpolation on spectrograms.'
print,'type ".c" to continue'
stop


;To delete an option call the routine with the option named but no argument.

;remove inteprolation option set in previous example
options, 'sta_SWEA_en', 'no_interp'

;remove default option from variable
options, 'sta_SWEA_en', 'ylog', /default

;remove global interpolation option set in previous example
tplot_options, 'no_interp'

tplot, 'sta_SWEA_en'

print, 'Example of how to delete options'
print,'type ".c" to continue'
stop


;Use the /default keyword to set as option as a variable's default.

;add ylog option removed in previous example
options, 'sta_SWEA_en', ylog=1, /default

tplot, 'sta_SWEA_en'

print, 'Example of how to add default options to variable'
print,'type ".c" to continue'
stop

;if the option is set normally that value will be used instead 
;of the default until it is removed
options, 'sta_SWEA_en', ylog=0

tplot, 'sta_SWEA_en'

print, 'Example of how to delete options'
print,'type ".c" to continue'
stop


;---------------------------------------------------------------------------------------------------
; Retrieving Data
;---------------------------------------------------------------------------------------------------

;you can use this command to get the array data that is stored in a tplot variable
;as well as the plot settings associated with that tplot variable

get_data,'sta_SWEA_en', data=d
;'d' contains the array data from the tplot variable
print,'contents of d:'
help,d,/str
print,'d.x:'
help,d.x ;d.x is the time array for the tplot variable
print,'d.y:'
help,d.y ;d.y is the data array for the tplot variable
print,'d.v:'
help,d.v ;d.v is the y-axis scaling data for the tplot variable(not all quantities have this component

print,"Use 'get_data,name,data=d' to get the array data from a tplot variable"
print,'Type ".c" to continue'
stop


get_data,'sta_SWEA_en',dlimit=dl

print,'contents of dl:'
help,/str,dl ;This struct contains default plot settings like color and labels
;print,'contents of dl.cdf:'
;help,/str,dl.cdf ;This component contains the CDF meta data that was read on ingestion
;print,'contents of dl.data_att:' 
;help,/str,dl.data_att ; This component contains commonly used meta data like units, coordinate system, and calibration level 

print,"Use 'get_data,name,dlimit=dl' to get the default plot settings from a tplot variable"
print,'Type ".c" to continue'
stop 


get_data,'sta_SWEA_en',limit=l

print,'limits:'
help,/str,l ;This struct contains user defined plot settings which override settings, if unset it will be a 0 

print,"Use 'get_data,name,limit=l' to get user settings from a tplot variable"
print,'Type ".c" to continue'
stop


;you can use store_data to replace the data,limits,& dlimits after modifying them
;if the limits or dlimits structures are not present you can add them

get_data,'sta_SWEA_mom_flux',data=d,limit=l,dlimit=dl

d.y = d.y * (-10.)  ;modify data

;dl.ysubtitle = 'new_subtitle'     ;change exsisting y subtitle
;str_element, dl, ysubtitle, 'new_subtitle'  ;add y subtitle to dlimits
dl = {ysubtitle:'new_subtitle'}   ;add y subtitle if no dlimits are present

store_data,'sta_SWEA_mom_flux_new',data=d,limit=l,dlimit=dl ;store it in a new variable

print,"you can use 'store_data' to replace the data, limits, & dlimits after modifying them"
print,'see the (commented out) lines above for editing/adding limits structures'
;replot it
tplot,['sta_SWEA_mom_flux','sta_SWEA_mom_flux_new']

;you can add a tshift to the data array to shift all times by a
;constant factor, 
get_data, 'sta_SWEA_mom_flux', data=d, limit=l, dlimit=dl
;str_element adds a tag to the structure, using the /add_replace
;keyword
str_element, d, 'tshift', 120.0, /add_replace
store_data,'sta_SWEA_mom_flux_shift120',data=d,limit=l,dlimit=dl ;store it in a new variable
print, 'you can add a tshift to the data array to shift all times by a constant factor'
;replot it
tplot,['sta_SWEA_mom_flux','sta_SWEA_mom_flux_shift120']



end
