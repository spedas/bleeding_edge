;+
;NAME:
; thm_ui_progobj__define
;PURPOSE:
; defines an object to pass through into file_retrieve and
; file_http_copy that allows updates to the thm_gui progress widget
;METHODS DEFINED IN THIS CLASS:
; set = sets the parameter (only one, the gui widget id)
; get = returns the parameter
; update = if called, this updates the thm_gui progress widget, with
;          the input text
; checkcancel = Currently does nothing, but will eventually allow the
;               user to cancel a download.
;HISTORY:
; 15-may-2007, jmm, jimm@ssl.berkeley.edu
; 24-jul-2007, jmm, activated checkcancel, to see if it can do anything...
; 5-mar-2008, jmm, pass _extra through to thm_ui_update_progress, to
;                  allow the message_wid value to be passed through
; $LastChangedBy: jimm $
; $LastChangedDate: 2009-01-20 11:23:55 -0800 (Tue, 20 Jan 2009) $
; $LastChangedRevision: 4561 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/deprecated/thm_ui/thm_ui_progobj__define.pro $
;-
Function thm_ui_progobj::init, _extra = _extra
  self -> set, _extra = _extra
  Return, 1
End
Pro thm_ui_progobj::cleanup
  self -> set, gui_id = -1
  Return
End
Function thm_ui_progobj::get, gui_id = gui_id, _extra = _extra
  If(keyword_set(gui_id)) Then Begin
    Return, self.gui_id
  Endif Else Return, gui_id
End
Pro thm_ui_progobj::set, gui_id = gui_id, _extra = _extra
  If(keyword_set(gui_id)) Then Begin
    self.gui_id = long(gui_id[0])
  Endif
  Return
End
Function thm_ui_progobj::checkcancel, ioerror = ioerror, _extra = _extra
;  kbrd_quit = (strupcase(get_kbrd(0)) EQ 'Q')
;  If(kbrd_quit Eq 1) Then qquit = 1b Else qquit = 0b
  qquit = 0b
  return, qquit
End
Pro thm_ui_progobj::update, percent, text = text, history_too = history_too, $
                  nocomment = nocomment, _extra = _extra
  If(is_string(text)) Then Begin
    gui_id = self -> get(/gui_id)
    If(gui_id Ne -1) Then Begin
      thm_ui_update_progress, gui_id, text, _extra = _extra
      If(keyword_set(history_too)) Then Begin
        If(keyword_set(nocomment)) Then thm_ui_update_history, gui_id, text $
        Else thm_ui_update_history, gui_id, ';'+text
      Endif
    Endif
  Endif
  Return
End
Pro thm_ui_progobj__define
  self = {thm_ui_progobj, gui_id:0l}
  Return
End


