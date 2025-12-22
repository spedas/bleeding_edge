;+
; FUNCTION:
; 	 GET_FA_TB_3D_EQ
;
; DESCRIPTION:
;
;
;	function to load FAST Teams burst H+, O+, He++, He+ species data from 
;	the call of routine get_fa_tb_eq to generate a 3D data in instrument
;	equatorial plane.
;
;	A structure of the following format is returned:
;
;	   DATA_NAME     STRING    'Tms Burst Data'  ; Data Quantity name
;	   VALID         INT       1                   ; Data valid flag
; 	   PROJECT_NAME  STRING    'FAST'              ; project name
; 	   UNITS_NAME    STRING    'Counts'            ; Units of this data
; 	   UNITS_PROCEDURE  STRING 'proc'              ; Units conversion proc
;	   TIME          DOUBLE    8.0118726e+08       ; Start Time of sample
;	   END_TIME      DOUBLE    7.9850884e+08       ; End time of sample
;	   INTEG_T       DOUBLE    3.0000000           ; Integration time
;	   NBINS         INT       nbins               ; Number of angle bins
;	   NENERGY       INT       nnrgs               ; Number of energy bins
;	   DATA          FLOAT     Array(nnrgs, nbins,mbins) ; Data qauantities
;	   ENERGY        FLOAT     Array(nnrgs, nbins) ; Energy steps
;	   THETA         FLOAT     Array(nnrgs, nbins) ; Angle for bins
;	   GEOM          FLOAT     Array(nbins)        ; Geometry factor
;	   DENERGY       FLOAT     Array(nnrgs, nbins) ; Energies for bins
;	   DTHETA        FLOAT     Array(nbins)        ; Delta Theta
;	   SPIN_FRACT    FLOAT     ARRAY(nnrgs, nbins) ; Spin fraction of angles
;	   EFF           FLOAT     Array(nnrgs,nbins,mbins)  ; Efficiency (GF)
;	   MASS          DOUBLE    ARRAY(4)            ; Mass eV/(km/sec)^2
;	   GEOMFACTOR    DOUBLE    0.0015              ; Bin GF
;	   HEADER_BYTES  BYTE      Array(25)	       ; Header bytes
;	   EFF_VERSION   FLOAT	   1.0		       ; Eff. calibration vers.
;	
; CALLING SEQUENCE:
;
; 	data = get_fa_tb_3d_eq (time, [START=start | EN=en | ADVANCE=advance |
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
;		 Li Tang   11/2/96      University of New Hampshire
;					Space Physics Lab
; MOD. HISTORY:	
;		7/25/97	 recalculated pitch angle	LT
;-


FUNCTION Get_fa_tb_3d_eq, inputTime, START=start, EN=en, ADVANCE=advance,  $
                         RETREAT=retreat, CALIB=calib

      magdir_offset = 0.0	;magnetic direction offset. need to change
      geomfactor = 0.0015
      swps=[32, 32, 64, 32, 64, 32, 64, 32, 64, 32]
      ; Get samples while dimensions are wrong

      index = find_handle('tb_time',tagname)
      IF index EQ 0 THEN BEGIN
	 dat = get_fa_tb_eq(inputTime,start=start,EN=en,AD=advance,RETR=retreat)
	 t = dat.time
	 n = 0
      ENDIF ELSE BEGIN
	 get_data, 'tb_time', data = last_time
	 IF last_time.valid NE 0 THEN BEGIN
	   t = last_time.end_time 
	   n = last_time.dat_pts	
	   dat=get_fa_tb_eq(t,/ad)
         ENDIF ELSE BEGIN
	   dat=get_fa_tb_eq(inputTime,start=start,EN=en,AD=advance,RETR=retreat)
	   t = dat.time
	   n = 0
         ENDELSE
      ENDELSE
      dat0 = dat	
      IF NOT dat.valid THEN       RETURN, {data_name: 'Null', valid: 0}

      inputTime = dat0.time 
      sphase0 = dat.header_bytes(0)+ISHFT(1*(dat.header_bytes(1) AND 3B), 8)
      IF sphase0 LT 512 OR index EQ 0 THEN mode=dat.mode ELSE mode=last_time.mode

      hfswps = swps(mode)/2
      spbin = dat.spbin
      spbin2 = dat.spbin2
      end_time = dat.end_time
      magdir = dat.magdir
      data = FLTARR(dat.nenergy, swps(mode), dat.mbins)
      theta = FLTARR(dat.nenergy, swps(mode))  
      energy = REBIN(dat.energy(*,0),  dat.nenergy, swps(mode))
      denergy = REBIN(dat.denergy(*,0),  dat.nenergy, swps(mode))
      geom = REPLICATE(1., dat0.nenergy, swps(mode))

      eff = FLTARR(dat.nenergy, swps(mode), dat.mbins)

      theta(*,spbin) = dat.theta(*,0)
      theta(*,spbin2) = dat.theta(*,1)

      IF sphase0 LT 512 THEN BEGIN		; these lines need to check.
	 FOR anbin = 0, hfswps-1 DO BEGIN	; 7/24/97
	     eff(*,anbin,*) = dat.eff(*,0,*)
	     eff(*,anbin+hfswps,*) = dat.eff(*,1,*)
	 ENDFOR
      ENDIF ELSE BEGIN
	 FOR anbin = 0, hfswps-1 DO BEGIN
	     eff(*,anbin,*) = dat.eff(*,1,*)
	     eff(*,anbin+hfswps,*) = dat.eff(*,0,*)
	 ENDFOR
      ENDELSE

      newspin = 0
      next = 0
      last_spbin = -1

      WHILE (dat.valid EQ 1 AND NEXT EQ 0) DO BEGIN
        IF dat.spbin NE last_spbin THEN BEGIN
	   data(*,dat.spbin,*) = dat.data(*, 0,*)
	   data(*,dat.spbin2,*) = dat.data(*, 1,*)
           end_time = dat.time
	   magdir = dat.magdir
        ENDIF
	last_spbin = dat.spbin

	dat = get_fa_tb_eq(dat.time, /ad)

	IF dat.valid EQ 1 THEN BEGIN
	   IF last_spbin LT hfswps AND dat.spbin GE hfswps THEN next=1   $
	   ELSE IF last_spbin GE hfswps AND dat.spbin LT hfswps THEN next=1
	   IF (dat.time - end_time) GE 5. THEN next = 1
	   theta(*,dat.spbin) = dat.theta(*,0)
	   theta(*,dat.spbin2) = dat.theta(*,1)

	ENDIF

      ENDWHILE

	n = n + 1

      datstr={time:inputTime, end_time:end_time, dat_pts:n, mode:mode, valid:1}
      store_data, 'tb_time', data = datstr

      sf = 1./hfswps
      spin_fract = FLOAT(REPLICATE(sf, dat0.nenergy, swps(mode)))
      dth = 360./swps(mode)
      dtheta =  FLOAT(REPLICATE (dth, swps(mode)))

      tbp_data = {data_name:	dat0.data_name, 			      $
                 valid: 	1, 					      $
                 project_name:	'FAST',					      $
                 units_name: 	dat0.units_name, 			      $
                 units_procedure: dat0.units_procedure,			      $
                 time: 		inputTime,				      $
                 end_time: 	end_Time, 			              $
                 integ_t: 	(end_time-dat0.time)/dat0.nenergy,            $
                 nbins: 	swps(mode), 			     	      $
                 mbins: 	dat0.mbins, 			     	      $
                 nenergy: 	dat0.nenergy, 			              $
                 data: 		data,					      $
                 energy: 	energy, 				      $
                 theta: 	theta,                                        $
                 geom: 		geom, 	       				      $
                 denergy: 	denergy,     				      $
                 dtheta: 	dtheta, 				      $
                 eff: 		eff,					      $
		 spin_fract:	spin_fract,				      $
                 mass: 		dat0.mass,				      $
                 geomfactor: 	dat0.geomfactor,			      $
                 header_bytes: 	dat0.header_bytes,			      $
		 eff_version:   dat0.eff_version}


RETURN, tbp_data

END 
