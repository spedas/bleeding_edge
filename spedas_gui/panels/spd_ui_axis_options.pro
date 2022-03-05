;+
;NAME:
; spd_ui_axis_options
;PURPOSE:
; User interface for modifying axis settings
;
;CALLING SEQUENCE:
; spd_ui_axis, gui_id
;
;INPUT:
; gui_id = the id number of the widget that calls this
;
;OUTPUT:
;
;HISTORY:
;
;(lphilpott 07/2011) Reorganised code: removed widget ids from the state structure, these should now be found using find_by_uname. Removed
;duplicate information eg panels, panelobjs from state structure. These can now be found using the helper methods spd_ui_axis_options_getpanelobjs etc.
;(lphilpott 02/2012) QA: Changed labels to have number prefixed in combobox to avoid problems with identical labels on linux.
;In the process removed the spaces that were added to empty labels to distinguish them under linux.
;Also changed truncation to avoid problem with combobox arrow being pushed over if label became too long.
;NB: This problem doesn't seem to happen with the panel title on Panel Options window.
;If we could work out why the panel title combobox worked there it would be better to fix axis label title to match rather than truncating.
;
;$LastChangedBy: jwl $
;$LastChangedDate: 2022-03-04 11:48:01 -0800 (Fri, 04 Mar 2022) $
;$LastChangedRevision: 30648 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/spedas_gui/panels/spd_ui_axis_options.pro $
;
;---------------------------------------------------------------------------------
;
;
;
;
;
;+
; set_minor
;SPD_UI_PROPAGATE_AXIS.PRO
;
;Given STATE propagate the current AXISSETTINGS from the current panel to all other panels.
;
;W.M.Feuerstein, 11/10/2008.
;
;-

pro SPD_UI_PROPAGATE_AXIS , state, apply_to_all_panels

  compile_opt idl2, hidden
  
  ;Get correct axis:
  ;*****************
  ; And panelobjs array, and current panel
  
  panelobjs = spd_ui_axis_options_getpanelobjs(state)
  currpanelobj = spd_ui_axis_options_getcurrentpanel(state)
  curraxissettings = spd_ui_axis_options_getaxis(state)
  
  IF N_Elements(panelobjs) GT 0 && Obj_Valid(panelobjs[0]) THEN BEGIN
    for i=0,n_elements(panelobjs)-1 do begin
      if i ne state.axispanelselect then begin
        ;axissettings = curraxissettings->Copy()
        temppanelobj = panelobjs[i]
        case state.axisselect of
          0: temppanelobj->getProperty,xaxis = newaxissettings
          1: temppanelobj->getProperty,yaxis = newaxissettings
        ; 2: temppanelobj->SetProperty,zaxis = axissettings ;z axis doesn't work with this panel
        endcase
        
        ;Range
        if apply_to_all_panels eq 0 then begin
          currAxisSettings->getProperty,$
            rangeOption=rangeOption,$
            scaling=scaling,$
            isTimeAxis=isTimeAxis,$
            rangeMargin=rangeMargin,$
            boundScaling=boundScaling,$
            minBoundRange=minBoundRange,           $ ; range for bounded autoscaling
            maxBoundRange=maxBoundRange,           $ ; max range for bounded autoscaling
            minFixedRange=minFixedRange,           $ ; min range value if fixed scaling
            maxFixedRange=maxFixedRange              ; max range value if fixed scaling
            
          newAxisSettings->setProperty,$
            rangeOption=rangeOption,$
            scaling=scaling,$
            isTimeAxis=isTimeAxis,$
            rangeMargin=rangeMargin,$
            boundScaling=boundScaling,$
            minBoundRange=minBoundRange,           $ ; range for bounded autoscaling
            maxBoundRange=maxBoundRange,           $ ; max range for bounded autoscaling
            minFixedRange=minFixedRange,           $ ; min range value if fixed scaling
            maxFixedRange=maxFixedRange              ; max range value if fixed scaling
        endif
        
        ;Tick
        if apply_to_all_panels eq 1 then begin
          currAxisSettings->getProperty,$
            MajorTickEvery=majortickevery,         $ ; display major ticks every
            MinorTickEvery=minortickevery,         $ ; display major ticks every
            MajorTickUnits=majortickunits,         $ ; major tick units (sec, hr, min, day, none)
            MinorTickUnits=minortickunits,         $ ; major tick units (sec, hr, min, day, none)
            MajorTickAuto=majortickauto,           $ ; set to automatically figure out major ticks
            MinorTickAuto=minortickauto,           $ ; set to automatically figure out minor ticks
            FirstTickAuto=firsttickauto,           $ ; obsolete
            NumMajorTicks=nummajorticks,           $ ; number of major ticks
            NumMinorTicks=numminorticks,           $ ; number of major ticks
            FirstTickAt=firsttickat,               $ ; value where first tick should be
            FirstTickUnits=firsttickunits,         $ ; first tick unit (sec, hr, min, day, none)
            TickStyle=tickstyle,                   $ ; style (inside, outside, both)
            BottomPlacement=bottomplacement,       $ ; flag set if ticks should be on bottom axis
            TopPlacement=topplacement,             $ ; flag set if ticks should be on top axis
            MajorLength=majorlength,               $ ; length of major tick
            MinorLength=minorlength,               $ ; length of minor tick
            autoTicks=autoTicks,                   $
            logminorticktype=logminorticktype
            
          newAxisSettings->setProperty,$
            MajorTickEvery=majortickevery,         $ ; display major ticks every
            MinorTickEvery=minortickevery,         $ ; display major ticks every
            MajorTickUnits=majortickunits,         $ ; major tick units (sec, hr, min, day, none)
            MinorTickUnits=minortickunits,         $ ; major tick units (sec, hr, min, day, none)
            MajorTickAuto=majortickauto,           $ ; set to automatically figure out major ticks
            MinorTickAuto=minortickauto,           $ ; set to automatically figure out minor ticks
            FirstTickAuto=firsttickauto,           $ ; obsolete
            NumMajorTicks=nummajorticks,           $ ; number of major ticks
            NumMinorTicks=numminorticks,           $ ; number of major ticks
            FirstTickAt=firsttickat,               $ ; value where first tick should be
            FirstTickUnits=firsttickunits,         $ ; first tick unit (sec, hr, min, day, none)
            TickStyle=tickstyle,                   $ ; style (inside, outside, both)
            BottomPlacement=bottomplacement,       $ ; flag set if ticks should be on bottom axis
            TopPlacement=topplacement,             $ ; flag set if ticks should be on top axis
            MajorLength=majorlength,               $ ; length of major tick
            MinorLength=minorlength,               $ ; length of minor tick
            autoTicks=autoTicks,                   $
            logminorticktype=logminorticktype
            
        endif
        
        ;Grid
        if apply_to_all_panels eq 2 then begin
          currAxisSettings->getProperty,$
            majorGrid=majorgrid,                   $ ; linestyle object of major grid
            minorGrid=minorgrid                      ; linestyle object of minor grid
            
          newAxisSettings->setProperty,$
            majorGrid=(majorgrid->copy()),                   $ ; linestyle object of major grid
            minorGrid=(minorgrid->copy())                      ; linestyle object of minor grid
            
          currpanelobj->GetProperty, Settings=panelSettings
          IF obj_valid(panelSettings) THEN panelSettings->GetProperty, framethick=framethick $
          ELSE framethick=1
          
          IF obj_valid(panelobjs[i]) THEN panelobjs[i]->GetProperty, Settings=newSettings
          IF obj_valid(newSettings) THEN newSettings->SetProperty, framethick=framethick
        endif
        
        ;Annotation
        if apply_to_all_panels eq 3 then begin
          currAxisSettings->getProperty,$
            LineAtZero=lineatzero,                 $ ; flag set if line is drawn at zero
            showdate=showdate,                     $ ; flag set if date strings are shown
            DateString1=datestring1,               $ ; string format of date for line 1
            DateString2=datestring2,               $ ; string format of date for line 1
            DateFormat1=dateformat1,               $ ; format of date for line 1 (annotation purposes)
            DateFormat2=dateformat2,               $ ; format of date for line 2
            AnnotateAxis=annotateaxis,             $ ; flag set to annotate along axis
            PlaceAnnotation=placeannotation,       $ ; placement of annotation (bottom or top)
            AnnotateMajorTicks=annotatemajorticks, $ ; set flag if major ticks are annotated
            annotateEvery=annotateevery, $ ; value where annotation of major ticks occur
            annotateUnits=annotateunits, $ ; units for major tick value (sec, min, hr, day)
            FirstAnnotation=firstannotation,       $ ; value where annotation of first major tick occurs
            FirstAnnotateUnits=firstannotateunits, $ ; units for major tick value (sec, min, hr, day)
            annotateRangeMin=annotaterangemin,   $ ; set flag to annotate the range min tick
            AnnotateRangeMax=annotaterangemax,   $ ; set flag to annotate the range max tick
            AnnotateStyle=annotatestyle,           $ ; format style of tick (h:m, doy, time, etc....)
            annotateOrientation=annotateOrientation,$ ;orientation of the annotations: 0(horizontal) & 1(vertical)
            annotateTextObject=annotateTextObject, $  ; Text object that represents that textual style of annotations
            annotateExponent=annotateExponent
            
          newAxisSettings->setProperty,$
            LineAtZero=lineatzero,                 $ ; flag set if line is drawn at zero
            showdate=showdate,                     $ ; flag set if date strings are shown
            DateString1=datestring1,               $ ; string format of date for line 1
            DateString2=datestring2,               $ ; string format of date for line 1
            DateFormat1=dateformat1,               $ ; format of date for line 1 (annotation purposes)
            DateFormat2=dateformat2,               $ ; format of date for line 2
            AnnotateAxis=annotateaxis,             $ ; flag set to annotate along axis
            PlaceAnnotation=placeannotation,       $ ; placement of annotation (bottom or top)
            AnnotateMajorTicks=annotatemajorticks, $ ; set flag if major ticks are annotated
            annotateEvery=annotateevery, $ ; value where annotation of major ticks occur
            annotateUnits=annotateunits, $ ; units for major tick value (sec, min, hr, day)
            FirstAnnotation=firstannotation,       $ ; value where annotation of first major tick occurs
            FirstAnnotateUnits=firstannotateunits, $ ; units for major tick value (sec, min, hr, day)
            annotateRangeMin=annotaterangemin,   $ ; set flag to annotate range min tick
            AnnotateRangeMax=annotaterangemax,   $ ; set flag to annotate range max tick
            AnnotateStyle=annotatestyle,           $ ; format style of tick (h:m, doy, time, etc....)
            annotateOrientation=annotateOrientation,$ ;orientation of the annotations: 0(horizontal) & 1(vertical)
            annotateTextObject=(annotateTextObject->copy()),$   ; Text object that represents that textual style of annotations
            annotateExponent=annotateExponent
        endif
        
        ;Title
        if apply_to_all_panels eq 4 then begin ;do not change all titles
          currAxisSettings->getProperty,$
            titleObj=titleObj,                       $ ; title obj
            subtitleObj=subtitleObj,                 $ ; subtitle obj
            placeTitle=placeTitle,                   $ ; placement of title (left/bottom or right/top)
            titleorientation=titleorientation,       $ ; orientation of title (0=horizontal, 1=vertical)
            titlemargin=titlemargin,                 $ ; number of points for title margin
            lazytitles=lazytitles,                   $ ; A flag to determine whether underscores should be converted to carriage returns
            showtitle=showtitle                        ; flag for whether the title should be displayed
            
            ;Keep the old values for title and subtitle text
           newAxisSettings->getProperty,  $
            titleObj=oldtitleObj,         $  
            subtitleObj=oldsubtitleObj  
           oldTitleStr = oldtitleObj->GetValue()
           oldSubTitleStr = oldsubtitleObj->GetValue()
           newTitle = titleObj->copy()
           newSubTitle = subtitleObj->copy()
           newTitle->setProperty, Value=oldTitleStr
           newSubTitle->setProperty, Value=oldSubTitleStr                  
            
          newAxisSettings->setProperty,$
            titleObj=newTitle,             $ ; title obj axis
            subtitleObj=newSubTitle,       $ ; subtitle obj axis
            placeTitle=placeTitle,                   $ ; placement of title (left/bottom or right/top)
            titleorientation=titleorientation,       $ ; orientation of title (0=horizontal, 1=vertical)
            titlemargin=titlemargin,                 $ ; number of points for title margin
            lazytitles=lazytitles,                   $ ; A flag to determine whether underscores should be converted to carriage returns
            showtitle=showtitle                        ; flag for whether the title should be displayed
            
            
            
        endif
        
        ;Label
        if apply_to_all_panels eq 5 then begin
          currAxisSettings->getProperty,$
            Orientation=orientation,               $ ; orientation of labels 0=Horizontal, 1=Vertical
            Margin=margin,                         $ ; number of points for label margins
            showLabels=showLabels,                 $ ; flag for whether or not labels are displayed
            labels=labels,                         $ ; A container object that stores the text objects which represent each label
            stackLabels=stackLabels,               $ ; A flag to determine whether labels should be stacked
            lazylabels=lazylabels,               $ ; A flag to determine whether underscores should be converted to carriage returns
            blackLabels=blackLabels,               $ ; A flag to determine whether labels should be stacked
            placeLabel=placeLabel                  ; place labels bottom/left (0) or top/right (1)
            
          newAxisSettings->getProperty, labels=newlabels
          
          ;properly copy labels
          if obj_valid(labels) && obj_isa(labels,'IDL_Container') && $
            obj_valid(newlabels) && obj_isa(newlabels,'IDL_Container') then begin
            
            labellist = labels->get(/all)
            
            newlabellist = newlabels->get(/all)
            
            if obj_valid(labellist[0]) && obj_valid(newlabellist[0]) then begin
            
              for j=0, n_elements(newlabellist)-1 do begin
              
                if j gt n_elements(labellist)-1 then break
                
                if obj_valid(labellist[j]) then begin
                
                  labellist[j]->getProperty, font=lfont, format=lformat, color=lcolor, $
                    size=lsize, thickness=lthickness, show=lshow
                    
                  newlabellist[j]->setProperty, font=lfont, format=lformat, color=lcolor, $
                    size=lsize, thickness=lthickness, show=lshow
                endif
                
              endfor
              
            endif
            
          endif else begin
          
          ;newlabels = obj_new()
          
          endelse
          
          newAxisSettings->setProperty,$
            Orientation=orientation,               $ ; orientation of labels 0=Horizontal, 1=Vertical
            Margin=margin,                         $ ; number of points for label margins
            showLabels=showLabels,                 $ ; flag for whether or not labels are displayed
            ;labels=newlabels,                         $ ; A container object that stores the text objects which represent each label
            stackLabels=stackLabels,               $ ; A flag to determine whether labels should be stacked
            lazylabels=lazylabels,                 $ ; A flag to determine whether underscores should be converted to carriage returns
            blackLabels=blackLabels,               $ ; A flag to determine whether labels should be stacked
            placeLabel=placeLabel
            
          if ~blacklabels && showlabels && (state.axisselect eq 1) then temppanelobj->SyncLinesToLabels
          
        endif
        
      endif
    endfor
  ENDIF
  
end ;------------------------------------------------


;+
;
;Procedure: spd_ui_update_axis_from_draw
;
;Syntax:
;  SPD_UI_INIT_AXIS_WINDOW , [ tlb ] [ , state = state ]
;
;After an update, this routine will update the fixed range of the axis objects
;Using the output of the draw object.  This stops the draw object from having
;to break abstraction.
;
;It also updates the number of ticks.  As the number displayed may vary
;from the number requested. (Only update is not using aesthetic ticks - lphilpott 26-june-2012)
;
;(aaflores 2013-2-7)
;Major ticks: If ticks by number is set then the ticks by interval option
;             should be updated to draw similarly spaced ticks, and vice versa.
;Minor ticks: Unsure... leaving them as is.
;
;-
pro spd_ui_update_axis_from_draw,drawObject,panels

  compile_opt idl2,hidden
  
  ;validate panel idl_container
  if obj_valid(panels) && panels->count() gt 0 then begin
  
    panel_list = panels->get(/all)
    
    ;loop over panel list
    for i = 0,n_elements(panel_list)-1 do begin
    
      panel_list[i]->getProperty,xaxis=xaxis,yaxis=yaxis
      
      ;get info about current panel settings
      info = drawObject->getPanelInfo(i)
      
      ;if there is a problem go to next iteration
      if ~is_struct(info) then continue
      
      
      ; X axis
      ;--------
      
      ;get x range and delog it
      xrange = info.xrange
      
      if info.xscale eq 1 then begin
        xrange = 10D^xrange
      endif else if info.xscale eq 2 then begin
        xrange = exp(xrange)
      endif
      
      ;store xrange
      xaxis->setProperty,$
          minFixedRange=xrange[0],$
          maxFixedRange=xrange[1]
      
      ;update ticks
      xaxis->getProperty, autoticks=aestheticticks, majortickauto=majortickauto, $
                          majortickunits=majortickunits, istimeaxis=istime
      
      if ~aestheticticks || ~majortickauto then begin
        xaxis->setProperty,$
          numMajorTicks=info.xmajorNum,$
          numMinorTicks=info.xminorNum
      endif
      if majortickauto then begin
        xmajorsize = ~istime ? info.xmajorsize :  $
          spd_ui_axis_options_convert_units(info.xmajorsize,majortickunits,/fromseconds)
        xaxis->setProperty, majortickevery = xmajorsize
      endif
      
      
      ; Y axis
      ;--------
      
      ;get yrange and delog it
      yrange = info.yrange
      
      if info.yscale eq 1 then begin
        yrange = 10D^yrange
      endif else if info.yscale eq 2 then begin
        yrange = exp(yrange)
      endif
      
      ;store yrange
      yaxis->setProperty,$
          minFixedRange=yrange[0],$
          maxFixedRange=yrange[1]
      
      ;update ticks
      yaxis->getProperty, autoticks=aestheticticks, majortickauto=majortickauto, $
                          majortickunits=majortickunits, istimeaxis=istime
      if ~aestheticticks || ~majortickauto then begin
        yaxis->setProperty,$
          numMajorTicks=info.ymajorNum,$
          numMinorTicks=info.yminorNum
      endif
      if majortickauto then begin
        ymajorsize = ~istime ? info.ymajorsize :  $
          spd_ui_axis_options_convert_units(info.ymajorsize,majortickunits,/fromseconds)
        yaxis->setProperty,majortickevery = ymajorsize
      endif
    endfor
    
  endif
  
end ;------------------------------------------------


function spd_ui_axis_options_convert_units,value,units,fromseconds=fromseconds

  compile_opt idl2, hidden
  
  if units eq 0 then begin
    conversion_factor = 1D
  endif else if units eq 1 then begin
    conversion_factor = 60D
  endif else if units eq 2 then begin
    conversion_factor = 60D*60D
  endif else if units eq 3 then begin
    conversion_factor = 60D*60D*24D
  endif
  
  if keyword_set(fromseconds) then begin
    return,value/conversion_factor
  endif else begin
    return,value*conversion_factor
  endelse
  
end ;------------------------------------------------



pro spd_ui_axis_options_init_color, state

  compile_opt idl2, hidden
  
  ; initialize color windows
  
  id = widget_info(state.tlb, find_by_uname='labelcolorwin')
  widget_control, id, get_value=labelcolorwin
  currlabelobj = spd_ui_axis_options_getcurrentlabel(state)
  
  currlabelobj->getproperty, color=color
  
  
  scene=obj_new('IDLGRSCENE', color=color)
  labelcolorwin->setProperty,graphics_tree=scene
  labelcolorwin->draw, scene
  
end ;------------------------------------------------



pro spd_ui_axis_update_units,state

    compile_opt idl2, hidden

  tlb=state.tlb
  axissettings = spd_ui_axis_options_getaxis(state)
  
  ;Gets the list of units, dependent upon whether the axis is a time axis or not
  units = axisSettings->getUnits()
  
  axissettings->GetProperty, majortickunits = majortickunits
  
  ;because the list of units may change length when other settings
  ;the previous unit index may not index into the list anymore
  if majorTickUnits ge n_elements(units) then begin
    majorTickUnits = 0
    axissettings->setProperty, majortickunits = majortickunits
  endif
  
  id = widget_info(tlb, find_by_uname = 'majortickunits')
  widget_control, id, set_value = units
  widget_control, id, set_combobox_select = majortickunits
  
  
  axissettings->GetProperty, annotateunits=annotateunits
  
  ;if isTime switch caused units switch, make sure they don't index out of range
  if annotateUnits ge n_elements(units) then begin
    annotateUnits = 0
    axissettings->setProperty, annotateUnits = annotateUnits
  endif
  
  id = widget_info(state.tlb, find_by_uname='annotateunits')
  widget_control, id, set_value = units
  widget_control, id, set_combobox_select=annotateunits
  
end ;------------------------------------------------


;+
;
;SPD_UI_INIT_AXIS_WINDOW.PRO
;
;Given the top level base when running SPD_UI_AXIS_OPTIONS, update all axis attributes from settings.
;
;The widget ID of the top level base should be the first parameter (this is when the program unit calling this routine
;does not have the STATE structure).  Otherwise, STATE should be passed by keyword and the first parameter should not be passed.
;
;Syntax:
;  SPD_UI_INIT_AXIS_WINDOW , [ tlb ] [ , state = state ]
;
;W.M.Feuerstein, 11/7/2008.
;
;-

pro SPD_UI_INIT_AXIS_WINDOW ,tlb, state=state

  compile_opt idl2, hidden
  
  statedef = ~(~size(state,/type))
  
  if ~statedef then begin
    Widget_Control, tlb, Get_UValue=state, /No_Copy  ;Only get STATE if it is not passed in.
  endif else begin
    tlb = state.tlb
  endelse
  
  ;Get correct axis:
  ;*****************
  ;
  currpanelobj = spd_ui_axis_options_getcurrentpanel(state)
  axissettings = spd_ui_axis_options_getaxis(state)
  panelObjs = spd_ui_axis_options_getpanelobjs(state)
  
  ; Set axispanelselect to bottom panel if panels are locked
;  activeWindow = state.windowStorage->GetActive()
;  if Obj_Valid(activeWindow) then begin
;     activeWindow->getproperty, locked = locked  
     ;if locked NE -1 then state.axispanelselect=n_elements(panelObjs)-1
