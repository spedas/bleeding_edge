;+
;PURPOSE:	To return Electron Survey Data for a specific time from the fa_ees_l2 common block.
;USEAGE:	dat=get_fa2_ees(t)
;		dat=get_fa2_ees() will call ctime.pro to get t.
;		The routine assumes the l2 common block for datatype is already loaded into IDL.
;KEYWORDS:	/START to return data structure for the first time in common block.
;		/EN to return data structure for the last time in common block.
;		/ADVANCE to return the next data structure in the common block.
;		/RETREAT to return the previous data structure in the common block.
;		INDEX=INDEX to return the INDEXth data structure in the common block.
;		/TIMES returns array of starting times in l2 common block instead of data structure.
;-

function get_fa2_ees,t,_EXTRA=extra

common fa_ees_l2,get_ind,all_dat

;convert to something useable in other programs, by changing the eflux
;tag to 'data'
otp = fa_esa_struct_l2(t,all_dat=all_dat,get_ind=get_ind,_EXTRA=extra)
str_element, otp, 'eflux', success = l2_struct
If(l2_struct) Then Begin
   eflux = otp.eflux
   str_element, otp, 'data', eflux, /add_replace
Endif

return, otp

end
