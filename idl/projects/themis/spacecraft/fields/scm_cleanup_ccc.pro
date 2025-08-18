;+
;FUNCTION: SCM_CLEANUP_CCC
;
;PURPOSE: cleans 8 hertz and harmonic instrument noise from scm data using 
;       superposed epoch analysis.
;	The raw data is high pass filtered above 4 Hz and then averaging on
;	this filtered data is performed to determine the noise.
;	Returns de-noised data and stores tplot quantity of this data
;
;INPUTS:requires 3-component single spacecraft data structure from thm_load_scm
;
;OUTPUT: data structure of 3 component cleaned data
;
;KEYWORDS:
;  probe: use this keyword to specify spacecraft if other than 'a'
;  clock: set keyword clock to base epoch on the 1 sec clock pulse closest to
;         the start of the interval otherwise epoch is from the beginning of
;         each interval
;
;  ave_window: set keyword ave_window to define window length in seconds for
;         averaging, Default 3 seconds in length
;         note for technique to work the window length should be an integer
;         multiple of the period of the noise
;         that is being removed.
;
;  min_num_windows: set keyword min_num_windows to define the minimum length
;         of continuous data in terms of window lengths
;         default is 10. The greater this number the more reliable the result.
;
;  diagnostic: set keyword diagnostic to plot spectral data and to store the
;         average noise, filtered (>4Hz) corrected signal,
;         and corrected signal for the last continuous interval anlaysed
;
;SIDE EFFECTS: in current version data preceding the epoch for each interval
;         is discarded
;
;HISTORY
;Chris Chaston 9-May-2007
;Modified by Olivier Le Contel 5th-July-2007
;  in order to include it in thm_cal_scm_ccc.pro routine
;  thm_cal_scm_ccc being a modified version of
;  thm_cal_scm routine written by Ken Bromund and Patrcik Robert
;Modified by Ken Bromund 27-Sept-2007
;  for inclusion in TDAS (use time routines available in TDAS)
;
;$LastChangedBy: aaflores $
;$LastChangedDate: 2012-01-09 15:50:20 -0800 (Mon, 09 Jan 2012) $
;$LastChangedRevision: 9520 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/spacecraft/fields/scm_cleanup_ccc.pro $
;-


