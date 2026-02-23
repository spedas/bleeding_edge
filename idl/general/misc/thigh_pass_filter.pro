;+
;PROCEDURE: thigh_pass_filter, varname, dtboxwidth, newname = newname
;PURPOSE:
; Uses high_pass_filter to calculate a running average of the input data and
;   store the data with the running average subtracted in an output tplot variable.
;                   
;INPUT:
; varname = variable passed to get_data, example - thg_mag_ccnv
; dtboxwidth = the averaging time (in seconds)
;KEYWORDS:
; newname: set output variable name
; no_time_interp:  Set to save memory by preventing interpolation of time
;                  array when smoothing data before subtraction.
;                  This option will probably be significantly slower.
; double:  Set so operation is performed at double precision
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
; interactive_warning = pops up a message box if there are memory problems and asks
;                     the user if they would like to continue                    
; warning_result = assign a named variable to this keyword to determine the result of the computation
; display_object = Object reference to be passed to dprint for output.
; 
; 
;HISTORY:
; 14-jan-2008, jmm, jimm@ssl.berkeley.edu
; 06-feb-2008, teq, teq@ssl.berkeley.edu
; 23-Apr-2009, pcruce, pcruce@igpp.ucla.edu, Added extra keyword support
; 28-apr-2008, pcruce, Added interp_resolution option, added memory warning, 
;                        mod to guarantee that precision of output is at least as 
;                        large as precision of input
;$LastChangedBy: jwl $
;$LastChangedDate: 2026-02-17 11:51:46 -0800 (Tue, 17 Feb 2026) $
;$LastChangedRevision: 34164 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/misc/thigh_pass_filter.pro $
;-

Pro thigh_pass_filter, varname, dtboxwidth, newname = newname,warning_result=warning_result, display_object=display_object,_extra=ex

  get_data, varname, data = data, dlimits = dlimits, limits = limits
  If is_struct(data) eq 0 Then Begin
    dprint, 'No data in '+varname, display_object=display_object
  Endif Else Begin
    y1 = high_pass_filter(data.y, data.x, dtboxwidth,warning_result=warning_result,interactive_varname=varname,_extra=ex)
    str_element, data, 'v', success = ok
    If(ok Eq 0) Then data1 = {x:data.x, y:y1} $
    Else data1 = {x:data.x, y:y1, v:data.v}
    If(keyword_set(newname)) then name2 = newname $
    Else name2 = varname+'_hpfilt'
    store_data, name2, data = data1, dlimits = dlimits, limits = limits
  Endelse
End
