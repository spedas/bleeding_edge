;+
;NAME:
; tdpwrspc
;PURPOSE:
; wapper for dpwrspc.pro allowing input of a tplot variable name
;CALLING SEQUENCE:
; tdpwrspc, varname, newname=newname,_extra=_extra
;INPUT:
; varname = one tplot variable name
;KEYWORDS:
; newname = if set,give this name to the new data, the
;           default is to append '_dpwrspc' to the input name and
;           pass out the name in the newname variable,
;           Unless /overwrite is set. Note that if a multi-dimensional
;           variable is passed in, the newname keyword is not used.
; overwrite = if set, write the new data back to the old tplot
;             variable, do not set this with newname
;             
; nboxpoints = the number of points to use for the hanning window, the
;              default is the closest power of 2 less than the number of points divided by 32
; nshiftpoints = the number of points to shift the hanning window per-step, the default in nboxpoints/2
; 
; bin = a binsize for binning of the data along the frequency domain, the default is 3
; tbegin = a start time, the default is time[0] 
; tend = an end time, the default is time[n_elements(time)-1]
; noline = if set, no straight line is subtracted
; nohanning = if set, then no hanning window is applied to the input
; notperhz = if set, the output units are simply the square of the
;            input units 
;HISTORY:
; 27-mar-2007, jmm, jimm.ssl.berkeley.edu
; 10-apr-2007, jmm, fixed 2 bugs wrt structure definition
;
; $LastChangedBy: $
; $LastChangedDate: $
; $LastChangedRevision: $
; $URL: $
;-
Pro tdpwrspc, varname, newname = newname, $
              trange = trange, nboxpoints=nboxpoints,$
              nshiftpoints=nshiftpoints,polar=polar,_extra = _extra

;test the input variable, and call recursively if y has two dimensions
  get_data, varname, data = d, dlim = dlim, lim = lim

  If(is_struct(d)) Then Begin
      sdy = size(d.y, /n_dimension)
      If(sdy Eq 2) Then Begin
          ndj = n_elements(d.y[0, *])
          If(ndj Eq 3) Then Begin
              split_vec, varname, polar = polar, names_out = vn_j
          Endif Else If(ndj Gt 1) Then Begin
              split_vec, varname, names_out = vn_j, $
                suffix = '_'+strcompress(string(indgen(ndj)), /remove_all)
          Endif
          For j = 0, ndj-1 Do Begin
              tdpwrspc, vn_j[j], trange = trange, nboxpoints = nboxpoints, $
                nshiftpoints = nshiftpoints, _extra = _extra
          Endfor
          Return
      Endif Else If(sdy Eq 1) Then Begin
          If(keyword_set(newname)) Then begin
              If(keyword_set(overwrite)) Then begin
                  dprint, 'Do not set both the newname and overwrite keywords'
                  return
              Endif
              nvn = newname
          Endif Else nvn = varname+'_dpwrspc'
;Now do the power spectrum
          y = d.y
          t = d.x
          If(n_elements(trange) Eq 2) Then Begin
              tr = time_double(trange)
              ok = where(t Ge tr[0] And t Lt tr[1], nok)
              If(nok Eq 0) Then Begin
                  dprint, 'No data in time range'
                  dprint,  time_string(tr)
                  dprint, 'No Dynamic Power spectrum for: '+varname
                  Return
              Endif Else Begin
                  t = t[ok] & y = y[ok]
              Endelse
          Endif
;Filter out NaN's
          Ok = where(finite(y), nok)
          If(nok Eq 0) Then Begin
              dprint, 'No finite data in time range'
              Return
          Endif Else Begin
              t = t[ok] & y = y[ok]
          Endelse
          t00 = d.x[0]
          t = t-t00
;Only do this if there are enough data points, default nboxpoints to
;64 and nshiftpoints to 32, and use larger values when there are more
;points
          if ~keyword_set(nboxpoints) then begin
              nbp = max([2^(floor(alog(nok)/alog(2),/l64)-5),8])
          endif else begin
              nbp = nboxpoints
          endelse
    
          if ~keyword_set(nshiftpoints) then begin
              nsp = nbp/2
          endif else begin
              nsp = nshiftpoints
          endelse

          If(nok Le nbp) Then Begin
              dprint, 'Not enough data in time range'
              Return
          Endif
          
          dpwrspc, t, y, tp, f, p, nboxpoints = nbp, nshiftpoints = nsp, _extra = _extra

          If(tp[0] Ne -1) Then Begin
              dd = {x:temporary(tp+t00), y:temporary(p), v:temporary(f)}
              If(keyword_set(overwrite)) Then newname = varname $
              Else newname = nvn
              ; let's update the dlimit structure
              
              str_element, dlim, 'data_att', data_att, success=has_data_att
              ; check for units
              if undefined(inputunits) then begin
                  inputunits='#'
                  if(has_data_att) then begin ; we were able to get the data_att structure
                      str_element, data_att, 'units', success = yes_units
                      if(yes_units) then inputunits = data_att.units
                  endif
              endif

              if ~undefined(notperhz) then newunits = '('+inputunits+')^2' $
              else newunits =  '('+inputunits+')^2/Hz'
              if (has_data_att) then begin
                  str_element, data_att, 'units', newunits, /add
                  str_element, dlim, 'data_att', data_att, /add
              endif

              str_element, dlim, 'data_type', 'dynamic_power_spectrum', /add
              str_element, dlim, 'ytitle', newname+'!c!c[Hz]', /add
              str_element, dlim, 'SPEC', 1, /add
              str_element, dlim, 'LOG', 1, /add
              
              if ~undefined(notperhz) then begin
                str_element, dlim, 'ztitle', '('+inputunits+')!U2!N', /add
              endif else begin
                str_element, dlim, 'ztitle', '('+inputunits+')!U2!N/Hz', /add
              endelse
              store_data, newname, data = dd, dlim = dlim, lim = lim
;an error check for bad result
              finite_test = where(finite(dd.y), nfinite_test)
              If(nfinite_test Eq 0) Then dprint, 'All NaN Power spectrum for: '+varname
;some other options;
              options, newname, spec = 1, ylog = 1, zlog = 1, ystyle = 1
              
              newname = nvn
          Endif Else Begin
              dprint, 'No Power spectrum for: '+varname
          Endelse
      Endif Else Begin
          dprint, 'Inappropriate Data Input: Y must be 1d: '+varname
      Endelse
  Endif Else Begin
      dprint, 'No data: '+varname
  Endelse
  Return
End
