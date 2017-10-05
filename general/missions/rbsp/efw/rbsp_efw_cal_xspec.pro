;+
; NAME: rbsp_efw_cal_xspec
;
; PURPOSE: Calibrate RBSP cross-spectral data
;
; NOTES: meant to be called from rbsp_load_efw_xspec.pro
;
;	The default is that xspec0 is SCMw x E12AC
;	and xspec1 is V1AC x V2AC
;	xspec3 is not used at this time
;
;	A note on the various channels.
;
;		From the LASP DFB document Fig 4, the spectral FFT of each channel (ex SCMw and E12AC)
;		is sent directly into the Xspec processor. The "top" channel in this figure
;		shows the calculation of the real and imaginary parts. 
;			FFT(SCMw) and FFT(E12AC) --> Xspec calc (eg SCMw x E12AC) --> bin averaging --> xspec compression
;		The power is calculated via the "bottom" channel
;			FFT(SCMw) --> FFT(SCMw)*FFT(SCMw)* --> bin averaging --> spec compression		
;		These values are "src1" and "src2"
;
;
;	src1 and src2 refer to the individual sources that comprise the xspec. These
;	are power spectral densities
;
;
;	Data calibration (ex, starting with src1, described above)
;		subtract offset
;			src1_2 = (double(src1.y) - offset_chn1)
;		Compensate for dynamic range compression
;			src1_2 /= 16   (/8 for the real and imaginary parts)
;		Divide the 0th bin by 4 (from weirdness doc)
;			src1_2[*,0] /= 4.
;		Compensate for using Hanning window
;			src1_2 /= 0.375^2
;		Apply ADC conversion
;			src1_2 *= adc_factor^2
;		Apply channel gain
;			src1_2 *= gain[0]^2
;		Resulting data in V^2/Hz
;
;
;	The coherence values are calculated as in Eqn 3.91 in "Engineering Applications of
;	Correlation and Spectral Analysis" by Bendat and Piersol (vol 1 apparently)
;
;	Coherence(f) = |Gxy(f)|^2 / Gxx(f)*Gyy(f)
;		where 
;			|Gxy(f)|^2 = (Real^2 + Imaginary^2)
;			Gxx(f) = src1_2
;			Gyy(f) = src2_2
;			
; SEE ALSO:
;
; HISTORY:
;   Sept 2012: Created by Aaron W Breneman, University of Minnesota
;
; VERSION:
; $LastChangedBy:  $
; $LastChangedDate:  $
; $LastChangedRevision:  $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/ssl_general/trunk/missions/rbsp/efw/rbsp_efw_cal_fbk.pro $
;
;-


pro rbsp_efw_cal_xspec, probe=probe, trange=trange, datatype=datatype


if datatype eq 'xspec' then begin


	get_data,'rbsp'+probe+'_efw_xspec_64_ccsds_data_DFB_config',data=dfbc
	dfbconfig = rbsp_get_efw_dfb_config(dfbc.y)
	;Xspec sources
	src1 = dfbconfig[0].xspec_config.xspec_src1
	src2 = dfbconfig[0].xspec_config.xspec_src2


	
	compile_opt idl2
	
	if ~keyword_set(trange) then trange = timerange()
	
	cp0 = rbsp_efw_get_cal_params(trange[0])
	

	case strlowcase(probe) of
	  'a': cp = cp0.a
	  'b': cp = cp0.b
	  else: dprint, 'Invalid probe name. Calibration aborted.'
	endcase
	
	boom_length = cp.boom_length
	

