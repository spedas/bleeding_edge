
;+
;  spd_ui_variable_options
;
;W.M.Feuerstein, 10/14/2008.
;Rewritten pcruce@igpp.ucla.edu 9/10/2009
;-
;
;$LastChangedBy: jwl $
;$LastChangedDate: 2022-03-04 11:48:01 -0800 (Fri, 04 Mar 2022) $
;$LastChangedRevision: 30648 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/spedas_gui/panels/spd_ui_variable_options.pro $
;-


pro spd_ui_variable_options_get_varinfo,tlb,panels,statusbar,historywin,operation,variables=variables,varselect=varselect,varlist=varlist,fail=fail, currentpanel=currentpanel

  Compile_Opt idl2, hidden
  
  fail = 1
  variables = obj_new()
  varselect = -1
  
  panelNum = panels->count()
  if panelNum eq 0 then begin
    statusbar->update,'Cannot '+ operation +' variable, no panels'
    historywin->update,'Variable Panel, ' + operation + ' : cannot ' + operation + ', no panels'
    return
  endif
  
  panels = panels->get(/all)
  ;panelSelect = spd_ui_variable_get_combobox_select(tlb,'panellist')
  ; When the user changes panel we need info about the previous panel, not the new panel. If you want info on the new
  ; panel then pass that panel number into the routine.
  panelSelect = currentpanel
  panel = panels[panelSelect]
  
  panel->getProperty,variables=variables
  
  variableNum = variables->count()
  if variableNum eq 0 then begin
    statusbar->update,'Cannot ' + operation + ' variable, no variables'
    historywin->update,'Variable Panel, ' + operation + ' : cannot ' + operation + ', no variables'
    return
  endif
  
  ;get variable list selection
  varlist = widget_info(tlb,find_by_uname='varlisttext')
  varselect = (widget_info(varlist,/list_select))[0]
  
  
  if varselect[0] eq -1 || varselect gt variableNum then begin
    statusbar->update,'Cannot ' + operation + ' variable, no valid selection'
    historywin->update,'Variable Panel, ' + operation + ' : cannot ' + operation + ', no valid selection'
    return
  endif
  
  fail = 0
  
end
pro spd_ui_variable_set_value,tlb,panels,statusbar,historywin, previousvar=previousvar,currentpanel=currentpanel,template=template

  Compile_Opt hidden,idl2
  
  panelNum = panels->count()
  if panelNum eq 0 then begin
    spd_ui_variable_options_init_novars,tlb,template=template
    return
  endif
  
  panelObjs = panels->get(/all)
  
  ;panelSelect = spd_ui_variable_get_combobox_select(tlb,'panellist')
  ; NB: IF this method is called as a result of the user changing panel selection, then currentpanel is the panel
  ; that was previously selected. This lets the routine update any changes the user made to the settings for that panel.
  panelSelect = currentpanel
  panel = panelObjs[panelSelect]
  
  if ~obj_valid(panel) then return
  
  ;set label margin value
  labelmarginwidget = widget_info(tlb,find_by_uname='labelmarginwidget')
  widget_control,labelmarginwidget,get_value=labelmargin
  if ~finite(labelmargin,/nan) then begin
    panel->setProperty,labelmargin=labelmargin
  endif else begin
    panel->getProperty,labelmargin=oldlabelmargin
    widget_control,labelmarginwidget,set_value=oldlabelmargin
    statusBar->update,'Invalid label margin, value reset.'
    historyWin->update,'Invalid label margin, value reset.',/dontshow
    messageString = 'Invalid label margin, value reset.'
    response=dialog_message(messageString,/CENTER)
  endelse
  
  
  spd_ui_variable_options_get_varinfo,tlb,panels,statusbar,historywin,'Set Value',variables=variables,varselect=varselect,varlist=varlist,fail=fail, currentpanel=currentpanel
  
  if fail then return
  
  if size(previousvar,/type) ne 0 then begin
    if previousvar ge 0 and previousvar ne varselect then begin
      varselect = previousvar
    endif
  endif
  
  varObj = variables->get(position=varselect)
  varObj->getProperty,text=textObj
  
  controlwidget  = widget_info(tlb,find_by_uname='controlwidget')
  widget_control,controlwidget,sensitive=1,get_value=controlname
  
  textwidget  = widget_info(tlb,find_by_uname='textwidget')
  widget_control,textwidget,sensitive=1,get_value=textString
  
  format = spd_ui_variable_get_combobox_select(tlb,'precisionwidget')
  
  if format eq -1 then begin
    format = 4
  endif
  
  autowidget  = widget_info(tlb,find_by_uname='aauto')
  dblwidget  = widget_info(tlb,find_by_uname='adbl')
  expwidget  = widget_info(tlb,find_by_uname='aexp')
  
  if widget_info(autowidget,/button_set) then begin
    annoExpo = 0
  endif else if widget_info(dblwidget,/button_set) then begin
    annoExpo = 1
  endif else begin
    annoExpo = 2
  endelse
  
  ;current color display draw widget
  colorwindow = widget_info(tlb,find_by_uname='colorwindow')
  ;get the actual window object
  Widget_Control, colorwindow, Get_Value=colorWin
  ;get the scene being drawn on the object
  ColorWin->getProperty,graphics_tree=scene
  ;get the color from the scene
  scene->getProperty,color=color
  
  font = spd_ui_variable_get_combobox_select(tlb,'fontwidget')
  if font eq -1 then font = 2
  
  textformat = spd_ui_variable_get_combobox_select(tlb,'textformatwidget')
  if textformat eq -1 then textformat = 3
  
  sizewidget = widget_info(tlb,find_by_uname='fontsizewidget')
  widget_control,sizewidget,get_value=newSize
  textObj->getProperty, size=prevSize
  ;check that the size is valid
  if ~finite(newSize,/nan) then begin
    if newSize lt 1 then begin
      statusBar->update,'Cannot have a font size less than 1'
      historyWin->update,'Cannot have a font size less than 1'
      messageString = 'Cannot have a font size less than 1, value set to 1.'
      response=dialog_message(messageString,/CENTER)
      newSize = 1
      widget_control, sizewidget, set_value=newSize
    endif
  endif else begin
    messageString = 'Invalid font size entered, value reset.'
    response=dialog_message(messageString,/CENTER)
    newSize=prevSize
    widget_control, sizewidget, set_value=prevSize
  endelse
  
  
  ;  includeunitswidget  = widget_info(tlb,find_by_uname='includeunitswidget')
  ;  includeunits = widget_info(includeunitswidget,/button_set)
  
  showvarwidget  = widget_info(tlb,find_by_uname='showvarwidget')
  showvar = widget_info(showvarwidget,/button_set)
  
  varObj->setProperty,$
    controlname=controlname,$
    includeunits=includeunits,$
    format=format,$
    annotateExponent=annoExpo
    
  textObj->setProperty,$
    value=textString,$
    color=color,$
    show=showvar,$
    font=font,$
    format=textformat,$
    size=newSize
    
