;+
; NAME: rbsp_efw_cal_fbk
;
; PURPOSE: Calibrate RBSP filterbank data
;
; NOTES: -This is meant to be called from rbsp_load_efw_fbk.pro
;		 -No check at this point to see if the channel changes over day. Now I'm using
;		  the channels at the start of day.
;		 -Boom lengths currently set to     100.02000       100.02000       10.000000
;		 -add in boom shorting factor
;
;
; SEE ALSO:
;
; HISTORY:
;   2012-xx-xx: Created by Aaron W Breneman, University of Minnesota
;	2013-04-xx: added support for FBK 7
;	2013-04-18: Added freq-dependent gain correction. At this point the gain curves
;				are "hard-wired" into the code. In the future they will be accessed
;				from the Berkeley RBSP website.
;	2013-05-15: freq-dependent gain curves now obtained from rbsp_get_efw_gain_results.pro and
;				are no longer "hard-wired" into this code. Also added the full
;				freq-dependent correction as well as the mu-metal square can (nT/v)
;				curves to correct the SCM data.
;	2013-09-20: Switched the channels for FBK7. Previously they were flipped.
;	2013-10-02: Re-switched the channels for FBK7. The L1 files have been corrected and
;				all works as it should.
;
; VERSION:
;$LastChangedBy: aaronbreneman $
;$LastChangedDate: 2020-01-03 14:13:58 -0800 (Fri, 03 Jan 2020) $
;$LastChangedRevision: 28162 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/missions/rbsp/efw/rbsp_efw_cal_fbk.pro $
;
;-