;	; first see if we have 36, 64, or 112 bins
	names=''
	nn=''
	names=tnames('rbsp'+probe+'_efw_xspec_'+'??' + '_xspec?_src?')

	bins = strmid(names[0],16,2)
	if bins eq '11' then bins = '112'

		
	
	adc_factor = 2.5d / 32767.5d
	
	rbspx = 'rbsp' + probe[0]
	
	units = replicate('',8)	
	

	
	if ~keyword_set(pT) then pTf = 1 else pTf = 1000.



	gain = [0d,0d]
	offset = [0d,0d]
	units = ['','']
	ytitle = ['','','','']  ;src1, src2, re, im
	ztitle = ['','','','']  ;src1, src2, re, im
	conversion = [0d,0d]		;used to get to real units (nT, V, mV/m)

	case src1[0] of
	
		;gains
		'E12AC': gain[0] = cp.adc_gain_eac[0]
		'E34AC': gain[0] = cp.adc_gain_eac[1]
		'E56AC': gain[0] = cp.adc_gain_eac[2]

		'E12DC': gain[0] = cp.adc_gain_edc[0]
		'E34DC': gain[0] = cp.adc_gain_edc[1]
		'E56DC': gain[0] = cp.adc_gain_edc[2]

		'V1DC': gain[0] = cp.adc_gain_vdc[0]
		'V2DC': gain[0] = cp.adc_gain_vdc[1]
		'V3DC': gain[0] = cp.adc_gain_vdc[2]
		'V4DC': gain[0] = cp.adc_gain_vdc[3]
		'V5DC': gain[0] = cp.adc_gain_vdc[4]
		'V6DC': gain[0] = cp.adc_gain_vdc[5]

		'V1AC': gain[0] = cp.adc_gain_vac[0]
		'V2AC': gain[0] = cp.adc_gain_vac[1]
		'V3AC': gain[0] = cp.adc_gain_vac[2]
		'V4AC': gain[0] = cp.adc_gain_vac[3]
		'V5AC': gain[0] = cp.adc_gain_vac[4]
		'V6AC': gain[0] = cp.adc_gain_vac[5]

		'SCMU': gain[0] = cp.adc_gain_msc[0]
		'SCMV': gain[0] = cp.adc_gain_msc[1]
		'SCMW': gain[0] = cp.adc_gain_msc[2]

	endcase
	
	case src1[0] of

		;offsets
		'E12AC': offset[0] = cp.adc_offset_eac[0]
		'E34AC': offset[0] = cp.adc_offset_eac[1]
		'E56AC': offset[0] = cp.adc_offset_eac[2]

		'E12DC': offset[0] = cp.adc_offset_edc[0]
		'E34DC': offset[0] = cp.adc_offset_edc[1]
		'E56DC': offset[0] = cp.adc_offset_edc[2]

		'V1DC': offset[0] = cp.adc_offset_vdc[0]
		'V2DC': offset[0] = cp.adc_offset_vdc[1]
		'V3DC': offset[0] = cp.adc_offset_vdc[2]
		'V4DC': offset[0] = cp.adc_offset_vdc[3]
		'V5DC': offset[0] = cp.adc_offset_vdc[4]
		'V6DC': offset[0] = cp.adc_offset_vdc[5]

		'V1AC': offset[0] = cp.adc_offset_vac[0]
		'V2AC': offset[0] = cp.adc_offset_vac[1]
		'V3AC': offset[0] = cp.adc_offset_vac[2]
		'V4AC': offset[0] = cp.adc_offset_vac[3]
		'V5AC': offset[0] = cp.adc_offset_vac[4]
		'V6AC': offset[0] = cp.adc_offset_vac[5]

		'SCMU': offset[0] = cp.adc_offset_msc[0]
		'SCMV': offset[0] = cp.adc_offset_msc[1]
		'SCMW': offset[0] = cp.adc_offset_msc[2]

	endcase
	
	case src1[0] of

		;units
		'E12AC': units[0] = 'mV/m!U2!N/Hz'
		'E34AC': units[0] = 'mV/m!U2!N/Hz'
		'E56AC': units[0] = 'mV/m!U2!N/Hz'

		'E12DC': units[0] = 'mV/m!U2!N/Hz'
		'E34DC': units[0] = 'mV/m!U2!N/Hz'
		'E56DC': units[0] = 'mV/m!U2!N/Hz'

		'V1DC': units[0] = 'V!U2!N/Hz'
		'V2DC': units[0] = 'V!U2!N/Hz'
		'V3DC': units[0] = 'V!U2!N/Hz'
		'V4DC': units[0] = 'V!U2!N/Hz'
		'V5DC': units[0] = 'V!U2!N/Hz'
		'V6DC': units[0] = 'V!U2!N/Hz'

		'V1AC': units[0] = 'V!U2!N/Hz'
		'V2AC': units[0] = 'V!U2!N/Hz'
		'V3AC': units[0] = 'V!U2!N/Hz'
		'V4AC': units[0] = 'V!U2!N/Hz'
		'V5AC': units[0] = 'V!U2!N/Hz'
		'V6AC': units[0] = 'V!U2!N/Hz'

		'SCMU': units[0] = 'nT!U2!N/Hz'
		'SCMV': units[0] = 'nT!U2!N/Hz'
		'SCMW': units[0] = 'nT!U2!N/Hz'

	endcase
	case src1[0] of

		;conversion factor
		'E12AC': conversion[0] = 1000./boom_length[0]
		'E34AC': conversion[0] = 1000./boom_length[1]
		'E56AC': conversion[0] = 1000./boom_length[2]

		'E12DC': conversion[0] = 1000./boom_length[0]
		'E34DC': conversion[0] = 1000./boom_length[1]
		'E56DC': conversion[0] = 1000./boom_length[2]

		'V1DC': conversion[0] = 1.
		'V2DC': conversion[0] = 1.
		'V3DC': conversion[0] = 1.
		'V4DC': conversion[0] = 1.
		'V5DC': conversion[0] = 1.
		'V6DC': conversion[0] = 1.

		'V1AC': conversion[0] = 1.
		'V2AC': conversion[0] = 1.
		'V3AC': conversion[0] = 1.
		'V4AC': conversion[0] = 1.
		'V5AC': conversion[0] = 1.
		'V6AC': conversion[0] = 1.

		'SCMU': conversion[0] = pTf
		'SCMV': conversion[0] = pTf
		'SCMW': conversion[0] = pTf


	endcase

	
	case src2[0] of
	
		;gains
		'E12AC': gain[1] = cp.adc_gain_eac[0]
		'E34AC': gain[1] = cp.adc_gain_eac[1]
		'E56AC': gain[1] = cp.adc_gain_eac[2]

		'E12DC': gain[1] = cp.adc_gain_edc[0]
		'E34DC': gain[1] = cp.adc_gain_edc[1]
		'E56DC': gain[1] = cp.adc_gain_edc[2]

		'V1DC': gain[1] = cp.adc_gain_vdc[0]
		'V2DC': gain[1] = cp.adc_gain_vdc[1]
		'V3DC': gain[1] = cp.adc_gain_vdc[2]
		'V4DC': gain[1] = cp.adc_gain_vdc[3]
		'V5DC': gain[1] = cp.adc_gain_vdc[4]
		'V6DC': gain[1] = cp.adc_gain_vdc[5]

		'V1AC': gain[1] = cp.adc_gain_vac[0]
		'V2AC': gain[1] = cp.adc_gain_vac[1]
		'V3AC': gain[1] = cp.adc_gain_vac[2]
		'V4AC': gain[1] = cp.adc_gain_vac[3]
		'V5AC': gain[1] = cp.adc_gain_vac[4]
		'V6AC': gain[1] = cp.adc_gain_vac[5]

		'SCMU': gain[1] = cp.adc_gain_msc[0]
		'SCMV': gain[1] = cp.adc_gain_msc[1]
		'SCMW': gain[1] = cp.adc_gain_msc[2]
	endcase
	case src2[0] of

		;offsets
		'E12AC': offset[1] = cp.adc_offset_eac[0]
		'E34AC': offset[1] = cp.adc_offset_eac[1]
		'E56AC': offset[1] = cp.adc_offset_eac[2]

		'E12DC': offset[1] = cp.adc_offset_edc[0]
		'E34DC': offset[1] = cp.adc_offset_edc[1]
		'E56DC': offset[1] = cp.adc_offset_edc[2]

		'V1DC': offset[1] = cp.adc_offset_vdc[0]
		'V2DC': offset[1] = cp.adc_offset_vdc[1]
		'V3DC': offset[1] = cp.adc_offset_vdc[2]
		'V4DC': offset[1] = cp.adc_offset_vdc[3]
		'V5DC': offset[1] = cp.adc_offset_vdc[4]
		'V6DC': offset[1] = cp.adc_offset_vdc[5]

		'V1AC': offset[1] = cp.adc_offset_vac[0]
		'V2AC': offset[1] = cp.adc_offset_vac[1]
		'V3AC': offset[1] = cp.adc_offset_vac[2]
		'V4AC': offset[1] = cp.adc_offset_vac[3]
		'V5AC': offset[1] = cp.adc_offset_vac[4]
		'V6AC': offset[1] = cp.adc_offset_vac[5]

		'SCMU': offset[1] = cp.adc_offset_msc[0]
		'SCMV': offset[1] = cp.adc_offset_msc[1]
		'SCMW': offset[1] = cp.adc_offset_msc[2]

	endcase
	case src2[0] of

		;units
		'E12AC': units[1] = 'mV/m!U2!N/Hz'
		'E34AC': units[1] = 'mV/m!U2!N/Hz'
		'E56AC': units[1] = 'mV/m!U2!N/Hz'

		'E12DC': units[1] = 'mV/m!U2!N/Hz'
		'E34DC': units[1] = 'mV/m!U2!N/Hz'
		'E56DC': units[1] = 'mV/m!U2!N/Hz'

		'V1DC': units[1] = 'V!U2!N/Hz'
		'V2DC': units[1] = 'V!U2!N/Hz'
		'V3DC': units[1] = 'V!U2!N/Hz'
		'V4DC': units[1] = 'V!U2!N/Hz'
		'V5DC': units[1] = 'V!U2!N/Hz'
		'V6DC': units[1] = 'V!U2!N/Hz'

		'V1AC': units[1] = 'V!U2!N/Hz'
		'V2AC': units[1] = 'V!U2!N/Hz'
		'V3AC': units[1] = 'V!U2!N/Hz'
		'V4AC': units[1] = 'V!U2!N/Hz'
		'V5AC': units[1] = 'V!U2!N/Hz'
		'V6AC': units[1] = 'V!U2!N/Hz'

		'SCMU': units[1] = 'nT!U2!N/Hz'
		'SCMV': units[1] = 'nT!U2!N/Hz'
		'SCMW': units[1] = 'nT!U2!N/Hz'
	endcase
	case src2[0] of

		;conversion factor
		'E12AC': conversion[1] = 1000./boom_length[0]
		'E34AC': conversion[1] = 1000./boom_length[1]
		'E56AC': conversion[1] = 1000./boom_length[2]

		'E12DC': conversion[1] = 1000./boom_length[0]
		'E34DC': conversion[1] = 1000./boom_length[1]
		'E56DC': conversion[1] = 1000./boom_length[2]

		'V1DC': conversion[1] = 1.
		'V2DC': conversion[1] = 1.
		'V3DC': conversion[1] = 1.
		'V4DC': conversion[1] = 1.
		'V5DC': conversion[1] = 1.
		'V6DC': conversion[1] = 1.

		'V1AC': conversion[1] = 1.
		'V2AC': conversion[1] = 1.
		'V3AC': conversion[1] = 1.
		'V4AC': conversion[1] = 1.
		'V5AC': conversion[1] = 1.
		'V6AC': conversion[1] = 1.

		'SCMU': conversion[1] = pTf
		'SCMV': conversion[1] = pTf
		'SCMW': conversion[1] = pTf
	endcase
	
	
	gain = gain/adc_factor

	gain_rc = sqrt(gain[0]*gain[1])
	gain_ic = gain_rc

	
	ytitle[0] = src1[0] + '!C[Hz]'	
	ytitle[1] = src2[0] + '!C[Hz]'	
	ytitle[2] = 'RE(' + src1[0] + ' x ' + src2[0] + ')!C[Hz]' 	
	ytitle[3] = 'IM(' + src1[0] + ' x ' + src2[0] + ')!C[Hz]' 	

	ztitle[0] = '!C'+ units[0] + '!C!C'+'RBSP'+probe+' EFW Xspec'	
	ztitle[1] = '!C'+ units[1] + '!C!C'+'RBSP'+probe+' EFW Xspec'	
	ztitle[2] = '!C'+ units[0] + ' ' + units[1] + '!C!C'+'RBSP'+probe+' EFW Xspec'	
	ztitle[3] = '!C'+ units[0] + ' ' + units[1] + '!C!C'+'RBSP'+probe+' EFW Xspec'	
	
	
	