;  endif
  
  ; put updating of widgets on hold until end of init function
  tabid = widget_info(state.tlb, find_by_uname='tabs')
  ;widget_control, state.tabbase, update=0
  widget_control, tabid, update=0
  
  ; Check if there are any panels. Pass panelsExist to sensitive to make things noneditable if no panels exist
  if obj_valid(panelObjs[0]) then panelsExist = 1 else panelsExist = 0
  
  
  ;*********************
  ;Initialize Range tab:
  ;*********************
  ;
  ;Get state of istime setting:
  ;****************************
  IF Obj_Valid(axissettings) THEN BEGIN
    axissettings->GetProperty, istimeaxis=istime
  ENDIF ELSE BEGIN
    axissettings=Obj_New("SPD_UI_AXIS_SETTINGS")
    axissettings->GetProperty, istimeaxis=istime
  ENDELSE
  ;
  
  id = widget_info(tlb, find_by_uname = 'rangepaneldroplist')
  widget_control, id, set_combobox_select = state.axispanelselect
 
  ;Set appropriate sensitivity, buttons, and attributes for Range Options, Scaling, Fixed Min/Max, AutoRange, and Floating Center:
  ;*******************************************************************************************************************************
  
  FOR i=0,N_Elements(state.rangeOptions)-1 DO Widget_Control, state.rangeOptions[i], sensitive=(1 && panelsExist)
  FOR i=0,N_Elements(state.scalingOptions)-1 DO Widget_Control, state.scalingOptions[i], sensitive = (1 && panelsExist)
  ;
  
  axissettings->GetProperty,rangeoption=rangeoption
  ;floating center removed: option index no longer matches widget array index
  WIDGET_CONTROL, state.rangeoptions[rangeoption eq 2], /Set_Button
  axissettings->GetProperty,scaling=scaling
  WIDGET_CONTROL, state.scalingoptions[scaling], /Set_Button
  styleValues = axisSettings->GetAnnotationFormats()
  id = widget_info(state.tlb, find_by_uname='annotatestyle')
  widget_control, id, set_value = styleValues
  
  ;sensitize annotation styles
  for j=0, n_elements(state.atype)-1 do widget_control, state.atype[j], sensitive=(1 && panelsExist)
  
  ;get data annotation format
  axissettings->GetProperty, annotateExponent=annotateExponent
  widget_control, state.atype[annotateExponent], set_button=1
  
  ;
  minincrement = widget_info(state.tlb, find_by_uname='minincrement')
  maxincrement = widget_info(state.tlb, find_by_uname='maxincrement')
  widget_control, minIncrement, /destroy
  widget_control, maxIncrement, /destroy
  if scaling eq 0 then minvalue = !values.d_nan else minvalue = 0
  minbase = widget_info(state.tlb, find_by_uname='minbase')
  maxbase = widget_info(state.tlb, find_by_uname='maxbase')
  minIncrement=spd_ui_spinner(minBase, Increment=1, text_box_size=24, $
    uval='MINFIXEDRANGE', uname='minincrement', $
    precision=13,min_value=minvalue)
  maxIncrement=spd_ui_spinner(maxBase, Increment=1, text_box_size=24, $
    uval='MAXFIXEDRANGE', uname='maxincrement', $
    precision=13,min_value=minvalue)
  ;
    
  ; Set the boundscaling settings EVEN if autorange is not selected and boundrange will end up
  ; densensitised.
  id = widget_info(state.tlb, find_by_uname = 'rmincrement')
  axissettings->GetProperty, rangemargin = rangemargin
  widget_control, id, set_value = 100*rangemargin
  id = widget_info(state.tlb, find_by_uname = 'boundscaling')
  axissettings->GetProperty, boundscaling = boundscaling
  widget_control, id, set_button = boundscaling
  id = widget_info(state.tlb, find_by_uname = 'minboundrange')
  axissettings->GetProperty, minboundrange = minboundrange
  widget_control, id, set_value=minboundrange
  id = widget_info(state.tlb, find_by_uname = 'maxboundrange')
  axissettings->GetProperty, maxboundrange = maxboundrange
  widget_control, id, set_value=maxboundrange
  
  case rangeoption of
  
    ;Fixed Range
    2: begin
      id = widget_info(state.tlb, find_by_uname = 'aobase')
      widget_control, id, sensitive = 0
      
      id = widget_info(state.tlb, find_by_uname = 'fobase')
      widget_control, id, sensitive = (1 && panelsExist)
      
      ;        id = widget_info(state.tlb, find_by_uname = 'fltobase')
      ;        widget_control, id, sensitive = 0
      
      ;
      id = widget_info(state.tlb, find_by_uname = 'minincrement')
      axissettings->GetProperty, minfixedrange = minfixedrange
      widget_control, id, set_value = minfixedrange
      ;
      id = widget_info(state.tlb, find_by_uname = 'maxincrement')
      axissettings->GetProperty, maxfixedrange = maxfixedrange
      widget_control, id, set_value = maxfixedrange
    end
    
    ;Auto-Range
    ;Using ELSE instead of specific check to avoid errors from loading
    ;.tgd files that use floating center.
    else: begin
      id = widget_info(state.tlb, find_by_uname = 'aobase')
      widget_control, id, sensitive = (1 && panelsExist)
      
      id = widget_info(state.tlb, find_by_uname = 'fobase')
      widget_control, id, sensitive = 0
      
      ;        id = widget_info(state.tlb, find_by_uname = 'fltobase')
      ;        widget_control, id, sensitive = 0
      
      id = widget_info(state.tlb,find_by_uname = 'boundbase')
      widget_control,id,sensitive=(boundscaling && panelsExist)
      
      id = widget_info(state.tlb, find_by_uname = 'minincrement')
      axissettings->GetProperty, minfixedrange = value
      widget_control, id, set_value=value
      id = widget_info(state.tlb, find_by_uname = 'maxincrement')
      axissettings->GetProperty, maxfixedrange = value
      widget_control, id, set_value=value
      
    end
  endcase
  
  
  if istime then begin
  
    minincrement = widget_info(state.tlb, find_by_uname='minincrement')
    maxincrement = widget_info(state.tlb, find_by_uname='maxincrement')
    widget_control, minIncrement, /destroy
    widget_control, maxIncrement, /destroy
    ;state.minIncrement=widget_text(state.minBase, Sensitive=sensitive, /editable, uval='MINFIXEDRANGE', $
    ;                               xsize=21, uname='minincrement',/all_events)
    ;state.maxIncrement=widget_text(state.maxBase, Sensitive=sensitive, /editable, uval='MAXFIXEDRANGE', $
    ;                               xsize=21, uname='maxincrement',/all_events)
    minbase = widget_info(state.tlb, find_by_uname='minbase')
    maxbase = widget_info(state.tlb, find_by_uname='maxbase')
    minIncrement=widget_text(minBase, /editable, uval='MINFIXEDRANGE', $
      xsize=21, uname='minincrement',/all_events)
    maxIncrement=widget_text(maxBase, /editable, uval='MAXFIXEDRANGE', $
      xsize=21, uname='maxincrement',/all_events)
    styleValues = axisSettings->GetAnnotationFormats()
    id = widget_info(state.tlb, find_by_uname='annotatestyle')
    widget_control, id, set_value = styleValues
    
    ;desensitize annotation types
    for j=0, n_elements(state.atype)-1 do widget_control, state.atype[j], sensitive=0
    
    id = widget_info(state.tlb, find_by_uname = 'minincrement')
    axissettings->GetProperty, minfixedrange = minfixedrange
    minfixedrangetime = formatDate(minfixedrange, '%date/%exacttime', 0)
    widget_control, id, set_value=minfixedrangetime, sensitive=1
    ;
    id = widget_info(state.tlb, find_by_uname = 'maxincrement')
    axissettings->GetProperty, maxfixedrange = maxfixedrange
    maxfixedrangetime = formatDate(maxfixedrange, '%date/%exacttime', 0)
    widget_control, id, set_value=maxfixedrangetime, sensitive=1
  endif
  
  
  id = widget_info(tlb,find_by_uname = 'istime')
  
  widget_control,id,set_button=istime, sensitive=panelsExist
  
  ; from Annotations tab to get ride of flicker in droplist
  axissettings->GetProperty, annotatestyle=annotatestyle
  id = widget_info(state.tlb, find_by_uname='annotatestyle')
  widget_control, id, set_combobox_select=annotatestyle, sensitive=panelsExist
  
  widget_control, state.tlb,tlb_get_offset=off
  widget_control, state.tlb, xoffset=off[0],yoffset=off[1]
  ;widget_control, state.tabbase, update=1
  widget_control, tabid, update=1
  
  
  ;Warn user about x-axis range options and locking
  if state.axisselect eq 0 then begin
    id = widget_info(state.tlb, find_by_uname='tabs')
    
    if widget_info(id, /tab_current) eq 0 then begin
      activeWindow = state.windowstorage->getactive()
      activewindow->getproperty, locked=locked
      
      ;added parameter to stop the locked message from being displayed over and over and over....
      if locked ne -1 && state.lockedMessageDisplayed eq 0 then begin
        state.statusbar->update, $
          '*Panels Are Locked: Changes to range are only displayed for the locked panel ("(L)" prefix).'
        state.lockedMessageDisplayed=1
      endif
    endif
  endif
  
  
  ;*********************
  ;Initialize Ticks tab:
  ;*********************
  ;
  
  ; grey out by number frame when no panels exist
  id = widget_info(tlb, find_by_uname = 'bynumberbase')
  widget_control, id, sensitive = panelsExist
  ;grey out by interval frame when no panels exist
  id = widget_info(tlb, find_by_uname = 'byintervalbase')
  widget_control, id, sensitive = panelsExist
  
  ;Set Auto Button
  
  axisSettings->GetProperty,autoticks=autoticks
  id = widget_info(tlb,find_by_uname = 'niceticks')
  widget_control,id,set_button=autoticks
  
  id = widget_info(tlb, find_by_uname = 'tickpaneldroplist')
  widget_control, id, set_combobox_select = state.axispanelselect
  
  axissettings->GetProperty, majortickevery = majortickevery
  id = widget_info(tlb, find_by_uname = 'majortickevery')
  widget_control, id, set_value = majortickevery
  
  spd_ui_axis_update_units,state
  
  axissettings->GetProperty, nummajorticks = value
  id = widget_info(tlb, find_by_uname = 'nummajorticks')
  widget_control, id, set_value = value
  
  axissettings->GetProperty, numminorticks = value
  
  ;for now use majortickauto option to control by number/by interval widgets
  axissettings->GetProperty, majortickauto = majortickauto
  bid = widget_info(tlb, find_by_uname = 'bynumber')
  id = widget_info(tlb, find_by_uname = 'numberbase')
  widget_control, bid, set_button = majortickauto
  widget_control, id, sensitive = majortickauto
  minortickbase = widget_info(state.tlb, find_by_uname='minortickbase')
  if autoticks && majortickauto then widget_control, minorTickBase, sensitive=0 else widget_control, minorTickBase, sensitive=1
  
  majortickbase = widget_info(state.tlb, find_by_uname='majortickbase')
  if autoticks && majortickauto then widget_control, majorTickBase, sensitive=0 else widget_control, majorTickBase, sensitive=1
  
  
  bid = widget_info(tlb, find_by_uname = 'byinterval')
  id = widget_info(tlb, find_by_uname = 'intervalbase')
  widget_control, bid, set_button = ~majortickauto
  widget_control, id, sensitive = ~majortickauto
  
  axissettings->GetProperty, numminorticks = value, autoticks=autoticks
  if ~autoticks then begin ;28/6/2011 lphilpott changed autoticks to ~autoticks because it wasn't loading correct minor value
    id = widget_info(tlb, find_by_uname = 'numminorticks')
    widget_control, id, set_value = value
  endif
  
  
  ; (lphilpott 7/6/2011) Setting to the minimum range here causes the "align ticks at" to be reset constantly.
  ; Change slightly such that it is set to the maximum of the minimum range and the current setting. This should
  ; only reset user changes if the user changes it to a value less than the minimum range
  if (state.axisselect eq 0) then begin ;x axis only
    axisSettings->getproperty,minfixedrange=minrange_firsttickat,firsttickat=current_firsttickat ;get the current minimum range for the panel
    ts_firsttickat = time_struct(minrange_firsttickat)
    ;set to the date of the minimum range for the axis
    default_firsttickat = time_double(num_to_str_pad(ts_firsttickat.year,4)+'-'+num_to_str_pad(ts_firsttickat.month,2)+'-'+num_to_str_pad(ts_firsttickat.date,2))
    firsttickat = default_firsttickat > current_firsttickat
    axisSettings->setProperty,firsttickat=firsttickat,/notouched
  endif
  axissettings->GetProperty, firsttickat = firsttickat
  bid = widget_info(state.tlb, find_by_uname='firsttickatbase')
  id = widget_info(tlb, find_by_uname = 'firsttickat')
  
  ;update first tick at widget, change type if necessary
  if istime then begin
    if widget_info(id,/type) ne 3 then begin
      widget_control, id, /destroy
      id = widget_text(bid, value=time_string(firsttickat), uname='firsttickat',/editable)
    endif else widget_control, id, set_value = time_string(firsttickat)
  endif else begin
    if widget_info(id,/type) ne 0 then begin
      widget_control, id, /destroy
      id = spd_ui_spinner(bid, value=firsttickat, incr=1, uname='firsttickat', $
        tooltip='Numerical location of first tick.', text_box=12)
    endif else widget_control, id, set_value = firsttickat
  endelse
  
  axisSettings->getProperty,logMinorTickType=logMinorTickType
  
  id = widget_info(tlb,find_by_uname='logminorticktype'+strtrim(logMinorTickType,2))
  widget_control,id,/set_button
  
  axisSettings->getProperty,scaling=scaling
  id = widget_info(tlb,find_by_uname='logminorticktypebase')
  if scaling eq 0 then begin
    widget_control,id,sensitive=0
  endif else begin
    widget_control,id,sensitive=1
  endelse
  
  ; grey out placement frame when no panels exist
  id = widget_info(tlb, find_by_uname = 'placeframebase')
  widget_control, id, sensitive = panelsExist
  ; grey out length frame when no panels exist
  id = widget_info(tlb, find_by_uname = 'lengthframebase')
  widget_control, id, sensitive = panelsExist
  
  axissettings->GetProperty, tickstyle = value
  id = widget_info(tlb, find_by_uname = 'tickstyle')
  widget_control, id, set_combobox_select=value, sensitive=panelsExist
  
  axissettings->GetProperty, bottomplacement = value
  id = widget_info(tlb, find_by_uname = 'bottomplace')
  widget_control, id, set_button=value
  
  axissettings->GetProperty, topplacement = value
  id = widget_info(tlb, find_by_uname = 'topplace')
  widget_control, id, set_button=value
  
  axissettings->GetProperty, majorlength = value
  id = widget_info(tlb, find_by_uname = 'majorlength')
  widget_control, id, set_value=value
  
  axissettings->GetProperty, minorlength = value
  id = widget_info(tlb, find_by_uname = 'minorlength')
  widget_control, id, set_value=value
  
  ;********************
  ;Initialize Grid tab:
  ;********************
  ;
  id = widget_info(tlb, find_by_uname = 'gridpaneldroplist')
  widget_control, id, set_combobox_select = state.axispanelselect
  
  ;id = widget_info(tlb, find_by_uname = 'outlinethick')
  ;IF ~Obj_Valid(currpanelobj) THEN currpanelobj=Obj_New("SPD_UI_PANEL", 1)
  ;currpanelobj->GetProperty, settings=panelsettings
  ;panelsettings->GetProperty, framethick=framethick
  ;widget_control, id, set_value = framethick, sensitive=panelsExist
  
  ;intialize color major grid window
  ;*********************************
  ;
  axissettings->GetProperty, majorgrid=majorgrid
  if obj_valid(majorgrid) then begin
    majorgrid->GetProperty,color=color
  endif else begin
    color = [0,0,0]
    majorGrid = obj_new('SPD_UI_LINE_STYLE',color=color, show=0)
    axissettings->SetProperty, majorgrid=majorgrid
  endelse
  majorcolorid = widget_info(state.tlb, find_by_uname='majorgridcolorwin')
  Widget_Control, majorcolorid, Get_Value=majorgridcolorWin
  if obj_valid(scene) then scene->remove,/all
  scene=obj_new('IDLGRSCENE', color=color)
  majorgridcolorWin->draw, scene
  
  majorgrid->GetProperty, show=showmajor
  id = widget_info(state.tlb, find_by_uname = 'majorbase')
  widget_control, id, sensitive=showmajor
  id = widget_info(state.tlb, find_by_uname = 'majorgrids')
  widget_control, id, set_button=showmajor, sensitive=panelsExist
  id = widget_info(state.tlb, find_by_uname = 'majorgridbtnlabel')
  widget_control, id, sensitive = panelsExist
  
  styleNames = majorgrid->getlinestyles()
  majorgrid->GetProperty, id=styleid
  id=widget_info(state.tlb, find_by_uname = 'majorgridstyle')
  widget_control, id, set_combobox_select=styleid
  
  majorgrid->GetProperty, thickness=thickness
  id=widget_info(state.tlb, find_by_uname = 'majorgridthick')
  widget_control, id, set_value = thickness
  
  
  ; intialize color minor grid window
  axissettings->GetProperty, minorgrid=minorgrid
  if obj_valid(minorgrid) then begin
    minorgrid->GetProperty,color=color
  endif else begin
    color = [0,0,0]
    minorGrid = obj_new('spd_ui_line_style',color=color, show=0)
    axissettings->SetProperty, minorgrid=minorgrid
  endelse
  minorcolorid = widget_info(state.tlb, find_by_uname='minorgridcolorwin')
  Widget_Control, minorcolorid, Get_Value=minorgridcolorWin
  if obj_valid(scene) then scene->remove,/all
  scene=obj_new('IDLGRSCENE', color=color)
  minorgridcolorWin->draw, scene
  
  minorgrid->GetProperty, show=showminor
  id = widget_info(state.tlb, find_by_uname = 'minorbase')
  widget_control, id, sensitive=showminor
  id = widget_info(state.tlb, find_by_uname = 'minorgrids')
  widget_control, id, set_button=showminor, sensitive=panelsExist
  id = widget_info(state.tlb, find_by_uname = 'minorgridbtnlabel')
  widget_control, id, sensitive=panelsExist
  
  
  styleNames = minorgrid->getlinestyles()
  minorgrid->GetProperty, id=styleid
  id=widget_info(state.tlb, find_by_uname = 'minorgridstyle')
  widget_control, id, set_value=styleNames, set_combobox_select=styleid
  
  minorgrid->GetProperty, thickness=thickness
  id=widget_info(state.tlb, find_by_uname = 'minorgridthick')
  widget_control, id, set_value = thickness
  
  ;**************************
  ;Initialize Annotation tab:
  ;**************************
  ;
  id = widget_info(tlb, find_by_uname = 'annopaneldroplist')
  widget_control, id, set_combobox_select = state.axispanelselect
  
  axissettings->GetProperty, lineatzero=lineatzero
  id = widget_info(tlb, find_by_uname = 'lineatzero')
  widget_control, id, set_button=lineatzero, sensitive = panelsExist
  
  axissettings->GetProperty, showdate=showdate
  id = widget_info(tlb, find_by_uname = 'showdate')
  widget_control, id, set_button=showdate
  if istime && ~state.axisselect then widget_control, id, sensitive=panelsExist else widget_control, id, sensitive=0
  
  id = widget_info(state.tlb, find_by_uname='anodatebase')
  if istime && ~state.axisselect then widget_control, id, sensitive=panelsExist&&showDate else widget_control, id, sensitive=0
  
  axissettings->GetProperty, datestring1=datestring1
  id = widget_info(tlb, find_by_uname = 'anodate1')
  widget_control, id, set_value=datestring1;, sensitive=panelsExist&&showDate - sensitivity set with anodatebase above
  
  axissettings->GetProperty, datestring2=datestring2
  id = widget_info(tlb, find_by_uname = 'anodate2')
  widget_control, id, set_value=datestring2;, sensitive=panelsExist&&showDate
  
  axissettings->GetProperty, annotateaxis=annotateaxis
  id = widget_info(state.tlb, find_by_uname='annotateaxis')
  widget_control, id, set_button=annotateaxis, sensitive=panelsExist
  id = widget_info(state.tlb, find_by_uname='annoaxisbase')
  widget_control, id, sensitive=(annotateaxis && panelsExist)
  
  axissettings->GetProperty, placeannotation=placeannotation
  id = widget_info(tlb, find_by_uname = 'placeannotation')
  widget_control, id, set_combobox_select=placeannotation
  
  
  axissettings->GetProperty, annotatemajorticks=annotatemajorticks
  id = widget_info(state.tlb, find_by_uname='annotatemajorticks')
  widget_control, id, set_button=annotatemajorticks
  id = widget_info(state.tlb, find_by_uname='annomajorbase')
  widget_control, id, sensitive=(~annotatemajorticks && panelsExist)
  
  axissettings->GetProperty, annotateevery=annotateevery
  id = widget_info(state.tlb, find_by_uname='annotateevery')
  widget_control, id, set_value=annotateevery
  
  axissettings->GetProperty, firstannotation=firstannotation
  id = widget_info(state.tlb, find_by_uname='firstannotation')
  bid =  widget_info(state.tlb, find_by_uname='firstannotationbase')
  
  if istime then begin
    if widget_info(id,/type) ne 3 then begin
      widget_control, id, /destroy
      id = widget_text(bid, value=time_string(firstannotation), uname='firstannotation',/editable)
    endif else begin
      widget_control, id, set_value = time_string(firstannotation)
    endelse
  endif else begin
    if widget_info(id,/type) ne 0 then begin
      widget_control,id,/destroy
      id = spd_ui_spinner(bid, value=firstannotation, incr=1, uname='firstannotation', $
        tooltip='Numerical location of first annotation.', text_box=12)
    endif else begin
      widget_control, id, set_value=firstannotation
    endelse
  endelse
  
  axissettings->GetProperty, annotaterangemin=annotaterangemin
  id = widget_info(state.tlb, find_by_uname='annotaterangemin')
  widget_control, id, set_button=annotaterangemin, sensitive=panelsExist
  
  axissettings->GetProperty, annotaterangemax=annotaterangemax
  id = widget_info(state.tlb, find_by_uname='annotaterangemax')
  widget_control, id, set_button=annotaterangemax, sensitive=panelsExist
  
  axissettings->GetProperty, annotateorientation=annotateorientation
  ;if annotateorientation then begin
  id = widget_info(state.tlb, find_by_uname='annohorizontal')
  widget_control, id, set_button=~annotateorientation
  id = widget_info(state.tlb, find_by_uname='annovertical')
  widget_control, id, set_button=annotateorientation
  
  axissettings->GetProperty, annotateTextObject=annotateTextObject
  annotateTextObject->GetProperty, font=font
  id = widget_info(state.tlb, find_by_uname='anofontlist')
  widget_control, id, set_combobox_select=font
  
  annotateTextObject->GetProperty, size=size
  id = widget_info(state.tlb, find_by_uname='anofontsize')
  widget_control, id, set_value=size
  
  ; intialize annotation font color window
  axissettings->GetProperty, annotatetextobject=annotatetextobject
  if obj_valid(annotatetextobject) then begin
    annotatetextobject->GetProperty,color=color
  endif else begin
    color = [0,0,0]
    annotatetextobject = obj_new('spd_ui_text',color=color, show=0)
    axissettings->SetProperty, annotatetextobject=annotatetextobject
  endelse
  anocolorid = widget_info(state.tlb, find_by_uname='anocolorwin')
  Widget_Control, anocolorid, Get_Value=anocolorWin
  if obj_valid(scene) then scene->remove,/all
  scene=obj_new('IDLGRSCENE', color=color)
  anocolorWin->draw, scene
  
  id = widget_info(tlb, find_by_uname= 'anoslabel')
  widget_control, id, sensitive=panelsExist
  
  ;**********************
  ;Initialize Labels tab:
  ;**********************
  ;
  id = widget_info(tlb, find_by_uname = 'labelpaneldroplist')
  widget_control, id, set_combobox_select = state.axispanelselect
  
  IF state.axisselect EQ 1 THEN BEGIN
    axisSettings->GetProperty, BLACKLABELS=blacklabels
    id = widget_info(state.tlb, find_by_uname = 'blacklabels')
    widget_control, id, set_button = blacklabels
  ENDIF
  
  id = widget_info(state.tlb, find_by_uname = 'labelstyleframebase')
  widget_control, id, sensitive=panelsExist
  
  axissettings->getproperty, lazylabels = lazylabels
  id = widget_info(state.tlb, find_by_uname='lazylabels')
  widget_control, id, set_button = lazylabels
  
  axissettings->GetProperty, stacklabels = stacklabels
  id = widget_info(state.tlb, find_by_uname = 'stacklabels')
  widget_control, id, set_button = stacklabels
  
  axissettings->GetProperty, showlabels = showlabels
  id = widget_info(state.tlb, find_by_uname = 'showlabels')
  widget_control, id, set_button = showlabels
  
  id = widget_info(state.tlb, find_by_uname = 'labeldroplist')
  axissettings->GetProperty, labels=labelsObj
  
  showid = widget_info(state.tlb,find_by_uname = 'showlabel')
  
  if obj_valid(labelsObj) then labels = labelsObj->get(/all) ELSE labels=Obj_New("SPD_UI_TEXT", Value=' ')
  
  
  if obj_valid(labels[0]) then begin
  
    nlabels = n_elements(labels)
    labeltextlines = strarr(nlabels)
    for i=0,nlabels-1 do begin
      labels[i]->GetProperty, value=labeltext
      labeltext = spd_ui_axis_options_create_label_name(i,labeltext)
      ; this label length test has been moved to the create_label_name function
      ;if strlen(labeltext) GT 45 then labeltext=strmid(labeltext, 0, 45)+'...'
      labeltextlines[i]=labeltext
    endfor
    
    currlabelobj = labels[state.labelselect]
    currlabelobj->getProperty, show=showlabel
    widget_control, id, set_value=labeltextlines
    widget_control, id, set_combobox_select=state.labelselect
    IF showlabel THEN widget_control,showid,set_button=1 ELSE widget_control,showid,set_button=0
    ;*state.currlabelobj->GetProperty, font=font, format=format, size=size, color=color, value=value
    currlabelobj->GetProperty, font=font, format=format, size=size, color=color, value=value
    IF showlabels THEN show=1 ELSE show=0
    ;  for i=0,nlabels-1 do begin
    ;    IF NOT show THEN labels[i]->SetProperty, Show=0
    ;  endfor
    widget_control, showid, sensitive=show
    id = widget_info(state.tlb, find_by_uname = 'labeldroplist')
    widget_control, id, sensitive=show
    
  endif else begin
    state.labelselect = 0
    labeltextlines=[' ']
    widget_control, id, set_value=' '
    widget_control,showid,sensitive=1
    font=0
    format=3
    size=10
    color=[0,0,0]
    value=''
  endelse
  id = widget_info(tlb, find_by_uname='ltframebase')
  widget_control, id, sensitive=panelsExist
  id = widget_info(tlb, find_by_uname='labeltextedit')
  widget_control, id, set_value=value
  id = widget_info(state.tlb, find_by_uname='labelfont')
  widget_control, id, set_combobox_select=font
  id = widget_info(state.tlb, find_by_uname='labelformat')
  widget_control, id, set_combobox_select=format
  id = widget_info(state.tlb, find_by_uname='labelsize')
  widget_control, id, set_value=size
  
  ; intialize label color window
  labelcolorid = widget_info(state.tlb, find_by_uname='labelcolorwin')
  Widget_Control, labelcolorid, Get_Value=labelcolorWin
  if obj_valid(scene) then scene->remove,/all
  scene=obj_new('IDLGRSCENE', color=color)
  labelcolorWin->draw, scene
  
  axissettings->GetProperty, placelabel=placelabel
  id = widget_info(tlb, find_by_uname = 'placelabel')
  widget_control, id, set_combobox_select=placelabel
  
  axissettings->GetProperty, orientation=orientation
  id = widget_info(state.tlb, find_by_uname='labelhorizontal')
  widget_control, id, set_button=~orientation
  id = widget_info(state.tlb, find_by_uname='labelvertical')
  widget_control, id, set_button=orientation
  
  axissettings->GetProperty, margin=margin
  id = widget_info(state.tlb, find_by_uname='labelmargin')
  widget_control, id, set_value=margin, sensitive = panelsExist
  
  id = widget_info(state.tlb, find_by_uname='labelsync')
  widget_control, id, sensitive = panelsExist
  id = widget_info(state.tlb, find_by_uname='labelpalette')
  widget_control, id, sensitive = panelsExist
  
  spd_ui_axis_options_init_color, state
  
  ;**********************************
  ; initialize title tab
  ;**********************************
  
  id = widget_info(tlb, find_by_uname = 'titlepaneldroplist')
  widget_control, id, set_combobox_select = state.axispanelselect
  
  id = widget_info(state.tlb, find_by_uname = 'titletextframebase')
  widget_control, id, sensitive=panelsExist
  id = widget_info(state.tlb, find_by_uname = 'titleplacementframebase')
  widget_control, id, sensitive=panelsExist
  
  ; intialize title font color window
  axissettings->GetProperty, titleobj=titleobj, subtitleobj=subtitleobj
  if obj_valid(titleobj) then begin
    titleobj->GetProperty,color=color
  endif else begin
    color = [0,0,0]
    titleobj = obj_new('spd_ui_text',color=color, show=0)
    axissettings->SetProperty, titleobj=titleobj
  endelse
  titlecolorid = widget_info(state.tlb, find_by_uname='titlecolorwin')
  Widget_Control, titlecolorid, Get_Value=titlecolorWin
  if obj_valid(scene) then scene->remove,/all
  scene=obj_new('IDLGRSCENE', color=color)
  titlecolorWin->draw, scene
  
  ; intialize subtitle font color window
  if obj_valid(subtitleobj) then begin
    subtitleobj->GetProperty,color=color
  endif else begin
    color = [0,0,0]
    titleobj = obj_new('spd_ui_text',color=color, show=0)
    axissettings->SetProperty, subtitleobj=subtitleobj
  endelse
  subtitlecolorid = widget_info(state.tlb, find_by_uname='subtitlecolorwin')
  Widget_Control, subtitlecolorid, Get_Value=subtitlecolorWin
  if obj_valid(scene) then scene->remove,/all
  scene=obj_new('IDLGRSCENE', color=color)
  subtitlecolorWin->draw, scene
  
  axissettings->GetProperty, placetitle=placetitle
  id = widget_info(tlb, find_by_uname = 'placetitle')
  widget_control, id, set_combobox_select=placetitle
  
  axissettings->GetProperty, titleorientation=titleorientation
  id = widget_info(state.tlb, find_by_uname='titlehorizontal')
  widget_control, id, set_button=~titleorientation
  id = widget_info(state.tlb, find_by_uname='titlevertical')
  widget_control, id, set_button=titleorientation
  
  titleobj->GetProperty, font=font
  id = widget_info(state.tlb, find_by_uname='titlefont')
  widget_control, id, set_combobox_select=font
  
  titleobj->GetProperty, size=size
  id = widget_info(state.tlb, find_by_uname='titlesize')
  widget_control, id, set_value=size
  
  titleobj->GetProperty, format=format
  id = widget_info(state.tlb, find_by_uname='titleformat')
  widget_control, id, set_combobox_select=format
  
  subtitleobj->GetProperty, font=font
  id = widget_info(state.tlb, find_by_uname='subtitlefont')
  widget_control, id, set_combobox_select=font
  
  subtitleobj->GetProperty, size=subsize
  id = widget_info(state.tlb, find_by_uname='subtitlesize')
  widget_control, id, set_value=subsize
  
  subtitleobj->GetProperty, format=format
  id = widget_info(state.tlb, find_by_uname='subtitleformat')
  widget_control, id, set_combobox_select=format
  
  titleobj->GetProperty, value=value
  id = widget_info(state.tlb, find_by_uname='titletextedit')
  widget_control, id, set_value=value
  
  axissettings->GetProperty, subtitleobj=subtitleobj
  subtitleobj->GetProperty, value=value
  id = widget_info(state.tlb, find_by_uname='subtitletextedit')
  widget_control, id, set_value=value
  
  axissettings->GetProperty, titlemargin=titlemargin
  id = widget_info(state.tlb, find_by_uname='titlemargin')
  widget_control, id, set_value=titlemargin
  
  axissettings->getproperty, lazytitles = lazytitles
  id = widget_info(state.tlb, find_by_uname='lazytitles')
  widget_control, id, set_button = lazytitles
  
  ;Initialize annotation font color:
  ;*********************************
  
  
  
  if ~statedef then Widget_Control, tlb, Set_UValue=state, /No_Copy   ;Only put STATE if it was not passed in.
  
