;+
; FUNCTION:
; 	 GET_TS_1P_FROM_SDT
;
; DESCRIPTION:
;
;	function to load one data point of generic time series data
;	type from the SDT program shared memory buffers at a 
; 	specific time.
;
;	At structure of the following format is returned:
;
;	   DATA_NAME     STRING    'QTY'            ; Data Quantity name
;	   VALID         INT       1                ; Data valid flag
;	   TIME          DOUBLE    8.0118726e+08    ; Time of sample, returned
;	   NCOMP         INT       ncomp            ; Number of components
;	   DEPTH         INT       Array(ncomp)     ; depth of component
;          CALIBRATED    INT       calibrated       ; flags calibrated data
;          CALIBRATED_UNITS STRING units            ; calibrated units string
;	   INDEX         LONG      idx              ; index into sdt data
;	   COMP1         FLOAT     Array(depth(0))  ; Data component 1
;	   COMP2         FLOAT     Array(depth(1))  ; Data component 2
;	   COMP3         FLOAT     Array(depth(2))  ; Data component 3
;	   COMP4         FLOAT     Array(depth(3))  ; Data component 4
;	   COMP5         FLOAT     Array(depth(4))  ; Data component 5
;	   COMP6         FLOAT     Array(depth(5))  ; Data component 6
;	   COMP7         FLOAT     Array(depth(6))  ; Data component 7
;	   COMP8         FLOAT     Array(depth(7))  ; Data component 8
;	   COMP9         FLOAT     Array(depth(8))  ; Data component 9
;	   COMP10        FLOAT     Array(depth(9))  ; Data component 10
;	   COMP11        FLOAT     Array(depth(10)) ; Data component 11
;	   COMP12        FLOAT     Array(depth(11)) ; Data component 12
;	   COMP13        FLOAT     Array(depth(12)) ; Data component 13
;	   COMP14        FLOAT     Array(depth(13)) ; Data component 14
;	   COMP15        FLOAT     Array(depth(14)) ; Data component 15
;	   COMP16        FLOAT     Array(depth(15)) ; Data component 16
;	   COMP17        FLOAT     Array(depth(16)) ; Data component 17
;	   COMP18        FLOAT     Array(depth(17)) ; Data component 18
;	   COMP19        FLOAT     Array(depth(18)) ; Data component 19
;	   COMP20        FLOAT     Array(depth(19)) ; Data component 20
;	   
;	
; CALLING SEQUENCE:
;
; 	data = get_ts_1p_from_sdt (data_name, sat_code, time)
;
; ARGUMENTS:
;
;	data_name		The SDT data quantity name
;	sat_code		The SDT satellite code
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
;	INDEX:			get data at this index.
;
; RETURN VALUE:
;
;	Upon success, the above structure is returned, with the valid tag
;	set to 1.  Upon failure, the valid tag will be 0.
;
; REVISION HISTORY:
;
;	@(#)get_ts_1p_from_sdt.pro	1.8 07/23/97
; 	Originally written by Jonathan M. Loran,  University of 
; 	California at Berkeley, Space Sciences Lab.   May '96
;-

FUNCTION get_ts_1p_from_sdt, data_type, sat_code, inputTime, INDEX=idx

   ; must have some input time

   IF N_ELEMENTS (inputTime) EQ 0 THEN BEGIN
      PRINT, '@(#)get_ts_1p_from_sdt.pro	1.8 : An input time argument must be specified'
      RETURN, {data_name: 'Null', valid: 0}
   ENDIF

   ; parse out the input time

   secs1970 = gettime(inputTime)

   ; !!! The following is a hack for the double precision time storage
   ; in sdt multdimentional data types

   inputTime = inputTime + 1e-6

   IF secs1970 LE 0.D THEN BEGIN ; format error in date
      PRINT, '@(#)get_ts_1p_from_sdt.pro	1.8 : Invalid input time: ', inputTime
      RETURN, {data_name: 'Null', valid: 0}
   ENDIF

   secs = secs1970 MOD 86400.D               ; extract seconds of day

   date_st = datestruct(secdate(secs1970))   ; separate out the date components
   
   year = LONG (date_st.year)
   month = LONG (date_st.month)
   day = LONG (date_st.monthday)

   ; first see how long our array is.  Note we allocate something for all
   ; possible components.

   time = 1D
   callTime = time
   component1 = FLTARR(1)
   component2 = FLTARR(1)
   component3 = FLTARR(1)
   component4 = FLTARR(1)
   component5 = FLTARR(1)
   component6 = FLTARR(1)
   component7 = FLTARR(1)
   component8 = FLTARR(1)
   component9 = FLTARR(1)
   component10 = FLTARR(1)
   component11 = FLTARR(1)
   component12 = FLTARR(1)
   component13 = FLTARR(1)
   component14 = FLTARR(1)
   component15 = FLTARR(1)
   component16 = FLTARR(1)
   component17 = FLTARR(1)
   component18 = FLTARR(1)
   component19 = FLTARR(1)
   component20 = FLTARR(1)
   type = LONARR(20)
   depth = LONARR(20)
   ncomp = 1L
   IF n_elements(idx) GT 0 THEN BEGIN
       retrievalMode = 12L
       index = long(idx)
   ENDIF ELSE BEGIN
       retrievalMode = 2L
       index = -1L
   ENDELSE
   callDay = day
   callMonth = month
   callYear = year
   callSecs = secs
   calibrated = 0L
   calibrated_units = bytarr(64)
   
   len = CALL_EXTERNAL ('loadSDTBufLib.so', 'getTimePointFromSDTTS',      $
                        long(sat_code),					   $
                        data_type,					   $
                        callYear, 					   $
                        callMonth, 					   $
                        callDay, 					   $
                        callSecs, 					   $
                        callTime,					   $
                        type, 						   $
                        depth, 						   $
                        ncomp, 						   $
                        0L, 						   $
                        component1, 					   $
                        component2, 					   $
                        component3, 					   $
                        component4, 					   $
                        component5, 					   $
                        component6, 					   $
                        component7, 					   $
                        component8, 					   $
                        component9, 					   $
                        component10, 					   $
                        component11, 					   $
                        component12, 					   $
                        component13, 					   $
                        component14, 					   $
                        component15, 					   $
                        component16, 					   $
                        component17, 					   $
                        component18, 					   $
                        component19, 					   $
                        component20, 					   $
                        retrievalMode, 				   	   $
                        calibrated,     				   $
                        calibrated_units,     				   $
                        index)

   IF len EQ 0 THEN BEGIN       ; trouble so bail out now

      RETURN, {data_name: 'Null', valid: 0}
   ENDIF
   
   ; allocate the space for the data

   FOR i = 0, ncomp-1 DO BEGIN
      CASE i OF
         0: component1 = allocateArray(type(i), 1, depth(i))
         1: component2 = allocateArray(type(i), 1, depth(i))
         2: component3 = allocateArray(type(i), 1, depth(i))
         3: component4 = allocateArray(type(i), 1, depth(i))
         4: component5 = allocateArray(type(i), 1, depth(i))
         5: component6 = allocateArray(type(i), 1, depth(i))
         6: component7 = allocateArray(type(i), 1, depth(i))
         7: component8 = allocateArray(type(i), 1, depth(i))
         8: component9 = allocateArray(type(i), 1, depth(i))
         9: component10 = allocateArray(type(i), 1, depth(i))
         10: component11 = allocateArray(type(i), 1, depth(i))
         11: component12 = allocateArray(type(i), 1, depth(i))
         12: component13 = allocateArray(type(i), 1, depth(i))
         13: component14 = allocateArray(type(i), 1, depth(i))
         14: component15 = allocateArray(type(i), 1, depth(i))
         15: component16 = allocateArray(type(i), 1, depth(i))
         16: component17 = allocateArray(type(i), 1, depth(i))
         17: component18 = allocateArray(type(i), 1, depth(i))
         18: component19 = allocateArray(type(i), 1, depth(i))
         19: component20 = allocateArray(type(i), 1, depth(i))
      ENDCASE
   ENDFOR 

   ; next get the actual data

   ret = CALL_EXTERNAL ('loadSDTBufLib.so', 'getTimePointFromSDTTS',       $
                        long(sat_code),					   $
                        data_type,					   $
                        year, 						   $
                        month, 						   $
                        day, 						   $
                        secs, 						   $
                        time, 						   $
                        type, 						   $
                        depth, 						   $
                        ncomp, 						   $
                        1L, 						   $
                        component1, 					   $
                        component2, 					   $
                        component3, 					   $
                        component4, 					   $
                        component5, 					   $
                        component6, 					   $
                        component7, 					   $
                        component8, 					   $
                        component9, 					   $
                        component10, 					   $
                        component11, 					   $
                        component12, 					   $
                        component13, 					   $
                        component14, 					   $
                        component15, 					   $
                        component16, 					   $
                        component17, 					   $
                        component18, 					   $
                        component19, 					   $
                        component20, 					   $
                        retrievalMode, 				   	   $
                        calibrated,     				   $
                        calibrated_units,     				   $
                        index)

   IF ret EQ 0 THEN BEGIN
      RETURN, {data_name: 'Null', valid: 0}
      
   ENDIF

   retTime = secs + datesec_var (day, month, year)

   idx = index
   
   ; load up the data into return struct

   dat = 								  $
     {data_name:	data_type, 					  $
       valid: 		1, 						  $
       time:		retTime,					  $
       ncomp:		ncomp, 						  $
       depth:		depth,	 					  $
       calibrated:	calibrated,     				  $
       calibrated_units:	string(calibrated_units),	   	  $
       comp1:		component1,					  $ 
       comp2:		component2,					  $ 
       comp3:		component3,					  $ 
       comp4:		component4,					  $ 
       comp5:		component5,					  $ 
       comp6:		component6,					  $ 
       comp7:		component7,					  $ 
       comp8:		component8,					  $ 
       comp9:		component9,					  $ 
       comp10:		component10,					  $
       comp11:		component11,					  $
       comp12:		component12,					  $
       comp13:		component13,					  $
       comp14:		component14,					  $
       comp15:		component15,					  $
       comp16:		component16,					  $
       comp17:		component17,					  $
       comp18:		component18,					  $
       comp19:		component19,					  $
       comp20:		component20,     				  $
       index:		index}

   RETURN,  dat
END 