;--------------------------------------------------------------------	
;Calibrate xspec0  (src1 = SCMw, src2 = E12AC)
	
	get_data,rbspx + '_efw_xspec_'+bins+'_xspec0_src1',data=src1d,dlimits=dlim_src1
	get_data,rbspx + '_efw_xspec_'+bins+'_xspec0_src2',data=src2d,dlimits=dlim_src2
	get_data,rbspx + '_efw_xspec_'+bins+'_xspec0_rc',data=rc,dlimits=dlim_rc
	get_data,rbspx + '_efw_xspec_'+bins+'_xspec0_ic',data=ic,dlimits=dlim_ic
	

;	offset_chn1 = cp.ADC_offset_MSC[2]
;	offset_chn2 = cp.ADC_offset_EAC[0]
	offset_rc = 0.
	offset_ic = 0.  ;what should these be set to?



	;subtract offset
	src1_2 = (double(src1d.y) - offset[0])
	;Compensate for 4 bit dynamic range compression
	src1_2 /= 16.
	;Divide the 0th bin by 4 (from weirdness doc)
	src1_2[*,0] /= 4.
	;Compensate for using Hanning window
	src1_2 /= 0.375^2
	;Apply ADC conversion
	src1_2 *= adc_factor^2
	;Apply channel gain
	src1_2 *= gain[0]^2    
	;Convert to mV/m or nT
	src1_2 *= conversion[0]^2

	;subtract offset
	src2_2 = (double(src2d.y) - offset[1])
	;Compensate for 4 bit dynamic range compression
	src2_2 /= 16.
	;Divide the 0th bin by 4 (from weirdness doc)
	src2_2[*,0] /= 4.
	;Compensate for using Hanning window
	src2_2 /= 0.375^2
	;Apply ADC conversion
	src2_2 *= adc_factor^2
	;Apply channel gain
	src2_2 *= gain[1]^2
	;Convert to mV/m or nT
	src2_2 *= conversion[1]^2

