;+
; PROCEDURE
;
; date_doy_sec.pro
;
; PURPOSE
;
; Given a standard format date/time (string or double float), returns
; the year, day of year, and seconds into day.
;
; INPUTS
;
; time     String or double float.
;
; OUTPUTS
;
; year     Four-digit year.
; doy      Day of year.
; sec      Seconds into day.
;
;-
pro date_doy_sec, time, year, doy, sec

if data_type(time) EQ 7 then tmp_date=str_to_time(time) else tmp_date=time
date = time_to_str(tmp_date, /fmt, /msec)

; Parse the date string

pieces = str_sep(strtrim(date, 2), ' ')

; day of month

dom = fix(pieces(0))

; year

yr = fix( (str_sep(pieces(2), '_')) (0) )
if yr GE 70 then year=yr+1900 else year=yr+2000

; month and number of days in

mon_strg = strtrim(strupcase(pieces(1)), 2)
mons=['JAN','FEB','MAR','APR','MAY','JUN','JUL','AUG','SEP','OCT','NOV','DEC']
dimon = [31,28,31,30,31,30,31,31,30,31,30,31]
if ((year MOD 4) EQ 0) AND (((year MOD 100) NE 0) OR ((year MOD 400) EQ 0)) $
  then dimon(1)=29
mon_ind = (where(mons EQ mon_strg))(0)

; Calculate day of year

if mon_ind EQ 0 then doy=dom else begin
    sum_ind = indgen(mon_ind)
    doy = fix(total(dimon(sum_ind)) + dom)
endelse

; Calculate seconds into day

hh_mm_ss = double( str_sep( (str_sep(pieces(2), '_'))(1), ':' ) )
hh = hh_mm_ss(0)
mm = hh_mm_ss(1)
ss = hh_mm_ss(2)

sec = hh*3600.d + mm*60.d + ss

return
end
