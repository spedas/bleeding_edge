;+
; FUNCTION: fa_sun_pulse_from_azim
;
; PURPOSE:
;	For the FAST satellite, calculates the time of a sun pulse
;	would occur based upon the earth nadir time, spin period,
;	azimuthal angle between sun direction and nadir direction in 
;	the spin plain.
;
; CALLING SEQUENCE:
;	simSunpulseArr = $
;		fa_sun_pulse_from_azim(azim, nadir, period)
; 
; INPUTS:
;	azim: 		Array of azimuthal angles between the sun
;			direction and the earth nadir in the spin plane
;	nadir:		An array times when the earth nadir is crossed
;			by the sun sensor.
;	period:		Period of one spin of the spacecraft in seconds.
;
; KEYWORD PARAMETERS:
;
; OUTPUTS:
;	simSunpulseArr:	This is the returned array of simulated
;			sun pulse times, one array element for each
;			input time given in the nadir parameter.
;
; MODIFICATION HISTORY:
;	@(#)fa_sun_pulse_from_azim.pro	1.1 02/12/98
; 	Originally written by Jonathan M. Loran,  University of 
; 	California at Berkeley, Space Sciences Lab.   Nov '97
;-

FUNCTION fa_sun_pulse_from_azim, azim, nadir, period

   ; angle between the horizon crossing sensor and the sun sensor

   hsAngle = 14 * !pi / 180        ; 14 degrees

   RETURN, period * (azim - hsAngle)/(2*!pi) + nadir
END