end
;+
;NAME:
; spd_ui_variable_options
;
;PURPOSE:
; This routine creates and handles the layout widget. The layout panel is
; used to create and control a panels settings
;
;CALLING SEQUENCE:
; spd_ui_variable_options, gui_id
;
;INPUT:
; gui_id:  id for the master base widget (tlb)
;
;OUTPUT:
;
;HISTORY:
;
;$LastChangedBy: jwl $
;$LastChangedDate: 2022-03-04 11:48:01 -0800 (Fri, 04 Mar 2022) $
;$LastChangedRevision: 30648 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/spedas_gui/panels/spd_ui_variable_options.pro $
;---------------------------------------------------------------------------------

PRO spd_ui_variable_options_event, event

  Compile_Opt hidden,idl2
  
  if widget_valid(event.top) then begin
    Widget_Control, event.TOP, Get_UValue=state
  endif else begin
    dprint,'IDL error detected, halting execution to prevent unescapable loop'
    if !version.release ge '8.3' then !debug_process_events = 0 ; required to stop events with the following stop
    stop
  endelse
  
;  err_xxx = 0
;  Catch, err_xxx
;  If(err_xxx Ne 0) Then Begin
;    Catch, /Cancel
;    Help, /Last_Message, output = err_msg
;    FOR j = 0, N_Elements(err_msg)-1 DO PRINT, err_msg[j]
;    ;Print, 'Error--See history'
;    histobj=state.historywin
;    Widget_Control, event.top, Set_UValue=state, /No_Copy
;    if is_struct(state) then begin
;      spd_gui_error,state.gui_id,histobj
;    endif else begin
;      dprint,'Handling error for bug with improperly set state struct.  Value of !ERROR_STATE.msg is:  ' + !error_state.msg
;    endelse
;    Widget_Control, event.top, /Destroy
;    RETURN
;  EndIf
  err_xxx = 0
  Catch, err_xxx
  IF (err_xxx NE 0) THEN BEGIN
    Catch, /Cancel
    Help, /Last_Message, Output = err_msg
    
    spd_ui_sbar_hwin_update, state, err_msg, /error, err_msgbox_title='Error in Variable Options'
    
    Widget_Control, event.TOP, Set_UValue=state, /No_Copy
    widget_control, event.top,/destroy
    RETURN
  ENDIF
  IF(Tag_Names(event, /Structure_Name) EQ 'WIDGET_KILL_REQUEST') THEN BEGIN
    cWindow = state.windowStorage->getActive()
    cWindow->reset
    state.drawObject->update,state.windowStorage,state.loadedData
    state.drawObject->draw
    Widget_Control, event.TOP, Set_UValue=state, /No_Copy
    Widget_Control, event.top, /Destroy
    RETURN
  ENDIF
  
  Widget_Control, event.id, Get_UValue=uval
  
  ;skip any events returned for widgets without user values
  if ~keyword_set(uval) && widget_valid(event.top) then begin
    Widget_Control, event.top, Set_UValue=state, /No_Copy
    return
  endif
  
  ;  ; update any settings the user might have changed
  ;  spd_ui_variable_set_value,state.tlb,state.panels,state.statusbar,state.historywin, previousvar=state.previousvar,currentpanel=state.currentpanel,template=state.template
  ;  ; now update the selected panel (newpanel and oldpanel are used later to see if variable selection needs to be reset)
  ;  newpanel = spd_ui_variable_get_combobox_select(state.tlb,'panellist')
  ;  oldpanel = state.currentpanel
  ;  state.currentpanel = newpanel
  
  CASE uval OF
    'ADD':BEGIN
    spd_ui_variable_set_value,state.tlb,state.panels,state.statusbar,state.historywin, previousvar=state.previousvar,currentpanel=state.currentpanel,template=state.template
    
    panelNum = state.panels->count()
    
    if panelNum eq 0 then begin
      state.statusbar->update,'Cannot add variables until panels are present in the layout'
      state.historywin->update,'Variable Add, unable to add variables: No Panels'
    endif else if is_num(state.loadedData->getAll()) then begin
      state.statusbar->update,'Cannot add variables until data is loaded.'
      state.historywin->update,'Variable Add, unable to add variables: No data.'
    endif else begin
      newvars = spd_ui_add_variable(state.tlb,state.loadedData,state.guiTree,state.historywin,state.statusbar,multi=1,/leafonly)
      if ~keyword_set(newvars[0]) then begin
        state.statusbar->update,'Cannot add variables no selection.'
        state.historywin->update,'Variable Add, unable to add variables: No selection.'
      endif else begin
      
        panels = state.panels->get(/all)
        panelSelect = spd_ui_variable_get_combobox_select(state.tlb,'panellist')
        panel = panels[panelSelect]
        
        panel->getProperty,variables=variables
        if ~obj_valid(variables) || ~obj_isa(variables,'idl_container') then begin
          variables = obj_new('IDL_Container')
          panel->setProperty,variables=variables
        endif
        
        state.template->getProperty,variable=variableTemplate
        
        for i = 0,n_elements(newvars)-1 do begin
        
          dataObj = state.loadedData->getObjects(name=newvars[i])
          dataObj->getProperty,indepname=indepname,timename=timename,isTime=isTime
          if keyword_set(indepname) && state.loadedData->isChild(indepname) then begin
            controlname = indepname
          endif else begin
            controlname = timename
          endelse
          
          ;state.pageSettings->getProperty,variables=varText
          
          if obj_valid(variableTemplate) then begin
            newvarobj = variableTemplate->copy()
          endif else begin
            newvarobj = obj_new('spd_ui_variable')
          endelse
          
          newVarObj->getProperty,text=varText
          varText->setProperty,value=newvars[i]+' :'
          
          newvarobj->setProperty,controlname=controlname,fieldname=newvars[i],text=varText,isTime=isTime
          
          variables->add,newvarobj
          
        endfor
        
      endelse
    endelse
    
    spd_ui_variable_options_init,state
    
  END
  'PICKCONTROL' : begin
  
    controlname = spd_ui_add_variable(state.tlb,state.loadedData,state.guiTree,$
      state.historywin,state.statusbar,multi=0,/control,/leafonly)
      
    if keyword_set(controlname[0]) then begin
      controlwidget  = widget_info(state.tlb,find_by_uname='controlwidget')
      widget_control,controlwidget,sensitive=1,set_value=controlname
    endif
    
  end
  'SUBTRACT': BEGIN
  
    spd_ui_variable_options_get_varinfo,state.tlb, $
      state.panels,$
      state.statusbar,$
      state.historywin,$
      'remove',$
      variables=variables,$
      varselect=varselect,$
      varlist=varlist,$
      fail=fail,$
      currentpanel=state.currentpanel
      
    if fail eq 0 then begin
      variables->remove,position=varselect
      widget_control,varlist,set_list_select=varselect-1
      state.statusbar->update,'Variable removed.'
      state.historywin->update,'Variable removed.'
    endif
    
    spd_ui_variable_options_init,state
  end
  'UP':BEGIN
  spd_ui_variable_set_value,state.tlb,state.panels,state.statusbar,state.historywin, previousvar=state.previousvar,currentpanel=state.currentpanel,template=state.template
  
  spd_ui_variable_options_get_varinfo,state.tlb, $
    state.panels,$
    state.statusbar,$
    state.historywin,$
    'move up',$
    variables=variables,$
    varselect=varselect,$
    varlist=varlist,$
    fail=fail,$
    currentpanel=state.currentpanel
    
  if fail eq 0 && varselect gt 0 then begin
    variables->move,varselect,varselect-1
    widget_control,varlist,set_list_select=varselect-1
    state.statusbar->update,'Variable moved.'
    state.historywin->update,'Variable moved.'
  endif
  
  spd_ui_variable_options_init,state
