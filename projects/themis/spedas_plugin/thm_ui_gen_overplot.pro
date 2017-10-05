;+
;NAME:
;  thm_ui_gen_overplot
;
;PURPOSE:
;  Widget wrapper for spd_ui_overplot used to create THEMIS overview plots in SPEDAS.
;
;CALLING SEQUENCE:
;  See SPEDAS plugin API
;
;INPUT:
;  gui_id:  The id of the main GUI window.
;  historyWin:  The history window object.
;  oplot_calls:  The number calls to thm_gen_overplot
;  callSequence: object that stores sequence of procedure calls that was used to load data
;  windowStorage: standard windowStorage object
;  windowMenus: standard menu object
;  loadedData: standard loadedData object
;  drawObject: standard drawObject object
;
;OUTPUT:
;  none
;  
;$LastChangedBy: aaflores $
;$LastChangedDate: 2015-05-01 18:01:59 -0700 (Fri, 01 May 2015) $
;$LastChangedRevision: 17470 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/spedas_plugin/thm_ui_gen_overplot.pro $
;-----------------------------------------------------------------------------------


pro thm_ui_fix_axis_fonts, axis_obj=axis_obj, axis_name=axis_name, size_multiplier=size_multiplier 
  ; This function fixes font sizes for IDL versions greater than 8.0
  
  err_xxx = 0
  Catch, err_xxx
  IF (err_xxx NE 0) THEN BEGIN
    Catch, /Cancel
    Help, /Last_Message, Output = err_msg
    dprint, dlevel = 1, 'Error trying to fix overview font sizes: ' + err_msg
    RETURN
  ENDIF
  
  IF ~keyword_set(size_multiplier) THEN return
  IF abs(size_multiplier-1) lt 0.01 then return
  IF ~(axis_name eq 'x' or axis_name eq 'y' or axis_name eq 'z') THEN return
  IF ~obj_valid(axis_obj) THEN return
   
  if axis_name eq 'x' or axis_name eq 'y' then begin 
    ; fix labels
    axis_obj->getProperty, labels = labels
    if obj_valid(labels) then begin
      label_obj = labels->get(/all)
      for j = 0, n_elements(label_obj)-1 do begin
        label_obj[j]->getProperty, size = size
        ;labels tend to get cluttered, so we further decrease them 
        size = size*size_multiplier-1
        label_obj[j]->setProperty, size = size
      endfor
    endif
    ; fix titles
    axis_obj->getProperty, titleobj = titleobj
    if obj_valid(titleobj) then begin 
      titleobj->getProperty, size = size
      size *= size_multiplier
      titleobj->setProperty, size = size
    endif
    ; fix subtitles
    axis_obj->getProperty, subtitleobj = subtitleobj
    if obj_valid(subtitleobj) then begin
      subtitleobj->getProperty, size = size
      size *= size_multiplier
      subtitleobj->setProperty, size = size
    endif
  endif
  
  if (axis_name eq 'x') or (axis_name eq 'y')  or (axis_name eq 'z') then begin 
    ; fix annotationsf
    axis_obj->getProperty, annotatetextobject = annotatetextobject
   if obj_valid(annotatetextobject) then begin 
      annotatetextobject->getProperty, size = size
      ;annotations (axis scale) tend to get cluttered, so we further decrease them 
      size = size*size_multiplier-1
      annotatetextobject->setProperty, size = size
    endif
  endif

  if axis_name eq 'z' then begin
    ; fix labels
    axis_obj->getProperty, labeltextobject = labeltextobject
    if obj_valid(labeltextobject) then begin
      labeltextobject->getProperty, size = size 
      ;z-axis labels tend to overlap, so we further decrease them
      size = size*size_multiplier-1
      labeltextobject->setProperty, size = size
    endif  
    ; fix subtitles  
    axis_obj->getProperty, subtitletextobject = subtitletextobject
    if obj_valid(subtitletextobject) then begin
      subtitletextobject->getProperty, size = size
      size *= size_multiplier
      subtitletextobject->setProperty, size = size
    endif
  endif
  
end

