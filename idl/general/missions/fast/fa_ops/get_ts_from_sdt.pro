;+
; FUNCTION:
; 	 GET_TS_FROM_SDT
;
; DESCRIPTION:
;
;	function to load generic time series data from the SDT program
; 	shared memory buffers.
;
;	At structure of the following format is returned:
;
;	   DATA_NAME     STRING    'QTY'                 ; Data Quantity name
;	   VALID         INT       1                     ; Data valid flag
;	   START_TIME    DOUBLE    8.0118726e+08         ; Start Time of sample
;	   END_TIME      DOUBLE    7.9850884e+08         ; End time of sample
;	   NPTS          INT       npts                  ; Number of time samples
;	   NCOMP         INT       ncomp                 ; Number of components
;	   DEPTH         INT       Array(ncomp)          ; depth of component
;          TIME          DOUBLE    Array(npts)           ; timetags
;          CALIBRATED    INT       calibrated            ; flags calibrated data
;          CALIBRATED_UNITS STRING units                 ; calibrated units string
;	   COMP1         FLOAT     Array(npts,depth(0))  ; Data component 1
;	   COMP2         FLOAT     Array(npts,depth(1))  ; Data component 2
;	   COMP3         FLOAT     Array(npts,depth(2))  ; Data component 3
;	   COMP4         FLOAT     Array(npts,depth(3))  ; Data component 4
;	   COMP5         FLOAT     Array(npts,depth(4))  ; Data component 5
;	   COMP6         FLOAT     Array(npts,depth(5))  ; Data component 6
;	   COMP7         FLOAT     Array(npts,depth(6))  ; Data component 7
;	   COMP8         FLOAT     Array(npts,depth(7))  ; Data component 8
;	   COMP9         FLOAT     Array(npts,depth(8))  ; Data component 9
;	   COMP10        FLOAT     Array(npts,depth(9))  ; Data component 10
;	   COMP11        FLOAT     Array(npts,depth(10)) ; Data component 11
;	   COMP12        FLOAT     Array(npts,depth(11)) ; Data component 12
;	   COMP13        FLOAT     Array(npts,depth(12)) ; Data component 13
;	   COMP14        FLOAT     Array(npts,depth(13)) ; Data component 14
;	   COMP15        FLOAT     Array(npts,depth(14)) ; Data component 15
;	   COMP16        FLOAT     Array(npts,depth(15)) ; Data component 16
;	   COMP17        FLOAT     Array(npts,depth(16)) ; Data component 17
;	   COMP18        FLOAT     Array(npts,depth(17)) ; Data component 18
;	   COMP19        FLOAT     Array(npts,depth(18)) ; Data component 19
;	   COMP20        FLOAT     Array(npts,depth(19)) ; Data component 20
;	   COMP21        FLOAT     Array(npts,depth(20)) ; Data component 21
;	   COMP22        FLOAT     Array(npts,depth(21)) ; Data component 22
;	   COMP23        FLOAT     Array(npts,depth(22)) ; Data component 23
;	   COMP24        FLOAT     Array(npts,depth(23)) ; Data component 24
;	   COMP25        FLOAT     Array(npts,depth(24)) ; Data component 25
;	   COMP26        FLOAT     Array(npts,depth(25)) ; Data component 26
;	   COMP27        FLOAT     Array(npts,depth(26)) ; Data component 27
;	   COMP28        FLOAT     Array(npts,depth(27)  ; Data component 28
;	   COMP29        FLOAT     Array(npts,depth(28)) ; Data component 29
;	   COMP30        FLOAT     Array(npts,depth(29)) ; Data component 30
;	   COMP31        FLOAT     Array(npts,depth(30)) ; Data component 31
;	   COMP32        FLOAT     Array(npts,depth(31)) ; Data component 32
;	   COMP33        FLOAT     Array(npts,depth(32)) ; Data component 33
;	   COMP34        FLOAT     Array(npts,depth(33)) ; Data component 34
;	   COMP35        FLOAT     Array(npts,depth(34)) ; Data component 35
;	   COMP36        FLOAT     Array(npts,depth(35)) ; Data component 36
;	   COMP37        FLOAT     Array(npts,depth(36)) ; Data component 37
;	   COMP38        FLOAT     Array(npts,depth(37)) ; Data component 38
;	   COMP39        FLOAT     Array(npts,depth(38)) ; Data component 39
;	   ST_INDEX      LONG      stidx                 ; index of 1st pt in sdt
;	   EN_INDEX      LONG      enidx                 ; index of last pt in sdt
;	   
;	
; CALLING SEQUENCE:
;
; 	data = get_ts_from_sdt (data_name, sat_code, t1=time1, t2=time2, 
;				[NPTS=npts], [START=st | EN=en | 
;				PANF=panf | PANB=panb | IDXST=startidx])
;
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
;	following truth table (NZ == non-zero):
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
; | 0  |  NZ |  0  |  0  |  NZ |  0  |  0  | st-index ->         |         |         |
; |    |     |     |     |     |     |     |   st_index + npts   |         |         |
;
;	Any other combination of keywords is not allowed.
;
; RETURN VALUE:
;
;	Upon success, the above structure is returned, with the valid tag
;	set to 1.  Upon failure, the valid tag will be 0.
;
; REVISION HISTORY:
;
;	@(#)get_ts_from_sdt.pro	1.13 07/26/02
; 	Originally written by	 Jonathan M. Loran,  University of 
; 	California at Berkeley, Space Sciences Lab.   Jan '96
;-

FUNCTION Get_ts_from_sdt, data_name, sat_code, t1=time1, t2=time2, NPTS=npts,    $
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
         PRINT, '@(#)get_ts_from_sdt.pro	1.13 : Illegal combination of keywords'
         RETURN, {data_name: 'Null', valid: 0}
      END 
   ENDCASE 

   ; parse out the input times into seconds since 1970

   IF t1used THEN BEGIN
      IF NOT KEYWORD_SET(st) AND NOT KEYWORD_SET(en) THEN secs1970_1 = gettime(time1) $
        ELSE IF N_ELEMENTS(time1) GT 0 THEN secs1970_1 = time1                        $
        ELSE BEGIN ; format error in date1
         PRINT, '@(#)get_ts_from_sdt.pro	1.13 : Invalid input time1: '
         RETURN, {data_name: 'Null', valid: 0}
      ENDELSE 
   ENDIF 

   IF t2used THEN BEGIN
      IF N_ELEMENTS(time2) GT 0 THEN                       $
        secs1970_2 = gettime(time2)                        $
        ELSE BEGIN              ; format error in date2
         PRINT, '@(#)get_ts_from_sdt.pro	1.13 : Invalid input time2'
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
   
   IF t1used THEN secs1 = secs1970_1 MOD 86400.D               ; extract seconds of day 1
   IF t2used THEN secs2 = secs1970_2 - secs1970_1 + secs1      ; extract seconds of day 2

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


   ; first see how long our data arrays are.  Note we allocate something for 
   ; all possible components.

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
   component21 = FLTARR(1)
   component22 = FLTARR(1)
   component23 = FLTARR(1)
   component24 = FLTARR(1)
   component25 = FLTARR(1)
   component26 = FLTARR(1)
   component27 = FLTARR(1)
   component28 = FLTARR(1)
   component29 = FLTARR(1)
   component30 = FLTARR(1)
   component31 = FLTARR(1)
   component32 = FLTARR(1)
   component33 = FLTARR(1)
   component34 = FLTARR(1)
   component35 = FLTARR(1)
   component36 = FLTARR(1)
   component37 = FLTARR(1)
   component38 = FLTARR(1)
   component39 = FLTARR(1)
   component40 = FLTARR(1)
   maxNComp = 40

   type = LONARR(maxNComp)
   depth = LONARR(maxNComp)
   calibrated = 0L
   calibrated_units = bytarr(64)
   ncomp = 1L
   IF N_ELEMENTS (npts) GT 0 THEN  npts = LONG(npts) $
     ELSE npts = 0L

   callTimes = 1D       ; will be timetags

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
   new_sat_code = sat_code

   len = CALL_EXTERNAL ('loadSDTBufLib.so', 'getTimeSeriesFromSDT',        $
                        long(sat_code),					   $
                        data_name,					   $
                        callYear1, 					   $
                        callMonth1, 					   $
                        callDay1, 					   $
                        callSecs1, 					   $
                        callYear2, 					   $
                        callMonth2, 					   $
                        callDay2, 					   $
                        callSecs2, 					   $
                        callTimes,					   $
                        type, 						   $
                        depth, 						   $
                        ncomp, 						   $
                        npts, 						   $
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
                        component21,					   $
                        component22,					   $
                        component23,					   $
                        component24,					   $
                        component25,					   $
                        component26,					   $
                        component27,					   $
                        component28,					   $
                        component29,					   $
                        component30, 					   $
                        component31, 					   $
                        component32, 					   $
                        component33, 					   $
                        component34, 					   $
                        component35, 					   $
                        component36, 					   $
                        component37, 					   $
                        component38, 					   $
                        component39, 					   $
                        component40, 					   $
                        selectionMode, 				   	   $
                        calibrated,     				   $
                        calibrated_units,				   $
                        stindex,  					   $
                        enindex)

   IF len EQ 0 THEN BEGIN       ; maybe should be the SCM:

      new_sat_code = 0
      len = CALL_EXTERNAL ('loadSDTBufLib.so', 'getTimeSeriesFromSDT',     $
                        long(0),					   $
                        data_name,					   $
                        callYear1, 					   $
                        callMonth1, 					   $
                        callDay1, 					   $
                        callSecs1, 					   $
                        callYear2, 					   $
                        callMonth2, 					   $
                        callDay2, 					   $
                        callSecs2, 					   $
                        callTimes,					   $
                        type, 						   $
                        depth, 						   $
                        ncomp, 						   $
                        npts, 						   $
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
                        component21,					   $
                        component22,					   $
                        component23,					   $
                        component24,					   $
                        component25,					   $
                        component26,					   $
                        component27,					   $
                        component28,					   $
                        component29,					   $
                        component30, 					   $
                        component31, 					   $
                        component32, 					   $
                        component33, 					   $
                        component34, 					   $
                        component35, 					   $
                        component36, 					   $
                        component37, 					   $
                        component38, 					   $
                        component39, 					   $
                        component40, 					   $
                        selectionMode, 				   	   $
                        calibrated,     				   $
                        calibrated_units,				   $
                        stindex,  					   $
                        enindex)
       IF len EQ 0 THEN BEGIN       ; trouble so bail out now
          RETURN, {data_name: 'Null', valid: 0}
       ENDIF
   ENDIF
   
   ; allocate the space for the data

   FOR i = 0, ncomp-1 DO BEGIN
      IF depth(i) GT 1 THEN BEGIN
         ndims = 2
         dimsizes = [depth(i), npts]
      ENDIF ELSE BEGIN
         ndims = 1
         dimsizes = npts
      ENDELSE

      CASE i OF
         0: component1 = allocateArray(type(i), ndims, dimsizes)
         1: component2 = allocateArray(type(i), ndims, dimsizes)
         2: component3 = allocateArray(type(i), ndims, dimsizes)
         3: component4 = allocateArray(type(i), ndims, dimsizes)
         4: component5 = allocateArray(type(i), ndims, dimsizes)
         5: component6 = allocateArray(type(i), ndims, dimsizes)
         6: component7 = allocateArray(type(i), ndims, dimsizes)
         7: component8 = allocateArray(type(i), ndims, dimsizes)
         8: component9 = allocateArray(type(i), ndims, dimsizes)
         9: component10 = allocateArray(type(i), ndims, dimsizes)
         10: component11 = allocateArray(type(i), ndims, dimsizes)
         11: component12 = allocateArray(type(i), ndims, dimsizes)
         12: component13 = allocateArray(type(i), ndims, dimsizes)
         13: component14 = allocateArray(type(i), ndims, dimsizes)
         14: component15 = allocateArray(type(i), ndims, dimsizes)
         15: component16 = allocateArray(type(i), ndims, dimsizes)
         16: component17 = allocateArray(type(i), ndims, dimsizes)
         17: component18 = allocateArray(type(i), ndims, dimsizes)
         18: component19 = allocateArray(type(i), ndims, dimsizes)
         19: component20 = allocateArray(type(i), ndims, dimsizes)
         20: component21 = allocateArray(type(i), ndims, dimsizes)
         21: component22 = allocateArray(type(i), ndims, dimsizes)
         22: component23 = allocateArray(type(i), ndims, dimsizes)
         23: component24 = allocateArray(type(i), ndims, dimsizes)
         24: component25 = allocateArray(type(i), ndims, dimsizes)
         25: component26 = allocateArray(type(i), ndims, dimsizes)
         26: component27 = allocateArray(type(i), ndims, dimsizes)
         27: component28 = allocateArray(type(i), ndims, dimsizes)
         28: component29 = allocateArray(type(i), ndims, dimsizes)
         29: component30 = allocateArray(type(i), ndims, dimsizes)
         30: component31 = allocateArray(type(i), ndims, dimsizes)
         31: component32 = allocateArray(type(i), ndims, dimsizes)
         32: component33 = allocateArray(type(i), ndims, dimsizes)
         33: component34 = allocateArray(type(i), ndims, dimsizes)
         34: component35 = allocateArray(type(i), ndims, dimsizes)
         35: component36 = allocateArray(type(i), ndims, dimsizes)
         36: component37 = allocateArray(type(i), ndims, dimsizes)
         37: component38 = allocateArray(type(i), ndims, dimsizes)
         38: component39 = allocateArray(type(i), ndims, dimsizes)
         39: component40 = allocateArray(type(i), ndims, dimsizes)
      ENDCASE
   ENDFOR 
   callTimes = DBLARR (npts)

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

   ret = CALL_EXTERNAL ('loadSDTBufLib.so', 'getTimeSeriesFromSDT',        $
                        long(new_sat_code),				   $
                        data_name,					   $
                        callYear1, 					   $
                        callMonth1, 					   $
                        callDay1, 					   $
                        callSecs1, 					   $
                        callYear2, 					   $
                        callMonth2, 					   $
                        callDay2, 					   $
                        callSecs2, 					   $
                        callTimes,					   $
                        type, 						   $
                        depth, 						   $
                        ncomp, 						   $
                        npts, 						   $
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
                        component21,					   $
                        component22,					   $
                        component23,					   $
                        component24,					   $
                        component25,					   $
                        component26,					   $
                        component27,					   $
                        component28,					   $
                        component29,					   $
                        component30, 					   $
                        component31, 					   $
                        component32, 					   $
                        component33, 					   $
                        component34, 					   $
                        component35, 					   $
                        component36, 					   $
                        component37, 					   $
                        component38, 					   $
                        component39, 					   $
                        component40, 					   $
                        selectionMode, 				   	   $
                        calibrated,     				   $
                        calibrated_units,				   $
                        stindex,  					   $
                        enindex)

   IF ret EQ 0 THEN BEGIN
      RETURN, {data_name: 'Null', valid: 0}
      
   ENDIF

   callTimes = callTimes + datesec_var (callDay1, callMonth1, callYear1)
   time1 = callTimes(0)
   time2 = callTimes(N_ELEMENTS(callTimes)-1)

   ; load up the data into return struct

   dat = 								  $
     {data_name:	data_name, 					  $
       valid: 		1, 						  $
       start_time:	time1,						  $
       end_time:	time2, 						  $
       npts:		npts, 						  $
       ncomp:		ncomp, 						  $
       depth:		depth,	 					  $
       time:		callTimes, 				   	  $
       calibrated:	calibrated,     				  $
       calibrated_units: string(calibrated_units),			  $
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
       comp20:		component20,		 			  $
       comp21:          component21,					  $
       comp22:          component22,					  $
       comp23:          component23,					  $
       comp24:          component24,					  $
       comp25:          component25,					  $
       comp26:          component26,					  $
       comp27:          component27,					  $
       comp28:          component28,					  $
       comp29:          component29,					  $
       comp30:          component30, 					  $
       comp31:          component31, 					  $
       comp32:          component32, 					  $
       comp33:          component33, 					  $
       comp34:          component34, 					  $
       comp35:          component35, 					  $
       comp36:          component36, 					  $
       comp37:          component37, 					  $
       comp38:          component38, 					  $
       comp39:          component39, 					  $
       st_index:	stindex,		 			  $
       en_index:	enindex}

   RETURN,  dat
END 