end
'DOWN':BEGIN
spd_ui_variable_set_value,state.tlb,state.panels,state.statusbar,state.historywin, previousvar=state.previousvar,currentpanel=state.currentpanel,template=state.template

spd_ui_variable_options_get_varinfo,state.tlb, $
  state.panels,$
  state.statusbar,$
  state.historywin,$
  'move down',$
  variables=variables,$
  varselect=varselect,$
  varlist=varlist,$
  fail=fail,$
  currentpanel=state.currentpanel
  
if fail eq 0 && varselect lt variables->count()-1 then begin
  variables->move,varselect,varselect+1
  widget_control,varlist,set_list_select=varselect+1
  state.statusbar->update,'Variable moved.'
  state.historywin->update,'Variable moved.'
endif

spd_ui_variable_options_init,state
end
'PALETTE': begin

  ;current color display draw widget
  colorwindow = widget_info(state.tlb,find_by_uname='colorwindow')
  ;get the actual window object
  Widget_Control, colorwindow, Get_Value=colorWin
  ;get the scene being drawn on the object
  ColorWin->getProperty,graphics_tree=scene
  ;get the color from the scene
  scene->getProperty,color=currentcolor
  
  color = PickColor(!p.color, Group_Leader=state.tlb, Cancel=cancelled,currentcolor=currentcolor)
  
  if ~cancelled then begin
    scene->setProperty,color=reform(color)
    colorwin->draw,scene
    state.statusbar->update,'Variable color updated.'
    state.historywin->update,'Variable color updated.'
  endif
  
end
'VARIABLES': begin
  spd_ui_variable_set_value,state.tlb,state.panels,state.statusbar,state.historywin, previousvar=state.previousvar,currentpanel=state.currentpanel,template=state.template
  
  spd_ui_variable_options_init,state
