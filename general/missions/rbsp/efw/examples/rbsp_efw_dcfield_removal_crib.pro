;+
;*****************************************************************************************
;
;  FUNCTION :   rbsp_efw_DCfield_removal_crib
;  PURPOSE  :   Subtract off DC magnetic field from Bw values. Saves as new tplot files
;
;               
;  REQUIRES:   Need: SSL THEMIS software and IDL Geopack DLM both found at 
;			   http://themis.ssl.berkeley.edu/software.shtml
;  
;
;  INPUT:
;		probe   -> 'a' or 'b'
;		model   -> Any of the Tsyganenko models or IGRF. Defaults to 't96'
;		ql -> set to load quicklook EMFISIS data
;               cadence -> cadence of EMFISIS data. 'hires', '4sec', '1sec'
;               nodelete -> don't delete various tplot
;               variables upon exit            
;
;  EXAMPLES:   
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
;   CREATED:  2012/12/12
;   CREATED BY:  Aaron W. Breneman
;    LAST MODIFIED:  08/26/2012   v1.0.0 - major update. Much simplified
;    MODIFIED BY: AWB
;
;*****************************************************************************************
;-



pro rbsp_efw_dcfield_removal_crib,probe,no_spice_load=no_spice_load,noplot=noplot,model=model,ql=ql,$
                                  cadence=cadence,nodelete=nodelete,decimate_level=decimate_level,$
                                  boom_pair=bp



; initialize RBSP environment
  rbsp_efw_init
  !rbsp_efw.user_agent = ''


; set desired probe
  rbspx = 'rbsp'+probe
  sc = probe

;Get the time range if it hasn't already been set
  x = timerange()
  date = strmid(time_string(x[0]),0,10)



  if ~keyword_set(cadence) then cadence = '1sec'

  ;;Extended timerange for t01 model
  if model eq 't01' then begin
     x2 = x
     x2[0] = x[0] - 3600.
  endif

;Load spice kernels

                                ;predicted kernels needed to convert very recent UVW mag data to GSE
  if ~keyword_set(no_spice_load) then rbsp_load_spice_kernels
  if ~keyword_set(bp) then bp = '12'
  if bp eq '12' then plane_dim = 0 else plane_dim = 1

;Load RBSP position data and transform to GSM which is needed for the model subtraction


  if model eq 't01' then timespan,x2[0],(x2[1] - x2[0]),/seconds

                                ;Get antenna pointing direction and stuff
  rbsp_load_state,probe=probe,/no_spice_load,datatype=['spinper','spinphase','mat_dsc','Lvec'] 
  rbsp_efw_position_velocity_crib,/no_spice_load,/noplot
  get_data,rbspx+'_spinaxis_direction_gse',data=wsc_GSE

  if model eq 't01' then timespan,x[0],(x[1]-x[0]),/seconds


