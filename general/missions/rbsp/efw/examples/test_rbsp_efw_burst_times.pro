;pro test_rbsp_efw_burst_times
;
;Purpose:	Finds times when vb1 and vb2 data are availale and creates
;			tplot variables rbsp{a,b}_efw_vb{1,2}_available that are
;			set equal to 1 when data is available, 0 otherwise.
;
;keywords:
;
;			N/A
;
;Example:
;   test_rbs_efw_burst_times
;
;Notes:
;	1. Created Mar 2012 - Kris Kersten (kris.kersten@gmail.com)
;   2. This routine assumes that RBSP burst waveform data is already loaded
;		in TPLOT variables.
;-

pro test_rbsp_efw_burst_times

	;========================================
	;--FIND BURST TIMES AND CREATE TPLOT VARS
	
	for vbcount=1,2 do begin
	
		bid='vb'+string(vbcount,format='(I1)')
		
		for pcount=0,1 do begin
			case pcount of
				0:probeid='a'
				1:probeid='b'
			endcase
			
			; first save an array of tplot names for individual vb1,vb2 traces
			vb_names=''
			tplot_names,'rbsp'+probeid+'_efw_'+bid+'*',names=vb_names
			; and extract the data from the first trace (combined)
			
			; check to see if we actually have vb? data.
			if strlen(vb_names[0]) eq 0 then begin
				; once the varnames keyword is implemented in
				; rbsp_load_efw_waveform.pro, we can temporarily load '*vb1*'
				; and '*vb2*' data to construct the vb1,2 flag variables, and
				; then clobber the '*vb1*' and '*vb2*' variables to conserve
				; memory.  for now, we just throw an error message and continue.
				print,'No valid burst variables found for RBSP'+strupcase(probeid)+' '+strupcase(bid)+'.',format='(/A/)'
			endif else begin
				get_data,vb_names[0],data=d,limits=l,dlimits=dl
				
				; now find bursts using variation of Bonnell's find_streaks algorithm
				otimes=d.x
				ntimes=size(otimes,/n_elements)
				; sandwich times array with -/+Inf so we see the first and last burst start/end
				times=[-!values.d_infinity,otimes,!values.d_infinity]
				dts=times[1L:ntimes+1]-times[0:ntimes]
				
				; set a threshold for determining whether or not a big dt indicates a break between bursts
				; we'll try 1.5 times the median dt
				dt=median(dts)
				dtmax=1.5*dt
				
				nbursts=0L
				iburst_start=-1L ; this will be an array of burst start indices, set to -1 initially
				iburst_end=-1L ; array of burst end indices
				
				ibreaks=where(dts gt dtmax, nbreaks)
				if nbreaks gt 0L then begin
					nbursts=nbreaks-1
					iburst_start=ibreaks[0L:nbursts-1L]
					iburst_end=ibreaks[1L:nbursts]-1L
				
			
					; now we need to construct an array of the form
					; flag = [..., off, on, on, off, ...]
					; time = [..., t_on-dt, t_on, t_off, t_off+dt, ...]

					zval=0.
					burst_flag=[zval,1,1,zval]
					burst_times=[otimes[iburst_start[0L]]-dt,otimes[iburst_start[0L]],$
						otimes[iburst_end[0L]],otimes[iburst_end[0L]]+dt]
					for iburst=1L,nbursts-1L do begin
						burst_flag=[burst_flag,zval,1,1,zval]
						burst_times=[burst_times,$
							otimes[iburst_start[iburst]]-dt,otimes[iburst_start[iburst]],$
							otimes[iburst_end[iburst]],otimes[iburst_end[iburst]]+dt]
					endfor
					
					; set burst flag off at t=00:00:00 and t=24:00:00, allowing for span across multiple days
					startday=time_string(otimes[0],precision=-3) ; precision=-3 gives 'YYYY-MM-DD'
					endday=time_string(otimes[ntimes-1],precision=-3)+'/24:00:00'
					burst_times=[time_double(startday),burst_times,time_double(endday)]
					burst_flag=[zval,burst_flag,zval]

					; and bundle it all up for tplot			
					bdata={x:burst_times, y:burst_flag}
					lim={yrange:[-.05,1.05],ystyle:1,colors:[4],thick:1.5,yticks:1, $
						ytickname:['off','on'],ticklen:0.,panel_size:.2}
					store_data,'rbsp'+probeid+'_efw_'+bid+'_available',data=bdata,limits=lim

				endif else begin
					print,'No bursts found for RBSP-'+strupcase(probeid)+' '+strupcase(bid)+'.',format='(/A/)'
				endelse

			endelse

		endfor

	endfor

	print,'Created:',format='(/A)'
	tplot_names,'*vb?_available'

end ; pro test_rbsp_efw_burst_times