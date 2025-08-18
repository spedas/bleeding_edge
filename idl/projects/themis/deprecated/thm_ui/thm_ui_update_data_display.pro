;+
;NAME:
; thm_ui_update_data_display
;PURPOSE:
; update the loaded-data display for the themis_w widget
;CALLIMG SEQUENCE:
; thm_ui_update_data_display, widget_id
;INPUT:
; widget_id = the id number of the widget
;HISTORY:
; dec-2006, jmm jimm@ssl.berkeley.edu
; 18-jun-2007, jmm, changed to access 'active data' widget
; 16-jul-2007, jmm, changed to add coordinate system to display
;$LastChangedBy: cgoethel $
;$LastChangedDate: 2008-07-08 08:41:22 -0700 (Tue, 08 Jul 2008) $
;$LastChangedRevision: 3261 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/deprecated/thm_ui/thm_ui_update_data_display.pro $
;
;-
Pro thm_ui_update_data_display, id, only_active = only_active, _extra = _extra
;change the data list display
  If(keyword_set(only_active)) Then Begin
    widget_control, id, get_uval = state, /no_copy
    adisplay_id = state.adatalist
    If(ptr_valid(state.active_vnames)) Then Begin
      temp_names = tnames()
      data_ss = sswhere_arr(temp_names, *state.active_vnames)
      If(data_ss[0] Ne -1) Then Begin
        p1 = *state.active_vnames
        For j = 0, n_elements(p1)-1 Do $
          p1[j] = p1[j]+' ('+cotrans_get_coord(p1[j])+')'
        widget_control, adisplay_id, set_val = p1
      Endif Else widget_control, adisplay_id, set_val = 'None'
    Endif Else Begin
      data_ss = -1
      widget_control, adisplay_id, set_val = 'None'
    Endelse
    widget_control, id, set_uval = state, /no_copy
  Endif Else Begin
    widget_control, id, get_uval = state, /no_copy
    display_id = state.datalist
    adisplay_id = state.adatalist
    If(ptr_valid(state.data_id)) Then Begin
      loaded_ids = *state.data_id
      If(ptr_valid(state.active_vnames)) Then Begin
        temp_names = tnames()
        data_ss = sswhere_arr(temp_names, *state.active_vnames)
        If(data_ss[0] Ne -1) Then Begin
        p1 = *state.active_vnames
        For j = 0, n_elements(p1)-1 Do $
          p1[j] = p1[j]+' ('+cotrans_get_coord(p1[j])+')'
        widget_control, adisplay_id, set_val = p1
        Endif Else widget_control, adisplay_id, set_val = 'None'
      Endif Else Begin
        data_ss = -1
        widget_control, adisplay_id, set_val = 'None'
      Endelse
      If(n_elements(loaded_ids) Gt 1) Then Begin
        loaded_ids = loaded_ids[1:*]
      Endif Else loaded_ids = 'No Data loaded'
      widget_control, display_id, set_val = loaded_ids
    Endif
    widget_control, id, set_uval = state, /no_copy
  Endelse
  Return
End


