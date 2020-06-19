;+
; $LastChangedBy: ali $
; $LastChangedDate: 2020-06-18 10:30:04 -0700 (Thu, 18 Jun 2020) $
; $LastChangedRevision: 28786 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SPP/sweap/COMMON/spp_swp_apdat_init.pro $
;-

pro spp_swp_apdat_init,reset=reset, save_flag = save_flag, $
                       rt_flag= rt_Flag, $
                       clear = clear, no_products =no_products

   common spp_swp_apdat_init, initialized
   if keyword_set(reset) then initialized = 0
   if keyword_set(initialized) then return
   initialized =1 
;   dprint,dlevel=3,/phelp ,rt_flag,save_flag


   ;; special case to accumulate statistics
   spp_apdat_info, 0 ,name='Stats',apid_obj='spp_gen_apdat_stats',tname='APIDS_', ttags=ttags,save_flag=save_flag,rt_flag=rt_flag 

   ;;#################
   ;; SETUP SWEM APIDs
   ;;#################
   ttags = 'SEQN*'
   spp_apdat_info,'1c5'x,name='sc_hkp_0x1c5',apid_obj = 'spp_sc_hk_0x1c5_apdat', tname = 'spp_sc_hkp_0x1c5_', save_flag=save_flag,ttags='*',rt_flag=rt_flag
   spp_apdat_info,'1de'x,name='sc_hkp_0x1de',apid_obj = 'spp_sc_hk_0x1de_apdat', tname = 'spp_sc_hkp_0x1de_', save_flag=save_flag,ttags='*',rt_flag=rt_flag
   spp_apdat_info,'1df'x,name='sc_hkp_0x1df',apid_obj = 'spp_sc_hk_0x1df_apdat', tname = 'spp_sc_hkp_0x1df_', save_flag=save_flag,ttags='*',rt_flag=rt_flag
   spp_apdat_info,'254'x,name='sc_hkp_0x254',apid_obj = 'spp_sc_hk_0x254_apdat', tname = 'spp_sc_hkp_0x254_', save_flag=save_flag,ttags='*',rt_flag=rt_flag
   spp_apdat_info,'255'x,name='sc_hkp_0x255',apid_obj = 'spp_sc_hk_0x255_apdat', tname = 'spp_sc_hkp_0x255_', save_flag=save_flag,ttags='*',rt_flag=rt_flag
   spp_apdat_info,'256'x,name='sc_hkp_0x256',apid_obj = 'spp_sc_hk_0x256_apdat', tname = 'spp_sc_hkp_0x256_', save_flag=save_flag,ttags='*',rt_flag=rt_flag
   spp_apdat_info,'257'x,name='sc_hkp_0x257',apid_obj = 'spp_sc_hk_0x257_apdat', tname = 'spp_sc_hkp_0x257_', save_flag=save_flag,ttags='*',rt_flag=rt_flag
   spp_apdat_info,'262'x,name='sc_hkp_0x262',apid_obj = 'spp_sc_hk_0x262_apdat', tname = 'spp_sc_hkp_0x262_', save_flag=save_flag,ttags='*',rt_flag=rt_flag
   
   spp_apdat_info,'340'x,name='swem_crit_hkp',             tname='spp_swem_crit_',  save_flag=save_flag,ttags=ttags,rt_flag=rt_flag 
   spp_apdat_info,'341'x,name='swem_dig_hkp',  apid_obj='spp_swp_swem_dhkp_apdat',  tname='spp_swem_dhkp_',  save_flag=save_flag,ttags='*',  rt_flag=rt_flag 
   spp_apdat_info,'342'x,name='swem_memdump', apid_obj='spp_swp_memdump_apdat',  tname='spp_swem_memdump_',   save_flag=save_flag,ttags='*',rt_flag=rt_flag
   spp_apdat_info,'343'x,name='swem_ana_hkp',  apid_obj='spp_swp_swem_hkp_apdat',   tname='spp_swem_ahkp_',  save_flag=save_flag,ttags='*',  rt_flag=rt_flag 
   spp_apdat_info,'344'x,name='swem_event_log',apid_obj='spp_swp_swem_events_apdat', tname='spp_event_log_',  save_flag=save_flag,ttags='*',rt_flag=rt_flag 
   spp_apdat_info,'345'x,name='swem_cmd_echo',                                     tname='spp_cmd_echo_',   save_flag=save_flag,ttags=ttags,rt_flag=rt_flag
   spp_apdat_info,'346'x,name='swem_timing',   apid_obj='spp_swp_swem_timing_apdat',tname='spp_swem_timing_',ttags='*',save_flag=save_flag,  rt_flag=rt_flag
   spp_apdat_info,'347'x,name='swem_memdwell',                        tname='spp_swem_memdwell_',    ttags='*',save_flag=save_flag,  rt_flag=rt_flag 


   spp_apdat_info,'348'x,name='wrp_P2rt',apid_obj='spp_swp_wrapper_apdat',tname='spp_swp_348_',   ttags='SEQN*',save_flag=save_flag,rt_flag=rt_flag
   spp_apdat_info,'349'x,name='wrp_P2',apid_obj='spp_swp_wrapper_apdat',tname='spp_swp_349_',   ttags='SEQN*',save_flag=save_flag,rt_flag=rt_flag
   spp_apdat_info,'34A'x,name='wrp_P3rt',apid_obj='spp_swp_wrapper_apdat',tname='spp_swp_34A_',   ttags='SEQN*',save_flag=save_flag,rt_flag=rt_flag
   spp_apdat_info,'34b'x,name='wrp_P3',apid_obj='spp_swp_wrapper_apdat',tname='spp_swp_34B_',   ttags='SEQN*',save_flag=save_flag,rt_flag=rt_flag
   spp_apdat_info,'34c'x,name='wrp_P4rt',apid_obj='spp_swp_wrapper_apdat',tname='spp_swp_34C_',   ttags='SEQN*',save_flag=save_flag,rt_flag=rt_flag
   spp_apdat_info,'34d'x,name='wrp_P4',apid_obj='spp_swp_wrapper_apdat',tname='spp_swp_34D_',   ttags='SEQN*',save_flag=save_flag,rt_flag=rt_flag
   spp_apdat_info,'34e'x,name='wrp_P5',apid_obj='spp_swp_wrapper_apdat',tname='spp_swp_34E_',   ttags='SEQN*',save_flag=save_flag,rt_flag=rt_flag
   spp_apdat_info,'34f'x,name='wrp_P8',apid_obj='spp_swp_wrapper_apdat',tname='spp_swp_34F_',   ttags='SEQN*',save_flag=save_flag,rt_flag=rt_flag
   spp_apdat_info,'350'x,name='wrp_P8x',apid_obj='spp_swp_wrapper_apdat',tname='spp_swp_350_',   ttags='SEQN*',save_flag=save_flag,rt_flag=rt_flag


   ;;################
   ;;#   SPC APIDs  #
   ;;################
   spp_apdat_info,'351'x,name='spc_351', apid_obj=!null,     tname='spp_spc_351_',ttags='SEQN*',save_flag=save_flag,rt_flag=rt_flag 
   spp_apdat_info,'352'x,name='spc_352', apid_obj=!null,     tname='spp_spc_352_',ttags='SEQN*',save_flag=save_flag,rt_flag=rt_flag
   spp_apdat_info,'353'x,name='spc_353', apid_obj=!null,     tname='spp_spc_353_',ttags='SEQN*',save_flag=save_flag,rt_flag=rt_flag 
   spp_apdat_info,'354'x,name='spc_rss', apid_obj=!null,      tname='spp_spc_rss_',ttags='SEQN*',save_flag=save_flag,rt_flag=rt_flag
   spp_apdat_info,'35E'x,name='spc_35E', apid_obj=!null,     tname='spp_spc_35E_',ttags='SEQN*',save_flag=save_flag,rt_flag=rt_flag 
   spp_apdat_info,'35F'x,name='spc_hkp', apid_obj='spp_swp_spc_hkp_apdat', tname='spp_spc_hkp_',ttags='*',save_flag=save_flag,rt_flag=rt_flag 


   ;;##################
   ;;#  SPAN-Ai APID  #
   ;;##################

   ;; Housekeeping - Rates - Events - Manipulator - Memory Dump
   spp_apdat_info,'3b8'x,name='spi_memdump',  apid_obj='spp_swp_memdump_apdat',       tname='spp_spi_memdump_', ttags='*',save_flag=save_flag,rt_flag=rt_flag
   spp_apdat_info,'3b9'x,name='spi_events',   routine='spp_swp_spani_event_decom',        tname='spp_spi_events_',   ttags='*',save_flag=save_flag,rt_flag=rt_flag
   ;;spp_apdat_info,'3ba'x,name='spi_tof',      routine='spp_swp_spani_tof_decom',          tname='spp_spi_tof_',      ttags='*',save_flag=save_flag,rt_flag=rt_flag
   spp_apdat_info,'3ba'x,name='spi_tof',      apid_obj='spp_swp_spi_tof_apdat',          tname='spp_spi_tof_',      ttags='*',save_flag=save_flag,rt_flag=rt_flag
   spp_apdat_info,'3bb'x,name='spi_rates',    apid_obj='spp_swp_spi_rates_apdat',         tname='spp_spi_rates_',    ttags='*CNTS',save_flag=save_flag,rt_flag=rt_flag
   spp_apdat_info,'3be'x,name='spi_hkp',      apid_obj='spp_swp_spi_hkp_apdat'  ,         tname='spp_spi_hkp_',      ttags='*TEMPS *NYS *MON* *MRAM* DACS HV_MODE CMDS_REC *ACT_FLAG',save_flag=save_flag,rt_flag=rt_flag
   spp_apdat_info,'3bf'x,name='spi_fhkp',     routine='spp_swp_spani_fast_hkp_decom',     tname='spp_spi_fhkp_',     ttags='*',save_flag=save_flag,rt_flag=rt_flag

   ;;decom_routine_i = 'spp_swp_spani_product_decom'
   ;;decom_routine_i = 'spp_swp_spani_product_decom2'
   decom_routine_obj = 'spp_swp_spi_prod_apdat'
   ttags = '*SPEC* *CNTS* *DATASIZE MODE2'
   if not keyword_set(no_products) then begin

      ;;----------------------------------------------------------- Moments -------------------------------------------------------------------
      spp_apdat_info,'3B0'x,name='spi_mom_0',apid_obj='spp_swp_moments_apdat',tname='spp_spi_mom_0_', ttags=ttags,save_flag=save_flag,rt_flag=rt_flag
      spp_apdat_info,'3B1'x,name='spi_mom_1',apid_obj='spp_swp_moments_apdat',tname='spp_spi_mom_1_', ttags=ttags,save_flag=save_flag,rt_flag=rt_flag
      spp_apdat_info,'3B2'x,name='spi_mom_2',apid_obj='spp_swp_moments_apdat',tname='spp_spi_mom_2_', ttags=ttags,save_flag=save_flag,rt_flag=rt_flag
      spp_apdat_info,'3B3'x,name='spi_mom_3',apid_obj='spp_swp_moments_apdat',tname='spp_spi_mom_3_', ttags=ttags,save_flag=save_flag,rt_flag=rt_flag
      
      ;;------------------------------------------------- Archive Full Sweep Products -------------------------------------------------------
      spp_apdat_info,'380'x,name='spi_af00',apid_obj=decom_routine_obj,tname='spp_spi_AF00_', ttags=ttags,save_flag=save_flag,rt_flag=rt_flag 
      spp_apdat_info,'381'x,name='spi_af01',apid_obj=decom_routine_obj,tname='spp_spi_AF01_', ttags=ttags,save_flag=save_flag,rt_flag=rt_flag 
      spp_apdat_info,'382'x,name='spi_af02',apid_obj=decom_routine_obj,tname='spp_spi_AF02_', ttags=ttags,save_flag=save_flag,rt_flag=rt_flag 
      spp_apdat_info,'383'x,name='spi_af03',apid_obj=decom_routine_obj,tname='spp_spi_AF03_', ttags=ttags,save_flag=save_flag,rt_flag=rt_flag 
      spp_apdat_info,'384'x,name='spi_af10',apid_obj=decom_routine_obj,tname='spp_spi_AF10_', ttags=ttags,save_flag=save_flag,rt_flag=rt_flag 
      spp_apdat_info,'385'x,name='spi_af11',apid_obj=decom_routine_obj,tname='spp_spi_AF11_', ttags=ttags,save_flag=save_flag,rt_flag=rt_flag 
      spp_apdat_info,'386'x,name='spi_af12',apid_obj=decom_routine_obj,tname='spp_spi_AF12_', ttags=ttags,save_flag=save_flag,rt_flag=rt_flag 
      spp_apdat_info,'387'x,name='spi_af13',apid_obj=decom_routine_obj,tname='spp_spi_AF13_', ttags=ttags,save_flag=save_flag,rt_flag=rt_flag 
      spp_apdat_info,'388'x,name='spi_af20',apid_obj=decom_routine_obj,tname='spp_spi_AF20_', ttags=ttags,save_flag=save_flag,rt_flag=rt_flag 
      spp_apdat_info,'389'x,name='spi_af21',apid_obj=decom_routine_obj,tname='spp_spi_AF21_', ttags=ttags,save_flag=save_flag,rt_flag=rt_flag 
      spp_apdat_info,'38a'x,name='spi_af22',apid_obj=decom_routine_obj,tname='spp_spi_AF22_', ttags=ttags,save_flag=save_flag,rt_flag=rt_flag 
      spp_apdat_info,'38b'x,name='spi_af23',apid_obj=decom_routine_obj,tname='spp_spi_AF23_', ttags=ttags,save_flag=save_flag,rt_flag=rt_flag 

      ;;---------------------------------------------- Archive Targeted Sweep Products ------------------------------------------------------
      spp_apdat_info,'38c'x,name='spi_at00',apid_obj=decom_routine_obj,tname='spp_spi_AT00_', ttags=ttags,save_flag=save_flag,rt_flag=rt_flag 
      spp_apdat_info,'38d'x,name='spi_at01',apid_obj=decom_routine_obj,tname='spp_spi_AT01_', ttags=ttags,save_flag=save_flag,rt_flag=rt_flag 
      spp_apdat_info,'38e'x,name='spi_at02',apid_obj=decom_routine_obj,tname='spp_spi_AT02_', ttags=ttags,save_flag=save_flag,rt_flag=rt_flag 
      spp_apdat_info,'38f'x,name='spi_at03',apid_obj=decom_routine_obj,tname='spp_spi_AT03_', ttags=ttags,save_flag=save_flag,rt_flag=rt_flag 
      spp_apdat_info,'390'x,name='spi_at10',apid_obj=decom_routine_obj,tname='spp_spi_AT10_', ttags=ttags,save_flag=save_flag,rt_flag=rt_flag 
      spp_apdat_info,'391'x,name='spi_at11',apid_obj=decom_routine_obj,tname='spp_spi_AT11_', ttags=ttags,save_flag=save_flag,rt_flag=rt_flag 
      spp_apdat_info,'392'x,name='spi_at12',apid_obj=decom_routine_obj,tname='spp_spi_AT12_', ttags=ttags,save_flag=save_flag,rt_flag=rt_flag 
      spp_apdat_info,'393'x,name='spi_at13',apid_obj=decom_routine_obj,tname='spp_spi_AT13_', ttags=ttags,save_flag=save_flag,rt_flag=rt_flag 
      spp_apdat_info,'394'x,name='spi_at20',apid_obj=decom_routine_obj,tname='spp_spi_AT20_', ttags=ttags,save_flag=save_flag,rt_flag=rt_flag 
      spp_apdat_info,'395'x,name='spi_at21',apid_obj=decom_routine_obj,tname='spp_spi_AT21_', ttags=ttags,save_flag=save_flag,rt_flag=rt_flag 
      spp_apdat_info,'396'x,name='spi_at22',apid_obj=decom_routine_obj,tname='spp_spi_AT22_', ttags=ttags,save_flag=save_flag,rt_flag=rt_flag 
      spp_apdat_info,'397'x,name='spi_at23',apid_obj=decom_routine_obj,tname='spp_spi_AT23_', ttags=ttags,save_flag=save_flag,rt_flag=rt_flag 

      ;;------------------------------------------------ Survey Full Sweep Products ---------------------------------------------------------
      spp_apdat_info,'398'x,name='spi_sf00',apid_obj=decom_routine_obj,tname='spp_spi_SF00_', ttags=ttags,save_flag=save_flag,rt_flag=rt_flag 
      spp_apdat_info,'399'x,name='spi_sf01',apid_obj=decom_routine_obj,tname='spp_spi_SF01_', ttags=ttags,save_flag=save_flag,rt_flag=rt_flag 
      spp_apdat_info,'39a'x,name='spi_sf02',apid_obj=decom_routine_obj,tname='spp_spi_SF02_', ttags=ttags,save_flag=save_flag,rt_flag=rt_flag 
      spp_apdat_info,'39b'x,name='spi_sf03',apid_obj=decom_routine_obj,tname='spp_spi_SF03_', ttags=ttags,save_flag=save_flag,rt_flag=rt_flag 
      spp_apdat_info,'39c'x,name='spi_sf10',apid_obj=decom_routine_obj,tname='spp_spi_SF10_', ttags=ttags,save_flag=save_flag,rt_flag=rt_flag 
      spp_apdat_info,'39d'x,name='spi_sf11',apid_obj=decom_routine_obj,tname='spp_spi_SF11_', ttags=ttags,save_flag=save_flag,rt_flag=rt_flag 
      spp_apdat_info,'39e'x,name='spi_sf12',apid_obj=decom_routine_obj,tname='spp_spi_SF12_', ttags=ttags,save_flag=save_flag,rt_flag=rt_flag 
      spp_apdat_info,'39f'x,name='spi_sf13',apid_obj=decom_routine_obj,tname='spp_spi_SF13_', ttags=ttags,save_flag=save_flag,rt_flag=rt_flag 
      spp_apdat_info,'3a0'x,name='spi_sf20',apid_obj=decom_routine_obj,tname='spp_spi_SF20_', ttags=ttags,save_flag=save_flag,rt_flag=rt_flag 
      spp_apdat_info,'3a1'x,name='spi_sf21',apid_obj=decom_routine_obj,tname='spp_spi_SF21_', ttags=ttags,save_flag=save_flag,rt_flag=rt_flag 
      spp_apdat_info,'3a2'x,name='spi_sf22',apid_obj=decom_routine_obj,tname='spp_spi_SF22_', ttags=ttags,save_flag=save_flag,rt_flag=rt_flag 
      spp_apdat_info,'3a3'x,name='spi_sf23',apid_obj=decom_routine_obj,tname='spp_spi_SF23_', ttags=ttags,save_flag=save_flag,rt_flag=rt_flag 

      ;----------------------------------------------  Survey Targeted Sweep Products -------------------------------------------------------
      spp_apdat_info,'3a4'x,name='spi_st00',apid_obj=decom_routine_obj,tname='spp_spi_ST00_', ttags=ttags,save_flag=save_flag,rt_flag=rt_flag 
      spp_apdat_info,'3a5'x,name='spi_st01',apid_obj=decom_routine_obj,tname='spp_spi_ST01_', ttags=ttags,save_flag=save_flag,rt_flag=rt_flag 
      spp_apdat_info,'3a6'x,name='spi_st02',apid_obj=decom_routine_obj,tname='spp_spi_ST02_', ttags=ttags,save_flag=save_flag,rt_flag=rt_flag 
      spp_apdat_info,'3a7'x,name='spi_st03',apid_obj=decom_routine_obj,tname='spp_spi_ST03_', ttags=ttags,save_flag=save_flag,rt_flag=rt_flag 
      spp_apdat_info,'3a8'x,name='spi_st10',apid_obj=decom_routine_obj,tname='spp_spi_ST10_', ttags=ttags,save_flag=save_flag,rt_flag=rt_flag 
      spp_apdat_info,'3a9'x,name='spi_st11',apid_obj=decom_routine_obj,tname='spp_spi_ST11_', ttags=ttags,save_flag=save_flag,rt_flag=rt_flag 
      spp_apdat_info,'3aa'x,name='spi_st12',apid_obj=decom_routine_obj,tname='spp_spi_ST12_', ttags=ttags,save_flag=save_flag,rt_flag=rt_flag 
      spp_apdat_info,'3ab'x,name='spi_st13',apid_obj=decom_routine_obj,tname='spp_spi_ST13_', ttags=ttags,save_flag=save_flag,rt_flag=rt_flag 
      spp_apdat_info,'3ac'x,name='spi_st20',apid_obj=decom_routine_obj,tname='spp_spi_ST20_', ttags=ttags,save_flag=save_flag,rt_flag=rt_flag 
      spp_apdat_info,'3ad'x,name='spi_st21',apid_obj=decom_routine_obj,tname='spp_spi_ST21_', ttags=ttags,save_flag=save_flag,rt_flag=rt_flag 
      spp_apdat_info,'3ae'x,name='spi_st22',apid_obj=decom_routine_obj,tname='spp_spi_ST22_', ttags=ttags,save_flag=save_flag,rt_flag=rt_flag 
      spp_apdat_info,'3af'x,name='spi_st23',apid_obj=decom_routine_obj,tname='spp_spi_ST23_', ttags=ttags,save_flag=save_flag,rt_flag=rt_flag 

   ENDIF 


   
   ;;##################
   ;;#  SPAN-Ae APID  #
   ;;##################
   spe_hkp_tags = 'RIO_???* ADC_*_* *_FLAG MRAM* CLKS_PER_NYS ALL_ADC EASIC_DAC *CMD_* PEAK*'
   spe_hkp_tags = '*'
   ;decom_routine = 'spp_swp_spane_product_decom2' ;; DEPRECATED ;;
   decom_routine_obj = 'spp_swp_spe_prod_apdat'
   ttags = '*'

   ;;----------------------------------------------------------------------------------------------------------------------------------
   ;; Product Decommutators
   ;;----------------------------------------------------------------------------------------------------------------------------------
   spp_apdat_info,'360'x,name='spa_af0' ,apid_obj=decom_routine_obj,tname='spp_spa_AF0_', ttags=ttags, save_flag=save_flag,rt_flag=rt_flag 
   spp_apdat_info,'361'x,name='spa_af1' ,apid_obj=decom_routine_obj,tname='spp_spa_AF1_', ttags=ttags, save_flag=save_flag,rt_flag=rt_flag 
   spp_apdat_info,'362'x,name='spa_at0' ,apid_obj=decom_routine_obj,tname='spp_spa_AT0_', ttags=ttags, save_flag=save_flag,rt_flag=rt_flag 
   spp_apdat_info,'363'x,name='spa_at1' ,apid_obj=decom_routine_obj,tname='spp_spa_AT1_', ttags=ttags, save_flag=save_flag,rt_flag=rt_flag 

   spp_apdat_info,'364'x,name='spa_sf0' ,apid_obj=decom_routine_obj,tname='spp_spa_SF0_', ttags=ttags, save_flag=save_flag,rt_flag=rt_flag 
   spp_apdat_info,'365'x,name='spa_sf1' ,apid_obj=decom_routine_obj,tname='spp_spa_SF1_', ttags=ttags, save_flag=save_flag,rt_flag=rt_flag 
   spp_apdat_info,'366'x,name='spa_st0' ,apid_obj=decom_routine_obj,tname='spp_spa_ST0_', ttags=ttags, save_flag=save_flag,rt_flag=rt_flag 
   spp_apdat_info,'367'x,name='spa_st1' ,apid_obj=decom_routine_obj,tname='spp_spa_ST1_', ttags=ttags, save_flag=save_flag,rt_flag=rt_flag 


   ;;----------------------------------------------------------------------------------------------------------------------------------------
   ;; Memory Dump
   ;;----------------------------------------------------------------------------------------------------------------------------------------
   spp_apdat_info,'36d'x,name='spa_memdump', apid_obj='spp_swp_memdump_apdat' ,tname='spp_spa_memdump_',ttags='SEQN', save_flag=save_flag,rt_flag=rt_flag 

   ;;----------------------------------------------------------------------------------------------------------------------------------------
   ;; Slow Housekeeping
   ;;----------------------------------------------------------------------------------------------------------------------------------------
   spp_apdat_info,'36e'x, name='spa_hkp' ,apid_obj='spp_swp_spe_hkp_apdat',tname='spp_spa_hkp_',ttags=spe_hkp_tags, save_flag=save_flag,rt_flag=rt_flag  

   ;;-----------------------------------------------------------------------------------------------------------------------------------------
   ;; Fast Housekeeping
   ;;-----------------------------------------------------------------------------------------------------------------------------------------
   spp_apdat_info,'36f'x, name='spa_fhkp' ,routine='spp_swp_spane_fast_hkp_decom',tname='spp_spa_fhkp_', ttags='*', save_flag=save_flag,rt_flag=rt_flag 




   ;;############################################
   ;; SETUP SPAN-B APID
   ;;############################################
   
   ;;----------------------------------------------------------------------------------------------------------------------------------
   ;; Product Decommutators
   ;;----------------------------------------------------------------------------------------------------------------------------------
   spp_apdat_info,'370'x,name='spb_af0' ,apid_obj=decom_routine_obj,tname='spp_spb_AF0_', ttags=ttags, save_flag=save_flag,rt_flag=rt_flag 
   spp_apdat_info,'371'x,name='spb_af1' ,apid_obj=decom_routine_obj,tname='spp_spb_AF1_', ttags=ttags, save_flag=save_flag,rt_flag=rt_flag 
   spp_apdat_info,'372'x,name='spb_at0' ,apid_obj=decom_routine_obj,tname='spp_spb_AT0_', ttags=ttags, save_flag=save_flag,rt_flag=rt_flag 
   spp_apdat_info,'373'x,name='spb_at1' ,apid_obj=decom_routine_obj,tname='spp_spb_AT1_', ttags=ttags, save_flag=save_flag,rt_flag=rt_flag 

   spp_apdat_info,'374'x,name='spb_sf0' ,apid_obj=decom_routine_obj,tname='spp_spb_SF0_', ttags=ttags, save_flag=save_flag,rt_flag=rt_flag 
   spp_apdat_info,'375'x,name='spb_sf1' ,apid_obj=decom_routine_obj,tname='spp_spb_SF1_', ttags=ttags, save_flag=save_flag,rt_flag=rt_flag 
   spp_apdat_info,'376'x,name='spb_st0' ,apid_obj=decom_routine_obj,tname='spp_spb_ST0_', ttags=ttags, save_flag=save_flag,rt_flag=rt_flag 
   spp_apdat_info,'377'x,name='spb_st1' ,apid_obj=decom_routine_obj,tname='spp_spb_ST1_', ttags=ttags, save_flag=save_flag,rt_flag=rt_flag 

   ;;----------------------------------------------------------------------------------------------------------------------------------------
   ;; Memory Dump
   ;;----------------------------------------------------------------------------------------------------------------------------------------
   spp_apdat_info,'37d'x ,name='spb_memdump', apid_obj='spp_swp_memdump_apdat',   tname='spp_spb_memdump_',  save_flag=save_flag,rt_flag=rt_flag 
   
   ;;----------------------------------------------------------------------------------------------------------------------------------------
   ;; Slow Housekeeping
   ;;----------------------------------------------------------------------------------------------------------------------------------------
   spp_apdat_info,'37e'x ,name='spb_hkp',apid_obj='spp_swp_spe_hkp_apdat',tname='spp_spb_hkp_',ttags=spe_hkp_tags, save_flag=save_flag,rt_flag=rt_flag 

   ;;-----------------------------------------------------------------------------------------------------------------------------------------
   ;; Fast Housekeeping
   ;;-----------------------------------------------------------------------------------------------------------------------------------------
   spp_apdat_info,'37f'x, name='spb_fhkp' ,routine='spp_swp_spane_fast_hkp_decom',tname='spp_spb_fhkp_', ttags='*', save_flag=save_flag,rt_flag=rt_flag 
   


   ;;############################################
   ;; SETUP GSE APID
   ;;############################################
   spp_apdat_info,'751'x,name='aps1' ,routine='spp_power_supply_decom',tname='APS1_',   save_flag=save_flag,ttags='*P25?',   rt_flag=rt_flag 
   spp_apdat_info,'752'x,name='aps2' ,routine='spp_power_supply_decom',tname='APS2_',   save_flag=save_flag,ttags='*P25?',   rt_flag=rt_flag 
   spp_apdat_info,'753'x,name='aps3' ,routine='spp_power_supply_decom',tname='APS3_',   save_flag=save_flag,ttags='*P6? *N25V',   rt_flag=rt_flag 
   spp_apdat_info,'754'x,name='aps4' ,routine='spp_power_supply_decom',tname='APS4_',   save_flag=save_flag,ttags='P25?',   rt_flag=rt_flag 
   spp_apdat_info,'755'x,name='aps5' ,routine='spp_power_supply_decom',tname='APS5_',   save_flag=save_flag,ttags='P25?',   rt_flag=rt_flag
   spp_apdat_info,'756'x,name='aps6' ,routine='spp_power_supply_decom',tname='APS6_',   save_flag=save_flag,ttags='P25?',   rt_flag=rt_flag
   spp_apdat_info,'761'x,name='bertan1' ,routine='spp_power_supply_decom',tname='Igun_',save_flag=save_flag,ttags='*VOLTS *CURRENT',   rt_flag=rt_flag 
   spp_apdat_info,'762'x,name='bertan2',routine='spp_power_supply_decom',tname='Egun_', save_flag=save_flag,ttags='*VOLTS *CURRENT',   rt_flag=rt_flag 
   spp_apdat_info,'7c0'x,name='log_msg',apid_obj='spp_swp_log_msg_apdat'     ,tname='log_',  save_flag=save_flag,ttags='MSG SEQN',   rt_flag=rt_flag 
   spp_apdat_info,'7c1'x,name='usrlog_msg',apid_obj='spp_swp_log_msg_apdat'     ,tname='usrlog_',  save_flag=save_flag,ttags='SEQN MSG',   rt_flag=rt_flag
;   spp_apdat_info,'7c0'x,name='log_msg',routine='spp_log_msg_decom'     ,tname='log_',  save_flag=save_flag,ttags='MSG',   rt_flag=rt_flag
;   spp_apdat_info,'7c1'x,name='usrlog_msg',routine='spp_log_msg_decom'     ,tname='usrlog_',  save_flag=save_flag,ttags='SEQN MSG',   rt_flag=rt_flag
   spp_apdat_info,'7c3'x,name='manip', routine='spp_swp_manip_decom'   ,tname='manip_', ttags='*POS',save_flag=save_flag,rt_flag=rt_flag 
   spp_apdat_info,'7c4'x,name='swemulator', apid_obj='spp_swp_swemulator_apdat'   ,tname='swemul_tns_',ttags='*',save_flag=save_flag,rt_flag=rt_flag


   if keyword_set(clear) then spp_apdat_info,/clear
   
   

end
