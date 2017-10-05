; Slow Housekeeping
function spp_swp_spani_slow_hkp_96x_decom, ccsds , ptp_header=ptp_header, apdat=apdat

  b = ccsds.data
  psize = 128                ; new version
  psize = 132                ; Used for Abiad's memory testing
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
         time:            ccsds.time, $
         met:             ccsds.met,  $
         delay_time:      ptp_header.ptp_time - ccsds.time, $
         seq_cntr:        ccsds.seq_cntr, $
 
         REVN:            b[12],  $
         CMDS_REC:        spp_swp_word_decom(b,13),  $
         CMDS_UNK:        ishft(b[15],4), $
         CMDS_ERR:        b[15] and 'f'x, $

         GND0_CH0_OFF:       ishft(b[16],-2),$ ;first 6 bits
         GND0:               (spp_swp_word_decom(b,16) AND '3FF'x) * 4.2520,  $ ;last 10 bits of word
         GND1_CH0_OFF:       ishft(b[18],-2),$  ;first 6 bits
         GND1:               (spp_swp_word_decom(b,18) AND '3FF'x) * 4.2520,  $ ;last 10 bits of word
         LVPS_CH0_OFF:       ishft(b[20],-2),$
         MON_LVPS_TEMP:      func(spp_swp_word_decom(b,20) * 1., param = temp_par_8bit),  $
         R22A_V_CH0_OFF:     ishft(b[22],-2),$   
         MON_22A_V:          (spp_swp_word_decom(b,22) AND '3FF'x) * 0.0281,$
         R1P5D_V_CH0_OFF:    ishft(b[24],-2),$
         MON_1P5D_V:         (spp_swp_word_decom(b,24) AND '3FF'x) * 0.0024,$
         R3P3A_V_CH0_OFF:    ishft(b[26],-2),$
         MON_3P3A_V:         (spp_swp_word_decom(b,26) AND '3FF'x) * 0.0037,$
         R3P3D_V_CH0_OFF:    ishft(b[28],-2),$
         MON_3P3D_V:         (spp_swp_word_decom(b,28) AND '3FF'x) * 0.0037,$
         RN8VA_C_CH0_OFF:    ishft(b[30],-2),$
         MON_N8VA_C:         (spp_swp_word_decom(b,30) AND '3FF'x) * 0.0117,$
         RN5VA_C_CH0_OFF:    ishft(b[32],-2),$
         MON_N5VA_C:         (spp_swp_word_decom(b,32) AND '3FF'x) * 0.0063,$
         RP8VA_C_CH0_OFF:    ishft(b[34],-2),$
         MON_P8VA_C:         (spp_swp_word_decom(b,34) AND '3FF'x) * 0.0117,$
         RP5A_C_CH0_OFF:     ishft(b[36],-2),$
         MON_P5A_C:          (spp_swp_word_decom(b,36) AND '3FF'x) * 0.0063,$
         ANAL_TEMP_CH0_OFF:  ishft(b[38],-2),$
         MON_ANAL_TEMP:      func(spp_swp_word_decom(b,38) * 1., param = temp_par_8bit),  $
         R3P3_C_CH0_OFF:     ishft(b[40],-2),$
         MON_3P3_C:          (spp_swp_word_decom(b,40) AND '3FF'x) * 0.5720,$
         R1P5_C_CH0_OFF:     ishft(b[42],-2),$
         MON_1P5_C:          (spp_swp_word_decom(b,42) AND '3FF'x) * 0.1720,$
         RP5I_C_CH0_OFF:     ishft(b[44],-2),$
         MON_P5I_c:          (spp_swp_word_decom(b,44) AND '3FF'x) * 2.4340,$
         RN5I_C_CH0_OFF:     ishft(b[46],-2),$
         MON_N5I_C:          (spp_swp_word_decom(b,46) AND '3FF'x) * 2.4340,$

         
         ACC_ERR_CNT:        ishft(b[48],-6),$          ; First 2 bits
         CDI_ERR_CNT:        ishft(b[48],-4) AND '11'b,$   ; Next  2 bits
         MON_ACC_V:          (spp_swp_word_decom(b,48) AND 'FFF'x) * 3.6630,$ ; Last 12 bits of word
         
         SRAM_ERR_CNT:       ishft(b[50],-6),$          ; First 2 bits
         TLM_ERR_CNT:        ishft(b[50],-4) AND '11'b,$   ; Next  2 bits
         MON_DEF1_V:         (spp_swp_word_decom(b,50) AND 'FFF'x) * 0.9768,$ ; Last 12 bits of word
         
         TOF_ERR_CNT:        ishft(b[52],-6),$               ; First 2 bits
         HV_ERR_CNT:         ishft(b[52],-4) AND '11'b,$   ; Next  2 bits
         MON_ACC_C:          (spp_swp_word_decom(b,52) AND 'FFF'x) * 0.0075,$ ; Last 12 bits of word  
         
         PROD_ERR_CNT:       ishft(b[54],-6),$               ; First 2 bits
         SP_ERR_CNT:         ishft(b[54],-4) AND '11'b,$   ; Next  2 bits
         MON_DEF2_V:         (spp_swp_word_decom(b,54) AND 'FFF'x) * 0.9768,$ ; Last 12 bits of word
         
         FSM_ERR_CNT:        ishft(b[56],-4),$               ; First 4 bits
         MON_MCP_V:          (spp_swp_word_decom(b,56) AND 'FFF'x) * 0.9162,$ ; Last 12 bits of word

         MEM_ERR_CNT:        ishft(b[58],-4),$               ; First 4 bits
         MON_SPOIL_V:        (spp_swp_word_decom(b,58) AND 'FFF'x) * 0.0195,$ ; Last 12 bits of word 

         PROD_LUT_MSB:       ishft(b[60],-7) AND '1'b,$    ; First  bit
         HV_LUT_MSB:         ishft(b[60],-6) AND '1'b,$    ; Second bit
         READ_NONVE:         ishft(b[60],-5) AND '1'b,$    ; Third  bit
         CAL_RESET:          ishft(b[60],-4) AND '1'b,$    ; Fourth bit
         MON_MCP_C:          (spp_swp_word_decom(b,60) AND 'FFF'x) * 0.0199,$ ; Last 12 bits of word

         HKP_SIZE:           ishft(b[62],-7) AND '1'b,$    ; First  bit
         TOF_COMPR:          ishft(b[62],-6) AND '1'b,$    ; Second bit
         TP_ENA:             ishft(b[62],-5) AND '1'b,$    ; Third  bit
         ALL_FULL_SWP:       ishft(b[62],-4) AND '1'b,$    ; Fourth bit
         MON_TDC_TEMP:       func(spp_swp_word_decom(b,62 )  * 1. ,param = temp_par_12bit) , $

         RESET_CNT:          ishft(b[64],-4),$             ; First 4 bits
         MON_RAW_V:          (spp_swp_word_decom(b,64) AND 'FFF'x) * 1.2210,$ ; Last 12 bits of word

         PROD_SV:            ishft(b[66],-7),$             ; First  bit
         PROD_AP:            ishft(b[66],-6),$             ; Second bit
         TOF_HIST:           ishft(b[66],-5),$             ; Third  bit
         RAW_EVENTS:         ishft(b[66],-4),$             ; Fourth bit
         MON_FPGA_TEMP:      func(spp_swp_word_decom(b,66 )  * 1. ,param = temp_par_12bit) , $

         BOARD_ID:           ishft(b[68],-6),$               ; First 2 bits
         HV_KEY_ENA:         ishft(b[68],-5),$               ; Next bit
         HV_ENABLED:         ishft(b[68],-4),$               ; Next bit
         MON_RAW_C:          (spp_swp_word_decom(b,68) AND 'FFF'x) * 0.0244,$ ; Last 12 bits of word

         HV_MODE:            ishft(b[70],-4),$               ; First 4 bits
         MON_HEM_V:          (spp_swp_word_decom(b,70) AND 'FFF'x) * 0.9768,$ ; Last 12 bits of word

         MAXCNT:             spp_swp_word_decom(b,72), $
         MODE_ID:            spp_swp_word_decom(b,74), $
         PPULSE_MASK:        spp_swp_word_decom(b,76), $
         PEAK_STEP:          b[78], $

         CVRPRIME:           ishft(b[79],-7) AND '1'b,$
         CVRSEC:             ishft(b[79],-6) AND '1'b,$
         ACTOPENPRIME:       ishft(b[79],-5) AND '1'b,$
         ACTSHUTPRIME:       ishft(b[79],-4) AND '1'b,$
         ACTOPENSEC:         ishft(b[79],-3) AND '1'b,$
         ACTSHUTSEC:         ishft(b[79],-2) AND '1'b,$
         ACTI:               ishft(b[79],-1) AND '1'b,$
         RLXOPENA:           b[79] AND '1'b,$

         PEAK_CNT:           spp_swp_word_decom(b,80),$
         TIME_CMDS:          ishft(b[82],-4),$
         PPULSE_SEL:         ishft(b[82],-2) AND '11'b,$
         F0_CNT:             (spp_swp_word_decom(b,82) AND '3FF'x),$
         
         ERR_ATN:            ishft(b[84],-2),$
         ERR_CVR:            b[84] AND '11'b,$

         PILUT_CHKSUM:       b[85], $       
         TSLUT_CHKSUM:       b[86], $
         SLUT_CHKSUM:        b[87], $
         MLUT_CHKSUM:        b[88], $
         MRAN_CHKSUM:        b[89], $
         PSUM_CHKSUM:        b[90], $
         PADD_CHKSUM:        b[91], $
         FSLUT_CHKSUM:       b[92], $
         PEADL_CHKSUM:       b[93], $
         PMBINS_CHKSUM:      b[94], $
         SPSUM_CHKSUM:       b[95], $

         atn_relax_tm:       spp_swp_word_decom(b,96),$ ; 16 bits
         cvr_relax_tm:       spp_swp_word_decom(b,98),$ ; 16 bits
         actin_act_time:     spp_swp_word_decom(b,100),$ ; 16 bits
         actout_act_time:    spp_swp_word_decom(b,102),$ ; 16 bits
         DAC_MCP:            spp_swp_word_decom(b,104), $
         DAC_ACC:            spp_swp_word_decom(b,106), $
         DAC_RAW:            spp_swp_word_decom(b,108), $
         PEAK_MASK:          spp_swp_word_decom(b,110), $
         act_override:       b[112],$ ;  8 bits
         TIMEOUT_CVR:        b[113],$  
         TIMEOUT_ATN:        b[114],$
         TIMEOUT_RELAX:      b[115],$
         TABLE_CHKSUM:       b[116],$
         MRAM_ADDR:          spp_swp_word_decom(b,117), $ ;;;!!!!! CHANGE TO 24 bits !!!!!
         HEMI_CDI:           spp_swp_word_decom(b,120), $
         SPOILER_CDI:        spp_swp_word_decom(b,122), $
         DEF1_CDI:           spp_swp_word_decom(b,124), $
         DEF2_CDI:           spp_swp_word_decom(b,126), $
         PEAK_UPDATE_CYC:    b[128],$
         CDI_ADDR:          spp_swp_word_decom(b,117), $ ;;;!!!!! CHANGE TO 24 bits !!!!!

         GAP:            ccsds.gap }
  
  if debug(3) then printdat,spai,/hex

  return,spai
  
end
