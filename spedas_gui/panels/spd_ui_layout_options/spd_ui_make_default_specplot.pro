;+ 
;NAME:  
;  spd_ui_make_default_specplot
;  
;PURPOSE:
;  Routine that creates a default specplot on particular panel
;  
;CALLING SEQUENCE:
;  spd_ui_make_default_specplot, loadedData, panel, xvar, yvar, zvar, 
;                                gui_sbar=gui_sbar
;
;INPUT:
;  loadedData: the loadedData object
;  panel:  the panel on which the plot should be placed.
;  xvar:  the name of the variable storing the x-data.
;  yvar:  the name of the variable storing the y-data.
;  zvar:  the name of the variable storing the z-data.
;  gui_sbar: the main GUI status bar object
;            
;KEYWORDS:
;  none
;        
;OUTPUT:
;  none
;
;--------------------------------------------------------------------------------

;just eliminates some repetition in retrieving a data object
function spd_ui_default_specplot_get_data_object,loadedData,name

  compile_opt idl2, hidden
  
  name = name[0]
  
  if name eq '' then begin
    return,0
  endif else if loadedData->isParent(name) then begin ;sometimes name can be a group and data name, this makes sure we get the data
    group = loadedData->getGroup(name)
    if group->hasChild(name) then begin
      return,group->getObject(name)
    endif else begin
      return,(group->getDataObjects())[0]
    endelse
  endif else begin
    return,loadedData->getObjects(name=name)
  endelse
  
end

pro spd_ui_make_default_specplot, loadedData, panel, xvar, yvar, zvar,template, $
                                  gui_sbar=gui_sbar

compile_opt idl2, hidden

panel->GetProperty, traceSettings=traceSettings, xAxis=xAxis, yAxis=yAxis, $
                    zAxis=zAxis
;ntraces = traceSettings->count()

template->getProperty,z_axis=zAxisTemplate,x_axis=xAxisTemplate,y_axis=yAxisTemplate

; check if x-axis object exists, create if not
if ~obj_valid(xAxis) then xAxis = obj_new('spd_ui_axis_settings', $
                                  isTimeAxis=1, $
                                  orientation=0, $
                                  majorLength=7., $
                                  minorLength=3., $
                                  topPlacement=1, $
                                  bottomPlacement=1, $
                                  tickStyle=0, $
                                  majorTickAuto=1, $
                                  numMajorTicks=5, $
                                  minorTickAuto=1, $
                                  numMinorTicks=5, $
                                 ; majorGrid=majorGrid, $
                                 ; minorGrid=minorGrid, $
                                  dateString1="%date", $
                                  dateString2="%time", $
                                  showdate=1,$
                                  annotateAxis=1,$
                                  placeAnnotation=0,$
                                  AnnotateMajorTicks=1,$
                                  annotateRangeMin=0,$
                                  annotateRangeMax=0,$
                                  annotateStyle=5,$
                                  annotateTextObject=obj_new('spd_ui_text',font=2,size=11.,color=[0,0,0]),$
                                  scaling=0,$
                                  rangeMargin=0., $
                                  margin=15., $
                                  annotateOrientation=0, $
                                  autoticks = 1 $
                                  ;labels=labels,$
                                  ;stacklabels=0 $
                                  ;rangeoption=2,$
                                  )

; check if y-axis object exists, create if not
if obj_valid(yAxis) then yAxis->setProperty, margin=35.;, titlemargin=95. ; change the label margin from default as spec plot labels are on left, line plot on right
if ~obj_valid(yAxis) then yAxis = obj_new('spd_ui_axis_settings', $
                                   isTimeAxis=0,$
                                   orientation=1,$
                                   majorLength=7.,$
                                   minorLength=3.,$
                                   topPlacement=1,$
                                   bottomPlacement=1,$
                                   tickStyle=0,$
                                   majorTickAuto=1,$
                                   numMajorTicks=5,$
                                   minorTickAuto=1,$
                                   numMinorTicks=8,$
                                   ;majorGrid=majorGrid,$
                                   ;minorGrid=minorGrid,$
                                   ;/lineatzero,$
                                   annotateAxis=1,$
                                   placeAnnotation=0,$
                                   AnnotateMajorTicks=1,$
                                   annotateRangeMax=0,$
                                   annotateRangeMin=0,$
                                   annotateStyle=4,$
                                   annotateTextObject=obj_new('spd_ui_text',font=2,size=11.,color=[0,0,0]),$
                                   rangeOption=0,$
                                   rangeMargin=.00, $
                                   scaling=1, $
                                   annotateOrientation=1, $
                                   margin=35., $
                                   autoticks = 1 $
                                   ;labels=labels, $
                                   ;stackLabels=1 $
                                   )