;Load EMFISIS L3 data in GSE. 
  if ~keyword_set(ql) then begin
     
     rbsp_load_emfisis,probe=probe,coord='gse',cadence=cadence,level='l3' ;load this for the mag model subtract


     ;;decimate the data?
     if keyword_set(decimate_level) then rbsp_decimate,rbspx+'_emfisis_l3_'+cadence+'_gse_Mag',$
        level=decimate_level,newname=rbspx+'_emfisis_l3_'+cadence+'_gse_Mag'


     get_data,rbspx+'_emfisis_l3_'+cadence+'_gse_Mag',data=dd

     if ~is_struct(dd) then begin
        print,'*****  NO EMFISIS L3 DATA TO LOAD *****'
        print,'exiting rbsp_efw_DCfield_removal_crib.pro'
        return
     endif

     tinterpol_mxn,rbspx+'_spinaxis_direction_gse',rbspx+'_emfisis_l3_'+cadence+'_gse_Mag'

     copy_data,rbspx+'_emfisis_l3_'+cadence+'_gse_Mag',rbspx+'_mag_gse'

     get_data,rbspx+'_spinaxis_direction_gse_interp',data=wsc_GSE_tmp
     rbsp_gse2mgse,rbspx+'_mag_gse',reform(wsc_GSE_tmp.y),newname=rbspx+'_mag_mgse'
     
     
     
  endif
  
  if keyword_set(ql) then begin
     rbsp_load_emfisis,probe=probe,/quicklook

     ;;decimate the data?
     if keyword_set(decimate_level) then rbsp_decimate,rbspx+'_emfisis_quicklook_Mag',$
        level=decimate_level,newname=rbspx+'_emfisis_quicklook_Mag'

     get_data,rbspx+'_emfisis_quicklook_Mag',data=dd
     if ~is_struct(dd) then begin
        print,'******NO QL MAG DATA TO LOAD.....rbsp_efw_DCfield_removal_crib.pro*******'
        return
     endif		

     

                                ;Some of the EMFISIS quicklook data extend beyond the day loaded. This messes things up
                                ;later. Remove these data points now. 

     t0 = time_double(date)
     t1 = t0 + 86400.

     ttst = tnames(rbspx+'_emfisis_quicklook_Mag',cnt)
     if cnt eq 1 then time_clip,rbspx+'_emfisis_quicklook_Mag',t0,t1,$
                                replace=1,error=error,newname=rbspx+'_emfisis_quicklook_Mag'
     ttst = tnames(rbspx+'_emfisis_quicklook_Magnitude',cnt)
     if cnt eq 1 then time_clip,rbspx+'_emfisis_quicklook_Magnitude',t0,t1,$
                                replace=1,error=error,newname=rbspx+'_emfisis_quicklook_Magnitude'


                                ;Create the dlimits structure for the EMFISIS quantity. Jianbao's spinfit program needs
                                ;to see that the coords are 'uvw'
     get_data,rbspx +'_emfisis_quicklook_Mag',data=datt
     data_att = {coord_sys:'uvw'}
     dlim = {data_att:data_att}
     store_data,rbspx +'_emfisis_quicklook_Mag',data=datt,dlimits=dlim


                                ;spinfit the mag data and transform to MGSE
     rbsp_decimate,rbspx +'_emfisis_quicklook_Mag', upper = 2
     rbsp_spinfit,rbspx +'_emfisis_quicklook_Mag', plane_dim = plane_dim
     rbsp_cotrans,rbspx +'_emfisis_quicklook_Mag_spinfit', rbspx + '_mag_mgse', /dsc2mgse


                                ;Rotate the MGSE data to GSE
     rbsp_mgse2gse,rbspx + '_mag_mgse',wsc_GSE_tmp.y,newname=rbspx+'_mag_gse',probe=probe,/no_spice_load
     
  endif




;Transform to GSM
  cotrans,rbspx+'_mag_gse',rbspx+'_mag_gsm',/GSE2GSM

  copy_data,rbspx+'_mag_gsm',rbspx+'_mag_gsm_for_subtract'
  copy_data,rbspx+'_mag_gse',rbspx+'_mag_gse_for_subtract'
  copy_data,rbspx+'_mag_mgse',rbspx+'_mag_mgse_for_subtract'
  

  copy_data,rbspx+'_state_pos_gsm','pos_gsm'
  posname = 'pos_gsm'



  if ~keyword_set(model) then model = 't89'
  
;;--------------------------------------------------
;;Call the specific model
;;--------------------------------------------------

  ;;Call the models without any solar wind input. Later, we'll
  ;;also call them with model input from OMNI, Wind, ACE
  if model eq 't89' then call_procedure,'t'+model,posname,kp=2.0,period=0.5
  if model eq 't96' then call_procedure,'t'+model,posname,pdyn=2.0D,dsti=-30.0D,$
                                        yimf=0.0D,zimf=-5.0D,period=0.5

  ;;Vsw of 400 km/s and By=0, Bz=-5 nT (general default values from Tsyganenko02b)



  ;;The t01 model requires a time history of solar wind values. 
  if model eq 't01' then begin
     timespan,x2[0],(x2[1] - x2[0]),/seconds

     g1 = 6.
     g2 = 10.
     if model eq 't01' then call_procedure,'t'+model,posname,pdyn=2.0D,dsti=-30.0D,$
                                           yimf=0.0D,zimf=-5.0D,g1=g1,g2=g2,period=0.5

     ;;return timespan to original
     timespan,x[0],(x[1]-x[0]),/seconds
     time_clip,'pos_gsm_bt01',x[0],x[1],/replace ;newname='POS_GSM_tclip'

  endif

