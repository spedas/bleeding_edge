; Handle the widget's events.
pro login_widget_event, event

  widget_control, event.top, get_uvalue=info
  
  case event.id of
    info.cancelID: widget_control, event.top, /destroy
    info.okID: handle_ok, event
    info.passwordID: handle_password, event
  endcase

end

pro handle_ok, event
  widget_control, event.top, get_uvalue=info
  widget_control, info.usernameID, get_value=username
  (*info.ptr).username = username
  ;Note, don't need to set password since that is already handled by handle_password
  (*info.ptr).cancel=0
  widget_control, event.top, /destroy
end

pro handle_password, event

  ;Handle return in the password field as hitting OK
  if event.type eq 0 then begin ;only insertion event types have "ch"
    if event.ch eq 10 then begin 
      handle_ok, event
      return
    endif
  endif
      
  ;Handle character insertion (type=0)
  if event.type eq 0 then begin
    ; Insert the character at the proper location.
    widget_control, event.id, /use_text_select, set_value = '*'
    ; Update the current insertion point in the text widget.
    widget_control, event.id, set_text_select=event.offset + 1
    ; Store the password.
    widget_control, event.top, get_uvalue=info
    if (*info.ptr).password eq "" then (*info.ptr).password = string(event.ch) else $
       (*info.ptr).password = (*info.ptr).password + string(event.ch)
  endif
       
  ;Handle character deletion (type=2)
  if event.type eq 2 then begin
    ;Get current password length.
    widget_control, event.id, get_value=text
    text = text[0] ;returned value is a string array
    oldLength = strlen(text)
    ;Get new length. Note, deletion event may include more than one character.
    newLength = oldLength - event.length
    ;Replace text with approapriate number of *s.
    if newLength eq 0 then widget_control, event.id, set_value = ''  $
    else widget_control, event.id, set_value = replicate('*', newLength)
    ;Update value of stored password.
     widget_control, event.top, get_uvalue=info
    (*info.ptr).password = strmid((*info.ptr).password, 0, newLength)
    ;Reset the text insertion point in the text widget.
    widget_control, event.id, set_text_select=event.offset
  endif
end

;==============================================================================
; Pop up a login widget prompting the user for username and password.
; Return username and password in a 'login' structure:
;   {login, username: '', password: ''}
function login_widget, title=title, cancel=cancel, $
      group_leader=group_leader
      
  ; Error handling. Clean up.
  catch, error
  if error ne 0 then begin
    catch, /cancel
    ok = dialog_message(!Error_State.Msg)
    if destroy_groupleader then widget_control, group_leader, /destroy
    cancel = 1
    return, ""
  endif

  ; Default title for the widget
  if n_elements(title) eq 0 then title = 'MMS SITL Login'
  
  ; Make sure we have a group leader to own this modal widget
  if n_elements(group_leader) eq 0 then begin
    group_leader = widget_base(map=0)
    widget_control, group_leader, /realize
    ;indicate that we have a group_leader to destroy when we clean up
    destroy_groupleader = 1  
  endif else destroy_groupleader = 0
  
  ; Create the widget
  base = widget_base(title=title, column=1, /modal, /base_align_center, group_leader=group_leader)
  
  ; Username and password fields
  unbase = widget_base(base, row=1)
  usernameID= cw_field(unbase, title='Username: ', value=username)
  pwbase = widget_base(base, row=1)
  passwordLabel = widget_label(pwbase, value='Password: ')
  passwordID = widget_text(pwbase, /all_events, editable=0)
  
  ; Buttons
  bbase = widget_base(base, row=1)
  okID     = widget_button(bbase, value = "  OK  ")
  cancelID = widget_button(bbase, value = "Cancel")
   
  ; Center the widget
  device, get_screen_size=screenSize
  if screensize[0] gt 2000 then screenSize[0] = screenSize[0]/2 ; Dual monitors.
  xCenter = screenSize(0) / 2
  yCenter = screenSize(1) / 2
  geom = widget_info(base, /Geometry)
  xHalfSize = geom.scr_xsize / 2
  yHalfSize = geom.scr_ysize / 2
  widget_control, base, xoffset = xCenter-xHalfSize, yoffset = yCenter-yHalfSize
   
  ; Popup the widget
  widget_control, base, /realize
  
   
  ; Define storage pointer
  ptr = ptr_new({username:'', password:'', cancel:1})
  info = {ptr:ptr, usernameID:usernameID, passwordID:passwordID, cancelID:cancelID, okID:okID}
  
  widget_control, base, set_uvalue=info, /no_copy
  XManager, 'login_widget', base
  
   
  ; Create the return structure holding login credentials.
  login = {login, username: (*ptr).username, password: (*ptr).password}
  
  ; Clean up
  ptr_free, ptr
  if destroy_groupleader then widget_control, group_leader, /destroy

  return, login
end