pro thm_ui_fix_page_fonts, state=state 
  ; Fixes font sizes for all panels on the current page
  ; Assumes that after IDL 8.0 we need to multiply font sizes by a factor of 0.8
  ; size_multiplier = 0.8 is derived by comparing overview plots in IDL 7.1 vs IDL 8.3
  
  err_xxx = 0
  Catch, err_xxx
  IF (err_xxx NE 0) THEN BEGIN
    Catch, /Cancel
    Help, /Last_Message, Output = err_msg
    dprint, dlevel = 1, 'Error trying to fix overview font sizes: ' + err_msg
    RETURN
  ENDIF
  
  activeWindow = state.windowStorage->GetActive()
  activeWindow->GetProperty, panels = panelsObj
  panel = panelsObj->get(/all,count=count) 
  if count eq 0 then return

  IF !VERSION.RELEASE GE '8.0' THEN begin
    size_multiplier = 0.8
    if (!version.os_family ne 'Windows') and (!version.os_name ne 'Mac OS X') then begin
      size_multiplier = 0.9
    endif
    
    ; Loop through the panels and fix the axis
    for i = 0, n_elements(panel)-1 do begin
      panel[i]->getProperty,xaxis=axis_obj
      thm_ui_fix_axis_fonts, axis_obj=axis_obj, axis_name='x', size_multiplier=size_multiplier
      panel[i]->getProperty,yaxis=axis_obj
      thm_ui_fix_axis_fonts, axis_obj=axis_obj, axis_name='y', size_multiplier=size_multiplier
      panel[i]->getProperty,zaxis=axis_obj
      thm_ui_fix_axis_fonts, axis_obj=axis_obj, axis_name='z', size_multiplier=size_multiplier     
    endfor
    
    ; Title of page
    activeWindow->GetProperty, settings = settings
    if obj_valid(settings) then begin 
      settings->GetProperty, title = title
      if obj_valid(title) then begin 
        title->getProperty, size = size
        size *= size_multiplier
        title->setProperty, size = size
      endif
    endif
    
    ; Also the variables of the last panel (printed below the last panel)
    panel[n_elements(panel)-1]->GetProperty, variables = variables
    if obj_valid(variables) then begin 
      vars = variables->get(/all)
      for i=0, n_elements(vars)-1 do begin 
        vars[i]->getProperty, text=textobj
        textobj->getProperty, size = size
        size *= size_multiplier
        textobj->setProperty, size = size
        vars[i]->setProperty, text=textobj      
      endfor    
    endif
  endif 
  
end

