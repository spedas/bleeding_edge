;+
; FUNCTION:	dipole_offset
;
; PURPOSE:	Calculate the location of the dipole using the IGRF
;		coefficients and their secular variation.  IGRF coefficients
;		are the coefficients used in the spherical harmonic
;		expansion of the earth's magnetic field and there is a
;		standard formula for converting the first few of these
;		coefficients to dipole offset.
;
;		This version is accurate for years 1995-2000
;
;		Returns a 3-element vector in kilometers.
;
; INPUT:	Optional argument is 4-digit year
;
; Algorithm by:	Mike Temerin
; Written by:	J.Rauchleiba  4/8/97
;-
function dipole_offset, refyear

if NOT keyword_set(refyear) then refyear=strmid(systime(0), 20, 4)
refyear = fix(refyear)
revision = 1995
year = refyear - revision

g10 = -29682.0 + 17.6*year
g11 = -1789.0 + 13.0*year
g20 = -2197.0 - 31.2*year
g21 = 3074.0 + 3.7*year
g22 = 1685.0 - .8*year

h11 = 5318.0 - 18.3*year
h21 = -2356.0 - 15.0*year
h22 = -425.0 - 8.8*year
h2 = g10*g10 + g11*g11 + h11*h11

sq3 = sqrt(3.0)

L0 = 2.*g10*g20 + (g11*g21 + h11*h21)*sq3
L2 = -h11*g20 + (g10*h21 - h11*g22 + g11*h22)*sq3
L1 = -g11*g20 + (g10*g21 + g11*g22 + h11*h22)*sq3

e = (L0*g10 + L1*g11 + L2*h11)/(4.*h2)

MEAN_RAD = 6372.1 ;km

magdisp = dblarr(3)

magdisp(0) = MEAN_RAD*(L1 - g11*e)/(3.*h2)
magdisp(1) = MEAN_RAD*(L2 - h11*e)/(3.*h2)
magdisp(2) = MEAN_RAD*(L0 - g10*e)/(3.*h2)

return, magdisp

end