; check if z-axis object exists, create z-axis and make sure y-axis is log
if ~obj_valid(zAxis) then begin
  
  xAxis->setProperty, annotateRangeMax=0,/notouched
  
  if obj_valid(zAxisTemplate) then begin
    zAxis = zAxisTemplate->copy()
  endif else begin
  
    zAxis = obj_new('spd_ui_zaxis_settings', $
                     colorTable = 6,$
                     fixed = 0,$
                     tickNum = 5, $
                     minorTickNum = 8, $
                     labelmargin = 40, $
                     scaling = 1, $
                     annotationStyle = 4, $
                     margin = 5, $
                     annotateTextObject = obj_new('spd_ui_text',size=11.,font=2,format=3), $
                     annotationOrientation = 0, $
                     ;labelTextObject = obj_new('spd_ui_text',value='FLUX in eV'),$
                     labelOrientation=1, $
                     placement=3,$
                     autoticks=1 $
                     )
   endelse
endif else begin
  zAxis->getProperty,placement=placement
  if placement eq 4 then begin
    zAxis->setProperty,placement=3,/notouched
  endif
endelse

yAxis->setProperty, rangeOption=0, $
                     rangeMargin=.00, $
                     scaling=0, $
                     lineatzero=0,/notouched

yAxis->getProperty, labels=ylabels
if ~obj_valid(ylabels) then ylabels = obj_new('IDL_Container')
xAxis->getProperty, labels=xlabels
if ~obj_valid(xlabels) then xlabels = obj_new('IDL_Container')
                    
traceSettings->add,obj_new('spd_ui_spectra_settings', dataX=xvar, dataY=yvar, dataZ=zvar)

xobj = spd_ui_default_specplot_get_data_object(loadedData,xvar)
yobj = spd_ui_default_specplot_get_data_object(loadedData,yvar)
zobj = spd_ui_default_specplot_get_data_object(loadedData,zvar)

if obj_valid(yobj) && yvar[0] ne '' then begin

    yObj->getProperty, istime=yIsTime, settings=datasettings
    
    if obj_valid(datasettings) then begin
    
    yAxis->getproperty, minfixedrange=minfixedrange, maxfixedrange=maxfixedrange
  
    ; make sure xrange=[0,0] isn't used to determine fixed range
    if (dataSettings->getyFixedRange())[0] ne (dataSettings->getyFixedRange())[1] then begin
      if (minFixedRange eq maxFixedRange) then begin
        minfixedrange = (dataSettings->getyFixedRange())[0]
        maxfixedrange = (dataSettings->getyFixedRange())[1]  
      endif else begin
        minfixedrange = min([minfixedrange,(dataSettings->getyFixedRange())[0]],/nan)
        maxfixedrange = max([maxfixedrange,(dataSettings->getyFixedRange())[1]],/nan)
      endelse
      yAxis->setproperty, minfixedrange=minfixedrange, maxfixedrange=maxfixedrange,rangeoption=2,/notouched
    endif
  
    if dataSettings->getyRangeOption() ne -1 then begin
      yAxis->setProperty,rangeoption=dataSettings->getyRangeOption(),/notouched
    endif
    
    if dataSettings->getyScaling() ne -1 then begin
      yAxis->setProperty,scaling=dataSettings->getyScaling(),/notouched
    endif
    
    yAxis->getProperty,rangeoption=rangeOption
    if rangeOption eq 2 then begin
      yAxis->setproperty,rangemargin=0,/notouched
    endif
    
    if dataSettings->getUseColor() then begin
      color = dataSettings->getColor()
    endif
    
    xlabeltext = dataSettings->getXLabel()
    ylabeltext = dataSettings->getYLabel()

  endif
