;+
;PURPOSE:	To return SESA Burst Data for a specific time from the fa_seb1/2/3/4/5/6_l1 common block.
;USEAGE:	dat=get_fa1_seb1/2/3/4/5/6(t)
;			dat=get_fa1_seb1/2/3/4/5/6() will call ctime.pro to get t.
;			The routine assumes the l1 common block for datatype is already loaded into IDL.
;KEYWORDS:	/START to return data structure for the first time in common block.
;			/EN to return data structure for the last time in common block.
;			/ADVANCE to return the next data structure in the common block.
;			/RETREAT to return the previous data structure in the common block.
;			INDEX=INDEX to return the INDEXth data structure in the common block.
;			/TIMES returns array of starting times in l1 common block instead of data structure.
;			UNITS=UNITS allows you to choose the returned data's units.  Default is compressed.
;UPDATES:	
;-

function get_fa1_seb1,t,units=units,_EXTRA=extra

common fa_seb1_l1,get_ind,all_dat

if NOT keyword_set(units) then units='Counts'
return,fa_seb_struct_l1(t,units=units,all_dat=all_dat,get_ind=get_ind,_EXTRA=extra)

end