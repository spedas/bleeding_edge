;object graphics example data  
pro example_data,info

  ;load data normally
  timespan,'2007-03-23'
  
  thm_init
  
 ; !SPEDAS.NO_DOWNLOAD = 1
  
  thm_load_state,probe='a'
  thm_load_esa,probe='a'
  thm_load_sst,probe='a',level=2
  
  get_data,'tha_state_pos',data=d
  
  d.y[330:500,*] = !VALUES.f_nan
  
  store_data,'tha_state_pos',data=d
   
  ;add data to loadedData data structure
  if ~info.loadedData->add('tha_state_pos',mission='THEMIS',observatory='tha',instrument='state') then begin
    ok = error_message('error adding data to loadedData',/traceback)
    return
  endif
  
  ;add data to loadedData data structure
  if ~info.loadedData->add('tha_state_vel',mission='THEMIS',observatory='tha',instrument='state') then begin
    ok = error_message('error adding data to loadedData',/traceback)
    return
  endif

  if ~info.loadedData->add('tha_peif_en_eflux',mission='THEMIS',observatory='tha',instrument='esa') then begin
    ok = error_message('error adding data to loadedData',/traceback)
    return
  endif
  
  if ~info.loadedData->add('tha_peib_en_eflux',mission='THEMIS',observatory='tha',instrument='esa') then begin
    ok = error_message('error adding data to loadedData',/traceback)
    return
  endif
  
  if ~info.loadedData->add('tha_psif_en_eflux',mission='THEMIS',observatory='tha',instrument='esa') then begin
    ok = error_message('error adding data to loadedData',/traceback)
    return
  endif

  ;create one panel with 2 traces
  panels = OBJ_NEW('IDL_Container')
  
  panelTitle = obj_new('spd_ui_text',value="I'm the first panel title",font=0,format=0,color=[110,0,0],size=14)
  
  panelSettings = obj_new('spd_ui_panel_settings',row=1,col=1,cspan=1,rspan=1,backgroundcolor=[255,203,164],titleobj=panelTitle,framethick=2.0,titleMargin=25.)

  symbol = obj_new('spd_ui_symbol',id=5,size=10.,show=1,color=[0,0,0])

  traceSettings = OBJ_NEW('IDL_Container')

  traceSettings->add,obj_new('spd_ui_line_settings',dataX='tha_state_pos_time',dataY='tha_state_pos_x',linestyle=obj_new('spd_ui_line_style',color=[255,0,0],thick=2.0),symbol=symbol,plotPoints=4)
  traceSettings->add,obj_new('spd_ui_line_settings',dataX='tha_state_pos_time',dataY='tha_state_pos_y',linestyle=obj_new('spd_ui_line_style',color=[0,255,0],thick=2.0),symbol=symbol,plotPoints=4)
  traceSettings->add,obj_new('spd_ui_line_settings',dataX='tha_state_pos_time',dataY='tha_state_pos_z',linestyle=obj_new('spd_ui_line_style',color=[0,0,255],thick=2.0),symbol=symbol,plotPoints=4)
  majorGrid = obj_new('spd_ui_line_style',color=[110,110,110],thickness=5.0,id=0,opacity=.5)
  minorGrid = obj_new('spd_ui_line_style',color=[255,0,0],thickness=2.0,id=0,opacity=.5)
  
  variables = OBJ_NEW('IDL_Container')
  
  var = obj_new('spd_ui_variable',$
                 fieldname='tha_state_pos_x',$
                ; controlname='1:tha_state_pos_time',$
                 text=obj_new('spd_ui_text',value='pos_x: ',size=8),$
                 format=11)
               ;  userange=0)
                 
  variables->add,var
  
  var = obj_new('spd_ui_variable',$
                 fieldname='tha_state_pos_y',$
               ;  controlname='1:tha_state_pos_time',$
                 text=obj_new('spd_ui_text',value='pos_y: ',size=8),$
                 format=11)
               ;  userange=0,$
                 
  variables->add,var
  
  labels = obj_new('IDL_Container')
  
  labels->add,obj_new('spd_ui_text',value='tha_state_pos_time',color=[0,0,0],size=8.)
  
  xAxis = obj_new('spd_ui_axis_settings', $
                isTimeAxis=1, $
                orientation=0, $
                majorLength=10., $
                minorLength=5., $
                topPlacement=1, $
                bottomPlacement=1, $
                tickStyle=0, $
                majorTickAuto=1, $
                numMajorTicks=4, $
                minorTickAuto=1, $
                numMinorTicks=2, $
               ; majorGrid=majorGrid, $
               ; minorGrid=minorGrid, $
                dateString1="%date", $
                dateString2="%time", $
                showdate=1,$
                annotateAxis=1,$
                placeAnnotation=0,$
                AnnotateMajorTicks=1,$
                annotateRangeMax=0,$
                annotateRangeMin=0,$
                annotateStyle=5,$
                annotateTextObject=obj_new('spd_ui_text',font=2,format=1,size=8.,color=[110,0,110]),$
                scaling=0,$
                rangeMargin=0.,$
                margin=15.,$
                annotateOrientation=0,$
                labels=labels,$
                stacklabels=0, $
                rangeoption=0 $
             ;   minFixedRange=time_double('2007-03-22'),$
             ;   maxFixedRange=time_double('2007-03-25') $
                )
       
  majorGrid = obj_new('spd_ui_line_style',color=[110,110,110],thickness=5.0,id=0)
                
  labels = obj_new('IDL_Container')
                
  labels->add,obj_new('spd_ui_text',value='tha_state_pos_x',color=[255,0,0])
  labels->add,obj_new('spd_ui_text',value='tha_state_pos_y',color=[0,255,0])
  labels->add,obj_new('spd_ui_text',value='tha_state_pos_z',color=[0,0,255])
                
  yAxis = obj_new('spd_ui_axis_settings', $
                 isTimeAxis=0,$
                 orientation=1,$
                 majorLength=10.,$
                 minorLength=5.,$
                 topPlacement=1,$
                 bottomPlacement=1,$
                 tickStyle=0,$
                 majorTickAuto=1,$
                 numMajorTicks=1,$
                 minorTickAuto=1,$
                 numMinorTicks=3,$
                ; majorGrid=majorGrid,$
                ; minorGrid=minorGrid,$
                 /lineatzero,$
                 annotateAxis=1,$
                 placeAnnotation=0,$
                 AnnotateMajorTicks=1,$
                 annotateRangeMax=1,$
                 annotateRangeMin=1,$
                 annotateStyle=9,$
                 annotateTextObject=obj_new('spd_ui_text',font=1,format=1,size=8.,color=[0,110,0]),$
                 rangeOption=0,$
                 rangeMargin=.25,$
                 scaling=0,$
                 annotateOrientation=1, $
                 margin=15.,$
                 labels=labels, $
                 stackLabels=1 $
                )
  
  
  panel = OBJ_NEW('spd_ui_panel',0,$
                  xAxis = xAxis, $
                  yAxis = yAxis, $
                  traceSettings=traceSettings, $
                  settings=panelSettings, $
                  variables=variables,$
                  name='Panel 1:')
  
  panels->add,panel
  
  panelTitle = obj_new('spd_ui_text',value="I'm the second panel title",color=[0,0,255],format=2)
  
  panelSettings =obj_new('spd_ui_panel_settings',row=2,col=1,rspan=1,cspan=1,backgroundColor=[155,221,255],titleobj=panelTitle,framecolor=[255,0,0])
  
  traceSettings = OBJ_NEW('IDL_Container')

  traceSettings->add,obj_new('spd_ui_line_settings',dataX='tha_state_vel_time',dataY='tha_state_vel_x',/mirrorline,plotPoints=4)

  majorGrid = obj_new('spd_ui_line_style',color=[110,110,110],thickness=2.0,id=3,opacity=.5)
  minorGrid = obj_new('spd_ui_line_style',color=[255,0,0],thickness=2.0,id=0,opacity=.5)
  

  xAxis = obj_new('spd_ui_axis_settings', $
                isTimeAxis=1, $
                orientation=0, $
                majorLength=10., $
                minorLength=3., $
                topPlacement=1, $
                bottomPlacement=1, $
                tickStyle=2, $
                majorTickAuto=1, $
                numMajorTicks=6, $
                minorTickAuto=1, $
                numMinorTicks=3, $
                dateString1="%date", $
                dateString2="%time", $
                majorGrid=majorGrid,$
              ;  minorGrid=minorGrid,$
                showdate=1,$
                annotateAxis=1,$
                placeAnnotation=0,$
                AnnotateMajorTicks=1,$
                annotateRangeMin=0,$
                annotateStyle=5,$
                rangeMargin=0.,$
                annotateOrientation=0, $
                annotateTextObject=obj_new('spd_ui_text',font=2,format=1,size=9.,color=[0,0,110]) $
           )
           
  yAxis = obj_new('spd_ui_axis_settings', $
                 isTimeAxis=0,$
                 orientation=1,$
                 majorLength=10.,$
                 minorLength=5.,$
                 topPlacement=1,$
                 bottomPlacement=1,$
                 tickStyle=0,$
                 majorTickAuto=1,$
                 numMajorTicks=5,$
                 minorTickAuto=1,$
                 numMinorTicks=3,$
                 majorGrid=majorGrid,$
                ; minorGrid=minorGrid,$
                 /lineatzero,$
                 annotateAxis=1,$
                 placeAnnotation=0,$
                 AnnotateMajorTicks=1,$
                 annotateStyle=9,$
                 rangeMargin=.05,$
              ;   majorGrid=majorGrid,$
                 scaling=0,$
                 annotateOrientation=0 $
                 )

  panel = OBJ_NEW('spd_ui_panel',1, $
                  xAxis =xAxis, $
                  yAxis =yAxis, $
                  settings=panelSettings, $
                  traceSettings=traceSettings, $
                  name='Panel 2:')
  
  panels->add,panel
  
  panelTitle = obj_new('spd_ui_text',value="I'm the third panel title",color=[0,0,255],format=2)
  
 ; panelSettings =obj_new('spd_ui_panel_settings',row=1,col=2,rspan=3,cspan=2,backgroundColor=[255,221,155],titleobj=panelTitle,framecolor=[255,0,0])
   panelSettings =obj_new('spd_ui_panel_settings',row=3,col=1,rspan=1,cspan=1,backgroundColor=[0,0,0],titleobj=panelTitle,framecolor=[255,0,0])
  
  traceSettings = OBJ_NEW('IDL_Container')
  
  traceSettings->add,obj_new('spd_ui_spectra_settings',dataX='tha_peif_en_eflux_time',dataY='tha_peif_en_eflux_yaxis',dataZ='tha_peif_en_eflux')
  traceSettings->add,obj_new('spd_ui_spectra_settings',dataX='tha_peib_en_eflux_time',dataY='tha_peib_en_eflux_yaxis',dataZ='tha_peib_en_eflux')
  traceSettings->add,obj_new('spd_ui_spectra_settings',dataX='tha_psif_en_eflux_time',dataY='tha_psif_en_eflux_yaxis',dataZ='tha_psif_en_eflux')
  
  markerContainer = obj_new('IDL_Container')  
  
  markerSettings = obj_new('spd_ui_marker_settings',$
                           vertPlacement=3,$
                           label = obj_new('spd_ui_text',value='hello',show=1,color=[255,0,255]), $
                           drawOpaque = 1. $                            
                           )
  
  marker = obj_new('spd_ui_marker',$
                    range=[time_double('2007-03-23/20:00:00'),time_double('2007-03-24/02:00:00')],$
                    settings=markerSettings)

  markerContainer->add,marker                      
  
  ;marker = obj_new('spd_ui_marker',$
  ;                range=[time_double('2007-03-23/03:00:00'),time_double('2007-03-23/09:00:00')])

  ;markerContainer->add,marker   
  
  markerSettings = obj_new('spd_ui_marker_settings',$
                            vertPlacement=0,$
                            label = obj_new('spd_ui_text',value="I'm a marker title.",show=1,color=[255,0,255]), $   
                            drawOpaque = 0. $    
                            )
                            
  marker = obj_new('spd_ui_marker',$
                    range=[time_double('2007-03-23/04:00:00'),time_double('2007-03-23/08:00:00')],$
                    settings=markerSettings)

  markerContainer->add,marker 
  
  xAxis = obj_new('spd_ui_axis_settings', $
                isTimeAxis=1, $
                orientation=0, $
                majorLength=10., $
                minorLength=3., $
                topPlacement=1, $
                bottomPlacement=1, $
                tickStyle=0, $
                majorTickAuto=1, $
                numMajorTicks=6, $
                minorTickAuto=1, $
                numMinorTicks=3, $
                dateString1="%date", $
                dateString2="%time", $
                showdate=1,$
                annotateAxis=1,$
                placeAnnotation=0,$
                AnnotateMajorTicks=1,$
                annotateRangeMin=0,$
                annotateStyle=5,$
                rangeMargin=0.,$
                scaling=0,$
                annotateOrientation=0,$
                margin=10, $
                annotateTextObject=obj_new('spd_ui_text',font=2,format=1,size=9.,color=[70,0,180])$
                )
           
  yAxis = obj_new('spd_ui_axis_settings', $
                 isTimeAxis=0,$
                 orientation=1,$
                 majorLength=10.,$
                 minorLength=5.,$
                 topPlacement=1,$
                 bottomPlacement=1,$
                 tickStyle=0,$
                 majorTickAuto=1,$
                 numMajorTicks=2,$
                 minorTickAuto=1,$
                 numMinorTicks=3,$
                 lineatzero=0,$
                 majorGrid=majorGrid,$
                 annotateAxis=1,$
                 placeAnnotation=0,$
                 annotateTextObject=obj_new('spd_ui_text',font=1,format=3,size=7.),$
                 AnnotateMajorTicks=1,$
                 annotateOrientation=1,$
                 annotateStyle=9,$
                 annotateRangeMax=1,$
                 rangeMargin=.00,$
              ;   majorgrid=majorgrid,$
                 margin=5.,$
                 scaling=1 $
                )
                
  zAxis = obj_new('spd_ui_zaxis_settings', $
               colorTable = 6,$
               fixed = 0,$
               tickNum = 2, $
               minorTickNum = 3,$
               scaling = 1, $
               annotationStyle = 9, $
               margin = 5, $
               annotateTextObject = obj_new('spd_ui_text',size=7.,font=1,format=3), $
               annotationOrientation = 1, $
               labelTextObject = obj_new('spd_ui_text',value='FLUX in eV'),$
               labelOrientation=1,$
               labelmargin=15,$
               placement=3)

  panel = OBJ_NEW('spd_ui_panel',2, $
                  xAxis =xAxis, $
                  yAxis =yAxis, $
                  zAxis = zAxis, $
                  settings=panelSettings, $
                  traceSettings=traceSettings, $
                  name='Panel 3:',$
                  markers=markerContainer)
  
  panels->add,panel
 
  ;create header & footer text objects
  title = obj_new('spd_ui_text',value="I'm a header",format=1)
  footer = obj_new('spd_ui_text',value="And I'm a footer",font=4,format=2)
  labels = obj_new('spd_ui_text',font=2,format=1,size=8.)
  
  windowsettings = obj_new('spd_ui_page_settings',title=title,footer=footer,labels=labels,xpanelSpacing=60,ypanelspacing=60)
  
  windowObj = info.windowStorage->getActive()
  if Obj_Valid(windowObj[0]) THEN BEGIN
    windowObj[0]->SetProperty, nrows=4,ncols=1,panels=panels,settings=windowsettings
   ; a = systime(/seconds)
   ; windowObj->repack ;this is just a test
   ; print,systime(/seconds)-a
;    ok = error_message('Problem adding window to windows object',/traceback)
;    return
  endif

;  if ~info.windowStorage->add(name='ExampleWindow',isActive=1,nrows=4,ncols=1,panels=panels,settings=windowsettings) then begin
;    ok = error_message('Problem adding window to windows object',/traceback)
;    return
;  endif

  ; *********** this is temporary and eventually needs to be removed  *************
  ; *********** added so Jim L. could test his marker code ************
  

;  spd_ui_create_marker, info
;  FOR i=0,N_Elements(info.markerButtons)-1 DO Widget_Control, info.markerButtons[i], sensitive=1
    
  info.drawObject->update,info.windowStorage,info.loadedData
  info.drawObject->draw
  info.drawObject->setCursor,[.5,.33]
  info.drawObject->vBarOn,/all
  info.drawObject->legendOn,/all
 ; info.drawObject->markerOn
 ; info.drawObject->markeroff
 
 ; stop
  
end
