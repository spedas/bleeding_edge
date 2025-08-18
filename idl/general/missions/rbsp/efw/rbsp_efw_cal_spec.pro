;+
; NAME: rbsp_efw_cal_spec
;
; PURPOSE: Calibrate RBSP spectral data
;
; NOTES: Intended to be called from rbsp_load_efw_spec.pro
;
; TO DO: 
;		-No accounting for possible midday source change
;		-not using boom shorting factor
;
;		There are 7 returned spec channels. The possibilities are
;			Select 7 of: E12dc,E34dc,E56dc
;						 E12ac,E34ac,E56ac
;						 Edcpar,Edcprp
;						 Eacpar,Eacprp
;						 V1ac,V2ac,V3ac,V4ac,V5ac,V6ac
;						 SCMU,SCMV,SCMW
;						 SCMpar,SCMprp,
;						 (V1dc+V2dc+V3dc+V4dc)/4,
;						 Edcprp2, Eacprp2, SCMprp2
;		
;
; Calibration procedure
;
;	subtract offset
;		vals = (double(vals) - offset[j])
;   Compensate for 4 bit dynamic range compression
;       vals /= 16.
;	Divide the 0th bin by 4 (from weirdness doc)
;		vals[*,0] /= 4.
;	Compensate for using Hanning window
;		vals /= 0.375^2
;	Apply ADC conversion
;		vals *= adc_factor^2
;	Apply channel gain
;		vals *= gain[j]^2   (V^2/Hz at this point)
;	Apply boom length to change from V^2/Hz to mV/m^2/Hz				
;		vals *=  conversion[j]^2   ;mV/m ^2 /Hz
;
;	Apply freq dependent gain
;			
;
;
;
; HISTORY:
;   2012-09-xx: Created by Aaron W Breneman, University of Minnesota
;	2013-04-xx: added automated channel selection
;	2013-04-23: added freq-dependent gain
;	2013-05-15: freq-dependent gain curves now obtained from rbsp_efw_get_gain_results.pro and
;				are no longer "hard-wired" into this code. Also added the full 
;				freq-dependent correction as well as the mu-metal square can (nT/v)
;				curves to correct the SCM data.
;
;
; VERSION:
; $LastChangedBy:  $
; $LastChangedDate:  $
; $LastChangedRevision:  $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/ssl_general/trunk/missions/rbsp/efw/rbsp_efw_cal_fbk.pro $
;
;-


pro rbsp_efw_cal_spec, probe=probe, trange=trange, datatype=datatype, pT=pT


;Spec sources
get_data,'rbsp'+probe+'_efw_spec_64_ccsds_data_DFB_config',data=dfbc
dfbconfig = rbsp_get_efw_dfb_config(dfbc.y)
src = dfbconfig[0].spec_config.spec_src





;***********GET THE CALIBRATION FILE*****************
;path = '~/Desktop/code/Aaron/RBSP/TDAS_trunk_svn/ssl_general/missions/rbsp/efw/calibration_files/'
;restore,path + 'gain_curves.idl'
   
;plot,tmp.freqs,tmp.gain


;
	;rbsp_efw_init
;
;	rbsp_burst=!rbsp_efw
;	rbsp_burst.remote_data_dir='http://tetra.space.umn.edu/rbspdata/'
;	
;	dt=1.e-6
;	
;	if keyword_set(probe) then p_var=probe else p_var='*'
;	vprobes = ['a','b']
;	p_var = strfilter(vprobes, p_var ,delimiter=' ',/string)
;	
;	for p=0,size(p_var,/n_elements)-1 do begin
;	
;		rbspx = 'rbsp'+ p_var[p]
;	
;		for b=1,2 do begin
;	
;			bid='vb'+string(b,format='(I0)')
;		
;			format = rbspx + '/'+bid+'_playback/YYYY/'+ $
;					rbspx+'_efw_'+bid+'_playback_YYYYMMDD_v*.txt'
;
;			relpathnames = file_dailynames(file_format=format,trange=trange, $
;					addmaster=addmaster)
;
;			files=file_retrieve(relpathnames,/last_version,_extra=rbsp_burst)
;