pro thm_ui_fix_overview_panels, state=state
  ; Only for GUI THEMIS overviews
  ; We need to fix some panel properties 
  
  err_xxx = 0
  Catch, err_xxx
  IF (err_xxx NE 0) THEN BEGIN
    Catch, /Cancel
    Help, /Last_Message, Output = err_msg
    dprint, dlevel = 1, 'Error trying to fix overview font sizes: ' + err_msg
    RETURN
  ENDIF

  activeWindow = state.windowStorage->GetActive()
  If(n_elements(activeWindow) gt 0 && obj_valid(activeWindow[0])) Then Begin
    activeWindow[0]->setproperty, tracking = 0
    activeWindow[0]->getproperty, panels = panelsj
    panel = panelsj->get(/all)
  Endif else return

  ; There should be 14 panels
  ; If not, then what follows might need modifications
  if n_elements(panel) ne 14 then begin
    dprint, dlevel = 1, 'Error: THEMIS overview plot does not contain 14 panel.'
    return
  endif

  ; Make changes to panels
  current_row = 1
  for i = 0, n_elements(panel)-1 do begin
    panel[i]->getProperty, xAxis=xobj, yAxis=yobj, zAxis=zobj, settings=panel_settings
    
    ; Fix panel orientiation for all panels
    yobj->setProperty, stackLabels = 1, orientation = 0
    yobj->setProperty, titlemargin = 50 ; margin of yaxis titles
    
    ; panel 7 has no title
    if i eq 7 then begin 
      yobj->getProperty, titleobj = titleobj
      titleobj->setProperty, value = ''
    endif
    
    ;decrease the number of ticks on the panels to avoid clutter
    if (i eq 1) || (i eq 7) then begin
     ; xobj->setProperty, majorLength=2, minorLength=1
      ;yobj->setProperty, numMajorTicks=0, autoticks=0, numMinorTicks=0
      ;yobj->setProperty, annotateAxis=0
    endif else begin
     ; xObj->setProperty, majorLength=4, minorLength=2
     ; yobj->setProperty, numMajorTicks=3, numMinorTicks=1
    endelse
    
    ; modify layout to make status bars smaller 
    ; also change number of ticks   
    CASE i OF
      1: Begin
        yobj->setProperty, annotateAxis=0, lineatzero=0
        panel_settings->setProperty, row=current_row, rSpan=2
        current_row += 2
        end
      7: begin
        yobj->setProperty, annotateAxis=0, lineatzero=0
        panel_settings->setProperty, row=current_row, rSpan=1
        current_row += 1
        end
      ELSE:  begin
        xobj->setProperty, majorLength=4, minorLength=2
        yobj->setProperty, numMajorTicks=3, numMinorTicks=1
        panel_settings->setProperty, row=current_row, rSpan=4
        current_row += 4
        end
    ENDCASE
    
    ; logarithmic scalling for some of the panels
    if (i ge 8) || (i eq 6) then begin 
      yobj->setproperty, scaling = 1
      yobj->setproperty, rangeoption = 2
    endif
    
   ;panel[i]->setProperty, xAxis=xobj, yAxis=yobj, zAxis=zObj, settings=panel_settings
    
  endfor
  
  ;set the total number of rows
   activewindow[0]->setproperty, nrows=current_row-1
          
          
          ;statusbar panel needs different colors
          panel[7]->getproperty, tracesettings = obj0
          trace_obj = obj0->get(/all)
          ntraces = n_elements(trace_obj)
          If(ntraces Gt 1) Then Begin
            If(obj_valid(trace_obj[1])) Then Begin
              trace_obj[1]->getproperty, linestyle = linestyleobj
              linestyleobj->setproperty, color = [255b, 255b, 0b] ;yellow
            Endif
            If(obj_valid(trace_obj[2])) Then Begin
              trace_obj[2]->getproperty, linestyle = linestyleobj
              linestyleobj->setproperty, color = [255b, 0b, 0b] ;red
            Endif
            If(obj_valid(trace_obj[3])) Then Begin
              trace_obj[3]->getproperty, linestyle = linestyleobj
              linestyleobj->setproperty, color = [0b, 0b, 255b] ;blue
            Endif
            If(obj_valid(trace_obj[4])) Then Begin
              trace_obj[4]->getproperty, linestyle = linestyleobj
              linestyleobj->setproperty, color = [0b, 0b, 0b] ;black
            Endif
              If(obj_valid(trace_obj[5])) Then Begin
                trace_obj[5]->getproperty, linestyle = linestyleobj
                linestyleobj->setproperty, color = [0b, 0b, 0b] ;black
              Endif
            for i = 0,n_elements(trace_obj)-1 do begin
              trace_obj[i]->getProperty,linestyle=linestyleObj,symbol=symbolobj
              lineStyleObj->setProperty,thickness=2
              lineStyleObj->getProperty,color=linecolor
              symbolobj->setProperty,show=0,name=symbolobj->getSymbolName(symbolid=4),id=4,color=linecolor
            endfor
          Endif
                   
          ;keep esa and sst spectra's z-range consistant
          panel[8]->getproperty, zaxis = zobj_ssti
          zobj_ssti->setproperty, minrange = 1d0, maxrange = 5d7, fixed=1
          panel[9]->getproperty, zaxis = zobj_esai
          zobj_esai->setproperty, minrange = 1d3, maxrange = 7.5d8, fixed=1
          panel[10]->getproperty, zaxis = zobj_sste
          zobj_sste->setproperty, minrange = 1d0, maxrange = 5d7, fixed=1
          panel[11]->getproperty, zaxis = zobj_esae
          zobj_esae->setproperty, minrange = 1d4, maxrange = 7.5d8, fixed=1
          
          ;set the vertical spacing to a smaller number, to save space on a many panel layout
          activewindow[0]->getproperty, settings=page
          page->setproperty,ypanelspacing=0
          
             
          ;get trace for the first panel and change the color to black
          panel[0]->getproperty, tracesettings = obj0
          trace_obj = obj0->get(/all)
          if obj_valid(trace_obj[0]) then begin
            trace_obj[0]->getproperty, linestyle = linestyleobj
            linestyleobj->setproperty, color = [0b, 0b, 0b]
          endif
          
          ;SST needs to have y scaling set to log
          panel[8]->getproperty, yaxis = yobj
          yobj->setproperty, scaling = 1
          yobj->setproperty, rangeoption = 2
