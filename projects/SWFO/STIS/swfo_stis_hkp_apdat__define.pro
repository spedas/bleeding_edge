; $LastChangedBy: davin-mac $
; $LastChangedDate: 2021-12-17 09:47:01 -0800 (Fri, 17 Dec 2021) $
; $LastChangedRevision: 30471 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SWFO/STIS/swfo_stis_hkp_apdat__define.pro $



function swfo_stis_hkp_apdat::decom,ccsds,source_dict=source_dict      ;,header,ptp_header=ptp_header,apdat=apdat
  ccsds_data = swfo_ccsds_data(ccsds)
  
  ;printdat,time_string(ccsds.time)
  ;printdat,ccsds
  if debug(3) && ccsds.apid eq 862 then begin
    dprint,ccsds.seqn,'   ',time_string(ccsds.time,prec=4),' ',ccsds.pkt_size
    ;hexprint,ccsds_data
  endif

  if debug(5) then begin
    dprint,dlevel=4,'SST',ccsds.pkt_size, n_elements(ccsds_data), ccsds.apid
    hexprint,ccsds_data[0:31]
    hexprint,swfo_data_select(ccsds_data,80,8)
  endif

  temp_par = swfo_therm_temp()

  temp_par.r1 = 51100d
  temp_par_16bit      = temp_par
  temp_par_16bit.xmax = 2.d^15
  ; MON_TEMP =   func((spp_swp_word_decom(b,20) and '3ff'x) *1., param = temp_par_10bit)



  flt=2.5/ 2.^15

  if 0 then begin
    adcs =  swfo_data_select(ccsds_data,(d+2*[1:8] )*8, 16 ,/signed) *flt
    if ccsds.apid and 1 then  print,adcs
  endif
  
  
  if ccsds.pkt_size eq 136 then begin
    dprint,dlevel=4,'hello'
    d= 20
    str = {time:ccsds.time,  $
      time_delta: ccsds.time_delta, $
      met: ccsds.met,   $
      seqn:    ccsds.seqn,$
      mode2:       swfo_data_select(ccsds_data,(14)*8, 16  ) , $
      status_bits:  swfo_data_select(ccsds_data,(16)*8, 16  ) , $
      noise_bits:  swfo_data_select(ccsds_data,(18)*8, 16  ) , $
      revnum0:    swfo_data_select(ccsds_data,(d+2*0)*8, 8  ) , $
      mapid:     swfo_data_select(ccsds_data,(d+2*0+1 )*8, 8  ) , $
      cmds:      swfo_data_select(ccsds_data,(d+2*1  )*8, 8  ) , $
      icmnds:    swfo_data_select(ccsds_data,(d+2*1+1)*8, 8  ) , $
      user_0e:  swfo_data_select(ccsds_data,(d+2*2)*8, 16 ) , $
      user_09:   swfo_data_select(ccsds_data,(d+2*3)*8, 16 ) , $
      mem_addr:   swfo_data_select(ccsds_data,(d+2*4)*8, 16 ) , $
      mem_chksum:   swfo_data_select(ccsds_data,(d+2*5)*8, 8) , $
      pps_cntr:   swfo_data_select(ccsds_data,(d+2*5+1)*8, 8) , $
      event_cntr:   swfo_data_select(ccsds_data,(d+2*6)*8, 16) , $
      rates_cntr:  swfo_data_select(ccsds_data,(d+[7:12]*2)*8, 16) , $
      bus_timeout_cntr: swfo_data_select(ccsds_data,(d+13*2)*8+4*[0:3], 4) , $
      det_timeout_cntr: swfo_data_select(ccsds_data,(d+14*2  )*8        , 8) , $
      noPeak_cntr:      swfo_data_select(ccsds_data,(d+14*2+1)*8 , 8) , $
      cmds_ignored:  swfo_data_select(ccsds_data,(d+15*2)*8 , 8) , $
      cmds_unknown:  swfo_data_select(ccsds_data,(d+15*2+1)*8 , 8) , $
      spare_00:     swfo_data_select(ccsds_data,(d+16*2)*8 , 2) , $
      board_id:     swfo_data_select(ccsds_data,(d+16*2)*8+2 , 2) , $
      pulses_remaining:     swfo_data_select(ccsds_data,(d+16*2)*8+4 , 12) , $
      errors_double_A:     swfo_data_select(ccsds_data,(d+17*2)*8 , 8) , $
      errors_single_A:     swfo_data_select(ccsds_data,(d+17*2)*8+1 , 8) , $
      errors_double_b:     swfo_data_select(ccsds_data,(d+18*2)*8 , 8) , $
      errors_single_b:     swfo_data_select(ccsds_data,(d+18*2)*8+1 , 8) , $
      errors_double_noise:     swfo_data_select(ccsds_data,(d+19*2)*8 , 8) , $
      errors_single_noise:     swfo_data_select(ccsds_data,(d+19*2)*8+1 , 8) , $
      dac_vals:  swfo_data_select(ccsds_data,(d+(20+[0:11])*2)*8 , 16) , $
      time_cmds:  swfo_data_select(ccsds_data,(d+32*2)*8 , 8) , $
      last_cmd:  swfo_data_select(ccsds_data,(d+32*2+1)*8 , 8) , $
      last_cdata:  swfo_data_select(ccsds_data,(d+33*2)*8 , 16) , $
      adc_bias_v:     swfo_data_select(ccsds_data,(d+2*34 )*8, 16 ,/signed) *flt , $
      adc_bias_c:    swfo_data_select(ccsds_data,(d+2*35 )*8, 16 ,/signed ) *flt , $
      adc_TEMP_DAP:   swfo_therm_temp( swfo_data_select(ccsds_data,(d+2*36 )*8, 16 ,/signed ), param=temp_par_16bit ) , $
      adc_p5d:    swfo_data_select(ccsds_data,(d+2*37 )*8, 16 ,/signed ) *flt , $
      adc_p5a:    swfo_data_select(ccsds_data,(d+2*38 )*8, 16 ,/signed ) *flt , $
      adc_n5a:    swfo_data_select(ccsds_data,(d+2*39 )*8, 16  ,/signed) *flt , $
      adc_temp_s1:   swfo_therm_temp(   swfo_data_select(ccsds_data,(d+2*40 )*8, 16  ,/signed) , param=temp_par_16bit) , $
      adc_temp_s2:    swfo_therm_temp(  swfo_data_select(ccsds_data,(d+2*41 )*8, 16  ,/signed) , param=temp_par_16bit) , $
      adc_all:    swfo_data_select(ccsds_data,(d+2*[34:41] )*8, 16  ,/signed) *flt , $
      gap:0b }
    str.gap = ccsds.gap

  endif  else  if  ccsds.time  gt 1.6297680e+09 then begin
    d= 20
    str = {time:ccsds.time,  $
      time_delta: ccsds.time_delta, $
      met: ccsds.met,   $
      seqn:    ccsds.seqn,$
      mode2:       swfo_data_select(ccsds_data,(14)*8, 16  ) , $
      status_bits:  swfo_data_select(ccsds_data,(16)*8, 16  ) , $
      noise_bits:  swfo_data_select(ccsds_data,(18)*8, 16  ) , $
      revnum:    swfo_data_select(ccsds_data,(d+2*0)*8, 8  ) , $
      mapid:     swfo_data_select(ccsds_data,(d+2*0+1 )*8, 8  ) , $
      cmds:      swfo_data_select(ccsds_data,(d+2*1  )*8, 8  ) , $
      icmnds:    swfo_data_select(ccsds_data,(d+2*1+1)*8, 8  ) , $
      user_0e:  swfo_data_select(ccsds_data,(d+2*2)*8, 16 ) , $
      user_09:   swfo_data_select(ccsds_data,(d+2*3)*8, 16 ) , $
      mem_addr:   swfo_data_select(ccsds_data,(d+2*4)*8, 16 ) , $
      mem_chksum:   swfo_data_select(ccsds_data,(d+2*5)*8, 8) , $
      pps_cntr:   swfo_data_select(ccsds_data,(d+2*5+1)*8, 8) , $
      event_cntr:   swfo_data_select(ccsds_data,(d+2*6)*8, 16) , $
      rates_cntr:  swfo_data_select(ccsds_data,(d+[7:12]*2)*8, 16) , $
      bus_timeout_cntr: swfo_data_select(ccsds_data,(d+13*2)*8+4*[0:3], 4) , $
      det_timeout_cntr: swfo_data_select(ccsds_data,(d+14*2  )*8        , 8) , $
      noPeak_cntr:      swfo_data_select(ccsds_data,(d+14*2+1)*8 , 8) , $
      cmds_ignored:  swfo_data_select(ccsds_data,(d+15*2)*8 , 8) , $
      cmds_unknown:  swfo_data_select(ccsds_data,(d+15*2+1)*8 , 8) , $
      spare_00:     swfo_data_select(ccsds_data,(d+16*2)*8 , 2) , $
      board_id:     swfo_data_select(ccsds_data,(d+16*2)*8+2 , 2) , $
      pulses_remaining:     swfo_data_select(ccsds_data,(d+16*2)*8+4 , 12) , $
      errors_double_A:     swfo_data_select(ccsds_data,(d+17*2)*8 , 8) , $
      errors_single_A:     swfo_data_select(ccsds_data,(d+17*2)*8+1 , 8) , $
      errors_double_b:     swfo_data_select(ccsds_data,(d+18*2)*8 , 8) , $
      errors_single_b:     swfo_data_select(ccsds_data,(d+18*2)*8+1 , 8) , $
      errors_double_noise:     swfo_data_select(ccsds_data,(d+19*2)*8 , 8) , $
      errors_single_noise:     swfo_data_select(ccsds_data,(d+19*2)*8+1 , 8) , $      
      dac_vals:  swfo_data_select(ccsds_data,(d+(20+[0:11])*2)*8 , 16) , $   
      time_cmds:  swfo_data_select(ccsds_data,(d+32*2)*8 , 8) , $
      last_cmd:  swfo_data_select(ccsds_data,(d+32*2+1)*8 , 8) , $
      last_cdata:  swfo_data_select(ccsds_data,(d+33*2)*8 , 16) , $
      adc_bias_v:     swfo_data_select(ccsds_data,(d+2*34 )*8, 16 ,/signed) *flt , $
      adc_bias_c:    swfo_data_select(ccsds_data,(d+2*35 )*8, 16 ,/signed ) *flt , $
      adc_TEMP_DAP:   swfo_therm_temp( swfo_data_select(ccsds_data,(d+2*36 )*8, 16 ,/signed ), param=temp_par_16bit ) , $
      adc_p5d:    swfo_data_select(ccsds_data,(d+2*37 )*8, 16 ,/signed ) *flt , $
      adc_p5a:    swfo_data_select(ccsds_data,(d+2*38 )*8, 16 ,/signed ) *flt , $
      adc_n5a:    swfo_data_select(ccsds_data,(d+2*39 )*8, 16  ,/signed) *flt , $
      adc_temp_s1:   swfo_therm_temp(   swfo_data_select(ccsds_data,(d+2*40 )*8, 16  ,/signed) , param=temp_par_16bit) , $
      adc_temp_s2:    swfo_therm_temp(  swfo_data_select(ccsds_data,(d+2*41 )*8, 16  ,/signed) , param=temp_par_16bit) , $
      adc_all:    swfo_data_select(ccsds_data,(d+2*[34:41] )*8, 16  ,/signed) *flt , $
      gap:0b }
    str.gap = ccsds.gap

  endif else if  ccsds.time lt (1.6297680e+09 -1800.) then  begin
    d= 18
    str = {time:ccsds.time,  $
      time_delta: ccsds.time_delta, $
      met: ccsds.met,   $
      seqn:    ccsds.seqn,$
      ;      adcs:  adcs , $
      adc_bias_v:     swfo_data_select(ccsds_data,(d+2*1 )*8, 16 ,/signed) *flt , $
      adc_bias_c:    swfo_data_select(ccsds_data,(d+2*2 )*8, 16 ,/signed ) *flt , $
      adc_TEMP_DAP:    swfo_data_select(ccsds_data,(d+2*3 )*8, 16 ,/signed ) *flt , $
      adc_p5d:    swfo_data_select(ccsds_data,(d+2*4 )*8, 16 ,/signed ) *flt , $
      adc_p5a:    swfo_data_select(ccsds_data,(d+2*5 )*8, 16 ,/signed ) *flt , $
      adc_n5a:    swfo_data_select(ccsds_data,(d+2*6 )*8, 16  ,/signed) *flt , $
      adc_temp_s1:    swfo_data_select(ccsds_data,(d+2*7 )*8, 16  ,/signed) *flt , $
      adc_temp_s2:    swfo_data_select(ccsds_data,(d+2*8 )*8, 16  ,/signed) *flt , $
      mapid:     swfo_data_select(ccsds_data,(d+2*9   )*8, 8  ) , $
      revnum:    swfo_data_select(ccsds_data,(d+2*9+1)*8, 8  ) , $
      cmds:      swfo_data_select(ccsds_data,(d+2*10  )*8, 8  ) , $
      icmnds:    swfo_data_select(ccsds_data,(d+2*10+1)*8, 8  ) , $
      status_bits:  swfo_data_select(ccsds_data,(d+2*11)*8, 16 ) , $
      noise_bits:  swfo_data_select(ccsds_data,(d+2*12)*8, 16 ) , $
      mem_addr:   swfo_data_select(ccsds_data,(d+2*13)*8, 16 ) , $
      mem_chksum:   swfo_data_select(ccsds_data,(d+2*14)*8, 8) , $
      pps_cntr:   swfo_data_select(ccsds_data,(d+2*14+1)*8, 8) , $
      event_cntr:   swfo_data_select(ccsds_data,(d+2*15)*8, 16) , $
      rates_cntr:  swfo_data_select(ccsds_data,(d+[16:21]*2)*8, 16) , $
      bus_timeout_cntr: swfo_data_select(ccsds_data,(d+22*2)*8+4*[0:3], 4) , $
      det_timeout_cntr: swfo_data_select(ccsds_data,(d+23*2  )*8        , 8) , $
      noPeak_cntr:      swfo_data_select(ccsds_data,(d+23*2+1)*8 , 8) , $
      reserved:  swfo_data_select(ccsds_data,(d+24*2)*8 , 16) , $
      last_cmd:  swfo_data_select(ccsds_data,(d+41*2+1)*8 , 8) , $
      last_cdata:  swfo_data_select(ccsds_data,(d+42*2)*8 , 16) , $
      dac_vals:  swfo_data_select(ccsds_data,(d+29*2+[0:11]*2)*8 , 16) , $    ; change from documentation
      gap:0b }
    str.gap = ccsds.gap

  endif else begin
    str = !null
  endelse

  if 0 then begin
    printdat,str,/hex
    printdat,time_string(str.time,/local)
  endif

  return,str

end






PRO swfo_stis_hkp_apdat__define

  void = {swfo_stis_hkp_apdat, $
    inherits swfo_gen_apdat, $    ; superclass
    flag: 0 $
  }
END


