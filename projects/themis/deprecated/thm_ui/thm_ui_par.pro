;+
;NAME:
; thm_ui_par
;PURPOSE:
; Simple widget that asks for a parameter
;CALLING SEQUENCE:
; new_value = thm_ui_par(name, init_value)
;INPUT:
; name = the name of the parameter, e.g., 'time_resolution'
; init_value = the initial value of the parameter, e.g., '1.0', must
;              be a string.
;OUTPUT:
; new_value = the output value of the parameter, a string, e.g., '4.67'
;HISTORY:
; 22-jan-2007, jmm, jimm@ssl.berkeley.edu
; 25-OCt-2007, jmm, added KILL_REQUEST block
;$LastChangedBy: cgoethel $
;$LastChangedDate: 2008-07-08 08:41:22 -0700 (Tue, 08 Jul 2008) $
;$LastChangedRevision: 3261 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/deprecated/thm_ui/thm_ui_par.pro $
;
;-

Pro thm_ui_par0_event, event
  common thm_ui_par0_private, value_sav

;If the 'X' is hit...
  If(TAG_NAMES(event, /STRUCTURE_NAME) EQ 'WIDGET_KILL_REQUEST') Then Begin
    value_sav = 'Cancelled'
    widget_control, event.top, /destroy
    Return
  Endif
  widget_control, event.id, get_uval = uval
  Case uval Of
    'YES':widget_control, event.top, /destroy
    'NO':Begin
      value_sav = 'Cancelled'
      widget_control, event.top, /destroy
    End
    'LIST':Begin
      widget_control, event.id, get_val = temp_string
      value_sav = temp_string
    End
  Endcase
Return
End
Pro thm_ui_par0, name, init_value

  master = widget_base(/col, title = 'Input Value', /tlb_kill_request_events)

  listid = widget_base(master, /row, /align_center, /frame)
  flabel = widget_label(listid, value = name)
  listw = widget_text(listid, value = init_value, $
                      xsiz = max(strlen(init_value))+20, $
                      ysiz = n_elements(init_value)+1, $
                      uval = 'LIST', $
                      /editable, /all_events)
  no_button = widget_button(master, val = 'Cancel', $
                            uval = 'NO', /align_center)
  yes_button = widget_button(master, val = 'Accept and Close', $
                             uval = 'YES', /align_center)
  state = {master:master, yes_button:yes_button, listw:listw}
  widget_control, master, set_uval = state, /no_copy
  widget_control, master, /realize
  xmanager, 'thm_ui_par0', master
  Return
End
Function thm_ui_par, name, init_value
  common thm_ui_par0_private, value_sav

  value_sav = init_value
  thm_ui_par0, name, init_value
  otp = value_sav

  Return, otp
End
