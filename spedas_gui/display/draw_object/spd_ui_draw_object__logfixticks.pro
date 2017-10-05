;+
;
;spd_ui_draw_object method: logFixTicks
;
;It is sometimes the case that logarithmic axes end up with 1 or 0 ticks
;when more were requested.  This routine attempts to fix this problem
;
;It does this by using a little trick of the change of base formula.
;Essentially, if ticks are evenly spaced in base-2 log, then they will
;be evenly spaced in another base.
;
;So if the goodTick algorithm couldn't find ticks at 1x10^1,1x10^2,...
;This algorithm may find ticks at,  5,10,20,40
;
;$LastChangedBy: jimm $
;$LastChangedDate: 2014-02-11 10:54:32 -0800 (Tue, 11 Feb 2014) $
;$LastChangedRevision: 14326 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/spedas_gui/display/draw_object/spd_ui_draw_object__logfixticks.pro $
;-
pro spd_ui_draw_object::logFixTicks,$
      range_in, $ ;2 element double precision, axis range(in log space)
      tickValues=tickValues, $ ; Returns the tick values here
      tickInterval=tickInterval,$ ; Returns the spacing here
      minorTickNum=minorTickNum ; return a recommended number of minorTicks
     
     
  compile_opt idl2,hidden
     
  numTicks = 2
  minorTickNum = 0
  
  minorTicks = [10,4,5,10]-1
  
  ;destroy any inputs via the outputs
  if n_elements(tickValues) gt 0 then begin
    tmp = temporary(tickValues)
  endif
  
  if n_elements(tickInterval) gt 0 then begin
    tmp = temporary(tickInterval)
  endif
  
  ;if the range is too small then return with evenly spaced ticks
  ;this case generally means that all ticks will have the same
  ;value and should not ever happen on normal plots
  if (range_in[1] - range_in[0]) / (numTicks+1) eq 0 then begin
    tickValues = dindgen(numTicks+2)/(numTicks+1)
    tickInterval = 1D/(numTicks+1) 

    return
    
  endif 
     
  range = 10^range_in
      
  ;Calculate the nominal interval near the requested one.    
  realTickIntervalFloor = self->nicenum((range[1]-range[0])/(numTicks+1),/floor,factors=[1,2,5,10],factor_index=factorIndexFloor)
  ;realTickIntervalFloor = self->nicenum((range[1]-range[0])/(numTicks+1),/floor)    
  realTickIntervalCeil = self->nicenum((range[1]-range[0])/(numTicks+1),/ceil,factors=[1,2,5,10],factor_index=factorIndexCeil)
  ;realTickIntervalCeil = self->nicenum((range[1]-range[0])/(numTicks+1),/ceil)
  
  ;Identify the value at which the ticks will start.
  tickStartFloor = ceil(range[0]/realTickIntervalFloor,/l64)*realTickIntervalFloor - range[0]
  ;Identify the value at which the ticks will stop.
  tickStopFloor =  floor(range[1]/realTickIntervalFloor,/l64)*realTickIntervalFloor - range[1]
  
  ;Identify the actual number of ticks that will be drawn.(numTicks is treated as an approximate value.
  realTickNumFloor = round((range[1]-range[0]+tickStopFloor-tickStartFloor)/realTickIntervalFloor + 1,/l64)
  
  ;Identify a nice interval close to the tick interval.
 
  ;Identify the value at which the ticks will start.
  tickStartCeil = ceil(range[0]/realTickIntervalCeil,/l64)*realTickIntervalCeil - range[0]
  ;Identify the value at which the ticks will stop.
  tickStopCeil =  floor(range[1]/realTickIntervalCeil,/l64)*realTickIntervalCeil - range[1]
  
  ;Identify the actual number of ticks that will be drawn.(numTicks is treated as an approximate value.
  realTickNumCeil = round((range[1]-range[0]+tickStopCeil-tickStartCeil)/realTickIntervalCeil + 1,/l64)
  
  if (abs(numTicks-realTickNumCeil) lt abs(numTicks-realTickNumFloor) || $
     (abs(numTicks-realTickNumCeil) eq abs(numTicks-realTickNumFloor) && $ 
    realTickNumCeil gt realTickNumFloor)) && realTickNumCeil gt 0 then begin  
    realTickInterval = realTickIntervalCeil
    tickStart = tickStartCeil
    realTickNum = realTickNumCeil
    factorIndex = factorIndexCeil
  endif else begin
    realTickInterval = realTickIntervalFloor
    tickStart = tickStartFloor
    realTickNum = realTickNumFloor
    factorIndex = factorIndexFloor
  endelse
  
  ;if we don't generate any ticks, lets get out of here
  if ~finite(realTickNum) || realTickNum le 0 then return
    
    
  ;Determine the tick values in range space.
  realTickValues = dindgen(2)*realTickInterval+tickStart
  
  ;relog
  realTickValues = alog10(realTickValues+range[0])
  
  ;Normalize the values for placement on the axis.
  tickValues = (realTickValues-range_in[0])/(range_in[1]-range_in[0])
  tickInterval = tickValues[1]-tickValues[0]
  minorTickNum = minorTicks[factorIndex]

  return 
      
end
