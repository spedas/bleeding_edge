

;
;function spp_swp_spane_slow_hkp_raw_decom,ccsds , ptp_header=ptp_header, apdat=apdat     ; Slow Housekeeping
;
;  b = ccsds.data
;  psize = 81-7
;  if n_elements(b) ne psize+7 then begin
;    dprint,dlevel=1, 'Size error ',ccsds.size,ccsds.apid
;    return,0
;  endif
;
;  sf0 = ccsds.data[11] and 3
;  if sf0 ne 0 then dprint,dlevel=4, 'Odd time at: ',time_string(ccsds.time)
;
;  ref = 5.29 ; Volts   (EM is 5 volt reference,  FM will be 4 volt reference)
;
;  spai = { $
;    time: ccsds.time, $
;    met: ccsds.met,  $
;    delay_time: ptp_header.ptp_time - ccsds.time, $
;    seq_cntr: ccsds.seq_cntr, $
;    HDR_16: b[16]  * 1.,  $
;    HDR_17: b[17]  * 1.,  $
;    HDR_18: b[18]  * 1.,  $
;    HDR_19: b[19]  * 1.,  $
;    
;    RIO_20: b[20]  * 1.,  $
;    RIO_21: b[21]  * 1.,  $
;    RIO_22: b[22]  * 1.,  $
;    RIO_23: b[23]  * 1.,  $
;    RIO_24: b[24]  * 1.,  $
;    RIO_25: b[25]  * 1.,  $
;    RIO_26: b[26]  * 1.,  $
;    RIO_27: b[27]  * 1.,  $
;    RIO_28: b[28]  * 1.,  $
;    RIO_29: b[29]  * 1.,  $
;    RIO_30: b[30]  * 1.,  $
;    RIO_31: b[31]  * 1.,  $
;    RIO_32: b[32]  * 1.,  $
;    RIO_33: b[33]  * 1.,  $
;    RIO_34: b[34]  * 1.,  $
;    RIO_35: b[35]  * 1.,  $
;    adc_ch00:  swap_endian(/swap_if_little_endian,  fix(b,36 ) ) * 1., $ ; ref*3750./4095. , $
;    adc_VMON_DEF1:  swap_endian(/swap_if_little_endian,  fix(b,38 ) ) * 1., $ ; ref*1000./4095. , $
;    adc_ch02:  swap_endian(/swap_if_little_endian,  fix(b,40 ) ) * 1. , $;ref*3750./4095. , $
;    adc_VMON_DEF2: swap_endian(/swap_if_little_endian,  fix(b,42 ) ) * 1., $ ; ref*1000./4095. , $
;    adc_VMON_MCP:  swap_endian(/swap_if_little_endian,  fix(b,44 ) ) * 1., $ ;ref*750./4095. , $
;    adc_VMON_SPL:  swap_endian(/swap_if_little_endian,  fix(b,46 ) ) * 1. , $;ref*20./4095. , $
;    adc_IMON_MCP:  swap_endian(/swap_if_little_endian,  fix(b,48 ) ) * 1. , $;ref*3750./4095. , $
;    adc_ch07:  swap_endian(/swap_if_little_endian,  fix(b,50 ) ) * 1. , $;ref*3750./4095. , $
;    adc_VMON_RAW:  swap_endian(/swap_if_little_endian,  fix(b,52 ) ) * 1., $ ;ref*1250./4095. , $
;    adc_ch09:  swap_endian(/swap_if_little_endian,  fix(b,54 ) ) * 1. , $;ref*3750./4095. , $
;    adc_IMON_RAW:  swap_endian(/swap_if_little_endian,  fix(b,56 ) ) * 1., $ ;ref*3750./4095. , $
;    adc_ch11:  swap_endian(/swap_if_little_endian,  fix(b,58 ) ) * 1. , $;vref*3750./4095. , $
;    adc_VMON_HEM:  swap_endian(/swap_if_little_endian,  fix(b,60 ) ) * 1., $ ; ref*1000./4095. , $
;    adc_ch13:  swap_endian(/swap_if_little_endian,  fix(b,62 ) ) * 1., $ ;ref*3750./4095. , $
;    adc_ch14:  swap_endian(/swap_if_little_endian,  fix(b,64 ) ) * 1. , $;ref*3750./4095. , $
;    adc_ch15:  swap_endian(/swap_if_little_endian,  fix(b,66 ) ) * 1. , $;ref*3750./4095. , $
;    CMD_ERRS: ishft(b[68],-4), $
;    CMD_REC:  swap_endian(/swap_if_little_endian, uint( b,68 ) ) and 'fff'x , $
;    BRD_ID: b[70]  ,  $
;    REVNUM: b[71]  * 1.,  $
;    MAXCNT: swap_endian(/swap_if_little_endian, uint(b, 64 ) ),  $
;    ;  SPAI_00
;    ACTSTAT_FLAG: b[67]  , $
;    GAP: ccsds.gap }
;
;  return,spai
;
;end


