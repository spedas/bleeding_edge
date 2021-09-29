;Ali: June 2020
;+
; $LastChangedBy: ali $
; $LastChangedDate: 2020-12-09 08:27:23 -0800 (Wed, 09 Dec 2020) $
; $LastChangedRevision: 29449 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SPP/COMMON/sc/spp_sc_hk_0x255_apdat__define.pro $
;-

function spp_SC_HK_0x255_struct,ccsds_data
  if n_elements(ccsds_data) eq 0 then ccsds_data = bytarr(67)

  FSW_GC_HK_HK_SYS_MOMENTUM_BODY0=spp_swp_data_select(ccsds_data,117*8+7-7,16)
  FSW_GC_HK_HK_SYS_MOMENTUM_BODY1=spp_swp_data_select(ccsds_data,119*8+7-7,16)
  FSW_GC_HK_HK_SYS_MOMENTUM_BODY2=spp_swp_data_select(ccsds_data,121*8+7-7,16)
  FSW_GC_HK_HK_TORQ_CMD_IN_WHEEL_QUANTIZED0=spp_swp_data_select(ccsds_data,147*8+7-7,16)
  FSW_GC_HK_HK_TORQ_CMD_IN_WHEEL_QUANTIZED1=spp_swp_data_select(ccsds_data,149*8+7-7,16)
  FSW_GC_HK_HK_TORQ_CMD_IN_WHEEL_QUANTIZED2=spp_swp_data_select(ccsds_data,151*8+7-7,16)
  FSW_GC_HK_HK_TORQ_CMD_IN_WHEEL_QUANTIZED3=spp_swp_data_select(ccsds_data,153*8+7-7,16)
  FSW_GC_HK_HK_THR_CNTS0=spp_swp_data_select(ccsds_data,155*8+7-7,16)
  FSW_GC_HK_HK_THR_CNTS1=spp_swp_data_select(ccsds_data,157*8+7-7,16)
  FSW_GC_HK_HK_THR_CNTS2=spp_swp_data_select(ccsds_data,159*8+7-7,16)
  FSW_GC_HK_HK_THR_CNTS3=spp_swp_data_select(ccsds_data,161*8+7-7,16)
  FSW_GC_HK_HK_THR_CNTS4=spp_swp_data_select(ccsds_data,163*8+7-7,16)
  FSW_GC_HK_HK_THR_CNTS5=spp_swp_data_select(ccsds_data,165*8+7-7,16)
  FSW_GC_HK_HK_THR_CNTS6=spp_swp_data_select(ccsds_data,167*8+7-7,16)
  FSW_GC_HK_HK_THR_CNTS7=spp_swp_data_select(ccsds_data,169*8+7-7,16)
  FSW_GC_HK_HK_THR_CNTS8=spp_swp_data_select(ccsds_data,171*8+7-7,16)
  FSW_GC_HK_HK_THR_CNTS9=spp_swp_data_select(ccsds_data,173*8+7-7,16)
  FSW_GC_HK_HK_THR_CNTS10=spp_swp_data_select(ccsds_data,175*8+7-7,16)
  FSW_GC_HK_HK_THR_CNTS11=spp_swp_data_select(ccsds_data,177*8+7-7,16)
  PDU_WHEEL1_CURR=spp_swp_data_select(ccsds_data,267*8+7-4,8)
  PDU_WHEEL2_CURR=spp_swp_data_select(ccsds_data,344*8+7-4,8)
  PDU_WHEEL3_CURR=spp_swp_data_select(ccsds_data,297*8+7-4,8)
  PDU_WHEEL4_CURR=spp_swp_data_select(ccsds_data,342*8+7-4,8)

  str = {time:!values.d_nan ,$
    met:!values.d_nan, $
    seqn: 0u, $
    pkt_size: 0u, $
    ;PDU_SWEAP_CURR:spp_swp_data_select(ccsds_data,279*8+7-4,8), $
    ;PDU_SWEAP_SPAN_AB_SURV_HTRS_CURR:spp_swp_data_select(ccsds_data,301*8+7-4,8), $
    ;PDU_SWEAP_SPC_SURV_HTR_CURR:spp_swp_data_select(ccsds_data,309*8+7-4,8), $
    PDU_SWEAP_CURR:interp([-1.125779040605658, 1.244296913976348, 8.36225289009219],[0.0, 102.0, 255.0],spp_swp_data_select(ccsds_data,279*8+7-4,8)), $
    PDU_SWEAP_SPAN_AB_SURV_HTRS_CURR:interp([-0.5590297951162084, 0.6239597053559871, 4.226999660991688],[0.0, 101.5, 255.0],spp_swp_data_select(ccsds_data,301*8+7-4,8)), $
    PDU_SWEAP_SPC_SURV_HTR_CURR:interp([-0.2815494183296126, 0.311373041137364, 2.122413461396678],[0.0, 101.5, 255.0],spp_swp_data_select(ccsds_data,309*8+7-4,8)), $
    FSW_GC_HK_HK_SYS_MOMENTUM_BODY:-5.0+0.00244140625*[FSW_GC_HK_HK_SYS_MOMENTUM_BODY0,FSW_GC_HK_HK_SYS_MOMENTUM_BODY1,FSW_GC_HK_HK_SYS_MOMENTUM_BODY2],$
    FSW_GC_HK_HK_TORQ_CMD_IN_WHEEL_QUANTIZED:-0.075+1.831054687e-05*[FSW_GC_HK_HK_TORQ_CMD_IN_WHEEL_QUANTIZED0,FSW_GC_HK_HK_TORQ_CMD_IN_WHEEL_QUANTIZED1,$
    FSW_GC_HK_HK_TORQ_CMD_IN_WHEEL_QUANTIZED2,FSW_GC_HK_HK_TORQ_CMD_IN_WHEEL_QUANTIZED3],$
    FSW_GC_HK_HK_THR_CNTS:[FSW_GC_HK_HK_THR_CNTS0,FSW_GC_HK_HK_THR_CNTS1,FSW_GC_HK_HK_THR_CNTS2,FSW_GC_HK_HK_THR_CNTS3,FSW_GC_HK_HK_THR_CNTS4,FSW_GC_HK_HK_THR_CNTS5,$
    FSW_GC_HK_HK_THR_CNTS6,FSW_GC_HK_HK_THR_CNTS7,FSW_GC_HK_HK_THR_CNTS8,FSW_GC_HK_HK_THR_CNTS9,FSW_GC_HK_HK_THR_CNTS10,FSW_GC_HK_HK_THR_CNTS11],$
    FSW_GC_HK_HK_SPIN_RATE:-0.008726646+6.817692391e-05*spp_swp_data_select(ccsds_data,179*8+7-7,8),$
    PDU_WHEEL_CURR_RAW:[PDU_WHEEL1_CURR,PDU_WHEEL2_CURR,PDU_WHEEL3_CURR,PDU_WHEEL4_CURR],$
    gap:0B}
  return, str
end

