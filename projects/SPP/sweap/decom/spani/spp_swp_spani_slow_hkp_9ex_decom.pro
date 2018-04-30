;; Slow Housekeeping
function spp_swp_spani_slow_hkp_9ex_decom,   ccsds ,   ptp_header=ptp_header,   apdat=apdat

  if n_params() eq 0 then begin
    dprint,'Not working yet.'
    return,!null
  endif


;  b = ccsds.data

  ccsds_data = spp_swp_ccsds_data(ccsds)
  b = ccsds_data

 ; printdat,apdat
; if ptr_valid(apdat.last_ccsds) && keyword_set(*(apdat.last_ccsds)) then  last_ccsds = *(apdat.last_ccsds) else last_ccsds = 0
 
; if keyword_set(last_ccsds) then begin
;  dseqn = (ccsds.seqn - last_ccsds.seq_cntr) and '3fff'xu
;  dtime = ccsds.time - last_ccsds.time
; endif else begin
;   dseq_cntr =  1u
;   dtime = !values.d_nan
; endelse

 REVNUMBER      =       b[12]
 if REVNUMBER ne '9e'x then begin
  dprint, dlevel=2, 'Bad Revnumber: ',REVNUMBER
 endif
  
  
  ;;------------------
  ;; Housekeeping Size
  psize = 136

  ;;------------------
  ;; Size Check
  if n_elements(b) eq 96 then begin
    ccsds_data = [ccsds_data,bytarr(136-96)]
    b = ccsds_data
  endif
  
  
  if n_elements(b) ne psize then begin
     dprint,dlevel=1, 'Size error ',  psize,ccsds.pkt_size,n_elements(b),ccsds.apid
     return,0
  endif
  
  sf0 = ccsds_data[11] and 3
  if sf0 ne 0 then dprint, 'Odd time at: ',time_string(ccsds.time)


if debug(5)  then begin   ; compression test
;  common spp_hkp_decom_data, data_delta_last
;  if not keyword_set(data_delta_last) then data_delta_last = b *0
  b_last = keyword_set(last_ccsds) ? last_ccsds.data : b* 0b
;  b_last =  b* 0b
  data_delta = b- b_last
;  data_ddelta = data_delta - data_delta_last
;  data_delta_last = data_delta
  ind = where(data_delta ne 0)
  dprint,total( data_delta ne 0)
  hexprint,data_delta
  printdat,ind
  printdat,ind-shift(ind,1)
  printdat,data_delta[ind]  ;+4b
;  printdat,total(data_ddelta ne 0)
;  hexprint,data_ddelta
endif



  n=0  

  temp_par = spp_swp_therm_temp()

  temp_par_8bit       = temp_par
  temp_par_8bit.xmax  = 255
  temp_par_10bit      = temp_par
  temp_par_10bit.xmax = 1023
  temp_par_12bit      = temp_par
  temp_par_12bit.xmax = 4095

  ;;-----------------------------------------------------------
  ;; Decommutator
  
  MON_LVPS_TEMP =   func((spp_swp_word_decom(b,20) and '3ff'x) *1., param = temp_par_10bit)
  MON_ANAL_TEMP =   func((spp_swp_word_decom(b,38) and '3ff'x) * 1., param = temp_par_10bit)
  MON_TDC_TEMP=     func((spp_swp_word_decom(b,62 ) and 'fff'x)  * 1. ,param = temp_par_12bit)
  MON_FPGA_TEMP=    func((spp_swp_word_decom(b,66 ) and 'fff'x)  * 1. ,param = temp_par_12bit) 
  
  TEMPS = float([mon_lvps_temp,mon_anal_temp,mon_TDC_TEMP,mon_FPGA_TEMP])
  
  ;; Voltages
  

  ;; offsets
  ch_offsets = ishft( b[[16,18,20,22,24,26,28,30,32,34,36,38,40,42,44,46]], -2)
  
  ;  The foolow look wrong!!!
    DAC_MCP=         spp_swp_word_decom(b,104)
    DAC_ACC=         spp_swp_word_decom(b,106)
    DAC_RAW=         spp_swp_word_decom(b,108)
    DAC_HEM=        spp_swp_word_decom(b,120)
    DAC_SPOILER=     spp_swp_word_decom(b,122)
    DAC_DEF1=        spp_swp_word_decom(b,124)
    DAC_DEF2=        spp_swp_word_decom(b,126)
  DAC_VALS  =  [DAC_MCP,DAC_ACC,DAC_RAW,DAC_HEM,DAC_SPOILER,DAC_DEF1,DAC_DEF2]

  ;ADC_VALS2 = spp_swp_word_decom(b,384/8,12,mask = 'fff'x)
