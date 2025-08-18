;;---------------------------------------
;; Slow Housekeeping




function spp_swp_spane_slow_hkp_v48x_decom,ccsds , ptp_header=ptp_header, apdat=apdat

  b = ccsds.data
  ;print, 'SIZE[B]', size(b)
  ;  psize = 69  ; REV  16
  ;  psize =81   ; REV 19
  ;  psize =89   ; REV 26?
  psize = 101                   ; REV 29
  psize = 97                    ;  REV 27
  psize = 105                   ; REV ??
  psize = 113                   ; REV ???????
  psize = 117                   ; REV 3B
  psize = 133                   ; rev 3d
  psize = 141                   ; rev 43
  
  if n_elements(b) ne psize+7 then begin
    dprint,dlevel=2, 'Size error ',time_string(ccsds.time,prec=2),' ',n_elements(b),ccsds.size,string(ccsds.apid,format='(4z)')
;    printdat,apdat
;    hexprint,ccsds.data[0:31]
;   
;    stop
    return,0
  endif

 if ccsds.apid eq '16e'x then  hexprint,ccsds.data;[0:31]

  if keyword_set(apdat) && ptr_valid(apdat.dataindex) && keyword_set(*apdat.dataindex) then begin
    last_spae = (*apdat.dataptr)[*apdat.dataindex -1]
    ;   printdat,last_spae
  endif else dprint,dlevel=3,'No previous structure'

  sf0 = ccsds.data[11] and 3
  if sf0 ne 0 then dprint,dlevel=4, 'Odd time at: ',time_string(ccsds.time)

  ref = 5.29 ; Volts   (EM is 5 volt reference,  FM will be 4 volt reference)

  rio_scale = .002444
  rio_mask = 'fff'x
  spae = { $

    time:           ccsds.time, $
    met:            ccsds.met,  $
    delay_time:     ptp_header.ptp_time - ccsds.time, $
    seq_cntr:       ccsds.seq_cntr, $
    HDR_12:         b[12], $
    HDR_13:         b[13], $
    HDR_14:         b[14], $
    HDR_15:         b[15], $
    HDR_16:         b[16], $
    HDR_17:         b[17], $
    HDR_18:         b[18], $
    HDR_19:         b[19], $
    RIO_20:        spp_swp_word_decom(b,20,mask=rio_mask) *1., $     ; swap_endian(/swap_if_little_endian,  fix(b,20 ) ),$
    RIO_21:        spp_swp_word_decom(b,22,mask=rio_mask) *1. , $      ; swap_endian(/swap_if_little_endian,  fix(b,22 ) ),$
    RIO_LVPS_TEMP: spp_swp_word_decom(b,24,mask=rio_mask) *1., $      ; swap_endian(/swap_if_little_endian,  fix(b,24 ) ),$
    RIO_22VA:      spp_swp_word_decom(b,26,mask=rio_mask) *0.111886, $     ; swap_endian(/swap_if_little_endian,  fix(b,26 ) ),$
    RIO_1p5VD:     spp_swp_word_decom(b,28,mask=rio_mask) *0.006789, $    ; swap_endian(/swap_if_little_endian,  fix(b,28 ) ),$
    RIO_3p3VDA:    spp_swp_word_decom(b,30,mask=rio_mask) *0.014911, $     ; swap_endian(/swap_if_little_endian,  fix(b,30 ) ),$
    RIO_3p3VD:     spp_swp_word_decom(b,32,mask=rio_mask) *0.014911, $     ; swap_endian(/swap_if_little_endian,  fix(b,32 ) ),$
    RIO_M8Va:      spp_swp_word_decom(b,34,mask=rio_mask) *0.045627, $     ; swap_endian(/swap_if_little_endian,  fix(b,34 ) ),$
    RIO_M5VA:      spp_swp_word_decom(b,36,mask=rio_mask) *0.025063, $     ; swap_endian(/swap_if_little_endian,  fix(b,36 ) ),$
    RIO_P85A:      spp_swp_word_decom(b,38,mask=rio_mask) *0.044899 , $    ; swap_endian(/swap_if_little_endian,  fix(b,38 ) ),$
    RIO_P5VA:      spp_swp_word_decom(b,40,mask=rio_mask) *0.025183, $     ; swap_endian(/swap_if_little_endian,  fix(b,40 ) ),$
    RIO_ANAL_TEMP: spp_swp_word_decom(b,42,mask=rio_mask)  *1., $    ; swap_endian(/swap_if_little_endian,  fix(b,42 ) ),$
    RIO_3p3I:      spp_swp_word_decom(b,44,mask=rio_mask) *1.150 , $    ; swap_endian(/swap_if_little_endian,  fix(b,44 ) ),$
    RIO_1p5I:      spp_swp_word_decom(b,46,mask=rio_mask) *0.345 , $    ; swap_endian(/swap_if_little_endian,  fix(b,46 ) ),$
    RIO_P5IA:      spp_swp_word_decom(b,48,mask=rio_mask) *1.955 , $    ; swap_endian(/swap_if_little_endian,  fix(b,48 ) ),$
    RIO_M5IA:      spp_swp_word_decom(b,50,mask=rio_mask) *4.887 , $    ; swap_endian(/swap_if_little_endian,  fix(b,50 ) ),$
    adc_VMON_MCP:  spp_swp_word_decom(b,52,mask=adc_mask)  *ref/4095. , $   ;swap_endian(/swap_if_little_endian,  fix(b,52 ) ) * ref/4095. , $
    adc_VMON_DEF1: spp_swp_word_decom(b,54,mask=adc_mask)  *ref*1000./4095. , $   swap_endian(/swap_if_little_endian,  fix(b,54 ) ) * ref*1000./4095. , $
    adc_IMON_MCP:  spp_swp_word_decom(b,56,mask=adc_mask)  *ref/4095. , $   swap_endian(/swap_if_little_endian,  fix(b,56 ) ) * ref/4095. , $
    adc_VMON_DEF2: spp_swp_word_decom(b,58,mask=adc_mask)  *ref*1000./4095.  , $   swap_endian(/swap_if_little_endian,  fix(b,58 ) ) * ref*1000./4095. , $
    adc_VMON_RAW:  spp_swp_word_decom(b,60,mask=adc_mask)  *ref*752.88/4095. , $   swap_endian(/swap_if_little_endian,  fix(b,60 ) ) * ref*752.88/4095. , $
    adc_VMON_SPL:  spp_swp_word_decom(b,62,mask=adc_mask)  *ref*20.12/4095. , $   swap_endian(/swap_if_little_endian,  fix(b,62 ) ) * ref*20.12/4095. , $
    adc_IMON_RAW:  spp_swp_word_decom(b,64,mask=adc_mask)  *ref*1000./40.2/4095. , $   swap_endian(/swap_if_little_endian,  fix(b,64 ) ) * ref*1000./40.2/4095. , $
    adc_PCBT:      spp_swp_word_decom(b,66,mask=adc_mask)  *ref/4095. , $   swap_endian(/swap_if_little_endian,  fix(b,66 ) ) * ref/4095. , $
    adc_HEMIV:     spp_swp_word_decom(b,68,mask=adc_mask)  *ref*1271./4095. , $   swap_endian(/swap_if_little_endian,  fix(b,68 ) ) * ref*1271./4095. , $
    adc_FPGAT:     spp_swp_word_decom(b,70,mask=adc_mask)  *ref/4095.  , $   swap_endian(/swap_if_little_endian,  fix(b,70 ) ) * ref/4095. , $
    adc_ch10:      spp_swp_word_decom(b,72,mask=adc_mask)  *ref*1000./40.2/4095. , $   swap_endian(/swap_if_little_endian,  fix(b,72 ) ) * ref*1000./40.2/4095. , $
    adc_ASICT:     spp_swp_word_decom(b,74,mask=adc_mask)  *ref/4095. , $   swap_endian(/swap_if_little_endian,  fix(b,74 ) ) * ref/4095. , $
    adc_ch12:      spp_swp_word_decom(b,76,mask=adc_mask)  *ref*1000./4095., $   swap_endian(/swap_if_little_endian,  fix(b,76 ) ) * ref*1000./4095. , $
    adc_ch13:      spp_swp_word_decom(b,78,mask=adc_mask)  *ref/4095. , $   swap_endian(/swap_if_little_endian,  fix(b,78 ) ) * ref/4095. , $
    adc_ch14:      spp_swp_word_decom(b,80,mask=adc_mask)  *ref/4095., $   swap_endian(/swap_if_little_endian,  fix(b,80 ) ) * ref/4095. , $
    adc_ch15:      spp_swp_word_decom(b,82,mask=adc_mask)  *ref/4095. , $   swap_endian(/swap_if_little_endian,  fix(b,82 ) ) * ref/4095. , $
    cmd_ignd:       b[84]    , $
    reset_cntr:     b[85]    , $
    BRD_ID:         b[86]    , $
    REVNUM:         b[87]  , $
    CMD_ERRS:       b[88]    , $
    cmd_ukn:        b[89]    , $
    CMD_REC:        swap_endian(/swap_if_little_endian, uint( b,90  ) ) and 'ffff'x , $
    raw_dac:        swap_endian(/swap_if_little_endian, uint( b,92  ) ) and 'ffff'x , $
    hv_conf_flag:   b[94]  , $
    ACTSTAT_FLAG:   b[95]  , $
    mcp_dac:        swap_endian(/swap_if_little_endian, uint( b,96  ) ) and 'ffff'x , $
    acc_dac:        swap_endian(/swap_if_little_endian, uint( b,98  ) ) and 'ffff'x , $
    peak_cmd_val:   b[100],$
    peak_meas:      b[101],$
    cycle_cnt:      swap_endian(/swap_if_little_endian, uint( b,102 ) ) and 'ffff'x , $
    peak_ch_mask:   swap_endian(/swap_if_little_endian, uint( b,104 ) ) and 'ffff'x , $
    lut_peak_sel:   b[106],$
    peak_step:      b[107],$ 
    fhkp_set:       b[108],$
    ppulse_set:     b[109],$
    foo_step:       b[110],$
    stim_mode:      b[111],$
    timeout_cvr:    b[112],$
    timeout_atn:    b[113],$
    timeout_rlx:    swap_endian(/swap_if_little_endian, uint( b,114 ) ) and 'ffff'x , $
    csum_pilut4:    b[116],$
    csum_pilut3:    b[117],$
    csum_pilut2:    b[118],$
    csum_pilut1:    b[119],$
    easic_dac:      swap_endian(/swap_if_little_endian, uint( b,120 ) ) and 'ffff'x , $
    tcmds_rcvd:     b[122],$
    act_overide:    b[123],$
    atn_rlx_t:      swap_endian(/swap_if_little_endian, uint( b,124 ) ) and 'ffff'x , $
    act_cvr_t:      swap_endian(/swap_if_little_endian, uint( b,126 ) ) and 'ffff'x , $
    act_ati_t:      swap_endian(/swap_if_little_endian, uint( b,128 ) ) and 'ffff'x , $
    act_ato_t:      swap_endian(/swap_if_little_endian, uint( b,130 ) ) and 'ffff'x , $
    ppulse_mask:    swap_endian(/swap_if_little_endian, uint( b,132 ) ) and 'ffff'x , $
    act_err_code:   b[134],$
    csum_tab_load:  b[135],$
    max_cnt:        swap_endian(/swap_if_little_endian, uint( b,136 ) ) and 'ffff'x , $
    peak_cnt:       swap_endian(/swap_if_little_endian, uint( b,138 ) ) and 'ffff'x , $
    pkt_csum:       swap_endian(/swap_if_little_endian, uint( b,140 ) ) and 'ffff'x , $
    GAP:            ccsds.gap}

  return,spae

end