endif else begin
  yistime = 0
endelse
  
if obj_valid(xObj) && xvar[0] ne '' then begin
  xObj->getProperty, isTime=xIsTime, settings=datasettings
  
  if obj_valid(datasettings) then begin
  
    xAxis->getproperty, minfixedrange=minfixedrange, maxfixedrange=maxfixedrange
  
    ; make sure xrange=[0,0] isn't used to determine fixed range
    if (dataSettings->getxFixedRange())[0] ne (dataSettings->getxFixedRange())[1] then begin
      if (minFixedRange eq maxFixedRange) then begin
        minfixedrange = (dataSettings->getxFixedRange())[0]
        maxfixedrange = (dataSettings->getxFixedRange())[1]  
      endif else begin
        minfixedrange = min([minfixedrange,(dataSettings->getxFixedRange())[0]],/nan)
        maxfixedrange = max([maxfixedrange,(dataSettings->getxFixedRange())[1]],/nan)
      endelse
      xAxis->setproperty, minfixedrange=minfixedrange, maxfixedrange=maxfixedrange,/notouched
    endif
  
    if dataSettings->getxRangeOption() ne -1 then begin
      xAxis->setProperty,rangeoption=dataSettings->getxRangeOption(),/notouched
    endif
    
    if dataSettings->getxScaling() ne -1 then begin
      xAxis->setProperty,scaling=dataSettings->getxScaling(),/notouched
    endif
    
    xAxis->getProperty,rangeoption=rangeOption
    if rangeOption eq 2 then begin
      xAxis->setproperty,rangemargin=0,/notouched
    endif
  endif
  
endif else begin
  xistime = 0
endelse

if obj_valid(zObj) && zvar[0] ne '' then begin

  zObj->getProperty, settings=dataSettings
  
  if obj_valid(dataSettings) then begin
    zAxis->getproperty, minrange=minrange, maxrange=maxrange
    
    if (dataSettings->getzRange())[0] ne (dataSettings->getzRange())[1] then begin
      if (minFixedRange eq maxFixedRange) then begin
        minfixedrange = (dataSettings->getzRange())[0]
        maxfixedrange = (dataSettings->getzRange())[1]  
      endif else begin
        minfixedrange = min([minfixedrange,(dataSettings->getzRange())[0]],/nan)
        maxfixedrange = max([maxfixedrange,(dataSettings->getzRange())[1]],/nan)
      endelse
      zAxis->setproperty, minrange=minfixedrange, maxrange=maxfixedrange,/notouched
    endif
    
    if dataSettings->getzFixed() ne -1 then begin
      zAxis->setProperty,fixed=dataSettings->getxRangeOption(),/notouched
    endif
    
    if dataSettings->getzScaling() ne -1 then begin
      zAxis->setProperty,scaling=dataSettings->getzScaling(),/notouched
    endif
  
  endif

;  spd_ui_process_axis_tags,zAxis,'z',zdlptr,zlptr
  
endif
 
if obj_valid(dataSettings) then begin
  xlabeltext = dataSettings->getxlabel()
  xtitletext = dataSettings->getxtitle()
  xsubtitletext = dataSettings->getxsubtitle()
  ylabeltext = dataSettings->getylabel()
  zlabeltext = dataSettings->getzlabel()
  zsubtitletext = dataSettings->getzSubtitle()
  ytitletext = dataSettings->getytitle()
  ysubtitletext = dataSettings->getysubtitle()
  if dataSettings->getUseColor() then begin
    ycolor = dataSettings->getcolor()
  endif
endif else begin
  xlabeltext = ''
  xtitletext = ''
  xsubtitletext = ''
  ylabeltext = zvar
  zlabeltext = ''
  zsubtitletext = ''
  ytitletext = ''
  ysubtitletext = ''
endelse

yfont = 2
yformat = 3
ysize = 11

