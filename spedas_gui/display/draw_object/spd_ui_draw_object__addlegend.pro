;+
;spd_ui_draw_object method: addLegend
;
;This routine adds a legend to a particular view/panel.
;
;Inputs:
;  view(IDLgrView):  The view to which the legend static components are added
;  annotation(IDLgrView): The view to which the legend dynamic components are added
;  panelInfo(struct):  This is the struct that stores all the information about the panel
;  traceInfoArray(array of structs):  This is an array of structs that store all the
;                                     info for all the traces in this panel
; 
;NOTE this routine is currently automatically generating labels
;IT SHOULDN'T BE DOING THIS.  When default labels are being
;correctly set, it should just use the label text object from
;the appropriate axis.
;
;$LastChangedBy: egrimes $
;$LastChangedDate: 2014-06-16 08:02:17 -0700 (Mon, 16 Jun 2014) $
;$LastChangedRevision: 15376 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/spedas_gui/display/draw_object/spd_ui_draw_object__addlegend.pro $
;-
pro spd_ui_draw_object::addLegend,view,annotation,panelInfo,traceInfoArray

  compile_opt idl2,hidden
  
  if ptr_valid(panelInfo.legendInfo) then legendobj = *panelInfo.legendInfo

  if obj_valid(legendobj) then begin
  
    legendobj->getProperty, size=textsize, font=textfont, format=textformat, color=textcolor, $
              vspacing=spacing, bgcolor=legendbgcolor, framethickness=framethickness, bordercolor=bordercolor, $
              enabled=enabled, bottom=lbottom, left=lleft, width=lwidth, height=lheight, bValue=bValue, $
              lValue=lValue, wValue=wValue, hValue=hValue, bUnit=bUnit, lUnit=lUnit, wUnit=wUnit, hUnit=hUnut, $
              xAxisValue=xAxisValue, xAxisValEnabled=xAxisValEnabled, yAxisValue=yAxisValue, yAxisValEnabled=yAxisValEnabled, $
              traces=traces, customtracesset=customtracesset
              
  endif else begin
    textsize = 12  ; Base-text size for auto generated labels
    textfont = 2 ; default is Helvetica
    textformat = -1 ; default is no formatting
    spacing = 2. ; default vertical spacing between lines in legend
    legendbgcolor = [255,255,255] ; default is white
    framethickness = 1 
    bordercolor = [0,0,0] ; default gives black borders
  endelse
  
  ; is this legend enabled?
  if (enabled eq 0) then begin
    hide_val=1
    showtext=0
  endif else begin
    hide_val=0
    showtext=1
  endelse
  
  zstack = .6  ;60% height of legend by default. Puts legend on top of most things
    
  numBias = 10 ; number of chars that annotation will take if using numerical output
  timeBias = 17 ; number of chars that annotation will take if using time output
  extraBias = 3 ; number of chars colon and space will take
    
  nchars = 0  ;Intialize the counter for the number of chars in the longest line
 
  if(xAxisValEnabled eq 1 and yAxisValEnabled eq 1) then nLines = 2+n_elements(traceInfoArray) else $
  if(xAxisValEnabled eq 1 or yAxisValEnabled eq 1) then nLines = 1+n_elements(traceInfoArray) else $
  if(xAxisValEnabled eq 0 and yAxisValEnabled eq 0) then nLines = n_elements(traceInfoArray)
  
  ;calculate the size of legend in chars
  ;the the legend should be as large as the most
  ;characters in any line
  ;Here the bias is the number of characters that will be
  ;contributed by the annotated value itself.(as opposed to the label)
  if panelInfo.xIsTime then begin
    bias = timeBias
    legendObj->axisIsTime, 'X'
  endif else begin
    bias = numBias
  endelse
  
  text = xAxisValue
  
  bias += extraBias
  
  nChars = nChars > (strlen(text)+bias)
  
  text = yAxisValue
  
  if panelInfo.yIsTime then begin
    bias = timeBias
    legendObj->axisIsTime, 'Y'
  endif else begin
    bias = numBias
  endelse
  bias += extraBias
  nChars = nChars > (strlen(text)+bias)
    
  if panelInfo.hasSpec then begin
    if panelInfo.zisTime then begin
      bias = timeBias
      legendObj->axisIsTime, 'Z'
    endif else begin
      bias = numBias
    endelse
    bias+= extraBias
  endif else begin
    if panelInfo.yistime then begin
      bias = timeBias
    endif else begin
      bias = numBias
    endelse
    bias+= extraBias
  endelse
  
  ;Identify the maximum number of characters in any line
  for i = 0,n_elements(traceInfoArray)-1 do begin
    nChars = nChars > (strlen(traceInfoArray[i].dataName)+bias)
  endfor
  
  ;2 is for colon and one extra
  ; nChars+=annoBias+extrabias

  ;Placement for legend is within the panel view, so it is relative to 
  ;the coordinate system of the panel view.  Measurements in the global
  ;page view will need to scaled to the shrunk coordinate system of
  ;the panel view.  divisors can below can be used to perform the 
  ;coordinate transform
  xdiv = panelInfo.xplotpos[1]-panelInfo.xplotpos[0]
  ydiv = panelInfo.yplotpos[1]-panelInfo.yplotpos[0]
  
  ;these estimates assume that a character width is 1/2 its height
  ;this may not be accurate across systems
  width = self->pt2norm(textsize * nchars/2 + 2*spacing,0)/xdiv
  height = self->pt2norm(nlines * textsize + (nlines+1)*spacing,1)/ydiv
  
  ; check if any of the placement settings were set by the user
  if obj_valid(legendObj) then legendObj->getProperty, bottom=legendbottom, left=legendleft, width=legendwidth, height=legendheight


  ;This correction prevents the legend from being drawn off the edge of the screen.
  ;The width correction was previously disabled, but no comment was given as to why
  ;So I turned it back on.(pcruce 2014-05-14)
  view->getProperty,viewPlane_rect=vpr
  if legendleft ne 1 then begin
      if width/2D gt vpr[2]+vpr[0]-1D then begin
        wbias = width/2D - (vpr[2]+vpr[0]-1D)
      endif else begin
        wbias = 0D
      endelse
      ;ensure that legend is not flush with edge of screen
      wbias += self->pt2norm(2.,0)/xdiv
  endif else wbias = 0.
  
  ;wbias = 0
  if legendbottom ne 1 then begin
      if height/2D gt vpr[3]+vpr[1]-1D then begin
        hbias = height/2D - (vpr[3]+vpr[1]-1D)
      endif else begin
        hbias = 0D
      endelse
      ; ensure the legend isn't flush with the top of the view
      hbias += self->pt2norm(2.,1)/ydiv
  endif else hbias = 0.
  

  if (legendbottom eq 1) then begin
    legendObj->getProperty, bValue=bValue, bUnit=bUnit
    userBottom = legendObj->ConvertUnit(bValue, bUnit, 0) ; convert to pts
    userBottom = self->pt2norm(userBottom,1)/ydiv
  endif else begin
    userBottom = 1.-height/2.
    legendObj->setProperty, bValue=self->norm2pt(userBottom,1)*ydiv
  endelse
  if (legendleft eq 1) then begin
    legendObj->getProperty, lValue=lValue, lUnit=lUnit
    userLeft = legendObj->ConvertUnit(lValue, lUnit, 0) ; convert to pts
    userLeft = self->pt2norm(userLeft,0)/xdiv
  endif else begin
    userLeft = (1.-width/2.)
    legendObj->setProperty, lValue=self->norm2pt(userLeft,0)*xdiv
  endelse
  if (legendwidth eq 1) then begin
    legendObj->getProperty, wValue=wValue, wUnit=wUnit
    userWidth = legendObj->ConvertUnit(wValue, wUnit, 0) ; convert to pts
    userWidth = self->pt2norm(userWidth,0)/xdiv
  endif else begin 
    userWidth = width
    legendObj->setProperty, wValue=self->norm2pt(userWidth,0)*xdiv
  endelse
  if (legendheight eq 1) then begin
    legendObj->getProperty, hValue=hValue, hUnit=hUnit
    userHeight = legendObj->ConvertUnit(hValue, hUnit, 0) ; convert to pts
    userHeight = self->pt2norm(userHeight,1)/ydiv
  endif else begin
    userHeight = height
    legendObj->setProperty, hValue=self->norm2pt(userHeight,1)*ydiv
  endelse
  
  ; check if X/Y axis labels were turned off by the user
  if obj_valid(legendObj) then legendObj->getProperty, xAxisValEnabled=xAxisValEnabled, yAxisValEnabled=yAxisValEnabled
  if (~undefined(xAxisValEnabled) and xAxisValEnabled eq 0) then begin
    ; X axis was disabled
    shiftpolygon = self->pt2norm(1*textsize+(1+1)*spacing,1)/ydiv
  endif else shiftpolygon = 0
  if (~undefined(yAxisValEnabled) and yAxisValEnabled eq 0) then begin
    ; Y axis was disabled
    shiftpolyline = self->pt2norm(1*textsize+(1+1)*spacing,1)/ydiv
  endif else shiftpolyline = 0
  if (xAxisValEnabled eq 1 and yAxisValEnabled eq 0) then shiftpolygon = shiftpolygon+self->pt2norm(1*textsize+(2)*spacing,1)/ydiv
  if (yAxisValEnabled eq 1 and xAxisValEnabled eq 0) then shiftpolyline = shiftpolyline+self->pt2norm(1*textsize+(2)*spacing,1)/ydiv

  
  model = obj_new('IDLgrModel',hide=hide_val)
  anno_model = obj_new('IDLgrModel',hide=hide_val)
  
  ;Legend background
  polygon = obj_new('IDLgrPolygon',$
    [userLeft,userLeft+userWidth,userLeft+userWidth,userLeft]-wbias,$
    [userBottom,userBottom,userBottom+userHeight,userBottom+userHeight]+shiftpolyline-shiftpolygon-hbias,$
    [zstack,zstack,zstack,zstack],color=self->convertColor(legendbgcolor),/double,hide=hide_val)

  ;Legend border
  polyline = obj_new('IDLgrPolyline',$
    [userLeft,userLeft+userWidth,userLeft+userWidth,userLeft,userLeft]-wbias,$
    [userBottom,userBottom,userBottom+userHeight,userBottom+userHeight,userBottom]+shiftpolyline-shiftpolygon-hbias,$
    [zstack,zstack,zstack,zstack,zstack]+.00001,color=self->convertColor(bordercolor),/double,thick=framethickness,hide=hide_val)
    
  model->add,polyline
  model->add,polygon
  
  ;Spacing in normalized coordinates
  xspaceNorm = self->pt2norm(spacing,0)/xdiv
  yspaceNorm = self->pt2norm(spacing,1)/ydiv
  xcharNorm = self->pt2norm(textsize,0)/xdiv
  ycharNorm = self->pt2norm(textsize,1)/ydiv
  
  labelLocation=[userLeft + xspacenorm - wbias,userBottom+userHeight - yspacenorm - ycharnorm - hbias,zstack+.05]
  valueLocation=[userLeft+userWidth - xspacenorm - wbias,userBottom+userheight - yspacenorm - ycharnorm - hbias,zstack+.05]


  ;Different label depending on whether x is a time or not
  text = xAxisValue
  
  ;space pad to line up colons
  text += ' :'
  
  if(xAxisValEnabled eq 1) then begin
      ;Generate label text object
      thm_label = obj_new('spd_ui_text',value=text,size=textsize,font=textfont,format=textformat,color=textcolor,show=showtext)
      xlabel = self->getTextObject(thm_label,labelLocation,1,0,justify=-1)
      model->add,xlabel
         
      ;Generate text object where values will be drawn
      thm_value = obj_new('spd_ui_text',value='',size=textsize,font=textfont,format=textformat,color=textcolor,show=showtext)
      xvalue = self->getTextObject(thm_value,valueLocation,1,0,justify=1,/enable_formatting)
      panelInfo.xobj = xvalue
      anno_model->add,xvalue
      labelLocation[1] -= (yspacenorm+ycharnorm)
      valueLocation[1] -= (yspacenorm+ycharnorm)
  endif 
  

  
  ;Different label depending on whether y is a time ro not
