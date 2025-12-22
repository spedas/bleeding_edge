;+
; NAME: GET_SDT_TIMESPAN
;
; PURPOSE: To return the start and stop times for data currently
;          stored in SDT. 
; 
; KEYWORD PARAMETERS: DQD - a string naming a specific quantity for
;                     which the timespan is desired. If not set, then
;                     the first and last times (among any currently
;                     stored quantity) are returned.
;
; OUTPUTS: T1 and T2 : scalar, double precision seconds since 1970,
;          ready to be passed to GET_FA_FIELDS, GET_EN_SPEC,
;          whatever. 
;
; EXAMPLE: if get_sdt_timespan(t1,t2,dqd='Eesa Burst') then begin
;             print,'timespan is from ',t1,' to ',t2
;          endif else begin
;             print,' could not get timespan...'
;          endelse
;
; MODIFICATION HISTORY: written 22-Aug_97 by Bill Peria UCB/SSL
;
;-
function get_sdt_timespan,t1,t2,DQD = dqd

dlist = get_dqds(start_times = start_times, end_times = end_times)

if defined(dqd) then begin 
    pick = where(dlist eq dqd,npick)
    if npick eq 0 then begin
        message,dqd+' is not loaded...',/continue
        return,0
    endif
    t1 = (start_times(pick))(0)
    t2 = (end_times(pick))(0)
endif else begin
    t1 = min(start_times)
    t2 = max(end_times)
endelse

return,1
end
