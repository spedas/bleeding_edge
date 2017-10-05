;+
;NAME:
; spd_ui_fix_performance
;
;PURPOSE:
; This fixes issue IDL-68782:
; in Linux, some drawing operations are very slow for IDL 8.3
; another solution would be win = obj_new("idlgrwindow", LINE_QUALITY=0)
; it might be useful for windows, too
;
;HISTORY:
;
;$LastChangedBy: $
;$LastChangedDate: $
;$LastChangedRevision: $
;$URL: $
;--------------------------------------------------------------------------------

Pro spd_ui_fix_performance, switch_on

  if switch_on eq 1 then begin
    setenv, "IDL_DISABLE_STROKED_LINES=1"
    statusmsg = 'STROKED_LINES performance fix applied.'
    print, statusmsg
  endif else begin
    setenv, "IDL_DISABLE_STROKED_LINES=" ;turn off fix
    statusmsg = 'STROKED_LINES performance fix removed.'
    print, statusmsg
  endelse
  
end