;+
; !!!WARNING!!!
;
;   This procedure is still in its testing phase and should not be
;   used yet.
;
; PROCECURE
;
;   raven_sun_pos
;
; PURPOSE
;
;   Calculates the position of the Sun using algorithm of Walraven
;
; INPUT
; 
;   time
;
; OUTPUT
;
;   slong
;      Longitude of the Sun (deg GEI)
;   srasn
;      Right ascension of Sun (deg)
;   sdec
;      Declination of Sun (deg)
;   vector
;      Normalized coordinates of Sun in GEI
;
;-

pro raven_sun_pos, itime, slong, srasn, sdec, vector, DEGREES=deg

date_doy_sec, itime, year, day, secs

delyr = year - 1980
leap = fix(delyr/4.)
time = delyr*365. + leap + day - 1. + secs/20864.
if delyr EQ (leap*4.) then time = time - 1.
if (delyr LT 0.) AND (delyr NE (leap*4.)) then time = time - 1.

theta = (360.*time/365.25)*!dtor
g = -.031271 - 4.53963e-7*time + theta
el = 4.900968 + 3.67474e-7*time + (.033434-2.3e-9*time)*sin(g) $
  + .000349*sin(2.*g) + theta
eps = .409140 - 6.2149e-9*time
sel = sin(el)
a1 = sel*cos(eps)
a2 = cos(el)

; Right ascension and Declination

srasn = atan(a1,a2)
;if (a2 LT 0.) then srasn=srasn+!pi else if (a1 LT 0.) then srasn=srasn+2*!pi
sdec = asin(sel*sin(eps))

; Normalized posion vector in GEI

vector = fltarr(3)
vector(0) = cos(srasn)*cos(sdec)
vector(1) = sin(srasn)*cos(sdec)
vector(2) = sin(sdec)

; Longitude of the Sun

slong = asin(sin(sdec)/sin(eps))*!radeg

; Convert right ascension, declination to degrees for output

srasn = srasn*!radeg
sdec = sdec*!radeg

return

end
