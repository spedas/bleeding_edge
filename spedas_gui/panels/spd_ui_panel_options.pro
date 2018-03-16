;+
;NAME:
; spd_ui_panel_options
;PURPOSE:
; A widget interface for selecting data
;CALLING SEQUENCE:
; spd_uifile, master_widget_id
;INPUT:
; master_widget_id = the id number of the widget that calls this
;OUTPUT:
; none, there are buttons to push for plotting, setting limits, not
; sure what else yet...
;HISTORY:
;
;(lphilpott 06/2011) Delayed the handling of spinner events until user clicks OK/APPLY/SET ALL or changes panel. Dialog messages
;are issued for invalid entries. This avoids the issue of the text overwriting in spinners as the user types if values aren't valid.
;
;$LastChangedBy: nikos $
;$LastChangedDate: 2018-03-15 14:14:59 -0700 (Thu, 15 Mar 2018) $
;$LastChangedRevision: 24892 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/spedas_gui/panels/spd_ui_panel_options.pro $
;
;--------------------------------------------------------------------------------


pro spd_ui_panel_update,tlb,state=state, nodraw=nodraw

  compile_opt idl2, hidden
  
  statedef = ~(~size(state,/type))
  
  if ~statedef then begin
    Widget_Control, tlb, Get_UValue=state, /No_Copy  ;Only get STATE if it is not passed in.
  endif else begin
    tlb = state.tlb
  endelse
  
  ;make sure settings are copied
  spd_ui_init_panel_options,tlb,state=state
  
  if ~keyword_set(nodraw) then begin
      ;now update
      state.drawObject->update,state.windowStorage,state.loadedData, errmsg=errmsg
      ; Issue a dialog message to user if an important error has occured.
      ; Note: not every drawObject error will return an errmsg structure.
      if keyword_set(errmsg) then begin
        if in_set('TYPE', tag_names(errmsg)) then begin
          if strupcase(errmsg.type) eq 'ERROR' then begin
            if in_set('VALUE', tag_names(errmsg)) then begin
              ok = dialog_message('Error: '+errmsg.value,/center)
            endif
          endif
        endif
      endif
      state.drawObject->draw
  endif
  
  ;now update panel coordinates with current info
  for i = 0,n_elements(state.panelObjs)-1 do begin
  
    info = state.drawObject->getPanelInfo(i)
    
    if is_struct(info) && obj_valid(state.panelObjs[i]) then begin
      newsize = state.drawObject->getpanelsize(info.xpos,info.ypos)
      state.panelObjs[i]->setPanelCoordinates,newsize
    endif
    
  endfor
  
  ;Mutate any structures to reflect current display settings
  spd_ui_init_panel_options,tlb,state=state
  
  if ~statedef then Widget_Control, tlb, Set_UValue=state, /No_Copy   ;Only put STATE if it was not passed in.
  
end

pro spd_ui_init_panel_options, tlb, state=state

  compile_opt idl2, hidden
  
  statedef = ~(~size(state,/type))
  
  if ~statedef then begin
    Widget_Control, tlb, Get_UValue=state, /No_Copy  ;Only get STATE if it is not passed in.
  endif else begin
    tlb = state.tlb
  endelse
  
  ; Get currently selected panel object and settings
  cpanel = state.panelobjs[*state.panel_select]
  IF ~Obj_Valid(cpanel) THEN BEGIN
    traceSettings=Obj_New('SPD_UI_LINE_SETTINGS')
    panelSettings=Obj_New('SPD_UI_PANEL_SETTINGS')
    panelSettings->GetProperty, titleobj=panelTitle
    sensitive = 0
  ENDIF ELSE BEGIN
    sensitive = 1
    cpanel->GetProperty, traceSettings=traceSettings, settings=panelSettings
    panelSettings->GetProperty, titleobj=panelTitle
  ENDELSE
  
  ; Set panel select
  id = widget_info(state.tlb, find_by_uname='layoutpanel')
  widget_control, id, set_combobox_select=*state.panel_select
  
  ; Get panel title and font options
  paneltitle->GetProperty, value=value, font=titlefont, size=titlesize, color=titlecolor
  id = widget_info(state.tlb, find_by_uname='paneltitle')
  widget_control, id, set_value = value, sensitive = sensitive
  id = widget_info(state.tlb, find_by_uname='titlecombo')
  widget_control, id, set_combobox_select=titlefont, sensitive = sensitive
  id = widget_info(state.tlb, find_by_uname='titlesize')
  widget_control, id, set_value=titlesize, sensitive = sensitive
  
  tcolorwindow = widget_info(tlb,find_by_uname='tcolorwindow')
  Widget_Control, tcolorwindow, Get_Value=tcolorWin
  scene=obj_new('IDLGRSCENE', color=titlecolor)
  tcolorWin->setProperty,graphics_tree=scene
  tcolorWin->draw
  id = widget_info(state.tlb, find_by_uname='tpalette')
  widget_control, id, sensitive=sensitive
  
  ; Get title margin
  panelSettings->GetProperty, titleMargin=titlemargin
  id = widget_info(state.tlb, find_by_uname='titlemargin')
  widget_control, id, set_value = titlemargin, sensitive = sensitive
  
  ; Get bottom/left position settings
  panelSettings->GetProperty, bottom=bottom, bunit=bunit, left=left, lunit=lunit,lvalue=lvalue,bvalue=bvalue
  
  unitNames=panelSettings->GetUnitNames()
  id = widget_info(state.tlb, find_by_uname='botbutton')
  widget_control, id, set_button=bottom, sensitive = sensitive
  id = widget_info(state.tlb, find_by_uname='bvalue')
  widget_control, id, set_value=strcompress(string(bvalue), /remove_all), sensitive=bottom
  id = widget_info(state.tlb, find_by_uname='bunit')
  widget_control, id, set_value=unitNames, set_combobox_select=bunit, sensitive=bottom
  
  id = widget_info(state.tlb, find_by_uname='leftbutton')
  widget_control, id, set_button=left, sensitive = sensitive
  id = widget_info(state.tlb, find_by_uname='lvalue')
  widget_control, id, set_value=strcompress(string(lvalue), /remove_all), sensitive=left
  id = widget_info(state.tlb, find_by_uname='lunit')
  widget_control, id, set_value=unitNames, set_combobox_select=lunit, sensitive=left
  
  ; Get width/height position settings
  panelSettings->GetProperty, width=width, wunit=wunit, height=height, $
    hunit=hunit, relvertsize=relvertsize,$
    hvalue=hvalue,wvalue=wvalue
    
  id = widget_info(state.tlb, find_by_uname='widthbutton')
  widget_control, id, set_button=width, sensitive = sensitive
  id = widget_info(state.tlb, find_by_uname='wvalue')
  widget_control, id, set_value=strcompress(string(wvalue), /remove_all), sensitive=width
  id = widget_info(state.tlb, find_by_uname='wunit')
  widget_control, id, set_value=unitNames, set_combobox_select=wunit, sensitive=width
  
  id = widget_info(state.tlb, find_by_uname='heightbutton')
  widget_control, id, set_button=height, sensitive = sensitive
  id = widget_info(state.tlb, find_by_uname='hvalue')
  widget_control, id, set_value=strcompress(string(hvalue), /remove_all), sensitive=height
  id = widget_info(state.tlb, find_by_uname='hunit')
  widget_control, id, set_value=unitNames, set_combobox_select=hunit, sensitive=height
  
