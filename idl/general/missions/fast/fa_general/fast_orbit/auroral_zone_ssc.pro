;+
; FUNCTION:   auroral_zone_ssc
;
; PURPOSE:    Given an array of MLT values, returns latitudes of the
;             auroral zone boundaries.  The definition of the 
;             auroral zone is that used by the Satellite Situation
;             Center.  It is basically the area between two
;             sinusoidally-perturbed concentric circles centered on
;             the magnetic pole. 
;             Output is equatorward latitude in Geomagnetic
;             Coordinates, and in radians unles DEGREES is set.
; ARGUMENTS:
;
;   MLTINPUT  The input array of MLT values.  Elements should look
;             like [0, .1, .2, ...,  23.9, 24.0]
;
; KEYWORDS:
;
;   POLEWARD  Set this to a named variable to receive the poleward
;             latitude values.
;   SOUTH     Set this keyword to one if a reflection through the
;             magnetic equator is desired.  This gives
;             S. Hem. coordinates.
;   DEGREES   Set this keyword to get the coordinates in degrees,
;             otherwise output is in radians.
;
; NOTES:      The definition of the auroral zones used here is that
;             accepted by the SSC.  See also: auroral_zone.pro.
;
; CREATED:    By Joseph Rauchleiba
;             98/1/6
;-

function auroral_zone_ssc, mltinput, $
                poleward=apole, $
                south=south, $
                degrees=deg

mlt = 2.*!pi * mltinput/24.
npts = dimen1(mlt)

C = fltarr(npts)
S = fltarr(npts)
S(*) = 1.0
;dayside = where(mlt GE 1.57080 AND mlt LE 4.71239)
;S(dayside) = -1.0 ; Only needed if using atan(y/x) instead of atan(y,x)

C(*) = 0.392699
switch = where(mlt GT 0.398517)
C(switch) = 5.89049

aequa = 90. - 25.*cos($
                               atan($
                                     (sin(mlt + C)/5.),  $
                                     (S*sqrt(1. - (sin(mlt + C)/5.)^2)) $
                                   )$
                             ) + 5.*cos(mlt + C)

apole = 90. - 15.*cos($
                               atan($
                                     (sin(mlt)/3.),  $
                                     (S*sqrt(1. - (sin(mlt)/3.)^2)) $
                                   )$
                             ) +5.*cos(mlt)

if keyword_set(south) then begin
    aequa = -aequa
    apole = -apole
endif
if NOT keyword_set(deg) then begin
    aequa = aequa * !dtor
    apole = apole * !dtor
endif

return, aequa
end




