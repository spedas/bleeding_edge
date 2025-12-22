;+
; FUNCTION:
;        GET_CACHE_TS_1P_FROM_SDT
;
; DESCRIPTION:
;
;       function to manage a cache of time series sdt data.  If the data 
;	selected is found in the sdt buffers, a cache of size cache_hsk.def_size 
;	will be returned in the cache argument, and this function will return 
;	the index into the cache that the selection applies to.
;       
; CALLING SEQUENCE:
;
;       arr_idx= get_cache_ts_1p_from_sdt (data_name, sat_code, cache_hsk, cache,
;                               TIME=time, | INDEX = index, 
;				[FLUSH = flush, CACHE_SIZE = cs])
;
; ARGUMENTS:
;
;       data_name               The SDT data quantity name
;       sat_code                The SDT satellite code
;       cache_hsk               Contains the cache housekeeping info
;       cache                   The actual cache
;
; KEYWORDS:
;
;       TIME                    This argument gives a time handle from which
;                               to take data from.  It may be either a string
;                               with the following possible formats:
;                                       'YY-MM-DD/HH:MM:SS.MSC'  or
;                                       'HH:MM:SS'     (use reference date)
;                               or a number, which will represent seconds
;                               since 1970 (must be a double > 94608000.D), or
;                               a hours from a reference time, if set.
;
;                               time will always be returned as a double
;                               representing the actual data time found in
;                               seconds since 1970.
;
;       INDEX                   If index is gt 0, it is used for selecting
;                               the index to get data.
;
;       FLUSH                   If non-zero, will flush the data cache
;                               This is useful to force a re-read of sdt
;                               buffers in case the data has changed.
;
;       CACHE_SIZE              If non-zero, will reset the default cache
;                               size.
;
; RETURN VALUE:
;
;       Upon success, a non-zero index is returned.  Upon failure, 
;       -1 is returned.
;
; REVISION HISTORY:
;
;       @(#)get_cache_ts_1p_from_sdt.pro	1.3 05/06/98
;       Originally written by Jonathan M. Loran,  University of 
;       California at Berkeley, Space Sciences Lab.   May '97
;-

FUNCTION Get_cache_ts_1p_from_sdt, data_name, sat_code, cache_hsk, cache,   $
                                   TIME=inputTime,  FLUSH=flush,             $
                                   INDEX=idx, CACHE_SIZE=cachesize
@sdt_data_cache_defs

   ; right calling sequence?

   IF N_PARAMS() LT 3 THEN BEGIN
       PRINT, '@(#)get_cache_ts_1p_from_sdt.pro	1.3 05/06/98 : Missing calling arguments'
       RETURN, -1
   ENDIF

   ; must have index or time method of selecting data point

   IF (NOT keyword_set (inputTime)) AND (n_elements(idx) EQ 0) THEN BEGIN
       PRINT, '@(#)get_cache_ts_1p_from_sdt.pro	1.3 05/06/98 : Either keyword TIME or INDEX must be set'
       RETURN, -1
   ENDIF

   ; !!! The following is a hack for the double precision time storage
   ; in sdt multdimentional data types

   IF keyword_set(inputTime) THEN inputTime = gettime(inputTime) + 1e-6

   ; first pass?  If so, initialize cache

   IF N_TAGS (cache_hsk) NE 3 THEN cache_hsk = sdt_ts_cache_def

   ; reset cache size

   IF keyword_set(cachesize) THEN cache_hsk.def_size = cachesize

   ; if we are flushing, invalidate cache

   IF keyword_set(flush) $
     THEN cache_hsk.valid = 0
   
   ; if we're getting by time (no index), convert to an index 
   
   IF (n_elements(idx) EQ 0)   THEN BEGIN
       dinfo = get_dqi_info (sat_code, data_name, time=inputTime, $
                             index=call_idx)
       IF call_idx LT 0 THEN        $             ; time out of range
           RETURN, -1
   ENDIF ELSE call_idx = idx
   
   ; If we have a valid cache, check for index in range

   IF cache_hsk.valid THEN     			$
     IF ( call_idx LT cache.st_index ) OR	$
        ( call_idx GT cache.en_index ) THEN      cache_hsk.valid = 0

   ; if the cache is invalid, get fresh data now

   IF NOT cache_hsk.valid THEN BEGIN

       cache = get_ts_from_sdt (data_name, sat_code,   		$
                                   IDXST=call_idx,		$
                                   NPTS=cache_hsk.def_size)
       ; error?
       IF NOT cache.valid THEN RETURN, -1

       cache_hsk.valid = cache.valid
   ENDIF

   ; handle case of only 1 point in cache

   IF (cache.npts EQ 1) THEN			$
     cache_hsk.cur_idx = 0			$
   ELSE 					$ 
     cache_hsk.cur_idx = call_idx - cache.st_index

   ret_idx = cache_hsk.cur_idx

   ; return a good idx (if we get here)
   
   RETURN, ret_idx
   
END