end
'PANELS': begin
  spd_ui_variable_set_value,state.tlb,state.panels,state.statusbar,state.historywin, previousvar=state.previousvar,currentpanel=state.currentpanel,template=state.template
  ; now update the selected panel (newpanel and oldpanel are used later to see if variable selection needs to be reset)
  newpanel = spd_ui_variable_get_combobox_select(state.tlb,'panellist')
  oldpanel = state.currentpanel
  state.currentpanel = newpanel
  ; if user changes panels reset variable selection to 0
  if newpanel ne oldpanel then begin
    varlist = widget_info(state.tlb,find_by_uname='varlisttext')
    widget_control,varlist,set_list_select=0
  endif
  spd_ui_variable_options_init,state
end
'TEMP': begin
  spd_ui_variable_set_value,state.tlb,state.panels,state.statusbar,state.historywin, previousvar=state.previousvar,currentpanel=state.currentpanel,template=state.template
  
  spd_ui_variable_options_get_varinfo,state.tlb, $
    state.panels,$
    state.statusbar,$
    state.historywin,$
    'save to temp',$
    variables=variables,$
    varselect=varselect,$
    varlist=varlist,$
    fail=fail,$
    currentpanel=state.currentpanel
  if fail eq 0 then begin
    state.template->setProperty,variable=(variables->get(position=varselect))->copy()
    state.statusbar->update,'Current variable options stored for use in a Template'
    state.historywin->update,'Current variable options stored for use in a Template'

    messageString = 'These values have now been stored!' +  string(10B) + string(10B) + 'To save them in a template, click File->Graph Options Template->Save Template'
    response=dialog_message(messageString,/CENTER, /information)

  endif else begin
    state.statusbar->update,'Cannot store options. Needs a valid variable object to store options for a template.'
    state.historywin->update,'Cannot store options. Needs a valid variable object to store options for a template.'
  endelse
  
end
'CANC': BEGIN
  state.statusbar->update,'Variable options panel closed.'
  state.historywin->update,'Variable options panel closed.'
  cWindow = state.windowStorage->getActive()
  cWindow->reset
  state.drawObject->update,state.windowStorage,state.loadedData
  state.drawObject->draw
  Widget_Control, event.TOP, Set_UValue=state, /No_Copy
  Widget_Control, event.top, /Destroy
  RETURN
END
'APPLY':begin
spd_ui_variable_set_value,state.tlb,state.panels,state.statusbar,state.historywin, previousvar=state.previousvar,currentpanel=state.currentpanel,template=state.template

state.drawObject->update,state.windowStorage,state.loadedData
state.drawObject->draw
state.statusbar->update,'Variable options changes applied.'
state.historywin->update,'Variable options changes applied.'
end
'OK': BEGIN
  spd_ui_variable_set_value,state.tlb,state.panels,state.statusbar,state.historywin, previousvar=state.previousvar,currentpanel=state.currentpanel,template=state.template
  
  panelSelect = spd_ui_variable_get_combobox_select(state.tlb,'panellist')
  cWindow = state.windowStorage->getActive()
  if obj_valid(cwindow) then begin
    cWindow->setProperty,varOptionsPanel=panelSelect
  endif
  
  state.drawObject->update,state.windowStorage,state.loadedData
  state.drawObject->draw
  state.statusbar->update,'Variable options changes applied.'
  state.historywin->update,'Variable options changes applied.'
  Widget_Control, event.TOP, Set_UValue=state, /No_Copy
  Widget_Control, event.top, /Destroy
  RETURN
END
ELSE:
ENDCASE

Widget_Control, event.top, Set_UValue=state, /No_Copy

RETURN

END ;--------------------------------------------------------------------------------

function spd_ui_variable_get_combobox_select,tlb,uname

  compile_opt idl2,hidden
  
  ;combobox widget index
  combo = widget_info(tlb,find_by_uname=uname)
  ;combobox text
  text = widget_info(combo,/combobox_gettext)
  ;combobox values list
  widget_control,combo,get_value=names
  
  ;combobox index of current text
  return,where(text eq names)
  
end

