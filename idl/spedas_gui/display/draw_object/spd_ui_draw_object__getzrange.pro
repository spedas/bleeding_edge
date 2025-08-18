;+
;
;spd_ui_draw_object method: getZRange
;
;
;Calculates the zrange of a spectral plot based upon the set of spectral traces in the panel
;and the z-axis settings
;
;Inputs:
;  dataPtrs(array of ptrs to arrays):  Array of ptrs to the z-axis data for this panel.
;  zaxisSettings:  spd_ui_zaxis_settings object for this panel.
;  
;Output:
;  range(2 element double):  The determined range
;  scaling(long):  The scaling mode: 0(linear),1(log10),2logn
;  fail(boolean):  1 on fail, 0 on success
;  fixed(boolean):  1 if fixed range is used, 0 if autorange is used
;
;Keywords: 
;  forceauto:
;    Forces an auto calculation to identify the full range of the data
;
;$LastChangedBy: jimm $
;$LastChangedDate: 2014-02-11 10:54:32 -0800 (Tue, 11 Feb 2014) $
;$LastChangedRevision: 14326 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/spedas_gui/display/draw_object/spd_ui_draw_object__getzrange.pro $
;-
pro spd_ui_draw_object::getZRange,dataptrs,zaxisSettings,range=range,scaling=scaling,fail=fail,fixed=fixed,forceauto=forceauto

  compile_opt idl2,hidden
  
  fail = 1
  
  zAxissettings->getProperty,fixed=fixed,maxRange=maxRange,minRange=minRange,scaling=scaling
  
  if keyword_set(forceauto) then begin
    fixed = 0
  endif
  
  ;For fixed range, just validate values and log the inputs
  if fixed then begin
  
    if maxRange lt 0 && scaling ne 0 then begin
      self.statusbar->update,'Error: Negative fixed range with logarithmic Z axis, autoscaling instead.'
      self.historywin->update,'Error: Negative fixed range with logarithmic Z axis, autoscaling instead.'
      ;ok = error_message('Negative range with logarithmic axis',/traceback)
      fixed = 0
    endif else if minRange lt 0 && scaling ne 0 then begin
      self.statusbar->update,'Error: Negative fixed range with logarithmic Z axis, autoscaling instead.'
      self.historywin->update,'Error: Negative fixed range with logarithmic Z axis, autoscaling instead.'
      ; ok = error_message('Negative range with logarithmic axis',/traceback)
      fixed = 0
    endif else if minRange gt maxRange then begin
      self.statusbar->update,'Error: min fixed z-range greater than max fixed z-range, autoscaling instead.' 
      self.historywin->update,'Error: min fixed z-range greater than max fixed z-range, autoscaling instead.' 
      fixed = 0
    endif
    
  endif
    
  if fixed then begin
    
     if scaling eq 1 then begin
      range = alog10([minRange,maxRange])
    endif else if scaling eq 2 then begin
      range = alog([minRange,maxRange])
    endif else begin
      range = [minRange,maxRange]
    endelse
  
    if scaling ne 0 && (minRange eq 0 || maxRange eq 0) then begin
    
      self.statusbar->update,'Warning: Adjusting Fixed 0 value on logarithmic Z-axis to data minimum.'
      self.historywin->update,'Warning: Adjusting Fixed 0 value on logarithmic Z-axis to data minimum.'
    
      self->getZrange,dataptrs,zAxisSettings,range=autorange,/forceauto
      
      if minRange eq 0 then begin
        range[0] = autorange[0]
      endif
  
      if maxRange eq 0 then begin
        range[1] = autorange[1]
      endif
    endif
    
  endif else begin
  
    minRange = !VALUES.D_NAN
    maxRange = !VALUES.D_NAN
    
    ;for autoscale, loop over data and identify the join of the min and max for each quantity
    for i = 0, n_elements(dataptrs)-1 do begin
    
      ;the calculation varies a little bit if log inputs are present.
      ;le 0 values need to be screened
      if ptr_valid(dataptrs[i]) then begin
      
        if scaling eq 1 || scaling eq 2 then begin
         
          idx = where(*dataptrs[i] gt 0,c1)
          idx = where(*dataptrs[i] eq 0,c2)
         
          ;This is fix deals with out of range log values
          if c1 eq 0 && c2 eq 0 then begin
            ;do nothing
          endif else if c1 eq 0 then begin
            if ~finite(minRange) && ~finite(maxRange) then begin
              minRange = -!VALUES.D_INFINITY
              maxRange = -!VALUES.D_INFINITY
            endif
          endif else if scaling eq 1 then begin
            minRange = min([min(alog10(*dataptrs[i]),/nan),minRange],/nan)
            maxRange = max([max(alog10(*dataptrs[i]),/nan),maxRange],/nan)
          endif else begin
            minRange = min([min(alog(*dataptrs[i]),/nan),minRange],/nan)
            maxRange = max([max(alog(*dataptrs[i]),/nan),maxRange],/nan)
          endelse
        endif else begin
          minRange = min([min(*dataptrs[i],/nan),minRange],/nan)
          maxRange = max([max(*dataptrs[i],/nan),maxRange],/nan)
        endelse
      endif
      
    endfor
    
    range=[minRange,maxRange]
    
  endelse
  
  range = double(range)
  
  fail = 0
  
  return
  
  
end
