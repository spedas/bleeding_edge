;+
; FUNCTION:
; 	 tms_himass_get_masses
;
; DESCRIPTION:
;
;	Procedure to return the mass for TEAMS HiMass data for a given mass bin
;
; CALLING SEQUENCE:
;
; 	ret = tms_himass_get_masses (mass, dmass, bin)
;
; ARGUMENTS:
;
;	bin:	the bin to get mass for
;	mass:	the returned array of mass angles vs bins
;	dmass:	the returned array of delta mass angles vs bins
;
; RETURN VALUE:
;
;	Upon success 0 is returned.  Upon failure, -1 is returned.
;
; REVISION HISTORY:
;
;	@(#)tms_himass_get_masses.pro	1.1 08/16/95
; 	Originally written by Jonathan M. Loran,  University of 
; 	California at Berkeley, Space Sciences Lab.   Aug '95
;-


FUNCTION  Tms_himass_get_masses, mass, dmass, bin

   IF N_ELEMENTS (bin) EQ 0 THEN BEGIN
      PRINT, '@(#)tms_himass_get_masses.pro	1.1: bin must be defined'
      RETURN, -1
   ENDIF
   
   CASE bin OF
   0: BEGIN &  mass = (0.70 + 0.75)/2. & dmass = 0.75 - 0.70 & END
   1: BEGIN &  mass = (0.75 + 0.81)/2. & dmass = 0.81 - 0.75 & END
   2: BEGIN &  mass = (0.81 + 0.87)/2. & dmass = 0.87 - 0.81 & END
   3: BEGIN &  mass = (0.87 + 0.93)/2. & dmass = 0.93 - 0.87 & END
   4: BEGIN &  mass = (0.93 + 1.00)/2. & dmass = 1.00 - 0.93 & END
   5: BEGIN &  mass = (1.00 + 1.07)/2. & dmass = 1.07 - 1.00 & END
   6: BEGIN &  mass = (1.07 + 1.15)/2. & dmass = 1.15 - 1.07 & END
   7: BEGIN &  mass = (1.15 + 1.23)/2. & dmass = 1.23 - 1.15 & END
   8: BEGIN &  mass = (1.23 + 1.32)/2. & dmass = 1.32 - 1.23 & END
   9: BEGIN &  mass = (1.32 + 1.42)/2. & dmass = 1.42 - 1.32 & END
   10: BEGIN &  mass = (1.42 + 1.52)/2. & dmass = 1.52 - 1.42 & END
   11: BEGIN &  mass = (1.52 + 1.63)/2. & dmass = 1.63 - 1.52 & END
   12: BEGIN &  mass = (1.63 + 1.75)/2. & dmass = 1.75 - 1.63 & END
   13: BEGIN &  mass = (1.75 + 1.88)/2. & dmass = 1.88 - 1.75 & END
   14: BEGIN &  mass = (1.88 + 2.02)/2. & dmass = 2.02 - 1.88 & END
   15: BEGIN &  mass = (2.02 + 2.17)/2. & dmass = 2.17 - 2.02 & END
   16: BEGIN &  mass = (2.17 + 2.33)/2. & dmass = 2.33 - 2.17 & END
   17: BEGIN &  mass = (2.33 + 2.50)/2. & dmass = 2.50 - 2.33 & END
   18: BEGIN &  mass = (2.50 + 2.68)/2. & dmass = 2.68 - 2.50 & END
   19: BEGIN &  mass = (2.68 + 2.88)/2. & dmass = 2.88 - 2.68 & END
   20: BEGIN &  mass = (2.88 + 3.09)/2. & dmass = 3.09 - 2.88 & END
   21: BEGIN &  mass = (3.09 + 3.31)/2. & dmass = 3.31 - 3.09 & END
   22: BEGIN &  mass = (3.31 + 3.55)/2. & dmass = 3.55 - 3.31 & END
   23: BEGIN &  mass = (3.55 + 3.82)/2. & dmass = 3.82 - 3.55 & END
   24: BEGIN &  mass = (3.82 + 4.09)/2. & dmass = 4.09 - 3.82 & END
   25: BEGIN &  mass = (4.09 + 4.39)/2. & dmass = 4.39 - 4.09 & END
   26: BEGIN &  mass = (4.39 + 4.72)/2. & dmass = 4.72 - 4.39 & END
   27: BEGIN &  mass = (4.72 + 5.06)/2. & dmass = 5.06 - 4.72 & END
   28: BEGIN &  mass = (5.06 + 5.43)/2. & dmass = 5.43 - 5.06 & END
   29: BEGIN &  mass = (5.43 + 5.83)/2. & dmass = 5.83 - 5.43 & END
   30: BEGIN &  mass = (5.83 + 6.26)/2. & dmass = 6.26 - 5.83 & END
   31: BEGIN &  mass = (6.26 + 6.71)/2. & dmass = 6.71 - 6.26 & END
   32: BEGIN &  mass = (6.71 + 7.21)/2. & dmass = 7.21 - 6.71 & END
   33: BEGIN &  mass = (7.21 + 7.73)/2. & dmass = 7.73 - 7.21 & END
   34: BEGIN &  mass = (7.73 + 8.30)/2. & dmass = 8.30 - 7.73 & END
   35: BEGIN &  mass = (8.30 + 8.91)/2. & dmass = 8.91 - 8.30 & END
   36: BEGIN &  mass = (8.91 + 9.56)/2. & dmass = 9.56 - 8.91 & END
   37: BEGIN &  mass = (9.56 + 10.26)/2. & dmass = 10.26 - 9.56 & END
   38: BEGIN &  mass = (10.26 + 11.01)/2. & dmass = 11.01 - 10.26 & END
   39: BEGIN &  mass = (11.01 + 11.81)/2. & dmass = 11.81 - 11.01 & END
   40: BEGIN &  mass = (11.81 + 12.68)/2. & dmass = 12.68 - 11.81 & END
   41: BEGIN &  mass = (12.68 + 13.61)/2. & dmass = 13.61 - 12.68 & END
   42: BEGIN &  mass = (13.61 + 14.60)/2. & dmass = 14.60 - 13.61 & END
   43: BEGIN &  mass = (14.60 + 15.67)/2. & dmass = 15.67 - 14.60 & END
   44: BEGIN &  mass = (15.67 + 16.82)/2. & dmass = 16.82 - 15.67 & END
   45: BEGIN &  mass = (16.82 + 18.05)/2. & dmass = 18.05 - 16.82 & END
   46: BEGIN &  mass = (18.05 + 19.37)/2. & dmass = 19.37 - 18.05 & END
   47: BEGIN &  mass = (19.37 + 20.79)/2. & dmass = 20.79 - 19.37 & END
   48: BEGIN &  mass = (20.79 + 22.31)/2. & dmass = 22.31 - 20.79 & END
   49: BEGIN &  mass = (22.31 + 23.95)/2. & dmass = 23.95 - 22.31 & END
   50: BEGIN &  mass = (23.95 + 25.70)/2. & dmass = 25.70 - 23.95 & END
   51: BEGIN &  mass = (25.70 + 27.58)/2. & dmass = 27.58 - 25.70 & END
   52: BEGIN &  mass = (27.58 + 29.60)/2. & dmass = 29.60 - 27.58 & END
   53: BEGIN &  mass = (29.60 + 31.77)/2. & dmass = 31.77 - 29.60 & END
   54: BEGIN &  mass = (31.77 + 34.09)/2. & dmass = 34.09 - 31.77 & END
   55: BEGIN &  mass = (34.09 + 36.59)/2. & dmass = 36.59 - 34.09 & END
   56: BEGIN &  mass = (36.59 + 39.27)/2. & dmass = 39.27 - 36.59 & END
   57: BEGIN &  mass = (39.27 + 42.14)/2. & dmass = 42.14 - 39.27 & END
   58: BEGIN &  mass = (42.14 + 45.23)/2. & dmass = 45.23 - 42.14 & END
   59: BEGIN &  mass = (45.23 + 48.54)/2. & dmass = 48.54 - 45.23 & END
   60: BEGIN &  mass = (48.54 + 52.09)/2. & dmass = 52.09 - 48.54 & END
   61: BEGIN &  mass = (52.09 + 55.91)/2. & dmass = 55.91 - 52.09 & END
   62: BEGIN &  mass = (55.91 + 60.00)/2. & dmass = 60.00 - 55.91 & END
   63: BEGIN &  mass = (60.00 + 64.40)/2. & dmass = 64.40 - 60.00 & END
   ENDCASE 

   ; and convert mass units to eV/(km/sec)^2

   mass = mass * 0.0104389
   dmass = dmass * 0.0104389

   RETURN, 0
END
