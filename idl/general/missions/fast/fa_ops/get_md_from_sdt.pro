;+
; FUNCTION:
; 	 GET_MD_FROM_SDT
;
; DESCRIPTION:
;
;	function to load generic multi dimensional data sample from the SDT program
; 	shared memory buffers.
;
;	A structure of the following format is returned:
;
;	   DATA_NAME     STRING    'QTY'                ; Data Quantity name
;	   VALID         INT       1                    ; Data valid flag
;	   YEAR          LONG      year                 ; Data year
;	   MONTH         LONG      month                ; Data month
;	   DAY           LONG      day                  ; Data day
;	   TIME          DOUBLE    time                 ; Start Time of sample
;	   ENDTIME       DOUBLE    end_time             ; End time of sample
;	   INTEG_T       DOUBLE    integ_t              ; Integration time
;          CALIBRATED    INT       calibrated           ; flags calibrated data
;          CALIBRATED_UNITS STRING units                ; calibrated units string
;	   VALUES        <TYPE>    Array(dimsizes(0..3)); Data qauantities
;	   NDIMS         LONG      ndims                ; Number of data dimensions
;	   DIMSIZES      LONG      dimsizes(3)          ; Sizes of each dimension
;	   NCOMP         LONG      ncomp                ; number of data components
;	   NMINMAX       INT       array(ndims)         ; number of array desc(dim)
;	   MIN1          DOUBLE    array(dimsizes(0)    ; Array descriptor min (0)
;	   MAX1          DOUBLE    array(dimsizes(0)    ; Array descriptor max (0)
;	   MIN2          DOUBLE    array(dimsizes(1)    ; Array descriptor min (1)
;	   MAX2          DOUBLE    array(dimsizes(1)    ; Array descriptor max (1)
;	   MIN3          DOUBLE    array(dimsizes(2)    ; Array descriptor min (2)
;	   MAX3          DOUBLE    array(dimsizes(2)    ; Array descriptor max (2)
;	   INDEX         LONG      idx                  ; index into sdt buffers
;	
; CALLING SEQUENCE:
;
;	data = get_md_from_sdt (data_name, sat_code, TIME=time, 
;	                        [START = start | EN = en | ADVANCE = advance |
;				RETREAT=retreat], INDEX=idx)
;
; ARGUMENTS:
;
;	data_name		The SDT data quantity name
;	sat_code		The SDT satellite code
;
; KEYWORDS:
;
;	TIME 			This argument gives a time handle from which
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
;	INDEX			If defined, data will be selected by this
;				index
;
; RETURN VALUE:
;
;	Upon success, the above structure is returned, with the valid tag
;	set to 1.  Upon failure, the valid tag will be 0.
;
; REVISION HISTORY:
;
;	@(#)get_md_from_sdt.pro	1.11 07/23/97
; 	Originally written by Jonathan M. Loran,  University of 
; 	California at Berkeley, Space Sciences Lab.   Jan '95
;-

FUNCTION Get_md_from_sdt, data_name, sat_code, TIME=inputTime, $
                          START=start, EN=en, ADVANCE=advance, RETREAT=retreat, $
                          INDEX=idx
   ; must have some input time

   IF N_ELEMENTS (inputTime) EQ 0 THEN BEGIN
      PRINT, '@(#)get_md_from_sdt.pro	1.11 : An input time argument must be specified'
      RETURN, {data_name: 'Null', valid: 0}
   ENDIF

   ; only one keyword can be set.  Check this and set selection mode

   nkeys = 0
   IF KEYWORD_SET (start)   THEN BEGIN
      nkeys = nkeys + 1 & selectionMode = 6L &  ENDIF 
   IF KEYWORD_SET (en)      THEN BEGIN
      nkeys = nkeys + 1 & selectionMode = 9L &  ENDIF
   IF KEYWORD_SET (advance) THEN BEGIN 
      nkeys = nkeys + 1 & selectionMode = 1L &  ENDIF 
   IF KEYWORD_SET (retreat) THEN BEGIN 
      nkeys = nkeys + 1 & selectionMode = 0L &  ENDIF
   IF n_elements (idx) GT 0 THEN BEGIN   
      nkeys = nkeys + 1 & selectionMode = 12L & ENDIF ELSE idx = -1L

   IF nkeys EQ 0 THEN selectionMode = 2L              $
   ELSE IF nkeys GT 1 THEN BEGIN
      PRINT, '@(#)get_md_from_sdt.pro	1.11 : Only one keyword may be used at one time'
      RETURN, {data_name: 'Null', valid: 0}
   ENDIF
   
   ; parse out the input time

   secs1970 = gettime(inputTime)

   ; !!! The following is a hack for the double precision time storage
   ; in sdt multdimentional data types

   inputTime = inputTime + 1e-6

   IF (secs1970 LE 0.D) AND (selectionMode NE 6) AND (selectionMode NE 9)  $
     AND (selectionMode NE 12 ) $
     THEN BEGIN                 ; format error in date
      PRINT, '@(#)get_md_from_sdt.pro	1.11 : Invalid input time: ', inputTime
      RETURN, {data_name: 'Null', valid: 0}
   ENDIF

   secs = secs1970 MOD 86400.D               ; extract seconds of day

   date_st = datestruct(secdate(secs1970))   ; separate out the date components
   
   year = LONG (date_st.year)
   month = LONG (date_st.month)
   day = LONG (date_st.monthday)

   ; first see how long our array is

   time = 1D
   callTime = time
   endTime = 1D
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
   callday = day
   callmonth = month
   callyear = year
   callsecs = secs
   calibrated = 0L
   calibrated_units = bytarr(64)
   index = long(idx)
   
   len = CALL_EXTERNAL ('loadSDTBufLib.so', 'getTimePointFromSDTMD',       $
                        LONG(sat_code),					   $
                        data_name, 					   $
                        callyear, 					   $
                        callmonth,					   $
                        callday, 					   $
                        callsecs,	 				   $
                        callTime, 					   $
                        endTime, 					   $
                        type, 						   $
                        ncomp, 						   $
                        0L, 						   $
                        ndims, 						   $
                        dimsizes, 					   $
                        values, 					   $
                        min1, 						   $
                        max1, 						   $
                        min2, 						   $
                        max2, 						   $
                        min3, 						   $
                        max3, 						   $
                        narrdesc, 					   $
                        selectionMode,					   $
			1L, 					   	   $
                        calibrated,     				   $
                        calibrated_units,				   $
                        index)

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
   ; descriptor per bin in any one dimension, we want to return 1-D arrays


   IF ncomp GT 2 THEN BEGIN
      CASE ndims OF
         1: BEGIN
             IF narrdesc(0) GT 1 THEN BEGIN
                 min1 = DBLARR (dimsizes(0), narrdesc(0))
                 max1 = DBLARR (dimsizes(0), narrdesc(0))
             ENDIF ELSE IF narrdesc(0) EQ 1 THEN BEGIN
                 min1 = DBLARR (dimsizes(0))
                 max1 = DBLARR (dimsizes(0))
             ENDIF
         END
         2: BEGIN
             IF narrdesc(0) GT 1 THEN BEGIN
                 min1 = DBLARR (dimsizes(0), narrdesc(0))
                 max1 = DBLARR (dimsizes(0), narrdesc(0))
             ENDIF ELSE IF narrdesc(0) EQ 1 THEN BEGIN
                 min1 = DBLARR (dimsizes(0))
                 max1 = DBLARR (dimsizes(0))
             ENDIF
             IF narrdesc(1) GT 1 THEN BEGIN
                 min2 = DBLARR (dimsizes(1), narrdesc(1))
                 max2 = DBLARR (dimsizes(1), narrdesc(1))
             ENDIF ELSE IF narrdesc(1) EQ 1 THEN BEGIN
                 min2 = DBLARR (dimsizes(1))
                 max2 = DBLARR (dimsizes(1))
             ENDIF
         END 
         3: BEGIN
             IF narrdesc(0) GT 1 THEN BEGIN
                 min1 = DBLARR (dimsizes(0), narrdesc(0))
                 max1 = DBLARR (dimsizes(0), narrdesc(0))
             ENDIF ELSE IF narrdesc(0) EQ 1 THEN BEGIN
                 min1 = DBLARR (dimsizes(0))
                 max1 = DBLARR (dimsizes(0))
             ENDIF
             IF narrdesc(1) GT 1 THEN BEGIN
                 min2 = DBLARR (dimsizes(1), narrdesc(1))
                 max2 = DBLARR (dimsizes(1), narrdesc(1))
             ENDIF ELSE IF narrdesc(1) EQ 1 THEN BEGIN
                 min2 = DBLARR (dimsizes(1))
                 max2 = DBLARR (dimsizes(1))
             ENDIF
             IF narrdesc(2) GT 1 THEN BEGIN
                 min3 = DBLARR (dimsizes(2), narrdesc(2))
                 max3 = DBLARR (dimsizes(2), narrdesc(2))
             ENDIF ELSE IF narrdesc(2) EQ 1 THEN BEGIN
                 min3 = DBLARR (dimsizes(2))
                 max3 = DBLARR (dimsizes(2))
             ENDIF
         END
      ENDCASE
   ENDIF

   ; next get the actual data

   ret = CALL_EXTERNAL ('loadSDTBufLib.so', 'getTimePointFromSDTMD',       $
                        LONG(sat_code),					   $
                        data_name, 					   $
                        year, 						   $
                        month, 						   $
                        day, 						   $
                        secs, 						   $
                        time, 						   $
                        endTime, 					   $
                        type, 						   $
                        ncomp, 						   $
                        1L, 						   $
                        ndims, 						   $
                        dimsizes, 					   $
                        values, 					   $
                        min1, 						   $
                        max1, 						   $
                        min2, 						   $
                        max2, 						   $
                        min3, 						   $
                        max3, 						   $
                        narrdesc, 					   $
                        selectionMode,					   $
			1L, 					   	   $
                        calibrated,     				   $
                        calibrated_units,				   $
                        index)

   IF ret EQ 0 THEN BEGIN

      IF selectionMode LE 0L THEN BEGIN
         PRINT, 'Error getting data from SDT buffers'
      ENDIF 

      RETURN, {data_name: 'Null', valid: 0}

   ENDIF ELSE BEGIN

      ; Return what we got..

      inputTime = time + datesec_var (day, month, year)
      
      idx = index
      
      RETURN, {data_name:	data_name, 				      $
                valid: 		1,  					      $       
                year:		year, 					      $
                month:		month, 					      $
                day:		day, 					      $
                time:		inputTime,				      $
                endTime:	endTime  + datesec_var (day, month, year),    $
                integ_t:	(endTime - time)/dimsizes(0), 		      $
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
                index:		index}

   ENDELSE
END
