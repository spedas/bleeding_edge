;Ali: June 2020
;+
; $LastChangedBy: ali $
; $LastChangedDate: 2020-08-10 12:14:20 -0700 (Mon, 10 Aug 2020) $
; $LastChangedRevision: 29012 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SPP/COMMON/sc/spp_sc_hk_0x081_apdat__define.pro $
;-

function spp_SC_HK_0x081_struct,ccsds_data
  if n_elements(ccsds_data) eq 0 then ccsds_data = bytarr(67)

  str = {time:!values.d_nan ,$
    met:!values.d_nan, $
    seqn: 0u, $
    pkt_size: 0u, $
    PDU_SWEAP_SPC_SURV_HTR_BRKR_TRIP_STATE:spp_swp_data_select(ccsds_data,37*8+7-1,1), $
    PDU_SWEAP_SPC_SURV_HTR_PWR_SET_STATE:spp_swp_data_select(ccsds_data,37*8+7-0,1), $
    PDU_SWEAP_SPC_SURV_HTR_PWR_STATE:spp_swp_data_select(ccsds_data,37*8+7-1,2), $
    PDU_SWEAP_SPC_SURV_HTR_CURR:interp([-0.2815494183296126, 0.311373041137364, 2.122413461396678],[0.0, 101.5, 255.0],spp_swp_data_select(ccsds_data,40*8+7-7,8)), $
    gap:0B}
  return, str
end

;PDU_SWEAP_SPC_SURV_HTR_BRKR_TRIP_STATE,                        37,    1,    1;
;PDU_SWEAP_SPC_SURV_HTR_PWR_SET_STATE,                          37,    0,    1;
;PDU_SWEAP_SPC_SURV_HTR_PWR_STATE,                              37,    1,    2;
;PDU_SWEAP_SPC_SURV_HTR_CURR,                                   40,    7,    8;
;EU(Raw='SC_HK_0x081.PDU_SWEAP_SPC_SURV_HTR_CURR') := fCalCurve([0.0, 101.5, 255.0], [-0.2815494183296126, 0.311373041137364, 2.122413461396678], Raw)

function SPP_SC_HK_0x081_apdat::decom,ccsds, source_dict=source_dict   ;,ptp_header=ptp_header

  ccsds_data = spp_swp_ccsds_data(ccsds)
  str2 = spp_SC_HK_0x081_struct(ccsds_data)
  struct_assign,ccsds,str2,/nozero
  return,str2

end


pro spp_SC_HK_0x081_apdat__define

  void = {spp_SC_HK_0x081_apdat, $
    inherits spp_gen_apdat, $    ; superclass
    flag: 0 $
  }