END ; -----------------------------------------



;Get and return current axis settings object from state
FUNCTION spd_ui_axis_options_getaxis, state

  compile_opt idl2,hidden
  
  currpanelobj = spd_ui_axis_options_getcurrentpanel(state)
  
  if ~Obj_Valid(currpanelobj) then currpanelobj=Obj_New("SPD_UI_PANEL", 1)
  case state.axisselect of
    0: currpanelobj->GetProperty,xaxis = axissettings
    1: currpanelobj->GetProperty,yaxis = axissettings
  endcase
  if ~obj_valid(axissettings) then axissettings=obj_new('SPD_UI_AXIS_SETTINGS')
  
  return, axissettings
  
END ; -------------------------------------------



; Get and return the panels (all)
; This is usually an IDL_container, but this is not guaranteed.
function spd_ui_axis_options_getpanels, state

  compile_opt idl2,hidden
  activeWindow = state.windowStorage->GetActive()
  activeWindow->GetProperty, Panels=panels
  return, panels
  
end

; Return the array of panel objects
; If there are no panels this will return -1
function spd_ui_axis_options_getpanelobjs, state

  compile_opt idl2, hidden
  panels = spd_ui_axis_options_getpanels(state)
  if obj_valid(panels) then begin
    panelobjs = panels->get(/All)
  endif else panelobjs = -1
  
  return, panelobjs
  
end

; Get and return current panel
; If there are no panels this will return a new panel object
function spd_ui_axis_options_getcurrentpanel, state

  compile_opt idl2,hidden
  panelObjs = spd_ui_axis_options_getpanelobjs(state)
  if obj_valid(panelobjs[0]) then begin
    currpanelobj = panelobjs[state.axispanelselect]
  endif
  if ~Obj_Valid(currpanelobj) then currpanelobj=Obj_New("SPD_UI_PANEL", 1)
  
  return, currpanelobj
  
end


;Get and return current label
function spd_ui_axis_options_getcurrentlabel, state

  compile_opt idl2, hidden
  
  axissettings = spd_ui_axis_options_getaxis(state)
  axissettings->getProperty, labels=labels
  if obj_valid(labels) then begin
    currlabelobj = labels->get(position = state.labelselect)
    if ~obj_valid(currlabelobj) then begin
      currlabelobj = Obj_new("SPD_UI_TEXT", Value=' ')
    endif
  endif else currlabelobj=Obj_New("SPD_UI_TEXT", Value=' ')
  
  return, currlabelobj
end


; Get scaling option from widgets and apply.
;
; This function should eventually replace the  
; correstponding code in the event handler.;
;
pro spd_ui_axis_options_set_scaling,tlb,state,nopopups=nopopups

  compile_opt idl2,hidden
  
  axissettings = spd_ui_axis_options_getaxis(state)
  
  linid = widget_info(tlb,find_by_uname='linear')
  logid = widget_info(tlb,find_by_uname='log10')
  
  if widget_info(linid,/button_set) then begin
    axissettings->setProperty,scaling=0
  endif else if widget_info(logid,/button_set) then begin
    axissettings->setProperty,scaling=1
  endif else begin
    axissettings->setProperty,scaling=2
  endelse
  
  
end

; Gets range values from widgets and applies them to the corresponding settings
; spd_ui_axis_options_set_scaling should be called first
;
; This function should eventually replace the  
; correstponding code in the event handler.
;
PRO spd_ui_axis_options_set_range, tlb, state,nopopups=nopopups

  compile_opt idl2, hidden
  
  
  panelObjs = spd_ui_axis_options_getpanelobjs(state)
  if ~Obj_valid(panelObjs[0]) then return
  axissettings = spd_ui_axis_options_getaxis(state)
  
  ; Retrieve scaling for later
  axissettings->getproperty,scaling=scaling, istimeaxis=istimeaxis
  
  ; Fixed Range
  ;
  ID = widget_info(tlb, find_by_uname='fixedrange')
  if widget_info(ID, /button_set) then begin
    axissettings->SetProperty,rangeoption=2
    maxID = widget_info(tlb, find_by_uname='maxincrement')
    minID = widget_info(tlb, find_by_uname='minincrement')
    widget_control, minid, get_value=minv
    widget_control, maxid, get_value=maxv
    axisSettings->getProperty,minFixedRange=oldmin,maxFixedRange=oldmax
    if istimeaxis then begin
      oldmin = formatDate(oldmin, '%date/%exacttime', 0)
      oldmax = formatDate(oldmax, '%date/%exacttime', 0)
    endif
    if istimeaxis then begin
      minv = spd_ui_timefix(minv)
      maxv = spd_ui_timefix(maxv)
      if ~is_string(minv) || ~is_string(maxv) then begin
        if ~is_string(minv) then begin
          inv = 'min'
          widget_control, minid, set_value=oldmin
          minv = oldmin
        endif
        if ~is_string(maxv) then begin
          inv = keyword_set(inv) ? inv + ' and max':'max'
          widget_control,maxid, set_value=oldmax
          maxv = oldmax
        endif
        spd_ui_message,'Invalid fixed '+inv+'; values reset. (Must be yyyy-mm-dd/hh:mm:ss)', $
                       sb=state.statusBar, hw=state.historywin, dialog=~keyword_set(nopopups)
      endif
      minv = time_double(minv)
      maxv = time_double(maxv)
    endif
    
    if finite(minv,/nan) || finite(maxv,/nan) then begin
      if finite(minv,/nan) then begin
        invd = 'min'
        widget_control, minid, set_value=oldmin
      endif
      if finite(maxv,/nan) then begin
        invd = keyword_set(invd) ? ' and max':'max'
        widget_control, maxid, set_value=oldmax
      endif
      spd_ui_message,'Invalid fixed '+invd+'; values reset.', $
                     sb=state.statusbar, hw=state.historywin, dialog=~keyword_set(nopopups)
    endif else begin
      if minv ge maxv then begin
        spd_ui_message,'Maximum range value must be greater than minimum; values reset.', $
                       sb=state.statusbar, hw=state.historywin, dialog=~keyword_set(nopopups)
        widget_control, minid, set_value=oldmin
        widget_control, maxid, set_value=oldmax
      endif else if scaling ne 0 && minv le 0 && ~istimeaxis then begin
        spd_ui_message,'Range must be greater than zero for logarithmic scaling.', $
                       sb=state.statusbar, hw=state.historywin, dialog=~keyword_set(nopopups)
        newmin = (oldmin gt 0)? oldmin:1
        newmax = (oldmax gt 0)? oldmax:10
        widget_control, minid, set_value=newmin
        widget_control, maxid, set_value=newmax
      endif else begin
        axisSettings->setproperty, minfixedrange=minv
        axisSettings->setproperty, maxfixedrange=maxv
      endelse
    endelse
  ;if isTimeAxis then return ; will always be fixed for time, regardless of widget selections
  endif
  
  ;Auto-Range
  ;
  id = widget_info(tlb, find_by_uname='autorange')
  if widget_info(ID, /button_set) then begin
    axissettings->SetProperty,rangeoption=0
    rmarginid = widget_info(tlb,find_by_uname='rmincrement')
    widget_control, rmarginid, get_value = rangemargin
    if ~finite(rangemargin,/nan) then begin
      if rangemargin lt 0 then begin
        spd_ui_message,'Range Margin value must be greater than 0; value reset.', $
                       sb=state.statusbar, hw=state.historywin, dialog=~keyword_set(nopopups)
        axissettings->GetProperty, rangemargin=rangemargin
        Widget_Control, rmarginid, set_value = rangemargin*100
      endif else begin
        axissettings->SetProperty, rangemargin = rangemargin/100
      endelse
    endif else begin
      spd_ui_message,'Invalid range margin; value reset.', $
                     sb=state.statusbar, hw=state.historywin, dialog=~keyword_set(nopopups)
      axissettings->GetProperty, rangemargin=rangemargin
      Widget_Control, rmarginid, set_value = rangemargin*100
    endelse
    
    ; Bound Scaling
    ;
    boundID = widget_info(tlb, find_by_uname='boundscaling')
    bound = widget_info(boundID, /button_set)
    
    if bound then begin
      minID = widget_info(tlb, find_by_uname='minboundrange')
      widget_control, minID, get_value = minboundrange
      maxID = widget_info(tlb, find_by_uname='maxboundrange')
      widget_control, maxID, get_value = maxboundrange
      if ~finite(minboundrange,/nan) && ~finite(maxboundrange,/nan) then begin
        if minboundrange ge maxboundrange then begin
          spd_ui_message,'Maximum bound scaling must be greater than minimum; values reset.', $
                         sb=state.statusbar, hw=state.historywin, dialog=~keyword_set(nopopups)
          Widget_Control, boundID, Set_Button=0
          bound = 0
        endif else if scaling ne 0 && maxboundrange le 0 then begin
          spd_ui_message,'Negative bound scaling range for a log axis. Bound scaling not used.', $
                         sb=state.statusbar, hw=state.historywin, dialog=~keyword_set(nopopups)
          Widget_Control, boundID, Set_Button=0
          bound = 0
        endif else begin
          if scaling ne 0 && minboundrange le 0 then begin
            spd_ui_message,'Warning: Negative minimum autoscaling range boundary set for a log axis.', $
                           sb=state.statusbar, hw=state.historywin
          endif
          axissettings->setproperty, maxboundrange = maxboundrange, minboundrange = minboundrange
        endelse
      endif else begin
        spd_ui_message,'Invalid bound range min/max, no changes made.', $
                       sb=state.statusbar, hw=state.historywin, dialog=~keyword_set(nopopups)
        widget_control, minID, set_value = 0
        widget_control, maxID, set_value = 0
        Widget_Control, boundID, Set_Button=0
        bound=0
      endelse
    endif
    
    axisSettings->getProperty,boundscaling=currentbound
    
    if currentBound ne bound then begin
      axissettings->SetProperty, boundscaling = bound
      spd_ui_message,'Bound scaling turned ' + (bound ? 'on.':'off.'), hw=state.historywin
    endif
    
  endif
END ;------------------------------------------------


; Simple routine to add the number to the front of a label eg. 1: and truncate the label
; to fit within the combobox (necessary mainly on linux to avoid combobox arrow disappearing)
; This is intended to prevent there every being identical labels stored in the combobox
; Identical or empty labels in the combobox can cause problems on linux etc.
function spd_ui_axis_options_create_label_name, labelnumber, value

  name = strtrim(string(labelnumber +1),2)
  name += ': '+value[0]
  ; NB: the length that can be displayed varies greatly between operating system
  ; don't change this number without testing on both windows and linux.
  if strlen(name) GT 35 then name=strmid(name, 0, 35)+'...'
  return, name
end ;------------------------------------------------


;Applies current widget values to selected label
;Label title is applied in main event handler
;
; This function should eventually replace the  
; correstponding code in the event handler.

;
PRO spd_ui_axis_options_set_labels, tlb, state,nopopups=nopopups

  compile_opt idl2, hidden
  
  ;Get current axis settings and current panel
  axissettings = spd_ui_axis_options_getaxis(state)
  ;currpanelobj = state.panelobjs[state.axispanelselect]
  currpanelobj = spd_ui_axis_options_getcurrentpanel(state)
  
  ; test for validity so OK/APPLY doesn't bomb when no data loaded bck 4/1/09
  if ~obj_valid(currpanelobj) then begin
    state.historywin->update, 'Current panel object is invalid'
    return
  endif
  
  ;Get font
  id = widget_info(tlb, find_by_uname='labelfont')
  widget_control, id, get_value =fontlist
  font = widget_info(id, /combobox_gettext)
  font = where(fontlist eq font)
  
  ;Get format
  id = widget_info(tlb, find_by_uname='labelformat')
  widget_control, id, get_value =formatlist
  format = widget_info(id, /combobox_gettext)
  format = where(formatlist eq format)
  
  ;Get size
  id = widget_info(tlb, find_by_uname='labelsize')
  widget_control, id, get_value =size
  
  ;Get color
  id = widget_info(tlb, find_by_uname='labelcolorwin')
  widget_control, id, get_value =colorwin
  colorwin->getProperty,graphics_tree=scene
  scene->getProperty,color=color
  
  ;Get margin size (to handle invalid entries)
  id = widget_info(tlb, find_by_uname='labelmargin')
  widget_control, id, get_value = marginsize
  
  ;Set Values, sync to labels if applicable
  axissettings->getProperty, labels=labels
  if obj_valid(labels) then begin
    currlabelobj = labels->get(position = state.labelselect)
    if obj_valid(currlabelObj) then begin
      currlabelobj->SetProperty, font=font, format=format, color=color
      if state.axisselect eq 1 then begin
        axissettings->GetProperty, blacklabels=blacklabels, showlabels=showlabels
        if ~blacklabels and showlabels then currpanelobj->SyncLinesToLabels
      endif
      if ~finite(size,/nan) then begin
        ;size will be cast as short when added to object
        if fix(size) lt 1 then begin
          spd_ui_message,'Label Size must be greater than or equal to one; value reset.', $
                         sb=state.statusbar, hw=state.historywin, dialog=~keyword_set(nopopups)
          currlabelobj->GetProperty, size = prevsize
          id = widget_info(tlb, find_by_uname='labelsize')
          widget_control, id, set_value =prevsize
        endif else currlabelobj->SetProperty, size = size
      endif else begin
        spd_ui_message,'Invalid label font size; value reset.', $
                       sb=state.statusbar, hw=state.historywin, dialog=~keyword_set(nopopups)
        currlabelobj->GetProperty, size = prevsize
        id = widget_info(tlb, find_by_uname='labelsize')
        widget_control, id, set_value =prevsize
      endelse
      if finite(marginsize, /nan) then begin
        spd_ui_message,'Invalid label margin size; value reset.', $
                       sb=state.statusbar, hw=state.historywin, dialog=~keyword_set(nopopups)
        axissettings->GetProperty, margin=prevmargin
        id = widget_info(tlb, find_by_uname='labelmargin')
        widget_control, id, set_value=prevmargin
      endif
    endif $
    else state.historywin->update, 'Invalid label object'
  endif else state.historywin->update, 'Invalid labels object'
  
END ;------------------------------------------------


pro spd_ui_axis_options_set_major_ticks,state,nopopups=nopopups

  compile_opt idl2,hidden
  
  tlb = state.tlb
  
  axissettings = spd_ui_axis_options_getaxis(state)
  
  ; only show a dialog if setting applies to a currently active choice
  showmessage = 1
  id = widget_info(tlb,find_by_uname='bynumber')
  bynumberset = widget_info(id,/button_set)
  
  ;setting number of major ticks
  showmessage = bynumberset
  id = widget_info(tlb, find_by_uname = 'nummajorticks')
  widget_control,id,get_value=ticknum
  spd_ui_spinner_get_max_value, id, majormax 
  if ~finite(ticknum,/nan) then begin
    if tickNum gt majormax then begin 
      spd_ui_message,'Major Ticks number cannot be greater than ' + STRTRIM(string(majormax,format='(I)'),2) + '; value reset.', $
      sb=state.statusbar, hw=state.historywin, $
        dialog=(showmessage && ~keyword_set(nopopups))
      axisSettings->getProperty,numMajorTicks=ticknum
      widget_control,id,set_value=ticknum    
    endif else if tickNum lt 0 then begin
      spd_ui_message,'Major Ticks number cannot be less than 0; value reset.', $
                     sb=state.statusbar, hw=state.historywin, $
                     dialog=(showmessage && ~keyword_set(nopopups))
      axisSettings->getProperty,numMajorTicks=0
      widget_control,id,set_value=ticknum
    endif else begin
      axissettings->SetProperty, nummajorticks = ticknum
    endelse
  endif else begin
    spd_ui_message,'Invalid number of major ticks; value reset.', $
                   sb=state.statusbar, hw=state.historywin, $
                   dialog=(showmessage && ~keyword_set(nopopups))
    axisSettings->getProperty,numMajorTicks=ticknum
    widget_control,id,set_value=ticknum
  endelse
  
  showmessage = ~bynumberset
  id = widget_info(tlb, find_by_uname = 'majortickevery')
  widget_control,id,get_value=majortickevery
  if ~finite(majortickevery,/nan) then begin
    if majortickevery le 0 then begin
      spd_ui_message,'Major tick interval must be greater than zero; value reset.', $
                     sb=state.statusbar, hw=state.historywin, $
                     dialog=(showmessage && ~keyword_set(nopopups))
      ; reset value AND units
      axissettings->GetProperty,majorTickEvery=majorTickEvery,majorTickUnits=majorTickUnits
      widget_control,id,set_value=majorTickEvery
      id = widget_info(tlb, find_by_uname = 'majortickunits')
      widget_control, id, set_combobox_select = majortickunits
    endif else begin
      axisSettings->setProperty,majorTickEvery=majorTickEvery
    endelse
  endif else begin
    spd_ui_message,'Invalid major tick interval; value reset.', $
                   sb=state.statusbar, hw=state.historywin, $
                   dialog=(showmessage && ~keyword_set(nopopups))
    ;reset value AND units
    axissettings->GetProperty,majorTickEvery=majorTickEvery, majorTickUnits=majorTickUnits
    widget_control,id,set_value=majorTickEvery
    ;units = axisSettings->getUnits()
    id = widget_info(tlb, find_by_uname = 'majortickunits')
    ;widget_control, id, set_value = units
    widget_control, id, set_combobox_select = majortickunits
  endelse
  
  axisSettings->setProperty,majorTickUnits=spd_ui_get_combobox_select(tlb,'majortickunits')
  
  id = widget_info(tlb,find_by_uname='bynumber')
  axisSettings->setProperty,majorTickAuto=widget_info(id,/button_set)
  
end ;------------------------------------------------


