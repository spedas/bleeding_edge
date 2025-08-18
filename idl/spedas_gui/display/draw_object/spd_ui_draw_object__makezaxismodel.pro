;+
;
;spd_ui_draw_object method: makeZAxisModel
;
;constructs a zaxis model for display, from a spd_ui_zaxis_settings object
;
;Inputs:
;  zrange(2 element double):  The min & max range of the axis in logged space.
;  zAxis(object reference):  The spd_ui_zaxis_settings object from which settings will be drawn.
;  xPlotPos(2 element double):  The x-start & stop position of the panel in draw area normal coordinates
;  yPlotPos(2 element double):  The y-start & stop position of the panel in draw area normal coordinates
;  frameColor(3 element bytarr):  The rgb color of the panel frame.
;  frameThick(double):  the thickness of the panel frame, in idl standard line thickness units
;  
;Outputs:
;  model(object reference):  The completed IDLgrModel
;  palette(object reference): The palette object used for this axis.
;  majorNum(long):  The number of major ticks on this axis.
;  minorNum(long):  The number of minor ticks per major tick on this axis
;
;$LastChangedBy: aaflores $
;$LastChangedDate: 2014-06-27 11:32:10 -0700 (Fri, 27 Jun 2014) $
;$LastChangedRevision: 15454 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/spedas_gui/display/draw_object/spd_ui_draw_object__makezaxismodel.pro $
;-
pro spd_ui_draw_object::makeZAxisModel,zrange,zAxis,xplotpos,yplotpos,framecolor,framethick,model=model,palette=palette,majorNum=majorTickNum,minorNum=minorTickNum

  compile_opt idl2,hidden
  
  ;This constant determines how close an automatic
  ;major tick must be to the edge of the axis before it is removed
  edgeTickMargin = .01
  
  ;Annotations within a distance of (roundingfactor)*(data range) of zero
  ;will be rounded to zero
  roundingfactor = 1d-15
  ;This determines how high the axis model will be placed in the layering
  zstack = .1
  ;This is thickness of the axis in points
  thick = 10
  ;Reseting the number of ticks to null value
  majorTickNum = 0
  minorTickNum = 0
  
  zAxis->getProperty, $
    tickNum=majorTickNum, $
    minorTickNum=minorTickNum,$
    annotationStyle=annotationStyle, $
    annotateTextObject=annotateTextObject, $
    annotationOrientation=annotationOrientation,$
    annotateExponent=annotateExponent,$
    labelTextObject=labelTextObject,$
    subtitleTextObject=subtitleTextObject,$
    labelOrientation=labelOrientation,$
    labelMargin=labelMargin,$
    lazylabels=lazylabels,$
    scaling=scaling,$
    placement=placement,$
    margin=margin,$
    autoTicks=autoTicks,$
    logMinorTickType=logMinorTickType
    
  ;If autoticks is set, we aim for 5 major ticks
