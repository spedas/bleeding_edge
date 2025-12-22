;+
; NAME: GET_DQDS
;
; PURPOSE: returns the list of DQD strings currently loaded in SDT
;
; CALLING SEQUENCE: list = get_dqds()
; 
; INPUTS: none
;
; KEYWORDS: START_TIMES and END_TIMES. These can be used to return an
;           array of start and end times to the caller, in double
;           precision seconds since 1970.
;
; OUTPUTS: a strarr of DQD names, or the null string if SDT is not running.
;
; SIDE EFFECTS: calls SHOW_DQIS, which has a call_external in it. 
;
; MODIFICATION HISTORY: wriiten 22-Aug-97 by Bill Peria UCB/SSL
;
;-
function get_dqds,START_TIMES = start_times, end_times = end_times

tstr_len = 23                   ; SHOW_DQIS formats time
                                ; strings with this many chars. 


result = ' '
show_dqis, result = result

dl = where(strpos(result,'Stat') gt 0,ndl)-1L

if ndl eq 0 then begin
    message,'No data are loaded in SDT...',/continue
    return,''
endif

dlist = strarr(ndl)
start_times = dblarr(ndl)
end_times = dblarr(ndl)
len = strlen(result(dl))
for i=0,ndl-1l do begin
    line = result(dl(i))
    last_colon = rstrpos(line,':')
    next_space = strpos(line,' ',last_colon)
    dqd_start = next_space+1
    dlist(i) = strmid(line,dqd_start,len(i)-dqd_start)
    
    slash1 = strpos(line,'/',0)
    slash2 = strpos(line,'/',slash1+1)
    start_times(i) = datetimesec(strmid(line,slash1-10,slash1+13))
    end_times(i)   = datetimesec(strmid(line,slash2-10,slash2+13))
endfor

dlist = strtrim(dlist,2)

return,dlist
end