; hexprint,ADC_VALS2
  tmp = ulong(b,117)
  rate = ishft(tmp,-29)
  
  spai = { $
         time:            ccsds.time, $
         dtime:           ccsds.time_delta/ccsds.seqn_delta, $
         met_mod1:         ccsds.met mod 1 , $
         time_mod1:      (ccsds.met / (2L^24/19.2d6) ) mod 1, $
         met:             ccsds.met,  $
;         delay_time:      ptp_header.ptp_time - ccsds.time, $
         seqn:        ccsds.seqn, $
         seqn_delta:       ccsds.seqn_delta   < 15, $
 
         REVN:            b[12],  $
         CMDS_REC:        spp_swp_word_decom(b,13) ,  $
         CMDS_UNK:        ishft(b[15],-4), $
         CMDS_ERR:        b[15] and 'f'x, $
         CH_OFFSETS:      ch_offsets, $
;         CH0_OFF:         ishft(b[16],-2),$
;         CH1_OFF:         ishft(b[18],-2),$
;         CH2_OFF:         ishft(b[20],-2),$
;         CH3_OFF:         ishft(b[22],-2),$
;         CH4_OFF:         ishft(b[24],-2),$
;         CH5_OFF:         ishft(b[26],-2),$
;         CH6_OFF:         ishft(b[28],-2),$
;         CH7_OFF:         ishft(b[30],-2),$
;         CH8_OFF:         ishft(b[32],-2),$
;         CH9_OFF:         ishft(b[34],-2),$
;         CH10_OFF:        ishft(b[36],-2),$
;         CH11_OFF:        ishft(b[38],-2),$
;         CH12_OFF:        ishft(b[40],-2),$
;         CH13_OFF:        ishft(b[42],-2),$
;         CH14_OFF:        ishft(b[44],-2),$
;         CH15_OFF:        ishft(b[46],-2),$
         MON_P8VA_I:          (spp_swp_word_decom(b,16) AND '3FF'x) * 4.2520,  $
         MON_N8VA_I:          (spp_swp_word_decom(b,18) AND '3FF'x) * 4.2520,  $
         MON_LVPS_TEMP:   MON_LVPS_TEMP,  $
         MON_22A_V:       (spp_swp_word_decom(b,22) AND '3FF'x) * 0.028104,$
         MON_1P5D_V:      (spp_swp_word_decom(b,24) AND '3FF'x) * 0.0024438,$
         MON_3P3A_V:      (spp_swp_word_decom(b,26) AND '3FF'x) * 0.0037097,$
         MON_3P3D_V:      (spp_swp_word_decom(b,28) AND '3FF'x) * 0.0037097,$
         MON_N8VA_V:      (spp_swp_word_decom(b,30) AND '3FF'x) * 0.01173,$
         MON_N5VA_V:      (spp_swp_word_decom(b,32) AND '3FF'x) * .006295,$
         MON_P8VA_V:      (spp_swp_word_decom(b,34) AND '3FF'x) * 0.01173,$
         MON_P5VA_V:       (spp_swp_word_decom(b,36) AND '3FF'x) * .006295,$
         MON_ANAL_TEMP:   MON_ANAL_TEMP,  $
         MON_3P3_C:       (spp_swp_word_decom(b,40) AND '3FF'x) * 0.572043,$
         MON_1P5_C:       (spp_swp_word_decom(b,42) AND '3FF'x) * 0.64516,$
         MON_P5I_c:       (spp_swp_word_decom(b,44) AND '3FF'x) * 2.4340,$
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
         MON_MCP_V:       (spp_swp_word_decom(b,56) AND 'FFF'x) * (850.*4./4095),$ ; Last 12 bits of word

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
         MON_TDC_TEMP:    MON_TDC_TEMP , $

         RESET_CNT:       ishft(b[64],-4),$                                ; First 4 bits
         MON_RAW_V:       (spp_swp_word_decom(b,64) AND 'FFF'x) * 1.2210,$ ; Last 12 bits of word

         PROD_SV:         ishft(b[66],-7) AND '1'b,$      ; First  bit
         PROD_AP:         ishft(b[66],-6) AND '1'b,$      ; Second bit
         TOF_HIST:        ishft(b[66],-5) AND '1'b,$      ; Third  bit
         RAW_EVENTS:      ishft(b[66],-4) AND '1'b,$      ; Fourth bit
         MON_FPGA_TEMP:   MON_FPGA_TEMP , $

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

         ACT_FLAG:       B[79], $
;         CVRPRIME:        ishft(b[79],-7) AND '1'b,$
;         CVRSEC:          ishft(b[79],-6) AND '1'b,$
;         ACTOPENPRIME:    ishft(b[79],-5) AND '1'b,$
;         ACTSHUTPRIME:    ishft(b[79],-4) AND '1'b,$
;         ACTOPENSEC:      ishft(b[79],-3) AND '1'b,$
;         ACTSHUTSEC:      ishft(b[79],-2) AND '1'b,$
;         ACTI:            ishft(b[79],-1) AND '1'b,$
;         RLXOPENA:        b[79] AND '1'b,$

         PEAK_CNT:        spp_swp_word_decom(b,80),$
         CMDS_TIME:       ishft(b[82],-4),$
         PPULSE_SEL:      ishft(b[82],-2) AND '11'b,$
         F0:          (spp_swp_word_decom(b,82) AND '3FF'x),$
         
         ERR_ATN:         ishft(b[84],-2),$
         ERR_CVR:         b[84] AND '11'b,$

         ALL_CHKSUM:      b[85:94],  $
;         PILUT_CHKSUM:    b[85], $       
;         TSLUT_CHKSUM:    b[86], $
;         SLUT_CHKSUM:     b[87], $
;         MLUT_CHKSUM:     b[88], $
;         MRAN_CHKSUM:     b[89], $
;         PSUM_CHKSUM:     b[90], $
;         PADD_CHKSUM:     b[91], $
;         FSLUT_CHKSUM:    b[92], $
;         PEADL_CHKSUM:    b[93], $
;         PMBINS_CHKSUM:   b[94], $
         
         PEAK_CYCLE:      ishft(b[95],-4), $            ; First 4 bits 
         PEAK_OVERRIDE:   ishft(b[95],-3) AND '1'b, $   ; Bit 5 
         EXT_PULSER:      ishft(b[95],-2) AND '1'b, $   ; Bit 6 
         DLL_PULSER:      ishft(b[95],-1) AND '1'b, $   ; Bit 7 
         MEMTEST:         ishft(b[95], 0) AND '1'b, $   ; Bit 8 

         ATN_RELAX_TM:    spp_swp_word_decom(b,96),$  
         CVR_RELAX_TM:    spp_swp_word_decom(b,98),$  
         ACTIN_ACT_TIME:  spp_swp_word_decom(b,100),$ 
         ACTOUT_ACT_TIME: spp_swp_word_decom(b,102),$ 
         PEAK_MASK_FLAG:       spp_swp_word_decom(b,110), $
         ACT_OVERRIDE:    b[112],$ 
         TIMEOUT_CVR:     b[113],$  
         TIMEOUT_ATN:     b[114],$
         TIMEOUT_RELAX:   b[115],$
         TABLE_CHKSUM:    b[116],$
         RATES_CYCLES:    ishft(b[117],-5), $
         MRAM_ADDR_HI:    b[117] and '11111'b, $
         MRAM_ADDR_low:       spp_swp_word_decom(b,118), $ ;;;!!!!! CHANGE TO LSB 21 bits !!!!!
         DACS:         DAC_VALS,  $
         DAC_DEFL:         long(DAC_DEF1) -  long(DAC_DEF2),  $
;         DACS2  :         ADC_VALS2,  $
         ;ADCS   :         ADC_VALS2,  $
;         DAC_MCP:         DAC_MCP, $
;         DAC_ACC:         DAC_ACC, $
;         DAC_RAW:         DAC_RAW,  $     ;spp_swp_word_decom(b,108), $
;         DAC_HEM:         DAC_HEM, $
;         DAC_SPOILER:     DAC_SPOILER, $
;         DAC_DEF1:        DAC_DEF1, $
;         DAC_DEF2:        DAC_DEF2, $

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
         all_temps : TEMPS, $

         GAP:            ccsds.gap }
  
  if debug(5) then printdat,spai,/hex

  return,spai
  
end
