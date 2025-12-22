;+
; FUNCTION:
; 	 GET_DQI_INFO
;
; DESCRIPTION:
;
;	function to get information about an sdt loaded DQI
;
; CALLING SEQUENCE:
;
; 	data =  get_dqi_info(sat_code, dqi_name, [TIME=time, INDEX=idx])
;
; ARGUMENTS:
;
;	sat_code  The sdt satellite code for the data quantity
;	          to be queried.   Current known codes are:
;			CRRES		1
;			ISEE		2
;			ISEE2		3
;			GEOTAIL		24
;			WIND		25
;			POLAR		26
;			CLUSTER		30
;			GEOTAIL_SURVEY	241
;			CRRES_SURVEY	1001
;			FAST		2001
;
;	dqi_name  The sdt data quatity string.  Hint, use the
;	          procedure show_dqis to get these strings.
;
; KEYWORDS:
;
;	The index and time keywords are to be used together:
;
;	index:	If defined, return in the time keyword the time at
;		index.
;	time:	If defined, return in the index keyword, the index at
;		time.
;
;	If either time or index is out of range, the returned keyword
;	of interest will be negative.
;
; RETURN VALUE:
;
;	Upon failure, a scaler -1 is returned, else a stucture 
;	of the following format is returned:
;		{ SAT_CODE	LONG    ; same as calling arg
;		  DQI_NAME	STRING  ; same as calling arg
;		  STYEAR	LONG    ; start year of data
;		  STMONTH	LONG    ; start month of data
;		  STDAYOFMONTH	LONG    ; start day of month of data
;		  STSEC		DOUBLE  ; start seconds of day of data
;		  ENYEAR	LONG    ; end year of data
;		  ENMONTH	LONG    ; end month of data
;		  ENDAYOFMONTH	LONG    ; end day of month of data
;		  ENSEC		DOUBLE  ; end seconds of day of data
;		  STORAGE_TYPE	LONG    ; see below
;		  NPTS		LONG    ; number of data points in dqi
;		  DONE		LONG    ; 1 if dqi filled, 0 if waiting
;		}
;
;	STORAGE_TYPE is defined as:
;		0	time series
;		1	Multi-dimensional, one dimension
;		2	Multi-dimensional, two dimensions
;		3	Multi-dimensional, three dimensions
;
; REVISION HISTORY:
;
;	@(#)get_dqi_info.pro	1.5 03/20/98
; 	Originally written by Jonathan M. Loran,  University of 
; 	California at Berkeley, Space Sciences Lab.   Dec. '96
;-

FUNCTION get_dqi_info, sat, dqi, INDEX=idx, TIME=tselection

   ; check for data type

   IF N_ELEMENTS(sat) EQ 0 OR N_ELEMENTS(dqi) EQ 0 THEN BEGIN
      PRINT, '@(#)get_dqi_info.pro	1.5: Input parameters "sat_code" and "dqi_name" must be filled.'
      RETURN, -1
   ENDIF 
   
   ; the following structure must remain in sync with the C code in 
   ; sdtDataToIdl.h

   args = {sat_code:		0L,					$
           dqi_name:		'',					$
           year:		0L,					$
           month:		0L,					$
           day:			0L,					$
           stSec:		0.D,					$
           enSec:		0.D,					$
           dType:		0L,					$
           npts:		0L,					$
           done:		0,					$
           index:		0L,					$
           time:		0.D,					$
           findIdxTime:		0					$
          }

   ; and load the values into this struct

   args.sat_code = long(sat)
   args.dqi_name = dqi
   
   ; selection by time takes presidence
   
   IF n_elements(idx) GT 0 THEN BEGIN
       IF idx GE 0 THEN BEGIN
           args.time = -1
           args.index = idx
           args.findIdxTime = 2              ; 2 means use index for time
       ENDIF
   ENDIF

   IF n_elements(tselection) GT 0 THEN BEGIN
       IF tselection GT 0 THEN BEGIN 
           args.index = -1
           args.time = gettime(tselection)
           args.findIdxTime = 1              ; 1 means use time for index
       ENDIF 
   ENDIF

   valid = CALL_EXTERNAL ('loadSDTBufLib.so', 'getDQIInformation', args)

   IF NOT valid THEN BEGIN
       print, '@(#)get_dqi_info.pro	1.5: error getting DQI info.'
       IF n_elements(tselection) GT 0 THEN idx = -1
       return, -1.
   ENDIF

   ; build up the return struct

   st_date_str = datestruct (time_to_str(datesec_var(                 $
                              args.day, args.month, args.year) + args.stSec))
   en_date_str = datestruct (time_to_str(datesec_var(                 $
                              args.day, args.month, args.year) + args.enSec))
   CASE args.dType OF
       8:    storage = 1
       9:    storage = 2
       10:   storage = 3
       ELSE: storage = 0
   ENDCASE
   
   ; pass back time and index
   
   idx = args.index
   tselection = args.time + datesec_var(st_date_str.monthday, $
                                        st_date_str.month,    $
                                        st_date_str.year)

   return, {sat_code:		args.sat_code,				$
            dqi_name:		args.dqi_name,				$
            styear:		st_date_str.year,			$
            stmonth:		st_date_str.month,			$
            stdayofmonth:	st_date_str.monthday,			$
            stsec:		args.stSec mod 86400.,			$
            enyear:		en_date_str.year,			$
            enmonth:		en_date_str.month,			$
            endayofmonth:	en_date_str.monthday,			$
            ensec:		args.enSec mod 86400.,			$
            storage_type:	storage,				$
            npts:		args.npts,				$
            done:		args.done				$
          }
end


