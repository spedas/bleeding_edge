;+
;	Name: SUPERPO_INTERPOL
;
;	Purpose:  This routine calculates the minimum (maximum, etc.) function of
;             several time series. The time bin (resolution) can be specified.
;             An example would be the calculation of AL (AU, AE) indices. The
;             results are stored in tplot variables. This routine interpolates
;             at desired sampling rate. An alternative routine exists which does
;             not interpolate (see 'superpo_histo').
;
;	Variable:
;
;		quantities = string of tplot variable names (e.g., ground stations)
;
;	Keywords:
;		res        = sampling interval (by default 60 sec)
;		min        = e.g., 'thg_pseudoAL'
;		max	       = e.g., 'thg_pseudoAU
;		dif	       = e.g., 'thg_pseudoAE
;		avg	       = average values
;       med        = median values
;
;	Example:
; 		superpo_interpol,'thg_mag_ccnv_x thg_mag_drby_x thg_mag_fsim_x
;				          thg_mag_fsmi_x thg_mag_fykn_x',
;			        	  min='thg_pseudoAL',avg='thg_avg'
;						  res=600n.0,
;
;		superpo_interpol,'thg_mag_????_x',min='thg_pseudoAL', res=30.0
;
; 		superpo_interpol,'thg_mag_????_x' ; default values for all keywords
;
;   Speed:
;       With an input of magnetometer data from 27 ground stations (178000 data points each)
;       and a bin resolution of 60 s (res=60.0), the running time is less than 1 sec (using IBM PC).
;       With res=1.0, the running time is around 1 sec.
;
;   Notes:
;       Written by Andreas Keiling, 30 July 2007
;
; $LastChangedBy:   $
; $LastChangedDate:   $
; $LastChangedRevision:  $
; $URL $
;-


pro superpo_interpol, quantities,res=res,min=min,max=max,dif=dif,avg=avg,med=med


;#######################################################
;               initialize variables
;#######################################################

; set default names for output quantities
if not (keyword_set(min) OR keyword_set(max) OR $
		keyword_set(avg) OR keyword_set(dif) OR $
		keyword_set(med)) then begin
	min='minarr'
	max='maxarr'
	avg='avgarr'
	dif='difarr'
	med='medarr'
endif

; set default time resolution
if not keyword_set(res) then res = 60d   ; 60 sec resolution
res=double(res)

; create array (name_array) containing names of input tplot quantities
tplot_names,quantities,names=name_array
n_name_array=n_elements(name_array)

; determine number of interpolation samples
t=timerange()
n_sample = (t[1]-t[0])/res

; declare arrays which will hold the results
min_array=fltarr(n_sample)
max_array=fltarr(n_sample)
dif_array=fltarr(n_sample)
avg_array=fltarr(n_sample)
med_array=fltarr(n_sample)

; create time axis (t) - midpoint of each sample bin
t_sample = t[0]+res*dindgen(n_sample) + res/2D
min_t = t_sample[0]
max_t = t_sample[n_sample-1]

; read and interpolate all tplot variables into array (MxN)
; where  M is the number of stations and N is the number of
; interpolated samples
quant_array=fltarr(n_name_array,n_sample)
for i=0,n_name_array-1 do begin
	get_data,name_array[i], data=temp
	quant_array[i,*] = interpol(temp.y,temp.x,t_sample)
    ; set values that are out of bound to NaN
	min_x=temp.x[0]
	max_x=temp.x[n_elements(temp.x)-1]
	if min_t lt min_x then begin
		i1=where(t_sample lt min_x)
		quant_array[i,i1] = !values.f_nan
	endif
	if max_t gt max_x then begin
		i2=where(t_sample gt max_x)
		quant_array[i,i2] = !values.f_nan
	endif
endfor



;###################################################
;                  main routine
;###################################################

if (keyword_set(min) OR keyword_set(max) OR keyword_set(dif)) then begin
	min_array=min(quant_array,dimension=1,max=max_value,/NAN)
	max_array=max_value
	dif_array=max_array-min_array
endif
; strangely 'median' function does not allow a /NAN keyword
if keyword_set(med) then med_array=median(quant_array,dimension=1)
d=1  ; strangely 'total' function does not allow dimension keyword, only 2nd argument
if keyword_set(avg) then avg_array=total(quant_array,d,/NAN)/n_name_array




;#######################################################
;               create tplot variables
;#######################################################

if keyword_set(min) then store_data,min,data={x:t_sample,y:min_array}
if keyword_set(max) then store_data,max,data={x:t_sample,y:max_array}
if keyword_set(dif) then store_data,dif,data={x:t_sample,y:dif_array}
if keyword_set(avg) then store_data,avg,data={x:t_sample,y:avg_array}
if keyword_set(med) then store_data,med,data={x:t_sample,y:med_array}


end