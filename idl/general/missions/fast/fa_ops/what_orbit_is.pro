;       @(#)what_orbit_is.pro	1.8 01/13/98

function what_orbit_is,timec
;+
; NAME: WHAT_ORBIT_IS
;
; PURPOSE: To quickly determine the orbit number at a particular time. 
;
; CALLING SEQUENCE: ORBIT = what_orbit_is(TIME)
; 
; INPUTS: TIME - a string (YYYY-MM-DD/HH:MM) or a double precision
;         number of seconds since 1970. If TIME is not defined, then
;         the orbit number of the current orbit is given (provided
;         your computers clock is set right. Check if
;         time_to_str(systime(1)) gives you the current UT. 
;        
;
; OUTPUTS: ORBIT - the orbit number, as defined by ORBGEN. 
;
; EXAMPLE: my_orbit = what_orbit_is('1996-08-21/12:00') (Note
;                   that the correct answer is 1!)
;
; MODIFICATION HISTORY: Written 4-Mar-97 by Bill Peria UCB/SSL
;       Re-written to use fast_archive database by Ken Bromund UCB/SSL
;
;-

if not defined(timec) then timec = systime(1)

time = time_double(timec)

if data_type(time) ne 5 then return, 0

t1 = min(time,/nan,max=t2)

con = sybcon()
ret = con->send('select orbit from orbits where start <= ' + $
                time_string(t1, /sql) + ' and finish > ' + $
                time_string(t1, /sql))
ret = con->fetch(min_orb)

ret = con->send('select orbit from orbits where start <= ' + $
                time_string(t2, /sql) + ' and finish > ' + $
                time_string(t2, /sql))
ret = con->fetch(max_orb)

sybclose, con

if min_orb.orbit eq max_orb.orbit then begin
    return,  fix(min_orb.orbit)
endif else begin
    return, fix([min_orb.orbit, max_orb.orbit])
endelse

end

