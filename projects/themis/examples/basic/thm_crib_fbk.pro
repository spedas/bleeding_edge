;+
;	Batch File: THM_CRIB_FBK
;
;	Purpose:  Demonstrate the loading, calibration, and plotting
;		of THEMIS FBK (Filter Bank) spectral data.
;
;	Calling Sequence:
;	.run thm_crib_fbk, or using cut-and-paste.
;
;	Arguements:
;   None.
;
;	Notes:
;	None.
;
; $LastChangedBy: pcruce $
; $LastChangedDate: 2015-02-06 20:06:42 -0800 (Fri, 06 Feb 2015) $
; $LastChangedRevision: 16906 $
; $URL $
;-

;------------------------------------------------------------------------------
; FBK FilterBank data load example.
;------------------------------------------------------------------------------
;
;start with a clean slate
del_data, '*'

print, 'at each stop point type .c to continue with the crib'

stop

;set a few TPLOT options. 
tplot_title = 'THEMIS FBK Spectra Examples'
tplot_options, 'title', tplot_title
tplot_options, 'xmargin', [ 15, 10]
tplot_options, 'ymargin', [ 5, 5]

; set the timespan and load the FBK data (FB1, FB2, FBH).
timespan, '2007-06-23', 1.0, /day

;this line loads all the data from probe alpha on the specified day
thm_load_fbk, probe = 'a'

tplot_names

print, 'We just loaded the level 2 fbk data from probe alpha'

stop

;------------------------------------------------------------------------------
; Plot the loaded data
;------------------------------------------------------------------------------
tplot, [ 'tha_fb_scm1']

print, 'We just plotted the search coil magnetometer boom 1 data'

stop

;------------------------------------------------------------------------------
;Set zoom for the data
;------------------------------------------------------------------------------

tlimit, '2007-06-23/03:30:00', '2007-06-23/05:30:00'

print, 'Now we adjusted the time limit to zoom in'

stop

tlimit, '2007-06-23/00:00:00', '2007-06-24/00:00:00'

print, 'Now we zoom back out'

stop

;------------------------------------------------------------------------------
; plot multiple quantities(all level 2 data from one probe on one plot)
;------------------------------------------------------------------------------
tplot, [ 'tha_fb_*']

print, 'We just plotted all the fb data on one plot'
print, 'The line plots(fb_hff) are the max and average of the high frequency filter output from the digital fields board'
print, 'fb_edc12 is the output of electrical boom one minus electrical boom two, dc filtered'
print, 'As mentioned above, fb_scm1 is the search coil magnetometer data boom 1'

stop

;------------------------------------------------------------------------------
;using the datatype keyword for FBK
;------------------------------------------------------------------------------

del_data,'*'



;NOTE: it can be dangerous to use the datatype keyword on filterbank
;data. Because the returned datatypes vary depending on spacecraft
;configuration, your requested datatype may not be
;available. If,however, you call thm_load_fbk without the datatype
;keyword, it will return any available data on the days requested,
;regardless of type

thm_load_fbk,probe=['a','b'],datatype='fb_scm1'

tplot_names

print,'now we just loaded all the fb_scm1 data from probes alpha and beta'

stop

tplot, [ 'tha_fb_scm1','thb_fb_scm1']

print, 'Now we plot all the data'

stop

del_data, '*'

print, 'We deleted all the data'

stop

;------------------------------------------------------------------------------
;FBK support data
;------------------------------------------------------------------------------

thm_load_fbk, level=1,/get_support_data

tplot_names

print, 'We just loaded all the level 1 data from all probes, this includes uncalibrated values(fb1,fb2,fbh),calibrated values(fb_*), and values used to calibrate(fb1_src)'

stop

tplot, 'thc_*'

print, 'and plotted the themis c data using the * wildcard'

stop

;------------------------------------------------------------------------------
;List valid loadable types
;------------------------------------------------------------------------------

thm_load_fbk, /valid_names

print, 'Use the /valid_names option to get a list of valid parameters for the fbk data type'

print, 'Now we are done'

end