pro spd_ui_axis_options_set_minor_ticks,state,nopopups=nopopups

  compile_opt idl2,hidden
  
  tlb = state.tlb
  
  axissettings = spd_ui_axis_options_getaxis(state)
  
  showmessage = 1
  ;setting number of minor ticks
  id = widget_info(tlb, find_by_uname = 'numminorticks')
  showmessage = widget_info(id,/sensitive)
  widget_control,id,get_value=ticknum
  if ~finite(ticknum,/nan) then begin
    if tickNum lt 0 then begin
      spd_ui_message,'Minor Tick Number cannot be less than 0; value reset.', $
                     sb=state.statusbar, hw=state.historywin, $
                     dialog=(showmessage && ~keyword_set(nopopups))
      axisSettings->getProperty,numminorTicks=ticknum
      widget_control,id,set_value=ticknum
    endif else if tickNum gt 2ll^63-1 then begin  ;(2ll^63-1 rolls over to the maximum positive signed 64 bit integer, 2's complement FTW)
      spd_ui_message,strtrim(tickNum,2) + ' is waaaaaay too many minor ticks. Try something smaller.', $
      sb=state.statusbar, hw=state.historywin, $
        dialog=(showmessage && ~keyword_set(nopopups))
      axisSettings->getProperty,numminorTicks=ticknum
      widget_control,id,set_value=ticknum
    endif else begin
      axissettings->SetProperty, numminorticks = ticknum
    endelse
  endif else begin
    spd_ui_message,'Invalid number of minor ticks, no changes made.', $
                   sb=state.statusbar, hw=state.historywin, $
                   dialog=(showmessage && ~keyword_set(nopopups))
    axisSettings->getProperty, numminorticks = ticknum
    widget_control, id, set_value = ticknum
  endelse
  
  for i = 0,3 do begin
    id = widget_info(tlb,find_by_uname='logminorticktype'+strtrim(i,2))
    if widget_info(id,/button_set) then begin
      axisSettings->setProperty,logminorticktype=i
    endif
  endfor
  
  ;ensure that minor ticks are on auto
  axisSettings->setProperty,minorTickAuto=1
  
end ;------------------------------------------------


pro spd_ui_axis_options_set_first_ticks,state,nopopups=nopopups

  compile_opt idl2,hidden
  
  tlb = state.tlb
  
  axissettings = spd_ui_axis_options_getaxis(state)
  axissettings->GetProperty, istimeaxis=istime, maxfixedrange=maxfixedrange
  
  id = widget_info(tlb, find_by_uname = 'firsttickat')
  widget_control,id,get_value=firsttickat
  
  f = 'Align ticks at'
  showmessage = 1
  bid = widget_info(tlb,find_by_uname='bynumber')
  bynumberset = widget_info(bid,/button_set)
  showmessage=~bynumberset
  ;If dealing with time axis
  if istime then begin
    if ~is_string(spd_ui_timefix(firsttickat)) then begin
      spd_ui_message,f+': Invalid entry; value reset. (Must be yyyy-mm-dd/hh:mm:ss)', $
                     sb=state.statusbar, hw=state.historywin, /dontshow, $
                     dialog=(showmessage && ~keyword_set(nopopups))
      axissettings->GetProperty,firsttickat=firsttickat
      widget_control,id,set_value=time_string(firsttickat)
    endif else begin
      axisSettings->setProperty,firsttickat=time_double(spd_ui_timefix(firsttickat))
    endelse
  ;If dealing with non-time axis
  endif else if finite(firsttickat) then begin
    axisSettings->setProperty,firsttickat=firsttickat
  endif else begin
    spd_ui_message,'Invalid "'+f+'"; no changes made.', $
                   sb=state.statusbar, hw=state.historywin, /dontshow, $
                   dialog=(showmessage && ~keyword_set(nopopups))
  endelse
  
end ;------------------------------------------------



; Set currect ticks options
;  
; This function should eventually replace the  
; correstponding code in the event handler.
;  
; nopopups: Set methods sometimes get called when not on an ok or apply. 
;           To prevent annoyance, these actions won't trigger popup messages
pro spd_ui_axis_options_set_ticks,tlb,state,nopopups=nopopups

  compile_opt idl2,hidden
  panelObjs = spd_ui_axis_options_getpanelobjs(state)
  if ~Obj_valid(panelObjs[0]) then return
  axissettings = spd_ui_axis_options_getaxis(state)
  
  ;set major tick settings
  spd_ui_axis_options_set_major_ticks,state,nopopups=nopopups
  
  ;set minor tick settings
  spd_ui_axis_options_set_minor_ticks,state,nopopups=nopopups
  
  ;set first tick settings
  spd_ui_axis_options_set_first_ticks,state,nopopups=nopopups
  
  ;set 'Nice ticks' button
  id = widget_info(tlb,find_by_uname='niceticks')
  ;must be set to zero when not sensitive until new behavior
  ;is implemented, otherwise will override other settings
  axissettings->setproperty, autoticks = widget_info(id,/button_set)
  axissettings->setProperty,tickStyle=spd_ui_get_combobox_select(tlb,'tickstyle')
  
  ;tick placement options
  id = widget_info(tlb, find_by_uname = 'bottomplace')
  axissettings->SetProperty, bottomplacement = widget_info(id,/button_set)
  
  id = widget_info(tlb, find_by_uname = 'topplace')
  axissettings->SetProperty, topplacement = widget_info(id,/button_set)
  
  ;tick length options
  
  ; 2011-06-24 lphilpott
  ; Adding code to issue dialog messages for invalid major and minor tick LENGTHS
  ; This will mean the user can't set an invalid entry and click okay without being
  ; informed that their entry will be ignored.
  
  id = widget_info(tlb, find_by_uname = 'majorlength')
  widget_control, id, get_value=value  
  spd_ui_spinner_get_max_value, id, majormax
  if ~finite(value,/nan) then begin
    if value gt majormax then begin
      spd_ui_message,'Major tick length must be less than or equal to ' + STRTRIM(string(majormax,format='(I)'),2) + '; value reset.', $
      sb=state.statusbar, hw=state.historywin, dialog=~keyword_set(nopopups)
      axisSettings->getProperty, majorlength = prevvalue
      if prevvalue gt majormax then prevvalue = majormax
      widget_control, id, set_value=STRTRIM(string(prevvalue,format='(I)'),2)   
    endif else if value lt 0. then begin
      spd_ui_message,'Major tick length must be greater than or equal to 0; value reset.', $
                     sb=state.statusbar, hw=state.historywin, dialog=~keyword_set(nopopups)
      axisSettings->getProperty, majorlength = prevvalue
      if prevvalue lt 0 then prevvalue = 0
      widget_control, id, set_value=prevvalue
    endif else begin
      axisSettings->setProperty, majorlength = value
    endelse
  endif else begin
    spd_ui_message,'Invalid major tick length; value reset.', $
                   sb=state.statusbar, hw=state.historywin, dialog=~keyword_set(nopopups)
    axisSettings->getProperty, majorlength = prevvalue
    widget_control, id, set_value=prevvalue
  endelse
  
  id = widget_info(tlb, find_by_uname = 'minorlength')
  widget_control, id, get_value=value
  spd_ui_spinner_get_max_value, id, majormax
  if ~finite(value,/nan) then begin    
    if value gt majormax then begin
      spd_ui_message,'Minor tick length must be less than or equal to ' + STRTRIM(string(majormax,format='(I)'),2) + '; value reset.', $
      sb=state.statusbar, hw=state.historywin, dialog=~keyword_set(nopopups)
      axisSettings->getProperty, minorlength = prevvalue
      if prevvalue gt majormax then prevvalue = majormax
      widget_control, id, set_value=prevvalue
    endif else if value lt 0. then begin
      spd_ui_message,'Minor tick length must be greater than or equal to 0; value reset.', $
                     sb=state.statusbar, hw=state.historywin, dialog=~keyword_set(nopopups)
      axisSettings->getProperty, minorlength = prevvalue
      if prevvalue lt 0 then prevvalue = 0
      widget_control, id, set_value=prevvalue
    endif else begin
      axisSettings->setProperty, minorlength = value
    endelse
  endif else begin
    spd_ui_message,'Invalid minor tick length; value reset.', $
                   sb=state.statusbar, hw=state.historywin, dialog=~keyword_set(nopopups)
    axisSettings->getProperty, minorlength = prevvalue
    widget_control, id, set_value=prevvalue
  endelse
end


;Get annotation settings and apply
;Only does first annotation at the moment
;
; This function should eventually replace the  
; correstponding code in the event handler.

;
pro  spd_ui_axis_options_set_annotations,tlb,state,nopopups=nopopups

  compile_opt idl2, hidden
  panelobjs = spd_ui_axis_options_getpanelobjs(state)
  if ~Obj_valid(panelObjs[0]) then return
  axissettings = spd_ui_axis_options_getaxis(state)
  
  ; Check font size is valid
  id = widget_info(state.tlb, find_by_uname='anofontsize')
  widget_control, id, get_value=anofontsize
  if anofontsize lt 1 then begin
    spd_ui_message,'Annotation font size must be greater than or equal to one; value reset.', $
                   sb=state.statusbar, hw=state.historywin, dialog=~keyword_set(nopopups)
    axissettings->GetProperty, annotatetextobject = annotatetextobject
    annotatetextobject->GetProperty, size = prevanofontsize
    widget_control, id, set_value=prevanofontsize
  endif else if finite(anofontsize, /nan) then begin
    spd_ui_message,'Invalid annotation font size; value reset.', $
                   sb=state.statusbar, hw=state.historywin, dialog=~keyword_set(nopopups)
    axissettings->GetProperty, annotatetextobject = annotatetextobject
    annotatetextobject->GetProperty, size = prevanofontsize
    widget_control, id, set_value=prevanofontsize
  endif else begin;set a valid font size
    axissettings->GetProperty, annotatetextobject = annotatetextobject
    annotatetextobject->SetProperty, size = anofontsize
  endelse
  ; Check annotate every is valid
  id = widget_info(state.tlb, find_by_uname='annotateevery')
  widget_control, id, get_value=aneveryvalue
  if aneveryvalue le 0 then begin
    spd_ui_message,'Annotate every value must be greater than zero; value reset.', $
                   sb=state.statusbar, hw=state.historywin, dialog=~keyword_set(nopopups)
    axissettings->GetProperty, annotateevery = prevaneveryvalue
    widget_control, id, set_value=prevaneveryvalue
  endif else if finite(aneveryvalue, /nan) then begin
    spd_ui_message,'Invalid annotate every value; value reset.', $
                   sb=state.statusbar, hw=state.historywin, dialog=~keyword_set(nopopups)
    axissettings->GetProperty, annotateevery = prevaneveryvalue
    widget_control, id, set_value=prevaneveryvalue
  endif
  
  
  firstannotationid = widget_info(tlb,find_by_uname='firstannotation')
  widget_control,firstannotationid,get_value=firstannotation
  
  axissettings->GetProperty, istimeaxis=istime, maxfixedrange=maxfixedrange
  axissettings->GetProperty, annotatemajorticks=annotatemajorticks
  axissettings->GetProperty, annotateaxis=annotateaxis
  
  f = 'Align Annotations at'
  
  ;If dealing with time axis
  if istime then begin
    firstannotation = spd_ui_timefix(firstannotation)
    if ~is_string(firstannotation) then begin
      spd_ui_message,f+': Invalid entry; value reset. (Must be yyyy-mm-dd/hh:mm:ss)', $
                 sb=state.statusbar, hw=state.historywin, /dontshow, dialog=~keyword_set(nopopups)
      axissettings->GetProperty,firstannotation=firstannotation
      widget_control,firstannotationid,set_value=time_string(firstannotation)
    endif else if annotateaxis and ~annotatemajorticks and (time_double(firstannotation) gt maxfixedrange) then begin
      spd_ui_message,f+': Invalid entry, value cannot be greater than range.', $
                 sb=state.statusbar, hw=state.historywin, /dontshow, dialog=~keyword_set(nopopups)
      axissettings->GetProperty,firstannotation=firstannotation
      widget_control,firstannotationid,set_value=time_string(firstannotation)
    endif else begin
      axisSettings->setProperty,firstannotation=time_double(firstannotation)
    endelse
  ;If dealing with non-time axis
  endif else if finite(firstannotation) then begin
    if  annotateaxis and ~annotatemajorticks and (firstannotation gt maxfixedrange) then begin
      spd_ui_message,f+': Invalid entry, value cannot be greater than range.', $
            sb=state.statusbar, hw=state.historywin, /dontshow, dialog=~keyword_set(nopopups)
    endif else begin
      axisSettings->setProperty,firstannotation=firstannotation
    endelse
  endif else begin
    spd_ui_message,'Invalid "'+f+'" value; value reset.', $
         sb=state.statusbar, hw=state.historywin, /dontshow, dialog=~keyword_set(nopopups)
    axisSettings->getProperty,firstannotation=prevfirstannotation
    widget_control,firstannotationid,set_value=prevfirstannotation
  endelse
  
end ;-------------------------------



; Get grid options from widgets and apply.
; 
; This function should eventually replace the  
; correstponding code in the event handler.
;
pro spd_ui_axis_options_set_grids, tlb, state,nopopups=nopopups

  compile_opt idl2, hidden
  
  panelObjs = spd_ui_axis_options_getpanelobjs(state)
  if ~Obj_valid(panelObjs[0]) then return
  axissettings = spd_ui_axis_options_getaxis(state)
  currpanelobj = spd_ui_axis_options_getcurrentpanel(state)
  currpanelobj->GetProperty, settings=panelsettings
  
  ;outline thickness
;  id = widget_info(tlb, find_by_uname = 'outlinethick')
;  widget_control, id, get_value=outlinethick
;  if outlinethick lt 1. or outlinethick gt 10 or ~finite(outlinethick) then begin
;    messageString = finite(outlinethick) ? 'Frame thickness must be between 1 and 10; value reset.':  $
;                                           'Invalid frame thickness; value reset.'
;    if ~keyword_set(nopopups) then begin
;      response = dialog_message(messageString, /CENTER)
;    endif
;    state.statusbar->update,messageString
;    state.historywin->update,messageString
;    panelsettings->GetProperty, framethick=prevoutlinethick
;    widget_control, id, set_value=prevoutlinethick
;  endif else begin
;    panelsettings->SetProperty, framethick=outlinethick
;  endelse
  
  ;major grid thickness
  showmessage = 1
  axissettings->GetProperty, majorgrid=majorgrid
  majorgrid->GetProperty, show=showmessage
  id = widget_info(tlb, find_by_uname = 'majorgridthick')
  widget_control, id, get_value=majorgridthick
  if majorgridthick lt 1. or majorgridthick gt 10 or ~finite(majorgridthick) then begin
    messageString = finite(majorgridthick) ? 'Major grid thickness must be between 1 and 10; value reset.': $
                                             'Invalid major grid thickness; value reset.'
    spd_ui_message, messageString, sb=state.statusbar, hw=state.historywin, $
                    dialog=(showmessage && ~keyword_set(nopopups))
    majorgrid->GetProperty, thickness=prevmajorthick
    widget_control, id, set_value=prevmajorthick
  endif else begin
    majorgrid->SetProperty, thickness=majorgridthick
  endelse
  
  ;minor grid thickness
  id = widget_info(tlb, find_by_uname = 'minorgridthick')
  widget_control, id, get_value=minorgridthick
  showmessage = 1
  axissettings->GetProperty, minorgrid=minorgrid
  minorgrid->GetProperty, show=showmessage
  if minorgridthick lt 1. or minorgridthick gt 10 or ~finite(minorgridthick) then begin
    messageString = finite(minorgridthick) ? 'Minor grid thickness must be between 1 and 10; value reset.': $
                                             'Invalid minor grid thickness; value reset.'
    spd_ui_message, messageString, sb=state.statusbar, hw=state.historywin, $
                    dialog=(showmessage && ~keyword_set(nopopups))
    minorgrid->GetProperty, thickness=prevminorthick
    widget_control, id, set_value=prevminorthick
  endif else begin
    minorgrid->SetProperty, thickness=minorgridthick
  endelse
  
end ;------------------------



pro spd_ui_axis_options_set_title, tlb, state,nopopups=nopopups

  compile_opt idl2, hidden
  
  ;Get current axis settings and current panel
  axissettings = spd_ui_axis_options_getaxis(state)
  ;currpanelobj = state.panelobjs[state.axispanelselect]
  currpanelobj = spd_ui_axis_options_getcurrentpanel(state)
  
  if ~obj_valid(currpanelobj) then begin
    state.historywin->update, 'Current panel object is invalid'
    return
  endif
  
  ;Get title
  id = widget_info(tlb, find_by_uname='titletextedit')
  widget_control, id, get_value = title
  
  ;Get title font
  id = widget_info(tlb, find_by_uname='titlefont')
  widget_control, id, get_value =fontlist
  font = widget_info(id, /combobox_gettext)
  font = where(fontlist eq font)
  
  ;Get title format
  id = widget_info(tlb, find_by_uname='titleformat')
  widget_control, id, get_value =formatlist
  format = widget_info(id, /combobox_gettext)
  format = where(formatlist eq format)
  
  axissettings->getProperty, titleobj=titleobj, subtitleobj=subtitleobj
  titleobj->SetProperty, value=title, font=font, format=format
  
  ;Get subtitle
  id = widget_info(tlb, find_by_uname='subtitletextedit')
  widget_control, id, get_value = subtitle
  
  ;Get subtitle font
  id = widget_info(tlb, find_by_uname='subtitlefont')
  widget_control, id, get_value =fontlist
  font = widget_info(id, /combobox_gettext)
  font = where(fontlist eq font)
  
  ;Get subtitle format
  id = widget_info(tlb, find_by_uname='subtitleformat')
  widget_control, id, get_value =formatlist
  format = widget_info(id, /combobox_gettext)
  format = where(formatlist eq format)
  
  subtitleobj->SetProperty, value=subtitle, font=font, format=format
  
  
  ;Get title size (to handle invalid entries)
  id = widget_info(tlb, find_by_uname='titlesize')
  widget_control, id, get_value =size
  
  ;Get subtitle size (to handle invalid entries)
  id = widget_info(tlb, find_by_uname='subtitlesize')
  widget_control, id, get_value =subsize
  
  ;Get margin size (to handle invalid entries)
  id = widget_info(tlb, find_by_uname='titlemargin')
  widget_control, id, get_value = marginsize
  ; check for invalid entries
  
  ;check title size
  if ~finite(size,/nan) then begin
    ;size will be cast as short when added to object
    if fix(size) le 0 then begin
      spd_ui_message,'Title font size must be greater than zero; value reset.', $
               sb=state.statusbar, hw=state.historywin, dialog=~keyword_set(nopopups)
      titleobj->GetProperty, size = prevsize
      id = widget_info(tlb, find_by_uname='titlesize')
      widget_control, id, set_value =prevsize
    endif else begin
      titleobj->SetProperty, size = size
    endelse
  endif else begin
    spd_ui_message,'Invalid title font size; value reset.', $
             sb=state.statusbar, hw=state.historywin, dialog=~keyword_set(nopopups)
    titleobj->GetProperty, size = prevsize
    id = widget_info(tlb, find_by_uname='titlesize')
    widget_control, id, set_value =prevsize
  endelse
  
  ;check subtitle size
  if ~finite(subsize,/nan) then begin
    ;size will be cast as short when added to object
    if fix(subsize) le 0 then begin
      spd_ui_message,'Subtitle font size must be greater than zero; value reset.', $
               sb=state.statusbar, hw=state.historywin, dialog=~keyword_set(nopopups)
      subtitleobj->GetProperty, size = prevsize
      id = widget_info(tlb, find_by_uname='subtitlesize')
      widget_control, id, set_value =prevsize
    endif else begin
      subtitleobj->SetProperty, size = subsize
    endelse
  endif else begin
    spd_ui_message,'Invalid subtitle font size; value reset.', $
             sb=state.statusbar, hw=state.historywin, dialog=~keyword_set(nopopups)
    subtitleobj->GetProperty, size = prevsize
    id = widget_info(tlb, find_by_uname='subtitlesize')
    widget_control, id, set_value =prevsize
  endelse
  if finite(marginsize, /nan) then begin
    spd_ui_message,'Invalid title margin size; value reset.', $
             sb=state.statusbar, hw=state.historywin, dialog=~keyword_set(nopopups)
    axissettings->GetProperty, titlemargin=prevmargin
    id = widget_info(tlb, find_by_uname='titlemargin')
    widget_control, id, set_value=prevmargin
  endif else axissettings->setProperty, titlemargin=marginsize
  
; colour, placement and orientation are handled in main event handler
end

;nopopups: Set methods sometimes get called when not on an ok or apply. To prevent annoyance, these actions won't trigger popup messages
PRO spd_ui_axis_options_setvalues, tlb, state,nopopups=nopopups

  compile_opt idl2, hidden
  
  ; Get current scaling
  spd_ui_axis_options_set_scaling, tlb, state,nopopups=nopopups
  
  ; Get current range settings and apply
  spd_ui_axis_options_set_range, tlb, state,nopopups=nopopups
  
  ;get current tick settings and apply
  spd_ui_axis_options_set_ticks, tlb,state,nopopups=nopopups
  
  ; Get current label settings and apply
  spd_ui_axis_options_set_labels, tlb, state,nopopups=nopopups
  
  ;Get current annotation settings and apply
  spd_ui_axis_options_set_annotations,tlb,state,nopopups=nopopups
  
  ;Get current grid settings and apply (currently just checks spinner values are valid)
  spd_ui_axis_options_set_grids, tlb, state,nopopups=nopopups
  
  ;Get current title settings and apply
  spd_ui_axis_options_set_title, tlb, state, nopopups=nopopups
  
  return
  
END ;--------------------------------------------------------------------------------



; Update appropriate widgets when switching scaling (e.g. linear, log10, natural log)
;
pro spd_ui_axis_options_update_scaling, state, axissettings, linear=linear, log10=log10, natural_log=natural_log

    compile_opt idl2, hidden

  
  ; Set scaling specific variables
;  if keyword_set(linear) then begin
  if ~undefined(linear) then begin
    scaling = 0
    def_range = [0,0] * !values.d_nan 
    msg = 'Linear'
  endif
;  if keyword_set(log10) then begin
  if ~undefined(log10) then begin
    scaling = 1
    def_range = [0,0]
    msg = 'Log 10'
  endif
;  if keyword_set(natural_log) then begin
  if ~undefined(natural_log) then begin
    scaling = 2
    def_range = [0,0]
    msg = 'Natural Log'
  endif

  ; Apply selected options
  axissettings->SetProperty,scaling=scaling
  
  ; Update spinner min/max values for non-time axes
  is_time = widget_info(state.tlb,find_by_uname='istime')
  if ~widget_info(is_time,/button_set) then begin
    spd_ui_spinner_set_min_value, widget_info(state.tlb, find_by_uname = 'minincrement'), def_range[0]
    spd_ui_spinner_set_min_value, widget_info(state.tlb, find_by_uname = 'maxincrement'), def_range[1]
  endif
  
  ; Sensitize other widgets as needed
  id = widget_info(state.tlb,find_by_uname='logminorticktypebase')
  widget_control, id, sensitive = (scaling gt 0)
  spd_ui_axis_update_units,state
  
  state.historywin->Update, msg+' scaling selected'

end




; Modified so that currlabelobj is no longer a pointer (lphilpott 7/26/2011)
PRO spd_ui_axis_options_update_labels, tlb, axissettings, currlabelobj, labelcolorwindow

  compile_opt idl2, hidden
  
  axissettings->GetProperty, orientation=orientation, margin = margin
  if obj_valid(currlabelobj) && (n_elements(currlabelobj) gt 0) then begin
    currlabelobj->GetProperty, font=font, format=format, size=size, color=color, value=value, show=show
    
    ;Text Options
    id = widget_info(tlb, find_by_uname='labeltextedit')
    widget_control, id, set_value=value
    
    id = widget_info(tlb, find_by_uname='labelfont')
    widget_control, id, set_combobox_select=font
    
    id = widget_info(tlb, find_by_uname='labelformat')
    widget_control, id, set_combobox_select=format
    
    id = widget_info(tlb, find_by_uname='labelsize')
    widget_control, id, set_value=size
    
    ;Show
    id = widget_info(tlb, find_by_uname='showlabel')
    widget_control, id, set_button=show
  endif
  
  
  ;Color window
  Widget_Control, labelcolorWindow, Get_Value=labelcolorWin
  labelcolorwin->getproperty, graphics_tree=scene
  
  if obj_valid(scene) then begin
    scene->remove,/all
    scene->setproperty, color=reform(color)
  endif else begin
    scene=obj_new('IDLGRSCENE', color=reform(color))
    labelcolorwin->setproperty, graphics_tree=scene
  endelse
  
  labelcolorWin->draw, scene
  
  
  ;Style
  id = widget_info(tlb, find_by_uname='labelhorizontal')
  widget_control, id, set_button=~orientation
  
  id = widget_info(tlb, find_by_uname='labelvertical')
  widget_control, id, set_button=orientation
  
  id = widget_info(tlb, find_by_uname='labelmargin')
  widget_control, id, set_value=margin
  
END ;---------------------------------------------------------

; Event Handler
; -------------
; The code contained here should mainly be for:
;   -widget updates
;   -output to the user
; Ideally changes to the axis options object should occur in
; helper procedures contained above.
;
PRO spd_ui_axis_options_event, event

  Compile_Opt idl2,hidden
  

  ; Get State structure from top level base
  Widget_Control, event.TOP, Get_UValue=state, /No_Copy
  

  ; Catch block for any errors that occur while processing events. 
  err_xxx = 0
  Catch, err_xxx
  IF (err_xxx NE 0) THEN BEGIN
    Catch, /Cancel
    Help, /Last_Message, Output = err_msg
    
    spd_ui_sbar_hwin_update, state, err_msg, /error, err_msgbox_title='Error in Axis Options'
    
    Widget_Control, event.TOP, Set_UValue=state, /No_Copy
    widget_control, event.top,/destroy
    RETURN
  ENDIF
  
  ;currpanelobj = state.panelobjs[state.axispanelselect]
  currpanelobj = spd_ui_axis_options_getcurrentpanel(state)
  
  
  ;kill request block
  IF (Tag_Names(event, /Structure_Name) EQ 'WIDGET_KILL_REQUEST') THEN BEGIN
    state.statusbar->Update, 'Widget kill request received...'
    state.historyWin->Update, 'Widget kill request received...'
    
    ;Call reset method on the settings object for every panel:
    ;*********************************************************
    ;
    
    (state.windowStorage->getActive())->reset
    ;  IF Obj_Valid(state.panelObjs[0]) THEN BEGIN
    ;    for i=0,n_elements(state.panelobjs)-1 do state.panelobjs[i]->reset
    ;  ENDIF
    ;IF Obj_Valid(state.infoaxissettings) THEN state.infoaxissettings->reset
    state.statusbar->Update, 'Panels reset.'
    state.historyWin->Update, 'Panels reset.'
    
    state.drawObject->update, state.windowStorage, state.loadedData
    state.drawObject->draw
    state.scrollbar->update
    
    state.statusbar->Update, 'Active window refreshed.'
    state.historyWin->Update, 'Active window refreshed.'
    
    state.statusbar->Update, 'Closing Axis Options widget...
    state.historyWin->Update, 'Closing Axis Options widget...
    dprint, dlevel=4, 'Closing Axis Options widget...
    state.tlb_statusbar->Update, 'Axis Options closed'
    dprint, dlevel=4, 'widget killed'
    Widget_Control, event.TOP, Set_UValue=state, /No_Copy
    Widget_Control, event.top, /Destroy
    RETURN
  ENDIF
  
  
  ;deal with tabs
  IF (Tag_Names(event, /Structure_Name) EQ 'WIDGET_TAB') THEN BEGIN
    Widget_Control, state.panelDroplists[event.tab], set_combobox_select = state.axispanelselect
    Widget_Control, event.TOP, Set_UValue=state, /No_Copy
    RETURN
  EndIF
  
  
  ; Get settings for current axis (once per event call)
  axissettings = spd_ui_axis_options_getaxis(state)
  
  
  ; Get the instructions from the widget causing the event and act on them.
  Widget_Control, event.id, Get_UValue=uval
  IF Size(uval, /Type) NE 0 THEN BEGIN 

    state.historyWin->Update,'SPD_UI_AXIS_OPTIONS: User value: '+uval, /dontshow
    
    CASE uval OF
      'APPLYTOALL': BEGIN
        ; ***************************************************************
        ; old way of doing things:
        spd_ui_axis_options_setvalues, state.tlb, state
        
          tabid = widget_info(state.tlb, find_by_uname='tabs',/TAB_CURRENT)
          tid = widget_info(tabid, /TAB_CURRENT)
          
          ;widget_control, state.tabbase, update=0
;          widget_control, tabid, get_value=tabval
  
        spd_ui_propagate_axis,state,tid ;favoring a delayed axis propagation over immediate to simplify code

        state.drawObject->update, state.windowStorage, state.loadedData, error=draw_error, errmsg=errmsg
        
        if draw_error ne 0 then begin
        
          ; Issue a dialog message to the user if one has been defined for this error type.
          if keyword_set(errmsg) then begin
            if in_set('TYPE', tag_names(errmsg)) then begin
              if strupcase(errmsg.type) eq 'ERROR' then begin
                if in_set('VALUE', tag_names(errmsg)) then begin
                  ok = dialog_message('Error: '+errmsg.value+' Changes reset.',/center)
                endif
              endif
            endif
          endif
          
          (state.windowStorage->getActive())->reset
          spd_ui_init_axis_window, state = state
          state.drawObject->update, state.windowStorage, state.loadedData
          currentwin=state.windowStorage->getActive()
          currentwin->getProperty, panels=panels
          
          ;update fixed range to match the auto or floating range value
          ;attempt to ensure it doesn't reset fixed min/max to 1970
          spd_ui_update_axis_from_draw,state.drawObject,panels
          state.historyWin->Update, 'Draw object update error, changes reset.'
        endif else begin
          currentwin=state.windowStorage->getActive()
          currentwin->getProperty, panels=panels
          spd_ui_update_axis_from_draw,state.drawObject,panels
          state.statusBar->update,'Changes applied to all Panels.'
          state.historyWin->update,'Changes applied to all Panels.'
        endelse
;         ***************************************************************
        spd_ui_init_axis_window, state = state
;        print, 'Applying ' + state.last_change + ' to all panels'
;        spd_ui_axis_options_apply_to_all, state
;        state.drawObject->update, state.windowStorage, state.loadedData, error=draw_error, errmsg=errmsg
;        (state.windowStorage->getActive())->reset
        state.drawObject->draw
;        state.scrollbar->update
        state.historyWin->Update, 'Active window refreshed.'
        
      end
      'APPLY': BEGIN
        spd_ui_axis_options_setvalues, state.tlb, state
;        spd_ui_propagate_axis,state,0 ;favoring a delayed axis propagation over immediate to simplify code
        
        state.drawObject->update, state.windowStorage, state.loadedData, error=draw_error, errmsg=errmsg
        
        if draw_error ne 0 then begin
          ;        if Obj_Valid(state.panelObjs[0]) then begin
          ;          for i=0,n_elements(state.panelobjs)-1 do state.panelobjs[i]->reset
          ;        endif
        
          ; Issue a dialog message to the user if one has been defined for this error type.
          if keyword_set(errmsg) then begin
            if in_set('TYPE', tag_names(errmsg)) then begin
              if strupcase(errmsg.type) eq 'ERROR' then begin
                if in_set('VALUE', tag_names(errmsg)) then begin
                  ok = dialog_message('Error: '+errmsg.value+' Changes reset.',/center)
                endif
              endif
            endif
          endif
          
          (state.windowStorage->getActive())->reset
          
          ; if Obj_Valid(state.infoaxissettings) then state.infoaxissettings->reset
          spd_ui_init_axis_window, state = state
          state.drawObject->update, state.windowStorage, state.loadedData
          
          ;(4259b) axis settings were no longer propagating through to the windowStorage following a draw error
          ; This is a temporary fix. Ultimately it might be good to always get the panel/axis information directly
          ; from the active window rather than storing multiple copies of stuff.
          currentwin=state.windowStorage->getActive()
          currentwin->getProperty, panels=panels
          ;        panelObjs=panels->get(/All)
          ;        state.panels = panels
          ;        state.panelObjs=panelObjs
          
          ;update fixed range to match the auto or floating range value
          ;attempt to ensure it doesn't reset fixed min/max to 1970
          spd_ui_update_axis_from_draw,state.drawObject,panels
          state.historyWin->Update, 'Draw object update error, changes reset.'
        endif else begin
          currentwin=state.windowStorage->getActive()
          currentwin->getProperty, panels=panels
          spd_ui_update_axis_from_draw,state.drawObject,panels
          
          spd_ui_message,'Changes applied.', hw=state.historywin
        endelse
        
        spd_ui_init_axis_window, state = state
        
        state.drawObject->draw
        state.scrollbar->update
        
        state.historyWin->Update, 'Active window refreshed.'
        
      END
      'CANC': Begin
        ;Call reset method on the settings object for every panel:
        ;*********************************************************
        ;
        ;      IF Obj_Valid(state.panelObjs[0]) THEN BEGIN
        ;        for i=0,n_elements(state.panelobjs)-1 do state.panelobjs[i]->reset
        ;      ENDIF
        (state.windowStorage->getActive())->reset
        ; IF Obj_Valid(state.infoaxissettings) THEN state.infoaxissettings->reset
        
        state.statusbar->Update, 'Panels reset.'
        state.historyWin->Update, 'Panels reset.'
        
        state.drawObject->update, state.windowStorage, state.loadedData
        state.drawObject->draw
        state.scrollbar->update
        
        state.statusbar->Update, 'Active window refreshed.'
        state.historyWin->Update, 'Active window refreshed.'
        
        state.statusbar->Update, 'Closing Axis Options widget...
        state.historyWin->Update, 'Closing Axis Options widget...
        dprint, dlevel=4, 'Closing Axis Options widget...
        state.tlb_statusbar->Update, 'Axis Options canceled'
        
        Widget_Control, event.TOP, Set_UValue=state, /No_Copy
        Widget_Control, event.top, /Destroy
        RETURN
      END
      'OK': BEGIN
        ;Exit widget:
        ;************
      
        spd_ui_axis_options_setvalues, state.tlb, state
;        spd_ui_propagate_axis,state,0 ;favoring a delayed axis propagation over immediate to simplify code
        
        state.drawObject->update, state.windowStorage, state.loadedData, error=draw_error, errmsg=errmsg
        
        if draw_error ne 0 then begin
          ;        if Obj_Valid(state.panelObjs[0]) then begin
          ;          for i=0,n_elements(state.panelobjs)-1 do state.panelobjs[i]->reset
          ;        endif
          ; Issue a dialog message to the user if one has been defined for this error type.
          if keyword_set(errmsg) then begin
            if in_set('TYPE', tag_names(errmsg)) then begin
              if strupcase(errmsg.type) eq 'ERROR' then begin
                if in_set('VALUE', tag_names(errmsg)) then begin
                  ok = dialog_message('Error: '+errmsg.value+' Changes reset.',/center)
                endif
              endif
            endif
          endif
          (state.windowStorage->getActive())->reset
          ; if Obj_Valid(state.infoaxissettings) then state.infoaxissettings->reset
          spd_ui_init_axis_window, state = state
          state.drawObject->update, state.windowStorage, state.loadedData
          ;update fixed range to match the auto or floating range value
          panels = spd_ui_axis_options_getpanels(state)
          spd_ui_update_axis_from_draw,state.drawObject,panels
          state.historyWin->Update, 'Draw object update error, changes reset.'
        endif else begin
          panels = spd_ui_axis_options_getpanels(state)
          spd_ui_update_axis_from_draw,state.drawObject,panels
        endelse
        
;        panelObjs = spd_ui_axis_options_getpanelobjs(state)
        ;      IF Obj_Valid(state.panelObjs[0]) THEN BEGIN
        ;        for i=0,n_elements(state.panelobjs)-1 do state.panelobjs[i]->setTouched
        ;      ENDIF
;        if Obj_valid(panelObjs[0]) then begin
;          for i=0, n_elements(panelobjs)-1 do panelobjs[i]->setTouched
;        endif
        
        state.drawObject->draw
        state.scrollbar->update
        
        state.statusbar->Update, 'Active window refreshed.'
        state.historyWin->Update, 'Active window refreshed.'
        dprint, dlevel=4, 'Active window refreshed.'
        
        state.statusbar->Update, 'Closing Axis Options widget...'
        state.historyWin->Update, 'Closing Axis Options widget...'
        dprint, dlevel=4, 'Closing Axis Options widget...'
        state.tlb_statusbar->update, 'Axis Options closed'
        
        Widget_Control, event.TOP, Set_UValue=state, /No_Copy
        Widget_Control, event.top, /Destroy
        RETURN
      END
      'TEMP':begin
      
      ;make sure internal state is updated before save
      spd_ui_axis_options_setvalues, state.tlb, state
;      spd_ui_propagate_axis,state,0 ;favoring a delayed axis propagation over immediate to simplify code
      ;panels = spd_ui_axis_options_getpanels(state)
      panelObjs = spd_ui_axis_options_getpanelobjs(state)
      if Obj_valid(panelObjs[0]) then begin
        for i=0, n_elements(panelobjs)-1 do panelobjs[i]->setTouched
      endif
      ;      IF Obj_Valid(state.panelObjs[0]) THEN BEGIN
      ;        for i=0,n_elements(state.panelobjs)-1 do state.panelobjs[i]->setTouched
      ;      ENDIF
      
      if obj_valid(panelObjs[state.axispanelselect]) then begin
      
        if state.axisselect eq 0 then begin
          state.template->setProperty,x_axis=axissettings->copy()
          axis_string = 'X'
        endif else begin
          state.template->setProperty,y_axis=axissettings->copy()
          axis_string = 'Y'
        endelse
        state.statusbar->update,'Current '+axis_string+'-Axis options stored for use in a Template'  
        state.historywin->update,'Current '+axis_string+'-Axis options stored for use in a Template'

        messageString = 'These values have now been stored!' +  string(10B) + string(10B) + 'To save them in a template, click File->Graph Options Template->Save Template'
        response=dialog_message(messageString,/CENTER, /information)

      endif else begin
        state.statusbar->update,'Cannot store options. Needs a valid panel to save axis options for a template.'
        state.historywin->update,'Cannot store options. Needs a valid panel to save axis options for a template.'
      endelse
      ;not sure if this is necessary
      spd_ui_init_axis_window, state = state
    end
    ;******************************************************************************
    ;Panel drop list
    ;******************************************************************************
    ;Multiple widgets have the same uvalue and trigger the same event
    ;The repeated code for each panel was making maintenance more difficult
    'PANELDROPLIST' : begin
      spd_ui_axis_options_setvalues, state.tlb, state,/nopopups
     
      state.axispanelselect = event.index
      ;currpanelobj = spd_ui_axis_options_getcurrentpanel(state)
      state.labelselect=0
      spd_ui_init_axis_window , state = state
      ; state.statusBar->Update, 'Panel selected'
      state.historywin->Update, 'Panel selected'
    end
    
    ;******************************************************************************
    ;  Annotation Options
    ;******************************************************************************
    
    'AAUTO': if event.select eq 1 then begin
      axissettings->setproperty, AnnotateExponent=0
      ;      state.statusbar->update,'Auto-Notation selected'
      state.historywin->update,'Auto-Notation selected'
    end
    'ADBL': if event.select eq 1 then begin
      axissettings->setproperty, AnnotateExponent=1
      ;     state.statusbar->update,'Decimal Notation selected'
      state.historywin->update,'Decimal Notation selected'
    end
    'AEXP': if event.select eq 1 then begin
      axissettings->setproperty, AnnotateExponent=2
      ;     state.statusbar->update,'Scientific Notation selected'
      state.historywin->update,'Scientific Notation selected'
    end
    'HEXNOT': if event.select eq 1 then begin
      axissettings->setproperty, AnnotateExponent=4
      ;     state.statusbar->update,'Scientific Notation selected'
      state.historywin->update,'Hexadecimal Notation selected'
    end
    'LINEATZERO': BEGIN
      axissettings->SetProperty, lineatzero=event.select
      ;    state.statusbar->update,'Draw Line at Zero toggled'
      state.historywin->update,'Draw Line at Zero toggled'
    END
    'SHOWDATE': BEGIN
      axissettings->SetProperty, showdate=event.select
      id = widget_info(state.tlb, find_by_uname='anodatebase')
      if event.select then begin
        widget_control, id, /sensitive
      endif else begin
        widget_control, id, sensitive=0
      endelse
      ;    state.statusbar->update,'Show Date toggled'
      state.historywin->update,'Show Date toggled'
    END
    'ANODATE1': BEGIN
      widget_control, event.id, get_value=value
      axissettings->SetProperty, datestring1=value
      ;      state.statusbar->update,'Annotate First toggled'
      state.historywin->update,'Annotate First toggled'
    END
    'ANODATE2': BEGIN
      widget_control, event.id, get_value=value
      axissettings->SetProperty, datestring2=value
      ;    state.statusbar->update,'Annotate Last toggled'
      state.historywin->update,'Annotate Last toggled'
    END
    'ANODATEPREVIEW': BEGIN
      axissettings->GetProperty, dateString1=datestring1, dateString2=datestring2
      ;panels = spd_ui_axis_options_getpanels(state)
      panelObjs = spd_ui_axis_options_getpanelobjs(state)
      IF ~in_set(Obj_Valid(panelObjs),'0') THEN BEGIN
        info = state.drawObject->GetPanelInfo(state.axispanelselect)
        line1 = formatdate(info.xrange[0], datestring1, info.xscale)
        line2 = formatdate(info.xrange[0], datestring2, info.xscale)
        preview = line1 + ssl_newline() + line2
        id = widget_info(state.tlb, find_by_uname='anodatepreviewtext')
        widget_control, id, set_value=preview
        ;  state.statusbar->update,'Annotate Preview selected'
        state.historywin->update,'Annotate Preview selected'
      ENDIF
    END
    'ANNOTATEAXIS': BEGIN
      axissettings->SetProperty, annotateaxis=event.select
      id = widget_info(state.tlb, find_by_uname='annoaxisbase')
      if event.select then begin
        widget_control, id, /sensitive
      endif else begin
        widget_control, id, sensitive=0
      endelse
      ;    state.statusbar->update,'Annotate Along Axis toggled'
      state.historywin->update,'Annotate Along Axis toggled'
    END
    'PLACEANNOTATION':BEGIN
    axissettings->SetProperty, placeannotation=event.index
    ;    state.statusbar->Update, 'Annotation placement updated to "'+event.str+'".'
    state.historyWin->Update, 'Annotation placement updated to "'+event.str+'".'
    
  ;this only works for X axis as GetPlacement returns top or bottom
  ;state.statusbar->Update, 'Annotation placement updated to "'+axissettings->GetPlacement(event.index)+'".'
  ;state.historyWin->Update, 'Annotation placement updated to "'+axissettings->GetPlacement(event.index)+'".'
  END
  'ANNOTATEMAJORTICKS': BEGIN
    axissettings->SetProperty, annotatemajorticks=event.select
    id = widget_info(state.tlb, find_by_uname='annomajorbase')
    if event.select then begin
      widget_control, id, sensitive=0
    endif else begin
      widget_control, id, /sensitive
    endelse
    ;   state.statusbar->update,'Annotate Major Ticks toggled'
    state.historywin->update,'Annotate Major Ticks toggled'
  END
  'ANNOTATEEVERY':BEGIN
  if event.valid then begin
    if event.value le 0 then begin
      state.statusBar->Update, 'Annotate Every must be greater than zero.'
    endif else begin
      axissettings->SetProperty, annotateevery = event.value
      ;     state.statusBar->Update, 'Annotate every value changed.'
      state.historywin->Update, 'Annotate every value changed.'
    endelse
  endif else if finite(event.value,/nan) then begin
    state.statusBar->Update, 'Invalid annotate every value, please re-enter.'
  endif else state.statusBar->Update, 'Annotate every value must be greater than zero.'
END
'ANNOTATEUNITS':BEGIN
axissettings->GetProperty, $
  annotateevery = annotateevery, $
  annotateUnits = annotateUnits
  
annotateEvery = spd_ui_axis_options_convert_units(annotateEvery,annotateUnits)
annotateEvery = spd_ui_axis_options_convert_units(annotateEvery,event.index,/fromSeconds)


axissettings->SetProperty, annotateunits=event.index,annotateEvery=annotateEvery

spd_ui_init_axis_window , state = state

;   state.statusbar->Update, 'Annotation units updated to "'+axissettings->GetUnit(event.index)+'".'
state.historyWin->Update, 'Annotation units updated to "'+axissettings->GetUnit(event.index)+'".'

END
'FIRSTANNOTATION':BEGIN
if finite(event.value,/nan) then state.statusBar->Update, 'Invalid ''Align annotation at'' value, please re-enter.'
END
'ANNOTATESTYLE': BEGIN
  axissettings->SetProperty, annotatestyle=event.index
  
  ;    state.statusbar->Update, 'Annotation style updated to "'+axissettings->GetAnnotationFormat(event.index)+'".'
  state.historyWin->Update, 'Annotation style updated to "'+axissettings->GetAnnotationFormat(event.index)+'".'
END
'ANNOTATERANGEMIN':BEGIN
axissettings->SetProperty, annotaterangemin = event.select
END
'ANNOTATERANGEMAX':BEGIN
axissettings->SetProperty, annotaterangemax = event.select
END
'ANNOHORIZONTAL': BEGIN
  axissettings->SetProperty, annotateorientation=~event.select
  ;   state.statusBar->Update, 'Horizontal Orientation selected'
  state.historywin->Update, 'Horizontal Orientation selected'
END
'ANNOVERTICAL':BEGIN
axissettings->SetProperty, annotateorientation=event.select
;  state.statusBar->Update, 'Vertical Orientation selected'
state.historywin->Update, 'Vertical Orientation selected'
END
'ANOFONTLIST': BEGIN
  axissettings->GetProperty, annotatetextobject = annotatetextobject
  annotatetextobject->SetProperty, font=event.index
  ;  state.statusbar->Update, 'Annotation font updated to "'+annotatetextobject->GetFont(index=event.index)+'".'
  state.historyWin->Update, 'Annotation font updated to "'+annotatetextobject->GetFont(index=event.index)+'".'
END
'ANOFONTSIZE': BEGIN
  if event.valid then begin
    ;axissettings->GetProperty, annotatetextobject = annotatetextobject
    if event.value lt 1. then begin
      state.statusbar->update, 'Font size should be greater than or equal to one.'
    endif
  ; Delay setting the font size until the user applies. Otherwise it resets the font size with every key press in the textfield
  ;         else begin
  ;          annotatetextobject->SetProperty, size=event.value
  ;    ;      state.statusBar->Update, 'Annotation font size changed.'
  ;          state.historywin->Update, 'Annotation font size changed.'
  ;        endelse
  endif else if finite(event.value, /nan) then begin
    state.statusBar->Update, 'Invalid annotation font size, please re-enter.'
  endif else state.statusBar->Update, 'Annotation font size should be greater than or equal to one, please re-enter.'
END
'ANNOTATIONPALETTE': BEGIN
  ;SPD_UI_PALETTE_EVENT, state.tlb, state.anocolorWin, color
  axissettings->GetProperty,annotatetextobject=annotatetextobject
  annotatetextobject->GetProperty,color=currentcolor
  color = PickColor(!P.Color, Group_Leader=state.tlb, Cancel=cancelled, $
    currentcolor=currentcolor)
  if cancelled then color=currentcolor
  if obj_valid(annotatetextobject) then annotatetextobject->SetProperty,color=color else begin
    annotatetextobject = obj_new('spd_ui_text')
    annotatetextobject->SetProperty,color=color
    axissettings->SetProperty,annotatetextobject=annotatetextobject
  endelse
  anocolorid = widget_info(state.tlb, find_by_uname='anocolorwin')
  Widget_Control, anocolorid, Get_Value=anocolorWin
  if obj_valid(scene) then scene->remove,/all
  scene=obj_new('IDLGRSCENE', color=reform(color))
  anocolorWin->draw, scene
  ;   state.statusBar->Update, 'Minor Grids Color selected'
  state.historywin->Update, 'Minor Grids Color selected'
  
END
;n;'ANNOTATIONSETALL': begin
;n;  ;   state.statusBar->Update, 'Set All Panels toggled'
;n;  state.historywin->Update, 'Set All Panels toggled'
;n;end
;******************************************************************************
;  End Annotation Options
;******************************************************************************


;******************************************************************************
;  Grid Panel Options
;******************************************************************************

;'OUTLINETHICK': BEGIN
;  if event.valid then begin
;    currpanelobj->GetProperty, settings = panelsettings
;    if event.value lt 1. then begin
;      state.statusbar->update, 'Frame thickness should be greater than or equal to one.'
;    endif else if event.value gt 10 then begin
;      state.statusbar->update, 'Maximum frame thickness is 10.'
;    endif else begin
;      panelsettings->SetProperty, framethick=event.value
;      ;      state.statusBar->Update, 'Outline thickness changed.'
;      state.historywin->Update, 'Outline thickness changed.'
;    endelse
;  endif else if finite(event.value,/nan) then begin
;    state.statusBar->Update, 'Invalid outline thickness, please re-enter.'
;  endif else state.statusBar->Update, 'Frame thickness must be between 1 and 10'
;END
'MAJORGRIDPALETTE': begin
  axissettings->GetProperty,majorgrid=majorgrid
  IF ~Obj_Valid(majorgrid) THEN majorgrid=Obj_New("SPD_UI_LINE_STYLE")
  majorgrid->GetProperty,color=currentcolor
  
  color = PickColor(!P.Color, Group_Leader=state.tlb, Cancel=cancelled, $
    currentcolor=currentcolor)
    
  if cancelled then color=currentcolor
  
  if obj_valid(majorgrid) then majorgrid->SetProperty,color=color else begin
    majorgrid = obj_new('SPD_UI_LINE_STYLE')
    majorgrid->SetProperty,color=color
    axissettings->SetProperty,majorgrid=majorgrid
  endelse
  majorcolorid = widget_info(state.tlb, find_by_uname='majorgridcolorwin')
  Widget_Control, majorcolorid, Get_Value=majorgridcolorWin
  if obj_valid(scene) then scene->remove,/all
  scene=obj_new('IDLGRSCENE', color=reform(color))
  majorgridcolorWin->draw, scene
  ;   state.statusBar->Update, 'Lazy Labels selected'
  state.historywin->Update, 'Lazy Labels selected'
end
'MAJORGRIDS': BEGIN
  axissettings->GetProperty, majorgrid=majorgrid
  IF ~Obj_Valid(majorgrid) THEN majorgrid=Obj_New("SPD_UI_LINE_STYLE")
  majorgrid->SetProperty, show=event.select
  if event.select then begin
    id = widget_info(state.tlb, find_by_uname = 'majorbase')
    widget_control, id, /sensitive
  endif else begin
    id = widget_info(state.tlb, find_by_uname = 'majorbase')
    widget_control, id, sensitive=0
  endelse
  ;   state.statusBar->Update, 'Major Grids toggled'
  state.historywin->Update, 'Major Grids toggled'
END
'MAJORGRIDSTYLE': BEGIN

  axissettings->GetProperty, majorgrid=majorgrid
  IF ~Obj_Valid(majorgrid) THEN majorgrid=Obj_New("SPD_UI_LINE_STYLE")
  styleNames = majorgrid->getlinestyles()
  majorgrid->SetProperty, Id=event.index, Name=styleNames[event.index]
  ;print, event.index, ' - ', styleNames[event.index]
  ;   state.statusbar->Update, 'Major grid line style updated to "'+majorgrid->GetLineStyleName(linestyleid=event.index)+'".'
  state.historyWin->Update, 'Major grid line style updated to "'+majorgrid->GetLineStyleName(linestyleid=event.index)+'".'
END
'MAJORGRIDTHICK': BEGIN
;  if event.valid then begin
;    axissettings->GetProperty, majorgrid=majorgrid
;    IF ~Obj_Valid(majorgrid) THEN majorgrid=Obj_New("SPD_UI_LINE_STYLE")
;    if event.value lt 1. then begin
;      state.statusBar->update, 'Grid thickness should be greater than or equal to 1.'
;    endif else if event.value gt 10 then begin
;      state.statusBar->update, 'Maximum grid thickness is 10.'
;    endif else begin
;      majorgrid->SetProperty, thickness=event.value
;      ;    state.statusBar->Update, 'Major grid thickness changed.'
;      state.historywin->Update, 'Major grid thickness changed.'
;    endelse
;  endif else if finite(event.value, /nan) then begin
;    state.statusBar->Update, 'Invalid major grid thickness, please re-enter.'
;  endif else state.statusBar->Update, 'Grid thickness must be between 1 and 10.'
END
'MINORGRIDPALETTE': begin
  axissettings->GetProperty,minorgrid=minorgrid
  IF ~Obj_Valid(minorgrid) THEN minorgrid=Obj_New("SPD_UI_LINE_STYLE")
  minorgrid->GetProperty,color=currentcolor
  color = PickColor(!P.Color, Group_Leader=state.tlb, Cancel=cancelled, $
    currentcolor=currentcolor)
  if cancelled then color=currentcolor
  if obj_valid(minorgrid) then minorgrid->SetProperty,color=color else begin
    minorgrid = obj_new('spd_ui_line_style')
    minorgrid->SetProperty,color=color
    axissettings->SetProperty,minorgrid=minorgrid
  endelse
  minorcolorid = widget_info(state.tlb, find_by_uname='minorgridcolorwin')
  Widget_Control, minorcolorid, Get_Value=minorgridcolorWin
  if obj_valid(scene) then scene->remove,/all
  scene=obj_new('IDLGRSCENE', color=reform(color))
  minorgridcolorWin->draw, scene
  ; state.statusBar->Update, 'Minor Grids Color selected'
  state.historywin->Update, 'Minor Grids Color selected'
end
'MINORGRIDS': BEGIN
  axissettings->GetProperty, minorgrid=minorgrid
  IF ~Obj_Valid(minorgrid) THEN minorgrid=Obj_New("SPD_UI_LINE_STYLE")
  minorgrid->SetProperty, show=event.select
  if event.select then begin
    id = widget_info(state.tlb, find_by_uname = 'minorbase')
    widget_control, id, /sensitive
  endif else begin
    id = widget_info(state.tlb, find_by_uname = 'minorbase')
    widget_control, id, sensitive=0
  endelse
  ;  state.statusBar->Update, 'Minor Grids toggled'
  state.historywin->Update, 'Minor Grids toggled'
END
'MINORGRIDSTYLE': BEGIN
  axissettings->GetProperty, minorgrid=minorgrid
  IF ~Obj_Valid(minorgrid) THEN minorgrid=Obj_New("SPD_UI_LINE_STYLE")
  styleNames = minorgrid->getlinestyles()
  minorgrid->SetProperty, Id=event.index, Name=styleNames[event.index]
  
  ;   state.statusbar->Update, 'Minor grid line style updated to "'+minorgrid->GetLineStyleName(linestyleid=event.index)+'".'
  state.historyWin->Update, 'Minor grid line style updated to "'+minorgrid->GetLineStyleName(linestyleid=event.index)+'".'
END
'MINORGRIDTHICK': BEGIN
;  if event.valid then begin
;    axissettings->GetProperty, minorgrid=minorgrid
;    IF ~Obj_Valid(minorgrid) THEN minorgrid=Obj_New("SPD_UI_LINE_STYLE")
;    if event.value lt 1. then begin
;      state.statusBar->update, 'Grid thickness should be greater than or equal to one.'
;    endif else if event.value gt 10 then begin
;      state.statusBar->update, 'Maximum grid thickness is 10.'
;    endif else begin
;      minorgrid->SetProperty, thickness=event.value
;      ;     state.statusBar->Update, 'Minor grid thickness changed.'
;      state.historywin->Update, 'Minor grid thickness changed.'
;    endelse
;  endif else if finite(event.value, /nan) then begin
;    state.statusBar->Update, 'Invalid minor grid thickness, please re-enter.'
;  endif else state.statusBar->Update, 'Grid thickness must be between 1 and 10.'
END
;n;'GRIDSETALL': begin
;n;  ;  state.statusBar->Update, 'Set All Panels toggled'
;n;  state.historywin->Update, 'Set All Panels toggled'
;n;end

;******************************************************************************
;  End Grid Panel Options
;******************************************************************************



;******************************************************************************
;  Labels Options
;******************************************************************************

'BLACKLABELS': BEGIN
  axissettings->SetProperty, BlackLabels=event.select
  id = widget_info(state.tlb, find_by_uname='labelpalette')
  if event.select eq 1 then widget_control, id, sensitive=0 $
  else widget_control, id, sensitive=1
END

'STACKLABELS': begin
  axissettings->SetProperty, stacklabels=event.select
  ;  state.statusBar->Update, 'Stack Labels toggled'
  state.historywin->Update, 'Stack Labels toggled'
end
'LAZYLABELS': begin
  axissettings->setproperty, lazylabels=event.select
  ;  state.statusBar->Update, 'Lazy Labels toggled'
  state.historywin->Update, 'Lazy Labels toggled'
end
'SHOWLABELS': BEGIN
  axissettings->SetProperty, showlabels=event.select
  id = widget_info(state.tlb, find_by_uname = 'showlabel')
  widget_control, id, sensitive=event.select
  id = widget_info(state.tlb, find_by_uname = 'labeldroplist')
  widget_control, id, sensitive=event.select
  ;  state.statusBar->Update, 'Show Labels toggled'
  state.historywin->Update, 'Show Labels toggled'
END
'SHOWLABEL': BEGIN
  axissettings->getProperty, labels=labels
  if obj_valid(labels) then begin
    currlabelobj = labels->get(position = state.labelselect)
    if obj_valid(currLabelobj) then begin
      currLabelObj->setProperty,show=event.select
    endif
  endif
  labelcolorid = widget_info(state.tlb, find_by_uname='labelcolorwin')
  spd_ui_axis_options_update_labels, state.tlb, axissettings, currlabelobj, labelcolorid
  ; state.statusBar->Update, 'Show Label toggled'
  state.historywin->Update, 'Show Label toggled'
END
'LABELDROPLIST': BEGIN
  spd_ui_axis_options_set_labels, state.tlb, state
  ;currlabelObj = *state.currlabelobj
  ;CHECK THIS. MAY NOT FUNCTION AS INTENDED
  currlabelObj = spd_ui_axis_options_getcurrentlabel(state)
  if event.index eq -1 then begin
    currlabelobj->SetProperty, value=event.str
  endif else begin
    state.labelselect = event.index
    currlabelObj = spd_ui_axis_options_getcurrentlabel(state)
  endelse
  
  labelcolorid = widget_info(state.tlb, find_by_uname='labelcolorwin')
  spd_ui_axis_options_update_labels, state.tlb, axissettings, currlabelobj, labelcolorid
  ;  state.statusBar->Update, 'Label selected'
  state.historywin->Update, 'Label selected'
END
'LABELTEXTEDIT': BEGIN
  widget_control, event.id, get_value = value
  
  ; this handles case where label is an empty string
  if stregex(value[0], '^ *$', /boolean) then begin
    show = 0
  ; shouldn't be necessary anymore as labels have number prefixed:
  ;placeholder = ''
  ;for i=0, state.labelselect do placeholder += ' ' ;equal entries not distinguished on linux
  ;value[0] = placeholder   ;combobox cannot take empty string
  endif else begin
    show = 1
  endelse
  
  name = spd_ui_axis_options_create_label_name(state.labelselect,value[0])
  
  id = widget_info(state.tlb, find_by_uname='labeldroplist')
  widget_control, id, get_value = labels
  
  ;labels[state.labelselect] = value[0]
  labels[state.labelselect] = name
  
  widget_control, id, set_value = labels
  widget_control, id, set_combobox_select=state.labelselect
  
  ;reset to empty string before altering label object
  if show eq 0 then value[0] = '' ; probably not necessary anymore
  axissettings->getProperty, labels=labels
  if obj_valid(labels) then begin
    currlabelobj=labels->get(position = state.labelselect)
    IF ~Obj_Valid(currlabelobj) THEN currlabelobj=Obj_New("SPD_UI_TEXT", Value=' ')
  endif else currlabelobj = obj_new("SPD_UI_TEXT", Value=' ')
  currLabelObj->setProperty, show=show, value=value[0]
  
  id = widget_info(state.tlb, find_by_uname='showlabel')
  widget_control, id, set_button=show
  ;  state.statusBar->Update, 'Label Text edited'
  state.historywin->Update, 'Label Text edited'
END
'ADDLABEL': BEGIN
  axissettings->GetProperty, labels=labelsObj
  if obj_valid(labelsObj) then begin
    labelsObj->add,obj_new('spd_ui_text',value='New Text Label',font=0,format=3, $
      size=10,color=[0,0,0])
  endif else begin
    labelsObj = obj_new('IDL_Container')
    labelsObj->add,obj_new('spd_ui_text',value='New Text Label',font=0,format=3, $
      size=10,color=[0,0,0])
  endelse
  axissettings->SetProperty, labels=labelsObj
  state.labelselect = labelsObj->Count() - 1
  currlabelobj = labelsObj->get(position = state.labelselect)
  ;if ptr_valid(state.currlabelobj) then ptr_free, state.currlabelobj
  ;state.currlabelObj = ptr_new(currlabelobj)
  
  spd_ui_init_axis_window , state = state
  ;   state.statusBar->Update, 'Label Text added'
  state.historywin->Update, 'Label Text added'
END
'LABELFONT': begin
  ;  state.statusBar->Update, 'Label Font selected'
  state.historywin->Update, 'Label Font selected'
end;Replaced by spd_ui_axis_options_set_labels
'LABELFORMAT': begin
  ;   state.statusBar->Update, 'Label Font Format selected'
  state.historywin->Update, 'Label Font Format selected'
end;Replaced by spd_ui_axis_options_set_labels
'LABELSIZE': BEGIN;Replaced by spd_ui_axis_options_set_labels
  if event.valid then begin
    ;axissettings->GetProperty, annotatetextobject = annotatetextobject
    if event.value lt 1. then begin
      state.statusbar->update, 'Font size should be greater than or equal to one.'
    endif
  endif else if finite(event.value, /nan) then begin
    state.statusBar->Update, 'Invalid label font size, please re-enter.'
  endif else state.statusBar->Update, 'Label font size should be greater than or equal to one, please re-enter.'
END
'LABELPALETTE': BEGIN
  axissettings->getProperty, labels=labels
  if obj_valid(labels) then begin
    currlabelobj=labels->get(position = state.labelselect)
    IF obj_Valid(currlabelobj) THEN currlabelobj->GetProperty,color=currentcolor $
    ELSE currentcolor=[0,0,0]
  endif else currentcolor=[0,0,0]
  color = PickColor(!P.Color, Group_Leader=state.tlb, Cancel=cancelled, $
    currentcolor=currentcolor)
  if cancelled then color=currentcolor
  
  ; update the label object with the user's selection
  if obj_valid(currlabelobj) then currlabelobj->setProperty, color=color
  
  labelcolorid = widget_info(state.tlb, find_by_uname='labelcolorwin')
  Widget_Control, labelcolorid, Get_Value=labelcolorWin
  labelcolorwin->getproperty, graphics_tree=scene
  if obj_valid(scene) then begin
    scene->remove,/all
    scene->setproperty, color=reform(color)
  endif else begin
    scene=obj_new('IDLGRSCENE', color=reform(color))
    labelcolorwin->setproperty, graphics_tree=scene
  endelse
  labelcolorWin->draw, scene
  ; state.statusBar->Update, 'Label Font Color selected'
  state.historywin->Update, 'Label Font Color selected'
END
'LABELHORIZONTAL': BEGIN
  axissettings->SetProperty, orientation=~event.select
  ;  state.statusBar->Update, 'Horizontal Label Orientation selected'
  state.historywin->Update, 'Horizontal Label Orientation selected'
END
'LABELVERTICAL': BEGIN
  axissettings->SetProperty, orientation=event.select
  ;  state.statusBar->Update, 'Vertical Label Orientation selected'
  state.historywin->Update, 'Vertical Label Orientation selected'
END
'PLACELABEL':BEGIN
axissettings->SetProperty, placelabel=event.index
state.historyWin->Update, 'Label placement updated to "'+event.str+'".'
END
'LABELMARGIN': BEGIN
  if event.valid then begin    
    axissettings->getProperty, margin=oldvalue
    mvalue = double(event.value)
    if (mvalue gt 10000) or  (mvalue lt -10000)  then begin
       state.historywin->Update, 'Invalid label margin, please re-enter.'
    endif else begin
      axissettings->SetProperty, margin=mvalue
      state.historywin->Update, 'Label margin changed.'
    endelse
  endif else state.statusBar->Update, 'Invalid label margin, please re-enter.'
END
;n;'LABELTSETALL': begin
;n;  ;  state.statusBar->Update, 'Set All Panels toggled'
;n;  state.historywin->Update, 'Set All Panels toggled'
;n;end;Replaced by spd_ui_axis_options_set_labels
'LABELSYNC': BEGIN
  ;set current settings before propagating
  spd_ui_axis_options_set_labels, state.tlb, state
  
  axissettings->GetProperty,labels=labels
  
  if obj_valid(labels[0]) then begin
    labelobjects = labels->get(/all)
    labelobjects[state.labelselect]->GetProperty, font=font, format=format, size=size, show=show
    for i=0, n_elements(labelobjects)-1 do begin
      if i eq state.labelselect then continue
      labelobjects[i]->SetProperty, font=font, format=format, size=size, show=show
    endfor
    ;   state.statusBar->update, 'Labels synchronized on panel.'; +strtrim(state.labelselect+1,2)+'.' -this is the label number, not the panel number
    state.historywin->update, 'Labels synchronized on panel.'
  endif else begin
    state.statusBar->update, 'No valid labels to sync on current panel.'; ('+strtrim(state.labelselect+1,2)+').'
  endelse
END
'FORMATHELPBUTTON': BEGIN ;; user clicked axis label format help
    gethelppath,path
    xdisplayfile,path+'spd_ui_format_axis_labels.txt' , group=state.tlb, /modal, done_button='Done', title='HELP: Formatting Axis Labels'
END
;******************************************************************************
;  End Labels Options
;******************************************************************************


;******************************************************************************
;  Range Options
;******************************************************************************

'AUTORANGE': begin

  ;Update AXISSETTINGS:
  ;********************
  ;

  ;Sensitize Range Options:
  ;************************
  ;
  id = widget_info(state.tlb, find_by_uname = 'aobase')
  widget_control, id, sensitive = 1
  ;check if bound scaling is checked
  boundid = widget_info(state.tlb, find_by_uname = 'boundscaling')
  bound = widget_info(boundid, /button_set)
  id = widget_info(state.tlb, find_by_uname='boundbase')
  widget_control,id,sensitive=bound
  ;Desensitize Floating Center and Fixed Min/Max:
  ;**********************************************
  ;
  ;      id = widget_info(state.tlb, find_by_uname = 'fltobase')
  ;      widget_control, id, sensitive = 0
  id = widget_info(state.tlb, find_by_uname = 'fobase')
  widget_control, id, sensitive = 0
  ;    state.statusBar->Update, 'Auto Range selected'
  state.historywin->Update, 'Auto Range selected'
  
end
;    'FLOATRANGE': begin
;
;      ;Desensitize Range Options:
;      ;**************************
;      ;
;      id = widget_info(state.tlb, find_by_uname = 'aobase')
;      widget_control, id, sensitive = 0
;
;      ;Sensitize Floating Center:
;      ;**************************
;      ;
;      id = widget_info(state.tlb, find_by_uname = 'fltobase')
;      widget_control, id, sensitive = 1
;
;      spd_ui_axis_options_update_flt, state.tlb, axissettings, state
;
;      id = widget_info(state.tlb, find_by_uname = 'fobase')
;      widget_control, id, sensitive = 0
;     ; state.statusBar->Update, 'Floating Center selected'
;      state.historywin->Update, 'Floating Center selected'
;
;    end
'FIXEDRANGE': begin

  ;Desensitize Range Options:
  ;**************************
  ;
  id = widget_info(state.tlb, find_by_uname = 'aobase')
  widget_control, id, sensitive = 0
  
  ;      id = widget_info(state.tlb, find_by_uname = 'fltobase')
  ;      widget_control, id, sensitive = 0
  
  id = widget_info(state.tlb, find_by_uname = 'fobase')
  widget_control, id, sensitive = 1
  ;set spinner min if log scaling is selected
  axissettings->getproperty,scaling=scaling, istimeaxis=istimeaxis
  linid = widget_info(state.tlb,find_by_uname='linear')
  if widget_info(linid,/button_set) then linscale = 1 else linscale = 0
  if ~istimeaxis then begin
    if linscale eq 0 then minvalue = 0 else minvalue = !values.d_nan
    spd_ui_spinner_set_min_value, widget_info(state.tlb, find_by_uname = 'minincrement'), minvalue
    spd_ui_spinner_set_min_value, widget_info(state.tlb, find_by_uname = 'maxincrement'),minvalue
  endif
  ;   state.statusBar->Update, 'Fixed Min/Max selected'
  state.historywin->Update, 'Fixed Min/Max selected'
end
'BOUNDSCALING': begin
  ;       ID1 = widget_info(event.top, find_by_uname='minboundrange')
  ;       ID2 = widget_info(event.top, find_by_uname='maxboundrange')
  ;       widget_control,ID1,sensitive=event.select
  ;       widget_control,ID2,sensitive=event.select

  id = widget_info(event.top, find_by_uname='boundbase')
  widget_control,id,sensitive=event.select
  ;    state.statusBar->Update, 'Bound Autoscaling toggled'
  state.historywin->Update, 'Bound Autoscaling toggled'
end
'ISTIME': BEGIN

  ;make sure axis settings settings are updated
  spd_ui_axis_options_setvalues, state.tlb, state,/nopopups
  
  ;Get state of istime button and store in AXISSETTINGS:
  ;*****************************************************
  ;
  
  istime = Widget_Info(event.id, /Button_Set)
  ;  IF ~Obj_Valid(axissettings) THEN axissettings = Obj_New("SPD_UI_AXIS_SETTINGS")
  
  axisSettings->getProperty,$
    istimeaxis=istimeold,$
    annotateUnits=annotateUnits,$
    firstAnnotateUnits=firstAnnotateUnits,$
    majorTickUnits=majorTickUnits,$
    minorTickUnits=minorTickUnits,$
    firstTickUnits=firstTickUnits,$
    annotateEvery=annotateEvery,$
    firstAnnotation=firstAnnotation,$
    majorTickEvery=majorTickEvery,$
    minorTickEvery=minorTickEvery,$
    firsttickAt=firstTickAt
    
  ;default units to hours when axis is time
  ;not entirely necessary, but this prevents users from accidentally creating
  ;plots with thousands of ticks or annotations
  if istime eq 1 && istimeold eq 0 then begin
    ;        axissettings->setProperty, annotateUnits = 2
    ;        axissettings->setProperty, majorTickUnits = 2
    ;        axissettings->setProperty, minortickUnits = 2
  
  
  
    annotateEvery = spd_ui_axis_options_convert_units(annotateEvery,annotateUnits,/fromseconds)
    firstAnnotation = spd_ui_axis_options_convert_units(firstAnnotation,firstAnnotateUnits,/fromseconds)
    majorTickEvery = spd_ui_axis_options_convert_units(majorTickEvery,majorTickUnits,/fromseconds)
    minorTickEvery = spd_ui_axis_options_convert_units(minorTickEvery,minorTickUnits,/fromseconds)
    firstTickAt = spd_ui_axis_options_convert_units(firstTickAt,firstTickUnits,/fromseconds)
    
    
  endif else begin
  
    annotateEvery = spd_ui_axis_options_convert_units(annotateEvery,annotateUnits)
    firstAnnotation = spd_ui_axis_options_convert_units(firstAnnotation,firstAnnotateUnits)
    majorTickEvery = spd_ui_axis_options_convert_units(majorTickEvery,majorTickUnits)
    minorTickEvery = spd_ui_axis_options_convert_units(minorTickEvery,minorTickUnits)
    firstTickAt = spd_ui_axis_options_convert_units(firstTickAt,firstTickUnits)
    
  endelse
  
  axissettings->SetProperty,$
    istimeaxis=istime,$
    annotateEvery=annotateEvery,$
    firstAnnotation=firstAnnotation,$
    majorTickEvery=majorTickEvery,$
    minorTickEvery=minorTickEvery,$
    firsttickAt=firstTickAt
    
  spd_ui_init_axis_window,event.top,state=state
  
  END
  
  'LINEAR': spd_ui_axis_options_update_scaling, state, axissettings, /linear
  
  'LOG10': spd_ui_axis_options_update_scaling, state, axissettings, /log10
  
  'NATURALLOG': spd_ui_axis_options_update_scaling, state, axissettings, /natural_log
  
  ;    'FLOATINGCENTER': begin
  ;      axissettings->SetProperty, floatingcenter = event.index
  ;  ;    state.statusbar->Update, 'Floating Center updated to "'+axissettings->GetFloatingCenter(event.index)+'".'
  ;      state.historyWin->Update, 'Floating Center updated to "'+axissettings->GetFloatingCenter(event.index)+'".'
  ;    end
  
  'EQUALXYSCALING': begin
    axissettings->SetProperty, equalxyscaling = widget_info(event.id, /button_set)
    ;    state.statusBar->Update, 'Equal X Y Axis Scaling toggled'
    state.historywin->Update, 'Eual X Y Axis Scaling toggled'
  end
  ;******************************************************************************
  ;  End Range Options
  ;******************************************************************************
  
  
  ;******************************************************************************
  ;  Tick Options
  ;******************************************************************************

  
  'MAJORTICKUNITS': BEGIN
  
    ;update numerical tick interval as needed
    ;(currently only time axes allow multiple units, units for non-time
    ; axes are determined by the scaling --aaflores 2013-2-7)
    axissettings->getProperty, majortickunits=majorunits, istimeaxis=istime
    if istime then begin
      id = widget_info(state.tlb,find_by_uname='majortickevery')
      widget_control,id,get_value=majorTickEvery
      majorTickEvery = spd_ui_axis_options_convert_units(majorTickEvery,majorUnits)
      majorTickEvery = spd_ui_axis_options_convert_units(majorTickEvery,event.index,/fromSeconds)
      widget_control,id,set_value=majorTickEvery
    endif
    
    ;apply new settings
    axissettings->setProperty, majortickunits=event.index
    
    ;     state.statusbar->Update, 'Major tick units updated to "'+axissettings->GetUnit(event.index)+'".'
    state.historyWin->Update, 'Major tick units updated to "'+axissettings->GetUnit(event.index)+'".'
  END
  
  'BYNUMBER': begin
    bid = widget_info(state.tlb, find_by_uname='byinterval')
    id = widget_info(state.tlb, find_by_uname='intervalbase')
    widget_control, bid, set_button=0
    widget_control, id, sens=0
    
    id = widget_info(state.tlb, find_by_uname='numberbase')
    widget_control, id, sens=1
    id = widget_info(state.tlb, find_by_uname='niceticks')
    minortickbase = widget_info(state.tlb, find_by_uname='minortickbase')
    If widget_info(id, /button_set) then widget_control, minorTickBase, sens=0 else widget_control, minorTickBase, sens=1
    ;    state.statusBar->Update, 'Major Ticks by Number selected'
    state.historywin->Update, 'Major Ticks by Number selected'
  end
  
  'NICETICKS': begin
    id = widget_info(state.tlb, find_by_uname='niceticks')
    minortickbase = widget_info(state.tlb, find_by_uname='minortickbase')
    If widget_info(id, /button_set) then widget_control, minorTickBase, sens=0 else widget_control, minorTickBase, sens=1
    
    majortickbase = widget_info(state.tlb, find_by_uname='majortickbase')
    If widget_info(id, /button_set) then widget_control, majorTickBase, sens=0 else widget_control, majorTickBase, sens=1
    ;    state.statusBar->Update, 'Aesthetic Ticks toggled'
    state.historywin->Update, 'Aesthetic Ticks toggled'
  end
  
  'BYINTERVAL': begin
    bid = widget_info(state.tlb, find_by_uname='bynumber')
    id = widget_info(state.tlb, find_by_uname='numberbase')
    widget_control, bid, set_button=0
    widget_control, id, sens=0
    
    id = widget_info(state.tlb, find_by_uname='intervalbase')
    widget_control, id, sens=1
    minortickbase = widget_info(state.tlb, find_by_uname='minortickbase')
    widget_control,minorTickBase,sensitive=1
    ;     state.statusBar->Update, 'Major Ticks by Interval selected'
    state.historywin->Update, 'Major Ticks by Interval selected'
  end
  
  ;******************************************************************************
  ;  End Tick Options
  ;******************************************************************************
  
  ;******************************************************************************
  ; Title Options
  ;******************************************************************************

  'TITLEPALETTE': BEGIN
    axissettings->getProperty, titleobj=titleobj
    if obj_valid(titleobj) then titleobj->GetProperty,color=currentcolor else currentcolor = [0,0,0]
    color = PickColor(!P.Color, Group_Leader=state.tlb, Cancel=cancelled, $
      currentcolor=currentcolor)
    if cancelled then color=currentcolor
    if obj_valid(titleobj) then titleobj->SetProperty,color=color else begin
      ; don't think this should be necessary
      titleobj = obj_new('spd_ui_text')
      titleobj->SetProperty,color=color
      axissettings->SetProperty,titleobj=titleobj
    endelse
    titlecolorid = widget_info(state.tlb, find_by_uname='titlecolorwin')
    Widget_Control, titlecolorid, Get_Value=titlecolorWin
    if obj_valid(scene) then scene->remove,/all
    scene=obj_new('IDLGRSCENE', color=reform(color))
    titlecolorWin->draw, scene
    state.historywin->Update, 'Title Color selected'
  END
  'SUBTITLEPALETTE': BEGIN
    axissettings->getProperty, subtitleobj=subtitleobj
    if obj_valid(subtitleobj) then subtitleobj->GetProperty,color=currentcolor else currentcolor = [0,0,0]
    color = PickColor(!P.Color, Group_Leader=state.tlb, Cancel=cancelled, $
      currentcolor=currentcolor)
    if cancelled then color=currentcolor
    if obj_valid(subtitleobj) then subtitleobj->SetProperty,color=color else begin
      ; don't think this should be necessary
      subtitleobj = obj_new('spd_ui_text')
      subtitleobj->SetProperty,color=color
      axissettings->SetProperty,subtitleobj=subtitleobj
    endelse
    subtitlecolorid = widget_info(state.tlb, find_by_uname='subtitlecolorwin')
    Widget_Control, subtitlecolorid, Get_Value=subtitlecolorWin
    if obj_valid(scene) then scene->remove,/all
    scene=obj_new('IDLGRSCENE', color=reform(color))
    subtitlecolorWin->draw, scene
    state.historywin->Update, 'Subtitle Color selected'
  END
  'LAZYTITLES': begin
    axissettings->setproperty, lazytitles=event.select
    ;  state.statusBar->Update, 'Lazy Labels toggled'
    state.historywin->Update, 'Lazy Titles toggled'
  end
  'TITLEHORIZONTAL': BEGIN
    axissettings->SetProperty, titleorientation=~event.select
    state.historywin->Update, 'Horizontal Title Orientation selected'
  END
  'TITLEVERTICAL': BEGIN
    axissettings->SetProperty, titleorientation=event.select
    state.historywin->Update, 'Vertical Title Orientation selected'
  END
  'PLACETITLE':BEGIN
  axissettings->SetProperty, placetitle=event.index
  state.historyWin->Update, 'Title placement updated to "'+event.str+'".'
  END
  ;n;'TITLESETALL': begin
  ;n;  state.historywin->Update, 'Set All Panels toggled'
  ;n;END
  'TITLEMARGIN': BEGIN
    if event.valid then begin
      ;axissettings->SetProperty, titlemargin=event.value
      state.historywin->Update, 'Title margin changed.'
    endif else state.statusBar->Update, 'Invalid title margin, please re-enter.'
  END
  'TITLEFONT': begin
    state.historywin->Update, 'Title Font selected'
  end;Handle later in spd_ui_axis_options_set_title
  'TITLEFORMAT': begin
    state.historywin->Update, 'Title Font Format selected'
  end;Handle later in spd_ui_axis_options_set_title
  'SUBTITLEFONT': begin
    state.historywin->Update, 'Subtitle Font selected'
  end;Handle later in spd_ui_axis_options_set_title
  'SUBTITLEFORMAT': begin
    state.historywin->Update, 'Subtitle Font Format selected'
  end;Handle later in spd_ui_axis_options_set_title
  'TITLESIZE': BEGIN;Handle later in spd_ui_axis_options_set_title
    if ~event.valid then begin
      if finite(event.value,/nan) then begin
        state.statusBar->Update, 'Invalid font size, please re-enter.'
      endif else begin
        state.statusBar->Update, 'Minimum font size is 1.'
      endelse
    endif
    state.historywin->Update, 'Title Font Size changed'
  END
  'SUBTITLESIZE': BEGIN;Handle later in spd_ui_axis_options_set_title
    if ~event.valid then begin
      if finite(event.value,/nan) then begin
        state.statusBar->Update, 'Invalid font size, please re-enter.'
      endif else begin
        state.statusBar->Update, 'Minimum font size is 1.'
      endelse
    endif
    state.historywin->Update, 'Subtitle Font Size changed'
  END
  'TITLETEXTEDIT': begin
    state.historywin->Update, 'Title updated'
  end
  'SUBTITLETEXTEDIT':begin
  state.historywin->Update, 'Subtitle updated'
  end
  ;******************************************************************************
  ;  End Title Options
  ;******************************************************************************
  
  ;(lphilpott, July 2011) TPALETTE event does not appear to be defined or necessary so I am
  ; commenting it out.
  ;    'TPALETTE': BEGIN
  ;
  ;      SPD_UI_PALETTE_EVENT, state.tlb, state.tcolorWin, color
  ;      state.axisSettings->GetProperty, Labels=labels
  ;      ; **********   NEED TO FIGURE OUT WHICH LABEL THIS IS ******
  ;      ; **********   Should know by index  ************
  ;      labelObj->SetProperty, Color=color
  ;    END
  
  
  ELSE:
  ENDCASE
  ENDIF
  
  Widget_Control, event.TOP, Set_UValue=state, /No_Copy
  
  RETURN  
END ;--------------------------------------------------------------------------------



PRO spd_ui_axis_options, gui_id, windowStorage, loadedData, drawObject, historyWin, $
    windowTitle, axisselect, scrollbar, template,$
    panel_select=panel_select, tlb_statusbar
    
  compile_opt idl2
  
  err_x=0
  catch, err_x
  if err_x ne 0 then begin
    catch, /cancel
    help, /Last_Message, Output=err_msg
    for j = 0, N_Elements(err_msg)-1 do historywin->update,err_msg[j]
    ok = error_message('An unknown error occured starting Axis Options.', /noname, $
      /center, title='Error in Axis Options')
    widget_control, tlb, /destroy
    spd_gui_error, gui_id, historywin
    return
  endif
  
  tlb_statusBar->update,'Axis Options opened'
  
  ;top level and main bases
  
  tlb = Widget_Base(/Col, Title=windowTitle, Group_Leader=gui_id, /Modal, /Floating,/tlb_kill_request_events, tab_mode=1)
  tabBase = Widget_Tab(tlb, Location=location, uname = 'tabs')
  buttonBase = Widget_Base(tlb, /Row, /align_center)
  statusBase = Widget_Base(tlb, /Row, /align_center)
  rangeBase = Widget_Base(tabBase, Title='Range', /Col)
  ticksBase = Widget_Base(tabBase, Title='Ticks', /Col)
  gridBase = Widget_Base(tabBase, Title='Grid', /Col)
  annotationBase = Widget_Base(tabBase, Title='Annotations', /Col)
  titleBase = widget_base(tabBase,Title='Title',/col)
  labelsBase  = Widget_Base(tabBase, Title='Labels', /Col)
  
  ;range bases
  
  panelBase = Widget_Base(rangeBase, /Row)
  rangeBase = Widget_Base(rangeBase, /Row)
  range1Base = Widget_Base(rangeBase, /Col)
  rlabelBase = Widget_Base(range1Base, /Col)
  roptionsBase = Widget_Base(range1Base, /Col, Frame=3)
  slabelBase = Widget_Base(range1Base, /Col)
  soptionsBase = Widget_Base(range1Base, /Col, Frame=3)
  flabelBase = Widget_Base(range1Base, /Col)
  foptionsBase = Widget_Base(range1Base, /Col, Frame=3, uname='fobase')
  timeXYBase = Widget_Base(range1Base, /Col, /NonExclusive, YPad=2)
  lockMSGbase = widget_base(range1Base, /row, ypad=1)
  range2Base = Widget_Base(rangeBase, /Col)
  alabelBase = Widget_Base(range2Base, /Col, uname='alabelbase')
  aoptionsBase = Widget_Base(range2Base, /Col, Frame=3, YPad=6, uname='aobase')
  ;    fclabelBase = Widget_Base(range2Base, /Col)
  ;    fcoptionsBase = Widget_Base(range2Base, /Col, Frame=3, YPad=6, uname='fltobase')
  ;n;setAllBase = Widget_Base(range2Base, /Col, /Align_Center, YPad=15, /nonexclusive)
  ;setAllBase = Widget_Base(range2Base, /Col, /Align_Center, YPad=6)
  
  ;ticks bases
  
  tpanelBase = Widget_Base(ticksBase, ypad=15, /Row)
  ticksMainBase = Widget_Base(ticksBase, /Col)
  ticksTopBase = Widget_Base(ticksMainBase, /row, ypad=5, /align_left)
  ticksMiddleBase = widget_base(ticksMainBase, /col, ypad=1)
  ticksBottomBase = Widget_Base(ticksMainBase, /Row,/align_left)
  plcmntBase = Widget_Base(ticksBottomBase, /Col, /Align_Left, ypad=5);,xpad=3)
  lengthBase = Widget_Base(ticksBottomBase, /Col, /Align_Left, xpad=3, ypad=5)
  ticksButtonBase = Widget_Base(ticksMainBase, /Row, /Align_Center, YPad=10, /nonexclusive)
  
  ;grid panel bases
  
  gpBase = Widget_Base(gridBase, /Col)
  grid1Base = Widget_Base(gridBase, /Col, XPad=4)
  majorBase = Widget_Base(grid1Base, /Col, YPad=1, xpad=20)
  mgLabelBase = Widget_Base(majorBase, /Row)
  majFrameBase = Widget_Base(majorBase, /Col, Frame=3, XPad=15, YPad=1, /align_center, uname='majorbase')
  mdLabelBase = Widget_Base(majFrameBase, /Row)
  dirPullBase =  Widget_Base(majFrameBase, /Col, YPad=1)
  minorBase = Widget_Base(grid1Base, /Col, YPad=1, XPad=20)
  mgiLabelBase = Widget_Base(minorBase, /Row, YPad=1)
  minFrameBase = Widget_Base(minorBase, /Col, Frame=3, YPad=1, XPad=15, /align_center, uname='minorbase')
  mdiLabelBase = Widget_Base(minFrameBase, /Row)
  diriPullBase =  Widget_Base(minFrameBase, /Col, YPad=1)
  gcBase = Widget_Base(grid1Base, /Col)
  gaBase = Widget_Base(gridBase, /Col, /Align_Center, YPad=1, /nonexclusive)
  
  ;annotation bases
  
  anoPanelBase = Widget_Base(annotationBase, /Row)
  anoMainBase = Widget_Base(annotationBase, /Col)
  anoTopBase = Widget_Base(anoMainBase, /row, space=0, ypad=0)
  anoTopCol1Base = Widget_Base(anoTopBase, space=0, ypad=0, /Col)
  anoTopCol2Base = Widget_Base(anoTopBase, space=0, ypad=0, /Col)
  anoMiddleBase = Widget_Base(anoMainBase, /Col, ypad=0, space=0)
  anoButtonBase = Widget_Base(anoMainBase, /Row, /Align_Center, /nonexclusive)
  
  ; title bases
  titlePanelBase = Widget_Base(titleBase, /Row)
  titleMainBase = Widget_Base(titleBase, /Col)
  titleTextBase = Widget_Base(titleMainBase, /Col, YPad=1, space=10)
  titleButtonBase = Widget_Base(titleMainBase, /Row, /Align_Center, /nonexclusive)
  
  ;labels bases
  
  lpanelBase = Widget_Base(labelsBase, /col, YPad=3)
  ;stackBase = Widget_Base(labelsBase, /nonexclusive, /row)
  labelMainBase = Widget_Base(labelsBase, /Col)
  labelTextBase = Widget_Base(labelMainBase, /Col, YPad=1)
  ;  labelPositionBase = Widget_Base(labelMainBase, /Col)
  stackBase = Widget_Base(labelMainBase, /nonexclusive, /row)
  labelButtonBase = Widget_Base(labelMainBase, /Row, /Align_Center, YPad=3, /nonexclusive)
  
  ;axis settings were passed in
  ;save here in case reset must be called
  ;infoaxissettings->save
  
  ;retrieve data and panel info for display
  
  activeWindow = windowStorage->GetActive()
  IF ~Obj_Valid(activeWindow) THEN BEGIN
    panelNames=['No Panels']
    windowlocked = -1
  ENDIF ELSE BEGIN
    activeWindow->GetProperty, Panels=panels,locked=windowlocked
    IF ~Obj_Valid(panels) THEN BEGIN
      panelNames=['No Panels']
    ENDIF ELSE BEGIN
      panelObjs = panels->Get(/all)
      IF Is_Num(panelObjs) THEN BEGIN
        panelNames=['No Panels']
      ENDIF ELSE BEGIN
        FOR i=0, N_Elements(panelObjs)-1 DO BEGIN
          activeWindow->getproperty, locked = locked
          lockPrefix = i eq locked ? '(L)  ':''
          name = lockPrefix + panelObjs[i]->constructPanelName()
          IF i EQ 0 THEN panelNames=[name] ELSE panelNames=[panelNames, name]
        ENDFOR
      ENDELSE
    ENDELSE
    IF Is_Num(panelNames) THEN panelNames=['No Panels']
    IF N_Elements(panelNames) EQ 1 && panelNames EQ '' THEN panelNames=['No Panels']
  ENDELSE
  
  activeWindow->save
  
  ;Save all existing panels in current window:
  ;*******************************************
  ;
  ;if ~(~size(panelobjs,/type)) && obj_valid(panelobjs[0]) then begin
  ;  for i=0,n_elements(panelobjs)-1 do panelobjs[i]->save
  ;endif
  
  ;If 0th PANELOBJ is valid, then assume the AXISPANELSELECT-th PANELOBJ is valid and get AXISSETTINGS for correct axis:
  ;*********************************************************************************************************************
  ;
  axispanelselect = 0 
  
  if obj_valid(panelobjs[0]) then begin
  
    if n_elements(panel_select) gt 0 && panel_select ge 0 && panel_select lt n_elements(panelObjs) then begin
      axispanelselect = panel_select
    endif else begin
      if windowlocked ne -1 then begin
