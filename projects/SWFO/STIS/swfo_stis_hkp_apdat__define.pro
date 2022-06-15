; $LastChangedBy: ali $
; $LastChangedDate: 2022-06-14 15:34:18 -0700 (Tue, 14 Jun 2022) $
; $LastChangedRevision: 30855 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SWFO/STIS/swfo_stis_hkp_apdat__define.pro $



function swfo_stis_hkp_apdat::decom,ccsds,source_dict=source_dict      ;,header,ptp_header=ptp_header,apdat=apdat
  ccsds_data = swfo_ccsds_data(ccsds)
  str1=swfo_stis_ccsds_header_decom(ccsds)

  if 0 then begin
    last_time = systime(1)
    last_time = (*(self.last_ccsds_p)).time
    last_met  = (*(self.last_ccsds_p)).met
    ;printdat,self.last_ccsds_p
    if 0 && (ccsds.MET eq last_met) then begin
      dprint,'MET not incrementing: '+time_string(last_time),dwait=10
      ccsds.time = last_time + 0.99
      ;ccsds.time = systime(1)
      ;hexprint,ccsds_data
    endif
  endif


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


  flt=2.5/(2.^15)
  r=[1e9,15.4,6.65,6.65,-6.65]
  coeff=(10+abs(r))/r

  if 0 then begin
    adcs =  swfo_data_select(ccsds_data,(d+2*[1:8] )*8, 16 ,/signed) *flt
    if ccsds.apid and 1 then  print,adcs
  endif


  if ccsds.pkt_size eq 136 then begin
    dprint,dlevel=4,'hello'
    d= 24
    fifo_size=8190
    if str1.fpga_rev ge 0x99 then begin
      cmd_fifo_write_ptr=       swfo_data_select(ccsds_data,(d+0*2)*8+3, 13 )
      cmd_fifo_read_ptr=        swfo_data_select(ccsds_data,(d+1*2)*8+3, 13 )
      cmds_remaining=(fix(cmd_fifo_write_ptr)-fix(cmd_fifo_read_ptr))/3.
      if cmds_remaining lt 0 then cmds_remaining+=8190/3.
      str2={$
        cmd_fifo_write_ptr:     cmd_fifo_write_ptr , $
        cmd_fifo_read_ptr:      cmd_fifo_read_ptr , $
        cmds_received:          cmd_fifo_write_ptr/3. , $
        cmds_executed:          cmd_fifo_read_ptr/3. , $
        cmds_remaining:         cmds_remaining , $
        user_0e:                swfo_data_select(ccsds_data,(d+ 2*2  )*8,16),$
        cmds_invalid:           swfo_data_select(ccsds_data,(d+ 3*2  )*8, 8),$
        bias_clock_period:      swfo_data_select(ccsds_data,(d+ 3*2+1)*8, 8),$
        memory_address:         swfo_data_select(ccsds_data,(d+ 4*2  )*8,16),$
        pps_counter:            swfo_data_select(ccsds_data,(d+ 5*2  )*8,16),$
        event_counter:          swfo_data_select(ccsds_data,(d+ 6*2  )*8,16),$
        rates_counter:          swfo_data_select(ccsds_data,(d+[7:12]*2)*8,16),$
        bus_timeout_counter:    swfo_data_select(ccsds_data,(d+13*2  )*8+4*[0:3],4),$
        det_timeout_counter:    swfo_data_select(ccsds_data,(d+14*2  )*8, 8),$
        nopeak_counter:         swfo_data_select(ccsds_data,(d+14*2+1)*8, 8),$
        cmds_ignored:           swfo_data_select(ccsds_data,(d+15*2  )*8, 8),$
        cmds_unknown:           swfo_data_select(ccsds_data,(d+15*2+1)*8, 8),$
        memory_page:            swfo_data_select(ccsds_data,(d+16*2)*8+1, 1),$
        board_id:               swfo_data_select(ccsds_data,(d+16*2)*8+2, 2),$
        pulses_remaining:       swfo_data_select(ccsds_data,(d+16*2)*8+4,12),$
        errors_double_a:        swfo_data_select(ccsds_data,(d+17*2  )*8, 8),$
        errors_single_a:        swfo_data_select(ccsds_data,(d+17*2+1)*8, 8),$
        errors_double_b:        swfo_data_select(ccsds_data,(d+18*2  )*8, 8),$
        errors_single_b:        swfo_data_select(ccsds_data,(d+18*2+1)*8, 8),$
        errors_double_noise:    swfo_data_select(ccsds_data,(d+19*2  )*8, 8),$
        errors_single_noise:    swfo_data_select(ccsds_data,(d+19*2+1)*8, 8),$
        errors_all:             swfo_data_select(ccsds_data,(d+17*2+[0:5])*8, 8),$    ;all error counters
        dac_values:             swfo_data_select(ccsds_data,(d+(20+[0:11])*2)*8,16),$ ;all 12 dac channels
        time_cmds_received:     swfo_data_select(ccsds_data,(d+32*2  )*8, 8),$
        first_cmd_id:           swfo_data_select(ccsds_data,(d+32*2+1)*8, 8),$
        first_cmd_data:         swfo_data_select(ccsds_data,(d+33*2  )*8,16),$
        checksum1:              swfo_data_select(ccsds_data,(d+34*2  )*8,16),$
        checksum0:              swfo_data_select(ccsds_data,(d+35*2  )*8,16),$
        cmd_pause_remaining:    swfo_data_select(ccsds_data,(d+36*2  )*8,16),$
        errors_total:           swfo_data_select(ccsds_data,(d+37*2  )*8, 8),$
        met_spare:              swfo_data_select(ccsds_data,(d+37*2+1)*8, 8),$
        user_2d:                swfo_data_select(ccsds_data,(d+38*2  )*8, 8),$
        last_cmd_id:            swfo_data_select(ccsds_data,(d+38*2+1)*8, 8),$
        last_cmd_data:          swfo_data_select(ccsds_data,(d+39*2  )*8,16),$
        adc_bias_voltage:       swfo_data_select(ccsds_data,(d+40*2  )*8,16,/signed)*flt,$
        ;adc_temp_dap:           swfo_therm_temp(swfo_data_select(ccsds_data,(d+41*2 )*8,16,/signed),param=temp_par_16bit),$
        adc_temps:              swfo_therm_temp(swfo_data_select(ccsds_data,(d+[41,48,49]*2 )*8,16,/signed),param=temp_par_16bit),$
        ;adc_1p5vd:              swfo_data_select(ccsds_data,(d+42*2  )*8,16,/signed)*flt,$
        ;adc_3p3vd:              swfo_data_select(ccsds_data,(d+43*2  )*8,16,/signed)*flt,$
        ;adc_5vd:                swfo_data_select(ccsds_data,(d+44*2  )*8,16,/signed)*flt,$
        ;adc_p5va:               swfo_data_select(ccsds_data,(d+45*2  )*8,16,/signed)*flt,$
        ;adc_n5va:               swfo_data_select(ccsds_data,(d+46*2  )*8,16,/signed)*flt,$
        adc_voltages:           swfo_data_select(ccsds_data,(d+[42:46]*2  )*8,16,/signed)*flt*coeff,$
        adc_bias_current:       swfo_data_select(ccsds_data,(d+47*2  )*8,16,/signed)*flt,$
        ;adc_temp_s1:            swfo_data_select(ccsds_data,(d+48*2  )*8,16,/signed)*flt,$
        ;adc_temp_s1:            swfo_therm_temp(swfo_data_select(ccsds_data,(d+48*2 )*8,16,/signed),param=temp_par_16bit),$
        ;adc_temp_s2:            swfo_therm_temp(swfo_data_select(ccsds_data,(d+49*2 )*8,16,/signed),param=temp_par_16bit),$
        adc_baselines:          swfo_data_select(ccsds_data,(d+[50:55]*2)*8,16,/signed)*flt,$
        ;adc_all:                swfo_data_select(ccsds_data,(d+[40:55]*2)*8,16,/signed)*flt,$
        gap:ccsds.gap }
      str=create_struct(str1,str2)
    endif else begin
      if str1.fpga_rev ge 0x97 then begin
        biasclk_period765=        swfo_data_select(ccsds_data,(d+ 0*2 )*8, 3  )
        biasclk_period432=        swfo_data_select(ccsds_data,(d+ 1*2 )*8, 3  )
        biasclk_period10 =        swfo_data_select(ccsds_data,(d+16*2 )*8, 2  )
        cmd_fifo_write_ptr=       swfo_data_select(ccsds_data,(d+0*2)*8+3, 13 )
        cmd_fifo_read_ptr=        swfo_data_select(ccsds_data,(d+1*2)*8+3, 13 )
        cmds_remaining=(fix(cmd_fifo_write_ptr)-fix(cmd_fifo_read_ptr))/3.
        if cmds_remaining lt 0 then cmds_remaining+=8190/3.
        str2={$
          bias_clock_period:      biasclk_period10+ishft(biasclk_period432,2)+ishft(biasclk_period765,5) , $
          cmd_fifo_write_ptr:     cmd_fifo_write_ptr , $
          cmd_fifo_read_ptr:      cmd_fifo_read_ptr , $
          cmds_received:          cmd_fifo_write_ptr/3. , $
          cmds_executed:          cmd_fifo_read_ptr/3. , $
          cmds_remaining:         cmds_remaining , $
          user_0e:                swfo_data_select(ccsds_data,(d+2*2)*8, 16 ) , $
          cmds_invalid:           swfo_data_select(ccsds_data,(d+3*2)*8, 8  ) , $
          cmd_pause_remaining:    swfo_data_select(ccsds_data,(d+3*2+1)*8, 8  ) , $
          mem_addr:               swfo_data_select(ccsds_data,(d+4*2)*8, 16 ) , $
          sect_cnt:               swfo_data_select(ccsds_data,(d+5*2)*8, 16) , $
          event_cntr:             swfo_data_select(ccsds_data,(d+6*2)*8, 16) , $
          rates_cntr:             swfo_data_select(ccsds_data,(d+[7:12]*2)*8, 16) , $
          bus_timeout_cntr:       swfo_data_select(ccsds_data,(d+13*2)*8+4*[0:3], 4) , $
          det_timeout_cntr:       swfo_data_select(ccsds_data,(d+14*2  )*8        , 8) , $
          noPeak_cntr:            swfo_data_select(ccsds_data,(d+14*2+1)*8 , 8) , $
          cmds_ignored:           swfo_data_select(ccsds_data,(d+15*2)*8 , 8) , $
          cmds_unknown:           swfo_data_select(ccsds_data,(d+15*2+1)*8 , 8) , $
          board_id:               swfo_data_select(ccsds_data,(d+16*2)*8+2 , 2) , $
          pulses_remaining:       swfo_data_select(ccsds_data,(d+16*2)*8+4 , 12) , $
          errors_double_A:        swfo_data_select(ccsds_data,(d+17*2)*8 , 8) , $
          errors_single_A:        swfo_data_select(ccsds_data,(d+17*2+1)*8 , 8) , $
          errors_double_b:        swfo_data_select(ccsds_data,(d+18*2)*8 , 8) , $
          errors_single_b:        swfo_data_select(ccsds_data,(d+18*2+1)*8 , 8) , $
          errors_double_noise:    swfo_data_select(ccsds_data,(d+19*2)*8 , 8) , $
          errors_single_noise:    swfo_data_select(ccsds_data,(d+19*2+1)*8 , 8) , $
          errors_all:             swfo_data_select(ccsds_data,(d+17*2+[0:5])*8, 8),  $    ; all error counters
          dac_vals:               swfo_data_select(ccsds_data,(d+(20+[0:11])*2)*8 , 16) , $   ;all 12 dac channels
          time_cmds:              swfo_data_select(ccsds_data,(d+32*2)*8 , 8) , $
          first_cmd_id:           swfo_data_select(ccsds_data,(d+32*2+1)*8 , 8) , $
          first_cmd_data:         swfo_data_select(ccsds_data,(d+33*2)*8 , 16) , $
          chksum_dat1:            swfo_data_select(ccsds_data,(d+34*2)*8 , 16) , $
          chksum_dat0:            swfo_data_select(ccsds_data,(d+35*2)*8 , 16) , $
          chksum_err1:            swfo_data_select(ccsds_data,(d+36*2)*8 , 8) , $
          chksum_err0:            swfo_data_select(ccsds_data,(d+36*2+1)*8 , 8) , $
          sm_err_cnt:             swfo_data_select(ccsds_data,(d+37*2)*8 , 8) , $
          met_spare:              swfo_data_select(ccsds_data,(d+37*2+1)*8 , 8) , $
          user_2d:                swfo_data_select(ccsds_data,(d+38*2)*8 , 8) , $
          last_cmd_id:            swfo_data_select(ccsds_data,(d+38*2+1)*8 , 8) , $
          last_cmd_data:          swfo_data_select(ccsds_data,(d+39*2)*8 , 16) , $
          adc_bias_v:             swfo_data_select(ccsds_data,(d+2*40 )*8, 16 ,/signed) *flt , $
          adc_bias_c:             swfo_data_select(ccsds_data,(d+2*47 )*8, 16 ,/signed ) *flt , $
          adc_TEMP_DAP:           swfo_therm_temp(swfo_data_select(ccsds_data,(d+2*42 )*8, 16 ,/signed ), param=temp_par_16bit ) , $
          adc_p5d:                swfo_data_select(ccsds_data,(d+2*43 )*8, 16 ,/signed ) *flt , $
          adc_p5a:                swfo_data_select(ccsds_data,(d+2*44 )*8, 16 ,/signed ) *flt , $
          adc_n5a:                swfo_data_select(ccsds_data,(d+2*45 )*8, 16  ,/signed) *flt , $
          adc_temp_s1:            swfo_therm_temp(swfo_data_select(ccsds_data,(d+2*46 )*8, 16  ,/signed) , param=temp_par_16bit) , $
          adc_temp_s2:            swfo_therm_temp(swfo_data_select(ccsds_data,(d+2*47 )*8, 16  ,/signed) , param=temp_par_16bit) , $
          adc_all:                swfo_data_select(ccsds_data,(d+2*[40:55] )*8, 16  ,/signed) *flt , $
          gap:ccsds.gap }
        str=create_struct(str1,str2)
      endif else begin
        if str1.fpga_rev ge 0x93 then begin
          str2={$
            fpga_rev0:              swfo_data_select(ccsds_data,(d+2*0  )*8, 8  ) , $
            user_2d:                  swfo_data_select(ccsds_data,(d+2*0+1)*8, 8  ) , $
            cmds_received:          swfo_data_select(ccsds_data,(d+2*1  )*8, 16  ) , $
            user_0e:                swfo_data_select(ccsds_data,(d+2*2)*8, 16 ) , $
            cmds_invalid:           swfo_data_select(ccsds_data,(d+2*3)*8, 8  ) , $
            cmd_pause_tcnt:         swfo_data_select(ccsds_data,(d+2*3+1)*8, 8  ) , $
            mem_addr:               swfo_data_select(ccsds_data,(d+2*4)*8, 16 ) , $
            sect_cnt:               swfo_data_select(ccsds_data,(d+2*5)*8, 16) , $
            event_cntr:             swfo_data_select(ccsds_data,(d+2*6)*8, 16) , $
            rates_cntr:             swfo_data_select(ccsds_data,(d+[7:12]*2)*8, 16) , $
            bus_timeout_cntr:       swfo_data_select(ccsds_data,(d+13*2)*8+4*[0:3], 4) , $
            det_timeout_cntr:       swfo_data_select(ccsds_data,(d+14*2  )*8        , 8) , $
            noPeak_cntr:            swfo_data_select(ccsds_data,(d+14*2+1)*8 , 8) , $
            cmds_ignored:           swfo_data_select(ccsds_data,(d+15*2)*8 , 8) , $
            cmds_unknown:           swfo_data_select(ccsds_data,(d+15*2+1)*8 , 8) , $
            spare_00:               swfo_data_select(ccsds_data,(d+16*2)*8 , 2) , $
            board_id:               swfo_data_select(ccsds_data,(d+16*2)*8+2 , 2) , $
            pulses_remaining:       swfo_data_select(ccsds_data,(d+16*2)*8+4 , 12) , $
            errors_double_A:        swfo_data_select(ccsds_data,(d+17*2)*8 , 8) , $
            errors_single_A:        swfo_data_select(ccsds_data,(d+17*2+1)*8 , 8) , $
            errors_double_b:        swfo_data_select(ccsds_data,(d+18*2)*8 , 8) , $
            errors_single_b:        swfo_data_select(ccsds_data,(d+18*2+1)*8 , 8) , $
            errors_double_noise:    swfo_data_select(ccsds_data,(d+19*2)*8 , 8) , $
            errors_single_noise:    swfo_data_select(ccsds_data,(d+19*2+1)*8 , 8) , $
            errors_all:             swfo_data_select(ccsds_data,(d+17*2+[0:5])*8, 8),  $    ; all error counters
            dac_vals:               swfo_data_select(ccsds_data,(d+(20+[0:11])*2)*8 , 16) , $   ;all 12 dac channels
            time_cmds:              swfo_data_select(ccsds_data,(d+32*2)*8 , 8) , $
            first_cmd:              swfo_data_select(ccsds_data,(d+32*2+1)*8 , 8) , $
            first_cdata:            swfo_data_select(ccsds_data,(d+33*2)*8 , 16) , $
            csum_dat1:              swfo_data_select(ccsds_data,(d+34*2)*8 , 16) , $
            csum_dat0:              swfo_data_select(ccsds_data,(d+35*2)*8 , 16) , $
            csum_err1:              swfo_data_select(ccsds_data,(d+36*2)*8 , 8) , $
            csum_err2:              swfo_data_select(ccsds_data,(d+36*2+1)*8 , 8) , $
            sm_err_cnt:             swfo_data_select(ccsds_data,(d+37*2)*8 , 8) , $
            met_spare:              swfo_data_select(ccsds_data,(d+37*2+1)*8 , 8) , $
            spare_0x00:             swfo_data_select(ccsds_data,(d+38*2)*8 , 8) , $
            last_cmd:               swfo_data_select(ccsds_data,(d+38*2+1)*8 , 8) , $
            last_cdata:             swfo_data_select(ccsds_data,(d+39*2)*8 , 16) , $
            adc_bias_v:             swfo_data_select(ccsds_data,(d+2*40 )*8, 16 ,/signed) *flt , $
            adc_bias_c:             swfo_data_select(ccsds_data,(d+2*41 )*8, 16 ,/signed ) *flt , $
            adc_TEMP_DAP:           swfo_therm_temp(swfo_data_select(ccsds_data,(d+2*42 )*8, 16 ,/signed ), param=temp_par_16bit ) , $
            adc_p5d:                swfo_data_select(ccsds_data,(d+2*43 )*8, 16 ,/signed ) *flt , $
            adc_p5a:                swfo_data_select(ccsds_data,(d+2*44 )*8, 16 ,/signed ) *flt , $
            adc_n5a:                swfo_data_select(ccsds_data,(d+2*45 )*8, 16  ,/signed) *flt , $
            adc_temp_s1:            swfo_therm_temp(swfo_data_select(ccsds_data,(d+2*46 )*8, 16  ,/signed) , param=temp_par_16bit) , $
            adc_temp_s2:            swfo_therm_temp(swfo_data_select(ccsds_data,(d+2*47 )*8, 16  ,/signed) , param=temp_par_16bit) , $
            adc_all:                swfo_data_select(ccsds_data,(d+2*[40:55] )*8, 16  ,/signed) *flt , $
            gap:ccsds.gap }
          str=create_struct(str1,str2)
        endif else begin
          str = {time:ccsds.time,  $
            time_delta: ccsds.time_delta, $
            apid: ccsds.apid,  $
            met: ccsds.met,   $
            seqn:    ccsds.seqn,$
            day:       swfo_data_select(ccsds_data,(6)*8, 24  ) , $
            millisec:  swfo_data_select(ccsds_data,(9)*8, 32  ) , $
            microsec:  swfo_data_select(ccsds_data,(13)*8, 16  ) , $
            revnum:    swfo_data_select(ccsds_data,(15)*8, 8  ) , $    ;  using spare
            lcss:      swfo_data_select(ccsds_data,(16)*8, 4  ) , $
            tres:         swfo_data_select(ccsds_data,(16)*8+4, 12  ) , $
            mode_id2:     swfo_data_select(ccsds_data,(18)*8, 16  ) , $
            pulser_bits:  swfo_data_select(ccsds_data,(20)*8, 8  ) , $
            status_bits:  swfo_data_select(ccsds_data,(21)*8, 8  ) , $
            noise_bits:  swfo_data_select(ccsds_data,(22)*8, 16  ) , $
            revnum0:     swfo_data_select(ccsds_data,(d+2*0  )*8, 8  ) , $
            user_2d:       swfo_data_select(ccsds_data,(d+2*0+1)*8, 8  ) , $
            cmds_valid:        swfo_data_select(ccsds_data,(d+2*1  )*8, 8  ) , $
            cmds_invalid:      swfo_data_select(ccsds_data,(d+2*1+1)*8, 8  ) , $
            user_0e:     swfo_data_select(ccsds_data,(d+2*2)*8, 16 ) , $
            user_09:     swfo_data_select(ccsds_data,(d+2*3)*8, 16 ) , $
            mem_addr:    swfo_data_select(ccsds_data,(d+2*4)*8, 16 ) , $
            sect_cnt:    swfo_data_select(ccsds_data,(d+2*5)*8, 16) , $
            event_cntr:  swfo_data_select(ccsds_data,(d+2*6)*8, 16) , $
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
            errors_single_A:     swfo_data_select(ccsds_data,(d+17*2+1)*8 , 8) , $
            errors_double_b:     swfo_data_select(ccsds_data,(d+18*2)*8 , 8) , $
            errors_single_b:     swfo_data_select(ccsds_data,(d+18*2+1)*8 , 8) , $
            errors_double_noise:     swfo_data_select(ccsds_data,(d+19*2)*8 , 8) , $
            errors_single_noise:     swfo_data_select(ccsds_data,(d+19*2+1)*8 , 8) , $
            errors_all    :     swfo_data_select(ccsds_data,(d+17*2+[0:5])*8, 8),  $    ; all error counters
            dac_vals:  swfo_data_select(ccsds_data,(d+(20+[0:11])*2)*8 , 16) , $                ; all 12 dac channels
            time_cmds:  swfo_data_select(ccsds_data,(d+32*2)*8 , 8) , $
            last_cmd:  swfo_data_select(ccsds_data,(d+32*2+1)*8 , 8) , $
            last_cdata:  swfo_data_select(ccsds_data,(d+33*2)*8 , 16) , $
            csum_dat1:  swfo_data_select(ccsds_data,(d+34*2)*8 , 16) , $
            csum_dat0:  swfo_data_select(ccsds_data,(d+35*2)*8 , 16) , $
            csum_err1:  swfo_data_select(ccsds_data,(d+36*2)*8 , 8) , $
            csum_err2:  swfo_data_select(ccsds_data,(d+36*2+1)*8 , 8) , $
            sm_err_cnt:  swfo_data_select(ccsds_data,(d+37*2)*8 , 8) , $
            met_spare:  swfo_data_select(ccsds_data,(d+37*2+1)*8 , 8) , $
            spare1:  swfo_data_select(ccsds_data,(d+38*2)*8 , 16) , $
            spare2:  swfo_data_select(ccsds_data,(d+39*2)*8 , 16) , $
            adc_bias_v:     swfo_data_select(ccsds_data,(d+2*40 )*8, 16 ,/signed) *flt , $
            adc_bias_c:    swfo_data_select(ccsds_data,(d+2*41 )*8, 16 ,/signed ) *flt , $
            adc_TEMP_DAP:   swfo_therm_temp( swfo_data_select(ccsds_data,(d+2*42 )*8, 16 ,/signed ), param=temp_par_16bit ) , $
            adc_p5d:    swfo_data_select(ccsds_data,(d+2*43 )*8, 16 ,/signed ) *flt , $
            adc_p5a:    swfo_data_select(ccsds_data,(d+2*44 )*8, 16 ,/signed ) *flt , $
            adc_n5a:    swfo_data_select(ccsds_data,(d+2*45 )*8, 16  ,/signed) *flt , $
            adc_temp_s1:   swfo_therm_temp(   swfo_data_select(ccsds_data,(d+2*46 )*8, 16  ,/signed) , param=temp_par_16bit) , $
            adc_temp_s2:    swfo_therm_temp(  swfo_data_select(ccsds_data,(d+2*47 )*8, 16  ,/signed) , param=temp_par_16bit) , $
            adc_all:    swfo_data_select(ccsds_data,(d+2*[40:55] )*8, 16  ,/signed) *flt , $
            gap:0b }
          str.gap = ccsds.gap

        endelse
      endelse
    endelse
    ;   if str.apid eq 863 then printdat,str

  endif  else  if  ccsds.time  gt 1.6297680e+09 then begin
    dprint,dlevel=2,'Obsolete'
    d= 20
    str = {time:ccsds.time,  $
      time_delta: ccsds.time_delta, $
      met: ccsds.met,   $
      seqn:    ccsds.seqn,$
      mode2:       swfo_data_select(ccsds_data,(14)*8, 16  ) , $
      status_bits:  swfo_data_select(ccsds_data,(16)*8, 16  ) , $
      noise_bits:  swfo_data_select(ccsds_data,(18)*8, 16  ) , $
      revnum:    swfo_data_select(ccsds_data,(d+2*0)*8, 8  ) , $
      user_2d:     swfo_data_select(ccsds_data,(d+2*0+1 )*8, 8  ) , $
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
    dprint,dlevel=2,'Obsolete'
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
      user_2d:     swfo_data_select(ccsds_data,(d+2*9   )*8, 8  ) , $
      revnum:    swfo_data_select(ccsds_data,(d+2*9+1)*8, 8  ) , $
      cmds_valid:      swfo_data_select(ccsds_data,(d+2*10  )*8, 8  ) , $
      cmds_invalid:    swfo_data_select(ccsds_data,(d+2*10+1)*8, 8  ) , $
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

  if 2 then begin
    printdat,str,/hex
    dprint,time_string(str.time,/local)
  endif

  return,str

end



PRO swfo_stis_hkp_apdat__define

  void = {swfo_stis_hkp_apdat, $
    inherits swfo_gen_apdat, $    ; superclass
    flag: 0 $
  }
END