if obj_valid(yAxisTemplate) then begin

  yAxisTemplate->getProperty,labels=yTlabels
  
  if obj_valid(yTlabels) && obj_isa(yTlabels,'IDL_Container') then begin
  
    yTlabel = yTlabels->get()
  
    if obj_valid(yTlabel) then begin
  
      yTlabel->getProperty,font=yfont,format=yformat,size=ysize
      
      if ~keyword_set(ycolor) then begin
        yTlabel->getProperty,color=ycolor
      endif
  
    endif
  
  endif

endif

if ~keyword_set(ycolor) then begin
  ycolor = [0,0,0]
endif

ylabels->add,obj_new('spd_ui_text', value=ylabeltext, font=yfont, format=yformat, size=ysize, $
                    color=ycolor,show=0)
     
xfont = 2
xformat = 3
xsize = 11
xcolor = [0,0,0]

if obj_valid(xAxisTemplate) then begin

  xAxisTemplate->getProperty,labels=xTlabels
  
  if obj_valid(xTlabels) && obj_isa(xTlabels,'IDL_Container') then begin
  
    xTlabel = xTlabels->get()
  
    if obj_valid(xTlabel) then begin
  
      xTlabel->getProperty,font=xfont,format=xformat,size=xsize,color=xcolor
  
    endif
  
  endif

endif
                    
xlabels->add,obj_new('spd_ui_text',value=xlabeltext,font=xfont,format=xformat,size=xsize,$
                    color=xcolor,show=keyword_set(xlabeltext))
;---- x title
; first check if the xtitle is already set, if so don't change it
xAxis->GetProperty, titleobj=xtitleobj
if obj_valid(xtitleobj) then begin
  xtitleobj->getProperty, value=xtitlecur
endif else xtitlecur = ''
if xtitlecur eq '' then begin
  xfont = 2
  xformat = 3
  xsize = 11
  xcolor = [0,0,0]

  if obj_valid(xAxisTemplate) then begin

    xAxisTemplate->getProperty,titleobj=xTtitle
  
    if obj_valid(xTtitle) then begin
  
      xTtitle->getProperty,font=xfont,format=xformat,size=xsize,color=xcolor
 
    endif

  endif                    

  xAxis->SetProperty, titleobj=obj_new('spd_ui_text', value=xtitletext, font=xfont, format=xformat, size=xsize,$
                    color=xcolor, show=keyword_set(xtitletext)),/notouched
endif
;-----x subtitle
; first check if the xsubtitle is already set, if so don't change it
xAxis->GetProperty, subtitleobj=xsubtitleobj
if obj_valid(xsubtitleobj) then begin
  xsubtitleobj->getProperty, value=xsubtitlecur
endif else xsubtitlecur = ''
if xsubtitlecur eq '' then begin

  xfont = 2
  xformat = 3
  xsize = 10
  xcolor = [0,0,0]

  if obj_valid(xAxisTemplate) then begin

    xAxisTemplate->getProperty,subtitleobj=xTsubtitle
  
    if obj_valid(xTsubtitle) then begin
  
      xTsubtitle->getProperty,font=xfont,format=xformat,size=xsize,color=xcolor
 
    endif

  endif
                    

  xAxis->SetProperty, subtitleobj=obj_new('spd_ui_text', value=xsubtitletext, font=xfont, format=xformat, size=xsize,$
                    color=xcolor, show=keyword_set(xsubtitletext)),/notouched
endif
;----- y title
; first check if the ytitle is already set, if so don't change it
yAxis->GetProperty, titleobj=ytitleobj
if obj_valid(ytitleobj) then begin
  ytitleobj->getProperty, value=ytitlecur
endif else ytitlecur = ''
if ytitlecur eq '' then begin
  yfont = 2
  yformat = 3
  ysize = 11
  ycolor = [0,0,0]
  if obj_valid(yAxisTemplate) then begin

    yAxisTemplate->getProperty,titleobj=yTtitle
  
    if obj_valid(yTtitle) then begin
      yTtitle->getProperty,font=yfont,format=yformat,size=ysize, color=ycolor
    endif

  endif
  yaxis->SetProperty, titleobj=obj_new('spd_ui_text', value=ytitletext, font=yfont, format=yformat, size=ysize,$
                    color=ycolor, show=1)
