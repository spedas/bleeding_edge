;+
;
;spd_ui_draw_object method: placeMajorTicks
;
;Determines where to place the tick marks for
;an axis, and deals with the various input validation issues
;and positioning options.
;If they are placed automatically,
;They should be at human readable values, if possible.
;In this case human readable means that if the axis
;is non time, the ticks will be at values of
;1*10^n or 2*10^n or 5*10^n where n is some number
;appropriate to the scale of the axis
;If the axis is a time axis the ticks will be at
;1,2,5 * 10^n or 60*1,2,5*10^n or 60*60*1,2,5*10^n or
;24*60*60*1,2,5*10^n  With selection/n dependent on scale
;
;$LastChangedBy: pcruce $
;$LastChangedDate: 2014-06-25 17:47:00 -0700 (Wed, 25 Jun 2014) $
;$LastChangedRevision: 15444 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/spedas_gui/display/draw_object/spd_ui_draw_object__placemajorticks.pro $
;-
pro spd_ui_draw_object::placeMajorTicks, $
                        isTime,$  ;Boolean, is the axis a time axis
                        range, $  ;2 element double precision, axis range(in log space for log axes)
                        scaling, $ ; 0: linear,1: log10,2 logN
                        majorTickAuto, $ ; Boolean, automatically position major ticks? (If this is 0, ticks will not be placed at human readable values)
                        autoTicks,$ ;Boolean whether the automatic tick algorithm should be used or not
                        numMajorTicks, $ ; number of major ticks(only used if autopositioning is on)
                        firstTickAt, $ ; the location of the first tick(only used if autopositioning is off)
                        majorTickSpace, $ ; the space between major ticks(only used if autopositioning is off)
                        majorTickValues=majorTickValues,$ ; the locations of major ticks are returned as an array from this argument
                        majorTickInterval=majorTickInterval,$ ; the final space between ticks
                        minorTickNum=minorTickNum,$ ; the recommended number of minor ticks for this spacing
                        logMinorTickType=logMinorTickType,$ ; needed to make good recommendation on number of minor ticks
                        ticksFixed=ticksFixed,$ ; if we used the non-standard log-spacing, note this so that we can change the annotation style
                        fail=fail  ;Boolean, 1 indicates a failure
          
    
  compile_opt idl2,hidden
          
  fail = 1
  ticksFixed = 0
  
  ;this margin determines whether or not another
  ;tick should be added at the beginning or end to create a full range
  edgeTickMargin = .01
               
  minorTickNum = -1
  
  if numMajorTicks lt 0 then return
  
  if range[1] eq range[0] then return
    
  ;if both firstTick and majorTick are autoscaling
  ;then we use human readable tick algorithm
  if majorTickAuto then begin
  
      self->goodTicks,isTime,$ ;Boolean, is the axis a time axis
                    range, $ ;2 element double precision, axis range(in log space for log axes)
                    scaling, $ ; 0: linear,1: log10,2 logN
                    numMajorTicks, $ ; The recommended number of ticks( 2 or more)
                    tickValues=majorTickValues, $ ; Returns the tick values here
                    tickInterval=majorTickInterval,$ ; Returns the spacing here
                    minorTickNum=minorTickNum,$ ; returns recommended minor tick number here
                    logMinorTickType=logMinorTickType, $  ;needed to make good recommendation on number of minor ticks
                    nicest=keyword_set(autoticks)  ;If this is set, disregards requested number of ticks and tries for best placement
                                                   ;See note in goodticks header, we may be able to deprecate for calls to IDL axis routine with /nodraw set  
     
      ;if we don't have enough ticks on a logarithmic axis
      ;we should correct the ticks, by using logFixTicks to add more, but placed at slightly less regular values.  
      ; (lphilpott 7/15/2011) Modifying condition to also catch case of 0 ticks when 1 was requested. 
      ; Hoping to avoid the problem where x ticks are reduced to 1 initially then 0 on following apply.
      if ((n_elements(majorTickValues) lt 2 && numMajorTicks ge 2) $
         ||(n_elements(majorTickValues) lt 1 && numMajorTicks ge 1)) $
         && scaling eq 1 then begin
      
        self->logFixTicks,$
         range,$
         tickValues=majorTickValues,$
         tickInterval=majorTickInterval,$
         minorTickNum=minorTickNum
          
       ticksFixed = 1
             
      endif
      
      ;this block runs corrections on automatic ticks, if the output is valid.
      ;it guarantees they run slightly passed the edge of the range
      if keyword_set(majorTickValues) && keyword_set(majorTickInterval) then begin     
   
        if majorTickValues[0] gt edgeTickMargin then begin
          majorNewNumLow = floor((majorTickValues[0]-edgeTickMargin)/majorTickInterval,/l64)
          
          if n_elements(majorTickValues) + majorNewNumLow gt self.maxTickNum then begin
            self.statusBar->update,'ERROR:  The current settings will result in the creation of ' + strcompress(string(n_elements(majorTickValues) + majorNewNumLow),/remove_all) + ' major ticks.  Draw operation failed.'
            self.historyWin->update,'ERROR:  The current settings will result in the creation of ' + strcompress(string(n_elements(majorTickValues) + majorNewNumLow),/remove_all) + ' major ticks.  Draw operation failed.'
            return
          endif
          
          majorTickValues = [majorTickValues[0]-(dindgen(majorNewNumLow+1)+1)*majorTickInterval,majorTickValues]
        endif
        
        if majorTickValues[n_elements(majorTickValues)-1] lt (1-edgeTickMargin) then begin
          majorNewNumHigh = floor(((1-edgeTickMargin)-majorTickValues[n_elements(majorTickValues)-1])/majorTickInterval,/l64)
          
          if n_elements(majorTickValues) + majorNewNumHigh gt self.maxTickNum then begin
            self.statusBar->update,'ERROR:  The current settings will result in the creation of ' + strcompress(string(n_elements(majorTickValues) + majorNewNumHigh),/remove_all) + ' major ticks.  Draw operation failed.'
            self.historyWin->update,'ERROR:  The current settings will result in the creation of ' + strcompress(string(n_elements(majorTickValues) + majorNewNumHigh),/remove_all) + ' major ticks.  Draw operation failed.'
            return
          endif
          
          majorTickValues = [majorTickValues,majorTickValues[n_elements(majorTickValues)-1]+(dindgen(majorNewNumHigh+1)+1)*majorTickInterval] 
        endif
      
      endif
   
 endif else begin
    