;******FIX THIS
;	;Apply boom length to change from V to mV/m				
;	src2_2 *=  (1000./boom_length[0])^2   ;mV/m ^2 / Hz



	;subtract offset
	rc_2 = (double(rc.y) - offset_rc)
	;Compensate for 4 bit dynamic range compression
	rc_2 /= 8.
	;Divide the 0th bin by 4 (from weirdness doc)
	rc_2[*,0] /= 4.
	;Compensate for using Hanning window
	rc_2 /= 0.375^2
	;Apply ADC conversion
	rc_2 *= adc_factor^2
	;Apply channel gain
	rc_2 *= gain_rc^2



	;subtract offset
	ic_2 = (double(ic.y) - offset_ic)
	;Compensate for 4 bit dynamic range compression
	ic_2 /= 8.
	;Divide the 0th bin by 4 (from weirdness doc)
	ic_2[*,0] /= 4.
	;Compensate for using Hanning window
	ic_2 /= 0.375^2
	;Apply ADC conversion
	ic_2 *= adc_factor^2
	;Apply channel gain
	ic_2 *= gain_ic^2


;*****************
;These should be unnecessary

	dlim_src1.data_att.units = units[0]
	dlim_src2.data_att.units = units[1]
	dlim_rc.data_att.units = units[0] + ' ' + units[1]
	dlim_ic.data_att.units = units[0] + ' ' + units[1]
;******************


	store_data,rbspx + '_efw_xspec_'+bins+'_xspec0_src1',data={x:src1d.x,y:src1_2,v:src1d.v},dlim=dlim_src1
	store_data,rbspx + '_efw_xspec_'+bins+'_xspec0_src2',data={x:src2d.x,y:src2_2,v:src2d.v},dlim=dlim_src2
	store_data,rbspx + '_efw_xspec_'+bins+'_xspec0_rc',data={x:rc.x,y:rc_2,v:rc.v},dlim=dlim_rc
	store_data,rbspx + '_efw_xspec_'+bins+'_xspec0_ic',data={x:ic.x,y:ic_2,v:ic.v},dlim=dlim_ic
	
	options,rbspx + '_efw_xspec_'+bins+'_xspec0_src1','ytitle',ytitle[0]	
	options,rbspx + '_efw_xspec_'+bins+'_xspec0_src1',labflag = 1
	options,rbspx + '_efw_xspec_'+bins+'_xspec0_src1','ztitle',ztitle[0]

	options,rbspx + '_efw_xspec_'+bins+'_xspec0_src2','ytitle',ytitle[1]
	options,rbspx + '_efw_xspec_'+bins+'_xspec0_src2',labflag = 1
	options,rbspx + '_efw_xspec_'+bins+'_xspec0_src2','ztitle',ztitle[1]

	options,rbspx + '_efw_xspec_'+bins+'_xspec0_rc','ytitle',ytitle[2]
	options,rbspx + '_efw_xspec_'+bins+'_xspec0_rc',labflag = 1
	options,rbspx + '_efw_xspec_'+bins+'_xspec0_rc','ztitle',ztitle[2]

	options,rbspx + '_efw_xspec_'+bins+'_xspec0_ic','ytitle',ytitle[3]
	options,rbspx + '_efw_xspec_'+bins+'_xspec0_ic',labflag = 1
	options,rbspx + '_efw_xspec_'+bins+'_xspec0_ic','ztitle',ztitle[3]


	
	