;desensitizes fields for common fail case
pro spd_ui_variable_options_init_novars,tlb,template=template

  compile_opt idl2,hidden
  
  varlist = widget_info(tlb,find_by_uname='varlisttext')
  widget_control,varlist,set_value=' '
  
  shiftup = widget_info(tlb,find_by_uname='shiftupbutton')
  widget_control,shiftup,sensitive=0
  
  shiftdown = widget_info(tlb,find_by_uname='shiftdownbutton')
  widget_control,shiftdown,sensitive=0
  
  fieldwidget  = widget_info(tlb,find_by_uname='fieldwidget')
  widget_control,fieldwidget,sensitive=0,set_value='<none selected>'
  
  controlwidget  = widget_info(tlb,find_by_uname='controlwidget')
  widget_control,controlwidget,sensitive=0,set_value='<none selected>'
  
  controlbutton  = widget_info(tlb,find_by_uname='controlbutton')
  widget_control,controlbutton,sensitive=0
  
  textwidget  = widget_info(tlb,find_by_uname='textwidget')
  widget_control,textwidget,sensitive=0,set_value=' '
  
  ;  symbolwidget  = widget_info(tlb,find_by_uname='symbolwidget')
  ;  widget_control,symbolwidget,sensitive=0
  
  precisionwidget  = widget_info(tlb,find_by_uname='precisionwidget')
  widget_control,precisionwidget,sensitive=0
  
  annobase  = widget_info(tlb,find_by_uname='annobase')
  widget_control,annobase,sensitive=0
  
  palettewidget  = widget_info(tlb,find_by_uname='palettewidget')
  widget_control,palettewidget,sensitive=0
  
  fontwidget  = widget_info(tlb,find_by_uname='fontwidget')
  widget_control,fontwidget,sensitive=0
  
  textFormatwidget  = widget_info(tlb,find_by_uname='textformatwidget')
  widget_control,textFormatwidget,sensitive=0
  
  fontSizeWidget  = widget_info(tlb,find_by_uname='fontsizewidget')
  widget_control,fontSizeWidget,sensitive=0
  
  ;  includeunitswidget  = widget_info(tlb,find_by_uname='includeunitswidget')
  ;  widget_control,includeunitswidget,sensitive=0
  
  showvarwidget  = widget_info(tlb,find_by_uname='showvarwidget')
  widget_control,showvarwidget,sensitive=0
  
  labelmarginwidget = widget_info(tlb,find_by_uname='labelmarginwidget')
  widget_control,labelmarginwidget,sensitive=0
  
  if ~obj_valid(template) then return
  
  template->getProperty,variable=variable
  
  if ~obj_valid(variable) then return
  variable->getProperty,text=text
  
  text->getProperty,value=v
  widget_control,textWidget,set_value=v
  
  ;  variable->getProperty,symbol=symbol
  ;  widget_control,symbolWidget,set_combobox_select=symbol
  
  variable->getProperty,format=numFormat
  widget_control,precisionwidget,set_combobox_select=numFormat
  
  variable->getProperty,annotateExponent=annotateStyle
  annoNames = ['aauto','adbl','aexp']
  annoSelected = widget_info(tlb,find_by_uname=annoNames[annotateStyle])
  widget_control,annoSelected,/set_button
  
  text->getProperty,color=color
  colorid = widget_info(tlb,find_by_uname='colorwindow')
  widget_control,colorid,get_value=colorwindow
  scene=obj_new('IDLGRSCENE', color=color)
  colorwindow->setProperty,graphics_tree=scene
  colorwindow->draw, scene
  
  text->getProperty,font=font
  widget_control,fontWidget,set_combobox_select=font
  
  text->getProperty,format=textFormat
  widget_control,textFormatWidget,set_combobox_select=textFormatWidget
  
  text->getProperty,size=size
  widget_control,fontSizeWidget,set_value=size
  
  ;  variable->getProperty,includeUnits=includeUnits
  ;  widget_control,includeUnitsWidget,set_button=includeUnits
  
  text->getProperty,show=show
  widget_control,showvarwidget,set_button=show
  
end

pro spd_ui_variable_options_init,state

  compile_opt idl2,hidden
  
  tlb = state.tlb
  
  shiftup = widget_info(tlb,find_by_uname='shiftupbutton')
  shiftdown = widget_info(tlb,find_by_uname='shiftdownbutton')
  
  panelNum = state.panels->count()
  if panelNum eq 0 then begin
    state.previousvar = -1
    spd_ui_variable_options_init_novars,tlb,template=state.template
    return
  endif
  
  panels = state.panels->get(/all)
  
  panelSelect = spd_ui_variable_get_combobox_select(tlb,'panellist')
  panel = panels[panelSelect]
  
  if ~obj_valid(panel) then return
  
  panel->getProperty,labelmargin=labelmargin,variables=variables
  
  ;set label margin value
  labelmarginwidget = widget_info(tlb,find_by_uname='labelmarginwidget')
  widget_control,labelmarginwidget,set_value=labelmargin
  
  ;get variable list selection
  varlist = widget_info(tlb,find_by_uname='varlisttext')
  varselect = (widget_info(varlist,/list_select))[0]
  
  ;no variables, then return
  varnum = variables->count()
  if varnum eq 0 then begin
    state.previousvar = -1
    spd_ui_variable_options_init_novars,tlb,template=state.template
    return
  endif
  
  ;assemble list of variable names
  
  varObjs = variables->get(/all)
  for i = 0,varnum-1 do begin
    varObj = varObjs[i]
    varObj->getProperty,fieldname=fieldname
    if undefined(varnames) then varnames=[fieldname] else varnames = array_concat(fieldname,varnames)
  endfor

  ;set default selection
  if varselect eq -1 then begin
    varselect = 0
  endif
  
  ;set list of variable names
  if keyword_set(varnames) then begin
    widget_control,varlist,set_value=varnames
    widget_control,varlist,set_list_select=varselect
    state.previousvar = varselect
  endif else begin
    state.previousvar = -1
    spd_ui_variable_options_init_novars,tlb,template=state.template
    return
  endelse
  
  ;set sensitivity values for arrows
  if varselect lt n_elements(varnames)-1 && $
    varselect gt 0 then begin
    widget_control,shiftup,sensitive=1
    widget_control,shiftdown,sensitive=1
  endif else if varselect lt n_elements(varnames)-1 then begin
    widget_control,shiftup,sensitive=0
    widget_control,shiftdown,sensitive=1
  endif else if varselect gt 0 then begin
    widget_control,shiftup,sensitive=1
    widget_control,shiftdown,sensitive=0
  endif else begin
    widget_control,shiftup,sensitive=0
    widget_control,shiftdown,sensitive=0
  endelse
  
  varObj = varObjs[varselect]
  
  varObj->getProperty, $
    fieldname=fieldname,$
    controlname=controlname,$
    includeunits=includeunits,$
    text=text,$
    format=format,$
    istime=istime,$
    annotateExponent=anno
    
  text->getProperty,color=color,value=textString,show=show,size=size,font=font,format=textFormat
  
  fieldwidget  = widget_info(tlb,find_by_uname='fieldwidget')
  widget_control,fieldwidget,sensitive=1,set_value=fieldname
  
  controlwidget  = widget_info(tlb,find_by_uname='controlwidget')
  widget_control,controlwidget,sensitive=1,set_value=controlname
  
  controlbutton  = widget_info(tlb,find_by_uname='controlbutton')
  widget_control,controlbutton,sensitive=1
  
  textwidget  = widget_info(tlb,find_by_uname='textwidget')
  widget_control,textwidget,sensitive=1,set_value=textString
  
  ;  symbolwidget  = widget_info(tlb,find_by_uname='symbolwidget')
  ;  widget_control,symbolwidget,sensitive=0
  
  precisionwidget  = widget_info(tlb,find_by_uname='precisionwidget')
  annobase  = widget_info(tlb,find_by_uname='annobase')
  
  formats = varObj->getFormats(istime=istime)
  
  widget_control,precisionwidget,sensitive=1,$
    set_value=formats,$
    set_combobox_select=format
    
  if istime then begin
  
    widget_control,annobase,sensitive=0
    
  endif else begin
  
    widget_control,annobase,sensitive=1
    
    if anno eq 0 then begin
      autowidget  = widget_info(tlb,find_by_uname='aauto')
      widget_control,autowidget,/set_button
    endif else if anno eq 1 then begin
      dblwidget  = widget_info(tlb,find_by_uname='adbl')
      widget_control,dblwidget,/set_button
    endif else if anno eq 2 then begin
      expwidget  = widget_info(tlb,find_by_uname='aexp')
      widget_control,expwidget,/set_button
    endif
    
  endelse
  
  palettewidget  = widget_info(tlb,find_by_uname='palettewidget')
  widget_control,palettewidget,sensitive=1
  
  colorid = widget_info(tlb,find_by_uname='colorwindow')
  widget_control,colorid,get_value=colorwindow
  scene=obj_new('IDLGRSCENE', color=color)
  colorwindow->setProperty,graphics_tree=scene
  colorwindow->draw, scene
  
  fontwidget = widget_info(tlb,find_by_uname='fontwidget')
  widget_control,fontwidget,set_combobox_select=font,sensitive=1
  
  textFormatwidget = widget_info(tlb,find_by_uname='textformatwidget')
  widget_control,textFormatwidget,set_combobox_select=textFormat,sensitive=1
  
  sizewidget = widget_info(tlb,find_by_uname='fontsizewidget')
  widget_control,sizewidget,set_value=size,sensitive=1
  
  ;  ;To re-enable the include units flag, just set sensitive = 1
  ;  includeunitswidget  = widget_info(tlb,find_by_uname='includeunitswidget')
  ;  widget_control,includeunitswidget,sensitive=0,set_button=includeunits
  
  showvarwidget  = widget_info(tlb,find_by_uname='showvarwidget')
  widget_control,showvarwidget,sensitive=1,set_button=show
  
  labelmarginwidget = widget_info(tlb,find_by_uname='labelmarginwidget')
  widget_control, labelmarginwidget,sensitive=1
  
