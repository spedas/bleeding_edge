;+ 
;NAME:  
;  spd_ui_make_default_lineplot
;  
;PURPOSE:
;  Routine that creates a default lineplot on particular panel
;  
;CALLING SEQUENCE:
;  spd_ui_make_default_lineplot, loadedData, panel, xvar, yvar, gui_sbar=gui_sbar
;  
;INPUT:
;  loadedData: the loadedData object
;  panel:  the panel on which the plot should be placed.
;  xvar:  the name of the variable storing the x-data.
;  yvar:  the name of the variable storing the y-data.
;            
;KEYWORDS:
;  gui_sbar: the main GUI status bar object
;  datanum: # of the trace that we're plotting - passed from layout options 
;        
;OUTPUT:
;  none
;
;--------------------------------------------------------------------------------

pro spd_ui_make_default_lineplot, loadedData, panel, xvar, yvar,template, gui_sbar=gui_sbar, datanum=datanum

compile_opt idl2, hidden

panel->GetProperty, traceSettings=traceSettings, xAxis=xAxis, yAxis=yAxis
ntraces = traceSettings->count()

template->getProperty,x_axis=xAxisTemplate,y_axis=yAxisTemplate,line=lineTemplate

; check if x,y-axis objects exist, create if not
if ~obj_valid(xAxis) then xAxis = obj_new('spd_ui_axis_settings', blacklabels=1)
if ~obj_valid(yAxis) then yAxis = obj_new('spd_ui_axis_settings', blacklabels=0)

; get and check if y-axis labels exist, create if not
yAxis->getProperty, labels=ylabels
if ~obj_valid(ylabels) then ylabels = obj_new('IDL_Container')
xAxis->getProperty, labels=xlabels
if ~obj_valid(xlabels) then xlabels = obj_new('IDL_Container')

; change default label side to right for line plots
yAxis->setProperty, placeLabel=1

;Note that this code assumes no names that represent quantities with multiple components
;will be passed in.  This is probably a good assumption, since we're dealing with line 
;quantities, but if this problem does occur, the function from the default specplot code
;called: spd_ui_default_specplot_get_data_object
;can probably be used without modification in lieu of the code below 

;sometimes name can be a group and data name, this makes sure we get the data
if loadedData->isParent(xvar) then begin 
  group = loadedData->getGroup(xvar)
  xObj = group->getObject(xvar)
endif else begin
  xObj = loadedData->getObjects(name=xvar)
endelse

;sometimes name can be a group and data name, this makes sure we get the data
if loadedData->isParent(yvar) then begin 
  group = loadedData->getGroup(yvar)
  yObj = group->getObject(yvar)
endif else begin
  yObj = loadedData->getObjects(name=yvar)
endelse

if obj_valid(yobj) && yvar[0] ne '' then begin

  yObj->getProperty, istime=yIsTime, settings=ydatasettings, isSpec=spec
  
  if obj_valid(ydatasettings) then begin
    
    yAxis->getproperty, minfixedrange=minfixedrange, maxfixedrange=maxfixedrange

    ;get range, scaling, and range options (auto/fixed)
    ;use z-axis if variable is flagged as spectra
    if keyword_set(spec) then begin
      ;data range
      datarange = ydatasettings->getzrange()
      
      ;range option (auto/fixed)
      ;value must be adjusted as flags differ between Z and Y
      zrangeOpt = ydataSettings->getzFixed()>0
      yAxis->setProperty,rangeoption=zrangeOpt gt 0 ? 2:0,/notouched

      ;scaling
      yAxis->setProperty,scaling=ydataSettings->getzScaling()>0,/notouched
    endif else begin
      ;data range
      datarange = ydatasettings->getyfixedrange()
      
      ;range option (auto/fixed)
      yAxis->setProperty,rangeoption=ydataSettings->getyRangeOption()>0,/notouched

      ;scaling
      yAxis->setProperty,scaling=ydataSettings->getyScaling()>0,/notouched
    endelse
    
    ;copy valid fixed range
    if datarange[0] ne datarange[1] then begin
      if (minFixedRange eq maxFixedRange) then begin
        minfixedrange = datarange[0]
        maxfixedrange = datarange[1]  
      endif else begin
        minfixedrange = min([minfixedrange,datarange[0]],/nan)
        maxfixedrange = max([maxfixedrange,datarange[1]],/nan)
      endelse
      yAxis->setproperty, minfixedrange=minfixedrange, maxfixedrange=maxfixedrange,/notouched
    endif
    
    ;only use margin for auto range
    yAxis->getProperty,rangeoption=rangeOption
    if rangeOption eq 2 then begin
      yAxis->setproperty,rangemargin=0,/notouched
    endif
    
    xlabeltext = ydataSettings->getXLabel()
    ylabeltext = ydataSettings->getYLabel()

  endif