;        axispanelselect = windowlocked
        ;if panels are locked default to the bottom panel
        axispanelselect = n_elements(panelObjs)-1
      endif
    endelse
    
    case axisselect of
      0: panelobjs[axispanelselect]->GetProperty,xaxis=axissettings
      1: panelobjs[axispanelselect]->GetProperty,yaxis=axissettings
    ;2: panelobjs[axispanelselect]->GetProperty,zaxis=axissettings ;axis options window couldn't possibly work with z axis
    endcase
    IF ~Obj_Valid(axissettings) THEN axissettings = obj_new('spd_ui_axis_settings')
  endif else axissettings = obj_new('spd_ui_axis_settings')
  
  axisSettings->GetProperty,       $
    Scaling=scaleIndex,             $
    RangeOption=rangeIndex,         $
    IsTimeAxis=isTimeAxis,          $
    EqualXYScaling=equalXYScaling,  $
    MinFixedRange=minFixedRange,    $
    MaxFixedRange=maxFixedRange,    $
    RangeMargin=rangeMargin,        $
    BoundScaling=boundScaling,      $
    MinBoundRange=minBoundRange,    $
    MaxBoundRange=maxBoundRange,    $
    ;  FloatingSpan=floatingSpan,      $
    ;  FloatingCenter=floatingCenter,  $
    MajorTickEvery=majorTickEvery,  $
    MajorTickUnits=majorTickUnits,  $
    MajorTickAuto=majorTickAuto,    $
    MinorTickEvery=minorTickEvery,  $
    MinorTickUnits=minorTickUnits,  $
    MinorTickAuto=minorTickAuto,    $
    NumMajorTicks=numMajorTicks,    $
    NumMinorTicks=numMinorTicks,    $
    FirstTickAt=firstTickAt,        $
    FirstTickUnits=firstickUnits,   $
    ;  FirstTickAuto=firstTickAuto,    $
    AnnotateExponent=AnnotateExponent
    
    
  ;Kludge to make sure that RANGEMARGIN is at 5% if it got initialized to 0 for some reason:
  ;*****************************************************************************************
  ;
  ;if rangemargin eq 0 and ~istimeaxis then begin
  ;  rangemargin = 0.05d
  ;  axissettings->SetProperty, rangemargin=rangemargin
  ;endif
    
  ;range widgets 
  rpdlabel = Widget_label(panelbase, value = 'Panel: ', /align_center)
  rangepanelDroplist = Widget_combobox(panelBase, Value=panelNames, uval='PANELDROPLIST', uname='rangepaneldroplist')

  ; warn user if xaxis selected and panels are locked.
  IF axisselect EQ 0 && ~undefined(locked) && locked NE -1 THEN BEGIN
    anolab = widget_label(panelBase, value ='  *Panels locked. Use apply all to change other panels.')
  ENDIF

  roptionsLabel = Widget_Label(rlabelBase, Value='Range Options:', /Align_Left)
  rbuttonsBase = Widget_Base(roptionsBase, /Col, /Exclusive)
  ;IF isTimeAxis EQ 1 THEN sensitive=0 ELSE sensitive=1
  sensitive = ~istimeaxis
  
  autoRangeButton = Widget_Button(rbuttonsBase, Value='Auto Range', Sensitive=sensitive, UValue='AUTORANGE',uname='autorange')
  ;floatingRangeButton = Widget_Button(rbuttonsBase, Value='Floating Center', Sensitive=sensitive, UValue='FLOATRANGE', uname ='floatrange')
  fixedRangeButton = Widget_Button(rbuttonsBase, Value='Fixed Range', Sensitive=sensitive, UValue='FIXEDRANGE',uname='fixedrange')
  
  rangeOptions = [autoRangeButton, fixedRangeButton]
  
  soptionsLabel = Widget_Label(slabelBase, Value='Scaling:', /Align_Left)
  sbuttonsBase = Widget_Base(soptionsBase, /Col, /Exclusive)
  scalingOptions = Make_Array(3, /long)
  scalingOptions[0] = Widget_Button(sbuttonsBase, Value='Linear', Sensitive=sensitive, uval = 'LINEAR', uname='linear')
  scalingOptions[1] = Widget_Button(sbuttonsBase, Value='Log 10', Sensitive=sensitive, uval = 'LOG10',uname='log10')
  scalingOptions[2] = Widget_Button(sbuttonsBase, Value='Natural Log', Sensitive=sensitive, uval = 'NATURALLOG',uname='logn')
  WIDGET_CONTROL, scalingOptions[scaleIndex], /Set_Button
  ;equalXYButton = Widget_Button(timeXYBase, Value='Equal X & Y Axis Scaling', uval = 'EQUALXYSCALING', uname='equalxyscaling')
  ;IF equalXYScaling EQ 1 THEN Widget_Control, equalXYButton, /Set_Button
  ;widget_control,equalxybutton,sensitive=0
  isTimeButton = Widget_Button(timeXYBase, Value='Time Axis', UValue='ISTIME',uname='istime', tooltip='If checked, SPEDAS will generate date and time based annotations for this axis.')
  lockMSG = widget_label(lockmsgbase, value='', uvalue = 'lockmsg')
  IF isTimeAxis EQ 1 THEN Widget_Control, isTimeButton, /Set_Button
  IF rangeIndex EQ 2 THEN sensitive=1 ELSE sensitive=0
  foptionsLabel = Widget_Label(flabelBase, Value='Fixed Range:', /Align_Left)
  minBase = Widget_Base(foptionsBase, /Row, /align_right, uname='minbase')
  maxBase = Widget_Base(foptionsBase, /Row, /align_right, uname='maxbase')
  minIncLabel=widget_label(minbase, Value='Min: ')
  maxIncLabel=widget_label(maxbase, Value='Max: ')
  
  if istimeaxis then begin
    ;  minFixedRangeTime = formatDate(minFixedRange, '%date/%time', 0)
    minIncrement=widget_text(minBase, Sensitive=sensitive, /editable, uval='MINFIXEDRANGE', uname='minincrement',/all_events)
    
    ;  maxFixedRangeTime = formatDate(maxFixedRange, '%date/%time', 0)
    maxIncrement=widget_text(maxBase, Sensitive=sensitive, /editable, uval='MAXFIXEDRANGE', uname='maxincrement',/all_events)
  endif else begin
    minIncrement=spd_ui_spinner(minBase, Increment=1, Sensitive=sensitive, Value=minFixedRange, text_box_size=12, $
      uval='MINFIXEDRANGE', uname='minincrement')
    maxIncrement=spd_ui_spinner(maxBase, Increment=1, Sensitive=sensitive, Value=maxFixedRange, text_box_size=12, $
      uval='MAXFIXEDRANGE', uname='maxincrement')
  endelse
  
  aoptionsLabel = Widget_Label(alabelBase, Value='Auto Range:', /Align_Left)
  rmBase = Widget_Base(aoptionsBase, /Row)
  IF rangeIndex EQ 0 THEN sensitive=1 ELSE sensitive=0
  ;rmIncrement=spd_ui_spinner(rmBase, Increment=0.1, Label='Range Margin (%): ', Sensitive=sensitive, Value=100*rangeMargin, uval = 'RANGEMARGIN', $
  ;  uname='rmincrement')
  rmLabel=Widget_Label(rmBase, value='Range Margin (%): ', /align_left, uname='rmlabel')
  rmIncrement=spd_ui_spinner(rmBase,increment=1, Value=200*rangeMargin, uval = 'RANGEMARGIN', $
    uname='rmincrement', min_value = 0)
  autoBase = Widget_Base(aoptionsBase, /NonExclusive);, Sensitive=sensitive)
  autoButton = Widget_Button(autoBase, value = ' Bound autoscaling range', $
      tooltip='Automatically scales the range within user defined boundaries', uname='boundscaling', uval='BOUNDSCALING')
  IF boundScaling THEN BEGIN
    Widget_Control, autoButton, /Set_Button
    sensitive=1
  ENDIF else sensitive = 0
  ;Widget_Control, rmLabel, sensitive=sensitive
  boundbase = widget_base(aoptionsBase,uname='boundbase',/col)
  minaBase = Widget_Base(boundbase, /Row)
  minaLabel=Widget_Label(minaBase, value='Minimum: ', /align_left,  uname='minlabel')
  minaIncrement=spd_ui_spinner(minaBase, Increment=1, Value=minBoundRange, $
    text_box_size=12, uval = 'MINBOUNDRANGE', uname='minboundrange')
  maxaBase = Widget_Base(boundbase, /Row)
  maxaLabel=Widget_Label(maxaBase, value='Maximum: ', /align_left, uname='maxlabel')
  mmaxaIncrement=spd_ui_spinner(maxaBase, Increment=1, Value=maxBoundRange, $
    text_box_size=12, uval = 'MAXBOUNDRANGE', uname='maxboundrange')
  minmaxLabel = Widget_Label(boundbase, Value='(Not applied if min/max are equal)')
  
  ;spaceLabel = Widget_Label(fclabelBase, Value='    ', /Align_Left)
  ;fcoptionsLabel = Widget_Label(fclabelBase, Value='Floating Center:', /Align_Left)
  ;IF rangeIndex EQ 1 THEN sensitive=1 ELSE sensitive=0
  ;
  ;spanBase = Widget_Base(fcoptionsBase, /Row)
  ;fslabel=widget_label(spanbase, value = 'Span: ', xsize=76, uname = 'fslabel')
  ;floatingspan=spd_ui_spinner(spanBase, Increment=1, Value=floatingspan, uval='FLOATINGSPAN', $
  ;  uname='floatingspan', tooltip='If logarithmic Max/Min = 10^[log(center) +- span]', $
  ;  text_box_size=12, min_value=0)
  ;cspaceBase = Widget_Base(fcoptionsBase, /Row, YPad=2)
  ;centerOptions = axisSettings->GetFloatingCenters()
  ;
  ;flclabel = widget_label(cspacebase, value = 'Center: ', xsize=76)
  ;floatingcenterid = Widget_combobox(cspaceBase, Value=centeroptions, uval='FLOATINGCENTER', $
  ;  uname='floatingcenter')
  ;Widget_Control, floatingcenterid, Set_combobox_Select=floatingCenter
  
  ;spaceLabel = Widget_Label(setAllBase, Value='  ')
  ;spaceLabel = Widget_Label(setAllBase, Value='  ')
  ;n;setAllButton = Widget_Button(setAllBase, Value='Set All Panels', /Align_Center, XSize = 120, uval='RANGESETALL', uname='rangesetall')
  
  ;n;if windowlocked && axisselect eq 0 then begin
  ;n;  widget_control,setAllButton,/set_button
  ;n;endif
  
  ;TICKS WIDGETS
  ;------------
  
  tpanellabel = widget_label(tpanelbase, value = 'Panel: ', /align_left)
  tpanelDroplist = Widget_combobox(tpanelBase, Value=panelNames, $
    uval='PANELDROPLIST', uname='tickpaneldroplist')
  ; warn user if xaxis selected and panels are locked.
  IF axisselect EQ 0 && ~undefined(locked) && locked NE -1 THEN BEGIN
    anolab = widget_label(tpanelBase, value ='  *Panels locked. Use apply all to change other panels.')
  ENDIF
  
  tickUnitValues = axisSettings->GetUnits()
  tickStyleValues = axisSettings->GetStyles()
  
  ;Main Bases for Type of ticks
  bynumberBase = widget_base(ticksTopBase, /col, uname='bynumberbase')
  byintervalBase = widget_base(ticksTopBase, /col, uname='byintervalbase')
  
  
  ;'By Interval' Widgets
  
  iLabelBase = widget_base(byintervalBase, /row, /exclusive)
  byinterval = widget_button(ilabelbase, value='Major Ticks By Interval', uvalue='BYINTERVAL', $
    uname='byinterval')
    
  intervalbase = widget_base(byintervalBase, /col, /base_align_left, uname='intervalbase', $
    frame=1, space=6, ypad=6, xpad=4)
    
  tickEvery = spd_ui_spinner(intervalBase, label='Major Tick Every:   ', getXLabelSize=xlsize, $
    text_box_size=12, uname='majortickevery', incr=1, $
    tooltip='Inverval in Units between major tick marks', min_value=0)
  geo_tmp = widget_info(tickevery,/geo)
  
  tickUnitsBase = widget_base(intervalBase, /row, xpad=0, ypad=0, space=1)
  unitslabel = widget_label(tickUnitsBase, value='Units', xsize=xlsize)
  unitslist = widget_combobox(tickUnitsBase, value=tickUnitValues, uval='MAJORTICKUNITS', $
    uname='majortickunits', xsize=geo_tmp.scr_xsize - xlsize - 2)
    
  firsttickBase = widget_base(intervalBase, /row, xpad=0, space=0,uname='firsttickatbase')
  firstticklabel = widget_label(firsttickBase, value='Align ticks at: ', xsize=xlsize+3)
  if istimeaxis then begin
    firsttick = widget_text(firsttickBase, value=time_string(firsttickat), uname='firsttickat',/editable)
  endif else begin
    firsttick = spd_ui_spinner(firsttickBase, value=firsttickat, incr=1, uname='firsttickat', $
      tooltip='Numerical location of first tick.', text_box=12)
  endelse
  
  
  ;'By Number' Widgets
  
  numLabelBase = widgeT_base(bynumberBase, /Col, /exclusive)
  bynumber = widget_button(numlabelBase, value='Major Ticks By Number', uvalue='BYNUMBER', $
    uname='bynumber')
    
  numberbase = widget_base(bynumberBase, /col, /base_align_left, uname='numberbase', $
    frame=1, space=6, ypad=6, xpad=4)
  niceticksbase = widget_base(numberbase, /row, /nonexclusive, uname='niceticksbase')
  niceticks = widget_button(niceticksbase, value='Automatic Ticks', uvalue='NICETICKS', uname='niceticks', $
    tooltip='Places ticks at easily read values.')
  majorTickBase = widget_base(numberBase,uname='majortickbase',sens=0)
  MajorTicknum = spd_ui_spinner(majorTickBase, value=nummajorticks, getXlabelSize=xlsize, $
    uname='nummajorticks', uvalue='NUMMAJORTICKS', label='Major Ticks (hint):  ', incr=1, min_value=0, max_value=100,tooltip='Number of ticks may be approximate.')
  

    
  ;resize bynumberbase
  widget_control, numberbase, scr_ysize=( widget_info(intervalbase, /geo) ).scr_ysize
  
  
  ;initializations
  widget_control, unitslist, Set_combobox_Select=majorTickUnits
  
  widget_control, bynumber, set_button=1
  widget_control, numberbase, sens=1
  
  widget_control, byinterval, set_button=0
  widget_control, intervalbase, sens=0
    
  minorTickBase = widget_base(ticksMiddleBase, /row, sens=0, uname='minortickbase')
  MinorTicknum = spd_ui_spinner(minorTickBase, value=numminorticks, getXlabelSize=xlsize, $
    uname='numminorticks', label='# of Minor Ticks:  ', incr=1, min_value=0, max_value=100)
    
  minorLogTickTypeBase = widget_base(ticksMiddleBase,/col,/frame,/base_align_center)
  minorLogTickTypeLabelBase = widget_base(minorLogTickTypeBase,/base_align_center,/row)
  minorLogTickTypeLabel = widget_label(minorLogTickTypeLabelBase,value="Log Minor Tick Type:", /align_center)
  minorLogTickTypeButtonBase = widget_base(minorLogTickTypeBase,/exclusive,/row,uname='logminorticktypebase')
  minorLogTickType0 = widget_button(minorLogTickTypeButtonBase,value='Full Interval', $
     uname='logminorticktype0', tooltip='Minor ticks linearly divide each major tick interval.')
  minorLogTickType1 = widget_button(minorLogTickTypeButtonBase,value='First Magnitude', $
     tooltip='For major tick spacing > 1 order of magnitude, minor ticks linearly divide first order of magnitude in each major tick interval.',uname='logminorticktype1')
  minorLogTickType2 = widget_button(minorLogTickTypeButtonBase,value='Last Magnitude',$
     tooltip='For major tick spacing > 1 order of magnitude, minor ticks linearly divide last order of magnitude in each major tick interval.',uname='logminorticktype2')
  minorLogTickType3 = widget_button(minorLogTickTypeButtonBase,value='Even Spacing',$
     tooltip='Minor ticks logarithmically divide each major tickinterval.',uname='logminorticktype3')

  tickstyleBase = Widget_Base(ticksMiddleBase, /row, ypad=3)
  tslabel = widget_label(tickstylebase, value = 'Draw Ticks: ', xsize=xlsize+1)
  tickStyleDroplist = Widget_combobox(tickstyleBase, Value=tickStyleValues, uval='TICKSTYLE',uname='tickstyle')
  
  placementLabel = Widget_Label(plcmntBase, Value = 'Placement', /Align_Left)
  placeFrameBase = Widget_Base(plcmntBase, /Col, /NonExclusive, Frame=3, YPad=11, XPad=10,uname='placeframebase')
  
  case axisselect of
    0:BEGIN
    botbutval = 'Bottom              '
    topbutval = 'Top                 '
  END
  1:BEGIN
  botbutval = 'Left                '
  topbutval = 'Right               '