endif
;---- ysubtitle
; first check if the ysubtitle is already set, if so don't change it
yAxis->GetProperty, subtitleobj=ysubtitleobj
if obj_valid(ysubtitleobj) then begin
  ysubtitleobj->getProperty, value=ysubtitlecur
endif else ysubtitlecur = ''
if ysubtitlecur eq '' then begin
  yfont = 2
  yformat = 3
  ysize = 10
  ycolor = [0,0,0]
  if obj_valid(yAxisTemplate) then begin

    yAxisTemplate->getProperty,subtitleobj=yTsubtitle
  
    if obj_valid(yTsubtitle) then begin
      yTsubtitle->getProperty,font=yfont,format=yformat,size=ysize, color=ycolor
    endif

  endif
  yaxis->SetProperty, subtitleobj=obj_new('spd_ui_text', value=ysubtitletext, font=yfont, format=yformat, size=ysize,$
                    color=ycolor, show=1)
endif                  

; z title and subtitle
; Note that the z title is stored in the labeltextobject as it was previously implemented as a label and when the
; subtitle field was introduced the object was not renamed

; first check if the z title is already set
zaxis->getProperty, labeltextobject=ztitleobj
if obj_valid(ztitleobj) then begin
  ztitleobj->getProperty, value=ztitlecur
endif else ztitlecur = ''
if ztitlecur eq '' then begin
  ;if keyword_set(zlabeltext) then begin

    zfont = 2
    zformat = 3
    zsize = 11
    zcolor = [0,0,0]
  
    if obj_valid(zAxisTemplate) then begin
  
      zAxisTemplate->getProperty,labeltextobject=zTlabel
    
      if obj_valid(zTlabel) then begin
  
        zTlabel->getProperty,font=zfont,format=zformat,size=zsize,color=zcolor
  
      endif
  
    endif

    zaxis->setProperty,labeltextobject=obj_new('spd_ui_text',value=zlabeltext,font=zfont,format=zformat,size=zsize,$
                    color=zcolor,show=1)
  ;endif
endif
; first check if the z subtitle is already set
zaxis->getProperty, subtitletextobject=zsubtitleobj
if obj_valid(zsubtitleobj) then begin
  zsubtitleobj->getProperty, value=zsubtitlecur
endif else zsubtitlecur = ''
if zsubtitlecur eq '' then begin
  ;if keyword_set(zsubtitletext) then begin

    zfont = 2
    zformat = 3
    zsize = 10
    zcolor = [0,0,0]
  
    if obj_valid(zAxisTemplate) then begin
  
      zAxisTemplate->getProperty,subtitletextobject=zTsubtitle
    
      if obj_valid(zTsubtitle) then begin
  
        zTsubtitle->getProperty,font=zfont,format=zformat,size=zsize,color=zcolor
  
      endif
  
    endif

    zaxis->setProperty,subtitletextobject=obj_new('spd_ui_text',value=zsubtitletext,font=zfont,format=zformat,size=zsize,$
                    color=zcolor,show=1)
  ;endif
endif

; check if current data is in current y-range (as long as it's not a new panel)
yaxis->getproperty, minfixedrange=minfixedrange, maxfixedrange=maxfixedrange, $
                    rangeOption=rangeOption
if (minfixedrange ne maxfixedrange) and (rangeOption eq 2) then begin
  cminmax = spd_ui_data_minmax(loadedData, yvar)
  if (cminmax[0] lt minfixedrange) OR (cminmax[1] gt maxfixedrange) then begin
    if obj_valid(gui_sbar) then $
      gui_sbar->update, 'Some of the data added may be outside the panel Y-Axis limits.'
  endif
endif

; set x and y axis properties
xAxis->SetProperty, labels=xlabels, isTimeAxis=xistime,/notouched

yAxis->SetProperty, labels=ylabels, isTimeAxis=yistime,/notouched

panel->SetProperty, traceSettings=traceSettings, xAxis=xAxis, yAxis=yAxis, $
                    zAxis=zAxis

end