pro rbsp_efw_cal_fbk, probe=probe, trange=trange, datatype=datatype, pT=pT


	if datatype ne 'fbk' then begin
		print,'NOT FILTERBANK DATA....ABORTING CALIBRATION'
		return
	endif


	;Determine whether we have FBK7 or FBK13. Note that only one of
	;these is possible per call to this routine, even if the mode changes during
	;the day. This is b/c the routine rbsp_load_efw_fbk.pro calls this routine
	;once for FBK7 and once for FBK13.
	get_data,'rbsp'+probe+'_efw_fbk_13_fbk_13_select',data=data13
	get_data,'rbsp'+probe+'_efw_fbk_7_fbk_7_select',data=data7

	if is_struct(data7) then source7_13 = '7'
	if is_struct(data13) then source7_13 = '13'
	if ~is_struct(data7) and ~is_struct(data13) then begin
		print,'SOURCE DATA MISSING.....ABORTING CALIBRATION'
		return
	endif


	;Determine from the HSK data which of the following channels are in use
		; Channel selects for the Filter Bank:
		;		0=E12DC
		;		1=E34DC
		;		2=E56DC
		;		3=E12AC
		;		4=E34AC
		;		5=E56AC
		;		6=SCMU
		;		7=SCMV
		;		8=SCMW
		;		9=(V1DC+V2DC+V3DC+V4DC)/4
		;		(default is 0)

	if source7_13 eq '13' then chns = [data13.y[0,0],data13.y[0,1]] $
						  					else chns = [data7.y[0,0],data7.y[0,1]]


	compile_opt idl2


	if ~keyword_set(trange) then trange = timerange()

	fbk_channels=['E12DC','E34DC','E56DC','E12AC','E34AC','E56AC', $
				'SCMU', 'SCMV', 'SCMW','VDC']
	channel = fbk_channels[chns]
	;note: the fbk select variables come back as nX2 arrays, where [*,0] array is
	;the fb1 source as a function of time, and [*,1] is the fb2 source




	;Get gain parameters
	cp0 = rbsp_efw_get_cal_params(trange[0])
	;Get gain(f) parameters as well as mu-metal square can nT/v corrections
	fcals = rbsp_efw_get_gain_results()
	;Get boom lengths
	bl = rbsp_efw_boom_deploy_history(trange[0])



	case strlowcase(probe) of
	  'a': cp = cp0.a
	  'b': cp = cp0.b
	  else: dprint, 'Invalid probe name. Calibration aborted.'
	endcase

	;boom_shorting_factor = cp.boom_shorting_factor

	rbspx = 'rbsp' + probe[0]



	gain = fltarr(2)
	unit = strarr(2)
	offset = fltarr(2)
	boomlength = fltarr(2)

	if source7_13 eq '7'  then gainf = fltarr(7,2)
	if source7_13 eq '13' then gainf = fltarr(13,2)

	;------------------------------------------------------
	;Get calibration factors
	;------------------------------------------------------

	;For each channel...
	for ch=0,1 do begin

	case channel[ch] of
	  'E12DC': begin
	  				 	gain[ch] = cp.ADC_gain_EDC[0]		;channel gain * adc_factor
	  					offset[ch] = cp.ADC_offset_EDC[0]
	  					unit[ch] = 'mV/m'
	  					;Freq-dependent gain
	  					if probe eq 'a' then begin
								if source7_13 eq '13' then gainf[*,ch] = fcals.cal_fbk.e12DC_a_fbk13.gain_vs_freq
								if source7_13 eq '7'  then gainf[*,ch] = fcals.cal_fbk.e12DC_a_fbk7.gain_vs_freq
		  					boomlength[ch] = bl.A12
							endif else begin
								if source7_13 eq '13' then gainf[*,ch] = fcals.cal_fbk.e12DC_b_fbk13.gain_vs_freq
								if source7_13 eq '7'  then gainf[*,ch] = fcals.cal_fbk.e12DC_b_fbk7.gain_vs_freq
		  					boomlength[ch] = bl.B12
							endelse
	 					 end
	  'E34DC': begin
	  				gain[ch] = cp.ADC_gain_EDC[1]
	  				offset[ch] = cp.ADC_offset_EDC[1]
	  				unit[ch] = 'mV/m'
	  				;Freq-dependent gain
	  				if probe eq 'a' then begin
							if source7_13 eq '13' then gainf[*,ch] = fcals.cal_fbk.e34DC_a_fbk13.gain_vs_freq
							if source7_13 eq '7'  then gainf[*,ch] = fcals.cal_fbk.e34DC_a_fbk7.gain_vs_freq
		  				boomlength[ch] = bl.A34
						endif else begin
							if source7_13 eq '13' then gainf[*,ch] = fcals.cal_fbk.e34DC_b_fbk13.gain_vs_freq
							if source7_13 eq '7'  then gainf[*,ch] = fcals.cal_fbk.e34DC_b_fbk7.gain_vs_freq
		  				boomlength[ch] = bl.B12
						endelse
			   		end
	  'E56DC': begin
	  				gain[ch] = cp.ADC_gain_EDC[2]
	  				offset[ch] = cp.ADC_offset_EDC[2]
	  				unit[ch] = 'mV/m'
	  				;Freq-dependent gain
	  				if probe eq 'a' then begin
							if source7_13 eq '13' then gainf[*,ch] = fcals.cal_fbk.e56DC_a_fbk13.gain_vs_freq
							if source7_13 eq '7'  then gainf[*,ch] = fcals.cal_fbk.e56DC_a_fbk7.gain_vs_freq
		  				boomlength[ch] = bl.A56
						endif else begin
							if source7_13 eq '13' then gainf[*,ch] = fcals.cal_fbk.e56DC_b_fbk13.gain_vs_freq
							if source7_13 eq '7'  then gainf[*,ch] = fcals.cal_fbk.e56DC_b_fbk7.gain_vs_freq
		  				boomlength[ch] = bl.B56
						endelse
	  		   	end
	  'E12AC': begin
	  				gain[ch] = cp.ADC_gain_EAC[0]
	  				offset[ch] = cp.ADC_offset_EAC[0]
	  				unit[ch] = 'mV/m'
						if probe eq 'a' then boomlength[ch] = bl.A12
						if probe eq 'b' then boomlength[ch] = bl.B12
	  				if source7_13 eq '13' then gainf[*,ch] = replicate(1.,13)
	  				if source7_13 eq '7'  then gainf[*,ch] = replicate(1.,7)
	  		   end
	  'E34AC': begin
	  				gain[ch] = cp.ADC_gain_EAC[1]
	  				offset[ch] = cp.ADC_offset_EAC[1]
	  				unit[ch] = 'mV/m'
						if probe eq 'a' then boomlength[ch] = bl.A34
						if probe eq 'b' then boomlength[ch] = bl.B34
						if source7_13 eq '13' then gainf[*,ch] = replicate(1.,13)
	  				if source7_13 eq '7'  then gainf[*,ch] = replicate(1.,7)
	  		   end
	  'E56AC': begin
	  				gain[ch] = cp.ADC_gain_EAC[2]
	  				offset[ch] = cp.ADC_offset_EAC[2]
	  				unit[ch] = 'mV/m'
						if probe eq 'a' then boomlength[ch] = bl.A56
						if probe eq 'b' then boomlength[ch] = bl.B56
						if source7_13 eq '13' then gainf[*,ch] = replicate(1.,13)
	  				if source7_13 eq '7'  then gainf[*,ch] = replicate(1.,7)
	  		   end
	  'SCMU':  begin
	  				gain[ch] = cp.ADC_gain_MSC[0]
					;*******************
	  				;***TEMPORARY - rbsp_efw_get_cal_params HAS A ROUGH SQ-CAN FACTOR
	  				;BUILT IN. I GET THE CORRECT CURVES FROM rbsp_efw_get_gain_results. SO, I NEED
	  				;TO MANUALLY REMOVE THE CORRECTION HERE.
	  				;if probe eq 'a' then gain[0] /= 2.35 else gain[0] /= 2.33
					;*******************

	  				offset[ch] = cp.ADC_offset_MSC[0]
	  				if probe eq 'a' then begin
		  				;nT per volt square can conversion curve
		  				nT_volt_f13 = fcals.cal_fbk.scmu_a_fbk13.stimcoil_nt2v
		  				nT_volt_f7 = fcals.cal_fbk.scmu_a_fbk7.stimcoil_nt2v
							;freq-dependent gain curve
		  				gainfscmu_13 = fcals.cal_fbk.scmu_a_fbk13.gain_vs_freq
		  				gainfscmu_7 = fcals.cal_fbk.scmu_a_fbk7.gain_vs_freq
						endif else begin
		  				nT_volt_f13 = fcals.cal_fbk.scmu_b_fbk13.stimcoil_nt2v
		  				nT_volt_f7 = fcals.cal_fbk.scmu_b_fbk7.stimcoil_nt2v
							;freq-dependent gain curve
		  				gainfscmu_13 = fcals.cal_fbk.scmu_b_fbk13.gain_vs_freq
		  				gainfscmu_7 = fcals.cal_fbk.scmu_b_fbk7.gain_vs_freq
						endelse

						if source7_13 eq '13' then gainf[*,ch] = nT_volt_f13*gainfscmu_13
						if source7_13 eq '7'  then gainf[*,ch] = nT_volt_f7*gainfscmu_7

	  				if ~keyword_set(pT) then unit[ch] = 'nT' else $
	  					unit[ch] = 'pT'
	  				boomlength[ch] = !values.f_nan
	  		   end
	  'SCMV':  begin
	  				gain[ch] = cp.ADC_gain_MSC[1]
					;*******************
	  				;***TEMPORARY - rbsp_efw_get_cal_params HAS A ROUGH SQ-CAN FACTOR
	  				;BUILT IN. I GET THE CORRECT CURVES FROM rbsp_efw_get_gain_results. SO, I NEED
	  				;TO MANUALLY REMOVE THE CORRECTION HERE.
	  				;if probe eq 'a' then gain[0] /= 2.22 else gain[0] /= 2.10
					;*******************
	  				offset[ch] = cp.ADC_offset_MSC[1]
	  				if probe eq 'a' then begin
		  				;nT per volt square can conversion curve
		  				nT_volt_f13 = fcals.cal_fbk.scmv_a_fbk13.stimcoil_nt2v
		  				nT_volt_f7 = fcals.cal_fbk.scmv_a_fbk7.stimcoil_nt2v
						;freq-dependent gain curve
		  				gainfscmv_13 = fcals.cal_fbk.scmv_a_fbk13.gain_vs_freq
		  				gainfscmv_7 = fcals.cal_fbk.scmv_a_fbk7.gain_vs_freq
					endif else begin
		  				nT_volt_f13 = fcals.cal_fbk.scmv_b_fbk13.stimcoil_nt2v
		  				nT_volt_f7 = fcals.cal_fbk.scmv_b_fbk7.stimcoil_nt2v
						;freq-dependent gain curve
		  				gainfscmv_13 = fcals.cal_fbk.scmv_b_fbk13.gain_vs_freq
		  				gainfscmv_7 = fcals.cal_fbk.scmv_b_fbk7.gain_vs_freq
					endelse

					if source7_13 eq '13' then gainf[*,ch] = nT_volt_f13*gainfscmv_13
					if source7_13 eq '7'  then gainf[*,ch] = nT_volt_f7*gainfscmv_7


	  				if ~keyword_set(pT) then unit[ch] = 'nT' else $
	  					unit[ch] = 'pT'
	  				boomlength[ch] = !values.f_nan
	  		   end
	  'SCMW':  begin
	  				gain[ch] = cp.ADC_gain_MSC[2]
					;*******************
	  				;***TEMPORARY - rbsp_efw_get_cal_params HAS A ROUGH SQ-CAN FACTOR
	  				;BUILT IN. I GET THE CORRECT CURVES FROM rbsp_efw_get_gain_results. SO, I NEED
	  				;TO MANUALLY REMOVE THE CORRECTION HERE.
					;if probe eq 'a' then gain[0] /= 2.22 else gain[0] /= 2.22
					;*******************
	  				offset[ch] = cp.ADC_offset_MSC[2]
	  				if probe eq 'a' then begin
		  				;nT per volt square can conversion curve
		  				nT_volt_f13 = fcals.cal_fbk.scmw_a_fbk13.stimcoil_nt2v
		  				nT_volt_f7 = fcals.cal_fbk.scmw_a_fbk7.stimcoil_nt2v
						;freq-dependent gain curve
		  				gainfscmw_13 = fcals.cal_fbk.scmw_a_fbk13.gain_vs_freq
		  				gainfscmw_7 = fcals.cal_fbk.scmw_a_fbk7.gain_vs_freq
					endif else begin
		  				nT_volt_f13 = fcals.cal_fbk.scmw_b_fbk13.stimcoil_nt2v
		  				nT_volt_f7 = fcals.cal_fbk.scmw_b_fbk7.stimcoil_nt2v
						;freq-dependent gain curve
		  				gainfscmw_13 = fcals.cal_fbk.scmw_b_fbk13.gain_vs_freq
		  				gainfscmw_7 = fcals.cal_fbk.scmw_b_fbk7.gain_vs_freq
					endelse

					if source7_13 eq '13' then gainf[*,ch] = nT_volt_f13*gainfscmw_13
					if source7_13 eq '7'  then gainf[*,ch] = nT_volt_f7*gainfscmw_7


	  				if ~keyword_set(pT) then unit[ch] = 'nT' else $
	  					unit[ch] = 'pT'
	  				boomlength[ch] = !values.f_nan
	  		   end
	  'VDC':   begin
	  				gain[ch] = cp.ADC_gain_VDC[0] ;use the first of 6 gain settings
