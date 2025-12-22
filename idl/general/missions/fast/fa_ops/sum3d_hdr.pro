;+
;FUNCTION: sum3d_hdr
;PURPOSE: Takes two 3D structures and returns a single 3D structure
;  whose data is the sum of the two, checks header and spin compatibility.
;INPUTS: d1,d2  each must be 3D structures obtained from the get_?? routines
;	e.g. "get_el"
;KEYWORDS:
;	HDR=hdr		array(n)	List of array indexes in dat.header_bytes 
;					to be compared. 
;					If not the same, returns d1 with d1.valid=2
;	Spin		1,0		If set, will check FAST spin number.
;					If not the same, returns d1 with d1.valid=2
;RETURNS: single 3D structure
;
;CREATED BY:	modified from sum3d.pro created by Davin Larson
;LAST MODIFICATION: Mcfadden 	 96/7/1
;
;Notes: This is a very crude subroutine. Use at your own risk.
;-


function  sum3d_hdr, d1,d2,HDR_IND=hdr,SPIN=spin
if d1.valid eq 0 then return,d2
if d2.valid eq 0 then return,d1
if d1.valid eq 2 then return,d1
if data_type(d1) ne 8 then return,d2
if d1.data_name ne d2.data_name then begin
  print,'Incompatible data types'
  return,d2
endif
if keyword_set(hdr) then begin
	index=where(d1.header_bytes(hdr) ne d2.header_bytes(hdr),count)
	if (count ne 0) then begin
		print,'Incompatible header bytes, spin average failed at t=',d1.time
		d1.valid=2
		return,d1
	endif
endif
if keyword_set(spin) then begin
	if fix(d1.header_bytes(1)/4) ne fix(d2.header_bytes(1)/4) then begin
		print,'Spin number change, spin average failed at t=',d1.time
		print,'Spin numbers=',fix(d1.header_bytes(1)/4),fix(d2.header_bytes(1)/4)
		d1.valid=2
		return,d1
	endif
endif
if ndimen(d1.geom) ne ndimen(d2.geom) then begin 
	print,'dat.geom array dimensions incompatible, spin average failed at t=',d1.time
	d1.valid=2
	return,d1
endif
if d1.nenergy ne d2.nenergy or d1.nbins ne d2.nbins then begin
	print,'Array dimensions incompatible, spin average failed at t=',d1.time
	d1.valid=2
	return,d1
endif
sum = d1
sum.data = sum.data+d2.data
sum.integ_t =  d1.integ_t + d2.integ_t
sum.geom = (d1.integ_t*d1.geom + d2.integ_t*d2.geom)/sum.integ_t
sum.end_time = d1.end_time > d2.end_time
sum.time     = d1.time     < d2.time
sum.valid  = d1.valid and d2.valid
return, sum
end


