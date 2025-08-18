;+
;FUNCTION: sum2d
;PURPOSE: Takes two 2D structures and returns a single 2D structure
;  whose data is the sum of the two
;INPUTS: d1,d2  each must be 3D structures obtained from the get_?? routines
;	e.g. "get_el"
;RETURNS: single 3D structure
;
;CREATED BY:	J. McFadden -- modified from D. Larson's sum3d.pro 96/06/27
;LAST MODIFICATION:	
;		J. McFadden - added theta,gf,geom averaging
;
;Notes:  
;-


function  sum2d, d1,d2
if data_type(d1) ne 8 then return,d2
if d2.valid eq 0 then return,d1
if d1.valid eq 0 then return,d2
if d1.data_name ne d2.data_name then begin
  print,'Incompatible data types'
  return,d2
endif
sum = d1
if d1.units_name eq 'Counts' or d1.units_name eq 'counts' then begin
	sum.data = d1.data+d2.data
endif else sum.data = (d1.data*d1.integ_t+d2.data*d2.integ_t)/(d1.integ_t+d2.integ_t)

sum.integ_t =  d1.integ_t + d2.integ_t
sum.end_time = d1.end_time > d2.end_time
sum.time     = d1.time     < d2.time
sum.valid  = d1.valid and d2.valid
sum.sc_pot= (d1.sc_pot*d1.integ_t + d2.sc_pot*d2.integ_t)/sum.integ_t

sum.theta = (d1.theta*d1.integ_t + d2.theta*d2.integ_t)/sum.integ_t
sum.gf = (d1.gf*d1.integ_t + d2.gf*d2.integ_t)/sum.integ_t
sum.geom = (d1.geom*d1.integ_t + d2.geom*d2.integ_t)/sum.integ_t


return, sum
end