;EU(Raw='SC_HK_0x255.PDU_SWEAP_CURR') := fCalCurve([0.0, 102.0, 255.0], [-1.125779040605658, 1.244296913976348, 8.36225289009219], Raw)
;EU(Raw='SC_HK_0x255.PDU_SWEAP_SPAN_AB_SURV_HTRS_CURR') := fCalCurve([0.0, 101.5, 255.0], [-0.5590297951162084, 0.6239597053559871, 4.226999660991688], Raw)
;EU(Raw='SC_HK_0x255.PDU_SWEAP_SPC_SURV_HTR_CURR') := fCalCurve([0.0, 101.5, 255.0], [-0.2815494183296126, 0.311373041137364, 2.122413461396678], Raw)
;EU(Raw='SC_HK_0x255.PDU_WHEEL1_CURR') := fCalCurve([0.0, 101.5, 255.0], [-2.03425878519223, 2.341301629495125, 15.89848437526145], Raw)
;EU(Raw='SC_HK_0x255.PDU_WHEEL2_CURR') := fCalCurve([0.0, 101.5, 255.0], [-2.071673591298432, 2.308261837238808, 15.49779722875937], Raw)
;EU(Raw='SC_HK_0x255.PDU_WHEEL3_CURR') := fCalCurve([0.0, 102.0, 255.0], [-2.189674753945994, 2.389793001872445, 15.86056018999356], Raw)
;EU(Raw='SC_HK_0x255.PDU_WHEEL4_CURR') := fCalCurve([0.0, 101.5, 255.0], [-2.166342989411793, 2.40412604065547, 16.1744727462611], Raw)
;EU(Raw='SC_HK_0x255.FSW_GC_HK_HK_TORQ_CMD_IN_WHEEL_QUANTIZED0') := fPolynomial([-0.075, 1.831054687e-05], Raw)
;EU(Raw='SC_HK_0x255.FSW_GC_HK_HK_TORQ_CMD_IN_WHEEL_QUANTIZED1') := fPolynomial([-0.075, 1.831054687e-05], Raw)
;EU(Raw='SC_HK_0x255.FSW_GC_HK_HK_TORQ_CMD_IN_WHEEL_QUANTIZED2') := fPolynomial([-0.075, 1.831054687e-05], Raw)
;EU(Raw='SC_HK_0x255.FSW_GC_HK_HK_TORQ_CMD_IN_WHEEL_QUANTIZED3') := fPolynomial([-0.075, 1.831054687e-05], Raw)
;EU(Raw='SC_HK_0x255.FSW_GC_HK_HK_SPIN_RATE') := fPolynomial([-0.008726646, 6.817692391e-05], Raw)
;EU(Raw='SC_HK_0x255.FSW_GC_HK_HK_SYS_MOMENTUM_BODY0') := fPolynomial([-5.0, 0.00244140625], Raw)
;EU(Raw='SC_HK_0x255.FSW_GC_HK_HK_SYS_MOMENTUM_BODY1') := fPolynomial([-5.0, 0.00244140625], Raw)
;EU(Raw='SC_HK_0x255.FSW_GC_HK_HK_SYS_MOMENTUM_BODY2') := fPolynomial([-5.0, 0.00244140625], Raw)

;PDU_SWEAP_CURR,                                               279,    4,    8;
;PDU_SWEAP_SPAN_AB_SURV_HTRS_CURR,                             301,    4,    8;
;PDU_SWEAP_SPC_SURV_HTR_CURR,                                  309,    4,    8;
;FSW_GC_HK_HK_SYS_MOMENTUM_BODY0,                              117,    7,   16;
;FSW_GC_HK_HK_SYS_MOMENTUM_BODY1,                              119,    7,   16;
;FSW_GC_HK_HK_SYS_MOMENTUM_BODY2,                              121,    7,   16;
;FSW_GC_HK_HK_TORQ_CMD_IN_WHEEL_QUANTIZED0,                    147,    7,   16;
;FSW_GC_HK_HK_TORQ_CMD_IN_WHEEL_QUANTIZED1,                    149,    7,   16;
;FSW_GC_HK_HK_TORQ_CMD_IN_WHEEL_QUANTIZED2,                    151,    7,   16;
;FSW_GC_HK_HK_TORQ_CMD_IN_WHEEL_QUANTIZED3,                    153,    7,   16;
;FSW_GC_HK_HK_THR_CNTS0,                                       155,    7,   16;
;FSW_GC_HK_HK_THR_CNTS1,                                       157,    7,   16;
;FSW_GC_HK_HK_THR_CNTS2,                                       159,    7,   16;
;FSW_GC_HK_HK_THR_CNTS3,                                       161,    7,   16;
;FSW_GC_HK_HK_THR_CNTS4,                                       163,    7,   16;
;FSW_GC_HK_HK_THR_CNTS5,                                       165,    7,   16;
;FSW_GC_HK_HK_THR_CNTS6,                                       167,    7,   16;
;FSW_GC_HK_HK_THR_CNTS7,                                       169,    7,   16;
;FSW_GC_HK_HK_THR_CNTS8,                                       171,    7,   16;
;FSW_GC_HK_HK_THR_CNTS9,                                       173,    7,   16;
;FSW_GC_HK_HK_THR_CNTS10,                                      175,    7,   16;
;FSW_GC_HK_HK_THR_CNTS11,                                      177,    7,   16;
;FSW_GC_HK_HK_SPIN_RATE,                                       179,    7,    8;
;PDU_WHEEL1_CURR,                                              267,    4,    8;
;PDU_WHEEL2_CURR,                                              344,    4,    8;
;PDU_WHEEL3_CURR,                                              297,    4,    8;
;PDU_WHEEL4_CURR,                                              342,    4,    8;



function SPP_SC_HK_0x255_apdat::decom,ccsds, source_dict=source_dict   ;,ptp_header=ptp_header

  ccsds_data = spp_swp_ccsds_data(ccsds)
  str2 = spp_SC_HK_0x255_struct(ccsds_data)
  struct_assign,ccsds,str2,/nozero
  return,str2

end


pro spp_SC_HK_0x255_apdat__define

  void = {spp_SC_HK_0x255_apdat, $
    inherits spp_gen_apdat, $    ; superclass
    flag: 0 $
  }
