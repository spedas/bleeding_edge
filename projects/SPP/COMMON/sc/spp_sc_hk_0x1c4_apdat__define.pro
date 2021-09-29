;Ali: June 2020
;+
; $LastChangedBy: ali $
; $LastChangedDate: 2021-05-30 19:17:01 -0700 (Sun, 30 May 2021) $
; $LastChangedRevision: 29998 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SPP/COMMON/sc/spp_sc_hk_0x1c4_apdat__define.pro $
;-

function spp_SC_HK_0x1c4_struct,ccsds_data
  if n_elements(ccsds_data) eq 0 then ccsds_data = bytarr(67)

  a1 = 100./255
  str = {time:!values.d_nan ,$
    met:!values.d_nan, $
    seqn: 0u, $
    pkt_size: 0u, $
    FSW_REC_HK_ALLOC_ERR_RAM_SSR_SWEAP_FIELDS_WISPR_EPIHI_LO:spp_swp_data_select(ccsds_data,42*8+7-7,7), $
    gap:0B}
  return, str
end

;FSW_REC_HK_ALLOC_ERR_06_CDH_RAM_HK_TT,                         42,    7,    1;
;FSW_REC_HK_ALLOC_ERR_05_CDH_SSR_HK_TT,                         42,    6,    1;
;FSW_REC_HK_ALLOC_ERR_04_SWEAP_TT,                              42,    5,    1;
;FSW_REC_HK_ALLOC_ERR_03_FIELDS_TT,                             42,    4,    1;
;FSW_REC_HK_ALLOC_ERR_02_WISPR_TT,                              42,    3,    1;
;FSW_REC_HK_ALLOC_ERR_01_EPIHI_TT,                              42,    2,    1;
;FSW_REC_HK_ALLOC_ERR_00_EPILO_TT,                              42,    1,    1;

function SPP_SC_HK_0x1c4_apdat::decom,ccsds, source_dict=source_dict   ;,ptp_header=ptp_header

  ccsds_data = spp_swp_ccsds_data(ccsds)
  str2 = spp_SC_HK_0x1c4_struct(ccsds_data)
  struct_assign,ccsds,str2,/nozero
  return,str2

end


pro spp_SC_HK_0x1c4_apdat__define

  void = {spp_SC_HK_0x1c4_apdat, $
    inherits spp_gen_apdat, $    ; superclass
    flag: 0 $
  }
end

