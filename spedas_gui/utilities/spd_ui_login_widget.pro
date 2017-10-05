;+
; FUNCTION:
;         spd_ui_login_widget
;         
; PURPOSE:
;         Prompt the user for their login information
; 
; KEYWORDS:
;         title: title of the login window
;         group_leader: widget ID of the leader widget
;         note: add a note to the bottom of the widget
; 
; OUTPUT:
;         Returns a structure containing the username, password, 
;         and a tag 'save' that specifies whether the user wants 
;         to save the login information
; 
; NOTES:
;         Written by Doug Lindholm at LASP, forked for SPEDAS on 8/20/2015. 
;         Minor modifications by Aaron Flores @ IGPP
;         3/15/2016: updated to accept 'note' keyword - allows for 
;           adding a note to the bottom of the widget
;         
;$LastChangedBy: egrimes $
;$LastChangedDate: 2017-02-15 15:48:51 -0800 (Wed, 15 Feb 2017) $
;$LastChangedRevision: 22793 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/spedas_gui/utilities/spd_ui_login_widget.pro $
;-

; Handle the widget's events.
pro spd_login_widget_event, event

  widget_control, event.top, get_uvalue=info
  
  case event.id of
    info.cancelID: widget_control, event.top, /destroy
    info.okID: spd_handle_ok, event
    info.passwordID: spd_handle_password, event
    info.saveID: (*info.ptr).save = event.select
    else:
  endcase

end

pro spd_handle_ok, event
  widget_control, event.top, get_uvalue=info
  widget_control, info.usernameID, get_value=username
  (*info.ptr).username = username
  ;Note, don't need to set password since that is already handled by handle_password
  (*info.ptr).cancel=0
  widget_control, event.top, /destroy
end

; **NOTE: This routine will not handle ctrl+v & ctrl+x (paste/cut text)
;         on windows when a non-ending subset of the current text is selected
;         due to multiple delete events that are generated from those operations.
pro spd_handle_password, event

  ;Handle return in the password field as hitting OK
  if event.type eq 0 then begin ;only insertion event types have "ch"
    if event.ch eq 10 then begin 
      spd_handle_ok, event
      return
    endif
    ;do not insert non-printing characters (allows accelerators)
    if event.ch lt 32 then return
  endif
      
  ;Handle character insertion (type=0|1)
  if event.type eq 0 or event.type eq 1 then begin
    ; get input (single insert uses byte, multi uses string)
    text = event.type ? event.str : string(event.ch)
    ; form new password
    widget_control, event.top, get_uvalue=info
    new = strmid((*info.ptr).password,0,event.offset-strlen(text)) + text + strmid((*info.ptr).password,event.offset-strlen(text)) 
    ; update displayed text & current insertion point in the text widget
    widget_control, event.id, set_value = replicate('*',strlen(new)), set_text_select=event.offset
    ; Store the password.
    (*info.ptr).password = new
  endif

  ;Handle character deletion (type=2)
  if event.type eq 2 then begin
    widget_control, event.top, get_uvalue=info
    new = strmid((*info.ptr).password,0,event.offset) + strmid((*info.ptr).password,event.offset+event.length)
    ;update displayed text & current insertion point
    widget_control, event.id, set_value = (new eq '' ? '' : replicate('*', strlen(new))), $
                              set_text_select=event.offset
    ;Update value of stored password.
    (*info.ptr).password = new
  endif
end

function spd_ui_login_widget, title=title, cancel=cancel, $
      group_leader=group_leader, note=note
      
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
  if n_elements(title) eq 0 then title = 'MMS Login'
  
  ; Make sure we have a group leader to own this modal widget
  if n_elements(group_leader) eq 0 then begin
    group_leader = widget_base(map=0)
    widget_control, group_leader, /realize
    ;indicate that we have a group_leader to destroy when we clean up
    destroy_groupleader = 1  
  endif else destroy_groupleader = 0
  
  ; Create the widget
  base = widget_base(title=title, column=1, /modal, /base_align_center, group_leader=group_leader, /tab)
  
  ; Username and password fields
  unbase = widget_base(base, row=1)
  usernameID= cw_field(unbase, title='Username: ', value=username)
  pwbase = widget_base(base, row=1)
  passwordLabel = widget_label(pwbase, value='Password: ')
  passwordID = widget_text(pwbase, /all_events, editable=1)
  
  ; Save to file option
  sbase = widget_base(base, row=1, /nonexclusive)
  saveID = widget_button(sbase, value='Save credentials', $
             tooltip='Store username and password in IDL .sav file for automatic login the next time')
  
  ; Buttons
  bbase = widget_base(base, row=1)
  okID     = widget_button(bbase, value = "  OK  ")
  cancelID = widget_button(bbase, value = "Cancel")
  
  if keyword_set(note) then begin
      notebase = widget_base(base, row=1)
      noteID = widget_label(notebase, value=note)
  endif 
  
  ; Center the widget
  device, get_screen_size=screenSize
  if screensize[0] gt 2000 then screenSize[0] = screenSize[0]/2 ; Dual monitors.
  xCenter = screenSize[0] / 2
  yCenter = screenSize[1] / 2
  geom = widget_info(base, /Geometry)
  xHalfSize = geom.scr_xsize / 2
  yHalfSize = geom.scr_ysize / 2
  widget_control, base, xoffset = xCenter-xHalfSize, yoffset = yCenter-yHalfSize
   
  ; Popup the widget
  widget_control, base, /realize
  
   
  ; Define storage pointer
  ptr = ptr_new({username:'', password:'', cancel:1, save:0})
  info = {ptr:ptr, usernameID:usernameID, passwordID:passwordID, saveID:saveID, cancelID:cancelID, okID:okID}
  
  widget_control, base, set_uvalue=info, /no_copy
  widget_control, base, default_button = okID
  XManager, 'spd_login_widget', base
  
   
  ; Create the return structure holding login credentials.
  login = {login, username: (*ptr).username, password: (*ptr).password, save:(*ptr).save}
  
  ; Clean up
  ptr_free, ptr
  if destroy_groupleader then widget_control, group_leader, /destroy

  return, login
end


