;+
;NAME:
; spd_ui_update_progress
;PURPOSE:
; Write a string into the progress widget for the THEMIS GUI
;CALLING SEQUENCE:
; spd_ui_update_progress, gui_id, input_string
;INPUT:
; gui_id = the widget_id for the GUI
; input_string = a string to be displayed
;OUTPUT:
; None
;KEYWORDS:
; message_wid = id for any other message widgets that you might like
;                to display the messages
;HISTORY:
; jmm, 9-may-2007, jimm@ssl.berkeley.edu
; jmm, 5-mar-2008, added multiple lines, and the ability to show in
;                  multiple message widgets.
;$LastChangedBy: nikos $
;$LastChangedDate: 2014-06-17 11:59:06 -0700 (Tue, 17 Jun 2014) $
;$LastChangedRevision: 15392 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/spedas_gui/utilities/spd_ui_update_progress.pro $
;-
Pro spd_ui_update_progress, gui_id, input_string, $
                            message_wid = message_wid

;Extract the state from the widget
  If(widget_valid(gui_id) And is_string(input_string)) Then Begin
    widget_control, gui_id, get_uval = state, /no_copy
    If(is_struct(state)) Then Begin
      message_buff = *state.messages ;this will always exist if there's a state
      message_buff = [temporary(message_buff), input_string]
      widget_control, state.progress_text, set_val = message_buff
      widget_control, state.progress_text, $
        set_text_top_line = n_elements(message_buff)-1
      ptr_free, state.messages
      state.messages = ptr_new(message_buff)
      widget_control, gui_id, set_uval = state, /no_copy
;set any other message buffers that are there
      If(keyword_set(message_wid)) Then Begin
        For j = 0, n_elements(message_wid)-1 Do Begin
          If(widget_valid(message_wid[j])) Then Begin
            widget_control, message_wid[j], set_val = message_buff
            widget_control, message_wid[j], $
              set_text_top_line = n_elements(message_buff)-1
          Endif
        Endfor
      Endif
    Endif

  Endif Else Begin
    dprint, 'Invalid message or widget_id'
  Endelse
  Return
End