endif else begin
  yistime = 0
endelse


  
if obj_valid(xObj) && xvar[0] ne '' then begin
  xObj->getProperty, isTime=xIsTime, settings=xdatasettings
  
  if obj_valid(xdatasettings) then begin
  
    xAxis->getproperty, minfixedrange=minfixedrange, maxfixedrange=maxfixedrange
  
    ; make sure xrange=[0,0] isn't used to determine fixed range
    if (xdataSettings->getxFixedRange())[0] ne (xdataSettings->getxFixedRange())[1] then begin
      if (minFixedRange eq maxFixedRange) then begin
        minfixedrange = (xdataSettings->getxFixedRange())[0]
        maxfixedrange = (xdataSettings->getxFixedRange())[1]  
      endif else begin
        minfixedrange = min([minfixedrange,(xdataSettings->getxFixedRange())[0]],/nan)
        maxfixedrange = max([maxfixedrange,(xdataSettings->getxFixedRange())[1]],/nan)
      endelse
      xAxis->setproperty, minfixedrange=minfixedrange, maxfixedrange=maxfixedrange,/notouched
    endif
  
    if xdataSettings->getxRangeOption() ne -1 then begin
      xAxis->setProperty,rangeoption=xdataSettings->getxRangeOption(),/notouched
    endif
    
    if xdataSettings->getxScaling() ne -1 then begin
      xAxis->setProperty,scaling=xdataSettings->getxScaling(),/notouched
    endif
    
    xAxis->getProperty,rangeoption=rangeOption
    if rangeOption eq 2 then begin
      xAxis->setproperty,rangemargin=0,/notouched
    endif
  endif
  
endif else begin
  xistime = 0
endelse

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

;setup line/label color.
;This code establishes the precedence of settings and ensures that line & label colors match.
;Precedence(highest to lowest)
;#1 Data/Tplot Settings
;#2 Template
;#3 Default
;

; setup default color order ['k','m','r','g','c','b','y']
;def_colors = [[0,0,0],[255,0,255],[255,0,0],[0,255,0],[0,255,255],[0,0,255],[255,255,0]]
def_colors = [[0,0,255],[0,255,0],[255,0,0],[0,0,0],[255,255,0],[255,0,255],[0,255,255]]

factors = [[1,0],[1,1],[1,3],[3,1],[1,7],[5,3],[3,5],[7,1]]

color_idx1 = ntraces mod 7
color_idx2 = (ntraces +1) mod 7
factor1 = factors[0,(ntraces/7) mod 8]
factor2 = factors[1,(ntraces/7) mod 8]

color=(factor1*def_colors[*,color_idx1]+factor2*def_colors[*,color_idx2])/(factor1+factor2)

if obj_valid(lineTemplate) then begin
  lineTemplate->getProperty,linestyle=linestyle
  linestyle->getProperty,color=color
endif

if obj_valid(ydataSettings) && ydataSettings->getUseColor() then begin
  color = ydataSettings->getColor()
endif

; add trace to traceSettings object

if obj_valid(lineTemplate) then begin

  line = lineTemplate->copy()
  line->setProperty,dataX=xvar,dataY=yvar
  line->getProperty,linestyle=linestyle
  linestyle->setProperty,color=color
  
  traceSettings->add,line

endif else begin

  traceSettings->add,obj_new('spd_ui_line_settings',dataX=xvar, dataY=yvar, $
                           linestyle=obj_new('spd_ui_line_style', color=color,thick=1.0),$
                           symbol=obj_new('spd_ui_symbol',color=color,size=10.,id=4,name='Diamond'),$
                           plotpoints=4)

endelse

; add label for trace to labels object
; 

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

yfont = 2
yformat = 3
ysize = 11

if obj_valid(yAxisTemplate) then begin

  yAxisTemplate->getProperty,labels=yTlabels
  
  if obj_valid(yTlabels) && obj_isa(yTlabels,'IDL_Container') then begin
  
    yTlabel = yTlabels->get(/all)

    if datanum lt n_elements(yTlabel) && obj_valid(yTlabel[datanum]) then begin
      yTlabel[datanum]->getProperty,font=yfont,format=yformat,size=ysize
    endif
  
  endif

endif

