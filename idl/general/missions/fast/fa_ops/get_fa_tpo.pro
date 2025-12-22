;+
; FUNCTION:
; 	 GET_FA_TPO
;
; DESCRIPTION:
;
;
;	function to load FAST Teams pole Oxygen species data from the SDT
;	program shared memory buffers.
;
;	A structure of the following format is returned:
;
;	   DATA_NAME     STRING    'Tms Pole Oxygen'   ; Data Quantity name
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
;	   THETA         FLOAT     Array(nnrgs, nbins) ; Angle for bins
;	   GEOM          FLOAT     Array(nngrs, nbins) ; Geometry factor
;	   DENERGY       FLOAT     Array(nnrgs, nbins) ; Energies for bins
;	   DTHETA        FLOAT     Array(nbins)        ; Delta Theta
;	   EFF           FLOAT     Array(nnrgs)        ; Efficiency (GF)
;	   SPIN_FRACT    FLOAT     ARRAY(nnrgs, nbins) ; Spin fraction of angles
;	   MASS          DOUBLE    0.0104389           ; Mass eV/(km/sec)^2
;	   GEOMFACTOR    DOUBLE    0.0015                  ; Bin GF
;	   HEADER_BYTES  BYTE      Array(25)	       ; Header bytes
;	   EFF_VERSION   FLOAT	   1.0			; Eff. calibration vers.
;	
; CALLING SEQUENCE:
;
; 	data = get_fa_tpo (time, [START=start | EN=en | ADVANCE=advance |
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
; RETURN VALUE:
;
;	Upon success, the above structure is returned, with the valid tag
;	set to 1.  Upon failure, the valid tag will be 0.
;
; REVISION HISTORY:
;
;	@(#)get_fa_tpo.pro	1.13 08/15/97
; 	Originally written by Jonathan M. Loran,  University of 
; 	California at Berkeley, Space Sciences Lab.   June '95
;
;LAST MODIFICATION:  eff added by Li Tang 11/11/96   Univ. of New Hampshire
;		     spin_fract added
;		     units_procedure = 'convert_tms_units'
;		     geom(nnrgs, nbins)
;			7/15/97  KEYWORD CALIB added, LT
;-

FUNCTION Get_fa_tpo, inputTime, START=start, EN=en, ADVANCE=advance,  $
                         RETREAT=retreat, CALIB = calib


      spec = 3;				; O+ species
      ; Get samples while dimensions are wrong

       
      first = 1

      REPEAT BEGIN
          IF NOT first THEN       $
            print, 'get_fa_tpo.pro: Badly formed data.  Getting next sample'
          first = 0

          dat = get_md_from_sdt ('Tms_HO_Pole_Data', 2001, TIME=inputTime,    $
                          START = start, EN = en, ADVANCE = advance, RETREAT=retreat)

          IF NOT dat.valid THEN       RETURN, {data_name: 'Null', valid: 0}

          IF ( keyword_set (en) OR keyword_set (retreat) ) THEN BEGIN
              retreat = 1
              en = 0
          ENDIF ELSE BEGIN
              advance = 1
              start = 0
          ENDELSE

          inputTime = dat.time 

      ENDREP UNTIL md_dims_ok(dat)

      ; get data dat.values into correct dimensions here

      data_name = 'Tms Pole Oxygen'
      units_name = 'Counts'
      units_procedure = 'convert_tms_units'
      data = FLOAT (REFORM (dat.values, dat.dimsizes(0), dat.dimsizes(1), dat.dimsizes(2)))
      data = data (*,*,1)

      IF dat.ncomp GT 2 THEN BEGIN
         IF (where(dat.max2-dat.min2 lt 0))(0) NE -1 THEN      $
           dat.max2(where(dat.max2-dat.min2 lt 0))=dat.max2(where(dat.max2-dat.min2 lt 0))+360
         theta = FLOAT (REPLICATE (1., dat.dimsizes(0)) # ((dat.max2+dat.min2)/2.) mod 360.)
         dtheta = FLOAT (dat.max2 - dat.min2)
         energy = FLOAT (REBIN((dat.max1+dat.min1)/2., dat.dimsizes(0), dat.dimsizes(1)))
         denergy = FLOAT (REBIN (dat.max1 - dat.min1, dat.dimsizes(0), dat.dimsizes(1)))
      ENDIF ELSE BEGIN 
         theta = REPLICATE(0., dat.dimsizes(0), dat.dimsizes(1))
         dtheta = REPLICATE(0., dat.dimsizes(1))
         energy = REPLICATE(0.,dat.dimsizes(0), dat.dimsizes(1))
         denergy = REPLICATE(0.,dat.dimsizes(0), dat.dimsizes(1))
      ENDELSE

      geom = FLOAT(REPLICATE (2., dat.dimsizes(0), dat.dimsizes(1)))
      mass = 0.1670224                          ; mass eV/(km/sec)^2
      geomfactor = 0.0015

      ; get the header bytes for this time

      hdr_time = inputTime
      hdr_dat = get_fa_tpop_hdr (hdr_time)

      IF hdr_dat.valid EQ 0 THEN BEGIN
         print, 'Error getting Header bytes for this packet.  Bytes will be nil.'
         header_bytes = BYTARR(14)
      ENDIF ELSE BEGIN
         header_bytes = hdr_dat.bytes
      ENDELSE

      pac = header_bytes(11)		;For post acceleration voltage

      eff = REPLICATE (1., dat.dimsizes(0), dat.dimsizes(1))
      eff0 = FA_TTOF_CALIBRATION(energy, spec, pac, eff_version)
      eff(*, 0) = (eff0(*, 0) + eff0(*,15))/2.
      eff(*, 1) = (eff0(*, 7) + eff0(*,8))/2.
      spin_fract = FLOAT(REPLICATE (1.,dat.dimsizes(0), dat.dimsizes(1)))


      ; load up the data into IDL data structs

      RETURN,  {data_name:	data_name, 				      $
                 valid: 	1, 					      $
                 project_name:	'FAST',					      $
                 units_name: 	units_name, 				      $
                 units_procedure: units_procedure,			      $
                 time: 		inputTime,				      $
                 end_time: 	dat.endTime,				      $
                 integ_t: 	(dat.endTime - dat.time)/dat.dimsizes(0),     $
                 nbins: 	dat.dimsizes(1), 			      $
                 nenergy: 	dat.dimsizes(0), 			      $
                 data: 		data,					      $
                 energy: 	energy, 				      $
                 theta: 	theta,                                        $
                 geom: 		geom, 	       				      $
                 denergy: 	denergy,       				      $
                 dtheta: 	dtheta, 				      $
                 eff: 		eff,					      $
		 spin_fract:	spin_fract,				      $
                 mass: 		mass,					      $
                 geomfactor: 	geomfactor,				      $
                 header_bytes: 	header_bytes,				      $
		 eff_version:   eff_version}

END 
