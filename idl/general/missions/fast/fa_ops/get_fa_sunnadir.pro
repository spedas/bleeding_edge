;+
; FUNCTION: get_fa_sunnadir
;
; PURPOSE:
;	For the FAST satellite, calculates the the simulated sun pulse
;	from earth horizon crossings and spin period.  
;
; CALLING SEQUENCE:
;	simSunpulseArr = get_fa_sunnadir(times, horizCrossings,   $
;			period, GOOD_INDICES=gi)
; 
; INPUTS:
;	times: 		Array of time tags that apply to the other
;       		input arrays.
;	horizCrossings:	An array the same size as times, of structures
;			{setime: double, estime: double} where setime
;                       is the space earth horizon crossing time, and
;                       estime is the earth space horizon crossing
;                       time.
;	period:		Period of one spin of the spacecraft in seconds.
;
; KEYWORD PARAMETERS:
; 	GOOD_INDICES:	This will give the indices that contain good
;		 	data that were used from the calling args.
;
; OUTPUTS:
;	simSunpulseArr:	This is the returned array of simulated
;			sun pulse times, one array element for each
;			input time given in the times parameter.
;
; MODIFICATION HISTORY:
;	@(#)get_fa_sunnadir.pro	1.1 02/12/98
; 	Originally written by Jonathan M. Loran,  University of 
; 	California at Berkeley, Space Sciences Lab.   Oct '97
;-

FUNCTION get_fa_sunnadir, times, horizCross, period, 		$
            		GOOD_INDICES = goodIndices

   ; eliminate horizon crossings where the sample time was between
   ; space-earth and earth-space.  These points won't contain the 
   ; necessary delta-T between horiz crossings to do our calculation.
   
   goodIndices = where ((horizCross.estime - horizCross.setime) GT 0)
   hc = horizCross (goodIndices)
   per = period (goodIndices)

   ; Get the Orbit data for this times-pan

   get_fa_orbit, times[goodIndices], /time_array,	$
                 /no_store, struc = orb, /definitive

   ; Get the nadirs from the horizon x-ings.

   nadir = fa_nadir_from_horiz (hc, orb)

   ; Get azimuthal angles in the spin plane between the earth nadir and 
   ; sun direction.

   azimAngles = fa_nadir_sun_azim (nadir, orb)

   ; From these angles, return sun pulse times

   RETURN, fa_sun_pulse_from_azim (azimAngles, nadir, per)
   
END
