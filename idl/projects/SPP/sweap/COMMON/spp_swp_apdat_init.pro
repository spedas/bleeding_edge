;+
; $LastChangedBy: ali $
; $LastChangedDate: 2023-07-22 18:26:45 -0700 (Sat, 22 Jul 2023) $
; $LastChangedRevision: 31965 $
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
  spp_apdat_info,'081'x,name='sc_hkp_0x081',apid_obj = 'spp_sc_hk_0x081_apdat', tname = 'spp_sc_hkp_0x081', save_flag=save_flag,ttags='*',rt_flag=rt_flag
  spp_apdat_info,'1c4'x,name='sc_hkp_0x1c4',apid_obj = 'spp_sc_hk_0x1c4_apdat', tname = 'spp_sc_hkp_0x1c4', save_flag=save_flag,ttags='*',rt_flag=rt_flag
  spp_apdat_info,'1c5'x,name='sc_hkp_0x1c5',apid_obj = 'spp_sc_hk_0x1c5_apdat', tname = 'spp_sc_hkp_0x1c5', save_flag=save_flag,ttags='*',rt_flag=rt_flag
  spp_apdat_info,'1de'x,name='sc_hkp_0x1de',apid_obj = 'spp_sc_hk_0x1de_apdat', tname = 'spp_sc_hkp_0x1de', save_flag=save_flag,ttags='*',rt_flag=rt_flag
  spp_apdat_info,'1df'x,name='sc_hkp_0x1df',apid_obj = 'spp_sc_hk_0x1df_apdat', tname = 'spp_sc_hkp_0x1df', save_flag=save_flag,ttags='*',rt_flag=rt_flag
  spp_apdat_info,'254'x,name='sc_hkp_0x254',apid_obj = 'spp_sc_hk_0x254_apdat', tname = 'spp_sc_hkp_0x254', save_flag=save_flag,ttags='*',rt_flag=rt_flag
  spp_apdat_info,'255'x,name='sc_hkp_0x255',apid_obj = 'spp_sc_hk_0x255_apdat', tname = 'spp_sc_hkp_0x255', save_flag=save_flag,ttags='*',rt_flag=rt_flag
  spp_apdat_info,'256'x,name='sc_hkp_0x256',apid_obj = 'spp_sc_hk_0x256_apdat', tname = 'spp_sc_hkp_0x256', save_flag=save_flag,ttags='*',rt_flag=rt_flag
  spp_apdat_info,'257'x,name='sc_hkp_0x257',apid_obj = 'spp_sc_hk_0x257_apdat', tname = 'spp_sc_hkp_0x257', save_flag=save_flag,ttags='*',rt_flag=rt_flag
  spp_apdat_info,'262'x,name='sc_hkp_0x262',apid_obj = 'spp_sc_hk_0x262_apdat', tname = 'spp_sc_hkp_0x262', save_flag=save_flag,ttags='*',rt_flag=rt_flag

  spp_apdat_info,'340'x,name='swem_crit_hkp',                                      tname='spp_swem_crit_hkp', save_flag=save_flag,ttags='*',rt_flag=rt_flag
  spp_apdat_info,'341'x,name='swem_dig_hkp',  apid_obj='spp_swp_swem_dhkp_apdat',  tname='spp_swem_dig_hkp',  save_flag=save_flag,ttags='*',rt_flag=rt_flag
  spp_apdat_info,'342'x,name='swem_memdump',  apid_obj='spp_swp_memdump_apdat',    tname='spp_swem_memdump',  save_flag=save_flag,ttags='*',rt_flag=rt_flag
  spp_apdat_info,'343'x,name='swem_ana_hkp',  apid_obj='spp_swp_swem_hkp_apdat',   tname='spp_swem_ana_hkp',  save_flag=save_flag,ttags='*',rt_flag=rt_flag
  spp_apdat_info,'344'x,name='swem_event_log',apid_obj='spp_swp_swem_events_apdat',tname='spp_swem_event_log',save_flag=save_flag,ttags='*',rt_flag=rt_flag
  spp_apdat_info,'345'x,name='swem_cmd_echo',                                      tname='spp_swem_cmd_echo', save_flag=save_flag,ttags='*',rt_flag=rt_flag
  spp_apdat_info,'346'x,name='swem_timing',   apid_obj='spp_swp_swem_timing_apdat',tname='spp_swem_timing',   save_flag=save_flag,ttags='*',rt_flag=rt_flag
  spp_apdat_info,'347'x,name='swem_memdwell',                                      tname='spp_swem_memdwell', save_flag=save_flag,ttags='*',rt_flag=rt_flag

  spp_apdat_info,'348'x,name='wrp_P2rt',apid_obj='spp_swp_wrapper_apdat',tname='spp_wrp_348_P2rt',ttags='*',save_flag=save_flag,rt_flag=rt_flag
  spp_apdat_info,'349'x,name='wrp_P2',  apid_obj='spp_swp_wrapper_apdat',tname='spp_wrp_349_P2',  ttags='*',save_flag=save_flag,rt_flag=rt_flag
  spp_apdat_info,'34A'x,name='wrp_P3rt',apid_obj='spp_swp_wrapper_apdat',tname='spp_wrp_34A_P3rt',ttags='*',save_flag=save_flag,rt_flag=rt_flag
  spp_apdat_info,'34b'x,name='wrp_P3',  apid_obj='spp_swp_wrapper_apdat',tname='spp_wrp_34B_P3',  ttags='*',save_flag=save_flag,rt_flag=rt_flag
  spp_apdat_info,'34c'x,name='wrp_P4rt',apid_obj='spp_swp_wrapper_apdat',tname='spp_wrp_34C_P4rt',ttags='*',save_flag=save_flag,rt_flag=rt_flag
  spp_apdat_info,'34d'x,name='wrp_P4',  apid_obj='spp_swp_wrapper_apdat',tname='spp_wrp_34D_P4',  ttags='*',save_flag=save_flag,rt_flag=rt_flag
  spp_apdat_info,'34e'x,name='wrp_P5P7',apid_obj='spp_swp_wrapper_apdat',tname='spp_wrp_34E_P5P7',ttags='*',save_flag=save_flag,rt_flag=rt_flag
  spp_apdat_info,'34f'x,name='wrp_P8',  apid_obj='spp_swp_wrapper_apdat',tname='spp_wrp_34F_P8',  ttags='*',save_flag=save_flag,rt_flag=rt_flag
  spp_apdat_info,'350'x,name='wrp_P8x', apid_obj='spp_swp_wrapper_apdat',tname='spp_wrp_350_P8x', ttags='*',save_flag=save_flag,rt_flag=rt_flag


  ;;################
  ;;#   SPC APIDs  #
  ;;################
  spp_apdat_info,'351'x,name='spc_all', apid_obj=!null,                   tname='spp_spc_all',ttags='SEQN*',save_flag=save_flag,rt_flag=rt_flag
  spp_apdat_info,'352'x,name='spc_tim', apid_obj=!null,                   tname='spp_spc_tim',ttags='SEQN*',save_flag=save_flag,rt_flag=rt_flag
  spp_apdat_info,'353'x,name='spc_sci', apid_obj=!null,                   tname='spp_spc_sci',ttags='SEQN*',save_flag=save_flag,rt_flag=rt_flag
  spp_apdat_info,'354'x,name='spc_rss', apid_obj=!null,                   tname='spp_spc_rss',ttags='SEQN*',save_flag=save_flag,rt_flag=rt_flag
  spp_apdat_info,'35E'x,name='spc_cfg', apid_obj=!null,                   tname='spp_spc_cfg',ttags='SEQN*',save_flag=save_flag,rt_flag=rt_flag
  spp_apdat_info,'35F'x,name='spc_hkp', apid_obj='spp_swp_spc_hkp_apdat', tname='spp_spc_hkp',ttags='*',    save_flag=save_flag,rt_flag=rt_flag


  ;;##################
  ;;#  SPAN-Ai APID  #
  ;;##################

  ;; Housekeeping - Rates - Events - Manipulator - Memory Dump
  spp_apdat_info,'3b8'x,name='spi_memdump',apid_obj='spp_swp_memdump_apdat',      tname='spp_spi_memdump',ttags='*',save_flag=save_flag,rt_flag=rt_flag
  spp_apdat_info,'3b9'x,name='spi_events', routine='spp_swp_spani_event_decom',   tname='spp_spi_events', ttags='*',save_flag=save_flag,rt_flag=rt_flag
  ;;spp_apdat_info,'3ba'x,name='spi_tof',  routine='spp_swp_spani_tof_decom',     tname='spp_spi_tof',    ttags='*',save_flag=save_flag,rt_flag=rt_flag
  spp_apdat_info,'3ba'x,name='spi_tof',    apid_obj='spp_swp_spi_tof_apdat',      tname='spp_spi_tof',    ttags='*',save_flag=save_flag,rt_flag=rt_flag
  spp_apdat_info,'3bb'x,name='spi_rates',  apid_obj='spp_swp_spi_rates_apdat',    tname='spp_spi_rates',  ttags='*CNTS',save_flag=save_flag,rt_flag=rt_flag
  spp_apdat_info,'3be'x,name='spi_hkp',    apid_obj='spp_swp_spi_hkp_apdat'  ,    tname='spp_spi_hkp',    ttags='*TEMPS *NYS *MON* *MRAM* DACS HV_MODE CMDS_REC *ACT_FLAG',save_flag=save_flag,rt_flag=rt_flag
  spp_apdat_info,'3bf'x,name='spi_fhkp',   routine='spp_swp_spani_fast_hkp_decom',tname='spp_spi_fhkp',   ttags='*',save_flag=save_flag,rt_flag=rt_flag

  ;;decom_routine_i = 'spp_swp_spani_product_decom'
  ;;decom_routine_i = 'spp_swp_spani_product_decom2'
  decom_routine_obj = 'spp_swp_spi_prod_apdat'
  ttags = '*SPEC CNTS DATASIZE MODE2 *BITS SOURCE COMPR_RATIO NUM_* TIME_*'
  if not keyword_set(no_products) then begin

    ;;----------------------------------------------------------- Moments -------------------------------------------------------------------
    spp_apdat_info,'3B0'x,name='spi_mom_0',apid_obj='spp_swp_moments_apdat',tname='spp_spi_mom_0', ttags=ttags,save_flag=save_flag,rt_flag=rt_flag
    spp_apdat_info,'3B1'x,name='spi_mom_1',apid_obj='spp_swp_moments_apdat',tname='spp_spi_mom_1', ttags=ttags,save_flag=save_flag,rt_flag=rt_flag
    spp_apdat_info,'3B2'x,name='spi_mom_2',apid_obj='spp_swp_moments_apdat',tname='spp_spi_mom_2', ttags=ttags,save_flag=save_flag,rt_flag=rt_flag
    spp_apdat_info,'3B3'x,name='spi_mom_3',apid_obj='spp_swp_moments_apdat',tname='spp_spi_mom_3', ttags=ttags,save_flag=save_flag,rt_flag=rt_flag

    ;;------------------------------------------------- Archive Full Sweep Products -------------------------------------------------------
    spp_apdat_info,'380'x,name='spi_af00',apid_obj=decom_routine_obj,tname='spp_spi_AF00', ttags=ttags,save_flag=save_flag,rt_flag=rt_flag
    spp_apdat_info,'381'x,name='spi_af01',apid_obj=decom_routine_obj,tname='spp_spi_AF01', ttags=ttags,save_flag=save_flag,rt_flag=rt_flag
    spp_apdat_info,'382'x,name='spi_af02',apid_obj=decom_routine_obj,tname='spp_spi_AF02', ttags=ttags,save_flag=save_flag,rt_flag=rt_flag
    spp_apdat_info,'383'x,name='spi_af03',apid_obj=decom_routine_obj,tname='spp_spi_AF03', ttags=ttags,save_flag=save_flag,rt_flag=rt_flag
    spp_apdat_info,'384'x,name='spi_af10',apid_obj=decom_routine_obj,tname='spp_spi_AF10', ttags=ttags,save_flag=save_flag,rt_flag=rt_flag
    spp_apdat_info,'385'x,name='spi_af11',apid_obj=decom_routine_obj,tname='spp_spi_AF11', ttags=ttags,save_flag=save_flag,rt_flag=rt_flag
    spp_apdat_info,'386'x,name='spi_af12',apid_obj=decom_routine_obj,tname='spp_spi_AF12', ttags=ttags,save_flag=save_flag,rt_flag=rt_flag
    spp_apdat_info,'387'x,name='spi_af13',apid_obj=decom_routine_obj,tname='spp_spi_AF13', ttags=ttags,save_flag=save_flag,rt_flag=rt_flag
    spp_apdat_info,'388'x,name='spi_af20',apid_obj=decom_routine_obj,tname='spp_spi_AF20', ttags=ttags,save_flag=save_flag,rt_flag=rt_flag
    spp_apdat_info,'389'x,name='spi_af21',apid_obj=decom_routine_obj,tname='spp_spi_AF21', ttags=ttags,save_flag=save_flag,rt_flag=rt_flag
    spp_apdat_info,'38a'x,name='spi_af22',apid_obj=decom_routine_obj,tname='spp_spi_AF22', ttags=ttags,save_flag=save_flag,rt_flag=rt_flag
    spp_apdat_info,'38b'x,name='spi_af23',apid_obj=decom_routine_obj,tname='spp_spi_AF23', ttags=ttags,save_flag=save_flag,rt_flag=rt_flag

    ;;---------------------------------------------- Archive Targeted Sweep Products ------------------------------------------------------
    spp_apdat_info,'38c'x,name='spi_at00',apid_obj=decom_routine_obj,tname='spp_spi_AT00', ttags=ttags,save_flag=save_flag,rt_flag=rt_flag
    spp_apdat_info,'38d'x,name='spi_at01',apid_obj=decom_routine_obj,tname='spp_spi_AT01', ttags=ttags,save_flag=save_flag,rt_flag=rt_flag
    spp_apdat_info,'38e'x,name='spi_at02',apid_obj=decom_routine_obj,tname='spp_spi_AT02', ttags=ttags,save_flag=save_flag,rt_flag=rt_flag
    spp_apdat_info,'38f'x,name='spi_at03',apid_obj=decom_routine_obj,tname='spp_spi_AT03', ttags=ttags,save_flag=save_flag,rt_flag=rt_flag
    spp_apdat_info,'390'x,name='spi_at10',apid_obj=decom_routine_obj,tname='spp_spi_AT10', ttags=ttags,save_flag=save_flag,rt_flag=rt_flag
    spp_apdat_info,'391'x,name='spi_at11',apid_obj=decom_routine_obj,tname='spp_spi_AT11', ttags=ttags,save_flag=save_flag,rt_flag=rt_flag
    spp_apdat_info,'392'x,name='spi_at12',apid_obj=decom_routine_obj,tname='spp_spi_AT12', ttags=ttags,save_flag=save_flag,rt_flag=rt_flag
    spp_apdat_info,'393'x,name='spi_at13',apid_obj=decom_routine_obj,tname='spp_spi_AT13', ttags=ttags,save_flag=save_flag,rt_flag=rt_flag
    spp_apdat_info,'394'x,name='spi_at20',apid_obj=decom_routine_obj,tname='spp_spi_AT20', ttags=ttags,save_flag=save_flag,rt_flag=rt_flag
    spp_apdat_info,'395'x,name='spi_at21',apid_obj=decom_routine_obj,tname='spp_spi_AT21', ttags=ttags,save_flag=save_flag,rt_flag=rt_flag
    spp_apdat_info,'396'x,name='spi_at22',apid_obj=decom_routine_obj,tname='spp_spi_AT22', ttags=ttags,save_flag=save_flag,rt_flag=rt_flag
    spp_apdat_info,'397'x,name='spi_at23',apid_obj=decom_routine_obj,tname='spp_spi_AT23', ttags=ttags,save_flag=save_flag,rt_flag=rt_flag

    ;;------------------------------------------------ Survey Full Sweep Products ---------------------------------------------------------
    spp_apdat_info,'398'x,name='spi_sf00',apid_obj=decom_routine_obj,tname='spp_spi_SF00', ttags=ttags,save_flag=save_flag,rt_flag=rt_flag
    spp_apdat_info,'399'x,name='spi_sf01',apid_obj=decom_routine_obj,tname='spp_spi_SF01', ttags=ttags,save_flag=save_flag,rt_flag=rt_flag
    spp_apdat_info,'39a'x,name='spi_sf02',apid_obj=decom_routine_obj,tname='spp_spi_SF02', ttags=ttags,save_flag=save_flag,rt_flag=rt_flag
    spp_apdat_info,'39b'x,name='spi_sf03',apid_obj=decom_routine_obj,tname='spp_spi_SF03', ttags=ttags,save_flag=save_flag,rt_flag=rt_flag
    spp_apdat_info,'39c'x,name='spi_sf10',apid_obj=decom_routine_obj,tname='spp_spi_SF10', ttags=ttags,save_flag=save_flag,rt_flag=rt_flag
    spp_apdat_info,'39d'x,name='spi_sf11',apid_obj=decom_routine_obj,tname='spp_spi_SF11', ttags=ttags,save_flag=save_flag,rt_flag=rt_flag
    spp_apdat_info,'39e'x,name='spi_sf12',apid_obj=decom_routine_obj,tname='spp_spi_SF12', ttags=ttags,save_flag=save_flag,rt_flag=rt_flag
    spp_apdat_info,'39f'x,name='spi_sf13',apid_obj=decom_routine_obj,tname='spp_spi_SF13', ttags=ttags,save_flag=save_flag,rt_flag=rt_flag
    spp_apdat_info,'3a0'x,name='spi_sf20',apid_obj=decom_routine_obj,tname='spp_spi_SF20', ttags=ttags,save_flag=save_flag,rt_flag=rt_flag
    spp_apdat_info,'3a1'x,name='spi_sf21',apid_obj=decom_routine_obj,tname='spp_spi_SF21', ttags=ttags,save_flag=save_flag,rt_flag=rt_flag
    spp_apdat_info,'3a2'x,name='spi_sf22',apid_obj=decom_routine_obj,tname='spp_spi_SF22', ttags=ttags,save_flag=save_flag,rt_flag=rt_flag
    spp_apdat_info,'3a3'x,name='spi_sf23',apid_obj=decom_routine_obj,tname='spp_spi_SF23', ttags=ttags,save_flag=save_flag,rt_flag=rt_flag

    ;----------------------------------------------  Survey Targeted Sweep Products -------------------------------------------------------
    spp_apdat_info,'3a4'x,name='spi_st00',apid_obj=decom_routine_obj,tname='spp_spi_ST00', ttags=ttags,save_flag=save_flag,rt_flag=rt_flag
    spp_apdat_info,'3a5'x,name='spi_st01',apid_obj=decom_routine_obj,tname='spp_spi_ST01', ttags=ttags,save_flag=save_flag,rt_flag=rt_flag
    spp_apdat_info,'3a6'x,name='spi_st02',apid_obj=decom_routine_obj,tname='spp_spi_ST02', ttags=ttags,save_flag=save_flag,rt_flag=rt_flag
    spp_apdat_info,'3a7'x,name='spi_st03',apid_obj=decom_routine_obj,tname='spp_spi_ST03', ttags=ttags,save_flag=save_flag,rt_flag=rt_flag
    spp_apdat_info,'3a8'x,name='spi_st10',apid_obj=decom_routine_obj,tname='spp_spi_ST10', ttags=ttags,save_flag=save_flag,rt_flag=rt_flag
    spp_apdat_info,'3a9'x,name='spi_st11',apid_obj=decom_routine_obj,tname='spp_spi_ST11', ttags=ttags,save_flag=save_flag,rt_flag=rt_flag
    spp_apdat_info,'3aa'x,name='spi_st12',apid_obj=decom_routine_obj,tname='spp_spi_ST12', ttags=ttags,save_flag=save_flag,rt_flag=rt_flag
    spp_apdat_info,'3ab'x,name='spi_st13',apid_obj=decom_routine_obj,tname='spp_spi_ST13', ttags=ttags,save_flag=save_flag,rt_flag=rt_flag
    spp_apdat_info,'3ac'x,name='spi_st20',apid_obj=decom_routine_obj,tname='spp_spi_ST20', ttags=ttags,save_flag=save_flag,rt_flag=rt_flag
    spp_apdat_info,'3ad'x,name='spi_st21',apid_obj=decom_routine_obj,tname='spp_spi_ST21', ttags=ttags,save_flag=save_flag,rt_flag=rt_flag
    spp_apdat_info,'3ae'x,name='spi_st22',apid_obj=decom_routine_obj,tname='spp_spi_ST22', ttags=ttags,save_flag=save_flag,rt_flag=rt_flag
    spp_apdat_info,'3af'x,name='spi_st23',apid_obj=decom_routine_obj,tname='spp_spi_ST23', ttags=ttags,save_flag=save_flag,rt_flag=rt_flag

  ENDIF


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


  ;;############################################
  ;; SETUP GSE APID
  ;;############################################
  spp_apdat_info,'734'x,name='moc_queue',save_flag=save_flag,rt_flag=rt_flag
  spp_apdat_info,'751'x,name='aps1' ,routine='spp_power_supply_decom',tname='APS1',   save_flag=save_flag,ttags='*P25?',   rt_flag=rt_flag
  spp_apdat_info,'752'x,name='aps2' ,routine='spp_power_supply_decom',tname='APS2',   save_flag=save_flag,ttags='*P25?',   rt_flag=rt_flag
  spp_apdat_info,'753'x,name='aps3' ,routine='spp_power_supply_decom',tname='APS3',   save_flag=save_flag,ttags='*P6? *N25V',   rt_flag=rt_flag
  spp_apdat_info,'754'x,name='aps4' ,routine='spp_power_supply_decom',tname='APS4',   save_flag=save_flag,ttags='P25?',   rt_flag=rt_flag
  spp_apdat_info,'755'x,name='aps5' ,routine='spp_power_supply_decom',tname='APS5',   save_flag=save_flag,ttags='P25?',   rt_flag=rt_flag
  spp_apdat_info,'756'x,name='aps6' ,routine='spp_power_supply_decom',tname='APS6',   save_flag=save_flag,ttags='P25?',   rt_flag=rt_flag
  spp_apdat_info,'761'x,name='bertan1' ,routine='spp_power_supply_decom',tname='Igun',save_flag=save_flag,ttags='*VOLTS *CURRENT',   rt_flag=rt_flag
  spp_apdat_info,'762'x,name='bertan2',routine='spp_power_supply_decom',tname='Egun', save_flag=save_flag,ttags='*VOLTS *CURRENT',   rt_flag=rt_flag
  spp_apdat_info,'7c0'x,name='log_msg',apid_obj='spp_swp_log_msg_apdat'     ,tname='log',  save_flag=save_flag,ttags='MSG SEQN',   rt_flag=rt_flag
  spp_apdat_info,'7c1'x,name='usrlog_msg',apid_obj='spp_swp_log_msg_apdat'     ,tname='usrlog',  save_flag=save_flag,ttags='SEQN MSG',   rt_flag=rt_flag
  ;   spp_apdat_info,'7c0'x,name='log_msg',routine='spp_log_msg_decom'     ,tname='log',  save_flag=save_flag,ttags='MSG',   rt_flag=rt_flag
  ;   spp_apdat_info,'7c1'x,name='usrlog_msg',routine='spp_log_msg_decom'     ,tname='usrlog',  save_flag=save_flag,ttags='SEQN MSG',   rt_flag=rt_flag
  spp_apdat_info,'7c3'x,name='manip', routine='spp_swp_manip_decom'   ,tname='manip', ttags='*',save_flag=save_flag,rt_flag=rt_flag
  spp_apdat_info,'7c4'x,name='swemulator', apid_obj='spp_swp_swemulator_apdat'   ,tname='swemul_tns',ttags='*',save_flag=save_flag,rt_flag=rt_flag
  spp_apdat_info,'7c5'x,name='newmanip', routine = 'spp_swp_newmanip_decom', tname='newmanip', ttags = '*', save_flag = save_flag, rt_flag=rt_flag


  if keyword_set(clear) then spp_apdat_info,/clear

end
