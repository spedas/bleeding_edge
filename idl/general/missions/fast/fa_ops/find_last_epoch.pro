;+
; FUNCTION:    find_last_epoch
;
; PURPOSE:     Gets the last orbit element epoch time entry of an orbit
;              file.  Returns time in double float.  (All arguments
;              and keywords are optional.)
;
; ARGUMENTS:   FILE         The orbit file to look in.  Defaults to:
;                           fa_almanac_dir()/orbit/predicted
;                           unless DEFINITIVE keyword set.
;              ORBIT        Named variable to return last orbit in file.
;              YEAR         Named variable to return year.
;              DOY          Named variable to return day of year.
;              TIME         Named variable to return time of day.
;
; KEYWORDS:    DEFINITIVE   If no FILE argument supplied, use the
;                           definitive orbit file:
;                           fa_almanac_dir()/orbit/definitive
;
;         
;-
function find_last_epoch, file, $
             ORBIT=orbit, $
             YEAR=year, $
             DOY=doy, $
             TIME=time, $
             DEFINITIVE=def

if NOT keyword_set(file) then begin
    if keyword_set(def) then file=fa_almanac_dir() + '/orbit/definitive' $
    else file=fa_almanac_dir() + '/orbit/predicted'
endif
if (findfile(file))(0) EQ '' then message, file + ' Not Found'

openr, unit, file, /get_lun, /append
point_lun, -unit, eof_pos
backspace = 554 < eof_pos
point_lun, unit, eof_pos - backspace

bytebuff = bytarr(554)
readu, unit, bytebuff
strnbuff = string(bytebuff)

correction =  rstrpos(strnbuff, 'ORBIT:')
if correction EQ -1 then message, 'ORBIT line not found near end of orbit file'
point_lun, unit, (eof_pos - backspace) + correction
epoch = ''
readf, unit, format='(A)', epoch
free_lun, unit
split_line = str_sep(epoch, '	')
if n_elements(split_line) NE 2 then message, 'Error parsing epoch line of orbit file'
orbit = long((str_sep(split_line(0), ' '))(1))
split_ep = str_sep(split_line(1), ' ')
year = fix(split_ep(1))
doy = fix(split_ep(2))
time = split_ep(3)

hh_mm_ss = str_sep(time, ':')
hour = fix(hh_mm_ss(0))
min = fix(hh_mm_ss(1))
sec_msc = str_sep(hh_mm_ss(2), '.')
sec = fix(sec_msc(0))
msc = float(double(sec_msc(1))/double(10^(strlen(sec_msc(1))-3)))

sec_date_time = datetimesec_doy(fix(strmid(strtrim(year,2),2,2)), doy, hour, min, sec, msc)

return, sec_date_time
end
