;+
; $LastChangedBy: davin-mac $
; $LastChangedDate: 2023-12-05 10:42:55 -0800 (Tue, 05 Dec 2023) $
; $LastChangedRevision: 32270 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu:36867/repos/spdsoft/trunk/projects/swx/swx_stis_apdat_init.pro $
;-

pro swx_sst_apdat_init,reset=reset, save_flag = save_flag, swem=swem, spane=spane, $
  rt_flag= rt_Flag, $
  clear = clear, no_products =no_products

  spane=1
  swem = 1

  common swx_stis_apdat_init, initialized
  if keyword_set(reset) then initialized = 0
  if keyword_set(initialized) then return
  initialized =1
  ;   dprint,dlevel=3,/phelp ,rt_flag,save_flag

  ;; special case to accumulate statistics
  swx_apdat_info, 0 ,name='Stats',apid_obj='swx_gen_apdat_stats',tname='APIDS', ttags=ttags,save_flag=save_flag,rt_flag=rt_flag

  ;;#################
  ;; SETUP SWEM APIDs
  ;;#################

  ; These APIDs are used by the SWEM
  if keyword_set(swem) then begin
    swx_apdat_info,'340'x,name='swem_crit_hkp',                                      tname='swx_swem_crit_hkp', save_flag=save_flag,ttags='*',rt_flag=rt_flag
    swx_apdat_info,'341'x,name='swem_dig_hkp',  apid_obj='swx_swem_dhkp_apdat',  tname='swx_swem_dig_hkp',  save_flag=save_flag,ttags='*',rt_flag=rt_flag
    swx_apdat_info,'342'x,name='swem_memdump',  apid_obj='swx_swem_memdump_apdat',    tname='swx_swem_memdump',  save_flag=save_flag,ttags='*',rt_flag=rt_flag
    swx_apdat_info,'343'x,name='swem_ana_hkp',  apid_obj='swx_swem_hkp_apdat',   tname='swx_swem_ana_hkp',  save_flag=save_flag,ttags='*',rt_flag=rt_flag
    swx_apdat_info,'344'x,name='swem_event_log',apid_obj='swx_swem_events_apdat',tname='swx_swem_event_log',save_flag=save_flag,ttags='*',rt_flag=rt_flag
    swx_apdat_info,'345'x,name='swem_cmd_echo',                                      tname='swx_swem_cmd_echo', save_flag=save_flag,ttags='*',rt_flag=rt_flag
    swx_apdat_info,'346'x,name='swem_timing',   apid_obj='swx_swem_timing_apdat',tname='swx_swem_timing',   save_flag=save_flag,ttags='*',rt_flag=rt_flag
    swx_apdat_info,'347'x,name='swem_memdwell',                                      tname='swx_swem_memdwell', save_flag=save_flag,ttags='*',rt_flag=rt_flag

    swx_apdat_info,'348'x,name='wrp_P2rt',apid_obj='swx_swem_wrapper_apdat',tname='swx_wrp_348_P2rt',ttags='*',save_flag=save_flag,rt_flag=rt_flag
    swx_apdat_info,'349'x,name='wrp_P2',  apid_obj='swx_swem_wrapper_apdat',tname='swx_wrp_349_P2',  ttags='*',save_flag=save_flag,rt_flag=rt_flag
    swx_apdat_info,'34A'x,name='wrp_P3rt',apid_obj='swx_swem_wrapper_apdat',tname='swx_wrp_34A_P3rt',ttags='*',save_flag=save_flag,rt_flag=rt_flag
    swx_apdat_info,'34b'x,name='wrp_P3',  apid_obj='swx_swem_wrapper_apdat',tname='swx_wrp_34B_P3',  ttags='*',save_flag=save_flag,rt_flag=rt_flag
    swx_apdat_info,'34c'x,name='wrp_P4rt',apid_obj='swx_swem_wrapper_apdat',tname='swx_wrp_34C_P4rt',ttags='*',save_flag=save_flag,rt_flag=rt_flag
    swx_apdat_info,'34d'x,name='wrp_P4',  apid_obj='swx_swem_wrapper_apdat',tname='swx_wrp_34D_P4',  ttags='*',save_flag=save_flag,rt_flag=rt_flag
    swx_apdat_info,'34e'x,name='wrp_P5P7',apid_obj='swx_swem_wrapper_apdat',tname='swx_wrp_34E_P5P7',ttags='*',save_flag=save_flag,rt_flag=rt_flag
    swx_apdat_info,'34f'x,name='wrp_P8',  apid_obj='swx_swem_wrapper_apdat',tname='swx_wrp_34F_P8',  ttags='*',save_flag=save_flag,rt_flag=rt_flag

  endif
  

  
  


  ;;################
  ;;#   STIS APIDs  #
  ;;################
  swx_apdat_info,'350'x,name='stis_sci', apid_obj='swfo_stis_sci_apdat',         tname='swx_stis_sci',ttags='*',save_flag=save_flag,rt_flag=rt_flag
  swx_apdat_info,'351'x,name='stis_nse', apid_obj='swfo_stis_nse_apdat',    tname='swx_stis_nse',ttags='*',save_flag=save_flag,rt_flag=rt_flag
  swx_apdat_info,'35d'x,name='stis_mem', apid_obj='swfo_stis_memdump_apdat', tname='swx_stis_memdump',ttags='*',save_flag=save_flag,rt_flag=rt_flag
  swx_apdat_info,'35E'x,name='stis_hkp1', apid_obj='swfo_stis_hkp_apdat', tname='swx_stis_hkp1',ttags='*',save_flag=save_flag,rt_flag=rt_flag
  swx_apdat_info,'35F'x,name='stis_hkp2', apid_obj='swfo_stis_hkp_apdat', tname='swx_stis_hkp2',ttags='*',    save_flag=save_flag,rt_flag=rt_flag


  if keyword_set(spane) then begin

    ;;##################
    ;;#  SPAN-Ae & SPAN-B APID  #
    ;;##################
    spe_hkp_tags = 'RIO_???* ADC_*_* *_FLAG MRAM* CLKS_PER_NYS ALL_ADC EASIC_DAC *CMD_* PEAK*'
    spe_hkp_tags = '*'
    ;decom_routine = 'spp_swp_spane_product_decom2' ;; DEPRECATED ;;
    decom_routine_obj = 'spp_swp_spe_prod_apdat'
    ;ttags = '*'

    ;;----------------------------------------------------------------------------------------------------------------------------------
    ;; Product Decommutators
    ;;----------------------------------------------------------------------------------------------------------------------------------
    spp_apdat_info,'360'x,name='spa_af0' ,apid_obj=decom_routine_obj,tname='spp_spa_AF0', ttags=ttags, save_flag=save_flag,rt_flag=rt_flag
    spp_apdat_info,'370'x,name='spb_af0' ,apid_obj=decom_routine_obj,tname='spp_spb_AF0', ttags=ttags, save_flag=save_flag,rt_flag=rt_flag
    spp_apdat_info,'361'x,name='spa_af1' ,apid_obj=decom_routine_obj,tname='spp_spa_AF1', ttags=ttags, save_flag=save_flag,rt_flag=rt_flag
    spp_apdat_info,'371'x,name='spb_af1' ,apid_obj=decom_routine_obj,tname='spp_spb_AF1', ttags=ttags, save_flag=save_flag,rt_flag=rt_flag
    spp_apdat_info,'362'x,name='spa_at0' ,apid_obj=decom_routine_obj,tname='spp_spa_AT0', ttags=ttags, save_flag=save_flag,rt_flag=rt_flag
    spp_apdat_info,'372'x,name='spb_at0' ,apid_obj=decom_routine_obj,tname='spp_spb_AT0', ttags=ttags, save_flag=save_flag,rt_flag=rt_flag
    spp_apdat_info,'363'x,name='spa_at1' ,apid_obj=decom_routine_obj,tname='spp_spa_AT1', ttags=ttags, save_flag=save_flag,rt_flag=rt_flag
    spp_apdat_info,'373'x,name='spb_at1' ,apid_obj=decom_routine_obj,tname='spp_spb_AT1', ttags=ttags, save_flag=save_flag,rt_flag=rt_flag

    spp_apdat_info,'364'x,name='spa_sf0' ,apid_obj=decom_routine_obj,tname='spp_spa_SF0', ttags=ttags, save_flag=save_flag,rt_flag=rt_flag
    spp_apdat_info,'374'x,name='spb_sf0' ,apid_obj=decom_routine_obj,tname='spp_spb_SF0', ttags=ttags, save_flag=save_flag,rt_flag=rt_flag
    spp_apdat_info,'365'x,name='spa_sf1' ,apid_obj=decom_routine_obj,tname='spp_spa_SF1', ttags=ttags, save_flag=save_flag,rt_flag=rt_flag
    spp_apdat_info,'375'x,name='spb_sf1' ,apid_obj=decom_routine_obj,tname='spp_spb_SF1', ttags=ttags, save_flag=save_flag,rt_flag=rt_flag
    spp_apdat_info,'366'x,name='spa_st0' ,apid_obj=decom_routine_obj,tname='spp_spa_ST0', ttags=ttags, save_flag=save_flag,rt_flag=rt_flag
    spp_apdat_info,'376'x,name='spb_st0' ,apid_obj=decom_routine_obj,tname='spp_spb_ST0', ttags=ttags, save_flag=save_flag,rt_flag=rt_flag
    spp_apdat_info,'367'x,name='spa_st1' ,apid_obj=decom_routine_obj,tname='spp_spa_ST1', ttags=ttags, save_flag=save_flag,rt_flag=rt_flag
    spp_apdat_info,'377'x,name='spb_st1' ,apid_obj=decom_routine_obj,tname='spp_spb_ST1', ttags=ttags, save_flag=save_flag,rt_flag=rt_flag


    ;;----------------------------------------------------------------------------------------------------------------------------------------
    ;; Memory Dump
    ;;----------------------------------------------------------------------------------------------------------------------------------------
    spp_apdat_info,'36d'x,name='spa_memdump',apid_obj='spp_swp_memdump_apdat',tname='spp_spa_memdump',ttags='SEQN*',save_flag=save_flag,rt_flag=rt_flag
    spp_apdat_info,'37d'x,name='spb_memdump',apid_obj='spp_swp_memdump_apdat',tname='spp_spb_memdump',ttags='SEQN*',save_flag=save_flag,rt_flag=rt_flag

    ;;----------------------------------------------------------------------------------------------------------------------------------------
    ;; Slow Housekeeping
    ;;----------------------------------------------------------------------------------------------------------------------------------------
    spp_apdat_info,'36e'x, name='spa_hkp',apid_obj='spp_swp_spe_hkp_apdat',tname='spp_spa_hkp',ttags=spe_hkp_tags, save_flag=save_flag,rt_flag=rt_flag
    spp_apdat_info,'37e'x ,name='spb_hkp',apid_obj='spp_swp_spe_hkp_apdat',tname='spp_spb_hkp',ttags=spe_hkp_tags, save_flag=save_flag,rt_flag=rt_flag

    ;;-----------------------------------------------------------------------------------------------------------------------------------------
    ;; Fast Housekeeping
    ;;-----------------------------------------------------------------------------------------------------------------------------------------
    spp_apdat_info,'36f'x, name='spa_fhkp' ,routine='spp_swp_spane_fast_hkp_decom',tname='spp_spa_fhkp', ttags='*', save_flag=save_flag,rt_flag=rt_flag
    spp_apdat_info,'37f'x, name='spb_fhkp' ,routine='spp_swp_spane_fast_hkp_decom',tname='spp_spb_fhkp', ttags='*', save_flag=save_flag,rt_flag=rt_flag

    
  endif





  ;;############################################
  ;; SETUP GSE APID
  ;;############################################
  ;swx_apdat_info,'751'x,name='aps1' ,routine='spp_power_supply_decom',tname='APS1',   save_flag=save_flag,ttags='*P25?',   rt_flag=rt_flag
  ;swx_apdat_info,'752'x,name='aps2' ,routine='spp_power_supply_decom',tname='APS2',   save_flag=save_flag,ttags='*P25?',   rt_flag=rt_flag
  ;swx_apdat_info,'753'x,name='aps3' ,routine='spp_power_supply_decom',tname='APS3',   save_flag=save_flag,ttags='*P6? *N25V',   rt_flag=rt_flag
  ;swx_apdat_info,'754'x,name='aps4' ,routine='spp_power_supply_decom',tname='APS4',   save_flag=save_flag,ttags='P25?',   rt_flag=rt_flag
  ;swx_apdat_info,'755'x,name='aps5' ,routine='spp_power_supply_decom',tname='APS5',   save_flag=save_flag,ttags='P25?',   rt_flag=rt_flag
  ;swx_apdat_info,'756'x,name='aps6' ,routine='spp_power_supply_decom',tname='APS6',   save_flag=save_flag,ttags='P25?',   rt_flag=rt_flag
  ;swx_apdat_info,'761'x,name='bertan1' ,routine='spp_power_supply_decom',tname='Igun',save_flag=save_flag,ttags='*VOLTS *CURRENT',   rt_flag=rt_flag
  ;swx_apdat_info,'762'x,name='bertan2',routine='spp_power_supply_decom',tname='Egun', save_flag=save_flag,ttags='*VOLTS *CURRENT',   rt_flag=rt_flag
  swx_apdat_info,'7c0'x,name='log_msg',apid_obj='swfo_stis_log_msg_apdat'     ,tname='log',  save_flag=save_flag,ttags='MSG SEQN',   rt_flag=rt_flag
  ;swx_apdat_info,'7c1'x,name='usrlog_msg',apid_obj='swx_stis_log_msg_apdat'     ,tname='usrlog',  save_flag=save_flag,ttags='SEQN MSG',   rt_flag=rt_flag
  ;   swx_apdat_info,'7c0'x,name='log_msg',routine='spp_log_msg_decom'     ,tname='log',  save_flag=save_flag,ttags='MSG',   rt_flag=rt_flag
  ;   swx_apdat_info,'7c1'x,name='usrlog_msg',routine='spp_log_msg_decom'     ,tname='usrlog',  save_flag=save_flag,ttags='SEQN MSG',   rt_flag=rt_flag
  ;swx_apdat_info,'7c3'x,name='manip', routine='spp_swp_manip_decom'   ,tname='manip', ttags='*POS',save_flag=save_flag,rt_flag=rt_flag
  swx_apdat_info,'7c4'x,name='swemulator', apid_obj='swfo_stis_swemulator_apdat'   ,tname='swemul_tns',ttags='*',save_flag=save_flag,rt_flag=rt_flag


  if keyword_set(clear) then swx_apdat_info,/clear

end