end
;
;#
;# SC_HK_0x255
;#
;SC_HK_0x255
;{
;( Block[573],                                                      ,     ,    8; )
;HK_MED_TPPH_VERSION,                                            0,    7,    3;
;HK_MED_TPPH_TYPE,                                               0,    4,    1;
;HK_MED_TPPH_SEC_HDR_FLAG,                                       0,    3,    1;
;HK_MED_TPPH_APID,                                               0,    2,   11;
;SC_D_APID,                                                      0,    2,   11;
;HK_MED_TPPH_SEQ_FLAGS,                                          2,    7,    2;
;HK_MED_TPPH_SEQ_CNT,                                            2,    5,   14;
;HK_MED_TPPH_LENGTH,                                             4,    7,   16;
;HK_MED_TPSH_MET_SEC,                                            6,    7,   32;
;SC_D_MET_SEC,                                                   6,    7,   32;
;HK_MED_TPSH_MET_SUBSEC,                                        10,    7,    8;
;HK_MED_TPSH_SBC_PHYS_ID,                                       11,    7,    2;
;SBC_RIO_TPPH_VERSION,                                           0,    7,    3;
;SBC_RIO_TPPH_TYPE,                                              0,    4,    1;
;SBC_RIO_TPPH_SEC_HDR_FLAG,                                      0,    3,    1;
;SBC_RIO_TPPH_APID,                                              0,    2,   11;
;SC_D_APID_DUP0,                                                 0,    2,   11;
;SBC_RIO_TPPH_SEQ_FLAGS,                                         2,    7,    2;
;SBC_RIO_TPPH_SEQ_CNT,                                           2,    5,   14;
;SBC_RIO_TPPH_LENGTH,                                            4,    7,   16;
;SBC_RIO_TPSH_MET_SEC,                                           6,    7,   32;
;SC_D_MET_SEC_DUP1,                                              6,    7,   32;
;SBC_RIO_TPSH_MET_SUBSEC,                                       10,    7,    8;
;SBC_RIO_TPSH_SBC_PHYS_ID,                                      11,    7,    2;
;FSW_GC_HK_ANGRATE_BODY0,                                       12,    7,   64;
;FSW_GC_HK_ANGRATE_BODY1,                                       20,    7,   64;
;FSW_GC_HK_ANGRATE_BODY2,                                       28,    7,   64;
;FSW_GC_HK_TIME_LAST_VALID_GYRO_RATE,                           36,    7,   64;
;FSW_GC_HK_HK_ST_MODE_STATUS_ST_TRANSITION_STATUS0,             44,    7,    8;
;FSW_GC_HK_HK_ST_MODE_STATUS_ST_MODE0,                          45,    7,    8;
;FSW_GC_HK_HK_ST_MODE_STATUS_ST_TRANSITION_STATUS1,             46,    7,    8;
;FSW_GC_HK_HK_ST_MODE_STATUS_ST_MODE1,                          47,    7,    8;
;FSW_GC_HK_HK_ST_BKG_LOCAL_MEAN0,                               48,    7,   16;
;FSW_GC_HK_HK_ST_BKG_LOCAL_MEAN1,                               50,    7,   16;
;FSW_GC_HK_HK_ST_BKG_LOCAL_RMS0,                                52,    7,   16;
;FSW_GC_HK_HK_ST_BKG_LOCAL_RMS1,                                54,    7,   16;
;FSW_GC_HK_HK_ST_BKG_GLOBAL_MEAN0,                              56,    7,   16;
;FSW_GC_HK_HK_ST_BKG_GLOBAL_MEAN1,                              58,    7,   16;
;FSW_GC_HK_HK_ST_BKG_GLOBAL_RMS0,                               60,    7,   16;
;FSW_GC_HK_HK_ST_BKG_GLOBAL_RMS1,                               62,    7,   16;
;FSW_GC_HK_HK_SC_SPAN_ID,                                       64,    7,    8;
;FSW_GC_HK_HK_EARTH_SPAN_ID,                                    65,    7,    8;
;FSW_GC_HK_HK_VENUS_SPAN_ID,                                    66,    7,    8;
;FSW_GC_HK_HK_ST1_ATT_SOL_PROBLEM,                              67,    7,    8;
;FSW_GC_HK_HK_ST2_ATT_SOL_PROBLEM,                              68,    7,    8;
;FSW_GC_HK_HK_ANGLE_ERR0,                                       69,    7,   32;
;FSW_GC_HK_HK_ANGLE_ERR1,                                       73,    7,   32;
;FSW_GC_HK_HK_ANGLE_ERR2,                                       77,    7,   32;
;FSW_GC_HK_HK_ANGRATE_ERR0,                                     81,    7,   32;
;FSW_GC_HK_HK_ANGRATE_ERR1,                                     85,    7,   32;
;FSW_GC_HK_HK_ANGRATE_ERR2,                                     89,    7,   32;
;FSW_GC_HK_HK_ANGLE_ERR_VECTOR0,                                93,    7,   32;
;FSW_GC_HK_HK_ANGLE_ERR_VECTOR1,                                97,    7,   32;
;FSW_GC_HK_HK_ANGLE_ERR_VECTOR2,                               101,    7,   32;
;FSW_GC_HK_HK_SUN_AZ_EPH,                                      105,    7,   16;
;FSW_GC_HK_HK_SUN_EL_EPH,                                      107,    7,   16;
;FSW_GC_HK_HK_EARTH_AZ_EPH,                                    109,    7,   16;
;FSW_GC_HK_HK_EARTH_EL_EPH,                                    111,    7,   16;
;FSW_GC_HK_HK_SC_VEL_AZ_EPH,                                   113,    7,   16;
;FSW_GC_HK_HK_SC_VEL_EL_EPH,                                   115,    7,   16;
;FSW_GC_HK_HK_SYS_MOMENTUM_BODY0,                              117,    7,   16;
;FSW_GC_HK_HK_SYS_MOMENTUM_BODY1,                              119,    7,   16;
;FSW_GC_HK_HK_SYS_MOMENTUM_BODY2,                              121,    7,   16;
;FSW_GC_HK_HK_CPUBIT,                                          123,    7,   16;
;FSW_GC_HK_HK_PSBIT,                                           125,    7,   16;
;FSW_GC_HK_HK_GAMALF0,                                         127,    7,   16;
;FSW_GC_HK_HK_GAMALF1,                                         129,    7,   16;
;FSW_GC_HK_HK_GAMALF2,                                         131,    7,   16;
;FSW_GC_HK_HK_GAMALF3,                                         133,    7,   16;
;FSW_GC_HK_HK_SUN_AZ_DSS1,                                     135,    7,   16;
;FSW_GC_HK_HK_SUN_EL_DSS1,                                     137,    7,   16;
;FSW_GC_HK_HK_SUN_AZ_DSS2,                                     139,    7,   16;
;FSW_GC_HK_HK_SUN_EL_DSS2,                                     141,    7,   16;
;FSW_GC_HK_HK_SUN_AZ_SLS,                                      143,    7,   16;
;FSW_GC_HK_HK_SUN_EL_SLS,                                      145,    7,   16;
;FSW_GC_HK_HK_TORQ_CMD_IN_WHEEL_QUANTIZED0,                    147,    7,   16;
;FSW_GC_HK_HK_TORQ_CMD_IN_WHEEL_QUANTIZED1,                    149,    7,   16;
;FSW_GC_HK_HK_TORQ_CMD_IN_WHEEL_QUANTIZED2,                    151,    7,   16;
;FSW_GC_HK_HK_TORQ_CMD_IN_WHEEL_QUANTIZED3,                    153,    7,   16;
;FSW_GC_HK_HK_THR_CNTS0,                                       155,    7,   16;
;FSW_GC_HK_HK_THR_CNTS1,                                       157,    7,   16;
;FSW_GC_HK_HK_THR_CNTS2,                                       159,    7,   16;
;FSW_GC_HK_HK_THR_CNTS3,                                       161,    7,   16;
;FSW_GC_HK_HK_THR_CNTS4,                                       163,    7,   16;
;FSW_GC_HK_HK_THR_CNTS5,                                       165,    7,   16;
;FSW_GC_HK_HK_THR_CNTS6,                                       167,    7,   16;
;FSW_GC_HK_HK_THR_CNTS7,                                       169,    7,   16;
;FSW_GC_HK_HK_THR_CNTS8,                                       171,    7,   16;
;FSW_GC_HK_HK_THR_CNTS9,                                       173,    7,   16;
;FSW_GC_HK_HK_THR_CNTS10,                                      175,    7,   16;
;FSW_GC_HK_HK_THR_CNTS11,                                      177,    7,   16;
;FSW_GC_HK_HK_SPIN_RATE,                                       179,    7,    8;
;FSW_GC_HK_HK_SLEW_TIME,                                       180,    7,    8;
;FSW_GC_HK_HK_TIME_SINCE_SLEW_START,                           181,    7,    8;
;FSW_GC_HK_HK_SEG,                                             182,    7,    8;
;FSW_GC_HK_HK_CMD_ERROR,                                       183,    7,    8;
;FSW_GC_HK_HK_DEF_ERROR,                                       184,    7,    8;
;FSW_GC_HK_HK_SC_EPH_VAL,                                      185,    7,    8;
;FSW_GC_HK_HK_EARTH_EPH_VAL,                                   186,    7,    8;
;FSW_GC_HK_HK_VENUS_EPH_VAL,                                   187,    7,    8;
;FSW_GC_HK_HK_ANT_ERROR,                                       188,    7,    8;
;FSW_GC_HK_HK_GYRO_MODE0,                                      189,    7,    8;
;FSW_GC_HK_HK_GYRO_MODE1,                                      190,    7,    8;
;FSW_GC_HK_HK_GYRO_MODE2,                                      191,    7,    8;
;FSW_GC_HK_HK_GYRO_MODE3,                                      192,    7,    8;
;FSW_GC_HK_HK_HGA_FLAG,                                        193,    7,    8;
;FSW_GC_HK_HK_FANBEAM_FLAG,                                    194,    7,    8;
;FSW_GC_HK_HK_HEATER_ON,                                       195,    7,    8;
;FSW_GC_HK_HK_FSW_IMU_VAL_FLAG_PERSIST,                        196,    7,    8;
;FSW_GC_HK_HK_LAST_VAL_FLAG0,                                  197,    7,    8;
;FSW_GC_HK_HK_LAST_VAL_FLAG1,                                  198,    7,    8;
;FSW_GC_HK_HK_LAST_VAL_FLAG2,                                  199,    7,    8;
;FSW_GC_HK_HK_LAST_VAL_FLAG3,                                  200,    7,    8;
;FSW_GC_HK_HK_ACC_VAL0,                                        201,    7,    8;
;FSW_GC_HK_HK_ACC_VAL1,                                        202,    7,    8;
;FSW_GC_HK_HK_ACC_VAL2,                                        203,    7,    8;
;FSW_GC_HK_HK_ACC_VAL3,                                        204,    7,    8;
;FSW_GC_HK_HK_WHEEL_STUCK_CNT_EXCEEDED0,                       205,    7,    8;
;FSW_GC_HK_HK_WHEEL_STUCK_CNT_EXCEEDED1,                       206,    7,    8;
;FSW_GC_HK_HK_WHEEL_STUCK_CNT_EXCEEDED2,                       207,    7,    8;
;FSW_GC_HK_HK_WHEEL_STUCK_CNT_EXCEEDED3,                       208,    7,    8;
;FSW_GC_HK_HK_WHEEL_OVER_SPD_CNT_EXCEEDED0,                    209,    7,    8;
;FSW_GC_HK_HK_WHEEL_OVER_SPD_CNT_EXCEEDED1,                    210,    7,    8;
;FSW_GC_HK_HK_WHEEL_OVER_SPD_CNT_EXCEEDED2,                    211,    7,    8;
;FSW_GC_HK_HK_WHEEL_OVER_SPD_CNT_EXCEEDED3,                    212,    7,    8;
;FSW_GC_HK_HK_TAC_LOCKOUT0,                                    213,    7,    8;
;FSW_GC_HK_HK_TAC_LOCKOUT1,                                    214,    7,    8;
;FSW_GC_HK_HK_TAC_LOCKOUT2,                                    215,    7,    8;
;FSW_GC_HK_HK_TAC_LOCKOUT3,                                    216,    7,    8;
;FSW_GC_HK_HK_TAC_LOCKOUT4,                                    217,    7,    8;
;FSW_GC_HK_HK_TAC_LOCKOUT5,                                    218,    7,    8;
;FSW_GC_HK_HK_TAC_LOCKOUT6,                                    219,    7,    8;
;FSW_GC_HK_HK_TAC_LOCKOUT7,                                    220,    7,    8;
;FSW_GC_HK_HK_TAC_LOCKOUT8,                                    221,    7,    8;
;FSW_GC_HK_HK_TAC_LOCKOUT9,                                    222,    7,    8;
;FSW_GC_HK_HK_TAC_LOCKOUT10,                                   223,    7,    8;
;FSW_GC_HK_HK_TAC_LOCKOUT11,                                   224,    7,    8;
;RIU_1A_TAC_RIU_PP,                                            225,    7,    1;
;PUMP_A_5HZ0_MOTOR_OVERCURR_INDICATOR,                         225,    6,    1;
;PUMP_A_MOTOR_OVERCURR_INDICATOR,                              225,    6,    1;
;PUMP_A_5HZ0_MOTOR_HYBRID_ENA_FAULT,                           225,    5,    1;
;PUMP_A_MOTOR_HYBRID_ENA_FAULT,                                225,    5,    1;
;PUMP_A_5HZ0_MOTOR_BEMF_FAULT,                                 225,    4,    1;
;PUMP_A_MOTOR_BEMF_FAULT,                                      225,    4,    1;
;PUMP_A_5HZ0_MOTOR_OVERCURR_FAULT,                             225,    3,    1;
;PUMP_A_MOTOR_OVERCURR_FAULT,                                  225,    3,    1;
;PUMP_A_5HZ0_MOTOR_BAD_CMD,                                    225,    2,    1;
;PUMP_A_MOTOR_BAD_CMD,                                         225,    2,    1;
;PUMP_A_5HZ0_MOTOR_HYBRID_ENA_STATE,                           225,    1,    1;
;PUMP_A_MOTOR_HYBRID_ENA_STATE,                                225,    1,    1;
;PUMP_A_5HZ0_FPGA_UNKNOWN_OPCODE,                              225,    0,    1;
;PUMP_A_FPGA_UNKNOWN_OPCODE,                                   225,    0,    1;
;PUMP_A_5HZ0_FPGA_PARM_OUT_OF_RANGE,                           226,    7,    1;
;PUMP_A_FPGA_PARM_OUT_OF_RANGE,                                226,    7,    1;
;PUMP_A_5HZ0_FPGA_PKT_XOR,                                     226,    6,    1;
;PUMP_A_FPGA_PKT_XOR,                                          226,    6,    1;
;PUMP_A_5HZ0_FPGA_PKT_TIMING,                                  226,    5,    1;
;PUMP_A_FPGA_PKT_TIMING,                                       226,    5,    1;
;PUMP_A_5HZ0_FPGA_PKT_PARITY,                                  226,    4,    1;
;PUMP_A_FPGA_PKT_PARITY,                                       226,    4,    1;
;PUMP_B_5HZ0_MOTOR_OVERCURR_INDICATOR,                         226,    3,    1;
;PUMP_B_MOTOR_OVERCURR_INDICATOR,                              226,    3,    1;
;PUMP_B_5HZ0_MOTOR_HYBRID_ENA_FAULT,                           226,    2,    1;
;PUMP_B_MOTOR_HYBRID_ENA_FAULT,                                226,    2,    1;
;PUMP_B_5HZ0_MOTOR_BEMF_FAULT,                                 226,    1,    1;
;PUMP_B_MOTOR_BEMF_FAULT,                                      226,    1,    1;
;PUMP_B_5HZ0_MOTOR_OVERCURR_FAULT,                             226,    0,    1;
;PUMP_B_MOTOR_OVERCURR_FAULT,                                  226,    0,    1;
;PUMP_B_5HZ0_MOTOR_BAD_CMD,                                    227,    7,    1;
;PUMP_B_MOTOR_BAD_CMD,                                         227,    7,    1;
;PUMP_B_5HZ0_MOTOR_HYBRID_ENA_STATE,                           227,    6,    1;
;PUMP_B_MOTOR_HYBRID_ENA_STATE,                                227,    6,    1;
;PUMP_B_5HZ0_FPGA_UNKNOWN_OPCODE,                              227,    5,    1;
;PUMP_B_FPGA_UNKNOWN_OPCODE,                                   227,    5,    1;
;PUMP_B_5HZ0_FPGA_PARM_OUT_OF_RANGE,                           227,    4,    1;
;PUMP_B_FPGA_PARM_OUT_OF_RANGE,                                227,    4,    1;
;PUMP_B_5HZ0_FPGA_PKT_XOR,                                     227,    3,    1;
;PUMP_B_FPGA_PKT_XOR,                                          227,    3,    1;
;PUMP_B_5HZ0_FPGA_PKT_TIMING,                                  227,    2,    1;
;PUMP_B_FPGA_PKT_TIMING,                                       227,    2,    1;
;PUMP_B_5HZ0_FPGA_PKT_PARITY,                                  227,    1,    1;
;PUMP_B_FPGA_PKT_PARITY,                                       227,    1,    1;
;TAC_RED_P1_PRESS0,                                            227,    0,   12;
;RIU_1A_CH1_COUNTS,                                            229,    4,   10;
;RIU_1A_CH6_COUNTS,                                            230,    2,   10;
;RIU_1B_CH4_COUNTS,                                            231,    0,   10;
;RIU_1B_CH6_COUNTS,                                            233,    6,   10;
;RIU_1B_CH9_COUNTS,                                            234,    4,   10;
;RIU_1B_CH13_COUNTS,                                           235,    2,   10;
;RIU_2A_CH9_COUNTS,                                            236,    0,   10;
;RIU_2A_CH12_COUNTS,                                           238,    6,   10;
;RIU_6A_CH6_COUNTS,                                            239,    4,   10;
;RIU_6B_CH5_COUNTS,                                            240,    2,   10;
;RIU_7A_CH5_COUNTS,                                            241,    0,   10;
;RIU_7A_CH6_COUNTS,                                            243,    6,   10;
;RIU_7A_CH7_COUNTS,                                            244,    4,   10;
;RIU_7B_CH5_COUNTS,                                            245,    2,   10;
;RIU_7B_CH6_COUNTS,                                            246,    0,   10;
;RIU_7B_CH7_COUNTS,                                            248,    6,   10;
;PDU_PDU_A_CURR,                                               249,    4,    8;
;PDU_RADIO_A_CURR,                                             250,    4,    8;
;PDU_MECH_MISC_SAFETY_BUS_A_VOLT,                              251,    4,    8;
;PDU_RF_SAFETY_BUS_A_VOLT,                                     252,    4,    8;
;PDU_THRUSTER_SAFETY_BUS_A_VOLT,                               253,    4,    8;
;PDU_RPM_ARC_A_CURR,                                           254,    4,    8;
;PDU_RPM_SBCC_CURR,                                            255,    4,    8;
;PDU_RPM_SBCA_CURR,                                            256,    4,    8;
;PDU_REM_B_CURR,                                               257,    4,    8;
;PDU_PDU_B_CURR,                                               258,    4,    8;
;PDU_RADIO_B_CURR,                                             259,    4,    8;
;PDU_MECH_MISC_SAFETY_BUS_B_VOLT,                              260,    4,    8;
;PDU_RF_SAFETY_BUS_B_VOLT,                                     261,    4,    8;
;PDU_THRUSTER_SAFETY_BUS_B_VOLT,                               262,    4,    8;
;PDU_RPM_ARC_B_CURR,                                           263,    4,    8;
;PDU_RPM_ARC_C_CURR,                                           264,    4,    8;
;PDU_RPM_SBCB_CURR,                                            265,    4,    8;
;PDU_REM_A_CURR,                                               266,    4,    8;
;PDU_WHEEL1_CURR,                                              267,    4,    8;
;PDU_RF_SWCH1_POSA_PULSE_CURR,                                 268,    4,    8;
;PDU_RF_SWCH1_POSB_PULSE_CURR,                                 269,    4,    8;
;PDU_PROP_POSY_VHTRS_A_CURR,                                   270,    4,    8;
;PDU_LOWSIDE_A_GRP19_CURR,                                     271,    4,    8;
;PDU_TWTA_KA_A_CURR_GRP19,                                     271,    4,    8;
;PDU_TWTA_X_A_CURR_GRP19,                                      271,    4,    8;
;PDU_SACS_PRESXDCR_CURR,                                       272,    4,    8;
;PDU_EPIHI_OPER_HTR_CURR,                                      273,    4,    8;
;PDU_ST2_CURR,                                                 274,    4,    8;
;PDU_BATT_HTR_A_CURR,                                          275,    4,    8;
;PDU_LOWSIDE_GRP3_CURR,                                        276,    4,    8;
;PDU_SA_BOOM_POSY_DEPLOY_A_CURR_GRP3,                          276,    4,    8;
;PDU_SA_BOOM_NEGY_DEPLOY_A_CURR_GRP3,                          276,    4,    8;
;PDU_LOWSIDE_GRP4_CURR,                                        277,    4,    8;
;PDU_MAG_BOOM_DEPLOY_2A_CURR_GRP4,                             277,    4,    8;
;PDU_FIELDS_ANT_HINGE_1_DEPLOY_PULSE_CURR_GRP4,                277,    4,    8;
;PDU_FIELDS_ANT_HINGE_2_DEPLOY_PULSE_CURR_GRP4,                277,    4,    8;
;PDU_FIELDS_ANT_HINGES_3_4_DEPLOY_PULSE_CURR_GRP4,             277,    4,    8;
;PDU_WISPR_DOOR_DEPLOY_A_PULSE_CURR_GRP4,                      277,    4,    8;
;PDU_SPAN_DOOR_CVR_HTR_A_CURR_GRP4,                            277,    4,    8;
;PDU_FIELDS1_MAG_AND_SURV_HTRS_CURR,                           278,    4,    8;
;PDU_SWEAP_CURR,                                               279,    4,    8;
;PDU_PRIO84_VOLT_MON_DATA_REG_HIGH3,                           280,    4,    8;
;PDU_LOWSIDE_GRP1_PULSE_CURR,                                  281,    4,    8;
;PDU_IMU_A_IRU_ON_PULSE_CURR_GRP1,                             281,    4,    8;
;PDU_IMU_A_IRU_OFF_PULSE_CURR_GRP1,                            281,    4,    8;
;PDU_IMU_A_PPSMB_SEL_PULSE_CURR_GRP1,                          281,    4,    8;
;PDU_LOWSIDE_GRP2_PULSE_CURR,                                  282,    4,    8;
;PDU_IMU_A_AB_OFF_PULSE_CURR_GRP2,                             282,    4,    8;
;PDU_IMU_A_AC_OFF_PULSE_CURR_GRP2,                             282,    4,    8;
;PDU_IMU_A_IRU_RST_PULSE_CURR_GRP2,                            282,    4,    8;
;PDU_INT_PANEL_SURV_HTRS_A_CURR,                               283,    4,    8;
;PDU_RF_SWCH3_POSA_PULSE_CURR,                                 284,    4,    8;
;PDU_RF_SWCH3_POSB_PULSE_CURR,                                 285,    4,    8;
;PDU_PROP_NEGY_VHTRS_B_CURR,                                   286,    4,    8;
;PDU_LOWSIDE_GRP20_PULSE_CURR,                                 287,    4,    8;
;PDU_CSPR23_UP_LV_A_PULSE_CURR_GRP20,                          287,    4,    8;
;PDU_CSPR23_DOWN_LV_A_PULSE_CURR_GRP20,                        287,    4,    8;
;PDU_MC_A_RESTART_INH_CURR,                                    288,    4,    8;
;PDU_EPILO_CURR,                                               289,    4,    8;
;PDU_PROP_PRESXDCR_A_CURR,                                     290,    4,    8;
;PDU_BATT_HTR_B_CURR,                                          291,    4,    8;
;PDU_LOWSIDE_GRP6_PULSE_CURR,                                  292,    4,    8;
;PDU_SACS_ACCUM_LV_OPEN_A_PULSE_CURR_GRP6,                     292,    4,    8;
;PDU_FIELDS1_V1_V2_DEPLOY_A_PULSE_CURR_GRP6,                   292,    4,    8;
;PDU_LOWSIDE_A_GRP21_CURR,                                     293,    4,    8;
;PDU_ECU_A_CURR_GRP21,                                         293,    4,    8;
;PDU_PUMP_ENA_A_FOR_PUMP_A_CURR_GRP21,                         293,    4,    8;
;PDU_PUMP_ENA_A_FOR_PUMP_B_CURR_GRP21,                         293,    4,    8;
;PDU_ST_AND_PROP_LINE_SURV_HTRS_A_CURR,                        294,    4,    8;
;PDU_FIELDS2_CURR,                                             295,    4,    8;
;PDU_GRP_C_CATBED_HTR_A_CURR,                                  296,    4,    8;
;PDU_WHEEL3_CURR,                                              297,    4,    8;
;PDU_LOWSIDE_GRP5_PULSE_CURR,                                  298,    4,    8;
;PDU_IMU_A_GB_ONPPSMB_PULSE_CURR_GRP5,                         298,    4,    8;
;PDU_IMU_A_GC_ONPPSMB_PULSE_CURR_GRP5,                         298,    4,    8;
;PDU_WHEEL1_ON_PULSE_CURR_GRP5,                                298,    4,    8;
;PDU_WHEEL1_OFF_PULSE_CURR_GRP5,                               298,    4,    8;
;PDU_PUMP_B_CURR,                                              299,    4,    8;
;PDU_ACTUATOR_HTR_A_CURR,                                      300,    4,    8;
;PDU_SWEAP_SPAN_AB_SURV_HTRS_CURR,                             301,    4,    8;
;PDU_LOWSIDE_A_GRP22_CURR,                                     302,    4,    8;
;PDU_THR_BUS_GRP_1_TAC_A_CURR_GRP22,                           302,    4,    8;
;PDU_THR_BUS_GRP_2_TAC_A_CURR_GRP22,                           302,    4,    8;
;PDU_FIELDS1_PREAMP_AND_SURV_HTRS_CURR,                        303,    4,    8;
;PDU_SSE_A_CURR,                                               304,    4,    8;
;PDU_DP_SENSR_A_CURR,                                          305,    4,    8;
;PDU_IMU_B_CURR,                                               306,    4,    8;
;PDU_LOWSIDE_GRP8_PULSE_CURR,                                  307,    4,    8;
;PDU_PROP_LV_A_OPEN_PULSE_CURR_GRP8,                           307,    4,    8;
;PDU_FIELDS2_V3_V4_DEPLOY_A_PULSE_CURR_GRP8,                   307,    4,    8;
;PDU_LOWSIDE_GRP9_CURR,                                        308,    4,    8;
;PDU_MAG_BOOM_DEPLOY_1A_CURR_GRP9,                             308,    4,    8;
;PDU_SA_PLATEN_POSY_DEPLOY_A_CURR_GRP9,                        308,    4,    8;
;PDU_SA_PLATEN_NEGY_DEPLOY_A_CURR_GRP9,                        308,    4,    8;
;PDU_HGA_DEPLOY_A_CURR_GRP9,                                   308,    4,    8;
;PDU_SWEAP_SPC_SURV_HTR_CURR,                                  309,    4,    8;
;PDU_PSE_B_CURR,                                               310,    4,    8;
;PDU_WISPR_CURR,                                               311,    4,    8;
;PDU_LOWSIDE_GRP7_PULSE_CURR,                                  312,    4,    8;
;PDU_WHEEL3_ON_PULSE_CURR_GRP7,                                312,    4,    8;
;PDU_WHEEL3_OFF_PULSE_CURR_GRP7,                               312,    4,    8;
;PDU_LOWSIDE_GRP23_CURR,                                       313,    4,    8;
;PDU_GRP_A_CATBED_HTR_B_CURR_GRP23,                            313,    4,    8;
;PDU_GRP_B_CATBED_HTR_B_CURR_GRP23,                            313,    4,    8;
;PDU_GRP_C_CATBED_HTR_B_CURR_GRP23,                            313,    4,    8;
;PDU_PUMP_A_CURR,                                              314,    4,    8;
;PDU_ACTUATOR_HTR_B_CURR,                                      315,    4,    8;
;PDU_EPIHI_CURR,                                               316,    4,    8;
;PDU_LOWSIDE_B_GRP22_CURR,                                     317,    4,    8;
;PDU_THR_BUS_GRP_1_TAC_B_CURR_GRP22,                           317,    4,    8;
;PDU_THR_BUS_GRP_2_TAC_B_CURR_GRP22,                           317,    4,    8;
;PDU_FIELDS2_PREAMP_AND_SURV_HTRS_CURR,                        318,    4,    8;
;PDU_SSE_B_CURR,                                               319,    4,    8;
;PDU_DP_SENSR_B_CURR,                                          320,    4,    8;
;PDU_IMU_A_CURR,                                               321,    4,    8;
;PDU_LOWSIDE_GRP17_PULSE_CURR,                                 322,    4,    8;
;PDU_PROP_LV_B_OPEN_PULSE_CURR_GRP17,                          322,    4,    8;
;PDU_FIELDS2_V3_V4_DEPLOY_B_PULSE_CURR_GRP17,                  322,    4,    8;
;PDU_LOWSIDE_GRP18_CURR,                                       323,    4,    8;
;PDU_SA_PLATEN_POSY_DEPLOY_B_CURR_GRP18,                       323,    4,    8;
;PDU_SA_PLATEN_NEGY_DEPLOY_B_CURR_GRP18,                       323,    4,    8;
;PDU_MAG_BOOM_DEPLOY_1B_CURR_GRP18,                            323,    4,    8;
;PDU_HGA_DEPLOY_B_CURR_GRP18,                                  323,    4,    8;
;PDU_PROP_LV_B_CLOSE_PULSE_CURR,                               324,    4,    8;
;PDU_PSE_A_CURR,                                               325,    4,    8;
;PDU_LOWSIDE_GRP16_PULSE_CURR,                                 326,    4,    8;
;PDU_WHEEL4_ON_PULSE_CURR_GRP16,                               326,    4,    8;
;PDU_WHEEL4_OFF_PULSE_CURR_GRP16,                              326,    4,    8;
;PDU_GRP_A_CATBED_HTR_A_CURR,                                  327,    4,    8;
;PDU_INT_PANEL_SURV_HTRS_B_CURR,                               328,    4,    8;
;PDU_RF_SWCH4_POSA_PULSE_CURR,                                 329,    4,    8;
;PDU_RF_SWCH4_POSB_PULSE_CURR,                                 330,    4,    8;
;PDU_PROP_NEGY_VHTRS_A_CURR,                                   331,    4,    8;
;PDU_LOWSIDE_GRP24_PULSE_CURR,                                 332,    4,    8;
;PDU_CSPR23_UP_LV_B_PULSE_CURR_GRP24,                          332,    4,    8;
;PDU_CSPR23_DOWN_LV_B_PULSE_CURR_GRP24,                        332,    4,    8;
;PDU_MC_C_RESTART_INH_CURR,                                    333,    4,    8;
;PDU_EPILO_SURV_HTR_CURR,                                      334,    4,    8;
;PDU_PROP_PRESXDCR_B_CURR,                                     335,    4,    8;
;PDU_ST_AND_PROP_LINE_SURV_HTRS_B_CURR,                        336,    4,    8;
;PDU_LOWSIDE_GRP15_PULSE_CURR,                                 337,    4,    8;
;PDU_SACS_ACCUM_LV_OPEN_B_PULSE_CURR_GRP15,                    337,    4,    8;
;PDU_FIELDS1_V1_V2_DEPLOY_B_PULSE_CURR_GRP15,                  337,    4,    8;
;PDU_LOWSIDE_B_GRP21_CURR,                                     338,    4,    8;
;PDU_ECU_B_CURR_GRP21,                                         338,    4,    8;
;PDU_PUMP_ENA_B_FOR_PUMP_A_CURR_GRP21,                         338,    4,    8;
;PDU_PUMP_ENA_B_FOR_PUMP_B_CURR_GRP21,                         338,    4,    8;
;PDU_WISPR_OPER_HTRS_CURR,                                     339,    4,    8;
;PDU_PROP_LV_A_CLOSE_PULSE_CURR,                               340,    4,    8;
;PDU_GRP_B_CATBED_HTR_A_CURR,                                  341,    4,    8;
;PDU_WHEEL4_CURR,                                              342,    4,    8;
;PDU_LOWSIDE_GRP14_PULSE_CURR,                                 343,    4,    8;
;PDU_IMU_B_GA_ONPPSMB_PULSE_CURR_GRP14,                        343,    4,    8;
;PDU_IMU_B_GD_ONPPSMB_PULSE_CURR_GRP14,                        343,    4,    8;
;PDU_WHEEL2_ON_PULSE_CURR_GRP14,                               343,    4,    8;
;PDU_WHEEL2_OFF_PULSE_CURR_GRP14,                              343,    4,    8;
;PDU_WHEEL2_CURR,                                              344,    4,    8;
;PDU_RF_SWCH2_POSA_PULSE_CURR,                                 345,    4,    8;
;PDU_RF_SWCH2_POSB_PULSE_CURR,                                 346,    4,    8;
;PDU_PROP_POSY_VHTRS_B_CURR,                                   347,    4,    8;
;PDU_LOWSIDE_B_GRP19_CURR,                                     348,    4,    8;
;PDU_TWTA_KA_B_CURR_GRP19,                                     348,    4,    8;
;PDU_TWTA_X_B_CURR_GRP19,                                      348,    4,    8;
;PDU_MC_B_RESTART_INH_CURR,                                    349,    4,    8;
;PDU_EPIHI_SURV_HTR_CURR,                                      350,    4,    8;
;PDU_ST1_CURR,                                                 351,    4,    8;
;PDU_WISPR_SURV_HTR_CURR,                                      352,    4,    8;
;PDU_LOWSIDE_GRP12_CURR,                                       353,    4,    8;
;PDU_SA_BOOM_POSY_DEPLOY_B_CURR_GRP12,                         353,    4,    8;
;PDU_SA_BOOM_NEGY_DEPLOY_B_CURR_GRP12,                         353,    4,    8;
;PDU_LOWSIDE_GRP13_CURR,                                       354,    4,    8;
;PDU_MAG_BOOM_DEPLOY_2B_CURR_GRP13,                            354,    4,    8;
;PDU_FIELDS_ANT_HINGE_3_DEPLOY_PULSE_CURR_GRP13,               354,    4,    8;
;PDU_FIELDS_ANT_HINGE_4_DEPLOY_PULSE_CURR_GRP13,               354,    4,    8;
;PDU_FIELDS_ANT_HINGES_1_2_DEPLOY_PULSE_CURR_GRP13,            354,    4,    8;
;PDU_WISPR_DOOR_DEPLOY_B_PULSE_CURR_GRP13,                     354,    4,    8;
;PDU_SPAN_DOOR_CVR_HTR_B_CURR_GRP13,                           354,    4,    8;
;PDU_FIELDS2_MAG_AND_SURV_HTRS_CURR,                           355,    4,    8;
;PDU_FIELDS1_CURR,                                             356,    4,    8;
;PDU_LOWSIDE_GRP10_PULSE_CURR,                                 357,    4,    8;
;PDU_IMU_B_IRU_ON_PULSE_CURR_GRP10,                            357,    4,    8;
;PDU_IMU_B_IRU_OFF_PULSE_CURR_GRP10,                           357,    4,    8;
;PDU_IMU_B_PPSMB_SEL_PULSE_CURR_GRP10,                         357,    4,    8;
;PDU_LOWSIDE_GRP11_PULSE_CURR,                                 358,    4,    8;
;PDU_IMU_B_AA_OFF_PULSE_CURR_GRP11,                            358,    4,    8;
;PDU_IMU_B_AD_ON_PULSE_CURR_GRP11,                             358,    4,    8;
;PDU_IMU_B_IRU_RST_PULSE_CURR_GRP11,                           358,    4,    8;
;RADIOA_PATH_ID,                                               359,    4,    3;
;RADIOA_STATUS_DSP_MODE_CMD_EXEC_CNT,                          359,    1,    8;
;RADIOA_STATUS_DSP_MODE_CMD_REJ_CNT,                           360,    1,    8;
;RADIOA_STATUS_DSP_MET_SUBSEC,                                 361,    1,   16;
;RADIOA_STATUS_DSP_MET_SEC,                                    363,    1,   32;
;RADIOA_STATUS_RX_1_NB_PWR_MASTER_SWCH_CNT,                    367,    1,   12;
;RADIOA_STATUS_DSP_EX_COHERENCY_FLTR_ENA,                      369,    5,    1;
;RADIOA_STATUS_SCRUB_REG_CNT,                                  369,    4,    8;
;RADIOA_STATUS_SCRUB_EXT_SRAM_CNT,                             370,    4,    8;
;RADIOA_STATUS_DSP_STATUS_FRAME_SENT_CNT,                      371,    4,    8;
;RADIOA_STATUS_MISSION_MODE_SEL,                               372,    4,    5;
;RADIOA_STATUS_RADIO_SIDE,                                     373,    7,    1;
;RADIOA_STATUS_EX_1_ENA,                                       373,    6,    1;
;RADIOA_STATUS_EX_2_ENA,                                       373,    5,    1;
;RADIOA_STATUS_EX_1_FAULT_STATUS,                              373,    4,    4;
;RADIOA_STATUS_EX_2_FAULT_STATUS,                              373,    0,    4;
;RADIOA_STATUS_ENCC_ENCODING_SEL,                              374,    4,    8;
;RADIOA_STATUS_MODC_MOD_SEL,                                   375,    4,    8;
;RADIOA_STATUS_DSP_SPW_RMAP_REJ_CNT,                           376,    4,    8;
;RADIOA_STATUS_MODC_TLM_CRC_ERR_CNT,                           377,    4,    8;
;RADIOA_STATUS_ENCC_FRAME_LENGTH,                              378,    4,   12;
;RADIOA_STATUS_MODC_DATA_RATE,                                 379,    0,   28;
;RADIOA_STATUS_DSP_FAULT_STATUS,                               383,    4,    4;
;RADIOA_STATUS_DSP_TLM_DL_CNT,                                 383,    0,    8;
;RADIOA_STATUS_MODC_BEACON_SEL,                                384,    0,    8;
;RADIOA_STATUS_MODC_DOR_SEL,                                   385,    0,    1;
;RADIOA_STATUS_SEU_SRAM_CNT,                                   386,    7,    8;
;RADIOA_STATUS_SEFI_DAC_CNT,                                   387,    7,    8;
;RADIOA_STATUS_SW_WDOG_TICK_CNT,                               388,    7,   16;
;RADIOA_STATUS_DSP_SEE_CNT,                                    390,    7,   16;
;RADIOA_STATUS_DSP_DEE_CNT,                                    392,    7,   16;
;RADIOB_PATH_ID,                                               394,    7,    3;
;RADIOB_STATUS_DSP_MODE_CMD_EXEC_CNT,                          394,    4,    8;
;RADIOB_STATUS_DSP_MODE_CMD_REJ_CNT,                           395,    4,    8;
;RADIOB_STATUS_DSP_MET_SUBSEC,                                 396,    4,   16;
;RADIOB_STATUS_DSP_MET_SEC,                                    398,    4,   32;
;RADIOB_STATUS_RX_1_NB_PWR_MASTER_SWCH_CNT,                    402,    4,   12;
;RADIOB_STATUS_DSP_EX_COHERENCY_FLTR_ENA,                      403,    0,    1;
;RADIOB_STATUS_SCRUB_REG_CNT,                                  404,    7,    8;
;RADIOB_STATUS_SCRUB_EXT_SRAM_CNT,                             405,    7,    8;
;RADIOB_STATUS_DSP_STATUS_FRAME_SENT_CNT,                      406,    7,    8;
;RADIOB_STATUS_MISSION_MODE_SEL,                               407,    7,    5;
;RADIOB_STATUS_RADIO_SIDE,                                     407,    2,    1;
;RADIOB_STATUS_EX_1_ENA,                                       407,    1,    1;
;RADIOB_STATUS_EX_2_ENA,                                       407,    0,    1;
;RADIOB_STATUS_EX_1_FAULT_STATUS,                              408,    7,    4;
;RADIOB_STATUS_EX_2_FAULT_STATUS,                              408,    3,    4;
;RADIOB_STATUS_ENCC_ENCODING_SEL,                              409,    7,    8;
;RADIOB_STATUS_MODC_MOD_SEL,                                   410,    7,    8;
;RADIOB_STATUS_DSP_SPW_RMAP_REJ_CNT,                           411,    7,    8;
;RADIOB_STATUS_MODC_TLM_CRC_ERR_CNT,                           412,    7,    8;
;RADIOB_STATUS_ENCC_FRAME_LENGTH,                              413,    7,   12;
;RADIOB_STATUS_MODC_DATA_RATE,                                 414,    3,   28;
;RADIOB_STATUS_DSP_FAULT_STATUS,                               418,    7,    4;
;RADIOB_STATUS_DSP_TLM_DL_CNT,                                 418,    3,    8;
;RADIOB_STATUS_MODC_BEACON_SEL,                                419,    3,    8;
;RADIOB_STATUS_MODC_DOR_SEL,                                   420,    3,    1;
;RADIOB_STATUS_SEU_SRAM_CNT,                                   420,    2,    8;
;RADIOB_STATUS_SEFI_DAC_CNT,                                   421,    2,    8;
;RADIOB_STATUS_SW_WDOG_TICK_CNT,                               422,    2,   16;
;RADIOB_STATUS_DSP_SEE_CNT,                                    424,    2,   16;
;RADIOB_STATUS_DSP_DEE_CNT,                                    426,    2,   16;
;FSW_GC_HK_HK_PARRAYS_AVG0,                                    428,    2,   16;
;FSW_GC_HK_HK_PARRAYS_AVG1,                                    430,    2,   16;
;FSW_GC_HK_HK_TEMP_ARRAY_FILTER_STATE_TDOT,                    432,    2,   16;
;FSW_GC_HK_HK_PLOAD_AVG,                                       434,    2,   16;
;FSW_GC_HK_HK_HGA_GUIDANCE_ANGLE,                              436,    2,   16;
;FSW_GC_HK_HK_ACT_ANG_INIT_CODE0,                              438,    2,    8;
;FSW_GC_HK_HK_ACT_ANG_INIT_CODE1,                              439,    2,    8;
;FSW_GC_HK_HK_PLOAD_AVG_VALID,                                 440,    2,    8;
;FSW_GC_HK_HK_PARRAYS_AVG_VALID,                               441,    2,    8;
;FSW_AUT_FAULT_ROLLING_AUT_RULE_NUM3,                          442,    2,   16;
;FSW_AUT_FAULT_ROLLING_AUT_RULE_MET3,                          444,    2,   32;
;FSW_AUT_FAULT_ROLLING_AUT_RULE_NUM4,                          448,    2,   16;
;FSW_AUT_FAULT_ROLLING_AUT_RULE_MET4,                          450,    2,   32;
;FSW_AUT_FAULT_ROLLING_AUT_RULE_NUM5,                          454,    2,   16;
;FSW_AUT_FAULT_ROLLING_AUT_RULE_MET5,                          456,    2,   32;
;SCIF_PING_PONG_1_HZ,                                          460,    2,    1;
;SCIF_POR_RESET_STATUS,                                        460,    1,    1;
;SCIF_RED_POR_RESET_STATUS,                                    460,    0,    1;
;TAC_RIU_C_BUS_ERR,                                            461,    7,    1;
;TAC_RIU_B_BUS_ERR,                                            461,    6,    1;
;TAC_RIU_A_BUS_ERR,                                            461,    5,    1;
;TAC_RELAY_TT_REG,                                             461,    4,   32;
;TAC_IMU_RELAY_TT,                                             465,    4,    1;
;TAC_REM_A_B_TT,                                               465,    3,    1;
;TAC_POR_RESET_STATUS,                                         465,    2,    1;
;TAC_RED_RELAY_TT_REG,                                         465,    1,   32;
;TAC_RED_IMU_RELAY_TT,                                         469,    1,    1;
;TAC_RED_REM_A_B_TT,                                           469,    0,    1;
;TAC_RED_POR_RESET_STATUS,                                     470,    7,    1;
;FSW_SPP_HK_SBC_PR_CHNL_1_SBC_3P3V,                            470,    6,   10;
;FSW_SPP_HK_SBC_PR_CHNL_0_SBC_5V,                              471,    4,   10;
;FSW_SPP_HK_SBC_PR_CHNL_3_SRAM_CORE_1P8V,                      472,    2,   10;
;FSW_SPP_HK_SBC_PR_CHNL_2_FLASH_3P3V,                          473,    0,   10;
;FSW_SPP_HK_SBC_PR_CHNL_5_LEON_CORE_1P2V,                      475,    6,   10;
;FSW_SPP_HK_SBC_PR_CHNL_4_FPGA_CORE_1P5V,                      476,    4,   10;
;FSW_SPP_HK_SBC_PR_CHNL_9_MC_3P3V,                             477,    2,   10;
;FSW_SPP_HK_SBC_PR_CHNL_8_MC_DCDC_5V,                          478,    0,   10;
;FSW_SPP_HK_SBC_PR_CHNL_11_SPARE_TLM_3,                        480,    6,   10;
;FSW_SPP_HK_SBC_PR_CHNL_10_MC_2P5V,                            481,    4,   10;
;FSW_SPP_HK_SBC_PR_CHNL_15_CAL_RESISTOR_1KOHM_UPR,             482,    2,   10;
;FSW_SPP_HK_SBC_PR_CHNL_15_CAL_RESISTOR_1KOHM_LWR,             483,    0,   10;
;HS_FSW_SPP_HK_SBC_HS_CHNL_1_SBC_3P3V,                         485,    6,   10;
;HS_FSW_SPP_HK_SBC_HS_CHNL_0_SBC_5V,                           486,    4,   10;
;HS_FSW_SPP_HK_SBC_HS_CHNL_3_SRAM_CORE_1P8V,                   487,    2,   10;
;HS_FSW_SPP_HK_SBC_HS_CHNL_2_FLASH_3P3V,                       488,    0,   10;
;HS_FSW_SPP_HK_SBC_HS_CHNL_5_LEON_CORE_1P2V,                   490,    6,   10;
;HS_FSW_SPP_HK_SBC_HS_CHNL_4_FPGA_CORE_1P5V,                   491,    4,   10;
;HS_FSW_SPP_HK_SBC_HS_CHNL_9_MC_3P3V,                          492,    2,   10;
;HS_FSW_SPP_HK_SBC_HS_CHNL_8_MC_DCDC_5V,                       493,    0,   10;
;HS_FSW_SPP_HK_SBC_HS_CHNL_11_SPARE_TLM_3,                     495,    6,   10;
;HS_FSW_SPP_HK_SBC_HS_CHNL_10_MC_2P5V,                         496,    4,   10;
;HS_FSW_SPP_HK_SBC_HS_CHNL_15_CAL_RESISTOR_1KOHM_UPR,          497,    2,   10;
;HS_FSW_SPP_HK_SBC_HS_CHNL_15_CAL_RESISTOR_1KOHM_LWR,          498,    0,   10;
;BS_FSW_SPP_HK_SBC_BS_CHNL_1_SBC_3P3V,                         500,    6,   10;
;BS_FSW_SPP_HK_SBC_BS_CHNL_0_SBC_5V,                           501,    4,   10;
;BS_FSW_SPP_HK_SBC_BS_CHNL_3_SRAM_CORE_1P8V,                   502,    2,   10;
;BS_FSW_SPP_HK_SBC_BS_CHNL_2_FLASH_3P3V,                       503,    0,   10;
;BS_FSW_SPP_HK_SBC_BS_CHNL_5_LEON_CORE_1P2V,                   505,    6,   10;
;BS_FSW_SPP_HK_SBC_BS_CHNL_4_FPGA_CORE_1P5V,                   506,    4,   10;
;BS_FSW_SPP_HK_SBC_BS_CHNL_9_MC_3P3V,                          507,    2,   10;
;BS_FSW_SPP_HK_SBC_BS_CHNL_8_MC_DCDC_5V,                       508,    0,   10;
;BS_FSW_SPP_HK_SBC_BS_CHNL_11_SPARE_TLM_3,                     510,    6,   10;
;BS_FSW_SPP_HK_SBC_BS_CHNL_10_MC_2P5V,                         511,    4,   10;
;BS_FSW_SPP_HK_SBC_BS_CHNL_15_CAL_RESISTOR_1KOHM_UPR,          512,    2,   10;
;BS_FSW_SPP_HK_SBC_BS_CHNL_15_CAL_RESISTOR_1KOHM_LWR,          513,    0,   10;
;FSW_CI_HK_RADIOA_TCTF_RCV_CNT,                                515,    6,   16;
;FSW_CI_HK_XPDRA_TCTF_RCV_CNT,                                 515,    6,   16;
;FSW_CI_HK_RADIOB_TCTF_RCV_CNT,                                517,    6,   16;
;FSW_CI_HK_XPDRB_TCTF_RCV_CNT,                                 517,    6,   16;
;FSW_CI_HK_RADIOA_TCTF_DROP_CNT,                               519,    6,   16;
;FSW_CI_HK_RADIOA_TCTF_DRP_CNT,                                519,    6,   16;
;FSW_CI_HK_RADIOB_TCTF_DROP_CNT,                               521,    6,   16;
;FSW_CI_HK_RADIOB_TCTF_DRP_CNT,                                521,    6,   16;
;FSW_CM_HK_AUT_CMD_TIMEOUT_CNT_LSB,                            523,    6,    8;
;FSW_CM_HK_TT_CMD_TIMEOUT_CNT_LSB,                             524,    6,    8;
;FSW_CM_HK_FI_CMD_TIMEOUT_CNT_LSB,                             525,    6,    8;
;FSW_CM_HK_FI_MACRO_CMD_TIMEOUT_CNT_LSB,                       526,    6,    8;
;FSW_CM_HK_MACRO_LOAD_FAIL_CNT_LSB,                            527,    6,    8;
;FSW_CM_HK_MACRO_LD_FAIL_CNT_LSB,                              527,    6,    8;
;FSW_CM_HK_CMD_SEND_FAIL_CNT_LSB,                              528,    6,    8;
;FSW_CPU_HK_WARM_RESET_CNT,                                    529,    6,   32;
;FSW_CPU_HK_WARM_RESET_COUNT,                                  529,    6,   32;
;FSW_TTAG_HK_RULE_FIRED_CNT,                                   533,    6,   16;
;FSW_CFE_ES_ES_HK_RESET_TYPE,                                  535,    6,    8;
;SC_FSW_CFE_ES_ES_HK_RESET_TYPE,                               535,    6,    8;
;FSW_CFE_ES_ES_HK_RESET_SUBTYPE,                               536,    6,   32;
;SC_FSW_CFE_ES_ES_HK_RESET_SUBTYPE,                            536,    6,   32;
;FSW_CFE_ES_ES_HK_CPU_RESETS,                                  540,    6,    8;
;SC_FSW_CFE_ES_ES_HK_CPU_RESETS,                               540,    6,    8;
;HS_FSW_CPU_HK_WARM_RESET_CNT,                                 541,    6,   32;
;HS_FSW_CPU_HK_WARM_RESET_COUNT,                               541,    6,   32;
;HS_FSW_CFE_ES_ES_HK_RESET_TYPE,                               545,    6,    8;
;HS_FSW_CFE_ES_ES_HK_RESET_SUBTYPE,                            546,    6,   32;
;HS_FSW_CFE_ES_ES_HK_CPU_RESETS,                               550,    6,    8;
;BS_FSW_CPU_HK_WARM_RESET_CNT,                                 551,    6,   32;
;BS_FSW_CPU_HK_WARM_RESET_COUNT,                               551,    6,   32;
;BS_FSW_CFE_ES_ES_HK_RESET_TYPE,                               555,    6,    8;
;BS_FSW_CFE_ES_ES_HK_RESET_SUBTYPE,                            556,    6,   32;
;BS_FSW_CFE_ES_ES_HK_CPU_RESETS,                               560,    6,    8;
;FSW_SPP_HK_SBC_PR_CHNL_13_MC_TEMP,                            561,    6,   10;
;FSW_SPP_HK_SBC_PR_CHNL_12_MC_DCDC_TEMP,                       562,    4,   10;
;FSW_SPP_HK_SBC_PR_CHNL_14_SBC_LEON_TEMP,                      563,    2,   10;
;HS_FSW_SPP_HK_SBC_HS_CHNL_13_MC_TEMP,                         564,    0,   10;
;HS_FSW_SPP_HK_SBC_HS_CHNL_12_MC_DCDC_TEMP,                    566,    6,   10;
;HS_FSW_SPP_HK_SBC_HS_CHNL_14_SBC_LEON_TEMP,                   567,    4,   10;
;BS_FSW_SPP_HK_SBC_BS_CHNL_13_MC_TEMP,                         568,    2,   10;
;BS_FSW_SPP_HK_SBC_BS_CHNL_12_MC_DCDC_TEMP,                    569,    0,   10;
;BS_FSW_SPP_HK_SBC_BS_CHNL_14_SBC_LEON_TEMP,                   571,    6,   10;
;SC_HK_MED_DERIVED_TRIGGER_PT,                                 571,    6,   10;
;}
