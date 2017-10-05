;+
;NAME:
;spd_gui_error
;PURPOSE:
; A widget to display, edit and save the file 'spd_gui_error.txt' error
;
;$LastChangedBy: nikos $
;$LastChangedDate: 2015-11-12 12:46:06 -0800 (Thu, 12 Nov 2015) $
;$LastChangedRevision: 19350 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/spedas_gui/panels/spd_gui_error.pro $
;
;-
Pro spd_gui_error_event, event
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
      ofile = 'spedas_help_request_'+ttt+'.txt'
      osf = strupcase(!version.os_family)
      If(osf Eq 'WINDOWS') Then ofile0 = file_expand_path('')+'\'+ofile $
      Else ofile0 = file_expand_path('')+'/'+ofile
;      ofile = dialog_pickfile(title = 'SPEDAS Help Request Filename', $
;                              filter = '*.txt', file = ofile0)
      ofile = spd_ui_dialog_pickfile_save_wrapper(title = 'SPEDAS Help Request Filename', $
                              filter = '*.txt', file = ofile0,/write,/overwrite_prompt)
      If(is_string(ofile)) Then Begin
        openw, unit, ofile, /get_lun
        For j = 0, nerr-1 Do printf, unit, error_arr[j]
        free_lun, unit
        If(obj_valid(!spedas.progobj)) Then Begin
          !spedas.progobj -> update, 0.0, $
            text = 'SPEDAS Help Request Saved as File: '+ofile
        Endif 
      Endif Else Begin
        If(obj_valid(!spedas.progobj)) Then $
          !spedas.progobj -> update, 0.0, text = 'Operation Cancelled'
      Endelse
    End
  Endcase
  Return
End
Pro spd_gui_error, gui_id,historywin

  error_arr = 'No Error File'
;Find the directory with the file
  getresourcepath,rpath
  f = file_search(rpath +'spedas_gui_error_message.txt')
  If(is_string(f)) Then Begin
    lines = file_lines(f)
    error_arr = strarr(lines)
    Openr, unit, f, /get_lun
    readf, unit, error_arr
    Free_lun, unit
  Endif


;Replace "XXXXXXXXXX" line with the path/filename to the running history file:
;*****************************************************************************
;
w=where(error_arr eq 'XXXXXXXXXX', errcount)
if errcount ne 0 then begin
    if ~(~size(historywin,/type)) && obj_valid(historywin) then begin
      historywin->GetProperty,running_history_dir=running_history_dir
      If(!version.os_family Eq 'Windows') Then Begin
        error_arr[w] = running_history_dir+'\spd_gui_running_history.txt'
      Endif Else error_arr[w] = running_history_dir+'/spd_gui_running_history.txt'
    endif
endif
xsize=80

sentinel_string=strjoin(replicate(' ',xsize+10)) ;used to stop an x-11 warning that occurs when:
;when text widgets are realized
;on linux
;in modal sub-widgets
;with initial text size is smaller than the horizontal width of the text area in characters
;the sentinel string guarantees that the initial text is wider than the horizontal width of the text area in characters
;it must be at the beginning of the text for the warning to be avoided 
error_arr = [sentinel_string,error_arr]

;here is the display widget, editable
  errorid = widget_base(/col, title = 'Help Request Form', $
                        /modal, Group_Leader=gui_id)
  errordisplay = widget_text(errorid, uval = 'ERROR_DISPLAY', $
                             val = error_arr, /all_events, $
                             /editable, xsize = xsize, ysize = 40, /scroll, $
                             frame = 5)
;a widget for buttons
  buttons = widget_base(errorid, /row, /align_center, frame = 5)

; save button
  save_button = widget_base(buttons, /col, /align_center)
  savebut = widget_button(save_button, val = ' Save ', uval = 'SAVE', $
                        /align_center, scr_xsize = 120)
; exit button
  exit_button = widget_base(buttons, /col, /align_center)
  exitbut = widget_button(exit_button, val = ' Close ', uval = 'EXIT', $
                        /align_center, scr_xsize = 120)
  state = {error:ptr_new(error_arr), errordisplay:errordisplay}
  centerTLB, errorid
  widget_control, errorid, set_uval = state, /no_copy
  widget_control, errorid, /realize
  xmanager, 'spd_gui_error', errorid, /no_block
  Return
End


