;+
;*****************************************************************************************
;
;  FUNCTION :   rbsp_remove_dcfield  (OBSOLETE: SEE rbsp_efw_DCfield_removal_crib.pro)
;  PURPOSE  :   Subtract off DC magnetic field from Bw values. Saves as new tplot files
;
;  CALLED BY:   see rbsp_efw_DCfield_removal_crib
;               
;               
;  REQUIRES:   Need: SSL THEMIS software and IDL Geopack DLM both found at 
;			   http://themis.ssl.berkeley.edu/software.shtml
;  
;
;  INPUT:
;		magname -> tplot name of the [n,3] magnetic field data in GSM
;		posname -> tplot name of the [n,3] GSM position data
;		probe   -> 'a' or 'b'
;		model   -> Any of the Tsyganenko models or IGRF. Defaults to 't96'
;
;
;            
;  EXAMPLES:    see remove_dcfield_crib.pro
;           
;				Produces the following variables (ex for magname = 'rbspa_mag_gsm', model='t96')
;					rbspa_mag_gsm_t96
;					rbspa_mag_gsm_t96_dif
;
;					If the model is not t89 then produces:
;					rbspa_mag_gsm_t96_wind
;					rbspa_mag_gsm_t96_wind_dif
;					rbspa_mag_gsm_t96_ace
;					rbspa_mag_gsm_t96_ace_dif
;					rbspa_mag_gsm_t96_omni
;					rbspa_mag_gsm_t96_omni_dif
;
;
;
;   NOTES:    ruthlessly pilfered from THEMIS crib sheets 
;             Subtracts off Tsyganenko values using input from ACE, Wind and OMNI, as
;			  well as user defined input. 
;  
;
;
;   CREATED:  2012/04/13
;   CREATED BY:  Aaron W. Breneman
;    LAST MODIFIED:  12/10/2012   v1.0.0 - major update. Much simplified
;    MODIFIED BY: AWB
;
;*****************************************************************************************
;-



pro rbsp_subtract_dcfield,$
		magname,$
		posname,$
		probe,$
		model=model



	if ~keyword_set(model) then model = 't96'
	model = strlowcase(model)
	rbspx = 'rbsp'+probe




;In order for the TDAS model subtraction routines to work we have to have the
;mag data named in the following convention: rbsp[a,b]_fgl_gsm	
	get_data,magname,data=dat,dlimits=dlim,limits=lim
	store_data,rbspx + '_fgl_gsm',data=dat,dlimits=dlim,limits=lim
	
	get_data,rbspx+'_fgl_gsm',data=mag_gsm	


	


;GET ACTUAL AND MODEL DATA
	
		
	;actual kp values can be found at: http://www.ngdc.noaa.gov/stp/GEOMAG/kp_ap.html
	if model eq 't89' then par = 2.0D
	


;call the appropriate magnetic field model
	
	if model ne 't89' and model ne 'igrf' then begin
		
		call_procedure,'t'+model,posname,pdyn=2.0D,dsti=-30.0D,$
			yimf=0.0D,zimf=-5.0D
	endif else begin
		if model eq 't89' then call_procedure,'t'+model,posname,kp=2.0		
		if model eq 'igrf' then call_procedure,'tt89',posname,kp=2.0,igrf_only=1	
	endelse



	
	
;Interpolate the model to the number of data points of actual data
	tinterpol_mxn,posname + '_b'+model,$
				  mag_gsm.x,$
				  newname=magname + '_' + model
	store_data,[posname + '_b'+model],/delete
	
	
	
	
;now substract model from input data
	dif_data,magname,$
			 magname + '_' + model,$
			 newname=magname + '_' + model + '_dif'



;	tplot,[magname,$
;		   magname + '_' + model,$
;		   magname + '_' + model + '_dif']









;AUTO PARAMETER DETERMINATION FROM ACTUAL DATA

if model ne 't89' then begin

