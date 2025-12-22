;+
; FUNCTION:  get_orbfile_epoch
;
; PURPOSE:   Searches an orbit file for the epoch time of an orbit.
;            Uses a relatively fast algorithm.
;
; ARGUMENTS: ORBIT       The orbit to search for in the orbit file.
;
; KEYWORDS:  ORBIT_FILE  The orbit file to search in. This defaults to
;                        the definitive orbit file in
;                        fa_almanac_dir()/orbit/.  If the requested
;                        orbit is beyond this file, it will try the
;                        predicted file.  A -1 will be returned if the
;                        orbit is not found in either file.
;
; CREATED:   1998/01/30 By J. Rauchleiba
;-
function get_orbfile_epoch, orbit, $
            orbit_file=orbit_file

; Test and set the orbit file

if keyword_set(orbit_file) then begin
    last_epoch =  find_last_epoch(orbit_file, ORBIT=last_orbit)
    if orbit GT last_orbit then message, 'Orbit is beyond orbit file.'
endif else begin
    def_orbit_file = findfile(fa_almanac_dir() + '/orbit/definitive')
    if def_orbit_file(0) EQ '' $
      then message, fa_almanac_dir() + '/orbit/definitive NOT FOUND'
    last_epoch = find_last_epoch(def_orbit_file(0), ORBIT=last_orbit)
    if orbit GT last_orbit then begin
        print, 'Switching to predicted orbit file.'
        pre_orbit_file = findfile(fa_almanac_dir() + '/orbit/predicted')
        if pre_orbit_file(0) EQ '' $
          then message, fa_almanac_dir() + '/orbit/predicted NOT FOUND'
        last_epoch = find_last_epoch(pre_orbit_file(0), ORBIT=last_orbit)
        if orbit GT last_orbit then message, 'Orbit is beyond orbit file.'
        orbit_file = pre_orbit_file(0)
    endif else begin
        orbit_file = def_orbit_file(0)
    endelse
endelse

; In case we got lucky

if last_orbit EQ orbit then return, last_epoch

; Open the orbit file an initialize values

openr, unit, orbit_file, /get_lun, /append
point_lun, -unit, eof_pos
ptr_pos = eof_pos
bytes_per_orb = long(547 < eof_pos)
bytebuff = bytarr(1100)
found_orbit = last_orbit + 1
orbit_string = strtrim(orbit,2)
tries = 0

; Loop until desired orbit found

while found_orbit NE orbit do begin
    shift_orbits = orbit - found_orbit
    shift_bytes = bytes_per_orb*(shift_orbits - 1L)
    point_lun, unit, ptr_pos + shift_bytes
    ptr_pos = ptr_pos + shift_bytes
    readu, unit, bytebuff
    strnbuff = string(bytebuff)
    correction = strpos(strnbuff, 'ORBIT: '+orbit_string+'	')
    if correction EQ -1 then correction = strpos(strnbuff, 'ORBIT:')
    point_lun, unit, ptr_pos + correction
    ptr_pos = ptr_pos + correction
    epochline = ''
    readf, unit, format='(A)', epochline
    split_line = str_sep(epochline, '	')
    found_orbit = long((str_sep(split_line(0), ' '))(1))
    tries = tries + 1
    if tries GE 20 then message, orbit_string+' Not Found in '+orbit_file
endwhile
free_lun, unit

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