function spp_swp_spane_slow_hkp_decom,ccsds , ptp_header=ptp_header, apdat=apdat     ; Slow Housekeeping

  b = ccsds.data
;  psize = 69  ; REV  16
;  psize =81   ; REV 19
;  psize =89   ; REV 26?
  psize = 101 ; REV 29
  psize = 97  ;  REV 27
  psize = 105  ; REV ??
  psize = 113  ; REV ???????
  if n_elements(b) ne psize+7 then begin
    dprint,dlevel=1, 'Size error ',ccsds.size,ccsds.apid
    return,0
  endif

  if keyword_set(apdat) && ptr_valid(apdat.dataindex) && keyword_set(*apdat.dataindex) then begin
    last_spai = (*apdat.dataptr)[*apdat.dataindex -1]
 ;   printdat,last_spai
  endif else dprint,'No previous structure'

  sf0 = ccsds.data[11] and 3
  if sf0 ne 0 then dprint,dlevel=4, 'Odd time at: ',time_string(ccsds.time)



  ref = 5.29 ; Volts   (EM is 5 volt reference,  FM will be 4 volt reference)

  rio_scale = .002444

  spai = { $
    time: ccsds.time, $
    met: ccsds.met,  $
    delay_time: ptp_header.ptp_time - ccsds.time, $
    seq_cntr: ccsds.seq_cntr, $
    HDR_16: b[16]  * 1.,  $
    HDR_17: b[17]  * 1.,  $
    HDR_18: b[18]  * 1.,  $
    HDR_19: b[19]  * 1.,  $

    RIO_20: b[20]  * 1.,  $
    RIO_21: b[21]  * 1.,  $
    RIO_LVPS_TEMP: b[22]  * 1.,  $
    RIO_22VA: b[23]  * rio_scale * 45.78,  $
    RIO_1p5VD: b[24]  * rio_scale * 2.778,  $
    RIO_3p3VDA: b[25]  * rio_scale * 6.101,  $
    RIO_3p3VD: b[26]  * rio_scale * 6.101,  $
    RIO_M8VA: b[27]  * rio_scale * 18.669,  $
    RIO_M5VA: b[28]  * rio_scale * 10.255,  $
    RIO_P85A: b[29]  * rio_scale * 18.371,  $
    RIO_P5VA: b[30]  * rio_scale * 10.304,  $
    RIO_ANAL_TEMP: b[31]  * 1.,  $
    RIO_3p3I: b[32]  * 1.15,  $
    RIO_1p5I: b[33]  * .345,  $
    RIO_P5IA: b[34]  * 1.955,  $
    RIO_M5IA: b[35]  * 4.887,  $
    adc_ch00:  swap_endian(/swap_if_little_endian,  fix(b,36 ) ) * ref/4095. , $
    adc_VMON_DEF1:  swap_endian(/swap_if_little_endian,  fix(b,38 ) ) * ref*1000./4095. , $
    adc_ch02:  swap_endian(/swap_if_little_endian,  fix(b,40 ) ) * ref/4095. , $
    adc_VMON_DEF2: swap_endian(/swap_if_little_endian,  fix(b,42 ) ) * ref*1000./4095. , $
    adc_VMON_MCP:  swap_endian(/swap_if_little_endian,  fix(b,44 ) ) * ref*752.88/4095. , $
    adc_VMON_SPL:  swap_endian(/swap_if_little_endian,  fix(b,46 ) ) * ref*20.12/4095. , $
    adc_IMON_MCP:  swap_endian(/swap_if_little_endian,  fix(b,48 ) ) * ref*1000./40.2/4095. , $
    adc_ch07:  swap_endian(/swap_if_little_endian,  fix(b,50 ) ) * ref/4095. , $
    adc_VMON_RAW:  swap_endian(/swap_if_little_endian,  fix(b,52 ) ) * ref*1271./4095. , $
    adc_ch09:  swap_endian(/swap_if_little_endian,  fix(b,54 ) ) * ref/4095. , $
    adc_IMON_RAW:  swap_endian(/swap_if_little_endian,  fix(b,56 ) ) * ref*1000./40.2/4095. , $
    adc_ch11:  swap_endian(/swap_if_little_endian,  fix(b,58 ) ) * ref/4095. , $
    adc_VMON_HEM:  swap_endian(/swap_if_little_endian,  fix(b,60 ) ) * ref*1000./4095. , $
    adc_ch13:  swap_endian(/swap_if_little_endian,  fix(b,62 ) ) * ref/4095. , $
    adc_ch14:  swap_endian(/swap_if_little_endian,  fix(b,64 ) ) * ref/4095. , $
    adc_ch15:  swap_endian(/swap_if_little_endian,  fix(b,66 ) ) * ref/4095. , $
    cmd_ignd: b[68]  , $
    CMD_ERRS:  b[72] , $
    CMD_REC:  swap_endian(/swap_if_little_endian, uint( b,74 ) ) and 'ffff'x , $
    cmd_ukn:  b[73] , $
    reset_cntr:b[69] , $
    BRD_ID: b[70]  ,  $
    REVNUM: b[71]  * 1.,  $
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

 ; dprint,dlevel=2,ccsds.apid,ccsds.gap
    
if keyword_set(last_spai) then begin
    spai.dcmd_errs = spai.cmd_errs - last_spai.cmd_errs
    spai.dcmd_rec = spai.cmd_rec   - last_spai.cmd_rec
    spai.dcmd_ukn = spai.cmd_ukn   - last_spai.cmd_ukn
    spai.dcmd_ignd = spai.cmd_ignd - last_spai.cmd_ignd
endif

  return,spai

end




function spp_swp_spane_p1_decom,ccsds,ptp_header=ptp_header,apdat=apdat

  data = ccsds.data[20:*]
  ;lll = 512
  lll = 512*4
  if n_elements(data) ne lll then begin
    dprint,'Improper packet size',dlevel=2
    dprint,dlevel=1, 'Size error ',n_elements(data),ccsds.size,ccsds.apid
    return,0
  endif
  ns = lll/4
  cnts = swap_endian(ulong(data,0,ns) ,/swap_if_little_endian )   ; convert 4 bytes to a ulong word
  cnts = reform(cnts,16,ns/16)
  cnts1 = total(cnts,1)
  cnts2 = total(cnts,2)
  tot = total(cnts)   

  if 0 then begin    
    hexprint,data
    savetomain,data
    savetomain,cnts
  endif

  str = { $
    time:ccsds.time, $
    seq_cntr:ccsds.seq_cntr,  $
    seq_group: ccsds.seq_group,  $
    total:tot, $
    ndat: n_elements(cnts), $
    cnts: float(cnts[*]), $ 
    cnts1: float(cnts1), $
    cnts2: float(cnts2), $
    gap: 0 }
    
    if (ccsds.seq_cntr and 1) ne 0 then return,0

  return, str
end




function spp_swp_spane_p2_decom,ccsds,ptp_header=ptp_header,apdat=apdat

  data = ccsds.data[20:*]
  ;lll = 512
  lll = 512*4
  if n_elements(data) ne lll then begin
    dprint,'Improper packet size',dlevel=2
    dprint,dlevel=1, 'Size error ',n_elements(data),ccsds.size,ccsds.apid
    return,0
  endif
  ns = lll/4
  cnts = swap_endian(ulong(data,0,ns) ,/swap_if_little_endian )   ; convert 4 bytes to a ulong word
  cnts = reform(cnts,16,ns/16)
  cnts1 = total(cnts,1)
  cnts2 = total(cnts,2)
  tot = total(cnts)   

  if 0 then begin    
    hexprint,data
    savetomain,data
    savetomain,cnts
  endif

  str = { $
    time:ccsds.time, $
    seq_cntr:ccsds.seq_cntr,  $
    seq_group: ccsds.seq_group,  $
    total:tot, $
    ndat: n_elements(cnts), $
    cnts: float(cnts[*]), $ 
    cnts1: float(cnts1), $
    cnts2: float(cnts2), $

    cnts_a0:  float(reform(cnts[ 0,*])), $ 
    cnts_a1:  float(reform(cnts[ 1,*])), $ 
    cnts_a2:  float(reform(cnts[ 2,*])), $ 
    cnts_a3:  float(reform(cnts[ 3,*])), $ 
    cnts_a4:  float(reform(cnts[ 4,*])), $ 
    cnts_a5:  float(reform(cnts[ 5,*])), $ 
    cnts_a6:  float(reform(cnts[ 6,*])), $ 
    cnts_a7:  float(reform(cnts[ 7,*])), $ 
    cnts_a8:  float(reform(cnts[ 8,*])), $ 
    cnts_a9:  float(reform(cnts[ 9,*])), $ 
    cnts_a10: float(reform(cnts[10,*])), $ 
    cnts_a11: float(reform(cnts[11,*])), $ 
    cnts_a12: float(reform(cnts[12,*])), $ 
    cnts_a13: float(reform(cnts[13,*])), $ 
    cnts_a14: float(reform(cnts[14,*])), $ 
    cnts_a15: float(reform(cnts[15,*])), $ 

    gap: 0 }
    
    if (ccsds.seq_cntr and 1) ne 0 then return,0

  return, str
end


function spp_swp_spane_p3_decom,ccsds,ptp_header=ptp_header,apdat=apdat

  data = ccsds.data[20:*]
  ;lll = 512
  lll = 512*4
  if n_elements(data) ne lll then begin
    dprint,'Improper packet size',dlevel=2
    dprint,dlevel=1, 'Size error ',n_elements(data),ccsds.size,ccsds.apid
    return,0
  endif
  ns = lll/4
  cnts = swap_endian(ulong(data,0,ns) ,/swap_if_little_endian )   ; convert 4 bytes to a ulong word
  cnts = reform(cnts,16,ns/16)
  cnts1 = total(cnts,1)
  cnts2 = total(cnts,2)
  tot = total(cnts)   

  if 0 then begin    
    hexprint,data
    savetomain,data
    savetomain,cnts
  endif

  str = { $
    time:ccsds.time, $
    seq_cntr:ccsds.seq_cntr,  $
    seq_group: ccsds.seq_group,  $
    total:tot, $
    ndat: n_elements(cnts), $
    cnts: float(cnts[*]), $ 
    cnts1: float(cnts1), $
    cnts2: float(cnts2), $
    gap: 0 }
    
    if (ccsds.seq_cntr and 1) ne 0 then return,0

  return, str
end


function spp_swp_spane_p4_decom,ccsds,ptp_header=ptp_header,apdat=apdat

  data = ccsds.data[20:*]
  ;lll = 512
  lll = 512*4
  if n_elements(data) ne lll then begin
    dprint,'Improper packet size',dlevel=2
    dprint,dlevel=1, 'Size error ',n_elements(data),ccsds.size,ccsds.apid
    return,0
  endif
  ns = lll/4
  cnts = swap_endian(ulong(data,0,ns) ,/swap_if_little_endian )   ; convert 4 bytes to a ulong word
  cnts = reform(cnts,16,ns/16)
  cnts1 = total(cnts,1)
  cnts2 = total(cnts,2)
  tot = total(cnts)   

  if 0 then begin    
    hexprint,data
    savetomain,data
    savetomain,cnts
  endif

  str = { $
    time:ccsds.time, $
    seq_cntr:ccsds.seq_cntr,  $
    seq_group: ccsds.seq_group,  $
    total:tot, $
    ndat: n_elements(cnts), $
    cnts: float(cnts[*]), $ 
    cnts1: float(cnts1), $
    cnts2: float(cnts2), $

    cnts_a0:  float(reform(cnts[ 0,*])), $ 
    cnts_a1:  float(reform(cnts[ 1,*])), $ 
    cnts_a2:  float(reform(cnts[ 2,*])), $ 
    cnts_a3:  float(reform(cnts[ 3,*])), $ 
    cnts_a4:  float(reform(cnts[ 4,*])), $ 
    cnts_a5:  float(reform(cnts[ 5,*])), $ 
    cnts_a6:  float(reform(cnts[ 6,*])), $ 
    cnts_a7:  float(reform(cnts[ 7,*])), $ 
    cnts_a8:  float(reform(cnts[ 8,*])), $ 
    cnts_a9:  float(reform(cnts[ 9,*])), $ 
    cnts_a10: float(reform(cnts[10,*])), $ 
    cnts_a11: float(reform(cnts[11,*])), $ 
    cnts_a12: float(reform(cnts[12,*])), $ 
    cnts_a13: float(reform(cnts[13,*])), $ 
    cnts_a14: float(reform(cnts[14,*])), $ 
    cnts_a15: float(reform(cnts[15,*])), $ 

    gap: 0 }
    
    if (ccsds.seq_cntr and 1) ne 0 then return,0

  return, str
end




pro spp_product_init

  ;;--------------------------
  ;; FS Product 0
  options,'spp_spane_p1_CNTS',    spec=1,yrange=[0,16],ylog=0,zrange=[1,500.],zlog=1,/no_interp, ystyle=1

  ;;--------------------------
  ;; FS Product 1
  options,'spp_spane_p2_CNTS_A0', spec=1,yrange=[0,32],ylog=0,zrange=[1,500.],zlog=1,/no_interp, ystyle=1
  options,'spp_spane_p2_CNTS_A1', spec=1,yrange=[0,32],ylog=0,zrange=[1,500.],zlog=1,/no_interp, ystyle=1
  options,'spp_spane_p2_CNTS_A2', spec=1,yrange=[0,32],ylog=0,zrange=[1,500.],zlog=1,/no_interp, ystyle=1
  options,'spp_spane_p2_CNTS_A3', spec=1,yrange=[0,32],ylog=0,zrange=[1,500.],zlog=1,/no_interp, ystyle=1
  options,'spp_spane_p2_CNTS_A4', spec=1,yrange=[0,32],ylog=0,zrange=[1,500.],zlog=1,/no_interp, ystyle=1
  options,'spp_spane_p2_CNTS_A5', spec=1,yrange=[0,32],ylog=0,zrange=[1,500.],zlog=1,/no_interp, ystyle=1
  options,'spp_spane_p2_CNTS_A6', spec=1,yrange=[0,32],ylog=0,zrange=[1,500.],zlog=1,/no_interp, ystyle=1
  options,'spp_spane_p2_CNTS_A7', spec=1,yrange=[0,32],ylog=0,zrange=[1,500.],zlog=1,/no_interp, ystyle=1
  options,'spp_spane_p2_CNTS_A8', spec=1,yrange=[0,32],ylog=0,zrange=[1,500.],zlog=1,/no_interp, ystyle=1
  options,'spp_spane_p2_CNTS_A9', spec=1,yrange=[0,32],ylog=0,zrange=[1,500.],zlog=1,/no_interp, ystyle=1
  options,'spp_spane_p2_CNTS_A10',spec=1,yrange=[0,32],ylog=0,zrange=[1,500.],zlog=1,/no_interp, ystyle=1
  options,'spp_spane_p2_CNTS_A11',spec=1,yrange=[0,32],ylog=0,zrange=[1,500.],zlog=1,/no_interp, ystyle=1
  options,'spp_spane_p2_CNTS_A12',spec=1,yrange=[0,32],ylog=0,zrange=[1,500.],zlog=1,/no_interp, ystyle=1
  options,'spp_spane_p2_CNTS_A13',spec=1,yrange=[0,32],ylog=0,zrange=[1,500.],zlog=1,/no_interp, ystyle=1
  options,'spp_spane_p2_CNTS_A14',spec=1,yrange=[0,32],ylog=0,zrange=[1,500.],zlog=1,/no_interp, ystyle=1
  options,'spp_spane_p2_CNTS_A15',spec=1,yrange=[0,32],ylog=0,zrange=[1,500.],zlog=1,/no_interp, ystyle=1

  ;;--------------------------
  ;; TS Product 0
  options,'spp_spane_p3_CNTS',    spec=1,yrange=[0,16],ylog=0,zrange=[1,500.],zlog=1,/no_interp, ystyle=1

  ;;--------------------------
  ;; TS Product 1
  options,'spp_spane_p4_CNTS_A0', spec=1,yrange=[0,32],ylog=0,zrange=[1,500.],zlog=1,/no_interp, ystyle=1
  options,'spp_spane_p4_CNTS_A1', spec=1,yrange=[0,32],ylog=0,zrange=[1,500.],zlog=1,/no_interp, ystyle=1
  options,'spp_spane_p4_CNTS_A2', spec=1,yrange=[0,32],ylog=0,zrange=[1,500.],zlog=1,/no_interp, ystyle=1
  options,'spp_spane_p4_CNTS_A3', spec=1,yrange=[0,32],ylog=0,zrange=[1,500.],zlog=1,/no_interp, ystyle=1
  options,'spp_spane_p4_CNTS_A4', spec=1,yrange=[0,32],ylog=0,zrange=[1,500.],zlog=1,/no_interp, ystyle=1
  options,'spp_spane_p4_CNTS_A5', spec=1,yrange=[0,32],ylog=0,zrange=[1,500.],zlog=1,/no_interp, ystyle=1
  options,'spp_spane_p4_CNTS_A6', spec=1,yrange=[0,32],ylog=0,zrange=[1,500.],zlog=1,/no_interp, ystyle=1
  options,'spp_spane_p4_CNTS_A7', spec=1,yrange=[0,32],ylog=0,zrange=[1,500.],zlog=1,/no_interp, ystyle=1
  options,'spp_spane_p4_CNTS_A8', spec=1,yrange=[0,32],ylog=0,zrange=[1,500.],zlog=1,/no_interp, ystyle=1
  options,'spp_spane_p4_CNTS_A9', spec=1,yrange=[0,32],ylog=0,zrange=[1,500.],zlog=1,/no_interp, ystyle=1
  options,'spp_spane_p4_CNTS_A10',spec=1,yrange=[0,32],ylog=0,zrange=[1,500.],zlog=1,/no_interp, ystyle=1
  options,'spp_spane_p4_CNTS_A11',spec=1,yrange=[0,32],ylog=0,zrange=[1,500.],zlog=1,/no_interp, ystyle=1
  options,'spp_spane_p4_CNTS_A12',spec=1,yrange=[0,32],ylog=0,zrange=[1,500.],zlog=1,/no_interp, ystyle=1
  options,'spp_spane_p4_CNTS_A13',spec=1,yrange=[0,32],ylog=0,zrange=[1,500.],zlog=1,/no_interp, ystyle=1
  options,'spp_spane_p4_CNTS_A14',spec=1,yrange=[0,32],ylog=0,zrange=[1,500.],zlog=1,/no_interp, ystyle=1
  options,'spp_spane_p4_CNTS_A15',spec=1,yrange=[0,32],ylog=0,zrange=[1,500.],zlog=1,/no_interp, ystyle=1


end








pro spp_init
 recorder,recorder_base,title='GSEOS MAG',port=2023,host='abiad-sw',exec_proc='spp_msg_stream_read',destination='spp_raw_YYYYMMDD_hhmmss.msg';,/set_proc,/set_connect,get_filename=filename
 exec,exec_base,exec_text = 'tplot,verbose=0,trange=systime(1)+[-1,.05]*300'

if 0 then begin
  tplot,'*MON*'
  tplot,'*RIO*',/add
  options,iton(),colors='r'
  tplot,'*CNTS',/add  
endif

wait,3
tplot,'*CNTS *DCMD_REC *VMON_MCP *VMON_RAW'


if 1 then begin
  options,'spp_spane_spec_CNTS',spec=0,yrange=[.5,5000],ystyle=1,ylog=1,colors='mbcgdr'
  options,'spp_spane_spec_CNTS1',spec=0,yrange=[.5,5000],ystyle=1,ylog=1,colors='mbcgdr'
  options,'spp_spane_spec_CNTS2',spec=0,yrange=[.5,5000],ystyle=1,ylog=1,colors='mbcgdr'
endif else begin
  options,'spp_spane_spec_CNTS',spec=1,yrange=[-1,16],ylog=0,zrange=[1,500.],zlog=1,/no_interp
  options,'spp_spane_spec_CNTS1',spec=1,yrange=[-1,32],ylog=0,zrange=[1,500.],zlog=1,/no_interp
  options,'spp_spane_spec_CNTS2',spec=1,yrange=[-1,16],ylog=0,zrange=[1,500.],zlog=1,/no_interp
endelse
end


pro misc
   spp_apid_data,'36E'x,apdata=hkp
   s=hkp.dataptr
   def = (*s).acc_dac * sign((*s).adc_vmon_def1 - (*s).adc_vmon_def2)
   store_data,'def',(*s).time,def
end






pro spp_swp_spane_init,save=save
  if n_elements(save) eq 0 then save=1
  rt_flag = 1

  ;;-----------------------------------------------------------------------------------------------------------------------------
  ;; Product Decommutators
  spp_apid_data,'360'x ,routine='spp_swp_spane_p1_decom',tname='spp_spane_p1_',tfields='*',rt_tags='*', save=save,rt_flag=rt_flag
  spp_apid_data,'361'x ,routine='spp_swp_spane_p2_decom',tname='spp_spane_p2_',tfields='*',rt_tags='*', save=save,rt_flag=rt_flag
  spp_apid_data,'362'x ,routine='spp_swp_spane_p3_decom',tname='spp_spane_p3_',tfields='*',rt_tags='*', save=save,rt_flag=rt_flag
  spp_apid_data,'363'x ,routine='spp_swp_spane_p4_decom',tname='spp_spane_p4_',tfields='*',rt_tags='*', save=save,rt_flag=rt_flag
  
  ;;-----------------------------------------------------------------------------------------------------------------------------
  ;; Memory Dump
  spp_apid_data,'36d'x ,routine='spp_generic_decom',tname='spp_spane_dump_',tfields='*',rt_tags='*', save=save,rt_flag=rt_flag
  
  ;;-----------------------------------------------------------------------------------------------------------------------------
  ;; Slow Housekeeping
  spp_apid_data,'36e'x ,routine='spp_swp_spane_slow_hkp_decom',tname='spp_spane_hkp_',tfields='*',rt_tags='*', save=save,rt_flag=rt_flag

  spp_apid_data,apdata=ap
  print_struct,ap

;spp_init

end



