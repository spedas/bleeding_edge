;Remove data spikes from tplot data. Spikes are identified with derivative

;der_limit -> the maximum value of derivative b/t two successive
;				time steps to allow
;samename -> set to overwrite the original tplot variable. Otherwise
;				saves as new tplot variable with "_nospike" added


pro rbsp_remove_spikes,tnames,der_limit=derlim,samename=sn

	if ~keyword_set(derlim) then derlim=100

	
	for j=0,n_elements(tnames)-1 do begin
	
		get_data,tnames[j],data=dat

		if is_struct(dat) then begin
			der = deriv(dat.y)
					
			goo = where(abs(der) ge derlim)
			
			if goo[0] ne -1 then begin
				dat.y[goo] = !values.f_nan
				if keyword_set(sn) then begin
					store_data,tnames[j],data=dat
					print,'Creating tplot variable ' + tnames[j]
				endif else begin 
					store_data,tnames[j]+'_nospike',data=dat
					print,'Creating tplot variable ' + tnames[j]+'_nospike'
				endelse
			endif	
			
;			store_data,'deriv',data={x:dat.x,y:der}			
;			store_data,'Bw_detrend2',data=dat
			
;			ylim,'Bw_detrend2',-10,10
;			tplot,['Bw_detrend','deriv','Bw_detrend2']
			
		endif else print,tnames[j] + ' is not a proper tplot variable (remove_spikes.pro)'	
	endfor
end




