;+
; FUNCTION:
; 	 GET_FA_TBH_EQ
;
; DESCRIPTION:
;
;
;	function to load FAST Teams burst helium species equator data 
;         from the SDT program shared memory buffers.
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
;	   GEOM          FLOAT     Array(nnrgs, nbins) ; Geometry factor
;	   DENERGY       FLOAT     Array(nnrgs, nbins) ; Energies for bins
;	   DTHETA        FLOAT     Array(nbins)        ; Delta Theta
;	   SPIN_FRACT    FLOAT     ARRAY(nnrgs, nbins) ; Spin fraction of angles
;	   SPBIN	 INT	   		       ; Spin phase bin
;	   MODE	  	 INT				; TEAMS Instrument mode
;	   MAGDIR	 FLOAT				; Mag direction
;	   EFF           FLOAT     Array(nnrgs)         ; Efficiency (GF)
;	   EFF_VERSION   FLOAT	   1.0			; Eff. calibration vers.
;	   MASS          DOUBLE    0.0417556           ; Mass eV/(km/sec)^2
;	   GEOMFACTOR    DOUBLE    0.0015                  ; Bin GF
;	   HEADER_BYTES  BYTE      Array(25)	       ; Header bytes
;	
; CALLING SEQUENCE:
;
; 	data = get_fa_tbh_eq (time, [START=start | EN=en | ADVANCE=advance |
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
; 
;
;	
; CREATED BY:
;		 Li Tang   11/2/96      University of New Hampshire
;					Space Physics Lab
; MODIFICATION HISTORY:
;		 7/15/97  Keyword CALIB added	L.Tang
;		 7/15/97  domega removed	L.Tang
;		 7/18/97  updated spin phase correction	L.Tang
;-

FUNCTION Get_fa_tbh_eq, inputTime, START=start, EN=en, ADVANCE=advance,  $
                         RETREAT=retreat, CALIB = calib

      spec=2			; species He+
      magdir_offset = 0.0	;magnetic direction offset. need to change
      geomfactor = 0.0015
      swps=[32, 32, 64, 32, 64, 32, 64, 32, 64, 32]
      ; Get samples while dimensions are wrong

      first = 1

      REPEAT BEGIN
          IF NOT first THEN       $
            print, 'get_fa_tbh_eq.pro: Badly formed data.  Getting next sample'
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

;     inputTime = dat.time

      ENDREP UNTIL md_dims_ok(dat)

      ; get data dat.values into correct dimensions here

      data_name = 'Tms Burst Helium'
      units_name = 'Counts'
      units_procedure = 'convert_tms_units'

      ; get the header bytes for this time

;      hdr_time = inputTime
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

WHILE mode EQ 0 AND sphase EQ 0 AND addr EQ 0 AND magdir LT 0.001 AND dat.valid EQ 1 DO BEGIN

      dat = get_md_from_sdt ('Tms_Burst_Data', 2001, TIME=dat.time, /advance)
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

      inputTime = dat.time 
      data0 = FLOAT (REFORM (dat.values, dat.dimsizes(0), dat.dimsizes(1), dat.dimsizes(2)))
      nbins = 2
      data = FLTARR(dat.dimsizes(0), nbins)
      data(*,0) = data0(*,3,2) + data0(*,4,2)
      data(*,1) = data0(*,11,2) + data0(*,12,2)



      IF dat.ncomp GT 2 THEN BEGIN
         theta = FLTARR(dat.dimsizes(0), nbins)  
         dtheta =  FLOAT(REPLICATE (360./swps(mode), nbins))
         energy = FLOAT (REBIN((dat.max1+dat.min1)/2., dat.dimsizes(0), nbins))
         denergy = FLOAT (REBIN (dat.max1 - dat.min1, dat.dimsizes(0), nbins))
      ENDIF ELSE BEGIN 
         theta = REPLICATE(0., dat.dimsizes(0), nbins)
         dtheta = REPLICATE(0., nbins)
         energy = REPLICATE(0.,dat.dimsizes(0), nbins)
         denergy = REPLICATE(0.,dat.dimsizes(0), nbins)
      ENDELSE

      addr_idx=addr/8	   	;0 for address 0,  1 for address 8, 
				;2 for address 16, 3 for address 24
      nswp = FIX(swps(mode)*(sphase/1024.))	; integer sweep number
      major_sphase = nswp/4		; 0<= major_sphase< 8 for 32 sweep mode
					; 0<= major_sphase<16 for 64 sweep mode

      angbin = 4*major_sphase+addr_idx
      IF nswp GT angbin THEN angbin = angbin 		$
      ELSE IF nswp LT angbin THEN angbin = angbin-4	$
      ELSE PRINT,"Data reading/timing problem detected by get_fa_tbh_eq!"
      IF angbin LT 0 THEN angbin = swps(mode) + angbin

      IF angbin LT swps(mode)/2 THEN angbin2 = angbin+swps(mode)/2 	$
      ELSE angbin2 = angbin-swps(mode)/2

      theta(*,0) = (360./swps(mode))*(angbin + 0.5)
      theta(*,1) = (theta(*,0) + 180.) MOD 360.

      pac = header_bytes(11)		;For post acceleration voltage
      eff = REPLICATE (1., dat.dimsizes(0), nbins)
      eff0 = FA_TTOF_CALIBRATION(energy, spec, pac, eff_version)
      eff(*,0) = (eff0(*,3) + eff0(*,4))/2.
      eff(*,1) = (eff0(*,11) + eff0(*,12))/2.

      geom = FLOAT(REPLICATE (2.,dat.dimsizes(0), nbins))
      spin_fract = FLOAT(REPLICATE (1.,dat.dimsizes(0), nbins))
      mass = 0.0417556                         ; mass AMU/CHARGE

      theta = theta + magdir - magdir_offset
      idx = WHERE(theta(0,*) LT 0.0)
      IF idx(0) NE -1 THEN theta(*, idx) = 360. + theta(*, idx)
      theta = theta mod 360.

      ; load up the data into IDL data structs

      RETURN,  {data_name:	data_name, 				      $
                 valid: 	1, 					      $
                 project_name:	'FAST',					      $
                 units_name: 	units_name, 				      $
                 units_procedure: units_procedure,			      $
                 time: 		dat.time,				      $
                 end_time: 	dat.endTime, 				      $
                 integ_t: 	((dat.endTime-dat.time)/dat.dimsizes(0)),  $
                 nbins: 	nbins, 			     	 	      $
                 nenergy: 	dat.dimsizes(0), 			      $
                 data: 		data,					      $
                 energy: 	energy, 				      $
                 theta: 	theta,                                        $
                 geom: 		geom, 	       				      $
                 denergy: 	denergy,       				      $
                 dtheta: 	dtheta, 				      $
		 spbin:		angbin,					      $
		 spbin2:	angbin2,				      $
		 mode:		mode,					      $
		 magdir:	magdir-magdir_offset,			      $
                 eff: 		eff,					      $
		 spin_fract:	spin_fract,				      $
                 mass: 		mass,					      $
                 geomfactor: 	geomfactor,				      $
                 header_bytes: 	header_bytes,				      $
		 eff_version:   eff_version}

END 
