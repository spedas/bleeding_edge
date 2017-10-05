;+ 
;NAME:  
;  spd_ui_make_default_panel
;  
;PURPOSE:
;  Routine that creates a default panel on current window
;  
;CALLING SEQUENCE:
;  spd_ui_make_default_panel, windows_object, outpanel=outpanel, row=row, col=col
;  
;INPUT:
;  windows:  the structure that stores all the windows, will place the default 
;            panel on the current window.
;            
;KEYWORDS:
;  outpanel = (optional) named variable in which the new panel object will be
;             returned.
;  row = (optional) particular row at which the panel should be placed, if not
;        set the panel is placed at the bottom of the layout for the specified
;        column.
;  col = (optional) particular column at which the panel should be placed, if
;        not set the panel is placed at the bottom of the first column.
;  trange = (optional) set the time range of the panel
;        
;OUTPUT:
;  none
;
;--------------------------------------------------------------------------------

pro spd_ui_make_default_panel, windows,template,outpanel=outpanel, row=row, col=col

compile_opt idl2, hidden

; get active window
cwindow = windows->GetActive()


; get active window's panels and the number of rows/cols in window
cWindow->GetProperty, Panels=panels, nRows=nRows, nCols=nCols


; check if col keyword set and set window's # of columns appropriately
if ~keyword_set(col) then col=1

if col gt nCols then begin
  nCols = col
  cWindow->SetProperty, nCols=nCols
endif


; get panel objects
if not Obj_Valid(panels) then panelObjs=[''] else panelObjs = panels->Get(/All)

if obj_valid(panelObjs[0]) then begin
  npanels = n_elements(panelObjs)
;  panelNames = strarr(npanels)

  for i = 0,npanels-1 do begin ; loop over panels
  
    cPanel = panelObjs[i]

    ; get panel layout structure
    if i eq 0 then panelLayout = cPanel->getLayoutStructure() $
      else panelLayout = [panelLayout, cPanel->getLayoutStructure()]
  
  endfor
  
endif else begin
  npanels=0
;  panelNames=''
endelse


if npanels eq 0 then begin
  maxid = -1 ; set max panel id
  maxrow = 0
endif else begin
  maxid = max(panelLayout.id) ; get max panel id
  
  
  ; get indexes and # of panels in column
  ColPanels = where(panelLayout.col eq col, nColPanels)


  ; get max number of rows in col
  if nColPanels eq 0 then begin
    maxrow = 0
  endif else begin
    ;subtract one because row is not 0 indexed, so panel at row 1, would end up having a maxrow of 2
    maxrow = max(panelLayout[ColPanels].row+panelLayout[ColPanels].rspan)-1
  endelse
  
endelse


; check if user set row is greater than max row of column 
if keyword_set(row) then begin
  if row gt maxrow then maxrow=row - 1
  setrow = row
endif else setrow = maxrow + 1


; set number of rows in window
if (maxrow + 1) gt nRows then begin
  nRows = maxrow + 1
  cWindow->SetProperty, nRows=nRows
endif

if obj_valid(template) then begin
  template->GetProperty,panel=templatePanel,x_axis=templateXaxis,y_axis=templateYaxis,z_axis=templateZaxis,legend=templateLegend
endif

if obj_valid(templatePanel) then begin

  panelSettings = templatePanel->Copy()
  
  ;prevent saved location & size settings from being used
  panelSettings->setProperty, row=setrow, col=col, rspan=1, cspan=1, $
    bottom=0, left=0, width=0, height=0, $ 
    bvalue=-1d, lvalue=-1d, wvalue=-1d, hvalue=-1d 
  
  ;prevent saved title text from being used
  panelsettings->getProperty, titleObj=titleObj
  titleObj->setProperty, value=''
  
endif else begin
  ; create panel_settings object
  panelSettings = obj_new('spd_ui_panel_settings', row=setrow, col=col, rspan=1, $
                        cspan=1, backgroundColor=[255,255,255],framecolor=[0,0,0])
endelse

if obj_valid(templateXaxis) then begin
  xAxis = templateXaxis->copy()
  xAxis->getProperty,labels=xLabels
  if obj_valid(xLabels) then begin
    xLabels->remove,/all
  endif
  
  ;major ticks should not be copied from template
  xAxis->setProperty,majortickauto=1  
  
endif else begin

  ; create x-axis object
  xAxis = obj_new('spd_ui_axis_settings', $
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
            rangeMargin=0.,$
            margin=15.,$
            annotateOrientation=0,$
            titleOrientation=0,$
            titleMargin=15,$
            placeTitle=0,$
            stacklabels=0, $
            autoticks=1 $
            )
endelse

if obj_valid(templateYaxis) then begin
  yAxis = templateYaxis->copy()
  yAxis->getProperty,labels=yLabels
  if obj_valid(yLabels) then begin
    yLabels->remove,/all
  endif
  
  ;major ticks should not be copied from template
  yAxis->setProperty,majortickauto=1
    
endif else begin
  ; create y-axis object
  yAxis = obj_new('spd_ui_axis_settings', $
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
             numMinorTicks=4,$
            ; majorGrid=majorGrid,$
            ; minorGrid=minorGrid,$
             /lineatzero,$
             annotateAxis=1,$
             placeAnnotation=0,$
             AnnotateMajorTicks=1,$
             annotateRangeMax=0,$
             annotateRangeMin=0,$
             annotateStyle=4,$
             annotateTextObject=obj_new('spd_ui_text',font=2,size=11.,color=[0,0,0]),$
             rangeOption=0,$
             rangeMargin=.25,$
             scaling=0,$
             annotateOrientation=0, $
             margin=5.,$;this is the label margin, for spec plots it is changed again in spd_ui_make_default_specplot
             titleOrientation=1,$
             titleMargin=35.,$; for spec plots this is changes in spd_ui_make_default_specplot
             placeTitle=0,$
             stackLabels=0, $
             autoticks=1 $
             )
endelse

if obj_valid(templateLegend) then  begin
    legendSettings = templateLegend
endif else begin
    legendSettings = obj_new('spd_ui_legend')
endelse


; create panel object
panel = OBJ_NEW('spd_ui_panel', maxid+1, $
                xAxis = xAxis, yAxis = yAxis, $
                settings=panelSettings, $
                legendSettings=legendSettings, labelmargin=20)


; add new panel to panels object 
panels->add,panel

outpanel = panel

end