;  id = widget_info(state.tlb, find_by_uname='relvertsize')
;  widget_control, id, set_value=relvertsize
  
  ; Get background color and initialize background color window
  panelSettings->GetProperty, backgroundcolor=value
  Widget_Control, state.bgcolorWindow, Get_Value=bgcolorWin
  if obj_valid(scene) then scene->remove,/all
  scene=obj_new('IDLGRSCENE', color=value)
  bgcolorWin->draw, scene
  
  id = widget_info(state.tlb, find_by_uname='bgpalette')
  widget_control, id, sensitive=sensitive
  
  ; Get frame color/thickness and initialize frame color window
  panelSettings->GetProperty, framecolor=value, framethick=framethick
  Widget_Control, state.fcolorWindow, Get_Value=fcolorWin
  if obj_valid(scene) then scene->remove,/all
  scene=obj_new('IDLGRSCENE', color=value)
  fcolorWin->draw, scene
  
  id = widget_info(state.tlb, find_by_uname='fpalette')
  widget_control, id, sensitive=sensitive
  
  id = widget_info(state.tlb, find_by_uname='framethick')
  widget_control, id, set_value=framethick, sensitive = sensitive
  
  state.historyWin->update,'SPD_UI_PANEL_OPTIONS: Widgets updated.'
  
  if ~statedef then Widget_Control, tlb, Set_UValue=state, /No_Copy   ;Only put STATE if it was not passed in.
  
END ;-----------------------------------------------------------------------

pro spd_ui_panel_options_set_dims, origWindow, cWindow, panelObjs

  compile_Opt idl2, hidden
  
  if ~obj_valid(panelObjs[0]) then return
  
  origWindow->getproperty, nrows=o_nrows, ncols=o_ncols
  
  r=0
  c=0
  for i=0, n_elements(panelObjs)-1 do begin
  
    panelObjs[i]->getproperty, settings=panelSettings
    panelSettings->getproperty, row=row, col=col, rspan=rspan, cspan=cspan
    panelSettings->getproperty, rspan=rspan, cspan=cspan
    
    r = (row+rspan-1) > r
    c = (col+cspan-1) > c
    r = (rspan-1) > r
    c = (cspan-1) > c
    
  endfor
  
  r = o_nrows > r
  c = o_ncols > c
  
  cWindow->setproperty, nrows=r, ncols=c
  
end

; procedure to update all relevant settings when the set all panels button is checked
; the title of the panels is preserved, everything else is copied
pro spd_ui_panel_options_set_all, tlb, state=state, panelSettings=panelSettings

  panelSettings->GetProperty, titleobj=titleobj, titlemargin=titlemargin, $
    backgroundcolor=backgroundcolor, framecolor=framecolor, $
    framethick=framethick
  npanels = n_elements(state.panelobjs)
  
  for i=0,npanels-1 do begin
    state.panelobjs[i]->GetProperty, settings=panelSettings1
    
    ; The following code preserves the panel title text, but copies all other properties
    panelSettings1->GetProperty,titleobj=titleobj1
    titleobj1->GetProperty,value=titletext1 ; that's the current title text, we don't want to change this
    titleObj2 = titleObj->Copy()
    titleObj2->SetProperty,value=titletext1 ; do not change title text
    
    ; Now set the panel to new properties and save it into state object
    panelSettings1->SetProperty,titleobj=titleObj2,titlemargin=titlemargin, $
      backgroundcolor=backgroundcolor, framecolor=framecolor, $
      framethick=framethick  
    state.panelobjs[i]->SetProperty, settings=panelSettings1
  endfor
  
end