function scm_cleanup_ccc,noisy_data,$
		     clock=clock,$
		     ave_window=ave_window,$
		     min_num_windows=min_num_windows


	datax={x:noisy_data.x,y:double(noisy_data.y(*,0))}
	datay={x:noisy_data.x,y:double(noisy_data.y(*,1))}
	dataz={x:noisy_data.x,y:double(noisy_data.y(*,2))}

	if keyword_set(clock) then begin
		thm_load_hsk,probe=satname,varformat='*onesec*'
		get_data,'tha_hsk_onesecmark_raw',data=onesec_mark
	endif

	;set the width of the averaging window

	if keyword_set(ave_window) then delta_t=ave_window else delta_t=3.0;seconds
	dprint, 'window duration',delta_t

	;set minimum number of consecutive windows of delta_t required for meaningful result

	if keyword_set(min_num_windows) then minimum_windows=min_num_windows else minimum_windows=10;
	valid=0.0


	number_points= n_elements(datax.x)
	dprint, 'start time ',time_string(datax.x(0), precision=7)
	dprint, 'stop time ', time_string(datax.x(number_points-1), precision=7)
	dprint, 'number of points ',number_points
	index_range=[findgen(number_points)]
	sampling_frequency=1.0/(datax.x(index_range(1))-datax.x(index_range(0)))
	nyquist=sampling_frequency/2.0
	dprint, sampling_frequency
	dprint, index_range(0),index_range(n_elements(index_range)-1)


	;determine number of averaging intervals

	n_stretch=floor(number_points/(delta_t*sampling_frequency))

	dprint, 'mininum number of windows asked',minimum_windows
	dprint, 'available number of windows',n_stretch

	if n_stretch GE minimum_windows then begin

		;extract sub_array

		datax_sub={x:datax.x(index_range),y:datax.y(index_range)}
		datay_sub={x:datay.x(index_range),y:datay.y(index_range)}
		dataz_sub={x:dataz.x(index_range),y:dataz.y(index_range)}

		;apply high pass filter above 4 Hz and store data

		datax_sub_f=time_domain_filter(datax_sub,4.0,nyquist)
		store_data,'datax_sub_f',data=datax_sub_f
		datay_sub_f=time_domain_filter(datay_sub,4.0,nyquist)
		store_data,'datay_sub_f',data=datay_sub_f
		dataz_sub_f=time_domain_filter(dataz_sub,4.0,nyquist)
		store_data,'dataz_sub_f',data=dataz_sub_f

		if keyword_set(clock) then begin
			;begin averaging from the closest one sec mark from the beginning of the second window of interval

			temp=min(abs(datax_sub.x(0)-onesec_mark.x),epoch_index)
			if onesec_mark.x(epoch_index) LT (datax_sub.x(0)+delta_t) then  epoch_index=epoch_index+1

			endif else begin
			;begin averaging from the second window to avoid end effects in the filtering

			epoch_index=0L
			;floor(sampling_frequency*delta_t,/L64)+1;begin averaging from the second window to avoid end effects in the filtering

			endelse
		;begin averaging

		count=0L
		end_window_index=floor(epoch_index+sampling_frequency*delta_t,/L64)-1L
		tot_stretchx=datax_sub_f.y(epoch_index:end_window_index)
		tot_stretchy=datay_sub_f.y(epoch_index:end_window_index)
		tot_stretchz=dataz_sub_f.y(epoch_index:end_window_index)

		while end_window_index LE number_points-sampling_frequency*delta_t do begin

				count=count+1L

				start_window_index=epoch_index+floor(sampling_frequency*delta_t,/L64)*(count)
				end_window_index=epoch_index+floor(sampling_frequency*delta_t,/L64)*(count+1L)-1L
				;print,start_window_index,end_window_index,number_points

				stretchx=datax_sub_f.y(start_window_index:end_window_index)
				tot_stretchx=tot_stretchx+stretchx

				stretchy=datay_sub_f.y(start_window_index:end_window_index)
				tot_stretchy=tot_stretchy+stretchy

				stretchz=dataz_sub_f.y(start_window_index:end_window_index)
				tot_stretchz=tot_stretchz+stretchz

		endwhile


		ave_stretchx=tot_stretchx/(count+1L)
		ave_stretchy=tot_stretchy/(count+1L)
		ave_stretchz=tot_stretchz/(count+1L)

		;create noise data array of length multiples of averaging window from epoch

		noise_x=make_array((count+1L)*floor(delta_t*sampling_frequency,/L64)+1L,/double)
		noise_y=make_array((count+1L)*floor(delta_t*sampling_frequency,/L64)+1L,/double)
		noise_z=make_array((count+1L)*floor(delta_t*sampling_frequency,/L64)+1L,/double)


		for j=0L,count do begin
			noise_x(floor(sampling_frequency*delta_t,/L64)*j:floor(sampling_frequency*delta_t,/L64)*(j+1)-1)=ave_stretchx
			noise_y(floor(sampling_frequency*delta_t,/L64)*j:floor(sampling_frequency*delta_t,/L64)*(j+1)-1)=ave_stretchy
			noise_z(floor(sampling_frequency*delta_t,/L64)*j:floor(sampling_frequency*delta_t,/L64)*(j+1)-1)=ave_stretchz
		endfor

		noise_x={x:datax_sub_f.x(epoch_index:count*floor(delta_t*sampling_frequency,/L64)),y:noise_x}
		noise_y={x:datay_sub_f.x(epoch_index:count*floor(delta_t*sampling_frequency,/L64)),y:noise_y}
		noise_z={x:dataz_sub_f.x(epoch_index:count*floor(delta_t*sampling_frequency,/L64)),y:noise_z}

		;noise_x={x:datax_sub_f.x(epoch_index:(count+1)*delta_t*sampling_frequency),y:noise_x}
		;noise_y={x:datay_sub_f.x(epoch_index:(count+1)*delta_t*sampling_frequency),y:noise_y}
		;noise_z={x:dataz_sub_f.x(epoch_index:(count+1)*delta_t*sampling_frequency),y:noise_z}

		;create corrected filtered time series

		corrected_f_x=datax_sub_f.y(epoch_index:count*floor(delta_t*sampling_frequency,/L64))-noise_x.y
		corrected_f_y=datay_sub_f.y(epoch_index:count*floor(delta_t*sampling_frequency,/L64))-noise_y.y
		corrected_f_z=dataz_sub_f.y(epoch_index:count*floor(delta_t*sampling_frequency,/L64))-noise_z.y

		corrected_f_x={x:datax_sub_f.x(epoch_index:count*floor(delta_t*sampling_frequency,/L64)),y:corrected_f_x}
		corrected_f_y={x:datay_sub_f.x(epoch_index:count*floor(delta_t*sampling_frequency,/L64)),y:corrected_f_y}
		corrected_f_z={x:dataz_sub_f.x(epoch_index:count*floor(delta_t*sampling_frequency,/L64)),y:corrected_f_z}

		;corrected_f_x=datax_sub_f.y(epoch_index:(count+1)*delta_t*sampling_frequency)-noise_x.y
		;corrected_f_y=datay_sub_f.y(epoch_index:(count+1)*delta_t*sampling_frequency)-noise_y.y
		;corrected_f_z=dataz_sub_f.y(epoch_index:(count+1)*delta_t*sampling_frequency)-noise_z.y

		;corrected_f_x={x:datax_sub_f.x(epoch_index:(count+1)*delta_t*sampling_frequency),y:corrected_f_x}
		;corrected_f_y={x:datay_sub_f.x(epoch_index:(count+1)*delta_t*sampling_frequency),y:corrected_f_y}
		;corrected_f_z={x:dataz_sub_f.x(epoch_index:(count+1)*delta_t*sampling_frequency),y:corrected_f_z}



		;create corrected time series

		corrected_x=datax_sub.y(epoch_index:count*floor(delta_t*sampling_frequency,/L64))-noise_x.y
		corrected_y=datay_sub.y(epoch_index:count*floor(delta_t*sampling_frequency,/L64))-noise_y.y
		corrected_z=dataz_sub.y(epoch_index:count*floor(delta_t*sampling_frequency,/L64))-noise_z.y

		corrected_x={x:datax_sub_f.x(epoch_index:count*floor(delta_t*sampling_frequency,/L64)),y:corrected_x}
		corrected_y={x:datay_sub_f.x(epoch_index:count*floor(delta_t*sampling_frequency,/L64)),y:corrected_y}
		corrected_z={x:dataz_sub_f.x(epoch_index:count*floor(delta_t*sampling_frequency,/L64)),y:corrected_z}

		;corrected_x=datax_sub.y(epoch_index:(count+1)*delta_t*sampling_frequency)-noise_x.y
		;corrected_y=datay_sub.y(epoch_index:(count+1)*delta_t*sampling_frequency)-noise_y.y
		;corrected_z=dataz_sub.y(epoch_index:(count+1)*delta_t*sampling_frequency)-noise_z.y

		;corrected_x={x:datax_sub_f.x(epoch_index:(count+1)*delta_t*sampling_frequency),y:corrected_x}
		;corrected_y={x:datay_sub_f.x(epoch_index:(count+1)*delta_t*sampling_frequency),y:corrected_y}
		;corrected_z={x:dataz_sub_f.x(epoch_index:(count+1)*delta_t*sampling_frequency),y:corrected_z}



		if valid EQ 0 then begin
			tot_corrected_time=corrected_x.x
			tot_corrected_x=corrected_x.y
			tot_corrected_y=corrected_y.y
			tot_corrected_z=corrected_z.y
			valid=1.0
		endif else begin
			tot_corrected_time=[tot_corrected_time,corrected_x.x]
			tot_corrected_x=[tot_corrected_x,corrected_x.y]
			tot_corrected_y=[tot_corrected_y,corrected_y.y]
			tot_corrected_z=[tot_corrected_z,corrected_z.y]
		endelse


		endif else dprint, 'insufficient continuous data for this interval'



corrected_scm_data={x:tot_corrected_time,y:transpose([transpose(tot_corrected_x),transpose(tot_corrected_y),transpose(tot_corrected_z)])}
return,corrected_scm_data
end
