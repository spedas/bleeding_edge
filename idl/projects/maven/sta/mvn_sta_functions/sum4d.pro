;+
;FUNCTION: sum4d
;PURPOSE: Takes two 4D structures and returns a single 4D structure whose data is the sum of the two
;INPUTS: d1,d2  each must be 4D structures obtained from the get_?? routines
;	e.g. "get_mvn_d0"
;RETURNS: single 4D structure
;
;CREATED BY:	McFadden
;LAST MODIFICATION:	@(#)sum3d.pro	1.6 14/01/31
;
;Notes: This is a very crude subroutine. Use at your own risk.
;-



function  sum4d, d1,d2
if size(/type,d1) ne 8 then return,d2
if d2.valid eq 0 then return,d1
if d1.valid eq 0 then return,d2
if d1.data_name ne d2.data_name or d1.mode ne d2.mode then begin
  print,'SUM4D: Incompatible data types'
  return,d2
endif
sum = d1

value=0 & str_element,sum,'data',value
	if n_elements(value) gt 1 then sum.data = sum.data+d2.data
value=0 & str_element,sum,'rates',value
	if n_elements(value) gt 1 then sum.rates = (sum.rates*sum.integ_t+d2.rates*d2.integ_t)/(sum.integ_t+d2.integ_t)

value=-1 & str_element,sum,'quality_flag',value
	if value ge 0 then begin
		value=-1 & str_element,sum,'att_ind',value
		if value ge 0 then begin
			sum.quality_flag = sum.quality_flag or d2.quality_flag or (64 * (sum.att_ind ne d2.att_ind))
		endif else begin
			sum.quality_flag = sum.quality_flag or d2.quality_flag
		endelse
	endif

;sum.delta_t =  d1.delta_t + d2.delta_t
;sum.delta_t =  d2.end_time - d1.time
sum.integ_t =  d1.integ_t + d2.integ_t
sum.end_time = d1.end_time > d2.end_time
sum.time     = d1.time     < d2.time
sum.valid  = d1.valid and d2.valid

value=0 & str_element,sum,'delta_t',value
	if size(value,/type) eq 5 then sum.delta_t= (d1.delta_t + d2.delta_t)
value=0 & str_element,sum,'sc_pot',value
;	if value le 0 or value ge 0 then sum.sc_pot= (d1.sc_pot*d1.integ_t + d2.sc_pot*d2.integ_t)/sum.integ_t
	if size(value,/type) eq 4 then sum.sc_pot= (d1.sc_pot*d1.integ_t + d2.sc_pot*d2.integ_t)/sum.integ_t

value=0 & str_element,sum,'b_gse',value
	if n_elements(value) gt 1 then sum.b_gse= (d1.b_gse*d1.integ_t + d2.b_gse*d2.integ_t)/sum.integ_t
;value=0 & str_element,sum,'magf',value
;	if n_elements(value) gt 1 then sum.magf= (d1.magf*d1.integ_t + d2.magf*d2.integ_t)/sum.integ_t
value=0 & str_element,sum,'quat_sc',value
	if n_elements(value) gt 1 then sum.quat_sc= (d1.quat_sc*d1.integ_t + d2.quat_sc*d2.integ_t)/sum.integ_t
value=0 & str_element,sum,'quat_mso',value
	if n_elements(value) gt 1 then sum.quat_mso= (d1.quat_mso*d1.integ_t + d2.quat_mso*d2.integ_t)/sum.integ_t
value=0 & str_element,sum,'pos_sc_mso',value
	if n_elements(value) gt 1 then sum.pos_sc_mso= (d1.pos_sc_mso*d1.integ_t + d2.pos_sc_mso*d2.integ_t)/sum.integ_t
value=0 & str_element,sum,'magf',value
	if n_elements(value) gt 1 then sum.magf= (d1.magf*d1.integ_t + d2.magf*d2.integ_t)/sum.integ_t
value=0 & str_element,sum,'bkg',value
	if n_elements(value) gt 1 then sum.bkg= (d1.bkg + d2.bkg)
value=0 & str_element,sum,'cnts',value
	if n_elements(value) gt 1 then sum.cnts= (d1.cnts + d2.cnts)
value=0 & str_element,sum,'bins_sc',value
	if n_elements(value) gt 1 then sum.bins_sc= (d1.bins_sc and d2.bins_sc)
value=0 & str_element,sum,'dead',value
	if n_elements(value) gt 1 then sum.dead= (d1.integ_t*d1.dead^2 + d2.integ_t*d2.dead^2)/(d1.integ_t*(d1.dead>1.) + d2.integ_t*(d2.dead>1.))

;print,'test'
return, sum
end