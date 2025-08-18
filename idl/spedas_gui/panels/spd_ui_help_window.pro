;+
;NAME:
;spd_ui_help_window
;
;PURPOSE:
; A widget to display the file 'spd_gui.txt' help
;
;$LastChangedBy: jwl $
;$LastChangedDate: 2022-03-04 11:48:01 -0800 (Fri, 04 Mar 2022) $
;$LastChangedRevision: 30648 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/spedas_gui/panels/spd_ui_help_window.pro $
;
;-
Pro spd_ui_help_window_event, event

  widget_control, event.top, get_uval = state
  getresourcepath,rpath
  
  
  ;catch block for future additions
  err_xxx = 0
  Catch, err_xxx
  IF (err_xxx NE 0) THEN BEGIN
    Catch, /Cancel
    Help, /Last_Message, Output = err_msg
    
    spd_ui_sbar_hwin_update, state, err_msg, /error, err_msgbox_title='Error in Help Window'
    
    Widget_Control, event.TOP, Set_UValue=state, /No_Copy
    widget_control, event.top,/destroy
    RETURN
  ENDIF
  
  ;  what happened?

  widget_control, event.id, get_uval = uval
  Case uval Of
    'EXIT': begin
      widget_control, event.top, /destroy
    end
    'showwiki' : begin
      spd_ui_open_url, 'http://spedas.org/wiki/'
    end
    'showhelp' : begin
      spd_ui_open_url, 'http://themis.ssl.berkeley.edu/socware/latest.html'
    end
  Endcase
  Return
End

Pro spd_ui_help_window, historyWin, gui_id

  ;catch block for future additions
  err=0
  catch, err
  if err ne 0 then begin
    catch,/cancel
    help,/last_message, output=err_msg
    if obj_valid(historyWin) then $
      for i=0,n_elements(err_msg)-1 do historyWin->update,err_msg[i]
    ok = error_message('Unknown error, the help window will now close',/noname, $
      /center, title='Error in Help Window')
    widget_control,helpid,/destroy
    spd_gui_error, gui_id, historywin
    return
  endif
  
  
  
  help_arr = 'No Help File'
  
  getresourcepath,rpath
  fname = rpath+'spd_users_guide_link.txt'
  if file_test(fname) then begin
    help_arr = strarr(file_lines(fname))
    openr, unit, fname, /get_lun
    readf, unit, help_arr
    free_lun, unit
  endif
  
  ;here is the display widget,not editable
  helpid = widget_base(/col, title = 'Help Window',Group_Leader = gui_id, $
    /Modal, /Floating)
  helpdisplay = widget_text(helpid, uval = 'HELP_DISPLAY', val = help_arr, $
    /scroll, frame = 5)
  ;a widget for buttons
  buttons = widget_base(helpid, /row, /align_center)
  exit_button = widget_base(buttons, /row, /align_center)
  
  onButton = widget_button(exit_button, value = ' Open SPEDAS Wiki ', uvalue= 'showwiki', /align_center)
  onlineButton = widget_button(exit_button, value = ' Open Online Documentation ', uvalue= 'showhelp', /align_center)
  exitbut = widget_button(exit_button, val = ' Close ', uval = 'EXIT', /align_center)
  state = {help:help_arr, historyWin:historyWin, gui_id:gui_id}
  
  CenterTLB, helpid
  widget_control, helpid, set_uval = state, /no_copy
  widget_control, helpid, /realize
  
  ;keep windows in X11 from snaping back to
  ;center during tree widget events
  if !d.NAME eq 'X' then begin
    widget_control, helpid, xoffset=0, yoffset=0
  endif
  
  xmanager, 'spd_ui_help_window', helpid, /no_block
  Return
End


