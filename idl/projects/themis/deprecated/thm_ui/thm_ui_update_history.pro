Function test_1st_element, string_in
  otp = ''
  test_nh = strpos(string_in, '=')
  If(test_nh[0] Ne -1) Then Begin
    px = strsplit(string_in, '=', /extract)
    otp = strcompress(px[0], /remove_all)
  Endif
  Return, otp
End

;+
;NAME:
; thm_ui_update_history
;PURPOSE:
; Adds the string input to the state structure history array
;INPUT:
; string = a string to add to the history array. Note that this is
; returned undefined, if it is passed in by reference, i/e/, if it's a
; named variable.
;OUTPUT:
; state.history is updated
;HISTORY:
; sep-2006, jmm, jimm@ssl.berkeley.edu
; 26-feb-2007, jmm, fixed problem with multiple lines when choosing
;                   multiple probes, datatypes, sataiotns, etc...
; 8-may-2007, jmm, changed so that the thm_gui widget id is now passed
;                  in, since the history widget is now on the main
;                  widget, removed some error checking, if things are
;                  undefined in here i want to know
;
;$LastChangedBy: cgoethel $
;$LastChangedDate: 2008-07-08 08:41:22 -0700 (Tue, 08 Jul 2008) $
;$LastChangedRevision: 3261 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/deprecated/thm_ui/thm_ui_update_history.pro $
;
;-

Pro thm_ui_update_history, gui_id, input_string

  
;Extract the state from the widget
  If(widget_valid(gui_id) And is_string(input_string)) Then Begin
    widget_control, gui_id, get_uval = state, /no_copy
    history = *state.history
    If(strupcase(strcompress(/remove_all, history[0])) Eq 'NONE') Then Begin
      history = temporary(input_string)
    Endif Else Begin
;check the last line of the history, and the 1st line of the input, if
;the first word is the same, an it's start_time, end_time, probe,
;dtype, asi_station or gmag_station, then take away the last line of
;the history
      check_arr = ['start_time', 'end_time', 'probe', $
                   'dtype', 'asi_station', 'gmag_station',  $
                   'varnames', 'tlimit', '!themis.remote_data_dir', $
                   '!themis.local_data_dir', '!themis.no_download', $
                   '!themis.no_update', '!themis.downloadonly', $
                   '!themis.verbose']
      nh = n_elements(history)
      h1 = test_1st_element(history[nh-1])
      h2 = test_1st_element(input_string[0])
      If(is_string(h1) And is_string(h2) And h1 Eq h2) Then Begin
        in_arr = where(check_arr Eq h1)
        If(in_arr[0] Ne -1) Then If (nh Gt 1) Then history = history[0:nh-2]
      Endif
      history = [temporary(history), temporary(input_string)]
    Endelse
    ptr_free, state.history
    state.history = ptr_new(history)
    widget_control, state.historylist, set_val = history
    widget_control, state.historylist, $
      set_text_top_line = (n_elements(history)-15) > 0
    widget_control, gui_id, set_uval = state, /no_copy        
  Endif
  Return
End