;          get_data, ssti_name, data = d
          yobj->setproperty, maxfixedrange = 3.0e6
          yobj->setproperty, minfixedrange = 3.0e4
;          If(is_struct(d) && tag_exist(d, 'v')) Then yobj->setproperty, minfixedrange = min(d.v) $
;          Else yobj->setproperty, minfixedrange = 3.0e4
          ;quick_set_panel_labels, panel[8], ['SSTi_Eflux_[eV]']
          ;  quick_set_panel_labels, panel[8], 'Eflux!CeV/cm!U2!N!C-s-sr-eV', /zaxis, /zhorizontal
          ;quick_set_panel_labels, panel[8], 'Eflux, EFU', /zaxis
          ;ESA needs logs too
          panel[9]->getproperty, yaxis = yobj
          yobj->setproperty, scaling = 1
          ;quick_set_panel_labels, panel[9], ['ESAi_Eflux_[eV]']
          ;  quick_set_panel_labels, panel[9], 'Eflux!CeV/cm!U2!N!C-s-sr-eV', /zaxis, /zhorizontal
          ;quick_set_panel_labels, panel[9], 'Eflux, EFU', /zaxis
          ;SST electrons
          panel[10]->getproperty, yaxis = yobj
          yobj->setproperty, scaling = 1
          yobj->setproperty, rangeoption = 2
;          get_data, sste_name, data = d
;          yobj->setproperty, maxfixedrange = 3.0e6
;          yobj->setproperty, minfixedrange = 3.0e4
;          If(is_struct(d) && tag_exist(d, 'v')) Then yobj->setproperty, minfixedrange = min(d.v) $
;          Else yobj->setproperty, minfixedrange = 3.0e4
          ;quick_set_panel_labels, panel[10], ['SSTe_eflux_[eV]']
          ;  quick_set_panel_labels, panel[10], 'Eflux!CeV/cm!U2!N!C-s-sr-eV', /zaxis, /zhorizontal
          ;quick_set_panel_labels, panel[10], 'Eflux, EFU', /zaxis
          ;ESA electrons
          panel[11]->getproperty, yaxis = yobj
          yobj->setproperty, scaling = 1
          ;quick_set_panel_labels, panel[11], ['ESAe_eflux_[eV]']
          ;  quick_set_panel_labels, panel[11], 'Eflux!CeV/cm!U2!N!C-s-sr-eV', /zaxis, /zhorizontal
          ;quick_set_panel_labels, panel[11], 'Eflux, EFU', /zaxis
          ;FBK panels
          npanels = n_elements(panel)
          For j = 0, n_elements(fbk_tvars)-1 Do Begin
            jp = j+12
            If(jp Le npanels-1) Then Begin
              panel[jp]->getproperty, yaxis = yobj
              yobj->setproperty, scaling = 1
              get_data, fbk_tvars[j], dlimits = dl, limits = al
              lbl0 =  strupcase(strmid(fbk_tvars[j], 4)) & lbl1 = '  '
              If(is_struct(al) && tag_exist(al, 'ztitle')) Then lbl1 = al.ztitle
              ;          quick_set_panel_labels, panel[jp], [lbl0, '[Hz]']
              ;quick_set_panel_labels, panel[jp], lbl1, /zaxis
              ;quick_set_panel_labels, panel[jp], thx+'_FBK '+strmid(fbk_tvars[j], 7)
            Endif
            ;quick_set_panel_labels, panel[12], '<|mV/m|>', /zaxis
            ;quick_set_panel_labels, panel[13], '<|nT|>', /zaxis
          Endfor       
     
 
  ; Panel 0
  
  ; Panel 1: ROI 
  ; setup colors for ROI plot
  panel[1]->getProperty,yaxis=nobj
  nobj->setProperty,annotateAxis=0,lineatzero=0
  panel[1]->getproperty, tracesettings = obj0
  trace_obj = obj0->get(/all)
  ntr = 11 ; 11 is based on the total of the bit mask in thm_roi_bar.pro
  ; setup colors for ROI plot
  ctbl = transpose([[7,0,5],$
    [235,255,0],$
    [0,97,255],$
    [253,0,0],$
    [90,255,0],$
    [43,0,232],$
    [255,103,0],$
    [0,255,133],$
    [83,0,117],$
    [255,199,0],$
    [0,235,254]])
  for i = 0,ntr-1 do begin
    trace_obj[i]->getProperty,linestyle=linestyleObj
    lineStyleObj->setProperty,thickness=2, color=ctbl[i,*]
  endfor  
  
  ; Panel 13
  ; Fix the variables of the last panel (printed below the last panel)
  panel[n_elements(panel)-1]->GetProperty, variables = variables
  if obj_valid(variables) then begin
    vars = variables->get(/all)
    for i=0, n_elements(vars)-1 do begin
      vars[i]->getProperty, text=textobj
      textobj->getproperty, value=text
      ;get component dynamically since order may change
      textobj->setProperty, value = $
        strupcase( (stregex(text,'.*_([xyz])_.*$',/sub,/extract))[1] ) + '-GSE'
      vars[i]->setProperty, text=textobj
    endfor
  endif

