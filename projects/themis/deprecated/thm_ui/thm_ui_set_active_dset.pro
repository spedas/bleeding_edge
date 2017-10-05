;+
;NAME:
; thm_ui_set_active_dset
;PURPOSE:
; sets active datasets in themis GUI to given tplot varnames, used in
; the call_tplot widget.
;CALLING SEQUENCE:
; ss = thm_ui_set_active_dset(gui_id, active_names)
;INPUT:
; gui_id = the widget id for the master widget
; active_names = the tplot variable names
;OUTPUT:
; ss = the subscripts of the valid active varnames in the full
;      tnames() array
;HISTORY:
; 22-jan-2007, jmm, jimm@ssl.berkeley.edu
; 27-feb-2007, jmm, removed call to set_state_ptrs routine
; 10-may-2007, jmm, changed argument list, to use the GUI_ID and not
;                   the state structure
; 7-may-2008, jmm, Slight change to avoid putting in invalid names
;
;$LastChangedBy: cgoethel $
;$LastChangedDate: 2008-07-08 08:41:22 -0700 (Tue, 08 Jul 2008) $
;$LastChangedRevision: 3261 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/deprecated/thm_ui/thm_ui_set_active_dset.pro $
;
;-
Function thm_ui_set_active_dset, gui_id, varnames

  data_ss = -1
  temp_names = tnames(varnames)
  If(is_string(temp_names)) Then Begin
    data_ss = sswhere_arr(tnames(), temp_names)
    If(widget_valid(gui_id)) Then Begin
      widget_control, gui_id, get_uval = state, /no_copy
      If(ptr_valid(state.active_vnames)) Then ptr_free, state.active_vnames
      state.active_vnames = ptr_new(temp_names)
      widget_control, gui_id, set_uval = state, /no_copy
    Endif Else message, 'Invalid GUI_ID?'
  Endif Else Begin
    widget_control, gui_id, get_uval = state, /no_copy
    If(ptr_valid(state.active_vnames)) Then ptr_free, state.active_vnames
    widget_control, gui_id, set_uval = state, /no_copy
    thm_ui_update_progress, gui_id, 'No Active Dataset'
  Endelse
  Return, data_ss
End

  
