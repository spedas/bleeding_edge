;Ali: June 2020
;+
; $LastChangedBy: ali $
; $LastChangedDate: 2020-12-09 08:27:23 -0800 (Wed, 09 Dec 2020) $
; $LastChangedRevision: 29449 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SPP/COMMON/sc/spp_sc_hk_0x1de_apdat__define.pro $
;-

function spp_SC_HK_0x1de_struct,ccsds_data
  if n_elements(ccsds_data) eq 0 then ccsds_data = bytarr(67)

  RIU_DERIVED_D_FIELDS_V1_CLAMSHELL_DEPLOY_TT_PRI_TEMP=spp_swp_data_select(ccsds_data, 78*8+7-7,16)
  RIU_DERIVED_D_FIELDS_V2_CLAMSHELL_DEPLOY_TT_PRI_TEMP=spp_swp_data_select(ccsds_data, 80*8+7-7,16)
  RIU_DERIVED_D_FIELDS_V3_CLAMSHELL_DEPLOY_TT_PRI_TEMP=spp_swp_data_select(ccsds_data, 82*8+7-7,16)
  RIU_DERIVED_D_FIELDS_V4_CLAMSHELL_DEPLOY_TT_PRI_TEMP=spp_swp_data_select(ccsds_data,144*8+7-7,16)
  RIU_DERIVED_D_FIELDS_V1_CLAMSHELL_DEPLOY_TT_RED_TEMP=spp_swp_data_select(ccsds_data,112*8+7-7,16)
  RIU_DERIVED_D_FIELDS_V2_CLAMSHELL_DEPLOY_TT_RED_TEMP=spp_swp_data_select(ccsds_data,110*8+7-7,16)
  RIU_DERIVED_D_FIELDS_V3_CLAMSHELL_DEPLOY_TT_RED_TEMP=spp_swp_data_select(ccsds_data,108*8+7-7,16)
  RIU_DERIVED_D_FIELDS_V4_CLAMSHELL_DEPLOY_TT_RED_TEMP=spp_swp_data_select(ccsds_data,178*8+7-7,16)
  RIU_DERIVED_D_FIELDS_V4_CLAMSHELL_DEPLOY_TT_RED_TEMP=spp_swp_data_select(ccsds_data,178*8+7-7,16)
  RIU_DERIVED_D_FIELDS_PLASMA_WAVE_PRE_AMP_1_TEMP=     spp_swp_data_select(ccsds_data, 84*8+7-7,16)
  RIU_DERIVED_D_FIELDS_PLASMA_WAVE_PRE_AMP_2_TEMP=     spp_swp_data_select(ccsds_data,116*8+7-7,16)
  RIU_DERIVED_D_FIELDS_PLASMA_WAVE_PRE_AMP_3_TEMP=     spp_swp_data_select(ccsds_data,094*8+7-7,16)
  RIU_DERIVED_D_FIELDS_PLASMA_WAVE_PRE_AMP_4_TEMP=     spp_swp_data_select(ccsds_data,114*8+7-7,16)
  RIU_DERIVED_D_WHEEL1_TEMP=                           spp_swp_data_select(ccsds_data,348*8+7-7,16)
  RIU_DERIVED_D_WHEEL2_TEMP=                           spp_swp_data_select(ccsds_data,370*8+7-7,16)
  RIU_DERIVED_D_WHEEL3_TEMP=                           spp_swp_data_select(ccsds_data,350*8+7-7,16)
  RIU_DERIVED_D_WHEEL4_TEMP=                           spp_swp_data_select(ccsds_data,374*8+7-7,16)
  RIU_DERIVED_D_WHEEL1_BEARING_TEMP=                   spp_swp_data_select(ccsds_data,388*8+7-7,16)
  RIU_DERIVED_D_WHEEL2_BEARING_TEMP=                   spp_swp_data_select(ccsds_data,364*8+7-7,16)
  RIU_DERIVED_D_WHEEL3_BEARING_TEMP=                   spp_swp_data_select(ccsds_data,390*8+7-7,16)
  RIU_DERIVED_D_WHEEL4_BEARING_TEMP=                   spp_swp_data_select(ccsds_data,366*8+7-7,16)
  RIU_DERIVED_D_SLS_1_TEMP=                            spp_swp_data_select(ccsds_data,150*8+7-7,16)
  RIU_DERIVED_D_SLS_2_TEMP=                            spp_swp_data_select(ccsds_data,184*8+7-7,16)
  RIU_DERIVED_D_SLS_3_TEMP=                            spp_swp_data_select(ccsds_data,180*8+7-7,16)
  RIU_DERIVED_D_SLS_4_TEMP=                            spp_swp_data_select(ccsds_data,148*8+7-7,16)
  RIU_DERIVED_D_SLS_5_TEMP=                            spp_swp_data_select(ccsds_data,166*8+7-7,16)
  RIU_DERIVED_D_SLS_6_TEMP=                            spp_swp_data_select(ccsds_data,152*8+7-7,16)
  RIU_DERIVED_D_SLS_7_TEMP=                            spp_swp_data_select(ccsds_data,146*8+7-7,16)

  a0 = -200.
  a1 = 500./65535
  str = {time:!values.d_nan ,$
    met:!values.d_nan, $
    seqn: 0u, $
    pkt_size: 0u, $
    RIU_DERIVED_D_SWEAP_SPAN_B_ELECT_BOX_TEMP:a0+a1*        spp_swp_data_select(ccsds_data,136*8+7-7,16), $
    RIU_DERIVED_D_SWEAP_SPAN_B_TOP_ANALYZER_TEMP:a0+a1*     spp_swp_data_select(ccsds_data,142*8+7-7,16), $
    RIU_DERIVED_D_SWEAP_SPAN_A_POS_TOP_ANALYZER_TEMP:a0+a1* spp_swp_data_select(ccsds_data,176*8+7-7,16), $
    RIU_DERIVED_D_SWEAP_SPAN_B_PEDESTAL_TEMP:a0+a1*         spp_swp_data_select(ccsds_data,234*8+7-7,16), $
    RIU_DERIVED_D_SWEAP_SPAN_A_POS_ELECT_BOX_TEMP:a0+a1*    spp_swp_data_select(ccsds_data,264*8+7-7,16), $
    RIU_DERIVED_D_SWEAP_SPC_PRE_AMP_TEMP:a0+a1*             spp_swp_data_select(ccsds_data,270*8+7-7,16), $
    RIU_DERIVED_D_SWEAP_SPAN_A_POS_PEDESTAL_TEMP:a0+a1*     spp_swp_data_select(ccsds_data,296*8+7-7,16), $
    RIU_DERIVED_D_SWEAP_SWEM_TEMP:a0+a1*                    spp_swp_data_select(ccsds_data,416*8+7-7,16), $
    RIU_DERIVED_D_TOP_OF_BARRIER_BLANKET_TEMP:a0+a1*        spp_swp_data_select(ccsds_data,102*8+7-7,16), $
    RIU_DERIVED_D_HGA_DISH_TEMP:a0+a1*                      spp_swp_data_select(ccsds_data,156*8+7-7,16), $
    RIU_DERIVED_D_BATT_TEMP:a0+a1*                          spp_swp_data_select(ccsds_data,310*8+7-7,16), $
    RIU_DERIVED_D_ECU_TEMP:a0+a1*                           spp_swp_data_select(ccsds_data,312*8+7-7,16), $
    RIU_DERIVED_D_PDU_TEMP:a0+a1*                           spp_swp_data_select(ccsds_data,314*8+7-7,16), $
    RIU_DERIVED_D_PSE_TEMP:a0+a1*                           spp_swp_data_select(ccsds_data,316*8+7-7,16), $
    RIU_DERIVED_D_SSE_TEMP:a0+a1*                           spp_swp_data_select(ccsds_data,418*8+7-7,16), $
    RIU_DERIVED_D_IMU_TEMP:a0+a1*                           spp_swp_data_select(ccsds_data,420*8+7-7,16), $
    RIU_DERIVED_D_PROP_TANK_BOT_TEMP:a0+a1*                 spp_swp_data_select(ccsds_data,362*8+7-7,16), $
    RIU_DERIVED_D_PROP_TANK_TOP_TEMP:a0+a1*                 spp_swp_data_select(ccsds_data,386*8+7-7,16), $
    RIU_DERIVED_D_FIELDS_MEP_TEMP:a0+a1*                    spp_swp_data_select(ccsds_data,398*8+7-7,16), $
    RIU_DERIVED_D_FIELDS_Vx_CLAMSHELL_DEPLOY_TT_PRI_TEMP:a0+a1*[RIU_DERIVED_D_FIELDS_V1_CLAMSHELL_DEPLOY_TT_PRI_TEMP,$
    RIU_DERIVED_D_FIELDS_V2_CLAMSHELL_DEPLOY_TT_PRI_TEMP,$
    RIU_DERIVED_D_FIELDS_V3_CLAMSHELL_DEPLOY_TT_PRI_TEMP,$
    RIU_DERIVED_D_FIELDS_V4_CLAMSHELL_DEPLOY_TT_PRI_TEMP],$
    RIU_DERIVED_D_FIELDS_Vx_CLAMSHELL_DEPLOY_TT_RED_TEMP:a0+a1*[RIU_DERIVED_D_FIELDS_V1_CLAMSHELL_DEPLOY_TT_RED_TEMP,$
    RIU_DERIVED_D_FIELDS_V2_CLAMSHELL_DEPLOY_TT_RED_TEMP,$
    RIU_DERIVED_D_FIELDS_V3_CLAMSHELL_DEPLOY_TT_RED_TEMP,$
    RIU_DERIVED_D_FIELDS_V4_CLAMSHELL_DEPLOY_TT_RED_TEMP],$
    RIU_DERIVED_D_FIELDS_PLASMA_WAVE_PRE_AMP_TEMP:a0+a1*[RIU_DERIVED_D_FIELDS_PLASMA_WAVE_PRE_AMP_1_TEMP,$
    RIU_DERIVED_D_FIELDS_PLASMA_WAVE_PRE_AMP_2_TEMP,$
    RIU_DERIVED_D_FIELDS_PLASMA_WAVE_PRE_AMP_3_TEMP,$
    RIU_DERIVED_D_FIELDS_PLASMA_WAVE_PRE_AMP_4_TEMP],$
    RIU_DERIVED_D_WHEEL_TEMP:a0+a1*[RIU_DERIVED_D_WHEEL1_TEMP,RIU_DERIVED_D_WHEEL2_TEMP,RIU_DERIVED_D_WHEEL3_TEMP,RIU_DERIVED_D_WHEEL4_TEMP],$
    RIU_DERIVED_D_WHEEL_BEARING_TEMP:a0+a1*[RIU_DERIVED_D_WHEEL1_BEARING_TEMP,RIU_DERIVED_D_WHEEL2_BEARING_TEMP,RIU_DERIVED_D_WHEEL3_BEARING_TEMP,RIU_DERIVED_D_WHEEL4_BEARING_TEMP],$
    RIU_DERIVED_D_SLS_TEMP:a0+a1*[RIU_DERIVED_D_SLS_1_TEMP,RIU_DERIVED_D_SLS_2_TEMP,RIU_DERIVED_D_SLS_3_TEMP,$
    RIU_DERIVED_D_SLS_4_TEMP,RIU_DERIVED_D_SLS_5_TEMP,RIU_DERIVED_D_SLS_6_TEMP,RIU_DERIVED_D_SLS_7_TEMP],$
    gap:0B}
  return, str