end

pro thm_ui_gen_overplot_event, event

  Compile_Opt hidden

  Widget_Control, event.TOP, Get_UValue=state, /No_Copy

  ;Put a catch here to insure that the state remains defined
  err_xxx = 0
  Catch, err_xxx
  IF (err_xxx NE 0) THEN BEGIN
    Catch, /Cancel
    Help, /Last_Message, Output = err_msg
    
    spd_ui_sbar_hwin_update, state, err_msg, /error, err_msgbox_title='Error while generating THEMIS overview plot'
    
    Widget_Control, event.TOP, Set_UValue=state, /No_Copy
    widget_control, event.top,/destroy
    RETURN
  ENDIF
  
  ;kill request block
  IF (Tag_Names(event, /Structure_Name) EQ 'WIDGET_KILL_REQUEST') THEN BEGIN  

    dprint,  'Generate THEMIS overview plot widget killed' 
    state.historyWin->Update,'THM_UI_GEN_OVERPLOT: Widget killed' 
    Widget_Control, event.TOP, Set_UValue=state, /No_Copy
    Widget_Control, event.top, /Destroy
    RETURN 
  ENDIF
  
  Widget_Control, event.id, Get_UValue=uval
  
  state.historywin->update,'THM_UI_GEN_OVERPLOT: User value: '+uval  ,/dontshow
  
  CASE uval OF
    'GOWEB': BEGIN
      timeid = widget_info(event.top, find_by_uname='time')
      widget_control, timeid, get_value=valid, func_get_value='spd_ui_time_widget_is_valid'
      if valid then begin
        state.tr_obj->getproperty, starttime=starttime, endtime=endtime 
        starttime->getproperty, year=year, month=month, date=date       
        probet = state.probe
        ; For some reason, the & cannot be sent as part of the URL. So we are going to use a single string variable that will be split by PHP.
        url = "http://themis.ssl.berkeley.edu/summary.php?bigvar=" + string(year, format='(I04)') + "___" + string(month, format='(I02)') + "___" + string(date, format='(I02)') + "___0024___th" + probet + "___overview"
        spd_ui_open_url, url
      endif else begin
        ok = dialog_message('Invalid start/end time, please use: YYYY-MM-DD/hh:mm:ss', $
          /center)   
      endelse
      

  END
    'APPLY': BEGIN
    ; Check whether times set in widget are valid
    timeid = widget_info(event.top, find_by_uname='time')
    widget_control, timeid, get_value=valid, func_get_value='spd_ui_time_widget_is_valid'
    if valid then begin
      state.tr_obj->getproperty, starttime=starttime, endtime=endtime
      starttime->getproperty, tdouble=st_double
      endtime->getproperty, tdouble=et_double
      if (st_double le 0.0) or (et_double le 0.0) then begin
        etxt = 'Invalid End Time.'
        if (st_double le 0.0) then etxt = 'Invalid Start Time.'
        ok = dialog_message(etxt,title='Error while generating THEMIS overview plot', /center, information=1)        
        Widget_Control, event.top, Set_UValue=state, /No_Copy
        return 
      endif
      dur = (et_double - st_double) / 86400
      if dur le 0 then begin
        etxt = 'End Time is earlier than Start Time.'
        ok = dialog_message(etxt,title='Error while generating THEMIS overview plot', /center, information=1)
        
        Widget_Control, event.top, Set_UValue=state, /No_Copy
        return
      endif
       
      widget_control, /hourglass
      
      if ~state.windowStorage->add(isactive=1) then begin
        ok = spd_ui_prompt_widget(state.tlb,state.statusbar,state.tlb,prompt='Error initializing new window for THEMIS overview plot.', $
               title='Error while generating THEMIS overview plot',/traceback, frame_attr=8)
        Widget_Control, event.top, Set_UValue=state, /No_Copy
        return
      endif  
      
      activeWindow = state.windowStorage->GetActive()
      state.statusBar->Update,'Generating THEMIS overview plot. Please wait!...'
      
      thm_gen_overplot,  probes=state.probe, date=st_double, dur = dur, $
         makepng = 0, fearless = 0, dont_delete_data = 1, gui_plot = 1, error=error        
                     
      if ~error then begin  
           
        thm_ui_fix_page_fonts, state=state
        thm_ui_fix_overview_panels, state=state
                           
        state.callSequence->addplugincall, 'thm_gen_overplot', $
          probes=state.probe, date=st_double, dur = dur, $
          makepng = 0, fearless = 0, dont_delete_data = 1, $
          gui_plot = 1, no_draw=1, track_one = 1 ;panel tacking kludge