END
endcase
bottomButton = Widget_Button(placeFrameBase, Value=botbutval, uval='BOTTOMPLACE', $
  uname='bottomplace')
topButton = Widget_Button(placeFrameBase, Value=topbutval, uval='TOPPLACE', $
  uname='topplace')
WIDGET_CONTROL, bottomButton, /Set_Button
WIDGET_CONTROL, topButton, /Set_Button
lengthLabel = Widget_Label(lengthBase, Value = 'Length', /Align_Left)
lengthFrameBase = Widget_Base(lengthBase, /Col, Frame=3, uname='lengthframebase')
lmajorBase = Widget_Base(lengthFrameBase, /Row, YPad=3)
lmajorIncrement = spd_ui_spinner(lmajorBase, label = 'Major : ',Increment=1, uval='MAJORLENGTH', $
  uname='majorlength', min_value = 0, max_value = 10000)
lmajorLabel= Widget_Label(lmajorBase, Value=' pts')
lminorBase = Widget_Base(lengthFrameBase, /Row, YPad=3)
lminorIncrement = spd_ui_spinner(lminorBase, label = 'Minor : ',Increment=1, uval='MINORLENGTH', $
  uname='minorlength', min_value = 0, max_value = 10000)
lminorLabel = Widget_Label(lminorBase, Value=' pts')

