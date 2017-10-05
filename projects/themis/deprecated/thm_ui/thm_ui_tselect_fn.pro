;+
; Calls the thm_tselect widget, returns the value..
;16-jul-2007, jmm added the init_time input
;$LastChangedBy: cgoethel $
;$LastChangedDate: 2008-07-08 08:41:22 -0700 (Tue, 08 Jul 2008) $
;$LastChangedRevision: 3261 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/deprecated/thm_ui/thm_ui_tselect_fn.pro $
;
;-
Function thm_ui_tselect_fn, init_time

  Common saved_time_sel, time_selected
  thm_ui_tselect, init_time = init_time
  return, time_selected
End
