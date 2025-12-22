;+
; FUNCTION: fa_nadir_sun_azim
;
; PURPOSE:
;	For FAST, Get azimuthal angles in the spin plane between the
;	earth nadir and sun direction.
;
; CALLING SEQUENCE:
;	azimAngles = fa_nadir_sun_azim (nadir, orbData)
; 
; INPUTS:
;	nadir: 		An array of times where the nadir of the earth
;			intersects the spin plane of the satellite.
;	orbData:	The orbit data from get_fa_orbit that covers
;			the times given in nadir.
;
; KEYWORD PARAMETERS:
;
; OUTPUTS:
;	azimAngles:	This is the returned array of aximuthal angles
;			in the satellite spin plane between the earth
;			nadir and the satellite sun direction.
;			Upon error, -1 is returned.
;
; NOTES:
;	This routine calls get_fa_fdf_att to get the spin vector for
;	the times given in the nadir input array.  This is done for
;	the start and end of this time span.  If these two vectors
;	change, then get_fa_fdf_att is called for each point in the
;	nadir array, else the spin vector is considered constant
;	throughout.
;
; MODIFICATION HISTORY:
;	@(#)fa_nadir_sun_azim.pro	1.1 02/12/98
; 	Originally written by Jonathan M. Loran,  University of 
; 	California at Berkeley, Space Sciences Lab.   Oct '97
;-

FUNCTION fa_nadir_sun_azim, nadir, orb

   ; get the spin vectors at these nadir times

   att = get_fa_fdf_att (nadir)

   ; Get the array of azimuthal angles.  This is done in C.  
   ; Set up variables (allocate space) for calling C.

   azimuths = dblarr (n_elements(nadir))
   							
   attX = DOUBLE(att.x)
   attY = DOUBLE(att.y)
   attZ = DOUBLE(att.z)
   orbitX = DOUBLE(orb.fa_pos[*,0])
   orbitY = DOUBLE(orb.fa_pos[*,1])
   orbitZ = DOUBLE(orb.fa_pos[*,2])
   nadirs = DOUBLE(nadir)
   nnadirs = LONG(n_elements(nadir))
   azimuths = DOUBLE(azimuths)

   ; call C routine

   ret = call_external ('sunNadirIdlUtilLib.so', 'calcSunNadirAzim',	$
                        attX,					$
                        attY,					$
                        attZ,					$
                        orbitX,					$
                        orbitY,					$
                        orbitZ,					$
                        nnadirs,				$
                        azimuths,				$
                        nadirs)

   ; Check return value

   IF ret THEN  RETURN, -1       $
   ELSE   RETURN, azimuths
   
END