; Procedure to check the entries in the spinner widgets for validity, update the settings, and issue any
; warning messages to the user.
; It is intended that this is called when the user clicks OK, APPLY, or changes to view a different panel.
; It should also be called if SET ALL is checked to update settings before they are propagated to other panels.
pro spd_ui_panel_spinner_update,tlb,panelsettings

  ; Placement
  ;
  ; ROW
  testvar = !values.d_nan
  minval = 1
  
  minval = 0
  id = widget_info(tlb,find_by_uname='botbutton')
  if widget_info(id, /button_set) then begin
    spd_ui_panel_spinner_check, tlb, panelsettings, 'bvalue','Bottom value',minval,reset=1,bvalue=testvar
    panelSettings->GetProperty, bvalue=bvalue
    widget_control, (widget_info(tlb, find_by_uname='bvalue')), set_value=bvalue
  endif
  ;LEFT -nb: event handling saves valid values immediately, if you change the valid range change there too
  id = widget_info(tlb,find_by_uname='leftbutton')
  if widget_info(id, /button_set) then begin
    spd_ui_panel_spinner_check, tlb, panelsettings, 'lvalue','Left value',minval,reset=1,lvalue=testvar
    panelSettings->GetProperty, lvalue=lvalue
    widget_control, (widget_info(tlb, find_by_uname='lvalue')), set_value=lvalue
  endif
  ;WIDTH
  id = widget_info(tlb,find_by_uname='widthbutton')
  if widget_info(id, /button_set) then begin
    spd_ui_panel_spinner_check_greater_than, tlb, panelsettings, 'wvalue','Width value',minval,wvalue=testvar
    panelSettings->GetProperty, wvalue=wvalue
    widget_control, (widget_info(tlb, find_by_uname='wvalue')), set_value=wvalue
  endif
  ;HEIGHT
  id = widget_info(tlb,find_by_uname='heightbutton')
  if widget_info(id, /button_set) then begin
    spd_ui_panel_spinner_check_greater_than, tlb, panelsettings, 'hvalue','Height value',minval,hvalue=testvar
    panelSettings->GetProperty, hvalue=hvalue
    widget_control, (widget_info(tlb, find_by_uname='hvalue')), set_value=hvalue
  endif
  ; FRAME THICKNESS
  
  id = widget_info(tlb, find_by_uname='framethick')
  widget_control, id, get_value=framethick
  if ~finite(framethick,/nan) then begin
    if framethick lt 1 then begin
      panelSettings->SetProperty,framethick=1
      widget_control, id, set_value=1
      messageString = 'Frame thickness must be greater than or equal to 1; value set to 1.'
      response=dialog_message(messageString,/CENTER)
    endif else if framethick gt 10 then begin
      panelSettings->SetProperty,framethick=10
      widget_control, id, set_value=10
      messageString = 'Maximum frame thickness is 10; value set to 10.'
      response=dialog_message(messageString,/CENTER)
    endif else begin
      panelSettings->SetProperty, framethick=framethick
    endelse
  endif else begin
    messageString = 'Invalid frame thickness entered; value reset.'
    response=dialog_message(messageString,/CENTER)
    panelSettings->GetProperty, framethick=prevframethick
    widget_control, id,set_value=prevframethick
  endelse
  
  ; TITLE MARGIN
  minval = 1
  spd_ui_panel_spinner_check, tlb, panelSettings, 'titlemargin', 'Title margin', minval,maxvalue=1000,titlemargin=testvar
  panelSettings->GetProperty, titlemargin=titlemargin
  widget_control, (widget_info(tlb,find_by_uname='titlemargin')), set_value=titlemargin
  ; TITLE SIZE
  panelsettings->GetProperty, titleobj=title
  spd_ui_panel_spinner_check, tlb, title, 'titlesize','Title size',minval,maxvalue=100, reset=1,size=testvar
  title->Getproperty, size=size
  widget_control, (widget_info(tlb,find_by_uname='titlesize')), set_value=size
  
end

