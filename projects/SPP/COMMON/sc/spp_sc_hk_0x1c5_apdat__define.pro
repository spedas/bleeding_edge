;Ali: June 2020
;+
; $LastChangedBy: ali $
; $LastChangedDate: 2020-10-07 22:54:10 -0700 (Wed, 07 Oct 2020) $
; $LastChangedRevision: 29223 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SPP/COMMON/sc/spp_sc_hk_0x1c5_apdat__define.pro $
;-

function spp_SC_HK_0x1c5_struct,ccsds_data
  if n_elements(ccsds_data) eq 0 then ccsds_data = bytarr(67)

  FSW_REC_ALLOC_ALLOC_EPILO=spp_swp_data_select(ccsds_data,12*8+7-7,32)
  FSW_REC_ALLOC_ALLOC_EPIHI=spp_swp_data_select(ccsds_data,16*8+7-7,32)
  FSW_REC_ALLOC_ALLOC_WISPR=spp_swp_data_select(ccsds_data,20*8+7-7,32)
  FSW_REC_ALLOC_ALLOC_FIELDS=spp_swp_data_select(ccsds_data,24*8+7-7,32)
  FSW_REC_ALLOC_ALLOC_SWEAP=spp_swp_data_select(ccsds_data,28*8+7-7,32)
  FSW_REC_ALLOC_ALLOC_CDH_SSR_HK=spp_swp_data_select(ccsds_data,32*8+7-7,32)
  FSW_REC_ALLOC_ALLOC_CDH_RAM_HK=spp_swp_data_select(ccsds_data,36*8+7-7,32)
  FSW_REC_ALLOC_USED_EPILO= spp_swp_data_select(ccsds_data,76*8+7-7,32)
  FSW_REC_ALLOC_USED_EPIHI= spp_swp_data_select(ccsds_data,80*8+7-7,32)
  FSW_REC_ALLOC_USED_WISPR= spp_swp_data_select(ccsds_data,84*8+7-7,32)
  FSW_REC_ALLOC_USED_FIELDS=spp_swp_data_select(ccsds_data,88*8+7-7,32)
  FSW_REC_ALLOC_USED_SWEAP= spp_swp_data_select(ccsds_data,92*8+7-7,32)
  FSW_REC_ALLOC_USED_CDH_SSR_HK=spp_swp_data_select(ccsds_data,96*8+7-7,32)
  FSW_REC_ALLOC_USED_CDH_RAM_HK=spp_swp_data_select(ccsds_data,100*8+7-7,32)

  FSW_REC_ALLOC_GBITS=256e-6*[FSW_REC_ALLOC_ALLOC_EPILO,FSW_REC_ALLOC_ALLOC_EPIHI,FSW_REC_ALLOC_ALLOC_WISPR,FSW_REC_ALLOC_ALLOC_FIELDS,FSW_REC_ALLOC_ALLOC_SWEAP,FSW_REC_ALLOC_ALLOC_CDH_SSR_HK,FSW_REC_ALLOC_ALLOC_CDH_RAM_HK,$
    FSW_REC_ALLOC_USED_EPILO,FSW_REC_ALLOC_USED_EPIHI,FSW_REC_ALLOC_USED_WISPR,FSW_REC_ALLOC_USED_FIELDS,FSW_REC_ALLOC_USED_SWEAP,FSW_REC_ALLOC_USED_CDH_SSR_HK,FSW_REC_ALLOC_USED_CDH_RAM_HK]

  str = {time:!values.d_nan ,$
    met:!values.d_nan, $
    seqn: 0u, $
    pkt_size: 0u, $
    FSW_REC_ALLOC_PERCENT_USED_EPILO:     100./255*spp_swp_data_select(ccsds_data,140*8+7-7,8), $
    FSW_REC_ALLOC_PERCENT_USED_EPIHI:     100./255*spp_swp_data_select(ccsds_data,141*8+7-7,8), $
    FSW_REC_ALLOC_PERCENT_USED_WISPR:     100./255*spp_swp_data_select(ccsds_data,142*8+7-7,8), $
    FSW_REC_ALLOC_PERCENT_USED_FIELDS:    100./255*spp_swp_data_select(ccsds_data,143*8+7-7,8), $
    FSW_REC_ALLOC_PERCENT_USED_SWEAP:     100./255*spp_swp_data_select(ccsds_data,144*8+7-7,8), $
    FSW_REC_ALLOC_PERCENT_USED_CDH_SSR_HK:100./255*spp_swp_data_select(ccsds_data,145*8+7-7,8), $
    FSW_REC_ALLOC_PERCENT_USED_CDH_RAM_HK:100./255*spp_swp_data_select(ccsds_data,146*8+7-7,8), $
    FSW_REC_ALLOC_GBITS:FSW_REC_ALLOC_GBITS, $
    FSW_REC_ALLOC_ALLOC_SWEAP:256e-6*FSW_REC_ALLOC_ALLOC_SWEAP, $
    FSW_REC_ALLOC_USED_SWEAP:256e-6*FSW_REC_ALLOC_USED_SWEAP, $
    gap:0B}
  return, str
