;+
;NAME:
; thm_ui_update_data_all
;PURPOSE:
; Calls thm_ui_set_data_id, thm_ui_set_active_dset and
; thm_ui_update_data_display in one procedure, 
;CALLING SEQUENCE:
; thm_ui_update_data_all, gui_id, active_vnames
;INPUT:
; gui_id = a widget id for the gui
;OUTPUT:
; none
;HISTORY:
; 5-jun-2007, jmm, jimm@ssl.berkeley.edu
; 7-may-2008, jmm, sort and uniq functionality is handled by tnames
;                  call. This is now a short program....
;$LastChangedBy: cgoethel $
;$LastChangedDate: 2008-07-08 08:41:22 -0700 (Tue, 08 Jul 2008) $
;$LastChangedRevision: 3261 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/deprecated/thm_ui/thm_ui_update_data_all.pro $
;-
Pro thm_ui_update_data_all, gui_id, active_vnames0, _extra = _extra

  If(widget_valid(gui_id)) Then Begin
    thm_ui_set_data_id, gui_id
    active_vnames = tnames(active_vnames0)
    If(is_string(active_vnames)) Then Begin
      data_ss = thm_ui_set_active_dset(gui_id, active_vnames)
    Endif
    thm_ui_update_data_display, gui_id, _extra = _extra
  Endif Else message, 'Invalid GUI_ID?'
  Return
End
