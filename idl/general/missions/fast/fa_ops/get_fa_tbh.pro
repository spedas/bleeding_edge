;+
; FUNCTION:
; 	 GET_FA_TBH
;
; DESCRIPTION:
;
;
;	function to load FAST Teams burst He+ species data from the
;	SDT program shared memory buffers.
;
;	A structure of the following format is returned:
;
;	   DATA_NAME     STRING    'Tms Burst Helium'  ; Data Quantity name
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
;	   GEOM          FLOAT     Array(nbins)        ; Geometry factor
;	   DENERGY       FLOAT     Array(nnrgs, nbins) ; Energies for bins
;	   DTHETA        FLOAT     Array(nbins)        ; Delta Theta
;	   EFF           FLOAT     Array(nnrgs)        ; Efficiency (GF)
;	   MASS          DOUBLE    0.0417556           ; Mass eV/(km/sec)^2
;	   GEOMFACTOR    DOUBLE    1.                  ; Bin GF
;	   HEADER_BYTES  BYTE      Array(25)	       ; Header bytes
;	
; CALLING SEQUENCE:
;
; 	data = get_fa_tbh (time, [START=start | EN=en | ADVANCE=advance |
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
;	@(#)get_fa_tbh.pro	1.14 08/15/97
; 	Originally written by Jonathan M. Loran,  University of 
; 	California at Berkeley, Space Sciences Lab.   June '95
;
; MODIFICATION HISTORY:
; 		     eff added by Li Tang 1/1/97   Univ. of New Hampshire
;		     geomfactor = 0.0015
;		     units_procedure = 'convert_tms_units'
;		     geom(nnrgs, nbins)
;		     spin_fract added
;		 7/15/97  Keyword CALIB added	L.Tang
;-

FUNCTION Get_fa_tbh, inputTime, START=start, EN=en, ADVANCE=advance,  $
                         RETREAT=retreat, CALIB = calib

      ; Get samples while dimensions are wrong

      spec = 0			; O+ species

      first = 1

      REPEAT BEGIN
          IF NOT first THEN       $
            print, 'get_fa_tbh.pro: Badly formed data.  Getting next sample'
          first = 0

          dat = get_md_from_sdt ('Tms_Burst_Data', 2001, TIME=inputTime,    $
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

      data_name = 'Tms Burst Helium'
      units_name = 'Counts'
      units_procedure = 'convert_tms_units'

      ; get the header bytes for this time

      hdr_time = inputTime
      hdr_dat = get_fa_tb_hdr (hdr_time)

      IF hdr_dat.valid EQ 0 THEN BEGIN
        print, 'Error getting Header bytes for this packet.  Bytes will be nil.'
        header_bytes = BYTARR(44)
      ENDIF ELSE BEGIN
         header_bytes = hdr_dat.bytes
      ENDELSE

      magdir_offset = 0.0	;magnetic direction offset. need to change
      mode = header_bytes(6) AND 15B	; teams mode
      sphase = header_bytes(0) + ISHFT(1*(header_bytes(1) AND 3B), 8)
      addr = header_bytes(4)
      magdir = (ISHFT(header_bytes(2), -4) + 			$ 
              ISHFT((1*header_bytes(3)), 4))*(360.0/4096.0)

      WHILE mode EQ 0 AND sphase EQ 0 AND addr EQ 0 AND magdir LT 0.001 AND dat.valid EQ 1 DO BEGIN

      dat = get_md_from_sdt ('Tms_Burst_Data', 2001, TIME=dat.time, /ad)
      IF dat.valid THEN BEGIN
        hdr_dat = get_fa_tb_hdr (dat.time)
        IF hdr_dat.valid EQ 0 THEN BEGIN
         print, 'Error getting Header bytes for this packet. Bytes will be nil.'
         header_bytes = BYTARR(44)
        ENDIF ELSE BEGIN
         header_bytes = hdr_dat.bytes
        ENDELSE
        mode = header_bytes(6) AND 15B	; teams mode
        sphase = header_bytes(0) + ISHFT(1*(header_bytes(1) AND 3B), 8)
        addr = header_bytes(4)
        magdir = (ISHFT(header_bytes(2), -4) + 			$ 
              ISHFT((1*header_bytes(3)), 4))*(360.0/4096.0)
      ENDIF
ENDWHILE
      IF NOT dat.valid THEN       RETURN, {data_name: 'Null', valid: 0}

      data = FLOAT (REFORM (dat.values, dat.dimsizes(0), dat.dimsizes(1), dat.dimsizes(2)))
      data = data (*,*,2)

      inputTime = dat.time 


      IF dat.ncomp GT 2 THEN BEGIN
         IF (where(dat.max2-dat.min2 lt 0))(0) NE -1 THEN      $
           dat.max2(where(dat.max2-dat.min2 lt 0))=dat.max2(where(dat.max2-dat.min2 lt 0))+360

	 theta=FLTARR(dat.dimsizes(0), dat.dimsizes(1))
	 FOR i = 0, 7 DO theta(*,i)=78.75 - i*22.5
	 FOR i = 8, 15 DO theta(*,i)=theta(*,15-i)
         dtheta = FLOAT(REPLICATE(22.5,dat.dimsizes(1)))
;         theta = FLOAT (REPLICATE (1., dat.dimsizes(0)) # ((dat.max2+dat.min2)/2.) mod 360.)
         energy = FLOAT (REBIN((dat.max1+dat.min1)/2., dat.dimsizes(0), dat.dimsizes(1)))
         denergy = FLOAT (REBIN (dat.max1 - dat.min1, dat.dimsizes(0), dat.dimsizes(1)))
      ENDIF ELSE BEGIN 
         theta = REPLICATE(0., dat.dimsizes(0), dat.dimsizes(1))
         dtheta = REPLICATE(0., dat.dimsizes(1))
         energy = REPLICATE(0.,dat.dimsizes(0), dat.dimsizes(1))
         denergy = REPLICATE(0.,dat.dimsizes(0), dat.dimsizes(1))
      ENDELSE

      geom = FLOAT(REPLICATE (1., dat.dimsizes(1)))
      mass = 0.0417556                          ; mass eV/(km/sec)^2
      geomfactor = 0.0015


      spin_fract = REPLICATE(1,dat.dimsizes(0), dat.dimsizes(1))

      pac = header_bytes(11)		;For post acceleration voltage
      eff = FA_TTOF_CALIBRATION(energy, spec, pac, eff_version)

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
		 mode:		mode,					      $
		 magdir:	magdir-magdir_offset,			      $
                 mass: 		mass,					      $
                 geomfactor: 	geomfactor,				      $
                 header_bytes: 	header_bytes,				      $
		 eff_version:   eff_version}

END 