;;--------------------------------------------------



  copy_data,'pos_gsm_b'+model,rbspx+'_mag_gsm_'+model

                                ;model output can be choppy (some problem within t89.pro). Smooth it here
  get_data,posname,data=dd
  dt = dd.x[1] - dd.x[0]
  ;; rbsp_detrend,rbspx+'_mag_gsm_'+model,dt/8.
  ;; store_data,rbspx+'_mag_gsm_'+model,/delete
  ;; copy_data,rbspx+'_mag_gsm_'+model+'_smoothed',rbspx+'_mag_gsm_'+model

;; ;Test smoothing and compare to original
;;         rbsp_detrend,rbspx+'_mag_gsm_'+model,dt/8.
;;         tplot,[rbspx+'_mag_gsm_t89_smoothed',rbspx+'_mag_gsm_t89_smoothed_smoothed']
;;         rbsp_detrend,[rbspx+'_mag_gsm_t89_smoothed',rbspx+'_mag_gsm_t89_smoothed_smoothed'],60.*2.
  
;;         ylim,[rbspx+'_mag_gsm_t89_smoothed',rbspx+'_mag_gsm_t89_smoothed_smoothed']+'_detrend',-200,200
;;         tplot,[rbspx+'_mag_gsm_t89_smoothed',rbspx+'_mag_gsm_t89_smoothed_smoothed']+'_detrend'


                                ;Transform the GSM mag model to GSE
  cotrans,rbspx+'_mag_gsm_'+model,rbspx+'_mag_gse_'+model,/GSM2GSE

  tinterpol_mxn,rbspx+'_mag_gse_'+model,rbspx+'_mag_gsm_for_subtract',newname=rbspx+'_mag_gse_'+model
  tinterpol_mxn,rbspx+'_mag_gsm_'+model,rbspx+'_mag_gsm_for_subtract',newname=rbspx+'_mag_gsm_'+model

  rbsp_gse2mgse,rbspx+'_mag_gse_'+model,reform(wsc_GSE_tmp.y),newname=rbspx+'_mag_mgse_'+model



  ;;Create mag - model variable in MGSE and GSE
  dif_data,rbspx+'_mag_gsm_for_subtract',rbspx+'_mag_gsm_'+model,newname=rbspx+'_mag_gsm_'+model+'_dif'
  dif_data,rbspx+'_mag_mgse_for_subtract',rbspx+'_mag_mgse_'+model,newname=rbspx+'_mag_mgse_'+model+'_dif'
  dif_data,rbspx+'_mag_gse_for_subtract',rbspx+'_mag_gse_'+model,newname=rbspx+'_mag_gse_'+model+'_dif'

  options,rbspx+'_mag_gsm_for_subtract','colors',[2,4,6]
  options,rbspx+'_mag_gse_for_subtract','colors',[2,4,6]
  options,rbspx+'_mag_mgse_for_subtract','colors',[2,4,6]


  options,rbspx+'_'+'mag'+'_gsm_for_subtract','labels',['gsm x','gsm y','gsm z']
  options,rbspx+'_mag_gsm_'+model,'labels',['gsm x','gsm y','gsm z']
  options,rbspx+'_mag_gsm_'+model+'_dif','labels',['gsm x','gsm y','gsm z']

  options,rbspx+'_'+'mag'+'_mgse_for_subtract','labels',['mgse x','mgse y','mgse z']
  options,rbspx+'_mag_mgse_'+model,'labels',['mgse x','mgse y','mgse z']
  options,rbspx+'_mag_mgse_'+model+'_dif','labels',['mgse x','mgse y','mgse z']

  options,rbspx+'_'+'mag'+'_gse_for_subtract','labels',['gse x','gse y','gse z']
  options,rbspx+'_mag_gse_'+model,'labels',['gse x','gse y','gse z']
  options,rbspx+'_mag_gse_'+model+'_dif','labels',['gse x','gse y','gse z']


  ylim,rbspx+'_mag_gsm_'+model+'_dif',-100,100
  ylim,rbspx+'_'+'mag'+'_gsm_for_subtract',-3d4,3d4
  ylim,rbspx+'_mag_gsm_'+model,-3d4,3d4	

  ylim,rbspx+'_mag_mgse_'+model+'_dif',-100,100
  ylim,rbspx+'_'+'mag'+'_mgse_for_subtract',-3d4,3d4
  ylim,rbspx+'_mag_mgse_'+model,-3d4,3d4	

  ylim,rbspx+'_mag_gse_'+model+'_dif',-100,100
  ylim,rbspx+'_'+'mag'+'_gse_for_subtract',-3d4,3d4
  ylim,rbspx+'_mag_gse_'+model,-3d4,3d4	



  options,rbspx+'_mag_gsm_'+model+'_dif','ytitle','Bfield-model!C'+strupcase(model)+'!C[nT]'
  options,rbspx+'_mag_gsm_'+model,'ytitle','Model field!C'+strupcase(model)+'!C[nT]'

  options,rbspx+'_mag_gse_'+model+'_dif','ytitle','Bfield-model!C'+strupcase(model)+'!C[nT]'
  options,rbspx+'_mag_gse_'+model,'ytitle','Model field!C'+strupcase(model)+'!C[nT]'

  options,rbspx+'_mag_mgse_'+model+'_dif','ytitle','Bfield-model!C'+strupcase(model)+'!C[nT]'
  options,rbspx+'_mag_mgse_'+model,'ytitle','Model field!C'+strupcase(model)+'!C[nT]'




