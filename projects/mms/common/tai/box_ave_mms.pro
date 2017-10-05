; This programs averages var2 onto ave1 time interval
; Common usage: average higher time resution FIELDS data onto lower time resolution plasma data
; created by Tai Phan 
; last update: Oct 20, 2015

pro box_ave_mms, variable1=var1, variable2=var2, var2ave=var2ave, start_time=start_time,end_time=end_time,inval=inval

get_data,var1,data=d
get_data,var2,data=d2



size_info=size(d2.y)

; find most typical time cadence in var1
time_diff_array=d.x(1:n_elements(d.x)-1)-d.x(0:n_elements(d.x)-2)
median, time_diff_array, n_elements(var), med

if not keyword_set (inval) then inval=med
print,'inval= ',inval

if not keyword_set (start_time) then start_time=d.x(0)
if not keyword_set (end_time) then end_time=d.x(n_elements(d.x)-1)

index_time=where(d.x ge time_double(start_time) and d.x le time_double(end_time))

store_data,var1,data={x:d.x(index_time),y:d.y(index_time,*)}

get_data,var1,data=d1

;store_data,var1+'_short',data={x:d.x(index_time),y:d.y(index_time,*)}

;get_data,var1+'_short',data=d1


if (size_info(0) eq 1) then begin
var2ave_y=fltarr(n_elements(d1.x))
endif else begin
var2ave_y=fltarr(n_elements(d1.x),size_info(2))
endelse

for i= 0, n_elements(d1.x) -1 do begin
index= where (abs(d2.x-d1.x(i)) le inval/2.)
	if index(0) ne -1 then begin
		if (size_info(0) eq 1) then begin
		var2ave_y(i)=total(d2.y(index))/float(n_elements(index))
		endif else begin
		for j=0,size_info(2)-1 do begin
			var2ave_y(i,j)=total(d2.y(index,j))/float(n_elements(index))
		endfor
		endelse
	endif else begin
		if (size_info(0) eq 1) then begin
			var2ave_y(i)=!values.f_nan
		endif else begin
			var2ave_y(i,*)=!values.f_nan	
		endelse
	endelse
;print,i,j

endfor

store_data,var2ave,data={x:d1.x,y:var2ave_y}

return

end