;n;tsetAllButton = Widget_Button(ticksButtonBase, Value='Set All Panels', /Align_Center, XSize = 120, uval='TICKSSETALL', uname='tickssetall')

;n;if windowlocked ne -1 && axisselect eq 0 then begin
;n;  widget_control,tsetallbutton,/set_button
;n;endif

;GRID WIDGETS
;------------

gppanelbase = widget_base(gpbase, /row)
gplabel = widget_label(gppanelbase, value='Panel: ')
gpDroplist = Widget_combobox(gppanelBase, Value=panelNames, uval='PANELDROPLIST', uname='gridpaneldroplist')
; warn user if xaxis selected and panels are locked.
IF axisselect EQ 0 && ~undefined(locked) && locked NE -1 THEN BEGIN
  anolab = widget_label(gppanelBase, value ='  *Panels locked. Use apply all to change other panels.')
ENDIF

;outlineBase = Widget_Base(gpBase, /Row)
;outlineIncrement = spd_ui_spinner(outlineBase, Label= 'Panel Outline Thickness : ', Increment=1, Value=1,  uval='OUTLINETHICK', uname='outlinethick', min_value=1, max_value=10)
gmajorLabel = Widget_Label(mglabelBase, Value='Major Grids: ', /Align_left, uname='majorgridbtnlabel')
gmajorbuttonbase = Widget_Base(mglabelBase, /NonExclusive)
gmajorbutton = Widget_Button(gmajorbuttonbase, value=' ', uval='MAJORGRIDS', uname='majorgrids')
currentBase =  Widget_Base(dirPullBase, /Row, XPad=1)
paletteBase = Widget_Base(dirPullBase, /Row, XPad=1)
colorLabel = Widget_Label(paletteBase, Value='Color: ', /align_left, uname='majorcolorlabel')

getresourcepath,rpath
palettebmp = read_bmp(rpath + 'color.bmp', /rgb)
spd_ui_match_background, tlb, palettebmp

majorgridpaletteButton = Widget_Button(paletteBase, Value=palettebmp, /Bitmap, $
  UValue='MAJORGRIDPALETTE', uname='majorgridpalette', $
  Tooltip='Choose color from Palette')
spaceLabel = Widget_Label(paletteBase, Value=' ')
;majorgridcolorWindow = Widget_Draw(paletteBase, XSize=50, YSize=21, uname='majorgridcolorwindow')
majorgridcolorWindow = WIDGET_DRAW(paletteBase,graphics_level=2,renderer=1, $
  retain=1, XSize=50, YSize=20, units=0, frame=1, /expose_events, uname='majorgridcolorwin')
cmajorBase = Widget_Base(dirpullBase, /Row)
cmajorlabel=widget_label(cmajorBase, value='Thickness: ', /align_left, uname='majorgridlabel')
cmajorIncrement = spd_ui_spinner(cmajorBase, Increment=1, Value=1,xsize=120, $
  uval='MAJORGRIDTHICK', uname='majorgridthick', min_value=1, max_value=10)
smajorbase = widget_base(dirpullbase, /row)
smajorlabel = widget_label(smajorbase, value='Style: ', /align_left, uname='majorstylelabel')
lineObj=Obj_New("SPD_UI_LINE_STYLE")
lineStyles=lineObj->GetLineStyles()
Obj_Destroy, lineObj
smajorDroplist = Widget_combobox(smajorbase, $
  uval='MAJORGRIDSTYLE', uname='majorgridstyle', $
  Value=lineStyles)
gimajorLabel = Widget_Label(mgilabelBase, Value = 'Minor Grids: ', /Align_Left, uname='minorgridbtnlabel')
gminorbuttonbase = Widget_Base(mgilabelBase, /NonExclusive)
gminorbutton = Widget_Button(gminorbuttonbase, value=' ', uval='MINORGRIDS', uname='minorgrids')
cminorBase =  Widget_Base(diripullBase, /Row, XPad=1)
;cminorLabel = Widget_Label(cminorBase, Value='                                  Current Color:')
paletteiBase = Widget_Base(diripullBase, /Row, XPad=1)
coloriLabel = Widget_Label(paletteiBase, Value='Color: ' ,/align_left, uname='minorclabolorel')
minorgridpaletteButton = Widget_Button(paletteiBase, Value=palettebmp, /Bitmap, $
  UValue='MINORGRIDPALETTE', uname='minorgridpalette', $
  Tooltip='Choose color from Palette')
spaceLabel = Widget_Label(paletteiBase, Value=' ')
;minorgridcolorWindow = WIDGET_DRAW(paletteiBase, XSize=50, YSize=21, uname='minorgridcolorwindow')
minorgridcolorWindow = WIDGET_DRAW(paletteiBase,graphics_level=2,renderer=1, $
  retain=1, XSize=50, YSize=20, units=0, frame=1, /expose_events, uname='minorgridcolorwin')
cminorBase = Widget_Base(diripullBase, /Row)
cmajorlabel=widget_label(cminorBase, value='Thickness: ', /align_left, uname='minorgridlabel')
cminorIncrement = spd_ui_spinner(cminorBase,Increment=1, Value=1, $
  uval='MINORGRIDTHICK', uname='minorgridthick',min_value=1, max_value=10)
sminorbase = widget_base(diripullbase, /row)
sminorlabel=widget_label(sminorBase, value='Style: ', /align_left, uname='minorstylelabel')
sminorDroplist = Widget_combobox(sminorbase, $
  uval='MINORGRIDSTYLE', uname='minorgridstyle', $
  Value=lineStyles)
;spaceLabel = Widget_Label(gaBase, Value='            ')  ;annoying IDL problem
;n;setAllgButton = Widget_Button(gaBase, Value='Set All Panels', /Align_Center, XSize=125, uval='GRIDSETALL', uname='gridsetall')
  
;n;if windowlocked ne -1 && axisselect eq 0 then begin
;n;  widget_control,setAllgButton,/set_button
;n;endif
  
;annotation widgets   
anoPlabel = widget_label(anopanelbase, value = 'Panel: ')
anoPanelDroplist = Widget_combobox(anopanelBase, Value=panelNames, uval='PANELDROPLIST', uname='annopaneldroplist')
; if panels are locked default to the bottom panel
; warn user if xaxis selected and panels are locked.
IF axisselect EQ 0 && ~undefined(locked) && locked NE -1 THEN BEGIN
  anolab = widget_label(anopanelBase, value ='  *Panels locked. Use apply all to change other panels.')
ENDIF

IF isTimeAxis EQ 1 THEN sensitive=1 ELSE sensitive=0

anoDrawBase = Widget_Base(anoTopCol1Base, /col, /NonExclusive)
anoDrawButton = Widget_Button(anoDrawBase, Value='Draw Line at Zero (1 for log)', uval='LINEATZERO', $
  uname='lineatzero')
