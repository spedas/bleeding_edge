;+
;PROCEDURE:	get_array_struct(time,START=start,EN=en,ADVANCE=advance,RETREAT=retreat)
;PURPOSE:	
;	Gets a structure from the common array_struc_com, see make_array_struc.pro
;INPUT:
;	time:	real		Currently time is ignored.
;	
;				Later versions may:
;				This argument gives a time handle from which
;				to take data from.  It may be either a string
;				with the following possible formats:
;					'MM-DD-YY/HH:MM:SS.MSC'  or
;					'HH:MM:SS'     (use reference date)
;				or a number, which will represent seconds
;				since 1970 (must be a double > 94608000.D), or
;				a hours from a reference time, if set.
;				Time will always be returned as a double
;				representing the actual data time found in
;				seconds since 1970.
;;KEYWORDS:
;	START:			If non-zero, get first data from array_struc
;	EN:			If non-zero, get last  data from array_struc
;	ADVANCE:		If non-zero, advance to the next data point
;	RETREAT:		If non-zero, retreat to the previous data point 
;
;CREATED BY:	J.McFadden
;VERSION:	1
;LAST MODIFICATION:  96-11-7	McFadden
;MOD HISTORY:
;
;NOTES:	  
;	make_array_struc.pro makes an array of structures that is called by get_array_struc.pro
;	Current version only works for FAST
;	Written to speed up summary plot production for ees and ies
;	Current version ignores time input, requires keyword to work properly
;-

FUNCTION get_array_struc,time,START=start,EN=en,ADVANCE=advance,$
            RETREAT=retreat, CALIB=calib


common array_struc_com, array_struc, nstruc, max_index, cur_index

if keyword_set(advance) then begin
	if cur_index eq max_index then begin
		dat=array_struc(cur_index)
		dat.valid=0
		return,dat
	endif else begin
		cur_index=cur_index+1 
	endelse
endif

if keyword_set(start) then begin
	cur_index=0 
endif

if keyword_set(en) then begin
	cur_index=max_index 
endif

if keyword_set(retreat) then begin
	if cur_index eq 0 then begin
		dat=array_struc(cur_index)
		dat.valid=0
		return,dat
	endif else begin
		cur_index=cur_index-1 
	endelse
endif
	
return,array_struc(cur_index)

end
