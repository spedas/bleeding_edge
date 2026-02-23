;+
;NAME:
; high_pass_filter
;PURPOSE:
; subtracts running average from a data array
;CALLING SEQUENCE:
; y = high_pass_filter(array, time_array, no_time_interp=no_time_interp)
;INPUT:
; array = a data array
; time_array = a time array (in units of seconds)
; dtboxwidth = the averaging time (in seconds)
; no_time_interp = if set, do *not* interpolate the data to the
;                  minimum time resolution. The default procedure is
;                  to interpolate the data to a regularly spaced grid,
;                  and then use ts_smooth to get the running
;                  average. This alternative can be slow, but it may
;                  save a lot of memory.                
; double = if set, do calculation in double precision
;                  regardless of input type. (If input data is double
;                  calculation is always done in double precision)
; interp_resolution = If time interpolation is being used, set this
;                     option to control the number of seconds between
;                     interpolated samples.  The default is to use
;                     the value of the smallest separation between 
;                     samples.  Any number higher than this will sacrifice
;                     output resolution to save memory. (NOTE: This option
;                     will not be applied if no interpolation is being
;                     performed because either (1) no_time_interp is set or
;                     (2) the sample rate of the data is constant)
;                     
; interactive_warning = if keyword is set pops up a message box if there are memory problems and asks
;                     the user if they would like to continue
; interactive_varname = set this to a string indicating the name of the quantity to be used in the warning message.
;                     
; warning_result = assign a named variable to this keyword to determine the result of the computation
;OUTPUT:
; y = the data array where at each point an average of the data for
; the previous dtboxwidth has been subtracted.
;HISTORY:
; 14-jan-2008, jmm, jimm@ssl.berkeley.edu
; 06-feb-2008, teq, teq@ssl.berkeley.edu
; 13-mar-2008, jmm, added the default behavior using interpolation
; 17-mar-2008, jmm, Gutted and rewritten to use smooth_in_time program
; 23-apr-2008, pcruce, Added padding for no_time_interp option, added _extra keyword
; 28-apr-2008, pcruce, Added interp_resolution option, added memory warning, 
;                        mod to guarantee that precision of output is at least as 
;                        large as precision of input
;$LastChangedBy: jwl $
;$LastChangedDate: 2026-02-17 11:51:46 -0800 (Tue, 17 Feb 2026) $
;$LastChangedRevision: 34164 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/misc/high_pass_filter.pro $
;-

Function high_pass_filter, array, time_array, dtboxwidth,warning_result=warning_result, _extra = _extra
	;
	;; Declaring variable as -1 for later check
	;
  out_array = -1
	;
	;; determine number of rows in input array
	;; Note: this is a tplot array, reversed from
	;; idl array
	;
  n =  n_elements(array[*, 0])
	;
	;; Make sure time values exist for each entry
	;
  If(n_elements(time_array) Ne n) Then Begin
    dprint, 'Array mismatch',dlevel=2
    ;message,/info,'Array mismatch'
    return,  out_array
  Endif
;Call the smooth_in_time routine to get the running average
  av_array = smooth_in_time(array, time_array, dtboxwidth, /backward, $
                            /true_t_integration, warning_result=warning_result,_extra = _extra)
     ;                        _extra = _extra)
;And subtract, note that NaNs will remain NaN's
  If(n_elements(av_array) Eq n_elements(array)) Then $
    out_array = array-temporary(av_array)
  Return, out_array

End
      
      
