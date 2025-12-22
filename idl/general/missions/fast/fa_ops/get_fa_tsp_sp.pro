;+
; FUNCTION:
; 	 GET_FA_TSP_SP
;
; DESCRIPTION:
;
;
;	function to get FAST Teams survey H+ species eqtuator data from 
;	get_fa_tsp.pro routine, calculate pitch angles and add efficiency 
;	to the returned data. The difference of this routine from 
;	GET_FA_TSP.PRO is that this routine generates one spin 
;	resolution data when in TEAMS mode 6 and 7.
;
;
;	A structure of the following format is returned:
;
;	   DATA_NAME     STRING    'Tms Survey Proton' ; Data Quantity name
;	   VALID         INT       1                   ; Data valid flag
; 	   PROJECT_NAME  STRING    'FAST'              ; project name
; 	   UNITS_NAME    STRING    'Counts'            ; Units of this data
; 	   UNITS_PROCEDURE  STRING 'proc'              ; Units conversion proc
;	   TIME          DOUBLE    8.0118726e+08       ; Start Time of sample
;	   END_TIME      DOUBLE    7.9850884e+08       ; End time of sample
;	   INTEG_T       DOUBLE    3.0000000           ; Integration time
;	   NBINS         INT       nbins               ; Number of angle bins
;	   NENERGY       INT       nnrgs               ; Number of energy bins
;	   DATA          FLOAT     Array(nnrgs, nbins) ; Data qauantities
;	   ENERGY        FLOAT     Array(nnrgs, nbins) ; Energy steps
;	   THETA         FLOAT     Array(nnrgs, nbins) ; Pitch angle for bins
;	   GEOM          FLOAT     Array(nnrgs, nbins) ; Geometry factor
;	   DENERGY       FLOAT     Array(nnrgs, nbins) ; Energies for bins
;	   DTHETA        FLOAT     Array(nbins)        ; Delta Theta
;	   DOMEGA        FLOAT     Array(nbins)        ; Solid angle for bins
;	   PT_LIMITS     FLOAT     Array(2)            ; Angle min/max limits
;	   EFF           FLOAT     Array(nnrgs, nbins) ; Efficiency (GF)
;	   MASS          DOUBLE    0.0104389            ; Mass eV/(km/sec)^2
;	   GEOMFACTOR    DOUBLE    0.0015              ; Bin GF
;	   HEADER_BYTES  BYTE      Array(86)	       ; Header bytes
;	   SPIN_FRACT    FLOAT     Array(nnrgs, nbins) ; Spin fraction of angles
;	   EFF_VERSION   FLOAT     1.00		       ; Calibration version
;	
; CALLING SEQUENCE:
;
; 	data = get_fa_tsp_sp (time, [START=start | EN=en | ADVANCE=advance |
;				RETREAT=retreat])
;
; ARGUMENTS:
;
;	time 			This argument gives a time handle from which
;				to take data from.  It may be either a string
;				with the following possible formats:
;					'YY-MM-DD/HH:MM:SS.MSC'  or
;					'HH:MM:SS'     (use reference date)
;				or a number, which will represent seconds
;				since 1970 (must be a double > 94608000.D), or
;				a hours from a reference time, if set.
;
;				time will always be returned as a double
;				representing the actual data time found in
;				seconds since 1970.
;
; KEYWORDS:
;
;	START			If non-zero, get data from the start time
;				of the data instance in the SDT buffers
;
;	EN			If non-zero, get data at the end time
;				of the data instance in the SDT buffers
;
;	ADVANCE			If non-zero, advance to the next data point
;				following the time input
;
;	RETREAT			If non-zero, retreat (reverse) to the previous
;				data point before the time input
;
;
; RETURN VALUE:
;
;	Upon success, the above structure is returned, with the valid tag
;	set to 1.  Upon failure, the valid tag will be 0.
;
; REVISION HISTORY:
;
;       Created By:     Eric Lund 2000-05-10    University of New Hampshire,
;                                               Space Physics Lab
;       Based On:       get_fa_tsp_eq_sp by Li Tang
;-

FUNCTION Get_fa_tsp_sp, inputTime, START=start, EN=en, ADVANCE=advance,  $
                         RETREAT=retreat, SPIN_AVER=spin_aver,CALIB=calib

   spec = 0				; H+ species

   dat = get_fa_tsp(inputTime, START = start, EN = en, ADVANCE = advance,  $
			 RETREAT=retreat)
   IF NOT dat.valid THEN       RETURN, {data_name: 'Null', valid: 0}

   mode = dat.header_bytes(6) AND 15B		; teams mode

   IF (mode EQ 6 OR mode EQ 7) THEN BEGIN
	inputTime = dat.time
	dat2 = get_fa_tsp(inputTime, /ad)
	IF NOT dat2.valid THEN RETURN, {data_name:'Null', valid: 0}

   	mode2 = dat2.header_bytes(6) AND 15B

	IF (mode2 EQ 6 OR mode2 EQ 7) THEN BEGIN
	   del_t2 = dat2.time - dat.end_time
	   del_t1 = dat.end_time - dat.time

	   IF del_t2 GT del_t1 THEN BEGIN inputTime = dat.time
	   ENDIF ELSE BEGIN
		dat = sum3d(dat, dat2)
	   ENDELSE
	ENDIF		; end of mode2 == 6 or 7

   ENDIF		; end of mode == 6 or 7

   RETURN, dat
END 