;;AUTO PARAMETER DETERMINATION FROM ACTUAL DATA

  if model ne 't89' then begin

;; --------------
;; WIND
;; --------------


                                ;you may have to set the default download directory manually
                                ;here are some examples:
                                ;setenv,'ROOT_DATA_DIR=~/data' ;good for single user unix/linux system
                                ;setenv,'ROOT_DATA_DIR=C:/Documents and Settings/YOURUSERNAME/My Documents' ;example  if you don't want to use the default windows location (C:/data/ or E:/data/)
     
     if model eq 't01' then timespan,x2[0],(x2[1] - x2[0]),/seconds


     kyoto_load_dst
     tdegap,'kyoto_dst',/overwrite     
     tdeflag,'kyoto_dst','linear',/overwrite



                                ;load wind data
     wi_mfi_load,tplotnames=tn
     wi_3dp_load,tplotnames=tn2
     
     if (tn[0] ne '') and (tn2[0] ne '') then begin


        tdegap,'wi_h0_mfi_B3GSE',/overwrite
        tdeflag,'wi_h0_mfi_B3GSE','linear',/overwrite
        tdegap,'wi_3dp_k0_ion_density',/overwrite
        tdeflag,'wi_3dp_k0_ion_density','linear',/overwrite
        tdegap,'wi_3dp_k0_ion_vel',/overwrite
        tdeflag,'wi_3dp_k0_ion_vel','linear',/overwrite

        cotrans,'wi_h0_mfi_B3GSE','wi_b3gsm',/GSE2GSM

        get_data,'wi_b3gsm',data=goo
        ;;only the By and Bz IMF components used
        store_data,'wi_imf',data={x:goo.x,y:[[goo.y[*,0]],[goo.y[*,1]],[goo.y[*,2]]]}

        get_tsy_params,'kyoto_dst','wi_imf','wi_3dp_k0_ion_density','wi_3dp_k0_ion_vel',strupcase(model)
        
        
                                ;Call the model with the Wind parameters
        if model eq 'igrf' then call_procedure,'igrf',posname,parmod=model+'_par',period=0.5 $
        else call_procedure,'t'+model,posname,parmod=model+'_par',period=0.5


        if model eq 't01' then begin
           time_clip,'pos_gsm_bt01',x[0],x[1],/replace
           timespan,x[0],(x[1] - x[0]),/seconds
        endif


        copy_data,'pos_gsm_b'+model,rbspx+'_mag_gsm_'+model+'_wind'
        
        
                                ;Interpolate the model to the number of data points of actual data
        tinterpol_mxn,rbspx+'_mag_gsm_'+model+'_wind',$
                      rbspx+'_mag_mgse',$
                      newname=rbspx+'_mag_gsm_'+model+'_wind'



        dif_data,rbspx+'_mag_gsm',$
                 rbspx+'_mag_gsm_'+model+'_wind',$
                 newname=rbspx + '_mag_gsm_' + model + '_wind_dif'

                                ;Transform the GSE model to MGSE
        cotrans,rbspx+'_mag_gsm_'+model+'_wind',rbspx+'_mag_gse_'+model+'_wind',/GSM2GSE


        dif_data,rbspx+'_mag_gse_for_subtract',$
                 rbspx+'_mag_gse_'+model+'_wind',$
                 newname=rbspx + '_mag_gse_' + model + '_wind_dif'



                                ;Create and plot MGSE mag
        rbsp_gse2mgse,rbspx+'_mag_gse_'+model+'_wind',wsc_GSE_tmp.y,newname=rbspx+'_mag_mgse_'+model+'_wind'

        dif_data,rbspx+'_mag_mgse_for_subtract',$
                 rbspx+'_mag_mgse_'+model+'_wind',$
                 newname=rbspx + '_mag_mgse_' + model + '_wind_dif'



     endif else print,'==> NO WIND DATA AVAILABLE'


