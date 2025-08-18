;+
;
;spd_ui_draw_object method: goodTicks
;
;
;This routine actually does the bulk of the work
;to select good ticks. 
;
;NOTE:  Now that we've switched over to a set of user input parameters that maps
;  pretty nearly to the set of options that IDL provides, we might want to do 
;  tick placement by lookup with IDL plotting routines and /nodraw.
;  We just need to be VERY careful about interaction/interference with command line utilities
;
;$LastChangedBy: pcruce $
;$LastChangedDate: 2014-06-25 17:47:00 -0700 (Wed, 25 Jun 2014) $
;$LastChangedRevision: 15444 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/spedas_gui/display/draw_object/spd_ui_draw_object__goodticks.pro $
;-
pro spd_ui_draw_object::goodTicks,$
                        isTime,$ ;Boolean, is the axis a time axis
                        range, $ ;2 element double precision, axis range(in log space for log axes)
                        scaling, $ ; 0: linear,1: log10,2 logN
                        numTicks, $ ; The recommended number of ticks( 2 or more)
                        tickValues=tickValues, $ ; Returns the tick values here
                        tickInterval=tickInterval,$ ; Returns the spacing here
                        minorTickNum=minorTickNum,$ ; Returns recommended number of minor Ticks
                        logMinorTickType=logMinorTickType, $  ;needed to make good recommendation on number of minor ticks
                        nozero=nozero,$ ; set this keyword to guarantee there are never 0 ticks
                        nicest=nicest ;set this keyword to mostly disregard requested # of ticks

  compile_opt idl2,hidden

  minorTickNum = -1
  if keyword_set(nicest) then begin
    numTicks=5
  endif

  ;These values are output only, prevents previous iterations from interacting.
  if n_elements(tickValues) gt 0 then begin
    tmp = temporary(tickValues)
  endif
  
  if n_elements(tickInterval) gt 0 then begin
    tmp = temporary(tickInterval)
  endif

  ;if the range is too small then return with evenly spaced ticks
  ;this case generally means that all ticks will have the same
  ;value and should not ever happen on normal plots
  if (range[1] - range[0]) / (numTicks+1) eq 0 then begin
  
    tickValues = dindgen(numTicks+2)/(numTicks+1)
    tickInterval = 1D/(numTicks+1) 

    return
    
  endif 

  ;the different factors that might be used for different nicenum calls
  ;and the number of minor ticks that are recommended for each outcome
  ;

  if ~isTime then begin

    if ~keyword_set(nicest) then begin
      ;More flexible nicenum placement for log and large numbers of ticks
      factors =    [5,10,15,20,25,30,35,40,45,50,55,60,65,70,75,80,85,90,95,100] 
      minorTicks = [5,10,15,2, 5, 3 ,7 ,4 ,9 ,5 ,5 ,6 ,6 ,7 ,7 ,8 ,8 ,9 ,9 ,10]-1
      ticksbias=1
      
    endif else begin
  ;  
      factors = [1D,2D,5D,10]
      minorTicks = [10,4,5,10]-1
  
      ticksbias=0
      
    endelse
    
    realTickIntervalFloor = self->nicenum((range[1]-range[0])/(numTicks+1),/floor,factors=factors,factor_index=factorIndexFloor,bias=ticksBias)
    realTickIntervalCeil = self->nicenum((range[1]-range[0])/(numTicks+1),/ceil,factors=factors,factor_index=factorIndexCeil,bias=ticksBias)
    
  endif else begin

    minorTicks = [10,4,3,6,10]-1
    factors = [1D,2D,3D,6D,10D]
    ticksBias=0
    
    ;This algorithm finds the closest nicenum below the input(floor) 
    ;and the closest nicenum above the input(ceil), then
    ;makes its own determinations about which is closest
    realTickIntervalFloor = self->nicenumtime((range[1]-range[0])/(numTicks+1),/floor,factors=factors,factor_index=factorIndexFloor,bias=ticksBias)
    realTickIntervalCeil = self->nicenumtime((range[1]-range[0])/(numTicks+1),/ceil,factors=factors,factor_index=factorIndexCeil,bias=ticksBias)
    
  endelse
  


    
  ;Identify the value at which the ticks will start.
  tickStartFloor = ceil(range[0]/realTickIntervalFloor,/l64)*realTickIntervalFloor - range[0]
  ;Identify the value at which the ticks will stop.
  tickStopFloor =  floor(range[1]/realTickIntervalFloor,/l64)*realTickIntervalFloor - range[1]
  
  ;Identify the actual number of ticks that will be drawn.(numTicks is treated as an approximate value.)
  realTickNumFloor = round((range[1]-range[0]+tickStopFloor-tickStartFloor)/realTickIntervalFloor + 1,/l64)
  
  ;Identify a nice interval close to the tick interval.
 
  
  ;Identify the value at which the ticks will start.
  tickStartCeil = ceil(range[0]/realTickIntervalCeil,/l64)*realTickIntervalCeil - range[0]
  ;Identify the value at which the ticks will stop.
  tickStopCeil =  floor(range[1]/realTickIntervalCeil,/l64)*realTickIntervalCeil - range[1]
  
  ;Identify the actual number of ticks that will be drawn.(numTicks is treated as an approximate value.
  realTickNumCeil = round((range[1]-range[0]+tickStopCeil-tickStartCeil)/realTickIntervalCeil + 1,/l64)
  
  
  ;select the winning parameters for output.
  ;This is based upon whether the floor or ceil is closest
  
  if ~keyword_set(nozero) then begin
   if abs(numTicks-realTickNumCeil) lt abs(numTicks-realTickNumFloor) || $
     (abs(numTicks-realTickNumCeil) eq abs(numTicks-realTickNumFloor) && $
      realTickNumCeil gt realTickNumFloor) then begin
      realTickInterval = realTickIntervalCeil
      tickStart = tickStartCeil
      realTickNum = realTickNumCeil
      minorTickNum = minorTicks[factorIndexCeil]
    endif else begin
      realTickInterval = realTickIntervalFloor
      tickStart = tickStartFloor
      realTickNum = realTickNumFloor
      minorTickNum = minorTicks[factorIndexFloor]
    endelse
  endif else begin
   if (abs(numTicks-realTickNumCeil) lt abs(numTicks-realTickNumFloor) || $
     (abs(numTicks-realTickNumCeil) eq abs(numTicks-realTickNumFloor) && $ 
     realTickNumCeil gt realTickNumFloor)) && realTickNumCeil gt 0 then begin  
      realTickInterval = realTickIntervalCeil
      tickStart = tickStartCeil
      realTickNum = realTickNumCeil
      minorTickNum = minorTicks[factorIndexCeil]
    endif else begin
      realTickInterval = realTickIntervalFloor
      tickStart = tickStartFloor
      realTickNum = realTickNumFloor
      minorTickNum = minorTicks[factorIndexFloor]
    endelse
  
  endelse
  
  ;There are not logical interrim values for a natural log axis.
  ;So one tick is used
  if scaling eq 2 then begin
    minorTickNum = 1
  endif
  
  ;if we're using minor ticks that don't cover the full interval our recommended minor tick number may be bad for intervals greater than one order of magnitude
  if scaling eq 1 && keyword_set(logMinorTickType) then begin
    if logMinorTickType eq 1 || logMinorTickType eq 2 then begin
      if realTickInterval gt 1 then begin
        minorTickNum = 9 ;if we're only drawing minor ticks for one order of magnitude, pick minor tick number appropriate for single order, even if major ticks have larger spacing
      endif
    endif
  endif
      
  ;if we don't generate any ticks, lets get out of here
  if ~finite(realTickNum) || realTickNum le 0 then return
  
  if realTickNum gt self.maxTickNum then begin
    self.statusBar->update,'ERROR:  The current settings will result in the creation of ' + strcompress(string(realTickNum),/remove_all) + ' major ticks.  Draw operation failed.'
    self.historyWin->update,'ERROR:  The current settings will result in the creation of ' + strcompress(string(realTickNum),/remove_all) + ' major ticks.  Draw operation failed.'
    return
  endif
    
  ;Determine the tick values in range space.
  realTickValues = dindgen(realTickNum)*realTickInterval+tickStart
  
  ;Normalize the values for placement on the axis.
  tickValues = realTickValues/(range[1]-range[0])
  tickInterval = realTickInterval/(range[1]-range[0])

  return 

end
