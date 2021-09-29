;Ali: June 2020
;+
; $LastChangedBy: ali $
; $LastChangedDate: 2021-05-30 19:27:32 -0700 (Sun, 30 May 2021) $
; $LastChangedRevision: 30000 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SPP/COMMON/sc/spp_sc_hk_0x1df_apdat__define.pro $
;-

function spp_SC_HK_0x1df_struct,ccsds_data
  if n_elements(ccsds_data) eq 0 then ccsds_data = bytarr(67)

  a1=100./255
  spd0=spp_swp_data_select(ccsds_data,56*8+7-7,16)
  spd1=spp_swp_data_select(ccsds_data,58*8+7-7,16)
  spd2=spp_swp_data_select(ccsds_data,60*8+7-7,16)
  spd3=spp_swp_data_select(ccsds_data,62*8+7-7,16)
  spd_all=[spd0,spd1,spd2,spd3]

  FSW_SPP_SA_POS_Y_FLAP_ANGLE=spp_swp_data_select(ccsds_data,20*8+7-7,8)
  FSW_SPP_SA_NEG_Y_FLAP_ANGLE=spp_swp_data_select(ccsds_data,21*8+7-7,8)
  FSW_SPP_SA_POS_Y_FTHR_ANGLE=spp_swp_data_select(ccsds_data,22*8+7-7,8)
  FSW_SPP_SA_NEG_Y_FTHR_ANGLE=spp_swp_data_select(ccsds_data,23*8+7-7,8)

  str = {time:!values.d_nan ,$
    met:!values.d_nan, $
    seqn: 0u, $
    pkt_size: 0u, $
    FSW_SPP_SOLAR_DIST:spp_swp_data_select(ccsds_data,16*8+7-7,32), $
    FSW_SPP_SOLAR_DIST_RS:1./700e3*spp_swp_data_select(ccsds_data,16*8+7-7,32), $
    FSW_SPP_SA_POS_NEG_Y_FLAP_ANGLE:90./255*[FSW_SPP_SA_POS_Y_FLAP_ANGLE,FSW_SPP_SA_NEG_Y_FLAP_ANGLE], $
    FSW_SPP_SA_POS_NEG_Y_FTHR_ANGLE:180./255*[FSW_SPP_SA_POS_Y_FTHR_ANGLE,FSW_SPP_SA_NEG_Y_FTHR_ANGLE], $
    FSW_SPP_EPI_LO_SSR_ALLOC_STATUS:a1*spp_swp_data_select(ccsds_data,25*8+7-7,8), $
    FSW_SPP_EPI_HI_SSR_ALLOC_STATUS:a1*spp_swp_data_select(ccsds_data,26*8+7-7,8), $
    FSW_SPP_WISPR_SSR_ALLOC_STATUS:a1*spp_swp_data_select(ccsds_data,27*8+7-7,8), $
    FSW_SPP_FIELDS_SSR_ALLOC_STATUS:a1*spp_swp_data_select(ccsds_data,28*8+7-7,8), $
    FSW_SPP_SWEAP_SSR_ALLOC_STATUS:a1*spp_swp_data_select(ccsds_data,30*8+7-7,8), $
    FSW_SPP_SWEAP_RATE_IND:spp_swp_data_select(ccsds_data,52*8+7-6,1), $
    FSW_SPP_TWTA_EPC_PWRD:spp_swp_data_select(ccsds_data,52*8+7-4,1), $
    FSW_SPP_THRUST_FIRE:spp_swp_data_select(ccsds_data,52*8+7-3,1), $
    FSW_SPP_FIELDS1_2_SWEAP_WISPR_EPIHI_LO_PWR_OFF_WARN:spp_swp_data_select(ccsds_data,52*8+7-2,6), $
    FSW_SPP_SWEAP_STARTUP_MODE:spp_swp_data_select(ccsds_data,55*8+7-3,1), $
    FSW_SPP_SWEAP_BOOT_MODE:spp_swp_data_select(ccsds_data,55*8+7-2,1), $
    FSW_SPP_RX_WHEEL_SPEED_RAW:spd_all, $
    gap:0B}
  return, str
end