;-----------------------------------
;ACE (only available from 2011 on)
;-----------------------------------

     if model eq 't01' then timespan,x2[0],(x2[1] - x2[0]),/seconds
     
     ace_mfi_load,tplotnames=tn
     ace_swe_load,tplotnames=tn2
     
     
     if (tn[0] ne '') and (tn2[0] ne '') then begin
        
        tdegap,'ace_k0_mfi_BGSEc',/overwrite
        tdeflag,'ace_k0_mfi_BGSEc','linear',/overwrite
        tdegap,'ace_k0_swe_Np',/overwrite
        tdeflag,'ace_k0_swe_Np','linear',/overwrite
        tdegap,'ace_k0_swe_Vp',/overwrite
        tdeflag,'ace_k0_swe_Vp','linear',/overwrite

                                ;load_ace_mag loads data in gse coords
        cotrans,'ace_k0_mfi_BGSEc','ace_mag_Bgsm',/GSE2GSM
        get_data,'ace_mag_Bgsm',data=goo

        ;;only the By and Bz IMF components used
        store_data,'ace_imf',data={x:goo.x,y:[[goo.y[*,0]],[goo.y[*,1]],[goo.y[*,2]]]}
        get_tsy_params,'kyoto_dst','ace_imf','ace_k0_swe_Np','ace_k0_swe_Vp',strupcase(model),/speed
        
        if model eq 'igrf' then call_procedure,'igrf',posname,parmod=model+'_par',period=0.5 $
        else call_procedure,'t'+model,posname,parmod=model+'_par',period=0.5

        if model eq 't01' then begin
           time_clip,'pos_gsm_bt01',x[0],x[1],/replace
           timespan,x[0],(x[1] - x[0]),/seconds
        endif



        copy_data,'pos_gsm_b'+model,rbspx+'_mag_gsm_'+model+'_ace'

        
                                ;Interpolate the model to the number of data points of actual data
        tinterpol_mxn,rbspx+'_mag_gsm_'+model+'_ace',$
                      rbspx+'_mag_mgse',$
                      newname=rbspx+'_mag_gsm_'+model+'_ace'



                                ;Create and plot GSM mag
        dif_data,rbspx+'_mag_gsm',$
                 rbspx+'_mag_gsm_'+model+'_ace',$
                 newname=rbspx + '_mag_gsm_' + model + '_ace_dif'



                                ;Transform the GSE model to MGSE
        
        cotrans,rbspx+'_mag_gsm_'+model+'_ace',rbspx+'_mag_gse_'+model+'_ace',/GSM2GSE



                                ;Create and plot GSE mag

        dif_data,rbspx+'_mag_gse_for_subtract',$
                 rbspx+'_mag_gse_'+model+'_ace',$
                 newname=rbspx + '_mag_gse_' + model + '_ace_dif'




                                ;Create and plot MGSE mag
        rbsp_gse2mgse,rbspx+'_mag_gse_'+model+'_ace',wsc_GSE_tmp.y,newname=rbspx+'_mag_mgse_'+model+'_ace'

        dif_data,rbspx+'_mag_mgse_for_subtract',$
                 rbspx+'_mag_mgse_'+model+'_ace',$
                 newname=rbspx + '_mag_mgse_' + model + '_ace_dif'



     endif else print,'==> NO ACE DATA AVAILABLE'


