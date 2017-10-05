;+
; This program creates a string for the history array when multiple
; datatypes, spacecraft or stations are chosen, for use in the
; themis_w_event routine
;$LastChangedBy: cgoethel $
;$LastChangedDate: 2008-07-08 08:41:22 -0700 (Tue, 08 Jul 2008) $
;$LastChangedRevision: 3261 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/deprecated/thm_ui/thm_ui_multichoice_history.pro $
;-
Function thm_ui_multichoice_history, init_string, multi_string

  n = n_elements(multi_string)
  
  mss = ''''+multi_string+''''
  ext = init_string+'['+mss[0]
  If(n Gt 1) Then Begin
    For j = 1, n-1 Do ext = ext+','+mss[j]
  Endif
  ext = ext+']'
  Return, ext
End

