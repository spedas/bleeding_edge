
;+
; 
; Name: 
;   spd_tplot_average.pro
; 
; Purpose: 
;   Returns the average value of a tplot variable over a specified time range.
; 
; Calling Sequence:
;   result = spd_tplot_average( tplot_var, trange [,interpolate=interpolate] )
;
; Input:
;   tplot_var: String containing the name of valid tplot variable
;   trange: String or double specifying the time range
;   interpolate: Flag to attempt interpolation from data outside the specifed 
;                range if none is found within.  At least 20 min or half the 
;                specified range will be checked past both time limits.
; 
; Output:
;   return value: averate of tplot variable's y component or NaN if unsuccessful 
;
; Example Usage:
;   trange = '2008-4-12/' + ['01:00','02:00']
;   bfield_ave = spd_tplot_average('bfield_data', trange)
;   
; Notes:
;
;
;$LastChangedBy: aaflores $
;$LastChangedDate: 2016-05-13 17:46:11 -0700 (Fri, 13 May 2016) $
;$LastChangedRevision: 21085 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/science/spd_slice2d/core/spd_tplot_average.pro $
;-

function spd_tplot_average, tvar, trange_in, center=center, interpolate=interpolate, _extra=_extra

    compile_opt idl2, hidden


tn = '_spd_tavg_tmp'

get_data, tvar, data=d, index=i

;Error Checks
if i eq 0 then begin
	dprint, dlevel=1,  'Error: ' + tvar + ' does not exist'
	return, !values.D_NAN
endif

if n_elements(trange_in) ne 2 then begin
  dprint, dlevel=1, 'Error: time range must be two element array'
  return, !values.d_nan
endif

trange = time_double(trange_in)

t0 = min(trange)
t1 = max(trange)

if t1 eq t0 then begin
  dprint, dlevel=1, 'Error: time range is zero'
  return, !values.D_NAN
endif

dprint, dlevel=4, 'Averaging '+tvar

;Find data within time range
index = where(d.x le t1 and d.x ge t0, count)

;calc average if data exists in range
if count ne 0 then begin

  if keyword_set(center) then begin
    ;get sample closest to center of time range
    dummy = min( d.x - (t0+t1)/2 ,center_idx, /absolute)
    output = d.y[center_idx,*,*]
  endif else begin
  	output = total(d.y[index,*,*],1)/n_elements(index)
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

  ;remove temp vars
  store_data, '*'+tn+'*', /delete

  if ~is_struct(dout) then begin
    dprint, dlevel=0, 'Error interpolating "'+tvar+'" data from outside specified time range.'
    return, !values.d_nan
  endif  

	if ndimen(dout.y) eq 0 then output = dout.y else output = reform(dout.y)

endif else begin
  dprint, dlevel=1, 'Error: '+tvar+' contains no data within the specified time range'
  return, !values.D_NAN
endelse

return, output


end