;--------------
;WIND
;--------------

	;you may have to set the default download directory manually
	;here are some examples:
	;setenv,'ROOT_DATA_DIR=~/data' ;good for single user unix/linux system
	;setenv,'ROOT_DATA_DIR=C:/Documents and Settings/YOURUSERNAME/My Documents' ;example  if you don't want to use the default windows location (C:/data/ or E:/data/)
	
	kyoto_load_dst
	
	;load wind data
	wi_mfi_load,tplotnames=tn
	wi_3dp_load,tplotnames=tn2
	
	if (tn[0] ne '') and (tn2[0] ne '') then begin

		cotrans,'wi_h0_mfi_B3GSE','wi_b3gsm',/GSE2GSM
		
		get_tsy_params,'kyoto_dst','wi_b3gsm','wi_3dp_k0_ion_density','wi_3dp_k0_ion_vel',strupcase(model)
		
		
	;Call the model with the Wind parameters
		if model eq 'igrf' then call_procedure,'igrf',posname,parmod=model+'_par'$
		else call_procedure,'t'+model,posname,parmod=model+'_par'


		get_data,posname + '_b'+model,data=dat
		store_data,posname + '_b'+model+'_wind',data=dat



		
	;Interpolate the model to the number of data points of actual data
		tinterpol_mxn,posname + '_b'+model+'_wind',$
					  mag_gsm.x,$
					  newname=magname + '_'+ model + '_wind'



		dif_data,magname,$
				 magname + '_' + model + '_wind',$
				 newname=magname + '_' + model + '_wind_dif'


;		tplot,[magname,$
;			   magname + '_' + model + '_wind',$
;			   magname + '_' + model + '_wind_dif']


	endif else print,'==> NO WIND DATA AVAILABLE'


;-----------------------------------
;ACE (only available from 2011 on)
;-----------------------------------

	
	ace_mfi_load,tplotnames=tn
	ace_swe_load,tplotnames=tn2
	
	
	if (tn[0] ne '') and (tn2[0] ne '') then begin
	
		;load_ace_mag loads data in gse coords
		cotrans,'ace_k0_mfi_BGSEc','ace_mag_Bgsm',/GSE2GSM
		
		get_tsy_params,'kyoto_dst','ace_mag_Bgsm','ace_k0_swe_Np','ace_k0_swe_Vp',strupcase(model),/speed
		
		if model eq 'igrf' then call_procedure,'igrf',posname,parmod=model+'_par' $
		else call_procedure,'t'+model,posname,parmod=model+'_par'



		get_data,posname + '_b'+model,data=dat
		store_data,posname + '_b'+model+'_ace',data=dat



		
		;Interpolate the model to the number of data points of actual data
		tinterpol_mxn,posname + '_b'+model+'_ace',$
					  mag_gsm.x,$
					  newname=magname + '_' + model + '_ace'


		dif_data,magname,$
				 magname + '_' + model + '_ace',$
				 newname=magname + '_' + model + '_ace_dif'

;		tplot,[magname,$
;			   magname + '_' + model + '_ace',$
;			   magname + '_' + model + '_ace_dif']



	endif else print,'==> NO ACE DATA AVAILABLE'


;---------
;OMNI 
;---------

	;omni data example
	;NOTE: you may want to degap and deflag the data(using tdegap and tdeflag)
	;to remove gaps and flags in the tsyganemo parameter data, especially
	;if you find that there are large gaps in the result  
	
	omni_hro_load,tplotnames=tn
	
	if tn[0] ne '' then begin
			
		store_data,'omni_imf',data=['OMNI_HRO_1min_BY_GSM','OMNI_HRO_1min_BZ_GSM']
		
		get_tsy_params,'kyoto_dst','omni_imf','OMNI_HRO_1min_proton_density','OMNI_HRO_1min_flow_speed',strupcase(model),/speed,/imf_yz
		
	
		
		if model eq 'igrf' then call_procedure,'igrf',posname,parmod=model+'_par' $
		else call_procedure,'t'+model,posname,parmod=model+'_par'



		get_data,posname + '_b'+model,data=dat
		store_data,posname + '_b'+model+'_omni',data=dat

		
		;Interpolate the model to the number of data points of actual data
		tinterpol_mxn,posname + '_b'+model+'_omni',$
					  mag_gsm.x,$
					  newname=magname + '_' + model + '_omni'


		dif_data,magname,$
				 magname + '_' + model + '_omni',$
				 newname=magname + '_' + model + '_omni_dif'


;		tplot,[magname,$
;			   magname + '_' + model + '_omni',$
;			   magname + '_' + model + '_omni_dif']
	

	endif else print,'==> NO OMNI DATA'

endif


	;dipole tilt example
	;add one degree to dipole tilt
	;Can also add time varying tilts, or replace the default dipole tilt with a user defined value
;	tt96, 'th'+probe+'_state_pos',pdyn=2.0D,dsti=-30.0D,yimf=0.0D,zimf=-5.0D,get_tilt='tilt_vals',add_tilt=1
;	tplot, ['th'+probe+'_state_pos_bt96', 'th'+probe+'_fgs_gsm','tilt_vals']



