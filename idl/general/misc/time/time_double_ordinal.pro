;+
; FUNCTION:
;         time_double_ordinal
;
; INPUT:
;         time must be input as a string
;         
; PURPOSE:
;         Wrapper around time_double that supports ordinal dates in the input string, e.g., YYYY-DOY instead of YYYY-MM-DD
;
;
;$LastChangedBy: egrimes $
;$LastChangedDate: 2018-03-09 13:56:38 -0800 (Fri, 09 Mar 2018) $
;$LastChangedRevision: 24861 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/misc/time/time_double_ordinal.pro $
;-

function time_double_ordinal, time, _extra=_extra
  ; kludge to check for ordinal date
  s = strsplit(time, '-', count=c)
  if c[0] eq 2 then begin ; c==2 when only one '-' in the input string
    return, time_double(time, tformat='YYYY-DOYThh:mm:ss.fff', _extra=_extra)
  endif
  return, time_double(time, _extra=_extra)
end
