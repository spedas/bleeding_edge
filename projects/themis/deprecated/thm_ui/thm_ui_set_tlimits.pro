;Function thm_ui_temp_call_ctime, otp, err_msg = err_msg
;This only exists to catch errors gracefully, in case ctime bombs
;  otp = -1
;  err_msg = ''
;  err_xxx = 0
;  catch, err_xxx
;  If(err_xxx Ne 0) Then Begin
;    catch, /cancel
;    help, /last_message, output = err_msg
;    For j = 0, n_elements(err_msg)-1 Do print, err_msg[j]
;    Return, -1
;  Endif
;  ctime, trange_new, npoints = 2
;  Return, trange_new
;End

 ;+
;NAME:
; thm_ui_set_tlimits
;PURPOSE:
; A widget interface for setting time ranges for the thm_gui widget
;CALLING SEQUENCE:
; thm_ui_set_tlimits, master_widget_id
;INPUT:
; master_widget_id = the id number of the widget that calls this
;OUTPUT:
; none, the start and end time are set
;HISTORY:
; 9-may-2007, jmm, jimm@ssl.berkeley.edu
; 12-jul-2007, jmm, Removed ability to type in time values....
; 19-jul-2007, jmm, typed time values are back..
; 29-jul-2007, jmm, added cancel button
; 25-Oct-2007, jmm, times are held in main GUI state structure
;$LastChangedBy: pcruce $
;$LastChangedDate: 2013-09-19 11:51:11 -0700 (Thu, 19 Sep 2013) $
;$LastChangedRevision: 13087 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/deprecated/thm_ui/thm_ui_set_tlimits.pro $
;
;-
Pro thm_ui_set_tlimits_event, event

  @tplot_com
  Common tlimits_saved, t0_sav, t1_sav, t0_init, t1_init
  Common saved_time_sel, time_selected

  err_xxx = 0
  catch, err_xxx
  If(err_xxx Ne 0) Then Begin
    catch, /cancel
    help, /last_message, output = err_msg
    For j = 0, n_elements(err_msg)-1 Do print, err_msg[j]
;kill the widget and return here if there is a catch
    If(is_struct(state) Eq 0) Then Begin
      widget_control, event.top, get_uval = state, /no_copy
    Endif
    thm_ui_update_progress, state.gui_id, 'Error, No Time limits chosen'
    thm_ui_update_history, state.gui_id, [';*** FYI', ';'+err_msg, 'No Time Limits Chosen']
    widget_control, state.messw, set_val = 'Error, No Time limits chosen'
    widget_control, event.top, /destroy
    Return
  Endif

;If the 'X' is hit...
  If(TAG_NAMES(event, /STRUCTURE_NAME) EQ 'WIDGET_KILL_REQUEST') Then Begin
    If(is_struct(state) Eq 0) Then $
      widget_control, event.top, get_uval = state, /no_copy
    gui_id = state.gui_id & messw = state.messw
    widget_control, event.top, set_uval = state, /no_copy
    If(is_struct(wstate)) Then $
      widget_control, gui_id, set_uval = wstate, /no_copy
    thm_ui_update_progress, message_wid = messw,  gui_id, 'No Time limits chosen'
    widget_control, event.top, /destroy
    Return
  Endif
;Else start here
  widget_control, event.id, get_uval = uval
  If(uval Eq 'CANCEL') Then Begin
    widget_control, event.top, get_uval = state, /no_copy
    gui_id = state.gui_id & messw = state.messw
    widget_control, event.top, set_uval = state, /no_copy
    thm_ui_update_progress, message_wid = messw,  gui_id, 'No Time limits chosen'
    widget_control, event.top, /destroy
  Endif Else If(uval Eq 'EXIT') Then Begin
    widget_control, event.top, get_uval = state, /no_copy      
    thm_ui_update_progress, message_wid = state.messw,  state.gui_id, $
      'End Choosing time limits'
    h = 'tlimit, '+''''+time_string(t0_sav)+''''+', '+ $
      ''''+time_string(t1_sav)+''''
    thm_ui_update_history, state.gui_id, h
;set the times in the main GUI widget here
    widget_control, state.gui_id, get_uval = wstate, /no_copy
    wstate.pstate.st_time = min([t0_sav, t1_sav]);to protect from cursor set times
    wstate.pstate.en_time = max([t0_sav, t1_sav])
    t0_sav = wstate.pstate.st_time
    t1_sav = wstate.pstate.en_time
    pstate = wstate.pstate
    If(ptr_valid(wstate.active_vnames)) Then Begin
      tvn = *wstate.active_vnames
    Endif Else tvn = '*'
    widget_control, state.gui_id, set_uval = wstate, /no_copy
    widget_control, event.top, set_uval = state, /no_copy
;You need to be sure that the window is still there, or else do a
;tplot
    do_tplot = 1b
;First check the window
;tlimit crashes badly if we don't have the window defined, but the
;window may have been deleted, in fact, there may be no windows left
;The window that is up may not match what tplot thinks it has, 
    cwno = pstate.current_wno
    cwno_tplot = -1
    If(is_struct(tplot_vars)) Then Begin
      If(is_struct(tplot_vars.settings)) Then $
        If(tag_exist(tplot_vars.settings, 'window')) Then $
        cwno_tplot = tplot_vars.settings.window
    Endif
