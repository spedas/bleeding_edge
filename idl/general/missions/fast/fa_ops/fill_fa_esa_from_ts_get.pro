;+
; FUNCTION:
; 	 FILL_FA_ESA_FROM_TS_GET
;
; DESCRIPTION:
;
;	Function to take a structure from get_md_ts_from_sdt that
;	contains Fast esa data, and return a array of structures in the
;	standard ssl idl esa format.
;
;
;	An array of npts structures of the following format are returned:
;
;	   DATA_NAME     STRING    'data-name'         ; Data Quantity name
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
;	   MASS          DOUBLE    5.68566e-6          ; Particle Mass
;	   GEOMFACTOR    DOUBLE    0.000147            ; Bin GF
;	   HEADER_BYTES  BYTE      Array(25)	       ; Header bytes
;	   INDEX         LONG      index               ; Data index, this pt. 
;	   ST_INDEX      LONG      st_idx              ; start index of arr
;	   EN_INDEX      LONG      en_idx              ; end index of arr
;	   NPTS          LONG      npts                ; array size
;	
; CALLING SEQUENCE:
;	data = fill_fa_esa_from_ts_get (dat, units, header_bytes,   
;                                            got_header_bytes, CALIBRATE=calib)
;
; ARGUMENTS:
;
;	dat			The data structure returned from
;				get_md_ts_from_sdt for esa data
;
;	units			The units of the data
;
;	header_bytes		The header bytes from the header
;				packets for the data in dat
;
; KEYWORDS:
;
;	CALIB			If non-zero, caclulate geometry
;				factors for each bin instead of using 1.'s
;
; RETURN VALUE:
;
;	Upon success, the above structure is returned, with the valid tag
;	set to 1.  Upon failure, the valid tag will be 0.
;
; REVISION HISTORY:
;
;	@(#)fill_fa_esa_from_ts_get.pro	1.4 02/10/98
; 	Originally written by Jonathan M. Loran,  University of 
; 	California at Berkeley, Space Sciences Lab.   Apr '97
;-

FUNCTION fill_fa_esa_from_ts_get, dat, units, header_bytes,    $
                                  got_header_bytes, CALIBRATE=calib


   ; get data values into correct dimensions here

   data_name = dat.data_name
   units_name = units
   IF (where(dat.max2-dat.min2 lt 0))(0) NE -1 THEN      $
     dat.max2(where(dat.max2-dat.min2 lt 0))=            $
     dat.max2(where(dat.max2-dat.min2 lt 0))+360

   theta = REPLICATE(1., dat.dimsizes(0), dat.dimsizes(1), dat.npts)
   energy = REPLICATE(1., dat.dimsizes(0), dat.dimsizes(1), dat.npts)
   denergy = REPLICATE(1., dat.dimsizes(0), dat.dimsizes(1), dat.npts)
   FOR i=0, dat.npts -1 DO BEGIN
     theta(*,*,i) = FLOAT (REPLICATE (1., dat.dimsizes(0)) #            $
                           ((dat.max2(*,i)+dat.min2(*,i))/2.) mod 360.)
     energy(*,*,i) = FLOAT (REBIN(([dat.max1(*,i)+dat.min1(*,i)])/2.,   $
                                  dat.dimsizes(0), dat.dimsizes(1)))
     denergy(*,*,i) = FLOAT (REBIN ([dat.max1(*,i) - dat.min1(*,i)],    $
                                    dat.dimsizes(0), dat.dimsizes(1)))
   ENDFOR

   dtheta = FLOAT (dat.max2 - dat.min2)

   if dat.dimsizes(0) GT 1 THEN   eff = REPLICATE (1., dat.dimsizes(0), dat.npts) $
   ELSE                           eff = 1.
   
   ; mcfadden: The following corrects for s/c spin during the sweep, will also 
   ; work for eesa/iesa survey as long as nswp_spin=32or64.
   ; NOTE: This will not work correctly for nswp_spin = 16.
   ; nswp_spin=3072/(dat.dimsizes(0)*2^(ishft((header_bytes(4) and 48),-4)))

     IF got_header_bytes AND                           $
       (data_name EQ 'Eesa Survey') OR                 $
       (data_name EQ 'Iesa Survey') OR                 $
       (data_name EQ 'Eesa Burst') OR                  $
       (data_name EQ 'Iesa Burst') THEN BEGIN
         FOR i=0, dat.npts -1 DO                       $
           theta(*,*,i) = theta(*,*,i) + ((180./(3072/(dat.dimsizes(0)*               $
                                         2^(ishft((header_bytes(4,i) and 48),-4)))))* $
                             (findgen(dat.dimsizes(0))-dat.dimsizes(0)/2+.5)/         $
                             (dat.dimsizes(0)/2.))#replicate(1.,dat.dimsizes(1))
     ENDIF

   ; get geometry factors

   IF NOT keyword_set(calib) THEN  $
       calib = getenv ('FAST_ESA_CALIBRATION')

   IF keyword_set(calib) AND got_header_bytes THEN BEGIN
       geom = FLTARR (dat.dimsizes(0), dat.dimsizes(1), dat.npts)
       geom_dec = FLOAT(REPLICATE (1., dat.dimsizes(0), dat.dimsizes(1)))
       FOR i=0, dat.npts-1 DO BEGIN
           g = calc_fa_esa_geom({data_name:	data_name,    $
                                 time:		dat.times(i), $
                                 header_bytes:	header_bytes(*,i)})
           IF g(0) GE 0 AND  $
             (n_elements(g) EQ dat.dimsizes(0) * dat.dimsizes(1)) THEN $
             geom(*,*,i) = reform(g, dat.dimsizes(0), dat.dimsizes(1)) $
           ELSE  BEGIN
               PRINT, 'Error getting geom factors for this packet.  Values will be 1.'
               geom(*,*,i) = REPLICATE (1., dat.dimsizes(0), dat.dimsizes(1))
           ENDELSE
       ENDFOR
   ENDIF ELSE  BEGIN
;       geom = FLOAT(REPLICATE (1., dat.dimsizes(0), dat.dimsizes(1)))
       geom = FLOAT(REPLICATE (1., dat.dimsizes(1),dat.npts))
       geom_dec = FLOAT(REPLICATE (1., dat.dimsizes(1)))
   ENDELSE

   ;  build array of return structs

   ret =						$
     REPLICATE( {data_name:	'name',				$
                 valid: 		1, 			$
                 project_name:	'FAST', 			$
                 units_name: 	'units', 			$
                 units_procedure:  'unknown', 			$
                 time: 		1.D, 				$
                 end_time: 	1.D, 				$
                 integ_t: 	1.D,				$
                 nbins: 	dat.dimsizes(1),	 	$
                 nenergy: 	dat.dimsizes(0), 		$
                 data: 		FLOAT(dat.values(*,*,0)),	$
                 energy: 	energy(*,*,0), 			$
                 theta: 	theta(*,*,0),  			$
                 geom: 		geom_dec,   			$
                 denergy: 	denergy(*,*,0),       		$
                 dtheta: 	dtheta(*,0), 			$
                 eff: 		eff(*,0), 			$
                 mass: 		1., 				$
                 geomfactor: 	1.,	 			$
                 header_bytes: 	header_bytes(*,0),		$
                 st_index:	1L,				$
                 en_index:	1L,				$
                 npts:		1L,				$
                 index:		1L},		$
                dat.npts)

   ; fill returned array

   ret.data_name	= dat.data_name
   ret.valid    	= 1
   ret.project_name	= 'FAST'
   ret.units_name	= units
   ret.units_procedure	= 'unknown'
   ret.time		= dat.times
   ret.end_time		= dat.endTimes
   ret.integ_t		= (dat.endTimes - dat.times)/dat.dimsizes(0)
   ret.nbins		= dat.dimsizes(1)
   ret.nenergy		= dat.dimsizes(0)
   ret.data		= dat.values
   ret.energy		= energy
   ret.theta		= theta
   ret.geom		= geom
   ret.denergy		= denergy
   ret.dtheta		= dtheta
   ret.eff		= eff
   ret.mass		= 1.
   ret.geomfactor	= 1.
   ret.header_bytes	= header_bytes
   ret.st_index		= dat.st_index
   ret.en_index		= dat.en_index
   ret.npts		= dat.npts
   IF dat.npts GT 1 THEN  ret.index = indgen(dat.npts) + dat.st_index $
   ELSE ret.index = dat.st_index

   RETURN, ret

END
