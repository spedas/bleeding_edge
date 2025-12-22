;+
;PROCEDURE:	get_tms_hm_spec
;PURPOSE:	
;	Generates energy-time spectrogram data structures for tplot
;INPUT:		
;	data_str, 	a string (either 'th_3d','ess', ...)
;			where get_'string' returns a 2D(if input is 3D) or
;			1D(input is 2D) mass data structure
;KEYWORDS:		
;	STIME:		'1996-10-09/12:23:34'	time to start
;	TSPAN:		seconds			time span
;	ENERGY:		fltarr(2)		energy range to sum over
;	ERANGE:		intarr(2)		energy bin range to sum over
;	EBINS:		bytarr(dat.nenergy)	energy bins to sum over
;	ANGLE:		fltarr(2),fltarr(4)	angle range to sum over
;	ARANGE:		intarr(2)		bin range to sum over
;	BINS:		bytarr(dat.nbins)	bins to sum over
;	gap_time: 	time gap big enough to signIFy a data gap 
;			(default 200 sec, 9 sec for FAST)
;	NO_DATA: 	returns 1 IF no_data ELSE returns 0
;	UNITS:		convert to these units IF included
;	NAME:  		New name of the Data Quantity
;	BKG:  		A 3d data structure containing the background counts.
;	FLOOR:  	Sets the minimum value of any data point to sqrt(bkg).
;	MISSING: 	Value for bad data.
;
;CREATED BY:	Li Tang     Univ. of New Hampshire
;			    Space Physics Lab		tang@teams.sr.unh.edu
;VERSION:	3.0
;LAST MODIFICATION:  96-10-17
;MOD HISTORY:  96-8-20  Added ASUM and ESUM keywords  - LT
;	       96-9-27  removed asum, esum, aweight, eweight, and etc     LT
;	       96-11-4 Able to deal with 2D data type			  LT 
;	       97-3-21  Change pitch angle calculation. 		  LT
;	       97-3-30  changed the aweight for 2D structure		  LT
;NOTES:	  
;	Current version only works for FAST
;-

PRO get_tms_hm_spec,data_str,  		$
		Time0=time0,		$
		T1=t1,			$
		T2=t2,			$
		TSPAN=tspan,		$
	  	ENERGY=en, 		$
		ERANGE=er, 		$
		EBINS=ebins, 		$
		ANGLE=an, 		$
		ARANGE=ar, 		$
		BINS=bins, 		$	
		gap_time=gap_time, 	$ 
		no_data=no_data, 	$
		units = units,  	$
 	     	name  = name, 		$
		bkg = bkg, 		$
        	missing = missing, 	$
        	floor = floor, 		$
        	retrace = retrace, 	$
		CALIB=calib


;	Time how long the routine takes
   ex_start = systime(1)

   n = 0
   max = 1000       ; this could be improved
   all_same = 1

   data_str = STRLOWCASE(data_str)
   routine = 'get_'+data_str 

   t = 10             ; get first sample
   dat = call_function(routine, t, /start, calib=calib)

   IF not dat.valid THEN BEGIN 
	no_data = 1 
	PRINT, 'No data found'
	RETURN
   ENDIF ELSE no_data = 0

   IF KEYWORD_SET(TIME0) THEN t1=time0
   IF KEYWORD_SET(t2) AND KEYWORD_SET(t1) THEN tspan = str_to_time(t2) - str_to_time(t1)
   IF NOT KEYWORD_SET(TSPAN) THEN tspan = 86400
   IF KEYWORD_SET(t2) AND KEYWORD_SET(tspan) THEN t1=time_to_str(str_to_time(t2) - tspan)

   IF KEYWORD_SET(t1) THEN BEGIN
	t = MAX([dat.time, str_to_time(t1)])
	IF str_to_time(t1)+tspan LT dat.time THEN BEGIN
	   PRINT,"No data found in your selected time range:",t1, '--',time_to_str(str_to_time(t1)+tspan),".  Data starts at ",$ 
		time_to_str(dat.time), "."
	   RETURN
	ENDIF ELSE dat = call_function(routine, t, calib=calib)
   ENDIF ELSE t1 = time_to_str(dat.time)

   IF NOT KEYWORD_SET(t2) THEN tmax=str_to_time(t1)+tspan ELSE tmax=str_to_time(t2)


   ytitle = data_str + '_tms_hm_spec'
   last_time = dat.time
   nenergy = dat.nenergy

   dimension = ndimen(dat.data)
   IF dimension LT 2 THEN BEGIN 
	PRINT,'Incorrect data type. Data must be 2D or 3D type'
	RETURN
   ENDIF
   IF dimension EQ 3 THEN BEGIN
      nmaxvar = dat.mbins
      nvar = dat.mbins 
   ENDIF ELSE BEGIN
      nmaxvar = 1
      nvar = 1
   ENDELSE

   default_gap_time = 120

   IF NOT keyword_set(gap_time) THEN gap_time = default_gap_time

   good_idx = REPLICATE(1, max+2) ; 2 is for the consideration   
   time   = dblarr(max+2)	         ; of the increasingof n in data gap
   endtime   = dblarr(max+2)
   data   = DBLARR(max+2,nmaxvar)
   var   = fltarr(max+2,nmaxvar) 
   nmax=nvar

   IF NOT keyword_set(units) THEN units = 'Counts'
   IF NOT keyword_set(missing) THEN missing = !values.f_nan

   units = STRLOWCASE(units)
 
