;+
;
;spd_ui_draw_object method: getRange
;
;Calculates the range of a sequence. Based upon axis settings and the set of traces in the panel.
;This calculation is symmetric across the x/y axes.
;Inputs:
;
;  dataPtrs(array of ptrs to arrays):  List of pointer to data quantities for which range is calculated
;  axisSettings(object reference):  The spd_ui_axis_settings object for this panel.
;  mirror(array of ptrs to arrays, optional):  List of pointers to mirror data quantities. 
;                                 Should have same number of elements as dataPtrs, and really only makes sense when used with the y-axis
;  isspec: needed to catch a particular special case for spectrograms
;
;Outputs:
;
;  range(2 element double):  The determined range
;  scaling(long):  The scaling mode: 0(linear),1(log10),2logn
;  istime(boolean): Returns the isTime flag from the axis being queried
;  fail(boolean):  1 on fail, 0 on success
;  errmsg: a struct describing an error that has occurred. Note that this only exists for some particular errors
;  where it is necessary to pass the error information up to the calling routine. fail=1 does not guarantee the
;  existance of errmsg and vice versa.
;
;$LastChangedBy: jimm $
;$LastChangedDate: 2014-02-11 10:54:32 -0800 (Tue, 11 Feb 2014) $
;$LastChangedRevision: 14326 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/spedas_gui/display/draw_object/spd_ui_draw_object__getrange.pro $
;-

pro spd_ui_draw_object::getRange,dataptrs,axisSettings,mirror=mirror,scaling=scaling,range=range,istime=isTimeAxis,fail=fail,center=center, errmsg=errmsg, isspec=isspec

  compile_opt idl2
  
  fail = 1
  
  axisSettings->getProperty,rangeOption=rangeOption, $
    rangeMargin=rangeMargin,$
    boundScaling=boundScaling, $
    boundfloating=boundfloating,$
    minFloatRange=minFloatRange,$
    maxFloatRange=maxFloatRange,$
    minBoundRange=minBoundRange, $
    maxBoundRange=maxBoundRange, $
    minFixedRange=minFixedRange, $
    maxFixedRange=maxFixedRange, $
    floatingSpan=floatingSpan, $
    floatingCenter=floatingCenter,$
    scaling=scaling,$
    isTimeAxis=isTimeAxis,$
    annotateStyle=annotateStyle,$
    annotateExponent=annotateExponent
      
  ;error handling for fixed range  done outside of main if block
  ;so that option can be modified and plot may be recovered
  if rangeOption eq 2 then begin
    if maxFixedRange le 0 && scaling ne 0 then begin
      self.statusbar->update,'Error: Negative range with logarithmic X/Y axis, Using automatically scaled range instead.'
      self.historywin->update,'Error: Negative range with logarithmic X/Y axis, Using automatically scaled range instead.'
      ;  ok = error_message('Negative range with logarithmic axis',/traceback)
      rangeOption = 0
    endif else if minFixedRange le 0 && scaling ne 0 then begin
      self.statusbar->update,'Error: Negative range with logarithmic X/Y axis, Using automatically scaled range instead'
      self.historywin->update,'Error: Negative range with logarithmic X/Y axis, Using automatically scaled range instead'  
      ;ok = error_message('Negative range with logarithmic axis',/traceback)
      rangeOption = 0
    endif else if minFixedRange gt maxFixedRange then begin
      self.statusbar->update,'Error: Min Fixed Range greater than Max Fixed Range, Using automatically scaled range instead'
      self.historywin->update,'Error: Min Fixed Range greater than Max Fixed Range, Using automatically scaled range instead'
      ;ok = error_message('Negative range with logarithmic axis',/traceback)
      rangeOption = 0
    endif
  endif
 


  ;*Note: The following calculation is used for the (now obsolete) floating center
  ;       option, however it may be needed for the 'updatepanels' method as well.

  ;The calculation for the floating range is generated using the mean of the 
  ;center for each individual data quantity. This is faster to calculate and 
  ;prevents variations in sample rate between traces from creating an unreasonable result.  
  ;(For example, if I'm looking at fgl & fgs, the value from fgl would dominate
  ; if I look at the combined mean/median of the data, rather than the mean of the medians
  ; because the sample rate is much higher on fgl, and thus it has many more points.)
  
  centers = dblarr(n_elements(dataptrs))
 
  ;loop through data and find the center for each using the requested method
  ;Approximate and Exact centers are handled the same way in the current version.
  for i = 0,n_elements(dataptrs)-1 do begin
  
    if ~ptr_valid(dataPtrs[i]) then continue
    
    if keyword_set(mirror) && ptr_valid(mirror[i]) then begin
      centers[i] = 0
    endif else if scaling eq 1 then begin
      if floatingCenter eq 0 || floatingCenter eq 2 then begin  
        centers[i] = mean((*dataPTrs[i]),/nan)
      endif else if floatingCenter eq 1 || floatingCenter eq 3 then begin
        centers[i] = median((*dataPTrs[i]))
      endif else begin
        self.statusBar->update,'Error: Unrecognized floating center option'
        ;ok = error_message('Unrecognized floating center option',/traceback)
        range = double([0,1])
        return
      endelse
    endif else if scaling eq 2 then begin
      if floatingCenter eq 0 || floatingCenter eq 2 then begin
        centers[i] = mean((*dataPTrs[i]),/nan)
      endif else if floatingCenter eq 1 || floatingCenter eq 3 then begin
        centers[i] = median((*dataPTrs[i]))
      endif else begin
        self.statusBar->update,'Error: Unrecognized floating center option'
        ;ok = error_message('Unrecognized floating center option',/traceback)
        range = double([0,1])
        return
      endelse
    endif else begin
      if floatingCenter eq 0 || floatingCenter eq 2 then begin
        centers[i] = mean(*dataPTrs[i],/nan)
      endif else if floatingCenter eq 1 || floatingCenter eq 3 then begin
        centers[i] = median(*dataPTrs[i])
      endif else begin
        self.statusBar->update,'Error: Unrecognized floating center option'
        ;ok = error_message('Unrecognized floating center option',/traceback)
        range = double([0,1])
        return
      endelse
    endelse
    
  endfor
  
  ;this gets passed out to draw object's "updatepanels" method
  center = mean(centers,/nan)

  

  ;get range based off option type and scaling
  if rangeOption eq 2 then begin
    range = [minFixedRange,maxFixedRange]
    
    if scaling eq 1 then begin
      range = double(alog10(range))
    endif else if scaling eq 2 then begin
      range = double(alog(range))
    endif else begin
      range = double(range)
    endelse
    
  endif else if rangeOption eq 1 then begin
