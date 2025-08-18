;+
; NAME:
;  spd_ui_legend_options
;
; PURPOSE:
;  A widget interface for changing legend settings
;
; CALLING SEQUENCE:
;  spd_ui_legend_options, info
; 
; INPUT:
;  info:   info structure from spd_gui
;  
; KEYWORDS:
;  panel_select:     pointer to current panel
; 
;$LastChangedBy: jwl $
;$LastChangedDate: 2022-03-08 13:43:52 -0800 (Tue, 08 Mar 2022) $
;$LastChangedRevision: 30662 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/spedas_gui/panels/spd_ui_legend_options.pro $
;-


; function to return names of traces from panelObjs[selected_panel] 
; note that the 'legendtraces' keyword is passed when the user has changed
; one or more of the trace names manually
function spd_ui_legend_options_get_traces, panelObjs, selected_panel
   if obj_valid(panelObjs[selected_panel]) then begin
        panelObjs[selected_panel]->getproperty, tracesettings=ts
        traces=ts->get(/all)
        
        if obj_valid(traces[0]) then begin ; check that there are valid traces in the panel
            linesonthispanel=strarr(n_elements(traces))
            for i=0, n_elements(traces)-1 do begin
                traces[i]->getProperty, dataY=dY
                linesonthispanel[i]=dY
            endfor 
        endif
   endif
   if undefined(linesonthispanel) then linesonthispanel='None'
   return, linesonthispanel
end