;        callSequence->singlePanelTracking, ptr_new(info)

        (*state.data).oplot_calls = (*state.data).oplot_calls + 1 ; update # of calls to overplot
        (*state.data).track_one = 1b ;set to single-panel tracking (temporary kludge)
        
        msg = 'THEMIS overview plot completed.'
      endif else begin
        msg = 'Error generating THEMIS overview plot.'
      endelse
      
      state.statusbar->update, msg
      state.historywin->update, msg
      
      Widget_Control, event.top, Set_UValue=state, /No_Copy
      Widget_Control, event.top, /Destroy
      return
    endif else ok = dialog_message('Invalid Start/End time, please use: YYYY-MM-DD/hh:mm:ss', $
                                   /center)
    END
    'CANC': BEGIN
      state.historyWin->update,'Generate THEMIS overview plot canceled',/dontshow
      Widget_Control, event.TOP, Set_UValue=state, /No_Copy
      Widget_Control, event.top, /Destroy
      RETURN
    END
    'KEY': begin
      spd_ui_overplot_key, state.gui_id, state.historyWin, /modal
    end
    'PROBE:A': state.probe='a'
    'PROBE:B': state.probe='b'
    'PROBE:C': state.probe='c'
    'PROBE:D': state.probe='d'
    'PROBE:E': state.probe='e'
    'TIME': ;nothing to implement at this time
    ELSE: dprint,  'Not yet implemented'
  ENDCASE
  
  Widget_Control, event.top, Set_UValue=state, /No_Copy

  RETURN
end


;see top of file for header
pro thm_ui_gen_overplot, gui_id = gui_id, $
                         history_window = historyWin, $
                         status_bar = statusbar, $
                         call_sequence = callSequence, $
                         time_range = tr_obj, $
                         window_storage = windowStorage, $
                         loaded_data = loadedData, $
                         data_structure = data_structure, $
                         _extra = _extra 

  compile_opt idl2

  err_xxx = 0
  Catch, err_xxx
  IF(err_xxx Ne 0) THEN BEGIN
    Catch, /Cancel
    Help, /Last_Message, Output=err_msg
    FOR j = 0, N_Elements(err_msg)-1 DO Begin
      print, err_msg[j]
      If(obj_valid(historywin)) Then historyWin->update, err_msg[j]
    Endfor
    Print, 'Error--See history'
    ok = error_message('An unknown error occured while starting the THEMIS overview plot widget. ', $
         'See console for details.', /noname, /center, title='Error in THEMIS overview plots')
    spd_gui_error, gui_id, historywin
    RETURN
  ENDIF
  
  tlb = widget_base(/col, title='Generate THEMIS Overview Plot', group_leader=gui_id, $
          /floating, /base_align_center, /tlb_kill_request_events, /modal)

