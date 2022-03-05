;NAME:
; spd_ui_zaxis_options
;
;PURPOSE:
; A widget interface for modifying line, zaxis and highlight attributes
;
;CALLING SEQUENCE:
; spd_uifile, gui_id
;
;INPUT:
; gui_id = the id number of the widget that calls this
;
;OUTPUT:
;
;
;HISTORY:
;$LastChangedBy: jwl $
;$LastChangedDate: 2022-03-04 11:48:01 -0800 (Fri, 04 Mar 2022) $
;$LastChangedRevision: 30648 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/spedas_gui/panels/spd_ui_zaxis_options.pro $
;
;---------------------------------------------------------------------------------

PRO spd_ui_zaxis_init_color, state=state


  compile_opt idl2, hidden
  
  ; intialize color windows
  
  state.zAxisSettings->GetProperty, LabelTextObject=labelTextObject, AnnotateTextObject=annotateTextObject,$
    subtitleTextObject=subtitleTextObject
  IF Obj_Valid(labelTextObject) THEN labelTextObject->GetProperty, Color=value ELSE value=[0,0,0]
  colorid = widget_info(state.tlb, find_by_uname='tcolor')
  Widget_Control, colorid, Get_Value=colorWin
  scene=obj_new('IDLGRSCENE', color=value)
  colorWin->setProperty,graphics_tree=scene
  colorWin->draw
  
  IF Obj_Valid(subtitleTextObject) THEN subtitleTextObject->GetProperty, Color=value ELSE value=[0,0,0]
  colorid = widget_info(state.tlb, find_by_uname='subtitlecolor')
  Widget_Control, colorid, Get_Value=colorWin
  scene=obj_new('IDLGRSCENE', color=value)
  colorWin->setProperty,graphics_tree=scene
  colorWin->draw
  
  IF Obj_Valid(annotateTextObject) THEN AnnotateTextObject->GetProperty, Color=value ELSE value = [0,0,0]
  acolorid = widget_info(state.tlb, find_by_uname='acolor')
  Widget_Control, acolorid, Get_Value=acolorWin
  scene=obj_new('IDLGRSCENE', color=value)
  acolorwin->setProperty,graphics_tree=scene
  acolorWin->draw
  
  ;get the draw window
  widget_control,state.zaxisarea,get_value=drawWin
  
  ;create the scene
  view = obj_new('IDLgrView',units=3,viewPlane_rect=[0,0,1,1],location=[0.,0.],dimensions=[1.,1.],zclip=[1.,-1],eye=5.,transparent=1,hide=0)
  model = obj_new('IDLgrModel')
  palette = obj_new('IDLgrPalette')
  getctpath,colortablepath
  palette->loadCt,state.zAxisSettings->getColorTableNumber(),file=colortablepath
  cbar = obj_new('IDLgrImage',indgen(1,256),palette=palette,location=[0,0,0],dimensions=[1,1])
  model->add,cbar
  view->add,model
  
  ;add the scene to the window and redraw
  drawWin->setProperty,graphics_tree=view
  drawWin->draw
  
  
  
END ;---------------------------------------------------------------------------------------------

pro spd_ui_zaxis_propagate_settings, state

  compile_opt idl2, hidden
  
  
  ;get settings for current panel
  z = state.zaxissettings->getall()
  
  ;get current tab
  tab = widget_info(state.tabbase, /tab_current)
  
  
  ;loop over panels
  for i=0, n_elements(state.zaxes)-1 do begin
  
    if i eq state.selectedpanel then continue
    
    ;propagate main tab's settings
    if tab eq 0 then begin
      
      state.zaxes[i]->setproperty, $
        minrange=z.minrange, $
        maxrange=z.maxrange, $
        colortable=z.colortable, $
        fixed=z.fixed, $
        scaling=z.scaling, $
        ticknum=z.ticknum, $
        minorticknum=z.minorticknum, $
        logminorticktype=z.logminorticktype, $
        autoticks=z.autoticks, $
        placement=z.placement, $
        margin=z.margin
        
    ;propagate title tab's settings
    endif else if tab eq 1 then begin
    
      t = z.labelTextObject->getall()
      st = z.subtitleTextObject->getall()
      
      state.zAxes[i]->getproperty, $
        labelTextObject=titleTextObject, $
        subtitleTextObject=subtitleTextObject

      titleTextObject->setproperty, $
        color=t.color, $
        font=t.font, $
        format=t.format, $
        size=t.size
      
      subtitleTextObject->setproperty, $
        color=st.color, $
        font=st.font, $
        format=st.format, $
        size=st.size

      state.zAxes[i]->setproperty, $
        lazylabels=z.lazylabels, $
        labelmargin=z.labelmargin, $
        labelorientation=z.labelorientation

    ;propagate annotation tab's settings
    endif else if tab eq 2 then begin
      
      a = z.annotateTextObject->getall()
      
      state.zAxes[i]->getproperty, $
        annotateTextObject=annotateTextObject
      
      annotateTextObject->setproperty, $
        color=a.color, $
        font=a.font, $
        format=a.format, $
        size=a.size
      
      state.zaxes[i]->setproperty, $
        annotationOrientation=z.annotationOrientation, $
        annotateExponent=z.annotateExponent, $
        annotationStyle=z.annotationStyle
      
    endif
    
  endfor

  
end ;---------------------------------------------------------------------------------------------