end

;FSW_REC_ALLOC_ALLOC_EPILO,                                     12,    7,   32;
;FSW_REC_ALLOC_ALLOC_EPIHI,                                     16,    7,   32;
;FSW_REC_ALLOC_ALLOC_WISPR,                                     20,    7,   32;
;FSW_REC_ALLOC_ALLOC_FIELDS,                                    24,    7,   32;
;FSW_REC_ALLOC_ALLOC_SWEAP,                                     28,    7,   32;
;FSW_REC_ALLOC_ALLOC_CDH_SSR_HK,                                32,    7,   32;
;FSW_REC_ALLOC_ALLOC_CDH_RAM_HK,                                36,    7,   32;
;FSW_REC_ALLOC_USED_EPILO,                                      76,    7,   32;
;FSW_REC_ALLOC_USED_EPIHI,                                      80,    7,   32;
;FSW_REC_ALLOC_USED_WISPR,                                      84,    7,   32;
;FSW_REC_ALLOC_USED_FIELDS,                                     88,    7,   32;
;FSW_REC_ALLOC_USED_SWEAP,                                      92,    7,   32;
;FSW_REC_ALLOC_USED_CDH_SSR_HK,                                 96,    7,   32;
;FSW_REC_ALLOC_USED_CDH_RAM_HK,                                100,    7,   32;
;FSW_REC_ALLOC_PERCENT_USED_EPILO,                             140,    7,    8;
;FSW_REC_ALLOC_PERCENT_USED_EPIHI,                             141,    7,    8;
;FSW_REC_ALLOC_PERCENT_USED_WISPR,                             142,    7,    8;
;FSW_REC_ALLOC_PERCENT_USED_FIELDS,                            143,    7,    8;
;FSW_REC_ALLOC_PERCENT_USED_SWEAP,                             144,    7,    8;
;FSW_REC_ALLOC_PERCENT_USED_CDH_SSR_HK,                        145,    7,    8;
;FSW_REC_ALLOC_PERCENT_USED_CDH_RAM_HK,                        146,    7,    8;
;EU(Raw='SC_HK_0x1C5.FSW_REC_ALLOC_PERCENT_USED_EPILO') := fCalCurve([0.0, 255.0], [0.0, 100.0], Raw)
;EU(Raw='SC_HK_0x1C5.FSW_REC_ALLOC_PERCENT_USED_EPIHI') := fCalCurve([0.0, 255.0], [0.0, 100.0], Raw)
;EU(Raw='SC_HK_0x1C5.FSW_REC_ALLOC_PERCENT_USED_WISPR') := fCalCurve([0.0, 255.0], [0.0, 100.0], Raw)
;EU(Raw='SC_HK_0x1C5.FSW_REC_ALLOC_PERCENT_USED_FIELDS') := fCalCurve([0.0, 255.0], [0.0, 100.0], Raw)
;EU(Raw='SC_HK_0x1C5.FSW_REC_ALLOC_PERCENT_USED_SWEAP') := fCalCurve([0.0, 255.0], [0.0, 100.0], Raw)
;EU(Raw='SC_HK_0x1C5.FSW_REC_ALLOC_PERCENT_USED_CDH_SSR_HK') := fCalCurve([0.0, 255.0], [0.0, 100.0], Raw)
;EU(Raw='SC_HK_0x1C5.FSW_REC_ALLOC_PERCENT_USED_CDH_RAM_HK') := fCalCurve([0.0, 255.0], [0.0, 100.0], Raw)

function SPP_SC_HK_0x1c5_apdat::decom,ccsds, source_dict=source_dict   ;,ptp_header=ptp_header

  ccsds_data = spp_swp_ccsds_data(ccsds)
  str2 = spp_SC_HK_0x1c5_struct(ccsds_data)
  struct_assign,ccsds,str2,/nozero
  return,str2

end


pro spp_SC_HK_0x1c5_apdat__define

  void = {spp_SC_HK_0x1c5_apdat, $
    inherits spp_gen_apdat, $    ; superclass
    flag: 0 $
  }
