;+
; FUNCTION:
; 	 GET_FA_TH_3D
;
; DESCRIPTION:
;
;
;	function to load FAST Teams HiMass data from the SDT
;	program shared memory buffers.
;
;	A structure of the following format is returned:
;
;	DATA_NAME     STRING    'Tms HiMass Bin:N'; Data Quantity name
;       VALID         INT       1                  	 ; Data valid flag
; 	PROJECT_NAME  STRING    'FAST'             	 ; project name
; 	UNITS_NAME    STRING    'Counts'           	 ; Units of this data
; 	UNITS_PROCEDURE  STRING 'proc'             	 ; Units conversion proc
;	TIME          DOUBLE    8.0118726e+08      	 ; Start Time of sample
; 	END_TIME      DOUBLE    7.9850884e+08      	 ; End time of sample
;	INTEG_T       DOUBLE    3.0000000          	 ; Integration time
;	NBINS         INT       nbins               	 ; Number of angle bins
;	NENERGY       INT       nnrgs             	 ; Number of energy bins
; 	NBINS	      INT	mbins		    	 ; Number of mass bins
;	DATA          FLOAT     Array(nnrgs, nbins,mbins) ; Data qauantities
;	ENERGY        FLOAT     Array(nnrgs, nbins) 	  ; Energy steps
;	THETA         FLOAT     Array(nnrgs, nbins) 	  ; Theta angle for bins
;	PHI           FLOAT     Array(nnrgs, nbins) 	  ; Phi angle for bins
;	GEOM          FLOAT     Array(nnrgs, nbins)	  ; Geometry factor
;	DENERGY       FLOAT     Array(nnrgs, nbins)	  ; Energies for bins
;	DTHETA        FLOAT     Array(nbins)        	  ; Delta Theta
;	DPHI          FLOAT     Array(nbins)        	  ; Delta Phi
;	DOMEGA        FLOAT     Array(nbins, nbins)	  ;Solid angle for bins
;	PT_LIMITS     FLOAT     Array(2)            	  ;Mass min/max limits
;	EFF           FLOAT     Array(nnrgs, nbins)	  ; Efficiency (GF)
;	MASS          FLOAT     Array(nnrgs, mbins)	  ; mean bin Mass in
;		  			       	   	   ;   mass unit
;	DMASS         FLOAT     Array(mbins)	   	   ; mass bin width in
;		 			           	   ;   mass unit
;	GEOMFACTOR    DOUBLE    0.0015              	   ; Bin GF
;	SPIN_FRACT    FLOAT     ARRAY(nnrgs, nbins)	   ; Spin fraction of 
;							   ; angles
;	HEADER_BYTES  BYTE      Array(226)	       	   ; Header bytes
;
; 	The bin number selected will be returned as part of the DATA_NAME
;	string.
;
; CALLING SEQUENCE:
;
; 	data = get_fa_th_3d (time, [START=start | EN=en |
;				ADVANCE = advance | RETREAT=retreat])
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
;	Made from get_fa_th.pro	1.13 12 Jul 1996
;	Last modification: 8/20/96   Li Tang   Univ. of New Hampshire
;					       Space Physcis Lab
; MODIFICATION HISTORY:
;		 7/15/97  Keyword CALIB added	L.Tang
;-

FUNCTION get_fa_th_3d, inputTime,  START=start, EN=en,            	$
                           ADVANCE=advance, RETREAT=retreat, CALIB = calib

   dat = get_md_from_sdt ('Tms_HiMass_Data', 2001, TIME=inputTime,      $
                          START = start, EN = en, ADVANCE = advance,	$
			  RETREAT=retreat)

   IF NOT dat.valid THEN       RETURN, {data_name: 'Null', valid: 0}

      ; get data dat.values into correct dimensions here

   data = FLOAT (REFORM (dat.values, dat.dimsizes(0), dat.dimsizes(1), dat.dimsizes(2)))
   inputTime = dat.time 
   data_name = 'Tms HiMass' 
   units_name = 'Counts'
   units_procedure = 'convert_tms_units'
   geom1 = [[2], [2], [3], [3], [2], [2], [3], [3], 			   $
	    [2], [2], [3], [3], [2], [2], [3], [3]]
   spin_fract1=[[0.25], [0.25], [0.5], [0.5], [0.25], [0.25], [0.5], [0.5], $
		[0.25], [0.25], [0.5], [0.5], [0.25], [0.25], [0.5], [0.5]]