;***********GET THE CALIBRATION FILE*****************





if datatype eq 'spec' then begin

	compile_opt idl2
	
	;dprint,verbose=verbose,dlevel=4,'$Id: rbsp_efw_cal_filterbank.pro 10920 2012-09-17 17:08:00Z aaron_breneman $'
	
	if ~keyword_set(trange) then trange = timerange()
	
	cp0 = rbsp_efw_get_cal_params(trange[0])
	;Get gain(f) parameters
	fcals = rbsp_efw_get_gain_results()
	;Get boom lengths
	bl = rbsp_efw_boom_deploy_history(trange[0])
	
	
	; first see if we have 36, 64, or 112 bins
	names=''
	nn=''
	names=tnames('rbsp'+probe+'*spec?')
	if strlen(names[0]) ne 0 then nn=strmid(names[0],10,1)

	case nn of
		'3': bins = '36'
		'6': bins = '64'
		'1': bins = '112'
		else: dprint,'NOT CORRECT NUMBER OF BINS...CALIBRATION ABORTED**************'
	endcase

	case strlowcase(probe) of
	  'a': cp = cp0.a
	  'b': cp = cp0.b
	  else: dprint, 'INVALID PROBE NAME. CALIBRATION ABORTED*************'
	endcase
	

	adc_factor = 2.5d / 32767.5d
	
;	boom_shorting_factor = cp.boom_shorting_factor
	
	rbspx = 'rbsp' + probe[0]
	
	
	tvar = rbspx + ['_efw_64_spec0',$
					'_efw_64_spec1',$
					'_efw_64_spec2',$
					'_efw_64_spec3',$
					'_efw_64_spec4',$
					'_efw_64_spec5',$
					'_efw_64_spec6']


	gain = replicate(0.,n_elements(src))
	offset = replicate(0.,n_elements(src))
	conversion = replicate(0.,n_elements(src))
	units = replicate('',n_elements(src))
	zlims = replicate(0d,n_elements(src),2)


	if ~keyword_set(pT) then pTf = 1. else pTf = 1000.
	if ~keyword_set(pT) then pTnT = 'nT' else pTnT = 'pT'
	if ~keyword_set(pT) then pTnT_zscale = 1. else pTnT_zscale=1d3


	;frequency bins
	fbins_36L = fcals.cal_spec.freq_spec36L
	fbins_36H = fcals.cal_spec.freq_spec36H
	fbins_36C = fcals.cal_spec.freq_spec36C
	fbins_64L = fcals.cal_spec.freq_spec64L
	fbins_64H = fcals.cal_spec.freq_spec64H
	fbins_64C = fcals.cal_spec.freq_spec64C
	fbins_112L = fcals.cal_spec.freq_spec112L
	fbins_112H = fcals.cal_spec.freq_spec112H
	fbins_112C = fcals.cal_spec.freq_spec112C



	if bins eq '36' then gainf = replicate(0.,36,7)
	if bins eq '64' then gainf = replicate(0.,64,7)
	if bins eq '112' then gainf = replicate(0.,112,7)
	

	;Determine parameters for each channel
	for bb=0,6 do begin
		case src[bb] of
	
			'E12AC': begin
						gain[bb] = cp.adc_gain_eac[0]
						if bins eq '36' then gainf[*,bb] = replicate(1.,36)
						if bins eq '64' then gainf[*,bb] = replicate(1.,64)
						if bins eq '112' then gainf[*,bb] = replicate(1.,112)
						offset[bb] = cp.adc_offset_eac[0]
