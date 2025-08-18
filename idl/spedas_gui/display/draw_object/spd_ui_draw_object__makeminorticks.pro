;+
;
;spd_ui_draw_object method: makeMinorTicks
;
;This routine takes generates the minor ticks for the z-axis and the xy axes.
;It does most of the work to guarantee proper spacing of minor ticks on logarithmic axes
;Inputs:
;  Range:  The range of the data values.(log applied, not real)
;  Scaling: The scaling factor used on this axis. (O: Linear, 1: Log10, 2:LogN)
;  MinorNum: The requested number of minor ticks per major tick
;  MajorValues: An array of major tick positions, normalized relative to their respective axis.  Minimum 2 major ticks. 
;  MajorSpacing:  The spacing between major ticks, in normalized units.
;  MinorAuto: Whether automatic minor ticks are being used or not.
; 
;Outputs:
;  MinorValues: An array of minor tick positions.  Not for a single major tick, but for the entire axis.
;  Fail: 0 indicates no fail, 1 indicates fail.  If no ticks can fit on axis, failure is indicated.
;
;NOTES:
;  Minor ticks will appear to be more evenly spaced the smaller the interval is between ticks on a logarithmic axis.
;  On a non-log axis, they will always be evenly spaced.
;
;
;$LastChangedBy: jimm $
;$LastChangedDate: 2014-02-11 10:54:32 -0800 (Tue, 11 Feb 2014) $
;$LastChangedRevision: 14326 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/spedas_gui/display/draw_object/spd_ui_draw_object__makeminorticks.pro $
;-
pro spd_ui_draw_object::makeMinorTicks,range,scaling,minorNum,majorValues,majorSpacing,logMinorTickType,minorValues=minorValues,fail=fail

  compile_opt idl2,hidden
  
  fail = 1
  tolerance = .01
  
  ;blank the minor tickValues, to prevent any inadvertent interaction
  undefine,minorValues

  majorNum = n_elements(majorValues)
    
  n = minorNum+1
  
  if n * majorNum gt self.maxTickNum * 2 then begin
    self.statusBar->update,'ERROR:  The current settings will result in the creation of ' + strcompress(string(n*majorNum),/remove_all) + ' minor ticks.  Draw operation failed.'
    self.historyWin->update,'ERROR:  The current settings will result in the creation of ' + strcompress(string(n*majorNum),/remove_all) + ' minor ticks.  Draw operation failed.'
    fail = 1
    return
  endif
  
  majorValue1 = (majorValues[0] + range[0]/(range[1]-range[0]))*(range[1]-range[0])
  majorValue2 = (majorValues[1] + range[0]/(range[1]-range[0]))*(range[1]-range[0])
    
  if scaling eq 1 then begin
    base = 10d
  endif else begin
    base = exp(1)
  endelse
    
  if scaling eq 0 || logMinorTickType eq 3 then begin
    minorValues = (dindgen(n)*(1D/n))*majorSpacing
  endif else if logMinorTickType eq 1 || logMinorTickType eq 2 then begin
  
    ;If we don't use this spacing, you won't get any ticks when the step size is less than one order of magnitude
    stepSize=majorValue2-majorValue1
  
    if logMinorTickType eq 1 then begin
      deLogMajorValue1 = base^majorValue1
      deLogMajorValue2 = base^(majorValue1+(1<stepSize))
    endif else if logMinorTickType eq 2 then begin
      deLogMajorValue1 = base^(majorValue2-(1<stepSize))
      deLogMajorValue2 = base^(majorValue2)
    endif
    
    minorValues = (dindgen(n+1)/(n))*(deLogMajorValue2-deLogMajorValue1) + deLogMajorValue1
    
    idx = where(minorValues ge base^majorValue1 and minorValues le base^majorValue2,c)
       
    if c eq 0 then begin
      minorValues = [base^majorValue1,base^majorValue2]
      n=1
    endif else begin
      minorValues = minorValues[idx]
      
      if minorValues[0] gt ((base^majorValue1)+(base^majorValue2-base^majorValue1)*tolerance) then begin
        minorValues = [base^majorValue1,minorValues]
      endif
      
      if minorValues[n_elements(minorValues)-1] lt ((base^majorValue2)-(base^majorValue2-base^majorValue1)*tolerance) then begin
        minorValues = [minorValues,base^majorValue2]
      endif
                    
      n = (n_elements(minorValues)-1 < n)
    endelse  
    
   ; print,minorValues
    
    if scaling eq 1 then begin
      minorValues = alog10(minorValues)
    endif else begin
      minorValues = alog(minorValues)
    endelse
  
    minorValues = majorSpacing*((minorValues[0:n]) - majorValue1)/(majorValue2-majorValue1)
  
  endif else begin
  
    minorValues = alog10(10*dindgen(n+2)/(n+1)+1)*(majorValue2-majorValue1)/(range[1]-range[0]) 

  endelse
  
  minorInd1 = lindgen((majorNum+1)*(n)) / long(n)
  minorInd2 = lindgen((majorNum+1)*(n)) mod long(n)
  
  minorValues = majorValues[minorInd1]+minorValues[minorInd2]
  
  idx = where(minorValues lt 1. and minorValues gt 0.,c)

  if c gt 0 then begin
    minorValues = minorValues[idx]
    fail = 0
  endif else begin
    minorValues = minorValues[0]
    fail = 1
  endelse
  
  return

end
