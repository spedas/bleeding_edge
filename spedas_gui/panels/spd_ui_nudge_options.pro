;+ 
;NAME:
; spd_ui_nudge_options
;
;PURPOSE:
; simple user interface window which allows the user to specify a new
; time array for a trace or spectrogram
;
;CALLING SEQUENCE:
; spd_ui_nudge_options, gui_id, info
;
;INPUT:
;  gui_id = widget id of the widget that called this program
;  info = the info structure of the Main GUI
;OUTPUT:
;
;HISTORY:
;$LastChangedBy: jimm $
;$LastChangedDate: 2014-02-11 10:54:32 -0800 (Tue, 11 Feb 2014) $
;$LastChangedRevision: 14326 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/spedas_gui/panels/spd_ui_nudge_options.pro $
;
;---------------------------------------------------------------------------------

; helper function to add a number to the front of the trace name and truncate to fit in the combobox.
; This helps resolve problems with identical traces and combobox problems on linux.
function spd_ui_nudge_options_truncate_traces, tracenames
  tracenamestrunc = tracenames
  for traceit = 0, n_elements(tracenames)-1 do begin
    tracenamestrunc[traceit] = strtrim(string(traceit +1),2)+': '+traceNames[traceit]
    if strlen(tracenamestrunc[traceit]) GT 35 then tracenamestrunc[traceit]=strmid(tracenamestrunc[traceit], 0, 35)+'...'
  endfor 
  return, tracenamestrunc
end

PRO spd_ui_nudge_options_event, event

  compile_opt hidden

;Catch here to insure that the state remains defined
  err_xxx = 0
  Catch, err_xxx
  IF (err_xxx NE 0) THEN BEGIN
    Catch, /Cancel
    Help, /Last_Message, Output = err_msg
    
    spd_ui_sbar_hwin_update, state.info, err_msg, /error, err_msgbox_title='Error in Nudge Options'
    
    Widget_Control, event.TOP, Set_UValue=state, /No_Copy
    widget_control, event.top,/destroy
    RETURN
  ENDIF
  widget_control, event.top, get_uvalue = state, /no_copy
;kill request block
  If(TAG_NAMES(event, /STRUCTURE_NAME) EQ 'WIDGET_KILL_REQUEST') Then Begin
    state.info.statusbar -> update, 'Nudge Options Panel Closed'
    widget_control, event.top, set_uvalue = state, /no_copy
    widget_control, event.top, /destroy
    Return
  Endif
;Options
  widget_control, event.id, get_uvalue = uval
  if is_struct(state) then state.info.historywin -> update,'SPD_UI_NUDGE_OPTIONS: User value: '+uval  ,/dontshow
  Case uval of
    'OK': Begin
      state.info.statusbar -> update, 'Nudge Options Panel Closed'
      widget_control, event.top, set_uvalue = state, /no_copy
      widget_control, event.top, /destroy
      Return
    End
    'PANEL':Begin
      panel_x = widget_info(state.panel_combobox, /combobox_gettext)
;populate the trace_combobox
      pindex = where(state.panel_values Eq panel_x)
      If(pindex[0] Eq -1) Then Message, 'No panel selection?'
      state.panel_index = pindex
      panel = state.active_panels[pindex]
      panel -> getproperty, tracesettings = dummy_obj
      trace_objs = dummy_obj -> get(/all)
      if obj_valid(trace_objs[0]) then begin
        trace_values = ''
        For j = 0, n_elements(trace_objs)-1 Do Begin
          trace_objs[j] -> getproperty, datay = tj
          trace_values = [trace_values, tj]
        Endfor
        trace_values = trace_values[1:*]
        trace_values_trunc = spd_ui_nudge_options_truncate_traces(trace_values)
        tracesensitive = 1
      endif else begin
        trace_values = ''
        trace_values_trunc = ' '
        tracesensitive = 0
      endelse
      trace_combobox = widget_info(state.tlb, find_by_uname='trace')
      widget_control, trace_combobox, set_value = trace_values_trunc, sensitive = tracesensitive
      apply_button = widget_info(state.tlb, find_by_uname='apply')
      widget_control, apply_button, sensitive = tracesensitive
      If(ptr_valid(state.trace_values)) Then ptr_free, state.trace_values
      state.trace_values = ptr_new(trace_values)
      state.trace_to_nudge = (*state.trace_values)[0]
      state.trace_id = 0
      id = widget_info(event.top, find_by_uname='tracetext')
      widget_control, id, set_value=state.trace_to_nudge, sensitive = tracesensitive
      state.statusbar -> update, 'Chosen Panel: '+state.panel_values[pindex]
    End
    'TRACE':Begin
      state.trace_id = event.index
      state.trace_to_nudge = (*state.trace_values)[event.index]
      id = widget_info(event.top, find_by_uname='tracetext')
      widget_control, id, set_value=state.trace_to_nudge
      ;check to see that a panel has been selected:
