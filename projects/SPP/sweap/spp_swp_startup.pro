
pro spp_swp_startup, spanai   = spanai,$
                     spanae   = spanae,$
                     spanb    = spanb,$
                     swem = swem, $
                     save = save, $
                     rt_flag= rt_Flag, $
                     clear = clear,  $
                     itf = itf, $
                     rm133 = rm133, $
                     rm320 = rm320, $
                     optional = optional

  ;
  ;if rt_flag eq !null then rt_flag = 1
  if save eq !null then save = 1
  
;  if rt_flag eq !null then rt_flag = ~save

  printdat,rt_flag,save


  ;;--------------------------------------------
  ;; Check keywords
  if ~keyword_set(spanai) and $
     ~keyword_set(spanae) and $
     ~keyword_set(spanb)  and $
     ~keyword_set(optional) then begin
     spanai = 1
     spanae = 1
     spanb  = 1
  endif
 

  ;;--------------------------------------------
  ;; Compile necessary programs
  ;resolve_routine, 'spp_swp_functions'
  ;resolve_routine, 'spp_swp_ptp_pkt_handler'


  ;;############################################
  ;; SETUP SWEM APIDs
  ;;############################################
  
  ttags = 'SEQN'
    
  spp_apid_data,'340'x,routine='spp_generic_decom',tname='spp_swem_hkp_',   tfields=ttags,save=save,rt_tags=ttags,rt_flag=rt_flag
  spp_apid_data,'341'x,routine='spp_generic_decom',tname='spp_swem_hkp_crit_',   tfields=ttags,save=save,rt_tags=ttags,rt_flag=rt_flag
  spp_apid_data,'343'x,routine='spp_generic_decom',tname='spp_swem_hkp_analog_',   tfields=ttags,save=save,rt_tags=ttags,rt_flag=rt_flag
  spp_apid_data,'344'x,routine='spp_generic_decom',tname='spp_swem_events_',   tfields=ttags,save=save,rt_tags=ttags,rt_flag=rt_flag
  spp_apid_data,'346'x,routine='spp_swp_swem_timing_decom',tname='spp_swem_timing_',   tfields='*',save=save,rt_tags='*',rt_flag=rt_flag

  spp_apid_data,'347'x,routine='spp_swp_swem_unwrapper',tname='spp_swp_347_',   tfields='*',save=save,rt_tags='*',rt_flag=rt_flag
  spp_apid_data,'34e'x,routine='spp_swp_swem_unwrapper',tname='spp_swp_34E_',   tfields='*',save=save,rt_tags='*',rt_flag=rt_flag
  spp_apid_data,'34f'x,routine='spp_swp_swem_unwrapper',tname='spp_swp_34F_',   tfields='*',save=save,rt_tags='*',rt_flag=rt_flag


  ;;############################################
  ;; SETUP SPC APIDs
  ;;############################################

  SPC = 1
  IF SPC THEN  BEGIN
    spp_apid_data,'352'x,routine='spp_swp_spc_decom',    tname='spp_spc_352_',tfields='*',rt_tags='*',save=save,rt_flag=rt_flag
    spp_apid_data,'353'x,routine='spp_swp_spc_decom',    tname='spp_spc_353_',tfields='*',rt_tags='*',save=save,rt_flag=rt_flag
    spp_apid_data,'35E'x,routine='spp_swp_spc_decom',    tname='spp_spc_35E_',tfields='*',rt_tags='*',save=save,rt_flag=rt_flag
    spp_apid_data,'35F'x,routine='spp_swp_spc_decom',    tname='spp_spc_hkp_',tfields='*',rt_tags='*',save=save,rt_flag=rt_flag
  endif


  ;;############################################
  ;; SETUP SPAN-Ai APID
  ;;############################################
  if keyword_set(spanai) then begin

     ;;------------------------------------------------------------------------------------------------------------
     ;; Housekeeping - Rates - Events - Manipulator - Memory Dump
     ;;------------------------------------------------------------------------------------------------------------
     

     if 1 then begin
        spp_apid_data,'3b8'x,routine='spp_generic_decom',                tname='spp_spani_mem_dump_',tfields='*',rt_tags='*',save=save,rt_flag=rt_flag
        spp_apid_data,'3b9'x,routine='spp_swp_spani_event_decom',        tname='spp_spani_events_',  tfields='*',rt_tags='*',save=save,rt_flag=rt_flag
        spp_apid_data,'3ba'x,routine='spp_swp_spani_tof_decom',          tname='spp_spani_tof_',     tfields='*',rt_tags='*',save=save,rt_flag=rt_flag
        spp_apid_data,'3bb'x,routine='spp_swp_spani_rates_decom',        tname='spp_spani_rates_',   tfields='*',rt_tags='*',save=save,rt_flag=rt_flag
        spp_apid_data,'3be'x,name='spi_hkp',routine='spp_swp_spani_slow_hkp_9ex_decom', tname='spp_spani_hkp_',     tfields='*',rt_tags='*',save=save,rt_flag=rt_flag
        spp_apid_data,'3bf'x,routine='spp_swp_spani_fast_hkp_decom',     tname='spp_spani_fhkp_',    tfields='*',rt_tags='*',save=save,rt_flag=rt_flag
     endif



     ;#############################
     ;######### ARCHIVE ###########
     ;#############################

     ;;-----------------------------------------------------------------------------------------------------------------------------------------
     ;; SPAN-Ai Full Sweep Products
     ;;-----------------------------------------------------------------------------------------------------------------------------------------
     decom_routine_i = 'spp_swp_spani_product_decom2'
     ;decom_routine_i = 'spp_swp_spani_product_decom'
     ttags = '*SPEC* *CNTS* *DATASIZE'

     spp_apid_data,'380'x,routine=decom_routine_i,tname='spp_spani_ar_full_p0_m0_',tfields=ttags,rt_tags=ttags,save=save,rt_flag=rt_flag
     spp_apid_data,'381'x,routine=decom_routine_i,tname='spp_spani_ar_full_p0_m1_',tfields=ttags,rt_tags=ttags,save=save,rt_flag=rt_flag
     spp_apid_data,'382'x,routine=decom_routine_i,tname='spp_spani_ar_full_p0_m2_',tfields=ttags,rt_tags=ttags,save=save,rt_flag=rt_flag
     spp_apid_data,'383'x,routine=decom_routine_i,tname='spp_spani_ar_full_p0_m3_',tfields=ttags,rt_tags=ttags,save=save,rt_flag=rt_flag
     spp_apid_data,'384'x,routine=decom_routine_i,tname='spp_spani_ar_full_p1_m0_',tfields=ttags,rt_tags=ttags,save=save,rt_flag=rt_flag
     spp_apid_data,'385'x,routine=decom_routine_i,tname='spp_spani_ar_full_p1_m1_',tfields=ttags,rt_tags=ttags,save=save,rt_flag=rt_flag
     spp_apid_data,'386'x,routine=decom_routine_i,tname='spp_spani_ar_full_p1_m2_',tfields=ttags,rt_tags=ttags,save=save,rt_flag=rt_flag
     spp_apid_data,'387'x,routine=decom_routine_i,tname='spp_spani_ar_full_p1_m3_',tfields=ttags,rt_tags=ttags,save=save,rt_flag=rt_flag
     spp_apid_data,'388'x,routine=decom_routine_i,tname='spp_spani_ar_full_p2_m0_',tfields=ttags,rt_tags=ttags,save=save,rt_flag=rt_flag
     spp_apid_data,'389'x,routine=decom_routine_i,tname='spp_spani_ar_full_p2_m1_',tfields=ttags,rt_tags=ttags,save=save,rt_flag=rt_flag
     spp_apid_data,'38a'x,routine=decom_routine_i,tname='spp_spani_ar_full_p2_m2_',tfields=ttags,rt_tags=ttags,save=save,rt_flag=rt_flag
     spp_apid_data,'38b'x,routine=decom_routine_i,tname='spp_spani_ar_full_p2_m3_',tfields=ttags,rt_tags=ttags,save=save,rt_flag=rt_flag
     
     ;;-----------------------------------------------------------------------------------------------------------------------------------------
     ;; SPAN-Ai Targeted Sweep Products
     ;;-----------------------------------------------------------------------------------------------------------------------------------------
     spp_apid_data,'38c'x,routine=decom_routine_i,tname='spp_spani_ar_targ_p0_m0_',tfields=ttags,rt_tags=ttags,save=save,rt_flag=rt_flag
     spp_apid_data,'38d'x,routine=decom_routine_i,tname='spp_spani_ar_targ_p0_m1_',tfields=ttags,rt_tags=ttags,save=save,rt_flag=rt_flag
     spp_apid_data,'38e'x,routine=decom_routine_i,tname='spp_spani_ar_targ_p0_m2_',tfields=ttags,rt_tags=ttags,save=save,rt_flag=rt_flag
     spp_apid_data,'38f'x,routine=decom_routine_i,tname='spp_spani_ar_targ_p0_m3_',tfields=ttags,rt_tags=ttags,save=save,rt_flag=rt_flag
     spp_apid_data,'390'x,routine=decom_routine_i,tname='spp_spani_ar_targ_p1_m0_',tfields=ttags,rt_tags=ttags,save=save,rt_flag=rt_flag
     spp_apid_data,'391'x,routine=decom_routine_i,tname='spp_spani_ar_targ_p1_m1_',tfields=ttags,rt_tags=ttags,save=save,rt_flag=rt_flag
     spp_apid_data,'392'x,routine=decom_routine_i,tname='spp_spani_ar_targ_p1_m2_',tfields=ttags,rt_tags=ttags,save=save,rt_flag=rt_flag
     spp_apid_data,'393'x,routine=decom_routine_i,tname='spp_spani_ar_targ_p1_m3_',tfields=ttags,rt_tags=ttags,save=save,rt_flag=rt_flag
     spp_apid_data,'394'x,routine=decom_routine_i,tname='spp_spani_ar_targ_p2_m0_',tfields=ttags,rt_tags=ttags,save=save,rt_flag=rt_flag
     spp_apid_data,'395'x,routine=decom_routine_i,tname='spp_spani_ar_targ_p2_m1_',tfields=ttags,rt_tags=ttags,save=save,rt_flag=rt_flag
     spp_apid_data,'396'x,routine=decom_routine_i,tname='spp_spani_ar_targ_p2_m2_',tfields=ttags,rt_tags=ttags,save=save,rt_flag=rt_flag
     spp_apid_data,'397'x,routine=decom_routine_i,tname='spp_spani_ar_targ_p2_m3_',tfields=ttags,rt_tags=ttags,save=save,rt_flag=rt_flag
     


     ;#############################
     ;########## SURVEY ###########
     ;#############################


     ;;-----------------------------------------------------------------------------------------------------------------------------------------
     ;; SPAN-Ai Full Sweep Products
     ;;-----------------------------------------------------------------------------------------------------------------------------------------
     spp_apid_data,'398'x,routine=decom_routine_i,tname='spp_spani_sr_full_p0_m0_',tfields=ttags,rt_tags=ttags,save=save,rt_flag=rt_flag
     spp_apid_data,'399'x,routine=decom_routine_i,tname='spp_spani_sr_full_p0_m1_',tfields=ttags,rt_tags=ttags,save=save,rt_flag=rt_flag
     spp_apid_data,'39a'x,routine=decom_routine_i,tname='spp_spani_sr_full_p0_m2_',tfields=ttags,rt_tags=ttags,save=save,rt_flag=rt_flag
     spp_apid_data,'39b'x,routine=decom_routine_i,tname='spp_spani_sr_full_p0_m3_',tfields=ttags,rt_tags=ttags,save=save,rt_flag=rt_flag
     spp_apid_data,'39c'x,routine=decom_routine_i,tname='spp_spani_sr_full_p1_m0_',tfields=ttags,rt_tags=ttags,save=save,rt_flag=rt_flag
     spp_apid_data,'39d'x,routine=decom_routine_i,tname='spp_spani_sr_full_p1_m1_',tfields=ttags,rt_tags=ttags,save=save,rt_flag=rt_flag
     spp_apid_data,'39e'x,routine=decom_routine_i,tname='spp_spani_sr_full_p1_m2_',tfields=ttags,rt_tags=ttags,save=save,rt_flag=rt_flag
     spp_apid_data,'39f'x,routine=decom_routine_i,tname='spp_spani_sr_full_p1_m3_',tfields=ttags,rt_tags=ttags,save=save,rt_flag=rt_flag
     spp_apid_data,'3a0'x,routine=decom_routine_i,tname='spp_spani_sr_full_p2_m0_',tfields=ttags,rt_tags=ttags,save=save,rt_flag=rt_flag
     spp_apid_data,'3a1'x,routine=decom_routine_i,tname='spp_spani_sr_full_p2_m1_',tfields=ttags,rt_tags=ttags,save=save,rt_flag=rt_flag
     spp_apid_data,'3a2'x,routine=decom_routine_i,tname='spp_spani_sr_full_p2_m2_',tfields=ttags,rt_tags=ttags,save=save,rt_flag=rt_flag
     spp_apid_data,'3a3'x,routine=decom_routine_i,tname='spp_spani_sr_full_p2_m3_',tfields=ttags,rt_tags=ttags,save=save,rt_flag=rt_flag
     
     ;;-----------------------------------------------------------------------------------------------------------------------------------------
     ;; SPAN-Ai Targeted Sweep Products
     ;;-----------------------------------------------------------------------------------------------------------------------------------------
     spp_apid_data,'3a4'x,routine=decom_routine_i,tname='spp_spani_sr_targ_p0_m0_',tfields=ttags,rt_tags=ttags,save=save,rt_flag=rt_flag
     spp_apid_data,'3a5'x,routine=decom_routine_i,tname='spp_spani_sr_targ_p0_m1_',tfields=ttags,rt_tags=ttags,save=save,rt_flag=rt_flag
     spp_apid_data,'3a6'x,routine=decom_routine_i,tname='spp_spani_sr_targ_p0_m2_',tfields=ttags,rt_tags=ttags,save=save,rt_flag=rt_flag
     spp_apid_data,'3a7'x,routine=decom_routine_i,tname='spp_spani_sr_targ_p0_m3_',tfields=ttags,rt_tags=ttags,save=save,rt_flag=rt_flag
     spp_apid_data,'3a8'x,routine=decom_routine_i,tname='spp_spani_sr_targ_p1_m0_',tfields=ttags,rt_tags=ttags,save=save,rt_flag=rt_flag
     spp_apid_data,'3a9'x,routine=decom_routine_i,tname='spp_spani_sr_targ_p1_m1_',tfields=ttags,rt_tags=ttags,save=save,rt_flag=rt_flag
     spp_apid_data,'3aa'x,routine=decom_routine_i,tname='spp_spani_sr_targ_p1_m2_',tfields=ttags,rt_tags=ttags,save=save,rt_flag=rt_flag
     spp_apid_data,'3ab'x,routine=decom_routine_i,tname='spp_spani_sr_targ_p1_m3_',tfields=ttags,rt_tags=ttags,save=save,rt_flag=rt_flag
     spp_apid_data,'3ac'x,routine=decom_routine_i,tname='spp_spani_sr_targ_p2_m0_',tfields=ttags,rt_tags=ttags,save=save,rt_flag=rt_flag
     spp_apid_data,'3ad'x,routine=decom_routine_i,tname='spp_spani_sr_targ_p2_m1_',tfields=ttags,rt_tags=ttags,save=save,rt_flag=rt_flag
     spp_apid_data,'3ae'x,routine=decom_routine_i,tname='spp_spani_sr_targ_p2_m2_',tfields=ttags,rt_tags=ttags,save=save,rt_flag=rt_flag
     spp_apid_data,'3af'x,routine=decom_routine_i,tname='spp_spani_sr_targ_p2_m3_',tfields=ttags,rt_tags=ttags,save=save,rt_flag=rt_flag
     
  endif


  ;;############################################
  ;; SETUP SPAN-Ae APID
  ;;############################################
  if keyword_set(spanae) then begin

     decom_routine = 'spp_swp_spane_product_decom2'
     ttags = '*'

     ;;----------------------------------------------------------------------------------------------------------------------------------
     ;; Product Decommutators
     ;;----------------------------------------------------------------------------------------------------------------------------------
     spp_apid_data,'360'x ,routine=decom_routine,tname='spp_spane_a_ar_full_p0_',tfields=ttags,rt_tags=ttags, save=save,rt_flag=rt_flag
     spp_apid_data,'361'x ,routine=decom_routine,tname='spp_spane_a_ar_full_p1_',tfields=ttags,rt_tags=ttags, save=save,rt_flag=rt_flag
     spp_apid_data,'362'x ,routine=decom_routine,tname='spp_spane_a_ar_targ_p0_',tfields=ttags,rt_tags=ttags, save=save,rt_flag=rt_flag
     spp_apid_data,'363'x ,routine=decom_routine,tname='spp_spane_a_ar_targ_p1_',tfields=ttags,rt_tags=ttags, save=save,rt_flag=rt_flag

     spp_apid_data,'364'x ,routine=decom_routine,tname='spp_spane_a_sr_full_p0_',tfields=ttags,rt_tags=ttags, save=save,rt_flag=rt_flag
     spp_apid_data,'365'x ,routine=decom_routine,tname='spp_spane_a_sr_full_p1_',tfields=ttags,rt_tags=ttags, save=save,rt_flag=rt_flag
     spp_apid_data,'366'x ,routine=decom_routine,tname='spp_spane_a_sr_targ_p0_',tfields=ttags,rt_tags=ttags, save=save,rt_flag=rt_flag
     spp_apid_data,'367'x ,routine=decom_routine,tname='spp_spane_a_sr_targ_p1_',tfields=ttags,rt_tags=ttags, save=save,rt_flag=rt_flag
  
     ;;----------------------------------------------------------------------------------------------------------------------------------------
     ;; Memory Dump
     ;;----------------------------------------------------------------------------------------------------------------------------------------
     spp_apid_data,'36d'x ,routine='spp_generic_decom',tname='spp_spane_a_dump_',tfields=ttags,rt_tags=ttags, save=save,rt_flag=rt_flag
     
     ;;----------------------------------------------------------------------------------------------------------------------------------------
     ;; Slow Housekeeping
     ;;----------------------------------------------------------------------------------------------------------------------------------------
     spp_apid_data,'36e'x ,routine='spp_swp_spane_slow_hkp_v52x_decom',tname='spp_spane_a_hkp_',tfields='*',rt_tags='*', save=save,rt_flag=rt_flag
     
     ;;-----------------------------------------------------------------------------------------------------------------------------------------
     ;; Fast Housekeeping
     ;;-----------------------------------------------------------------------------------------------------------------------------------------
     spp_apid_data,'36f'x ,routine='spp_swp_spane_fast_hkp_decom',tname='spp_spane_a_fast_hkp_',tfields='*',rt_tags='*', save=save,rt_flag=rt_flag
     

  endif


  ;;############################################
  ;; SETUP SPAN-B APID
  ;;############################################
  if keyword_set(spanb) then begin
     
     ;;----------------------------------------------------------------------------------------------------------------------------------
     ;; Product Decommutators
     ;;----------------------------------------------------------------------------------------------------------------------------------
     spp_apid_data,'370'x ,routine=decom_routine,tname='spp_spane_b_ar_full_p0_',tfields=ttags,rt_tags=ttags, save=save,rt_flag=rt_flag
     spp_apid_data,'371'x ,routine=decom_routine,tname='spp_spane_b_ar_full_p1_',tfields=ttags,rt_tags=ttags, save=save,rt_flag=rt_flag
     spp_apid_data,'372'x ,routine=decom_routine,tname='spp_spane_b_ar_targ_p0_',tfields=ttags,rt_tags=ttags, save=save,rt_flag=rt_flag
     spp_apid_data,'373'x ,routine=decom_routine,tname='spp_spane_b_ar_targ_p1_',tfields=ttags,rt_tags=ttags, save=save,rt_flag=rt_flag

     spp_apid_data,'374'x ,routine=decom_routine,tname='spp_spane_b_sr_full_p0_',tfields=ttags,rt_tags=ttags, save=save,rt_flag=rt_flag
     spp_apid_data,'375'x ,routine=decom_routine,tname='spp_spane_b_sr_full_p1_',tfields=ttags,rt_tags=ttags, save=save,rt_flag=rt_flag
     spp_apid_data,'376'x ,routine=decom_routine,tname='spp_spane_b_sr_targ_p0_',tfields=ttags,rt_tags=ttags, save=save,rt_flag=rt_flag
     spp_apid_data,'377'x ,routine=decom_routine,tname='spp_spane_b_sr_targ_p1_',tfields=ttags,rt_tags=ttags, save=save,rt_flag=rt_flag

     ;;----------------------------------------------------------------------------------------------------------------------------------------
     ;; Memory Dump
     ;;----------------------------------------------------------------------------------------------------------------------------------------
     spp_apid_data,'37d'x ,routine='spp_generic_decom',tname='spp_spane_b_dump_',tfields='*',rt_tags='*', save=save,rt_flag=rt_flag
     
     ;;----------------------------------------------------------------------------------------------------------------------------------------
     ;; Slow Housekeeping
     ;;----------------------------------------------------------------------------------------------------------------------------------------
     spp_apid_data,'37e'x ,routine='spp_swp_spane_slow_hkp_v52x_decom',tname='spp_spane_b_hkp_',tfields='*',rt_tags='*', save=save,rt_flag=rt_flag
     
     ;;-----------------------------------------------------------------------------------------------------------------------------------------
     ;; Fast Housekeeping
     ;;-----------------------------------------------------------------------------------------------------------------------------------------
     spp_apid_data,'37f'x ,routine='spp_swp_spane_fast_hkp_decom',tname='spp_spane_b_fast_hkp_',tfields='*',rt_tags='*', save=save,rt_flag=rt_flag
     
  endif


  ;;############################################
  ;; SETUP GSE APID
  ;;############################################
  spp_apid_data,'751'x,routine='spp_power_supply_decom',tname='APS1_',       tfields='*P25?',     save=save,rt_tags='*P25?',   rt_flag=rt_flag
  spp_apid_data,'752'x,routine='spp_power_supply_decom',tname='APS2_',       tfields='*P25?',     save=save,rt_tags='*P25?',   rt_flag=rt_flag
  spp_apid_data,'753'x,routine='spp_power_supply_decom',tname='APS3_',       tfields='*P6? *N25V',     save=save,rt_tags='*P6? *N25V',   rt_flag=rt_flag
  spp_apid_data,'761'x,routine='spp_power_supply_decom',tname='Igun_',       tfields='*VOLTS *CURRENT',     save=save,rt_tags='*VOLTS *CURRENT',   rt_flag=rt_flag
  spp_apid_data,'762'x,routine='spp_power_supply_decom',tname='Egun_',       tfields='*VOLTS *CURRENT',     save=save,rt_tags='*VOLTS *CURRENT',   rt_flag=rt_flag
  spp_apid_data,'7c0'x,routine='spp_log_msg_decom',     tname='log_',      tfields='MSG',   save=save,rt_tags='MSG',   rt_flag=rt_flag
  spp_apid_data,'7c3'x,routine='spp_swp_manip_decom',tname='spp_manip_',tfields='*',name='manip',rt_tags='M???POS',save=save,rt_flag=rt_flag


  ;;############################################
  ;; OPTIONAL
  ;;############################################
  if keyword_set(optional) then begin
     spp_apid_data,'3bb'x,routine='spp_swp_spani_rates_64x_decom',    tname='spp_spanai_rates_',   tfields='*',rt_tags='*',save=save,rt_flag=rt_flag
     spp_apid_data,'3be'x,routine='spp_swp_spani_slow_hkp_97x_decom', tname='spp_spanai_hkp_',     tfields='*',rt_tags='*',save=save,rt_flag=rt_flag
     ;spp_apid_data,'3b9'x,routine='spp_swp_spani_event_decom',        tname='spp_spanai_events_',  tfields='*',rt_tags='*',save=save,rt_flag=rt_flag
     ;print, 'Check'
  endif

  if keyword_set(clear) then spp_apid_data,/clear
  
  if 1 then begin
    spp_apid_data,apdata=ap
    print_struct,ap
  endif

  ;;------------------------------
  ;; Connect to GSEOS
  ;if keyword_set(rt_flag) then spp_init_realtime,swem=swem,itf=itf,rm133=rm133,rm320=rm320
  
  store_data,'APID',data='APIDS_*'
  ylim,'APID',820,960
  tplot_options,'wshow',0
  

end
