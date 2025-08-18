
;+
; 
; Name: thm_dat_avg.pro
; 
; Purpose:  Averages data from tplot variable over specified 
;           time range and returns value.
; 
; Calling Sequence:
;   result = thm_dat_avg( tplot_var,  time1, time2 [,interpolate=interpolate])
;
; Arguments:
;   tplot_var: String containing the name of valid tplot variable
;   time1: String or double precision number specifying a time range boundary
;   time2: String or double precision number specifying a time range boundary
;          (time1 / time 2 may be in any order)
;
; Keywords:
;   interpolate: Flag to attempt interpolation from data outside the specifed 
;                range if none is found within.  At least 20 min or half the 
;                specified range will be checked past both time limits.
; 
; Example:
;   t1 = '2008-4-12/02:00'
;   t0 = '2008-4-12/01:00'
;   bfield_ave = thm_dat_avg('tha_fgs', t0, t1)
;   
;-

function thm_dat_avg, tvar, t_0, t_1, interpolate=interpolate, _extra=_extra

    compile_opt idl2, hidden


tn = '_thm_dat_avg_tmp'

get_data, tvar, data=d, index=i

;Error Checks
if i eq 0 then begin
	dprint, dlevel=1,  tvar + ' does not exist'
	return, !values.D_NAN
endif

if size(/type,t0) eq 7 then t0 = time_double(t_0)
if size(/type,t1) eq 7 then t1 = time_double(t_1)

if t_1 eq t_0 then begin
  dprint, dlevel=1, 'Error: time range is zero'
  return, !values.D_NAN
endif
if t_0 gt t_1 then begin
  t1 = t_0
  t0 = t_1
endif else begin
  t0 = t_0
  t1 = t_1
endelse

dprint, dlevel=4, 'Averaging '+tvar

;Find data within time range
index = where(d.x le t1 and d.x ge t0, count)

;calc average if data exists in range
if count ne 0 then begin
	if ndimen(d.y) eq 2 then begin
		avg = total(d.y[index,*],1)/n_elements(index)
	endif else begin 
		avg = total(d.y[index])/n_elements(index)
	endelse

;attempt to interpolate if no data in range  
endif else if keyword_set(interpolate) then begin

	dprint, dlevel=4,'No data points in trange for '+tvar +', interpolating'

  ;pad range by >= 20 min
  padding = (t1 - t0)/2d > 1200d 
	cutindex = where(d.x le t1 + padding and d.x ge t0 - padding, cc)
	
	if cc lt 2 then begin
	  dprint, dlevel=1, 'Error: '+tvar+' contains no data within '+ $
	                    strtrim(padding,2)+' sec of specified time range'
	  return, !values.D_NAN
	endif 
	
	;cut data before averaging 
	store_data, tvar+tn, data = {x:d.x[cutindex], y:d.y[cutindex,*]}

  ;temp variable for interpolation
  store_data, 'time'+tn,data = {x:(t1+t0)/2.}
	
	;interpolate data
	tinterpol_mxn, tvar + tn, 'time'+tn,newname='data_out'+tn, _extra=_extra

	get_data,'data_out'+tn, data = dout

  if ~is_struct(dout) then begin
    dprint, dlevel=0, 'Error interpolating "'+tvar+'" data from outside specified time range.'
    return, !values.d_nan
  endif  

	if ndimen(dout.y) eq 0 then avg = dout.y else avg = reform(dout.y)

  ;remove temp vars
  store_data, '*'+tn+'*', /delete

endif else begin
  dprint, dlevel=1, 'Error: '+tvar+' contains no data within the specified time range'
  return, !values.D_NAN
endelse

return, avg


end