;						conversion[bb] = 1000./cp.boom_length[0]
						if probe eq 'a' then conversion[bb] = 1000./bl.A12
						if probe eq 'b' then conversion[bb] = 1000./bl.B12
						units[bb] = '(mV/m)!U2!N'
						zlims[bb,*] = [1d-3^2,1d-1^2]						
					 end
			'E34AC': begin
						gain[bb] = cp.adc_gain_eac[1]
						if bins eq '36' then gainf[*,bb] = replicate(1.,36)
						if bins eq '64' then gainf[*,bb] = replicate(1.,64)
						if bins eq '112' then gainf[*,bb] = replicate(1.,112)
						offset[bb] = cp.adc_offset_eac[1]
;						conversion[bb] = 1000./cp.boom_length[1]
						if probe eq 'a' then conversion[bb] = 1000./bl.A34
						if probe eq 'b' then conversion[bb] = 1000./bl.B34
						units[bb] = '(mV/m)!U2!N'
						zlims[bb,*] = [1d-3^2,1d-1^2]
					 end
			'E56AC': begin
						gain[bb] = cp.adc_gain_eac[2]
						if bins eq '36' then gainf[*,bb] = replicate(1.,36)
						if bins eq '64' then gainf[*,bb] = replicate(1.,64)
						if bins eq '112' then gainf[*,bb] = replicate(1.,112)
						offset[bb] = cp.adc_offset_eac[2]
;						conversion[bb] = 1000./cp.boom_length[2]
						if probe eq 'a' then conversion[bb] = 1000./bl.A56
						if probe eq 'b' then conversion[bb] = 1000./bl.B56
						units[bb] = '(mV/m)!U2!N'
						zlims[bb,*] = [1d-3^2,1d-1^2]
					 end
			'E12DC': begin
						gain[bb] = cp.adc_gain_edc[0]
						if probe eq 'a' then begin
							if bins eq '36' then gainf[*,bb] = fcals.cal_spec.e12DC_a_spec36.gain_vs_freq
							if bins eq '64' then gainf[*,bb] = fcals.cal_spec.e12DC_a_spec64.gain_vs_freq
							if bins eq '112' then gainf[*,bb] = fcals.cal_spec.e12DC_a_spec112.gain_vs_freq
						endif else begin
							if bins eq '36' then gainf[*,bb] = fcals.cal_spec.e12DC_b_spec36.gain_vs_freq
							if bins eq '64' then gainf[*,bb] = fcals.cal_spec.e12DC_b_spec64.gain_vs_freq
							if bins eq '112' then gainf[*,bb] = fcals.cal_spec.e12DC_b_spec112.gain_vs_freq
						endelse							
						offset[bb] = cp.adc_offset_edc[0]
;						conversion[bb] = 1000./cp.boom_length[0]
						if probe eq 'a' then conversion[bb] = 1000./bl.A12
						if probe eq 'b' then conversion[bb] = 1000./bl.B12
						units[bb] = '(mV/m)!U2!N'
						zlims[bb,*] = [1d-3^2,1d-1^2]
					 end
			'E34DC': begin
						gain[bb] = cp.adc_gain_edc[1]
						if probe eq 'a' then begin
							if bins eq '36' then gainf[*,bb] = fcals.cal_spec.e34DC_a_spec36.gain_vs_freq
							if bins eq '64' then gainf[*,bb] = fcals.cal_spec.e34DC_a_spec64.gain_vs_freq
							if bins eq '112' then gainf[*,bb] = fcals.cal_spec.e34DC_a_spec112.gain_vs_freq
						endif else begin
							if bins eq '36' then gainf[*,bb] = fcals.cal_spec.e34DC_b_spec36.gain_vs_freq
							if bins eq '64' then gainf[*,bb] = fcals.cal_spec.e34DC_b_spec64.gain_vs_freq
							if bins eq '112' then gainf[*,bb] = fcals.cal_spec.e34DC_b_spec112.gain_vs_freq
						endelse
						offset[bb] = cp.adc_offset_edc[1]
