;+
;FUNCTION: get_fa_orbit_geomag(orbit)
;NAME:
;  get_fa_orbit_geomag
;PURPOSE:
;  Gets geomag data kp, ap, and dsp for given orbit.  Data are
;  returned for incoming and outgoing north and south.
;
;
;INPUT:  input(s) can be scalers or arrays of any dimension of type:
;  integer        orbit number.
;
;OUTPUT:
;  structure: {orbit_geomag, inNorth:{geomag}, outNorth:{geomag}, 
;              inSouth:{geomag}, outSouth:{geomag}}
;
;SEE ALSO:
;  what_orbit_is, get_fa_orbit_times_db, geomag
;
;CREATED BY:	Ken Bromund  Dec 1997
;FILE:  get_fa_orbit_geomag.pro
;VERSION:  1.2
;LAST MODIFICATION:  98/01/06
;-

FUNCTION get_fa_orbit_geomag, orbit
times = get_fa_orbit_times_db(orbit)
twentyMin = 20.*60.


return, {orbit_geomag, inNorth:geomag(times.north-twentyMin, times.north), $
         outNorth:geomag(times.north, times.north+twentyMin), $
         inSouth:geomag(times.south-twentyMin, times.south), $
         outSouth:geomag(times.south, times.south+twentyMin)}
end

