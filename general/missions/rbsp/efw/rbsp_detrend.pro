;Detrends tplot data with boxcar average. 
;Returns two new tplot variables
;	tname + '_mean' -> the mean value
;	tname + '_detrend' -> original data - mean value 


;tnames -> array of tplot variables
;sec -> seconds used to calculate the mean value


;Created by: Aaron Breneman
;2012-11-05
;2014-04-13 -> added support for multi-dimensional tplot variables


pro rbsp_detrend,tnames,sec

	tn = tnames(tnames)

	if ~keyword_set(sec) then sec = 60.
	
        if tn[0] ne '' then begin
           for j=0,n_elements(tn)-1 do begin
              
              get_data,tn[j],data=dat
              
              sz = size(dat.y,/n_dimensions)
              if sz eq 2 then begin 
                 nvec = size(dat.y,/dimensions)
                 nvec = nvec[1]		
              endif else nvec = 1
              
              
              
              if is_struct(dat) then begin
                 
                                ;Calculate sample rate	

                 goo = rbsp_sample_rate(dat.x,out_med_avg=avg)
                 sr = avg[0]

                 n_samples = sr*sec
                 num = n_elements(dat.x)/n_samples
                 
                 
                                ;calculate width to smooth over
                 width = floor(sec * sr)
                 
                 dat_smoothed = dat.y
                 for q=0,nvec-1 do dat_smoothed[*,q] = smooth(dat.y[*,q],width,/nan)
                 
                 store_data,tn[j] + '_smoothed',data={x:dat.x,y:dat_smoothed}
                 store_data,tn[j] + '_detrend',data={x:dat.x,y:dat.y - dat_smoothed}
                 
                 
              endif else print,'NO TPLOT VARIABLE ' + tn[j]
              
              
           endfor
        endif else print,'NO TPLOT VARIABLES'

end
