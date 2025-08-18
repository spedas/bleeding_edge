;+
;NAME:
;thm_ui_error
;PURPOSE:
; A widget to display, edit and save the file 'thm_gui_error.txt' error
;
;$LastChangedBy: cgoethel_new $
;$LastChangedDate: 2009-03-12 14:24:14 -0700 (Thu, 12 Mar 2009) $
;$LastChangedRevision: 5269 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/deprecated/thm_ui/thm_ui_error.pro $
;
;-
Pro thm_ui_error_event, event
;  what happened?
  widget_control, event.id, get_uval = uval
  Case uval Of
    'EXIT': widget_control, event.top, /destroy
    'ERROR_DISPLAY':Begin
      widget_control, event.id, get_val = error_arr
      If(is_string(error_arr)) Then Begin
        widget_control, event.top, get_uval = state, /no_copy
        ptr_free, state.error
        state.error = ptr_new(temporary(error_arr))
      Endif
      widget_control, event.top, set_uval = state, /no_copy
    End
    'SAVE': Begin
      widget_control, event.top, get_uval = state, /no_copy
      error_arr = *state.error  ;this will always work
      widget_control, event.top, set_uval = state, /no_copy
      nerr = n_elements(error_arr)
      xt = time_string(systime(/sec))
      ttt = strmid(xt, 0, 4)+strmid(xt, 5, 2)+strmid(xt, 8, 2)+$
        '_'+strmid(xt, 11, 2)+strmid(xt, 14, 2)+strmid(xt, 17, 2)
      ofile = 'themis_help_request_'+ttt+'.txt'
      osf = strupcase(!version.os_family)
      If(osf Eq 'WINDOWS') Then ofile0 = file_expand_path('')+'\'+ofile $
      Else ofile0 = file_expand_path('')+'/'+ofile
      ofile = dialog_pickfile(title = 'THEMIS Help Request Filename', $
                              filter = '*.txt', file = ofile0)
      If(is_string(ofile)) Then Begin
        openw, unit, ofile, /get_lun
        For j = 0, nerr-1 Do printf, unit, error_arr[j]
        free_lun, unit
        If(obj_valid(!themis.progobj)) Then Begin
          !themis.progobj -> update, 0.0, $
            text = 'THEMIS Help Request Saved as File: '+ofile
        Endif 
      Endif Else Begin
        If(obj_valid(!themis.progobj)) Then $
          !themis.progobj -> update, 0.0, text = 'Operation Cancelled'
      Endelse
    End
  Endcase
  Return
End
Pro thm_ui_error

  error_arr = 'No Error File'
;Find the directory with the file
  p = expand_path(!path, /array) ;get the path
  If(!version.os_family Eq 'Windows') Then Begin
    d = strpos(p, 'themis\common')
  Endif Else d = strpos(p, 'themis/common')
  ok = where(d Ne -1)
  If(ok[0] Ne -1) Then Begin
    f = file_search(p[ok[0]]+'/'+'themis_error_message.txt')
    If(is_string(f)) Then Begin
      lines = file_lines(f)
      error_arr = strarr(lines)
      Openr, unit, f, /get_lun
      readf, unit, error_arr
      Free_lun, unit
    Endif
  Endif

;here is the display widget, editable
  errorid = widget_base(/col, $
                        title = 'THEMIS: Help Request Form')
  errordisplay = widget_text(errorid, uval = 'ERROR_DISPLAY', $
                             val = error_arr, /all_events, $
                             /editable, xsize = 80, ysize = 40, /scroll, $
                             frame = 5)
;a widget for buttons
  buttons = widget_base(errorid, /row, /align_center)

; save button
  save_button = widget_base(buttons, /col, /align_center)
  savebut = widget_button(save_button, val = ' Save ', uval = 'SAVE', $
                        /align_center, scr_xsize = 120)
; exit button
  exit_button = widget_base(buttons, /col, /align_center)
  exitbut = widget_button(exit_button, val = ' Close ', uval = 'EXIT', $
                        /align_center, scr_xsize = 120)
  state = {error:ptr_new(error_arr), errordisplay:errordisplay}
  widget_control, errorid, set_uval = state, /no_copy
  widget_control, errorid, /realize
  xmanager, 'thm_ui_error', errorid, /no_block
  Return
End


