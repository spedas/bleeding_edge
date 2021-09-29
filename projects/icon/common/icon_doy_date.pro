;+
;NAME:
;   icon_doy_date
;
;PURPOSE:
;   Finds DOY from month and day
;   Finds month and day from  DOY
;
;KEYWORDS:
;
;HISTORY:
;$LastChangedBy: nikos $
;$LastChangedDate: 2018-05-10 10:41:33 -0700 (Thu, 10 May 2018) $
;$LastChangedRevision: 25192 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/icon/common/icon_doy_date.pro $
;
;--------------------------------------------------------------------------------

pro icon_doy_date, year, month=month, day=day, doy=doy

  days_per_month = [31,28,31,30,31,30,31,31,30,31,30,31]
  if ((((year mod 100) ne 0) and ((year mod 4) eq 0)) $
    or ((year mod 400) eq 0))  then begin
    days_per_month[1] = 29 ;leap year
  endif else days_per_month[1] = 28

  if keyword_set(doy) && doy gt 0 && doy lt 367 then begin ;find month, day

    ndoy = doy
    for month = 1,12 do begin
      if ndoy le days_per_month[month-1] then begin
        day = ndoy
        break
      endif
      ndoy = ndoy - days_per_month[month-1]
    endfor

  endif else  begin ;find doy
    doy = -1
    if keyword_set(month) && keyword_set(day) && month gt 0 && month lt 13 && day gt 0 && day lt 33 then begin
      doy=0
      for i=0,month-2 do begin
        doy = doy + days_per_month[i]
      endfor
      doy = doy + day
    endif

  endelse

end