; Base skeleton          
  mainBase = widget_base(tlb, /col, /align_center, tab_mode=1, space=4)
    txtBase = widget_base(mainbase, /Col, /align_center)
    probeBase = widget_base(mainBase, /row)
      probeLabel = widget_label(probeBase, value='Probe:  ', /align_left)
      probeButtonBase = widget_base(probeBase, /row, /exclusive)
    midBase = widget_base(mainBase, /Row)
      trvalsBase = Widget_Base(midBase, /Col, Frame=1, xpad=8)
      keyButtonBase = widget_button(midBase, Value=' Plot Key ', UValue='KEY', XSize=80, $
                                    tooltip = 'Displays detailed descriptions of overview plot panels.')
    goWebBase = Widget_Base(mainBase, /Row, Frame=1, xpad=8)
    
    buttonBase = Widget_Base(mainBase, /row, /align_center)
    
    goWebLabel = widget_label(goWebBase, Value='  Alternatively, you can view the plot on the web (single day).  ', /align_left)
    goWebButton = Widget_Button(goWebBase, Value='  Web Plot  ', UValue='GOWEB', XSize=80)

; Help text
  wj = widget_label(txtbase, value='Creating the overview plot might take a few minutes.', /align_left)

; Probe selection widgets
  aButton = widget_button(probeButtonBase, value='A(P5)', uvalue='PROBE:A')
  bButton = widget_button(probeButtonBase, value='B(P1)', uvalue='PROBE:B')
  cButton = widget_button(probeButtonBase, value='C(P2)', uvalue='PROBE:C')
  dButton = widget_button(probeButtonBase, value='D(P3)', uvalue='PROBE:D')
  eButton = widget_button(probeButtonBase, value='E(P4)', uvalue='PROBE:E')
  
  widget_control, aButton, /set_button
  probe='a'

; Time range-related widgets
  getresourcepath,rpath
  cal = read_bmp(rpath + 'cal.bmp', /rgb)
  spd_ui_match_background, tlb, cal  

  if ~obj_valid(tr_obj) then begin
    st_text = '2007-03-23/00:00:00.0'
    et_text = '2007-03-24/00:00:00.0'
    tr_obj=obj_new('spd_ui_time_range',starttime=st_text,endtime=et_text)
  endif


  timeWidget = spd_ui_time_widget(trvalsBase,statusBar,historyWin,timeRangeObj=tr_obj, $
                                  uvalue='TIME',uname='time');, oneday=1 
  
  trControls=[timewidget]

; Main window buttons
  applyButton = Widget_Button(buttonBase, Value='  Apply   ', UValue='APPLY', XSize=80)
  cancelButton = Widget_Button(buttonBase, Value='  Cancel  ', UValue='CANC', XSize=80)

  ;initialize structure to store variables for future calls
  if ~is_struct(data_structure) then begin
    data_structure = { oplot_calls:0, track_one:0b }
  endif
  
  ;create copy that can be retrieved later
  data_ptr = ptr_new(data_structure)

  state = {tlb:tlb, gui_id:gui_id, historyWin:historyWin,statusBar:statusBar, $
           trControls:trControls, tr_obj:tr_obj, probe:probe, $
           data:data_ptr, $
           callSequence:callSequence,$
           windowStorage:windowStorage, $
           loadedData:loadedData}

  Centertlb, tlb         
  Widget_Control, tlb, Set_UValue=state, /No_Copy
  Widget_Control, tlb, /Realize

  ;keep windows in X11 from snaping back to 
  ;center during tree widget events 
  if !d.NAME eq 'X' then begin
    widget_control, tlb, xoffset=0, yoffset=0
  endif

  XManager, 'thm_ui_gen_overplot', tlb, /No_Block

  ;if pointer or struct are not valid the original structure will be unchanged
  if ptr_valid(data_ptr) && is_struct(*data_ptr) then begin
    data_structure = *data_ptr
  endif

  RETURN
end