;anoShowButton = Widget_Button(anoShowDateBase, Value='Show Date', Sensitive=sensitive, $
;anoShowBase = Widget_Base(anoTopCol1Base, /row, /nonexclusive)
;anoftBase = Widget_Base(anoTopCol1Base, /col, /NonExclusive)
anoftButton =  Widget_Button(anoDrawBase, Value='Annotate Range Min', uval='ANNOTATERANGEMIN', $
  uname='annotaterangemin')
WIDGET_CONTROL, anoftButton, /Set_Button
;ano2ftBase = Widget_Base(anoftBase, /Row, /NonExclusive)
ano2ftButton =  Widget_Button(anoDrawBase, Value='Annotate Range Max', uval='ANNOTATERANGEMAX', $
  uname='annotaterangemax')
WIDGET_CONTROL, ano2ftButton, /Set_Button
;anoShowButton = Widget_Button(anoDrawBase, Value='Show Date', Sensitive=sensitive, $
;  uval='SHOWDATE', uname='showdate')
;WIDGET_CONTROL, anoShowButton, /Set_Button

anoShowDateBase = Widget_Base(anoMiddleBase, /Row, /NonExclusive)
anoShowButton = Widget_Button(anoShowDateBase, Value='Show Date:', Sensitive=sensitive, $
  uval='SHOWDATE', uname='showdate', tooltip='Include Date string with first tick')
WIDGET_CONTROL, anoShowButton, /Set_Button
anoDateBase = Widget_Base(anoMiddleBase, /Row, frame=1, uname='anodatebase')
anoDateTextBases = Widget_Base(anoDateBase, /col)
anoDateFormat1Base = Widget_Base(anoDateTextBases, /row)
anoDateFormat2Base = Widget_Base(anoDateTextBases, /row)
anoDatePreviewTextBase = Widget_Base(anoDateBase, /col)

anoDateFormat1Label = Widget_Label(anoDateFormat1Base, Value='Line 1: ')
anoDateFormat1 = Widget_Text(anoDateFormat1Base, /editable, uval='ANODATE1', uname='anodate1', /All_Events)
anoDateFormat2Label = Widget_Label(anoDateFormat2Base, Value='Line 2: ')
anoDateFormat2 = Widget_Text(anoDateFormat2Base, /editable, uval='ANODATE2', uname='anodate2', /All_Events)

anoDatePreviewText = Widget_Text(anoDatePreviewTextBase, ysize=2, /wrap, uname='anodatepreviewtext')
anoDatePreviewButt = Widget_Button(anoDatePreviewTextBase, value='Preview of Date String', uval='ANODATEPREVIEW')

;anoDateButton = Widget_Button(anoTopCol2Base, Value='Date Format...', Sensitive=sensitive)
anoSpaceBase = Widget_Base(anoMiddleBase, /Row)
anoSpaceLabel = Widget_Label(anoSpaceBase, value = '    ')
anoAxisBase = Widget_Base(anoMiddleBase, /Row, /NonExclusive)
anoAxisButton = Widget_Button(anoAxisBase, Value='Annotate Along Axis:', uval='ANNOTATEAXIS', $
  uname='annotateaxis')
WIDGET_CONTROL, anoAxisButton, /Set_Button

anoFrameBase = Widget_Base(anoMiddleBase, /Col, Frame=5, XPad=5, uname='annoaxisbase')
anofpBase = Widget_Base(anoFrameBase, /row)
;annoplacement = axissettings->GetPlacements()
case axisselect of
  0: annoplacement = ['Bottom','Top']
  1: annoplacement = ['Left','Right']
endcase

anoMajorBase = Widget_Base(anofpBase, /Row, /NonExclusive)
anoMajorButton = Widget_Button(anoMajorBase, Value='Annotate Major Ticks', uval='ANNOTATEMAJORTICKS', $
  uname='annotatemajorticks')
anoplabel = widget_label(anofpbase, value='Place Annotation on: ', /align_left)
anoPlaceDroplist = Widget_combobox(anofpBase, Value=annoplacement, uval='PLACEANNOTATION', uname='placeannotation')

WIDGET_CONTROL, anoMajorButton, /Set_Button
anomFrameBase = Widget_Base(anoFrameBase, /Col, XPad=4, uname='annomajorbase')
anoEveryBase = Widget_Base(anomFrameBase, /Row)
anoEveryLabel = Widget_Label(anoEveryBase, Value='Annotate Every: ', /align_left)
anoEveryText = spd_ui_spinner(anoEveryBase, Value=majortickevery, increment=1,$
  text_box_size=12, uval='ANNOTATEEVERY', uname='annotateevery',min_value=0)
spaceLabel = Widget_Label(anoEveryBase, Value = '    ')
IF isTimeAxis EQ 1 THEN Sensitive=1 ELSE Sensitive=0
anoEveryDroplist = Widget_combobox(anoEveryBase, Value=tickUnitValues, uval='ANNOTATEUNITS', uname='annotateunits')
anoFirstBase = Widget_Base(anomFrameBase, /Row,uname='firstannotationbase')
anoFirstLabel = Widget_Label(anoFirstBase, Value='Align Annotations At: ' ,/align_left)
if istimeaxis then begin
  anoFirstText = widget_text(anoFirstBase, value=time_string(0), uname='firstannotation',/editable,uval='FIRSTANNOTATION')
endif else begin
  anoFirstText = spd_ui_spinner(anoFirstBase, value=0, incr=1, uname='firstannotation', $
    tooltip='Numerical location of first annotation.', text_box=12,uval='FIRSTANNOTATION')
endelse

anoBase = Widget_Base(anoFrameBase, /row)
styleValues = axisSettings->GetAnnotationFormats()
anoSBase = widget_base(anoTopCol2Base, /row, space = 0)
avalue = istimeaxis ? 'Annotation Format:  ':'Annotation Precision:  '
anoSLabel = widget_label(anosbase, value = avalue, uname='anoslabel')
anoStyleDroplist = Widget_combobox(anosbase, Value = styleValues, uval='ANNOTATESTYLE', uname='annotatestyle')

anoSOBase = widget_base(anoTopCol2Base, column=1, /exclusive, ypad=0, space=0)
default = widget_button(anoSOBase, value = 'Auto-Notation', uvalue='AAUTO', uname='aauto', sensitive=~istimeaxis)
dbl = widget_button(anoSOBase, value = 'Decimal Notation', uvalue='ADBL', uname='adbl', sensitive=~istimeaxis)
expo = widget_button(anoSOBase, value = 'Scientific Notation', uvalue='AEXP', uname = 'aexp', sensitive=~istimeaxis)
hexno = widget_button(anoSOBase, value = 'Hexadecimal Notation', uvalue='HEXNOT', uname = 'hexnot', sensitive=~istimeaxis)

; We need hexno twice because type=4 (type=3 has been used before but it is not currently used)
atype = [default, dbl, expo, hexno, hexno]
widget_control, atype[annotateExponent], /set_button

;ano2Base = Widget_Base(anoFrameBase, /row)
;spaceLabel = Widget_Label(anoFrameBase, Value = '')
orientBase = Widget_Base(anoFrameBase, /row)
orientationLabel = Widget_Label(orientBase, Value=' Orientation: ', /Align_Left,sensitive=1)
orientButtonBase = Widget_Base(orientBase, /Exclusive, /row)
landscapeButton = Widget_Button(orientButtonBase, Value='Horizontal      ', UValue='ANNOHORIZONTAL', $
  uname='annohorizontal');, sensitive=1)
landscapeButton = Widget_Button(orientButtonBase, Value='Vertical   ', UValue='ANNOVERTICAL', $
  uname='annovertical');, sensitive=1)
;n;anoSetAllButton = Widget_Button(anoButtonBase, Value='Set All Panels', /Align_Center, XSize = 125, uval='ANNOTATIONSETALL', uname='annotationsetall')
;spaceLabel = Widget_Label(anoFrameBase, Value = '')
;
;
;
;n;if windowlocked ne -1 && axisselect eq 0 then begin
;n;widget_control,anoSetAllButton,/set_button
;n;endif
  
;styleLabel = Widget_Label(anoFrameBase, Value=' Style:', /Align_Left, sensitive=1)
anoStyleBase = Widget_Base(anoFrameBase, /row)
anoFontBase = Widget_Base(anoStyleBase, /col)
textObj = Obj_New("SPD_UI_TEXT")
fontNames = textObj->GetFonts()
anoFontLabel = Widget_Label(anoFontBase, value='Font', /align_left)
anoStyleDroplist = Widget_combobox(anoFontbase, value=fontNames, uval='ANOFONTLIST', uname='anofontlist')
anoIncBase = Widget_Base(anoStyleBase, /col)
anoIncLabel = Widget_Label(anoIncBase, value='Size (pts)', /align_left)
fontTitleIncrement = spd_ui_spinner(anoIncBase, Increment=1, uval='ANOFONTSIZE', $
  uname='anofontsize', min_value=1)
anoColorBase = Widget_Base(anoStyleBase, /col)
colorLabel = Widget_Label(anoColorbase, value='Color', /align_center)
;getresourcepath,rpath
;palettebmp = rpath + 'color.bmp'
annotationpaletteButton = Widget_Button(anoColorBase, Value=palettebmp, /Bitmap, $
  UVal='ANNOTATIONPALETTE', uname='annotationpalette', $
  Tooltip='Choose color from Palette')
anoCurrentBase = Widget_Base(anoStyleBase, /col)
anoCurrentLabel = Widget_Label(anocurrentbase, value='Current Color')
anoColorWindow = WIDGET_DRAW(anoCurrentBase, graphics_level=2, renderer=1, retain=1, XSize=50, $
  YSize=20, units=0, frame=1, /expose_events, uname='anocolorwin')
  
;-----------------------------------------------------------------------------------------------------------------------------
; title widgets
  
titlepdBase = widget_base(titlepanelbase, /row)
titlePLabel=Widget_Label(titlepdBase, value='Panel: ')


titlepanelDroplist = Widget_combobox(titlepdBase, Value=panelNames, uval='PANELDROPLIST', uname='titlepaneldroplist')
; warn user if xaxis selected and panels are locked.
IF axisselect EQ 0 && ~undefined(locked) && locked NE -1 THEN BEGIN
  anolab = widget_label(titlepdBase, value ='  *Panels locked. Use apply all to change other panels.')
ENDIF

titletextcolbase = widget_base(titletextBase, col=2, space=350)
titletextframeLabel = Widget_Label(titletextcolbase, Value='Text: ', /Align_Left)
titlehelpbutton = widget_button(titletextcolbase, value='Format Help', uname='formathelpbutton', uvalue='FORMATHELPBUTTON')
titletextFrameBase = Widget_Base(titletextBase, /col, Frame=3,XPad=1, uname='titletextframebase')
titlecolBase = widget_base(titletextframebase,/col)
titleeditBase = widget_base(titlecolbase,/row, ypad=1,/base_align_center)
titleeditbasecol1 = widget_base(titleeditBase, /col, /base_align_left);, space=20, ypad=6)
titleeditbasecol2 = widget_base(titleeditbase, /col, /base_align_left);, space=12)
titletextlabel = widget_label(titleeditbasecol1, value='Title:', /align_left)
titletextfield = widget_text(titleeditBasecol2, value = '', /editable, /all_events, xsize=50, ysize=1, $
  uval='TITLETEXTEDIT', uname='titletextedit')

titlerow1base = widget_base(titlecolbase,/row, xpad=40,/base_align_center);, ypad=10)
titlelabel1base = widget_base(titlerow1base,/col,/base_align_left, space=20, ypad=6);, xpad=30)
titlefield1base = widget_base(titlerow1base,/col,/base_align_left, space=12)
titlelabel2base = widget_base(titlerow1base,/col,/base_align_left, space=20, ypad=6)
titlefield2base = widget_base(titlerow1base,/col,/base_align_left, space=6)
tlabel = Widget_Label(titlelabel1Base, value = 'Font:')
lpofontDroplist = Widget_combobox(titlefield1Base, Value=fontnames, uval='TITLEFONT', uname='titlefont')
tlabel = Widget_Label(titlelabel1Base, value = 'Format:')
formattypes=textObj->getformats()
titleFormatDroplist = Widget_combobox(titlefield1Base, Value=formattypes, uval='TITLEFORMAT', uname='titleformat')

tlabel= Widget_Label(titlelabel2Base, value='Size (points): ', /align_left)
fontIncrement = spd_ui_spinner(titlefield2Base, Increment=1,  Value=12, uval='TITLESIZE', uname='titlesize', min_value=1)


tlabel= Widget_Label(titlelabel2Base, value='Color: ', /align_left)
titlecolorBase = Widget_Base(titlefield2Base, /row, xpad=0, /base_align_center)
titlepaletteButton = Widget_Button(titlecolorBase, Value=palettebmp, /Bitmap, UValue='TITLEPALETTE', uname='titlepalette', $
  Tooltip='Choose color from Palette')
titleColorWindow = WIDGET_DRAW(titlecolorBase, graphics_level=2, renderer=1, retain=1, XSize=50, YSize=20, units=0, frame=1, $
  uname = 'titlecolorwin', /expose_events)
;-------- subtitle
subtitleeditBase = widget_base(titlecolbase,/row, ypad=1,/base_align_center)
subtitleeditbasecol1 = widget_base(subtitleeditBase, /col, /base_align_left);, space=20, ypad=6)
subtitleeditbasecol2 = widget_base(subtitleeditbase, /col, /base_align_left);, space=12)
subtitletextlabel = widget_label(subtitleeditbasecol1, value='Subtitle:',/align_left)
subtitletextfield = widget_text(subtitleeditbasecol2, value='',/editable, /all_events, xsize=50, ysize=1,$
  uval='SUBTITLETEXTEDIT',uname='subtitletextedit')
  
subtitlerow1base = widget_base(titlecolbase,/row, xpad=40,/base_align_center);, ypad=10)
subtitlelabel1base = widget_base(subtitlerow1base,/col,/base_align_left, space=20, ypad=6);, xpad=30)
subtitlefield1base = widget_base(subtitlerow1base,/col,/base_align_left, space=12)
subtitlelabel2base = widget_base(subtitlerow1base,/col,/base_align_left, space=20, ypad=6)
subtitlefield2base = widget_base(subtitlerow1base,/col,/base_align_left, space=6)
subtlabel = Widget_Label(subtitlelabel1Base, value = 'Font:')
sublpofontDroplist = Widget_combobox(subtitlefield1Base, Value=fontnames, uval='SUBTITLEFONT', uname='subtitlefont')
subtlabel = Widget_Label(subtitlelabel1Base, value = 'Format:')
formattypes=textObj->getformats()
subtitleFormatDroplist = Widget_combobox(subtitlefield1Base, Value=formattypes, uval='SUBTITLEFORMAT', uname='subtitleformat')

subtlabel= Widget_Label(subtitlelabel2Base, value='Size (points): ', /align_left)
subfontIncrement = spd_ui_spinner(subtitlefield2Base, Increment=1,  Value=12, uval='SUBTITLESIZE', uname='subtitlesize', min_value=1)


subtlabel= Widget_Label(subtitlelabel2Base, value='Color: ', /align_left)
subtitlecolorBase = Widget_Base(subtitlefield2Base, /row, xpad=0, /base_align_center)
subtitlepaletteButton = Widget_Button(subtitlecolorBase, Value=palettebmp, /Bitmap, UValue='SUBTITLEPALETTE', uname='subtitlepalette', $
  Tooltip='Choose color from Palette')
subtitleColorWindow = WIDGET_DRAW(subtitlecolorBase, graphics_level=2, renderer=1, retain=1, XSize=50, YSize=20, units=0, frame=1, $
  uname = 'subtitlecolorwin', /expose_events)
  
  
;------ placement
titleplacementframeLabel = Widget_Label(titletextBase, Value='Style & Placement: ', /Align_Left)
titleplacementFrameBase = Widget_Base(titletextBase, /col, Frame=3,XPad=1, uname='titleplacementframebase')

case axisselect of
  0: titleplacement = ['Bottom','Top   ']
  1: titleplacement = ['Left  ','Right ']
endcase
titleplacebase0 = widget_base(titleplacementframebase,/row, /base_align_center)
titlelazybase = widget_base(titleplaceBase0, /row, /nonexclusive,/align_left)
titlelazyButton = widget_button(titlelazybase, value='Lazy Titles', uval='LAZYTITLES', $
  uname='lazytitles', tooltip='Underscores will be converted to new lines')
titleplaceBase = widget_base(titleplacementframebase,/row,/base_align_center)
titlepBase = Widget_Base(titleplaceBase, /row)
titleplacelabel = widget_label(titlepbase, value='Place Title on:   ')
titlePlaceDroplist = Widget_combobox(titlepBase, Value=titleplacement, uval='PLACETITLE', uname='placetitle')


titlemarginBase = Widget_Base(titleplacebase, /Row, xpad=20)
titlemarginIncrement=spd_ui_spinner(titlemarginBase, label = 'Margin:   ',Increment=1, uval='TITLEMARGIN', uname='titlemargin')
titlemarginLabel = Widget_Label(titlemarginBase, Value=' pts ')

titleplace2Base = widget_base(titleplacementframebase,/row)
titlep2Base = Widget_Base(titleplace2Base, /row)
titleplacelabel = widget_label(titlep2base, value='Orientation:   ')
titleButBase = Widget_Base(titlep2Base , /row, /Exclusive,xpad=12,space=50)
titleHorizButton = Widget_Button(titleButBase, Value='Horizontal', uval='TITLEHORIZONTAL', uname='titlehorizontal')
titleVertButton = Widget_Button(titleButBase, Value='Vertical', uval='TITLEVERTICAL', uname='titlevertical')
Widget_Control, titleVertButton, /Set_Button ;correct button will be set in spd_ui_init_axis_window

;n;titleSetAllButton = Widget_Button(titleButtonBase, Value='Set All Panels', /Align_Center, XSize = 125, uval='TITLESETALL', uname='titlesetall')

;-----------------------------------------------------------------------------------------------------------------------------
;labels widgets

lpdBase = widget_base(lpanelbase, /row)
panelLabel=Widget_Label(lpdBase, value='Panel: ')

lpanelDroplist = Widget_combobox(lpdBase, Value=panelNames, uval='PANELDROPLIST', uname='labelpaneldroplist')
; warn user if xaxis selected and panels are locked.
IF axisselect EQ 0 && ~undefined(locked) && locked NE -1 THEN BEGIN
  anolab = widget_label(lpdBase, value ='  *Panels locked. Use apply all to change other panels.')
ENDIF

ltextLabel = Widget_Label(labeltextBase, Value='Text: ', /Align_Left)
ltFrameBase = Widget_Base(labeltextBase, /col, Frame=3,XPad=1, uname='ltframebase')
lt1TextBase = Widget_Base(ltFrameBase, /row, xpad=3)
col1Base = Widget_Base(lt1TextBase, /col, /base_align_Center, ypad=5);, ypad=10)

labelSelectBase = widget_base(col1base, /row, xpad=0, /align_left, space=3)
ltexteditlabel = widget_label(labelSelectBase,value='Select Label:  ')
lt1Text = Widget_Combobox(labelSelectBase,Value = ' ', XSize=260, uval='LABELDROPLIST', uname='labeldroplist')

ltexteditBase = widget_base(col1base, /row, xpad=0, /align_left, space=3)
ltexteditlabel = widget_label(ltexteditBase,value='Edit/Add Label:')
ltextedit = widget_text(ltexteditBase, value = '', /editable, /all_events, xsize=40, ysize=1, $
  uval='LABELTEXTEDIT', uname='labeltextedit')

;uptoarrow = read_bmp(rpath + 'up_to_arrow.bmp', /rgb)
;spd_ui_match_background, tlb, uptoarrow
;ltextsync = widget_button(ltexteditBase, value = uptoarrow, /bitmap, uval='LABELTEXTSYNC', uname='labeltextsync')
 
col2Base = Widget_Base(lt1TextBase, /col)
col2Base2 = Widget_Base(col2Base, /col, /nonexclusive, ypad=5)
showSingleLabelCheck = widget_button(col2Base2,value='Show Label',UVALUE='SHOWLABEL',uname='showlabel')
ltexthelpbutton = widget_button(col2Base, value='Format Help', uname='formathelpbutton', uvalue='FORMATHELPBUTTON')


;lt2Base = Widget_Base(ltFrameBase, /col, xpad=7, /align_left)
;lt3Base = Widget_base(lt2base, /row, /align_center)

ltFrameAttrBase = widget_base(ltFrameBase,/row)
lpcol1Base = Widget_Base(ltFrameAttrBase, /row)
lpcol2Base = Widget_Base(ltFrameAttrBase, /row)

;lt4Base = Widget_base(lt3Base, /row)

;lpFrameBase = Widget_Base(labelTextBase, /row, Frame=3, YPad=2, XPad=2)

;lpcol1Base = Widget_Base(lpFrameBase, /row)
lpcol1aBase = Widget_Base(lpcol1Base, /col, space=17)
lpcol1bBase = Widget_Base(lpcol1Base, /col, space=5)
lpcol2aBase = Widget_Base(lpcol2Base, /col, space=17)
lpcol2bBase = Widget_Base(lpcol2Base, /col, space=5)
;lpcol2Base = Widget_Base(lpFrameBase, /col)

lpstyleLabel = Widget_Label(labelTextBase, Value='Style & Placement:', /Align_Left)

styleFrameBase= Widget_Base(labelTextBase, /col, Frame=3, YPad=2, XPad=2, uname='labelstyleframebase')
stylepBase = Widget_Base(styleFrameBase, /row)
case axisselect of
  0: labelplacement = ['Bottom','Top']
  1: labelplacement = ['Left','Right']
endcase
labelplabel = widget_label(stylepbase, value='Place Label on: ', /align_left)
titlePlaceDroplist = Widget_combobox(stylepBase, Value=labelplacement, uval='PLACELABEL', uname='placelabel')

showLabelButtonBase = widget_base(styleFrameBase,/row,/nonexclusive,/align_left)
stackButton = Widget_Button(showLabelButtonBase, Value='Stack Labels', uval='STACKLABELS', uname='stacklabels')
lazyButton = widget_button(showlabelButtonBase, value='Lazy Labels', uval='LAZYLABELS', $
  uname='lazylabels', tooltip='Underscores will be converted to new lines')
showLabelButton = Widget_Button(showLabelButtonBase, Value='Show Labels', uval='SHOWLABELS', uname='showlabels')
stackButtonBase= widget_base(styleFrameBase,/row,/nonexclusive)

IF axisselect EQ 1 THEN blackButton = Widget_Button(stackButtonBase, Value='Set All Labels Black', UValue='BLACKLABELS', uname='blacklabels')
Widget_Control, showlabelButton, /Set_Button

lpGlobalBase = Widget_Base(styleFrameBase, /row)
lpoBase = Widget_Base(lpGlobalBase, /col)
lpoLabel = Widget_Label(lpoBase , Value='Orientation:  ', /align_left)
lpoButBase = Widget_Base(lpoBase , /col, /Exclusive, Frame=3, xpad=18)
lpovHorizButton = Widget_Button(lpoButBase, Value='Horizontal', uval='LABELHORIZONTAL', uname='labelhorizontal')
lpoVertButton = Widget_Button(lpoButBase, Value='Vertical', uval='LABELVERTICAL', uname='labelvertical')
Widget_Control, lpovHorizButton, /Set_Button

lpoIncrBase = Widget_Base(lpGlobalBase, /Row, YPad=2,/align_center)
lpoIncrIncrement=spd_ui_spinner(lpoIncrBase, label = 'Margin: ',Increment=1, uval='LABELMARGIN', uname='labelmargin')
lpoIncrLabel = Widget_Label(lpoIncrBase, Value=' pts ')

tlabel = Widget_Label(lpcol1aBase, value = 'Font:', /align_left)
lpofontDroplist = Widget_combobox(lpcol1bBase, Value=fontnames, uval='LABELFONT', uname='labelfont')
tlabel = Widget_Label(lpcol1aBase, value = 'Format:', /align_left)
formattypes=textObj->getformats()
Obj_Destroy, textObj

lpoFormatDroplist = Widget_combobox(lpcol1bBase, Value=formattypes, uval='LABELFORMAT', uname='labelformat')

labelsync = widget_button(lpcol1bBase, value='Sync Panel Labels', uval='LABELSYNC', uname='labelsync', tooltip='Propagate text settings to the other labels on this panel')

tlabel= Widget_Label(lpcol2aBase, value='Size (points): ', /align_left)
fontIncrement = spd_ui_spinner(lpcol2bBase, Increment=1,  Value=12, uval='LABELSIZE', uname='labelsize', min_value=1)
cb1Base = Widget_Base(lpcol2bBase, /row, space=3, /base_align_center)

tlabel= Widget_Label(lpcol2aBase, value='Color: ', /align_left)

labelpaletteButton = Widget_Button(cb1Base, Value=palettebmp, /Bitmap, UValue='LABELPALETTE', uname='labelpalette', $
  Tooltip='Choose color from Palette')
labelColorWindow = WIDGET_DRAW(cb1Base, graphics_level=2, renderer=1, retain=1, XSize=50, YSize=20, units=0, frame=1, $
  uname = 'labelcolorwin', /expose_events)
  
;n;labelsSetButton = Widget_Button(labelButtonBase, Value='Set All Panels', /Align_Center, XSize = 125, uval='LABELTSETALL', uname='labeltsetall')
  
  
okButton = Widget_Button(buttonBase, Value='OK', uval='OK')
applyButton = Widget_Button(buttonBase, Value='Apply', UValue='APPLY',Tooltip='Apply all settings from all tabs to current panel.')
applyToAllButton = Widget_Button(buttonBase, Value='Apply to All Panels', Uvalue='APPLYTOALL', sens=1, $
   Tooltip='Apply settings from the current tab to all panels')
cancelButton = Widget_Button(buttonBase, Value='Cancel', UValue='CANC')
templateButton = Widget_Button(buttonBase,  Value='Store for a Template', UValue='TEMP',tooltip='Use these settings when saving a Graph Options Template')
;helpButton = Widget_Button(buttonBase, Value='Help', XSize=75)


;Create Status Bar Object:
;*************************
;
panelDroplists=[rangepanelDroplist, tpanelDroplist, gpDroplist, anopanelDroplist, titlepanelDroplist, lpanelDroplist]
statusBar = Obj_New('SPD_UI_MESSAGE_BAR', statusBase, XSize=80, YSize=1)

;state = {tlb:tlb, gui_id:gui_id, rangeOptions:rangeOptions,$; tabbase:tabbase,$
;  scalingOptions:scalingOptions, labelselect:0, atype:atype, $
;  axispanelselect:axispanelselect,; panels:panels, panelobjs:panelobjs, $
;  axisselect:axisselect,$; currlabelobj:ptr_new(),  anocolorwin:-1, $
;  ;labelcolorwin:-1, majorgridcolorwin:-1, minorgridcolorwin:-1, tcolorWin:0,firstUnits:0,$
;  windowStorage:windowStorage, loadedData:loadedData, drawObject:drawObject, $
;  historyWin:historyWin, statusBar:statusBar, panelDroplists:panelDroplists, $
;  ;majorgridcolorWindow:majorgridcolorWindow, minorgridcolorWindow:minorgridcolorWindow, $
;  ;anocolorWindow:anocolorWindow, labelcolorWindow:labelcolorWindow, $
;  ;minIncrement:minIncrement, maxIncrement:maxIncrement, minBase:minBase, maxBase:maxBase,$
;  ;majorUnits:0,minorUnits:0, minorTickBase:minorTickBase, $
;  scrollbar:scrollbar,template:template}

state = {tlb:tlb, gui_id:gui_id, rangeOptions:rangeOptions,scalingOptions:scalingOptions,$
  labelselect:0, atype:atype, axispanelselect:axispanelselect, axisselect:axisselect,$
  windowStorage:windowStorage, loadedData:loadedData, drawObject:drawObject, historyWin:historyWin,$
  statusBar:statusBar, panelDroplists:panelDroplists, scrollbar:scrollbar, template:template, tlb_statusbar:tlb_statusbar,$
  lockedMessageDisplayed:0,last_change:''}
  
  
  
Widget_Control, tlb, Set_UValue=state, /No_Copy
centerTLB, tlb
Widget_Control, tlb, /realize
statusBar->Draw

; the following call to update was commented out 9/30/2014
; by Eric Grimes; seems unnecessary, and calls to 
; the update method of the draw object are very expensive
;drawObject->update,windowStorage,loadedData

spd_ui_update_axis_from_draw,drawObject,panels
spd_ui_init_axis_window, tlb

;keep windows in X11 from snaping back to
;center during tree widget events
if !d.NAME eq 'X' then begin
  widget_control, tlb, xoffset=0, yoffset=0
endif

XManager, 'spd_ui_axis_options', tlb, /No_Block

RETURN
END ;--------------------------------------------------------------------------------