;   if firstTickAt ge range[1] then begin
;     self.statusBar->update,'First tick at is larger than range, no ticks can be drawn.'
;     self.historywin->update,'First tick at is larget than range, no ticks can be drawn.'
;     return
;   endif
   
   if majorTickSpace le 0 then begin
     self.statusBar->update,'Tick Spacing is less than or equal to 0, no ticks can be drawn.'
     self.historywin->update,'Tick Spacing is less than or equal to 0 , no ticks can be drawn.'
     return
   endif
   
   if majorTickSpace gt (range[1]-range[0]) then begin
     self.statusBar->update,'Tick Spacing is greater than range span, no ticks can be drawn.'
     self.historywin->update,'Tick Spacing is greater than range span, no ticks can be drawn.'
     return
   endif
   
   ;first shift tick start so that it is slightly less than
   ;the min range, but still a multiple of the original value
   if firstTickAt le range[0] then begin
     tickStartNum = floor((range[0] - firstTickAt) / majorTickSpace,/l64)
     tickStart = firstTickAt + tickStartNum*majorTickSpace
   endif else begin
     tickStartNum = floor((firstTickAt - range[0]) / majorTickSpace,/l64) + 1
     tickStart = firstTickAt - tickStartNum*majorTickSpace
   endelse
  
   majorTickNum = floor((range[1] - tickStart) / majorTickSpace,/l64) 
  
   tickStart = (tickStart - range[0]) / (range[1]-range[0])
   majorTickInterval = majorTickSpace / (range[1] - range[0])
   
   if majorTickNum gt self.maxTickNum then begin
     self.statusBar->update,'ERROR:  The current settings will result in the creation of ' + strcompress(string(majorTickNum),/remove_all) + ' major ticks.  Draw operation failed.'
     self.historyWin->update,'ERROR:  The current settings will result in the creation of ' + strcompress(string(majorTickNum),/remove_all) + ' major ticks.  Draw operation failed.'
     return
   endif
   
   majorTickValues = dindgen(majorTickNum+1)*majorTickInterval + tickStart
   
  endelse
  
  if keyword_set(majorTickValues) && keyword_set(majorTickInterval) then begin
  
    idx = where(majorTickValues ge edgeTickMargin and majorTickValues le (1-edgeTickMargin),c)
        
    if c gt 0 then begin
    
      majorTickValues = [0,majorTickValues[idx],1]
   
      ;the old major tick interval could have become invalid when ticks got clipped
      if c eq 1 then begin
        majorTickInterval = max([majorTickValues[1]-majorTickValues[0],majorTickValues[n_elements(majorTickValues)-1]-majorTickValues[n_elements(majorTickValues)-2]])
      endif
    endif else begin
      majorTickValues = [0,1]
      majorTickInterval = 1
    endelse
  endif else begin
    majorTickValues = [0,1]
    majorTickInterval = 1
  endelse
  
  fail = 0
  
   
end
