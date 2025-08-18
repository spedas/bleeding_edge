;+
;
;spd_ui_draw_object method: makeXYAxisModel
;
;Constructs an X or Y axis model from a spd_ui_axis_settings object
;Inputs:
;dir = direction of the axis(0=x,1=y)
;xrange,yrange: data range of the panel
;scaling: scaling mode of the panel 0(linear),1(log10),2(logN)
;axisSettings: axis settings object
;plotDim1: normalized length of the plot on the dimension perpendicual to the axis
;plotDim2: normalized length of the plot on the dimension parallel to the axis
;color: The color of the plot frame in RGB
;thick: The thickness of the plot frame/ticks
;useIsTime: use this keyword to override the current isTime value
;Outputs
;gridmodel: the model containing any axis grids
;model: the axis model is returned in this keyword
;majorTickValues:the major tickvalues are returned in this keyword
;numMinorTicks: the number of minor ticks is returned in this keyword
;isTimeAxis: flag indicating whether the axis is time annotated or not returned in this keyword
;labelPos: this keyword returns the most distant label position from the axis
;fail: 1 indicates failure, 0 success
; 
;$LastChangedBy: pcruce $
;$LastChangedDate: 2014-06-25 17:47:00 -0700 (Wed, 25 Jun 2014) $
;$LastChangedRevision: 15444 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/spedas_gui/display/draw_object/spd_ui_draw_object__makexyaxismodel.pro $
;-