;SC_HK_0x1C4
;{
;( Block[250],                                                      ,     ,    8; )
;FSW_REC_HK_TPPH_VERSION,                                        0,    7,    3;
;FSW_REC_HK_TPPH_TYPE,                                           0,    4,    1;
;FSW_REC_HK_TPPH_SEC_HDR_FLAG,                                   0,    3,    1;
;FSW_REC_HK_TPPH_APID,                                           0,    2,   11;
;SC_D_APID,                                                      0,    2,   11;
;FSW_REC_HK_TPPH_SEQ_FLAGS,                                      2,    7,    2;
;FSW_REC_HK_TPPH_SEQ_CNT,                                        2,    5,   14;
;FSW_REC_HK_TPPH_LENGTH,                                         4,    7,   16;
;FSW_REC_HK_TPSH_MET_SEC,                                        6,    7,   32;
;SC_D_MET_SEC,                                                   6,    7,   32;
;FSW_REC_HK_TPSH_MET_SUBSEC,                                    10,    7,    8;
;FSW_REC_HK_TPSH_SBC_PHYS_ID,                                   11,    7,    2;
;FSW_REC_HK_CMD_RCVD_CNT,                                       12,    7,   16;
;FSW_REC_HK_CMD_EXEC_CNT,                                       14,    7,   16;
;FSW_REC_HK_CMD_FAIL_CNT,                                       16,    7,   16;
;FSW_REC_HK_CMD_PKT_FAIL_CNT,                                   18,    7,   16;
;FSW_REC_HK_CMD_CHECK_FAIL_CNT,                                 20,    7,   16;
;FSW_REC_HK_CMD_EXEC_FAIL_CNT,                                  22,    7,   16;
;FSW_REC_HK_APP_CYCLE_CNT,                                      24,    7,   16;
;FSW_REC_HK_LOW_PRIORITY_TASK_HTB,                              28,    7,    1;
;FSW_REC_HK_CLOSE_ALL_IN_PROGRESS,                              28,    6,    1;
;FSW_REC_HK_CLOSE_ALL_SUCCESS,                                  28,    5,    1;
;FSW_REC_HK_RECORD_ENA_RAM,                                     29,    1,    1;
;FSW_REC_HK_RECORD_ENA_SSR,                                     29,    0,    1;
;FSW_REC_HK_PKT_RCVD_CNT,                                       30,    7,   16;
;FSW_REC_HK_PKT_ACCEPTED_CNT,                                   32,    7,   16;
;FSW_REC_HK_PKT_RECORDED_CNT,                                   34,    7,   16;
;FSW_REC_HK_PKT_RECORDED_TOTAL,                                 36,    7,   32;
;FSW_REC_HK_ALLOC_ERR_15_TT,                                    40,    0,    1;
;FSW_REC_HK_ALLOC_ERR_14_TT,                                    41,    7,    1;
;FSW_REC_HK_ALLOC_ERR_13_TT,                                    41,    6,    1;
;FSW_REC_HK_ALLOC_ERR_12_TT,                                    41,    5,    1;
;FSW_REC_HK_ALLOC_ERR_11_TT,                                    41,    4,    1;
;FSW_REC_HK_ALLOC_ERR_10_TT,                                    41,    3,    1;
;FSW_REC_HK_ALLOC_ERR_09_TT,                                    41,    2,    1;
;FSW_REC_HK_ALLOC_ERR_08_TT,                                    41,    1,    1;
;FSW_REC_HK_ALLOC_ERR_07_TT,                                    41,    0,    1;
;FSW_REC_HK_ALLOC_ERR_06_CDH_RAM_HK_TT,                         42,    7,    1;
;FSW_REC_HK_ALLOC_ERR_05_CDH_SSR_HK_TT,                         42,    6,    1;
;FSW_REC_HK_ALLOC_ERR_04_SWEAP_TT,                              42,    5,    1;
;FSW_REC_HK_ALLOC_ERR_03_FIELDS_TT,                             42,    4,    1;
;FSW_REC_HK_ALLOC_ERR_02_WISPR_TT,                              42,    3,    1;
;FSW_REC_HK_ALLOC_ERR_01_EPIHI_TT,                              42,    2,    1;
;FSW_REC_HK_ALLOC_ERR_00_EPILO_TT,                              42,    1,    1;
;FSW_REC_HK_CMD_REJ_LP_SET_ALLOC_CURR_USAGE_TT,                 43,    7,    1;
;FSW_REC_HK_CMD_REJ_LP_PFT_APID_MOD_MULTIPLE_TT,                43,    6,    1;
;FSW_REC_HK_CMD_REJ_LP_PFT_APID_MOD_SINGLE_TT,                  43,    5,    1;
;FSW_REC_HK_CMD_REJ_LP_FILE_CLOSE_ALL_TT,                       43,    4,    1;
;FSW_REC_HK_CMD_REJ_LP_FILE_CLOSE_TT,                           43,    3,    1;
;FSW_REC_HK_CMD_REJ_LP_FILE_OPEN_TT,                            43,    2,    1;
;FSW_REC_HK_CMD_REJ_LP_RECORD_ENA_SEL_TT,                       43,    1,    1;
;FSW_REC_HK_CMD_REJ_LP_TT,                                      43,    0,    1;
;FSW_REC_HK_CMD_FIND_FILE_FAIL_TT,                              44,    7,    1;
;FSW_REC_HK_CMD_MOVE_FILE_FAIL_TT,                              44,    6,    1;
;FSW_REC_HK_CMD_CLOSE_FILE_FAIL_TT,                             44,    5,    1;
;FSW_REC_HK_CMD_OPEN_FILE_FAIL_TT,                              44,    4,    1;
;FSW_REC_HK_AUTO_FIND_FILE_FAIL_TT,                             44,    3,    1;
;FSW_REC_HK_AUTO_MOVE_FILE_FAIL_TT,                             44,    2,    1;
;FSW_REC_HK_AUTO_CLOSE_FILE_FAIL_TT,                            44,    1,    1;
;FSW_REC_HK_AUTO_OPEN_FILE_FAIL_TT,                             44,    0,    1;
;FSW_REC_HK_LP_CMD_PUT_FAIL_CNT,                                46,    7,   16;
;FSW_REC_HK_LP_CMD_PUT_FAIL_CNT_LSB,                            47,    7,    8;
;FSW_REC_HK_LP_CMDS_RCVD_CNT,                                   48,    7,   16;
;FSW_REC_HK_LP_CMDS_RCVD_CNT_LSB,                               49,    7,    8;
;FSW_REC_HK_LP_CMDS_UNKNOWN_CNT,                                50,    7,   16;
;FSW_REC_HK_LP_CMDS_UNKNOWN_CNT_LSB,                            51,    7,    8;
;FSW_REC_HK_LP_CMDS_FAIL_CNT,                                   52,    7,   16;
;FSW_REC_HK_LP_CMDS_FAIL_CNT_LSB,                               53,    7,    8;
;FSW_REC_HK_SSR_FILES_OPEN_CNT,                                 54,    7,    8;
;FSW_REC_HK_RAM_FILES_OPEN_CNT,                                 55,    7,    8;
;FSW_REC_HK_BYTES_RECORDED_THIS_SEC,                            56,    7,   32;
;FSW_REC_HK_BYTES_RECORDED_TOTAL,                               60,    7,   32;
;FSW_REC_HK_FILE_CMD_OPEN_FAIL_CNT,                             64,    7,    8;
;FSW_REC_HK_FILE_CMD_CLOSE_FAIL_CNT,                            65,    7,    8;
;FSW_REC_HK_FILE_CMD_MOVE_FAIL_CNT,                             66,    7,    8;
;FSW_REC_HK_FILE_CMD_FIND_FAIL_CNT,                             67,    7,    8;
;FSW_REC_HK_FILE_CMD_OPEN_SUCCESS_CNT,                          68,    7,   16;
;FSW_REC_HK_FILE_CMD_CLOSE_SUCCESS_CNT,                         70,    7,   16;
;FSW_REC_HK_FILE_CMD_MOVE_SUCCESS_CNT,                          72,    7,   16;
;FSW_REC_HK_FILE_CMD_FIND_SUCCESS_CNT,                          74,    7,   16;
;FSW_REC_HK_FILE_CMD_LAST_CLOSE_NAME[32],                       76,    7,    8;
;FSW_REC_HK_FILE_CMD_LAST_CLOSE_RC,                            108,    7,    8;
;FSW_REC_HK_FILE_CMD_LAST_CLOSE_PRIORITY,                      109,    7,    8;
;FSW_REC_HK_FILE_CMD_LAST_CLOSE_INST_H,                        110,    7,    4;
;FSW_REC_HK_FILE_CMD_LAST_CLOSE_INST_L,                        110,    3,    4;
;FSW_REC_HK_FILE_CMD_LAST_OPEN_NAME[32],                       112,    7,    8;
;FSW_REC_HK_FILE_CMD_LAST_OPEN_RC,                             144,    7,    8;
;FSW_REC_HK_FILE_CMD_LAST_OPEN_PRIORITY,                       145,    7,    8;
;FSW_REC_HK_FILE_CMD_LAST_OPEN_INST_H,                         146,    7,    4;
;FSW_REC_HK_FILE_CMD_LAST_OPEN_INST_L,                         146,    3,    4;
;FSW_REC_HK_FILE_AUTO_OPEN_FAIL_CNT,                           148,    7,    8;
;FSW_REC_HK_FILE_AUTO_CLOSE_FAIL_CNT,                          149,    7,    8;
;FSW_REC_HK_FILE_AUTO_MOVE_FAIL_CNT,                           150,    7,    8;
;FSW_REC_HK_FILE_AUTO_FIND_FAIL_CNT,                           151,    7,    8;
;FSW_REC_HK_FILE_AUTO_OPEN_SUCCESS_CNT,                        152,    7,   16;
;FSW_REC_HK_FILE_AUTO_CLOSE_SUCCESS_CNT,                       154,    7,   16;
;FSW_REC_HK_FILE_AUTO_MOVE_SUCCESS_CNT,                        156,    7,   16;
;FSW_REC_HK_FILE_AUTO_FIND_SUCCESS_CNT,                        158,    7,   16;
;FSW_REC_HK_FILE_AUTO_LAST_CLOSE_NAME[32],                     160,    7,    8;
;FSW_REC_HK_FILE_AUTO_LAST_CLOSE_RC,                           192,    7,    8;
;FSW_REC_HK_FILE_AUTO_LAST_CLOSE_PRIORITY,                     193,    7,    8;
;FSW_REC_HK_FILE_AUTO_LAST_CLOSE_INST_H,                       194,    7,    4;
;FSW_REC_HK_FILE_AUTO_LAST_CLOSE_INST_L,                       194,    3,    4;
;FSW_REC_HK_FILE_AUTO_LAST_OPEN_NAME[32],                      196,    7,    8;
;FSW_REC_HK_FILE_AUTO_LAST_OPEN_RC,                            228,    7,    8;
;FSW_REC_HK_FILE_AUTO_LAST_OPEN_PRIORITY,                      229,    7,    8;
;FSW_REC_HK_FILE_AUTO_LAST_OPEN_INST_H,                        230,    7,    4;
;FSW_REC_HK_FILE_AUTO_LAST_OPEN_INST_L,                        230,    3,    4;
;FSW_REC_HK_LP_CMDS_SUCCESS_CNT,                               232,    7,   16;
;FSW_REC_HK_LP_CMDS_SUCCESS_CNT_LSB,                           233,    7,    8;
;FSW_REC_HK_PFT_TOTAL_SUBSCRIPTIONS,                           234,    7,   16;
;FSW_REC_HK_FS_FULL_SSR_PKT_DISCARD_CNT,                       236,    7,   32;
;FSW_REC_HK_FS_FULL_RAM_PKT_DISCARD_CNT,                       240,    7,   32;
;FSW_REC_HK_FS_CREATE_FAIL_CNT,                                244,    7,   16;
;FSW_REC_HK_FS_WRITE_FAIL_CNT,                                 246,    7,   16;
;FSW_REC_HK_ALLOC_MGMT_ENA_SSR,                                248,    7,    8;
;FSW_REC_HK_ALLOC_MGMT_ENA_RAM,                                249,    7,    8;
;}