; 	the following assumes that theta increases with bin number
;	needs modIFication for WIND to use ANGLE keyword

	
   IF keyword_set(en) THEN  er=energy_to_ebin(dat,en)
   
   IF keyword_set(er) THEN BEGIN
	ebins=bytarr(dat.nenergy)
	IF er(0) GT er(1) THEN er=reverse(er)
	ebins(er(0):er(1))=1
   ENDIF
   IF not keyword_set(ebins) THEN BEGIN
	ebins=bytarr(dat.nenergy)
	ebins(*)=1
   ENDIF
	
   IF keyword_set(retrace) then ebins(0:retrace-1)=0
   eind=WHERE(ebins,ecount)

   IF eind(0) EQ -1 THEN BEGIN
 	PRINT, 'No energies selected. Please select correct energies.'
	RETURN
   ENDIF


;	Collect the data - Main Loop

str_element, dat, "phi", index=ind_3d	;check if its 3d structure. 3/30

   WHILE (dat.valid ne 0) AND (n lt max) DO BEGIN

	if keyword_set(an) then bins=angle_to_bins(dat,an)

	if keyword_set(ar) then begin
		nb=dat.nbins
		bins=bytarr(nb)
		if ar(0) gt ar(1) then begin
			bins(ar(0):nb-1)=1
			bins(0:ar(1))=1
		endif else begin
			bins(ar(0):ar(1))=1
		endelse
	endif

; Set the "acount" to the number of bins summed over
      IF not keyword_set(bins) THEN bins = REPLICATE(1, dat.nbins) 

      aind=where(bins,acount)
      IF aind(0) EQ -1 THEN BEGIN 
         PRINT, 'No angles selected. Please select correct angles.'
         RETURN
      ENDIF

   	aweight = FLTARR(dat.nenergy, dat.nbins)
   	eweight = FLTARR(dat.nenergy, dat.nbins)
   	weight = FLTARR(dat.nenergy, dat.nbins)

       IF units EQ 'counts' OR units EQ 'rate' THEN BEGIN 
          anorm = 1
          aweight(*, aind) = 1
       ENDIF ELSE BEGIN
	IF ind_3d GE 0 THEN BEGIN
	   domega = dat.domega
	   IF ndimen(domega) EQ 1 THEN domega=REPLICATE(1,d.nenergy)#domega
	ENDIF ELSE domega = get_2d_domega(dat)

          anorm = TOTAL(domega(0, aind))
          aweight(*, aind) = domega(*,aind)
       ENDELSE

       IF units EQ 'flux' THEN BEGIN
	   enorm=TOTAL(dat.denergy(eind))
	   eweight(eind, *) = dat.denergy(eind, *)
       ENDIF ELSE BEGIN
	   enorm = 1.
	   eweight(eind, *) = 1.
       ENDELSE
	   
       weight = aweight*eweight
       norm = anorm*enorm	   


	IF keyword_set(bkg) THEN dat = sub3d(dat,bkg)
 	dat = conv_units(dat,units)

	IF n GE 1 THEN BEGIN
	 IF (dat.time - endtime(n-1)) GE gap_time THEN BEGIN