;	  				if source7_13 eq '13' then gainf[*,ch] = replicate(1.,13)
;	  				if source7_13 eq '7'  then gainf[*,ch] = replicate(1.,7)
;						gainf[*,ch]b = gainf[*,ch]
;						gainf[*,ch]b = gainf[*,ch]
	  		   end
	  else: dprint, 'Invalid filterbank channel. Calibration aborted.'
	endcase


endfor ;for each channel




	;Conversion to mV/m and nT
	nT = 1.   ;****** GET THESE VALUES FROM fbk_volts_to_nt.pro *****



	tvar = rbspx +  ['_efw_fbk_'+source7_13+'_fb1_av',$
									 '_efw_fbk_'+source7_13+'_fb1_pk',$
									 '_efw_fbk_'+source7_13+'_fb2_av',$
									 '_efw_fbk_'+source7_13+'_fb2_pk']

	;For looping purposes, but gains, offsets, etc in arrays of size [4]
	;that correspond to fb1_av, fb1_pk, fb2_av, fb2_pk
	gains = [gain[0],gain[0],gain[1],gain[1]]


	gainf_fin = [[gainf[*,0]],[gainf[*,0]],[gainf[*,1]],[gainf[*,1]]]
	offsets = [offset[0],offset[0],offset[1],offset[1]]
	channels = [channel[0],channel[0],channel[1],channel[1]]
	units = [unit[0],unit[0],unit[1],unit[1]]
	unit_conv = replicate(1.,4)



	;Set scaling to pT if requested
	if (channel[0] eq 'SCMU') or (channel[0] eq 'SCMV') or (channel[0] eq 'SCMW') then begin
		if ~keyword_set(pT) then unit_conv[0:1] = nT else unit_conv[0:1] = 1000.*nT
	endif else unit_conv[0:1] = 1000./boomlength[0]

	if (channel[1] eq 'SCMU') or (channel[1] eq 'SCMV') or (channel[1] eq 'SCMW') then begin
		if ~keyword_set(pT) then unit_conv[2:3] = nT else unit_conv[2:3] = 1000.*nT
	endif else unit_conv[2:3] = 1000./boomlength[1]



	tr = timerange()
	for j=0,3 do begin


		if tdexists(tvar[j],tr[0],tr[1]) then begin
			get_data,tvar[j],data=data,dlim=dlim

			;Add channel to the dlimit.data_att structure
			if j lt 2 then dlim.data_att.channel = channel[0]
			if j ge 2 then dlim.data_att.channel = channel[1]

			if dlim.data_att.units eq 'ADC' then begin


				tst = size(data)
				;make sure there's data
				if tst[0] ne 0 then begin

					new_y = double(data.y)
					new_y =  (new_y - offsets[j]) * gains[j] * unit_conv[j]

					gain_tmp = reform(gainf_fin[*,j])

 					;apply freq-dependent gain
					if source7_13 eq '7' then for f=0,6 do new_y[*,f] = new_y[*,f]*gain_tmp[f]
					if source7_13 eq '13' then for f=0,12 do new_y[*,f] = new_y[*,f]*gain_tmp[f]

					new_data = {x:data.x,y:new_y,v:data.v}
					dlim.data_att.units = units[j]

					str_element, dlim, 'cdf', /delete
					str_element, dlim, 'code_id', /delete

					newname = tvar[j]
					store_data, newname,data=new_data,dlim=dlim

					options,newname,'ztitle',units[j]+'!C!CRBSP'+probe+' '+channels[j]
					options,newname,'ysubtitle',''

					if j eq 0 or j eq 2 then $
						 options,newname,'ytitle','FBK'+source7_13+'!Caverage!C[Hz]' $
					else options,newname,'ytitle','FBK'+source7_13+'!Cpeak!C[Hz]'

				endif

			endif else print,tvar[j] + ' is already calibrated***************'

		endif
	endfor



	;---------------------------------------------------
	;Define filterbank frequencies and label plot y-axis.
	;Set zlim and ylim
	;---------------------------------------------------

	fbk13_binsC = fcals.cal_fbk.freq_fbk13c
	fbk7_binsC = fcals.cal_fbk.freq_fbk7c
	fbk13_binsL = fcals.cal_fbk.freq_fbk13L
	fbk7_binsL = fcals.cal_fbk.freq_fbk7L
	fbk13_binsH = fcals.cal_fbk.freq_fbk13H
	fbk7_binsH = fcals.cal_fbk.freq_fbk7H


	tplot_names,'*fbk_'+source7_13+'_fb1*',names=tnames1
	tplot_names,'*fbk_'+source7_13+'_fb2*',names=tnames2


	;tnames2 doesn't exist for the original FBK13 run
	if size(tnames2,/n_elements) eq 2 then tnames = [tnames1,tnames2] else tnames = tnames1

	if tnames[0] ne '' then begin
		for i=0,size(tnames,/n_elements)-1 do begin
			get_data,tnames[i],data=d,limits=l,dlimits=dl
			if source7_13 eq '7' then d.v=fbk7_binsH else d.v=fbk13_binsH
			store_data,tnames[i],data=d,limits=l,dlimits=dl
			ylim,tnames[i],1,1d4,1


			goo = strpos(tnames[i],'fb1')
			if goo[0] ne -1 then begin
				if (channel[0] eq 'SCMU') or (channel[0] eq 'SCMV') or (channel[0] eq 'SCMW') then begin
					if ~keyword_set(pT) then $
							   zlim,tnames[i],0.0001,0.1,1 else $
							   zlim,tnames[i],0.1,100.,1  ;scaling for searchcoil values
					endif else zlim,tnames[i],0.01,1,1 ;scaling for Efield values
			endif
			goo = strpos(tnames[i],'fb2')
			if goo[0] ne -1 then begin
				if (channel[1] eq 'SCMU') or (channel[1] eq 'SCMV') or (channel[1] eq 'SCMW') then begin
					if ~keyword_set(pT) then $
							   zlim,tnames[i],0.0001,0.1,1 else $
							   zlim,tnames[i],0.1,100.,1  ;scaling for searchcoil values
					endif else zlim,tnames[i],0.01,1,1 ;scaling for Efield values
			endif

		endfor
	endif
end