;If all the windows match, then don't do the plot
    If(cwno Eq cwno_tplot And cwno Eq !d.window And !d.window Ne -1) Then do_tplot = 0b
    If(do_tplot) Then Begin
      window, cwno, xsize = pstate.windowsize[0], ysize = pstate.windowsize[1]
      tplot, tvn
    Endif
;Now tlimit should be ok
    tlimit, t0_sav, t1_sav
    widget_control, event.top, /destroy
  Endif Else If(uval Eq 'STTIME_DISPLAY') Then Begin
    widget_control, event.top, get_uval = state, /no_copy
    widget_control, event.id, get_val = temp_string
    t0 = thm_ui_timefix(temp_string)
    If(event.type Le 2) Then Begin
      If(is_string(t0)) Then Begin
        t0_sav = time_double(t0)
        If(t1_sav Le t0_sav) Then Begin
          thm_ui_update_progress, message_wid = state.messw,  state.gui_id, $
            'End Time is LE Start Time'
        Endif Else Begin
          thm_ui_update_progress, message_wid = state.messw,  state.gui_id, $
            'Valid Start Time selected'
        Endelse
      Endif Else Begin
        thm_ui_update_progress, message_wid = state.messw,  state.gui_id, $
          'Bad time selection, No action taken'
      Endelse
    Endif
    widget_control, event.top, set_uval = state, /no_copy
  Endif Else If(uval Eq 'ENTIME_DISPLAY') Then Begin
    widget_control, event.top, get_uval = state, /no_copy
    widget_control, event.id, get_val = temp_string
    t1 = thm_ui_timefix(temp_string)
    If(event.type Le 2) Then Begin
      If(is_string(t1)) Then Begin
        t1_sav = time_double(t1)
        If(t1_sav Le t0_sav) Then Begin
          thm_ui_update_progress, message_wid = state.messw,  state.gui_id, $
            'End Time is LE Start Time'
        Endif Else Begin
          thm_ui_update_progress, message_wid = state.messw,  state.gui_id, $
            'Valid End Time selected'
        Endelse
      Endif Else Begin
        thm_ui_update_progress, message_wid = state.messw,  state.gui_id, $
          'Bad time selection, No action taken'
      Endelse
    Endif
    widget_control, event.top, set_uval = state, /no_copy
  Endif Else Begin
    widget_control, event.top, get_uval = state, /no_copy
    For j = 0, n_elements(state.button_arr)-1 Do $
      widget_control, state.button_arr[j], sensitive = 0
    Case uval Of
      'STTIME':Begin
        thm_ui_tselect, init_time = t0_sav
        t0 = time_selected
        If(is_struct(t0)) Then Begin
          t0_sav = time_double(t0)
;Set time in display
          widget_control, state.sttime_display, set_val = time_string(t0_sav)
;erorr check
          If(t1_sav Le t0_sav) Then Begin
            thm_ui_update_progress, message_wid = state.messw,  state.gui_id, $
              'End Time is LE Start Time'
          Endif Else Begin
            thm_ui_update_progress, message_wid = state.messw,  state.gui_id, $
              'Valid Start Time selected'
          Endelse
        Endif Else Begin
          thm_ui_update_progress, message_wid = state.messw,  state.gui_id, $
            'Bad time selection, No action taken'
        Endelse
      End
      'ENTIME':Begin
        thm_ui_tselect, init_time = t1_sav
        t1 = time_selected
        If(is_struct(t1)) Then Begin
          t1_sav = time_double(t1)
          widget_control, state.entime_display, set_val = time_string(t1_sav)
          If(t1_sav Le t0_sav) Then Begin
            thm_ui_update_progress, message_wid = state.messw,  state.gui_id, $
              'End Time is LE Start Time'
          Endif Else Begin
            thm_ui_update_progress, message_wid = state.messw,  state.gui_id, $
              'Valid End Time selected'
          Endelse
        Endif Else Begin
          thm_ui_update_progress, message_wid = state.messw,  state.gui_id, $
            'Bad time selection, No action taken'
        Endelse
      End
      'TLIMIT':Begin
        widget_control, state.gui_id, get_uval = wstate, /no_copy
        If(ptr_valid(wstate.active_vnames)) Then Begin
          tvn = *wstate.active_vnames
        Endif Else tvn = ''
        pstate = wstate.pstate  ;dude
        widget_control, state.gui_id, set_uval = wstate, /no_copy
        If(pstate.ptyp Eq 'SCREEN') Then Begin
          If(is_string(tvn)) Then Begin
;Do we need to do this tplot?
            do_tplot = 1b
;First check the window
;ctime crashes badly if we don't have the window defined, but the
;window may have been deleted, in fact, there may be no windows left
;The window that is up may not match what tplot thinks it has, 
            cwno = pstate.current_wno
            cwno_tplot = -1
            If(is_struct(tplot_vars)) Then Begin
              If(is_struct(tplot_vars.settings)) Then Begin
                If(tag_exist(tplot_vars.settings, 'window')) Then $
                  cwno_tplot = tplot_vars.settings.window
              Endif
            Endif
