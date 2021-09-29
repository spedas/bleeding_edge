;+
; $LastChangedBy: davin-mac $
; $LastChangedDate: 2021-08-17 02:32:37 -0700 (Tue, 17 Aug 2021) $
; $LastChangedRevision: 30212 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SWFO/STIS/swfo_stis_apdat_init.pro $
;-

pro swfo_stis_apdat_init,reset=reset, save_flag = save_flag, swem=swem, $
  rt_flag= rt_Flag, $
  clear = clear, no_products =no_products

  common swfo_stis_apdat_init, initialized
  if keyword_set(reset) then initialized = 0
  if keyword_set(initialized) then return
  initialized =1
  ;   dprint,dlevel=3,/phelp ,rt_flag,save_flag

  ;; special case to accumulate statistics
  swfo_apdat_info, 0 ,name='Stats',apid_obj='swfo_gen_apdat_stats',tname='APIDS_', ttags=ttags,save_flag=save_flag,rt_flag=rt_flag

  ;;#################
  ;; SETUP SWEM APIDs
  ;;#################
  ttags = 'SEQN*'
;  swfo_apdat_info,'081'x,name='sc_hkp_0x081',apid_obj = 'spp_sc_hk_0x081_apdat', tname = 'spp_sc_hkp_0x081_', save_flag=save_flag,ttags='*',rt_flag=rt_flag
;  swfo_apdat_info,'1c5'x,name='sc_hkp_0x1c5',apid_obj = 'spp_sc_hk_0x1c5_apdat', tname = 'spp_sc_hkp_0x1c5_', save_flag=save_flag,ttags='*',rt_flag=rt_flag
;  swfo_apdat_info,'1de'x,name='sc_hkp_0x1de',apid_obj = 'spp_sc_hk_0x1de_apdat', tname = 'spp_sc_hkp_0x1de_', save_flag=save_flag,ttags='*',rt_flag=rt_flag
;  swfo_apdat_info,'1df'x,name='sc_hkp_0x1df',apid_obj = 'spp_sc_hk_0x1df_apdat', tname = 'spp_sc_hkp_0x1df_', save_flag=save_flag,ttags='*',rt_flag=rt_flag
;  swfo_apdat_info,'254'x,name='sc_hkp_0x254',apid_obj = 'spp_sc_hk_0x254_apdat', tname = 'spp_sc_hkp_0x254_', save_flag=save_flag,ttags='*',rt_flag=rt_flag
;  swfo_apdat_info,'255'x,name='sc_hkp_0x255',apid_obj = 'spp_sc_hk_0x255_apdat', tname = 'spp_sc_hkp_0x255_', save_flag=save_flag,ttags='*',rt_flag=rt_flag
;  swfo_apdat_info,'256'x,name='sc_hkp_0x256',apid_obj = 'spp_sc_hk_0x256_apdat', tname = 'spp_sc_hkp_0x256_', save_flag=save_flag,ttags='*',rt_flag=rt_flag
;  swfo_apdat_info,'257'x,name='sc_hkp_0x257',apid_obj = 'spp_sc_hk_0x257_apdat', tname = 'spp_sc_hkp_0x257_', save_flag=save_flag,ttags='*',rt_flag=rt_flag
;  swfo_apdat_info,'262'x,name='sc_hkp_0x262',apid_obj = 'spp_sc_hk_0x262_apdat', tname = 'spp_sc_hkp_0x262_', save_flag=save_flag,ttags='*',rt_flag=rt_flag

  ; These APIDs are used by the SWEM
  if keyword_set(swem) then begin
    swfo_apdat_info,'340'x,name='swem_crit_hkp',                                      tname='swfo_swem_crit_hkp_', save_flag=save_flag,ttags='*',rt_flag=rt_flag
    swfo_apdat_info,'341'x,name='swem_dig_hkp',  apid_obj='swfo_swp_swem_dhkp_apdat',  tname='swfo_swem_dig_hkp_',  save_flag=save_flag,ttags='*',rt_flag=rt_flag
    swfo_apdat_info,'342'x,name='swem_memdump',  apid_obj='swfo_swp_memdump_apdat',    tname='swfo_swem_memdump_',  save_flag=save_flag,ttags='*',rt_flag=rt_flag
    swfo_apdat_info,'343'x,name='swem_ana_hkp',  apid_obj='swfo_swp_swem_hkp_apdat',   tname='swfo_swem_ana_hkp_',  save_flag=save_flag,ttags='*',rt_flag=rt_flag
    swfo_apdat_info,'344'x,name='swem_event_log',apid_obj='swfo_swp_swem_events_apdat',tname='swfo_swem_event_log_',save_flag=save_flag,ttags='*',rt_flag=rt_flag
    swfo_apdat_info,'345'x,name='swem_cmd_echo',                                      tname='swfo_swem_cmd_echo_', save_flag=save_flag,ttags='*',rt_flag=rt_flag
    swfo_apdat_info,'346'x,name='swem_timing',   apid_obj='swfo_swp_swem_timing_apdat',tname='swfo_swem_timing_',   save_flag=save_flag,ttags='*',rt_flag=rt_flag
    swfo_apdat_info,'347'x,name='swem_memdwell',                                      tname='swfo_swem_memdwell_', save_flag=save_flag,ttags='*',rt_flag=rt_flag

    swfo_apdat_info,'348'x,name='wrp_P2rt',apid_obj='swfo_swp_wrapper_apdat',tname='swfo_wrp_348_P2rt_',ttags='*',save_flag=save_flag,rt_flag=rt_flag
    swfo_apdat_info,'349'x,name='wrp_P2',  apid_obj='swfo_swp_wrapper_apdat',tname='swfo_wrp_349_P2_',  ttags='*',save_flag=save_flag,rt_flag=rt_flag
    swfo_apdat_info,'34A'x,name='wrp_P3rt',apid_obj='swfo_swp_wrapper_apdat',tname='swfo_wrp_34A_P3rt_',ttags='*',save_flag=save_flag,rt_flag=rt_flag
    swfo_apdat_info,'34b'x,name='wrp_P3',  apid_obj='swfo_swp_wrapper_apdat',tname='swfo_wrp_34B_P3_',  ttags='*',save_flag=save_flag,rt_flag=rt_flag
    swfo_apdat_info,'34c'x,name='wrp_P4rt',apid_obj='swfo_swp_wrapper_apdat',tname='swfo_wrp_34C_P4rt_',ttags='*',save_flag=save_flag,rt_flag=rt_flag
    swfo_apdat_info,'34d'x,name='wrp_P4',  apid_obj='swfo_swp_wrapper_apdat',tname='swfo_wrp_34D_P4_',  ttags='*',save_flag=save_flag,rt_flag=rt_flag
    swfo_apdat_info,'34e'x,name='wrp_P5P7',apid_obj='swfo_swp_wrapper_apdat',tname='swfo_wrp_34E_P5P7_',ttags='*',save_flag=save_flag,rt_flag=rt_flag
    swfo_apdat_info,'34f'x,name='wrp_P8',  apid_obj='swfo_swp_wrapper_apdat',tname='swfo_wrp_34F_P8_',  ttags='*',save_flag=save_flag,rt_flag=rt_flag
    
  endif


  ;;################
  ;;#   STIS APIDs  #
  ;;################
  swfo_apdat_info,'350'x,name='stis_sci', apid_obj='swfo_stis_sci_apdat',         tname='swfo_stis_sci_',ttags='*',save_flag=save_flag,rt_flag=rt_flag
  swfo_apdat_info,'351'x,name='stis_nse', apid_obj='swfo_stis_nse_apdat',    tname='swfo_stis_nse_',ttags='*',save_flag=save_flag,rt_flag=rt_flag
  swfo_apdat_info,'35d'x,name='stis_mem', apid_obj='swfo_stis_memdump_apdat', tname='swfo_stis_mem_',ttags='*',save_flag=save_flag,rt_flag=rt_flag
  swfo_apdat_info,'35E'x,name='stis_hkp1', apid_obj='swfo_stis_hkp_apdat', tname='swfo_stis_hkp1_',ttags='*',save_flag=save_flag,rt_flag=rt_flag
  swfo_apdat_info,'35F'x,name='stis_hkp2', apid_obj='swfo_stis_hkp_apdat', tname='swfo_stis_hkp2_',ttags='*',    save_flag=save_flag,rt_flag=rt_flag



  ;;############################################
  ;; SETUP GSE APID
  ;;############################################
  ;swfo_apdat_info,'751'x,name='aps1' ,routine='spp_power_supply_decom',tname='APS1_',   save_flag=save_flag,ttags='*P25?',   rt_flag=rt_flag
  ;swfo_apdat_info,'752'x,name='aps2' ,routine='spp_power_supply_decom',tname='APS2_',   save_flag=save_flag,ttags='*P25?',   rt_flag=rt_flag
  ;swfo_apdat_info,'753'x,name='aps3' ,routine='spp_power_supply_decom',tname='APS3_',   save_flag=save_flag,ttags='*P6? *N25V',   rt_flag=rt_flag
  ;swfo_apdat_info,'754'x,name='aps4' ,routine='spp_power_supply_decom',tname='APS4_',   save_flag=save_flag,ttags='P25?',   rt_flag=rt_flag
  ;swfo_apdat_info,'755'x,name='aps5' ,routine='spp_power_supply_decom',tname='APS5_',   save_flag=save_flag,ttags='P25?',   rt_flag=rt_flag
  ;swfo_apdat_info,'756'x,name='aps6' ,routine='spp_power_supply_decom',tname='APS6_',   save_flag=save_flag,ttags='P25?',   rt_flag=rt_flag
  ;swfo_apdat_info,'761'x,name='bertan1' ,routine='spp_power_supply_decom',tname='Igun_',save_flag=save_flag,ttags='*VOLTS *CURRENT',   rt_flag=rt_flag
  ;swfo_apdat_info,'762'x,name='bertan2',routine='spp_power_supply_decom',tname='Egun_', save_flag=save_flag,ttags='*VOLTS *CURRENT',   rt_flag=rt_flag
  swfo_apdat_info,'7c0'x,name='log_msg',apid_obj='swfo_stis_log_msg_apdat'     ,tname='log_',  save_flag=save_flag,ttags='MSG SEQN',   rt_flag=rt_flag
  ;swfo_apdat_info,'7c1'x,name='usrlog_msg',apid_obj='swfo_stis_log_msg_apdat'     ,tname='usrlog_',  save_flag=save_flag,ttags='SEQN MSG',   rt_flag=rt_flag
  ;   swfo_apdat_info,'7c0'x,name='log_msg',routine='spp_log_msg_decom'     ,tname='log_',  save_flag=save_flag,ttags='MSG',   rt_flag=rt_flag
  ;   swfo_apdat_info,'7c1'x,name='usrlog_msg',routine='spp_log_msg_decom'     ,tname='usrlog_',  save_flag=save_flag,ttags='SEQN MSG',   rt_flag=rt_flag
  ;swfo_apdat_info,'7c3'x,name='manip', routine='spp_swp_manip_decom'   ,tname='manip_', ttags='*POS',save_flag=save_flag,rt_flag=rt_flag
  swfo_apdat_info,'7c4'x,name='swemulator', apid_obj='swfo_stis_swemulator_apdat'   ,tname='swemul_tns_',ttags='*',save_flag=save_flag,rt_flag=rt_flag


  if keyword_set(clear) then swfo_apdat_info,/clear

end