;   domega1 =  [[.6011176], [.6011176], [.9696786], [.9696786],          $
;               [.6011176], [.6011176], [.9696786], [.9696786],          $
;               [.6011176], [.6011176], [.9696786], [.9696786],          $
;               [.6011176], [.6011176], [.9696786], [.9696786]]

      domega =  [.6011176, .6011176, .9696786, .9696786,          $
                  .6011176, .6011176, .9696786, .9696786,          $
                  .6011176, .6011176, .9696786, .9696786,          $
                  .6011176, .6011176, .9696786, .9696786]

   IF dat.ncomp GT 2 THEN BEGIN
      IF (where(dat.max2(*,1)-dat.min2(*,1) lt 0))(0) NE -1 THEN        $
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
;      denergy = (dat.max1 - dat.min1)
      denergy = FLOAT (REBIN(dat.max1-dat.min1, dat.dimsizes(0), dat.dimsizes(1)))
      mass1 = REFORM((dat.max3+dat.min3)/2., 1, dat.dimsizes(2))
      mass = FLOAT (REBIN(mass1, dat.dimsizes(0), dat.dimsizes(2)))
      dmass = FLOAT (REBIN((dat.max3 - dat.min3)/2.,  dat.dimsizes(2)))

;      domega = FLOAT (REBIN(domega1, dat.dimsizes(0), dat.dimsizes(1)))
      geom = FLOAT (REBIN(geom1, dat.dimsizes(0), dat.dimsizes(1)))
      sf = FLOAT (REBIN(spin_fract1,dat.dimsizes(0),dat.dimsizes(1)))

   ENDIF ELSE BEGIN 
      theta = REPLICATE(0.,dat.dimsizes(0), dat.dimsizes(1))
      dtheta = REPLICATE(0., dat.dimsizes(1))
      phi = REPLICATE(0., dat.dimsizes(0), dat.dimsizes(1))
      dphi = REPLICATE(0., dat.dimsizes(1))

      energy = REPLICATE(0.,dat.dimsizes(0), dat.dimsizes(1))
      denergy = REPLICATE(0., dat.dimsizes(0),dat.dimsizes(1))
      mass = REPLICATE(0.,dat.dimsizes(0), dat.dimsizes(2))
      dmass = REPLICATE(0., dat.dimsizes(2))

      geom = REPLICATE(0.,dat.dimsizes(0), dat.dimsizes(1))
      sf = REPLICATE(0.,dat.dimsizes(0), dat.dimsizes(1))

   ENDELSE

      pt_limits = [-90., -180., 90., 180.]

   eff = REPLICATE (1., dat.dimsizes(0), dat.dimsizes(1))
   geomfactor = 0.0015

   hdr_time = inputTime
   hdr_dat = get_fa_th_hdr (hdr_time)

   IF hdr_dat.valid EQ 0 THEN BEGIN
         print, 'Error getting Header bytes for this packet.  Bytes will be nil.'
         header_bytes = BYTARR(226)
   ENDIF ELSE BEGIN
         header_bytes = hdr_dat.bytes
   ENDELSE



;      hdr_time = inputTime
;      hdr_dat = get_fa_th_hdr (hdr_time)   ;Header quantity not found,   $ 
					    ;comended out by LT.

;      IF hdr_dat.valid EQ 0 THEN RETURN, {data_name: 'Null', valid: 0}
;         print, 'Error getting Header bytes for this packet.  Bytes will be nil.'
;         header_bytes = BYTARR(44)
;      ENDIF ELSE BEGIN
;        header_bytes = hdr_dat.bytes
;      ENDELSE

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
		 mbins:		dat.dimsizes(2),			      $
                 data: 		data,					      $
                 energy: 	energy, 				      $
                 theta: 	theta,                                        $
                 phi:   	phi,                                          $
                 geom: 		geom, 	       				      $
                 denergy: 	denergy,       				      $
                 dtheta: 	dtheta, 				      $
                 dphi:   	dphi,                                         $
                 domega:	domega,	 				      $
                 pt_limits:	pt_limits,				      $
                 eff: 		eff,					      $
                 mass: 		mass,					      $
                 dmass: 	dmass,					      $
                 geomfactor: 	geomfactor,				      $
		 spin_fract:    sf,					      $
                 header_bytes: 	header_bytes}

END 

