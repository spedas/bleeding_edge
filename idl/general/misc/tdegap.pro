;+
;NAME:
; tdegap
;PURPOSE:
; wrapper for xdegap.pro allowing input of tplot variable names
;CALLING SEQUENCE:
; tdegap, varnames, dt=dt, margin=margin, maxgap=maxgap,$
;         newname=newname, overwrite=overwrite
;INPUT:
; varnames = an array (or scalar) of tplot variable names
;KEYWORDS:
; dt = the nominal time resolution of the data that will be inserted,
;      the default is to choose the median of the input time array
; margin = the margin used to determine if a gap is big enough, the
;          default is 0.25 seconds
; maxgap = the maximum gap size that will be allowed to be filled, in
;          units of dt. the default is to set this to the max number
;          of data points
;          (TDEGAP degaps anything that is greater than dt+margin 
;          and less than maxgap*dt)
; newname = if set,give these names to the degapped data, the
;                default is to append '_degap' to the input names and
;                pass out the names in the newname variables,
;                Unless /overwrite is set
; overwrite = if set, write the new data back to the old tplot
;             variables, do not set this with newname
; (Keywords passed to XDEGAP:)
; nowarning = if set, suppresses warnings
; flag = A numeric user-specified value to use for flagging gaps.
;   Defaults to a floating NaN.  If an array is entered, only the
;   first element is considered.If a non-numeric datatype is entered,
;   its value is ignored.
; onenanpergap = Fill gaps with only one NaN -> useful for conserving memory.
;   Also, for reference concerning post-processing, the INTERPOL function
;   propagates a single NaN just as it would many NaNs.  
; display_object = An object reference to be passed to dprint for output.
; output_message = Passes any messages generated up to the calling procedure as an array of strings
; 
; 
;HISTORY:
; 9-apr-2007, jmm, jimm.ssl.berkeley.edu
; 10-oct-2008, jmm, Degaps v tags if necessary
; Added output_message keyword Feb-02-2011 prc
;$LastChangedBy: jwl $
;$LastChangedDate: 2025-08-20 11:11:05 -0700 (Wed, 20 Aug 2025) $
;$LastChangedRevision: 33563 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/misc/tdegap.pro $
;-
Pro tdegap, varnames_in, dt = dt, margin = margin, $
            newname = newname, overwrite = overwrite, $
            output_message=output_message, maxgap=maxgap, $
            display_object=display_object, $
            flag=flag, _extra = _extra

  varnames = tnames(varnames_in)  ;for wild cards, etc....
;First extract the data
  n = n_elements(varnames)
  If(keyword_set(newname)) Then begin
    If(keyword_set(overwrite)) Then begin
      msg = 'Do not set both the newname and overwrite keywords'
      dprint,msg, display_object=display_object
      if arg_present(output_message) then begin
        output_message = array_concat([msg],output_message)
      endif
      return
    Endif
    If(n_elements(newname) Ne n) Then Begin
    
      msg = 'Incompatible varnames, newname input'
      dprint,msg, display_object=display_object
      if arg_present(output_message) then begin
        output_message = array_concat([msg],output_message)
      endif
      
      Return
    Endif
    nvn = newname
  Endif Else nvn = varnames+'_degap'
;Now do the degapping
  If(keyword_set(margin)) Then mar = margin Else mar = 0.25
  For j = 0, n-1 Do Begin
    get_data, varnames[j], data = d, dlim = dlim, lim = lim
    If(is_struct(d)) Then Begin
      x = d.x
      If(n_elements(x) Le 1) Then Begin
        msg = 'Only one X value, No Degapping of: '+varnames[j]
        dprint,msg, display_object=display_object
        if arg_present(output_message) then begin
          output_message = array_concat([msg],output_message)
        endif
        nvn[j] = ''
      Endif Else Begin
        y = d.y
        If(keyword_set(dt)) Then dx = dt Else Begin
          dx = median(x[1:*]-x)
        Endelse
;may need to degap v's and dy's also, depending on size
        str_element, d, 'v', v, success = yes_v
        str_element, d, 'v2', v2, success = yes_v2
        str_element, d, 'dy', dy, success = yes_dy
        If(yes_v) Then Begin
          vsz = size(v, /dim) & ysz = size(y, /dim)
          If(n_elements(vsz) Eq n_elements(ysz) && total(vsz-ysz) Eq 0) Then degap_v = 1b $
          Else degap_v = 0b
        Endif Else degap_v = 0b
        If(yes_v2) Then Begin
          vsz = size(v2, /dim) & ysz = size(y, /dim)
          If(n_elements(vsz) Eq n_elements(ysz) && total(vsz-ysz) Eq 0) Then degap_v2 = 1b $
          Else degap_v2 = 0b
        Endif Else degap_v2 = 0b
        If(yes_dy) Then Begin
          dysz = size(dy, /dim) & ysz = size(y, /dim)
          If(n_elements(dysz) Eq n_elements(ysz) && total(dysz-ysz) Eq 0) Then degap_dy = 1b $
          Else degap_dy = 0b
        Endif Else degap_dy = 0b
        xdegap, dx, mar, temporary(x), temporary(y), $
          x_out, y_out, iindices = ii, maxgap=maxgap, flag=flag, $
          output_message=xdegap_message, display_object=display_object, $
          n_gaps=n_gaps, _extra = _extra
        if arg_present(output_message) && is_string(xdegap_message) then begin
          output_message = array_concat(xdegap_message,output_message)
        endif
        If(x_out[0] Ne -1) && n_gaps gt 0 Then Begin
          If(degap_v) Then Begin
            v_out = make_array(dimension = size(y_out, /dim), type = size(v, /type), $
                               value = 'NaN')
            v_out[ii, *] = temporary(v)
            str_element, d, 'v', temporary(v_out), /add_replace
          Endif
          If(degap_v2) Then Begin
            v_out = make_array(dimension = size(y_out, /dim), type = size(v2, /type), $
                               value = 'NaN')
            v_out[ii, *] = temporary(v2)
            str_element, d, 'v2', temporary(v_out), /add_replace
          Endif
          If(degap_dy) Then Begin
            dy_out = make_array(dimension = size(y_out, /dim), type = size(dy, /type), $
                               value = 'NaN')
            dy_out[ii, *] = temporary(dy)
            str_element, d, 'dy', temporary(dy_out), /add_replace
          Endif
          str_element, d, 'y', temporary(y_out), /add_replace
          str_element, d, 'x', temporary(x_out), /add_replace

          If(keyword_set(overwrite)) Then new_name = varnames[j] $
          Else new_name = nvn[j]
          store_data, new_name, data = d, dlim = dlim, lim = lim
        Endif Else Begin
          msg = (x_out[0] eq -1 ? 'Error Degapping: ' : 'No gaps found: ')+varnames[j]
          dprint,msg, display_object=display_object
          if arg_present(output_message) then begin
            output_message = array_concat([msg],output_message)
          endif 
          nvn[j] = ''
        Endelse
      Endelse
    Endif Else Begin
      msg = 'No data available, No Degapping of: '+varnames[j]
      dprint,msg, display_object=display_object
      if arg_present(output_message) then begin
        output_message = array_concat([msg],output_message)
      endif 
      nvn[j] = ''
    Endelse
  Endfor
  newname = nvn
  Return
End