;FSW_SPP_SOLAR_DIST,                                            16,    7,   32;
;FSW_SPP_SA_POS_Y_FLAP_ANGLE,                                   20,    7,    8;
;FSW_SPP_SA_NEG_Y_FLAP_ANGLE,                                   21,    7,    8;
;FSW_SPP_SA_POS_Y_FTHR_ANGLE,                                   22,    7,    8;
;FSW_SPP_SA_NEG_Y_FTHR_ANGLE,                                   23,    7,    8;
;FSW_SPP_EPI_LO_SSR_ALLOC_STATUS,                               25,    7,    8;
;FSW_SPP_EPI_HI_SSR_ALLOC_STATUS,                               26,    7,    8;
;FSW_SPP_WISPR_SSR_ALLOC_STATUS,                                27,    7,    8;
;FSW_SPP_FIELDS_SSR_ALLOC_STATUS,                               28,    7,    8;
;FSW_SPP_SWEAP_SSR_ALLOC_STATUS,                                30,    7,    8;
;FSW_SPP_SWEAP_RATE_IND,                                        52,    6,    1;
;FSW_SPP_TWTA_EPC_PWRD,                                         52,    4,    1;
;FSW_SPP_THRUST_FIRE,                                           52,    3,    1;
;FSW_SPP_FIELDS1_PWR_OFF_WARN,                                  52,    2,    1;
;FSW_SPP_FIELDS2_PWR_OFF_WARN,                                  52,    1,    1;
;FSW_SPP_SWEAP_PWR_OFF_WARN,                                    52,    0,    1;
;FSW_SPP_WISPR_PWR_OFF_WARN,                                    53,    7,    1;
;FSW_SPP_EPI_HI_PWR_OFF_WARN,                                   53,    6,    1;
;FSW_SPP_EPI_LO_PWR_OFF_WARN,                                   53,    5,    1;
;FSW_SPP_SWEAP_STARTUP_MODE,                                    55,    3,    1;
;FSW_SPP_SWEAP_BOOT_MODE,                                       55,    2,    1;
;FSW_SPP_RX_WHEEL_1_SPEED,                                      56,    7,   16;
;FSW_SPP_RX_WHEEL_2_SPEED,                                      58,    7,   16;
;FSW_SPP_RX_WHEEL_3_SPEED,                                      60,    7,   16;
;FSW_SPP_RX_WHEEL_4_SPEED,                                      62,    7,   16;

;EU(Raw='SC_HK_0x1DF.FSW_SPP_EPI_LO_SSR_ALLOC_STATUS') := fCalCurve([1.0, 255.0], [0.392156862745098, 100.0], Raw)
;EU(Raw='SC_HK_0x1DF.FSW_SPP_EPI_HI_SSR_ALLOC_STATUS') := fCalCurve([1.0, 255.0], [0.392156862745098, 100.0], Raw)
;EU(Raw='SC_HK_0x1DF.FSW_SPP_WISPR_SSR_ALLOC_STATUS') := fCalCurve([1.0, 255.0], [0.392156862745098, 100.0], Raw)
;EU(Raw='SC_HK_0x1DF.FSW_SPP_FIELDS_SSR_ALLOC_STATUS') := fCalCurve([1.0, 255.0], [0.392156862745098, 100.0], Raw)
;EU(Raw='SC_HK_0x1DF.FSW_SPP_SWEAP_SSR_ALLOC_STATUS') := fCalCurve([1.0, 255.0], [0.392156862745098, 100.0], Raw)


function SPP_SC_HK_0x1df_apdat::decom,ccsds, source_dict=source_dict   ;,ptp_header=ptp_header

  ccsds_data = spp_swp_ccsds_data(ccsds)
  str2 = spp_SC_HK_0x1df_struct(ccsds_data)
  struct_assign,ccsds,str2,/nozero
  return,str2

end


pro spp_SC_HK_0x1df_apdat__define

  void = {spp_SC_HK_0x1df_apdat, $
    inherits spp_gen_apdat, $    ; superclass
    flag: 0 $
  }
