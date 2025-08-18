; Get the username and password for authentication.
; If the 'group_leader' is set, prompt the user via a popup.
; Otherwise prompt the user at the command line.
; This will look for a saved login in the user's home directory.
; The save option is designed to support test automation, not routine use.
function mms_sitl_login, group_leader=group_leader

  ;Look for saved login.
  save_file = getenv('HOME') + '/.mms_sitl_login.sav'
  if file_test(save_file) then begin 
    restore, save_file
    return, login
  endif

  ;Saved login not found so prompt the user.
  if n_elements(group_leader) eq 1 then begin
    ;popup login widget
    login = login_widget(group_leader=group_leader)
  endif else begin
    ;prompt the user at the IDL command line
    username = ''
    password = ''
    read, username, prompt='username: '
    
    if !version.release ge 8.0 then begin
        password = read_password(prompt='password: ') ;don't echo password
    endif else read, password, prompt='password: ' ; no choice but to echo password for older versions of IDL

    login = {login, username: username, password: password}
  endelse

  return, login
end