; procedure to ensure settings are initialized correctly in the legend options window
pro spd_ui_legend_options_init, tlb, legendSettings, panel_select=panel_select
  compile_opt idl2, hidden
  
  Widget_Control, tlb, Get_UValue=pState
  state = *pState
  
  ; check that legend settings object is valid
  if ~obj_valid(legendSettings) then begin
      dprint, 'Error, no valid legendSettings object'
      return
  endif else begin
      ; Grab the settings from the legendSettings object
      legendSettings->getProperty, font=lfont, size=lsize, format=lformat, color=lfontcolor, $
        bgcolor=bgcolor, bordercolor=bordercolor, vspacing=vspacing, framethickness=lframethickness, $
        width=width, wValue=wValue, wUnit=wUnit, left=left, lValue=lValue, lUnit=lUnit, $
        bottom=bottom, bValue=bValue, bUnit=bUnit, height=height, hValue=hValue, hUnit=hUnit, $
        enabled=enabled, xAxisValue=xAxisLabel, xAxisValEnabled=xAxisValueEnabled, yAxisValue=yAxisLabel, $
        yAxisValEnabled=yAxisValueEnabled, traces=traces, xIsTime=xIsTime, yIsTime=yIsTime, $
        notationSet=notationSet, timeFormat=timeFormat, numFormat=numFormat
      
      ; is this legend enabled?
      legendenabled = widget_info(tlb,find_by_uname='legendenabled')
      Widget_Control, legendenabled, set_button=enabled

      ; desensitize everything if the legend is disabled or if this isn't a valid panel
      if(enabled eq 0 || state.validpanel eq 0) then begin
            sens=0
            bottom=0
            left=0
            height=0
            width=0
            xAxisValueEnabled=0
            yAxisValueEnabled=0
      endif else sens=1
      panellist = widget_info(tlb, find_by_uname='panelselected')
      if ptr_valid(panel_select) then widget_control, panellist, set_combobox_select = *panel_select
      
      ; Find the legend font widgets
      lcolorwindow = widget_info(tlb,find_by_uname='lcolorwindow')
      bgcolorwindow = widget_info(tlb,find_by_uname='bgcolorwindow')
      bordercolorwindow = widget_info(tlb,find_by_uname='bordercolorwindow')
      lfontcombo = widget_info(tlb,find_by_uname='lfontnames')
      lsizespinner = widget_info(tlb,find_by_uname='lfontsize')
      lformatc = widget_info(tlb,find_by_uname='lformatcombo')
      lthickness = widget_info(tlb,find_by_uname='framethickness')
      lvspacing = widget_info(tlb,find_by_uname='vspacing')
      bgpalette = widget_info(tlb,find_by_uname='bgpalette')
      fontpalette = widget_info(tlb,find_by_uname='lfontpalette')
      borderpalette = widget_info(tlb,find_by_uname='borderpalette')
      
      ; Find the placement widgets
      lbottombutton = widget_info(tlb,find_by_uname='botbutton')
      lleftbutton = widget_info(tlb,find_by_uname='leftbutton')
      lwidthbutton = widget_info(tlb,find_by_uname='widthbutton')
      lheightbutton = widget_info(tlb,find_by_uname='heightbutton')
      lbottomvalue = widget_info(tlb,find_by_uname='bvalue')
      lbottomunits = widget_info(tlb,find_by_uname='bunit')
      lleftvalue = widget_info(tlb,find_by_uname='lvalue')
      lleftunits = widget_info(tlb,find_by_uname='lunit')
      lwidthvalue = widget_info(tlb,find_by_uname='wvalue')
      lwidthunits = widget_info(tlb,find_by_uname='wunit')
      lheightvalue = widget_info(tlb,find_by_uname='hvalue')
      lheightunits = widget_info(tlb,find_by_uname='hunit')
      
      ; Find the variable name widgets
      lxAxisVal = widget_info(tlb,find_by_uname='newxaxisvalue')
      lyAxisVal = widget_info(tlb,find_by_uname='newyaxisvalue')
      lxAxisEnabled = widget_info(tlb,find_by_uname='xaxisenabled')
      lyAxisEnabled = widget_info(tlb,find_by_uname='yaxisenabled')
      ltraces = widget_info(tlb,find_by_uname='addtraces')
      tracestext = widget_info(tlb,find_by_uname='changetracename')
      
      ; Find the variable format widgets
      listofvars = widget_info(tlb,find_by_uname='varlist')
      listofformats = widget_info(tlb,find_by_uname='formcombo')
      autonot = widget_info(tlb,find_by_uname='autonotation')
      decnot = widget_info(tlb,find_by_uname='decnotation')
      scinot = widget_info(tlb,find_by_uname='scinotation')
      hexnot = widget_info(tlb,find_by_uname='hexnotation')
      
      ; placement widgets
      Widget_Control, lbottombutton, Set_Button=bottom, sensitive=sens
      Widget_Control, lleftbutton, Set_Button=left, sensitive=sens
      Widget_Control, lwidthbutton, Set_Button=width, sensitive=sens
      Widget_Control, lheightbutton, Set_Button=height, sensitive=sens
      
      Widget_Control, lbottomunits, sensitive=bottom, Set_Combobox_Select=bUnit
      Widget_Control, lbottomvalue, sensitive=bottom, set_value=bValue
      Widget_Control, lleftunits, sensitive=left, Set_Combobox_Select=lUnit
      Widget_Control, lleftvalue, sensitive=left, set_value=lValue
      Widget_Control, lwidthunits, sensitive=width, Set_Combobox_Select=wUnit
      Widget_Control, lwidthvalue, sensitive=width, set_value=wValue
      Widget_Control, lheightunits, sensitive=height, Set_Combobox_Select=hUnit
      Widget_Control, lheightvalue, sensitive=height, set_value=hValue
      ; reset combobox units to pts if the placement option isn't sensitized
      legendSettings->ResetPlacement, bunit=bUnit, lunit=lUnit, wunit=wUnit, hunit=hUnit
      
      ; variable name widgets
      Widget_Control, lxAxisVal, set_value=xAxisLabel, sensitive=xAxisValueEnabled
      Widget_Control, lyAxisVal, set_value=yAxisLabel, sensitive=yAxisValueEnabled
      Widget_Control, lxAxisEnabled, set_button=xAxisValueEnabled, sensitive=sens
      Widget_Control, lyAxisEnabled, set_button=yAxisValueEnabled, sensitive=sens
      Widget_Control, ltraces, sensitive=sens

      ; populate trace dropdown
      if ptr_valid(traces) then tracesstruct = *traces
      if ~undefined(tracesstruct) then BEGIN
        Widget_Control, ltraces, set_value=tracesstruct.traceNames
        Widget_Control, tracestext, set_value=(tracesstruct.traceNames)[0], sensitive=sens
      endif else begin
         tracesstruct = {panel:(ptr_valid(panel_select) ? *panel_select : 0), numTraces:0, traceNames:['']}
         linesonthispanel = spd_ui_legend_options_get_traces(state.panelObjs, *panel_select)
         tracesstruct.numTraces=n_elements(linesonthispanel)
        ; tracesstruct.panel = *panel_select+1
         str_element, tracesstruct, 'traceNames', linesonthispanel, /add_replace
        ; if obj_valid(legendSettings) then legendSettings->setProperty, traces=ptr_new(tracesstruct)
         Widget_Control, ltraces, set_value=linesonthispanel
         Widget_Control, tracestext, set_value=linesonthispanel[0], sensitive=sens
      endelse 

      ; colors
      Widget_Control, lcolorwindow, Get_Value=lcolorWin, sensitive=sens
      Widget_Control, bgcolorwindow, Get_Value=bgcolorWin, sensitive=sens
      Widget_Control, bordercolorwindow, Get_Value=bcolorWin, sensitive=sens
      
      ; font settings
      Widget_Control, lfontcombo, Set_Combobox_Select=lfont, sensitive=sens
      Widget_Control, lsizespinner, Set_Value=lsize, sensitive=sens
      Widget_Control, lformatc, Set_Combobox_Select=lformat, sensitive=sens
      Widget_Control, lthickness, Set_Value=lframethickness, sensitive=sens
      Widget_Control, lvspacing, Set_Value=vspacing, sensitive=sens
      Widget_Control, bgpalette, sensitive=sens
      Widget_Control, fontpalette, sensitive=sens
      Widget_Control, borderpalette, sensitive=sens
      
      formatvars = ['Time', 'Data']
      ; Variable format options
      Widget_Control, listofvars, set_value=formatvars, sensitive=sens
      Widget_Control, listofformats, get_value=flist, sensitive=sens
      varObj = obj_new('spd_ui_variable')
       
      currentvar = widget_info(listofvars, /combobox_gettext)
      if (currentvar eq 'Time') then formatValues = varObj->getFormats(/isTime) else formatValues = varObj->getFormats()
      
      Widget_Control, listofformats, set_value=formatValues
      if (currentvar eq 'Time') then Widget_Control, listofformats, set_combobox_select=timeFormat

      obj_destroy, varObj
      annoset = (sens eq 0 || (currentvar eq 'Time')) ? 0 : 1
      
      ; need to check if the notation was set by the user
      if (notationSet eq 0) then Widget_Control, autonot, sensitive=annoset, /set_button else Widget_Control, autonot, sensitive=annoset
      if (notationSet eq 1) then Widget_Control, decnot, sensitive=annoset, /set_button else Widget_Control, decnot, sensitive=annoset
      if (notationSet eq 2) then Widget_Control, scinot, sensitive=annoset, /set_button else Widget_Control, scinot, sensitive=annoset
      if (notationSet eq 4) then Widget_Control, hexnot, sensitive=annoset, /set_button else Widget_Control, hexnot, sensitive=annoset
      
      ; set font color
      scene=obj_new('IDLGRSCENE', color=lfontcolor)
      lcolorWin->setProperty,graphics_tree=scene
      lcolorWin->draw
      
      ; set background color
      bgscene=obj_new('IDLGRSCENE', color=bgcolor)
      bgcolorWin->setProperty,graphics_tree=bgscene
      bgcolorWin->draw
      
      ; set border color
      bscene=obj_new('IDLGRSCENE', color=bordercolor)
      bcolorWin->setProperty,graphics_tree=bscene
      bcolorWin->draw
  endelse
  if double(!version.release) lt 8.0d then heap_gc
end

; function to handle color changing events
function spd_ui_legend_options_color_event, tlb, fontcolorwin, currentcolor
  color = PickColor(!P.Color, Group_Leader=tlb, Cancel=canceled, $
    currentcolor=currentcolor)
    
  if canceled then color=currentcolor
  
  Widget_Control, fontcolorwin, Get_Value=colorWin
  if obj_valid(scene) then scene->remove,/all
  scene=obj_new('IDLGRSCENE', color=reform(color))
  colorWin->draw, scene
  
  return, color ; returns chosen color
end 