;  if panelInfo.yIsTime then begin
;    text = 'Y Axis Time'
;  endif else begin
;    text = 'Y Axis Value'
;  endelse
  text = yAxisValue
  
  text += ' :'
  
  if(yAxisValEnabled eq 1) then begin
      ;Generate label
      thm_label = obj_new('spd_ui_text',value=text,size=textsize,font=textfont,format=textformat,color=textcolor,show=showtext)
      ylabel = self->getTextObject(thm_label,labelLocation,1,0,justify=-1)
      model->add,ylabel
      
      ;Generate text object where values will be drawn
      thm_value = obj_new('spd_ui_text',value='',size=textsize,font=textfont,format=textformat,color=textcolor,show=showtext)
      yvalue = self->getTextObject(thm_value,valueLocation,1,0,justify=1,/enable_formatting)
      panelInfo.yobj = yvalue
      anno_model->add,yvalue

      labelLocation[1] -= (yspacenorm+ycharnorm)
      valueLocation[1] -= (yspacenorm+ycharnorm)
  endif

  if ptr_valid(traces) then tracesstruct = *traces
  if ~undefined(tracesstruct) then listoftraces=reverse(tracesstruct.traceNames)
  ;loop backwards because traces are in reverse order to create proper layering
  for i = n_elements(traceInfoArray)-1,0,-1 do begin
   ; if traceInfoArray[i].isSpec then begin

      if (customtracesset eq 1 && ~undefined(listoftraces)) then begin