end
;
;SC_HK_0x1DF
;{
;( Block[65],                                                       ,     ,    8; )
;FSW_SPP_TPPH_VERSION,                                           0,    7,    3;
;FSW_SPP_TPPH_TYPE,                                              0,    4,    1;
;FSW_SPP_TPPH_SEC_HDR_FLAG,                                      0,    3,    1;
;FSW_SPP_TPPH_APID,                                              0,    2,   11;
;SC_D_APID,                                                      0,    2,   11;
;FSW_SPP_TPPH_SEQ_FLAGS,                                         2,    7,    2;
;FSW_SPP_TPPH_SEQ_CNT,                                           2,    5,   14;
;FSW_SPP_TPPH_LENGTH,                                            4,    7,   16;
;FSW_SPP_TPSH_MET_SEC,                                           6,    7,   32;
;SC_D_MET_SEC,                                                   6,    7,   32;
;FSW_SPP_TPSH_MET_SUBSEC,                                       10,    7,    8;
;FSW_SPP_TPSH_SBC_PHYS_ID,                                      11,    7,    2;
;FSW_SPP_NEXT_V1PPS_MET_SECS,                                   12,    7,   32;
;FSW_SPP_SOLAR_DIST,                                            16,    7,   32;
;FSW_SPP_SA_POS_Y_FLAP_ANGLE,                                   20,    7,    8;
;FSW_SPP_SA_NEG_Y_FLAP_ANGLE,                                   21,    7,    8;
;FSW_SPP_SA_POS_Y_FTHR_ANGLE,                                   22,    7,    8;
;FSW_SPP_SA_NEG_Y_FTHR_ANGLE,                                   23,    7,    8;
;FSW_SPP_EPI_LO_SSR_ALLOC_STATUS,                               25,    7,    8;
;FSW_SPP_EPI_HI_SSR_ALLOC_STATUS,                               26,    7,    8;
;FSW_SPP_WISPR_SSR_ALLOC_STATUS,                                27,    7,    8;
;FSW_SPP_FIELDS_SSR_ALLOC_STATUS,                               28,    7,    8;
;FSW_SPP_SWEAP_SSR_ALLOC_STATUS,                                30,    7,    8;
;FSW_SPP_EPI_LO_SHARED_DATA,                                    31,    7,    8;
;FSW_SPP_EPI_HI_SHARED_DATA,                                    32,    7,   16;
;FSW_SPP_FIELDS1_SHARED_DATA,                                   34,    7,   16;
;FSW_SPP_FIELDS2_SHARED_DATA,                                   36,    7,   16;
;FSW_SPP_SWEAP_SHARED_DATA0,                                    40,    7,    8;
;FSW_SPP_SWEAP_SHARED_DATA1,                                    41,    7,    8;
;FSW_SPP_SWEAP_SHARED_DATA2,                                    42,    7,    8;
;FSW_SPP_SWEAP_SHARED_DATA3,                                    43,    7,    8;
;FSW_SPP_SWEAP_SHARED_DATA4,                                    44,    7,    8;
;FSW_SPP_SWEAP_SHARED_DATA5,                                    45,    7,    8;
;FSW_SPP_SWEAP_SHARED_DATA6,                                    46,    7,    8;
;FSW_SPP_SWEAP_SHARED_DATA7,                                    47,    7,    8;
;FSW_SPP_SWEAP_SHARED_DATA8,                                    48,    7,    8;
;FSW_SPP_SWEAP_SHARED_DATA9,                                    49,    7,    8;
;FSW_SPP_SWEAP_SHARED_DATA10,                                   50,    7,    8;
;FSW_SPP_SWEAP_SHARED_DATA11,                                   51,    7,    8;
;FSW_SPP_FIELDS1_RATE_IND,                                      52,    7,    1;
;FSW_SPP_SWEAP_RATE_IND,                                        52,    6,    1;
;FSW_SPP_TWTA_EPC_PWRD,                                         52,    4,    1;
;FSW_SPP_THRUST_FIRE,                                           52,    3,    1;
;FSW_SPP_FIELDS1_PWR_OFF_WARN,                                  52,    2,    1;
;FSW_SPP_FIELDS2_PWR_OFF_WARN,                                  52,    1,    1;
;FSW_SPP_SWEAP_PWR_OFF_WARN,                                    52,    0,    1;
;FSW_SPP_WISPR_PWR_OFF_WARN,                                    53,    7,    1;
;FSW_SPP_EPI_HI_PWR_OFF_WARN,                                   53,    6,    1;
;FSW_SPP_EPI_LO_PWR_OFF_WARN,                                   53,    5,    1;
;FSW_SPP_SBC_TRANSITION_IND,                                    53,    4,    1;
;FSW_SPP_SOLAR_DIST_INFLXN,                                     53,    3,    1;
;FSW_SPP_ISIS_EPI_LO_SHARED_DATA_RCVD,                          53,    2,    1;
;FSW_SPP_ISIS_EPI_HI_SHARED_DATA_RCVD,                          53,    1,    1;
;FSW_SPP_WISPR_SHARED_DATA_RCVD,                                53,    0,    1;
;FSW_SPP_FIELDS1_SHARED_DATA_RCVD,                              54,    7,    1;
;FSW_SPP_FIELDS2_SHARED_DATA_RCVD,                              54,    6,    1;
;FSW_SPP_SWEAP_SHARED_DATA_RCVD,                                54,    5,    1;
;FSW_SPP_SOLAR_DIST_VAL,                                        54,    4,    1;
;FSW_SPP_POS_Y_FLAP_FTHR_VAL,                                   54,    3,    1;
;FSW_SPP_NEG_Y_FLAP_FTHR_VAL,                                   54,    2,    1;
;FSW_SPP_EPI_LO_STARTUP_MODE,                                   54,    1,    1;
;FSW_SPP_EPI_HI_STARTUP_MODE,                                   54,    0,    1;
;FSW_SPP_FIELDS1_STARTUP_MODE,                                  55,    5,    1;
;FSW_SPP_FIELDS2_STARTUP_MODE,                                  55,    4,    1;
;FSW_SPP_SWEAP_STARTUP_MODE,                                    55,    3,    1;
;FSW_SPP_SWEAP_BOOT_MODE,                                       55,    2,    1;
;FSW_SPP_WISPR_STARTUP_MODE,                                    55,    1,    2;
;FSW_SPP_RX_WHEEL_1_SPEED,                                      56,    7,   16;
;FSW_SPP_RX_WHEEL_2_SPEED,                                      58,    7,   16;
;FSW_SPP_RX_WHEEL_3_SPEED,                                      60,    7,   16;
;FSW_SPP_RX_WHEEL_4_SPEED,                                      62,    7,   16;
;FSW_SPP_RX_WHEEL_1_SPEED_VALID,                                64,    7,    1;
;FSW_SPP_RX_WHEEL_2_SPEED_VALID,                                64,    6,    1;
;FSW_SPP_RX_WHEEL_3_SPEED_VALID,                                64,    5,    1;
;FSW_SPP_RX_WHEEL_4_SPEED_VALID,                                64,    4,    1;
;}
