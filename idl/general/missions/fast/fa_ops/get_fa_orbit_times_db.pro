;+
;FUNCTION: get_fa_orbit_times_db(orbit)
;NAME:
;  get_fa_orbit_times_db
;PURPOSE:
;  Obtains orbit start, stop, north and south pole crossing times
;  from the fast_archive database given an orbit number.
;
;INPUT:  input(s) can be scalers or arrays of any dimension of type:
;  integer        orbit number.
;
;OUTPUT:
;  structure: {orbit_times, start:limits.start, finish:limits.finish, $
;              north:north.time, south:south.time}
;
;SEE ALSO:
;  what_orbit_is
;
;CREATED BY:	Ken Bromund  Dec 1997
;FILE:  get_fa_orbit_times_db.pro
;VERSION:  1.2
;LAST MODIFICATION:  98/01/06
;-

FUNCTION get_fa_orbit_times_db, orbit

con = obj_new('sybcon')
ret = con->send('select start, finish from orbits where orbit = ' + string(orbit))
ret = con->fetch(limits)

ret = con->send('select time from ephemeris_events where time > ' + $
                time_string(limits.start, /sql) + ' and time < ' + $
                time_string(limits.finish, /sql) + $
                ' and max_ilat = 1 order by time')
ret = con->fetch(north)
ret = con->fetch(south)

obj_destroy, con
return, {orbit_times, start:limits.start, finish:limits.finish, $
         north:north.time, south:south.time}

end
