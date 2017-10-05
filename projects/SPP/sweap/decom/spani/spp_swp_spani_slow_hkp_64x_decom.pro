;; Slow Housekeeping
function spp_swp_spani_slow_hkp_decom_version_64x,ccsds , ptp_header=ptp_header, apdat=apdat     

  b = ccsds.data
  psize = 69+7
  if n_elements(b) ne psize then begin
     dprint,dlevel=1, 'Size error ',ccsds.size,ccsds.apid
     return,0
  endif

  sf0 = ccsds.data[11] and 3
  if sf0 ne 0 then dprint, 'Odd time at: ',time_string(ccsds.time)
  ;Volts   (EM is 5 volt reference,  FM will be 4 volt reference)                                                                             
  ref = 4. 
  n=0
  
  temp_par= spp_sweap_therm_temp()
  temp_par_8bit = temp_par
  temp_par_8bit.xmax = 255
  temp_par_12bit = temp_par
  temp_par_12bit.xmax = 4095
  
  spai = { $
         time: ccsds.time, $
         met: ccsds.met,  $
         delay_time: ptp_header.ptp_time - ccsds.time, $
         seq_cntr: ccsds.seq_cntr, $
         REVN: b[12],  $
         CMDS_REC: spp_swp_word_decom(b,13),  $
         cmds_unk:  ishft(b[15],4), $
         cmds_err:  b[15] and 'f'x, $
         GND0: b[16],  $
         GND1: b[17],  $
         Vmon_22VA: b[19] * 0.1118 ,  $
         vmon_1P5V: b[20] * .0068  ,  $
         Imon_3P3VA: b[21] * .0149 ,  $
         vmon_3P3VD: b[22] * .0149 ,  $
         Imon_N12VA: b[23] * .0456 ,  $
         Imon_N5VA: b[24]  * .0251 ,  $
         Imon_P12VA: b[25] * .0449 ,  $
         Imon_P5VA: b[26] * .0252 ,  $
         IMON_3P3I: b[28] * 1.15,  $
         IMON_1P5I: b[29] * .345,  $
         IMON_P5I: b[30] * 1.955,  $
         IMON_N5I: b[31] * 4.887,  $
         LVPS_TEMP: func(b[18] * 1., param = temp_par_8bit),  $
         ANAL_TEMP: func(b[27] * 1., param = temp_par_8bit),  $
         TDC_TEMP:  func(spp_swp_word_decom(b,46 )  * 1. ,param = temp_par_12bit) , $
         FPGA_TEMP: func(spp_swp_word_decom(b,50 )  * 1. ,param = temp_par_12bit) , $
         HVMON_ACC:  swap_endian(/swap_if_little_endian,  uint(b,32 ) ) * ref*3750./4095. , $
         HVMON_DEF1: swap_endian(/swap_if_little_endian,  uint(b,34 ) ) * ref*1000./4095., $
         HIMON_ACC: swap_endian(/swap_if_little_endian,  uint(b,36 ) ) * ref/130.*1000./4095. , $
         HVMON_DEF2: swap_endian(/swap_if_little_endian,  uint(b,38 ) ) * ref*1000./4095. , $
         HVMON_MCP:  swap_endian(/swap_if_little_endian,  uint(b,40 ) ) * ref*938./4095 , $
         HVMON_SPOIL:swap_endian(/swap_if_little_endian,  uint(b,42 ) ) * ref*80./4./4095. , $
         HIMON_MCP:  swap_endian(/swap_if_little_endian,  uint(b,44 ) ) * ref*20.408/4095 , $
         HVMON_RAW: swap_endian(/swap_if_little_endian,  uint(b,48 ) ) *  ref*1250./4095 , $
         HIMON_RAW:  swap_endian(/swap_if_little_endian,  uint(b,52 ) ) * ref*25./ 4095. , $
         HVMON_HEM: swap_endian(/swap_if_little_endian,   uint(b,54 ) ) *ref *1000./4095  , $
         DAC_RAW: spp_swp_word_decom(b,56)   , $
         MAXCNT: swap_endian(/swap_if_little_endian, uint(b, 64 ) ),  $
         DAC_MCP: spp_swp_word_decom(b,60), $
         DAC_ACC: spp_swp_word_decom(b,62), $
         HV_STATUS_FLAG: spp_swp_word_decom(b,58), $
         Cycle_cnt: spp_swp_word_decom(b,66), $
         reset_cnt: spp_swp_word_decom(b,68), $
         user2: 0u, $
         ACTSTAT_FLAG: b[72]  , $
         user3: b[73] ,$
         user4: spp_swp_word_decom(b,74) ,$
         GAP: ccsds.gap }

  return,spai

end


