;+
;NAME:
;thm_ui_help
;PURPOSE:
; A widget to display the file 'thm_gui.txt' help
;
;$LastChangedBy: cgoethel $
;$LastChangedDate: 2008-07-08 08:41:22 -0700 (Tue, 08 Jul 2008) $
;$LastChangedRevision: 3261 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/deprecated/thm_ui/thm_ui_help.pro $
;
;-
Pro thm_ui_help_event, event
;  what happened?
  widget_control, event.id, get_uval = uval
  Case uval Of
    'EXIT': widget_control, event.top, /destroy
  Endcase
  Return
End
Pro thm_ui_help

  help_arr = 'No Help File'
;Find the directory with the file
  p = expand_path(!path, /array) ;get the path
  If(!version.os_family Eq 'Windows') Then Begin
    d = strpos(p, 'themis\examples')
  Endif Else d = strpos(p, 'themis/examples')
  ok = where(d Ne -1)
  If(ok[0] Ne -1) Then Begin
    f = file_search(p[ok[0]]+'/'+'thm_gui.txt')
    If(is_string(f)) Then Begin
      lines = file_lines(f)
      help_arr = strarr(lines)
      Openr, unit, f, /get_lun
      readf, unit, help_arr
      Free_lun, unit
    Endif
  Endif

;here is the display widget,not editable
  helpid = widget_base(/col, title = 'THEMIS: GUI Help')
  helpdisplay = widget_text(helpid, uval = 'HELP_DISPLAY', val = help_arr, $
                            xsize = 80, ysize = 40, /scroll, frame = 5)
;a widget for buttons
  buttons = widget_base(helpid, /row, /align_center, frame = 5)
; exit button
  exit_button = widget_base(buttons, /col, /align_center)
  exitbut = widget_button(exit_button, val = ' Close ', uval = 'EXIT', $
                        /align_center)
  state = {help:help_arr}
  widget_control, helpid, set_uval = state, /no_copy
  widget_control, helpid, /realize
  xmanager, 'thm_ui_help', helpid, /no_block
  Return
End