;    case scaling of
;      0: center = center
;      1: center = alog10(center)
;      2: center = alog(center)
;    endcase
 
    case scaling of
      0: range = [center-floatingSpan,center+floatingSpan]
      1: range = [alog10(center)-floatingSpan,alog10(center)+floatingSpan]
      2: range = [alog(center)-floatingSpan,alog(center)+floatingSpan]
    endcase

;    range = [center-floatingSpan,center+floatingSpan]
    
    if keyword_set(boundfloating) then begin
      range[0] = max([range[0],minFloatRange],/nan)
      range[1] = min([range[1],maxFloatRange],/nan)
    endif
    
    range = double(range)
    
  endif else if rangeOption eq 0 then begin
  ;automatic scaling option
  
    minRange = !values.d_nan
    minLogRange = !values.d_nan
    maxRange = !values.d_nan
    
       
    ;loop over the data and find the joined min & max
    ; by joined I mean the min(mins_for_each_quantity), and max(maxes_for_each_quantity)
    for i = 0,n_elements(dataptrs) -1 do begin
    
      if ~ptr_valid(dataPtrs[i]) then continue
            
      minRangeTmp = min(*dataPtrs[i],/nan)
      maxRangeTmp = max(*dataPtrs[i],/nan)
      
      ;smallest value greater than zero needed to autorange log axes
      if scaling ne 0 then begin
        minLogRangeTmp = exp(min(alog(*dataPtrs[i]),/nan))
        minLogRange = min([minLogRange,minLogRangeTmp],/nan)     
      endif else if keyword_set(mirror) && ptr_valid(mirror[i]) then begin      ;only bothers try to mirror linear data
        ;If a mirror is present, we reflect the range over 0, so that
        ;we can be certain the mirrored line will be in the plot
        ;only reflect linear axes
        rangeAbs = max([abs(maxRangeTmp),abs(minRangeTmp)],/nan)
        maxRangeTmp = rangeAbs
        minRangeTmp = -rangeAbs
      endif
      
      minRange = min([minRange,minRangeTmp],/nan)
      maxRange = max([maxRange,maxRangeTmp],/nan)
      
    endfor
    
    ;log spectra with zero range should be plotted linearly so that it is possible to display the data at all
    if keyword_set(isspec) && scaling ne 0 then begin
      if (maxRange-minRange) eq 0 then begin
        scaling = 0
      endif
    endif
  
    ;convert ranges into log space.  Incidentally, this will nan ranges that are invalid for log axes
    if scaling eq 1 then begin
      minRange=alog10(minLogRange)
      maxRange=alog10(maxRange)
    endif else if scaling eq 2 then begin
      minRange=alog(minLogRange)
      maxRange=alog(maxRange)
    endif
    
    ;add range margin to calculated range.
    ;It is interpreted as +- some % of the current span.
    ;So if rangemargin is .05, The final span will be the same
    ;whether the range goes from [-10,10] or [100,120], but not [-20,20]
    margin = rangeMargin*(maxRange-minRange)
    
    if margin eq 0 && rangeMargin ne 0 then begin
    
      if maxRange eq 0 then begin
        margin = 1
      endif else begin
        margin = rangeMargin * maxRange
      endelse
    
    endif
    
    maxRange+= abs(margin)
    minRange-= abs(margin)
    
    ;Boundscaling is last.   If the range is larger or smaller than the bounds,
    ;replace the appropriate value with the bounded value.
    ;It is probably equally correct to calculate the range margin after the boundscaling,
    ;but this would produce a different result.  
    if keyword_set(boundScaling) then begin
    
      if scaling eq 0 then begin
        minRange = max([minRange,minBoundRange],/nan)
        maxRange = min([maxRange,maxBoundRange],/nan)
      endif else if scaling eq 1 then begin
        minRange = max([minRange,alog10(minBoundRange)],/nan)
        maxRange = min([maxRange,alog10(maxBoundRange)],/nan)
      endif else if scaling eq 2 then begin
        minRange = max([minRange,alog(minBoundRange)],/nan)
        maxRange = min([maxRange,alog(maxBoundRange)],/nan)
      endif
      
      if minRange gt maxRange then begin
        self.statusBar->update,'No data found within range when using bound autoscaling range option.'
        errmsg = {TYPE:'ERROR', VALUE:'Bound autoscaling range option set. No data found within range.'}
        range = double([minRange,maxRange])
        return
      endif
      
    endif
    
    range = double([minRange,maxRange])

  endif else begin
    self.statusBar->update,'Error: Illegal range option on axis'
    ;error_message,'Illegal range option on axis',/traceback
    range = double([0,1])
  endelse
  
  
  ;Final value validation  
  ;Note that we may want to improve this error reporting in the future.  It could, for example, tell the user whether it failed because there is no data, the range is invalid, or a log axis is used on data that is less than or equal to zero 
  if ~finite(range[0]) || ~finite(range[1]) then begin
    self.statusbar->update,'There is no real and finite data in the current range.'
    errmsg = {TYPE:'ERROR', VALUE:'There is no real and finite data in the current range.'}
    return
  endif
  
  if range[1]-range[0] lt 0 then begin
    self.statusbar->update,'Error: range interval is less than 0'
    self.historyWin->update,'Error: range interval is less than 0'
    errmsg = {TYPE:'ERROR', VALUE:'Range interval is less than 0.'}
    return
  endif
  
  ;Used to convert to strings for error messages.
  data_struct = {scaling:scaling,timeAxis:isTimeAxis,formatid:annotateStyle,exponent:annotateExponent}
  
  if range[1] eq range[0] then begin
 
    self.statusbar->update,'Warning: range interval is 0: ' +'Range: [' + formatannotation(0,0,range[0],data=data_struct)  + ',' + formatannotation(0,0,range[1],data=data_struct)  + ']
    self.historyWin->update,'Warning: range interval is 0: ' +'Range: [' + formatannotation(0,0,range[0],data=data_struct)  + ',' + formatannotation(0,0,range[1],data=data_struct)  + ']
  endif else begin
    
    self.historyWin->update,'Range: [' + formatannotation(0,0,range[0],data=data_struct)  + ',' + formatannotation(0,0,range[1],data=data_struct)  + '] will be used to plot.'
      
  endelse
  
  fail = 0
  
end