; function for syncing variable names droplist with variable name text box
function spd_ui_legend_options_update_varnames, tlb, legend
    legend->getProperty, traces=traces
    updatetrace = widget_info(tlb,find_by_uname='addtraces')
    ; find the currently selected element in the droplist
    idx_to_update = widget_info(updatetrace, /droplist_select)
    ; find the text box where the user can change a variable name
    tracename_txtbox = widget_info(tlb,find_by_uname='changetracename')
    widget_control, updatetrace, get_value=droplist_values
    widget_control, tracename_txtbox, get_value = newtrace_txt
    
    Widget_Control, tlb, Get_UValue=pState
    state = *pState
    if ptr_valid(traces) then begin
        tracesstruct = *traces
      
        if (tracesstruct.traceNames[0] ne 'None') then begin
            droplist_values[idx_to_update] = newtrace_txt
            widget_control, updatetrace, set_value=droplist_values
            widget_control, updatetrace, set_droplist_select=idx_to_update

            tracesstruct.traceNames = droplist_values
            tracesstruct.panel = *state.panel_select+1
            legend->UpdateTraces, tracesstruct
        endif
    endif else begin
         tracesstruct = {panel:0, numTraces:0, traceNames:['']}
         linesonthispanel = spd_ui_legend_options_get_traces(state.panelObjs, *state.panel_select)
         tracesstruct.panel = *state.panel_select+1

         if linesonthispanel[0] ne 'None' then begin
            droplist_values[idx_to_update] = newtrace_txt
            widget_control, updatetrace, set_value=droplist_values
            widget_control, updatetrace, set_droplist_select=idx_to_update
            tracesstruct.numTraces=n_elements(linesonthispanel)
            str_element, tracesstruct, 'tracenames', linesonthispanel, /add_replace
            legend->UpdateTraces, tracesstruct
         endif
    endelse
    return, legend
end

