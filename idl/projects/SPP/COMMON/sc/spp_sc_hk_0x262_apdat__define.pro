;Ali: June 2020
;+
; $LastChangedBy: ali $
; $LastChangedDate: 2020-06-16 08:55:23 -0700 (Tue, 16 Jun 2020) $
; $LastChangedRevision: 28779 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SPP/COMMON/sc/spp_sc_hk_0x262_apdat__define.pro $
;-

function spp_SC_HK_0x262_struct,ccsds_data
  if n_elements(ccsds_data) eq 0 then ccsds_data = bytarr(67)

  str = {time:!values.d_nan ,$
    met:!values.d_nan, $
    seqn: 0u, $
    pkt_size: 0u, $
    SWEAP_CRIT_SW_58:spp_swp_data_select(ccsds_data,58*8,8), $
    SWEAP_CRIT_SW_EVENT_CNTR:spp_swp_data_select(ccsds_data,59*8,4), $
    SWEAP_CRIT_SW_59:spp_swp_data_select(ccsds_data,59*8+7-3,4), $
    SWEAP_CRIT_SW_LAST_FSW_EVENT:spp_swp_data_select(ccsds_data,60*8,4), $
    SWEAP_CRIT_SW_60:spp_swp_data_select(ccsds_data,60*8+7-3,4), $
    SWEAP_CRIT_SW_SWEM3P3V:0.016422288*spp_swp_data_select(ccsds_data,61*8,8), $ ; 61,    7,    8;
    SWEAP_CRIT_SW_SPANAI:spp_swp_data_select(ccsds_data,62*8,4), $
    SWEAP_CRIT_SW_SPANAI_HV_MODE:spp_swp_data_select(ccsds_data,62*8+7-3,4), $
    SWEAP_CRIT_SW_SPANAE:spp_swp_data_select(ccsds_data,63*8,4), $
    SWEAP_CRIT_SW_SPANAE_HV_MODE:spp_swp_data_select(ccsds_data,63*8+7-3,4), $
    SWEAP_CRIT_SW_SPANB:spp_swp_data_select(ccsds_data,64*8,4), $
    SWEAP_CRIT_SW_SPANB_HV_MODE:spp_swp_data_select(ccsds_data,64*8+7-3,4), $
    SWEAP_CRIT_SW_SPC:spp_swp_data_select(ccsds_data,65*8,4), $
    SWEAP_CRIT_SW_SPC_ERR_CNTR:spp_swp_data_select(ccsds_data,65*8+7-3,4), $
    gap:0B}
  return, str
end

;SWEAP_CRIT_SW_OVERCURR_DETECT,                                 58,    7,    1;
;SWEAP_CRIT_SW_ACTR_PWR,                                        58,    6,    1;
;SWEAP_CRIT_SW_SPANB_HTR,                                       58,    5,    1;
;SWEAP_CRIT_SW_SPANA_HTR,                                       58,    4,    1;
;SWEAP_CRIT_SW_SPANB_PWR,                                       58,    3,    1;
;SWEAP_CRIT_SW_SPANAE_PWR,                                      58,    2,    1;
;SWEAP_CRIT_SW_SPANAI_PWR,                                      58,    1,    1;
;SWEAP_CRIT_SW_SPC_PWR,                                         58,    0,    1;
;SWEAP_CRIT_SW_EVENT_CNTR,                                      59,    7,    4;
;SWEAP_CRIT_SW_FLASH_PLBK_IN_PROGRESS,                          59,    3,    1;
;SWEAP_CRIT_SW_FIELDS_CLOCK,                                    59,    2,    1;
;SWEAP_CRIT_SW_LINK_A_ACTIVE,                                   59,    1,    1;
;SWEAP_CRIT_SW_LINK_B_ACTIVE,                                   59,    0,    1;
;SWEAP_CRIT_SW_LAST_FSW_EVENT,                                  60,    7,    4;
;SWEAP_CRIT_SW_OP_OVERRUN,                                      60,    3,    1;
;SWEAP_CRIT_SW_FSW_CSCI,                                        60,    2,    1;
;SWEAP_CRIT_SW_BOOT_MODE,                                       60,    1,    1;
;SWEAP_CRIT_SW_WDOG_RESET_DETECTED,                             60,    0,    1;
;SWEAP_CRIT_SW_SWEM3P3V,                                        61,    7,    8;
;SWEAP_CRIT_SW_SPANAI_HK_MON_TRIP,                              62,    7,    1;
;SWEAP_CRIT_SW_SPANAI_CVR_OR_EOT1_EOT2,                         62,    6,    1;
;SWEAP_CRIT_SW_SPANAI_ATT_OR_IN1_IN2,                           62,    5,    1;
;SWEAP_CRIT_SW_SPANAI_HV_ENABLED,                               62,    4,    1;
;SWEAP_CRIT_SW_SPANAI_HV_MODE,                                  62,    3,    4;
;SWEAP_CRIT_SW_SPANAE_HK_MON_TRIP,                              63,    7,    1;
;SWEAP_CRIT_SW_SPANAE_CVR_OR_EOT1_EOT2,                         63,    6,    1;
;SWEAP_CRIT_SW_SPANAE_ATT_OR_IN1_IN2,                           63,    5,    1;
;SWEAP_CRIT_SW_SPANAE_HV_ENABLED,                               63,    4,    1;
;SWEAP_CRIT_SW_SPANAE_HV_MODE,                                  63,    3,    4;
;SWEAP_CRIT_SW_SPANB_HK_MON_TRIP,                               64,    7,    1;
;SWEAP_CRIT_SW_SPANB_CVR_OR_EOT1_EOT2,                          64,    6,    1;
;SWEAP_CRIT_SW_SPANB_ATT_OR_IN1_IN2,                            64,    5,    1;
;SWEAP_CRIT_SW_SPANB_HV_ENABLED,                                64,    4,    1;
;SWEAP_CRIT_SW_SPANB_HV_MODE,                                   64,    3,    4;
;SWEAP_CRIT_SW_SPC_MODE,                                        65,    7,    1;
;SWEAP_CRIT_SW_SPC_HV_ENABLED,                                  65,    6,    1;
;SWEAP_CRIT_SW_SPC_OR_ELEC_FA_CALON,                            65,    5,    1;
;SWEAP_CRIT_SW_SPC_RAIL_DAC_GT_LIMIT,                           65,    4,    1;
;SWEAP_CRIT_SW_SPC_ERR_CNTR,                                    65,    3,    4;

