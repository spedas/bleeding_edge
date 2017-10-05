;+
;NAME:
; spd_ui_open_url
;
;PURPOSE:
; Open an url in the default web browser.
; If a browser executable is specified in the Configuration Settings, then prefer that.
; On UNIX platforms, the script tries to find an appropriate browser.
;
;
;CALLING SEQUENCE:
; spd_ui_open_url, url
;
;INPUT:
;    url : string, the full url, for example http://spedas.org
;
;$LastChangedBy:        $
;$LastChangedDate:      $
;$LastChangedRevision:    $
;$URL:    $
;-

function get_linux_browser
  ; for linux only:
  ; check browsers till we find one that works

  spawn, 'which firefox|grep ''not found''', browserstr
  if browserstr eq '' then return, "firefox"

  spawn, 'which google-chrome|grep ''not found''', browserstr
  if browserstr eq '' then return, "google-chrome"

  spawn, 'which opera|grep ''not found''', browserstr
  if browserstr eq '' then return, "opera"

  spawn, 'which epiphany|grep ''not found''', browserstr
  if browserstr eq '' then return, "epiphany"

  spawn, 'which konqueror|grep ''not found''', browserstr
  if browserstr eq '' then return, "konqueror"

  spawn, 'which xdg-open|grep ''not found''', browserstr
  if browserstr eq '' then return, "xdg-open"

  return, ""
end


pro spd_ui_open_url, url
  ; Open a URL using the browser

  ; use the browser executable specified by the user, if it exists
  defsysv,'!spedas',exists=exists
  if ~exists then spedas_init
  browser_exe = !spedas.browser_exe
  if browser_exe ne '' then begin
    if FILE_SEARCH(browser_exe) then begin
      if !version.os_family eq 'Windows' then begin    ; Windows
        spawn,  '"' + browser_exe + '" ' + url, /hide, /nowait,  EXIT_STATUS=exit_status
      endif else begin
        spawn,  '"' + browser_exe + '" ' + url + ' &', EXIT_STATUS=exit_status
      endelse
      if exit_status ne 0 then begin
        dprint, dlevel=2, exit_status
      endif else begin
        dprint, dlevel=4, 'Browser started.'
        return
      endelse
    endif
  endif

  if !version.os_family eq 'Windows' then begin    ; Windows
    spawn, 'start ' + url, /hide, /nowait
  endif else begin
    if !version.os_name eq 'Mac OS X' then begin    ; MacOS
      spawn, 'open ' + url + ' &'
    endif else begin  ; unix, linux
      browser_name = get_linux_browser()
      if browser_name ne '' then begin
        spawn, browser_name + ' ''' + url + ''' &'
      endif else begin
        dprint, dlevel=2, 'Web browser was not found. Cannot open ', url
      endelse
    endelse
  endelse

end
