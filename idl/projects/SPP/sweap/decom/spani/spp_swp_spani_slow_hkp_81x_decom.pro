;; Slow Housekeeping
function spp_swp_spanai_slow_hkp_81x_decom,ccsds , ptp_header=ptp_header, apdat=apdat     

  b = ccsds.data
  psize = 97+7   ; should be 94
  if n_elements(b) ne psize then begin
     dprint,dlevel=1, 'Size error',ccsds.size,ccsds.apid                                                                                              
     return,0
  endif

  sf0 = ccsds.data[11] and 3
  if sf0 ne 0 then dprint, 'Odd time at: ',time_string(ccsds.time)
  
  ;; Volts
  ;; EM is 5 volt reference
  ;; FM will be 4 volt reference
  ref = 4.
  n=0

  temp_par      = spp_sweap_therm_temp()
  temp_par_8bit = temp_par
  temp_par_8bit.xmax  = 255
  temp_par_12bit      = temp_par
  temp_par_12bit.xmax = 4095

  spai = { $
         time:           ccsds.time,$
         met:            ccsds.met,$
         delay_time:     ptp_header.ptp_time - ccsds.time,$
         seq_cntr:       ccsds.seq_cntr,$
         REVN:           b[12],$
         CMDS_REC:       spp_swp_word_decom(b,13),$
         cmds_unk:       ishft(b[15],4),$
         cmds_err:       b[15] and 'f'x,$
         GND0:           spp_swp_word_decom(b,16) * 4.2520,$
         GND1:           spp_swp_word_decom(b,18) * 4.2520,$
         MON_LVPS_TEMP:  func(spp_swp_word_decom(b,20) * 1., param = temp_par_8bit),  $
         mon_22A_V:      spp_swp_word_decom(b,22) * 0.0281,$
         mon_1P5D_V:     spp_swp_word_decom(b,24) * 0.0024,$
         mon_3P3A_V:     spp_swp_word_decom(b,26) * 0.0037,$
         mon_3P3D_V:     spp_swp_word_decom(b,28) * 0.0037,$
         mon_N8VA_C:     spp_swp_word_decom(b,30) * 0.0117,$
         mon_N5VA_C:     spp_swp_word_decom(b,32) * 0.0063,$
         mon_P8VA_C:     spp_swp_word_decom(b,34) * 0.0117,$
         mon_P5A_C:      spp_swp_word_decom(b,36) * 0.0063,$
         MON_ANAL_TEMP:  func(spp_swp_word_decom(b,38) * 1., param = temp_par_8bit),  $
         MON_3P3_C:      spp_swp_word_decom(b,40) * 0.5720,$
         MON_1P5_C:      spp_swp_word_decom(b,42) * 0.1720,$
         MON_P5I_c:      spp_swp_word_decom(b,44) * 2.4340,$
         MON_N5I_C:      spp_swp_word_decom(b,46) * 2.4340,$
         MON_ACC_V:      spp_swp_word_decom(b,48) * 3.6630,$
         MON_DEF1_V:     spp_swp_word_decom(b,50) * 0.9768,$
         MON_ACC_C:      spp_swp_word_decom(b,52) * 0.0075,$
         MON_DEF2_V:     spp_swp_word_decom(b,54) * 0.9768,$
         MON_MCP_V:      spp_swp_word_decom(b,56) * 0.9162,$
         MON_SPOIL_V:    spp_swp_word_decom(b,58) * 0.0195,$
         MON_MCP_C:      spp_swp_word_decom(b,60) * 0.0199,$
         MON_TDC_TEMP:   func(spp_swp_word_decom(b,62 )  * 1. ,param = temp_par_12bit),$
         MON_RAW_V:      spp_swp_word_decom(b,64)  * 1.2210, $
         MON_FPGA_TEMP:  func(spp_swp_word_decom(b,66 )  * 1. ,param = temp_par_12bit),$
         MON_RAW_C:      spp_swp_word_decom(b,68) * .0244,$
         MON_HEM_V:      spp_swp_word_decom(b,70) * .9768,$
         DAC_RAW:        spp_swp_word_decom(b,72),$
         HV_STATUS_FLAG: spp_swp_word_decom(b,74),$
         DAC_MCP:        spp_swp_word_decom(b,76),$
         DAC_ACC:        spp_swp_word_decom(b,78),$
         MAXCNT:         spp_swp_word_decom(b,80),$
         Cycle_cnt:      spp_swp_word_decom(b,82),$
         reset_cnt:      spp_swp_word_decom(b,87),$
         user2:          0u,$
         ACTSTAT_FLAG:   b[74],$
         user3:          b[73],$
         user4:          spp_swp_word_decom(b,74) ,$
         GAP:            ccsds.gap }

  return,spai

end

