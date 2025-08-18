; Slow Housekeeping
function spp_swp_spani_slow_hkp_91x_decom, ccsds , ptp_header=ptp_header, apdat=apdat

  b = ccsds.data
  psize = 117+7                 ; new version
  if n_elements(b) ne psize then begin
     dprint,dlevel=1, 'Size error ',psize,ccsds.size,ccsds.apid
     return,0
  endif
  
  sf0 = ccsds.data[11] and 3
  if sf0 ne 0 then dprint, 'Odd time at: ',time_string(ccsds.time)
  ref = 4.                      ; Volts   (EM is 5 volt reference,  FM will be 4 volt reference)
  n=0
  
  temp_par= spp_sweap_therm_temp()
  temp_par_8bit = temp_par
  temp_par_8bit.xmax = 255
  temp_par_12bit = temp_par
  temp_par_12bit.xmax = 4095

  spai = { $
         time:           ccsds.time, $
         met:            ccsds.met,  $
         delay_time:     ptp_header.ptp_time - ccsds.time, $
         seq_cntr:       ccsds.seq_cntr, $

         REVN:           b[12],  $
         CMDS_REC:       spp_swp_word_decom(b,13),  $
         cmds_unk:       ishft(b[15],4), $
         cmds_err:       b[15] and 'f'x, $
         GND0:           spp_swp_word_decom(b,16) * 4.2520,  $
         GND1:           spp_swp_word_decom(b,18) * 4.2520,  $
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
         MON_TDC_TEMP:   func(spp_swp_word_decom(b,62 )  * 1. ,param = temp_par_12bit) , $
         MON_RAW_V:      spp_swp_word_decom(b,64) * 1.2210, $
         MON_FPGA_TEMP:  func(spp_swp_word_decom(b,66 )  * 1. ,param = temp_par_12bit) , $
         MON_RAW_C:      spp_swp_word_decom(b,68) * 0.0244, $
         MON_HEM_V:      spp_swp_word_decom(b,70) * 0.9768, $
         DAC_RAW:        spp_swp_word_decom(b,72), $
         HV_STATUS_FLAG: spp_swp_word_decom(b,74), $
         DAC_MCP:        spp_swp_word_decom(b,76), $
         DAC_ACC:        spp_swp_word_decom(b,78), $
         MAXCNT:         spp_swp_word_decom(b,80), $
         USRVAR:         spp_swp_word_decom(b,82), $

         sram_ADDR:      ishft(b[84] and '3f'xUL,16)  + spp_swp_word_decom(b,85), $
         reset_cntr:     b[87], $
         chksums:        b[88:95] , $
         SLUT_chksum:    b[88], $
         FSLUT_chksum:   b[89], $
         TSLUT_chksum:   b[90], $
         PILUT_chksum:   b[91], $
         MLUT_chksum:    b[92], $
         MRAN_chksum:    b[93], $
         PSUM_chksum:    b[94], $
         PADD_chksum:    b[95], $

         prod_srv:       ishft(b[96],-7) and 1,$ ; 1 bit
         prod_ap:        ishft(b[96],-6) and 1,$ ; 1 bit
         tof_hist:       ishft(b[96],-5) and 1,$ ; 1 bit - currently named processing
         raw_events:     ishft(b[96],-4) and 1,$ ; 1 bit
         time_cmds:      b[96] and '1111'b    ,$ ; 4 bits         

         peadl_chksum:   b[97], $
         PMBINS_chksum:  b[98], $
         table_chksum:   b[99], $

         cycle_cntr:     ishft(spp_swp_word_decom(b,100) ,-5), $ ;top 11 bits
         MRAM_ADDR:      ishft( b[101] and '1f'xul  ,16) + spp_swp_word_decom(b,102), $ ; 21 bits

         
         err_atn:         ishft(b[104],-2)  ,$        ;  6 bits
         err_cvr:         (b[104] and '11'b),$        ;  2 bits
         timeout_cvr:     b[105],$                    ;  8 bits
         timeout_atn:     b[106],$                    ;  8 bits
         timeout_relax:   b[107],$                    ;  8 bits
         atn_relax_tm:    spp_swp_word_decom(b,108),$ ; 16 bits
         cvr_relax_tm:    spp_swp_word_decom(b,110),$ ; 16 bits
         actin_act_time:  spp_swp_word_decom(b,112),$ ; 16 bits
         actout_act_time: spp_swp_word_decom(b,114),$ ; 16 bits
         zero:            b[116] ,$                   ;  8 bits
         peak_cnt:        spp_swp_word_decom(b,117),$ ; 16 bits
         peak_step:       b[119],$                    ;  8 bits
         fsm_errcnt:      b[120],$                    ;  8 bits
         mem_errcnt:      b[121],$                    ;  8 bits
         chksum_spsum:    b[122],$                    ;  8 bits
         act_override:    b[123],$                    ;  8 bits

         GAP:            ccsds.gap }
  
  if debug(3) then printdat,spai,/hex

  return,spai
  
end