;--------------------------------------------------------------------	
;Calibrate xspec1  (src1 = V1AC, src2 = V2AC)




	gain = [0d,0d]
	offset = [0d,0d]
	units = ['','']
	conversion = [0d,0d]


	case src1[1] of
	
		;gains
		'E12AC': gain[0] = cp.adc_gain_eac[0]
		'E34AC': gain[0] = cp.adc_gain_eac[1]
		'E56AC': gain[0] = cp.adc_gain_eac[2]

		'E12DC': gain[0] = cp.adc_gain_edc[0]
		'E34DC': gain[0] = cp.adc_gain_edc[1]
		'E56DC': gain[0] = cp.adc_gain_edc[2]

		'V1DC': gain[0] = cp.adc_gain_vdc[0]
		'V2DC': gain[0] = cp.adc_gain_vdc[1]
		'V3DC': gain[0] = cp.adc_gain_vdc[2]
		'V4DC': gain[0] = cp.adc_gain_vdc[3]
		'V5DC': gain[0] = cp.adc_gain_vdc[4]
		'V6DC': gain[0] = cp.adc_gain_vdc[5]

		'V1AC': gain[0] = cp.adc_gain_vac[0]
		'V2AC': gain[0] = cp.adc_gain_vac[1]
		'V3AC': gain[0] = cp.adc_gain_vac[2]
		'V4AC': gain[0] = cp.adc_gain_vac[3]
		'V5AC': gain[0] = cp.adc_gain_vac[4]
		'V6AC': gain[0] = cp.adc_gain_vac[5]

		'SCMU': gain[0] = cp.adc_gain_msc[0]
		'SCMV': gain[0] = cp.adc_gain_msc[1]
		'SCMW': gain[0] = cp.adc_gain_msc[2]
	endcase
	case src1[1] of


		;offsets
		'E12AC': offset[0] = cp.adc_offset_eac[0]
		'E34AC': offset[0] = cp.adc_offset_eac[1]
		'E56AC': offset[0] = cp.adc_offset_eac[2]

		'E12DC': offset[0] = cp.adc_offset_edc[0]
		'E34DC': offset[0] = cp.adc_offset_edc[1]
		'E56DC': offset[0] = cp.adc_offset_edc[2]

		'V1DC': offset[0] = cp.adc_offset_vdc[0]
		'V2DC': offset[0] = cp.adc_offset_vdc[1]
		'V3DC': offset[0] = cp.adc_offset_vdc[2]
		'V4DC': offset[0] = cp.adc_offset_vdc[3]
		'V5DC': offset[0] = cp.adc_offset_vdc[4]
		'V6DC': offset[0] = cp.adc_offset_vdc[5]

		'V1AC': offset[0] = cp.adc_offset_vac[0]
		'V2AC': offset[0] = cp.adc_offset_vac[1]
		'V3AC': offset[0] = cp.adc_offset_vac[2]
		'V4AC': offset[0] = cp.adc_offset_vac[3]
		'V5AC': offset[0] = cp.adc_offset_vac[4]
		'V6AC': offset[0] = cp.adc_offset_vac[5]

		'SCMU': offset[0] = cp.adc_offset_msc[0]
		'SCMV': offset[0] = cp.adc_offset_msc[1]
		'SCMW': offset[0] = cp.adc_offset_msc[2]

	endcase
	case src1[1] of

		;units
		'E12AC': units[0] = 'mV/m!U2!N/Hz'
		'E34AC': units[0] = 'mV/m!U2!N/Hz'
		'E56AC': units[0] = 'mV/m!U2!N/Hz'

		'E12DC': units[0] = 'mV/m!U2!N/Hz'
		'E34DC': units[0] = 'mV/m!U2!N/Hz'
		'E56DC': units[0] = 'mV/m!U2!N/Hz'

		'V1DC': units[0] = 'V!U2!N/Hz'
		'V2DC': units[0] = 'V!U2!N/Hz'
		'V3DC': units[0] = 'V!U2!N/Hz'
		'V4DC': units[0] = 'V!U2!N/Hz'
		'V5DC': units[0] = 'V!U2!N/Hz'
		'V6DC': units[0] = 'V!U2!N/Hz'

		'V1AC': units[0] = 'V!U2!N/Hz'
		'V2AC': units[0] = 'V!U2!N/Hz'
		'V3AC': units[0] = 'V!U2!N/Hz'
		'V4AC': units[0] = 'V!U2!N/Hz'
		'V5AC': units[0] = 'V!U2!N/Hz'
		'V6AC': units[0] = 'V!U2!N/Hz'

		'SCMU': units[0] = 'nT!U2!N/Hz'
		'SCMV': units[0] = 'nT!U2!N/Hz'
		'SCMW': units[0] = 'nT!U2!N/Hz'

	endcase
	case src1[1] of

		;conversion factor
		'E12AC': conversion[0] = 1000./boom_length[0]
		'E34AC': conversion[0] = 1000./boom_length[1]
		'E56AC': conversion[0] = 1000./boom_length[2]

		'E12DC': conversion[0] = 1000./boom_length[0]
		'E34DC': conversion[0] = 1000./boom_length[1]
		'E56DC': conversion[0] = 1000./boom_length[2]

		'V1DC': conversion[0] = 1.
		'V2DC': conversion[0] = 1.
		'V3DC': conversion[0] = 1.
		'V4DC': conversion[0] = 1.
		'V5DC': conversion[0] = 1.
		'V6DC': conversion[0] = 1.

		'V1AC': conversion[0] = 1.
		'V2AC': conversion[0] = 1.
		'V3AC': conversion[0] = 1.
		'V4AC': conversion[0] = 1.
		'V5AC': conversion[0] = 1.
		'V6AC': conversion[0] = 1.

		'SCMU': conversion[0] = pTf
		'SCMV': conversion[0] = pTf
		'SCMW': conversion[0] = pTf

	endcase

	
	case src2[1] of
	
		;gains
		'E12AC': gain[1] = cp.adc_gain_eac[0]
		'E34AC': gain[1] = cp.adc_gain_eac[1]
		'E56AC': gain[1] = cp.adc_gain_eac[2]

		'E12DC': gain[1] = cp.adc_gain_edc[0]
		'E34DC': gain[1] = cp.adc_gain_edc[1]
		'E56DC': gain[1] = cp.adc_gain_edc[2]

		'V1DC': gain[1] = cp.adc_gain_vdc[0]
		'V2DC': gain[1] = cp.adc_gain_vdc[1]
		'V3DC': gain[1] = cp.adc_gain_vdc[2]
		'V4DC': gain[1] = cp.adc_gain_vdc[3]
		'V5DC': gain[1] = cp.adc_gain_vdc[4]
		'V6DC': gain[1] = cp.adc_gain_vdc[5]

		'V1AC': gain[1] = cp.adc_gain_vac[0]
		'V2AC': gain[1] = cp.adc_gain_vac[1]
		'V3AC': gain[1] = cp.adc_gain_vac[2]
		'V4AC': gain[1] = cp.adc_gain_vac[3]
		'V5AC': gain[1] = cp.adc_gain_vac[4]
		'V6AC': gain[1] = cp.adc_gain_vac[5]

		'SCMU': gain[1] = cp.adc_gain_msc[0]
		'SCMV': gain[1] = cp.adc_gain_msc[1]
		'SCMW': gain[1] = cp.adc_gain_msc[2]

	endcase
	case src2[1] of


		;offsets
		'E12AC': offset[1] = cp.adc_offset_eac[0]
		'E34AC': offset[1] = cp.adc_offset_eac[1]
		'E56AC': offset[1] = cp.adc_offset_eac[2]

		'E12DC': offset[1] = cp.adc_offset_edc[0]
		'E34DC': offset[1] = cp.adc_offset_edc[1]
		'E56DC': offset[1] = cp.adc_offset_edc[2]

		'V1DC': offset[1] = cp.adc_offset_vdc[0]
		'V2DC': offset[1] = cp.adc_offset_vdc[1]
		'V3DC': offset[1] = cp.adc_offset_vdc[2]
		'V4DC': offset[1] = cp.adc_offset_vdc[3]
		'V5DC': offset[1] = cp.adc_offset_vdc[4]
		'V6DC': offset[1] = cp.adc_offset_vdc[5]

		'V1AC': offset[1] = cp.adc_offset_vac[0]
		'V2AC': offset[1] = cp.adc_offset_vac[1]
		'V3AC': offset[1] = cp.adc_offset_vac[2]
		'V4AC': offset[1] = cp.adc_offset_vac[3]
		'V5AC': offset[1] = cp.adc_offset_vac[4]
		'V6AC': offset[1] = cp.adc_offset_vac[5]

		'SCMU': offset[1] = cp.adc_offset_msc[0]
		'SCMV': offset[1] = cp.adc_offset_msc[1]
		'SCMW': offset[1] = cp.adc_offset_msc[2]

	endcase
	case src2[1] of


		;units
		'E12AC': units[1] = 'mV/m!U2!N/Hz'
		'E34AC': units[1] = 'mV/m!U2!N/Hz'
		'E56AC': units[1] = 'mV/m!U2!N/Hz'

		'E12DC': units[1] = 'mV/m!U2!N/Hz'
		'E34DC': units[1] = 'mV/m!U2!N/Hz'
		'E56DC': units[1] = 'mV/m!U2!N/Hz'

		'V1DC': units[1] = 'V!U2!N/Hz'
		'V2DC': units[1] = 'V!U2!N/Hz'
		'V3DC': units[1] = 'V!U2!N/Hz'
		'V4DC': units[1] = 'V!U2!N/Hz'
		'V5DC': units[1] = 'V!U2!N/Hz'
		'V6DC': units[1] = 'V!U2!N/Hz'

		'V1AC': units[1] = 'V!U2!N/Hz'
		'V2AC': units[1] = 'V!U2!N/Hz'
		'V3AC': units[1] = 'V!U2!N/Hz'
		'V4AC': units[1] = 'V!U2!N/Hz'
		'V5AC': units[1] = 'V!U2!N/Hz'
		'V6AC': units[1] = 'V!U2!N/Hz'

		'SCMU': units[1] = 'nT!U2!N/Hz'
		'SCMV': units[1] = 'nT!U2!N/Hz'
		'SCMW': units[1] = 'nT!U2!N/Hz'
	endcase
	case src2[1] of

		;conversion factor
		'E12AC': conversion[1] = 1000./boom_length[0]
		'E34AC': conversion[1] = 1000./boom_length[1]
		'E56AC': conversion[1] = 1000./boom_length[2]

		'E12DC': conversion[1] = 1000./boom_length[0]
		'E34DC': conversion[1] = 1000./boom_length[1]
		'E56DC': conversion[1] = 1000./boom_length[2]

		'V1DC': conversion[1] = 1.
		'V2DC': conversion[1] = 1.
		'V3DC': conversion[1] = 1.
		'V4DC': conversion[1] = 1.
		'V5DC': conversion[1] = 1.
		'V6DC': conversion[1] = 1.

		'V1AC': conversion[1] = 1.
		'V2AC': conversion[1] = 1.
		'V3AC': conversion[1] = 1.
		'V4AC': conversion[1] = 1.
		'V5AC': conversion[1] = 1.
		'V6AC': conversion[1] = 1.

		'SCMU': conversion[1] = pTf
		'SCMV': conversion[1] = pTf
		'SCMW': conversion[1] = pTf

	endcase
	



	gain = gain/adc_factor

	gain_rc = sqrt(gain[0]*gain[1])
	gain_ic = gain_rc
	

	ytitle[0] = src1[1] + '!C[Hz]'	
	ytitle[1] = src2[1] + '!C[Hz]'	
	ytitle[2] = 'RE(' + src1[1] + ' x ' + src2[1] + ')!C[Hz]' 	
	ytitle[3] = 'IM(' + src1[1] + ' x ' + src2[1] + ')!C[Hz]' 	


	ztitle[0] = '!C'+ units[0] + '!C!C'+'RBSP'+probe+' EFW Xspec'	
	ztitle[1] = '!C'+ units[1] + '!C!C'+'RBSP'+probe+' EFW Xspec'	
	ztitle[2] = '!C'+ units[0] + ' ' + units[1] + '!C!C'+'RBSP'+probe+' EFW Xspec'	
	ztitle[3] = '!C'+ units[0] + ' ' + units[1] + '!C!C'+'RBSP'+probe+' EFW Xspec'	



	
	get_data,rbspx + '_efw_xspec_'+bins+'_xspec1_src1',data=src1d,dlimits=dlim_src1
	get_data,rbspx + '_efw_xspec_'+bins+'_xspec1_src2',data=src2d,dlimits=dlim_src2
	get_data,rbspx + '_efw_xspec_'+bins+'_xspec1_rc',data=rc,dlimits=dlim_rc
	get_data,rbspx + '_efw_xspec_'+bins+'_xspec1_ic',data=ic,dlimits=dlim_ic
	