;---------
;OMNI 
;---------

                                ;omni data example
                                ;NOTE: you may want to degap and deflag the data(using tdegap and tdeflag)
                                ;to remove gaps and flags in the tsyganemo parameter data, especially
                                ;if you find that there are large gaps in the result  
    
     if model eq 't01' then timespan,x2[0],(x2[1] - x2[0]),/seconds
     

     omni_hro_load,tplotnames=tn

     if tn[0] ne '' then begin
        
        tdegap,'OMNI_HRO_1min_BY_GSM',/overwrite
        tdeflag,'OMNI_HRO_1min_BY_GSM','linear',/overwrite
        tdegap,'OMNI_HRO_1min_BZ_GSM',/overwrite
        tdeflag,'OMNI_HRO_1min_BZ_GSM','linear',/overwrite
        tdegap,'OMNI_HRO_1min_proton_density',/overwrite
        tdeflag,'OMNI_HRO_1min_proton_density','linear',/overwrite
        tdegap,'OMNI_HRO_1min_flow_speed',/overwrite
        tdeflag,'OMNI_HRO_1min_flow_speed','linear',/overwrite
       
        store_data,'omni_imf',data=['OMNI_HRO_1min_BY_GSM','OMNI_HRO_1min_BZ_GSM']

        get_tsy_params,'kyoto_dst','omni_imf','OMNI_HRO_1min_proton_density','OMNI_HRO_1min_flow_speed',strupcase(model),/speed,/imf_yz

        
        if model eq 'igrf' then call_procedure,'igrf',posname,parmod=model+'_par',period=0.5 $
        else call_procedure,'t'+model,posname,parmod=model+'_par',period=0.5


        if model eq 't01' then begin
           time_clip,'pos_gsm_bt01',x[0],x[1],/replace
           timespan,x[0],(x[1] - x[0]),/seconds
        endif

        copy_data,'pos_gsm_b'+model,rbspx+'_mag_gsm_'+model+'_omni'

        
                                ;Interpolate the model to the number of data points of actual data
        tinterpol_mxn,rbspx+'_mag_gsm_'+model+'_omni',$
                      rbspx+'_mag_mgse',$
                      newname=rbspx+'_mag_gsm_'+model+'_omni'



                                ;Create and plot GSM mag

        dif_data,rbspx+'_mag_gsm',$
                 rbspx+'_mag_gsm_'+model+'_omni',$
                 newname=rbspx + '_mag_gsm_' + model + '_omni_dif'



;		;Transform the GSE model to MGSE
        
        cotrans,rbspx+'_mag_gsm_'+model+'_omni',rbspx+'_mag_gse_'+model+'_omni',/GSM2GSE



                                ;Create and plot GSE mag

        dif_data,rbspx+'_mag_gse_for_subtract',$
                 rbspx+'_mag_gse_'+model+'_omni',$
                 newname=rbspx + '_mag_gse_' + model + '_omni_dif'



                                ;Create and plot MGSE mag

        rbsp_gse2mgse,rbspx+'_mag_gse_'+model+'_omni',wsc_GSE_tmp.y,newname=rbspx+'_mag_mgse_'+model+'_omni'

        dif_data,rbspx+'_mag_mgse_for_subtract',$
                 rbspx+'_mag_mgse_'+model+'_omni',$
                 newname=rbspx + '_mag_mgse_' + model + '_omni_dif'


     endif else print,'==> NO OMNI DATA'

  endif


                                ;dipole tilt example
                                ;add one degree to dipole tilt
                                ;Can also add time varying tilts, or replace the default dipole tilt with a user defined value
