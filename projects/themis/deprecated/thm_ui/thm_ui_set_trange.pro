;+
;NAME:
; thm_ui_set_trange
;PURPOSE:
; A widget interface for setting time ranges for the thm_gui widget
;CALLING SEQUENCE:
; thm_ui_set_trange, master_widget_id
;INPUT:
; master_widget_id = the id number of the widget that calls this
;OUTPUT:
; none, the start and end time are set
;HISTORY:
; 9-may-2007, jmm, jimm@ssl.berkeley.edu
; 12-jul-2007, jmm, Removed ability to type in time values..
; 19-jul-2007, jmm, typed time values are back..
; 25-oct-2007, jmm, Added kill_request block
;$LastChangedBy: jimm $
;$LastChangedDate: 2011-11-04 11:47:05 -0700 (Fri, 04 Nov 2011) $
;$LastChangedRevision: 9262 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/deprecated/thm_ui/thm_ui_set_trange.pro $
;
;-
Pro thm_ui_set_trange_event, event

  Common saved_time_sel, time_selected
  t0 = -1 & t1 = -1

;If the 'X' is hit...
  If(TAG_NAMES(event, /STRUCTURE_NAME) EQ 'WIDGET_KILL_REQUEST') Then Begin
    If(is_struct(state) Eq 0) Then $
      widget_control, event.top, get_uval = state, /no_copy
    gui_id = state.master_id
    widget_control, event.top, set_uval = state, /no_copy
    If(is_struct(wstate)) Then $
      widget_control, gui_id, set_uval = wstate, /no_copy
    thm_ui_update_progress, gui_id, 'End Choosing time range'
    widget_control, event.top, /destroy
    Return
  Endif

;start here
  widget_control, event.id, get_uval = uval
  Case uval Of
    'EXIT': Begin
      widget_control, event.top, get_uval = state, /no_copy      
      thm_ui_update_progress, state.master_id, 'End Choosing time range'
      widget_control, event.top, set_uval = state, /no_copy      
      widget_control, event.top, /destroy
    End
    'STTIME':Begin
      widget_control, event.top, get_uval = state, /no_copy
      For j = 0, n_elements(state.button_arr)-1 Do $
        widget_control, state.button_arr[j], sensitive = 0
      widget_control, state.master_id, get_uval = wstate, /no_copy
      init_time = wstate.st_time
      widget_control, state.master_id, set_uval = wstate, /no_copy
      thm_ui_tselect, init_time = init_time
      t0 = time_selected
      If(is_struct(t0)) Then Begin