;	offset_chn1 = cp.ADC_offset_VAC[0]
;	offset_chn2 = cp.ADC_offset_VAC[1]
	offset_rc = 0.
	offset_ic = 0.  ;what should these be set to?


	;subtract offset
	src1_2 = (double(src1d.y) - offset[0])
	;Compensate for 4 bit dynamic range compression
	src1_2 /= 16.
	;Divide the 0th bin by 4 (from weirdness doc)
	src1_2[*,0] /= 4.
	;Compensate for using Hanning window
	src1_2 /= 0.375^2
	;Apply ADC conversion
	src1_2 *= adc_factor^2
	;Apply channel gain
	src1_2 *= gain[0]^2
	;Convert to mV/m or nT
	src1_2 *= conversion[0]^2



	;subtract offset
	src2_2 = (double(src2d.y) - offset[1])
	;Compensate for 4 bit dynamic range compression
	src2_2 /= 16.
	;Divide the 0th bin by 4 (from weirdness doc)
	src2_2[*,0] /= 4.
	;Compensate for using Hanning window
	src2_2 /= 0.375^2
	;Apply ADC conversion
	src2_2 *= adc_factor^2
	;Apply channel gain
	src2_2 *= gain[1]^2
	;Convert to mV/m or nT
	src2_2 *= conversion[1]^2



	;subtract offset
	rc_2 = (double(rc.y) - offset_rc)
	;Compensate for 4 bit dynamic range compression
	rc_2 /= 8.
	;Divide the 0th bin by 4 (from weirdness doc)
	rc_2[*,0] /= 4.
	;Compensate for using Hanning window
	rc_2 /= 0.375^2
	;Apply ADC conversion
	rc_2 *= adc_factor^2
	;Apply channel gain
	rc_2 *= gain_rc^2



	;subtract offset
	ic_2 = (double(ic.y) - offset_ic)
	;Compensate for 4 bit dynamic range compression
	ic_2 /= 8.
	;Divide the 0th bin by 4 (from weirdness doc)
	ic_2[*,0] /= 4.
	;Compensate for using Hanning window
	ic_2 /= 0.375^2
	;Apply ADC conversion
	ic_2 *= adc_factor^2
	;Apply channel gain
	ic_2 *= gain_ic^2


	dlim_src1.data_att.units = units[0]
	dlim_src2.data_att.units = units[1]
	dlim_rc.data_att.units = units[0] + ' ' + units[1]
	dlim_ic.data_att.units = units[0] + ' ' + units[1]


	store_data,rbspx + '_efw_xspec_'+bins+'_xspec1_src1',data={x:src1d.x,y:src1_2,v:src1d.v},dlim=dlim_src1
	store_data,rbspx + '_efw_xspec_'+bins+'_xspec1_src2',data={x:src2d.x,y:src2_2,v:src2d.v},dlim=dlim_src2
	store_data,rbspx + '_efw_xspec_'+bins+'_xspec1_rc',data={x:rc.x,y:rc_2,v:rc.v},dlim=dlim_rc
	store_data,rbspx + '_efw_xspec_'+bins+'_xspec1_ic',data={x:ic.x,y:ic_2,v:ic.v},dlim=dlim_ic
	
	options,rbspx + '_efw_xspec_'+bins+'_xspec1_src1','ytitle',ytitle[0]	
	options,rbspx + '_efw_xspec_'+bins+'_xspec1_src1',labflag = 1
	options,rbspx + '_efw_xspec_'+bins+'_xspec1_src1','ztitle',ztitle[0]

	options,rbspx + '_efw_xspec_'+bins+'_xspec1_src2','ytitle',ytitle[1]
	options,rbspx + '_efw_xspec_'+bins+'_xspec1_src2',labflag = 1
	options,rbspx + '_efw_xspec_'+bins+'_xspec1_src2','ztitle',ztitle[1]

	options,rbspx + '_efw_xspec_'+bins+'_xspec1_rc','ytitle',ytitle[2]
	options,rbspx + '_efw_xspec_'+bins+'_xspec1_rc',labflag = 1
	options,rbspx + '_efw_xspec_'+bins+'_xspec1_rc','ztitle',ztitle[2]

	options,rbspx + '_efw_xspec_'+bins+'_xspec1_ic','ytitle',ytitle[3]
	options,rbspx + '_efw_xspec_'+bins+'_xspec1_ic',labflag = 1
	options,rbspx + '_efw_xspec_'+bins+'_xspec1_ic','ztitle',ztitle[3]