end

Pro spd_ui_variable_options, gui_id, loadeddata, windowstorage, drawobject, historywin, template,guiTree,panel_select=panel_select

  ; top level and main base widgets

  tlb = Widget_Base(/Col, Title='Variable Options', Group_Leader=gui_id, /Modal, /Floating, /tlb_kill_request_events, tab_mode=1)
  mainBase = Widget_Base(tlb, /Row)
  varlistBase = Widget_Base(mainBase, /Col, YPad=8)
  
  panelBase = Widget_Base(varListBase, /row, ypad=4)
  dummybase = Widget_Base(varListBase, /row, ypad=4)
  varTextBase = Widget_Base(varListBase, YPad=1)
  varButtonBase = Widget_Base(varListBase, /Row, /Align_center, YPad=1)
  
  plusMinusBase = Widget_Base(mainBase, /Col, YPad=135, XPad=4)
  attributesBase = Widget_Base(mainBase, /Col)
  
  attLabelBase = Widget_Base(attributesBase)
  attListBase = Widget_Base(attributesBase, /Col, Frame=3)
  marginBase = Widget_Base(attributesBase, /Row, YPad=1)
  
  buttonBase = Widget_Base(tlb, /Row, /Align_Center)
  statusBase = Widget_Base(tlb, /Row, /Align_Center)
  
  ; widgets
  
  ;Get text values of current VARIABLESOBJECTS (if any) as well PANELOBJS, and PANELNAMES:
  ;***************************************************************************************
  cWindow = windowStorage->GetActive()
  cWindow->GetProperty, Panels=panels, locked=locked,settings=pageSettings
  panelObjs = panels->Get(/all)
  
  if is_num(panelObjs) then begin
    panelObjs = obj_new()
  endif
  
  if  n_elements(panel_select) eq 0 and obj_valid(cWindow) then begin
    cWindow->GetProperty,varOptionsPanel=panel_select
  endif
  
  ;Check to see if PANEL_SELECT is set.  If not, then check to see if axes are locked.  If so, then initialize to last panel:
  ;**************************************************************************************************************************
  ;
  if n_elements(panel_select) eq 0 || panel_select lt 0 || panel_select ge n_elements(panelObjs) then begin
    if locked ge 0 && locked lt n_elements(panelObjs) && obj_valid(panelObjs[0]) then begin
      rownum = 0
      for i=0, n_elements(panelobjs)-1 do begin ;find last panel on the page
        panelobjs[i]->getproperty, settings=psettings
        psettings->getproperty, row=row
        if row gt rownum then begin
          panel_select = i
          rownum = row
        endif
      endfor
    endif else begin
      panel_select = 0
    endelse
  endif
  
  IF ~obj_valid(panelobjs[0]) THEN BEGIN
    panelNames=['No Panels']
    variables = obj_new('IDL_Container')
    variableobjs = obj_new()
  ENDIF ELSE BEGIN
    n_panels=n_elements(panelobjs)
    panelObjs[panel_select]->GetProperty,variables=variables      ; *** Retrieve variables from 1st panel.
    panelObjs[panel_select]->GetProperty,labelmargin = labelmargin             ; Get LABELMARGIN from 1st panel.
    variableobjects=variables->get(/all)
    ;  FOR i=0, N_Elements(panelObjs)-1 DO BEGIN
    ;    panelObjs[i]->GetProperty, Name=name
    ;    IF i EQ 0 THEN panelNames=[name] ELSE panelNames=[panelNames, name]
    ;  ENDFOR
    panelnames=panelobjs[0]->constructpanelname()
    if n_panels gt 1 then begin
      for i=1,n_panels-1 do panelnames=[panelnames,panelobjs[i]->constructpanelname()]
    endif
  ENDELSE
  
  IF Is_Num(panelNames) THEN panelNames=['No Panels']
  IF N_Elements(panelNames) EQ 1 && panelNames EQ '' THEN panelNames=['No Panels']
  
  
  cWindow->save
  
  pdLabel = widget_label(panelBase, value = 'Panel: ')
  panelDroplist = Widget_combobox(panelBase, Value=panelNames, UValue='PANELS',uname='panellist')
  if is_num(panel_select) then widget_control,panelDroplist, set_combobox_select=panel_select
  varListLabel = Widget_Label(dummybase, Value='Variables: ')
  varlistText=Widget_list(varTextBase, Value=ctextvalues, XSize=37, YSize=15, uname='varlisttext', uval='VARIABLES')
  ;varlistText=Widget_list(varTextBase, Value=shadowlisttextvalues, XSize=37, YSize=15, uname='varlisttext', uval='VARIABLES')
  
  getresourcepath,rpath
  upArrow = read_bmp(rpath + 'arrow_090_medium.bmp', /rgb)
  downArrow = read_bmp(rpath + 'arrow_270_medium.bmp', /rgb)
  plusbmp = read_bmp(rpath + 'plus.bmp', /rgb)
  minusbmp = read_bmp(rpath + 'minus.bmp', /rgb)
  palettebmp = read_bmp(rpath + 'color.bmp', /rgb)
  
  spd_ui_match_background, tlb, upArrow
  spd_ui_match_background, tlb, downArrow
  spd_ui_match_background, tlb, plusbmp
  spd_ui_match_background, tlb, minusbmp
  spd_ui_match_background, tlb, palettebmp
  
  shiftUpButton = Widget_Button(varButtonBase, Value=upArrow, /Bitmap, UValue='UP', uname = 'shiftupbutton', Tooltip='Move this variable up by one', $
    sensitive = 0)
  shiftDownButton = Widget_Button(varButtonBase, Value=downArrow, /Bitmap, UValue='DOWN', uname = 'shiftdownbutton', $
    Tooltip='Move this variable down by one', sensitive = 0)
  ;getresourcepath,rpath
  ;plusbmp = rpath + 'plus.bmp'
  ;minusbmp = rpath + 'minus.bmp'
  addButton = Widget_Button(plusMinusBase, Value=plusbmp, /Bitmap, ToolTip='Add selections to the list of data to be loaded', uval='ADD')
  minusButton = Widget_Button(plusMinusBase, Value=minusbmp, /Bitmap, ToolTip='Remove data from the list of data to be loaded', $
    uval='SUBTRACT', uname='subtract')
  attLabel = Widget_Label(attLabelBase, Value='Attributes: ')
  
  fieldBase = Widget_Base(attListBase, /row)
  fieldLabel = Widget_Label(fieldBase, Value='Field: ', /align_left)
  fieldText = Widget_Text(fieldBase, Value='<none selected>', XSize=20, YSize=1, uname='fieldwidget', sensitive=0)
  
  controlBase = Widget_Base(attListBase, /row)
  controlLabel = Widget_Label(controlBase, Value='Control: ', /align_left)
  controlText = Widget_Text(controlBase, Value='<none selected>', XSize=20, YSize=1, uname='controlwidget', sensitive=0, uval='PICKCONTROL')
  ;controltext= Widget_text(attListBase, xsize=200, Title='Control:  ', Value='<none selected>', uname = 'controlwidget', sensitive = 0, uval='PICKCONTROL')
  controlButton = Widget_Button(controlBase, Value="Choose...", ToolTip='Pick a control for the variable.', uval='PICKCONTROL',sensitive=0,uname='controlbutton')
  
  textBase = Widget_Base(attListBase, /Row)
  textLabel = Widget_Label(textBase, Value='Text: ', /align_left)
  textText = Widget_Text(textBase, Value=' ', XSize=20, /Editable, /all_events, YSize=1, uname='textwidget', uval='TEXT', sensitive=0)
  
  ;**Commented out 2-15-12**
  ;if obj_valid(panelobjs[0]) then begin
  ;  panelobjs[panel_select]->GetProperty,xaxis=xaxis
  ;  if obj_valid(xaxis) then precisionValues = xaxis->getannotationformats()
  ;  foo=obj_new('spd_ui_variable')
  ;  symbolValues = foo->getsymbols()
  ;  obj_destroy, foo
  ;endif else begin
  ;  symbolvalues='<none selected>'
  ;  precisionValues='<none selected>'
  ;endelse
  ;
  ;sdBase = widget_base(attListBase, /row)
  ;sdLabel = widget_label(sdBase, value = 'Symbol: ', XSize=70, /align_left)
  ;symbolDroplist = WIDGET_combobox(sdBase, uname='symbolwidget', uval='SYMBOL', sensitive=0, value=symbolValues)
  
  pdBase = widget_base(attListBase, /row)
  pdLabel = widget_label(pdBase, value = 'Precision: ', /align_left, uname='precisionlabel')
  precisionDroplist = WIDGET_combobox(pdBase, Value=precisionValues,uname='precisionwidget', uval='PRECISION', sensitive=0)
  
  anoSOBase = widget_base(attListBase, /row, /exclusive, ypad=2, space=0,uname='annobase',sensitive=0)
  default = widget_button(anoSOBase, value = 'Auto-Notation', uvalue='AAUTO', uname='aauto')
  dbl = widget_button(anoSOBase, value = 'Decimal', uvalue='ADBL', uname='adbl')
  expo = widget_button(anoSOBase, value = 'Sci-Notation', uvalue='AEXP', uname = 'aexp')
  atype = [default, dbl, expo]
  
  paletteBase = Widget_Base(attListBase, /Row)
  colorLabel = Widget_Label(paletteBase, Value='Color: ', /align_left)
  
  paletteButton = Widget_Button(paletteBase, Value=palettebmp, /Bitmap, UValue='PALETTE', ToolTip='Choose color from Palette', uname = 'palettewidget', $
    sensitive=0)
  vspaceLabel = Widget_Label(paletteBase, Value=' ')
  colorWindow = Widget_Draw(paletteBase, XSize=50, YSize=19,sensitive=0,uname='colorwindow', $
    graphics_level=2,renderer=1,retain=1,units=0,frame=1, /expose_events)
    
  tempTextObj = obj_new('spd_ui_text')
  fontValues = tempTextObj->GetFonts()
  textFormatValues = tempTextObj->getFormats()
  
  fontBase = widget_base(attListBase,/row)
  fontLabel = widget_label(fontBase,value='Font ')
  fontDroplist = Widget_Combobox(fontBase, Value=fontValues,uname='fontwidget')
  widget_control,fontDroplist,set_combobox_select=2
  
  textFormatBase = widget_base(attListBase,/row)
  textFormatLabel = widget_label(textFormatBase,value='Style: ')
  textFormatDroplist = Widget_Combobox(textFormatBase, Value=textFormatValues,uname='textformatwidget')
  widget_control,textFormatDroplist,set_combobox_select=3
  
  fontSizeBase = Widget_Base(attListBase, /Row)
  fontSize = spd_ui_spinner(fontSizeBase, label= 'Font Size : ', Increment=1, Value=8,getxlabelsize=xsize0, $
    uname='fontsizewidget', /all_events,sensitive=1, min_value=1)
    
  ;**commented out 2-15-12**
  ;includeBase = Widget_Base(attListBase, /Row, /NonExclusive)
  ;includeButton = Widget_Button(includeBase, Value='Include units in label', uname = 'includeunitswidget', uval='INCLUDE UNITS', sensitive=0)
    
  widget_control, fontlabel, xsize=xsize0+1
  widget_control, textFormatLabel, xsize=xsize0+1
  
  showVarBase = Widget_Base(attListBase, /Row, /NonExclusive)
  showVarButton = Widget_Button(showVarBase , Value='Show Variable', uname = 'showvarwidget', uval='SHOWVAR', sensitive=0)
  widget_control,showVarButton,/set_button
  
  margBase = Widget_Base(marginBase, /Row)
  if ~size(labelmargin,/type) then labelmargin=0
  margIncrement = spd_ui_spinner(margBase, label= 'Label Margin (pts): ', Increment=1, $
    Value=labelmargin, uname='labelmarginwidget', /all_events,sensitive=0, $
    tooltip="Horizonal spacing between the plot's edge and the variable labels on the left.")
    
  okButton = Widget_Button(buttonBase, Value=' OK ', UValue='OK', $
    ToolTip='Applies the changes to the layout and closes the window')
  applyButton = Widget_Button(buttonBase, Value=' Apply ', UValue='APPLY', $
    ToolTip='Applies the changes to the layout, leaves window open')
  cancelButton = Widget_Button(buttonBase, Value=' Cancel ', UValue='CANC', $
    ToolTip='Cancels the operation and closes the window')
  templateButton = Widget_Button(buttonBase,Value='Store for a Template', UValue='TEMP',tooltip='Use these settings when saving a Graph Options Template')
  
  ; Create Status Bar Object
  statusBar = Obj_New('SPD_UI_MESSAGE_BAR', $
    Value='Status information is displayed here.', $
    statusBase,Xsize=75, YSize=1)
    
  names=loadeddata->getall(/child)
  
  ;LOADEDDATA: contains unique NAMES of the loaded data.
  ;GUI_ID: Needed for the groud leader for the variable selection widget.
  ;WINDOWSTORAGE: Contains the current variable objects.
  ; currentpanel: this stores the number of the current panel (this is the index into the list of panels, not the
  ; named number of the panel eg. if user has two panels "Panel 2", "Panel 3" then the currentpanel is 0 or 1). When user
  ; changes panel the currentpanel number is updated last after settings have been saved to old panel.
  currentpanel = panel_select
  
  state = {tlb:tlb, loadeddata:loadeddata, gui_id:gui_id, windowstorage:windowstorage, $
    drawobject:drawobject,panels:panels,pageSettings:pageSettings, previousvar:0L, currentpanel:currentpanel,$
    historywin:historywin, statusbar:statusbar, $
    guiTree:guiTree, treeObj:obj_new(),template:template}
    
  centertlb,tlb
  Widget_control, tlb, Set_UValue=state
  Widget_control, tlb, /Realize
  
  spd_ui_variable_options_init,state
  
  ;keep windows in X11 from snaping back to
  ;center during tree widget events
  if !d.NAME eq 'X' then begin
    widget_control, tlb, xoffset=0, yoffset=0
  endif
  
  XManager, 'spd_ui_variable_options', tlb, /No_Block
  
  RETURN
END ;--------------------------------------------------------------------------------
