pro spd_ui_draw_object::makeXYAxisModel, $
                                    dir,$
                                    xrange,$
                                    yrange,$
                                    scaling,$
                                    axisSettings,$
                                    plotDim1,$
                                    plotdim2,$
                                    color,$
                                    thick,$
                                    bgcolor,$
                                    useIstime=useIsTime,$
                                    gridmodel=gridmodel,$
                                    model=model,$
                                    majors=majorTickValues,$
                                    minorNum=numMinorTicks,$
                                    isTimeAxis=isTimeAxis,$
                                    labelPos=labelPos,$
                                    fail=fail

  compile_opt idl2,hidden
  
  fail = 1
  
  noMajor = 0
  noMinor = 0
  
  numMinorTicks = 0
  
  ;how close to edge of axis before annotation not drawn
  annotateEdgeMargin = .01
  ;how close to edge of axis before grid not drawn
  gridEdgeMargin = .01 
  
  axisSettings->getProperty,$
    annotateOrientation=annotateOrientation,$
    placeAnnotation=placeAnnotation,$
    annotateAxis=annotateAxis,$
    isTimeAxis=isTimeAxis,$
    annotateMajorTicks=annotateMajorTicks,$
    annotateRangeMin=annotateRangeMin,$
    annotateRangeMax=annotateRangeMax,$
    annotateStyle=annotateStyle,$
    annotateTextObject=annotateTextObject,$
    annotateExponent=annotateExponent,$
    majorTickAuto=majorTickAuto,$
    minorTickAuto=minorTickAuto,$
    firstTickAuto=firstTickAuto,$
    majorLength=majorLength,$
    minorLength=minorLength,$
    bottomPlacement=bottomPlacement,$
    topPlacement=topPlacement,$
    tickStyle=tickStyle,$
    numMajorTicks=numMajorTicks,$
    numMinorTicks=numMinorTicks,$
    lineAtZero=lineAtZero,$
    majorGrid=majorGrid,$
    minorGrid=minorGrid,$
    margin=margin,$
    showLabels=showLabels,$
    labels=labels,$
    orientation=orientation,$
    stackLabels=stackLabels,$
    placeLabel=placeLabel,$
    lazylabels=lazylabels, $
    titleobj=titleobj, $
    subtitleobj=subtitleobj, $
    titleorientation=titleorientation, $
    placetitle=placetitle, $
    titlemargin=titlemargin, $
    showtitle=showtitle, $
    lazytitles=lazytitles, $
    autoTicks=autoTicks,$
    logMinorTickType=logMinorTickType
    
  if n_elements(useIsTime) gt 0 && useIsTime ge 0 then begin
    isTimeAxis = useIsTime
  endif  

  ;don't want division operations 
  ;to fail because of wrong type
  ;so data converted to double explicitly.
  ;(these problems are probably largely gone by now)
  xrange = double(xrange)
  yrange = double(yrange)
  plotdim1 = double(plotdim1)
  
  ; xconv = [-xrange[0]/(xrange[1]-xrange[0]),1./(xrange[1]-xrange[0])]
  ; yconv = [-yrange[0]/(yrange[1]-yrange[0]),1./(yrange[1]-yrange[0])]
  

  
  ;Annotations within a distance of (roundingfactor)*(data range) of zero
  ;will be rounded to zero
  roundingfactor = 1d-15
  ;The height of the axis
  axiszstack = .25D
  ;The height of the grid
  gridzstack = .07D
  ;The height of the line-at-zero
  linezstack = .08D
  ;The height of the annotations
  AnnotationDepth = .05D
  
  ;The basic tick spacing settings with any time based conversions already performed
  tickSpacing = axisSettings->getTickSpacing()
  
  location1 = [0.,0.,axiszstack]
  
  ;The tickConversion determines how much to scale the ticks to
  ;get consistent length even if aspect ratio is not 1:1
  if dir eq 0 then begin
    range = xrange
    location2 = [0.,1.,axiszstack]
    
    tickconversion = 1./(plotdim1[1]-plotdim1[0])
    
  endif else begin
    range=yrange
    location2 = [1.,0.,axiszstack]
    
    tickconversion = 1./(plotdim1[1]-plotdim1[0])
  endelse
  
  ;transform ticklength from pts to data coordinates
  majTicklen = self->pt2norm(majorLength,~dir)*tickConversion
  minTicklen = self->pt2norm(minorLength,~dir)*tickConversion
  
  model = obj_new('IDLgrModel')
  gridmodel = obj_new('IDLgrModel')
  
  ;just a dummy parameter for axis objects
  tickNum = -1

  if ~finite(range[1]) || ~finite(range[0]) then begin
    range = [0D,1D]
  endif

 ; dprint,numMajorTicks

  ;digest all the tick settings and determine major tick positioning
  self->placeMajorTicks,$
    isTimeAxis,$
    range,$
    scaling,$
    majorTickAuto,$
    autoticks,$ 
    numMajorTicks,$
    tickSpacing[0],$
    tickSpacing[1],$
    majorTickValues=majorTickValues,$
    majorTickInterval=tickSpacingMajor,$
    minorTickNum=minorTickNumRecommended,$
    logMinorTickType=logMinorTickType,$
    ticksFixed=ticksFixed,$
    fail=placefail
    