;Remove, rename stuff...

	
	store_data,['*OMNI_HRO*'],/delete
	store_data,['*omni_imf*'],/delete
	store_data,['*ace_k0*','ace_mag_Bgsm'],/delete
	store_data,['*wi_3dp*','*wi_h0*','wi_b3gsm'],/delete
	store_data,['*kyoto_dst*'],/delete
	store_data,['t96_par','par_out'],/delete
	store_data,[rbspx+'_fgl_gsm'],/delete
	
	
	
	options,magname + '_' + model,'ytitle',rbspx + '!C'+strupcase(model)+' mag!CGSM!C[nT]'
	options,magname + '_' + model+'_wind','ytitle',rbspx + '!C'+strupcase(model)+' mag!CGSM!Cwith Wind input!C[nT]'
	options,magname + '_' + model+'_ace','ytitle',rbspx + '!C'+strupcase(model)+' mag!CGSM!Cwith ACE input!C[nT]'
	options,magname + '_' + model+'_omni','ytitle',rbspx + '!C'+strupcase(model)+' mag!CGSM!Cwith OMNI input!C[nT]'
	
	options,magname + '_' + model + '_dif','ytitle',rbspx + '!C'+strupcase(model)+' mag-model!CGSM!C[nT]'
	options,magname + '_' + model+'_wind_dif','ytitle',rbspx + '!C'+strupcase(model)+' mag-model!CGSM!Cwith Wind input!C[nT]'
	options,magname + '_' + model+'_ace_dif','ytitle',rbspx + '!C'+strupcase(model)+' mag-model!CGSM!Cwith ACE input!C[nT]'
	options,magname + '_' + model+'_omni_dif','ytitle',rbspx + '!C'+strupcase(model)+' mag-model!CGSM!Cwith OMNI input!C[nT]'
	
	options,magname + '_' + model,'ysubtitle',''
	options,magname + '_' + model+'_wind','ysubtitle',''
	options,magname + '_' + model+'_ace','ysubtitle',''
	options,magname + '_' + model+'_omni','ysubtitle',''
	
	options,magname + '_' + model + '_dif','ysubtitle',''
	options,magname + '_' + model+'_wind_dif','ysubtitle',''
	options,magname + '_' + model+'_ace_dif','ysubtitle',''
	options,magname + '_' + model+'_omni_dif','ysubtitle',''
	
	


	;change name from T89 to IGRF if appropriate. 
	;Since the IGRF model is called with the T89 routine and a keyword it was easier to change
	;IGRF -> T89 to get the code to work. Here I change it back. 
	if model eq 'igrf' then begin
		get_data,rbspx+'_mag_bt89_original',data=dd
		store_data,rbspx+'_mag_bigrf_original',data={x:dd.x,y:dd.y}
		store_data,[rbspx+'_mag_bt89_original'],/delete	
	endif
	 
end







;-------------------------------------------------
;TEST THE DIFFERENCE B/T THE IGRF AND T89 MODELS
;-------------------------------------------------

;			call_procedure,'t'+model,rbspx+'_state_pos',kp=2.0		
;			get_data,rbspx+'_state_pos_bt89',data=ddd
;			store_data,'t89_tmp',data={x:ddd.x,y:ddd.y}

;			call_procedure,'tt89',rbspx+'_state_pos',kp=2.0,igrf_only=1		
;			get_data,rbspx+'_state_pos_bt89',data=ddd
;			store_data,'igrf_tmp',data={x:ddd.x,y:ddd.y}			
			
;			get_data,'igrf_tmp',data=igrf
;			get_data,'t89_tmp',data=t89
;			split_vec,'igrf_tmp'
;			split_vec,'t89_tmp'
			
;			dif_data,'igrf_tmp_x','t89_tmp_x',newname='diff_x'
;			dif_data,'igrf_tmp_y','t89_tmp_y',newname='diff_y'
;			dif_data,'igrf_tmp_z','t89_tmp_z',newname='diff_z'
;			
;			tplot,['igrf_tmp_x','t89_tmp_x','diff_x']
;			tplot,['igrf_tmp_y','t89_tmp_y','diff_y']
;			tplot,['igrf_tmp_z','t89_tmp_z','diff_z']


;if model eq 'igrf' then call_procedure,'igrf',rbspx+'_state_pos',$
;			pdyn=2.0D,dsti=-30.0D,yimf=0.0D,zimf=-5.0D $
;---------------------------


	;Rename the first model by adding "original" to name b/c it will otherwise be
	;overwritten later when the Wind, ACE, OMNI models are called. 
;	get_data,rbspx+'_state_pos',dlimits=dlm
;	get_data,rbspx+'_state_pos_b'+model,data=dat
;	store_data,rbspx+'_state_pos_b'+model+'_original',data=dat,dlimits=dlm
	