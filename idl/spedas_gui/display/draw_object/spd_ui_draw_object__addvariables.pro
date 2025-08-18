;+
;spd_ui_draw_object method: addVariables
;
;adds spd_ui_variables to requested display
;
;$LastChangedBy: jimm $
;$LastChangedDate: 2014-02-11 10:54:32 -0800 (Tue, 11 Feb 2014) $
;$LastChangedRevision: 14326 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/spedas_gui/display/draw_object/spd_ui_draw_object__addvariables.pro $
;-
pro spd_ui_draw_object::addVariables, $
    view, $  ;the view to which they will be added
    annotation,$ ;the view to which the legend text will be added
    vars, $  ;the list of variables to be added
    panelInfo, $ ;the panel info struct
    loadedData, $ ;loaded data object
    xMajors,$  ; the positions of the major ticks on the x axis
    xAxis,$ ;the x axis of the panel
    labelPos,$ ;most extreme position of the labels
    labelMargin,$ ;the distance from the edge of the panel that labels should be placed
    varptr=varptr ; Output, a pointer to variable info structures representing displayed variable
    
  compile_opt idl2,hidden
  zstack = .1
  
  ;decrease this number to fill variable values with NaNs if they are not within a % difference from the true value
  tolerance = 1.0
  
  ;this factor will convert normalized window coords into normalized panel coords
  xpanelConv = panelInfo.xplotpos[1] - panelInfo.xplotpos[0]
  ypanelConv = panelInfo.yplotpos[1] - panelInfo.yplotpos[0]
  spacing = self->pt2norm(2,1)/ypanelConv ; the amount of space between each variable
  
  validmask = intarr(n_elements(vars))
  
  ;number of pixels across the panel * res_factor = number of points in lookup
  linedim = self->getPlotSize(panelInfo.xplotpos,panelInfo.yplotpos,self.lineres)
  xpx = linedim[0]
  
  model = obj_new('IDLgrModel')
  anno_model = obj_new('IDLgrModel')
  
  xAxis->getProperty, $  ;should probably also account for annotation orientation, but I'm not gonna stress that at this point
    tickStyle=tickStyle,$
    bottomPlacement=bottomPlacement,$
    majorLength=majorLength,$
    minorLength=minorLength,$
    annotateAxis=annotateAxis,$
    placeAnnotation=placeAnnotation,$
    margin=margin,$
    scaling=xscaling,$
    annotateRangeMin=annotateRangeMin,$
    annotateRangeMax=annotateRangeMax,$
    annotateTextObject=annotateTextObject,$
    annotateExponent=annotateExponent,$
    showDate=showDate
   
  if n_elements(xMajors) eq 0 then begin ;this won't be set if range is 0, because major ticks cannot be spaced on zero width axis
    noXMajors = 1
  endif else begin 
    xAxisMajors = xMajors
  endelse
  
  ;Determine if we need to draw variables at first or last tick,
  ;Based upon related axis settings
  if ~annotateRangeMin then begin
    if n_elements(xAxisMajors) gt 1 then begin
      xAxisMajors = xAxisMajors[1:n_elements(xAxisMajors)-1]
    endif else begin
      noXMajors = 1
    endelse
  endif
  
  if ~annotateRangeMax then begin
    if n_elements(xAxisMajors) gt 1 then begin
      xAxisMajors = xAxisMajors[0:n_elements(xAxisMajors)-2]
    endif else begin
      noXMajors = 1
    endelse
  endif
  
  ;if ticks are outside the bottom axis, how long are they?
  ;Use this distance to shift variables.
  if bottomPlacement && (tickStyle eq 1 || tickStyle eq 2) then begin
    tickLoc = self->pt2norm(majorLength > minorLength,1)/ypanelConv
  endif else begin
    tickLoc = 0
  endelse
  
  ;If annotations are drawn on the bottom, more shift-down is required.
  if annotateAxis && ~placeAnnotation && obj_valid(annotateTextObject) then begin
    labelLoc = abs(labelPos)
    annotateTextObject->getProperty,size=size
    annoLoc = tickLoc +  self->pt2norm(size,1)/ypanelConv
  endif else begin
    ;otherwise we only shift down according to tick length
    annoLoc = tickLoc
    labelLoc = 0
  endelse
  
  if showDate && ~placeAnnotation && obj_valid(annotateTextObject) then begin
    annotateTextObject->getProperty,size=size
    dateLoc = tickLoc +  2*self->pt2norm(size,1)/ypanelConv
  endif else begin
    ;otherwise we only shift down according to tick length
    dateLoc = tickLoc
  endelse
  
 ; yloc = 0. - (labelloc > annoloc) - 3*spacing
  
  yloc = 0. - max([labelloc,annoloc,dateLoc])
  
  varInfoArray = *panelInfo.varInfo
  
  ;Loop over the variables on this panel
  for i = 0,n_elements(vars)-1 do begin
  
    vars[i]->getProperty, $
      fieldname=fieldname,$
      controlname=controlname,$
      text=text,$
      format=format,$
      minRange=minRange,$
      maxRange=maxRange,$
      scaling=vscaling,$
      useRange=useRange,$
      annotateExponent=annotateExponent
      
    text->getProperty,size=size,show=show
    
    ;If it is not displayed, skip it.
    if ~show then continue
    
    ;Shift down 1-line after each variable is written
    yloc -= (spacing + self->pt2norm(size,1)/ypanelConv)
    ;This value determines how far to the left the variable title should be placed
    ;and how far to the left the text objects for the variable legend should go.
    xloc = 0. - self->pt2norm(labelMargin,0)/xpanelConv
    
    textObj = self->getTextObject(text,[xloc,yloc,zstack],1,0,justify=1,/enable_formatting)
    
    model->add,textObj
    
    ;Extract the dependent variable from the loaded data object
    if keyword_set(fieldname) && loadedData->isChild(fieldname) then begin
      loadedData->getVarData,name=fieldname,data=yd,isTime=isTime,/duplicate
      varInfoArray[i].dataY = yd
      varInfoArray[i].isTime = isTime
    endif else begin
      continue
    endelse
    
    ;Extract the independent variable from the loaded data object
    if keyword_set(controlname) && loadedData->isChild(controlname) then begin
      loadedData->getVarData,name=controlname,data=xd,/duplicate
      ;varInfoArray[i].dataX = xd
      ;xscaling = vscaling
      
      ;independent data range
      xrange = [min(*xd,/nan),max(*xd,/nan)]
    endif else begin
    
      ;dummy independent variable
      xd2 = ptr_new(dindgen(n_elements(*yd[0]))/(n_elements(*yd[0])-1))
      varInfoArray[i].dataX = xd2
      xrange = [0D,1D]
    endelse
    
    ;Override default independent data range with panel data range, or
    ;Fixed value from user.
    if userange eq 2 then begin
    
      if panelInfo.locked then begin
        xrange = panelInfo.lockedRange
        xscaling = panelInfo.lockedScale
      endif else begin
        xrange = panelInfo.xrange
        xscaling = panelInfo.xscale
      endelse
      
      vars[i]->setProperty,minrange=xrange[0],maxrange=xrange[1]
    endif else if userange eq 1 then begin
      xrange = [minRange,maxRange]
      xscaling = vscaling
    endif
    
    ;Store results in info struct
    varInfoArray[i].annotateStyle = format
    varInfoArray[i].scaling = xscaling
    varInfoArray[i].range = xrange
    
    if ptr_valid(xd) then begin
    
      ;if we're not using a dummy independent, then clip the data as normal
      self->xclip,xd,yd,ptr_new(),xrange,xscaling,fail=fail
         
      if fail then begin
        self.statusBar->update,'Error: Could not process variable control'
        self.historyWin->update,'Error: Could not process variable control'
        ;ok = error_message('Failure to process variable control:' + controlname)
        continue
      endif
    
      ;Normalize clipped x-values for creation of line reference  
      xdata = (temporary(*xd[0])-xrange[0])/(xrange[1]-xrange[0])
      ydata = temporary(*yd[0])
 
      ;Create legend reference for variable
      self->makeLineReference,xdata,ydata,xpx,ref=refvar
      
      varInfoArray[i].dataY = ptr_new(temporary(refvar))
      
    endif else begin
    
     ;Otherwise use dummy normalized data to create
     ;line reference with spacing proportional to element index 
     xdata = dindgen(n_elements(ydata))/n_elements(ydata)
     ydata = temporary(*yd) 
     self->makeLineReference,xdata,ydata,xpx,ref=refvar
    
     varInfoArray[i].dataY = ptr_new(temporary(refvar))
      
    endelse
    
    textTemp = text->copy()
    textTemp->setProperty,value=''
    
    ;Location of legend on the right side
    xloc = 1. + self->pt2norm(labelMargin,0)/xpanelconv
    
    ;The actual text object for the legend
    textObj = self->getTextObject(textTemp,[xloc,yloc,zstack],1,0,justify=-1,/enable_formatting)
    varInfoArray[i].textObj = textObj
    anno_model->add,textObj
    
    ; xmajornorm = (xAxisMajors-xrange[0])/(xrange[1]-xrange[0])
    annotatedata = {timeAxis:isTime,formatid:format,scaling:0,exponent:annotateExponent}
    
    if ~keyword_set(noXMajors) then begin
    
      annotateValues = dblarr(n_elements(xAxisMajors))
      annotateAutoExponent=1
      
      ;Loop over the majors to determine annotation values and autoformat
      for j = 0,n_elements(xAxisMajors)-1 do begin
      
        ;Find closest value to each major
        temp = min(abs(xdata - xAxisMajors[j]),idx,/nan)
        if temp lt tolerance then begin ;only use real valued annotation if major tick value close to an actual value
          annotateValues[j] = ydata[idx]
        endif else begin
          annotateValues[j] = !VALUES.D_NAN
        endelse
        
        spd_ui_usingexponent,annotateValues[j],annotatedata,type=type
      
        if type ne 0 then begin
          annotateAutoExponent=2
        endif
      endfor
      
      ;if autoformat, force consistent annotate for all values
      if annotateExponent eq 0 then begin
        annotateData.exponent=annotateAutoExponent
      endif
      
      for j = 0,n_elements(xAxisMajors)-1 do begin
      
       
        ;And generate text string/object to display
        valueString = formatannotation(0,0,annotatevalues[j],data=annotatedata)
        
        textTemp = text->copy()
        textTemp->setProperty,value=valuestring
        
        textObj = self->getTextObject(textTemp,[xAxisMajors[j],yloc,zstack],1,0,/enable_formatting)
        model->add,textObj
        
      endfor
    endif
      
    validmask[i] = 1
    
  endfor
  
  idx = where(validmask,c)
  
  if c gt 0 then begin
    varptr=ptr_new(varInfoArray[idx])
    view->add,model
    annotation->add,anno_model
  endif else begin
    varptr=ptr_new()
  endelse
  
end
