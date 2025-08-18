;; Slow Housekeeping
function spp_swp_spanai_slow_hkp_decom_version_50x,ccsds , ptp_header=ptp_header, apdat=apdat     

  b = ccsds.data
  psize = 68
  if n_elements(b) ne psize then begin
     dprint,dlevel=1, 'Size error ',ccsds.size,ccsds.apid
     return,0
  endif
  
  sf0 = ccsds.data[11] and 3
  if sf0 ne 0 then dprint, 'Odd time at: ',time_string(ccsds.time)
  
  ref = 5. ; Volts   (EM is 5 volt reference,  FM will be 4 volt reference)                                                                               

  spai = { $
         time: ccsds.time, $
         met: ccsds.met,  $
         delay_time: ptp_header.ptp_time - ccsds.time, $
         seq_cntr: ccsds.seq_cntr, $
         GND0: b[16],  $
         GND1: b[17],  $
         LVPS_TEMP: b[18] * 1.,  $
         Vmon_22VA: b[19] * 0.1118 ,  $
         vmon_1P5V: b[20] * .0068  ,  $
         Imon_3P3VA: b[21] * .0149 ,  $
         vmon_3P3VD: b[22] * .0149 ,  $
         Imon_N12VA: b[23] * .0456 ,  $
         Imon_N5VA: b[24]  * .0251 ,  $
         Imon_P12VA: b[25] * .0449 ,  $
         Imon_P5VA: b[26] * .0252 ,  $
         ANAL_TEMP: b[27] *1.,  $
         IMON_3P3I: b[28] * 1.15,  $
         IMON_1P5I: b[29] * .345,  $
         IMON_P5I: b[30] * 1.955,  $
         IMON_N5I: b[31] * 4.887,  $
         HVMON_ACC:  swap_endian(/swap_if_little_endian,  fix(b,32 ) ) * ref*3750./4095. , $
         HVMON_DEF1: swap_endian(/swap_if_little_endian,  fix(b,34 ) ) * ref*1000./4095., $
         HIMON_ACC: swap_endian(/swap_if_little_endian,  fix(b,36 ) ) * ref/130.*1000./4095. , $
         HVMON_DEF2: swap_endian(/swap_if_little_endian,  fix(b,38 ) ) * ref*1000./4095. , $
         HVMON_MCP:  swap_endian(/swap_if_little_endian,  fix(b,40 ) ) * ref*938./4095 , $
         HVMON_SPOIL:swap_endian(/swap_if_little_endian,  fix(b,42 ) ) * ref*80./4./4095. , $
         HIMON_MCP:  swap_endian(/swap_if_little_endian,  fix(b,44 ) ) * ref*20.408/4095 , $
         TDC_TEMP:  swap_endian(/swap_if_little_endian,  fix(b,46 ) ) * 1. , $
         HVMON_RAW: swap_endian(/swap_if_little_endian,  fix(b,48 ) ) *  ref*1250./4095 , $
         FPGA_TEMP: swap_endian(/swap_if_little_endian,  fix(b,50 ) ) * 1. , $
         HIMON_RAW:  swap_endian(/swap_if_little_endian,  fix(b,52 ) ) * ref*25./ 4095. , $
         ;spare0
         ;spare1
         HVMON_HEM: swap_endian(/swap_if_little_endian,   fix(b,56 ) ) *ref *1000./4095  , $
         ;spare2
         ;spare3
         ;SPAI_0X11
         CMD_ERRS: ishft(b[61],-4), $
         CMD_REC:  swap_endian(/swap_if_little_endian, uint( b,61 ) ) and 'fff'x , $
         ;SPAI_0X44
         MAXCNT: swap_endian(/swap_if_little_endian, uint(b, 64 ) ),  $
         ;SPAI_00
         ACTSTAT_FLAG: b[67]  , $
         GAP: ccsds.gap }

  return,spai

end