end

;Line 13125:     RIU_DERIVED_D_SWEAP_SPAN_B_ELECT_BOX_TEMP,                    136,    7,   16;
;Line 13128:     RIU_DERIVED_D_SWEAP_SPAN_B_TOP_ANALYZER_TEMP,                 142,    7,   16;
;Line 13145:     RIU_DERIVED_D_SWEAP_SPAN_A_POS_TOP_ANALYZER_TEMP,             176,    7,   16;
;Line 13174:     RIU_DERIVED_D_SWEAP_SPAN_B_PEDESTAL_TEMP,                     234,    7,   16;
;Line 13189:     RIU_DERIVED_D_SWEAP_SPAN_A_POS_ELECT_BOX_TEMP,                264,    7,   16;
;Line 13192:     RIU_DERIVED_D_SWEAP_SPC_PRE_AMP_TEMP,                         270,    7,   16;
;Line 13205:     RIU_DERIVED_D_SWEAP_SPAN_A_POS_PEDESTAL_TEMP,                 296,    7,   16;
;Line 13265:     RIU_DERIVED_D_SWEAP_SWEM_TEMP,                                416,    7,   16;

;Line 13096:     RIU_DERIVED_D_FIELDS_V1_CLAMSHELL_DEPLOY_TT_PRI_TEMP,          78,    7,   16;
;Line 13097:     RIU_DERIVED_D_FIELDS_V2_CLAMSHELL_DEPLOY_TT_PRI_TEMP,          80,    7,   16;
;Line 13098:     RIU_DERIVED_D_FIELDS_V3_CLAMSHELL_DEPLOY_TT_PRI_TEMP,          82,    7,   16;
;Line 13099:     RIU_DERIVED_D_FIELDS_PLASMA_WAVE_PRE_AMP_1_TEMP,               84,    7,   16;
;Line 13104:     RIU_DERIVED_D_FIELDS_PLASMA_WAVE_PRE_AMP_3_TEMP,               94,    7,   16;
;Line 13111:     RIU_DERIVED_D_FIELDS_V3_CLAMSHELL_DEPLOY_TT_RED_TEMP,         108,    7,   16;
;Line 13112:     RIU_DERIVED_D_FIELDS_V2_CLAMSHELL_DEPLOY_TT_RED_TEMP,         110,    7,   16;
;Line 13113:     RIU_DERIVED_D_FIELDS_V1_CLAMSHELL_DEPLOY_TT_RED_TEMP,         112,    7,   16;
;Line 13114:     RIU_DERIVED_D_FIELDS_PLASMA_WAVE_PRE_AMP_4_TEMP,              114,    7,   16;
;Line 13115:     RIU_DERIVED_D_FIELDS_PLASMA_WAVE_PRE_AMP_2_TEMP,              116,    7,   16;
;Line 13129:     RIU_DERIVED_D_FIELDS_V4_CLAMSHELL_DEPLOY_TT_PRI_TEMP,         144,    7,   16;
;Line 13146:     RIU_DERIVED_D_FIELDS_V4_CLAMSHELL_DEPLOY_TT_RED_TEMP,         178,    7,   16;
;Line 13256:     RIU_DERIVED_D_FIELDS_MEP_TEMP,                                398,    7,   16;

;Line 13130:     RIU_DERIVED_D_SLS_7_TEMP,                                     146,    7,   16;
;Line 13131:     RIU_DERIVED_D_SLS_5_TEMP,                                     148,    7,   16;
;Line 13132:     RIU_DERIVED_D_SLS_1_TEMP,                                     150,    7,   16;
;Line 13133:     RIU_DERIVED_D_SLS_6_TEMP,                                     152,    7,   16;
;Line 13147:     RIU_DERIVED_D_SLS_3_TEMP,                                     180,    7,   16;
;Line 13148:     RIU_DERIVED_D_SLS_4_TEMP,                                     182,    7,   16;
;Line 13149:     RIU_DERIVED_D_SLS_2_TEMP,                                     184,    7,   16;

;RIU_DERIVED_D_TOP_OF_BARRIER_BLANKET_TEMP,                    102,    7,   16;
;RIU_DERIVED_D_HGA_DISH_TEMP,                                  156,    7,   16;
;RIU_DERIVED_D_BATT_TEMP,                                      310,    7,   16;
;RIU_DERIVED_D_ECU_TEMP,                                       312,    7,   16;
;RIU_DERIVED_D_PDU_TEMP,                                       314,    7,   16;
;RIU_DERIVED_D_PSE_TEMP,                                       316,    7,   16;
;RIU_DERIVED_D_SSE_TEMP,                                       418,    7,   16;
;RIU_DERIVED_D_IMU_TEMP,                                       420,    7,   16;
;RIU_DERIVED_D_WHEEL1_TEMP,                                    348,    7,   16;
;RIU_DERIVED_D_WHEEL3_TEMP,                                    350,    7,   16;
;RIU_DERIVED_D_WHEEL2_BEARING_TEMP,                            364,    7,   16;
;RIU_DERIVED_D_WHEEL4_BEARING_TEMP,                            366,    7,   16;
;RIU_DERIVED_D_WHEEL2_TEMP,                                    370,    7,   16;
;RIU_DERIVED_D_WHEEL4_TEMP,                                    374,    7,   16;
;RIU_DERIVED_D_WHEEL1_BEARING_TEMP,                            388,    7,   16;
;RIU_DERIVED_D_WHEEL3_BEARING_TEMP,                            390,    7,   16;
;RIU_DERIVED_D_PROP_TANK_BOT_TEMP,                             362,    7,   16;
;RIU_DERIVED_D_PROP_TANK_TOP_TEMP,                             386,    7,   16;

;Line 320: EU(Raw='SC_HK_0x1DE.RIU_DERIVED_D_SWEAP_SPAN_B_ELECT_BOX_TEMP') := fCalCurve([0.0, 65535.0], [-200.0, 300.0], Raw)
;Line 323: EU(Raw='SC_HK_0x1DE.RIU_DERIVED_D_SWEAP_SPAN_B_TOP_ANALYZER_TEMP') := fCalCurve([0.0, 65535.0], [-200.0, 300.0], Raw)
;Line 340: EU(Raw='SC_HK_0x1DE.RIU_DERIVED_D_SWEAP_SPAN_A_POS_TOP_ANALYZER_TEMP') := fCalCurve([0.0, 65535.0], [-200.0, 300.0], Raw)
;Line 369: EU(Raw='SC_HK_0x1DE.RIU_DERIVED_D_SWEAP_SPAN_B_PEDESTAL_TEMP') := fCalCurve([0.0, 65535.0], [-200.0, 300.0], Raw)
;Line 384: EU(Raw='SC_HK_0x1DE.RIU_DERIVED_D_SWEAP_SPAN_A_POS_ELECT_BOX_TEMP') := fCalCurve([0.0, 65535.0], [-200.0, 300.0], Raw)
;Line 387: EU(Raw='SC_HK_0x1DE.RIU_DERIVED_D_SWEAP_SPC_PRE_AMP_TEMP') := fCalCurve([0.0, 65535.0], [-200.0, 300.0], Raw)
;Line 400: EU(Raw='SC_HK_0x1DE.RIU_DERIVED_D_SWEAP_SPAN_A_POS_PEDESTAL_TEMP') := fCalCurve([0.0, 65535.0], [-200.0, 300.0], Raw)
;Line 460: EU(Raw='SC_HK_0x1DE.RIU_DERIVED_D_SWEAP_SWEM_TEMP') := fCalCurve([0.0, 65535.0], [-200.0, 300.0], Raw)


function SPP_SC_HK_0x1de_apdat::decom,ccsds, source_dict=source_dict   ;,ptp_header=ptp_header

  ccsds_data = spp_swp_ccsds_data(ccsds)
  str2 = spp_SC_HK_0x1de_struct(ccsds_data)
  struct_assign,ccsds,str2,/nozero
  return,str2

end


pro spp_SC_HK_0x1de_apdat__define

  void = {spp_SC_HK_0x1de_apdat, $
    inherits spp_gen_apdat, $    ; superclass
    flag: 0 $
  }