;If all the windows match, check variables. If all of the vars match,
;then don't do the plot
            If(cwno Eq cwno_tplot And cwno Eq !d.window And !d.window Ne -1) Then Begin
              If(is_struct(tplot_vars)) Then Begin
                If(is_struct(tplot_vars.options)) Then Begin
                  tvn_t = tplot_vars.options.varnames
                  If(n_elements(tvn_t) Eq n_elements(tvn)) Then Begin
                    do_tplot = 0b ;don't do it unless there's a mismatch
                    For j = 0, n_elements(tvn)-1 Do If(tvn[j] Ne tvn_t[j]) Then do_tplot = 1b
                  Endif
                Endif
              Endif
            Endif
            If(do_tplot) Then Begin
              window, cwno, xsize = pstate.windowsize[0], ysize = pstate.windowsize[1]
              tplot, tvn
            Endif
;Now ctime should be useable
            trange_new = -1
            ctime, trange_new, npoints = 2
            If(n_elements(trange_new) Eq 2) Then Begin
              t0_sav = trange_new[0] & t1_sav = trange_new[1]
              widget_control, state.sttime_display, set_val = time_string(t0_sav)
              widget_control, state.entime_display, set_val = time_string(t1_sav)
            Endif Else Begin
              thm_ui_update_progress, message_wid = state.messw,  state.gui_id, $
                'Bad time Selection '
            Endelse
          Endif Else Begin
            thm_ui_update_progress, message_wid = state.messw,  state.gui_id, $
              'No Active Dataset, No time selection '
          Endelse
        Endif Else Begin
          thm_ui_update_progress, message_wid = state.messw,  state.gui_id, $
            'Please set SCREEN plot for time selection '
        Endelse
      End
      'RESET_TLIMIT':Begin
        t0_sav = t0_init & t1_sav = t1_init
        widget_control, state.sttime_display, set_val = time_string(t0_init)
        widget_control, state.entime_display, set_val = time_string(t1_init)
      End
    Endcase
    For j = 0, n_elements(state.button_arr)-1 Do $
      widget_control, state.button_arr[j], sensitive = 1
    widget_control, event.top, set_uval = state, /no_copy
  Endelse
End

Pro thm_ui_set_tlimits, proc_id

  Common tlimits_saved, t0_sav, t1_sav, t0_init, t1_init

;time selection widget
  timesel = widget_base(/col, /align_center, $
                        title = 'THEMIS: Time Selection Widget', $
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
;set init values, if they don't exist
  widget_control, proc_id, get_uval = pstate, /no_copy
  widget_control, pstate.cw, get_uval = wstate, /no_copy
  gui_id = pstate.cw
  messw = pstate.messw
  If(n_elements(t0_sav) Eq 0 Or n_elements(t1_sav) Eq 0) Then Begin
     t0_sav = wstate.pstate.st_time & t1_sav = wstate.pstate.en_time
  Endif
  If(n_elements(t0_init) Eq 0 Or n_elements(t1_init) Eq 0) Then Begin
     t0_init = wstate.st_time & t1_init = wstate.en_time
  Endif
  widget_control, pstate.cw, set_uval = wstate, /no_copy
  widget_control, proc_id, set_uval = pstate, /no_copy

; sttime text
  sttime_display = widget_text(timedisplaybase, /edit, $
                               uval = 'STTIME_DISPLAY', $
                               val = time_string(t0_sav), $
                               xsize = 30, /all_events)
; entime text
  entime_display = widget_text(timedisplaybase, /edit, $
                               uval = 'ENTIME_DISPLAY', $
                               val = time_string(t1_sav), $
                               xsize = 30, /all_events)

;widget for tlimit and tlimit reset
  xbutton0 = widget_base(timebase, /col, /align_center)
;tlimit button
  tlimitbut = widget_button(xbutton0, val = ' Tlimits from Cursor ', $
                            uval = 'TLIMIT', /align_center)
;tlimit reset button
  tlimitresetbut = widget_button(xbutton0, val = ' Reset to Init value ', $
                            uval = 'RESET_TLIMIT', /align_center)
;widget for cancel and exit buttons
  xbutton = widget_base(timesel, /row, /align_center)
;cancel button
  cancelbut = widget_button(xbutton, val = ' Cancel ', $
                            uval = 'CANCEL', /align_center)
;exit button
  exitbut = widget_button(xbutton, val = ' Accept and Close ', $
                          uval = 'EXIT', /align_center)

  button_arr = [sttimebut, entimebut, tlimitbut, tlimitresetbut, exitbut, $
                cancelbut, sttime_display, entime_display]
  state = {proc_id:proc_id, $
           gui_id:gui_id, $
           messw:messw, $
           sttime_display:sttime_display, $
           entime_display:entime_display, $
           button_arr:button_arr}

  widget_control, timesel, set_uval = state, /no_copy
  widget_control, timesel, /realize
  xmanager, 'thm_ui_set_tlimits', timesel, /no_block

  Return
End


