;+
; FUNCTION:
; 	 GET_FA_TSP
;
; DESCRIPTION:
;
;
;	function to load FAST Teams survey proton species data from the SDT
;	program shared memory buffers.
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
;	   THETA         FLOAT     Array(nnrgs, nbins) ; Theta angle for bins
;	   PHI           FLOAT     Array(nnrgs, nbins) ; Phi angle for bins
;	   GEOM          FLOAT     Array(nbins)        ; Geometry factor
;	   DENERGY       FLOAT     Array(nnrgs, nbins) ; Energies for bins
;	   DTHETA        FLOAT     Array(nbins)        ; Delta Theta
;	   DPHI          FLOAT     Array(nbins)        ; Delta Phi
;	   DOMEGA        FLOAT     Array(nbins)        ; Solid angle for bins
;	   PT_LIMITS     FLOAT     Array(4)            ; Angle min/max limits
;	   EFF           FLOAT     Array(nnrgs, nbins) ; Efficiency (GF)
;	   MASS          DOUBLE    0.0104389           ; Mass eV/(km/sec)^2
;	   GEOMFACTOR    DOUBLE    0.0015                  ; Bin GF
;	   HEADER_BYTES  BYTE      Array(86)	       ; Header bytes
;	
; CALLING SEQUENCE:
;
; 	data = get_fa_tsp (time, [START=start | EN=en | ADVANCE=advance |
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
;	@(#)get_fa_tsp.pro	1.20 08/15/97
; 	Originally written by Jonathan M. Loran,  University of 
; 	California at Berkeley, Space Sciences Lab.   June '95
;
;LAST MODIFICATION:  eff added by Li Tang 10/21/96   Univ. of New Hampshire
;		     geomfactor = 0.0015
;		     units_procedure = 'convert_tms_units'
;			geom(nnrgs, nbins)
;		     7/15/97  keyword CALIB added 	L.Tang
;		    
;-

FUNCTION Get_fa_tsp, inputTime, START=start, EN=en, ADVANCE=advance,  $
                         RETREAT=retreat, CALIB=calib
      spec = 0
      ; Get samples while dimensions are wrong

      first = 1

      REPEAT BEGIN
          IF NOT first THEN       $
            print, 'get_fa_tsp.pro: Badly formed data.  Getting next sample'
          first = 0

          dat = get_md_from_sdt ('Tms_HO_Survey_Data', 2001, TIME=inputTime,    $
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

      data_name = 'Tms Survey Proton'
      units_name = 'Counts'
      units_procedure = 'convert_tms_units'
      data = FLOAT (REFORM (dat.values, dat.dimsizes(0), dat.dimsizes(1), dat.dimsizes(2)))
      data = data (*,*,0)

      IF dat.ncomp GT 2 THEN BEGIN
         IF (where(dat.max2(*,1)-dat.min2(*,1) lt 0))(0) NE -1 THEN      $
           dat.max2(where(dat.max2(*,1)-dat.min2(*,1) lt 0),1) =           $
                 dat.max2(where(dat.max2(*,1)-dat.min2(*,1) lt 0),1) + 180
         theta = FLOAT (REPLICATE (1.,  dat.dimsizes(0)) #     $
                        (dat.min2(*,1)+dat.max2(*,1))/2.)
         dtheta = FLOAT (dat.max2(*,1) - dat.min2(*,1))

         IF (where(dat.max2(*,0)-dat.min2(*,0) lt 0))(0) NE -1 THEN      $
           dat.max2(where(dat.max2(*,0)-dat.min2(*,0) lt 0),0) =           $
                 dat.max2(where(dat.max2(*,0)-dat.min2(*,0) lt 0),0) + 360
         phi = FLOAT (REPLICATE (1.,  dat.dimsizes(0)) #     $
                      ((dat.min2(*,0)+dat.max2(*,0))/2.) mod 360.)
         dphi = FLOAT (dat.max2(*,0) - dat.min2(*,0))

         energy = FLOAT (REBIN((dat.max1+dat.min1)/2., dat.dimsizes(0), dat.dimsizes(1)))
         denergy = FLOAT (REBIN (dat.max1 - dat.min1, dat.dimsizes(0), dat.dimsizes(1)))
      ENDIF ELSE BEGIN 
         theta = REPLICATE(0., dat.dimsizes(0), dat.dimsizes(1))
         dtheta = REPLICATE(0., dat.dimsizes(1))
         phi = REPLICATE(0., dat.dimsizes(0), dat.dimsizes(1))
         dphi = REPLICATE(0., dat.dimsizes(1))

         energy = REPLICATE(0.,dat.dimsizes(0), dat.dimsizes(1))
         denergy = REPLICATE(0.,dat.dimsizes(0), dat.dimsizes(1))
      ENDELSE

      ; set solid angles for angle bins

      domega = [ .1502794, .1502794, .2548015, .1502794,             $
                 .1502794, .2548015, .1502794, .1502794,             $
                 .1195698, .3405058, .2548015, .1502794,             $
                 .1502794, .2548015, .3405058, .1195698,             $
                 .1502794, .1502794, .2548015, .1502794,             $
                 .1502794, .2548015, .1502794, .1502794,             $
                 .1195698, .3405058, .2548015, .1502794,             $
                 .1502794, .2548015, .3405058, .1195698,             $
                 .1502794, .1502794, .2548015, .1502794,             $
                 .1502794, .2548015, .1502794, .1502794,             $
                 .1195698, .3405058, .2548015, .1502794,             $
                 .1502794, .2548015, .3405058, .1195698,             $
                 .1502794, .1502794, .2548015, .1502794,             $
                 .1502794, .2548015, .1502794, .1502794,             $
                 .1195698, .3405058, .2548015, .1502794,             $
                 .1502794, .2548015, .3405058, .1195698 ]

 spin_fract =								$
       [0.125,  0.125,  0.25,   0.125,  0.125,  0.25,   0.125,  0.125,	$
        0.5,    0.5,    0.25,   0.125,  0.125,  0.25,   0.5,    0.5,	$
        0.125,  0.125,  0.25,   0.125,  0.125,  0.25,   0.125,  0.125,	$
        0.5,    0.5,    0.25,   0.125,  0.125,  0.25,   0.5,    0.5,	$
        0.125,  0.125,  0.25,   0.125,  0.125,  0.25,   0.125,  0.125,	$
        0.5,    0.5,    0.25,   0.125,  0.125,  0.25,   0.5,    0.5,	$
        0.125,  0.125,  0.25,   0.125,  0.125,  0.25,   0.125,  0.125,	$
        0.5,    0.5,    0.25,   0.125,  0.125,  0.25,   0.5,    0.5]

      spin_fract = (REPLICATE(1, 1, dat.dimsizes(1)))*spin_fract
      spin_fract =REBIN(spin_fract, dat.dimsizes(0), dat.dimsizes(1))

      pt_limits = [-90., -180., 90., 180.]

      geom = FLOAT(REPLICATE (1., dat.dimsizes(0), dat.dimsizes(1)))
;      eff = REPLICATE (1., dat.dimsizes(0))
      mass = 0.0104389                          ; mass eV/(km/sec)^2
      geomfactor = 0.0015

      ; get the header bytes for this time

      hdr_time = inputTime
      hdr_dat = get_fa_tsop_hdr (hdr_time)

      IF hdr_dat.valid EQ 0 THEN BEGIN
         print, 'Error getting Header bytes for this packet.  Bytes will be nil.'
         header_bytes = BYTARR(86)
      ENDIF ELSE BEGIN
         header_bytes = hdr_dat.bytes
      ENDELSE

      sphase = header_bytes(0) + ISHFT(1*(header_bytes(1) AND 3B), 8)
      spin_section = (sphase/512) + 1    ;spin section in which data read out.
      pac = header_bytes(11)		;For post acceleration voltage
      mode = header_bytes(6) AND 15B	; teams mode

      eff = fa_ts_eff(energy, pac, spec, mode, spin_section, eff_version)

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
                 phi:   	phi,                                          $
                 geom: 		geom, 	       				      $
                 denergy: 	denergy,       				      $
                 dtheta: 	dtheta, 				      $
                 dphi:   	dphi,   				      $
                 domega:	domega,	 				      $
                 pt_limits:	pt_limits,				      $
                 eff: 		eff,					      $
		 spin_fract:    spin_fract,				      $
                 mass: 		mass,					      $
                 geomfactor: 	geomfactor,				      $
                 header_bytes: 	header_bytes,				      $
		 eff_version:   eff_version}

END 
