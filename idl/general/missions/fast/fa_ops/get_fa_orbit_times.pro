;	@(#)get_fa_orbit_times.pro	1.6	
;+
; NAME: GET_FA_ORBIT_TIMES
;
; PURPOSE: To obtain the orbit start and stop times, in double
;          precision seconds since 1970, given an orbit number. 
;
; CALLING SEQUENCE: if get_fa_orbit_times(1701,t0,t1) then ...
; 
; INPUTS: the orbit number.
;
; OUTPUTS: The return value is 1 for success, 0 for failure. The times
;          are returned in T0 and T1. 
;
; SIDE EFFECTS: A process is spawned, and the orbit almanac file is
;               awked. The orbit number and times are stored, unless
;               NO_STORE is set, or unless the desired times are
;               already stored. 
;
;
; MODIFICATION HISTORY: Originally written by J.Rauchleiba, for
;                       PLOT_FA_CROSSING, although he'll deny it. 
;                       Stolen and modularized by Bill Peria,
;                       27-Jan-97. 
;
;                       Hard-coded path removed 11-March-97 BP
;                       TPLOT storage added     15-April-97 BP
;                       Use ORBITTIME spawn    22-July-97  BP
;-
function get_fa_orbit_times,orbit,tstart,tstop,NO_STORE = no_store

status = 0

catch,err_stat
if (err_stat ne 0) then begin
    message,!err_string,/continue
    catch,/cancel
    status = 0
    return,status
endif

if find_handle('orbit_times') then begin
    get_data,'orbit_times',data=ot
    if ot.num eq orbit then begin
        tstart = ot.tstart
        tstop = ot.tstop
        status = 1
        return,status
    endif
endif

orbit_str = strcompress(string(orbit),/remove_all)
spawn,'orbittime ' + orbit_str, times, /sh
times = substr(times,'/','-',2)
if strmid(times(0),0,4) ne '0000' then begin
    tstart = str_to_time(times(0))
    tstop = str_to_time(times(1))
    status = 1
    return,status
endif

almanac = fa_almanac_dir()
if almanac eq '-error-' then begin
    almanac = '/disks/fast/almanac'
    message, 'Almanac directory not found...guessing '+almanac,/continue
endif
orbit_file = almanac+'/orbit/predicted'

orbit = long(orbit)

for i=0,1 do begin
    com1="awk '/ORBIT: '"""
    com2='"''\t/ {printf("%2s\n%s\n%s\n",$4,$5,$6)}'' '
    orbstring=strtrim(string(orbit+i),2)
    command=com1 + orbstring + com2
    spawn, command + orbit_file, epoch

    if NOT keyword_set(epoch) then print, $
      'Definitive data not recent enough. Using predicted orbit file.'
    orbit_file = almanac+'/orbit/predicted'
    spawn, command + orbit_file, epoch

    if NOT keyword_set(epoch) then message, 'Orbit data not found.'

    yr=strmid(epoch(0),2,2)
    doy=epoch(1)
    ep_hms=str_sep(epoch(2),':')

    tmin=datesec_doy(yr,doy) + ep_hms(0)*3600. + ep_hms(1)*60. + $
      ep_hms(1)
    if i eq 0 then tstart = tmin else tstop = tmin
endfor

if not keyword_set(no_store) then begin
    store_data,'orbit_times',data={num:orbit,tstart:tstart,tstop:tstop}
endif

status = 1
return,status
end