;  if ~keyword_set(tickSpacingMajor) then stop
    
  ;If we fail, don't draw any ticks
  if placefail then begin
    nomajor = 1
    nominor = 1
  endif
  
  numMajorTicks = n_elements(majorTickValues)
 
  ; If autoticks is on and we have a valid recommendation,
  ;use the recommended number of ticks
  if n_elements(minorTickNumRecommended) gt 0 && $
     keyword_set(autoTicks) && $
     minorTickNumRecommended ge 0 then begin
 
     numMinorTicks = minorTickNumRecommended

  endif
    
  if (numMinorTicks + 1) le 0 then begin
    ok = error_message('ERROR:  The current settings will result in the creation of less than or equal to 0 minor ticks. Draw Operation Failed',/center)
    nomajor = 1
    nominor = 1
  endif
  
  if ~nomajor && ~nominor then begin
    tickSpacingMinor = tickSpacingMajor/(numMinorTicks+1)
  endif

  if numMinorTicks eq 0 || nominor eq 1 then begin
    noMinor = 1
  endif else begin
    
    ;minor tick code assumes that the ticks are in order.  But the code to correct the ticks doesn't necessarily produce major ticks as an ordered list
    majorTickValuesForMinors = majorTickValues[bsort(majorTickValues)]
    
    ;make sure we have majors running at least as far as the edges of the axis, even if these ticks are out of range
    ;any out of range minors created with this will be clipped.
    if numMajorTicks gt 2 then begin
    
      if majorTickValuesForMinors[1] - majorTickValuesForMinors[0] lt tickSpacingMajor then begin
    
        majorTickValuesForMinors[0] = majorTickValuesForMinors[1] - tickSpacingMajor 
    
      endif
    
      if numMajorTicks gt 2 && majorTickValuesForMinors[numMajorTicks-1] - majorTickValuesForMinors[numMajorTicks-2] lt tickSpacingMajor then begin
    
        majorTickValuesForMinors[numMajorTicks-1] = majorTickValuesForMinors[numMajorTicks-2] + tickSpacingMajor 
    
      endif
    
      ;Add some extra ticks to ensure there isn't blank on the edge of the panel
    
      majorTickValuesForMinors = [majorTickValuesForMinors[0] - tickSpacingMajor,majorTickValuesForMinors,majorTickValuesForMinors[n_elements(majorTickValuesForMinors)-1]+tickSpacingMajor]
    
    endif
    
    self->makeMinorTicks,range,scaling,numMinorTicks,majorTickValuesForMinors,tickSpacingMajor,logMinorTickType,minorValues=minorTickValues,fail=fail
    
    if fail then begin
      nominor = 1
    endif
  
  endelse
  
  ;this check is probably redundant with other checks.  
  if (n_elements(majorTickValues) gt self.maxTickNum ||  n_elements(minorTickValues) gt self.maxTickNum*2) && (noMinor eq 0 && noMajor eq 0) then begin
    ok = error_message('ERROR:  The current settings will result in the creation of ' + strcompress(string(n_elements(majorTickValues)),/remove_all) + ' major ticks and ' + strcompress(string(n_elements(minorTickValues)),/remove_all) + ' minor ticks.  Draw operation failed.',/center)
    nomajor = 1
    nominor = 1
  endif

  ;Create an axis objects.
  ;Because IDL doesn't allow the degree of control
  ;that the options in the gui spec require. The 
  ;axis is generated by layering several simpler IDLgrAxis
  ;objects on top of each other, and controlling their
  ;settings explicitly so that it gives the appearance of
  ;a single axis.

  ;majorTicks
  if topPlacement then topTickLen = majTickLen else topTickLen = 0.
  
  if bottomPlacement then bottomTickLen = majTickLen else bottomTickLen = 0.
  
  if ~noMajor then begin
  
    ;outside ticks
    if tickStyle eq 1 || tickStyle eq 2 then begin
    
      ;bottom axis
      majorAxis1 = OBJ_NEW('IDLgrAxis',dir,$
        range=[0D,1D],$
        location=location1,$
        color=self->convertColor(color),$
        thick=thick,$
        /exact,$
        /notext,$
        tickLen = bottomTickLen, $
        tickDir=1,$
        minor=0,$
        subticklen=0.0,$
        major=tickNum,$
        tickValues=majorTickValues)
        
      ;top axis
      majorAxis2 = OBJ_NEW('IDLgrAxis',dir,$
        range=[0D,1D],$
        location=location2,$
        color=self->convertColor(color),$
        thick=thick,$
        /exact,$
        /notext,$
        tickLen = topTickLen, $
        tickDir=0,$
        minor=0,$
        subticklen=0.0,$
        major=ticknum,$
        tickValues=majorTickValues)

      model->add,majorAxis1    
      model->add,majorAxis2
      
    endif
    
    ;inside ticks
    if tickStyle eq 0 || tickStyle eq 2 then begin
    
      ;bottom axis
      majorAxis1 = OBJ_NEW('IDLgrAxis',dir,$
        range=[0D,1D],$
        location=location1,$
        color=self->convertColor(color),$
        thick=thick,$
        /exact,$
        /notext,$
        tickLen = bottomTickLen, $
        tickDir=0,$
        minor=0, $
        subticklen=0.0,$
        major=ticknum,$
        tickValues=majorTickValues)
        
      ;top axis
      majorAxis2 = OBJ_NEW('IDLgrAxis',dir,$
        range=[0D,1D],$
        location=location2,$
        color=self->convertColor(color),$
        thick=thick,$
        /exact,$
        /notext,$
        tickLen = topTickLen, $
        tickDir=1,$
        minor=0,$
        subticklen=0.0,$
        major=ticknum,$
        tickValues=majorTickValues)
        
      model->add,majorAxis1
      
      model->add,majorAxis2
      
    endif
  endif else begin ;no major ticks
  
    ;bottom axis
    majorAxis1 = OBJ_NEW('IDLgrAxis',dir,$
      range=[0D,1D],$
      location=location1,$
      color=self->convertColor(color),$
      thick=thick,$
      subticklen=0.0,$
      /exact,$
      /notext,$
      minor=0,$
      major=0)
      
    ;top axis
    majorAxis2 = OBJ_NEW('IDLgrAxis',dir,$
      range=[0D,1D],$
      location=location2,$
      color=self->convertColor(color),$
      thick=thick,$
      /exact,$
      /notext,$
      subticklen=0.0,$
      minor=0,$
      major=0)
      
    model->add,majorAxis1
    
    model->add,majorAxis2
    
  endelse
  
   ;minorTicks
  
  if topPlacement then topTickLen = minTickLen else topTickLen = 0.
  
  if bottomPlacement then bottomTickLen = minTickLen else bottomTickLen = 0.
  
  if ~noMinor then begin
  
    ;outside ticks
    if tickStyle eq 1 || tickStyle eq 2 then begin
    
      ;bottom axis
      minorAxis1 = OBJ_NEW('IDLgrAxis',dir,$
        range=[0D,1D],$
        location=location1,$
        color=self->convertColor(color),$
        thick=thick,$
        /exact,$
        /notext,$
        tickLen = bottomTickLen, $
        tickDir=1,$
        minor=0,$
        subticklen=0.0,$
        major=ticknum,$
        tickValues=minorTickValues)
        
      ;top axis
      minorAxis2 = OBJ_NEW('IDLgrAxis',dir,$
        range=[0D,1D],$
        location=location2,$
        color=self->convertColor(color),$
        thick=thick,$
        /exact,$
        /notext,$
        tickLen = topTickLen, $
        tickDir=0,$
        minor=0,$
        subticklen=0.0,$
        major=ticknum,$
        tickValues=minorTickValues)
      
      model->add,minorAxis1
      model->add,minorAxis2
      
    endif
    
    ;inside ticks
    if tickStyle eq 0 || tickStyle eq 2 then begin
    
      ;minorTickValues = minorTickValues[0:n_elements(minorTickValues)-3]
    
      ;bottom axis
      minorAxis1 = OBJ_NEW('IDLgrAxis',dir,$
        range=[0D,1D],$
        location=location1,$
        color=self->convertColor(color),$
        thick=thick,$
        /exact,$
        /notext,$
        tickLen = bottomTickLen, $
        tickDir=0,$
        minor=0, $
        subticklen=0.0,$
        major=ticknum,$
        tickValues=minorTickValues,$
        log=log)
        
      ;top axis
      minorAxis2 = OBJ_NEW('IDLgrAxis',dir,$
        range=[0D,1D],$
        location=location2,$
        color=self->convertColor(color),$
        thick=thick,$
        /exact,$
        /notext,$
        tickLen = topTickLen, $
        tickDir=1,$
        minor=0,$
        subticklen=0.0,$
        major=ticknum,$
        tickValues=minorTickValues)
        
      model->add,minorAxis1
