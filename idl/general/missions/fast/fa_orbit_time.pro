;+
; converts time to FAST orbit number
; Only accurate to about one orbit.
; D Larson
;-
function fa_orbit_time,time


times='1996-08-30/22:01 1998-01-21/02:47 1999-06-07/17:21 2000-10-15/16:35 2002-01-27/18:26 2003-06-30/11:09 2004-11-10/22:21 2006-04-20/11:07 2007-09-25/22:00 2009-04-30/05:32'
orbits=[      103.01045 ,      5599.8664,       11054.278,       16467.985,       21636.072,      27401.815,        32986.090,       38879.855,       44761.655,       51312.285]
times=time_double(strsplit(times,' ',/extract))
orbn = interp(orbits,times,time_double(time))
return,orbn
end