;	tt96, 'th'+probe+'_state_pos',pdyn=2.0D,dsti=-30.0D,yimf=0.0D,zimf=-5.0D,get_tilt='tilt_vals',add_tilt=1
;	tplot, ['th'+probe+'_state_pos_bt96', 'th'+probe+'_fgs_gsm','tilt_vals']



;Remove, rename stuff...
  
  if ~keyword_set(nodelete) then begin
     store_data,['*OMNI_HRO*'],/delete
     store_data,['*omni_imf*'],/delete
     store_data,['*ace_k0*','ace_mag_Bgsm'],/delete
     store_data,['*wi_3dp*','*wi_h0*','wi_b3gsm'],/delete
     store_data,['*kyoto_dst*'],/delete
     store_data,['t96_par','par_out'],/delete
  endif  

  options,rbspx + '_mag_mgse_' + model+'_wind','ytitle','Model field!C'+strupcase(model)+'!Cwith Wind input!C[nT]'
  options,rbspx + '_mag_mgse_' + model+'_ace','ytitle','Model field!C'+strupcase(model)+'!Cwith ACE input!C[nT]'
  options,rbspx + '_mag_mgse_' + model+'_omni','ytitle','Model field!C'+strupcase(model)+'!Cwith OMNI input!C[nT]'

  options,rbspx + '_mag_mgse_' + model+'_wind_dif','ytitle','Bfield-model!C'+strupcase(model)+'!Cwith Wind input!C[nT]'
  options,rbspx + '_mag_mgse_' + model+'_ace_dif','ytitle','Bfield-model!C'+strupcase(model)+'!Cwith ACE input!C[nT]'
  options,rbspx + '_mag_mgse_' + model+'_omni_dif','ytitle','Bfield-model!C'+strupcase(model)+'!Cwith OMNI input!C[nT]'

  
  options,rbspx + '_mag_mgse_' + model,'ysubtitle',''
  options,rbspx + '_mag_mgse_' + model+'_wind','ysubtitle',''
  options,rbspx + '_mag_mgse_' + model+'_ace','ysubtitle',''
  options,rbspx + '_mag_mgse_' + model+'_omni','ysubtitle',''
  
  options,rbspx + '_mag_mgse_' + model + '_dif','ysubtitle',''
  options,rbspx + '_mag_mgse_' + model+'_wind_dif','ysubtitle',''
  options,rbspx + '_mag_mgse_' + model+'_ace_dif','ysubtitle',''
  options,rbspx + '_mag_mgse_' + model+'_omni_dif','ysubtitle',''
  
  


                                ;change name from T89 to IGRF if appropriate. 
                                ;Since the IGRF model is called with the T89 routine and a keyword it was easier to change
                                ;IGRF -> T89 to get the code to work. Here I change it back. 
  if model eq 'igrf' then begin
     copy_data,rbspx+'_mag_bt89_original',rbspx+'_mag_bigrf_original'
     store_data,[rbspx+'_mag_bt89_original'],/delete	
  endif
  





;;--------------------------------------------------
;Plot various quantities
;;--------------------------------------------------


  if ~keyword_set(noplot) then begin

     ylim,[rbspx+'_mag_mgse_for_subtract',$
           rbspx+'_mag_mgse_'+model+'_dif',$
           rbspx+'_mag_mgse_'+model+'_wind_dif',$
           rbspx+'_mag_mgse_'+model+'_ace_dif',$
           rbspx+'_mag_mgse_'+model+'_omni_dif',$
           rbspx+'_mag_mgse_'+model,$
           rbspx+'_mag_mgse_'+model+'_wind',$
           rbspx+'_mag_mgse_'+model+'_ace',$
           rbspx+'_mag_mgse_'+model+'_omni'],-2d4,2d4	



     tplot_options,'title','RBSP-'+strupcase(probe)+' Mag model comparison'
     tplot,[rbspx+'_mag_mgse_for_subtract',$
            rbspx+'_mag_mgse_'+model,$
            rbspx+'_mag_mgse_'+model+'_dif']

     tplot_options,'title','RBSP-'+strupcase(probe)+' Mag model comparison!Cusing Wind input'
     tplot,[rbspx+'_mag_mgse_for_subtract',$
            rbspx+'_mag_mgse_'+model+'_wind',$
            rbspx+'_mag_mgse_'+model+'_wind_dif']


     tplot_options,'title','RBSP-'+strupcase(probe)+' Mag model comparison!Cusing ACE input'
     tplot,[rbspx+'_mag_mgse_for_subtract',$
            rbspx+'_mag_mgse_'+model+'_ace',$
            rbspx+'_mag_mgse_'+model+'_ace_dif']

     tplot_options,'title','RBSP-'+strupcase(probe)+' Mag model comparison!Cusing OMNI input'
     tplot,[rbspx+'_mag_mgse_for_subtract',$
            rbspx+'_mag_mgse_'+model+'_omni',$
            rbspx+'_mag_mgse_'+model+'_omni_dif']





