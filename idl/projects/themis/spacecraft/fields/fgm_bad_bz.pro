;+
;NAME:
; fgm_bad_bz
;PURPOSE:
; Returns True if the Bz output is known to be bad for the specified probe and date
;CALLING SEQUENCE:
; flag = fgm_bad_bz(probe=probe, data=date)
;
;KEYWORDS:
; probe = probe letter a, b, c, d or e
; date = a string date like '2026-01-01'
;RETURNS:
; 1 if Bz was known bad, 0 otherwise
;$LastChangedBy: jwl $
;$LastChangedDate: 2026-09-02 13:32:02 -0700 (Wed, 02 Sep 2026) $
;$LastChangedRevision: 34866 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/spacecraft/fields/fgm_bad_bz.pro $


function fgm_bad_bz,probe=probe,date=date
  pl = strlowcase(probe)
  date_dbl = time_double(date)
  if (pl eq 'a') then begin
     if (date_dbl Ge time_double('2024-09-01')) && (date_dbl lt time_double('2026-04-16')) then begin
         ; Most of this data is bad. except for some good time intervals
         if (date_dbl Ge time_double('2026-01-15')) && (date_dbl lt time_double('2026-01-25')) then begin
          ; first good subrange
          return, 0
         endif else $
         if (date_dbl Ge time_double('2026-01-27')) && (date_dbl lt time_double('2026-01-31')) then begin
          ; second good subrange
          return, 0
         endif else begin
          ; bad tha range
          return, 1
         endelse
     endif else begin
      ; not in bad tha range
      return, 0
     endelse
  endif
  if (pl eq 'e') && (date_dbl Ge time_double('2024-05-25')) then begin
    ; the bad range
    return, 1
  endif else begin
     ; not tha or the
     return, 0
  endelse
    
end