;ylabels->add,obj_new('spd_ui_text', value=ylabel, font=2, format=3, size=8, $
ylabels->add,obj_new('spd_ui_text', value=ylabeltext, font=yfont, format=yformat, size=ysize, $
                    color=color)
xlabels->add,obj_new('spd_ui_text', value=xlabeltext, font=xfont, format=xformat, size=xsize,$
                    color=xcolor, show=keyword_set(xlabeltext))

; ------ Add titles (from information that was set when data was imported)

; add xtitle and subtitle
if obj_valid(ydataSettings) then begin
  xtitletext = ydataSettings->getxtitle()
  xsubtitletext = ydataSettings->getxsubtitle()
endif else begin
  xtitletext = ''
  xsubtitletext = ''
endelse

; First check if there is already a title. If there is a title don't overwrite (user may have manually set title)
xAxis->GetProperty,subtitleobj=xsubtitleobj,titleobj=xtitleobj
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
  xtitleobj = obj_new('spd_ui_text', value=xtitletext, font=xfont, format=xformat, size=xsize,$
                    color=xcolor, show=1)
                    xfont = 2
  xAxis->SetProperty, titleobj=xtitleobj,/notouched
endif
if obj_valid(xsubtitleobj) then begin
  xsubtitleobj->getProperty, value=xsubtitlecur
endif else xsubtitlecur = ''
if xsubtitlecur eq '' then begin
  xformat = 3
  xsize = 10
  xcolor = [0,0,0]

  if obj_valid(xAxisTemplate) then begin

    xAxisTemplate->getProperty,subtitleobj=xTsubtitle
  
    if obj_valid(xTsubtitle) then begin
      xTsubtitle->getProperty,font=xfont,format=xformat,size=xsize,color=xcolor
    endif

  endif
  xsubtitleobj = obj_new('spd_ui_text', value=xsubtitletext, font=xfont, format=xformat, size=xsize,$
                    color=xcolor, show=1)
  xAxis->SetProperty, subtitleobj=xsubtitleobj,/notouched
endif
; Add y subtitle and title


if obj_valid(ydataSettings) then begin
  ytitletext = ydataSettings->getytitle()
  ysubtitletext = ydataSettings->getysubtitle()
endif else begin
  ytitletext = ''
  ysubtitletext = ''
endelse

; First check if there is already a title. If there is a title don't overwrite (user may have manually set title)
yAxis->GetProperty,subtitleobj=ysubtitleobj,titleobj=ytitleobj
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
  ytitleobj = obj_new('spd_ui_text', value=ytitletext, font=yfont, format=yformat, size=ysize,$
                    color=ycolor, show=1)
  yAxis->SetProperty, titleobj=ytitleobj,/notouched
endif
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
  ysubtitleobj = obj_new('spd_ui_text', value=ysubtitletext, font=yfont, format=yformat, size=ysize,$
                    color=ycolor, show=1)
  yAxis->SetProperty, subtitleobj=ysubtitleobj,/notouched
endif
; set x and y axis properties
xAxis->SetProperty, labels=xlabels, titleobj=xtitleobj, subtitleobj=xsubtitleobj, isTimeAxis=xistime,/notouched

yAxis->SetProperty, labels=ylabels, isTimeAxis=yistime,/notouched


;change annotation format to account for long time ranges/date changes
if xistime then begin
  
  trange = xobj->getrange()
  t0 = time_struct(trange[0])
  t1 = time_struct(trange[1])
  
  if t1.daynum - t0.daynum gt 2 then begin
    
    ;catch long time periods
    large = t1.daynum - t0.daynum ge 7
    
    ;catch month/year boundaries
    if t0.year ne t1.year then begin
      style = large ? 0:1  ; date|date:hr:min
    endif else begin
      style = large ? 7:8  ; month:day|month:day:hr:min
    endelse
  
    xAxis->setProperty, annotatestyle = style, /notouched

    ;lessen number of major ticks for date:hr:min format (xaxis only)
    if ~large && style eq 1 then begin
      xAxis->setProperty, nummajorticks = 4, /notouched ;default is 5
    endif
    
  endif
  
endif

;similar checks as above in case yaxis is time
if yistime then begin

  trange = yobj->getrange()
  t0 = time_struct(trange[0])
  t1 = time_struct(trange[1])
  
  if t1.daynum - t0.daynum gt 2 then begin
    
    ;catch long time periods  
    large = t1.daynum - t0.daynum ge 7
    
    ;catch month/year boundaries
    if t0.year ne t1.year then begin
      style = large ? 0:1  ; date|date:hr:min
    endif else begin
      style = large ? 7:8  ; month:day|month:day:hr:min
    endelse
  
    yAxis->setProperty, annotatestyle=style, /notouched
    
  endif
endif 

panel->SetProperty, traceSettings=traceSettings, xAxis=xAxis, yAxis=yAxis

end
