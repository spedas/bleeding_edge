;+
;PROCEDURE: tsmooth_in_time, varname, dt, newname = newname
;PURPOSE:
; Calls smooth_in_time function on a plot variable
;INPUT:
; varname = variable passed to get_data, example - thg_mag_ccnv
; dt = the averaging time (in seconds)
;KEYWORDS:
; newname = set output variable name
; display_object = Object reference to be passed to dprint for output.

; 
;HISTORY:
; 11-apr-2008, jmm, jimm@ssl.berkeley.edu
;
;$LastChangedBy: aaflores $
;$LastChangedDate: 2012-01-26 15:01:41 -0800 (Thu, 26 Jan 2012) $
;$LastChangedRevision: 9619 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/misc/tsmooth_in_time.pro $
;-

Pro tsmooth_in_time, varname, dt, newname = newname, _extra = _extra,interactive_warning=interactive_warning,warning_result=warning_result, display_object=display_object

  get_data, varname, data = data, dlimits = dlimits, limits = limits
  If(is_struct(data) Eq 0) Then Begin
    dprint, 'No data in '+varname, display_object=display_object
  Endif Else Begin
    y1 = smooth_in_time(data.y, data.x, dt, _extra = _extra,interactive_warning=keyword_set(interactive_warning),warning_result=warning_result, display_object=display_object)
    if warning_result eq 0 then return
    str_element, data, 'v', success = ok
    If(ok Eq 0) Then data1 = {x:data.x, y:y1} $
    Else data1 = {x:data.x, y:y1, v:data.v}
    If(keyword_set(newname)) then name2 = newname $
    Else name2 = varname+'_smoothed'
    store_data, name2, data = data1, dlimits = dlimits, limits = limits
  Endelse
End