;  if keyword_set(autoTicks) then begin
;  
;    majorTickNum = 5
;  
;  endif
    
  ; minorTickNum = 3
    
  model = obj_new('IDLgrModel')
  
  palette = obj_new('IDLgrPalette')
  
  ;lookup the color table from the hard-drive
  getctpath,colortablepath
  
  ;load the color table
  palette->loadCt,zAxis->getColorTableNumber(),file=colortablepath
  
  ;This next block determines the position and dimensions of the axis
  ;The specific meaning of the variables in each if varies because orientation changes.
  ;generally, marginNorm1, is the distance from the x/y axis to the near side of the z-axis, in draw-area normal coordinates
  ;           marginNorm2, is the distance from the x/y axis to the far  side of the z-axis, in draw-area normal coordinates
  ;pt1-4 are each corners of the axis
  
  if placement eq 0 then begin ; top
  
    marginNorm1 = self->pt2Norm(margin,1)
    marginNorm2 = self->pt2Norm(margin+thick,1)
    
    pt1 = [0.,1. + marginNorm1/(yplotpos[1]-yplotpos[0]),zstack]
    pt2 = [1.,1. + marginNorm1/(yplotpos[1]-yplotpos[0]),zstack]
    pt3 = [1.,1. + marginNorm2/(yplotpos[1]-yplotpos[0]),zstack]
    pt4 = [0.,1. + marginNorm2/(yplotpos[1]-yplotpos[0]),zstack]
    
    location = pt1
    xsize = pt3[0]-pt1[0]
    ysize = pt3[1]-pt1[1]
    
  endif else if placement eq 1 then begin ; bottom
  
    marginNorm1 = self->pt2Norm(margin,1)
    marginNorm2 = self->pt2Norm(margin+thick,1)
    
    pt1 = [0.,0. - marginNorm1/(yplotpos[1]-yplotpos[0]),zstack]
    pt2 = [1.,0. - marginNorm1/(yplotpos[1]-yplotpos[0]),zstack]
    pt3 = [1.,0. - marginNorm2/(yplotpos[1]-yplotpos[0]),zstack]
    pt4 = [0.,0. - marginNorm2/(yplotpos[1]-yplotpos[0]),zstack]
    
    location = pt4
    xsize = pt4[0]-pt2[0]
    ysize = pt4[1]-pt2[1]
    
  endif else if placement eq 2 then begin ; left
  
    marginNorm1 = self->pt2Norm(margin,0)
    marginNorm2 = self->pt2Norm(margin+thick,0)
    
    pt1 = [0. - marginNorm1/(xplotpos[1]-xplotpos[0]),0.,zstack]
    pt2 = [0. - marginNorm1/(xplotpos[1]-xplotpos[0]),1.,zstack]
    pt3 = [0. - marginNorm2/(xplotpos[1]-xplotpos[0]),1.,zstack]
    pt4 = [0. - marginNorm2/(xplotpos[1]-xplotpos[0]),0.,zstack]
    
    location = pt4
    xsize = pt4[0]-pt2[0]
    ysize = pt4[1]-pt2[1]
    
  endif else if placement eq 3 then begin ;right
  
    marginNorm1 = self->pt2Norm(margin,0)
    marginNorm2 = self->pt2Norm(margin+thick,0)
    
    pt1 = [1. + marginNorm1/(xplotpos[1]-xplotpos[0]),0.,zstack]
    pt2 = [1. + marginNorm1/(xplotpos[1]-xplotpos[0]),1.,zstack]
    pt3 = [1. + marginNorm2/(xplotpos[1]-xplotpos[0]),1.,zstack]
    pt4 = [1. + marginNorm2/(xplotpos[1]-xplotpos[0]),0.,zstack]
    
    location = pt1
    xsize = pt3[0]-pt1[0]
    ysize = pt3[1]-pt1[1]
    
  endif else begin
  
    return
    
  endelse
  
  ;If we are not using a postscript,
  ;The axis is modeled as a texture mapped polygon.  
  
  if ~keyword_set(self.postscript) then begin
  
    ; if 0 then begin
    poly = obj_new('IDLgrPolygon')
  
    image = obj_new('IDLgrImage',indgen(1,256),palette=palette)
    
    poly->setProperty,data=[[pt1],[pt2],[pt3],[pt4]],texture_map = image,texture_coord=[[0,0],[0,1],[1,1],[1,0]],/texture_interp,color=self->convertColor([255,255,255]),/double
    
  endif else begin
  
    ;Since postscript does not properly render texture mapped polygons, we use a static image and control layering using order.
    poly = obj_new('IDLgrImage',indgen(1,256),palette=palette,location=location,dimensions=[xsize,ysize],depth_test_disable=2)
    
  endelse
  
  ;now create axis
  
  if majorTickNum lt 0 then begin
  
    self.statusBar->update,'Illegal negative z axis major tick number, using 0 ticks'
    self.historyWin->update,'Illegal negative z axis major tick number, using 0 ticks'
    majorTickNum = 0
    
  endif
  
 
  ;this is a bit of a kluge to deal with the
  ;case of a logarithmic z-axis with only 0 values
  ;To fix this we treat it as 0,0 range in log space([1,1] in normal)
  if finite(zrange[0],/infinity,sign=-1) && $
     finite(zrange[1],/infinity,sign=-1) && $
     (scaling eq 1 || scaling eq 2) then begin
     
     scaling = 0
     zrange = [0D,0D]    
 
  endif
 
  ;If there are no finite values we go to a default range
  if ~finite(zrange[0]) || ~finite(zrange[1]) then begin
    zrange = [0D,1D]
  endif
  
  ;Now determine major tick position
  if majorTickNum gt 0 then begin
  
    ;First try human readable tick algorithm
    self->goodTicks,0,zrange,scaling,majorTickNum, $
                  tickValues=tickValues,tickInterval=tickInterval,$
                  /nozero,minorTickNum=minorTickNumRecommended,$
                  nicest=keyword_set(autoticks),$
                  logMinorTickType=logMinorTickType
         

    ;if we don't have enough ticks on a logarithmic axis
    ;we should correct the ticks, by using logFixTicks to add more, but placed at slightly less regular values.  
    if n_elements(tickValues) lt 2 && $
       majorTickNum ge 2 && $
       scaling eq 1 then begin
    
      self->logFixTicks,$
        zrange,$
        tickValues=tickValues,$
        tickInterval=tickInterval,minorTickNum=minorTickNumRecommended
        
      ticksFixed = 1
       
    endif

    ;If available and not overriden by user settings,
    ;we use the recommended tick number, which should be appropriate for tick spacing. 
    if keyword_set(autoticks) && $
       n_elements(minorTickNumRecommended) gt 0 && $
       minorTickNumRecommended ge 0 then begin
      minorTickNum = minorTickNumRecommended
    endif
     
  
    ;if values aren't too close to the edge of the range, we 
    ;add leading and trailing ticks
    if n_elements(tickValues) gt 0 then begin       
     
      ;make sure ticks run to the edge of available range
      while tickValues[0] gt edgeTickMargin do begin
        tickValues = [tickValues[0]-tickInterval,tickValues]
      endwhile
        
      while tickValues[n_elements(tickValues)-1] lt (1-edgeTickMargin) do begin
        tickValues = [tickValues,tickValues[n_elements(tickValues)-1]+tickInterval]
      endwhile
      
      tickValuesForMinors = tickValues 
      
      ;remove out of range major tick values
      idx = where(tickValues le 1. and tickValues ge 0,c)
      if c gt 0 then begin
       
        tickValues = tickValues[idx]
        
      endif else begin
        tickValues = tickValues[0]
        noMajors=1
      endelse
                   
    endif else begin
      noMajors = 1
    endelse
        
    ;if autoticks is not selected, and the number of ticks
    ;produced by ::goodticks is not the number requested,
    ;generate the requested number of ticks.  
    ;In the future, we may be able to improve goodTicks
    ;by incorporating an iterative approximation algorithm    
    ;
    ; Disabled, in favor of more restrictive, but better tick placement.
    ; pcruce-2013-04-12
    ; If we want to get more flexible tick placement in the future, 
    ; We should add a ticks by interval option to the z-axis