end
;
;
;SC_HK_0x081
;{
;( Block[54],                                                       ,     ,    8; )
;PDU_PRIO94_TPPH_VERSION,                                        0,    7,    3;
;PDU_PRIO94_TPPH_TYPE,                                           0,    4,    1;
;PDU_PRIO94_TPPH_SEC_HDR_FLAG,                                   0,    3,    1;
;PDU_PRIO94_TPPH_APID,                                           0,    2,   11;
;SC_D_APID,                                                      0,    2,   11;
;PDU_PRIO94_TPPH_SEQ_FLAGS,                                      2,    7,    2;
;PDU_PRIO94_TPPH_SEQ_CNT,                                        2,    5,   14;
;PDU_PRIO94_TPPH_LENGTH,                                         4,    7,   16;
;PDU_PRIO94_TPSH_MET_SEC,                                        6,    7,   32;
;SC_D_MET_SEC,                                                   6,    7,   32;
;PDU_PRIO94_TPSH_MET_SUBSEC,                                    10,    7,    8;
;PDU_PRIO94_TPSH_SBC_PHYS_ID,                                   11,    7,    2;
;PDU_PRIO94_ITF_HDR_COMPONENT_ID,                               12,    7,    5;
;PDU_PRIO94_ITF_HDR_REM_PATH,                                   12,    2,    3;
;PDU_PRIO94_ITF_HDR_PHYSICAL_ID,                                13,    7,    4;
;PDU_PRIO94_ITF_HDR_LOGICAL_ID,                                 13,    3,    4;
;PDU_PRIO94_READ_LOC,                                           14,    5,    6;
;PDU_PRIO94_HEALTH_CNT,                                         15,    7,    8;
;PDU_PRIO94_DIO_7_0,                                            16,    7,    8;
;PDU_PRIO94_DIO7,                                               16,    7,    1;
;PDU_PRIO94_DIO6,                                               16,    6,    1;
;PDU_PRIO94_DIO5,                                               16,    5,    1;
;PDU_PRIO94_DIO4,                                               16,    4,    1;
;PDU_PRIO94_DIO3,                                               16,    3,    1;
;PDU_PRIO94_DIO2,                                               16,    2,    1;
;PDU_PRIO94_DIO1,                                               16,    1,    1;
;PDU_PRIO94_DIO0,                                               16,    0,    1;
;PDU_PRIO94_DIO_15_8,                                           17,    7,    8;
;PDU_PRIO94_DIO15,                                              17,    7,    1;
;PDU_PRIO94_DIO14,                                              17,    6,    1;
;PDU_PRIO94_DIO13,                                              17,    5,    1;
;PDU_PRIO94_DIO12,                                              17,    4,    1;
;PDU_PRIO94_DIO11,                                              17,    3,    1;
;PDU_PRIO94_DIO10,                                              17,    2,    1;
;PDU_PRIO94_DIO9,                                               17,    1,    1;
;PDU_PRIO94_DIO8,                                               17,    0,    1;
;PDU_PRIO94_PDC_7_0,                                            18,    7,    8;
;PDU_PRIO94_PDC7,                                               18,    7,    1;
;PDU_PRIO94_PDC6,                                               18,    6,    1;
;PDU_PRIO94_PDC5,                                               18,    5,    1;
;PDU_PRIO94_PDC4,                                               18,    4,    1;
;PDU_PRIO94_PDC3,                                               18,    3,    1;
;PDU_PRIO94_PDC2,                                               18,    2,    1;
;PDU_PRIO94_PDC1,                                               18,    1,    1;
;PDU_PRIO94_PDC0,                                               18,    0,    1;
;PDU_PRIO94_PDC_15_8,                                           19,    7,    8;
;PDU_PRIO94_PDC15,                                              19,    7,    1;
;PDU_PRIO94_PDC14,                                              19,    6,    1;
;PDU_PRIO94_PDC13,                                              19,    5,    1;
;PDU_PRIO94_PDC12,                                              19,    4,    1;
;PDU_PRIO94_PDC11,                                              19,    3,    1;
;PDU_PRIO94_PDC10,                                              19,    2,    1;
;PDU_PRIO94_PDC9,                                               19,    1,    1;
;PDU_PRIO94_PDC8,                                               19,    0,    1;
;PDU_PRIO94_PORT_STATIC_LEVEL_3_0,                              20,    7,    8;
;PDU_PRIO94_PORT_STATIC_LEVEL_MASK3,                            20,    7,    1;
;PDU_PRIO94_PORT_STATIC_LEVEL_MASK2,                            20,    6,    1;
;PDU_PRIO94_PORT_STATIC_LEVEL_MASK1,                            20,    5,    1;
;PDU_PRIO94_PORT_STATIC_LEVEL_MASK0,                            20,    4,    1;
;PDU_PRIO94_PORT_STATIC_LEVEL3,                                 20,    3,    1;
;PDU_PRIO94_PORT_STATIC_LEVEL2,                                 20,    2,    1;
;PDU_PRIO94_PORT_STATIC_LEVEL1,                                 20,    1,    1;
;PDU_PRIO94_PORT_STATIC_LEVEL0,                                 20,    0,    1;
;PDU_PRIO94_PORT_STATIC_LEVEL_7_4,                              21,    7,    8;
;PDU_PRIO94_PORT_STATIC_LEVEL_MASK7,                            21,    7,    1;
;PDU_PRIO94_PORT_STATIC_LEVEL_MASK6,                            21,    6,    1;
;PDU_PRIO94_PORT_STATIC_LEVEL_MASK5,                            21,    5,    1;
;PDU_PRIO94_PORT_STATIC_LEVEL_MASK4,                            21,    4,    1;
;PDU_PRIO94_PORT_STATIC_LEVEL7,                                 21,    3,    1;
;PDU_PRIO94_PORT_STATIC_LEVEL6,                                 21,    2,    1;
;PDU_PRIO94_PORT_STATIC_LEVEL5,                                 21,    1,    1;
;PDU_PRIO94_PORT_STATIC_LEVEL4,                                 21,    0,    1;
;PDU_PRIO94_PORT_STATIC_LEVEL_11_8,                             22,    7,    8;
;PDU_PRIO94_PORT_STATIC_LEVEL_MASK11,                           22,    7,    1;
;PDU_PRIO94_PORT_STATIC_LEVEL_MASK10,                           22,    6,    1;
;PDU_PRIO94_PORT_STATIC_LEVEL_MASK9,                            22,    5,    1;
;PDU_PRIO94_PORT_STATIC_LEVEL_MASK8,                            22,    4,    1;
;PDU_PRIO94_PORT_STATIC_LEVEL11,                                22,    3,    1;
;PDU_PRIO94_PORT_STATIC_LEVEL10,                                22,    2,    1;
;PDU_PRIO94_PORT_STATIC_LEVEL9,                                 22,    1,    1;
;PDU_PRIO94_PORT_STATIC_LEVEL8,                                 22,    0,    1;
;PDU_PRIO94_PORT_STATIC_LEVEL_15_12,                            23,    7,    8;
;PDU_PRIO94_PORT_STATIC_LEVEL_MASK15,                           23,    7,    1;
;PDU_PRIO94_PORT_STATIC_LEVEL_MASK14,                           23,    6,    1;
;PDU_PRIO94_PORT_STATIC_LEVEL_MASK13,                           23,    5,    1;
;PDU_PRIO94_PORT_STATIC_LEVEL_MASK12,                           23,    4,    1;
;PDU_PRIO94_PORT_STATIC_LEVEL15,                                23,    3,    1;
;PDU_PRIO94_PORT_STATIC_LEVEL14,                                23,    2,    1;
;PDU_PRIO94_PORT_STATIC_LEVEL13,                                23,    1,    1;
;PDU_PRIO94_PORT_STATIC_LEVEL12,                                23,    0,    1;
;PDU_PRIO94_PRESCALAR_LSB,                                      24,    7,    8;
;PDU_PRIO94_PRESCALAR_MSB,                                      25,    3,    4;
;PDU_PRIO94_PULSED_OUTPUT_MODE0,                                26,    7,    1;
;PDU_PRIO94_PULSED_OUTPUT_WIDTH0,                               26,    6,    7;
;PDU_PRIO94_PULSED_OUTPUT_MODE1,                                27,    7,    1;
;PDU_PRIO94_PULSED_OUTPUT_WIDTH1,                               27,    6,    7;
;PDU_PRIO94_PULSED_OUTPUT_MODE2,                                28,    7,    1;
;PDU_PRIO94_PULSED_OUTPUT_WIDTH2,                               28,    6,    7;
;PDU_PRIO94_PULSED_OUTPUT_MODE3,                                29,    7,    1;
;PDU_PRIO94_PULSED_OUTPUT_WIDTH3,                               29,    6,    7;
;PDU_PRIO94_PULSED_OUTPUT_MODE4,                                30,    7,    1;
;PDU_PRIO94_PULSED_OUTPUT_WIDTH4,                               30,    6,    7;
;PDU_PRIO94_PULSED_OUTPUT_MODE5,                                31,    7,    1;
;PDU_PRIO94_PULSED_OUTPUT_WIDTH5,                               31,    6,    7;
;PDU_PRIO94_PULSED_OUTPUT_MODE6,                                32,    7,    1;
;PDU_PRIO94_PULSED_OUTPUT_WIDTH6,                               32,    6,    7;
;PDU_PRIO94_PULSED_OUTPUT_MODE7,                                33,    7,    1;
;PDU_PRIO94_PULSED_OUTPUT_WIDTH7,                               33,    6,    7;
;PDU_PRIO94_PORT_ISSUE_PULSE_REG_3_0,                           34,    7,    8;
;PDU_PRIO94_PORT_ISSUE_PULSE_REG_MASK3,                         34,    7,    1;
;PDU_PRIO94_PORT_ISSUE_PULSE_REG_MASK2,                         34,    6,    1;
;PDU_PRIO94_PORT_ISSUE_PULSE_REG_MASK1,                         34,    5,    1;
;PDU_PRIO94_PORT_ISSUE_PULSE_REG_MASK0,                         34,    4,    1;
;PDU_PRIO94_PORT_ISSUE_PULSE_REG3,                              34,    3,    1;
;PDU_PRIO94_PORT_ISSUE_PULSE_REG2,                              34,    2,    1;
;PDU_PRIO94_PORT_ISSUE_PULSE_REG1,                              34,    1,    1;
;PDU_PRIO94_PORT_ISSUE_PULSE_REG0,                              34,    0,    1;
;PDU_PRIO94_PORT_ISSUE_PULSE_REG_7_4,                           35,    7,    8;
;PDU_PRIO94_PORT_ISSUE_PULSE_REG_MASK7,                         35,    7,    1;
;PDU_PRIO94_PORT_ISSUE_PULSE_REG_MASK6,                         35,    6,    1;
;PDU_PRIO94_PORT_ISSUE_PULSE_REG_MASK5,                         35,    5,    1;
;PDU_PRIO94_PORT_ISSUE_PULSE_REG_MASK4,                         35,    4,    1;
;PDU_PRIO94_PORT_ISSUE_PULSE_REG7,                              35,    3,    1;
;PDU_PRIO94_PORT_ISSUE_PULSE_REG6,                              35,    2,    1;
;PDU_PRIO94_PORT_ISSUE_PULSE_REG5,                              35,    1,    1;
;PDU_PRIO94_PORT_ISSUE_PULSE_REG4,                              35,    0,    1;
;PDU_PRIO94_READ_PORT_VALUE_REG_7_0,                            36,    7,    8;
;PDU_PRIO94_READ_PORT_VALUE_REG7,                               36,    7,    1;
;PDU_PRIO94_READ_PORT_VALUE_REG6,                               36,    6,    1;
;PDU_PRIO94_READ_PORT_VALUE_REG5,                               36,    5,    1;
;PDU_PRIO94_READ_PORT_VALUE_REG4,                               36,    4,    1;
;PDU_PRIO94_READ_PORT_VALUE_REG3,                               36,    3,    1;
;PDU_PRIO94_READ_PORT_VALUE_REG2,                               36,    2,    1;
;PDU_PRIO94_READ_PORT_VALUE_REG1,                               36,    1,    1;
;PDU_PRIO94_READ_PORT_VALUE_REG0,                               36,    0,    1;
;PDU_PRIO94_READ_PORT_VALUE_REG_15_8,                           37,    7,    8;
;PDU_PRIO94_READ_PORT_VALUE_REG15,                              37,    7,    1;
;PDU_PRIO94_READ_PORT_VALUE_REG14,                              37,    6,    1;
;PDU_PRIO94_READ_PORT_VALUE_REG13,                              37,    5,    1;
;PDU_PRIO94_READ_PORT_VALUE_REG12,                              37,    4,    1;
;PDU_PRIO94_READ_PORT_VALUE_REG11,                              37,    3,    1;
;PDU_PRIO94_READ_PORT_VALUE_REG10,                              37,    2,    1;
;PDU_PRIO94_READ_PORT_VALUE_REG9,                               37,    1,    1;
;PDU_PRIO94_READ_PORT_VALUE_REG8,                               37,    0,    1;
;PDU_PRIO94_VOLT_MON_DATA_REG_HIGH0,                            38,    7,    8;
;PDU_PRIO94_VOLT_MON_DATA_REG_LOW0,                             39,    7,    8;
;PDU_PRIO94_VOLT_MON_DATA_REG_HIGH1,                            40,    7,    8;
;PDU_PRIO94_VOLT_MON_DATA_REG_LOW1,                             41,    7,    8;
;PDU_PRIO94_VOLT_MON_DATA_REG_HIGH2,                            42,    7,    8;
;PDU_PRIO94_VOLT_MON_DATA_REG_LOW2,                             43,    7,    8;
;PDU_PRIO94_VOLT_MON_DATA_REG_HIGH3,                            44,    7,    8;
;PDU_PRIO94_VOLT_MON_DATA_REG_LOW3,                             45,    7,    8;
;PDU_PRIO94_VOLT_MON_DATA_REG_HIGH4,                            46,    7,    8;
;PDU_PRIO94_VOLT_MON_DATA_REG_LOW4,                             47,    7,    8;
;PDU_PRIO94_VOLT_MON_DATA_REG_HIGH5,                            48,    7,    8;
;PDU_PRIO94_VOLT_MON_DATA_REG_LOW5,                             49,    7,    8;
;PDU_PRIO94_VOLT_MON_DATA_REG_HIGH6,                            50,    7,    8;
;PDU_PRIO94_VOLT_MON_DATA_REG_LOW6,                             51,    7,    8;
;PDU_PRIO94_VOLT_MON_DATA_REG_HIGH7,                            52,    7,    8;
;PDU_PRIO94_VOLT_MON_DATA_REG_LOW7,                             53,    7,    8;
;PDU_WISPR_BRKR_SET_STATE,                                      20,    3,    1;
;PDU_PSE_B_BRKR_SET_STATE,                                      20,    1,    1;
;PDU_LOWSIDE_GRP23_BRKR_SET_STATE,                              21,    3,    1;
;PDU_GRP_A_CATBED_HTR_B_BRKR_SET_STATE_GRP23,                   21,    3,    1;
;PDU_GRP_B_CATBED_HTR_B_BRKR_SET_STATE_GRP23,                   21,    3,    1;
;PDU_GRP_C_CATBED_HTR_B_BRKR_SET_STATE_GRP23,                   21,    3,    1;
;PDU_LOWSIDE_GRP7_PULSE_BRKR_SET_STATE,                         21,    1,    1;
;PDU_WHEEL3_ON_PULSE_BRKR_SET_STATE_GRP7,                       21,    1,    1;
;PDU_WHEEL3_OFF_PULSE_BRKR_SET_STATE_GRP7,                      21,    1,    1;
;PDU_SWEAP_SPC_SURV_HTR_BRKR_SET_STATE,                         22,    1,    1;
;PDU_LOWSIDE_GRP23_BRKR_TRIP_STATE,                             36,    7,    1;
;PDU_GRP_A_CATBED_HTR_B_BRKR_TRIP_STATE_GRP23,                  36,    7,    1;
;PDU_GRP_B_CATBED_HTR_B_BRKR_TRIP_STATE_GRP23,                  36,    7,    1;
;PDU_GRP_C_CATBED_HTR_B_BRKR_TRIP_STATE_GRP23,                  36,    7,    1;
;PDU_LOWSIDE_GRP23_PWR_SET_STATE,                               36,    6,    1;
;PDU_GRP_A_CATBED_HTR_B_PWR_SET_STATE_GRP23,                    36,    6,    1;
;PDU_GRP_B_CATBED_HTR_B_PWR_SET_STATE_GRP23,                    36,    6,    1;
;PDU_GRP_C_CATBED_HTR_B_PWR_SET_STATE_GRP23,                    36,    6,    1;
;PDU_LOWSIDE_GRP23_PWR_STATE,                                   36,    7,    2;
;PDU_GRP_A_CATBED_HTR_B_PWR_STATE_GRP23,                        36,    7,    2;
;PDU_GRP_B_CATBED_HTR_B_PWR_STATE_GRP23,                        36,    7,    2;
;PDU_GRP_C_CATBED_HTR_B_PWR_STATE_GRP23,                        36,    7,    2;
;PDU_LOWSIDE_GRP7_PULSE_BRKR_TRIP_STATE,                        36,    5,    1;
;PDU_WHEEL3_ON_PULSE_BRKR_TRIP_STATE_GRP7,                      36,    5,    1;
;PDU_WHEEL3_OFF_PULSE_BRKR_TRIP_STATE_GRP7,                     36,    5,    1;
;PDU_LOWSIDE_GRP7_PULSE_SET_STATE,                              36,    4,    1;
;PDU_WHEEL3_ON_PULSE_SET_STATE_GRP7,                            36,    4,    1;
;PDU_WHEEL3_OFF_PULSE_SET_STATE_GRP7,                           36,    4,    1;
;PDU_LOWSIDE_GRP7_PULSE_STATE,                                  36,    5,    2;
;PDU_WHEEL3_ON_PULSE_STATE_GRP7,                                36,    5,    2;
;PDU_WHEEL3_OFF_PULSE_STATE_GRP7,                               36,    5,    2;
;PDU_WISPR_BRKR_TRIP_STATE,                                     36,    3,    1;
;PDU_WISPR_PWR_SET_STATE,                                       36,    2,    1;
;PDU_WISPR_PWR_STATE,                                           36,    3,    2;
;PDU_PSE_B_BRKR_TRIP_STATE,                                     36,    1,    1;
;PDU_PSE_B_PWR_SET_STATE,                                       36,    0,    1;
;PDU_PSE_B_PWR_STATE,                                           36,    1,    2;
;PDU_HGA_DEPLOY_A_ARM_STATE_GRP9,                               37,    7,    1;
;PDU_MAG_BOOM_DEPLOY_1A_ARM_STATE_GRP9,                         37,    6,    1;
;PDU_SA_PLATEN_NEGY_DEPLOY_A_ARM_STATE_GRP9,                    37,    5,    1;
;PDU_SA_PLATEN_POSY_DEPLOY_A_ARM_STATE_GRP9,                    37,    4,    1;
;PDU_FIELDS2_V3_V4_DEPLOY_A_ARM_STATE_GRP8,                     37,    3,    1;
;PDU_PROP_LV_A_OPEN_ENA_STATE_GRP8,                             37,    2,    1;
;PDU_SWEAP_SPC_SURV_HTR_BRKR_TRIP_STATE,                        37,    1,    1;
;PDU_SWEAP_SPC_SURV_HTR_PWR_SET_STATE,                          37,    0,    1;
;PDU_SWEAP_SPC_SURV_HTR_PWR_STATE,                              37,    1,    2;
;PDU_SWEAP_SPC_SURV_HTR_CURR,                                   40,    7,    8;
;PDU_PSE_B_CURR,                                                42,    7,    8;
;PDU_WISPR_CURR,                                                44,    7,    8;
;PDU_LOWSIDE_GRP7_PULSE_CURR,                                   46,    7,    8;
;PDU_WHEEL3_ON_PULSE_CURR_GRP7,                                 46,    7,    8;
;PDU_WHEEL3_OFF_PULSE_CURR_GRP7,                                46,    7,    8;
;PDU_LOWSIDE_GRP23_CURR,                                        48,    7,    8;
;PDU_GRP_A_CATBED_HTR_B_CURR_GRP23,                             48,    7,    8;
;PDU_GRP_B_CATBED_HTR_B_CURR_GRP23,                             48,    7,    8;
;PDU_GRP_C_CATBED_HTR_B_CURR_GRP23,                             48,    7,    8;
;}
