; Slow Housekeeping
function spp_swp_spani_slow_hkp_9dx_decom, $
   ccsds , $
   ptp_header=ptp_header, $
   apdat=apdat

  b = ccsds.data
  
 ; printdat,apdat
 if ptr_valid(apdat.last_ccsds) && keyword_set(*(apdat.last_ccsds)) then  last_ccsds = *(apdat.last_ccsds) else last_ccsds = 0
 
 if keyword_set(last_ccsds) then begin
  dseq_cntr = (ccsds.seq_cntr - last_ccsds.seq_cntr) and '3fff'xu
  dtime = ccsds.time - last_ccsds.time
 endif else begin
   dseq_cntr =  1u
   dtime = !values.d_nan
 endelse
 

  ;;------------------
  ;; Housekeeping Size
  psize = 136

  ;;------------------
  ;; Size Check
  if n_elements(b) ne psize then begin
     dprint,dlevel=1, 'Size error ',$
            psize,ccsds.size,n_elements(b),ccsds.apid
     return,0
  endif
  
  sf0 = ccsds.data[11] and 3
  if sf0 ne 0 then dprint, 'Odd time at: ',time_string(ccsds.time)

  ;; Volts   
  ;; EM is 5 Volt reference.
  ;; FM will be 4 Volt reference.
  ref = 4.                      

  n=0  
  temp_par = spp_swp_therm_temp()
  temp_par_8bit = temp_par
  temp_par_8bit.xmax = 255
  temp_par_12bit = temp_par
  temp_par_12bit.xmax = 4095

  ;;-----------------------------------------------------------
  ;; Decommutator

  spai = { $

         time:            ccsds.time, $
         dtime:           dtime/dseq_cntr, $
         time_mod1:         (ccsds.met) mod 1 , $
         time2_mod1:      (ccsds.met / (2L^24/19.2d6) ) mod 1, $
         met:             ccsds.met,  $
         delay_time:      ptp_header.ptp_time - ccsds.time, $
         seq_cntr:        ccsds.seq_cntr, $
         dseq_cntr:       dseq_cntr   < 15, $
 
         REVN:            b[12],  $
         CMDS_REC:        spp_swp_word_decom(b,13),  $
         CMDS_UNK:        ishft(b[15],4), $
         CMDS_ERR:        b[15] and 'f'x, $

         CH0_OFF:         ishft(b[16],-2),$
         GND0:            (spp_swp_word_decom(b,16) AND '3FF'x) * 4.2520,  $
         CH1_OFF:         ishft(b[18],-2),$
         GND1:            (spp_swp_word_decom(b,18) AND '3FF'x) * 4.2520,  $
         CH2_OFF:         ishft(b[20],-2),$
         MON_LVPS_TEMP:   func(spp_swp_word_decom(b,20) * 1., param = temp_par_8bit),  $
         CH3_OFF:         ishft(b[22],-2),$   
         MON_22A_V:       (spp_swp_word_decom(b,22) AND '3FF'x) * 0.0281,$
         CH4_OFF:         ishft(b[24],-2),$
         MON_1P5D_V:      (spp_swp_word_decom(b,24) AND '3FF'x) * 0.0024,$
         CH5_OFF:         ishft(b[26],-2),$
         MON_3P3A_V:      (spp_swp_word_decom(b,26) AND '3FF'x) * 0.0037,$
         CH6_OFF:         ishft(b[28],-2),$
         MON_3P3D_V:      (spp_swp_word_decom(b,28) AND '3FF'x) * 0.0037,$
         CH7_OFF:         ishft(b[30],-2),$
         MON_N8VA_C:      (spp_swp_word_decom(b,30) AND '3FF'x) * 0.0117,$
         CH8_OFF:         ishft(b[32],-2),$
         MON_N5VA_C:      (spp_swp_word_decom(b,32) AND '3FF'x) * 0.0063,$
         CH9_OFF:         ishft(b[34],-2),$
         MON_P8VA_C:      (spp_swp_word_decom(b,34) AND '3FF'x) * 0.0117,$
         CH10_OFF:        ishft(b[36],-2),$
         MON_P5A_C:       (spp_swp_word_decom(b,36) AND '3FF'x) * 0.0063,$
         CH11_OFF:        ishft(b[38],-2),$
         MON_ANAL_TEMP:   func(spp_swp_word_decom(b,38) * 1., param = temp_par_8bit),  $
         CH12_OFF:        ishft(b[40],-2),$
         MON_3P3_C:       (spp_swp_word_decom(b,40) AND '3FF'x) * 0.5720,$
         CH13_OFF:        ishft(b[42],-2),$
         MON_1P5_C:       (spp_swp_word_decom(b,42) AND '3FF'x) * 0.1720,$
         CH14_OFF:        ishft(b[44],-2),$
         MON_P5I_c:       (spp_swp_word_decom(b,44) AND '3FF'x) * 2.4340,$
         CH15_OFF:        ishft(b[46],-2),$
         MON_N5I_C:       (spp_swp_word_decom(b,46) AND '3FF'x) * 2.4340,$
         
         ACC_ERR_CNT:     ishft(b[48],-6),$                                ; First 2 bits
         CDI_ERR_CNT:     ishft(b[48],-4) AND '11'b,$                      ; Next  2 bits
         MON_ACC_V:       (spp_swp_word_decom(b,48) AND 'FFF'x) * 3.6630,$ ; Last 12 bits of word
         
         SRAM_ERR_CNT:    ishft(b[50],-6),$                                ; First 2 bits
         TLM_ERR_CNT:     ishft(b[50],-4) AND '11'b,$                      ; Next  2 bits
         MON_DEF1_V:      (spp_swp_word_decom(b,50) AND 'FFF'x) * 0.9768,$ ; Last 12 bits of word
         
         TOF_ERR_CNT:     ishft(b[52],-6),$                                ; First 2 bits
         HV_ERR_CNT:      ishft(b[52],-4) AND '11'b,$                      ; Next  2 bits
         MON_ACC_C:       (spp_swp_word_decom(b,52) AND 'FFF'x) * 0.0075,$ ; Last 12 bits of word  
         
         PROD_ERR_CNT:    ishft(b[54],-6),$                                ; First 2 bits
         SP_ERR_CNT:      ishft(b[54],-4) AND '11'b,$                      ; Next  2 bits
         MON_DEF2_V:      (spp_swp_word_decom(b,54) AND 'FFF'x) * 0.9768,$ ; Last 12 bits of word
         
         FSM_ERR_CNT:     ishft(b[56],-4),$                                ; First 4 bits
         MON_MCP_V:       (spp_swp_word_decom(b,56) AND 'FFF'x) * 0.9162,$ ; Last 12 bits of word

         MEM_ERR_CNT:     ishft(b[58],-4),$                                ; First 4 bits
         MON_SPOIL_V:     (spp_swp_word_decom(b,58) AND 'FFF'x) * 0.0195,$ ; Last 12 bits of word 

         PROD_LUT_MSB:    ishft(b[60],-7) AND '1'b,$    ; First  bit
         HV_LUT_MSB:      ishft(b[60],-6) AND '1'b,$    ; Second bit
         READ_NONVE:      ishft(b[60],-5) AND '1'b,$    ; Third  bit
         CAL_RESET:       ishft(b[60],-4) AND '1'b,$    ; Fourth bit
         MON_MCP_C:       (spp_swp_word_decom(b,60) AND 'FFF'x) * 0.0199,$ ; Last 12 bits of word

         HKP_SIZE:        ishft(b[62],-7) AND '1'b,$    ; First  bit
         TOF_COMPR:       ishft(b[62],-6) AND '1'b,$    ; Second bit
         TP_ENA:          ishft(b[62],-5) AND '1'b,$    ; Third  bit
         ALL_FULL_SWP:    ishft(b[62],-4) AND '1'b,$    ; Fourth bit
         MON_TDC_TEMP:    func(spp_swp_word_decom(b,62 )  * 1. ,param = temp_par_12bit) , $

         RESET_CNT:       ishft(b[64],-4),$                                ; First 4 bits
         MON_RAW_V:       (spp_swp_word_decom(b,64) AND 'FFF'x) * 1.2210,$ ; Last 12 bits of word

         PROD_SV:         ishft(b[66],-7) AND '1'b,$             ; First  bit
         PROD_AP:         ishft(b[66],-6) AND '1'b,$             ; Second bit
         TOF_HIST:        ishft(b[66],-5) AND '1'b,$             ; Third  bit
         RAW_EVENTS:      ishft(b[66],-4) AND '1'b,$             ; Fourth bit
         MON_FPGA_TEMP:   func(spp_swp_word_decom(b,66 )  * 1. ,param = temp_par_12bit) , $

         BOARD_ID:        ishft(b[68],-6),$               ; First 2 bits
         HV_KEY_ENA:      ishft(b[68],-5) AND '1'b,$      ; Next bit
         HV_ENABLED:      ishft(b[68],-4) AND '1'b,$      ; Next bit
         MON_RAW_C:       (spp_swp_word_decom(b,68) AND 'FFF'x) * 0.0244,$ ; Last 12 bits of word

         HV_MODE:         ishft(b[70],-4),$               ; First 4 bits
         MON_HEM_V:       (spp_swp_word_decom(b,70) AND 'FFF'x) * 0.9768,$ ; Last 12 bits of word

         MAXCNT:          spp_swp_word_decom(b,72), $
         MODE_ID:         spp_swp_word_decom(b,74), $
         PPULSE_MASK:     spp_swp_word_decom(b,76), $
         PEAK_STEP:       b[78], $

         CVRPRIME:        ishft(b[79],-7) AND '1'b,$
         CVRSEC:          ishft(b[79],-6) AND '1'b,$
         ACTOPENPRIME:    ishft(b[79],-5) AND '1'b,$
         ACTSHUTPRIME:    ishft(b[79],-4) AND '1'b,$
         ACTOPENSEC:      ishft(b[79],-3) AND '1'b,$
         ACTSHUTSEC:      ishft(b[79],-2) AND '1'b,$
         ACTI:            ishft(b[79],-1) AND '1'b,$
         RLXOPENA:        b[79] AND '1'b,$

         PEAK_CNT:        spp_swp_word_decom(b,80),$
         TIME_CMDS:       ishft(b[82],-4),$
         PPULSE_SEL:      ishft(b[82],-2) AND '11'b,$
         F0_CNT:          (spp_swp_word_decom(b,82) AND '3FF'x),$
         
         ERR_ATN:         ishft(b[84],-2),$
         ERR_CVR:         b[84] AND '11'b,$

         PILUT_CHKSUM:    b[85], $       
         TSLUT_CHKSUM:    b[86], $
         SLUT_CHKSUM:     b[87], $
         MLUT_CHKSUM:     b[88], $
         MRAN_CHKSUM:     b[89], $
         PSUM_CHKSUM:     b[90], $
         PADD_CHKSUM:     b[91], $
         FSLUT_CHKSUM:    b[92], $
         PEADL_CHKSUM:    b[93], $
         PMBINS_CHKSUM:   b[94], $
         
         PEAK_CYCLE:      ishft(b[95],-4), $            ; First 4 bits 
         PEAK_OVERRIDE:   ishft(b[95],-3) AND '1'b, $   ; Bit 5 
         EXT_PULSER:      ishft(b[95],-2) AND '1'b, $   ; Bit 6 
         DLL_PULSER:      ishft(b[95],-1) AND '1'b, $   ; Bit 7 
         MEMTEST:         ishft(b[95], 0) AND '1'b, $   ; Bit 8 

         ATN_RELAX_TM:    spp_swp_word_decom(b,96),$  
         CVR_RELAX_TM:    spp_swp_word_decom(b,98),$  
         ACTIN_ACT_TIME:  spp_swp_word_decom(b,100),$ 
         ACTOUT_ACT_TIME: spp_swp_word_decom(b,102),$ 
         DAC_MCP:         spp_swp_word_decom(b,104), $
         DAC_ACC:         spp_swp_word_decom(b,106), $
         DAC_RAW:         spp_swp_word_decom(b,108), $
         PEAK_MASK:       spp_swp_word_decom(b,110), $
         ACT_OVERRIDE:    b[112],$ 
         TIMEOUT_CVR:     b[113],$  
         TIMEOUT_ATN:     b[114],$
         TIMEOUT_RELAX:   b[115],$
         TABLE_CHKSUM:    b[116],$
         RATES_CYCLES:    ishft(b[117],-5), $
         MRAM_ADDR:       spp_swp_word_decom(b,117), $ ;;;!!!!! CHANGE TO LSB 21 bits !!!!!
         HEMI_CDI:        spp_swp_word_decom(b,120), $
         SPOILER_CDI:     spp_swp_word_decom(b,122), $
         DEF1_CDI:        spp_swp_word_decom(b,124), $
         DEF2_CDI:        spp_swp_word_decom(b,126), $

         ACT_COOLTIME:       ishft(ishft(b[128],1) or b[129],-7),$
         SNAPSHOT_FULL_AP:   ishft(b[129],-6) AND   '1'b,$
         SNAPSHOT_TARG_AP:   ishft(b[129],-5) AND   '1'b,$
         SNAPSHOT_FULL_SP:   ishft(b[129],-4) AND   '1'b,$
         SNAPSHOT_TARG_SP:   ishft(b[129],-3) AND   '1'b,$
         SRAM_CDI_ADDR:      ishft(b[129]     AND '111'b,16) OR $
                             ishft(b[130], 8)  OR b[131],$
         
         SUMMEM_ERR:  ishft(b[132],-6) AND   '11'b,$
         PALMEM_ERR:  ishft(b[132],-4) AND   '11'b,$
         EDLMEM_ERR:  ishft(b[132],-2) AND   '11'b,$
         MREM_ERR:    ishft(b[132], 0) AND   '11'b,$
         PMBMEM_ERR:  ishft(b[133],-6) AND   '11'b,$
         APFIFO_ERR:  ishft(b[133],-2) AND '1111'b,$
         TOFMEM_ERR:  ishft(b[133],-0) AND   '11'b,$
         ACCMEM_ERR:  ishft(b[134],-6) AND   '11'b,$
         MLUTMEM_ERR: ishft(b[134],-4) AND   '11'b,$
         SP_MEM_ERR:  ishft(b[134], 0) AND '1111'b,$
         
         RIO_NO_ACK:   ishft(b[135],-7),$
         CLKS_PER_NYS: b[135] AND '7f'x,$

         GAP:            ccsds.gap }
  
  if debug(5) then printdat,spai,/hex

  return,spai
  
end