;						conversion[bb] = 1000./cp.boom_length[1]
						if probe eq 'a' then conversion[bb] = 1000./bl.A34
						if probe eq 'b' then conversion[bb] = 1000./bl.B34
						units[bb] = '(mV/m)!U2!N'
						zlims[bb,*] = [1d-3^2,1d-1^2]
					 end
			'E56DC': begin
						gain[bb] = cp.adc_gain_edc[2]
						if probe eq 'a' then begin
							if bins eq '36' then gainf[*,bb] = fcals.cal_spec.e56DC_a_spec36.gain_vs_freq
							if bins eq '64' then gainf[*,bb] = fcals.cal_spec.e56DC_a_spec64.gain_vs_freq
							if bins eq '112' then gainf[*,bb] = fcals.cal_spec.e56DC_a_spec112.gain_vs_freq
						endif else begin
							if bins eq '36' then gainf[*,bb] = fcals.cal_spec.e56DC_b_spec36.gain_vs_freq
							if bins eq '64' then gainf[*,bb] = fcals.cal_spec.e56DC_b_spec64.gain_vs_freq
							if bins eq '112' then gainf[*,bb] = fcals.cal_spec.e56DC_b_spec112.gain_vs_freq
						endelse
						offset[bb] = cp.adc_offset_edc[2]
