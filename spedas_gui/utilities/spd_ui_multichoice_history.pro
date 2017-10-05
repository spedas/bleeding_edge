;+
; This program creates a string for the history array when multiple
; datatypes, spacecraft or stations are chosen, for use in the
; spedas_w_event routine
;$LastChangedBy: jimm $
;$LastChangedDate: 2014-02-11 10:54:32 -0800 (Tue, 11 Feb 2014) $
;$LastChangedRevision: 14326 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/spedas_gui/utilities/spd_ui_multichoice_history.pro $
;-
Function spd_ui_multichoice_history, init_string, multi_string

  n = n_elements(multi_string)
  
  mss = ''''+multi_string+''''
  ext = init_string+'['+mss[0]
  If(n Gt 1) Then Begin
    For j = 1, n-1 Do ext = ext+','+mss[j]
  Endif
  ext = ext+']'
  Return, ext
End