;This routine will update the zaxis settings using information from
;the draw object.  When automatic settings are used, the draw object
;will sometimes use different numbers of ticks than the requested
;number.  This routine ensures the values reported by the panel
;are accurate without requiring the draw object to break abstraction
pro spd_ui_update_zaxis_from_draw,panels,draw,historywin

  compile_opt idl2,hidden
  
  if obj_valid(panels) && panels->count() gt 0 then begin
  
    panel_list = panels->get(/all)
    
    ;loop over panel list
    for i = 0,n_elements(panel_list)-1 do begin
    
      panel_list[i]->getProperty,zaxis=zaxis
      
      if ~obj_valid(zaxis) then continue
      
      info = draw->getPanelInfo(i)
      
      if ~is_struct(info) then continue
      
      if ~info.hasSpec then begin
        historyWin->update,'Possible problem in zaxis Options.  Panel was expected to have z-axis but none is present.'
        continue
      endif
      
      zrange = info.zrange
      
      ;delog range(draw object represents ranges internally with logs already applied
      if info.zscale eq 1 then begin
        zrange = 10D^zrange
      endif else if info.zscale eq 2 then begin
        zrange = exp(zrange)
      endif
      
      zaxis->setProperty, $
        minRange=zrange[0], $
        maxrange=zrange[1], $
        ; tickNum = info.zmajornum,$
        minorTickNum = info.zminornum
        
    endfor
    
  endif
  
end

pro spd_ui_zaxis_switch_color_table,table,tlb

  compile_opt idl2, hidden
  
  ; set color table button
  
  colorbar = widget_info(tlb,find_by_uname='colorbar')
  
  Widget_Control, colorbar, Get_Value=win
  win->getProperty,graphics_tree=view
  model = (view->get(/all))[0]
  image = (model->get(/all))[0]
  image->getProperty,palette=pal
  getctpath,ctpathname
  pal->loadct,table,file=ctpathname
  win->draw
  
end

;note the update function is the only remaining function
;in this panel that makes extensive use of the state struct
;to pass around widget ids.  If at possible, try to migrate
;away from this formulation when maintaining the code,
;and instead use the uname/find_by_uname formulation
PRO spd_ui_zaxis_update, state

  state.zAxisSettings->GetProperty, $
    ColorTable=colortable, $
    Fixed=fixed, $
    MinRange=minrange, $
    MaxRange=maxrange, $
    Scaling=scaling, $
    Placement=placement, $
    TickNum=ticknum, $
    minorTickNum=minorTickNum,$
    Margin=margin, $
    lazylabels=lazylabels, $
    LabelMargin=labelmargin, $
    LabelTextObject=labeltextobject, $
    subtitleTextObject=subtitletextobject, $
    AnnotateTextObject=annotatetextobject, $
    LabelOrientation=labelorientation, $
    AnnotationStyle=annotationstyle, $
    AnnotationOrientation=annotationorientation, $
    annotateExponent=annotateExponent,$
    autoticks=autoticks,$
    logminorticktype=logminorticktype
    
  IF ~Obj_Valid(labelTextObject) THEN begin
    labelTextObject=Obj_New("SPD_UI_TEXT")
    state.zAxisSettings->setProperty,labelTextObject=labelTextObject
  endif
  
  LabelTextObject->getproperty, $
    value=value, $
    font=font, $
    size=size, $
    format=format, $
    color=color
    
  IF ~Obj_Valid(subtitleTextObject) THEN begin
    subtitleTextObject=Obj_New("SPD_UI_TEXT")
    state.zAxisSettings->setProperty,subtitleTextObject=subtitleTextObject
  endif
  
  subtitleTextObject->getproperty, $
    value=subvalue, $
    font=subfont, $
    size=subsize, $
    format=subformat, $
    color=subcolor
    
  if ~obj_valid(AnnotateTextObject) then begin
    AnnotateTextObject=obj_new('spd_ui_text')
    state.zAxisSettings->setProperty,annotateTextObject=annotateTextObject
  endif
  
  AnnotateTextObject->getproperty, $
    font=afont, $
    size=asize, $
    format=aformat, $
    color=acolor
    
  ; set current panel selection
  panels = widget_info(state.tlb, find_by_uname='sPanels')
  widget_control, panels, set_combobox_select=state.selectedPanel
  panels = widget_info(state.tlb, find_by_uname='tPanels')
  widget_control, panels, set_combobox_select=state.selectedPanel
  
  ; update widgets on the settings panel
  spd_ui_zaxis_switch_color_table,colortable,state.tlb
  
  FOR i = 0, N_Elements(state.colortablebuttons)-1 DO BEGIN
    IF i EQ colortable THEN begin
      state.colortable=colortable
      Widget_Control, state.colorTableButtons[colortable], set_button=1
    endif
  ENDFOR
  
  ; set range widgets
  IF fixed EQ 0 THEN BEGIN
    Widget_Control, state.fixedButton, Set_Button=0
    Widget_Control, state.rangeMinIncrement, Set_Value=minRange
    Widget_Control, state.rangeMaxIncrement, Set_Value=maxRange
    Widget_Control, state.rangeMinIncrement, sensitive=0
    Widget_Control, state.rangeMaxIncrement, sensitive=0
  ENDIF ELSE BEGIN
    Widget_Control, state.fixedButton, set_Button=1
    Widget_Control, state.rangeMinIncrement, Set_Value=minRange
    Widget_Control, state.rangeMaxIncrement, Set_Value=maxRange
    Widget_Control, state.rangeMinIncrement, sensitive=1
    Widget_Control, state.rangeMaxIncrement, sensitive=1
  ENDELSE
  ; set scaling button
  CASE scaling OF
    0: Widget_Control, state.slinearButton, Set_Button=1
    1: Widget_Control, state.slogButton, Set_Button=1
    2: Widget_Control, state.snatButton, Set_Button=1
  ENDCASE
  ; set placement buttons
  Widget_Control, state.plinearButtons[placement], Set_Button=1
  
  ;set ticks options
  id = widget_info(state.tlb,find_by_uname='autoticks')
  widget_control,id,set_button=autoticks
  
  id = widget_info(state.tlb,find_by_uname='nmajorticks')
  widget_control,id,set_value=ticknum
  widget_control,id,sensitive=~autoticks 
  
  id = widget_info(state.tlb,find_by_uname='nminorticks')
  widget_control,id,set_value=minorTickNum
  widget_control,id,sensitive=~autoticks 
  
  id = widget_info(state.tlb,find_by_uname='margin')
  widget_control,id,set_value=margin
  
  ; set text tab widgets
  
  id = widget_info(state.tlb,find_by_uname='logminorticktypebase')
  widget_control,id,sensitive=scaling ne 0
  
  id = widget_info(state.tlb,find_by_uname='logminorticktype'+strtrim(logminorticktype,2))
  widget_control,id,/set_button
  
  ; Labels (title)
  id = widget_info(state.tlb,find_by_uname='text')
  widget_control,id,set_value=value
  id = widget_info(state.tlb, find_by_uname='tfont')
  widget_control, id, set_combobox_select=font
  id = widget_info(state.tlb, find_by_uname='tsize')
  widget_control, id, set_value=size
  if format eq -1 then format = n_elements(labeltextobject->getformats())-1
  id = widget_info(state.tlb, find_by_uname='tformat')
  widget_control, id, set_combobox_select=format
  
  ; subtitle
  id = widget_info(state.tlb,find_by_uname='subtitletext')
  widget_control,id,set_value=subvalue
  id = widget_info(state.tlb, find_by_uname='subtitlefont')
  widget_control, id, set_combobox_select=subfont
  id = widget_info(state.tlb, find_by_uname='subtitlesize')
  widget_control, id, set_value=subsize
  if format eq -1 then format = n_elements(labeltextobject->getformats())-1
  id = widget_info(state.tlb, find_by_uname='subtitleformat')
  widget_control, id, set_combobox_select=subformat
  
  id = widget_info(state.tlb, find_by_uname='tmargin')
  widget_control, id, set_value=labelmargin
  idhoriz = widget_info(state.tlb, find_by_uname='thoriz')
  idvert = widget_info(state.tlb, find_by_uname='tvert')
  if labelorientation eq 0 then widget_control, idhoriz, /set_button $
  else widget_control, idvert, /set_button
  
  id = widget_info(state.tlb, find_by_uname='lazy')
  widget_control, id, set_button = lazylabels
  
  ; redraw color
  colorid = widget_info(state.tlb, find_by_uname='tcolor')
  widget_control, colorid, get_value=colorWin
  colorWin->getProperty,graphics_tree=scene
  scene->setProperty,color=reform(color)
  colorWin->draw
  
  subcolorid = widget_info(state.tlb, find_by_uname='subtitlecolor')
  widget_control, subcolorid, get_value=subcolorWin
  subcolorWin->getProperty,graphics_tree=scene
  scene->setProperty,color=reform(subcolor)
  subcolorWin->draw
  
  ; Annotations
  id = widget_info(state.tlb, find_by_uname='afont')
  widget_control, id, set_combobox_select=afont
  id = widget_info(state.tlb, find_by_uname='asize')
  widget_control, id, set_value=asize
  if aformat eq -1 then aformat = n_elements(labeltextobject->getformats())-1
  id = widget_info(state.tlb, find_by_uname='aformat')
  widget_control, id, set_combobox_select=aformat
  id = widget_info(state.tlb, find_by_uname='astyle')
  widget_control, id, set_combobox_select=annotationstyle
  widget_control, state.atype[annotateExponent], set_button=1
  idhoriz = widget_info(state.tlb, find_by_uname='ahoriz')
  idvert = widget_info(state.tlb, find_by_uname='avert')
  if annotationOrientation eq 0 then widget_control, idhoriz, /set_button $
  else widget_control, idvert, /set_button
  ; redraw color
  acolorid = widget_info(state.tlb, find_by_uname='acolor')
  widget_control, acolorid, get_value=acolorWin
  acolorWin->getProperty,graphics_tree=scene
  scene->setProperty,color=reform(acolor)
  acolorWin->draw
  
  state.historywin->update,'SPD_UI_ZAXIS_OPTIONS: Widget display values updated/redrawn.
  
END ;---------------------------------------------------------------------------------------------

;This routine allows delayed handling of events
;This should simplify code, allow for more reliable error handling, and generate more reliable code
;This style of event handling is being implemented using a gradual approach
pro spd_ui_zaxis_set_value,state,event

  compile_opt idl2,hidden
  
  zaxis = state.zAxisSettings
  historyWin = state.historyWin
  statusBar = state.statusBar
  tlb = event.top
  
  ;minor tick num,major tick num
  spd_ui_zaxis_set_value_ticks,zaxis,tlb,statusBar,historyWin
  
  ;range and scaling settings settings
  spd_ui_zaxis_set_value_range,zaxis,tlb,statusBar,historyWin
  
  ;color table value
  spd_ui_zaxis_set_value_color_table,zaxis,tlb,statusBar,historyWin
  
  ;zaxis placement
  spd_ui_zaxis_set_value_placement,zaxis,tlb,statusBar,historyWin
  
  ;text parameters
  spd_ui_zaxis_set_value_text,zaxis,tlb,statusBar,historyWin
  
  ;annotation parameters
  spd_ui_zaxis_set_value_annotation,zaxis,tlb,statusBar,historyWin
  
  historyWin->update,'Z Axis Update Complete',/dontshow
  
end

pro spd_ui_zaxis_set_value_text_formats,textobj,tlb,statusBar,historywin,uprefix,messagename

  compile_opt idl2,hidden
  
  ;set text font
  font = widget_info(tlb,find_by_uname=uprefix+'font')
  widget_control,font,get_value=fontnames
  currentfont = widget_info(font,/combobox_gettext)
  fontindex = where(currentfont eq fontnames,c)
  
  if c eq 0 then begin
    statusBar->update,'Error: Cannot identify ' +messagename+ ' font index'
    historyWin->update,'Error: Cannot identify ' +messagename+ ' font index'
    textObj->getProperty,font=fontindex
    widget_control,font,set_combobox_select=fontindex
  endif else begin
    textObj->setProperty,font=fontindex
    ;  statusBar->update,'Set ' + messagename + ' Font Value'
    historyWin->update,'Set ' + messagename + ' Font Value',/dontshow
  endelse
  
  ;set text size
  size = widget_info(tlb,find_by_uname=uprefix+'size')
  widget_control,size,get_value=sizevalue
  if ~finite(sizevalue,/nan) then begin
    if sizevalue lt 1 then begin
      statusBar->update,'Error: ' + messagename+ ' font size cannot less than 1.'
      historyWin->update,'Error: ' + messagename + ' font size cannot less than 1.'
      messageString = messagename+ ' font size cannot be less than 1, value set to 1.'
      response=dialog_message(messageString,/CENTER)
      widget_control,size,set_value=1
      textObj->setProperty,size=1
    endif else begin
      textObj->setProperty,size=sizevalue
      ;      statusBar->update,'Set ' + messagename + ' Font Value'
      historyWin->update,'Set ' + messagename + ' Font Size',/dontshow
    endelse
  endif else begin
    statusBar->update,'Invalid ' + messagename + ' text size, value reset.'
    historyWin->update,'Invalid ' + messagename + ' text size, value reset.',/dontshow
    messageString = 'Invalid '+messagename+ ' font size, value reset.'
    response=dialog_message(messageString,/CENTER)
    textObj->getProperty,size=sizevalue
    widget_control,size,set_value=sizevalue
  endelse
  
  ;set text format
  format = widget_info(tlb,find_by_uname=uprefix+'format')
  widget_control,format,get_value=formatnames
  currentformat = widget_info(format,/combobox_gettext)
  formatindex = where(currentformat eq formatnames,c)
  
  if c eq 0 then begin
    statusBar->update,'Error: Cannot identify ' + messagename + ' format index'
    historyWin->update,'Error: Cannot identify ' + messagename + ' format index'
    textObj->getProperty,format=formatindex
    widget_control,format,set_combobox_select=formatindex
  endif else begin
    textObj->setProperty,format=formatindex
    ; statusBar->update,'Set ' + messagename + ' format Value'
    historyWin->update,'Set ' + messagename + ' format Value',/dontshow
  endelse
  
  ;set text color
  color = widget_info(tlb,find_by_uname=uprefix+'color')
  widget_control,color,get_value=cWin
  cWin->getProperty,graphics_tree=view
  view->getProperty,color=colorvalue
  textObj->setProperty,color=colorvalue
  ;statusBar->update,'Set ' + messagename + ' color Value'
  historyWin->update,'Set ' + messagename + ' color Value',/dontshow
  
end

pro spd_ui_zaxis_set_value_annotation,zaxis,tlb,statusBar,historyWin

  compile_opt idl2,hidden
  
  zaxis->getProperty,annotateTextObject=textobj
  
  ;verify that the text object actually exists
  if ~obj_valid(textobj) then begin
    textobj = obj_new('spd_ui_text')
    zaxis->setProperty,annotateTextObject=textobj
  endif
  
  ;use this function to handle all the features that are duplicated between text and annotations
  spd_ui_zaxis_set_value_text_formats,textobj,tlb,statusBar,historywin,'a','Annotation'
  
  ;set annotation orientation
  vert = widget_info(tlb,find_by_uname='avert')
  vertvalue = widget_info(vert,/button_set)
  zaxis->setProperty,annotationOrientation=vertvalue
  ; statusBar->update,'Set annotation orientation'
  historyWin->update,'Set annotation orientation',/dontshow
  
  ;set annotation style
  style = widget_info(tlb,find_by_uname='astyle')
  widget_control,style,get_value=stylenames
  currentstyle = widget_info(style,/combobox_gettext)
  styleindex = where(currentstyle eq stylenames,c)
  
  if c eq 0 then begin
    statusBar->update,'Error: Cannot identify style index'
    historyWin->update,'Error: Cannot identify style index'
    zaxis->getProperty,annotationstyle=styleindex
    widget_control,style,set_combobox_select=styleindex
  endif else begin
    zaxis->setProperty,annotationstyle=styleindex
    ;statusBar->update,'Set Style Value'
    historyWin->update,'Set Style Value',/dontshow
  endelse
  
  ;set annotation type restrictions
  annoExp=0
  id = widget_info(tlb, find_by_uname='aauto')
  if widget_info(id, /button_set) then annoExp =0
  id = widget_info(tlb, find_by_uname='adbl')
  if widget_info(id, /button_set) then annoExp =1
  id = widget_info(tlb, find_by_uname='aexp')
  if widget_info(id, /button_set) then annoExp =2
  zaxis->setProperty, annotateExponent=annoExp
  
end

pro spd_ui_zaxis_set_value_text,zaxis,tlb,statusBar,historyWin

  compile_opt idl2,hidden
  
  zaxis->getProperty,labelTextObject=textobj, subtitletextobject=subtitletextobject
  
  ;verify that the text object actually exists
  if ~obj_valid(textobj) then begin
    textobj = obj_new('spd_ui_text')
    zaxis->setProperty,labelTextObject=textobj
  endif
  
  ;set text value
  text = widget_info(tlb,find_by_uname='text')
  widget_control,text,get_value=textvalue
  textobj->setProperty,value=textvalue
  ;  statusBar->update,'Set Text Value'
  historyWin->update,'Set Title Value',/dontshow
  
  ;use this function to handle all the features that are duplicated between text and annotations
  spd_ui_zaxis_set_value_text_formats,textobj,tlb,statusBar,historywin,'t','Title'
  
  ; set subtitle text
  subtitle = widget_info(tlb,find_by_uname='subtitletext')
  widget_control,subtitle,get_value=subtitlevalue
  subtitletextobject->setProperty,value=subtitlevalue
  historyWin->update,'Set Subtitle Value',/dontshow
  
  ;use this function to handle all the features that are duplicated between text and annotations
  spd_ui_zaxis_set_value_text_formats,subtitletextobject,tlb,statusBar,historywin,'subtitle','Subtitle'
  
  
  ;set label orientation
  vert = widget_info(tlb,find_by_uname='tvert')
  vertvalue = widget_info(vert,/button_set)
  zaxis->setProperty,labelOrientation=vertvalue
  ; statusBar->update,'Set label orientation'
  historyWin->update,'Set label orientation',/dontshow
  
  ;set 'lazy labels' option
  id = widget_info(tlb, find_by_uname='lazy')
  zaxis->setproperty, lazylabels = widget_info(id,/button_set)
  historyWin->update,'Set "lazy labels"',/dontshow
  
  ;set label margin
  margin = widget_info(tlb,find_by_uname='tmargin')
  widget_control,margin,get_value=marginvalue
  if marginvalue lt 0 then begin
    statusBar->update,'Error: label margin cannot be negative, value set to 0.'
    historyWin->update,'Error: label margin cannot be negative, value set to 0.'
    widget_control,margin,set_value=0
    zaxis->setProperty,labelmargin=0
    messageString = 'Label margin cannot be negative, value set to 0.'
    response=dialog_message(messageString,/CENTER)
  endif else begin
    if ~finite(marginvalue,/nan) then begin
      zaxis->setProperty,labelmargin=marginvalue
      ;      statusBar->update,'Set label margin'
      historyWin->update,'Set label margin',/dontshow
    endif else begin
      statusBar->update,'Invalid label margin, value reset.'
      historyWin->update,'Invalid label margin, value reset.',/dontshow
      zaxis->getProperty,labelmargin=marginvalue
      widget_control,margin,set_value=marginvalue
      messageString = 'Invalid label margin, value reset.'
      response=dialog_message(messageString,/CENTER)
    endelse
  endelse
  
  
end

pro spd_ui_zaxis_set_value_color_table,zaxis,tlb,statusBar,historyWin

  compile_opt idl2,hidden
  
  colorTableNames = zaxis->getColorTables()
  
  for i = 0,n_elements(colorTableNames)-1 do begin
  
    button = widget_info(tlb,find_by_uname=colorTableNames[i])
    if widget_info(button,/button_set) then begin
      zaxis->setProperty,colorTable=i
      ; statusBar->update,'Updating color table'
      historyWin->update,'Updating color table',/dontshow
      break
    endif
    
  endfor
  
end


;Set colorbar placement and margin 
;
pro spd_ui_zaxis_set_value_placement,zaxis,tlb,statusBar,historyWin

  compile_opt idl2,hidden
  
  placementNames = zaxis->getPlacements()
  
  for i = 0,n_elements(placementNames)-1 do begin
  
    button = widget_info(tlb,find_by_uname=placementNames[i])
    if widget_info(button,/button_set) then begin
      zaxis->getProperty,placement=j
      zaxis->setProperty,placement=i
      ;statusBar->update,'Updating placement'
      historyWin->update,'Updating placement',/dontshow
      break
    endif
    
  endfor
  
  margin = widget_info(tlb,find_by_uname='margin')
  widget_control,margin,get_value=marginnum
  
  if ~finite(marginnum,/nan) then begin
    if marginnum lt 0 then begin
      messageString = 'Margin cannot be negative, value set to 0.'
      statusBar->update,messageString
      historyWin->update,messageString, /dontshow
      response=dialog_message(messageString,/CENTER)
      widget_control,margin,set_value=0
      zaxis->setProperty,margin=0
    endif else begin
      zaxis->setProperty,margin=marginnum
      historyWin->update,'Margin Updated',/dontshow
    endelse
  endif else begin
    messageString = 'Invalid margin value, value reset.'
    statusBar->update,messageString
    historywin->update,messageString, /dontshow
    response=dialog_message(messageString,/CENTER)
    zaxis->getProperty,margin=marginnum
    widget_control,margin,set_value=marginnum
  endelse
  
  
  
end

;range and scaling settings
pro spd_ui_zaxis_set_value_range,zaxis,tlb,statusBar,historyWin

  compile_opt idl2,hidden
  
  ;fixed range flag
  fixed = widget_info(tlb,find_by_uname='fixed')
  fixedvalue = widget_info(fixed,/button_set)
  zaxis->getProperty,fixed=oldfixed
  zaxis->setProperty,fixed=fixedvalue
  ; statusBar->update,'Updated fixed value'
  historyWin->update,'Updated fixed value',/dontshow
  
  ;scaling flag
  linear = widget_info(tlb,find_by_uname='linear')
  linearvalue = widget_info(linear,/button_set)
  log10 = widget_info(tlb,find_by_uname='log10')
  log10value = widget_info(log10,/button_set)
  natural = widget_info(tlb,find_by_uname='natural')
  naturalvalue = widget_info(natural,/button_set)
  
  if log10value then begin
    scaling = 1
  endif else if naturalvalue then begin
    scaling = 2
  endif else begin
    scaling = 0
  endelse
  
  zaxis->getProperty,scaling=oldscaling
  zaxis->setProperty,scaling=scaling
  
  ;statusBar->update,'Updated scaling value'
  historyWin->update,'Updated scaling value',/dontshow
  
  ;minimum and maximum values
  
  minimum = widget_info(tlb,find_by_uname='minimum')
  widget_control,minimum,get_value=minimumvalue
  
  maximum = widget_info(tlb,find_by_uname='maximum')
  widget_control,maximum,get_value=maximumvalue
  ;
  ;Modified to only issue messages if fixed value is checked (note that other than the case of no panels no messages
  ; would be issued anyway).
  if finite(maximumvalue,/nan) && finite(minimumvalue,/nan) && fixedValue then begin
    messageString = 'Invalid Fixed Maximum & Minimum, values reset.'
    statusBar->update,messageString
    historyWin->update,messageString, /dontshow
    response=dialog_message(messageString,/CENTER)
    zaxis->getProperty,minrange=minimumvalue,maxrange=maximumvalue
    widget_control,minimum,set_value=minimumvalue
    widget_control,maximum,set_value=maximumvalue
  endif else if finite(maximumvalue,/nan) && fixedValue then begin
    messageString = 'Invalid Fixed Maximum, value reset.'
    statusBar->update,messageString
    historyWin->update,messageString, /dontshow
    response=dialog_message(messageString,/CENTER)
    zaxis->getProperty,maxrange=maximumvalue
    widget_control,maximum,set_value=maximumvalue
  endif else if finite(minimumvalue,/nan) && fixedValue then begin
    messageString = 'Invalid Fixed Minimum, value reset.'
    statusBar->update,messageString
    historyWin->update,messageString,/dontshow
    response=dialog_message(messageString,/CENTER)
    zaxis->getProperty,minrange=minimumvalue
    widget_control,minimum,set_value=minimumvalue
  endif else begin
    zaxis->getProperty,minrange=oldmin,maxrange=oldmax
    if minimumvalue ge maximumvalue && fixedValue then begin
      messageString = 'Cannot have a minimum range that is greater than or equal to maximum range, values reset.'
      statusBar->update,messageString
      historyWin->update,messageString
      response=dialog_message(messageString,/CENTER)
      zaxis->getProperty,minrange=minimumvalue,maxrange=maximumvalue
      widget_control,minimum,set_value=minimumvalue
      widget_control,maximum,set_value=maximumvalue
    endif else if scaling ne 0 && minimumvalue le 0 && fixedValue then begin
      messageString = 'Cannot have a minimum range that is less than or equal to 0 on log z-axis. Resetting.'
      statusBar->update,messageString
      historyWin->update,messageString
      response=dialog_message(messageString,/CENTER)
      zaxis->getProperty,minrange=minimumvalue,maxrange=maximumvalue
      widget_control,minimum,set_value=minimumvalue
      widget_control,maximum,set_value=maximumvalue
    ;    endif else if scaling ne 0 && minimumvalue lt 0 then begin
    ;      statusBar->update,'Cannot have a minimum range that is less than 0 on log z-axis. Resetting.'
    ;      historyWin->update,'Cannot have a minimum range that is less than 0 on log z-axis. Resetting.'
    ;      messageString = 'Cannot have a minimum range that is less than 0 on log z-axis. Resetting.'
    ;      response=dialog_message(messageString,/CENTER)
    ;      zaxis->getProperty,minrange=minimumvalue,maxrange=maximumvalue
    ;      widget_control,minimum,set_value=minimumvalue
    ;      widget_control,maximum,set_value=maximumvalue
    ;    endif else if scaling ne 0 && maximumvalue lt 0 then begin
    ;      statusBar->update,'Cannot have a minimum range that is less than 0 on log z-axis. Resetting.'
    ;      historyWin->update,'Cannot have a minimum range that is less than 0 on log z-axis. Resetting.'
    ;      zaxis->getProperty,minrange=minimumvalue,maxrange=maximumvalue
    ;      widget_control,minimum,set_value=minimumvalue
    ;      widget_control,maximum,set_value=maximumvalue
    endif else begin
      zaxis->setProperty,minRange=minimumvalue,maxrange=maximumvalue
      ;  statusBar->update,'Min & Max range set.'
      historyWin->update,'Min & Max range set.',/dontshow
    endelse
    
  endelse
  
end


;This procedure will set values for the tick spinners and the margin spinner
pro spd_ui_zaxis_set_value_ticks,zaxis,tlb,statusBar,historyWin

  compile_opt idl2,hidden
  

;  zaxis->getProperty,autoticks=oldauto
  autoticks = widget_info(tlb,find_by_uname='autoticks')
  autoval = widget_info(autoticks,/button_set)
  zaxis->setProperty,autoticks=autoval
  
  major = widget_info(tlb,find_by_uname='nmajorticks')
  widget_control,major,get_value=majornum
  
  spd_ui_spinner_get_max_value, major, majormax  
  
  if ~finite(majornum,/nan) then begin
    if majornum gt majormax then begin
      messageString = 'Major ticks number cannot be larger than ' + STRTRIM(string(majormax),2) + ', value reset.'
      statusBar->update,messageString
      historywin->update,messageString, /dontshow
      response=dialog_message(messageString,/CENTER)
      zaxis->getProperty,ticknum=oldticknum
      widget_control,major,set_value=oldticknum
    endif else if majornum lt 0 then begin
      messageString = 'Major ticks number cannot be negative, value reset.'
      statusBar->update,messageString
      historywin->update,messageString, /dontshow
      response=dialog_message(messageString,/CENTER)
      zaxis->getProperty,ticknum=oldticknum
      widget_control,major,set_value=oldticknum
    endif else begin
      zaxis->setProperty,tickNum=majornum
      historyWin->update,'major Ticks Updated',/dontshow
    endelse
  endif else begin
    messageString = 'Invalid number of major ticks, value reset.'
    statusBar->update,messageString
    historywin->update,messageString, /dontshow
    response=dialog_message(messageString,/CENTER)
    zaxis->getProperty,ticknum=oldticknum
    widget_control,major,set_value=oldticknum
  endelse
  
  minor = widget_info(tlb,find_by_uname='nminorticks')
  widget_control,minor,get_value=minornum
  
  spd_ui_spinner_get_max_value, minor, minormax
  
  if ~finite(minornum,/nan) then begin
     if minornum gt minormax then begin
      messageString = 'Minor ticks number cannot be larger than ' + STRTRIM(string(minormax),2) + ', value reset.'
      statusBar->update,messageString
      historywin->update,messageString, /dontshow
      response=dialog_message(messageString,/CENTER)
      zaxis->getProperty,minorTickNum=oldminornum
      widget_control,minor,set_value=oldminornum
    endif else if minornum lt 0 then begin
      messageString = 'Minor ticks number cannot be negative, value reset.'
      statusBar->update,messageString
      historywin->update,messageString, /dontshow
      response=dialog_message(messageString,/CENTER)
      zaxis->getProperty,minorTickNum=oldminornum
      widget_control,minor,set_value=oldminornum
    endif else begin
      zaxis->setProperty,minorTickNum=minornum
      historyWin->update,'Minor Ticks Updated',/dontshow
    endelse
  endif else begin
    messageString = 'Invalid number of minor ticks, value reset.'
    statusBar->update,messageString
    historywin->update,messageString, /dontshow
    response=dialog_message(messageString,/CENTER)
    zaxis->getProperty,minorTickNum=oldminornum
    widget_control,minor,set_value=oldminornum
  endelse
  
  for i = 0,3 do begin
    id = widget_info(tlb,find_by_uname='logminorticktype'+strtrim(i,2))
    if widget_info(id,/button_set) then begin
      zaxis->setProperty,logminorticktype=i
    endif
  endfor
  
end

pro spd_ui_zaxis_color_event,tlb,uname,messagename,historywin,statusbar

  compile_opt idl2,hidden
  
  colorwindow = widget_info(tlb,find_by_uname=uname)
  Widget_Control, colorwindow, Get_Value=colorWin
  ColorWin->getProperty,graphics_tree=scene
  scene->getProperty,color=currcolor
  color = PickColor(!p.color, Group_Leader=tlb, Cancel=cancelled,currentcolor=currcolor)
  if ~cancelled then begin
  
    scene->setProperty,color=reform(color)
    Colorwin->draw
    
    historyWin->Update,messagename + ' color changed.',/dontshow
    statusbar->Update,messagename + ' color changed.'
  endif
  
end


PRO spd_ui_zaxis_options_event, event

  Widget_Control, event.TOP, Get_UValue=state, /No_Copy
  
  ;Put a catch here to insure that the state remains defined
  err_xxx = 0
  Catch, err_xxx
  IF (err_xxx NE 0) THEN BEGIN
    Catch, /Cancel
    Help, /Last_Message, Output = err_msg
    
    spd_ui_sbar_hwin_update, state, err_msg, /error, err_msgbox_title='Error in Z-Axis Options'
    
    Widget_Control, event.TOP, Set_UValue=state, /No_Copy
    widget_control, event.top,/destroy
    RETURN
  ENDIF
  ;kill request block
  
  IF (Tag_Names(event, /Structure_Name) EQ 'WIDGET_KILL_REQUEST') THEN BEGIN
    ; reset values for each z axis
    IF N_Elements(state.zAxes) GE 1 && ~in_set(obj_valid(state.zAxes),'0') THEN BEGIN
      FOR i=0, N_Elements(state.zAxes)-1 DO BEGIN
        state.spectraPanels[i]->Reset
      ENDFOR
    ENDIF
    state.drawObject->Update, state.windowStorage, state.loadedData
    state.drawObject->Draw
    
    ; exit
    dprint, dlevel=4, 'widget killed'
    state.historywin->update,'SPD_UI_ZAXIS_OPTIONS: widget killed'
    state.statusbar->update,'SPD_UI_ZAXIS_OPTIONS: widget killed'
    state.tlb_statusbar->Update, 'Axis Options closed'
    Widget_Control, event.TOP, Set_UValue=state, /No_Copy
    Widget_Control, event.top, /Destroy
    RETURN
  ENDIF
  
  ;redraw palettes and write history about swap
  IF (Tag_Names(event, /Structure_Name) EQ 'WIDGET_TAB') THEN BEGIN
  
  
    Widget_Control, state.zAxisArea, Get_Value=win
    win->Draw
    colorid = widget_info(state.tlb, find_by_uname='tcolor')
    widget_control, colorid, get_value=colorWin
    colorWin->draw
    subcolorid = widget_info(state.tlb, find_by_uname='subtitlecolor')
    widget_control, subcolorid, get_value=subcolorWin
    subcolorWin->draw
    acolorid = widget_info(state.tlb, find_by_uname='acolor')
    widget_control, acolorid, get_value=acolorWin
    acolorWin->draw
    
    state.historywin->update,'SPD_UI_ZAXIS_OPTIONS: tab switched to: ' + $
      strtrim(widget_info(state.tabbase, /tab_current))
    Widget_Control, event.TOP, Set_UValue=state, /No_Copy
    RETURN
  ENDIF
  
  ; Get the instructions from the Widget causing the event and
  ; act on them.
  
  Widget_Control, event.id, Get_UValue=uval
  
  IF Size(uval, /Type) NE 0 THEN BEGIN
    state.historywin->update,'SPD_UI_ZAXIS_OPTIONS: User value: '+uval, /dontshow
    CASE uval OF
      'CANC': BEGIN
        dprint, dlevel=4, 'Panel Widget canceled'
        state.tlb_statusbar->Update, 'Axis Options canceled'
        ; for each panel reset z axis
        IF N_Elements(state.zAxes) GE 1 && ~in_set(obj_valid(state.zAxes),'0') THEN BEGIN
          FOR i=0, N_Elements(state.zAxes)-1 DO BEGIN
            state.spectraPanels[i]->Reset
          ENDFOR
        ENDIF
        state.drawObject->Update, state.windowStorage, state.loadedData
        state.drawObject->Draw
        spd_ui_update_zaxis_from_draw,state.panels,state.drawObject,state.historyWin
        Widget_Control, event.TOP, Set_UValue=state, /No_Copy
        Widget_Control, event.top, /Destroy
        RETURN
      END
      
      'APPLYTOALL': BEGIN
      
        IF Obj_Valid(state.zAxisSettings) && ~in_set(obj_valid(state.zAxes),'0') THEN BEGIN
          spd_ui_zaxis_set_value,state,event
          spd_ui_zaxis_propagate_settings, state
          state.zAxes[state.selectedPanel]=state.zAxisSettings
          state.drawObject->Update, state.windowStorage, state.loadedData,error=draw_error
          
          if draw_error then begin
            state.statusBar->update,'Draw Error, Attempting to revert settings'
            state.historyWin->update,'Draw Error, Attempting to revert settings'
            IF N_Elements(state.zAxes) GE 1 && ~in_set(obj_valid(state.zAxes),'0') THEN BEGIN
              FOR i=0, N_Elements(state.zAxes)-1 DO BEGIN
                state.spectraPanels[i]->Reset
              ENDFOR
            ENDIF
            
            state.drawObject->Update, state.windowStorage, state.loadedData
          endif else begin
            state.statusBar->update,'Changes applied to all Panels.'
            state.historyWin->update,'Changes applied to all Panels.'
          endelse
          
          spd_ui_update_zaxis_from_draw,state.panels,state.drawObject,state.historyWin
          
          spd_ui_zaxis_update,state
          
          state.drawObject->Draw
        ENDIF ELSE BEGIN
          state.statusBar->Update, 'No panels or axes to apply.'
        ENDELSE
      END
      'APPLY': BEGIN
        IF Obj_Valid(state.zAxisSettings) && ~in_set(obj_valid(state.zAxes),'0') THEN BEGIN
          spd_ui_zaxis_set_value,state,event
          state.zAxes[state.selectedPanel]=state.zAxisSettings
          state.drawObject->Update, state.windowStorage, state.loadedData,error=draw_error
          
          if draw_error then begin
            state.statusBar->update,'Draw Error, Attempting to revert settings'
            state.historyWin->update,'Draw Error, Attempting to revert settings'
            IF N_Elements(state.zAxes) GE 1 && ~in_set(obj_valid(state.zAxes),'0') THEN BEGIN
              FOR i=0, N_Elements(state.zAxes)-1 DO BEGIN
                state.spectraPanels[i]->Reset
              ENDFOR
            ENDIF
            
            state.drawObject->Update, state.windowStorage, state.loadedData
          endif else begin
            state.statusBar->update,'Changes applied.'
            state.historyWin->update,'Changes applied.'
          endelse
          
          spd_ui_update_zaxis_from_draw,state.panels,state.drawObject,state.historyWin
          spd_ui_zaxis_update,state
          
          state.drawObject->Draw
        ENDIF ELSE BEGIN
          state.statusBar->Update, 'No panels or axes to apply.'
        ENDELSE
      END
      'OK': BEGIN
        spd_ui_zaxis_set_value,state,event
        state.drawObject->Update, state.windowStorage, state.loadedData,error=draw_error
        
        if draw_error then begin
          state.statusBar->update,'Draw Error, Attempting to revert settings'
          state.historyWin->update,'Draw Error, Attempting to revert settings'
          IF ~in_set(obj_valid(state.zAxes),'0') THEN BEGIN
            FOR i=0, N_Elements(state.zAxes)-1 DO BEGIN
              state.spectraPanels[i]->Reset
            ENDFOR
          ENDIF
          
          state.drawObject->Update, state.windowStorage, state.loadedData
        endif
        
        IF N_Elements(state.zAxes) GE 1 && ~in_set(obj_valid(state.zAxes),'0') THEN BEGIN
          FOR i=0, N_Elements(state.zAxes)-1 DO BEGIN
            state.spectraPanels[i]->setTouched
          ENDFOR
        ENDIF
        
        state.drawObject->Draw
        state.tlb_statusbar->Update, 'Axis Options closed'
        spd_ui_update_zaxis_from_draw,state.panels,state.drawObject,state.historyWin
        Widget_Control, event.TOP, Set_UValue=state, /No_Copy
        Widget_Control, event.top, /Destroy
        RETURN
      END
      'TEMP': begin
      
        ;make sure internal state is updated before save
        spd_ui_zaxis_set_value,state,event
        IF N_Elements(state.zAxes) GE 1 && ~in_set(obj_valid(state.zAxes),'0') THEN BEGIN
          FOR i=0, N_Elements(state.zAxes)-1 DO BEGIN
            state.spectraPanels[i]->setTouched
          ENDFOR
        ENDIF
        if ~in_set(obj_valid(state.zAxes),'0') then begin
          state.zAxes[state.selectedPanel]=state.zAxisSettings
          state.template->setProperty,z_axis=state.zaxisSettings->copy()
          state.historywin->update,'Current z-axis options stored for use in a Template'
          state.statusBar->update,'Current z-axis options stored for use in a Template'

          messageString = 'These values have now been stored!' +  string(10B) + string(10B) + 'To save them in a template, click File->Graph Options Template->Save Template'
          response=dialog_message(messageString,/CENTER, /information)

        endif else begin
          state.statusbar->update,'Cannot store options. Needs a valid spectral panel to store options for a template.'
          state.historywin->update,'Cannot store options. Needs a valid spectral panel to store options for a template.'
        endelse
      ;
      end
      'PANEL': BEGIN
        IF ~in_set(Obj_Valid(state.zAxes),'0') THEN  BEGIN
          spd_ui_zaxis_set_value,state,event
          state.selectedPanel = event.index
          state.zAxisSettings = state.zAxes[event.index]
          spd_ui_zaxis_update, state
          state.statusBar->Update, 'Panel selected'
          state.historywin->Update, 'Panel selected'
        ENDIF
      END
      'RAINBOW':BEGIN
      spd_ui_zaxis_switch_color_table,0,event.top
      state.statusBar->Update, 'Rainbow Color Table selected'
      state.historywin->Update, 'Rainbow Color Table selected'
    END
    'COOL':BEGIN
    spd_ui_zaxis_switch_color_table,1,event.top
    state.statusBar->Update, 'Cool Color Table selected'
    state.historywin->Update, 'Cool Color Table selected'
  END
  'HOT':BEGIN
  spd_ui_zaxis_switch_color_table,2,event.top
  state.statusBar->Update, 'Hot Color Table selected'
  state.historywin->Update, 'Hot Color Table selected'
END
'COPPER':BEGIN
spd_ui_zaxis_switch_color_table,3,event.top
state.statusBar->Update, 'Copper Color Table selected'
state.historywin->Update, 'Copper Color Table selected'
END
'EXTREME HOT-COLD':BEGIN
spd_ui_zaxis_switch_color_table,4,event.top
state.statusBar->Update, 'Extreme Hot-Cold Color Table selected'
state.historywin->Update, 'Extreme Hot-Cold Color Table selected'
END
'GRAY':BEGIN
spd_ui_zaxis_switch_color_table,5,event.top
state.statusBar->Update, 'Gray Color Table selected'
state.historywin->Update, 'Gray Color Table selected'
END
'SPEDAS':BEGIN
spd_ui_zaxis_switch_color_table,6,event.top
state.statusBar->Update, 'SPEDAS Color Table selected'
state.historywin->Update, 'SPEDAS Color Table selected'
END
'FIXED': BEGIN
  ;this code switches sensitivity and fills in the range information
  result = Widget_Info(event.id, /Button_Set)
  ;changing this to fill in the range info when you unset also - to prevent invalid range messages coming
  ; up when the user clicks apply even if FIXED is unset.
  if Obj_Valid(state.spectrapanels[0]) then begin
    ;state.spectrapanels[state.selectedpanel]->getproperty, id=selected
    ;info = state.drawobject->getpanelinfo(selected) - id doesn't correspond to index if panels have been removed
  
    specindex = state.selectedPanel ; index into spectral panels
    full_panel_list = state.panels->get(/all)
    ;loop over panel list and find corresponding index into all panels
    fullindex = 0
    specnum = 0
    while (fullindex lt n_elements(full_panel_list)) && (specnum le specindex) do begin
      full_panel_list[fullindex]->getProperty,zaxis=zaxis
      fullindex++
      if ~obj_valid(zaxis) then continue
      specnum ++
    endwhile
    info = state.drawobject->getpanelinfo(fullindex-1)
    case info.zscale of
      '0':begin
      widget_control, state.rangeminincrement, set_value=info.zrange[0]
      widget_control, state.rangemaxincrement, set_value=info.zrange[1]
      state.zaxissettings->setproperty, minrange=info.zrange[0]
      state.zaxissettings->setproperty, maxrange=info.zrange[1]
    end
    '1':begin
    widget_control, state.rangeminincrement, set_value=10^info.zrange[0]
    widget_control, state.rangemaxincrement, set_value=10^info.zrange[1]
    state.zaxissettings->setproperty, minrange=10^info.zrange[0]
    state.zaxissettings->setproperty, maxrange=10^info.zrange[1]
  end
  '2':begin
  widget_control, state.rangeminincrement, set_value=exp(info.zrange[0])
  widget_control, state.rangemaxincrement, set_value=exp(info.zrange[1])
  state.zaxissettings->setproperty, minrange=exp(info.zrange[0])
  state.zaxissettings->setproperty, maxrange=exp(info.zrange[1])
end
endcase
endif
IF result EQ 1 THEN BEGIN
  Widget_Control, state.rangeMinIncrement, Sensitive=1
  Widget_Control, state.rangeMaxIncrement, Sensitive=1
ENDIF ELSE BEGIN
  Widget_Control, state.rangeMinIncrement, Sensitive=0
  Widget_Control, state.rangeMaxIncrement, Sensitive=0
ENDELSE
END
'PALETTE': BEGIN
  spd_ui_zaxis_color_event,event.top,'tcolor','Title Color',state.historyWin,state.statusBar
END
'SUBTITLEPALETTE': BEGIN
  spd_ui_zaxis_color_event,event.top,'subtitlecolor','Subtitle Color',state.historyWin,state.statusBar
END
'APALETTE': BEGIN
  spd_ui_zaxis_color_event,event.top,'acolor','Annotation Color',state.historyWin,state.statusBar
END
'AUTOTICKS':BEGIN
  id = widget_info(event.top,find_by_uname='nminorticks')
  widget_control,id,sensitive=~event.select
  id = widget_info(event.top,find_by_uname='nmajorticks')
  widget_control,id,sensitive=~event.select
  
  state.statusBar->Update, 'Automatic Ticks toggled
  state.historywin->Update, 'Automatic Ticks toggled',/dontshow
END
'LINEAR': begin
  id = widget_info(event.top,find_by_uname='logminorticktypebase')
  widget_control,id,sensitive=0
  ;Note that although the minimum is set to 0, 0 itself is not a valid value and must be checked for.
  minid = widget_info(event.top,find_by_uname='minimum')
  spd_ui_spinner_set_min_value, minid, !values.d_nan
  maxid = widget_info(event.top,find_by_uname='maximum')
  spd_ui_spinner_set_min_value, maxid, !values.d_nan
  state.statusBar->Update, 'Linear Scaling selected'
  state.historywin->Update, 'Linear Scaling selected'
end
'LOG10': begin
  id = widget_info(event.top,find_by_uname='logminorticktypebase')
  widget_control,id,sensitive=1
  ;Note that although the minimum is set to 0, 0 itself is not a valid value and must be checked for.
  minid = widget_info(event.top,find_by_uname='minimum')
  spd_ui_spinner_set_min_value, minid, 0
  maxid = widget_info(event.top,find_by_uname='maximum')
  spd_ui_spinner_set_min_value, maxid, 0
  state.statusBar->Update, 'Log 10 Scaling selected'
  state.historywin->Update, 'Log 10 Scaling selected'
end
'NATLOG': begin
  id = widget_info(event.top,find_by_uname='logminorticktypebase')
  widget_control,id,sensitive=1
  ;Note that although the minimum is set to 0, 0 itself is not a valid value and must be checked for.
  minid = widget_info(event.top,find_by_uname='minimum')
  spd_ui_spinner_set_min_value, minid, 0
  maxid = widget_info(event.top,find_by_uname='maximum')
  spd_ui_spinner_set_min_value, maxid, 0
  state.statusBar->Update, 'Natural Log Scaling selected'
  state.historywin->Update, 'Natural Log Scaling selected'
end
ELSE :
ENDCASE
ENDIF

Widget_Control, event.TOP, Set_UValue=state, /No_Copy

RETURN
END ;--------------------------------------------------------------------------------



PRO spd_ui_zaxis_options, gui_id, windowStorage, zaxisSettings, drawObject, loadedData,historywin,template, tlb_statusbar, panel_select;=panel_select

  ; kill top base in case of init error
  catch, err
  if err ne 0 then begin
    catch, /cancel
    
    help, /last_message, output=err_msg
    for i = 0, N_Elements(err_msg)-1 do historywin->update,err_msg[i]
    print, 'Error--See history'
    ok = error_message('An error occured while starting Z-Axis Options.',$
      /noname, /center, title='Error in Z-Axis Options')
      
    widget_control, tlb, /destroy
    
    spd_gui_error, gui_id, historywin
    
    return
  endif
  
  tlb_statusbar->Update,'Axis Options opened'
  ; build top level and main tab bases
  
  tlb = Widget_Base(/Col, title='Z Axis Options ', Group_Leader=gui_id, $
    /Modal, /Floating, /TLB_KILL_REQUEST_EVENTS, tab_mode=1)
    
  ; Z Axis Bases
    
  tabBase = Widget_Tab(tlb, Location=location)
  buttonBase = Widget_Base(tlb, /Row, /align_center)
  statusBase = Widget_Base(tlb, /Row, /align_center)
  settingsBase = Widget_Base(tabBase, Title='Settings', /Col)
  textBase = Widget_Base(tabBase, Title='Title', /Col)
  annoBase = Widget_Base(tabBase, Title='Annotations',/Col)
  
  ; Settings Bases
  
  panelsBase = Widget_Base(settingsBase, /Row)
  middleBase = Widget_Base(settingsBase, /Row)
  col1Base = Widget_Base(middleBase, /Col, ypad=6, space=2)
  colorTableBase = Widget_Base(col1Base, /Col)
  colorFrameBase = Widget_Base(col1Base, /Col, /Exclusive, Frame=3)
  rangeLabelBase = Widget_Base(col1Base, /Col)
  rangeFrameBase = Widget_Base(col1Base, /Col, Frame=3, YPad=5)
  col2Base = Widget_Base(middleBase, /Col, XPad=10, space=2)
  scalingLabelBase = Widget_Base(col2Base, /Col)
  scalingBase = Widget_Base(col2Base, /col, Frame=3, /Exclusive)
  placementLabelBase = Widget_Base(col2Base, /Col)
  placementBase = Widget_Base(col2Base, /Col, Frame=3, /Exclusive)
  autotickBase = widget_base(col2Base,/col,/align_left,/nonexclusive)
  tickBase = Widget_Base(col2Base, /col, /align_right, ypad=4,frame=1,uname='ticksbase')
  ;anoLabelBase = Widget_Base(col2Base, /Col)
  ;anoBase = Widget_Base(col2Base, /Col, Frame=3)
  marginBase = Widget_Base(col2Base, /col, /align_right)
  col3Base = Widget_Base(middleBase, /Col, YPad=4, XPad=5)
  bottomBase = widget_base(settingsBase, /col, /align_center)
  
  
  ; Text Bases
  
  tpanelsBase = Widget_Base(textBase, /Row)
  labelBase = Widget_Base(textBase, /Col)
  
  ; Annotation Bases
  apanelsBase = Widget_Base(annoBase, /Row)
  annotationBase = Widget_base(annoBase, /Col, space=10, ypad=20)
  
  ;retrieve data zaxis, and panel info for display
  validzaxes = 1
  activeWindow = windowStorage->GetActive()
  IF ~Obj_Valid(activeWindow) THEN BEGIN
    panelNames=['No Panels']
    validzaxes = 0
  ENDIF ELSE BEGIN
    activeWindow->GetProperty, Panels=panels
    IF ~Obj_Valid(panels) THEN BEGIN
      panelNames=['No Panels']
      validzaxes = 0
    ENDIF ELSE BEGIN
      panelObjs = panels->Get(/all)
      IF Is_Num(panelObjs) THEN BEGIN
        panelNames=['No Panels']
        validzaxes = 0
      ENDIF ELSE BEGIN
        FOR i=0, N_Elements(panelObjs)-1 DO BEGIN
          panelObjs[i]->Save
          panelObjs[i]->GetProperty, Name=name, ZAxis=zaxis
          IF Obj_Valid(zAxis) THEN BEGIN
            activeWindow->getproperty, locked = locked
            lockPrefix = i eq locked ? '(L)  ':''
            name = lockPrefix + panelObjs[i]->constructPanelName()
            zAxis->Save
            IF Size(panelNames, /type) EQ 0 THEN BEGIN
              panelNames=[name]
              spectraPanels=[panelObjs[i]]
              zAxes=[zAxis]
            ENDIF ELSE BEGIN
              panelNames=[panelNames, name]
              spectraPanels=[spectraPanels, panelObjs[i]]
              zAxes=[zAxes, zAxis]
            ENDELSE
            
            if n_elements(panel_select) gt 0 && i eq panel_select then begin
              selected_zpanel = n_elements(panelNames)-1
            endif
            
          ENDIF
        ENDFOR
      ENDELSE
    ENDELSE
    IF Size(panelNames, /type) EQ 0 THEN BEGIN
      panelNames=['No Panels with Z Axes']
      validzaxes = 0
      zAxes=-1
    ENDIF
    IF Is_Num(panelNames) THEN BEGIN
      panelNames=['No Panels with Z Axes']
      validzaxes = 0
      zAxes=-1
    ENDIF
    IF N_Elements(panelNames) EQ 1 && panelNames EQ '' THEN BEGIN
      panelNames=['No Panels with Z Axes']
      validzaxes = 0
      zAxes=-1
    ENDIF
  ENDELSE
  ; desensitise all options when no valid panels with z axes exist
  ; Note that some particular parts are desensitized further down in code.
  if ~validzaxes then begin
    widget_control, colorFrameBase, sensitive = 0
    widget_control, rangeFrameBase, sensitive = 0
    widget_control, scalingBase, sensitive = 0
    widget_control, placementBase, sensitive = 0
    widget_control, autotickBase, sensitive = 0
    widget_control, marginBase, sensitive = 0
    
  endif
  
  if size(selected_zpanel, /type) eq 0 then selected_zpanel = 0
  
  IF Size(spectraPanels, /type) NE 0 && Obj_Valid(spectraPanels[0]) $
    THEN spectraPanels[selected_zpanel]->GetProperty, ZAxis=zAxisSettings $
  ELSE spectraPanels=-1
  
  IF ~Obj_Valid(zAxisSettings) THEN zAxisSettings=Obj_New("SPD_UI_ZAXIS_SETTINGS")
  
  zAxisSettings->GetProperty, $
    ColorTable=colortable, $
    Fixed=fixed, $
    MinRange=minrange, $
    MaxRange=maxrange, $
    Scaling=scaling, $
    Placement=placement, $
    TickNum=ticknum, $
    minorTickNum=minorTickNum,$
    Margin=margin, $
    LabelTextObject=labeltextobject, $
    LabelMargin=labelmargin, $
    AnnotateTextObject=annotatetextobject, $
    LabelOrientation=labelorientation, $
    AnnotationOrientation=annotationorientation,$
    annotationStyle=annotationStyle, $
    annotateExponent=annotateExponent
    
  IF ~Obj_Valid(labeltextobject) THEN labeltextobject=Obj_New("SPD_UI_TEXT")
  IF ~Obj_Valid(annotatetextobject) THEN annotatetextobject=Obj_New("SPD_UI_TEXT")
  
  ;widgets for Settings Tab
  
  plabel = Widget_Label(panelsBase, value='Panel: ')
  sxaxisDroplist = Widget_combobox(panelsBase, $
    Value=panelNames, UValue='PANEL', uname = 'sPanels')
    
  ;swap the default, if necessary
  if keyword_set(selected_zpanel) then begin
  
    widget_control,sxaxisDroplist,set_combobox_select=selected_zpanel
    
  endif else begin
  
    selected_zpanel = 0
    
  endelse
  
  colorTableLabel = Widget_Label(colorTableBase, Value ='Color Table:')
  colorTableNames = zaxisSettings->GetColorTables()
  colorTableButtons = make_array(N_Elements(colorTableNames), /Long)
  FOR i=0,N_Elements(colorTableNames)-1 DO BEGIN
    colorTableButtons[i]= Widget_Button(colorFrameBase, Value=colorTableNames[i], $
      UValue=StrUpCase(colorTableNames[i]),uname=colorTableNames[i])
  ENDFOR
  Widget_Control, colorTableButtons[colortable], /Set_Button
  rangeLabelLabel =  Widget_Label(rangeLabelBase, Value ='Range:')
  fixedBase =  Widget_Base(rangeFrameBase, /Row, /nonexclusive)
  fixedButton=Widget_Button(fixedBase, Value='Fixed Min/Max', /align_center, UValue='FIXED',uname='fixed')
  IF fixed EQ 1 THEN Widget_Control, fixedButton, /Set_Button
  IF fixed EQ 1 THEN sensitive=1 ELSE sensitive=0
  
  ;attempt to align spinner labels
  ;on mac/linux widgets may be right aligned regardless of alignment keywords on parent base
  rangeMinIncrement = spd_ui_spinner(rangeFrameBase, label= 'Min:  ', Value=minRange, $
    text_box_size=12, getxlabelsize=xms, UValue='MINR', sensitive=sensitive,uname='minimum')
  rangeMaxIncrement = spd_ui_spinner(rangeFrameBase, label= 'Max:  ', Value=maxRange, $
    text_box_size=12, xlabelsize=xms, UValue='MAXR', sensitive=sensitive,uname='maximum')
    
  scalingLabel = Widget_Label(scalingLabelBase, Value='Scaling:')
  slinearButton = Widget_Button(scalingBase, Value= 'Linear', UValue='LINEAR',uname='linear')
  slogButton = Widget_Button(scalingBase, Value= 'Log 10', UValue='LOG10',uname='log10')
  snatButton = Widget_Button(scalingBase, Value= 'Natural Log', UValue='NATLOG',uname='natural')
  IF scaling EQ 0 THEN Widget_Control, slinearButton, /Set_Button
  IF scaling EQ 1 THEN Widget_Control, slogButton, /Set_Button
  IF scaling EQ 2 THEN Widget_Control, snatButton, /Set_Button
  
  ;Note that although the minimum is set to 0, 0 is still not a valid value and must be checked for.
  if scaling gt 0 then begin
    spd_ui_spinner_set_min_value, rangeMinIncrement, 0
    spd_ui_spinner_set_min_value, rangeMaxIncrement, 0
  endif else begin
    spd_ui_spinner_set_min_value, rangeMinIncrement, !values.d_nan
    spd_ui_spinner_set_min_value, rangeMaxIncrement, !values.d_nan
  endelse
  placementLabel = Widget_Label(placementLabelBase, Value='Colorbar Placement:')
  placeValues = zaxisSettings->GetPlacements()
  plinearButtons = make_array(N_Elements(placeValues), /Long)
  FOR i=0,N_Elements(placeValues)-1 DO BEGIN
    plinearButtons[i]=Widget_Button(placementBase, Value=placeValues[i], UValue=Strupcase(placeValues[i]),uname=placeValues[i])
  ENDFOR
  Widget_Control, plinearButtons[placement], /Set_Button
  
  autobutton = widget_button(autotickbase,value='Automatic Ticks',uname='autoticks',UVALUE='AUTOTICKS')
  
  ticknum = spd_ui_spinner(tickBase, label= 'Major Ticks(#):  ', Increment=1, Value=ticknum, UValue='NTICKS',uname='nmajorticks',min_value=0,max_value=100)
  minorTickNum = spd_ui_spinner(tickBase, label= 'Minor Ticks(#):  ', Increment=1, Value=minorticknum, UValue='NMINORTICKS',uname='nminorticks',min_value=0,max_value=100)
  margin = spd_ui_spinner(marginBase, label= 'Colorbar Margin:  ', Increment=1, Value=margin, $
    uval='MARGIN', /all_events,sensitive=barmarginsensitive,uname='margin',min_value=0)
    
  minorLogTickTypeBase = widget_base(bottomBase,/col,/frame,/base_align_center)
  minorLogTickTypeLabelBase = widget_base(minorLogTickTypeBase,/base_align_center,/row)
  minorLogTickTypeLabel = widget_label(minorLogTickTypeLabelBase,value="Log Minor Tick Type:",/align_center)
  minorLogTickTypeButtonBase = widget_base(minorLogTickTypeBase,/exclusive,/row,uname='logminorticktypebase')
  minorLogTickType0 = widget_button(minorLogTickTypeButtonBase,value='Full Interval',uname='logminorticktype0')
  minorLogTickType1 = widget_button(minorLogTickTypeButtonBase,value='First Magnitude',uname='logminorticktype1')
  minorLogTickType2 = widget_button(minorLogTickTypeButtonBase,value='Last Magnitude',uname='logminorticktype2')
  minorLogTickType3 = widget_button(minorLogTickTypeButtonBase,value='Even Spacing',uname='logminorticktype3')
  
  lowerBase = widget_base(bottomBase, /col, /align_center, ypad=4, /nonexclusive)
  
  ; Text Tab Widgets
  
  tplabel = WIDGET_LABEL(tpanelsBase, value = 'Panel: ')
  txaxisDroplist = Widget_combobox(tpanelsBase, $
    Value=panelNames, UValue='PANEL', uname = 'tPanels')
  widget_control,txaxisDroplist,set_combobox_select=selected_zpanel
  textLabel = Widget_Label(labelBase, value = 'Text:', /align_left)
  labelFrame = Widget_Base(labelBase, /col, frame=3, sensitive = validzaxes)
  
  styleNames = zaxisSettings->GetAnnotations()
  textObj = Obj_New("SPD_UI_TEXT")
  fontNames = textObj->GetFonts()
  formatNames = textObj->GetFormats()
  Obj_Destroy, textObj
  
  titlecolBase = widget_base(labelFrame,/col)
  titleeditBase = widget_base(titlecolbase,/row, ypad=1,/base_align_center)
  titleeditbasecol1 = widget_base(titleeditBase, /col, /base_align_left);, space=20, ypad=6)
  titleeditbasecol2 = widget_base(titleeditbase, /col, /base_align_left);, space=12)
  titletextlabel = widget_label(titleeditbasecol1, value='Title:', /align_left)
  zAxisSettings->GetProperty, LabelTextObject=labeltextobject
  IF Obj_Valid(labeltextobject) THEN labeltextobject->GetProperty, Value=labelValue ELSE labelValue=''
  titletextfield = widget_text(titleeditBasecol2, value = labelvalue, /editable, /all_events, xsize=55, ysize=1, $
    uval='TEXT', uname='text')
    
  titlerow1base = widget_base(titlecolbase,/row, xpad=40,/base_align_center);, ypad=10)
  titlelabel1base = widget_base(titlerow1base,/col,/base_align_left, space=20, ypad=6);, xpad=30)
  titlefield1base = widget_base(titlerow1base,/col,/base_align_left, space=12)
  titlelabel2base = widget_base(titlerow1base,/col,/base_align_left, space=20, ypad=6)
  titlefield2base = widget_base(titlerow1base,/col,/base_align_left, space=6)
  tlabel = Widget_Label(titlelabel1Base, value = 'Font:')
  fontDroplist = Widget_combobox(titlefield1Base, Value=fontnames, uval='FONT', uname='tfont')
  
  IF ~Obj_Valid(labelTextObject) THEN BEGIN
    font = 0
    format = n_elements(formatnames)-1  ;correct for no formatting
    size=12
    color=[0,0,0]
  ENDIF ELSE BEGIN
    labeltextobject->GetProperty, Font=font, Format=format, Size=size, Color=color
  ENDELSE
  Widget_Control, fontDroplist, Set_combobox_Select=font
  
  tlabel = Widget_Label(titlelabel1Base, value = 'Format:')
  formatDroplist = Widget_combobox(titlefield1Base, Value=formatnames, uval='FORMAT', uname='tformat')
  IF format eq -1 then format=n_elements(formatnames)-1   ; correct for no formating
  Widget_Control, formatDroplist, Set_combobox_Select=format
  tlabel= Widget_Label(titlelabel2Base, value='Size (points): ', /align_left)
  fontIncrement = spd_ui_spinner(titlefield2Base, Increment=1,  Value=size, uval='SIZE', uname='tsize', min_value=1)
  tlabel= Widget_Label(titlelabel2Base, value='Color: ', /align_left)
  titlecolorBase = Widget_Base(titlefield2Base, /row, xpad=0, /base_align_center)
  
  getresourcepath,rpath
  palettebmp = read_bmp(rpath + 'color.bmp', /rgb)
  spd_ui_match_background, tlb, palettebmp
  
  titlepaletteButton = Widget_Button(titlecolorBase, Value=palettebmp, /Bitmap, UValue='PALETTE', uname='titlepalette', $
    Tooltip='Choose color from Palette')
  colorWindow = WIDGET_DRAW(titlecolorBase, graphics_level=2, renderer=1, retain=1, XSize=50, YSize=20, units=0, frame=1, $
    uname = 'tcolor', /expose_events)
  ;-------- subtitle
  subtitleeditBase = widget_base(titlecolbase,/row, ypad=1,/base_align_center)
  subtitleeditbasecol1 = widget_base(subtitleeditBase, /col, /base_align_left);, space=20, ypad=6)
  subtitleeditbasecol2 = widget_base(subtitleeditbase, /col, /base_align_left);, space=12)
  subtitletextlabel = widget_label(subtitleeditbasecol1, value='Subtitle:',/align_left)
  subtitletextfield = widget_text(subtitleeditbasecol2, value='',/editable, /all_events, xsize=55, ysize=1,$
    uval='SUBTITLETEXT',uname='subtitletext')
  ;
  subtitlerow1base = widget_base(titlecolbase,/row, xpad=40,/base_align_center);, ypad=10)
  subtitlelabel1base = widget_base(subtitlerow1base,/col,/base_align_left, space=20, ypad=6);, xpad=30)
  subtitlefield1base = widget_base(subtitlerow1base,/col,/base_align_left, space=12)
  subtitlelabel2base = widget_base(subtitlerow1base,/col,/base_align_left, space=20, ypad=6)
  subtitlefield2base = widget_base(subtitlerow1base,/col,/base_align_left, space=6)
  subtlabel = Widget_Label(subtitlelabel1Base, value = 'Font:')
  sublpofontDroplist = Widget_combobox(subtitlefield1Base, Value=fontnames, uval='SUBTITLEFONT', uname='subtitlefont')
  subtlabel = Widget_Label(subtitlelabel1Base, value = 'Format:')
  subtitleFormatDroplist = Widget_combobox(subtitlefield1Base, Value=formatnames, uval='SUBTITLEFORMAT', uname='subtitleformat')
  
  subtlabel= Widget_Label(subtitlelabel2Base, value='Size (points): ', /align_left)
  subfontIncrement = spd_ui_spinner(subtitlefield2Base, Increment=1,  Value=12, uval='SUBTITLESIZE', uname='subtitlesize', min_value=1)
  ;
  ;
  subtlabel= Widget_Label(subtitlelabel2Base, value='Color: ', /align_left)
  subtitlecolorBase = Widget_Base(subtitlefield2Base, /row, xpad=0, /base_align_center)
  subtitlepaletteButton = Widget_Button(subtitlecolorBase, Value=palettebmp, /Bitmap, UValue='SUBTITLEPALETTE', uname='subtitlepalette', $
    Tooltip='Choose color from Palette')
  subtitleColorWindow = WIDGET_DRAW(subtitlecolorBase, graphics_level=2, renderer=1, retain=1, XSize=50, YSize=20, units=0, frame=1, $
    uname = 'subtitlecolor', /expose_events)
  ;
    
  placeLabel = Widget_Label(labelBase, value = 'Placement:', /align_left)
  placementFrame = Widget_Base(labelBase, /col, frame=3, sensitive = validzaxes)
  placementrow1 = widget_base(placementframe,/row, xpad=1)
  lazybase = widget_base(placementrow1, /nonexclusive)
  lazylabels = widget_button(lazybase, value='Lazy Labels', uval='LAZY', uname='lazy', $
    tooltip='Converts underscores in labels to new lines')
  orientationBase = Widget_Base(placementFrame, /row, xpad=1)
  labelcolumn = widget_base(orientationbase,/col, /base_align_left, ypad=2, space=12)
  fieldcolumn = widget_base(orientationbase,/col, /base_align_left)
  orientationlabelrow = widget_base(labelcolumn, /row)
  orientationLabel = Widget_Label(orientationlabelrow, value='Orientation: ', /align_center)
  orientBase = Widget_Base(fieldcolumn, /row, /exclusive,space=50, /align_center)
  horizontalButton = Widget_Button(orientBase, value='Horizontal', UValue='HORIZ',uname='thoriz')
  verticalButton = Widget_Button(orientBase, value='Vertical', UValue='VERT',uname='tvert')
  IF labelorientation EQ 0 THEN Widget_Control, horizontalButton, /Set_Button $
  ELSE Widget_Control, verticalButton, /Set_Button
  
  ;placementrow3 = widget_base(placementFrame,/row, xpad=1)
  marglabelrow = widget_base(labelcolumn, /row)
  margLabel=Widget_Label(marglabelrow, value='Label Margin (pts): ',/align_center)
  margABase = Widget_Base(fieldcolumn, /Row,/align_left)
  labelmarg = spd_ui_spinner(margABase, Increment=1, Value=labelmargin, uval='LABELMARGIN', $
    /all_events,sensitive=labelmarginsensitive,uname='tmargin', min_value=0,/align_center)
    
  ; Annotations tab
    
  aplabel = WIDGET_LABEL(apanelsBase, value = 'Panel: ')
  aaxisDroplist = Widget_combobox(apanelsBase, $
    Value=panelNames, UValue='PANEL', uname = 'aPanels')
  widget_control,aaxisDroplist,set_combobox_select=selected_zpanel
  
  anoLabel = Widget_Label(annotationBase, value = 'Annotation:', /align_left)
  anoFrameBase = Widget_Base(annotationBase, /col, frame=3, sensitive = validzaxes)
  afontBase = Widget_Base(anoFrameBase, /row, space=3)
  afcol1Base = Widget_Base(afontBase, /col, space=17)
  afcol2Base = Widget_Base(afontBase, /col, space=6)
  afcol3Base = Widget_Base(afontBase, /col, space=17)
  afcol4Base = Widget_Base(afontBase, /col, space=4)
  afontLabel=Widget_Label(afcol1Base, value='Font: ', /align_left)
  annotatetextobject->GetProperty, Font=font, Format=format, Size=size, Color=acolor
  afontDroplist = Widget_combobox(afcol2Base, Value=fontNames, UValue='AFONT',uname='afont')
  Widget_Control, afontDroplist, Set_combobox_Select=font
  aincLabel=Widget_Label(afcol3Base, value='Size(pts) : ', /align_left)
  afontIncrement = spd_ui_spinner(afcol4Base, Increment=1, Value=size, UValue='ASIZE',uname='asize', min_value=1)
  acolorBase = Widget_Base(afcol4Base, /row, space=1)
  aformatLabel=Widget_Label(afcol1Base, value='Format: ', /align_left)
  aformatDroplist = Widget_combobox(afcol2Base, Value=formatNames, UValue='AFORMAT',uname='aformat')
  Widget_Control, aformatDroplist, Set_combobox_Select=format
  acolorLabel = Widget_Label(afcol3Base, Value='Color: ', /align_left)
  apaletteButton = Widget_Button(acolorBase, Value=palettebmp, /bitmap, $
    UValue='APALETTE', Tooltip='Choose color from Palette')
  spaceLabel = Widget_Label(acolorBase, Value=' ')
  acolorWindow = WIDGET_DRAW(acolorBase, graphics_level=2,renderer=1, retain=1,  XSize=50, YSize=21, units=0, frame=1,uname='acolor',/expose_events)
  
  anoSOBase = widget_base(anoFrameBase, /row, /exclusive, ypad=2, space=0)
  default = widget_button(anoSOBase, value = 'Auto-Notation', uvalue='AAUTO', uname='aauto')
  dbl = widget_button(anoSOBase, value = 'Decimal Notation', uvalue='ADBL', uname='adbl')
  expo = widget_button(anoSOBase, value = 'Scientific Notation', uvalue='AEXP', uname = 'aexp')
  
  atype = [default, dbl, expo]
  widget_control, atype[annotateExponent], /set_button
  
  
  aorientationBase = Widget_Base(anoFrameBase, /row, xpad=5)
  aorientationLabel = Widget_Label(aorientationBase, value='Orientation: ', /align_left)
  aorientBase = Widget_Base(aorientationBase, /row, /exclusive, frame=3, ypad=3)
  ahorizontalButton = Widget_Button(aorientBase, value='Horizontal', UValue='AHORIZ',uname='ahoriz')
  averticalButton = Widget_Button(aorientBase, value='Vertical', UValue='AVERT',uname='avert')
  
  IF annotationorientation EQ 0 THEN Widget_Control, ahorizontalButton, /Set_Button $
  ELSE Widget_Control, averticalButton, /Set_Button
  annotationsBase=Widget_Base(aorientationBase, /row)
  annotationsLabel=Widget_Label(afcol1Base, value='Annotation Precision: ', /align_left)
  annotations=zAxisSettings->GetAnnotations()
  annotationDroplist=Widget_combobox(afcol2Base, value=annotations, uValue='ANNOTATIONFORMAT',uname='astyle')
  widget_control,annotationDroplist,set_combobox_select=annotationstyle
  
  
  sampleLabel = Widget_Label(col3Base, Value='Sample:')
  specAreaBase = Widget_Base(col3Base, /Row)
  colorBase = widget_base(specAreaBase,frame=1)
  zaxisArea = Widget_Draw(colorBase,uname='colorbar',graphics_level=2,xsize=24,ysize=295,renderer=1,retain=1,/expose_events)
  
  ; colorBar = Obj_New("COLORBAR", Title='Colorbar Values', Vertical=1, Position=[0,0,1,1])
  
  okButton = Widget_Button(buttonBase, Value='OK', UValue='OK')
  applyButton = Widget_Button(buttonBase, Value='Apply', UValue='APPLY')
  applyToAllButton = Widget_Button(buttonBase, Value='Apply to All Panels', $
    Uvalue='APPLYTOALL', tooltip='Apply settings from the current tab to all panels')
  cancelButton = Widget_Button(buttonBase, Value='Cancel', UValue='CANC')
  templateButton = Widget_Button(buttonBase, Value='Store for a Template', UValue='TEMP',tooltip='Use these settings when saving a Graph Options Template')
  
  IF N_Elements(zAxes) GE 1 && ~in_set(obj_valid(zaxes),'0') THEN BEGIN
    FOR i=0, N_Elements(zAxes)-1 DO BEGIN
      zOrig = zAxes[i]->Copy()
      IF i EQ 0 THEN zOriginals=[zOrig] ELSE zOriginals=[zOriginals,zOrig]
    ENDFOR
  ENDIF ELSE BEGIN
    zOriginals=-1
    zAxes=-1
  ENDELSE
  
  statusBar = Obj_New('SPD_UI_MESSAGE_BAR', statusBase, XSize=75, YSize=1)
  
  ;NOTE TO FUTURE DEVELOPERS
  ;Any modifications should port over to not including the value in the state
  ;and using a uname/find_by_uname paradigm.
  state = {tlb:tlb, gui_id:gui_id, winID:0, tabBase:tabBase, panelNames:panelNames, zaxisSettings:zaxisSettings, statusBar:statusBar, $
    rangeMinIncrement:rangeMinIncrement, rangeMaxIncrement:rangeMaxIncrement, $
    atype:atype, $
    spectraPanels:spectraPanels,panels:panels, colorTableButtons:colorTableButtons, fixedButton:fixedButton, $
    slinearButton:slinearButton, slogButton:slogButton, snatButton:snatButton, $
    plinearButtons:plinearButtons, selectedPanel:selected_zpanel, $
    colorTable:colorTable, zAxisArea:zAxisArea, drawObject:drawObject, loadedData:loadedData, $
    windowStorage:windowStorage, zAxes:zAxes, zOriginals:zOriginals, panelObjs:panelObjs, historywin:historywin,template:template, tlb_statusbar:tlb_statusbar}
    
  Widget_Control, tlb, Set_UValue=state, /No_Copy
  CenterTLB, tlb
  Widget_Control, tlb, /Realize
  
  Widget_Control, tlb, Get_UValue=state, /No_Copy
  
; the following call to update was commented out 9/30/2014
; by Eric Grimes; seems unnecessary, and calls to 
; the update method of the draw object are very expensive
  ;guarantee accurate settings are presented in panel
 ; state.drawObject->update, state.windowStorage, state.loadedData
 ; state.drawObject->draw
  spd_ui_update_zaxis_from_draw,state.panels,state.drawObject,state.historyWin
  
  spd_ui_zaxis_init_color, State=state
  spd_ui_zaxis_update,state
  Widget_Control, tlb, Set_UValue=state, /No_Copy
  
  ;keep windows in X11 from snaping back to
  ;center during tree widget events
  if !d.NAME eq 'X' then begin
    widget_control, tlb, xoffset=0, yoffset=0
  endif
  
  historywin->update,'SPD_UI_ZAXIS_OPTIONS: Panel started.'
  
  XManager, 'spd_ui_zaxis_options', tlb, /no_block
  
  RETURN
END