end
;
;
;SC_HK_0x1DE
;{
;( Block[521],                                                      ,     ,    8; )
;RIU_DERIVED_TPPH_VERSION,                                       0,    7,    3;
;RIU_DERIVED_TPPH_TYPE,                                          0,    4,    1;
;RIU_DERIVED_TPPH_SEC_HDR_FLAG,                                  0,    3,    1;
;RIU_DERIVED_TPPH_APID,                                          0,    2,   11;
;SC_D_APID,                                                      0,    2,   11;
;RIU_DERIVED_TPPH_SEQ_FLAGS,                                     2,    7,    2;
;RIU_DERIVED_TPPH_SEQ_CNT,                                       2,    5,   14;
;RIU_DERIVED_TPPH_LENGTH,                                        4,    7,   16;
;RIU_DERIVED_TPSH_MET_SEC,                                       6,    7,   32;
;SC_D_MET_SEC,                                                   6,    7,   32;
;RIU_DERIVED_TPSH_MET_SUBSEC,                                   10,    7,    8;
;RIU_DERIVED_TPSH_SBC_PHYS_ID,                                  11,    7,    2;
;RIU_DERIVED_SCIF_SIDE,                                         12,    7,   32;
;RIU_DERIVED_D_RIU_1A_INTERNAL_TEMP,                            16,    7,   16;
;RIU_DERIVED_D_CSPR_4_A1_TEMP,                                  18,    7,   16;
;RIU_DERIVED_D_CSPR_4_A4_TEMP,                                  20,    7,   16;
;RIU_DERIVED_D_CSPR_4_A2_TEMP,                                  22,    7,   16;
;RIU_DERIVED_D_CSPR_3_A3_TEMP,                                  24,    7,   16;
;RIU_DERIVED_D_CSPR_3_A1_TEMP,                                  26,    7,   16;
;RIU_DERIVED_D_CSPR_2_A3_TEMP,                                  28,    7,   16;
;RIU_DERIVED_D_CSPR_2_A2_TEMP,                                  30,    7,   16;
;RIU_DERIVED_D_CSPR_1_A3_TEMP,                                  32,    7,   16;
;RIU_DERIVED_D_CSPR_3_A4_TEMP,                                  34,    7,   16;
;RIU_DERIVED_D_CSPR_1_A4_TEMP,                                  36,    7,   16;
;RIU_DERIVED_D_CSPR_4_A3_TEMP,                                  38,    7,   16;
;RIU_DERIVED_D_CSPR_1_A2_TEMP,                                  40,    7,   16;
;RIU_DERIVED_D_CSPR_3_A2_TEMP,                                  42,    7,   16;
;RIU_DERIVED_D_CHECK_VALVE_PRI_TEMP,                            44,    7,   16;
;RIU_DERIVED_D_RIU_1B_INTERNAL_TEMP,                            46,    7,   16;
;RIU_DERIVED_D_CSPR_3_B2_TEMP,                                  48,    7,   16;
;RIU_DERIVED_D_CSPR_4_B4_TEMP,                                  50,    7,   16;
;RIU_DERIVED_D_CSPR_4_B2_TEMP,                                  52,    7,   16;
;RIU_DERIVED_D_CSPR_3_B3_TEMP,                                  54,    7,   16;
;RIU_DERIVED_D_CSPR_2_B4_TEMP,                                  56,    7,   16;
;RIU_DERIVED_D_CSPR_2_B3_TEMP,                                  58,    7,   16;
;RIU_DERIVED_D_CSPR_2_B1_TEMP,                                  60,    7,   16;
;RIU_DERIVED_D_CSPR_2_B2_TEMP,                                  62,    7,   16;
;RIU_DERIVED_D_CSPR_1_B3_TEMP,                                  64,    7,   16;
;RIU_DERIVED_D_CSPR_1_B1_TEMP,                                  66,    7,   16;
;RIU_DERIVED_D_CSPR_1_B4_TEMP,                                  68,    7,   16;
;RIU_DERIVED_D_CSPR_1_B2_TEMP,                                  70,    7,   16;
;RIU_DERIVED_D_CSPR_4_B3_TEMP,                                  72,    7,   16;
;RIU_DERIVED_D_CHECK_VALVE_RED_TEMP,                            74,    7,   16;
;RIU_DERIVED_D_RIU_2A_INTERNAL_TEMP,                            76,    7,   16;
;RIU_DERIVED_D_FIELDS_V1_CLAMSHELL_DEPLOY_TT_PRI_TEMP,          78,    7,   16;
;RIU_DERIVED_D_FIELDS_V2_CLAMSHELL_DEPLOY_TT_PRI_TEMP,          80,    7,   16;
;RIU_DERIVED_D_FIELDS_V3_CLAMSHELL_DEPLOY_TT_PRI_TEMP,          82,    7,   16;
;RIU_DERIVED_D_FIELDS_PLASMA_WAVE_PRE_AMP_1_TEMP,               84,    7,   16;
;RIU_DERIVED_D_NEGY_SA_BOOM_HOSE_CLAMP_3_TEMP,                  86,    7,   16;
;RIU_DERIVED_D_POSY_SA_BOOM_HOSE_CLAMP_1_TEMP,                  88,    7,   16;
;RIU_DERIVED_D_PUMP_1_TEMP,                                     90,    7,   16;
;RIU_DERIVED_D_CSPR_1_A1_TEMP,                                  92,    7,   16;
;RIU_DERIVED_D_FIELDS_PLASMA_WAVE_PRE_AMP_3_TEMP,               94,    7,   16;
;RIU_DERIVED_D_CSPR_2_A4_TEMP,                                  96,    7,   16;
;RIU_DERIVED_D_CSPR_2_A1_TEMP,                                  98,    7,   16;
;RIU_DERIVED_D_LATCH_VALVE_ISO_2_TEMP,                         100,    7,   16;
;RIU_DERIVED_D_TOP_OF_BARRIER_BLANKET_TEMP,                    102,    7,   16;
;RIU_DERIVED_D_RIU_2B_INTERNAL_TEMP,                           104,    7,   16;
;RIU_DERIVED_D_RIU_1_3B_TEMP,                                  106,    7,   16;
;RIU_DERIVED_D_FIELDS_V3_CLAMSHELL_DEPLOY_TT_RED_TEMP,         108,    7,   16;
;RIU_DERIVED_D_FIELDS_V2_CLAMSHELL_DEPLOY_TT_RED_TEMP,         110,    7,   16;
;RIU_DERIVED_D_FIELDS_V1_CLAMSHELL_DEPLOY_TT_RED_TEMP,         112,    7,   16;
;RIU_DERIVED_D_FIELDS_PLASMA_WAVE_PRE_AMP_4_TEMP,              114,    7,   16;
;RIU_DERIVED_D_FIELDS_PLASMA_WAVE_PRE_AMP_2_TEMP,              116,    7,   16;
;RIU_DERIVED_D_NEGY_SA_BOOM_HOSE_CLAMP_1_TEMP,                 118,    7,   16;
;RIU_DERIVED_D_POSY_SA_BOOM_HOSE_CLAMP_3_TEMP,                 120,    7,   16;
;RIU_DERIVED_D_PUMP_2_TEMP,                                    122,    7,   16;
;RIU_DERIVED_D_CSPR_3_B4_TEMP,                                 124,    7,   16;
;RIU_DERIVED_D_CSPR_4_B1_TEMP,                                 126,    7,   16;
;RIU_DERIVED_D_CSPR_3_B1_TEMP,                                 128,    7,   16;
;RIU_DERIVED_D_LATCH_VALVE_ISO_3_TEMP,                         130,    7,   16;
;RIU_DERIVED_D_RIU_3A_INTERNAL_TEMP,                           132,    7,   16;
;RIU_DERIVED_D_EPIHI_ELECT_BOX_1_TEMP,                         134,    7,   16;
;RIU_DERIVED_D_SWEAP_SPAN_B_ELECT_BOX_TEMP,                    136,    7,   16;
;RIU_DERIVED_D_EPILO_HTR_CTRL_A_TEMP,                          138,    7,   16;
;RIU_DERIVED_D_EPIHI_LET1_TEMP,                                140,    7,   16;
;RIU_DERIVED_D_SWEAP_SPAN_B_TOP_ANALYZER_TEMP,                 142,    7,   16;
;RIU_DERIVED_D_FIELDS_V4_CLAMSHELL_DEPLOY_TT_PRI_TEMP,         144,    7,   16;
;RIU_DERIVED_D_SLS_7_TEMP,                                     146,    7,   16;
;RIU_DERIVED_D_SLS_5_TEMP,                                     148,    7,   16;
;RIU_DERIVED_D_SLS_1_TEMP,                                     150,    7,   16;
;RIU_DERIVED_D_SLS_6_TEMP,                                     152,    7,   16;
;RIU_DERIVED_D_LGA1_POSX_TEMP,                                 154,    7,   16;
;RIU_DERIVED_D_HGA_DISH_TEMP,                                  156,    7,   16;
;RIU_DERIVED_D_FB1_POSZ_TEMP,                                  158,    7,   16;
;RIU_DERIVED_D_DSS_1_TEMP,                                     160,    7,   16;
;RIU_DERIVED_D_RIU_3B_INTERNAL_TEMP,                           162,    7,   16;
;RIU_DERIVED_D_EPIHI_ELECT_BOX_2_TEMP,                         164,    7,   16;
;RIU_DERIVED_D_EPIHI_HET_TEMP,                                 166,    7,   16;
;RIU_DERIVED_D_EPILO_HTR_CTRL_B1_TEMP,                         168,    7,   16;
;RIU_DERIVED_D_RIU_4A_B_TEMP,                                  170,    7,   16;
;RIU_DERIVED_D_EPIHI_LET2_TEMP,                                172,    7,   16;
;RIU_DERIVED_D_EPILO_B2_TEMP,                                  174,    7,   16;
;RIU_DERIVED_D_SWEAP_SPAN_A_POS_TOP_ANALYZER_TEMP,             176,    7,   16;
;RIU_DERIVED_D_FIELDS_V4_CLAMSHELL_DEPLOY_TT_RED_TEMP,         178,    7,   16;
;RIU_DERIVED_D_SLS_3_TEMP,                                     180,    7,   16;
;RIU_DERIVED_D_SLS_4_TEMP,                                     182,    7,   16;
;RIU_DERIVED_D_SLS_2_TEMP,                                     184,    7,   16;
;RIU_DERIVED_D_FB2_NEGZ_TEMP,                                  186,    7,   16;
;RIU_DERIVED_D_LGA2_NEGX_TEMP,                                 188,    7,   16;
;RIU_DERIVED_D_DSS_2_TEMP,                                     190,    7,   16;
;RIU_DERIVED_D_RIU_4A_INTERNAL_TEMP,                           192,    7,   16;
;RIU_DERIVED_D_PROP_LINES_EXT_B1_TEMP,                         194,    7,   16;
;RIU_DERIVED_D_PROP_LINES_EXT_C1_TEMP,                         196,    7,   16;
;RIU_DERIVED_D_THRUSTER_VALVE_A1_TEMP,                         198,    7,   16;
;RIU_DERIVED_D_THRUSTER_VALVE_B1_TEMP,                         200,    7,   16;
;RIU_DERIVED_D_THRUSTER_VALVE_C2_TEMP,                         202,    7,   16;
;RIU_DERIVED_D_PROP_LINES_EXT_A1_TEMP,                         204,    7,   16;
;RIU_DERIVED_D_WISPR_ERM_TEMP,                                 206,    7,   16;
;RIU_DERIVED_D_WISPR_INNER_TELESCOPE_DRB_TEMP,                 208,    7,   16;
;RIU_DERIVED_D_WISPR_OUTER_TELESCOPE_LBA_TEMP,                 210,    7,   16;
;RIU_DERIVED_D_FRANGIBOLT_MAG_BOOM_NEGZ_PRI_TEMP,              212,    7,   16;
;RIU_DERIVED_D_FRANGIBOLT_MAG_BOOM_POSZ_PRI_TEMP,              214,    7,   16;
;RIU_DERIVED_D_FRANGIBOLT_POSY_SA_PLATEN_NEGX_PRI_TEMP,        216,    7,   16;
;RIU_DERIVED_D_FRANGIBOLT_POSY_SA_PLATEN_POSX_PRI_TEMP,        218,    7,   16;
;RIU_DERIVED_D_FRANGIBOLT_POSY_SA_BOOM_PRI_TEMP,               220,    7,   16;
;RIU_DERIVED_D_RIU_4B_INTERNAL_TEMP,                           222,    7,   16;
;RIU_DERIVED_D_PROP_LINES_EXT_B2_C2_TEMP,                      224,    7,   16;
;RIU_DERIVED_D_THRUSTER_VALVE_A2_TEMP,                         226,    7,   16;
;RIU_DERIVED_D_THRUSTER_VALVE_B2_TEMP,                         228,    7,   16;
;RIU_DERIVED_D_THRUSTER_VALVE_C1_TEMP,                         230,    7,   16;
;RIU_DERIVED_D_PROP_LINES_EXT_A2_TEMP,                         232,    7,   16;
;RIU_DERIVED_D_SWEAP_SPAN_B_PEDESTAL_TEMP,                     234,    7,   16;
;RIU_DERIVED_D_WISPR_INNER_TELESCOPE_LBA_TEMP,                 236,    7,   16;
;RIU_DERIVED_D_WISPR_OUTER_TELESCOPE_DRB_TEMP,                 238,    7,   16;
;RIU_DERIVED_D_WISPR_CAMERA_INTERFACE_ELECT_TEMP,              240,    7,   16;
;RIU_DERIVED_D_FRANGIBOLT_MAG_BOOM_NEGZ_RED_TEMP,              242,    7,   16;
;RIU_DERIVED_D_FRANGIBOLT_MAG_BOOM_POSZ_RED_TEMP,              244,    7,   16;
;RIU_DERIVED_D_FRANGIBOLT_POSY_SA_PLATEN_NEGX_RED_TEMP,        246,    7,   16;
;RIU_DERIVED_D_FRANGIBOLT_POSY_SA_PLATEN_POSX_RED_TEMP,        248,    7,   16;
;RIU_DERIVED_D_FRANGIBOLT_POSY_SA_BOOM_RED_TEMP,               250,    7,   16;
;RIU_DERIVED_D_RIU_5A_INTERNAL_TEMP,                           252,    7,   16;
;RIU_DERIVED_D_PROP_LINES_EXT_B3_C3_TEMP,                      254,    7,   16;
;RIU_DERIVED_D_THRUSTER_VALVE_A3_TEMP,                         256,    7,   16;
;RIU_DERIVED_D_THRUSTER_VALVE_B4_TEMP,                         258,    7,   16;
;RIU_DERIVED_D_THRUSTER_VALVE_C3_TEMP,                         260,    7,   16;
;RIU_DERIVED_D_KA_BAND_CIRCULATOR_PRI_TEMP,                    262,    7,   16;
;RIU_DERIVED_D_SWEAP_SPAN_A_POS_ELECT_BOX_TEMP,                264,    7,   16;
;RIU_DERIVED_D_RIU_5A_B_TEMP,                                  266,    7,   16;
;RIU_DERIVED_D_PROP_LINES_EXT_A4_TEMP,                         268,    7,   16;
;RIU_DERIVED_D_SWEAP_SPC_PRE_AMP_TEMP,                         270,    7,   16;
;RIU_DERIVED_D_RIU_1_3A_TEMP,                                  272,    7,   16;
;RIU_DERIVED_D_FRANGIBOLT_NEGY_SA_PLATEN_POSX_PRI_TEMP,        274,    7,   16;
;RIU_DERIVED_D_FRANGIBOLT_NEGY_SA_PLATEN_NEGX_PRI_TEMP,        276,    7,   16;
;RIU_DERIVED_D_FRANGIBOLT_NEGY_SA_BOOM_PRI_TEMP,               278,    7,   16;
;RIU_DERIVED_D_FRANGIBOLT_HGA_PRI_TEMP,                        280,    7,   16;
;RIU_DERIVED_D_RIU_5B_INTERNAL_TEMP,                           282,    7,   16;
;RIU_DERIVED_D_PROP_LINES_EXT_B4_TEMP,                         284,    7,   16;
;RIU_DERIVED_D_PROP_LINES_EXT_C4_TEMP,                         286,    7,   16;
;RIU_DERIVED_D_THRUSTER_VALVE_A4_TEMP,                         288,    7,   16;
;RIU_DERIVED_D_THRUSTER_VALVE_B3_TEMP,                         290,    7,   16;
;RIU_DERIVED_D_THRUSTER_VALVE_C4_TEMP,                         292,    7,   16;
;RIU_DERIVED_D_KA_BAND_CIRCULATOR_RED_TEMP,                    294,    7,   16;
;RIU_DERIVED_D_SWEAP_SPAN_A_POS_PEDESTAL_TEMP,                 296,    7,   16;
;RIU_DERIVED_D_PROP_LINES_EXT_A3_TEMP,                         298,    7,   16;
;RIU_DERIVED_D_FRANGIBOLT_NEGY_SA_PLATEN_POSX_RED_TEMP,        300,    7,   16;
;RIU_DERIVED_D_FRANGIBOLT_NEGY_SA_PLATEN_NEGX_RED_TEMP,        302,    7,   16;
;RIU_DERIVED_D_FRANGIBOLT_NEGY_SA_BOOM_RED_TEMP,               304,    7,   16;
;RIU_DERIVED_D_FRANGIBOLT_HGA_RED_TEMP,                        306,    7,   16;
;RIU_DERIVED_D_RIU_6A_INTERNAL_TEMP,                           308,    7,   16;
;RIU_DERIVED_D_BATT_TEMP,                                      310,    7,   16;
;RIU_DERIVED_D_ECU_TEMP,                                       312,    7,   16;
;RIU_DERIVED_D_PDU_TEMP,                                       314,    7,   16;
;RIU_DERIVED_D_PSE_TEMP,                                       316,    7,   16;
;RIU_DERIVED_D_RF_DIODE_UNIT_TEMP,                             318,    7,   16;
;RIU_DERIVED_D_X_BAND_EPC_A_TEMP,                              320,    7,   16;
;RIU_DERIVED_D_SACS_P1_TEMP,                                   322,    7,   16;
;RIU_DERIVED_D_SACS_DP_SENSR_A_TEMP,                           324,    7,   16;
;RIU_DERIVED_D_FILL_DRAIN_VALVE_TEMP,                          326,    7,   16;
;RIU_DERIVED_D_ACCUMULATOR_PRI_TEMP,                           328,    7,   16;
;RIU_DERIVED_D_RIU_6B_INTERNAL_TEMP,                           330,    7,   16;
;RIU_DERIVED_D_ACCUMULATOR_RED_TEMP,                           332,    7,   16;
;RIU_DERIVED_D_SACS_DP_SENSR_B_TEMP,                           334,    7,   16;
;RIU_DERIVED_D_RIU_6A_B_TEMP,                                  336,    7,   16;
;RIU_DERIVED_D_RF_SWITCH_PLATE_TEMP,                           338,    7,   16;
;RIU_DERIVED_D_X_BAND_EPC_B_TEMP,                              340,    7,   16;
;RIU_DERIVED_D_LATCH_VALVE_ISO_1_TEMP,                         342,    7,   16;
;RIU_DERIVED_D_SACS_ELECT_TEMP,                                344,    7,   16;
;RIU_DERIVED_D_RIU_7A_INTERNAL_TEMP,                           346,    7,   16;
;RIU_DERIVED_D_WHEEL1_TEMP,                                    348,    7,   16;
;RIU_DERIVED_D_WHEEL3_TEMP,                                    350,    7,   16;
;RIU_DERIVED_D_RIU_7A_TEMP,                                    352,    7,   16;
;RIU_DERIVED_D_TWTA_KA_A_TEMP,                                 354,    7,   16;
;RIU_DERIVED_D_RADIOA_TEMP,                                    356,    7,   16;
;RIU_DERIVED_D_TWTA_X_A_TEMP,                                  358,    7,   16;
;RIU_DERIVED_D_ST1_TEMP,                                       360,    7,   16;
;RIU_DERIVED_D_PROP_TANK_BOT_TEMP,                             362,    7,   16;
;RIU_DERIVED_D_WHEEL2_BEARING_TEMP,                            364,    7,   16;
;RIU_DERIVED_D_WHEEL4_BEARING_TEMP,                            366,    7,   16;
;RIU_DERIVED_D_RIU_7B_INTERNAL_TEMP,                           368,    7,   16;
;RIU_DERIVED_D_WHEEL2_TEMP,                                    370,    7,   16;
;RIU_DERIVED_D_KA_BAND_HYBRID_TEMP,                            372,    7,   16;
;RIU_DERIVED_D_WHEEL4_TEMP,                                    374,    7,   16;
;RIU_DERIVED_D_TWTA_KA_B_TEMP,                                 376,    7,   16;
;RIU_DERIVED_D_RADIOB_TEMP,                                    378,    7,   16;
;RIU_DERIVED_D_TWTA_X_B_TEMP,                                  380,    7,   16;
;RIU_DERIVED_D_ST2_TEMP,                                       382,    7,   16;
;RIU_DERIVED_D_RIU_7B_TEMP,                                    384,    7,   16;
;RIU_DERIVED_D_PROP_TANK_TOP_TEMP,                             386,    7,   16;
;RIU_DERIVED_D_WHEEL1_BEARING_TEMP,                            388,    7,   16;
;RIU_DERIVED_D_WHEEL3_BEARING_TEMP,                            390,    7,   16;
;RIU_DERIVED_D_RIU_8A_INTERNAL_TEMP,                           392,    7,   16;
;RIU_DERIVED_D_PROP_PTA_TEMP,                                  394,    7,   16;
;RIU_DERIVED_D_SERVICE_VALVES_TEMP,                            396,    7,   16;
;RIU_DERIVED_D_FIELDS_MEP_TEMP,                                398,    7,   16;
;RIU_DERIVED_D_KA_BAND_EPC_A_TEMP,                             400,    7,   16;
;RIU_DERIVED_D_RIU_8A_B_TEMP,                                  402,    7,   16;
;RIU_DERIVED_D_REM_TEMP,                                       404,    7,   16;
;RIU_DERIVED_D_WISPR_DPU_TEMP,                                 406,    7,   16;
;RIU_DERIVED_D_LATCH_VALVE_A_TEMP,                             408,    7,   16;
;RIU_DERIVED_D_RIU_8B_INTERNAL_TEMP,                           410,    7,   16;
;RIU_DERIVED_D_PROP_PTB_TEMP,                                  412,    7,   16;
;RIU_DERIVED_D_RPM_TEMP,                                       414,    7,   16;
;RIU_DERIVED_D_SWEAP_SWEM_TEMP,                                416,    7,   16;
;RIU_DERIVED_D_SSE_TEMP,                                       418,    7,   16;
;RIU_DERIVED_D_IMU_TEMP,                                       420,    7,   16;
;RIU_DERIVED_D_KA_BAND_EPC_B_TEMP,                             422,    7,   16;
;RIU_DERIVED_D_LATCH_VALVE_B_TEMP,                             424,    7,   16;
;RIU_DERIVED_D_RIU_9A_INTERNAL_TEMP,                           426,    7,   16;
;RIU_DERIVED_D_SA_INLET_LINE_NEGY_3_TEMP,                      428,    7,   16;
;RIU_DERIVED_D_CSPR_1_TBLOCK_LOWER_MANIFOLD_FIN_6_TEMP,        430,    7,   16;
;RIU_DERIVED_D_CSPR_4_TBLOCK_LOWER_MANIFOLD_FIN_4_TEMP,        432,    7,   16;
;RIU_DERIVED_D_SA_INLET_LINE_POSY_1_TEMP,                      434,    7,   16;
;RIU_DERIVED_D_SA_INLET_LINE_POSY_2_TEMP,                      436,    7,   16;
;RIU_DERIVED_D_CSPR_2_TBLOCK_LOWER_MANIFOLD_FIN_8_TEMP,        438,    7,   16;
;RIU_DERIVED_D_CSPR_3_TBLOCK_LOWER_MANIFOLD_FIN_4_TEMP,        440,    7,   16;
;RIU_DERIVED_D_SA_OUTLET_LINE_POSY_1_TEMP,                     442,    7,   16;
;RIU_DERIVED_D_SA_OUTLET_LINE_POSY_2_TEMP,                     444,    7,   16;
;RIU_DERIVED_D_SA_OUTLET_LINE_POSY_3_TEMP,                     446,    7,   16;
;RIU_DERIVED_D_SA_OUTLET_LINE_NEGY_4_TEMP,                     448,    7,   16;
;RIU_DERIVED_D_SA_OUTLET_LINE_NEGY_5_TEMP,                     450,    7,   16;
;RIU_DERIVED_D_SA_OUTLET_LINE_NEGY_6_TEMP,                     452,    7,   16;
;RIU_DERIVED_D_PUMP_CHECK_VALVE_OUTLET_A_TEMP,                 454,    7,   16;
;RIU_DERIVED_D_RIU_9B_INTERNAL_TEMP,                           456,    7,   16;
;RIU_DERIVED_D_CSPR_1_TBLOCK_LOWER_MANIFOLD_FIN_4_TEMP,        458,    7,   16;
;RIU_DERIVED_D_SA_INLET_LINE_NEGY_1_TEMP,                      460,    7,   16;
;RIU_DERIVED_D_SA_INLET_LINE_NEGY_2_TEMP,                      462,    7,   16;
;RIU_DERIVED_D_CSPR_4_TBLOCK_LOWER_MANIFOLD_FIN_6_TEMP,        464,    7,   16;
;RIU_DERIVED_D_CSPR_2_TBLOCK_LOWER_MANIFOLD_FIN_4_TEMP,        466,    7,   16;
;RIU_DERIVED_D_SA_INLET_LINE_POSY_3_TEMP,                      468,    7,   16;
;RIU_DERIVED_D_CSPR_3_TBLOCK_LOWER_MANIFOLD_FIN_8_TEMP,        470,    7,   16;
;RIU_DERIVED_D_SA_OUTLET_LINE_POSY_4_TEMP,                     472,    7,   16;
;RIU_DERIVED_D_SA_OUTLET_LINE_POSY_5_TEMP,                     474,    7,   16;
;RIU_DERIVED_D_SA_OUTLET_LINE_POSY_6_TEMP,                     476,    7,   16;
;RIU_DERIVED_D_SA_OUTLET_LINE_NEGY_1_TEMP,                     478,    7,   16;
;RIU_DERIVED_D_SA_OUTLET_LINE_NEGY_2_TEMP,                     480,    7,   16;
;RIU_DERIVED_D_SA_OUTLET_LINE_NEGY_3_TEMP,                     482,    7,   16;
;RIU_DERIVED_D_PUMP_CHECK_VALVE_OUTLET_B_TEMP,                 484,    7,   16;
;RIU_DERIVED_D_RIU_1A_INTERNAL_TEMP_VALIDITY,                  486,    7,    1;
;RIU_DERIVED_D_CSPR_4_A1_TEMP_VALIDITY,                        486,    6,    1;
;RIU_DERIVED_D_CSPR_4_A4_TEMP_VALIDITY,                        486,    5,    1;
;RIU_DERIVED_D_CSPR_4_A2_TEMP_VALIDITY,                        486,    4,    1;
;RIU_DERIVED_D_CSPR_3_A3_TEMP_VALIDITY,                        486,    3,    1;
;RIU_DERIVED_D_CSPR_3_A1_TEMP_VALIDITY,                        486,    2,    1;
;RIU_DERIVED_D_CSPR_2_A3_TEMP_VALIDITY,                        486,    1,    1;
;RIU_DERIVED_D_CSPR_2_A2_TEMP_VALIDITY,                        486,    0,    1;
;RIU_DERIVED_D_CSPR_1_A3_TEMP_VALIDITY,                        487,    7,    1;
;RIU_DERIVED_D_CSPR_3_A4_TEMP_VALIDITY,                        487,    6,    1;
;RIU_DERIVED_D_CSPR_1_A4_TEMP_VALIDITY,                        487,    5,    1;
;RIU_DERIVED_D_CSPR_4_A3_TEMP_VALIDITY,                        487,    4,    1;
;RIU_DERIVED_D_CSPR_1_A2_TEMP_VALIDITY,                        487,    3,    1;
;RIU_DERIVED_D_CSPR_3_A2_TEMP_VALIDITY,                        487,    2,    1;
;RIU_DERIVED_D_CHECK_VALVE_PRI_TEMP_VALIDITY,                  487,    1,    1;
;RIU_DERIVED_D_RIU_1B_INTERNAL_TEMP_VALIDITY,                  487,    0,    1;
;RIU_DERIVED_D_CSPR_3_B2_TEMP_VALIDITY,                        488,    7,    1;
;RIU_DERIVED_D_CSPR_4_B4_TEMP_VALIDITY,                        488,    6,    1;
;RIU_DERIVED_D_CSPR_4_B2_TEMP_VALIDITY,                        488,    5,    1;
;RIU_DERIVED_D_CSPR_3_B3_TEMP_VALIDITY,                        488,    4,    1;
;RIU_DERIVED_D_CSPR_2_B4_TEMP_VALIDITY,                        488,    3,    1;
;RIU_DERIVED_D_CSPR_2_B3_TEMP_VALIDITY,                        488,    2,    1;
;RIU_DERIVED_D_CSPR_2_B1_TEMP_VALIDITY,                        488,    1,    1;
;RIU_DERIVED_D_CSPR_2_B2_TEMP_VALIDITY,                        488,    0,    1;
;RIU_DERIVED_D_CSPR_1_B3_TEMP_VALIDITY,                        489,    7,    1;
;RIU_DERIVED_D_CSPR_1_B1_TEMP_VALIDITY,                        489,    6,    1;
;RIU_DERIVED_D_CSPR_1_B4_TEMP_VALIDITY,                        489,    5,    1;
;RIU_DERIVED_D_CSPR_1_B2_TEMP_VALIDITY,                        489,    4,    1;
;RIU_DERIVED_D_CSPR_4_B3_TEMP_VALIDITY,                        489,    3,    1;
;RIU_DERIVED_D_CHECK_VALVE_RED_TEMP_VALIDITY,                  489,    2,    1;
;RIU_DERIVED_D_RIU_2A_INTERNAL_TEMP_VALIDITY,                  489,    1,    1;
;RIU_DERIVED_D_FIELDS_V1_CLAMSHELL_DEPLOY_TT_PRI_TEMP_VALIDITY,  489,    0,    1;
;RIU_DERIVED_D_FIELDS_V2_CLAMSHELL_DEPLOY_TT_PRI_TEMP_VALIDITY,  490,    7,    1;
;RIU_DERIVED_D_FIELDS_V3_CLAMSHELL_DEPLOY_TT_PRI_TEMP_VALIDITY,  490,    6,    1;
;RIU_DERIVED_D_FIELDS_PLASMA_WAVE_PRE_AMP_1_TEMP_VALIDITY,     490,    5,    1;
;RIU_DERIVED_D_NEGY_SA_BOOM_HOSE_CLAMP_3_TEMP_VALIDITY,        490,    4,    1;
;RIU_DERIVED_D_POSY_SA_BOOM_HOSE_CLAMP_1_TEMP_VALIDITY,        490,    3,    1;
;RIU_DERIVED_D_PUMP_1_TEMP_VALIDITY,                           490,    2,    1;
;RIU_DERIVED_D_CSPR_1_A1_TEMP_VALIDITY,                        490,    1,    1;
;RIU_DERIVED_D_FIELDS_PLASMA_WAVE_PRE_AMP_3_TEMP_VALIDITY,     490,    0,    1;
;RIU_DERIVED_D_CSPR_2_A4_TEMP_VALIDITY,                        491,    7,    1;
;RIU_DERIVED_D_CSPR_2_A1_TEMP_VALIDITY,                        491,    6,    1;
;RIU_DERIVED_D_LATCH_VALVE_ISO_2_TEMP_VALIDITY,                491,    5,    1;
;RIU_DERIVED_D_TOP_OF_BARRIER_BLANKET_TEMP_VALIDITY,           491,    4,    1;
;RIU_DERIVED_D_RIU_2B_INTERNAL_TEMP_VALIDITY,                  491,    3,    1;
;RIU_DERIVED_D_RIU_1_3B_TEMP_VALIDITY,                         491,    2,    1;
;RIU_DERIVED_D_FIELDS_V3_CLAMSHELL_DEPLOY_TT_RED_TEMP_VALIDITY,  491,    1,    1;
;RIU_DERIVED_D_FIELDS_V2_CLAMSHELL_DEPLOY_TT_RED_TEMP_VALIDITY,  491,    0,    1;
;RIU_DERIVED_D_FIELDS_V1_CLAMSHELL_DEPLOY_TT_RED_TEMP_VALIDITY,  492,    7,    1;
;RIU_DERIVED_D_FIELDS_PLASMA_WAVE_PRE_AMP_4_TEMP_VALIDITY,     492,    6,    1;
;RIU_DERIVED_D_FIELDS_PLASMA_WAVE_PRE_AMP_2_TEMP_VALIDITY,     492,    5,    1;
;RIU_DERIVED_D_NEGY_SA_BOOM_HOSE_CLAMP_1_TEMP_VALIDITY,        492,    4,    1;
;RIU_DERIVED_D_POSY_SA_BOOM_HOSE_CLAMP_3_TEMP_VALIDITY,        492,    3,    1;
;RIU_DERIVED_D_PUMP_2_TEMP_VALIDITY,                           492,    2,    1;
;RIU_DERIVED_D_CSPR_3_B4_TEMP_VALIDITY,                        492,    1,    1;
;RIU_DERIVED_D_CSPR_4_B1_TEMP_VALIDITY,                        492,    0,    1;
;RIU_DERIVED_D_CSPR_3_B1_TEMP_VALIDITY,                        493,    7,    1;
;RIU_DERIVED_D_LATCH_VALVE_ISO_3_TEMP_VALIDITY,                493,    6,    1;
;RIU_DERIVED_D_RIU_3A_INTERNAL_TEMP_VALIDITY,                  493,    5,    1;
;RIU_DERIVED_D_EPIHI_ELECT_BOX_1_TEMP_VALIDITY,                493,    4,    1;
;RIU_DERIVED_D_SWEAP_SPAN_B_ELECT_BOX_TEMP_VALIDITY,           493,    3,    1;
;RIU_DERIVED_D_EPILO_HTR_CTRL_A_TEMP_VALIDITY,                 493,    2,    1;
;RIU_DERIVED_D_EPIHI_LET1_TEMP_VALIDITY,                       493,    1,    1;
;RIU_DERIVED_D_SWEAP_SPAN_B_TOP_ANALYZER_TEMP_VALIDITY,        493,    0,    1;
;RIU_DERIVED_D_FIELDS_V4_CLAMSHELL_DEPLOY_TT_PRI_TEMP_VALIDITY,  494,    7,    1;
;RIU_DERIVED_D_SLS_7_TEMP_VALIDITY,                            494,    6,    1;
;RIU_DERIVED_D_SLS_5_TEMP_VALIDITY,                            494,    5,    1;
;RIU_DERIVED_D_SLS_1_TEMP_VALIDITY,                            494,    4,    1;
;RIU_DERIVED_D_SLS_6_TEMP_VALIDITY,                            494,    3,    1;
;RIU_DERIVED_D_LGA1_POSX_TEMP_VALIDITY,                        494,    2,    1;
;RIU_DERIVED_D_HGA_DISH_TEMP_VALIDITY,                         494,    1,    1;
;RIU_DERIVED_D_FB1_POSZ_TEMP_VALIDITY,                         494,    0,    1;
;RIU_DERIVED_D_DSS_1_TEMP_VALIDITY,                            495,    7,    1;
;RIU_DERIVED_D_RIU_3B_INTERNAL_TEMP_VALIDITY,                  495,    6,    1;
;RIU_DERIVED_D_EPIHI_ELECT_BOX_2_TEMP_VALIDITY,                495,    5,    1;
;RIU_DERIVED_D_EPIHI_HET_TEMP_VALIDITY,                        495,    4,    1;
;RIU_DERIVED_D_EPILO_HTR_CTRL_B1_TEMP_VALIDITY,                495,    3,    1;
;RIU_DERIVED_D_RIU_4A_B_TEMP_VALIDITY,                         495,    2,    1;
;RIU_DERIVED_D_EPIHI_LET2_TEMP_VALIDITY,                       495,    1,    1;
;RIU_DERIVED_D_EPILO_B2_TEMP_VALIDITY,                         495,    0,    1;
;RIU_DERIVED_D_SWEAP_SPAN_A_POS_TOP_ANALYZER_TEMP_VALIDITY,    496,    7,    1;
;RIU_DERIVED_D_FIELDS_V4_CLAMSHELL_DEPLOY_TT_RED_TEMP_VALIDITY,  496,    6,    1;
;RIU_DERIVED_D_SLS_3_TEMP_VALIDITY,                            496,    5,    1;
;RIU_DERIVED_D_SLS_4_TEMP_VALIDITY,                            496,    4,    1;
;RIU_DERIVED_D_SLS_2_TEMP_VALIDITY,                            496,    3,    1;
;RIU_DERIVED_D_FB2_NEGZ_TEMP_VALIDITY,                         496,    2,    1;
;RIU_DERIVED_D_LGA2_NEGX_TEMP_VALIDITY,                        496,    1,    1;
;RIU_DERIVED_D_DSS_2_TEMP_VALIDITY,                            496,    0,    1;
;RIU_DERIVED_D_RIU_4A_INTERNAL_TEMP_VALIDITY,                  497,    7,    1;
;RIU_DERIVED_D_PROP_LINES_EXT_B1_TEMP_VALIDITY,                497,    6,    1;
;RIU_DERIVED_D_PROP_LINES_EXT_C1_TEMP_VALIDITY,                497,    5,    1;
;RIU_DERIVED_D_THRUSTER_VALVE_A1_TEMP_VALIDITY,                497,    4,    1;
;RIU_DERIVED_D_THRUSTER_VALVE_B1_TEMP_VALIDITY,                497,    3,    1;
;RIU_DERIVED_D_THRUSTER_VALVE_C2_TEMP_VALIDITY,                497,    2,    1;
;RIU_DERIVED_D_PROP_LINES_EXT_A1_TEMP_VALIDITY,                497,    1,    1;
;RIU_DERIVED_D_WISPR_ERM_TEMP_VALIDITY,                        497,    0,    1;
;RIU_DERIVED_D_WISPR_INNER_TELESCOPE_DRB_TEMP_VALIDITY,        498,    7,    1;
;RIU_DERIVED_D_WISPR_OUTER_TELESCOPE_LBA_TEMP_VALIDITY,        498,    6,    1;
;RIU_DERIVED_D_FRANGIBOLT_MAG_BOOM_NEGZ_PRI_TEMP_VALIDITY,     498,    5,    1;
;RIU_DERIVED_D_FRANGIBOLT_MAG_BOOM_POSZ_PRI_TEMP_VALIDITY,     498,    4,    1;
;RIU_DERIVED_D_FRANGIBOLT_POSY_SA_PLATEN_NEGX_PRI_TEMP_VALIDITY,  498,    3,    1;
;RIU_DERIVED_D_FRANGIBOLT_POSY_SA_PLATEN_POSX_PRI_TEMP_VALIDITY,  498,    2,    1;
;RIU_DERIVED_D_FRANGIBOLT_POSY_SA_BOOM_PRI_TEMP_VALIDITY,      498,    1,    1;
;RIU_DERIVED_D_RIU_4B_INTERNAL_TEMP_VALIDITY,                  498,    0,    1;
;RIU_DERIVED_D_PROP_LINES_EXT_B2_C2_TEMP_VALIDITY,             499,    7,    1;
;RIU_DERIVED_D_THRUSTER_VALVE_A2_TEMP_VALIDITY,                499,    6,    1;
;RIU_DERIVED_D_THRUSTER_VALVE_B2_TEMP_VALIDITY,                499,    5,    1;
;RIU_DERIVED_D_THRUSTER_VALVE_C1_TEMP_VALIDITY,                499,    4,    1;
;RIU_DERIVED_D_PROP_LINES_EXT_A2_TEMP_VALIDITY,                499,    3,    1;
;RIU_DERIVED_D_SWEAP_SPAN_B_PEDESTAL_TEMP_VALIDITY,            499,    2,    1;
;RIU_DERIVED_D_WISPR_INNER_TELESCOPE_LBA_TEMP_VALIDITY,        499,    1,    1;
;RIU_DERIVED_D_WISPR_OUTER_TELESCOPE_DRB_TEMP_VALIDITY,        499,    0,    1;
;RIU_DERIVED_D_WISPR_CAMERA_INTERFACE_ELECT_TEMP_VALIDITY,     500,    7,    1;
;RIU_DERIVED_D_FRANGIBOLT_MAG_BOOM_NEGZ_RED_TEMP_VALIDITY,     500,    6,    1;
;RIU_DERIVED_D_FRANGIBOLT_MAG_BOOM_POSZ_RED_TEMP_VALIDITY,     500,    5,    1;
;RIU_DERIVED_D_FRANGIBOLT_POSY_SA_PLATEN_NEGX_RED_TEMP_VALIDITY,  500,    4,    1;
;RIU_DERIVED_D_FRANGIBOLT_POSY_SA_PLATEN_POSX_RED_TEMP_VALIDITY,  500,    3,    1;
;RIU_DERIVED_D_FRANGIBOLT_POSY_SA_BOOM_RED_TEMP_VALIDITY,      500,    2,    1;
;RIU_DERIVED_D_RIU_5A_INTERNAL_TEMP_VALIDITY,                  500,    1,    1;
;RIU_DERIVED_D_PROP_LINES_EXT_B3_C3_TEMP_VALIDITY,             500,    0,    1;
;RIU_DERIVED_D_THRUSTER_VALVE_A3_TEMP_VALIDITY,                501,    7,    1;
;RIU_DERIVED_D_THRUSTER_VALVE_B4_TEMP_VALIDITY,                501,    6,    1;
;RIU_DERIVED_D_THRUSTER_VALVE_C3_TEMP_VALIDITY,                501,    5,    1;
;RIU_DERIVED_D_KA_BAND_CIRCULATOR_PRI_TEMP_VALIDITY,           501,    4,    1;
;RIU_DERIVED_D_SWEAP_SPAN_A_POS_ELECT_BOX_TEMP_VALIDITY,       501,    3,    1;
;RIU_DERIVED_D_RIU_5A_B_TEMP_VALIDITY,                         501,    2,    1;
;RIU_DERIVED_D_PROP_LINES_EXT_A4_TEMP_VALIDITY,                501,    1,    1;
;RIU_DERIVED_D_SWEAP_SPC_PRE_AMP_TEMP_VALIDITY,                501,    0,    1;
;RIU_DERIVED_D_RIU_1_3A_TEMP_VALIDITY,                         502,    7,    1;
;RIU_DERIVED_D_FRANGIBOLT_NEGY_SA_PLATEN_POSX_PRI_TEMP_VALIDITY,  502,    6,    1;
;RIU_DERIVED_D_FRANGIBOLT_NEGY_SA_PLATEN_NEGX_PRI_TEMP_VALIDITY,  502,    5,    1;
;RIU_DERIVED_D_FRANGIBOLT_NEGY_SA_BOOM_PRI_TEMP_VALIDITY,      502,    4,    1;
;RIU_DERIVED_D_FRANGIBOLT_HGA_PRI_TEMP_VALIDITY,               502,    3,    1;
;RIU_DERIVED_D_RIU_5B_INTERNAL_TEMP_VALIDITY,                  502,    2,    1;
;RIU_DERIVED_D_PROP_LINES_EXT_B4_TEMP_VALIDITY,                502,    1,    1;
;RIU_DERIVED_D_PROP_LINES_EXT_C4_TEMP_VALIDITY,                502,    0,    1;
;RIU_DERIVED_D_THRUSTER_VALVE_A4_TEMP_VALIDITY,                503,    7,    1;
;RIU_DERIVED_D_THRUSTER_VALVE_B3_TEMP_VALIDITY,                503,    6,    1;
;RIU_DERIVED_D_THRUSTER_VALVE_C4_TEMP_VALIDITY,                503,    5,    1;
;RIU_DERIVED_D_KA_BAND_CIRCULATOR_RED_TEMP_VALIDITY,           503,    4,    1;
;RIU_DERIVED_D_SWEAP_SPAN_A_POS_PEDESTAL_TEMP_VALIDITY,        503,    3,    1;
;RIU_DERIVED_D_PROP_LINES_EXT_A3_TEMP_VALIDITY,                503,    2,    1;
;RIU_DERIVED_D_FRANGIBOLT_NEGY_SA_PLATEN_POSX_RED_TEMP_VALIDITY,  503,    1,    1;
;RIU_DERIVED_D_FRANGIBOLT_NEGY_SA_PLATEN_NEGX_RED_TEMP_VALIDITY,  503,    0,    1;
;RIU_DERIVED_D_FRANGIBOLT_NEGY_SA_BOOM_RED_TEMP_VALIDITY,      504,    7,    1;
;RIU_DERIVED_D_FRANGIBOLT_HGA_RED_TEMP_VALIDITY,               504,    6,    1;
;RIU_DERIVED_D_RIU_6A_INTERNAL_TEMP_VALIDITY,                  504,    5,    1;
;RIU_DERIVED_D_BATT_TEMP_VALIDITY,                             504,    4,    1;
;RIU_DERIVED_D_ECU_TEMP_VALIDITY,                              504,    3,    1;
;RIU_DERIVED_D_PDU_TEMP_VALIDITY,                              504,    2,    1;
;RIU_DERIVED_D_PSE_TEMP_VALIDITY,                              504,    1,    1;
;RIU_DERIVED_D_RF_DIODE_UNIT_TEMP_VALIDITY,                    504,    0,    1;
;RIU_DERIVED_D_X_BAND_EPC_A_TEMP_VALIDITY,                     505,    7,    1;
;RIU_DERIVED_D_SACS_P1_TEMP_VALIDITY,                          505,    6,    1;
;RIU_DERIVED_D_SACS_DP_SENSR_A_TEMP_VALIDITY,                  505,    5,    1;
;RIU_DERIVED_D_FILL_DRAIN_VALVE_TEMP_VALIDITY,                 505,    4,    1;
;RIU_DERIVED_D_ACCUMULATOR_PRI_TEMP_VALIDITY,                  505,    3,    1;
;RIU_DERIVED_D_RIU_6B_INTERNAL_TEMP_VALIDITY,                  505,    2,    1;
;RIU_DERIVED_D_ACCUMULATOR_RED_TEMP_VALIDITY,                  505,    1,    1;
;RIU_DERIVED_D_SACS_DP_SENSR_B_TEMP_VALIDITY,                  505,    0,    1;
;RIU_DERIVED_D_RIU_6A_B_TEMP_VALIDITY,                         506,    7,    1;
;RIU_DERIVED_D_RF_SWITCH_PLATE_TEMP_VALIDITY,                  506,    6,    1;
;RIU_DERIVED_D_X_BAND_EPC_B_TEMP_VALIDITY,                     506,    5,    1;
;RIU_DERIVED_D_LATCH_VALVE_ISO_1_TEMP_VALIDITY,                506,    4,    1;
;RIU_DERIVED_D_SACS_ELECT_TEMP_VALIDITY,                       506,    3,    1;
;RIU_DERIVED_D_RIU_7A_INTERNAL_TEMP_VALIDITY,                  506,    2,    1;
;RIU_DERIVED_D_WHEEL1_TEMP_VALIDITY,                           506,    1,    1;
;RIU_DERIVED_D_WHEEL3_TEMP_VALIDITY,                           506,    0,    1;
;RIU_DERIVED_D_RIU_7A_TEMP_VALIDITY,                           507,    7,    1;
;RIU_DERIVED_D_TWTA_KA_A_TEMP_VALIDITY,                        507,    6,    1;
;RIU_DERIVED_D_RADIOA_TEMP_VALIDITY,                           507,    5,    1;
;RIU_DERIVED_D_TWTA_X_A_TEMP_VALIDITY,                         507,    4,    1;
;RIU_DERIVED_D_ST1_TEMP_VALIDITY,                              507,    3,    1;
;RIU_DERIVED_D_PROP_TANK_BOT_TEMP_VALIDITY,                    507,    2,    1;
;RIU_DERIVED_D_WHEEL2_BEARING_TEMP_VALIDITY,                   507,    1,    1;
;RIU_DERIVED_D_WHEEL4_BEARING_TEMP_VALIDITY,                   507,    0,    1;
;RIU_DERIVED_D_RIU_7B_INTERNAL_TEMP_VALIDITY,                  508,    7,    1;
;RIU_DERIVED_D_WHEEL2_TEMP_VALIDITY,                           508,    6,    1;
;RIU_DERIVED_D_KA_BAND_HYBRID_TEMP_VALIDITY,                   508,    5,    1;
;RIU_DERIVED_D_WHEEL4_TEMP_VALIDITY,                           508,    4,    1;
;RIU_DERIVED_D_TWTA_KA_B_TEMP_VALIDITY,                        508,    3,    1;
;RIU_DERIVED_D_RADIOB_TEMP_VALIDITY,                           508,    2,    1;
;RIU_DERIVED_D_TWTA_X_B_TEMP_VALIDITY,                         508,    1,    1;
;RIU_DERIVED_D_ST2_TEMP_VALIDITY,                              508,    0,    1;
;RIU_DERIVED_D_RIU_7B_TEMP_VALIDITY,                           509,    7,    1;
;RIU_DERIVED_D_PROP_TANK_TOP_TEMP_VALIDITY,                    509,    6,    1;
;RIU_DERIVED_D_WHEEL1_BEARING_TEMP_VALIDITY,                   509,    5,    1;
;RIU_DERIVED_D_WHEEL3_BEARING_TEMP_VALIDITY,                   509,    4,    1;
;RIU_DERIVED_D_RIU_8A_INTERNAL_TEMP_VALIDITY,                  509,    3,    1;
;RIU_DERIVED_D_PROP_PTA_TEMP_VALIDITY,                         509,    2,    1;
;RIU_DERIVED_D_SERVICE_VALVES_TEMP_VALIDITY,                   509,    1,    1;
;RIU_DERIVED_D_FIELDS_MEP_TEMP_VALIDITY,                       509,    0,    1;
;RIU_DERIVED_D_KA_BAND_EPC_A_TEMP_VALIDITY,                    510,    7,    1;
;RIU_DERIVED_D_RIU_8A_B_TEMP_VALIDITY,                         510,    6,    1;
;RIU_DERIVED_D_REM_TEMP_VALIDITY,                              510,    5,    1;
;RIU_DERIVED_D_WISPR_DPU_TEMP_VALIDITY,                        510,    4,    1;
;RIU_DERIVED_D_LATCH_VALVE_A_TEMP_VALIDITY,                    510,    3,    1;
;RIU_DERIVED_D_RIU_8B_INTERNAL_TEMP_VALIDITY,                  510,    2,    1;
;RIU_DERIVED_D_PROP_PTB_TEMP_VALIDITY,                         510,    1,    1;
;RIU_DERIVED_D_RPM_TEMP_VALIDITY,                              510,    0,    1;
;RIU_DERIVED_D_SWEAP_SWEM_TEMP_VALIDITY,                       511,    7,    1;
;RIU_DERIVED_D_SSE_TEMP_VALIDITY,                              511,    6,    1;
;RIU_DERIVED_D_IMU_TEMP_VALIDITY,                              511,    5,    1;
;RIU_DERIVED_D_KA_BAND_EPC_B_TEMP_VALIDITY,                    511,    4,    1;
;RIU_DERIVED_D_LATCH_VALVE_B_TEMP_VALIDITY,                    511,    3,    1;
;RIU_DERIVED_D_RIU_9A_INTERNAL_TEMP_VALIDITY,                  511,    2,    1;
;RIU_DERIVED_D_SA_INLET_LINE_NEGY_3_TEMP_VALIDITY,             511,    1,    1;
;RIU_DERIVED_D_CSPR_1_TBLOCK_LOWER_MANIFOLD_FIN_6_TEMP_VALIDITY,  511,    0,    1;
;RIU_DERIVED_D_CSPR_4_TBLOCK_LOWER_MANIFOLD_FIN_4_TEMP_VALIDITY,  512,    7,    1;
;RIU_DERIVED_D_SA_INLET_LINE_POSY_1_TEMP_VALIDITY,             512,    6,    1;
;RIU_DERIVED_D_SA_INLET_LINE_POSY_2_TEMP_VALIDITY,             512,    5,    1;
;RIU_DERIVED_D_CSPR_2_TBLOCK_LOWER_MANIFOLD_FIN_8_TEMP_VALIDITY,  512,    4,    1;
;RIU_DERIVED_D_CSPR_3_TBLOCK_LOWER_MANIFOLD_FIN_4_TEMP_VALIDITY,  512,    3,    1;
;RIU_DERIVED_D_SA_OUTLET_LINE_POSY_1_TEMP_VALIDITY,            512,    2,    1;
;RIU_DERIVED_D_SA_OUTLET_LINE_POSY_2_TEMP_VALIDITY,            512,    1,    1;
;RIU_DERIVED_D_SA_OUTLET_LINE_POSY_3_TEMP_VALIDITY,            512,    0,    1;
;RIU_DERIVED_D_SA_OUTLET_LINE_NEGY_4_TEMP_VALIDITY,            513,    7,    1;
;RIU_DERIVED_D_SA_OUTLET_LINE_NEGY_5_TEMP_VALIDITY,            513,    6,    1;
;RIU_DERIVED_D_SA_OUTLET_LINE_NEGY_6_TEMP_VALIDITY,            513,    5,    1;
;RIU_DERIVED_D_PUMP_CHECK_VALVE_OUTLET_A_TEMP_VALIDITY,        513,    4,    1;
;RIU_DERIVED_D_RIU_9B_INTERNAL_TEMP_VALIDITY,                  513,    3,    1;
;RIU_DERIVED_D_CSPR_1_TBLOCK_LOWER_MANIFOLD_FIN_4_TEMP_VALIDITY,  513,    2,    1;
;RIU_DERIVED_D_SA_INLET_LINE_NEGY_1_TEMP_VALIDITY,             513,    1,    1;
;RIU_DERIVED_D_SA_INLET_LINE_NEGY_2_TEMP_VALIDITY,             513,    0,    1;
;RIU_DERIVED_D_CSPR_4_TBLOCK_LOWER_MANIFOLD_FIN_6_TEMP_VALIDITY,  514,    7,    1;
;RIU_DERIVED_D_CSPR_2_TBLOCK_LOWER_MANIFOLD_FIN_4_TEMP_VALIDITY,  514,    6,    1;
;RIU_DERIVED_D_SA_INLET_LINE_POSY_3_TEMP_VALIDITY,             514,    5,    1;
;RIU_DERIVED_D_CSPR_3_TBLOCK_LOWER_MANIFOLD_FIN_8_TEMP_VALIDITY,  514,    4,    1;
;RIU_DERIVED_D_SA_OUTLET_LINE_POSY_4_TEMP_VALIDITY,            514,    3,    1;
;RIU_DERIVED_D_SA_OUTLET_LINE_POSY_5_TEMP_VALIDITY,            514,    2,    1;
;RIU_DERIVED_D_SA_OUTLET_LINE_POSY_6_TEMP_VALIDITY,            514,    1,    1;
;RIU_DERIVED_D_SA_OUTLET_LINE_NEGY_1_TEMP_VALIDITY,            514,    0,    1;
;RIU_DERIVED_D_SA_OUTLET_LINE_NEGY_2_TEMP_VALIDITY,            515,    7,    1;
;RIU_DERIVED_D_SA_OUTLET_LINE_NEGY_3_TEMP_VALIDITY,            515,    6,    1;
;RIU_DERIVED_D_PUMP_CHECK_VALVE_OUTLET_B_TEMP_VALIDITY,        515,    5,    1;
;RIU_DERIVED_D_CSPR_4_A1_TEMP_ENHANCED_VALIDITY,               515,    4,    1;
;RIU_DERIVED_D_CSPR_4_A4_TEMP_ENHANCED_VALIDITY,               515,    3,    1;
;RIU_DERIVED_D_CSPR_3_A3_TEMP_ENHANCED_VALIDITY,               515,    2,    1;
;RIU_DERIVED_D_CSPR_3_A1_TEMP_ENHANCED_VALIDITY,               515,    1,    1;
;RIU_DERIVED_D_CSPR_2_A3_TEMP_ENHANCED_VALIDITY,               515,    0,    1;
;RIU_DERIVED_D_CSPR_1_A3_TEMP_ENHANCED_VALIDITY,               516,    7,    1;
;RIU_DERIVED_D_CSPR_4_A3_TEMP_ENHANCED_VALIDITY,               516,    6,    1;
;RIU_DERIVED_D_SACS_CHECK_VALVE_PRI_TEMP_ENHANCED_VALIDITY,    516,    5,    1;
;RIU_DERIVED_D_CSPR_3_B3_TEMP_ENHANCED_VALIDITY,               516,    4,    1;
;RIU_DERIVED_D_CSPR_2_B3_TEMP_ENHANCED_VALIDITY,               516,    3,    1;
;RIU_DERIVED_D_CSPR_2_B1_TEMP_ENHANCED_VALIDITY,               516,    2,    1;
;RIU_DERIVED_D_CSPR_1_B3_TEMP_ENHANCED_VALIDITY,               516,    1,    1;
;RIU_DERIVED_D_CSPR_1_B1_TEMP_ENHANCED_VALIDITY,               516,    0,    1;
;RIU_DERIVED_D_CSPR_1_B4_TEMP_ENHANCED_VALIDITY,               517,    7,    1;
;RIU_DERIVED_D_CSPR_4_B3_TEMP_ENHANCED_VALIDITY,               517,    6,    1;
;RIU_DERIVED_D_SACS_CHECK_VALVE_RED_TEMP_ENHANCED_VALIDITY,    517,    5,    1;
;RIU_DERIVED_D_SA_INLET_LINE_NEGY_3_ENHANCED_VALIDITY,         517,    4,    1;
;RIU_DERIVED_D_CSPR_1_TBLOCK_LOWER_MANIFOLD_FIN_6_ENHANCED_VALIDITY,  517,    3,    1;
;RIU_DERIVED_D_CSPR_4_TBLOCK_LOWER_MANIFOLD_FIN_4_ENHANCED_VALIDITY,  517,    2,    1;
;RIU_DERIVED_D_SA_INLET_LINE_POSY_1_ENHANCED_VALIDITY,         517,    1,    1;
;RIU_DERIVED_D_SA_INLET_LINE_POSY_2_ENHANCED_VALIDITY,         517,    0,    1;
;RIU_DERIVED_D_CSPR_2_TBLOCK_LOWER_MANIFOLD_FIN_8_ENHANCED_VALIDITY,  518,    7,    1;
;RIU_DERIVED_D_CSPR_3_TBLOCK_LOWER_MANIFOLD_FIN_4_ENHANCED_VALIDITY,  518,    6,    1;
;RIU_DERIVED_D_SA_OUTLET_LINE_POSY_1_ENHANCED_VALIDITY,        518,    5,    1;
;RIU_DERIVED_D_SA_OUTLET_LINE_POSY_2_ENHANCED_VALIDITY,        518,    4,    1;
;RIU_DERIVED_D_SA_OUTLET_LINE_POSY_3_ENHANCED_VALIDITY,        518,    3,    1;
;RIU_DERIVED_D_SA_OUTLET_LINE_NEGY_4_ENHANCED_VALIDITY,        518,    2,    1;
;RIU_DERIVED_D_SA_OUTLET_LINE_NEGY_5_ENHANCED_VALIDITY,        518,    1,    1;
;RIU_DERIVED_D_SA_OUTLET_LINE_NEGY_6_ENHANCED_VALIDITY,        518,    0,    1;
;RIU_DERIVED_D_PUMP_CHECK_VALVE_OUTLET_A_ENHANCED_VALIDITY,    519,    7,    1;
;RIU_DERIVED_D_CSPR_1_TBLOCK_LOWER_MANIFOLD_FIN_4_ENHANCED_VALIDITY,  519,    6,    1;
;RIU_DERIVED_D_SA_INLET_LINE_NEGY_1_ENHANCED_VALIDITY,         519,    5,    1;
;RIU_DERIVED_D_SA_INLET_LINE_NEGY_2_ENHANCED_VALIDITY,         519,    4,    1;
;RIU_DERIVED_D_CSPR_4_TBLOCK_LOWER_MANIFOLD_FIN_6_ENHANCED_VALIDITY,  519,    3,    1;
;RIU_DERIVED_D_CSPR_2_TBLOCK_LOWER_MANIFOLD_FIN_4_ENHANCED_VALIDITY,  519,    2,    1;
;RIU_DERIVED_D_SA_INLET_LINE_POSY_3_ENHANCED_VALIDITY,         519,    1,    1;
;RIU_DERIVED_D_CSPR_3_TBLOCK_LOWER_MANIFOLD_FIN_8_ENHANCED_VALIDITY,  519,    0,    1;
;RIU_DERIVED_D_SA_OUTLET_LINE_POSY_4_ENHANCED_VALIDITY,        520,    7,    1;
;RIU_DERIVED_D_SA_OUTLET_LINE_POSY_5_ENHANCED_VALIDITY,        520,    6,    1;
;RIU_DERIVED_D_SA_OUTLET_LINE_POSY_6_ENHANCED_VALIDITY,        520,    5,    1;
;RIU_DERIVED_D_SA_OUTLET_LINE_NEGY_1_ENHANCED_VALIDITY,        520,    4,    1;
;RIU_DERIVED_D_SA_OUTLET_LINE_NEGY_2_ENHANCED_VALIDITY,        520,    3,    1;
;RIU_DERIVED_D_SA_OUTLET_LINE_NEGY_3_ENHANCED_VALIDITY,        520,    2,    1;
;RIU_DERIVED_D_PUMP_CHECK_VALVE_OUTLET_B_ENHANCED_VALIDITY,    520,    1,    1;
;RIU_DERIVED_SPARE_VALIDITY_BIT,                               520,    0,    1;
;}