;    if ~keyword_set(autoTicks) && $
;       n_elements(tickValues) ne majorTickNum then begin
;       
;       tickInterval = 1D/(majorTickNum+1)
;       tickValues = (dindgen(majorTickNum)+1)*tickInterval
;       tickValuesForMinors = [0,tickValues,1]
;       noMajors = 0
;       ticksFixed = 1
;  
;    endif
        
    ;if number of ticks gets switched because of automatic ticks
    ;update the value here
    majorTickNum = n_elements(tickValues)
     
  endif else begin
   
    tickValues = [0D,1D]
    tickValuesForMinors = tickValues
    tickInterval = 1
     
  endelse
  
  ;if we're using less than powers of 10 on a log axis
  ;Then force scientific notation
  if keyword_set(ticksFixed) && annotateExponent eq 0 then begin
    annotateExponent = 2
  endif
          
  ;This struct is used to communicate annotation format settings
  data = {timeAxis:0,formatid:annotationStyle,scaling:scaling,range:zrange,exponent:annotateExponent}
  
  ;Determine label alignment/justification options and position
  if placement eq 0 then begin
  
    if annotationOrientation eq 0 then begin
      annobaseline = [1,0,0]
      annoupdir = [0,1,0]
      annoalignment = [.5,0.0]
    endif else begin
      annobaseline = [0,1,0]
      annoupdir = [-1,0,0]
      annoalignment = [0.0,.5]
    endelse
    
    loc = [0D, [1. + marginNorm2/(yplotpos[1]-yplotpos[0])],zstack+.1]
    
    ticklen = self->pt2norm(thick,1)/(yplotpos[1]-yplotpos[0])
    
    tickDir = 0
    textpos = 1
    
    dir = 0
    
  endif else if placement eq 1 then begin
  
    if annotationOrientation eq 0 then begin
      annobaseline = [1,0,0]
      annoupdir = [0,1,0]
      annoalignment = [.5,1.0]
    endif else begin
      annobaseline = [0,1,0]
      annoupdir = [-1,0,0]
      annoalignment = [1.0,.5]
    endelse
    
    loc = [0D, [0. - marginNorm2/(yplotpos[1]-yplotpos[0])],zstack+.1]
    
    ticklen = self->pt2norm(thick,1)/(yplotpos[1]-yplotpos[0])
    
    tickDir = 1
    textpos = 0
    
    dir = 0
    
  endif else if placement eq 2 then begin
  
    if annotationOrientation eq 0 then begin
      annobaseline = [1,0,0]
      annoupdir = [0,1,0]
      annoalignment = [1.0,.5]
    endif else begin
      annobaseline = [0,1,0]
      annoupdir = [-1,0,0]
      annoalignment = [.5,0.0]
    endelse
    
    
    loc = [[0. - marginNorm2/(xplotpos[1]-xplotpos[0])],0D,zstack+.1]
    
    ticklen = self->pt2norm(thick,1)/(xplotpos[1]-xplotpos[0])
    
    tickDir = 1
    textpos = 0
    
    dir = 1
    
  endif else if placement eq 3 then begin
  
    if annotationOrientation eq 0 then begin
      annobaseline = [1,0,0]
      annoupdir = [0,1,0]
      annoalignment = [0.0,.5]
    endif else begin
      annobaseline = [0,1,0]
      annoupdir = [-1,0,0]
      annoalignment = [.5,1.0]
    endelse
    
    loc = [[1. + marginNorm2/(xplotpos[1]-xplotpos[0])],0D,zstack+.1]
    
    ticklen = self->pt2norm(thick,1)/(xplotpos[1]-xplotpos[0])
    
    tickDir = 0
    textpos = 1
    
    dir = 1
    
  endif
  
  ;Now we determine where to render minor ticks and we generate an axis for them
  if majorTickNum gt 0 && ~keyword_set(nomajors) then begin
  
    borderpos = [[pt4],[pt1],[pt2],[pt3]]
  
    ;calculate irregular minor tick spacing
    if minorTickNum ne 0 then begin
          
      self->makeMinorTicks,zrange,scaling,minorTickNum,tickValuesForMinors,tickInterval,logMinorTickType,minorValues=minorTickValues,fail=fail
      
      if ~fail then begin
        axis_minor = obj_new('IDLgrAxis',dir, $
          range=[0D,1D], $
          location=loc, $
          minor=0,$
          tickLen = ticklen/2,$
          tickdir=tickDir,$
          tickValues=minorTickValues,$
          subTickLen=0,$
          thick=framethick,$
          tickfrmtdata=data,$
          tickformat='formatannotation',$
          color=self->convertColor(frameColor),$
          /notext,$
          /exact)
          
        model->add,axis_minor
      endif
       
    endif
    
    ;determine if any ticks are going to be auto-shifted into exponential
    ;if yes, make them all exponential
    ;This makes sure that are formatting is done in a consistent fashion on any particular axis.
    if data.exponent eq 0 && (scaling eq 0 || scaling eq 1) then begin
      for i = 0,n_elements(tickValues)-1 do begin
      
        if (data.range[1]-data.range[0]) eq 0 then begin
          val = data.range[0]
        endif else begin
          val = (tickValues[i] + data.range[0]/(data.range[1]-data.range[0]))*(data.range[1]-data.range[0])
            relativecuttoff = (data.range[1]-data.range[0])*roundingfactor
            if val le relativecuttoff && val ge -relativecuttoff then begin
              val = 0
            endif
        endelse
        
        if scaling eq 1 then begin
          val = 10^val
        endif
        
        spd_ui_usingexponent,val,data,type=type
        
        if type ne 0 && scaling eq 0 then begin
          data.exponent = 2
          break
        endif else if type ne 0 && scaling eq 1 then begin
          data.exponent = 3
          break
        endif
      endfor
    endif

    ;Now we create an axis object for major ticks.
    ;Because IDL doesn't allow the degree of control
    ;that the options in the gui spec require. The 
    ;axis is generated by layering several simpler IDLgrAxis
    ;objects on top of each other, and controlling their
    ;settings explicitly so that it gives the appearance of
    ;a single axis.
    if ~keyword_set(nomajors) then begin

      axis1 = obj_new('IDLgrAxis',dir, $
          range=[0D,1D], $
          location=loc, $
          minor=0,$
          tickLen = ticklen,$
          tickdir=tickDir,$
          textpos=textpos,$
          tickValues=tickValues,$
          thick=framethick,$
          tickfrmtdata=data,$
          tickformat='formatannotation',$
          color=self->convertColor(frameColor),$
          textBaseLine = annobaseline,$
          textupdir = annoupdir, $
          textalignments = annoalignment, $
          /use_text_color,$
          /exact)
          
    endif else begin
    
       axis1 = obj_new('IDLgrAxis',dir, $
          range=[0D,1D], $
          location=loc, $
          minor=0,$
          subTickLen=0.0,$
          tickLen = ticklen,$
          tickdir=tickDir,$
          textpos=textpos,$
          major=0,$
          thick=framethick,$
          tickfrmtdata=data,$
          tickformat='formatannotation',$
          color=self->convertColor(frameColor),$
          textBaseLine = annobaseline,$
          textupdir = annoupdir, $
          textalignments = annoalignment, $
          /use_text_color,$
          /exact)
    
    endelse
  
      
    ;Since annotation object are autogenerated when IDLgrAxis is created
    ;We need to pull them out after the fact to overwrite some of their settings
    ;(for example, IDL uses the same color argument to axis object as the color for both the axis line and the text itself)
    axis1->getProperty,tickText=tickObj
    
    annofont = annotateTextObject->getGrFont()
    
    annotateTextObject->getProperty,color=annocolor,size=size
    
    annoFont->setProperty,size=self->getZoom()*size
    
    tickObj->setProperty,font=annofont,color=self->convertColor(annocolor)
    
    model->add,axis1
  
  endif else begin
  
    borderpos = [[pt4],[pt1],[pt2],[pt3],[pt4]]
  
  endelse
  
  ; now create/position the label/title
  
  ; first work out how much space title, subtitle will take up so that labels can be offset where necessary
  ; how many lines is each? (we are allowing lazy labels and internal formatting)
  if obj_valid(labelTextObject) then begin
    labeltextObject->getproperty, value=titletext, size=titlesize
    if keyword_set(lazylabels) then begin
      titletext = strjoin(strsplit(titletext,'_',/extract),'!c')
    endif
    titlesplit = strsplit(titletext,'!c|!C',/regex,/extract,count=numlines)
    titlespace = (titlesize+1)*numlines
  endif else titlespace = 0
  if obj_valid(subtitleTextObject) then begin
    subtitletextObject->getproperty, value=subtitletext, size=subtitlesize
    if keyword_set(lazylabels) then begin
      subtitletext = strjoin(strsplit(subtitletext,'_',/extract),'!c')
    endif
    subtitlesplit = strsplit(subtitletext,'!c|!C',/regex,/extract,count=numsublines)
    subtitlespace = (subtitlesize+1)*numsublines
  endif else subtitlespace=0
  
  ;title/subtitle still collide a bit when the text is perpendicular to the colorbar,
  ;his should provide adequate padding while the "offset" var below still allows scalability
  ;(to keep label truly centered some padding should be applied to title and subtitle,
  ; but I've only applied it to the title for simplicity)
  titlepadding = self->pt2norm(10.,1)
  
  if obj_valid(labelTextObject) then begin
  
    if placement eq 0 then begin
      if labelOrientation eq 0 then begin
        pos = [.5,1.+self->pt2norm(margin+thick+labelmargin+subtitlespace,1)/(yplotpos[1]-yplotpos[0]),zstack+.1]
        justify = 0
      endif else begin
        pos = [.5-titlepadding,1.+self->pt2norm(margin+thick+labelmargin,1)/(yplotpos[1]-yplotpos[0]),zstack+.1]
        justify = -1
      endelse
      offset = 1
      
    endif else if placement eq 1 then begin
      if labelOrientation eq 0 then begin
        pos = [.5,0.-self->pt2norm(margin+thick+labelmargin,1)/(yplotpos[1]-yplotpos[0]),zstack+.1]
        justify = 0
      endif else begin
        pos = [.5-titlepadding,0.-self->pt2norm(margin+thick+labelmargin,1)/(yplotpos[1]-yplotpos[0]),zstack+.1]
        justify = -1
      endelse
      offset = -1
      
    endif else if placement eq 2 then begin

      if labelOrientation eq 0 then begin; horizontal
        pos = [0.-self->pt2norm(margin+thick+labelmargin,0)/(xplotpos[1]-xplotpos[0]),.5+titlepadding,zstack+.1]
        offset = 1
        justify = 1
      endif else begin; vertical
        pos = [0.-self->pt2norm(margin+thick+labelmargin+subtitlespace,0)/(xplotpos[1]-xplotpos[0]),.5,zstack+.1]
        offset = 0
        justify = -1
      endelse
      
    endif else if placement eq 3 then begin
    
      pos = [1.+self->pt2norm(margin+thick+labelmargin,0)/(xplotpos[1]-xplotpos[0]),.5+titlepadding,zstack+.1]
      
      if labelOrientation eq 0 then begin
        offset = 1
        justify = -1
      endif else begin
        offset = 0
        justify = 1
      endelse
      
    endif
    
    labelObj = self->getTextObject(labelTextObject,pos,offset,labelOrientation,justify=justify,/enable_formatting)
    
    ; convert underscores to carriage returns
    if keyword_set(lazylabels) then begin
      labelObj->getproperty, strings=labelval
      if n_elements(labelval) eq 1 then begin
        labelval = strjoin(strsplit(labelval,'_',/extract),'!c')
        labelobj->setproperty, strings=labelval
      endif
    endif
    
    model->add,labelObj
    
  endif
  
    ; now create/position the subtitle
  if obj_valid(subtitleTextObject) then begin
  
    if placement eq 0 then begin
      if labelOrientation eq 0 then begin
        pos = [.5,1.+self->pt2norm(margin+thick+labelmargin,1)/(yplotpos[1]-yplotpos[0]),zstack+.1]
        justify = 0
      endif else begin
        pos = [.5,1.+self->pt2norm(margin+thick+labelmargin,1)/(yplotpos[1]-yplotpos[0]),zstack+.1]
        justify = 1
      endelse
 
      offset = 1
      
    endif else if placement eq 1 then begin
      if labelOrientation eq 0 then begin
        pos = [.5,0.-self->pt2norm(margin+thick+labelmargin+titlespace,1)/(yplotpos[1]-yplotpos[0]),zstack+.1]
        justify = 0
      endif else begin
        pos = [.5,0.-self->pt2norm(margin+thick+labelmargin,1)/(yplotpos[1]-yplotpos[0]),zstack+.1]
        justify = 1
      endelse
      offset = -1
      
    endif else if placement eq 2 then begin
    
      pos = [0.-self->pt2norm(margin+thick+labelmargin,0)/(xplotpos[1]-xplotpos[0]),.5,zstack+.1]
      
      if labelOrientation eq 0 then begin
        offset = -1
        justify = 1
      endif else begin
        offset = 0
        justify = -1
      endelse
      
    endif else if placement eq 3 then begin
    
      if labelOrientation eq 0 then begin
        pos = [1.+self->pt2norm(margin+thick+labelmargin,0)/(xplotpos[1]-xplotpos[0]),.5,zstack+.1]
        offset = -1
        justify = -1
      endif else begin
        pos = [1.+self->pt2norm(margin+thick+labelmargin+titlespace,0)/(xplotpos[1]-xplotpos[0]),.5,zstack+.1]
        offset = 0
        justify = 1
      endelse
      
    endif
    
    sublabelObj = self->getTextObject(subtitleTextObject,pos,offset,labelOrientation,justify=justify,/enable_formatting)
    
    ; convert underscores to carriage returns
    if keyword_set(lazylabels) then begin
      sublabelObj->getproperty, strings=labelval
      if n_elements(labelval) eq 1 then begin
        labelval = strjoin(strsplit(labelval,'_',/extract),'!c')
        sublabelobj->setproperty, strings=labelval
      endif
    endif
    
    model->add,sublabelObj
    
  endif
  
  ;Since axis is only on one side, we create a border around the other sides.
  border = obj_new('IDLgrPolyLine',borderpos,color=self->convertColor(frameColor),thick=framethick,/double)
  
  model->add,border
  
  model->add,poly
  
  
end