;	   use 5 sec - the FAST spin period
	   dbadtime = MIN([20.,gap_time/2.-.1])
	   time(n) = endtime(n-1) + dbadtime
	   endtime(n) = dat.time - dbadtime
print, 'data gap: ', n,'  ', time_to_str(time(n)), '---', time_to_str(endtime(n)) , '  ', endtime(n) - time(n)
	   data(n,*) = missing
	   var(n,*) = var(n-1,*)
	   good_idx(n) = 0
	   n=n+1
	   time(n) = endtime(n-1)
	   endtime(n) = dat.time
print, 'data gap: ', n,'  ', time_to_str(time(n)), '---', time_to_str(endtime(n)) , '  ', endtime(n) - time(n)
	   data(n,*) = missing
	   var(n,*) = var(n-1,*)
	   good_idx(n) = 0
	   n=n+1
	   good_idx(n) = 0	; because of the bug of the 1st data
				; accumulation time(see idl_himass_data_gap.bug)
				; this data point is not good.  LT 10/02/96
	 ENDIF
	ENDIF


	time(n)   = dat.time
	endtime(n)   = dat.end_time

        IF dimension EQ 3 THEN BEGIN
	   nvar = dat.mbins
	   IF nvar GT nmax THEN nmax = nvar
      	   tmpdata = DBLARR(dat.mbins)

       	   FOR mbin = 0, (dat.mbins-1) DO BEGIN				   
	      tmpdata(mbin) = TOTAL( dat.data(*,*,mbin)*weight(*,*))   
	   ENDFOR
	   tmpvar = TOTAL( dat.mass(0,*), 1)
;	   tmpdata = TOTAL(tmpdata1, 1)
	   tmpdata = tmpdata/norm
; 	   ShIFt the mass array so that mass increase monotonicly 
;	   with index -- needed for tplot
	   minvar = MIN(tmpvar,indminvar)
	   var(n,0:nvar-1) = SHIFT(tmpvar,-indminvar)
	   data(n,0:nvar-1) = SHIFT(tmpdata,-indminvar)
	ENDIF ELSE BEGIN
	   var(n,0) = 1.
	   data(n,0) = TOTAL(dat.data*weight)/norm
	ENDELSE



;Following two lines do not make sense.  nvar always GE nmaxvar!!   lt 9/17/96

	IF nvar lt nmaxvar THEN data(n,nvar:nmaxvar-1) = data(n,nvar-1)
	IF nvar lt nmaxvar THEN var(n,nvar:nmaxvar-1) = 1.5*var(n,nvar-1)-.5*var(n,nvar-2)

	IF (all_same EQ 1) THEN BEGIN			;???? 9/17/96
	   IF dimen1(where(var(n,0:nvar-1) ne var(0,0:nvar-1))) gt 1 THEN all_same = 0
	ENDIF

	n=n+1
	last_time = dat.time

	dat = call_function(routine,t,/ad, calib=calib)

        IF dat.valid EQ 1 THEN  IF dat.time GT tmax THEN dat.valid=0

   ENDWHILE


;	Store the data


   data = data(0:n-1,0:nmax-1)
   var = var(0:n-1,0:nmax-1)

   PRINT,'all_same=',all_same
   labels =''

   time = time(0:n-1)
   endtime = endtime(0:n-1)
   good_idx = good_idx(0:n-1)

   ex_time = systime(1) - ex_start
   message,string(ex_time)+' seconds execution time.',/cont,/info
   PRINT,'Number of data points = ',n

   IF dimension EQ 3 THEN BEGIN
      datstr = { name:	'fast_tms_himass', 	$
	      units:	units,			$	
	      valid:	1,			$
	      x:  	time, 			$
	      x1:	endtime, 		$
	      good_idx:	good_idx, 		$
	      y:	data, 			$
	      v:	var, 			$
	      ytype:    1,			$
;	      labels:   'test',			$
	      panel_size:2.}
   ENDIF ELSE BEGIN
      datstr = {name:	data_str, 		$
	        units:	units,			$
		x:	time,			$
		y:	data,			$
		ytype:	1,			$
	        good_idx: good_idx, 		$
		labels:	labels,			$
		spec:	0,			$
		panel_size:	2.}
   ENDELSE

   store_data,name,data=datstr

   print, 'stored himass handle name= ', name


   END




; The calculation of rate, counts was carefully checked on 10/03/96. OK.