;Helper procedure to avoid code repetition.
; set reset keyword if you want to reset to previous value (NB: this just means this helper function doesn't change the settings, widget must be updated elsewhere)
; if reset is not set it will update to the minvalue if value is less than minimum.

pro spd_ui_panel_spinner_check, tlb,panelsettings,uname,namestring, minvalue,maxvalue=maxvalue, reset=reset, _extra=ex
  if ~keyword_set(maxvalue) then maxvalue = 1000
  id = widget_info(tlb, find_by_uname=uname)
  widget_control, id, get_value=val
  if ~finite(val,/nan) then begin
    if val lt minvalue then begin
      if keyword_set(reset) then begin
        messageString = namestring+' must be greater than or equal to '+strtrim(string(minvalue),1)+'; value reset.'
        response=dialog_message(messageString,/CENTER)
      endif else begin
        ex.(0)=minvalue
        panelSettings->SetProperty,_extra=ex
        widget_control, id, set_value=minvalue
        messageString = namestring+' must be greater than or equal to '+strtrim(string(minvalue),1)+'; value set to '+strtrim(string(minvalue),1)+'.'
        response=dialog_message(messageString,/CENTER)
      endelse
    endif else if val gt maxvalue then begin
      if keyword_set(reset) then begin
        messageString = namestring+' must be lower than or equal to '+strtrim(string(maxvalue),1)+'; value reset.'
        response=dialog_message(messageString,/CENTER)
      endif else begin
        ex.(0)=maxvalue
        panelSettings->SetProperty,_extra=ex
        widget_control, id, set_value=maxvalue
        messageString = namestring+' must be lower than or equal to '+strtrim(string(maxvalue),1)+'; value set to '+strtrim(string(maxvalue),1)+'.'
        response=dialog_message(messageString,/CENTER)
      endelse
    endif else begin
      ex.(0)=val
      panelSettings->SetProperty, _extra=ex
    endelse
  endif else begin
    messageString = 'Invalid '+namestring+' entered; value reset.'
    response=dialog_message(messageString,/CENTER)
  endelse
  
end
;repeat of helper above, but checks if greater than rather than greater than or equal to the minvalue
; no reset keyword as setting to minvalue isn't valid
pro spd_ui_panel_spinner_check_greater_than, tlb,panelsettings,uname,namestring, minvalue, _extra=ex

  id = widget_info(tlb, find_by_uname=uname)
  widget_control, id, get_value=val
  if ~finite(val,/nan) then begin
    if val le minvalue then begin
      messageString = namestring+' must be greater than '+strtrim(string(minvalue),1)+'; value reset.'
      response=dialog_message(messageString,/CENTER)
    endif else begin
      ex.(0)=val
      panelSettings->SetProperty, _extra=ex
    endelse
  endif else begin
    messageString = 'Invalid '+namestring+' entered; value reset.'
    response=dialog_message(messageString,/CENTER)
  endelse
  
end


;function to handle color changing events
;returns chosen color
function spd_ui_panel_options_color_event, tlb, panelsettings, colorwidget, currentcolor

  ;panelSettings->GetProperty, backgroundColor=currentcolor

  color = PickColor(!P.Color, Group_Leader=tlb, Cancel=cancelled, $
    currentcolor=currentcolor)
    
  if cancelled then color=currentcolor
  
  Widget_Control, colorwidget, Get_Value=colorWin
  if obj_valid(scene) then scene->remove,/all
  scene=obj_new('IDLGRSCENE', color=reform(color))
  colorWin->draw, scene
  
  return, color
end ;---------------------------------------


PRO spd_ui_panel_options_event, event

  Compile_Opt hidden
  
  Widget_Control, event.TOP, Get_UValue=state, /No_Copy
  
  ;Put a catch here to insure that the state remains defined
  err_xxx = 0
  Catch, err_xxx
  IF (err_xxx NE 0) THEN BEGIN
    Catch, /Cancel
    Help, /Last_Message, Output = err_msg
    
    spd_ui_sbar_hwin_update, state, err_msg, /error, err_msgbox_title='Error in Panel Options'
    
    Widget_Control, event.TOP, Set_UValue=state, /No_Copy
    widget_control, event.top,/destroy
    RETURN
  ENDIF
  
  cpanel = state.panelobjs[*state.panel_select]
  IF ~Obj_Valid(cpanel) THEN cpanel = Obj_New('SPD_UI_PANEL', 1)
  cpanel->GetProperty, tracesettings=tracesettings, settings=panelsettings, YAxis=yaxis
  
  
  ;kill request block
  
  IF (Tag_Names(event, /Structure_Name) EQ 'WIDGET_KILL_REQUEST') THEN BEGIN
    ; reset
    state.origWindow->GetProperty, panels=origPanels, nrows=nrows, ncols=ncols
    state.cWindow->SetProperty, panels=origPanels, nrows=nrows, ncols=ncols
    state.drawObject->update,state.windowStorage,state.loadedData
    state.drawObject->draw
    state.historyWin->Update,'SPD_UI_PANEL_OPTIONS: Panel Options window killed.'
    state.tlb_statusBar->update,'Panel Options killed'
    
    exit_sequence:
    dprint, dlevel=4, 'widget killed'
    Widget_Control, event.TOP, Set_UValue=state, /No_Copy
    Widget_Control, event.top, /Destroy
    RETURN
  ENDIF
  
  ; Get the instructions from the widget causing the event and
  ; act on them.
  
  Widget_Control, event.id, Get_UValue=uval
  
  IF Size(uval, /Type) NE 0 THEN BEGIN
  
    state.historywin->update,'SPD_UI_PANEL_OPTIONS: User value: '+uval  ,/dontshow
    
    CASE uval OF
      'APPLYTOALL': BEGIN ;apply to all panels
      
        ;Update spinner widget values
        if obj_valid(state.panelobjs[*state.panel_select]) then spd_ui_panel_spinner_update,state.tlb,panelsettings
        
        ;Update list of Panel names in combobox if setall has been set to true.
        ;Also copy all settings from current panel over to other panels.
        
        if obj_valid(state.panelobjs[*state.panel_select]) then spd_ui_panel_options_set_all, tlb, state=state, panelSettings=panelSettings
        IF Is_Num(panelNames) THEN panelNames=['No Panels']
        IF N_Elements(panelNames) EQ 1 && panelNames EQ '' THEN panelNames=['No Panels']
        id_layoutpanel = widget_info(state.tlb, find_by_uname='layoutpanel')
        widget_control, id_layoutpanel, set_value=panelNames,set_combobox_select=*state.panel_select
        
        if obj_valid(state.panelobjs[*state.panel_select]) then spd_ui_panel_spinner_update,state.tlb,panelsettings
        spd_ui_panel_options_set_dims, state.origWindow, state.cWindow, state.panelObjs
        if spd_ui_check_overlap(state.panelobjs, state.cwindow[0]) then break
        spd_ui_panel_update,event.top, state=state
        
        IF Is_Num(panelNames) THEN panelNames=['No Panels']
        IF N_Elements(panelNames) EQ 1 && panelNames EQ '' THEN panelNames=['No Panels']
        widget_control, id_layoutpanel, set_value=panelNames,set_combobox_select=*state.panel_select
        if obj_valid(state.panelobjs[*state.panel_select]) then begin
          state.historyWin->Update, 'Changes applied to All Panels.'
          state.statusBar->Update, 'Changes applied to All Panels.'
        endif else begin
          state.historywin->update,'No changes applied (no valid panels).'
          state.statusBar->update,'No changes applied (no valid panels).'
        endelse
        
      END
      'APPLY': BEGIN
        ;update spinner widget values
        if obj_valid(state.panelobjs[*state.panel_select]) then spd_ui_panel_spinner_update,state.tlb,panelsettings
        
        spd_ui_panel_options_set_dims, state.origWindow, state.cWindow, state.panelObjs
        
        if spd_ui_check_overlap(state.panelobjs, state.cwindow[0]) then break
        
        spd_ui_panel_update,event.top, state=state
        
        IF Is_Num(panelNames) THEN panelNames=['No Panels']
        IF N_Elements(panelNames) EQ 1 && panelNames EQ '' THEN panelNames=['No Panels']
        id = widget_info(state.tlb, find_by_uname='layoutpanel')
        widget_control, id, set_value=panelNames,set_combobox_select=*state.panel_select
        if obj_valid(state.panelobjs[*state.panel_select]) then begin
          state.historyWin->Update, 'Changes applied.'
          state.statusBar->Update, 'Changes applied.'
        endif else begin
          state.historywin->update,'No changes applied (no valid panels).'
          state.statusBar->update,'No changes applied (no valid panels).'
        endelse
      END
      'CANC': BEGIN
        state.origWindow->GetProperty, panels=origPanels, nrows=nrows, ncols=ncols
        state.cWindow->SetProperty, panels=origPanels, nrows=nrows, ncols=ncols
        state.drawObject->update,state.windowStorage,state.loadedData
        state.drawObject->draw
        dprint, dlevel=4,  'Panel Options widget cancelled. No changes made.'
        state.historyWin->Update, 'Panel Options window cancelled. No changes made.'
        state.tlb_statusBar->update,'Panel Options cancelled'
        Widget_Control, event.TOP, Set_UValue=state, /No_Copy
        Widget_Control, event.top, /Destroy
        RETURN
      END
      'OK': BEGIN
        ;Update spinner widget values
      
      
        if obj_valid(state.panelobjs[*state.panel_select]) then spd_ui_panel_spinner_update,state.tlb,panelsettings
        spd_ui_panel_options_set_dims, state.origWindow, state.cWindow, state.panelObjs
        if spd_ui_check_overlap(state.panelobjs, state.cwindow[0]) then break
        spd_ui_panel_update,event.top, state=state
        dprint, dlevel=4, 'Panel options update. Panel Options widget closed.'
        state.historyWin->Update, 'Panel options update. Panel Options widget closed.'
        state.tlb_statusBar->update,'Panel Options closed'
        Widget_Control, event.TOP, Set_UValue=state, /No_Copy
        Widget_Control, event.top, /destroy
        RETURN
      END
      'TEMP': begin
      
        if obj_valid(state.panelobjs[*state.panel_select]) then begin
          ;Update spinner widget values
          spd_ui_panel_spinner_update,state.tlb,panelsettings
          state.template->setProperty,panel=panelSettings->copy()
          state.historywin->update,'Current panel options stored for use in a Template'
          state.statusBar->update,'Current panel options stored for use in a Template'
          
          messageString = 'These values have now been stored!' +  string(10B) + string(10B) + 'To save them in a template, click File->Graph Options Template->Save Template'
          response=dialog_message(messageString,/CENTER, /information)
          
        endif else begin
          state.historywin->update,'Cannot store options. Needs a valid panel to store options for a template.'
          state.statusBar->update,'Cannot store options. Needs a valid panel to store options for a template.'
        endelse
        
      end
      'LAYOUTPANEL': BEGIN
        *state.panel_select = event.index
        *state.ctr_num = 0
        if obj_valid(state.panelobjs[*state.panel_select]) then spd_ui_panel_spinner_update,state.tlb,panelsettings
        spd_ui_init_panel_options, state=state
        state.historyWin->Update, 'Panel Layout changed'
        state.statusbar->Update, 'Panel Layout changed'
      END
      'PANELTITLE': BEGIN
        widget_control, event.id, get_value=value
        panelsettings->GetProperty, titleobj=panelTitle
        panelTitle->SetProperty, value=value
        
        ;update title in panel combobox
        if obj_valid(state.panelobjs[*state.panel_select]) then begin
          id = widget_info(state.tlb, find_by_uname='layoutpanel')
          widget_control, id, get_value=panelNames
          panelNames[*state.panel_select] = state.panelObjs[*state.panel_select]->constructPanelName()
          widget_control, id, set_value=panelNames, set_combobox_select=*state.panel_select
        endif
        
        state.historyWin->Update, 'Panel Title changed'
        state.statusbar->Update, 'Panel Title changed'
      END
      'TFONT': BEGIN
        panelsettings->getproperty, titleobj=title
        title->setproperty, font=event.index
        ;        spd_ui_init_panel_options, state=state
        state.historyWin->Update, 'Title Font changed'
        state.statusbar->Update, 'Title Font changed'
      END
      'TSIZE': BEGIN
      
        state.historyWin->Update, 'Title Font Size changed'
        state.statusbar->Update, 'Title Font Size changed'
      END
      'TITLEMARGIN': BEGIN
      
        state.historyWin->Update, 'Title Margin changed'
        state.statusbar->Update, 'Title Margin changed'
      END
      
      'BOTBUTTON': BEGIN
        panelSettings->SetProperty, bottom=event.select
        id = widget_info(state.tlb, find_by_uname='bvalue')
        widget_control, id, sensitive=event.select
        id = widget_info(state.tlb, find_by_uname='bunit')
        widget_control, id, sensitive=event.select
        
        state.historyWin->Update, 'Bottom Margin toggled'
        state.statusbar->Update, 'Bottom Margin toggled'
      END
      'LEFTBUTTON': BEGIN
        panelSettings->SetProperty, left=event.select
        id = widget_info(state.tlb, find_by_uname='lvalue')
        widget_control, id, sensitive=event.select
        id = widget_info(state.tlb, find_by_uname='lunit')
        widget_control, id, sensitive=event.select
        
        state.historyWin->Update, 'Left Margin toggled'
        state.statusbar->Update, 'Left Margin toggled'
      END
      'WIDTHBUTTON': BEGIN
        panelSettings->SetProperty, width=event.select
        id = widget_info(state.tlb, find_by_uname='wvalue')
        widget_control, id, sensitive=event.select
        id = widget_info(state.tlb, find_by_uname='wunit')
        widget_control, id, sensitive=event.select
        
        state.historyWin->Update, 'Width Margin toggled'
        state.statusbar->Update, 'Width Margin toggled'
        
      END
      'HEIGHTBUTTON': BEGIN
        panelSettings->SetProperty, height=event.select
        
        id = widget_info(state.tlb, find_by_uname='hvalue')
        widget_control, id, sensitive=event.select
        id = widget_info(state.tlb, find_by_uname='hunit')
        widget_control, id, sensitive=event.select
        state.historyWin->Update, 'Height Margin toggled'
        state.statusbar->Update, 'Height Margin toggled'
        
      END
      
; This code was updating the state too aggressively.  When invalid spinner entries were made, it would revert to the last valid entry
; Rather than the last applied entry.  (.e.g. If bvalue is 7 and I change it to 56ff, it would reset to 56, when it should reset to 7
; Commenting the code fixes the problem
; I'm not deleting this for now block because it is always possible removing it could cause regressions.
; Current date is 2014/05/08.  If you read this comment and it is next year or something, it is probably safe to remove the block.  
; 
;      'BVALUE': BEGIN
;        ; handle only valid cases (wait until the user switches panels or clicks apply/ok/setall to do anything about invalid entries)
;        if event.valid and event.value ge 0 then panelSettings->SetProperty, bvalue=event.value
;        
;        state.historyWin->Update, 'Bottom Margin updated'
;        state.statusbar->Update, 'Bottom Margin updated'
;      END
;      'LVALUE': BEGIN
;        ; handle only valid cases
;        if event.valid and event.value ge 0 then panelSettings->SetProperty, lvalue=event.value
;        
;        state.historyWin->Update, 'Left Margin updated'
;        state.statusbar->Update, 'Left Margin updated'
;      END
;      'WVALUE': BEGIN
;        ; handle only valid cases
;        if event.valid and event.value gt 0 then panelSettings->SetProperty, wvalue=event.value
;        
;        state.historyWin->Update, 'Width Margin updated'
;        state.statusbar->Update, 'Width Margin updated'
;      END
;      'HVALUE': BEGIN
;        ; handle only valid cases
;        if event.valid and event.value gt 0 then panelSettings->SetProperty, hvalue=event.value
;        
;        state.historyWin->Update, 'Height Margin updated'
;        state.statusbar->Update, 'Height Margin updated'
;      END
      'BUNIT': BEGIN
        panelSettings->SetProperty, bunit=event.index
        panelSettings->GetProperty, bvalue=bvalue
        id = widget_info(state.tlb, find_by_uname='bvalue')
        widget_control, id, set_value=strcompress(string(bvalue), /remove_all)
        state.historyWin->Update, 'Bottom Margin Units updated'
        state.statusbar->Update, 'Bottom Margin Units updated'
        
      END
      'LUNIT': BEGIN
        panelSettings->SetProperty, lunit=event.index
        panelSettings->GetProperty, lvalue=lvalue
        id = widget_info(state.tlb, find_by_uname='lvalue')
        widget_control, id, set_value=strcompress(string(lvalue), /remove_all)
        
        state.historyWin->Update, 'Left Margin Units updated'
        state.statusbar->Update, 'Left Margin Units updated'
      END
      'WUNIT': BEGIN
        panelSettings->SetProperty, wunit=event.index
        panelSettings->GetProperty, wvalue=wvalue
        id = widget_info(state.tlb, find_by_uname='wvalue')
        widget_control, id, set_value=strcompress(string(wvalue), /remove_all)
        
        state.historyWin->Update, 'Width Margin Units updated'
        state.statusbar->Update, 'Width Margin Units updated'
      END
      'HUNIT': BEGIN
        panelSettings->SetProperty, hunit=event.index
        panelSettings->GetProperty, hvalue=hvalue
        id = widget_info(state.tlb, find_by_uname='hvalue')
        widget_control, id, set_value=strcompress(string(hvalue), /remove_all)
        
        state.historyWin->Update, 'Height Margin Units updated'
        state.statusbar->Update, 'Height Margin Units updated'
      END
      'RELVERTSIZE': BEGIN
        if event.valid then begin
          if event.value lt 0 then begin
            panelSettings->SetProperty, relvertsize=0
            widget_control, event.id, set_value=0
          endif else panelSettings->SetProperty, relvertsize=event.value
        endif
        state.historyWin->Update, 'Relative Vertical Size updated'
        state.statusbar->Update, 'Relative Vertical Size updated'
      END
      'TPALETTE': BEGIN
        panelSettings->GetProperty, titleobj=title
        title->GetProperty, color = currentcolor
        color = spd_ui_panel_options_color_event(state.tlb, panelsettings, state.tcolorWindow, currentcolor)
        title->SetProperty, color=color
        
        state.historyWin->Update, 'Font Color selected'
        state.statusbar->Update, 'Font Color selected'
      END
      'BGPALETTE': BEGIN
        panelSettings->GetProperty, backgroundColor=currentcolor
        color = spd_ui_panel_options_color_event(state.tlb, panelsettings, state.bgcolorWindow, currentcolor)
        panelSettings->SetProperty, backgroundcolor=color
        
        state.historyWin->Update, 'Backgournd Color selected'
        state.statusbar->Update, 'Backgournd Color selected'
      END
      'FPALETTE': BEGIN
        panelSettings->GetProperty, frameColor=currentcolor
        color = spd_ui_panel_options_color_event(state.tlb, panelsettings, state.fcolorWindow, currentcolor)
        panelSettings->SetProperty, framecolor=color
        
        state.historyWin->Update, 'Panel Frame Color selected'
        state.statusbar->Update, 'Panel Frame Color selected'
      END
      'FRAMETHICK': BEGIN
      
        state.historyWin->Update, 'Frame Thickness updated'
        state.statusbar->Update, 'Frame Thickness updated'
        
      END
      
      ELSE:; dprint,  ''
    ENDCASE
  ENDIF
  
  ; ALWAYS reset state
  
  Widget_Control, event.TOP, Set_UValue=state, /No_Copy
  
  RETURN
END ;--------------------------------------------------------------------------------



PRO spd_ui_panel_options, gui_id, windowStorage, loadedData, historyWin, $
    drawObject, panel_select=panel_select, ctr_num=ctr_num,$
    template, tlb_statusbar
    
  ; kill top base in case of init error
  catch, err
  if err ne 0 then begin
    catch, /cancel
    help, /last_message, output=err_msg
    for i = 0, n_elements(err_msg)-1 do historywin->update,err_msg[i]
    print, 'Error--See history'
    widget_control, tlb, /destroy
    ok = error_message('An unknown error occured while starting Panel Options. See console for details.',$
      /noname, /center, title='Error in Panel Options')
    spd_gui_error, gui_id, historywin
    return
  endif
  
  ;top level and main base widgets
  tlb_statusBar->update,'Panel Options opened'
  tlb = Widget_Base(/Col, Title='Panel Options', Group_Leader=gui_id, $
    /Modal, /Floating, /tlb_kill_request_events, TAB_MODE=1)
    
  mainBase = Widget_Base(tlb, /Col)
  mainButtonBase = Widget_Base(tlb, /Row, /Align_Center)
  
  ;layout panel bases
  
  layoutBase = Widget_Base(mainBase, Title='Layout', /Col, ypad=2)
  panellBase = Widget_Base(layoutBase, /ROW, YPad=2, XPad=2)
  titleBase = Widget_Base(layoutBase, /Row, YPad=1, XPad=2)
  titleFontBase = widget_base(layoutBase,/row, ypad=0, xpad=2)
  plabelBase = Widget_Base(layoutBase, /Row, YPad = 2, XPad=2)
  placeBase = Widget_Base(layoutBase, /Col, Frame=3)
  ;       overlayBase = Widget_Base(placeBase, /Row, YPad=1, XPad=2)
  rcBase = Widget_Base(placeBase, /Row, YPad=2)
  col1 = Widget_Base(rcBase, /Col,  XPad=2, ypad=10)
  col2 = Widget_Base(rcBase, /Col, XPad=30)
  topBase = Widget_Base(placeBase, /Row)
  tcol1 = Widget_Base(col2, /Row, XPad=80)
  tcol2 = Widget_Base(col2, /Row, XPad=80)
  tcol3 = Widget_Base(col2, /Row, XPad=80)
  tcol4 = Widget_Base(col2, /Row, XPad=80)
  tButBase = Widget_Base(tcol1, /Col, /NonExclusive, xsize=70)
  tSizeBase = Widget_Base(tcol1, /Col)
  tPullBase = Widget_Base(tcol1, /Col)
  t2ButBase = Widget_Base(tcol2, /Col, /NonExclusive, xsize=70)
  t2SizeBase = Widget_Base(tcol2, /Col)
  t2PullBase = Widget_Base(tcol2, /Col)
  t3ButBase = Widget_Base(tcol3, /Col, /NonExclusive, xsize=70)
  t3SizeBase = Widget_Base(tcol3, /Col)
  t3PullBase = Widget_Base(tcol3, /Col)
  t4ButBase = Widget_Base(tcol4, /Col, /NonExclusive, xsize=70)
  t4SizeBase = Widget_Base(tcol4, /Col)
  t4PullBase = Widget_Base(tcol4, /Col)
  bottomBase = Widget_Base(placeBase, /Row)
  relBase = Widget_Base(placeBase, /Row, /Align_Center)
  clabelBase = Widget_Base(layoutBase, /Row, YPad=1, XPad=2)
  colorColBase = Widget_Base(layoutBase, /col, Frame=3)
  colorBase = Widget_Base(colorColBase, /Row, YPad=1, XPad=2)
  thicknessBase = Widget_Base(colorColBase, /row)
  
  if ~ptr_valid(panel_select) then panel_select = ptr_new(0)
  if ~ptr_valid(ctr_num) then ctr_num = ptr_new(0) else *ctr_num = 0
  
  cWindow = windowStorage->GetActive()
  origWindow = cWindow->Copy()
  
  IF NOT Obj_Valid(cWindow) THEN BEGIN
    panelNames=['No Panels']
  ENDIF ELSE BEGIN
    cWindow->GetProperty, Panels=panels, nRows=nRows, nCols=nCols
    IF Obj_Valid(panels) THEN BEGIN
      panelObjs = panels->Get(/all)
      IF obj_valid(panelobjs[0]) then begin
        FOR i=0, N_Elements(panelObjs)-1 do panelobjs[i]->save
      endif
    endif
    IF NOT Obj_Valid(panels) THEN BEGIN
      panelNames=['No Panels']
    ENDIF ELSE BEGIN
      panelObjs = panels->Get(/all)
      IF Is_Num(panelObjs) THEN BEGIN
        panelNames=['No Panels']
      ENDIF ELSE BEGIN
        FOR i=0, N_Elements(panelObjs)-1 DO BEGIN
          name = panelObjs[i]->constructPanelName()
          IF i EQ 0 THEN panelNames=[name] ELSE panelNames=[panelNames, name]
        ENDFOR
        panelobjs[0]->getproperty, settings=panelsettings
        panelsettings->getproperty, titleobj=title
      ENDELSE
    ENDELSE
    IF Is_Num(panelNames) THEN panelNames=['No Panels']
    IF N_Elements(panelNames) EQ 1 && panelNames EQ '' THEN panelNames=['No Panels']
  ENDELSE
  
  if ~obj_valid(title) then title = obj_new('spd_ui_text')
  
  ;Get path to bitmap icons
  getresourcepath,rpath
  palettebmp = read_bmp(rpath + 'color.bmp', /rgb)
  spd_ui_match_background, tlb, palettebmp
  
  ;layout panel widgets
  
  ;pldBase = widget_base(panellbase, /row)
  pldLabel = widget_label(panellBase, value = 'Panel: ', xsize=50)
  panellDroplist = Widget_combobox(panellBase, Value=panelNames, XSize=340, $
    UValue='LAYOUTPANEL', uname='layoutpanel')
  TitleLabel = Widget_Label(TitleBase, Value='Title: ', xsize=50)
  TitleText = Widget_Text(TitleBase, /Editable, /all_events, XSize = 55, ysize=1, $
    uvalue='PANELTITLE', uname='paneltitle')
  marginBase = Widget_Base(TitleBase, /Row)
  marginIncrement = spd_ui_spinner(marginBase, Label='Margin: ', Increment=1, Value=1, $
    UValue='TITLEMARGIN', uname='titlemargin', min_value=1)
    
  ;Title font and options widgets
  spacelabel = widget_label(titleFontBase, value='', xsize=50)
  titleFontDroplist = Widget_Combobox(titleFontBase,xsize=150, Value=title->getfonts(), uval='TFONT', uname='titlecombo')
  titleFontIncBase = widget_base(titleFontBase, /row, xpad=8, ypad=0, space=0)
  titleFontIncrement = spd_ui_spinner(titleFontIncBase, incr=1, uval='TSIZE', uname='titlesize',min_value=1)
  
  titleColorBase = Widget_Base(titleFontBase, /row, xpad=4, ypad=0, space=0)
  paletteButton = Widget_Button(titleColorBase, Value=palettebmp, /Bitmap, UValue='TPALETTE', uname = 'tpalette',Tooltip='Choose color from Palette')
  
  geo_struct = widget_info(paletteButton,/geometry)
  tcolorWindow = Widget_Draw(titleFontBase, XSize=50, YSize=geo_struct.scr_ysize,uname='tcolorwindow', $
    graphics_level=2,renderer=1,retain=1,units=0,frame=1, /expose_events)
    
  placemLabel = Widget_Label(plabelBase, Value='Placement: ' )
  
  botButton = Widget_Button(tbutBase, Value = 'Bottom:', uval='BOTBUTTON', uname='botbutton')
  leftButton = Widget_Button(t2butBase, Value = 'Left:', uval='LEFTBUTTON', uname='leftbutton')
  botText = spd_ui_spinner(tsizeBase, Increment=1, uval='BVALUE', uname='bvalue', $
    min_value=0, tooltip='Measured from the bottom of the page')
  leftText = spd_ui_spinner(t2sizeBase, Increment=1, uval='LVALUE', uname='lvalue', $
    min_value=0, tooltip='Measured from the left side of the page')
  botDroplist = Widget_combobox(tpullBase, uval='BUNIT', uname='bunit')
  leftDroplist = Widget_combobox(t2pullBase, uval='LUNIT', uname='lunit')
  widthButton = Widget_Button(t3butBase, Value = 'Width:', uval='WIDTHBUTTON', uname='widthbutton')
  heightButton = Widget_Button(t4butBase, Value = 'Height:', uval='HEIGHTBUTTON', uname='heightbutton')
  widthText = spd_ui_spinner(t3sizeBase, Increment=1, uval='WVALUE', uname='wvalue',min_value=0)
  heightText = spd_ui_spinner(t4sizeBase, Increment=1, uval='HVALUE', uname='hvalue',min_value=0)
  widthDroplist = Widget_combobox(t3pullBase, uval='WUNIT', uname='wunit')
  heightDroplist = Widget_combobox(t4pullBase, uval='HUNIT', uname='hunit')
;  relLabel = Widget_Label(relBase, Value='Relative Vertical Size (%):  ', /Align_Center, sensitive=0)
;  relText = spd_ui_spinner(relBase, /Align_Center, Increment=1, uval='RELVERTSIZE', uname='relvertsize', sensitive=0)
  colorLabel = Widget_Label(clabelBase, Value='Color: ' )
  bgpaletteBase = Widget_Base(colorBase, /Row)
  bgcolorLabel = Widget_Label(bgpaletteBase, Value='Background Color: ')
  geo_struct = widget_info(bgcolorLabel,/geometry)
  labelXSize = geo_struct.scr_xsize
  
  getresourcepath,rpath
  palettebmp = read_bmp(rpath + 'color.bmp', /rgb)
  spd_ui_match_background, tlb, palettebmp
  
  bgpaletteButton = Widget_Button(bgpaletteBase, Value=palettebmp, /Bitmap, $
    UValue='BGPALETTE',uname='bgpalette', Tooltip='Choose background color from palette')
  bgspaceLabel = Widget_Label(bgpaletteBase, Value=' ')
  bgcolorWindow = WIDGET_DRAW(bgpaletteBase,graphics_level=2,renderer=1, $
    retain=1, XSize=50, YSize=20, units=0, frame=1, /expose_events)
  fpaletteBase = Widget_Base(thicknessBase, /Row)
  fcolorLabel = Widget_Label(fpaletteBase, Value=' Panel Frame Color: ', xsize=labelXSize)
  fpaletteButton = Widget_Button(fpaletteBase, Value=palettebmp, /Bitmap, $
    UValue='FPALETTE',uname='fpalette', Tooltip='Choose panel frame color from palette')
  fspaceLabel = Widget_Label(fpaletteBase, Value=' ')
  fcolorWindow = WIDGET_DRAW(fpaletteBase,graphics_level=2,renderer=1, $
    retain=1, XSize=50, YSize=20, units=0, frame=1, /expose_events)
  frametBase = WIDGET_BASE(thicknessBase, /row, xpad = 30)
  linetIncrement = spd_ui_spinner(frametBase, label='Frame Thickness:    ', Increment=1, $
    uval='FRAMETHICK', uname='framethick', min_value=1, max_value=10) ;(IDLgrAxis/IDLgrPolyline restrict thickness to 1:10)
  linetLabel = Widget_Label(frametBase, Value=' (pts)')
  okButton = Widget_Button(mainButtonBase, Value='OK', Uvalue='OK', XSize=75)
  applyButton = Widget_Button(mainButtonBase, Value='Apply', Uvalue='APPLY', XSize=75)
  applyToAllButton = Widget_Button(mainButtonBase, Value='Apply to All Panels', Uvalue='APPLYTOALL', XSize=125)
  cancelButton = Widget_Button(mainButtonBase, Value='Cancel', UValue='CANC', XSize=75)
  templateButton = Widget_Button(mainButtonBase,Value='Store for a Template', UValue='TEMP',xsize=125,tooltip='Use these settings when saving a Graph Options Template') 
  
  statusBar = obj_new('spd_ui_message_bar',tlb)
  
  state = {tlb:tlb, tcolorWindow:tcolorWindow, bgcolorWindow:bgcolorWindow, fcolorWindow:fcolorWindow, loadedData:loadedData, $
    panelObjs:panelObjs, windowStorage:windowStorage, origWindow:origWindow, $
    cWindow:cWindow, drawObject:drawObject, $
    historyWin:historyWin, nRows:nRows, nCols:nCols, $
    panel_select:panel_select, ctr_num:ctr_num, $
    gui_id:gui_id, template:template, statusBar:statusBar,$
    panelNames:panelNames,is_trace_spec:0, tlb_statusbar:tlb_statusbar}
    
  Widget_Control, tlb, Set_UValue=state, /No_Copy
  centertlb, tlb
  widget_control, tlb, /Realize
  
  spd_ui_panel_update,tlb, /nodraw
  
  historyWin->update,'SPD_UI_PANEL_OPTIONS: Widget started'
  
  ;keep windows in X11 from snaping back to
  ;center during tree widget events
  if !d.NAME eq 'X' then begin
    widget_control, tlb, xoffset=0, yoffset=0
  endif
  
  XManager, 'spd_ui_panel_options', tlb, /No_Block
  
  RETURN
END ;--------------------------------------------------------------------------------