;Plot with zoomed in yscale
     ylim,[rbspx+'_mag_mgse_for_subtract',$
           rbspx+'_mag_mgse_'+model+'_dif',$
           rbspx+'_mag_mgse_'+model+'_wind_dif',$
           rbspx+'_mag_mgse_'+model+'_ace_dif',$
           rbspx+'_mag_mgse_'+model+'_omni_dif',$
           rbspx+'_mag_mgse_'+model,$
           rbspx+'_mag_mgse_'+model+'_wind',$
           rbspx+'_mag_mgse_'+model+'_ace',$
           rbspx+'_mag_mgse_'+model+'_omni'],-200,200	


     tplot_options,'title','RBSP-'+strupcase(probe)+' Mag model comparison'
     tplot,[rbspx+'_mag_mgse_for_subtract',$
            rbspx+'_mag_mgse_'+model,$
            rbspx+'_mag_mgse_'+model+'_dif']

     tplot_options,'title','RBSP-'+strupcase(probe)+' Mag model comparison!Cusing Wind input'
     tplot,[rbspx+'_mag_mgse_for_subtract',$
            rbspx+'_mag_mgse_'+model+'_wind',$
            rbspx+'_mag_mgse_'+model+'_wind_dif']


     tplot_options,'title','RBSP-'+strupcase(probe)+' Mag model comparison!Cusing ACE input'
     tplot,[rbspx+'_mag_mgse_for_subtract',$
            rbspx+'_mag_mgse_'+model+'_ace',$
            rbspx+'_mag_mgse_'+model+'_ace_dif']

     tplot_options,'title','RBSP-'+strupcase(probe)+' Mag model comparison!Cusing OMNI input'
     tplot,[rbspx+'_mag_mgse_for_subtract',$
            rbspx+'_mag_mgse_'+model+'_omni',$
            rbspx+'_mag_mgse_'+model+'_omni_dif']





;compare the four models

     ylim,[rbspx+'_mag_mgse_'+model+'_dif',$
           rbspx+'_mag_mgse_'+model+'_wind_dif',$
           rbspx+'_mag_mgse_'+model+'_ace_dif',$
           rbspx+'_mag_mgse_'+model+'_omni_dif'],-100,100


     tplot_options,'Comparison of four models'
     tplot,[rbspx+'_mag_gsm_'+model+'_dif',$
            rbspx+'_mag_gsm_'+model+'_wind_dif',$
            rbspx+'_mag_gsm_'+model+'_ace_dif',$
            rbspx+'_mag_gsm_'+model+'_omni_dif']


     tplot_options,'Comparison of four models'
     tplot,[rbspx+'_mag_gse_'+model+'_dif',$
            rbspx+'_mag_gse_'+model+'_wind_dif',$
            rbspx+'_mag_gse_'+model+'_ace_dif',$
            rbspx+'_mag_gse_'+model+'_omni_dif']


     tplot_options,'Comparison of four models'
     tplot,[rbspx+'_mag_mgse_'+model+'_dif',$
            rbspx+'_mag_mgse_'+model+'_wind_dif',$
            rbspx+'_mag_mgse_'+model+'_ace_dif',$
            rbspx+'_mag_mgse_'+model+'_omni_dif']
     
  endif	


  if model eq 't01' then begin
     tn = tnames()
     for i=0,n_elements(tn)-1 do time_clip,tn[i],x[0],x[1],/replace
  endif

end	