;      if ~undefined(listoftraces) then begin
          text = listoftraces[i] + ' :'
      endif else begin
          text = traceInfoArray[i].dataName + ' :'
      endelse
      ;check for colors too close to background (white)
      c = traceInfoArray[i].color
      color_convert, c[0],c[1],c[2],h,l,s, /rgb_hls

      ;colors near yellow are harder to see, 
      ;the subtracted quantity here should adjust for that
      threshold = 0.90 - 0.12 * (  1 - (h/70.-60/70.)^2  > 0 )
      color = l le threshold ? traceInfoArray[i].color : [0,0,0]
      
      ;Label for each trace
      thm_label = obj_new('spd_ui_text',value=text,size=textsize,font=textfont,color=color,format=textformat,show=showtext)
      olabel = self->getTextObject(thm_label,labelLocation,1,0,justify=-1)
      model->add,olabel
      
      ;Value text object for each trace
      thm_value = obj_new('spd_ui_text',value='',size=textsize,font=textfont,color=color,format=textformat,show=showtext)
      ovalue = self->getTextObject(thm_value,valueLocation,1,0,justify=1,/enable_formatting)
      traceInfoArray[i].textobj = ovalue
      anno_model->add,ovalue
      labelLocation[1] -= (yspacenorm+ycharnorm)
      valueLocation[1] -= (yspacenorm+ycharnorm)
  endfor
  
  ;add to info 
  panelInfo.legendModel = model
  panelInfo.legendAnnoModel = anno_model
  
  ;If everything complete successfully add models to views
  view->add,model
  annotation->add,anno_model
end
