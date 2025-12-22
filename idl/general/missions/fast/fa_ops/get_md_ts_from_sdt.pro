;+
; FUNCTION:
; 	 GET_MD_TS_FROM_SDT
;
; DESCRIPTION:
;
;	function to load generic multi dimensional data time series
;	from the SDT program shared memory buffers.
;
;	A structure of the following format is returned:
;
;	   DATA_NAME     STRING    'QTY'                ; Data Quantity name
;	   VALID         INT       1                    ; Data valid flag
;	   START_TIME    DOUBLE    8.0118726e+08        ; Start Time of sample
;	   END_TIME      DOUBLE    7.9850884e+08        ; End time of sample
;	   NPTS          INT       npts                 ; Number of time samples
;          TIMES         DOUBLE    Array(npts)          ; start timetags
;          ENDTIMES      DOUBLE    Array(npts)          ; end timetags
;	   INTEG_T       DOUBLE    array(npts)          ; Integration time
;          CALIBRATED    LONG      calibrated           ; flags calibrated data
;          CALIBRATED_UNITS STRING units                ; calibrated units string
;	   VALUES        <TYPE>    Array(dimsizes(0..3)); Data qauantities
;	   NDIMS         LONG      ndims                ; Number of data dimensions
;	   DIMSIZES      LONG      dimsizes(3)          ; Sizes of each dimension
;	   NCOMP         LONG      ncomp                ; number of data components
;	   NMINMAX       LONG       array(ndims)         ; number of array desc(dim)
;	   MIN1          DOUBLE    array(dimsizes(0),npts) ; Array desc min (0)
;	   MAX1          DOUBLE    array(dimsizes(0),npts) ; Array desc max (0)
;	   MIN2          DOUBLE    array(dimsizes(1),npts) ; Array desc min (1)
;	   MAX2          DOUBLE    array(dimsizes(1),npts) ; Array desc max (1)
;	   MIN3          DOUBLE    array(dimsizes(2),npts) ; Array desc min (2)
;	   MAX3          DOUBLE    array(dimsizes(2),npts) ; Array desc max (2)
;	   ST_INDEX      LONG      stidx                ; index of 1st pt in sdt
;	   EN_INDEX      LONG      enidx                ; index of last pt in sdt
;	
; CALLING SEQUENCE:
;
;	data = get_md_ts_from_sdt (data_name, sat_code, t1=time1, t2=time2, 
;				[NPTS=npts], [START=st | EN=en | 
;				PANF=panf | PANB=panb | IDXST=startidx])
; ARGUMENTS:
;
;	data_name		The SDT data quantity name
;	sat_code		The SDT satellite code
;
; KEYWORDS:
;
;	t1 			This argument gives the start time from
;				which to take data, or, if START or EN keywords
;				are non-zero, the length of time to take data.
;				It may be either a string with the following
;				possible formats:
;					'YY-MM-DD/HH:MM:SS.MSC'  or
;					'HH:MM:SS'     (use reference date)
;				or a number, which will represent seconds
;				since 1970 (must be a double > 94608000.D), or
;				a hours from a reference time, if set.
;
;				Time will always be returned as a double
;				representing the actual data start time found 
;				in seconds since 1970.
;
;	t2			The same as time1, except it represents the
;				end time.
;
;				If the NPTS, START, EN, PANF or PANB keywords 
;				are non-zero, THEN time2 will be ignored as an
;				input paramter.
;
;	Data time selection is determined from the keywords as given in the 
;	following truth table (NZ == non-zero, DF == defined):
;
; |ALL |NPTS |START| EN  |IDXST|PANF |PANB |selection            |use time1|use time2|
; |----|-----|-----|-----|-----|-----|-----|---------------------|---------|---------|
; | NZ |  0  |  0  |  0  |  0  |  0  |  0  | start -> end        |  X      |  X      |
; | 0  |  0  |  0  |  0  |  0  |  0  |  0  | time1 -> time2      |  X      |  X      |
; | 0  |  0  |  NZ |  0  |  0  |  0  |  0  | start -> time1 secs |  X      |         |
; | 0  |  0  |  0  |  NZ |  0  |  0  |  0  | end-time1 secs ->end|  X      |         |
; | 0  |  0  |  0  |  0  |  0  |  NZ |  0  | pan fwd from        |  X      |  X      |
; |    |     |     |     |     |     |     |   time1->time2      |         |         |
; | 0  |  0  |  0  |  0  |  0  |  0  |  NZ | pan back from       |  X      |  X      |
; |    |     |     |     |     |     |     |   time1->time2      |         |         |
; | 0  |  NZ |  0  |  0  |  0  |  0  |  0  | time1 -> time1+npts |  X      |         |
; | 0  |  NZ |  NZ |  0  |  0  |  0  |  0  | start -> start+npts |         |         |
; | 0  |  NZ |  0  |  NZ |  0  |  0  |  0  | end-npts -> end     |         |         |
; | 0  |  NZ |  0  |  0  |  DF |  0  |  0  | st-index ->         |         |         |
; |    |     |     |     |     |     |     |   st_index + npts   |         |         |
;	Any other combination of keywords is not allowed.
;
; RETURN VALUE:
;
;	Upon success, the above structure is returned, with the valid tag
;	set to 1.  Upon failure, the valid tag will be 0.
;
; REVISION HISTORY:
;
;	@(#)get_md_ts_from_sdt.pro	1.3 05/30/97
; 	Originally written by Jonathan M. Loran,  University of 
; 	California at Berkeley, Space Sciences Lab.   Mar '97
;-

FUNCTION Get_md_ts_from_sdt, data_name, sat_code, t1=time1, t2=time2, NPTS=npts,    $
                          START=st, EN=en, PANF=pf, PANB=pb, ALL=all, IDXST=idxst

   ; only certain keyword can be set together.  Check this out and
   ; set selectionMode

   nkeys = 0
   IF KEYWORD_SET (st)   THEN          $
      nkeys = nkeys + 1 
   IF KEYWORD_SET (en)   THEN          $
      nkeys = nkeys + 4 
   IF KEYWORD_SET (npts) THEN          $
      nkeys = nkeys + 8
   IF KEYWORD_SET (pf)   THEN          $
      nkeys = nkeys + 16
   IF KEYWORD_SET (pb)   THEN          $
      nkeys = nkeys + 32
   IF KEYWORD_SET (all)  THEN          $
      nkeys = nkeys + 64
   IF N_ELEMENTS (idxst) GT 0 THEN     $   ; handle index of zero
      nkeys = nkeys + 128

                                ;  Note that 99 is a special selection
                                ;  mode: ALL
   CASE nkeys OF
      0:   BEGIN selectionMode = 3L & t1used=1 & t2used=1 & END 
      1:   BEGIN selectionMode = 7L & t1used=1 & t2used=0 & END 
      4:   BEGIN selectionMode = 10L& t1used=1 & t2used=0 & END 
      16:  BEGIN selectionMode = 4L & t1used=1 & t2used=1 & END 
      32:  BEGIN selectionMode = 4L & t1used=1 & t2used=1 & END 
      8:   BEGIN selectionMode = 5L & t1used=1 & t2used=0 & END 
      9:   BEGIN selectionMode = 8L & t1used=0 & t2used=0 & END 
      12:  BEGIN selectionMode = 11L& t1used=0 & t2used=0 & END 
      64:  BEGIN selectionMode = 99L& t1used=0 & t2used=0 & END 
      136: BEGIN selectionMode = 12L& t1used=0 & t2used=0 & END 
      ELSE: BEGIN 
         PRINT, '@(#)get_md_ts_from_sdt.pro	1.3 : Illegal combination of keywords'
         RETURN, {data_name: 'Null', valid: 0}
      END 
   ENDCASE 

   ; parse out the input times into seconds since 1970

   IF t1used THEN BEGIN
      IF NOT KEYWORD_SET(st) AND NOT KEYWORD_SET(en) THEN secs1970_1 = gettime(time1)$
        ELSE IF N_ELEMENTS(time1) GT 0 THEN secs1970_1 = time1                       $
        ELSE BEGIN ; format error in date1
         PRINT, '@(#)get_md_ts_from_sdt.pro	1.3 : Invalid input time1: '
         RETURN, {data_name: 'Null', valid: 0}
      ENDELSE 
   ENDIF 

   IF t2used THEN BEGIN
      IF N_ELEMENTS(time2) GT 0 THEN                       $
        secs1970_2 = gettime(time2)                        $
        ELSE BEGIN              ; format error in date2
         PRINT, '@(#)get_md_ts_from_sdt.pro	1.3 : Invalid input time2'
         RETURN, {data_name: 'Null', valid: 0}
      ENDELSE
   ENDIF 

   ; take care of special panning/start/end cases

   IF KEYWORD_SET(pf) THEN BEGIN
      deltime = secs1970_2 - secs1970_1
      secs1970_1 = secs1970_2
      secs1970_2 = deltime
   ENDIF 
   IF KEYWORD_SET(pb) THEN BEGIN
      deltime = secs1970_2 - secs1970_1
      secs1970_1 = secs1970_1 - deltime
      secs1970_2 = deltime
   ENDIF 
   IF nkeys EQ 1 OR nkeys EQ 4 THEN BEGIN
      secs1970_2 = secs1970_1
   ENDIF 

   ; initialize times and dates

   secs1 = 0L
   secs2 = 0L
   year1 = 0L
   year2 = 0L
   month1 = 0L
   month2 = 0L
   day1 = 0L
   day2 = 0L
   
   ; get seconds of day
   
   IF t1used THEN secs1 = secs1970_1 MOD 86400.D         ; extract seconds of day 1
   IF t2used THEN secs2 = secs1970_2 MOD 86400.D         ; extract seconds of day 2

   ; date portions seperated
   
   IF t1used THEN BEGIN 
      date_st_1 = datestruct(secdate(secs1970_1)) ; separate out date components
      year1 = LONG (date_st_1.year)
      month1 = LONG (date_st_1.month)
      day1 = LONG (date_st_1.monthday)
   ENDIF 

   IF t2used THEN BEGIN 
      date_st_2 = datestruct(secdate(secs1970_2)) ; separate out date components
      year2 = LONG (date_st_2.year)
      month2 = LONG (date_st_2.month)
      day2 = LONG (date_st_2.monthday)
   ENDIF    


   values = FLTARR (1)
   narrdesc = LONARR(3)
   min1 = DBLARR (1)
   max1 = DBLARR (1)
   min2 = DBLARR (1)
   max2 = DBLARR (1)
   min3 = DBLARR (1)
   max3 = DBLARR (1)
   ndims = 1L
   dimsizes = LONARR (3)
   ncomp = 1L
   type = 1L
   calibrated = 0L
   calibrated_units = bytarr(64)

   IF N_ELEMENTS (npts) GT 0 THEN  npts = LONG(npts) $
     ELSE npts = 0L

   callTimes = 1D       ; will be timetags
   endCallTimes = 1D    ; will be endtimetags

   ; set up call times, set time2 to time1
   ; if necessary
   
   callYear1 = year1
   callMonth1 = month1
   callDay1 = day1
   callSecs1 = secs1
   IF nkeys EQ 1 OR           $
     nkeys EQ 4  OR           $
     nkeys EQ 9  OR           $
     nkeys EQ 12 THEN BEGIN 
      callYear2 = year1
      callMonth2 = month1
      callDay2 = day1
      callSecs2 = secs1
   ENDIF ELSE BEGIN 
      callYear2 = year2
      callMonth2 = month2
      callDay2 = day2
      callSecs2 = secs2
   ENDELSE
   IF nkeys EQ 136 THEN  BEGIN
       st_idx = LONG(idxst) 
       en_idx = LONG(idxst + npts - 1)
   ENDIF ELSE BEGIN
       st_idx = 0L
       en_idx = 0L
   ENDELSE
   stindex = st_idx
   enindex = en_idx

   len = CALL_EXTERNAL ('loadSDTBufLib.so', 'getTimeSeriesFromSDTMD',       $
                        LONG(sat_code),					   $
                        data_name, 					   $
                        callYear1, 					   $
                        callMonth1, 					   $
                        callDay1, 					   $
                        callSecs1, 					   $
                        callYear2, 					   $
                        callMonth2, 					   $
                        callDay2, 					   $
                        callSecs2, 					   $
                        callTimes,					   $
                        endCallTimes,					   $
                        npts,						   $
                        type, 						   $
                        ncomp, 						   $
                        0L, 						   $
                        selectionMode,					   $
                        ndims, 						   $
                        dimsizes, 					   $
                        values, 					   $
                        narrdesc, 					   $
                        min1, 						   $
                        max1, 						   $
                        min2, 						   $
                        max2, 						   $
                        min3, 						   $
                        max3, 						   $
			1L, 					   	   $
                        calibrated,     				   $
                        calibrated_units,				   $
                        stindex,  					   $
                        enindex)

   IF len EQ 0 THEN BEGIN       ; trouble so bail out now
      IF selectionMode LE 0L THEN BEGIN 
         PRINT, 'Error getting data sizes from SDT buffers'
         PRINT, 'No data found at selected time, or SDT is not running.. abort'
      ENDIF 

      RETURN, {data_name: 'Null', valid: 0}
   ENDIF
   
   ; allocate the space for the data

   CASE type OF
      0: BEGIN
         PRINT, 'Error getting data type from sdt buffers: Type undefined!' 
         RETURN, {data_name: 'Null', valid: 0}
         END
      1: values = BYTARR (len)
      2: values = INTARR (len)
      3: values = LONARR (len)
      4: values = FLTARR (len)
      5: values = DBLARR (len)
   ENDCASE

   ; Allocate space for min/max components, if necessary.
   ; Note that for backward compatibility, if there is only one array 
   ; descriptor per bin in any one dimension, we want to return 2-D arrays
   ; (dimension size, number points).

   IF ncomp GT 2 THEN BEGIN
      CASE ndims OF
         1: BEGIN
             IF narrdesc(0) GT 1 THEN BEGIN
                 min1 = DBLARR (dimsizes(0), narrdesc(0), npts)
                 max1 = DBLARR (dimsizes(0), narrdesc(0), npts)
             ENDIF ELSE IF narrdesc(0) EQ 1 THEN BEGIN
                 min1 = DBLARR (dimsizes(0), npts)
                 max1 = DBLARR (dimsizes(0), npts)
             ENDIF
         END
         2: BEGIN
             IF narrdesc(0) GT 1 THEN BEGIN
                 min1 = DBLARR (dimsizes(0), narrdesc(0), npts)
                 max1 = DBLARR (dimsizes(0), narrdesc(0), npts)
             ENDIF ELSE IF narrdesc(0) EQ 1 THEN BEGIN
                 min1 = DBLARR (dimsizes(0), npts)
                 max1 = DBLARR (dimsizes(0), npts)
             ENDIF
             IF narrdesc(1) GT 1 THEN BEGIN
                 min2 = DBLARR (dimsizes(1), narrdesc(1), npts)
                 max2 = DBLARR (dimsizes(1), narrdesc(1), npts)
             ENDIF ELSE IF narrdesc(1) EQ 1 THEN BEGIN
                 min2 = DBLARR (dimsizes(1), npts)
                 max2 = DBLARR (dimsizes(1), npts)
             ENDIF
         END 
         3: BEGIN
             IF narrdesc(0) GT 1 THEN BEGIN
                 min1 = DBLARR (dimsizes(0), narrdesc(0), npts)
                 max1 = DBLARR (dimsizes(0), narrdesc(0), npts)
             ENDIF ELSE IF narrdesc(0) EQ 1 THEN BEGIN
                 min1 = DBLARR (dimsizes(0), npts)
                 max1 = DBLARR (dimsizes(0), npts)
             ENDIF
             IF narrdesc(1) GT 1 THEN BEGIN
                 min2 = DBLARR (dimsizes(1), narrdesc(1), npts)
                 max2 = DBLARR (dimsizes(1), narrdesc(1), npts)
             ENDIF ELSE IF narrdesc(1) EQ 1 THEN BEGIN
                 min2 = DBLARR (dimsizes(1), npts)
                 max2 = DBLARR (dimsizes(1), npts)
             ENDIF
             IF narrdesc(2) GT 1 THEN BEGIN
                 min3 = DBLARR (dimsizes(2), narrdesc(2), npts)
                 max3 = DBLARR (dimsizes(2), narrdesc(2), npts)
             ENDIF ELSE IF narrdesc(2) EQ 1 THEN BEGIN
                 min3 = DBLARR (dimsizes(2), npts)
                 max3 = DBLARR (dimsizes(2), npts)
             ENDIF
         END
      ENDCASE
   ENDIF

   ; allocate time tags:

   callTimes = DBLARR (npts)
   endCallTimes = DBLARR (npts)


   ; set up call times, set time2 to time1
   ; if necessary
   
   callYear1 = year1
   callMonth1 = month1
   callDay1 = day1
   callSecs1 = secs1
   IF nkeys EQ 1 OR           $
     nkeys EQ 4  OR           $
     nkeys EQ 9  OR           $
     nkeys EQ 12 THEN BEGIN 
      callYear2 = year1
      callMonth2 = month1
      callDay2 = day1
      callSecs2 = secs1
   ENDIF ELSE BEGIN 
      callYear2 = year2
      callMonth2 = month2
      callDay2 = day2
      callSecs2 = secs2
   ENDELSE
   stindex = st_idx
   enindex = en_idx

   ; next get the actual data

   len = CALL_EXTERNAL ('loadSDTBufLib.so', 'getTimeSeriesFromSDTMD',       $
                        LONG(sat_code),					   $
                        data_name, 					   $
                        callYear1, 					   $
                        callMonth1, 					   $
                        callDay1, 					   $
                        callSecs1, 					   $
                        callYear2, 					   $
                        callMonth2, 					   $
                        callDay2, 					   $
                        callSecs2, 					   $
                        callTimes,					   $
                        endCallTimes,					   $
                        npts,						   $
                        type, 						   $
                        ncomp, 						   $
                        1L, 						   $
                        selectionMode,					   $
                        ndims, 						   $
                        dimsizes, 					   $
                        values, 					   $
                        narrdesc, 					   $
                        min1, 						   $
                        max1, 						   $
                        min2, 						   $
                        max2, 						   $
                        min3, 						   $
                        max3, 						   $
			1L, 					   	   $
                        calibrated,     				   $
                        calibrated_units,				   $
                        stindex,  					   $
                        enindex)

   IF len EQ 0 THEN BEGIN

       IF selectionMode LE 0L THEN BEGIN
           PRINT, 'Error getting data from SDT buffers'
       ENDIF 

       RETURN, {data_name: 'Null', valid: 0}

   ENDIF ELSE BEGIN

       ; Return what we got..

       callTimes = callTimes + datesec_var (callDay1, callMonth1, callYear1)
       endCallTimes = endCallTimes + datesec_var (callDay1, callMonth1, callYear1)
       time1 = callTimes(0)
       time2 = endCallTimes(N_ELEMENTS(endCallTimes)-1)

       CASE ndims OF
         1: values = REFORM (values, dimsizes(0), npts)
         2: values = REFORM (values, dimsizes(0), dimsizes(1), npts)
         3: values = REFORM (values, dimsizes(0), dimsizes(1), dimsizes(2), $
                             npts)
       ENDCASE

       RETURN, {data_name:	data_name, 				      $
                valid: 		1,  					      $       
                start_time:	time1,					      $
                end_time:	time2, 					      $
                npts:		npts, 					      $
                times:		callTimes, 				      $
                endTimes:	endCallTimes, 				      $
                integ_t:	(endCallTimes - callTimes)/dimsizes(0),	      $
                calibrated:	calibrated,     			      $
                calibrated_units:	string(calibrated_units),	      $
                values:		values, 				      $
                ndims:		ndims, 					      $
                dimsizes:	dimsizes, 				      $
                ncomp:		ncomp, 	 				      $
                nminmax:	narrdesc, 				      $
                min1:		min1,	 				      $
                max1:		max1,	 				      $
                min2:		min2,	 				      $
                max2:		max2,	 				      $
                min3:		min3,	 				      $
                max3:		max3,	 				      $
                st_index:	stindex,	 			      $
                en_index:	enindex}

   ENDELSE
END
