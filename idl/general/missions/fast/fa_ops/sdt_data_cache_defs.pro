;+
; DEFINITIONS FILE:
; 	 SDT_DATA_CACHE_DEFS
;
; DESCRIPTION:
;
;	Defs for idl caches while getting sdt data.
;
; REVISION HISTORY:
;
;	@(#)sdt_data_cache_defs.pro	1.1 05/31/97
; 	Originally written by Jonathan M. Loran,  University of 
; 	California at Berkeley, Space Sciences Lab.   Apr '97
;-

; Note: These two are currently the same, except for default size (points)

sdt_md_cache_def = {valid: 0, cur_idx: -1L, def_size: 100L}
sdt_ts_cache_def = {valid: 0, cur_idx: -1L, def_size: 100000L}