;-----------------------------------------------
;Calculate phase and coherence values
;-----------------------------------------------

	
	nxspec=4
	xspec_names = [rbspx+'_efw_xspec_'+bins+'_xspec' + string(lindgen(nxspec),format='(I0)')]
	rc_names = xspec_names + '_rc'
	ic_names = xspec_names + '_ic'
	src1_names = xspec_names + '_src1'
	src2_names = xspec_names + '_src2'
	
	for count=0,nxspec-1 do begin
		
		get_data,rc_names[count],data=rc_temp,limits=rclimits,dlimits=rcdlimits
		get_data,ic_names[count],data=ic_temp
		get_data,src1_names[count],data=src1_temp,limits=src1limits,dlimits=src1dlimits
		get_data,src2_names[count],data=src2_temp
		
		; make sure we have the data and calculate phase, coherence
		if is_struct(rc_temp) and is_struct(ic_temp) and $
			is_struct(src1_temp) and is_struct(src2_temp) then begin
		
			phase_temp=ATAN(ic_temp.y, rc_temp.y)/!DTOR
			coh_temp=(rc_temp.y^2 + ic_temp.y^2)/(src1_temp.y * src2_temp.y )

			small=1.e-3
			badpts=where( sqrt(src1_temp.y) * sqrt(src2_temp.y) lt small)
			
			if badpts[0] ne -1 then coh_temp[badpts]=0.
			
			phase_struct={x:rc_temp.x,y:phase_temp,v:rc_temp.v}
			store_data,xspec_names[count]+'_phase',data=phase_struct,$
				limits=rclimits,dlimits=rcdlimits
			print,'Saved:  '+xspec_names[count]+'_phase'
	
			coh_struct={x:rc_temp.x,y:coh_temp,v:rc_temp.v}
			store_data,xspec_names[count]+'_coh',data=coh_struct,$
				limits=rclimits,dlimits=rcdlimits
			print,'Saved:  '+xspec_names[count]+'_coh'
		
		endif

	endfor




	options,rbspx+'_efw_xspec_'+bins+'_xspec0_phase','ytitle',src1[0]+' x '+src2[0]+'!Cphase angle!C[Hz]'
	options,rbspx+'_efw_xspec_'+bins+'_xspec0_phase','ztitle','!Cdegrees!C!C'+'RBSP'+probe+' EFW Xspec'
	options,rbspx+'_efw_xspec_'+bins+'_xspec0_coh','ytitle',src1[0]+' x '+src2[0]+'!CCoherence!C[Hz]'
	options,rbspx+'_efw_xspec_'+bins+'_xspec0_coh','ztitle','!CCoherence!C!C'+'RBSP'+probe+' EFW Xspec'


	options,rbspx+'_efw_xspec_'+bins+'_xspec1_phase','ytitle',src1[1]+' x '+src2[1]+'!Cphase angle!C[Hz]'
	options,rbspx+'_efw_xspec_'+bins+'_xspec1_phase','ztitle','!Cdegrees!C!C'+'RBSP'+probe+' EFW Xspec'
	options,rbspx+'_efw_xspec_'+bins+'_xspec1_coh','ytitle',src1[1]+' x '+src2[1]+'!CCoherence!C[Hz]'
	options,rbspx+'_efw_xspec_'+bins+'_xspec1_coh','ztitle','!CCoherence!C!C'+'RBSP'+probe+' EFW Xspec'
	

	options,rbspx+'_efw_xspec_'+bins+'_xspec*_phase','zlog',1
	
	

;-------------------------------------------------------------------------------------------------
;Find where phase = 0 and set to NaN. Otherwise zero values will be some color...doesn't look nice
;-------------------------------------------------------------------------------------------------

	
	get_data,rbspx+'_efw_xspec_'+bins+'_xspec0_phase',data=dd
	goo = where(dd.y eq 0)
	if goo[0] ne -1 then dd.y[goo] = !values.f_nan
	store_data,rbspx+'_efw_xspec_'+bins+'_xspec0_phase',data=dd
	
	get_data,rbspx+'_efw_xspec_'+bins+'_xspec1_phase',data=dd
	goo = where(dd.y eq 0)
	if goo[0] ne -1 then dd.y[goo] = !values.f_nan
	store_data,rbspx+'_efw_xspec_'+bins+'_xspec1_phase',data=dd




