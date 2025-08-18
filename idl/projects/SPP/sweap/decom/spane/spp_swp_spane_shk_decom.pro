; Slow Housekeeping

function spp_swp_spane_shk_decom,ccsds , ptp_header=ptp_header, apdat=apdat     
  
  b = ccsds.data
  ;psize = 69   ;; REV 16
  ;psize = 81   ;; REV 19
  ;psize = 89   ;; REV 26?
  ;psize = 101  ;; REV 29
  ;psize = 97   ;; REV 27
  ;psize = 105  ;; REV ??
  psize = 113  ;; REV ???????

  stop
  ;;------------------------------------
  ;; Check packet size
  if n_elements(b) ne psize+7 then begin
     dprint,dlevel=1, 'Size error ',$
            ccsds.size,ccsds.apid
     return,0
  endif

  ;;------------------------------------
  ;; Check for structure
  if keyword_set(apdat) && $
     ptr_valid(apdat.dataindex) && $
     keyword_set(*apdat.dataindex) then begin
     last_spae = (*apdat.dataptr)[*apdat.dataindex -1]
  endif else dprint,'No previous structure'


  ;;------------------------------------
  ;; Error Check for odd times
  sf0 = ccsds.data[11] and 3
  if sf0 ne 0 then $
     dprint, dlevel=4, 'Odd time at: ',time_string(ccsds.time)


  ;;------------------------------------
  ;; EM is 5 volt reference  
  ;; FM will be 4 volt reference
  ref = 5.29 ;; [Volts]   

  ;;------------------------------------
  ;; RIO Scale
  rio_scale = .002444


  ;;-----------------------------------------------
  ;; SHK Structure
  spae = { $

    time: ccsds.time, $
    met: ccsds.met,  $
    delay_time: ptp_header.ptp_time - ccsds.time, $
    seq_cntr: ccsds.seq_cntr, $

    HDR_16:     b[16]  * 1.,  $
    HDR_17:     b[17]  * 1.,  $
    HDR_18:     b[18]  * 1.,  $
    HDR_19:     b[19]  * 1.,  $

    RIO_20:        b[20]  * 1.,  $
    RIO_21:       b[21]  * 1.,  $
    RIO_LVPS_TEMP: b[22]  * 1.,  $
    RIO_22VA:   b[23]  * rio_scale * 45.78,  $
    RIO_1p5VD:  b[24]  * rio_scale * 2.778,  $
    RIO_3p3VDA: b[25]  * rio_scale * 6.101,  $
    RIO_3p3VD:  b[26]  * rio_scale * 6.101,  $
    RIO_M8VA:   b[27]  * rio_scale * 18.669,  $
    RIO_M5VA:   b[28]  * rio_scale * 10.255,  $
    RIO_P85A:   b[29]  * rio_scale * 18.371,  $
    RIO_P5VA:   b[30]  * rio_scale * 10.304,  $
    RIO_ANAL_TEMP: b[31]  * 1.,  $
    RIO_3p3I:   b[32]  * 1.15,  $
    RIO_1p5I:   b[33]  * 0.345,  $
    RIO_P5IA:   b[34]  * 1.955,  $
    RIO_M5IA:   b[35]  * 4.887,  $
    adc_ch00:      swap_endian(/swap_if_little_endian,  fix(b,36 ) ) * ref/4095. , $
    adc_VMON_DEF1: swap_endian(/swap_if_little_endian,  fix(b,38 ) ) * ref*1000./4095. , $
    adc_ch02:      swap_endian(/swap_if_little_endian,  fix(b,40 ) ) * ref/4095. , $
    adc_VMON_DEF2: swap_endian(/swap_if_little_endian,  fix(b,42 ) ) * ref*1000./4095. , $
    adc_VMON_MCP:  swap_endian(/swap_if_little_endian,  fix(b,44 ) ) * ref*752.88/4095. , $
    adc_VMON_SPL:  swap_endian(/swap_if_little_endian,  fix(b,46 ) ) * ref*20.12/4095. , $
    adc_IMON_MCP:  swap_endian(/swap_if_little_endian,  fix(b,48 ) ) * ref*1000./40.2/4095. , $
    adc_ch07:      swap_endian(/swap_if_little_endian,  fix(b,50 ) ) * ref/4095. , $
    adc_VMON_RAW:  swap_endian(/swap_if_little_endian,  fix(b,52 ) ) * ref*1271./4095. , $
    adc_ch09:      swap_endian(/swap_if_little_endian,  fix(b,54 ) ) * ref/4095. , $
    adc_IMON_RAW:  swap_endian(/swap_if_little_endian,  fix(b,56 ) ) * ref*1000./40.2/4095. , $
    adc_ch11:      swap_endian(/swap_if_little_endian,  fix(b,58 ) ) * ref/4095. , $
    adc_VMON_HEM:  swap_endian(/swap_if_little_endian,  fix(b,60 ) ) * ref*1000./4095. , $
    adc_ch13:      swap_endian(/swap_if_little_endian,  fix(b,62 ) ) * ref/4095. , $
    adc_ch14:      swap_endian(/swap_if_little_endian,  fix(b,64 ) ) * ref/4095. , $
    adc_ch15:      swap_endian(/swap_if_little_endian,  fix(b,66 ) ) * ref/4095. , $
    cmd_ignd:   b[68]  , $
    CMD_ERRS:   b[72] , $
    CMD_REC:  swap_endian(/swap_if_little_endian, uint( b,74 ) ) and 'ffff'x , $
    cmd_ukn:    b[73] , $
    reset_cntr: b[69] , $
    BRD_ID:     b[70]  ,  $
    REVNUM:     b[71]  * 1.,  $
    raw_dac:   swap_endian(/swap_if_little_endian, uint( b,76 ) ) and 'ffff'x , $
    mcp_dac:   swap_endian(/swap_if_little_endian, uint( b,80 ) ) and 'ffff'x , $
    acc_dac:   swap_endian(/swap_if_little_endian, uint( b,82 ) ) and 'ffff'x , $
    max_cnt:   swap_endian(/swap_if_little_endian, uint( b,84 ) ) and 'ffff'x , $
    cycle_cnt: swap_endian(/swap_if_little_endian, uint( b,86 ) ) and 'ffff'x , $
    dCMD_ERRS: 0b , $
    dCMD_REC:  0u , $
    dcmd_ignd: 0b , $
    dcmd_ukn:  0b , $
    dreset_cntr:0b , $
    hv_conf_flag: b[66]  , $
    ACTSTAT_FLAG: b[67]  , $
    GAP: ccsds.gap }


  if keyword_set(last_spae) then begin
     spae.dcmd_errs = spae.cmd_errs - last_spae.cmd_errs
     spae.dcmd_rec = spae.cmd_rec   - last_spae.cmd_rec
     spae.dcmd_ukn = spae.cmd_ukn   - last_spae.cmd_ukn
     spae.dcmd_ignd = spae.cmd_ignd - last_spae.cmd_ignd
  endif
  
  return,spae
  
end