end
;
;SC_HK_0x1C5
;{
;( Block[168],                                                      ,     ,    8; )
;FSW_REC_ALLOC_TPPH_VERSION,                                     0,    7,    3;
;FSW_REC_ALLOC_TPPH_TYPE,                                        0,    4,    1;
;FSW_REC_ALLOC_TPPH_SEC_HDR_FLAG,                                0,    3,    1;
;FSW_REC_ALLOC_TPPH_APID,                                        0,    2,   11;
;SC_D_APID,                                                      0,    2,   11;
;FSW_REC_ALLOC_TPPH_SEQ_FLAGS,                                   2,    7,    2;
;FSW_REC_ALLOC_TPPH_SEQ_CNT,                                     2,    5,   14;
;FSW_REC_ALLOC_TPPH_LENGTH,                                      4,    7,   16;
;FSW_REC_ALLOC_TPSH_MET_SEC,                                     6,    7,   32;
;SC_D_MET_SEC,                                                   6,    7,   32;
;FSW_REC_ALLOC_TPSH_MET_SUBSEC,                                 10,    7,    8;
;FSW_REC_ALLOC_TPSH_SBC_PHYS_ID,                                11,    7,    2;
;FSW_REC_ALLOC_ALLOC_EPILO,                                     12,    7,   32;
;FSW_REC_ALLOC_ALLOC_EPIHI,                                     16,    7,   32;
;FSW_REC_ALLOC_ALLOC_WISPR,                                     20,    7,   32;
;FSW_REC_ALLOC_ALLOC_FIELDS,                                    24,    7,   32;
;FSW_REC_ALLOC_ALLOC_SWEAP,                                     28,    7,   32;
;FSW_REC_ALLOC_ALLOC_CDH_SSR_HK,                                32,    7,   32;
;FSW_REC_ALLOC_ALLOC_CDH_RAM_HK,                                36,    7,   32;
;FSW_REC_ALLOC_ALLOC_07,                                        40,    7,   32;
;FSW_REC_ALLOC_ALLOC_08,                                        44,    7,   32;
;FSW_REC_ALLOC_ALLOC_09,                                        48,    7,   32;
;FSW_REC_ALLOC_ALLOC_10,                                        52,    7,   32;
;FSW_REC_ALLOC_ALLOC_11,                                        56,    7,   32;
;FSW_REC_ALLOC_ALLOC_12,                                        60,    7,   32;
;FSW_REC_ALLOC_ALLOC_13,                                        64,    7,   32;
;FSW_REC_ALLOC_ALLOC_14,                                        68,    7,   32;
;FSW_REC_ALLOC_ALLOC_15,                                        72,    7,   32;
;FSW_REC_ALLOC_USED_EPILO,                                      76,    7,   32;
;FSW_REC_ALLOC_USED_EPIHI,                                      80,    7,   32;
;FSW_REC_ALLOC_USED_WISPR,                                      84,    7,   32;
;FSW_REC_ALLOC_USED_FIELDS,                                     88,    7,   32;
;FSW_REC_ALLOC_USED_SWEAP,                                      92,    7,   32;
;FSW_REC_ALLOC_USED_CDH_SSR_HK,                                 96,    7,   32;
;FSW_REC_ALLOC_USED_CDH_RAM_HK,                                100,    7,   32;
;FSW_REC_ALLOC_USED_07,                                        104,    7,   32;
;FSW_REC_ALLOC_USED_08,                                        108,    7,   32;
;FSW_REC_ALLOC_USED_09,                                        112,    7,   32;
;FSW_REC_ALLOC_USED_10,                                        116,    7,   32;
;FSW_REC_ALLOC_USED_11,                                        120,    7,   32;
;FSW_REC_ALLOC_USED_12,                                        124,    7,   32;
;FSW_REC_ALLOC_USED_13,                                        128,    7,   32;
;FSW_REC_ALLOC_USED_14,                                        132,    7,   32;
;FSW_REC_ALLOC_USED_15,                                        136,    7,   32;
;FSW_REC_ALLOC_PERCENT_USED_EPILO,                             140,    7,    8;
;FSW_REC_ALLOC_PERCENT_USED_EPIHI,                             141,    7,    8;
;FSW_REC_ALLOC_PERCENT_USED_WISPR,                             142,    7,    8;
;FSW_REC_ALLOC_PERCENT_USED_FIELDS,                            143,    7,    8;
;FSW_REC_ALLOC_PERCENT_USED_SWEAP,                             144,    7,    8;
;FSW_REC_ALLOC_PERCENT_USED_CDH_SSR_HK,                        145,    7,    8;
;FSW_REC_ALLOC_PERCENT_USED_CDH_RAM_HK,                        146,    7,    8;
;FSW_REC_ALLOC_PERCENT_USED_07,                                147,    7,    8;
;FSW_REC_ALLOC_PERCENT_USED_08,                                148,    7,    8;
;FSW_REC_ALLOC_PERCENT_USED_09,                                149,    7,    8;
;FSW_REC_ALLOC_PERCENT_USED_10,                                150,    7,    8;
;FSW_REC_ALLOC_PERCENT_USED_11,                                151,    7,    8;
;FSW_REC_ALLOC_PERCENT_USED_12,                                152,    7,    8;
;FSW_REC_ALLOC_PERCENT_USED_13,                                153,    7,    8;
;FSW_REC_ALLOC_PERCENT_USED_14,                                154,    7,    8;
;FSW_REC_ALLOC_PERCENT_USED_15,                                155,    7,    8;
;FSW_REC_ALLOC_ALLOC_ENA_SSR,                                  156,    7,   32;
;FSW_REC_ALLOC_ALLOC_ENA_RAM,                                  160,    7,   32;
;FSW_REC_ALLOC_NO_SRC_CNTR,                                    164,    7,   32;
;}
