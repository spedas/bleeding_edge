PRO del_data,names,except_ptrs=except_ptrs
;+
;NAME:                  del_data
;PURPOSE:
;			obsolete procedure!  use "STORE_DATA" instead
;                       delete tplot variables
;                       del_data calls "store_data" with the DELETE keyword set
;                       let: input=['a','b','c','d','e','f']
;                       then, del_data,input is the same as
;                       store_data,delete=input
;CALLING SEQUENCE:      del_data,input
;INPUTS:                input:  strarr() or intarr() of tplot variables
;LAST MODIFICATION:     @(#)del_data.pro	1.4 01/10/08
;CREATED BY:            Frank Marcoline
;-
if not keyword_set(names) then dprint,'Input required!' $
else  store_data,delete=tnames(names,cnt),except_ptrs=except_ptrs

end