pro spd_ui_legend_options_event, event
  COMPILE_OPT hidden

  Widget_Control, event.top, Get_UValue=pState
  state = *pState

  ;Put a catch here to ensure that the state remains defined
  err_xxx = 0
  Catch, err_xxx
  IF (err_xxx NE 0) THEN BEGIN
    Catch, /Cancel
    Help, /Last_Message, Output = err_msg
    
    spd_ui_sbar_hwin_update, state, err_msg, /error, err_msgbox_title='Error in Legend Options'
    
    Widget_Control, event.TOP, Set_UValue=state, /No_Copy
    widget_control, event.top,/destroy
    RETURN
  ENDIF
  
  if obj_valid(state.panelObjs[*state.panel_select]) then begin
      state.panelObjs[*state.panel_select]->getProperty, legendSettings=legend
      state.legendSettings = legend
  endif else begin
      state.historyWin->Update, 'SPD_UI_LEGEND_OPTIONS: No valid legend object.'
      state.statusBar->Update, 'SPD_UI_LEGEND_OPTIONS: No valid legend object.'
  endelse 
  
  ; kill request block
  IF (Tag_Names(event, /Structure_Name) EQ 'WIDGET_KILL_REQUEST') THEN BEGIN
    state.historyWin->Update,'SPD_UI_LEGEND_OPTIONS: Legend Options window killed.'
    state.statusBar->update,'Legend Options killed'
    state.tlb_statusBar->update,'Legend Options killed'
    
    ; reset original settings
    if(obj_valid(state.origlegendSettings) && obj_valid(legend)) then begin
        ; check the legend we're restoring
        state.origlegendSettings->getProperty, traces=the_tracesptr

        state.legendSettings->getProperty, traces=curr_panel_traces
        ; make sure this is the correct panel
        if ptr_valid(curr_panel_traces) && ptr_valid(the_tracesptr) && ((*curr_panel_traces).panel eq (*the_tracesptr).panel) then begin
            state.legendSettings=state.legendSettings->RestoreBackup(state.origlegendSettings)
        endif
    endif 

    dprint, dlevel=4, 'Legend Options widget killed'
    ; free the pointer to the state before closing the window
    if(ptr_valid(pState)) then ptr_free, pState
    Widget_Control, event.top, /Destroy
    if double(!version.release) lt 8.0d then heap_gc
    RETURN
  ENDIF
  
  Widget_Control, event.id, Get_UValue=uval
  
  IF size(uval, /Type) NE 0 THEN BEGIN
    CASE uval OF
        'OK': BEGIN ; user hit 'OK'
            ; update page
            if (obj_valid(legend) && obj_valid(state.origLegendSettings)) then begin
                ; query the variable name text box and update the trace names appropriately
                upd_legend = spd_ui_legend_options_update_varnames(event.top, legend)
              
                state.origLegendSettings=upd_legend->BackupSettings(state.origLegendSettings)
            endif 
            state.drawObject->update,state.windowStorage,state.loadedData
            state.drawObject->draw
            state.historyWin->update,'Changes applied to legend'
            state.statusBar->update,'Changes applied to legend'
            state.tlb_statusbar->update, 'Changes applied to legend'
            
            ; free the pointer to the state before closing the window
            if(ptr_valid(pState)) then ptr_free, pState
            Widget_Control, event.top, /destroy
            if double(!version.release) lt 8.0d then heap_gc
            RETURN
        END
        'APPLY': BEGIN ; user hit 'Apply'
            ; create a backup, in case the user hits 'Cancel' after hitting 'Apply'
            if (obj_valid(legend) && obj_valid(state.origLegendSettings)) then begin
              ; query the variable name text box and update the trace names appropriately
              upd_legend = spd_ui_legend_options_update_varnames(event.top, legend)
              
              state.origLegendSettings=upd_legend->BackupSettings(state.origLegendSettings)
              
              state.drawObject->update,state.windowStorage,state.loadedData
              state.drawObject->draw
              state.historyWin->update,'Changes applied to legend'
              state.statusBar->update,'Changes applied to legend'
            endif
        END
        'APPALL': BEGIN
            if obj_valid(state.panelObjs[0]) then begin
                ; query the variable name text box and update the trace names appropriately
                ; only update the traces in this panel, though. 
                upd_legend = spd_ui_legend_options_update_varnames(event.top, legend)
                
                ; loop through panels, saving current settings to each
                for i=0, n_elements(state.panelObjs)-1 do begin
                    state.panelObjs[i]->getProperty, legendSettings=plegend
                    legend->CopyContents, plegend
                endfor
                
                state.origLegendSettings=upd_legend->BackupSettings(state.origLegendSettings)
                
                state.drawObject->update,state.windowStorage,state.loadedData
                state.drawObject->draw
                state.historyWin->update,'Changes applied to all legends'
                state.statusBar->update,'Changes applied to all legends'
            endif else begin
                state.historyWin->update, 'No valid panels'
                state.statusBar->update, 'No valid panels'
            endelse
        END
        'CANC': BEGIN ; user canceled
            state.historyWin->Update, 'Legend Options window canceled.'
            state.statusBar->update,'Legend Options canceled'
            state.tlb_statusbar->update, 'Legend Options canceled'
            
            ;state.origLegendSettings->getProperty, traces=otraces
            
            ; reset original settings
            if(obj_valid(state.origlegendSettings) && obj_valid(legend)) then begin
                ; check the legend we're restoring
                state.origlegendSettings->getProperty, traces=the_tracesptr
                
                ; make sure this is the correct panel
                legend->getproperty, traces=curr_panel_traces
                if ptr_valid(curr_panel_traces) && ptr_valid(the_tracesptr) && ((*curr_panel_traces).panel eq (*the_tracesptr).panel) then begin
                    legend=legend->RestoreBackup(state.origlegendSettings)
                endif
            endif

            ; free the pointer to the state before closing the window
            if(ptr_valid(pState)) then ptr_free, pState
            Widget_Control, event.top, /Destroy
            if double(!version.release) lt 8.0d then heap_gc
            RETURN
        END
        'LFSIZE': BEGIN ; user changed font size
            if (event.value gt 0) then begin
                if(obj_valid(state.legendSettings)) then begin
                    state.legendSettings->setProperty, size=event.value
                endif
            endif else begin
                state.historyWin->Update, 'Invalid font size entered.'
                state.statusBar->Update, 'Invalid font size entered.'
            endelse
        END
        'LFONTNAMES': BEGIN ; user changed font family
            if(obj_valid(state.legendSettings)) then begin
                state.legendSettings->setProperty, font=event.index
            endif
        END
        'FFORMAT': BEGIN ; user changed font format/style
            if(obj_valid(state.legendSettings)) then begin
                state.legendSettings->setProperty, format=event.index
            endif
        END
        'LFONTPALETTE': BEGIN ; user opened font color palette
            state.legendSettings->getProperty, color = currentcolor
            fcolor = spd_ui_legend_options_color_event(state.tlb, state.lcolorwindow, currentcolor)
            state.legendSettings->setProperty, color = fcolor
        END
        'BGPALETTE': BEGIN ; user opened background color palette
            state.legendSettings->getProperty, bgcolor = currentbgcolor
            newbgcolor = spd_ui_legend_options_color_event(state.tlb, state.bgcolorwindow, currentbgcolor)
            state.legendSettings->setProperty, bgcolor=newbgcolor
        END
        'BORDERPALETTE': BEGIN ; user opened border color palette
            state.legendSettings->getProperty, bordercolor = currentbordercolor
            newbordercolor = spd_ui_legend_options_color_event(state.tlb, state.bordercolorwindow, currentbordercolor)
            state.legendSettings->setProperty, bordercolor=newbordercolor
        END
        'FRAMETHICKNESS': BEGIN ; user changed legend border thickness
            if(obj_valid(state.legendSettings)) then begin
                if(event.value ge 1 and event.value le 10) then begin
                  state.legendSettings->setProperty, framethickness=event.value
                endif else begin
                  state.historyWin->Update, 'Invalid legend frame thickness entered.'
                  state.statusBar->Update, 'Invalid legend frame thickness entered.'
                endelse
            endif
        END
        'VSPACING': BEGIN ; user changed vertical spacing in legend
            if(obj_valid(state.legendSettings)) then begin
                state.legendSettings->setProperty, vspacing=event.value
            endif
        END
        'TEMP': BEGIN ; user wants to save to a template
            if(obj_valid(state.legendSettings) && obj_valid(state.template)) then begin
                new_legend_template = state.legendSettings->copy()
                
                if obj_valid(new_legend_template) then begin
                    ; make sure customTracesset is set to 0, since we don't save custom trace names
                    new_legend_template->setProperty, customTracesset = 0
                
                    ; save the new legend to the global template
                    state.template->setProperty, legend=new_legend_template
                
                    state.historywin->update,'Current legend options stored for use in a Template'
                    state.statusBar->update,'Current legend options stored for use in a Template'                    

                    messageString = 'These values have now been stored!' +  string(10B) + string(10B) + 'To save them in a template, click File->Graph Options Template->Save Template'
                    response=dialog_message(messageString,/CENTER, /information)
                    
                endif else begin
                    state.historywin->update, 'Problem copying legend options.'
                    state.statusBar->update, 'Problem copying legend options.'
                endelse
            endif else begin
               state.historywin->update,'Cannot store options. Needs a valid legend to store options for a template.'
               state.statusBar->update,'Cannot store options. Needs a valid legend to store options for a template.'
            endelse
        END
        'PANELSELECTED': BEGIN ; user clicked panel dropdown
             *state.panel_select = event.index
             if obj_valid(state.panelObjs[event.index]) then state.panelObjs[event.index]->getProperty, legendSettings=leg

             if obj_valid(leg) then begin
                 leg->getProperty,customTracesset=customTracesset, traces=thetraces
   
                 spd_ui_legend_options_init, state.tlb, leg, panel_select=state.panel_select
             endif
        END
        'BOTBUTTON': BEGIN ; user clicked 'bottom' placement button
             legend->setProperty, bottom=event.select
             lbottomvalue = widget_info(state.tlb,find_by_uname='bvalue')
             lbottomunits = widget_info(state.tlb,find_by_uname='bunit')
             widget_control, lbottomvalue, sensitive=event.select
             widget_control, lbottomunits, sensitive=event.select
        END
        'LEFTBUTTON': BEGIN ; user clicked 'left' placement button
             legend->setProperty, left=event.select
             lleftvalue = widget_info(state.tlb, find_by_uname='lvalue')
             lleftunits = widget_info(state.tlb, find_by_uname='lunit')
             widget_control, lleftvalue, sensitive=event.select
             widget_control, lleftunits, sensitive=event.select
        END
        'WIDTHBUTTON': BEGIN ; user clicked 'width' placement button
             legend->setProperty, width=event.select
             lwidthvalue = widget_info(state.tlb, find_by_uname='wvalue')
             lwidthunits = widget_info(state.tlb, find_by_uname='wunit')
             widget_control, lwidthvalue, sensitive=event.select
             widget_control, lwidthunits, sensitive=event.select
        END
        'HEIGHTBUTTON': BEGIN ; user clicked 'height' placement button
             legend->setProperty, height=event.select
             lheightvalue = widget_info(state.tlb, find_by_uname='hvalue')
             lheightunits = widget_info(state.tlb, find_by_uname='hunit')
             widget_control, lheightvalue, sensitive=event.select
             widget_control, lheightunits, sensitive=event.select
        END
        'BVALUE': BEGIN ; user changed bottom placement value
            if (event.valid and event.value ge 0) then begin
                legend->setProperty, bValue=event.value
            endif
        END
        'LVALUE': BEGIN ; user changed left placement value
            if (event.valid and event.value ge 0) then begin
                legend->setProperty, lValue=event.value
            endif
        END
        'WVALUE': BEGIN ; user changed width placement value
            if (event.valid and event.value ge 0) then begin
                legend->setProperty, wValue=event.value
            endif
        END
        'HVALUE': BEGIN ; user changed height placement value
            if (event.valid and event.value ge 0) then begin
                legend->setProperty, hValue=event.value
            endif
        END
        'BUNIT': BEGIN ; user changed bottom placement units
            if ~undefined(event.index) then begin
                legend->setProperty, bUnit=event.index
                legend->getProperty, bValue=bValue
                id = widget_info(state.tlb,find_by_uname='bvalue')
                widget_control, id, set_value=strcompress(string(bvalue), /remove_all) 
            endif
        END
        'LUNIT': BEGIN ; user changed left placement units
            if ~undefined(event.index) then begin
                legend->setProperty, lUnit=event.index
                legend->getProperty, lValue=lValue
                id = widget_info(state.tlb,find_by_uname='lvalue')
                widget_control, id, set_value=strcompress(string(lvalue), /remove_all)
            endif
        END
        'WUNIT': BEGIN ; user changed width placement units
            if ~undefined(event.index) then begin
                legend->setProperty, wUnit=event.index
                legend->getProperty, wValue=wValue
                id = widget_info(state.tlb,find_by_uname='wvalue')
                widget_control, id, set_value=strcompress(string(wValue), /remove_all)
            endif
        END
        'HUNIT': BEGIN ; user changed height placement units
            if ~undefined(event.index) then begin
                legend->setProperty, hUnit=event.index
                legend->getProperty, hValue=hValue
                id = widget_info(state.tlb,find_by_uname='hvalue')
                widget_control, id, set_value=strcompress(string(hValue), /remove_all)
            endif
        END
        'XAXISENABLED': BEGIN ; user clicked 'X axis label' enable/disable button
            if(event.select eq 0) then begin ; X axis label was disabled
                legend->setProperty, xAxisValEnabled=0
                xaxislabel=widget_info(event.top,find_by_uname='newxaxisvalue')
                widget_control, xaxislabel, sensitive=0
            endif else begin ; X axis label was enabled 
                legend->setProperty, xAxisValEnabled=1
                xaxislabel=widget_info(event.top,find_by_uname='newxaxisvalue')
                widget_control, xaxislabel, sensitive=1
            endelse
        END
        'YAXISENABLED': BEGIN ; user clicked 'Y axis label' enable/disable button
            if(event.select eq 0) then begin ; Y axis label was disabled
                legend->setProperty, yAxisValEnabled=0
                yaxislabel=widget_info(event.top,find_by_uname='newyaxisvalue')
                widget_control, yaxislabel, sensitive=0
            endif else begin ; Y axis label was enabled
                legend->setProperty, yAxisValEnabled=1
                yaxislabel=widget_info(event.top,find_by_uname='newyaxisvalue')
                widget_control, yaxislabel, sensitive=1
            endelse
        END
        'LEGENDENABLED': BEGIN ; user enabled/disabled legend
            if(event.select eq 0) then begin ; legend was disabled
                legend->setProperty, enabled=0
                state.historyWin->update,'Legend disabled.'
                state.statusBar->update,'Legend disabled.'
                state.tlb_statusbar->update, 'Legend disabled.'
            endif else begin ; legend was enabled
                legend->setProperty, enabled=1
                state.historyWin->update,'Legend enabled.'
                state.statusBar->update,'Legend enabled.'
                state.tlb_statusbar->update, 'Legend enabled.'
            endelse    
            spd_ui_legend_options_init, state.tlb, legend, panel_select=state.panel_select
        END
        'NEWXAXISVALUE': BEGIN ; user changed X axis value
            widget_control, event.id, get_value=xlabel
            legend->setProperty, xAxisValue=xlabel
        END
        'NEWYAXISVALUE': BEGIN ; user changed Y axis value
            widget_control, event.id, get_value=ylabel
            legend->setProperty, yAxisValue=ylabel
        END
        'ADDTRACES': BEGIN ; user changed which trace is displayed in dropdown box
            newTrace = widget_info(event.top,find_by_uname='changetracename')
            
            ; get the list of values
            widget_control, event.id, get_value=droplist_values

            ; and the current index
            droplist_selection = widget_info(event.id, /droplist_select)
            ; update the text box
            Widget_Control, newTrace, set_value=droplist_values[droplist_selection]
        END 
        'CHANGETRACENAME': BEGIN ; user changed currently selected trace name
            pd_varnames = spd_ui_legend_options_update_varnames(event.top, state.legendSettings)
        END
        'AUTONOTATION': BEGIN ; user clicked auto-notation button
            legend->setProperty, notationSet=0
        END
        'DECNOTATION': BEGIN ; user clicked decimal notation button
            legend->setProperty, notationSet=1
        END
        'HEXNOTATION': BEGIN ; user clicked hexadecimal notation button
          legend->setProperty, notationSet=4
        END
        'SCINOTATION': BEGIN ; user clicked scientific notation button
            legend->setProperty, notationSet=2
        END
        'FORMCOMBO': BEGIN ; user clicked the format combobox
            id = widget_info(state.tlb,find_by_uname='varlist')
            currentvar = widget_info(id, /combobox_gettext)     

            legend->getProperty, timeFormat=timeFormat, numFormat=numFormat
            
            if (currentvar eq 'Time') then begin
                ; variable being changed is time
                legend->setProperty, timeFormat=event.index
            endif else begin
                legend->setProperty, numFormat=event.index
            endelse
        END
        'VARLIST': BEGIN ; user selected variable type 
             id = widget_info(state.tlb,find_by_uname='varlist')
             idform = widget_info(state.tlb, find_by_uname='formcombo')
             autonot = widget_info(state.tlb,find_by_uname='autonotation')
             decnot = widget_info(state.tlb,find_by_uname='decnotation')
             hexnot = widget_info(state.tlb,find_by_uname='hexnotation')
             scinot = widget_info(state.tlb,find_by_uname='scinotation')
             idtext = widget_info(id, /combobox_gettext)
             varObj = obj_new('SPD_UI_VARIABLE')
             
             legend->getProperty, timeFormat=timeFormat, numFormat=numFormat, notationSet=notationSet
             
             if (idtext eq 'Time') then begin
                formatValues = varObj->getFormats(/isTime)
                widget_control, idform, set_value=formatValues 
                widget_control, idform, set_combobox_select=timeFormat
             endif else begin
                formatValues = varObj->getFormats()
                widget_control, idform, set_value=formatValues
                widget_control, idform, set_combobox_select=numFormat
                if (notationSet eq 0) then widget_control, autonot, /set_button
                if (notationSet eq 1) then widget_control, decnot, /set_button
                if (notationSet eq 2) then widget_control, scinot, /set_button
                if (notationSet eq 4) then widget_control, hexnot, /set_button
             endelse
             
             annoset = (idtext eq 'Time') ? 0 : 1
        
             Widget_Control, autonot, sensitive=annoset
             Widget_Control, decnot, sensitive=annoset
             Widget_Control, scinot, sensitive=annoset
             Widget_Control, hexnot, sensitive=annoset
             obj_destroy, varObj
        END
        ELSE: dprint, 'Legend options: feature not implemented yet: '+uval
             
    ENDCASE
  ENDIF 