;      widget_control, state.trace_combobox, get_value = tvals
;      tvalue = widget_info(state.trace_combobox, /combobox_gettext)
;      tvals = *state.trace_values
;      tindex = where(tvals Eq tvalue)
;      If(tindex[0] Eq -1) Then Message, 'No trace selection?'
;      state.trace_to_nudge = tvals[tindex]
      state.statusbar -> update, 'Chosen Trace: '+state.trace_to_nudge
    End
    'SECONDS': Begin
      state.shift_unit = 'sec'
      state.shift_scale = 1.0
      state.use_records = 0b
      state.statusbar -> update, 'Shift unit: Seconds'
    End
    'MINUTES': Begin
      state.shift_unit = 'min'
      state.shift_scale = 60.0
      state.use_records = 0b
      state.statusbar -> update, 'Shift unit: Minutes'
    End
    'HOURS': Begin
      state.shift_unit = 'hr'
      state.shift_scale = 3600.0
      state.use_records = 0b
      state.statusbar -> update, 'Shift unit: Hours'
    End
    'DAYS': Begin
      state.shift_unit = 'day'
      state.shift_scale = 86400.0
      state.use_records = 0b
      state.statusbar -> update, 'Shift unit: Days'
    End
    'RECORDS': Begin
      state.shift_unit = 'rec'
      state.shift_scale = 1.0
      state.use_records = 1b
      state.statusbar -> update, 'Shift unit: Records'
    End
    'MAJINC':Begin
      if event.valid then begin
        If(event.value Ne 0) Then Begin
          state.nshift = event.value
          ext_string = strcompress(string(event.value))
          state.statusbar -> update, 'Shift by'+ext_string+$
            ' '+state.shift_unit
        Endif Else Begin
          state.statusbar -> update, 'Invalid or Zero Shift Input: '
          state.nshift = 0
        Endelse
      endif else state.statusBar->update, 'Invalid or Zero Shift Input.'
    End
    'APPLY': Begin
;first, get the trace that you;re nudging
        tn = state.trace_to_nudge
        widget_control, state.nshift_widget, get_value=val
        If(is_string(tn) Eq 0) Then Begin
            state.statusbar -> update, tn+' Is not an active trace, No nudge'
        Endif Else If ~finite(val) then begin
            state.statusbar -> update, 'Invalid shift input, no changes made to '+tn
        Endif Else If(state.nshift Eq 0) Then Begin
            state.statusbar -> update, 'Zero Shift Input. No Nudge for '+tn
        Endif Else If(ptr_valid(state.trace_values) Eq 0) Then Begin
            state.statusbar -> update, 'Please Choose a Panel and Trace'
        Endif Else Begin
;check to see if the trace involved is a spectrogram
            pobj = state.active_panels[state.panel_index]
            pobj -> getproperty, tracesettings = pset
            psetj = pset -> get(/all)
;there should always be a trace_value equal to tn
            ;tindex = where(*state.trace_values Eq tn)
;And if you've replicated the trace, there may be more
            ;tindex = tindex[0]
            tindex = state.trace_id
            If(tindex[0] Eq -1) Then Begin
               fail = 1b
               state.statusbar -> update, 'No trace available, No Nudge for '+tn
            Endif Else Begin
               If(obj_isa(psetj[tindex], 'spd_ui_line_settings')) Then isspec = 0b $
               Else isspec = 1b
