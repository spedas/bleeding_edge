;+
;	Name: SUPERPO_HISTO
;
;	Purpose:  This routine calculates the minimum (maximum, etc.) function of
;             several time series. The time bin (resolution) can be specified.
;             An example would be the calculation of AL (AU, AE) indices. The
;             results are stored in tplot variables. This routine only uses
;             the actual values in the time series; no interpolation is done.
;             An alternative routine exists which interpolates ('superpo_interpol').
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
;       output_names: an array that stores the tplot variable names created 
;                     by this routine
;
;	Example:
; 		superpo_histo,'thg_mag_ccnv_x thg_mag_drby_x thg_mag_fsim_x
;				       thg_mag_fsmi_x thg_mag_fykn_x',
;			           min='thg_pseudoAL',avg='thg_avg'
;					   res=600.0
;
;		superpo_histo,'thg_mag_????_x',min='thg_pseudoAL', res=30.0
;
; 		superpo_histo,'thg_mag_????_x' ; default values for all keywords
;
;   Speed:
;       With an input of magnetometer data from 27 ground stations (178000 data points each)
;       and a bin resolution of 60 s (res=60.0), the running time is about 3 sec (using IBM PC).
;       With res=1.0, the running time is about 9 sec.
;
;   Notes:
;       Written by Andreas Keiling, 30 July 2007
;
; $LastChangedBy:   $
; $LastChangedDate:   $
; $LastChangedRevision:  $
; $URL $
;-


pro superpo_histo, quantities,res=res,min=min,max=max,dif=dif,avg=avg,med=med,$
                   output_names=output_names,_extra=_extra ;, _ref_extra = _ref_extra

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

; look up beginning and end time of interval
t=timerange()
min_t = t[0]
max_t = t[1]

; determine maximum array size (size_y) among all input quantities (which can
; vary in size) and maximum array size (size_r) for the corresponding reversed
; indices, both sizes are needed to create two arrays that can hold
; the data (see below)
; Note: The need for size_y and size_r is because it is not possible to
; have an array (NxM) where the size of M varies for different N.
size_y=0.0
size_r=0.0
for s=0,n_name_array-1 do begin
; iterates through all input quantities (e.g., ground stations)
	get_data,name_array[s],data=temp
	dummy=histogram(temp.x,min=min_t,max=max_t,binsize=res,reverse_indices=r)
	n1 = n_elements(temp.y)
	n2 = n_elements(r)
	if (n1 gt size_y) then size_y=n1
	if (n2 gt size_r) then size_r=n2
endfor

; transfer content of tplot variables onto array ('values')
; on which to operate in the main routine (below)
values=fltarr(n_name_array,size_y)
r_index=fltarr(n_name_array,size_r)
for s=0,n_name_array-1 do begin
	get_data,name_array[s],data=temp
	dummy=histogram(temp.x,min=min_t,max=max_t,binsize=res,reverse_indices=r)
	l1=n_elements(temp.y)
	l2=n_elements(r)
	values[s,0:l1-1]=temp.y
	r_index[s,0:l2-1]=r
endfor

; initialize number of bins (n_bins)
n_bins = n_elements(dummy)

; declare arrays which will hold the results
min_array=fltarr(n_bins)
max_array=fltarr(n_bins)
dif_array=fltarr(n_bins)
avg_array=fltarr(n_bins)
med_array=fltarr(n_bins)

; create time axis (t) - midpoint of each time bin
t = min_t+res*dindgen(n_bins) + res/2D



;#######################################################
;                   main routine
;#######################################################

for j=0.0,n_bins-1.0 do begin
    bin_values = [!values.f_nan]
	for s=0,n_name_array-1 do begin
		if(r_index[s,j] ne r_index[s,j+1]) then begin
			ss = r_index[s, r_index[s,j]:r_index[s,j+1]-1]  ;subscripts in this time bin
			bin_values=[bin_values,reform(values[s,ss])]
		endif
    endfor

	if (keyword_set(min) OR keyword_set(max) OR keyword_set(dif)) then begin
		min_array[j]=min(bin_values,MAX=max_value,/NaN)
		max_array[j]=max_value
		dif_array[j]=max_array[j]-min_array[j]
	endif
	if keyword_set(avg) then avg_array[j]=total(bin_values,/NaN)/n_elements(bin_values)
	; strangely 'median' function does not allow a /NaN keyword
	if keyword_set(med) then med_array[j]=median(bin_values)
endfor



;#######################################################
;               create tplot variables
;#######################################################

if keyword_set(min) then begin
    store_data,min,data={x:t,y:min_array}
    append_array, output_names, min
endif
if keyword_set(max) then begin
    store_data,max,data={x:t,y:max_array}
    append_array, output_names, max
endif
if keyword_set(dif) then begin
    store_data,dif,data={x:t,y:dif_array}
    append_array, output_names, dif
endif
if keyword_set(avg) then begin 
    store_data,avg,data={x:t,y:avg_array}
    append_array, output_names, avg
endif
if keyword_set(med) then begin
    store_data,med,data={x:t,y:med_array}
    append_array, output_names, med
endif
end
