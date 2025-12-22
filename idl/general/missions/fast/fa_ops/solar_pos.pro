;+
;
; PROCEDURE   solar_pos.pro
;
; PURPOSE     Calculates the position of the Sun.
;
; INPUTS
;
;   TIME     String or double float
;
; OUTPUTS
;
;   GST      Greenwich Mean Siderial Time (deg)
;   SLONG    Longitude along ecliptic (GEI, deg)
;   SRASN    Right Ascension of Sun (GEI, deg)
;   SDEC     Declination of Sun (GEI, deg)
;   S        Earth-Sun vector (GEI, normalized)
;
; NOTES
;
;   Only handles one point at a time.  The ease of calling this script
;   sacrifices its array capability.  If you want to use arrays,
;   compile rotmat.pro and use the SUN procedure therein.
;
;   Good for years 1901 through 2099.   
;   Accuracy .006 degree.
;   Cartesian coordinates of Earth-Sun vector are:
;
;   X = cos(SRASN)*cos(SDEC)
;   Y = sin(SRASN)*cos(SDEC)
;   Z = sin(SDEC)
;
; Algorithm by: G.D.Mead
; Translated into IDL by: J.Raucheiba 97/6/30
;-
pro solar_pos, time, gst, slong, srasn, sdec, S

date_doy_sec, time, iyr, iday, secs

if (iyr LT 1901) OR (IYR GT 2099) then message, 'Year out of range.'

;; Conversion constants

dtor = !dpi/180d
radeg = 1d/dtor

;; Fraction of a day

fday = secs/86400.D

;; The term "long(iyr-1901)/4L" is zero if unevenly divisible

dj = double(365L*long(iyr-1900) + long(iyr-1901)/4L + iday + fday) -.5D
t = dj/36525.D

;; vl in degrees

vl = (279.696678D + .9856473354D*dj) MOD 360.D

;; gst in degrees

gst = (279.690983D + .9856473354D*dj + 360.D*fday + 180.D) MOD 360.D
g = ((358.475845D + .985600267D*dj) MOD 360.D)*dtor

;; slong in degrees

slong = vl + (1.91946D - .004789D*t)*sin(g) + 0.020094D*sin(2.D*g)

;; Re-range SLONG

audela = where(slong GT 180.)
if audela(0) NE -1 then slong(audela) = slong(audela) - 360.D

;; obliq in radians (converted)

obliq = (23.45229D - .0130125D*t)*dtor

;; slp in radians (converted)

slp = (slong - .005686D)*dtor
sind = sin(obliq) * sin(slp)
cosd = sqrt(1.D - sind^2)

;; sdec in radians

sdec = atan(sind, cosd)

;; srasn in radians
;; This follows the form: PI - atan(y/x).
;; The negative in the "x" is a correction to C.T.Russell's
;; publication of Mead's routine SUN. Without it, the x-component of
;; the sun vector has the wrong sign, and the right ascension is pi
;; minus the correct value.

srasn = !dpi - atan(sind/cosd/tan(obliq), -cos(slp)/cosd)

;; Re-range SRASN

audela = where(srasn GT !dpi)
if audela(0) NE -1 then srasn(audela) = srasn(audela) - 2.D*!dpi

;; Get GEI vector pointing from Earth to Sun
;; sdec, srasn should be in radians at this point

S = reform([[cos(srasn)*cos(sdec), sin(srasn)*cos(sdec), sin(sdec)]])

;; Convert rt ascension, declination to degrees like other quantities

sdec = sdec*radeg
srasn = srasn*radeg

return
end