;if the name has "_yaxis" or "_data" on the end, strip it and use that
;variable. This avoids extra-long variable names
               If(isspec) Then Begin
                  temp_array = strsplit(tn, '_',/extract)
                  ntemp = n_elements(temp_array)
                  If(ntemp GT 1 && temp_array[ntemp-1] Eq 'yaxis') Then Begin
                     tn_trace = tn
                     tn = strjoin(temp_array[0:ntemp-2], '_')
                  Endif Else tn_trace = tn ;don't lose the trace name
               Endif Else Begin
                  temp_array = strsplit(tn, '_',/extract)
                  ntemp = n_elements(temp_array)
                  If(ntemp GT 1 && temp_array[ntemp-1] Eq 'data') Then Begin
                     tn_trace = tn
                     tn = strjoin(temp_array[0:ntemp-2], '_')
                  Endif Else tn_trace = tn ;don't lose the trace name
               Endelse
;get the data, create a variable with the data for this trace and the
;nudged time pointer, create an object that can be copied and put into
;the loadeddata object
               overwrite_selections = ''
               spd_ui_do_nudge, tn, state.nshift, state.shift_unit, state.shift_scale, $
                                state.use_records, isspec, state.info.loadedData, $
                                state.info.historyWin, state.statusbar, state.gui_id, fail=fail, $
                                tn1=tn1, overwrite_selections = overwrite_selections
            Endelse

            if ~fail then Begin 
              state.call_sequence->addNudgeOp,$
                                   tn,$
                                   state.nshift,$
                                   state.shift_unit,$
                                   state.shift_scale,$
                                   state.use_records,$
                                   isspec,$
                                   overwrite_selections
                                   
              If(isspec) Then tn1_trace = tn1+'_yaxis' Else tn1_trace = tn1+'_data';added 8-feb-2011, jmm
              ;the new trace is now the trace to nudge
              state.trace_to_nudge = tn1_trace
              ;get the trace and time variable names for the new trace
              allvars = state.info.loadeddata -> getall(/parent)
              tn1p = allvars[where(strmatch(allvars, '*'+tn1) Eq 1)]
              tn1p = tn1p[n_elements(tn1p)-1] ;just in case there are more than one.
              If(isspec) Then Begin           ;spectra are handled differently
                  psetj[tindex] -> setproperty, datax = tn1p+'_time', datay = tn1p+'_yaxis', dataz = tn1p
              Endif Else Begin
                  tn1c = state.info.loadeddata -> getchildren(tn1p)
                  ;reset the trace to point to the nudged variable
                  psetj[tindex] -> setproperty, datax = tn1c[0], datay = tn1c[1]
              Endelse
              ;update y-axis label if it hasn't been modified by the user
              pobj -> getproperty, yaxis=yaxis
              yaxis -> getproperty, labels = labels
              if obj_valid(labels) then begin
                labels = labels->get(/all)
                trace_label = labels[tindex]->getall()
                if trace_label.value eq tn then labels[tindex]->setproperty, value = tn1_trace $
                  else state.info.historywin->update, 'Label modified by user, no change made.'
              endif else state.info.historywin->update, 'Y-Axis labels not valid, no change made.'
              ;update the draw object and redraw the panels
              state.info.drawObject -> update, state.info.windowStorage, state.info.loadedData
              state.info.drawObject -> draw
              state.info.scrollbar -> update
              state.statusbar -> update, 'Trace Nudged: '+tn1 
              state.info.historywin -> update, 'Trace Nudged: '+tn1 
              ;Update the traces in the droplist for this panel
              trace_values = ''
              For j = 0, n_elements(psetj)-1 Do Begin
                  psetj[j] -> getproperty, datay = tj
                  trace_values = [trace_values, tj]
              Endfor
              trace_values_trunc = spd_ui_nudge_options_truncate_traces(trace_values[1:*])
              trace_combobox = widget_info(state.tlb, find_by_uname='trace')
              widget_control, trace_combobox, set_value = trace_values_trunc
              widget_control, trace_combobox, set_combobox_select=tindex
              If(ptr_valid(state.trace_values)) Then ptr_free, state.trace_values
              state.trace_values = ptr_new(trace_values[1:*])
              id = widget_info(event.top, find_by_uname='tracetext')
              widget_control, id, set_value = (*state.trace_values)[tindex]
            Endif
        Endelse
    End
  Endcase

  Widget_Control, event.top, Set_UValue=state, /No_Copy

  RETURN
