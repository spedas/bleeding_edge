;+
; FUNCTION:
; 	 GET_FA_TSO_EQ_SP
;
; DESCRIPTION:
;
;
;	function to get FAST Teams survey O+ species eqtuator data from 
;	get_fa_tsp.pro routine, calculate pitch angles and add efficiency 
;	to the returned data. The difference of this routine from 
;	GET_FA_TSO_EQ.PRO is that this routine generates one spin 
;	resolution data when in TEAMS mode 6 and 7.
;	
;
;	A structure of the following format is returned:
;
;	   DATA_NAME     STRING    'Tms Survey Oxygen' ; Data Quantity name
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
;	   MASS          DOUBLE    0.165695            ; Mass eV/(km/sec)^2
;	   GEOMFACTOR    DOUBLE    0.0015              ; Bin GF
;	   HEADER_BYTES  BYTE      Array(86)	       ; Header bytes
;	   SPIN_FRACT    FLOAT     Array(nnrgs, nbins) ; Spin fraction of angles
;	   EFF_VERSION   FLOAT     1.00		       ; Calibration version
;	
; CALLING SEQUENCE:
;
; 	data = get_fa_tso_eq_sp (time, [START=start | EN=en | ADVANCE=advance |
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
;	Created By:           Li Tang	9/17/96	  University of New Hampshire, 
;						  Space Physics Lab
;       Last modification: 
;		     7/15/97  keyword CALIB added 	L.Tang
;		              domega removed		L.Tang
;-

FUNCTION Get_fa_tso_eq_sp, inputTime, START=start, EN=en, ADVANCE=advance,  $
                         RETREAT=retreat, SPIN_AVER=spin_aver,CALIB=calib

   spec = 3				; O+ species
   eq_ang = [0, 3, 6, 11, 32, 35, 38, 43, 16, 19, 22, 27, 48, 51, 54, 59]
   magdir_offset = 0.0		;magnetic direction offset. need to change
   geomfactor = 0.0015
   pt_limits = [0., 360.]

   dat = get_fa_tso(inputTime, START = start, EN = en, ADVANCE = advance,  $
			 RETREAT=retreat)
   IF NOT dat.valid THEN       RETURN, {data_name: 'Null', valid: 0}

   nbins = 16		;In equator, there are 16 angle bins
   spin_fract = FLOAT(REPLICATE (0.125, dat.nenergy, nbins))
   units_procedure = 'convert_tms_units'
   geom = FLOAT(REPLICATE (2., dat.nenergy, nbins))
;   domega = REPLICATE(0.3005588, nbins)

   energy = FLOAT(REBIN(dat.energy(*, 0), dat.nenergy, nbins))
   denergy = FLOAT(REBIN(dat.denergy(*, 0), dat.nenergy, nbins))

   theta = FLTARR(dat.nenergy, nbins)  
   FOR i = 0, (nbins-1) DO  theta(*, i) = 11.25 + 22.5*i
   dtheta =  FLOAT(REPLICATE (22.5, nbins))

   last_hdr_time = dat.time - (dat.end_time - dat.time)/2.0
   hdr_mag = get_fa_tsop_hdr(last_hdr_time)	;call previous data header
						;to average mag-direction
   IF hdr_mag.valid EQ 0 THEN last_hdr_bytes = dat.header_bytes 	$
   ELSE last_hdr_bytes = hdr_mag.bytes


   mode = dat.header_bytes(6) AND 15B		; teams mode

   IF (mode EQ 6 OR mode EQ 7)  THEN BEGIN
	inputTime = dat.time
	dat2 = get_fa_tso(inputTime, /ad)
	IF NOT dat2.valid THEN RETURN, {data_name:'Null', valid: 0}

   	mode2 = dat2.header_bytes(6) AND 15B

	IF (mode2 EQ 6 OR mode2 EQ 7) THEN BEGIN
	   del_t2 = dat2.time - dat.end_time
	   del_t1 = dat.end_time - dat.time

	   IF del_t2 GT del_t1 THEN BEGIN inputTime = dat.time
	   ENDIF ELSE BEGIN
	     dat.data = dat.data + dat2.data
	     IF (WHERE(dat2.header_bytes))(0) NE -1 THEN dat.header_bytes = dat2.header_bytes


	     dat.end_time = dat2.end_time
	     dat.integ_t = dat.integ_t + dat2.integ_t
   	   ENDELSE
	ENDIF		; end of mode2 == 6 or 7

   ENDIF		; end of mode == 6 or 7

   IF (WHERE(dat.header_bytes))(0) EQ -1 THEN dat.header_bytes = last_hdr_bytes

; get equator data:
   data = FLTARR(dat.nenergy, nbins)
   FOR an = 0, (nbins-1) DO BEGIN
         an1 = eq_ang(an)
         an2 = an1 + 1
         data(*,an) = dat.data(*,an1) + dat.data(*, an2)
   ENDFOR

   magdir1 = (ISHFT(last_hdr_bytes(2), -4) + 				$ 
              ISHFT((1*last_hdr_bytes(3)), 4))*360.0/4096.0
   magdir2 = (ISHFT(dat.header_bytes(2), -4) + 				$ 
              ISHFT((1*dat.header_bytes(3)), 4))*360.0/4096.0

   magdir = (magdir1 + magdir2)/2.0
   IF ABS(magdir1 - magdir2) GT 180.0 THEN magdir = (magdir + 180.) mod 360.

;   magdir = magdir + magdir_offset

   theta = theta + magdir - magdir_offset

   idx = WHERE(theta(0,*) LT 0.0)
   IF idx(0) NE -1 THEN theta(*, idx) = 360. + theta(*, idx)
   theta = theta mod 360.


;   pac = dat.header_bytes(11)			;For post acceleration voltage

   eff_eq = (dat.eff(*,eq_ang) + dat.eff(*,(eq_ang+1)))/2.
;   eff = fa_ts_eff_eq(dat.energy,pac,spec, 0, 1, eff_version)

   RETURN,  {  data_name:	dat.data_name, 				      $
               valid: 		1, 					      $
               project_name:	'FAST',					      $
               units_name: 	dat.units_name, 			      $
               units_procedure: units_procedure,			      $
               time: 		dat.Time,				      $
               end_time: 	dat.end_time,				      $
               integ_t: 	dat.integ_t,			              $
               nbins: 		nbins,		 			      $
               nenergy: 	dat.nenergy,	 			      $
               data: 		data,					      $
               energy:	 	energy, 				      $
               theta:	 	theta,                                        $
               geom: 		geom, 		       			      $
               denergy: 	denergy,	       			      $
               dtheta: 		dtheta, 				      $
               pt_limits:	pt_limits,				      $
               eff: 	 	eff_eq,					      $
               mass: 		dat.mass,				      $
               geomfactor: 	geomfactor,				      $
               header_bytes: 	dat.header_bytes,			      $
	       spin_fract:      spin_fract,				      $
	       eff_version:     dat.eff_version}

END 