;      
      model->add,minorAxis2
      
    endif
  endif
  
  ;perform annotation on Axis
  if annotateAxis then begin
  
    noAnno = 0
  
    if range[1] eq range[0] && ~annotateMajorTicks then begin
      self.statusBar->update,'Max and Min range are the same: Annotating major ticks.'
      self.historyWin->update,'Max and Min range are the same: Annotating major ticks.'
      annotateMajorTicks=1
    endif
  
    if annotateMajorTicks then begin
      if ~noMajor then begin
        majorAxis1->getProperty,tickValues=annotateValues
      endif else begin
        noAnno = 1
        annotateValues = [0,1]
        self.historyWin->update,'Cannot annotate major ticks, because no major ticks being drawn'
      endelse
    endif else begin
    
    
      if tickSpacing[3] gt range[1] then begin
        self.statusBar->update,'"Align Annotations At:" is larger than maximum range.  No annotations will be drawn.'
        self.historyWin->update,'"Align Annotations At:" is larger than maximum range.  No annotations will be drawn.'
        annotateValues = [0,1]
        noAnno = 1
      endif else if tickSpacing[4] le 0 then begin
        self.statusBar->update,'"Annotate Every" is less than 0.  No annotations will be drawn.'
        self.historyWin->update,'"Annotate Every" is less than 0.  No annotations will be drawn.'
        annotateValues = [0,1]
        noAnno = 1
      endif else if tickSpacing[4] gt (range[1]-range[0]) then begin
        self.statusBar->update,'"Annotate Every" is greater than range span.  No annotations will be drawn.'
        self.historyWin->update,'"Annotate Every" is greater than range span.  No annotations will be drawn.'
        annotateValues = [0,1]
        noAnno = 1
      endif else begin

        annotateStart = tickSpacing[3]
        annotateInterval = tickSpacing[4]
  
        ;first shift annotate start so that it is slightly less than
        ;the min range, but still a multiple of the original value
        if annotateStart lt range[0] then begin
        
          annotateStartNum = floor((range[0] - annotateStart) / annotateInterval,/l64)
          annotateStart += annotateStartNum*annotateInterval
        
        endif else begin
          annotateStartNum = floor((annotateStart - range[0]) / annotateInterval,/l64) + 1
          annotateStart -= annotateStartNum*annotateInterval
        endelse
   
        annotateNum = floor((range[1] - annotateStart) / annotateInterval,/l64)
        
        ;normalize values
        annotateStart = (annotateStart - range[0]) / (range[1]-range[0])
        annotateInterval = annotateInterval/(range[1]-range[0])
         
        if annotateNum gt self.maxTickNum then begin
          self.statusBar->update,'ERROR:  The current settings will result in the creation of ' + strcompress(string(annotateNum),/remove_all) + ' annotations.  Draw operation failed.'
          self.historyWin->update,'ERROR:  The current settings will result in the creation of ' + strcompress(string(annotateNum),/remove_all) + ' annotations.  Draw operation failed.'
          return
        endif
        
        annotateValues = dindgen(annotateNum + 2) * annotateInterval + annotateStart
                
        idx = where(annotateValues ge annotateEdgeMargin and annotateValues le (1-annotateEdgeMargin),c)
        
        if c gt 0 then begin
          annotateValues = [0,annotateValues[idx],1]
        endif else begin
          annotateValues = [0,1]
        endelse
        
      endelse  
          
    endelse
    
    if ~annotateRangeMax && ~noAnno then begin
      if n_elements(annotateValues) eq 1 then begin
        noAnno = 1
      endif else begin
        annotateValues = annotateValues[0:n_elements(annotateValues)-2]
      endelse
    endif
  
    if ~annotateRangeMin && ~noAnno then begin
      if n_elements(annotateValues) eq 1 then begin
        noAnno = 1
      endif else begin
        annotateValues = annotateValues[1:*]
      endelse
    endif
    
    if ~noAnno then begin
    
      ;Check if there are too many annotations.
      if n_elements(annotateValues) gt self.maxTickNum then begin
        ok = error_message('ERROR:  The current settings will result in the creation of ' + strcompress(string(n_elements(annotateValues)),/remove_all) + ' annotations.  Draw operation failed.',/center)
        return
      endif
      
      data = {timeAxis:isTimeAxis,formatid:AnnotateStyle,scaling:scaling,range:range,exponent:annotateExponent,maxexplen:-1,negexp:0}
      
      if placeAnnotation eq 1 then begin
        annoPos = 1
      endif else begin
        annoPos = 0
      endelse
      
      if tickStyle eq 1 || tickStyle eq 2 then begin
        AnnoColor = bgcolor ; the color to draw the axis so that it won't be visible
        ;we draw real but invisible ticks so that the annotations will be shifted out of the way of collision with the ticks
        if placeAnnotation eq 1 then begin
          AnnoDir = 0
          AnnoLoc = location2
          AnnoLen = topTickLen
        endif else begin
          AnnoDir = 1
          AnnoLoc = location1
          AnnoLen = bottomTickLen
        endelse
      endif else if tickStyle eq 0 then begin
        AnnoColor = color
        AnnoLen = 0 ;when ticks are only on the inside, ticklength can be 0, because there is no need to shift the annotations down.w
        if placeAnnotation eq 1 then begin
          AnnoDir = 1
          AnnoLoc = location2
        endif else begin
          AnnoDir = 0
          AnnoLoc = location1
        endelse
      endif else begin
        self.statusBar->update,'Error: Illegal tickstyle'
        ;ok = error_message('Illegal tickstyle',/traceback)
        return
      endelse
      
      if annotateOrientation eq 1 then begin
        annoBaseLine = [0,1,0]
        annoUpDir = [-1,0,0]
        if dir eq 1 then begin
          if annoPos eq 0 then begin
            annoAlign = [.5,0.]
          endif else begin
            annoAlign = [.5,1.]
          endelse
        endif else begin
          if AnnoPos eq 0 then begin
            annoAlign = [1.,.5]
          endif else begin
            annoAlign = [0.,.5]
          endelse
        endelse
      endif else begin
        annoBaseLine = [1,0,0]
        annoUpDir = [0,1,0]
      ;annoAlign = [1.,-.5]
      endelse
      
      labFont = annotateTextObject->getGrFont()
      
      annoLoc[2] = AnnotationDepth
      
      annotateTextObject->getProperty,color=labcolor,size=size
      
      if size le 0 then begin
        size = 1D
        fontshow = 0
      endif else begin
        fontshow = 1
      endelse
      
      labFont->setProperty,size=self->getZoom()*size
      
      ; labFont->setProperty,size=self->getZoom()*size
      
      
      if ticksFixed && data.exponent eq 0 then begin ; lphilpott 27-feb-2012 changed to check whether autonotation is set so that if user has set to decimal it remains set to decimal
        data.exponent = 2   
      ;determine is any ticks are going to be auto-shifted into exponential
      ;if yes, make them all exponential, this guarantees that any annotations
      ;on a particular axis will use the same size
      endif else if ~isTimeAxis && data.exponent eq 0 && (scaling eq 0 || scaling eq 1) then begin
        for i = 0,n_elements(annotateValues)-1 do begin
        
          if data.range[1]-data.range[0] eq 0 then begin
            val = data.range[0]
          endif else begin
            val = (annotateValues[i] + data.range[0]/(data.range[1]-data.range[0]))*(data.range[1]-data.range[0])
              relativecuttoff = (data.range[1]-data.range[0])*roundingfactor
              if val le relativecuttoff && val ge -relativecuttoff then begin
                val = 0
              endif
          endelse
          
          if scaling eq 1 then begin
            val = 10^val
          endif
          
          ;putting log axes into b^x when auto-generated tick placement is used
          ;With flexible auto-placement on log axes, the numbers look very odd if not in exponential format
          ;Shouldn't be a problem, because log scaling is all about orders of magnitude and user can still over-ride
          ;This is a pretty specific case, but since it is a default, it is worth a special rule, IMO.
          if scaling ne 0 && data.exponent eq 0 && majorTickAuto && annotateMajorTicks then begin
            if scaling eq 1 then begin
              data.exponent= 2
            endif else begin ;scaling eq 2
              data.exponent= 3
            endelse
          endif else begin
          
            ;Normal annotation selection method
            spd_ui_usingexponent,val,data,type=type
          
            if type ne 0 && scaling eq 0 then begin
              data.exponent = 2
              break
            endif else if type ne 0 && scaling eq 1 then begin
              data.exponent = 3
              break
            endif
          endelse
        endfor
      endif

      ; Attempt to line up annotations (simply using left-align doesn't work) - lphilpott 28-june-2012
      ; check through all annotations first to determine maximum exponent length, and whether any exponents are negative
      if ~isTimeAxis && data.exponent ne 1 then begin;don't check for time axis or decimal format
        negexp = 0; this should end up 1 if any of the exponents are negative 
        maxexplen = 0; max number of characters in exponent
        for i = 0,n_elements(annotateValues)-1 do begin
          axistmp='';both axis and index are required but ignored by formatannotation
          indextmp=''
          annotation=formatannotation(axistmp,indextmp,annotateValues[i],data=data)
          ; exponents are preceded by !U
          ;confirm there is an exponent
          exppos = strpos(annotation,'!U');what about noformatcodes?
          if exppos ne -1 then begin
            expstr = strmid(annotation,exppos+2)
            explen = strlen(expstr)
            if explen gt maxexplen then begin
              maxexplen = explen
            endif
            negstr = strmid(expstr,0,1)
            if negstr eq '-' then negexp = 1
          endif
        endfor
        data.maxexplen = maxexplen
        data.negexp = negexp
      endif
      annaxis = OBJ_NEW('IDLgrAxis',dir,$
        range=[0D,1D],$
        location=AnnoLoc,$
        alpha_channel = 1.0,$
        thick=thick,$
        color=AnnoColor,$
        /exact,$
        tickLen = AnnoLen, $
        tickDir=AnnoDir,$
        textPos=AnnoPos,$
        minor=0,$
        subticklen=0.0,$
        major=-1,$
        tickValues=annotateValues,$
        /use_text_color, $
        tickfrmtdata=data,$
        tickformat='formatannotation',$
        textBaseline=annoBaseLine,$
        textupdir=annoUpDir,$
        textAlignments=annoAlign)
        
        
      annaxis->getProperty,tickText=tickObj
      
      tickObj->setProperty,font=labFont,color=self->convertColor(labcolor),alpha_channel=1.0,hide=~fontshow,/enable_formatting
      
      model->add,annaxis
      
    endif
  endif
  
 
  
  ;draw lineatzero
  if lineatzero && $
    0. gt range[0] && $
    0. lt range[1] then begin
    
    if dir eq 0 then begin
      locationx = replicate((0-range[0])/(range[1]-range[0]),2)
      locationy = [0D,1D]
    endif else begin
      locationx = [0D,1D]
      locationy = replicate((0-range[0])/(range[1]-range[0]),2)
    endelse
    
    locationz = [linezstack,linezstack]
    
    line = obj_new('IDLgrPolyline',locationx,locationy,locationz,$
      color = self->convertColor([0,0,0]),/double)
      
    model->add,line
    
  endif
  
  majorGridShow = 0 ; needed to generate minor grid
  
  ;add major grid lines
  if obj_valid(majorGrid) && obj_isa(majorgrid,'spd_ui_line_style') && ~noMajor then begin
    majorGrid->getProperty,id=gridstyle,$
      color=gridcolor,$
      show=majorgridshow,$
      thickness=gridthick,$
      opacity=opacity
      
      
    if majorgridshow && range[1] ne range[0] then begin
      ;get tick values, (may have been automatically set)
      tickValues = majorTickValues
      normGridThick = self->pt2norm(gridthick,dir)/(2D*(plotDim2[1]-plotDim2[0]))
      
      if n_elements(tickValues) gt 1 then begin
        for i = 1,n_elements(tickvalues)-1 do begin
          if dir eq 0 then begin
            gridx = [tickvalues[i],tickvalues[i]]
            gridy = [0D,1D]  
          endif else begin
            gridx = [0D,1D]
            gridy = [tickvalues[i],tickvalues[i]]      
          endelse
          
          ;it looks bad if you draw grid lines on top of frame
          if tickvalues[i] lt 0+gridEdgeMargin || tickvalues[i] gt 1-gridEdgeMargin then begin
            lineshow=0
          endif else begin
            lineshow=1
          endelse
          
          gridz = [gridzstack,gridzstack]
          
          if lineshow then begin
          
            gridline = obj_new('IDLgrPolyline',$
              gridx,gridy,gridz,alpha=opacity,$
              linestyle=gridstyle,thick=gridthick,$
              color=self->convertColor(gridColor),/double)
              
            gridmodel->add,gridline
          ;model->add,gridline
          endif
        endfor
      endif
    endif
  endif
  
  ;minor grid
  if obj_valid(minorGrid) && obj_isa(minorgrid,'spd_ui_line_style') && ~noMinor then begin
    minorGrid->getProperty,id=gridstyle,$
      color=gridcolor,$
      show=gridshow,$
      thickness=gridthick,$
      opacity=opacity
      
    if gridshow && range[1] ne range[0] then begin
      ;get tick values, (may have been automatically set)
      ;axis1->getProperty,tickValues=tickValues
    
      tickValues = minorTickValues
      
      for i = 0,n_elements(tickvalues)-1 do begin
      
        ;don't draw minor grids on major grids, if majorGrids are drawn
        if n_elements(majorTickValues) gt 0 && majorGridShow then begin
          val = min(abs(majorTickValues - tickvalues[i]))
          
          if val lt .01 then continue
          
        endif
        
        if dir eq 0 then begin
          gridx = [tickvalues[i],tickvalues[i]]
          gridy = [0D,1D]   
        endif else begin
          gridx = [0D,1D]
          gridy = [tickvalues[i],tickvalues[i]]
        endelse
        
        ;it looks bad if you draw grid lines on top of frame
        if tickvalues[i] lt 0+gridEdgeMargin || tickvalues[i] gt 1-gridEdgeMargin then begin
          lineshow=0
        endif else begin
          lineshow=1
        endelse
        
        gridz = [gridzstack,gridzstack]
        
        if lineshow then begin
          gridline = obj_new('IDLgrPolyline',$
            gridx,gridy,gridz,alpha=opacity,$
            linestyle=gridstyle,thick=gridthick,$
            xcoord_conv=xconv,ycoord_conv=yconv,$
            color=self->convertColor(gridColor),/double)
            
          gridmodel->add,gridline
        ;model->add,gridline
        endif
      endfor
    endif
  endif
  
  ; axis label

  axisSettings->getProperty,blacklabels=blacklabels
  
  self->addAxisLabels,model,labels,margin,placeLabel,dir,orientation,stacklabels,showlabels,self->pt2norm(1.,~dir)/(plotDim1[1]-plotDim1[0]),self->pt2norm(1.,dir)/(plotDim2[1]-plotDim2[0]),lazylabels,blacklabels,labelPos=labelPos
  
  self->addAxisTitle,model,titleobj,subtitleobj,titlemargin,placetitle,dir, titleorientation, showtitle,self->pt2norm(1.,~dir)/(plotDim1[1]-plotDim1[0]),self->pt2norm(1.,dir)/(plotDim2[1]-plotDim2[0]), lazytitles
  fail = 0
  
end