END ;--------------------------------------------------------------------------------



PRO spd_ui_nudge_options, gui_id, info,call_sequence

  err_xxx = 0
  catch, err_xxx
  If(err_xxx Ne 0) Then Begin
    catch, /cancel
    Help, /Last_Message, Output=err_msg
    FOR j = 0, N_Elements(err_msg)-1 DO begin
      if (is_struct(info)) then info.historywin->update,err_msg[j]
    endfor
    ok = error_message('Unknown error starting Nudge Traces: See console for details.',$
         /noname, /center, title='Error in Nudge Traces')
    if tlb gt 0 then widget_control,tlb,/destroy
    if is_struct(info) then spd_gui_error,gui_id,info.historywin
    Return
  Endif

;Get the panels for the active window(s)
  wo = info.windowstorage -> getactive()
  If(obj_valid(wo[0]) Eq 0) Then Begin
    ok = error_message('Nudge Traces: There are No Active Windows', $
                       /info, traceback = 0, /noname, /center, title = 'Error in Nudge Traces')
    Return
  Endif
  For j = 0, n_elements(wo)-1 Do Begin
    wo[j] -> getproperty, panels = panelsj
    parray = panelsj -> Get(/all)
    If(obj_valid(parray[0])) Then Begin
      If(n_elements(active_panels) Eq 0) Then Begin
        active_panels = parray
      Endif Else active_panels = [active_panels, parray]
    Endif
  Endfor
  npan = n_elements(active_panels)
  If(npan Eq 0) Then Begin
    ok = error_message('Nudge Traces: There are No Active Panels', $
                       /info, traceback = 0, /noname, /center, title = 'Error in Nudge Traces')
    Return
  Endif
;each panel has a name:
  panel_values = strarr(npan)
  panel_copy = objarr(npan)
  For k = 0, n_elements(active_panels)-1 Do Begin
    active_panels[k] -> Getproperty, name = pname
    IF pname EQ '' THEN panel_values=active_panels[k]->ConstructPanelName() ELSE panel_values[k] = pname
    panel_copy[k] = active_panels[k] -> copy()
  Endfor
;set up traces
  panel_index = 0
  panel = active_panels[panel_index]
  panel -> getproperty, tracesettings = dummy_obj
  trace_objs = dummy_obj -> get(/all)
  if obj_valid(trace_objs[0]) then begin
    For j = 0, n_elements(trace_objs)-1 Do Begin
      trace_objs[j] -> getproperty, datay = tj
      trace_values = array_concat(tj, trace_values)
    Endfor
    if n_elements(trace_values) gt 0 then begin
      trace_to_nudge = trace_values[0]
      trace_values_trunc = spd_ui_nudge_options_truncate_traces(trace_values)
      tracesensitive = 1
    endif 
  endif else begin
    trace_values = ' '
    trace_to_nudge = ' '
    trace_values_trunc = ' '
    tracesensitive = 0
  endelse
;set up the panel
  tlb = Widget_Base(/Col, Title = 'Nudge Traces', Group_Leader = gui_id, /Modal, /Floating)
  textBase = Widget_Base(tlb, /Row)
  topBase = Widget_Base(tlb, /Row)
  col1Base = Widget_Base(topBase, /Col)
  col2Base = Widget_Base(topBase, /Row)
  panelBase = Widget_Base(col1Base, /Row, YPad = 7,xpad=22)
  traceBase = Widget_Base(col1Base, /Row, YPad = 7)
  tracetextBase = widget_base(col1Base,/Row, YPad = 7,xpad=16)
  incBase = Widget_Base(col1Base, /Row, YPad = 7, xpad=6)
  unitsLabelBase = Widget_Base(col2Base, /Row)
  unitsFrameBase = Widget_Base(col2Base, /Col, /Exclusive)
  nudgeAllBase = Widget_Base(tlb, /Col, /Align_Center, YPad = 10)
  buttonBase = Widget_Base(tlb, /Row, /Align_Center)

