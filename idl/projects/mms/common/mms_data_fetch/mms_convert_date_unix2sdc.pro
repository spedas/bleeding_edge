; Routine to convert unix time to date string that can be used in an SDC query.
; 

function mms_convert_date_unix2sdc, unix_time, hour=hour

  jul = unix_time/double(86400) + julday(1, 1, 1970, 0, 0, 0)

  caldat, jul, mo, dy, yr, hr

  if mo lt 10 then begin
    mostr = '0'+string(mo, format = '(I1)')
  endif else begin
    mostr = string(mo, format = '(I2)')
  endelse
  if dy lt 10 then begin
    dystr = '0'+string(dy, format = '(I1)')
  endif else begin
    dystr = string(dy, format = '(I2)')
  endelse
  if hr lt 10 then begin
    hrstr = '0'+string(hr, format = '(I1)')
  endif else begin
    hrstr = string(hr, format = '(I2)')
  endelse

  yrstr = string(yr, format = '(I4)')
  
  if keyword_set(hour) then begin
    date_string = yrstr + '-' + mostr + '-' + dystr + '-' + hrstr
  endif else begin
    date_string = yrstr + '-' + mostr + '-' + dystr
  endelse
  
  return, date_string
  
end