;Set time in thm_gui widget
        t1 = time_double(temporary(t0))
        t0 = time_string(t1)
        widget_control, state.master_id, get_uval = wstate, /no_copy
        wstate.st_time = t1
        wstate.pstate.st_time = t1
        t0x = wstate.en_time
        widget_control, state.master_id, set_uval = wstate, /no_copy
        thm_ui_update_history, state.master_id, 'start_time = '''+t0+''''
;Set time in display
        widget_control, state.sttime_display, set_val = t0
        If(t0x Le t1) Then thm_ui_update_progress, state.master_id, 'End Time is LE Start Time' $
        Else thm_ui_update_progress, state.master_id, 'Valid Start Time selected'
      Endif Else Begin
        thm_ui_update_progress, state.master_id, $
          'Bad time selection, No action taken'
      Endelse
      For j = 0, n_elements(state.button_arr)-1 Do $
        widget_control, state.button_arr[j], sensitive = 1
      widget_control, event.top, set_uval = state, /no_copy
    End
    'ENTIME':Begin
      widget_control, event.top, get_uval = state, /no_copy
      For j = 0, n_elements(state.button_arr)-1 Do $
        widget_control, state.button_arr[j], sensitive = 0
      widget_control, state.master_id, get_uval = wstate, /no_copy
      init_time = wstate.en_time
      widget_control, state.master_id, set_uval = wstate, /no_copy
      thm_ui_tselect, init_time = init_time
      t0 = time_selected
      If(is_struct(t0)) Then Begin
        t1 = time_double(temporary(t0))
        t0 = time_string(t1)
        widget_control, state.master_id, get_uval = wstate, /no_copy
        wstate.en_time = t1
        wstate.pstate.en_time = t1
        t0x = wstate.st_time    ;for error checking
        widget_control, state.master_id, set_uval = wstate, /no_copy
        thm_ui_update_history, state.master_id, 'end_time = '''+t0+''''
        widget_control, state.entime_display, set_val = t0
        If(t1 Le t0x) Then thm_ui_update_progress, state.master_id, 'End Time is LE Start Time' $
        Else thm_ui_update_progress, state.master_id, 'Valid End Time selected'
      Endif Else Begin
        thm_ui_update_progress, state.master_id, $
          'Bad time selection, No action taken'
      Endelse
      For j = 0, n_elements(state.button_arr)-1 Do $
        widget_control, state.button_arr[j], sensitive = 1
      widget_control, event.top, set_uval = state, /no_copy
    End
    'STTIME_DISPLAY':Begin
      widget_control, event.id, get_val = temp_string
      t0 = thm_ui_timefix(temp_string)
      If(event.type Le 2) Then Begin
        If(is_string(t0)) Then Begin
          t1 = time_double(t0)
          widget_control, event.top, get_uval = state, /no_copy
          widget_control, state.master_id, get_uval = wstate, /no_copy
          wstate.st_time = t1
          wstate.pstate.st_time = t1
          t0x = wstate.en_time
          widget_control, state.master_id, set_uval = wstate, /no_copy
          thm_ui_update_history, state.master_id, 'start_time = '''+t0+''''
          If(t0x Le t1) Then thm_ui_update_progress, state.master_id, 'End Time is LE Start Time' $
          Else thm_ui_update_progress, state.master_id, 'Valid Start Time selected'
          widget_control, event.top, set_uval = state, /no_copy
        Endif Else Begin
          widget_control, event.top, get_uval = state, /no_copy
          thm_ui_update_progress, state.master_id, $
            'Bad time selection, No action taken'
          widget_control, event.top, set_uval = state, /no_copy
        Endelse
      Endif
    End
    'ENTIME_DISPLAY':Begin
      widget_control, event.id, get_val = temp_string
      t0 = thm_ui_timefix(temp_string)
      If(event.type Le 2) Then Begin
        If(is_string(t0)) Then Begin
          t1 = time_double(t0)
          widget_control, event.top, get_uval = state, /no_copy
          widget_control, state.master_id, get_uval = wstate
          wstate.en_time = t1
          wstate.pstate.en_time = t1
          t0x = wstate.st_time  ;for error checking
          widget_control, state.master_id, set_uval = wstate, /no_copy
          thm_ui_update_history, state.master_id, 'end_time = '''+t0+''''
          If(t1 Le t0x) Then thm_ui_update_progress, state.master_id, 'End Time is LE Start Time' $
          Else thm_ui_update_progress, state.master_id, 'Valid End Time selected'
          widget_control, event.top, set_uval = state, /no_copy
        Endif Else Begin
          widget_control, event.top, get_uval = state, /no_copy
          thm_ui_update_progress, state.master_id, $
            'Bad time selection, No action taken'
          widget_control, event.top, set_uval = state, /no_copy
        Endelse
      Endif
    End
  Endcase
End

Pro thm_ui_set_trange, master_id

;time selection widget
  timesel = widget_base(/col, /align_center, group_leader = master_id, $
                        title = 'THEMIS: Time Selection', $
                        /tlb_kill_request_events)
  timebase = widget_base(timesel, /row, /align_left, $
                        title = 'Time Selection Widget')
  timeselbase = widget_base(timebase, /column, /align_left, frame = 5)

; sttime button
  sttime_button = widget_base(timeselbase, /col, /align_left)
  sttimebut = widget_button(sttime_button, val = ' Choose Start time ', $
                            uval = 'STTIME', /align_left)
; entime button
  entime_button = widget_base(timeselbase, /col, /align_left)
  entimebut = widget_button(entime_button, val = ' Choose End time ', $
                            uval = 'ENTIME', /align_left)
;time display widget
  timedisplaybase = widget_base(timebase, /column, /align_left, frame = 5)

;set init values
  widget_control, master_id, get_uval = wstate, /no_copy
  If(is_struct(wstate)) Then Begin
    t0 = time_string(wstate.st_time)
    t1 = time_string(wstate.en_time)
    widget_control, master_id, set_uval = wstate, /no_copy
  Endif Else Begin
    message, 'No THM_GUI widget?'
  Endelse
 
; sttime text
  sttime_display = widget_text(timedisplaybase, /edit, $
                               uval = 'STTIME_DISPLAY', $
                               val = t0, xsize = 30, /all_events)
; entime text
  entime_display = widget_text(timedisplaybase, /edit, $
                               uval = 'ENTIME_DISPLAY', $
                               val = t1, xsize = 30, /all_events)
;exit button
  exitbut = widget_button(timesel, val = ' Accept and Close ', $
                          uval = 'EXIT', /align_center)

;set id in main GUI
  widget_control, master_id, get_uval = wstate
  wstate.trange_id = timesel
  widget_control, master_id, set_uval = wstate  
  state = {master_id:master_id, $
           sttime_display:sttime_display, $
           entime_display:entime_display, $
           button_arr:[sttimebut, entimebut, exitbut, $
                       sttime_display, entime_display]}

  widget_control, timesel, set_uval = state, /no_copy
  widget_control, timesel, /realize
  xmanager, 'thm_ui_set_trange', timesel, /no_block

  Return
End


