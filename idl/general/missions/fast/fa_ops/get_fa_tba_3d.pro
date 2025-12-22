;+
; FUNCTION:
; 	 GET_FA_TBH_3D
;
; DESCRIPTION:
;
;
;	function to load FAST Teams burst He++ species data from 
;	the call of routine get_fa_tba_eq to generate a 3D data.
;
;	A structure of the following format is returned:
;
;	   DATA_NAME     STRING    'Tms Burst Alpha'  ; Data Quantity name
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
;	   DOMEGA        FLOAT     ARRAY(nbins)
;	   SPIN_FRACT    FLOAT     ARRAY(nnrgs, nbins) ; Spin fraction of angles
;	   EFF           FLOAT     Array(nnrgs,nbins)  ; Efficiency (GF)
;	   MASS          DOUBLE    0.0104389           ; Mass eV/(km/sec)^2
;	   GEOMFACTOR    DOUBLE    0.0015              ; Bin GF
;	   HEADER_BYTES  BYTE      Array(25)	       ; Header bytes
;	   EFF_VERSION   FLOAT	   1.0		       ; Eff. calibration vers.
;	
; CALLING SEQUENCE:
;
; 	data = get_fa_tba_3d (time, [START=start | EN=en | ADVANCE=advance |
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
; CREATED BY:
;		 Li Tang   1/1/97      University of New Hampshire
;				       Space Physics Lab
;					tang@teams.sr.unh.edu
; MODIFICATION HISTORY:
;		 7/15/97  Keyword CALIB added	L.Tang
;-


FUNCTION Get_fa_tba_3d, inputTime, START=start, EN=en, ADVANCE=advance,  $
                         RETREAT=retreat, CALIB = calib

      magdir_offset = 0.0	;magnetic direction offset. need to change
      geomfactor = 0.0015
      swps=[32, 32, 64, 32, 64, 32, 64, 32, 64, 32]
      ; Get samples while dimensions are wrong

      index = find_handle('tba_time',tagname)
      IF index EQ 0 THEN BEGIN
	 dat = get_fa_tba(0, /st)
	 dat = get_fa_tba(dat.time, /ad)
	 t = dat.time
	 n = 0
      ENDIF ELSE BEGIN
	 get_data, 'tbp_time', data = last_time
	 t = last_time.end_time 
	 n = last_time.dat_pts	 
      ENDELSE

      dat0 = get_fa_tba(t, /ad)
      IF NOT dat0.valid THEN       RETURN, {data_name: 'Null', valid: 0}

      inputTime = dat0.time 
      sphase0 = dat0.header_bytes(0)+ISHFT(1*(dat0.header_bytes(1) AND 3B), 8)

      IF sphase0 LT 512 THEN mode=dat0.mode ELSE mode=last_time.mode
      dat = dat0
      nbins = 8*swps(mode)
      hfswps = swps(mode)/2
      spbin = FIX(swps(mode)*(sphase0/1024.)) - 1
      IF spbin EQ -1 THEN spbin = swps(mode)-1
      IF spbin LT hfswps THEN spbin2=spbin+ hfswps	$
      ELSE spbin2 = spbin-hfswps

      phibin = (spbin < spbin2)
      side = FIX(2*spbin/swps(mode))		; 0: high side, 1: low side

      end_time = dat0.end_time
      magdir = dat0.magdir
      data = FLTARR(dat0.nenergy, nbins)
      theta = FLTARR(dat0.nenergy, nbins)
      phi = FLTARR(dat0.nenergy, nbins)
      energy = REBIN(dat0.energy(*,0),  dat0.nenergy, nbins)
      denergy = REBIN(dat0.denergy(*,0),  dat0.nenergy, nbins)
      geom = REPLICATE(1., dat0.nenergy, nbins)

      eff = REPLICATE(1.,dat0.nenergy, nbins)

      dphi0 = 360./swps(mode)
      FOR pix =0, 15 DO BEGIN
	  phi_180 = 180*(pix/8)
	  pix1 = ABS(15*side - pix)
	  FOR phin = 0, hfswps-1 DO BEGIN
	      ang = pix1 + phin*16
	      theta(*,ang) = dat.theta(*,pix)
	      phi(*,ang) = (phin + 0.5)*dphi0 + phi_180
	      IF KEYWORD_SET(CALIB) THEN eff(*,ang) = dat.eff(*,pix)
	  ENDFOR
      ENDFOR

      newspin = 0
      next = 0
      last_spbin = -1

      WHILE (dat.valid EQ 1 AND NEXT EQ 0) DO BEGIN
        IF spbin NE last_spbin THEN BEGIN
	   FOR pix = 0,15 DO data(*,ABS(15*side-pix)+phibin*16)=dat.data(*,pix)
           end_time = dat.time
	   magdir = dat.magdir
        ENDIF

	last_spbin = spbin

	dat = get_fa_tba(dat.time, /ad)

	IF dat.valid EQ 1 THEN BEGIN
           sphase = dat.header_bytes(0)+ISHFT(1*(dat.header_bytes(1) AND 3B), 8)
           spbin = FIX(swps(mode)*(sphase/1024.)) - 1
           IF spbin EQ -1 THEN spbin = swps(mode)-1

           IF spbin LT hfswps THEN spbin2=spbin+ hfswps	$
           ELSE spbin2 = spbin-hfswps
	   
	   phibin = (spbin < spbin2)

	   IF last_spbin LT hfswps AND spbin GE hfswps THEN next = 1	$
	   ELSE IF last_spbin GE hfswps AND spbin LT hfswps THEN next = 1

	   IF (dat.time - end_time) GE 3. THEN next = 1

	ENDIF

      ENDWHILE
      n = n + 1

      datstr = {time:inputTime, end_time: end_time, dat_pts: n, mode:mode}
      store_data, 'tba_time', data = datstr

      magdir = ((dat0.magdir + magdir)/2) MOD 360.
      
      spin_fract = FLOAT(REPLICATE(1./hfswps, dat0.nenergy, nbins))
      dtheta =  FLOAT(REPLICATE (22.5, nbins))
      dphi =  FLOAT(REPLICATE (dphi0, nbins))
;      pt_limits = [-90., -180., 90., 180.]
      pt_limits = [-90., 0., 90., 360.]

       RETURN,  {data_name:	dat0.data_name, 			      $
                 valid: 	1, 					      $
                 project_name:	'FAST',					      $
                 units_name: 	dat0.units_name, 			      $
                 units_procedure: dat0.units_procedure,			      $
                 time: 		inputTime,				      $
                 end_time: 	end_Time, 			              $
                 integ_t: 	(dat.end_time-dat0.time)/dat0.nenergy,        $
                 nbins: 	nbins,	 			     	      $
                 mbins: 	1,	 			     	      $
                 nenergy: 	dat0.nenergy, 			              $
                 data: 		data,					      $
                 energy: 	energy, 				      $
                 theta: 	theta,                                        $
                 phi: 		phi,                                          $
                 geom: 		geom,	 	       			      $
                 denergy: 	denergy, 	    			      $
                 dtheta: 	dtheta, 				      $
                 dphi: 		dphi, 					      $
                 domega: 	REPLICATE(4*!pi/nbins,nbins), 		      $
		 pt_limits:     pt_limits, 				      $
                 eff: 		eff,					      $
		 spin_fract:	spin_fract,				      $
                 mass: 		dat0.mass,				      $
                 geomfactor: 	dat0.geomfactor,			      $
                 header_bytes: 	dat0.header_bytes,			      $
		 eff_version:   dat0.eff_version}

; eff needs to be modified.		12-06-96 LT
; domega needs to be changed.		1/1/97  LT

END 