;						conversion[bb] = 1000./cp.boom_length[2]
						if probe eq 'a' then conversion[bb] = 1000./bl.A56
						if probe eq 'b' then conversion[bb] = 1000./bl.B56
						units[bb] = '(mV/m)!U2!N'
						zlims[bb,*] = [1d-3^2,1d-1^2]
					 end
			'V1DC': begin
						gain[bb] = cp.adc_gain_vdc[0]
						if bins eq '36' then gainf[*,bb] = replicate(1.,36)
						if bins eq '64' then gainf[*,bb] = replicate(1.,64)
						if bins eq '112' then gainf[*,bb] = replicate(1.,112)
						offset[bb] = cp.adc_offset_vdc[0]
						conversion[bb] = 1.
						units[bb] = 'volts!U2!N'
						zlims[bb,*] = [1d-4^2,1d-2^2]
					end
			'V2DC': begin
						gain[bb] = cp.adc_gain_vdc[1]
						if bins eq '36' then gainf[*,bb] = replicate(1.,36)
						if bins eq '64' then gainf[*,bb] = replicate(1.,64)
						if bins eq '112' then gainf[*,bb] = replicate(1.,112)
						offset[bb] = cp.adc_offset_vdc[1]
						conversion[bb] = 1.
						units[bb] = 'volts!U2!N'
						zlims[bb,*] = [1d-4^2,1d-2^2]
					end
			'V3DC': begin
						gain[bb] = cp.adc_gain_vdc[2]
						if bins eq '36' then gainf[*,bb] = replicate(1.,36)
						if bins eq '64' then gainf[*,bb] = replicate(1.,64)
						if bins eq '112' then gainf[*,bb] = replicate(1.,112)
						offset[bb] = cp.adc_offset_vdc[2]
						conversion[bb] = 1.
						units[bb] = 'volts!U2!N'
						zlims[bb,*] = [1d-4^2,1d-2^2]
					end
			'V4DC': begin
						gain[bb] = cp.adc_gain_vdc[3]
						if bins eq '36' then gainf[*,bb] = replicate(1.,36)
						if bins eq '64' then gainf[*,bb] = replicate(1.,64)
						if bins eq '112' then gainf[*,bb] = replicate(1.,112)
						offset[bb] = cp.adc_offset_vdc[3]
						conversion[bb] = 1.
						units[bb] = 'volts!U2!N'
						zlims[bb,*] = [1d-4^2,1d-2^2]
					end
			'V5DC': begin
						gain[bb] = cp.adc_gain_vdc[4]
						if bins eq '36' then gainf[*,bb] = replicate(1.,36)
						if bins eq '64' then gainf[*,bb] = replicate(1.,64)
						if bins eq '112' then gainf[*,bb] = replicate(1.,112)
						offset[bb] = cp.adc_offset_vdc[4]
						conversion[bb] = 1.
						units[bb] = 'volts!U2!N'
						zlims[bb,*] = [1d-4^2,1d-2^2]
					end
			'V6DC': begin
						gain[bb] = cp.adc_gain_vdc[5]
						if bins eq '36' then gainf[*,bb] = replicate(1.,36)
						if bins eq '64' then gainf[*,bb] = replicate(1.,64)
						if bins eq '112' then gainf[*,bb] = replicate(1.,112)
						offset[bb] = cp.adc_offset_vdc[5]
						conversion[bb] = 1.
						units[bb] = 'volts!U2!N'
						zlims[bb,*] = [1d-4^2,1d-2^2]
					end

			'V1AC': begin
						gain[bb] = cp.adc_gain_vac[0]
						if bins eq '36' then gainf[*,bb] = replicate(1.,36)
						if bins eq '64' then gainf[*,bb] = replicate(1.,64)
						if bins eq '112' then gainf[*,bb] = replicate(1.,112)
						offset[bb] = cp.adc_offset_vac[0]
						conversion[bb] = 1.
						units[bb] = 'volts!U2!N'
						zlims[bb,*] = [1d-4^2,1d-2^2]
					end
			'V2AC': begin
						gain[bb] = cp.adc_gain_vac[1]
						if bins eq '36' then gainf[*,bb] = replicate(1.,36)
						if bins eq '64' then gainf[*,bb] = replicate(1.,64)
						if bins eq '112' then gainf[*,bb] = replicate(1.,112)
						offset[bb] = cp.adc_offset_vac[1]
						conversion[bb] = 1.
						units[bb] = 'volts!U2!N'
						zlims[bb,*] = [1d-4^2,1d-2^2]
					end
			'V3AC': begin
						gain[bb] = cp.adc_gain_vac[2]
						if bins eq '36' then gainf[*,bb] = replicate(1.,36)
						if bins eq '64' then gainf[*,bb] = replicate(1.,64)
						if bins eq '112' then gainf[*,bb] = replicate(1.,112)
						offset[bb] = cp.adc_offset_vac[2]
						conversion[bb] = 1.
						units[bb] = 'volts!U2!N'
						zlims[bb,*] = [1d-4^2,1d-2^2]
					end
			'V4AC': begin
						gain[bb] = cp.adc_gain_vac[3]
						if bins eq '36' then gainf[*,bb] = replicate(1.,36)
						if bins eq '64' then gainf[*,bb] = replicate(1.,64)
						if bins eq '112' then gainf[*,bb] = replicate(1.,112)
						offset[bb] = cp.adc_offset_vac[3]
						conversion[bb] = 1.
						units[bb] = 'volts!U2!N'
						zlims[bb,*] = [1d-4^2,1d-2^2]
					end
			'V5AC': begin
						gain[bb] = cp.adc_gain_vac[4]
						if bins eq '36' then gainf[*,bb] = replicate(1.,36)
						if bins eq '64' then gainf[*,bb] = replicate(1.,64)
						if bins eq '112' then gainf[*,bb] = replicate(1.,112)
						offset[bb] = cp.adc_offset_vac[4]
						conversion[bb] = 1.
						units[bb] = 'volts!U2!N'
						zlims[bb,*] = [1d-4^2,1d-2^2]
					end
			'V6AC': begin
						gain[bb] = cp.adc_gain_vac[5]
						if bins eq '36' then gainf[*,bb] = replicate(1.,36)
						if bins eq '64' then gainf[*,bb] = replicate(1.,64)
						if bins eq '112' then gainf[*,bb] = replicate(1.,112)
						offset[bb] = cp.adc_offset_vac[5]
						conversion[bb] = 1.
						units[bb] = 'volts!U2!N'
						zlims[bb,*] = [1d-4^2,1d-2^2]
					end

			'SCMU': begin
						gain[bb] = cp.adc_gain_msc[0]
						;*******************
						;***TEMPORARY - rbsp_efw_get_cal_params HAS A ROUGH SQ-CAN FACTOR
						;BUILT IN. I GET THE CORRECT CURVES FROM rbsp_efw_get_gain_results. SO, I NEED
						;TO MANUALLY REMOVE THE CORRECTION HERE. 
						;if probe eq 'a' then gain[bb] /= 2.35 else gain[bb] /= 2.33
						;*******************

						if probe eq 'a' then begin
							if bins eq '36' then gain_tmp = fcals.cal_spec.scmu_a_spec36.gain_vs_freq
							if bins eq '64' then gain_tmp = fcals.cal_spec.scmu_a_spec64.gain_vs_freq
							if bins eq '112' then gain_tmp = fcals.cal_spec.scmu_a_spec112.gain_vs_freq
			  				;nT per volt square can conversion curve
							if bins eq '36' then nT_volt = fcals.cal_spec.scmu_a_spec36.stimcoil_nt2v
							if bins eq '64' then nT_volt = fcals.cal_spec.scmu_a_spec64.stimcoil_nt2v
							if bins eq '112' then nT_volt = fcals.cal_spec.scmu_a_spec112.stimcoil_nt2v
						endif else begin
							if bins eq '36' then gain_tmp = fcals.cal_spec.scmu_b_spec36.gain_vs_freq
							if bins eq '64' then gain_tmp = fcals.cal_spec.scmu_b_spec64.gain_vs_freq
							if bins eq '112' then gain_tmp = fcals.cal_spec.scmu_b_spec112.gain_vs_freq
			  				;nT per volt square can conversion curve
							if bins eq '36' then nT_volt = fcals.cal_spec.scmu_b_spec36.stimcoil_nt2v
							if bins eq '64' then nT_volt = fcals.cal_spec.scmu_b_spec64.stimcoil_nt2v
							if bins eq '112' then nT_volt = fcals.cal_spec.scmu_b_spec112.stimcoil_nt2v							
						endelse

						gainf[*,bb] = 1/(gain_tmp * nT_volt)
						offset[bb] = cp.adc_offset_msc[0]
						conversion[bb] = pTf
						units[bb] = pTnT+'!U2!N'
						zlims[bb,*] = [(pTnT_zscale*1d-4)^2,(pTnT_zscale*1d-2)^2]
					end
			'SCMV': begin
						gain[bb] = cp.adc_gain_msc[1]
						;*******************
						;***TEMPORARY - rbsp_efw_get_cal_params HAS A ROUGH SQ-CAN FACTOR
						;BUILT IN. I GET THE CORRECT CURVES FROM rbsp_efw_get_gain_results. SO, I NEED
						;TO MANUALLY REMOVE THE CORRECTION HERE. 
						;if probe eq 'a' then gain[bb] /= 2.22 else gain[bb] /= 2.10
						;*******************
						if probe eq 'a' then begin
							if bins eq '36' then gain_tmp = fcals.cal_spec.scmv_a_spec36.gain_vs_freq
							if bins eq '64' then gain_tmp = fcals.cal_spec.scmv_a_spec64.gain_vs_freq
							if bins eq '112' then gain_tmp = fcals.cal_spec.scmv_a_spec112.gain_vs_freq
			  				;nT per volt square can conversion curve
							if bins eq '36' then nT_volt = fcals.cal_spec.scmv_a_spec36.stimcoil_nt2v
							if bins eq '64' then nT_volt = fcals.cal_spec.scmv_a_spec64.stimcoil_nt2v
							if bins eq '112' then nT_volt = fcals.cal_spec.scmv_a_spec112.stimcoil_nt2v
						endif else begin
							if bins eq '36' then gain_tmp = fcals.cal_spec.scmv_b_spec36.gain_vs_freq
							if bins eq '64' then gain_tmp = fcals.cal_spec.scmv_b_spec64.gain_vs_freq
							if bins eq '112' then gain_tmp = fcals.cal_spec.scm_b_spec112.gain_vs_freq
			  				;nT per volt square can conversion curve
							if bins eq '36' then nT_volt = fcals.cal_spec.scmv_b_spec36.stimcoil_nt2v
							if bins eq '64' then nT_volt = fcals.cal_spec.scmv_b_spec64.stimcoil_nt2v
							if bins eq '112' then nT_volt = fcals.cal_spec.scmv_b_spec112.stimcoil_nt2v							
						endelse


						gainf[*,bb] = 1/(gain_tmp * nT_volt)
						offset[bb] = cp.adc_offset_msc[1]
						conversion[bb] = pTf
						units[bb] = pTnT+'!U2!N'
						zlims[bb,*] = [(pTnT_zscale*1d-4)^2,(pTnT_zscale*1d-2)^2]
					end
			'SCMW': begin
						gain[bb] = cp.adc_gain_msc[2]
						;*******************
						;***TEMPORARY - rbsp_efw_get_cal_params HAS A ROUGH SQ-CAN FACTOR
						;BUILT IN. I GET THE CORRECT CURVES FROM rbsp_efw_get_gain_results. SO, I NEED
						;TO MANUALLY REMOVE THE CORRECTION HERE. 
						;if probe eq 'a' then gain[bb] /= 2.22 else gain[bb] /= 2.22
						;*******************
						if probe eq 'a' then begin
							if bins eq '36' then gain_tmp = fcals.cal_spec.scmw_a_spec36.gain_vs_freq
							if bins eq '64' then gain_tmp = fcals.cal_spec.scmw_a_spec64.gain_vs_freq
							if bins eq '112' then gain_tmp = fcals.cal_spec.scmw_a_spec112.gain_vs_freq
			  				;nT per volt square can conversion curve
							if bins eq '36' then nT_volt = fcals.cal_spec.scmw_a_spec36.stimcoil_nt2v
							if bins eq '64' then nT_volt = fcals.cal_spec.scmw_a_spec64.stimcoil_nt2v
							if bins eq '112' then nT_volt = fcals.cal_spec.scmw_a_spec112.stimcoil_nt2v
						endif else begin
							if bins eq '36' then gain_tmp = fcals.cal_spec.scmw_b_spec36.gain_vs_freq
							if bins eq '64' then gain_tmp = fcals.cal_spec.scmw_b_spec64.gain_vs_freq
							if bins eq '112' then gain_tmp = fcals.cal_spec.scmw_b_spec112.gain_vs_freq
			  				;nT per volt square can conversion curve
							if bins eq '36' then nT_volt = fcals.cal_spec.scmw_b_spec36.stimcoil_nt2v
							if bins eq '64' then nT_volt = fcals.cal_spec.scmw_b_spec64.stimcoil_nt2v
							if bins eq '112' then nT_volt = fcals.cal_spec.scmw_b_spec112.stimcoil_nt2v							
						endelse
						gainf[*,bb] = 1/(gain_tmp * nT_volt)
						offset[bb] = cp.adc_offset_msc[2]
						conversion[bb] = pTf
						units[bb] = pTnT+'!U2!N'
						zlims[bb,*] = [(pTnT_zscale*1d-4)^2,(pTnT_zscale*1d-2)^2]
					end
		endcase
	endfor


		gain = gain/adc_factor  
	
		ylabel = src
		zlabel = 'RBSP'+probe+' EFW spec'
	
	
		ytitle = ylabel + '!C[Hz]'	
		ztitle = strarr(7)
		for j=0,6 do ztitle[j] = '!C' + units[j] + '/[Hz]!C!C' + zlabel
	
		for j=0,6 do begin
	
	
			get_data,tvar[j],data=data,dlimits=dlim
	
			if dlim.data_att.units eq 'ADC' then begin
	
			tst = size(data)
			
				;make sure there's data
				if tst[0] ne 0 then begin
		

					;subtract offset
					new_y = (double(data.y) - offset[j])

					;Compensate for 4 bit dynamic range compression
					new_y /= 4.^2
				
					;Divide the 0th bin by 4 (from weirdness doc)
					new_y[*,0] /= 4.

					;Compensate for using Hanning window
					new_y /= 0.375^2
				
					;Apply ADC conversion
					new_y *= adc_factor^2
				
					;Apply channel gain
					new_y *= gain[j]^2

					;Apply boom length to change from V to mV/m or from V to nT (or pT)		
					new_y *=  conversion[j]^2 
	
	
					;Apply freq dependent gain (and square can conversion of nT/v for SCM)
					gtmp = reform(gainf[*,j])^2
					for qq=0,n_elements(new_y[*,0])-1 do new_y[qq,*] = new_y[qq,*]*gtmp
	
				
			
					new_data = {x:data.x,y:new_y,v:data.v}
					dlim.data_att.units = units[j]
					dlim.data_att.channel = src[j]
					
					colors = [1]
				
					str_element, dlim, 'cdf', /delete
					str_element, dlim, 'code_id', /delete
				
					newname = tvar[j]
					store_data, newname,data=new_data,dlim=dlim
				
					options,newname,labflag=1
					options,newname,'ytitle',ytitle[j]
					options,newname,'ztitle',ztitle[j]
					ylim,newname,3,10000,1

		
				endif	
			endif else print,tvar[j], ' is already calibrated'
		endfor



	endif else begin
		print, ''
		dprint, 'Invalid datatype. Calibration aborted.'
		print, ''
		return
	endelse




	zlim,rbspx +'_efw_'+bins+'_spec0',zlims[0,0],zlims[0,1],1
	zlim,rbspx +'_efw_'+bins+'_spec1',zlims[1,0],zlims[1,1],1
	zlim,rbspx +'_efw_'+bins+'_spec2',zlims[2,0],zlims[2,1],1
	zlim,rbspx +'_efw_'+bins+'_spec3',zlims[3,0],zlims[3,1],1
	zlim,rbspx +'_efw_'+bins+'_spec4',zlims[4,0],zlims[4,1],1
	zlim,rbspx +'_efw_'+bins+'_spec5',zlims[5,0],zlims[5,1],1
	zlim,rbspx +'_efw_'+bins+'_spec6',zlims[6,0],zlims[6,1],1



	;--------------------------------------------
	;Fix the bin labels in the tplot structure
	;--------------------------------------------

	if bins eq '36' then begin
		tplot_names,'*efw_36_spec*',names=tnames
		fbin_label_36 = strtrim(fbins_36L,2) + '-' + strtrim(fbins_36H,2) + ' Hz'
		for i=0,size(tnames,/n_elements)-1 do begin
			get_data,tnames[i],data=d,limits=l,dlimits=dl
			if is_struct(d) then d.v=fbins_36c[0:35]
			store_data,tnames[i],data=d,limits=l,dlimits=dl
		endfor
	endif

	if bins eq '64' then begin
		tplot_names,'*efw_64_spec*',names=tnames
		fbin_label_64 = strtrim(fbins_64L,2) + '-' + strtrim(fbins_64H,2) + ' Hz'
		for i=0,size(tnames,/n_elements)-1 do begin
			get_data,tnames[i],data=d,limits=l,dlimits=dl
			if is_struct(d) then d.v=fbins_64c[0:63]
			store_data,tnames[i],data=d,limits=l,dlimits=dl
		endfor
	endif


	if bins eq '112' then begin
		tplot_names,'*efw_112_spec*',names=tnames
		fbin_label_112 = strtrim(fbins_112L,2) + '-' + strtrim(fbins_112H,2) + ' Hz'
		for i=0,size(tnames,/n_elements)-1 do begin
			get_data,tnames[i],data=d,limits=l,dlimits=dl
			if is_struct(d) then d.v=fbins_112c[0:111]
			store_data,tnames[i],data=d,limits=l,dlimits=dl
		endfor
	endif

end