;widgets
  nudge_text = WIDGET_Label(textBase, Value = 'Nudging will shift a trace in the selected panel by a specific amount')
  plabel = widget_label(panelbase, value = '    Panel: ')
  panel_combobox = Widget_Combobox(panelBase, Value = panel_values, scr_XSize = 260, UValue = 'PANEL')
  tlabel = widget_label(tracebase, value = 'Select Trace: ')
  trace_combobox = Widget_Combobox(traceBase, scr_XSize = 260, Value = trace_values_trunc, uvalue = 'TRACE', uname='trace', sensitive=tracesensitive)
  tracetextlabel = widget_label(tracetextbase, value='     Trace: ')
  trace_text = widget_text(tracetextbase, scr_XSize=260,value = trace_to_nudge, uname='tracetext', sensitive=tracesensitive)
  cmajor_increment = spd_ui_spinner(incBase, Label = '      Amount: ', $
                                    Increment = 1, Value = 1, UValue = 'MAJINC')
  units_text = WIDGET_Label(unitslabelBase, Value = 'Units:')
  seconds_button = Widget_Button(unitsframeBase, Value = 'Seconds', UValue = 'SECONDS')
  minutes_button = Widget_Button(unitsframeBase, Value = 'Minutes', UValue = 'MINUTES')
  hours_button = Widget_Button(unitsframeBase, Value = 'Hours', UValue = 'HOURS')
  days_button = Widget_Button(unitsframeBase, Value = 'Days', UValue = 'DAYS')
  records_button = Widget_Button(unitsframeBase, Value = 'Records', UValue = 'RECORDS')
  Widget_Control, seconds_button, /set_button
  apply_button = Widget_Button(buttonBase, Value = '    Apply    ', XSize = 85, $
                               UValue = 'APPLY', sensitive=tracesensitive, uname = 'apply')
  ok_button = Widget_Button(buttonBase, Value = '  Done   ', XSize = 85, UValue = 'OK')

 ; Create Status Bar Object
  statusbar = obj_new('spd_ui_message_bar', Value = 'Status information is displayed here.', $
                      tlb, Xsize=80, YSize=1)

  state = {tlb:tlb, gui_id:gui_id, panel_combobox:panel_combobox, panel_values:panel_values, $
           panel_index:panel_index, info:info, $
           trace_to_nudge:trace_to_nudge, trace_id:0, shift_scale:1.0, shift_unit:'sec', $
           active_panels:active_panels, use_records:0b, nshift:1.0, $
           nshift_widget:cmajor_increment, trace_values:ptr_new(trace_values), $
           panel_copy:panel_copy, statusbar:statusbar,call_sequence:call_sequence} 
; lphilpott 24-feb-2012
; This code should be revised at some point so extraneous information is not stored in state.
; trace_values: contains the full names of the traces, needed because those displayed in the combobox may need to be truncated
; trace_to_nudge: is the text of the current active trace (probably not necessary)
; trace_id: is the index into the combobox of the current active trace, needed because there may be multiple entries of the same trace
; trace_combobox: I am removing this because it is just the widget_id of the combobox and we can get that through widget_info        

;the panel_copy will be a copy of the original panel that was nudged,
;so that it can be reset properly if the 'cancel' button is pushed
  CenterTlb, tlb
  Widget_Control, tlb, Set_UValue = state, /No_Copy
  Widget_Control, tlb, /Realize
  
  ;keep windows in X11 from snaping back to 
  ;center during tree widget events 
  if !d.NAME eq 'X' then begin
    widget_control, tlb, xoffset=0, yoffset=0
  endif
  
  XManager, 'spd_ui_nudge_options', tlb, /No_Block

  RETURN
END ;--------------------------------------------------------------------------------