;---------------------------------
;Set variable ranges
;---------------------------------


	ylim,rbspx+'_efw_xspec_'+bins+'_xspec*_src1',1,10000,1
	ylim,rbspx+'_efw_xspec_'+bins+'_xspec*_src2',1,10000,1
	ylim,rbspx+'_efw_xspec_'+bins+'_xspec*_phase',1,10000,1
	ylim,rbspx+'_efw_xspec_'+bins+'_xspec*_rc',1,10000,1
	ylim,rbspx+'_efw_xspec_'+bins+'_xspec*_ic',1,10000,1
	ylim,rbspx+'_efw_xspec_'+bins+'_xspec*_coh',1,10000,1


;Set separate zrange for SCM, E and V channels
	if strmid(src1[0],0,1) eq 'S' then zr = [0.0001^2,0.01^2]
	if strmid(src1[0],0,1) eq 'E' then zr = [0.001^2,0.1^2]
	if strmid(src1[0],0,1) eq 'V' then zr = [0.001^2,0.1^2]
	zlim,rbspx+'_efw_xspec_'+bins+'_xspec0_src1',zr[0],zr[1],1


	if strmid(src2[0],0,1) eq 'S' then zr = [0.0001^2,0.01^2]
	if strmid(src2[0],0,1) eq 'E' then zr = [0.001^2,0.1^2]
	if strmid(src2[0],0,1) eq 'V' then zr = [0.001^2,0.1^2]
	zlim,rbspx+'_efw_xspec_'+bins+'_xspec0_src2',zr[0],zr[1],1


	if strmid(src1[1],0,1) eq 'S' then zr = [0.0001^2,0.01^2]
	if strmid(src1[1],0,1) eq 'E' then zr = [0.001^2,0.1^2]
	if strmid(src1[1],0,1) eq 'V' then zr = [0.001^2,0.1^2]
	zlim,rbspx+'_efw_xspec_'+bins+'_xspec1_src1',0.001^2,0.1^2,1


	if strmid(src2[1],0,1) eq 'S' then zr = [0.0001^2,0.01^2]
	if strmid(src2[1],0,1) eq 'E' then zr = [0.001^2,0.1^2]
	if strmid(src2[1],0,1) eq 'V' then zr = [0.001^2,0.1^2]
	zlim,rbspx+'_efw_xspec_'+bins+'_xspec1_src2',0.001^2,0.1^2,1


	zlim,rbspx+'_efw_xspec_'+bins+'_xspec?_phase',-180,180,0
	zlim,rbspx+'_efw_xspec_'+bins+'_xspec?_coh',0.1,1,1

	zlim,rbspx+'_efw_xspec_'+bins+'_xspec?_rc',zr[0],zr[1],1
	zlim,rbspx+'_efw_xspec_'+bins+'_xspec?_ic',zr[0],zr[1],1
	
	
endif else begin
	  print, ''
  dprint, 'Invalid datatype. Calibration aborted.'
  print, ''
 return


endelse



;Fix the bin labels


if bins eq '36' then begin

	tplot_names,'rbsp'+probe+'_efw_xspec_36_xspec?_*',names=tnames
	
	; 36 bin spec
	fbins_36 = [findgen(8)*8,findgen(4)*16+64,$
			findgen(4)*32+128,findgen(4)*64+256,$
			findgen(4)*128+512,findgen(4)*256+1024,$
			findgen(4)*512+2048,findgen(4)*1024+4096]
	
	fcenter_36=(fbins_36[0:35] + fbins_36[1:35])/2.
	
	fbin_labels_36=strarr(36)
	fbin_labels_36[0:35]=string(fbins_36[0:35], format='(I0)')+'-'+$
				string(fbins_36[1:36], format='(I0)')+' Hz'
	
	
	for i=0,size(tnames,/n_elements)-1 do begin
		get_data,tnames[i],data=d,limits=l,dlimits=dl
		if is_struct(d) then d.v=fbins_36[0:35]
		store_data,tnames[i],data=d,limits=l,dlimits=dl
	endfor


endif

if bins eq '64' then begin

	tplot_names,'rbsp'+probe+'_efw_xspec_64_xspec?_*',names=tnames
	
	
	; 64 bin spec
	fbins_64=[findgen(16)*8., findgen(8)*16.+128, $
				findgen(8)*32.+256, findgen(8)*64.+512,$
				findgen(8)*128.+1024., findgen(8)*256.+2048, $
				findgen(9)*512.+4096]
	
	fcenter_64=(fbins_64[0:63] + fbins_64[1:64])/2.
	
	fbin_labels_64=strarr(64)
	fbin_labels_64[0:63]=string(fbins_64[0:63], format='(I0)')+'-'+$
				string(fbins_64[1:64], format='(I0)')+' Hz'
	
	
	for i=0,size(tnames,/n_elements)-1 do begin
		get_data,tnames[i],data=d,limits=l,dlimits=dl
		if is_struct(d) then d.v=fbins_64[0:63]
		store_data,tnames[i],data=d,limits=l,dlimits=dl
	endfor
endif


if bins eq '112' then begin

	tplot_names,'rbsp'+probe+'_efw_xspec_112_xspec?_*',names=tnames
	
	
	; 112 bin spec
	fbins_112 = [findgen(32)*8,findgen(16)*16+256,$
			findgen(16)*32+512,findgen(16)*64+1024,$
			findgen(16)*128+2048,findgen(16)*256+4096]
	
	fcenter_112=(fbins_112[0:111] + fbins_112[1:112])/2.
	
	fbin_labels_112=strarr(112)
	fbin_labels_112[0:111]=string(fbins_112[0:111], format='(I0)')+'-'+$
				string(fbins_112[1:112], format='(I0)')+' Hz'
	
	
	for i=0,size(tnames,/n_elements)-1 do begin
		get_data,tnames[i],data=d,limits=l,dlimits=dl
		if is_struct(d) then d.v=fbins_112[0:111]
		store_data,tnames[i],data=d,limits=l,dlimits=dl
	endfor
endif



end