function SPP_SC_HK_0x262_apdat::decom,ccsds, source_dict=source_dict   ;,ptp_header=ptp_header

  ccsds_data = spp_swp_ccsds_data(ccsds)
  str2 = spp_SC_HK_0x262_struct(ccsds_data)
  struct_assign,ccsds,str2,/nozero
  return,str2

end


pro spp_SC_HK_0x262_apdat__define

  void = {spp_SC_HK_0x262_apdat, $
    inherits spp_gen_apdat, $    ; superclass
    flag: 0 $
  }
end

;
;#
;# SC_HK_0x262
;#
;SC_HK_0x262
;{
;( Block[67],                                                       ,     ,    8; )
;FSW_HK_HK_INST_TPPH_VERSION,                                    0,    7,    3;
;FSW_HK_HK_INST_TPPH_TYPE,                                       0,    4,    1;
;FSW_HK_HK_INST_TPPH_SEC_HDR_FLAG,                               0,    3,    1;
;FSW_HK_HK_INST_TPPH_APID,                                       0,    2,   11;
;SC_D_APID,                                                      0,    2,   11;
;FSW_HK_HK_INST_TPPH_SEQ_FLAGS,                                  2,    7,    2;
;FSW_HK_HK_INST_TPPH_SEQ_CNT,                                    2,    5,   14;
;FSW_HK_HK_INST_TPPH_LENGTH,                                     4,    7,   16;
;FSW_HK_HK_INST_TPSH_MET_SEC,                                    6,    7,   32;
;SC_D_MET_SEC,                                                   6,    7,   32;
;FSW_HK_HK_INST_TPSH_MET_SUBSEC,                                10,    7,    8;
;FSW_HK_HK_INST_TPSH_SBC_PHYS_ID,                               11,    7,    2;
;FIELDS1_CRIT_DCB_FPGA_TEMP,                                    12,    7,    8;
;FIELDS1_CRIT_DCB_TEMP,                                         13,    7,    8;
;FIELDS1_CRIT_LNPS1_4V,                                         14,    7,    8;
;FIELDS1_CRIT_DCB_3P3V,                                         15,    7,    8;
;FIELDS1_CRIT_LNPS1_3P3V,                                       16,    7,    8;
;FIELDS1_CRIT_AEB1_TEMP,                                        17,    7,    8;
;FIELDS1_CRIT_DFB_TEMP,                                         18,    7,    8;
;FIELDS1_CRIT_SCM_TEMP,                                         19,    7,    8;
;FIELDS1_CRIT_LNPS1_TEMP,                                       20,    7,    8;
;FIELDS1_CRIT_LNPS1_6V,                                         21,    7,    8;
;FIELDS1_CRIT_MAGO_SENSR_TEMP,                                  22,    7,    8;
;FIELDS1_CRIT_MAGO_PCB_TEMP,                                    23,    7,    8;
;FIELDS2_CRIT_LNPS2_6V,                                         24,    7,    8;
;FIELDS2_CRIT_LVDS_3P3V,                                        25,    7,    8;
;FIELDS2_CRIT_LVDS_ZENER,                                       26,    7,    8;
;FIELDS2_CRIT_LNPS2_3P3V,                                       27,    7,    8;
;FIELDS2_CRIT_TDS_FPGA_TEMP,                                    28,    7,    8;
;FIELDS2_CRIT_AEB2_TEMP,                                        29,    7,    8;
;FIELDS2_CRIT_LNPS2_TEMP,                                       30,    7,    8;
;FIELDS2_CRIT_MAGI_SENSR_TEMP,                                  31,    7,    8;
;FIELDS2_CRIT_MAGI_PCB_TEMP,                                    32,    7,    8;
;WISPR_CRIT_PAGE_0X40,                                          33,    7,    1;
;WISPR_CRIT_PAGE_0X41,                                          33,    6,    1;
;WISPR_CRIT_PAGE_0X42,                                          33,    5,    1;
;WISPR_CRIT_AUT_LEVEL,                                          33,    4,    2;
;WISPR_CRIT_SPARE_BIT_1_DECOM,                                  33,    2,    1;
;WISPR_CRIT_WIM_CMD_OFF_BY_AUT_RULE,                            33,    1,    1;
;WISPR_CRIT_WIM_PWR,                                            33,    0,    1;
;WISPR_CRIT_AUTONOMY_RULE_TRIGGER_CNTR,                         34,    7,    8;
;WISPR_CRIT_LAST_AUTONOMY_RULE_TRIGGERED_ID,                    35,    7,    8;
;WISPR_CRIT_PREVIOUS_AUTONOMY_RULE_TRIGGERED_ICD,               36,    7,    8;
;WISPR_CRIT_IT_DETECTOR_TEMP,                                   37,    7,   16;
;WISPR_CRIT_OT_DETECTOR_TEMP,                                   39,    7,   16;
;EPI_HI_CRIT_PRIMARY_SIDE_INSTRUMENT_CURR,                      41,    7,    4;
;EPI_HI_CRIT_LET1_TELESCOPE_TEMP,                               41,    3,    4;
;EPI_HI_CRIT_LET2_TELESCOPE_TEMP,                               42,    7,    4;
;EPI_HI_CRIT_HET_TELESCOPE_TEMP,                                42,    3,    4;
;EPI_HI_CRIT_LVPS_TEMP,                                         43,    7,    4;
;EPI_HI_CRIT_DPU_TEMP,                                          43,    3,    4;
;EPI_HI_CRIT_LET1_TRIGGER_RATE,                                 44,    7,    4;
;EPI_HI_CRIT_LET2_TRIGGER_RATE,                                 44,    3,    4;
;EPI_HI_CRIT_HET_TRIGGER_RATE,                                  45,    7,    4;
;EPI_HI_CRIT_LET1_EVENT_RATE,                                   45,    3,    4;
;EPI_HI_CRIT_LET2_EVENT_RATE,                                   46,    7,    4;
;EPI_HI_CRIT_HET_EVENT_RATE,                                    46,    3,    4;
;EPI_HI_CRIT_LVPS_STATUS,                                       47,    7,    1;
;EPI_HI_CRIT_CODE_STATUS,                                       47,    6,    1;
;EPI_HI_CRIT_LET1_DYNAMIC_THRSHLD_STATE,                        47,    5,    2;
;EPI_HI_CRIT_LET2_DYNAMIC_THRSHLD_STATE,                        47,    3,    2;
;EPI_HI_CRIT_HET_DYNAMIC_THRSHLD_STATE,                         47,    1,    2;
;EPI_HI_CRIT_SPARE_BYTE_1_DECOM,                                48,    7,    8;
;EPI_LO_CRIT_ALARM_ID,                                          49,    7,    8;
;EPI_LO_CRIT_ALARM_TYPE,                                        50,    7,    1;
;EPI_LO_CRIT_ALARM_CNT,                                         50,    6,    7;
;EPI_LO_CRIT_ADC_2_5,                                           51,    7,    8;
;EPI_LO_CRIT_ADC_2_3,                                           52,    7,    8;
;EPI_LO_CRIT_ADC_3_5,                                           53,    7,    8;
;EPI_LO_CRIT_ADC_0_3,                                           54,    7,    8;
;EPI_LO_CRIT_START1_RATE,                                       55,    7,    8;
;EPI_LO_CRIT_STOP_RATE,                                         56,    7,    8;
;EPI_LO_CRIT_ENERGY_RATE,                                       57,    7,    8;
;SWEAP_CRIT_SW_OVERCURR_DETECT,                                 58,    7,    1;
;SWEAP_CRIT_SW_ACTR_PWR,                                        58,    6,    1;
;SWEAP_CRIT_SW_SPANB_HTR,                                       58,    5,    1;
;SWEAP_CRIT_SW_SPANA_HTR,                                       58,    4,    1;
;SWEAP_CRIT_SW_SPANB_PWR,                                       58,    3,    1;
;SWEAP_CRIT_SW_SPANAE_PWR,                                      58,    2,    1;
;SWEAP_CRIT_SW_SPANAI_PWR,                                      58,    1,    1;
;SWEAP_CRIT_SW_SPC_PWR,                                         58,    0,    1;
;SWEAP_CRIT_SW_EVENT_CNTR,                                      59,    7,    4;
;SWEAP_CRIT_SW_FLASH_PLBK_IN_PROGRESS,                          59,    3,    1;
;SWEAP_CRIT_SW_FIELDS_CLOCK,                                    59,    2,    1;
;SWEAP_CRIT_SW_LINK_A_ACTIVE,                                   59,    1,    1;
;SWEAP_CRIT_SW_LINK_B_ACTIVE,                                   59,    0,    1;
;SWEAP_CRIT_SW_LAST_FSW_EVENT,                                  60,    7,    4;
;SWEAP_CRIT_SW_OP_OVERRUN,                                      60,    3,    1;
;SWEAP_CRIT_SW_FSW_CSCI,                                        60,    2,    1;
;SWEAP_CRIT_SW_BOOT_MODE,                                       60,    1,    1;
;SWEAP_CRIT_SW_WDOG_RESET_DETECTED,                             60,    0,    1;
;SWEAP_CRIT_SW_SWEM3P3V,                                        61,    7,    8;
;SWEAP_CRIT_SW_SPANAI_HK_MON_TRIP,                              62,    7,    1;
;SWEAP_CRIT_SW_SPANAI_CVR_OR_EOT1_EOT2,                         62,    6,    1;
;SWEAP_CRIT_SW_SPANAI_ATT_OR_IN1_IN2,                           62,    5,    1;
;SWEAP_CRIT_SW_SPANAI_HV_ENABLED,                               62,    4,    1;
;SWEAP_CRIT_SW_SPANAI_HV_MODE,                                  62,    3,    4;
;SWEAP_CRIT_SW_SPANAE_HK_MON_TRIP,                              63,    7,    1;
;SWEAP_CRIT_SW_SPANAE_CVR_OR_EOT1_EOT2,                         63,    6,    1;
;SWEAP_CRIT_SW_SPANAE_ATT_OR_IN1_IN2,                           63,    5,    1;
;SWEAP_CRIT_SW_SPANAE_HV_ENABLED,                               63,    4,    1;
;SWEAP_CRIT_SW_SPANAE_HV_MODE,                                  63,    3,    4;
;SWEAP_CRIT_SW_SPANB_HK_MON_TRIP,                               64,    7,    1;
;SWEAP_CRIT_SW_SPANB_CVR_OR_EOT1_EOT2,                          64,    6,    1;
;SWEAP_CRIT_SW_SPANB_ATT_OR_IN1_IN2,                            64,    5,    1;
;SWEAP_CRIT_SW_SPANB_HV_ENABLED,                                64,    4,    1;
;SWEAP_CRIT_SW_SPANB_HV_MODE,                                   64,    3,    4;
;SWEAP_CRIT_SW_SPC_MODE,                                        65,    7,    1;
;SWEAP_CRIT_SW_SPC_HV_ENABLED,                                  65,    6,    1;
;SWEAP_CRIT_SW_SPC_OR_ELEC_FA_CALON,                            65,    5,    1;
;SWEAP_CRIT_SW_SPC_RAIL_DAC_GT_LIMIT,                           65,    4,    1;
;SWEAP_CRIT_SW_SPC_ERR_CNTR,                                    65,    3,    4;
;FSW_SPP_FIELDS1_SHARED_DATA_RCVD,                              66,    7,    1;
;FSW_SPP_FIELDS2_SHARED_DATA_RCVD,                              66,    6,    1;
;FSW_SPP_WISPR_SHARED_DATA_RCVD,                                66,    5,    1;
;FSW_SPP_ISIS_EPI_HI_SHARED_DATA_RCVD,                          66,    4,    1;
;FSW_SPP_ISIS_EPI_LO_SHARED_DATA_RCVD,                          66,    3,    1;
;FSW_SPP_SWEAP_SHARED_DATA_RCVD,                                66,    2,    1;
;SC_HK_INST_DERIVED_TRIGGER_PT,                                 66,    2,    1;
;}