end

pro spd_ui_legend_options, info, panel_select=panel_select, tlb_statusbar=tlb_statusbar
   ; handle and report errors
   err_xxx = 0
   Catch, err_xxx
   IF(err_xxx NE 0) THEN BEGIN
     Catch, /Cancel
     Help, /Last_Message, Output=err_msg
     FOR j = 0, N_Elements(err_msg)-1 DO Begin
       dprint, dlevel=1,  err_msg[j]
       If(obj_valid(info.historywin)) Then info.historyWin -> update, err_msg[j]
     Endfor
     dprint, dlevel=1, 'Error--See history'
     ok = error_message('An unknown error occured starting legend options. See console for details.',$
       /noname, /center, title='Error in Legend Options')
     spd_gui_error, info.master, info.historywin
     RETURN
   ENDIF

   tlb_statusbar->update,'Legend Options opened'
   info.historyWin->update,'Legend Options opened'
   
   ; get list of panels
   ; Note that IDL passes keywords by reference, so the 
   ; valid panel objects will be returned in panelObjs
   cWindow = info.windowStorage->getActive()
   panelObjs = obj_new('spd_ui_panel')
   panelNames = spd_ui_get_panels(cWindow, panelObjs=panelObjs)
   
   if ~ptr_valid(panel_select) then panel_select = ptr_new(0)
   
   ; we need a text object to query font and format names
   if ~obj_valid(textsettings) then textsettings = obj_new('spd_ui_text')
   panelsettings = obj_new('spd_ui_panel_settings')
   if obj_valid(panelsettings) then placementunits = panelsettings->GetUnitNames()
   obj_destroy, panelsettings
   
   ; get a list of fonts and formats from the text object
   fontValues = textsettings->getFonts()
   formatValues = textsettings->getFormats()
   
   if obj_valid(panelObjs[*panel_select]) then panelObjs[*panel_select]->getProperty, legendSettings=legendSettings else legendSettings = obj_new('spd_ui_legend')
 
   ; get current legend settings
   legendSettings->getProperty, size=lfontsize, font=lfont, color=lfontcolor, format=lfontformat, $
        vspacing=vspacing, bgcolor=bgcolor, framethickness=framethickness, bordercolor=bordercolor, $
        enabled=enabled, bottom=lbottom, left=lleft, width=lwidth, height=lheight, bValue=bValue, $
        lValue=lValue, wValue=wValue, hValue=hValue, bUnit=bUnit, lUnit=lUnit, wUnit=wUnit, hUnit=hUnit, $
        xAxisValue=xAxisValue, xAxisValEnabled=xAxisValEnabled, yAxisValue=yAxisValue, yAxisValEnabled=yAxisValEnabled, $
        traces=legendtraces, customTracesset=customTracesset
   

   if(panelNames eq ['No Panels']) then begin
       validpanel=0 ; if there are no valid panels, desensitize everything
   endif else begin
       validpanel=1
   endelse
   
    if customTracesset eq 0 then begin
        ; create a structure to store trace information
        tracesstruct = {panel:0, numTraces:0, traceNames:['']}
        linesonthispanel = spd_ui_legend_options_get_traces(panelObjs, *panel_select)
        tracesstruct.numTraces=n_elements(linesonthispanel)
        tracesstruct.panel = *panel_select+1
        str_element, tracesstruct, 'traceNames', linesonthispanel, /add_replace
        if obj_valid(legendSettings) then legendSettings->UpdateTraces, tracesstruct
       
    endif else begin
        ;legendsettings->getproperty, traces=oldtraces
        if ptr_valid(legendtraces) then linesonthispanel = (*legendtraces).tracenames
    endelse

   if undefined(linesonthispanel) then linesonthispanel='None'
   if n_elements(linesonthispanel) gt 1 then currentline = linesonthispanel[0] else currentline = linesonthispanel

   tlb = Widget_Base(/Col, Title='Legend Options', Group_Leader=info.master, /Modal, $
        /Floating, /tlb_kill_request_events, tab_mode=1)
        
   getresourcepath,rpath
   palettebmp = read_bmp(rpath + 'color.bmp', /rgb)
   spd_ui_match_background, tlb, palettebmp
   
   combobox_xsize = 145 ; xsize of most of our dropdowns
   
   ; Base widgets for legend options
   mainBase = Widget_Base(tlb, /Col)
   panellist = Widget_Base(mainBase, Row=1)   
     
   ; Create the panel list
   plistlabel = Widget_Label(panellist, value=' Panel: ', /Align_Left)
   plistcombo = Widget_Combobox(panellist, value=panelNames, uvalue='PANELSELECTED', uname='panelselected', /Align_Center)
   plistenabled = Widget_Base(panellist, /NonExclusive)
   plistButton = Widget_Button(plistenabled, value='Legend Enabled?', uvalue='LEGENDENABLED', uname='legendenabled', sensitive=validpanel)
   widget_control, plistButton, set_button=1 ; legend enabled by default

   ; More base widgets for font/background options
   lblrowbase = Widget_Base(mainBase, Row=1)
   mainButtonBase = Widget_Base(tlb, /Row, /Align_Center)
   layoutBase = Widget_Base(mainBase, /Row)
   fontBase = Widget_Base(layoutBase, Row=4, Frame=3)
   bBase = Widget_Base(layoutBase, Row=5, frame=3)
   bgBase = Widget_Base(bBase, Row=2)
    
   legendlabel = Widget_Label(lblrowbase, value=' Font options:', /Align_Left)
   bkgdlabel = Widget_Label(lblrowbase, value=' Frame options:', /Align_Left)
   
   ; Legend font type widgets
   fnamelabel = Widget_Label(fontBase, value=' Name:', /Align_Left, sensitive=validpanel)
   fontTitleDroplist = Widget_Combobox(fontbase, Value=fontValues, $
        uval='LFONTNAMES',uname='lfontnames', sensitive=validpanel)
   Widget_Control, fontTitleDroplist, set_combobox_select=lfont ; select the correct font
   
   ; Legend font size widgets
   fontsizelabel = Widget_Label(fontBase, value=' Size:', /Align_Left, sensitive=validpanel)
   FontIncBase = Widget_Base(fontBase, /col)
   FontIncrement = spd_ui_spinner(FontIncBase, incr=1, uval='LFSIZE', uname='lfontsize', $
        min_value=1, value=lfontsize, sensitive=validpanel)
   
   ; Legend font color widgets
   fcolorlabelBase = Widget_Base(fontbase, row=1)
   fcolorlabel = Widget_Label(fcolorlabelBase, value=' Color:', /Align_Left, sensitive=validpanel)
   fontpaletteButton = Widget_Button(fcolorlabelBase, Value=palettebmp, /Bitmap, $
        UValue='LFONTPALETTE', uname='lfontpalette', Tooltip=' Choose font color from palette', sensitive=validpanel)
   geo_struct = Widget_Info(fontpaletteButton,/geometry)
   rowysize = geo_struct.scr_ysize
   lcolorWindow = Widget_Draw(fcolorlabelBase, XSIZE=50, YSize=rowysize,uname='lcolorwindow', $
        graphics_level=2,renderer=1,retain=1,units=0,frame=1, /expose_events, sensitive=validpanel)
  
   ; Legend font format widgets
   fformatBase = Widget_Base(fontbase, row=1)
   fformatlabel = Widget_Label(fformatBase, value=' Format:', /Align_Left, sensitive=validpanel)
   fontFormatDroplist = Widget_Combobox(fformatBase, Value=formatValues, $
        uval='FFORMAT',uname='lformatcombo', sensitive=validpanel)
   Widget_Control, fontFormatDroplist, set_combobox_select=lfontformat 

   ; Legend background color widgets
   bckgndcolorlabel = Widget_Label(bgBase, Value=' Background Color:', /Align_Left, sensitive=validpanel)
   bgpaletteButton = Widget_Button(bgBase, Value=palettebmp, /Bitmap, UValue='BGPALETTE', $
        uname='bgpalette', Tooltip=' Choose background color from palette', sensitive=validpanel)
   geo_struct = widget_info(bgpaletteButton,/geometry)
   rowysize = geo_struct.scr_ysize
   bgcolorWindow = Widget_Draw(bgBase, XSIZE=50, YSize=rowysize,uname='bgcolorwindow', $
        graphics_level=2,renderer=1,retain=1,units=0,frame=1, /expose_events, sensitive=validpanel)

   ; Legend border color widgets
   bordercolorlabel = Widget_Label(bgBase, Value=' Border Color:', /Align_Left, sensitive=validpanel)
   borderpaletteButton = Widget_Button(bgBase, Value=palettebmp, /Bitmap, UValue='BORDERPALETTE', $
        uname='borderpalette', Tooltip=' Choose border color from palette', sensitive=validpanel)
   geo_struct = widget_info(borderpaletteButton,/geometry)
   rowysize = geo_struct.scr_ysize
   bordercolorWindow = Widget_Draw(bgBase, XSIZE=50, YSize=rowysize,uname='bordercolorwindow', $
        graphics_level=2,renderer=1,retain=1,units=0,frame=1, /expose_events, sensitive=validpanel)
   
   ; Legend border thickness widgets
   spinnerBase = Widget_Base(bBase, Row=2)
   framethicknesslabel = Widget_Label(spinnerBase, Value=' Frame Thickness:', /Align_Left, sensitive=validpanel)
   thicknessIncBase = Widget_Base(spinnerBase, /col)
   thicknessIncrement = spd_ui_spinner(thicknessIncBase, incr=1, uval='FRAMETHICKNESS', $
        uname='framethickness', min_value=1, value=framethickness, max_value=10, sensitive=validpanel)
   
   ; Widgets for vertical spacing of text on legends
   vspacinglabel = Widget_Label(spinnerBase, Value=' Vertical Spacing:', /Align_Left, sensitive=validpanel)
   vspacingIncBase = Widget_Base(spinnerBase, /col)
   vspacingIncrement = spd_ui_spinner(vspacingIncBase, incr=1, uval='VSPACING', uname='vspacing', $
        min_value=1, value=vspacing, sensitive=validpanel)

   ; beginning of placement stuff
   lblPos = Widget_Base(mainBase, Row=1)
   placementlabel = Widget_Label(lblPos, value=' Placement: ', /Align_Left)
   varnamelabel = Widget_Label(lblPos, value=' Variable names: ', /Align_Left)
   
   ; Base widgets for placement of legend
   posBase = Widget_Base(mainBase, Row=1)
   positionBase = Widget_Base(posBase, row=4, Frame=3)
   sBase1 = Widget_Base(positionBase, /col, /nonexclusive)
   spinnerBase1 = Widget_Base(positionBase, /col)
   unitsBase1 = Widget_Base(positionBase, /col)
   sBase2 = Widget_Base(positionBase, /col, /nonexclusive)
   spinnerBase2 = Widget_Base(positionBase, /col)
   unitsBase2 = Widget_Base(positionBase, /col)
   sBase3 = Widget_Base(positionBase, /col, /nonexclusive)
   spinnerBase3 = Widget_Base(positionBase, /col)
   unitsBase3 = Widget_Base(positionBase, /col)
   sBase4 = Widget_Base(positionBase, /col, /nonexclusive)
   spinnerBase4 = Widget_Base(positionBase, /col)
   unitsBase4 = Widget_Base(positionBase, /col)
   varNameBase = Widget_Base(posBase, Col=1, Frame=3)
  
  placementcombosize = 55
  placementunitsize = 45
   ; create placement widgets
   plBottom = Widget_Button(sBase1, Value=' Bottom: ', uval='BOTBUTTON', uname='botbutton', sensitive=validpanel)
   bottomSpinner = spd_ui_spinner(spinnerBase1, increment=1, uval='BVALUE', uname='bvalue', min_value=0, sensitive=validpanel, value=bvalue)
   botDropDown = Widget_Combobox(unitsBase1, uval='BUNIT', uname='bunit', value=placementunits, sensitive=validpanel)
   plLeft = Widget_Button(sBase2, Value=' Left: ', uval='LEFTBUTTON', uname='leftbutton', sensitive=validpanel)
   leftSpinner = spd_ui_spinner(spinnerBase2, increment=1, uval='LVALUE', uname='lvalue', min_value=0, sensitive=validpanel, value=lvalue)
   leftDropDown = Widget_Combobox(unitsBase2, uval='LUNIT', uname='lunit', value=placementunits, sensitive=validpanel)
   plWidth = Widget_Button(sBase3, Value=' Width: ', uval='WIDTHBUTTON', uname='widthbutton', sensitive=validpanel)
   widthSpinner = spd_ui_spinner(spinnerBase3, increment=1, uval='WVALUE', uname='wvalue', min_value=0, sensitive=validpanel, value=wvalue)
   widthDropDown = Widget_Combobox(unitsBase3, uval='WUNIT', uname='wunit', value=placementunits, sensitive=validpanel)
   plHeight = Widget_Button(sBase4, Value=' Height: ', uval='HEIGHTBUTTON', uname='heightbutton', sensitive=validpanel)
   heightSpinner = spd_ui_spinner(spinnerBase4, increment=1, uval='HVALUE', uname='hvalue', min_value=0, sensitive=validpanel, value=hvalue)
   heightDropDown = Widget_Combobox(unitsBase4, uval='HUNIT', uname='hunit', value=placementunits, sensitive=validpanel)
   
   ; create variable name widgets
   xnamelabel = Widget_Label(varNameBase, value=' X Axis Value:', /Align_Left, sensitive=validpanel)
   xAxisBase = Widget_Base(varNameBase, /Row)
   xnametext = Widget_Text(xAxisBase, value='X Axis Value', /editable, xsize=30, sensitive=validpanel, uval='NEWXAXISVALUE', uname='newxaxisvalue', /all_events)
   xAxisBaseNE = Widget_Base(xAxisBase, /NonExclusive)
   xAxisButton = Widget_Button(xAxisBaseNE, Value='Enabled?', sensitive=validpanel, uval='XAXISENABLED', uname='xaxisenabled')
   widget_control, xAxisButton, set_button=NEWXAXISVALUE
   ynamelabel = Widget_Label(varNameBase, value=' Y Axis Value:', /Align_Left, sensitive=validpanel)
   yAxisBase = Widget_Base(varNameBase, /Row)
   ynametext = Widget_Text(yAxisBase, value='Y Axis Value', /editable, xsize=30, sensitive=validpanel, uval='NEWYAXISVALUE', uname='newyaxisvalue', /all_events)
   yAxisBaseNE = Widget_Base(yAxisBase, /NonExclusive)
   yAxisButton = Widget_Button(yAxisBaseNE, Value='Enabled?', sensitive=validpanel, uval='YAXISENABLED', uname='yaxisenabled')
   widget_control, yAxisButton, set_button=1
   
   ; change trace/line names, e.g., thd_fgs_bz -> FGS Bz
   tracesBase = Widget_Base(varNameBase, /Row)
   ;additionalLabels = Widget_Combobox(tracesBase, value='None', sensitive=validpanel, SCR_XSIZE=105, uval='ADDTRACES', uname='addtraces')
   additionalLabels = Widget_Droplist(tracesBase, value='None', sensitive=validpanel, uval='ADDTRACES', uname='addtraces',/dynamic_resize)
   changetraces = Widget_Text(tracesBase, value=currentline, uval='CHANGETRACENAME', uname='changetracename',xsize=30, /editable)
      
   formatBase = Widget_Base(mainBase, Row=2)
   formatLabel = Widget_Label(formatBase, value=' Variable format:')   
   fBase = Widget_Base(formatBase, Row=2, Frame=3, /base_align_center)
   varformatBase = Widget_Base(fBase, Row=1)
   ;nullLabel = Widget_Label(varformatBase, value=' ', SCR_XSIZE=5)
   varlistLabel = Widget_Label(varformatBase, value=' For all variables of type: ', sensitive=validpanel)
   varlistCombo = Widget_Combobox(varformatBase, uval='VARLIST', uname='varlist', sensitive=validpanel)
   nullLabel = Widget_Label(varformatBase, value=' ')
   formatLabel = Widget_Label(varformatBase, value=' Set format: ', sensitive=validpanel)
   formatCombo = Widget_Combobox(varformatBase, uval='FORMCOMBO', uname='formcombo', sensitive=validpanel)
   
   notationBase1 = Widget_Base(fBase, row=1)  
   nullLabel1 = Widget_Label(notationBase1, value=' ')
   notationBase = Widget_Base(notationBase1, /exclusive, row=1)  
   autoNotation = Widget_Button(notationBase, value=' Auto-Notation', sensitive=validpanel, uval='AUTONOTATION', uname='autonotation')
   decNotation = Widget_Button(notationBase, value=' Decimal ', sensitive=validpanel, uval='DECNOTATION', uname= 'decnotation')
   sciNotation = Widget_Button(notationBase, value=' Scientific ', sensitive=validpanel, uval='SCINOTATION', uname='scinotation')
   hexNotation = Widget_Button(notationBase, value=' Hexadecimal ', sensitive=validpanel, uval='HEXNOTATION', uname= 'hexnotation')
   
   Widget_Control, autoNotation, /set_button
   
   ; Simple button widgets
   okButton = Widget_Button(mainButtonBase, Value='OK', Uvalue='OK')
   applyButton = Widget_Button(mainButtonBase, Value='Apply', Uvalue='APPLY')
   applytoallButton = Widget_Button(mainButtonBase, Value='Apply to All Panels', Tooltip='Apply settings to the legends of all panels.', UValue='APPALL')
   cancelButton = Widget_Button(mainButtonBase, Value='Cancel', UValue='CANC')
   templateButton = Widget_Button(mainButtonBase, Value='Store for a Template', UValue='TEMP',tooltip='Use these settings when saving a Graph Options Template')
   
   statusBase = Widget_Base(tlb, /Row, /align_center)
   statusBar = Obj_New('SPD_UI_MESSAGE_BAR', statusBase, XSize=79, YSize=1) 
   ; make a copy of current legend settings, in case of a cancel/close window prior to applying
   origLegendSettings=legendSettings->copy()

   ; state structure
   state = {tlb:tlb, gui_id:info.master, historyWin:info.historyWin, $
            drawObject:info.drawObject, statusBar:statusBar, tlb_statusbar:tlb_statusbar, $
            windowStorage:info.windowStorage,loadedData:info.loadedData, $
            legendSettings:legendSettings, origLegendSettings:origLegendSettings, $
            lcolorWindow:lcolorWindow, bgcolorwindow:bgcolorwindow, $
            bordercolorwindow:bordercolorwindow, template:info.template_object, $
            panelObjs:panelObjs, panel_select:panel_select, validpanel:validpanel}
   

   ; We set the user value of the top-level widget to a pointer 
   ; to the state structure for handling events
   pState = ptr_new(state, /no_copy)
   Widget_Control, tlb, Set_UValue=pState, /No_Copy
   centertlb, tlb 
   Widget_Control, tlb, /Realize
   statusBar->Draw

   spd_ui_legend_options_init, tlb, legendSettings, panel_select=panel_select
   XManager, 'spd_ui_legend_options', tlb, /No_Block

   RETURN
end
