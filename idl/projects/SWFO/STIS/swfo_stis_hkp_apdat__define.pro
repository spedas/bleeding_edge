; $LastChangedBy: rjolitz $
; $LastChangedDate: 2025-03-23 18:07:39 -0700 (Sun, 23 Mar 2025) $
; $LastChangedRevision: 33198 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SWFO/STIS/swfo_stis_hkp_apdat__define.pro $


function swfo_stis_hkp_apdat::decom,ccsds,source_dict=source_dict      ;,header,ptp_header=ptp_header,apdat=apdat

  if n_params() eq 0 then begin   ; Not working yet.  eventually should provide a dummy fill structure
    message,'Not working yet'
    dummy = bytarr(500)
    dat = self.decom(dummy)
    fill = fill_nan(dat)
    return,fill
  endif

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

  if ccsds.time lt time_double('2021-1-1') then begin
    dprint,'Invalid CCSDS time.  should be Ignoring Packet', dwait = 20.
    ;return,!null
  endif


  ;printdat,time_string(ccsds.time)
  ;printdat,ccsds
  if debug(3) && ccsds.apid eq 862 then begin
    dprint,ccsds.seqn,'   ',time_string(ccsds.time,prec=4),' ',ccsds.pkt_size
    hexprint,ccsds_data
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
  r=[1e9,15.4,6.65,6.65,6.65]
  coeff=(10+r)/r
  voltages=[1.5,3.3,5,5.6,-5.6]
  d=24 ;header bytes (6 CCSDS header + 18 STIS header)
  hkp_size=ccsds.pkt_size-d
  ;if str1.fpga_rev gt 209 then hkp_size-=2 ;checksum bytes at the end of each packet
  ana_size=2*16 ;analog hkp bytes
  dig_size=hkp_size-ana_size ;digital hkp bytes
  fifo_size=8190 ;bytes
  
  fpga_rev = str1.fpga_rev  
  swx_flag = fpga_rev and 'f0'x  eq '50'x
  emu_flag = fpga_rev and 'f0'x  eq 0
  if swx_flag then begin
    fpga_rev += ('c0'x - '50'x)
    dig_size = 128
    d = 20
  endif else begin
    dig_size = 128
    d = 24
  endelse

  fpga_rev = 'ff'x  

  if fpga_rev ge '99'x then begin
;    dig_size = 128
    ana_hkp={$
    adc_bias_voltage:         swfo_data_select(ccsds_data,(d+dig_size)*8,16,/signed)*(2.67+.402+49.9+49.9)/2.67*flt,$
    temp_dap:                 swfo_therm_temp(swfo_data_select(ccsds_data,(d+dig_size+1*2)*8,16,/signed),param=temp_par_16bit),$
    voltage_1p5_vd:           swfo_data_select(ccsds_data,(d+dig_size+2*2)*8,16,/signed)*flt*coeff[0],$
    voltage_3p3_vd:           swfo_data_select(ccsds_data,(d+dig_size+3*2)*8,16,/signed)*flt*coeff[1],$
    voltage_5p0_vd:           swfo_data_select(ccsds_data,(d+dig_size+4*2)*8,16,/signed)*flt*coeff[2],$
    voltage_dfe_pos_va:       swfo_data_select(ccsds_data,(d+dig_size+5*2)*8,16,/signed)*flt*coeff[3],$
    voltage_dfe_neg_va:       swfo_data_select(ccsds_data,(d+dig_size+6*2)*8,16,/signed)*flt*coeff[4],$
    adc_bias_current:         swfo_data_select(ccsds_data,(d+dig_size+7*2)*8,16,/signed)*flt,$
    bias_current_microamps:  -swfo_data_select(ccsds_data,(d+dig_size+7*2)*8,16,/signed)/200e3*1e6*flt,$
    temp_sensor1:             swfo_therm_temp(swfo_data_select(ccsds_data,(d+dig_size+8*2)*8,16,/signed),param=temp_par_16bit),$
    temp_sensor2:             swfo_therm_temp(swfo_data_select(ccsds_data,(d+dig_size+9*2)*8,16,/signed),param=temp_par_16bit),$
    adc_baselines:            swfo_data_select(ccsds_data,(d+dig_size+[10:15]*2)*8,16,/signed)*flt,$
    adc_voltages:             swfo_data_select(ccsds_data,(d+dig_size+[2:6]*2)*8,16,/signed)*flt*coeff-voltages,$
    adc_temps:                swfo_therm_temp(swfo_data_select(ccsds_data,(d+dig_size+[1,8,9]*2)*8,16,/signed),param=temp_par_16bit),$
    mux_all:                  swfo_data_select(ccsds_data,(d+dig_size+[0:15]*2)*8,16,/signed)*flt, $
    replay: 0b, $
    valid: 1b, $
    gap: 0b}
  endif


  if hkp_size ge 160 then begin
    if fpga_rev ge 'CD'x then begin
      ; DEFAULT MODE:
      cmd_fifo_write_ptr=         swfo_data_select(ccsds_data,(d+14*2)*8+6, 13)
      cmd_fifo_read_ptr=          swfo_data_select(ccsds_data,(d+15*2)*8+3, 13)
      cmds_remaining=(fix(cmd_fifo_write_ptr)-fix(cmd_fifo_read_ptr))/3.
      if cmds_remaining lt 0 then cmds_remaining+=fifo_size/3.
      str2={$
        dac_values:               swfo_data_select(ccsds_data,(d+(0+[0:11])*2)*8,16),$
        pps_counter:              swfo_data_select(ccsds_data,(d+12*2  )*8,16),$
        pps_period_100us:         swfo_data_select(ccsds_data,(d+13*2  )*8,16),$
        pps_timeout_100ms:        swfo_data_select(ccsds_data,(d+14*2  )*8, 6),$
        cmd_fifo_write_ptr:       cmd_fifo_write_ptr,$
        cmd_fifo_read_ptr:        cmd_fifo_read_ptr,$
        cmds_remaining:           cmds_remaining,$
        cmds_received:            cmd_fifo_write_ptr/3.,$
        cmds_executed:            cmd_fifo_read_ptr/3.,$
        cmds_executed2:           swfo_data_select(ccsds_data,(d+16*2  )*8,16),$
        cmds_ignored:             swfo_data_select(ccsds_data,(d+17*2  )*8, 8),$
        cmds_unknown:             swfo_data_select(ccsds_data,(d+17*2+1)*8, 8),$
        cmds_invalid:             swfo_data_select(ccsds_data,(d+18*2  )*8, 8),$
        time_cmds_received:       swfo_data_select(ccsds_data,(d+18*2+1)*8, 8),$
        cmd_pause_remaining_100ms:swfo_data_select(ccsds_data,(d+19*2  )*8,16),$
        async_rates:              float(swfo_stis_log_decomp(swfo_data_select(ccsds_data,(d+20*2+[0:5])*8,8))),$
        valid_rates:              float(swfo_stis_log_decomp(swfo_data_select(ccsds_data,(d+23*2+[0:5])*8,8))),$
        event_timeout_rates:      float(swfo_stis_log_decomp(swfo_data_select(ccsds_data,(d+26*2+[0:5])*8,8))),$
        valid_timeout_rates:      float(swfo_stis_log_decomp(swfo_data_select(ccsds_data,(d+29*2+[0:5])*8,8))),$
        nopeak_rates:             float(swfo_stis_log_decomp(swfo_data_select(ccsds_data,(d+32*2+[0:5])*8,8))),$
        unknown_pattern_rates:    float(swfo_stis_log_decomp(swfo_data_select(ccsds_data,(d+35*2+[0:5])*8,8))),$
        negative_pulse_rates:     float(swfo_stis_log_decomp(swfo_data_select(ccsds_data,(d+38*2  )*8,8))),$
        science_events:           float(swfo_stis_log_decomp(swfo_data_select(ccsds_data,(d+38*2+1)*8,8))),$
        met_spare:                swfo_data_select(ccsds_data,(d+39*2  )*8, 8),$
        test_pulse_width_1us:     swfo_data_select(ccsds_data,(d+39*2+1)*8, 8),$
        pulses_remaining:         swfo_data_select(ccsds_data,(d+40*2  )*8,12),$
        board_id:                 swfo_data_select(ccsds_data,(d+40*2)*8+12,2),$
        self_tod_enable:          swfo_data_select(ccsds_data,(d+40*2)*8+14,1),$
        memory_page:              swfo_data_select(ccsds_data,(d+40*2)*8+15,1),$
        memory_address:           swfo_data_select(ccsds_data,(d+41*2  )*8,16),$
        expected_checksum1:       swfo_data_select(ccsds_data,(d+42*2  )*8,16),$
        expected_checksum0:       swfo_data_select(ccsds_data,(d+43*2  )*8,16),$
        checksum1:                swfo_data_select(ccsds_data,(d+44*2  )*8,16),$
        checksum0:                swfo_data_select(ccsds_data,(d+45*2  )*8,16),$
        bias_clock_period_2us:    swfo_data_select(ccsds_data,(d+46*2  )*8, 8),$
        edac_errors:              swfo_data_select(ccsds_data,(d+46*2+1)*8+[0:9]*4,4),$
        bus_timeout_counters:     swfo_data_select(ccsds_data,(d+49*2  )*8+[0:3]*4,4),$
        user_0e:                  swfo_data_select(ccsds_data,(d+50*2  )*8,16),$
        coincidence_window_clkcyc:swfo_data_select(ccsds_data,(d+51*2  )*8, 8),$
        noise_delay_1us:          swfo_data_select(ccsds_data,(d+51*2+1)*8, 4),$
        state_machine_errors:     swfo_data_select(ccsds_data,(d+51*2+1)*8+[1:13]*4,4),$
        first_cmd_id:             swfo_data_select(ccsds_data,(d+55*2  )*8, 8),$
        last_cmd_id:              swfo_data_select(ccsds_data,(d+55*2+1)*8, 8),$
        first_cmd_data:           swfo_data_select(ccsds_data,(d+56*2  )*8,16),$
        last_cmd_data:            swfo_data_select(ccsds_data,(d+57*2  )*8,16),$
        cmd_packets_received:     swfo_data_select(ccsds_data,(d+58*2  )*8, 8),$
        blr_test_pulse_1us:       swfo_data_select(ccsds_data,(d+58*2+1)*8,4),$
        blr_extension_half_us:    swfo_data_select(ccsds_data,(d+58*2+1)*8+4,3),$
        baseline_restore_mode:    swfo_data_select(ccsds_data,(d+58*2+1)*8+7,1),$
        digi_filter_clock_cycles: swfo_data_select(ccsds_data,(d+59*2+[0:1])*8,8),$
        pulser_delay_clock_cycles:swfo_data_select(ccsds_data,(d+60*2  )*8+[0:2]*8,8),$
        valid_enable_mask_bits:   swfo_data_select(ccsds_data,(d+61*2+1)*8, 6),$
        sci_mode_bits:            swfo_data_select(ccsds_data,(d+61*2)*8+14,2),$
        timeouts_2us:             swfo_data_select(ccsds_data,(d+62*2  )*8+[0:2]*4,4),$
        sci_resolution:           swfo_data_select(ccsds_data,(d+62*2)*8+12,4),$
        sci_translate:            swfo_data_select(ccsds_data,(d+63*2  )*8,16)      }
      valid_rates_pps=str2.valid_rates/float(str2.pps_period_100us)*1e4
      str3={valid_rates_pps:valid_rates_pps,valid_rates_total:total(str2.valid_rates)}
      str=create_struct(str1,str2,str3,ana_hkp)
      return,str
    endif

    if fpga_rev ge 'CB'x then begin
      cmd_fifo_write_ptr=         swfo_data_select(ccsds_data,(d+14*2)*8+6, 13)
      cmd_fifo_read_ptr=          swfo_data_select(ccsds_data,(d+15*2)*8+3, 13)
      cmds_remaining=(fix(cmd_fifo_write_ptr)-fix(cmd_fifo_read_ptr))/3.
      if cmds_remaining lt 0 then cmds_remaining+=fifo_size/3.
      str2={$
        dac_values:               swfo_data_select(ccsds_data,(d+(0+[0:11])*2)*8,16),$
        pps_counter:              swfo_data_select(ccsds_data,(d+12*2  )*8,16),$
        pps_period_100us:         swfo_data_select(ccsds_data,(d+13*2  )*8,16),$
        pps_timeout_100ms:        swfo_data_select(ccsds_data,(d+14*2  )*8, 6),$
        cmd_fifo_write_ptr:       cmd_fifo_write_ptr,$
        cmd_fifo_read_ptr:        cmd_fifo_read_ptr,$
        cmds_remaining:           cmds_remaining,$
        cmds_received:            cmd_fifo_write_ptr/3.,$
        cmds_executed:            cmd_fifo_read_ptr/3.,$
        cmds_executed2:           swfo_data_select(ccsds_data,(d+16*2  )*8,16),$
        cmds_ignored:             swfo_data_select(ccsds_data,(d+17*2  )*8, 8),$
        cmds_unknown:             swfo_data_select(ccsds_data,(d+17*2+1)*8, 8),$
        cmds_invalid:             swfo_data_select(ccsds_data,(d+18*2  )*8, 8),$
        time_cmds_received:       swfo_data_select(ccsds_data,(d+18*2+1)*8, 8),$
        cmd_pause_remaining_100ms:swfo_data_select(ccsds_data,(d+19*2  )*8,16),$
        async_rates:              float(swfo_stis_log_decomp(swfo_data_select(ccsds_data,(d+20*2+[0:5])*8,8))),$
        valid_rates:              float(swfo_stis_log_decomp(swfo_data_select(ccsds_data,(d+23*2+[0:5])*8,8))),$
        event_timeout_rates:      float(swfo_stis_log_decomp(swfo_data_select(ccsds_data,(d+26*2+[0:5])*8,8))),$
        valid_timeout_rates:      float(swfo_stis_log_decomp(swfo_data_select(ccsds_data,(d+29*2+[0:5])*8,8))),$
        nopeak_rates:             float(swfo_stis_log_decomp(swfo_data_select(ccsds_data,(d+32*2+[0:5])*8,8))),$
        unknown_pattern_rates:    float(swfo_stis_log_decomp(swfo_data_select(ccsds_data,(d+35*2+[0:5])*8,8))),$
        negative_pulse_rates:     float(swfo_stis_log_decomp(swfo_data_select(ccsds_data,(d+38*2  )*8,8))),$
        science_events:           float(swfo_stis_log_decomp(swfo_data_select(ccsds_data,(d+38*2+1)*8,8))),$
        met_spare:                swfo_data_select(ccsds_data,(d+39*2  )*8, 8),$
        test_pulse_width_1us:     swfo_data_select(ccsds_data,(d+39*2+1)*8, 8),$
        pulses_remaining:         swfo_data_select(ccsds_data,(d+40*2  )*8,12),$
        board_id:                 swfo_data_select(ccsds_data,(d+40*2)*8+12,2),$
        self_tod_enable:          swfo_data_select(ccsds_data,(d+40*2)*8+14,1),$
        memory_page:              swfo_data_select(ccsds_data,(d+40*2)*8+15,1),$
        memory_address:           swfo_data_select(ccsds_data,(d+41*2  )*8,16),$
        expected_checksum1:       swfo_data_select(ccsds_data,(d+42*2  )*8,16),$
        expected_checksum0:       swfo_data_select(ccsds_data,(d+43*2  )*8,16),$
        checksum1:                swfo_data_select(ccsds_data,(d+44*2  )*8,16),$
        checksum0:                swfo_data_select(ccsds_data,(d+45*2  )*8,16),$
        bias_clock_period_2us:    swfo_data_select(ccsds_data,(d+46*2  )*8, 8),$
        edac_errors:              swfo_data_select(ccsds_data,(d+46*2+1)*8+[0:9]*4,4),$
        bus_timeout_counters:     swfo_data_select(ccsds_data,(d+49*2  )*8+[0:3]*4,4),$
        user_0e:                  swfo_data_select(ccsds_data,(d+50*2  )*8,16),$
        coincidence_window_clkcyc:swfo_data_select(ccsds_data,(d+51*2  )*8, 8),$
        noise_delay_1us:          swfo_data_select(ccsds_data,(d+51*2+1)*8, 4),$
        state_machine_errors:     swfo_data_select(ccsds_data,(d+51*2+1)*8+[1:13]*4,4),$
        first_cmd_id:             swfo_data_select(ccsds_data,(d+55*2  )*8, 8),$
        last_cmd_id:              swfo_data_select(ccsds_data,(d+55*2+1)*8, 8),$
        first_cmd_data:           swfo_data_select(ccsds_data,(d+56*2  )*8,16),$
        last_cmd_data:            swfo_data_select(ccsds_data,(d+57*2  )*8,16),$
        reserved:                 swfo_data_select(ccsds_data,(d+58*2  )*8, 8),$
        blr_test_pulse_1us:       swfo_data_select(ccsds_data,(d+58*2+1)*8,4),$
        blr_extension_half_us:    swfo_data_select(ccsds_data,(d+58*2+1)*8+4,3),$
        baseline_restore_mode:    swfo_data_select(ccsds_data,(d+58*2+1)*8+7,1),$
        digi_filter_clock_cycles: swfo_data_select(ccsds_data,(d+59*2+[0:1])*8,8),$
        pulser_delay_clock_cycles:swfo_data_select(ccsds_data,(d+60*2  )*8+[0:2]*8,8),$
        valid_enable_mask_bits:   swfo_data_select(ccsds_data,(d+61*2+1)*8, 6),$
        sci_mode_bits:            swfo_data_select(ccsds_data,(d+61*2)*8+14,2),$
        timeouts_2us:             swfo_data_select(ccsds_data,(d+62*2  )*8+[0:2]*4,4),$
        sci_resolution:           swfo_data_select(ccsds_data,(d+62*2)*8+12,4),$
        sci_translate:            swfo_data_select(ccsds_data,(d+63*2  )*8,16),$
        gap:ccsds.gap }
      valid_rates_pps=str2.valid_rates/float(str2.pps_period_100us)*1e4
      str3={valid_rates_pps:valid_rates_pps,valid_rates_total:total(str2.valid_rates)}
      str=create_struct(str1,str2,str3,ana_hkp)
      return,str
    endif

    if str1.fpga_rev ge 'C9'x then begin
      cmd_fifo_write_ptr=         swfo_data_select(ccsds_data,(d+14*2)*8+6, 13)
      cmd_fifo_read_ptr=          swfo_data_select(ccsds_data,(d+15*2)*8+3, 13)
      cmds_remaining=(fix(cmd_fifo_write_ptr)-fix(cmd_fifo_read_ptr))/3.
      if cmds_remaining lt 0 then cmds_remaining+=fifo_size/3.
      str2={$
        dac_values:               swfo_data_select(ccsds_data,(d+(0+[0:11])*2)*8,16),$
        pps_counter:              swfo_data_select(ccsds_data,(d+12*2  )*8,16),$
        pps_period_100us:         swfo_data_select(ccsds_data,(d+13*2  )*8,16),$
        pps_timeout_100ms:        swfo_data_select(ccsds_data,(d+14*2  )*8, 6),$
        cmd_fifo_write_ptr:       cmd_fifo_write_ptr,$
        cmd_fifo_read_ptr:        cmd_fifo_read_ptr,$
        cmds_remaining:           cmds_remaining,$
        cmds_received:            cmd_fifo_write_ptr/3.,$
        cmds_executed:            cmd_fifo_read_ptr/3.,$
        cmds_executed2:           swfo_data_select(ccsds_data,(d+16*2  )*8,16),$
        cmds_ignored:             swfo_data_select(ccsds_data,(d+17*2  )*8, 8),$
        cmds_unknown:             swfo_data_select(ccsds_data,(d+17*2+1)*8, 8),$
        cmds_invalid:             swfo_data_select(ccsds_data,(d+18*2  )*8, 8),$
        time_cmds_received:       swfo_data_select(ccsds_data,(d+18*2+1)*8, 8),$
        cmd_pause_remaining_100ms:swfo_data_select(ccsds_data,(d+19*2  )*8,16),$
        async_rates:              float(swfo_stis_log_decomp(swfo_data_select(ccsds_data,(d+20*2+[0:5])*8,8))),$
        valid_rates:              float(swfo_stis_log_decomp(swfo_data_select(ccsds_data,(d+23*2+[0:5])*8,8))),$
        event_timeout_rates:      float(swfo_stis_log_decomp(swfo_data_select(ccsds_data,(d+26*2+[0:5])*8,8))),$
        valid_timeout_rates:      float(swfo_stis_log_decomp(swfo_data_select(ccsds_data,(d+29*2+[0:5])*8,8))),$
        nopeak_rates:             float(swfo_stis_log_decomp(swfo_data_select(ccsds_data,(d+32*2+[0:5])*8,8))),$
        unknown_pattern_rates:    float(swfo_stis_log_decomp(swfo_data_select(ccsds_data,(d+35*2+[0:5])*8,8))),$
        negative_pulse_rates:     float(swfo_stis_log_decomp(swfo_data_select(ccsds_data,(d+38*2  )*8,8))),$
        science_events:           float(swfo_stis_log_decomp(swfo_data_select(ccsds_data,(d+38*2+1)*8,8))),$
        met_spare:                swfo_data_select(ccsds_data,(d+39*2  )*8, 8),$
        test_pulse_width_1us:     swfo_data_select(ccsds_data,(d+39*2+1)*8, 8),$
        pulses_remaining:         swfo_data_select(ccsds_data,(d+40*2  )*8,12),$
        board_id:                 swfo_data_select(ccsds_data,(d+40*2)*8+12,2),$
        self_tod_enable:          swfo_data_select(ccsds_data,(d+40*2)*8+14,1),$
        memory_page:              swfo_data_select(ccsds_data,(d+40*2)*8+15,1),$
        memory_address:           swfo_data_select(ccsds_data,(d+41*2  )*8,16),$
        expected_checksum1:       swfo_data_select(ccsds_data,(d+42*2  )*8,16),$
        expected_checksum0:       swfo_data_select(ccsds_data,(d+43*2  )*8,16),$
        checksum1:                swfo_data_select(ccsds_data,(d+44*2  )*8,16),$
        checksum0:                swfo_data_select(ccsds_data,(d+45*2  )*8,16),$
        bias_clock_period_2us:    swfo_data_select(ccsds_data,(d+46*2  )*8, 8),$
        edac_errors:              swfo_data_select(ccsds_data,(d+46*2+1)*8+[0:9]*4,4),$
        bus_timeout_counters:     swfo_data_select(ccsds_data,(d+49*2  )*8+[0:3]*4,4),$
        user_0e:                  swfo_data_select(ccsds_data,(d+50*2  )*8,16),$
        coincidence_window_clkcyc:swfo_data_select(ccsds_data,(d+51*2  )*8, 8),$
        noise_delay_1us:          swfo_data_select(ccsds_data,(d+51*2+1)*8, 4),$
        state_machine_errors:     swfo_data_select(ccsds_data,(d+51*2+1)*8+[1:13]*4,4),$
        first_cmd_id:             swfo_data_select(ccsds_data,(d+55*2  )*8, 8),$
        last_cmd_id:              swfo_data_select(ccsds_data,(d+55*2+1)*8, 8),$
        first_cmd_data:           swfo_data_select(ccsds_data,(d+56*2  )*8,16),$
        last_cmd_data:            swfo_data_select(ccsds_data,(d+57*2  )*8,16),$
        reserved:                 swfo_data_select(ccsds_data,(d+58*2  )*8, 4),$
        baseline_restore_ext1_2us:swfo_data_select(ccsds_data,(d+58*2)*8+4, 4),$
        baseline_restore_ext2_us: swfo_data_select(ccsds_data,(d+58*2+1)*8, 6),$
        baseline_restore_mode:    swfo_data_select(ccsds_data,(d+58*2)*8+14,2),$
        digi_filter_clock_cycles: swfo_data_select(ccsds_data,(d+59*2+[0:1])*8,8),$
        pulser_delay_clock_cycles:swfo_data_select(ccsds_data,(d+60*2  )*8+[0:2]*8,8),$
        valid_enable_mask_bits:   swfo_data_select(ccsds_data,(d+61*2+1)*8, 6),$
        sci_mode_bits:            swfo_data_select(ccsds_data,(d+61*2)*8+14,2),$
        timeouts_2us:             swfo_data_select(ccsds_data,(d+62*2  )*8+[0:2]*4,4),$
        sci_resolution:           swfo_data_select(ccsds_data,(d+62*2)*8+12,4),$
        sci_translate:            swfo_data_select(ccsds_data,(d+63*2  )*8,16),$
        gap:ccsds.gap }
      valid_rates_pps=str2.valid_rates/float(str2.pps_period_100us)*1e4
      str3={valid_rates_pps:valid_rates_pps,valid_rates_total:total(str2.valid_rates)}
      str=create_struct(str1,str2,str3,ana_hkp)
      return,str
    endif

    if str1.fpga_rev ge 'BE'x then begin
      cmd_fifo_write_ptr=         swfo_data_select(ccsds_data,(d+14*2)*8+6, 13)
      cmd_fifo_read_ptr=          swfo_data_select(ccsds_data,(d+15*2)*8+3, 13)
      cmds_remaining=(fix(cmd_fifo_write_ptr)-fix(cmd_fifo_read_ptr))/3.
      if cmds_remaining lt 0 then cmds_remaining+=fifo_size/3.
      str2={$
        dac_values:               swfo_data_select(ccsds_data,(d+(0+[0:11])*2)*8,16),$
        pps_counter:              swfo_data_select(ccsds_data,(d+12*2  )*8,16),$
        pps_period_100us:         swfo_data_select(ccsds_data,(d+13*2  )*8,16),$
        pps_timeout_100ms:        swfo_data_select(ccsds_data,(d+14*2  )*8, 6),$
        cmd_fifo_write_ptr:       cmd_fifo_write_ptr,$
        cmd_fifo_read_ptr:        cmd_fifo_read_ptr,$
        cmds_remaining:           cmds_remaining,$
        cmds_received:            cmd_fifo_write_ptr/3.,$
        cmds_executed:            cmd_fifo_read_ptr/3.,$
        cmds_executed2:           swfo_data_select(ccsds_data,(d+16*2  )*8,16),$
        cmds_ignored:             swfo_data_select(ccsds_data,(d+17*2  )*8, 8),$
        cmds_unknown:             swfo_data_select(ccsds_data,(d+17*2+1)*8, 8),$
        cmds_invalid:             swfo_data_select(ccsds_data,(d+18*2  )*8, 8),$
        time_cmds_received:       swfo_data_select(ccsds_data,(d+18*2+1)*8, 8),$
        cmd_pause_remaining_100ms:swfo_data_select(ccsds_data,(d+19*2  )*8,16),$
        async_rates:              float(swfo_stis_log_decomp(swfo_data_select(ccsds_data,(d+20*2+[0:5])*8,8))),$
        valid_rates:              float(swfo_stis_log_decomp(swfo_data_select(ccsds_data,(d+23*2+[0:5])*8,8))),$
        event_timeout_rates:      float(swfo_stis_log_decomp(swfo_data_select(ccsds_data,(d+26*2+[0:5])*8,8))),$
        valid_timeout_rates:      float(swfo_stis_log_decomp(swfo_data_select(ccsds_data,(d+29*2+[0:5])*8,8))),$
        nopeak_rates:             float(swfo_stis_log_decomp(swfo_data_select(ccsds_data,(d+32*2+[0:5])*8,8))),$
        unknown_pattern_rates:    float(swfo_stis_log_decomp(swfo_data_select(ccsds_data,(d+35*2+[0:5])*8,8))),$
        negative_pulse_rates:     float(swfo_stis_log_decomp(swfo_data_select(ccsds_data,(d+38*2  )*8,8))),$
        science_events:           float(swfo_stis_log_decomp(swfo_data_select(ccsds_data,(d+38*2+1)*8,8))),$
        met_spare:                swfo_data_select(ccsds_data,(d+39*2  )*8, 8),$
        test_pulse_width_1us:     swfo_data_select(ccsds_data,(d+39*2+1)*8, 8),$
        pulses_remaining:         swfo_data_select(ccsds_data,(d+40*2  )*8,12),$
        board_id:                 swfo_data_select(ccsds_data,(d+40*2)*8+12,2),$
        self_tod_enable:          swfo_data_select(ccsds_data,(d+40*2)*8+14,1),$
        memory_page:              swfo_data_select(ccsds_data,(d+40*2)*8+15,1),$
        memory_address:           swfo_data_select(ccsds_data,(d+41*2  )*8,16),$
        expected_checksum1:       swfo_data_select(ccsds_data,(d+42*2  )*8,16),$
        expected_checksum0:       swfo_data_select(ccsds_data,(d+43*2  )*8,16),$
        checksum1:                swfo_data_select(ccsds_data,(d+44*2  )*8,16),$
        checksum0:                swfo_data_select(ccsds_data,(d+45*2  )*8,16),$
        bias_clock_period_2us:    swfo_data_select(ccsds_data,(d+46*2  )*8, 8),$
        edac_errors:              swfo_data_select(ccsds_data,(d+46*2+1)*8+[0:9]*4,4),$
        bus_timeout_counters:     swfo_data_select(ccsds_data,(d+49*2  )*8+[0:3]*4,4),$
        user_0e:                  swfo_data_select(ccsds_data,(d+50*2  )*8,16),$
        user_2d:                  swfo_data_select(ccsds_data,(d+51*2  )*8, 8),$
        noise_delay_1us:          swfo_data_select(ccsds_data,(d+51*2+1)*8, 4),$
        state_machine_errors:     swfo_data_select(ccsds_data,(d+51*2+1)*8+[1:13]*4,4),$
        first_cmd_id:             swfo_data_select(ccsds_data,(d+55*2  )*8, 8),$
        last_cmd_id:              swfo_data_select(ccsds_data,(d+55*2+1)*8, 8),$
        first_cmd_data:           swfo_data_select(ccsds_data,(d+56*2  )*8,16),$
        last_cmd_data:            swfo_data_select(ccsds_data,(d+57*2  )*8,16),$
        baseline_restore_ext1_us: swfo_data_select(ccsds_data,(d+58*2  )*8, 8),$
        baseline_restore_ext2_us: swfo_data_select(ccsds_data,(d+58*2+1)*8, 6),$
        baseline_restore_mode:    swfo_data_select(ccsds_data,(d+58*2)*8+14,2),$
        digi_filter_clock_cycles: swfo_data_select(ccsds_data,(d+59*2+[0:1])*8,8),$
        pulser_delay_clock_cycles:swfo_data_select(ccsds_data,(d+60*2  )*8+[0:2]*8,8),$
        valid_enable_mask_bits:   swfo_data_select(ccsds_data,(d+61*2+1)*8, 6),$
        sci_mode_bits:            swfo_data_select(ccsds_data,(d+61*2)*8+14,2),$
        timeouts_2us:             swfo_data_select(ccsds_data,(d+62*2  )*8+[0:2]*4,4),$
        sci_resolution:           swfo_data_select(ccsds_data,(d+62*2)*8+12,4),$
        sci_translate:            swfo_data_select(ccsds_data,(d+63*2  )*8,16),$
        gap:ccsds.gap }
      valid_rates_pps=str2.valid_rates/float(str2.pps_period_100us)*1e4
      str3={valid_rates_pps:valid_rates_pps,valid_rates_total:total(str2.valid_rates)}
      str=create_struct(str1,str2,str3,ana_hkp)
      return,str
    endif

    if str1.fpga_rev ge 'BA'x then begin
      cmd_fifo_write_ptr=         swfo_data_select(ccsds_data,(d+14*2)*8+6, 13)
      cmd_fifo_read_ptr=          swfo_data_select(ccsds_data,(d+15*2)*8+3, 13)
      cmds_remaining=(fix(cmd_fifo_write_ptr)-fix(cmd_fifo_read_ptr))/3.
      if cmds_remaining lt 0 then cmds_remaining+=fifo_size/3.
      str2={$
        dac_values:               swfo_data_select(ccsds_data,(d+(0+[0:11])*2)*8,16),$
        pps_counter:              swfo_data_select(ccsds_data,(d+12*2  )*8,16),$
        pps_period_100us:         swfo_data_select(ccsds_data,(d+13*2  )*8,16),$
        pps_timeout_100ms:        swfo_data_select(ccsds_data,(d+14*2  )*8, 6),$
        cmd_fifo_write_ptr:       cmd_fifo_write_ptr,$
        cmd_fifo_read_ptr:        cmd_fifo_read_ptr,$
        cmds_remaining:           cmds_remaining,$
        cmds_received:            cmd_fifo_write_ptr/3.,$
        cmds_executed:            cmd_fifo_read_ptr/3.,$
        cmds_executed2:           swfo_data_select(ccsds_data,(d+16*2  )*8,16),$
        cmds_ignored:             swfo_data_select(ccsds_data,(d+17*2  )*8, 8),$
        cmds_unknown:             swfo_data_select(ccsds_data,(d+17*2+1)*8, 8),$
        cmds_invalid:             swfo_data_select(ccsds_data,(d+18*2  )*8, 8),$
        time_cmds_received:       swfo_data_select(ccsds_data,(d+18*2+1)*8, 8),$
        cmd_pause_remaining_100ms:swfo_data_select(ccsds_data,(d+19*2  )*8,16),$
        async_rates:              float(swfo_stis_log_decomp(swfo_data_select(ccsds_data,(d+20*2+[0:5])*8,8))),$
        valid_rates:              float(swfo_stis_log_decomp(swfo_data_select(ccsds_data,(d+23*2+[0:5])*8,8))),$
        event_timeout_rates:      float(swfo_stis_log_decomp(swfo_data_select(ccsds_data,(d+26*2+[0:5])*8,8))),$
        valid_timeout_rates:      float(swfo_stis_log_decomp(swfo_data_select(ccsds_data,(d+29*2+[0:5])*8,8))),$
        nopeak_rates:             float(swfo_stis_log_decomp(swfo_data_select(ccsds_data,(d+32*2+[0:5])*8,8))),$
        unknown_pattern_rates:    float(swfo_stis_log_decomp(swfo_data_select(ccsds_data,(d+35*2+[0:5])*8,8))),$
        negative_pulse_rates:     float(swfo_stis_log_decomp(swfo_data_select(ccsds_data,(d+38*2  )*8,8))),$
        science_events:           float(swfo_stis_log_decomp(swfo_data_select(ccsds_data,(d+38*2+1)*8,8))),$
        met_spare:                swfo_data_select(ccsds_data,(d+39*2  )*8, 8),$
        test_pulse_width_1us:     swfo_data_select(ccsds_data,(d+39*2+1)*8, 8),$
        pulses_remaining:         swfo_data_select(ccsds_data,(d+40*2  )*8,12),$
        board_id:                 swfo_data_select(ccsds_data,(d+40*2)*8+12,2),$
        self_tod_enable:          swfo_data_select(ccsds_data,(d+40*2)*8+14,1),$
        memory_page:              swfo_data_select(ccsds_data,(d+40*2)*8+15,1),$
        memory_address:           swfo_data_select(ccsds_data,(d+41*2  )*8,16),$
        expected_checksum1:       swfo_data_select(ccsds_data,(d+42*2  )*8,16),$
        expected_checksum0:       swfo_data_select(ccsds_data,(d+43*2  )*8,16),$
        checksum1:                swfo_data_select(ccsds_data,(d+44*2  )*8,16),$
        checksum0:                swfo_data_select(ccsds_data,(d+45*2  )*8,16),$
        bias_clock_period_2us:    swfo_data_select(ccsds_data,(d+46*2  )*8, 8),$
        edac_errors:              swfo_data_select(ccsds_data,(d+46*2+1)*8+[0:9]*4,4),$
        bus_timeout_counters:     swfo_data_select(ccsds_data,(d+49*2  )*8+[0:3]*4,4),$
        user_0e:                  swfo_data_select(ccsds_data,(d+50*2  )*8,16),$
        user_2d:                  swfo_data_select(ccsds_data,(d+51*2  )*8, 8),$
        reserved0:                swfo_data_select(ccsds_data,(d+51*2+1)*8, 4),$
        state_machine_errors:     swfo_data_select(ccsds_data,(d+51*2+1)*8+[1:13]*4,4),$
        first_cmd_id:             swfo_data_select(ccsds_data,(d+55*2  )*8, 8),$
        last_cmd_id:              swfo_data_select(ccsds_data,(d+55*2+1)*8, 8),$
        first_cmd_data:           swfo_data_select(ccsds_data,(d+56*2  )*8,16),$
        last_cmd_data:            swfo_data_select(ccsds_data,(d+57*2  )*8,16),$
        baseline_restore_ext1_us: swfo_data_select(ccsds_data,(d+58*2  )*8, 8),$
        baseline_restore_ext2_us: swfo_data_select(ccsds_data,(d+58*2+1)*8, 6),$
        baseline_restore_mode:    swfo_data_select(ccsds_data,(d+58*2)*8+14,2),$
        digi_filter_clock_cycles: swfo_data_select(ccsds_data,(d+59*2+[0:1])*8,8),$
        pulser_delay_clock_cycles:swfo_data_select(ccsds_data,(d+60*2  )*8+[0:2]*8,8),$
        valid_enable_mask_bits:   swfo_data_select(ccsds_data,(d+61*2+1)*8, 6),$
        sci_mode_bits:            swfo_data_select(ccsds_data,(d+61*2)*8+14,2),$
        timeouts_2us:             swfo_data_select(ccsds_data,(d+62*2  )*8+[0:2]*4,4),$
        sci_resolution:           swfo_data_select(ccsds_data,(d+62*2)*8+12,4),$
        sci_translate:            swfo_data_select(ccsds_data,(d+63*2  )*8,16),$
        gap:ccsds.gap }
      valid_rates_pps=str2.valid_rates/float(str2.pps_period_100us)*1e4
      str3={valid_rates_pps:valid_rates_pps,valid_rates_total:total(str2.valid_rates)}
      str=create_struct(str1,str2,str3,ana_hkp)
      return,str
    endif

    if str1.fpga_rev ge 'B9'x then begin
      cmd_fifo_write_ptr=         swfo_data_select(ccsds_data,(d+14*2)*8+6, 13)
      cmd_fifo_read_ptr=          swfo_data_select(ccsds_data,(d+15*2)*8+3, 13)
      cmds_remaining=(fix(cmd_fifo_write_ptr)-fix(cmd_fifo_read_ptr))/3.
      if cmds_remaining lt 0 then cmds_remaining+=fifo_size/3.
      str2={$
        dac_values:               swfo_data_select(ccsds_data,(d+(0+[0:11])*2)*8,16),$
        pps_counter:              swfo_data_select(ccsds_data,(d+12*2  )*8,16),$
        pps_period_100us:         swfo_data_select(ccsds_data,(d+13*2  )*8,16),$
        pps_timeout_100ms:        swfo_data_select(ccsds_data,(d+14*2  )*8, 6),$
        cmd_fifo_write_ptr:       cmd_fifo_write_ptr,$
        cmd_fifo_read_ptr:        cmd_fifo_read_ptr,$
        cmds_remaining:           cmds_remaining,$
        cmds_received:            cmd_fifo_write_ptr/3.,$
        cmds_executed:            cmd_fifo_read_ptr/3.,$
        cmds_executed2:           swfo_data_select(ccsds_data,(d+16*2  )*8,16),$
        cmds_ignored:             swfo_data_select(ccsds_data,(d+17*2  )*8, 8),$
        cmds_unknown:             swfo_data_select(ccsds_data,(d+17*2+1)*8, 8),$
        cmds_invalid:             swfo_data_select(ccsds_data,(d+18*2  )*8, 8),$
        time_cmds_received:       swfo_data_select(ccsds_data,(d+18*2+1)*8, 8),$
        cmd_pause_remaining_100ms:swfo_data_select(ccsds_data,(d+19*2  )*8,16),$
        valid_rates:              float(swfo_stis_log_decomp(swfo_data_select(ccsds_data,(d+20*2+[0:5])*8,8))),$
        async_rates:              float(swfo_stis_log_decomp(swfo_data_select(ccsds_data,(d+23*2+[0:5])*8,8))),$
        nopeak_rates:             float(swfo_stis_log_decomp(swfo_data_select(ccsds_data,(d+26*2+[0:5])*8,8))),$
        event_timeout_rates:      float(swfo_stis_log_decomp(swfo_data_select(ccsds_data,(d+29*2+[0:5])*8,8))),$
        unknown_pattern_rates:    float(swfo_stis_log_decomp(swfo_data_select(ccsds_data,(d+32*2+[0:5])*8,8))),$
        valid_timeout_rates:      float(swfo_stis_log_decomp(swfo_data_select(ccsds_data,(d+35*2+[0:5])*8,8))),$
        negative_pulse_rates:     float(swfo_stis_log_decomp(swfo_data_select(ccsds_data,(d+38*2  )*8,8))),$
        science_events:           float(swfo_stis_log_decomp(swfo_data_select(ccsds_data,(d+38*2+1)*8,8))),$
        met_spare:                swfo_data_select(ccsds_data,(d+39*2  )*8, 8),$
        test_pulse_width_1us:     swfo_data_select(ccsds_data,(d+39*2+1)*8, 8),$
        pulses_remaining:         swfo_data_select(ccsds_data,(d+40*2  )*8,12),$
        board_id:                 swfo_data_select(ccsds_data,(d+40*2)*8+12,2),$
        self_tod_enable:          swfo_data_select(ccsds_data,(d+40*2)*8+14,1),$
        memory_page:              swfo_data_select(ccsds_data,(d+40*2)*8+15,1),$
        memory_address:           swfo_data_select(ccsds_data,(d+41*2  )*8,16),$
        expected_checksum1:       swfo_data_select(ccsds_data,(d+42*2  )*8,16),$
        expected_checksum0:       swfo_data_select(ccsds_data,(d+43*2  )*8,16),$
        checksum1:                swfo_data_select(ccsds_data,(d+44*2  )*8,16),$
        checksum0:                swfo_data_select(ccsds_data,(d+45*2  )*8,16),$
        bias_clock_period_2us:    swfo_data_select(ccsds_data,(d+46*2  )*8, 8),$
        edac_errors:              swfo_data_select(ccsds_data,(d+46*2+1)*8+[0:9]*4,4),$
        bus_timeout_counters:     swfo_data_select(ccsds_data,(d+49*2  )*8+[0:3]*4,4),$
        user_0e:                  swfo_data_select(ccsds_data,(d+50*2  )*8,16),$
        user_2d:                  swfo_data_select(ccsds_data,(d+51*2  )*8, 8),$
        reserved0:                swfo_data_select(ccsds_data,(d+51*2+1)*8, 4),$
        state_machine_errors:     swfo_data_select(ccsds_data,(d+51*2+1)*8+[1:13]*4,4),$
        first_cmd_id:             swfo_data_select(ccsds_data,(d+55*2  )*8, 8),$
        last_cmd_id:              swfo_data_select(ccsds_data,(d+55*2+1)*8, 8),$
        first_cmd_data:           swfo_data_select(ccsds_data,(d+56*2  )*8,16),$
        last_cmd_data:            swfo_data_select(ccsds_data,(d+57*2  )*8,16),$
        baseline_restore_ext1_us: swfo_data_select(ccsds_data,(d+58*2  )*8, 8),$
        baseline_restore_ext2_us: swfo_data_select(ccsds_data,(d+58*2+1)*8, 6),$
        baseline_restore_mode:    swfo_data_select(ccsds_data,(d+58*2)*8+14,2),$
        digi_filter_clock_cycles: swfo_data_select(ccsds_data,(d+59*2+[0:1])*8,8),$
        pulser_delay_clock_cycles:swfo_data_select(ccsds_data,(d+60*2  )*8+[0:2]*8,8),$
        valid_enable_mask_bits:   swfo_data_select(ccsds_data,(d+61*2+1)*8, 6),$
        sci_mode_bits:            swfo_data_select(ccsds_data,(d+61*2)*8+14,2),$
        timeouts_2us:             swfo_data_select(ccsds_data,(d+62*2  )*8+[0:2]*4,4),$
        sci_resolution:           swfo_data_select(ccsds_data,(d+62*2)*8+12,4),$
        sci_translate:            swfo_data_select(ccsds_data,(d+63*2  )*8,16),$
        gap:ccsds.gap }
      valid_rates_pps=str2.valid_rates/float(str2.pps_period_100us)*1e4
      str3={valid_rates_pps:valid_rates_pps,valid_rates_total:total(str2.valid_rates)}
      str=create_struct(str1,str2,str3,ana_hkp)
      return,str
    endif
  endif

  if hkp_size eq 176 then begin
    if str1.fpga_rev ge 'B8'x then begin
      cmd_fifo_write_ptr=         swfo_data_select(ccsds_data,(d+14*2)*8+6, 13)
      cmd_fifo_read_ptr=          swfo_data_select(ccsds_data,(d+15*2)*8+3, 13)
      cmds_remaining=(fix(cmd_fifo_write_ptr)-fix(cmd_fifo_read_ptr))/3.
      if cmds_remaining lt 0 then cmds_remaining+=fifo_size/3.
      str2={$
        dac_values:               swfo_data_select(ccsds_data,(d+(0+[0:11])*2)*8,16),$
        pps_counter:              swfo_data_select(ccsds_data,(d+12*2  )*8,16),$
        pps_period_100us:         swfo_data_select(ccsds_data,(d+13*2  )*8,16),$
        pps_timeout_100ms:        swfo_data_select(ccsds_data,(d+14*2  )*8, 6),$
        cmd_fifo_write_ptr:       cmd_fifo_write_ptr,$
        cmd_fifo_read_ptr:        cmd_fifo_read_ptr,$
        cmds_remaining:           cmds_remaining,$
        cmds_received:            cmd_fifo_write_ptr/3.,$
        cmds_executed:            cmd_fifo_read_ptr/3.,$
        cmds_executed2:           swfo_data_select(ccsds_data,(d+16*2  )*8,16),$
        cmds_ignored:             swfo_data_select(ccsds_data,(d+17*2  )*8, 8),$
        cmds_unknown:             swfo_data_select(ccsds_data,(d+17*2+1)*8, 8),$
        cmds_invalid:             swfo_data_select(ccsds_data,(d+18*2  )*8, 8),$
        time_cmds_received:       swfo_data_select(ccsds_data,(d+18*2+1)*8, 8),$
        cmd_pause_remaining_100ms:swfo_data_select(ccsds_data,(d+19*2  )*8,16),$
        valid_rates:              float(swfo_stis_log_decomp(swfo_data_select(ccsds_data,(d+20*2+[0:5])*8,8))),$
        async_rates:              float(swfo_stis_log_decomp(swfo_data_select(ccsds_data,(d+23*2+[0:5])*8,8))),$
        nopeak_rates:             float(swfo_stis_log_decomp(swfo_data_select(ccsds_data,(d+26*2+[0:5])*8,8))),$
        event_timeout_rates:      float(swfo_stis_log_decomp(swfo_data_select(ccsds_data,(d+29*2+[0:5])*8,8))),$
        unknown_pattern_rates:    float(swfo_stis_log_decomp(swfo_data_select(ccsds_data,(d+32*2+[0:5])*8,8))),$
        negative_pulse_rates:     float(swfo_stis_log_decomp(swfo_data_select(ccsds_data,(d+35*2  )*8,8))),$
        science_events:           float(swfo_stis_log_decomp(swfo_data_select(ccsds_data,(d+35*2+1)*8,8))),$
        met_spare:                swfo_data_select(ccsds_data,(d+36*2  )*8, 8),$
        test_pulse_width_1us:     swfo_data_select(ccsds_data,(d+36*2+1)*8, 8),$
        pulses_remaining:         swfo_data_select(ccsds_data,(d+37*2  )*8,12),$
        board_id:                 swfo_data_select(ccsds_data,(d+37*2)*8+12,2),$
        self_tod_enable:          swfo_data_select(ccsds_data,(d+37*2)*8+14,1),$
        memory_page:              swfo_data_select(ccsds_data,(d+37*2)*8+15,1),$
        memory_address:           swfo_data_select(ccsds_data,(d+38*2  )*8,16),$
        expected_checksum1:       swfo_data_select(ccsds_data,(d+39*2  )*8,16),$
        expected_checksum0:       swfo_data_select(ccsds_data,(d+40*2  )*8,16),$
        checksum1:                swfo_data_select(ccsds_data,(d+41*2  )*8,16),$
        checksum0:                swfo_data_select(ccsds_data,(d+42*2  )*8,16),$
        bias_clock_period_2us:    swfo_data_select(ccsds_data,(d+43*2  )*8, 8),$
        edac_errors:              swfo_data_select(ccsds_data,(d+43*2+1)*8+[0:9]*4,4),$
        bus_timeout_counters:     swfo_data_select(ccsds_data,(d+46*2  )*8+[0:3]*4,4),$
        user_0e:                  swfo_data_select(ccsds_data,(d+47*2  )*8,16),$
        user_2d:                  swfo_data_select(ccsds_data,(d+48*2  )*8, 8),$
        reserved0:                swfo_data_select(ccsds_data,(d+48*2+1)*8, 4),$
        state_machine_errors:     swfo_data_select(ccsds_data,(d+48*2+1)*8+[1:13]*4,4),$
        first_cmd_id:             swfo_data_select(ccsds_data,(d+52*2  )*8, 8),$
        last_cmd_id:              swfo_data_select(ccsds_data,(d+52*2+1)*8, 8),$
        first_cmd_data:           swfo_data_select(ccsds_data,(d+53*2  )*8,16),$
        last_cmd_data:            swfo_data_select(ccsds_data,(d+54*2  )*8,16),$
        baseline_restore_ext1_us: swfo_data_select(ccsds_data,(d+55*2  )*8, 8),$
        baseline_restore_ext2_us: swfo_data_select(ccsds_data,(d+55*2+1)*8, 6),$
        baseline_restore_mode:    swfo_data_select(ccsds_data,(d+55*2)*8+14,2),$
        digi_filter_clock_cycles: swfo_data_select(ccsds_data,(d+56*2+[0:1])*8,8),$
        pulser_delay_clock_cycles:swfo_data_select(ccsds_data,(d+57*2  )*8+[0:2]*16,16),$
        reserved1:                swfo_data_select(ccsds_data,(d+60*2  )*8,10),$
        valid_enable_mask_bits:   swfo_data_select(ccsds_data,(d+60*2+1)*8+2,6),$
        timeouts:                 swfo_data_select(ccsds_data,(d+61*2  )*8+[0:2]*16,16),$
        valid_timeout_rates:      float(swfo_stis_log_decomp(swfo_data_select(ccsds_data,(d+64*2+[0:5])*8,8))),$
        gap:ccsds.gap }
      valid_rates_pps=str2.valid_rates/float(str2.pps_period_100us)*1e4
      str3={valid_rates_pps:valid_rates_pps,valid_rates_total:total(str2.valid_rates)}
      str=create_struct(str1,str2,str3,ana_hkp)
      return,str
    endif
  endif

  if hkp_size eq 160 then begin
    if str1.fpga_rev ge 'B3'x then begin
      cmd_fifo_write_ptr=         swfo_data_select(ccsds_data,(d+14*2)*8+6, 13)
      cmd_fifo_read_ptr=          swfo_data_select(ccsds_data,(d+15*2)*8+3, 13)
      cmds_remaining=(fix(cmd_fifo_write_ptr)-fix(cmd_fifo_read_ptr))/3.
      if cmds_remaining lt 0 then cmds_remaining+=fifo_size/3.
      str2={$
        dac_values:               swfo_data_select(ccsds_data,(d+(0+[0:11])*2)*8,16),$
        pps_counter:              swfo_data_select(ccsds_data,(d+12*2  )*8,16),$
        pps_period_100us:         swfo_data_select(ccsds_data,(d+13*2  )*8,16),$
        pps_timeout_100ms:        swfo_data_select(ccsds_data,(d+14*2  )*8, 6),$
        cmd_fifo_write_ptr:       cmd_fifo_write_ptr,$
        cmd_fifo_read_ptr:        cmd_fifo_read_ptr,$
        cmds_remaining:           cmds_remaining,$
        cmds_received:            cmd_fifo_write_ptr/3.,$
        cmds_executed:            cmd_fifo_read_ptr/3.,$
        cmds_executed2:           swfo_data_select(ccsds_data,(d+16*2  )*8,16),$
        cmds_ignored:             swfo_data_select(ccsds_data,(d+17*2  )*8, 8),$
        cmds_unknown:             swfo_data_select(ccsds_data,(d+17*2+1)*8, 8),$
        cmds_invalid:             swfo_data_select(ccsds_data,(d+18*2  )*8, 8),$
        time_cmds_received:       swfo_data_select(ccsds_data,(d+18*2+1)*8, 8),$
        cmd_pause_remaining_100ms:swfo_data_select(ccsds_data,(d+19*2  )*8,16),$
        valid_rates:              float(swfo_stis_log_decomp(swfo_data_select(ccsds_data,(d+20*2+[0:5])*8,8))),$
        async_rates:              float(swfo_stis_log_decomp(swfo_data_select(ccsds_data,(d+23*2+[0:5])*8,8))),$
        nopeak_rates:             float(swfo_stis_log_decomp(swfo_data_select(ccsds_data,(d+26*2+[0:5])*8,8))),$
        event_timeout_rates:      float(swfo_stis_log_decomp(swfo_data_select(ccsds_data,(d+29*2+[0:5])*8,8))),$
        unknown_pattern_rates:    float(swfo_stis_log_decomp(swfo_data_select(ccsds_data,(d+32*2+[0:5])*8,8))),$
        negative_pulse_rates:     float(swfo_stis_log_decomp(swfo_data_select(ccsds_data,(d+35*2  )*8,8))),$
        science_events:           float(swfo_stis_log_decomp(swfo_data_select(ccsds_data,(d+35*2+1)*8,8))),$
        met_spare:                swfo_data_select(ccsds_data,(d+36*2  )*8, 8),$
        test_pulse_width_1us:     swfo_data_select(ccsds_data,(d+36*2+1)*8, 8),$
        pulses_remaining:         swfo_data_select(ccsds_data,(d+37*2  )*8,12),$
        board_id:                 swfo_data_select(ccsds_data,(d+37*2)*8+12,2),$
        self_tod_enable:          swfo_data_select(ccsds_data,(d+37*2)*8+14,1),$
        memory_page:              swfo_data_select(ccsds_data,(d+37*2)*8+15,1),$
        memory_address:           swfo_data_select(ccsds_data,(d+38*2  )*8,16),$
        expected_checksum1:       swfo_data_select(ccsds_data,(d+39*2  )*8,16),$
        expected_checksum0:       swfo_data_select(ccsds_data,(d+40*2  )*8,16),$
        checksum1:                swfo_data_select(ccsds_data,(d+41*2  )*8,16),$
        checksum0:                swfo_data_select(ccsds_data,(d+42*2  )*8,16),$
        bias_clock_period_2us:    swfo_data_select(ccsds_data,(d+43*2  )*8, 8),$
        edac_errors:              swfo_data_select(ccsds_data,(d+43*2+1)*8+[0:9]*4,4),$
        bus_timeout_counters:     swfo_data_select(ccsds_data,(d+46*2  )*8+[0:3]*4,4),$
        user_0e:                  swfo_data_select(ccsds_data,(d+47*2  )*8,16),$
        user_2d:                  swfo_data_select(ccsds_data,(d+48*2  )*8, 8),$
        reserved0:                swfo_data_select(ccsds_data,(d+48*2+1)*8, 4),$
        state_machine_errors:     swfo_data_select(ccsds_data,(d+48*2+1)*8+[1:13]*4,4),$
        first_cmd_id:             swfo_data_select(ccsds_data,(d+52*2  )*8, 8),$
        last_cmd_id:              swfo_data_select(ccsds_data,(d+52*2+1)*8, 8),$
        first_cmd_data:           swfo_data_select(ccsds_data,(d+53*2  )*8,16),$
        last_cmd_data:            swfo_data_select(ccsds_data,(d+54*2  )*8,16),$
        baseline_restore_ext1_us: swfo_data_select(ccsds_data,(d+55*2  )*8, 8),$
        baseline_restore_ext2_us: swfo_data_select(ccsds_data,(d+55*2+1)*8, 6),$
        baseline_restore_mode:    swfo_data_select(ccsds_data,(d+55*2)*8+14,2),$
        digi_filter_clock_cycles: swfo_data_select(ccsds_data,(d+56*2+[0:1])*8,8),$
        pulser_delay_clock_cycles:swfo_data_select(ccsds_data,(d+57*2  )*8+[0:2]*16,16),$
        reserved1:                swfo_data_select(ccsds_data,(d+60*2  )*8,10),$
        valid_enable_mask_bits:   swfo_data_select(ccsds_data,(d+60*2+1)*8+2,6),$
        reserved2:                swfo_data_select(ccsds_data,(d+61*2  )*8,16),$
        reserved3:                swfo_data_select(ccsds_data,(d+62*2  )*8,16),$
        reserved4:                swfo_data_select(ccsds_data,(d+63*2  )*8,16),$
        gap:ccsds.gap }
      valid_rates_pps=str2.valid_rates/float(str2.pps_period_100us)*1e4
      str3={valid_rates_pps:valid_rates_pps,valid_rates_total:total(str2.valid_rates)}
      str=create_struct(str1,str2,str3,ana_hkp)
      return,str
    endif

    if str1.fpga_rev ge 'B0'x then begin
      cmd_fifo_write_ptr=         swfo_data_select(ccsds_data,(d+0*2)*8+6, 13)
      cmd_fifo_read_ptr=          swfo_data_select(ccsds_data,(d+1*2)*8+3, 13)
      cmds_remaining=(fix(cmd_fifo_write_ptr)-fix(cmd_fifo_read_ptr))/3.
      if cmds_remaining lt 0 then cmds_remaining+=fifo_size/3.
      str2={$
        cmd_fifo_write_ptr:       cmd_fifo_write_ptr , $
        cmd_fifo_read_ptr:        cmd_fifo_read_ptr , $
        cmds_received:            cmd_fifo_write_ptr/3. , $
        cmds_executed:            cmd_fifo_read_ptr/3. , $
        cmds_remaining:           cmds_remaining , $
        pps_timeout_100ms:        swfo_data_select(ccsds_data,(d+ 0*2  )*8, 6),$
        user_0e:                  swfo_data_select(ccsds_data,(d+ 2*2  )*8,16),$
        cmds_invalid:             swfo_data_select(ccsds_data,(d+ 3*2  )*8, 8),$
        bias_clock_period_2us:    swfo_data_select(ccsds_data,(d+ 3*2+1)*8, 8),$
        memory_address:           swfo_data_select(ccsds_data,(d+ 4*2  )*8,16),$
        pps_counter:              swfo_data_select(ccsds_data,(d+ 5*2  )*8,16),$
        edac_nse_errors:          swfo_data_select(ccsds_data,(d+ 6*2  )*8+[0:1]*4,4),$
        science_events:           float(swfo_stis_log_decomp(swfo_data_select(ccsds_data,(d+ 6*2+1)*8,8))),$
        valid_rates:              float(swfo_stis_log_decomp(swfo_data_select(ccsds_data,(d+ 7*2+[0:5])*8,8))),$
        expected_checksum1:       swfo_data_select(ccsds_data,(d+10*2  )*8,16),$
        expected_checksum0:       swfo_data_select(ccsds_data,(d+11*2  )*8,16),$
        state_machine_errors4:    swfo_data_select(ccsds_data,(d+12*2  )*8+[0:3]*4,4),$
        bus_timeout_counters:     swfo_data_select(ccsds_data,(d+13*2  )*8+[0:3]*4,4),$
        edac_cmd_errors:          swfo_data_select(ccsds_data,(d+14*2  )*8+[0:3]*4,4),$
        cmds_ignored:             swfo_data_select(ccsds_data,(d+15*2  )*8, 8),$
        cmds_unknown:             swfo_data_select(ccsds_data,(d+15*2+1)*8, 8),$
        self_tod_enable:          swfo_data_select(ccsds_data,(d+16*2  )*8, 1),$
        memory_page:              swfo_data_select(ccsds_data,(d+16*2)*8+1, 1),$
        board_id:                 swfo_data_select(ccsds_data,(d+16*2)*8+2, 2),$
        pulses_remaining:         swfo_data_select(ccsds_data,(d+16*2)*8+4,12),$
        edac_sci_errors:          swfo_data_select(ccsds_data,(d+17*2  )*8+[0:3]*4,4),$
        state_machine_errors8:    swfo_data_select(ccsds_data,(d+18*2  )*8+[0:7]*4,4),$
        dac_values:               swfo_data_select(ccsds_data,(d+(20+[0:11])*2)*8,16),$
        time_cmds_received:       swfo_data_select(ccsds_data,(d+32*2  )*8, 8),$
        pps_period_100us:         swfo_data_select(ccsds_data,(d+33*2  )*8,16),$
        checksum1:                swfo_data_select(ccsds_data,(d+34*2  )*8,16),$
        checksum0:                swfo_data_select(ccsds_data,(d+35*2  )*8,16),$
        cmd_pause_remaining_100ms:swfo_data_select(ccsds_data,(d+36*2  )*8,16),$
        test_pulse_width_1us:     swfo_data_select(ccsds_data,(d+37*2  )*8, 8),$
        met_spare:                swfo_data_select(ccsds_data,(d+37*2+1)*8, 8),$
        user_2d:                  swfo_data_select(ccsds_data,(d+38*2  )*8, 8),$
        last_cmd_id:              swfo_data_select(ccsds_data,(d+38*2+1)*8, 8),$
        last_cmd_data:            swfo_data_select(ccsds_data,(d+39*2  )*8,16),$
        cmd_state_machine_errors: swfo_data_select(ccsds_data,(d+40*2  )*8, 8),$
        first_cmd_id:             swfo_data_select(ccsds_data,(d+40*2+1)*8, 8),$
        first_cmd_data:           swfo_data_select(ccsds_data,(d+41*2  )*8,16),$
        async_rates:              float(swfo_stis_log_decomp(swfo_data_select(ccsds_data,(d+42*2+[0:5])*8,8))),$
        baseline_restore_ext1_us: swfo_data_select(ccsds_data,(d+45*2  )*8, 8),$
        baseline_restore_ext2_us: swfo_data_select(ccsds_data,(d+45*2+1)*8, 6),$
        baseline_restore_mode:    swfo_data_select(ccsds_data,(d+45*2)*8+14,2),$
        negative_pulse_rates:     float(swfo_stis_log_decomp(swfo_data_select(ccsds_data,(d+46*2+1)*8, 8))),$
        cmds_executed2:           swfo_data_select(ccsds_data,(d+47*2  )*8,16),$
        nopeak_rates:             float(swfo_stis_log_decomp(swfo_data_select(ccsds_data,(d+48*2+[0:5])*8,8))),$
        event_timeout_rates:      float(swfo_stis_log_decomp(swfo_data_select(ccsds_data,(d+51*2+[0:5])*8,8))),$
        unknown_pattern_rates:    float(swfo_stis_log_decomp(swfo_data_select(ccsds_data,(d+54*2+[0:5])*8,8))),$
        digi_filter_clock_cycles: swfo_data_select(ccsds_data,(d+57*2+[0:1])*8,8),$
        valid_enable_mask_bits:   swfo_data_select(ccsds_data,(d+58*2+1)*8+2,6),$
        gap:ccsds.gap }
      valid_rates_pps=str2.valid_rates/float(str2.pps_period_100us)*1e4
      str3={valid_rates_pps:valid_rates_pps,valid_rates_total:total(str2.valid_rates)}
      str=create_struct(str1,str2,str3,ana_hkp)
      return,str
    endif

    if str1.fpga_rev ge 'AF'x then begin
      cmd_fifo_write_ptr=         swfo_data_select(ccsds_data,(d+0*2)*8+6, 13)
      cmd_fifo_read_ptr=          swfo_data_select(ccsds_data,(d+1*2)*8+3, 13)
      cmds_remaining=(fix(cmd_fifo_write_ptr)-fix(cmd_fifo_read_ptr))/3.
      if cmds_remaining lt 0 then cmds_remaining+=fifo_size/3.
      str2={$
        cmd_fifo_write_ptr:       cmd_fifo_write_ptr , $
        cmd_fifo_read_ptr:        cmd_fifo_read_ptr , $
        cmds_received:            cmd_fifo_write_ptr/3. , $
        cmds_executed:            cmd_fifo_read_ptr/3. , $
        cmds_remaining:           cmds_remaining , $
        pps_timeout_100ms:        swfo_data_select(ccsds_data,(d+ 0*2  )*8, 6),$
        user_0e:                  swfo_data_select(ccsds_data,(d+ 2*2  )*8,16),$
        cmds_invalid:             swfo_data_select(ccsds_data,(d+ 3*2  )*8, 8),$
        bias_clock_period_2us:    swfo_data_select(ccsds_data,(d+ 3*2+1)*8, 8),$
        memory_address:           swfo_data_select(ccsds_data,(d+ 4*2  )*8,16),$
        pps_counter:              swfo_data_select(ccsds_data,(d+ 5*2  )*8,16),$
        edac_nse_errors:          swfo_data_select(ccsds_data,(d+ 6*2  )*8+[0:1]*4,4),$
        science_events:           float(swfo_stis_log_decomp(swfo_data_select(ccsds_data,(d+ 6*2+1)*8,8))),$
        valid_rates:              float(swfo_stis_log_decomp(swfo_data_select(ccsds_data,(d+ 7*2+[0:5])*8,8))),$
        expected_checksum1:       swfo_data_select(ccsds_data,(d+10*2  )*8,16),$
        expected_checksum0:       swfo_data_select(ccsds_data,(d+11*2  )*8,16),$
        state_machine_errors4:    swfo_data_select(ccsds_data,(d+12*2  )*8+[0:3]*4,4),$
        bus_timeout_counters:     swfo_data_select(ccsds_data,(d+13*2  )*8+[0:3]*4,4),$
        edac_cmd_errors:          swfo_data_select(ccsds_data,(d+14*2  )*8+[0:3]*4,4),$
        cmds_ignored:             swfo_data_select(ccsds_data,(d+15*2  )*8, 8),$
        cmds_unknown:             swfo_data_select(ccsds_data,(d+15*2+1)*8, 8),$
        self_tod_enable:          swfo_data_select(ccsds_data,(d+16*2  )*8, 1),$
        memory_page:              swfo_data_select(ccsds_data,(d+16*2)*8+1, 1),$
        board_id:                 swfo_data_select(ccsds_data,(d+16*2)*8+2, 2),$
        pulses_remaining:         swfo_data_select(ccsds_data,(d+16*2)*8+4,12),$
        edac_sci_errors:          swfo_data_select(ccsds_data,(d+17*2  )*8+[0:3]*4,4),$
        state_machine_errors8:    swfo_data_select(ccsds_data,(d+18*2  )*8+[0:7]*4,4),$
        dac_values:               swfo_data_select(ccsds_data,(d+(20+[0:11])*2)*8,16),$
        time_cmds_received:       swfo_data_select(ccsds_data,(d+32*2  )*8, 8),$
        pps_period_100us:         swfo_data_select(ccsds_data,(d+33*2  )*8,16),$
        checksum1:                swfo_data_select(ccsds_data,(d+34*2  )*8,16),$
        checksum0:                swfo_data_select(ccsds_data,(d+35*2  )*8,16),$
        cmd_pause_remaining_100ms:swfo_data_select(ccsds_data,(d+36*2  )*8,16),$
        test_pulse_width_1us:     swfo_data_select(ccsds_data,(d+37*2  )*8, 8),$
        met_spare:                swfo_data_select(ccsds_data,(d+37*2+1)*8, 8),$
        user_2d:                  swfo_data_select(ccsds_data,(d+38*2  )*8, 8),$
        last_cmd_id:              swfo_data_select(ccsds_data,(d+38*2+1)*8, 8),$
        last_cmd_data:            swfo_data_select(ccsds_data,(d+39*2  )*8,16),$
        cmd_state_machine_errors: swfo_data_select(ccsds_data,(d+40*2  )*8, 8),$
        first_cmd_id:             swfo_data_select(ccsds_data,(d+40*2+1)*8, 8),$
        first_cmd_data:           swfo_data_select(ccsds_data,(d+41*2  )*8,16),$
        async_rates:              float(swfo_stis_log_decomp(swfo_data_select(ccsds_data,(d+42*2+[0:5])*8,8))),$
        baseline_restore_ext1_us: swfo_data_select(ccsds_data,(d+45*2  )*8, 8),$
        baseline_restore_ext2_us: swfo_data_select(ccsds_data,(d+45*2+1)*8, 6),$
        baseline_restore_mode:    swfo_data_select(ccsds_data,(d+45*2)*8+14,2),$
        negative_pulse_counter:   swfo_data_select(ccsds_data,(d+46*2  )*8,16),$
        cmds_executed2:           swfo_data_select(ccsds_data,(d+47*2  )*8,16),$
        nopeak_rates:             float(swfo_stis_log_decomp(swfo_data_select(ccsds_data,(d+48*2+[0:5])*8,8))),$
        event_timeout_rates:      float(swfo_stis_log_decomp(swfo_data_select(ccsds_data,(d+51*2+[0:5])*8,8))),$
        unknown_pattern_counters: float(swfo_stis_log_decomp(swfo_data_select(ccsds_data,(d+54*2+[0:5])*8,8))),$
        gap:ccsds.gap }
      valid_rates_pps=str2.valid_rates/float(str2.pps_period_100us)*1e4
      str3={valid_rates_pps:valid_rates_pps,valid_rates_total:total(str2.valid_rates)}
      str=create_struct(str1,str2,str3,ana_hkp)
      return,str
    endif
  endif

  if hkp_size eq 128 then begin
    if str1.fpga_rev ge 'AE'x then begin
      cmd_fifo_write_ptr=         swfo_data_select(ccsds_data,(d+0*2)*8+6, 13)
      cmd_fifo_read_ptr=          swfo_data_select(ccsds_data,(d+1*2)*8+3, 13)
      cmds_remaining=(fix(cmd_fifo_write_ptr)-fix(cmd_fifo_read_ptr))/3.
      if cmds_remaining lt 0 then cmds_remaining+=fifo_size/3.
      str2={$
        cmd_fifo_write_ptr:       cmd_fifo_write_ptr , $
        cmd_fifo_read_ptr:        cmd_fifo_read_ptr , $
        cmds_received:            cmd_fifo_write_ptr/3. , $
        cmds_executed:            cmd_fifo_read_ptr/3. , $
        cmds_remaining:           cmds_remaining , $
        pps_timeout_100ms:        swfo_data_select(ccsds_data,(d+ 0*2  )*8, 6),$
        user_0e:                  swfo_data_select(ccsds_data,(d+ 2*2  )*8,16),$
        cmds_invalid:             swfo_data_select(ccsds_data,(d+ 3*2  )*8, 8),$
        bias_clock_period_2us:    swfo_data_select(ccsds_data,(d+ 3*2+1)*8, 8),$
        memory_address:           swfo_data_select(ccsds_data,(d+ 4*2  )*8,16),$
        pps_counter:              swfo_data_select(ccsds_data,(d+ 5*2  )*8,16),$
        edac_nse_errors:          swfo_data_select(ccsds_data,(d+ 6*2  )*8+[0:1]*4,4),$
        science_events:           float(swfo_stis_log_decomp(swfo_data_select(ccsds_data,(d+ 6*2+1)*8,8))),$
        valid_rates:              float(swfo_stis_log_decomp(swfo_data_select(ccsds_data,(d+ 7*2)*8+[0:5]*8,8))),$
        expected_checksum1:       swfo_data_select(ccsds_data,(d+10*2  )*8,16),$
        expected_checksum0:       swfo_data_select(ccsds_data,(d+11*2  )*8,16),$
        state_machine_errors4:    swfo_data_select(ccsds_data,(d+12*2  )*8+[0:3]*4,4),$
        bus_timeout_counters:     swfo_data_select(ccsds_data,(d+13*2  )*8+[0:3]*4,4),$
        event_timeout_rate:       float(swfo_stis_log_decomp(swfo_data_select(ccsds_data,(d+14*2  )*8, 8))),$
        nopeak_rate:              float(swfo_stis_log_decomp(swfo_data_select(ccsds_data,(d+14*2+1)*8, 8))),$
        cmds_ignored:             swfo_data_select(ccsds_data,(d+15*2  )*8, 8),$
        cmds_unknown:             swfo_data_select(ccsds_data,(d+15*2+1)*8, 8),$
        self_tod_enable:          swfo_data_select(ccsds_data,(d+16*2  )*8, 1),$
        memory_page:              swfo_data_select(ccsds_data,(d+16*2)*8+1, 1),$
        board_id:                 swfo_data_select(ccsds_data,(d+16*2)*8+2, 2),$
        pulses_remaining:         swfo_data_select(ccsds_data,(d+16*2)*8+4,12),$
        edac_sci_errors:          swfo_data_select(ccsds_data,(d+17*2  )*8+[0:3]*4,4),$
        state_machine_errors8:    swfo_data_select(ccsds_data,(d+18*2  )*8+[0:7]*4,4),$
        dac_values:               swfo_data_select(ccsds_data,(d+(20+[0:11])*2)*8,16),$
        time_cmds_received:       swfo_data_select(ccsds_data,(d+32*2  )*8, 8),$
        pps_period_100us:         swfo_data_select(ccsds_data,(d+33*2  )*8,16),$
        checksum1:                swfo_data_select(ccsds_data,(d+34*2  )*8,16),$
        checksum0:                swfo_data_select(ccsds_data,(d+35*2  )*8,16),$
        cmd_pause_remaining_100ms:swfo_data_select(ccsds_data,(d+36*2  )*8,16),$
        test_pulse_width_1us:     swfo_data_select(ccsds_data,(d+37*2  )*8, 8),$
        met_spare:                swfo_data_select(ccsds_data,(d+37*2+1)*8, 8),$
        user_2d:                  swfo_data_select(ccsds_data,(d+38*2  )*8, 8),$
        last_cmd_id:              swfo_data_select(ccsds_data,(d+38*2+1)*8, 8),$
        last_cmd_data:            swfo_data_select(ccsds_data,(d+39*2  )*8,16),$
        cmd_state_machine_errors: swfo_data_select(ccsds_data,(d+40*2  )*8, 8),$
        first_cmd_id:             swfo_data_select(ccsds_data,(d+40*2+1)*8, 8),$
        first_cmd_data:           swfo_data_select(ccsds_data,(d+41*2  )*8,16),$
        async_rates:              float(swfo_stis_log_decomp(swfo_data_select(ccsds_data,(d+42*2)*8+[0:5]*8,8))),$
        baseline_restore_ext1_us: swfo_data_select(ccsds_data,(d+45*2  )*8, 8),$
        baseline_restore_ext2_us: swfo_data_select(ccsds_data,(d+45*2+1)*8, 6),$
        baseline_restore_mode:    swfo_data_select(ccsds_data,(d+45*2)*8+14,2),$
        unknown_pattern_counter:  swfo_data_select(ccsds_data,(d+46*2+[0:1])*8,8),$
        cmds_executed2:           swfo_data_select(ccsds_data,(d+47*2  )*8,16),$
        gap:ccsds.gap }
      valid_rates_pps=str2.valid_rates/float(str2.pps_period_100us)*1e4
      str3={valid_rates_pps:valid_rates_pps,valid_rates_total:total(str2.valid_rates)}
      str=create_struct(str1,str2,str3,ana_hkp)
      return,str
    endif
  endif

  if hkp_size eq 112 then begin
    if str1.fpga_rev ge 'AC'x then begin
      cmd_fifo_write_ptr=         swfo_data_select(ccsds_data,(d+0*2)*8+6, 13)
      cmd_fifo_read_ptr=          swfo_data_select(ccsds_data,(d+1*2)*8+3, 13)
      cmds_remaining=(fix(cmd_fifo_write_ptr)-fix(cmd_fifo_read_ptr))/3.
      if cmds_remaining lt 0 then cmds_remaining+=fifo_size/3.
      str2={$
        cmd_fifo_write_ptr:       cmd_fifo_write_ptr , $
        cmd_fifo_read_ptr:        cmd_fifo_read_ptr , $
        cmds_received:            cmd_fifo_write_ptr/3. , $
        cmds_executed:            cmd_fifo_read_ptr/3. , $
        cmds_remaining:           cmds_remaining , $
        pps_timeout_100ms:        swfo_data_select(ccsds_data,(d+ 0*2  )*8, 6),$
        user_0e:                  swfo_data_select(ccsds_data,(d+ 2*2  )*8,16),$
        cmds_invalid:             swfo_data_select(ccsds_data,(d+ 3*2  )*8, 8),$
        bias_clock_period_2us:    swfo_data_select(ccsds_data,(d+ 3*2+1)*8, 8),$
        memory_address:           swfo_data_select(ccsds_data,(d+ 4*2  )*8,16),$
        pps_counter:              swfo_data_select(ccsds_data,(d+ 5*2  )*8,16),$
        edac_nse_errors:          swfo_data_select(ccsds_data,(d+ 6*2  )*8+[0:1]*4,4),$
        science_events:           float(swfo_stis_log_decomp(swfo_data_select(ccsds_data,(d+ 6*2+1)*8,8))),$
        valid_rates:              float(swfo_stis_log_decomp(swfo_data_select(ccsds_data,(d+ 7*2)*8+[0:5]*8,8))),$
        expected_checksum1:       swfo_data_select(ccsds_data,(d+10*2  )*8,16),$
        expected_checksum0:       swfo_data_select(ccsds_data,(d+11*2  )*8,16),$
        state_machine_errors4:    swfo_data_select(ccsds_data,(d+12*2  )*8+[0:3]*4,4),$
        bus_timeout_counters:     swfo_data_select(ccsds_data,(d+13*2  )*8+[0:3]*4,4),$
        event_timeout_rate:       float(swfo_stis_log_decomp(swfo_data_select(ccsds_data,(d+14*2  )*8, 8))),$
        nopeak_rate:              float(swfo_stis_log_decomp(swfo_data_select(ccsds_data,(d+14*2+1)*8, 8))),$
        cmds_ignored:             swfo_data_select(ccsds_data,(d+15*2  )*8, 8),$
        cmds_unknown:             swfo_data_select(ccsds_data,(d+15*2+1)*8, 8),$
        self_tod_enable:          swfo_data_select(ccsds_data,(d+16*2  )*8, 1),$
        memory_page:              swfo_data_select(ccsds_data,(d+16*2)*8+1, 1),$
        board_id:                 swfo_data_select(ccsds_data,(d+16*2)*8+2, 2),$
        pulses_remaining:         swfo_data_select(ccsds_data,(d+16*2)*8+4,12),$
        edac_sci_errors:          swfo_data_select(ccsds_data,(d+17*2  )*8+[0:3]*4,4),$
        state_machine_errors8:    swfo_data_select(ccsds_data,(d+18*2  )*8+[0:7]*4,4),$
        dac_values:               swfo_data_select(ccsds_data,(d+(20+[0:11])*2)*8,16),$
        time_cmds_received:       swfo_data_select(ccsds_data,(d+32*2  )*8, 8),$
        unknown_pattern_counter:  swfo_data_select(ccsds_data,(d+32*2+1)*8+[0:1]*4,4),$
        pps_period_100us:         swfo_data_select(ccsds_data,(d+33*2  )*8,16),$
        checksum1:                swfo_data_select(ccsds_data,(d+34*2  )*8,16),$
        checksum0:                swfo_data_select(ccsds_data,(d+35*2  )*8,16),$
        cmd_pause_remaining_100ms:swfo_data_select(ccsds_data,(d+36*2  )*8,16),$
        test_pulse_width_1us:     swfo_data_select(ccsds_data,(d+37*2  )*8, 4),$
        cmd_state_machine_errors: swfo_data_select(ccsds_data,(d+37*2)*8+4, 4),$
        met_spare:                swfo_data_select(ccsds_data,(d+37*2+1)*8, 8),$
        user_2d:                  swfo_data_select(ccsds_data,(d+38*2  )*8, 8),$
        last_cmd_id:              swfo_data_select(ccsds_data,(d+38*2+1)*8, 8),$
        last_cmd_data:            swfo_data_select(ccsds_data,(d+39*2  )*8,16),$
        gap:ccsds.gap }
      valid_rates_pps=str2.valid_rates/float(str2.pps_period_100us)*1e4
      str3={valid_rates_pps:valid_rates_pps,valid_rates_total:total(str2.valid_rates)}
      str=create_struct(str1,str2,str3,ana_hkp)
      return,str
    endif

    if str1.fpga_rev ge 'A9'x then begin
      cmd_fifo_write_ptr=         swfo_data_select(ccsds_data,(d+0*2)*8+6, 13)
      cmd_fifo_read_ptr=          swfo_data_select(ccsds_data,(d+1*2)*8+3, 13)
      cmds_remaining=(fix(cmd_fifo_write_ptr)-fix(cmd_fifo_read_ptr))/3.
      if cmds_remaining lt 0 then cmds_remaining+=fifo_size/3.
      str2={$
        cmd_fifo_write_ptr:       cmd_fifo_write_ptr , $
        cmd_fifo_read_ptr:        cmd_fifo_read_ptr , $
        cmds_received:            cmd_fifo_write_ptr/3. , $
        cmds_executed:            cmd_fifo_read_ptr/3. , $
        cmds_remaining:           cmds_remaining , $
        pps_timeout_100ms:        swfo_data_select(ccsds_data,(d+ 0*2  )*8, 6),$
        user_0e:                  swfo_data_select(ccsds_data,(d+ 2*2  )*8,16),$
        cmds_invalid:             swfo_data_select(ccsds_data,(d+ 3*2  )*8, 8),$
        bias_clock_period_2us:    swfo_data_select(ccsds_data,(d+ 3*2+1)*8, 8),$
        memory_address:           swfo_data_select(ccsds_data,(d+ 4*2  )*8,16),$
        pps_counter:              swfo_data_select(ccsds_data,(d+ 5*2  )*8,16),$
        edac_nse_errors:          swfo_data_select(ccsds_data,(d+ 6*2  )*8+[0:1]*4,4),$
        science_events:           float(swfo_stis_log_decomp(swfo_data_select(ccsds_data,(d+ 6*2+1)*8,8))),$
        valid_rates:              float(swfo_stis_log_decomp(swfo_data_select(ccsds_data,(d+ 7*2)*8+[0:5]*8,8))),$
        expected_checksum1:       swfo_data_select(ccsds_data,(d+10*2  )*8,16),$
        expected_checksum0:       swfo_data_select(ccsds_data,(d+11*2  )*8,16),$
        state_machine_errors4:    swfo_data_select(ccsds_data,(d+12*2  )*8+[0:3]*4,4),$
        bus_timeout_counters:     swfo_data_select(ccsds_data,(d+13*2  )*8+[0:3]*4,4),$
        event_timeout_rate:       float(swfo_stis_log_decomp(swfo_data_select(ccsds_data,(d+14*2  )*8, 8))),$
        nopeak_rate:              float(swfo_stis_log_decomp(swfo_data_select(ccsds_data,(d+14*2+1)*8, 8))),$
        cmds_ignored:             swfo_data_select(ccsds_data,(d+15*2  )*8, 8),$
        cmds_unknown:             swfo_data_select(ccsds_data,(d+15*2+1)*8, 8),$
        self_tod_enable:          swfo_data_select(ccsds_data,(d+16*2  )*8, 1),$
        memory_page:              swfo_data_select(ccsds_data,(d+16*2)*8+1, 1),$
        board_id:                 swfo_data_select(ccsds_data,(d+16*2)*8+2, 2),$
        pulses_remaining:         swfo_data_select(ccsds_data,(d+16*2)*8+4,12),$
        edac_sci_errors:          swfo_data_select(ccsds_data,(d+17*2  )*8+[0:3]*4,4),$
        state_machine_errors8:    swfo_data_select(ccsds_data,(d+18*2  )*8+[0:7]*4,4),$
        dac_values:               swfo_data_select(ccsds_data,(d+(20+[0:11])*2)*8,16),$
        time_cmds_received:       swfo_data_select(ccsds_data,(d+32*2  )*8, 8),$
        first_cmd_id:             swfo_data_select(ccsds_data,(d+32*2+1)*8, 8),$
        pps_period_100us:         swfo_data_select(ccsds_data,(d+33*2  )*8,16),$
        checksum1:                swfo_data_select(ccsds_data,(d+34*2  )*8,16),$
        checksum0:                swfo_data_select(ccsds_data,(d+35*2  )*8,16),$
        cmd_pause_remaining_100ms:swfo_data_select(ccsds_data,(d+36*2  )*8,16),$
        state_machine_errors2:    swfo_data_select(ccsds_data,(d+37*2  )*8+[0:1]*4,4),$
        met_spare:                swfo_data_select(ccsds_data,(d+37*2+1)*8, 8),$
        user_2d:                  swfo_data_select(ccsds_data,(d+38*2  )*8, 8),$
        last_cmd_id:              swfo_data_select(ccsds_data,(d+38*2+1)*8, 8),$
        last_cmd_data:            swfo_data_select(ccsds_data,(d+39*2  )*8,16),$
        gap:ccsds.gap }
      valid_rates_pps=str2.valid_rates/float(str2.pps_period_100us)*1e4
      str3={valid_rates_pps:valid_rates_pps,valid_rates_total:total(str2.valid_rates)}
      str=create_struct(str1,str2,str3,ana_hkp)
      return,str
    endif

    if str1.fpga_rev ge 'A8'x then begin
      cmd_fifo_write_ptr=         swfo_data_select(ccsds_data,(d+0*2)*8+6, 13)
      cmd_fifo_read_ptr=          swfo_data_select(ccsds_data,(d+1*2)*8+3, 13)
      cmds_remaining=(fix(cmd_fifo_write_ptr)-fix(cmd_fifo_read_ptr))/3.
      if cmds_remaining lt 0 then cmds_remaining+=fifo_size/3.
      str2={$
        cmd_fifo_write_ptr:       cmd_fifo_write_ptr , $
        cmd_fifo_read_ptr:        cmd_fifo_read_ptr , $
        cmds_received:            cmd_fifo_write_ptr/3. , $
        cmds_executed:            cmd_fifo_read_ptr/3. , $
        cmds_remaining:           cmds_remaining , $
        pps_timeout_100ms:        swfo_data_select(ccsds_data,(d+ 0*2  )*8, 6),$
        user_0e:                  swfo_data_select(ccsds_data,(d+ 2*2  )*8,16),$
        cmds_invalid:             swfo_data_select(ccsds_data,(d+ 3*2  )*8, 8),$
        bias_clock_period_2us:    swfo_data_select(ccsds_data,(d+ 3*2+1)*8, 8),$
        memory_address:           swfo_data_select(ccsds_data,(d+ 4*2  )*8,16),$
        pps_counter:              swfo_data_select(ccsds_data,(d+ 5*2  )*8,16),$
        science_events:           float(swfo_stis_log_decomp(swfo_data_select(ccsds_data,(d+ 6*2  )*8,16))),$
        valid_rates:              float(swfo_stis_log_decomp(swfo_data_select(ccsds_data,(d+[7:12]*2)*8,16))),$
        bus_timeout_counters:     swfo_data_select(ccsds_data,(d+13*2  )*8+4*[0:3],4),$
        event_timeout_counter:    swfo_data_select(ccsds_data,(d+14*2  )*8, 8),$
        nopeak_counter:           swfo_data_select(ccsds_data,(d+14*2+1)*8, 8),$
        cmds_ignored:             swfo_data_select(ccsds_data,(d+15*2  )*8, 8),$
        cmds_unknown:             swfo_data_select(ccsds_data,(d+15*2+1)*8, 8),$
        self_tod_enable:          swfo_data_select(ccsds_data,(d+16*2  )*8, 1),$
        memory_page:              swfo_data_select(ccsds_data,(d+16*2)*8+1, 1),$
        board_id:                 swfo_data_select(ccsds_data,(d+16*2)*8+2, 2),$
        pulses_remaining:         swfo_data_select(ccsds_data,(d+16*2)*8+4,12),$
        edac_errors:              swfo_data_select(ccsds_data,(d+17*2+[0:5])*8, 8),$    ;all edac error counters
        dac_values:               swfo_data_select(ccsds_data,(d+(20+[0:11])*2)*8,16),$ ;all 12 dac channels
        time_cmds_received:       swfo_data_select(ccsds_data,(d+32*2  )*8, 8),$
        first_cmd_id:             swfo_data_select(ccsds_data,(d+32*2+1)*8, 8),$
        pps_period_100us:         swfo_data_select(ccsds_data,(d+33*2  )*8,16),$
        checksum1:                swfo_data_select(ccsds_data,(d+34*2  )*8,16),$
        checksum0:                swfo_data_select(ccsds_data,(d+35*2  )*8,16),$
        cmd_pause_remaining_100ms:swfo_data_select(ccsds_data,(d+36*2  )*8,16),$
        fpga_state_machine_errors:swfo_data_select(ccsds_data,(d+37*2  )*8, 8),$
        met_spare:                swfo_data_select(ccsds_data,(d+37*2+1)*8, 8),$
        user_2d:                  swfo_data_select(ccsds_data,(d+38*2  )*8, 8),$
        last_cmd_id:              swfo_data_select(ccsds_data,(d+38*2+1)*8, 8),$
        last_cmd_data:            swfo_data_select(ccsds_data,(d+39*2  )*8,16),$
        gap:ccsds.gap }
      valid_rates_pps=str2.valid_rates/float(str2.pps_period_100us)*1e4
      str3={valid_rates_pps:valid_rates_pps,valid_rates_total:total(str2.valid_rates)}
      str=create_struct(str1,str2,str3,ana_hkp)
      return,str
    endif

    if str1.fpga_rev ge 'A5'x then begin
      cmd_fifo_write_ptr=         swfo_data_select(ccsds_data,(d+0*2)*8+6, 13)
      cmd_fifo_read_ptr=          swfo_data_select(ccsds_data,(d+1*2)*8+3, 13)
      cmds_remaining=(fix(cmd_fifo_write_ptr)-fix(cmd_fifo_read_ptr))/3.
      if cmds_remaining lt 0 then cmds_remaining+=fifo_size/3.
      str2={$
        cmd_fifo_write_ptr:       cmd_fifo_write_ptr , $
        cmd_fifo_read_ptr:        cmd_fifo_read_ptr , $
        cmds_received:            cmd_fifo_write_ptr/3. , $
        cmds_executed:            cmd_fifo_read_ptr/3. , $
        cmds_remaining:           cmds_remaining , $
        pps_timeout_100ms:        swfo_data_select(ccsds_data,(d+ 0*2  )*8, 6),$
        user_0e:                  swfo_data_select(ccsds_data,(d+ 2*2  )*8,16),$
        cmds_invalid:             swfo_data_select(ccsds_data,(d+ 3*2  )*8, 8),$
        bias_clock_period_2us:    swfo_data_select(ccsds_data,(d+ 3*2+1)*8, 8),$
        memory_address:           swfo_data_select(ccsds_data,(d+ 4*2  )*8,16),$
        pps_counter:              swfo_data_select(ccsds_data,(d+ 5*2  )*8,16),$
        event_counter:            swfo_data_select(ccsds_data,(d+ 6*2  )*8,16),$
        rates_counter:            swfo_data_select(ccsds_data,(d+[7:12]*2)*8,16),$
        bus_timeout_counters:     swfo_data_select(ccsds_data,(d+13*2  )*8+4*[0:3],4),$
        event_timeout_counter:    swfo_data_select(ccsds_data,(d+14*2  )*8, 8),$
        nopeak_counter:           swfo_data_select(ccsds_data,(d+14*2+1)*8, 8),$
        cmds_ignored:             swfo_data_select(ccsds_data,(d+15*2  )*8, 8),$
        cmds_unknown:             swfo_data_select(ccsds_data,(d+15*2+1)*8, 8),$
        self_tod_enable:          swfo_data_select(ccsds_data,(d+16*2  )*8, 1),$
        memory_page:              swfo_data_select(ccsds_data,(d+16*2)*8+1, 1),$
        board_id:                 swfo_data_select(ccsds_data,(d+16*2)*8+2, 2),$
        pulses_remaining:         swfo_data_select(ccsds_data,(d+16*2)*8+4,12),$
        edac_errors:              swfo_data_select(ccsds_data,(d+17*2+[0:5])*8, 8),$    ;all error counters
        dac_values:               swfo_data_select(ccsds_data,(d+(20+[0:11])*2)*8,16),$ ;all 12 dac channels
        time_cmds_received:       swfo_data_select(ccsds_data,(d+32*2  )*8, 8),$
        first_cmd_id:             swfo_data_select(ccsds_data,(d+32*2+1)*8, 8),$
        pps_period_100us:         swfo_data_select(ccsds_data,(d+33*2  )*8,16),$
        checksum1:                swfo_data_select(ccsds_data,(d+34*2  )*8,16),$
        checksum0:                swfo_data_select(ccsds_data,(d+35*2  )*8,16),$
        cmd_pause_remaining_100ms:swfo_data_select(ccsds_data,(d+36*2  )*8,16),$
        fpga_state_machine_errors:swfo_data_select(ccsds_data,(d+37*2  )*8, 8),$
        met_spare:                swfo_data_select(ccsds_data,(d+37*2+1)*8, 8),$
        user_2d:                  swfo_data_select(ccsds_data,(d+38*2  )*8, 8),$
        last_cmd_id:              swfo_data_select(ccsds_data,(d+38*2+1)*8, 8),$
        last_cmd_data:            swfo_data_select(ccsds_data,(d+39*2  )*8,16),$
        gap:ccsds.gap }
      str=create_struct(str1,str2,ana_hkp)
      return,str
    endif

    if str1.fpga_rev ge '9F'x then begin
      cmd_fifo_write_ptr=       swfo_data_select(ccsds_data,(d+0*2)*8+3, 13 )
      cmd_fifo_read_ptr=        swfo_data_select(ccsds_data,(d+1*2)*8+3, 13 )
      cmds_remaining=(fix(cmd_fifo_write_ptr)-fix(cmd_fifo_read_ptr))/3.
      if cmds_remaining lt 0 then cmds_remaining+=fifo_size/3.
      str2={$
        cmd_fifo_write_ptr:     cmd_fifo_write_ptr , $
        cmd_fifo_read_ptr:      cmd_fifo_read_ptr , $
        cmds_received:          cmd_fifo_write_ptr/3. , $
        cmds_executed:          cmd_fifo_read_ptr/3. , $
        cmds_remaining:         cmds_remaining , $
        user_0e:                swfo_data_select(ccsds_data,(d+ 2*2  )*8,16),$
        cmds_invalid:           swfo_data_select(ccsds_data,(d+ 3*2  )*8, 8),$
        bias_clock_period_2us:  swfo_data_select(ccsds_data,(d+ 3*2+1)*8, 8),$
        memory_address:         swfo_data_select(ccsds_data,(d+ 4*2  )*8,16),$
        pps_counter:            swfo_data_select(ccsds_data,(d+ 5*2  )*8,16),$
        event_counter:          swfo_data_select(ccsds_data,(d+ 6*2  )*8,16),$
        rates_counter:          swfo_data_select(ccsds_data,(d+[7:12]*2)*8,16),$
        bus_timeout_counters:   swfo_data_select(ccsds_data,(d+13*2  )*8+4*[0:3],4),$
        det_timeout_counter:    swfo_data_select(ccsds_data,(d+14*2  )*8, 8),$
        nopeak_counter:         swfo_data_select(ccsds_data,(d+14*2+1)*8, 8),$
        cmds_ignored:           swfo_data_select(ccsds_data,(d+15*2  )*8, 8),$
        cmds_unknown:           swfo_data_select(ccsds_data,(d+15*2+1)*8, 8),$
        memory_page:            swfo_data_select(ccsds_data,(d+16*2)*8+1, 1),$
        board_id:               swfo_data_select(ccsds_data,(d+16*2)*8+2, 2),$
        pulses_remaining:       swfo_data_select(ccsds_data,(d+16*2)*8+4,12),$
        edac_errors:            swfo_data_select(ccsds_data,(d+17*2+[0:5])*8, 8),$    ;all error counters
        dac_values:             swfo_data_select(ccsds_data,(d+(20+[0:11])*2)*8,16),$ ;all 12 dac channels
        time_cmds_received:     swfo_data_select(ccsds_data,(d+32*2  )*8, 8),$
        first_cmd_id:           swfo_data_select(ccsds_data,(d+32*2+1)*8, 8),$
        pps_bits:               swfo_data_select(ccsds_data,(d+33*2  )*8, 2),$
        ;pps_missing:            swfo_data_select(ccsds_data,(d+33*2  )*8, 1),$
        ;pps_self_enable:        swfo_data_select(ccsds_data,(d+33*2)*8+1, 1),$
        pps_period_100us:       swfo_data_select(ccsds_data,(d+33*2)*8+2,14),$
        checksum1:              swfo_data_select(ccsds_data,(d+34*2  )*8,16),$
        checksum0:              swfo_data_select(ccsds_data,(d+35*2  )*8,16),$
        cmd_pause_remaining:    swfo_data_select(ccsds_data,(d+36*2  )*8,16),$
        sm_err_cnt:             swfo_data_select(ccsds_data,(d+37*2  )*8, 8),$
        met_spare:              swfo_data_select(ccsds_data,(d+37*2+1)*8, 8),$
        user_2d:                swfo_data_select(ccsds_data,(d+38*2  )*8, 8),$
        last_cmd_id:            swfo_data_select(ccsds_data,(d+38*2+1)*8, 8),$
        last_cmd_data:          swfo_data_select(ccsds_data,(d+39*2  )*8,16),$
        gap:ccsds.gap }
      str=create_struct(str1,str2,ana_hkp)
      return,str
    endif

    if str1.fpga_rev ge '99'x then begin
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
        bias_clock_period_2us:  swfo_data_select(ccsds_data,(d+ 3*2+1)*8, 8),$
        memory_address:         swfo_data_select(ccsds_data,(d+ 4*2  )*8,16),$
        pps_counter:            swfo_data_select(ccsds_data,(d+ 5*2  )*8,16),$
        event_counter:          swfo_data_select(ccsds_data,(d+ 6*2  )*8,16),$
        rates_counter:          swfo_data_select(ccsds_data,(d+[7:12]*2)*8,16),$
        bus_timeout_counters:   swfo_data_select(ccsds_data,(d+13*2  )*8+4*[0:3],4),$
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
        edac_errors:            swfo_data_select(ccsds_data,(d+17*2+[0:5])*8, 8),$    ;all error counters
        dac_values:             swfo_data_select(ccsds_data,(d+(20+[0:11])*2)*8,16),$ ;all 12 dac channels
        time_cmds_received:     swfo_data_select(ccsds_data,(d+32*2  )*8, 8),$
        first_cmd_id:           swfo_data_select(ccsds_data,(d+32*2+1)*8, 8),$
        first_cmd_data:         swfo_data_select(ccsds_data,(d+33*2  )*8,16),$
        checksum1:              swfo_data_select(ccsds_data,(d+34*2  )*8,16),$
        checksum0:              swfo_data_select(ccsds_data,(d+35*2  )*8,16),$
        cmd_pause_remaining:    swfo_data_select(ccsds_data,(d+36*2  )*8,16),$
        sm_err_cnt:             swfo_data_select(ccsds_data,(d+37*2  )*8, 8),$
        met_spare:              swfo_data_select(ccsds_data,(d+37*2+1)*8, 8),$
        user_2d:                swfo_data_select(ccsds_data,(d+38*2  )*8, 8),$
        last_cmd_id:            swfo_data_select(ccsds_data,(d+38*2+1)*8, 8),$
        last_cmd_data:          swfo_data_select(ccsds_data,(d+39*2  )*8,16),$
        gap:ccsds.gap }
      str=create_struct(str1,str2,ana_hkp)
      return,str
    endif

    if str1.fpga_rev ge '97'x then begin
      biasclk_period765=        swfo_data_select(ccsds_data,(d+ 0*2 )*8, 3  )
      biasclk_period432=        swfo_data_select(ccsds_data,(d+ 1*2 )*8, 3  )
      biasclk_period10 =        swfo_data_select(ccsds_data,(d+16*2 )*8, 2  )
      cmd_fifo_write_ptr=       swfo_data_select(ccsds_data,(d+0*2)*8+3, 13 )
      cmd_fifo_read_ptr=        swfo_data_select(ccsds_data,(d+1*2)*8+3, 13 )
      cmds_remaining=(fix(cmd_fifo_write_ptr)-fix(cmd_fifo_read_ptr))/3.
      if cmds_remaining lt 0 then cmds_remaining+=8190/3.
      str2={$
        bias_clock_period_2us:  biasclk_period10+ishft(biasclk_period432,2)+ishft(biasclk_period765,5) , $
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
      return,str
    endif

    if str1.fpga_rev ge '93'x then begin
      str2={$
        fpga_rev0:              swfo_data_select(ccsds_data,(d+2*0  )*8, 8  ) , $
        user_2d:                swfo_data_select(ccsds_data,(d+2*0+1)*8, 8  ) , $
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
      return,str
    endif

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
    return,str
    ;   if str.apid eq 863 then printdat,str
  endif

  if  ccsds.time  lt 1.6297680e+09 then begin
    dprint,dlevel=2,'Obsolete'
    if ~keyword_set(use_obsolete) then return,!null
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
    return,str
  endif

  if 0 && ccsds.time lt (1.6297680e+09 -1800.) then begin
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
    return,str
  endif
  return,!null

end


pro swfo_stis_hkp_apdat::handler2_test,struct_stis_sci_level_0b  ,source_dict=source_dict
  if  ~obj_valid(self.level_0b) then begin
    dprint,'Creating Science level 0B'
    self.level_0b = dynamicarray(name='Science_L0b')
    first_level_0b = 1
  endif

  if  ~obj_valid(self.level_1a) then begin
    dprint,'Creating Science level 1a'
    self.level_1a = dynamicarray(name='Science_L1a')
    first_level_1a = 1
  endif

  sciobj = swfo_apdat('stis_sci')
  nseobj = swfo_apdat('stis_nse')
  hkpobj = swfo_apdat('stis_hkp2')

  sci_last = sciobj.last_data    ; this should be identical to struct_stis_sci_level_0b
  ;  nse_last = nseobj.last_data
  ;  hkp_last = hkpobj.last_data

  res = self.file_resolution

  if res gt 0 && isa(sci_last) && sci_last.time gt (self.lastfile_time + res) then begin
    makefile =1
    trange = self.lastfile_time + [0,res]
    self.lastfile_time = floor( sci_last.time /res) * res
    dprint,dlevel=2,'Make new file ',time_string(self.lastfile_time,prec=3)+'  '+time_string(sci_last.time,prec=3)
  endif else makefile = 0

  ;  if isa(self.level_0b,'dynamicarray') then begin
  ;    self.level_0b.append, sci_last
  ;    if makefile then   self.ncdf_make_file,ddata=self.level_0b, trange=trange,type='L0b'
  ;  endif

  ;  if isa(self.level_0b_all,'dynamicarray') then begin
  ;    if makefile then   self.ncdf_make_file,ddata=self.level_0b_all, trange=trange,type='_all_L0b'
  ;    ignore_tags = ['pkt_size','MET_RAW']
  ;    sci_all = {time:0d,nse_reltime:0d, hkp_reltime:0d}
  ;    extract_tags, sci_all, sci_last, except=ignore_tags
  ;    extract_tags, sci_all, nse_last, except=ignore_tags, /preserve
  ;    extract_tags, sci_all, hkp_last, except=ignore_tags, /preserve
  ;    sci_all.nse_reltime = sci_last.time - struct_value(nse_last,'time',default = !values.d_nan )
  ;    sci_all.nse_reltime = sci_last.time - struct_value(hkp_last,'time',default = !values.d_nan )
  ;    self.level_0b.append, sci_all
  ;  endif

  if isa(self.level_0b,'dynamicarray') then begin
    ;struct_stis_sci_level_1a = swfo_stis_sci_level_1a(sci_last)
    self.level_0b.append, struct_stis_sci_level_0b
    if keyword_set(first_level_0b) then begin
      ;store_data,'stis_L0B',data = self.level_0b,tagnames = '*'  ;,val_tag='_NRG'
      ;options,'stis_L0B_COUNTS',spec=1
      store_data,'swfo_stis',data = self.level_0b,tagnames = '*'  ;,val_tag='_NRG'
      options,'swfo_stis_COUNTS',spec=1
    endif
    if makefile then  begin
      self.ncdf_make_file,ddata=self.level_0b, trange=trange,type='L0B'
    endif
  endif



  if isa(self.level_1a,'dynamicarray') then begin
    struct_stis_sci_level_1a = swfo_stis_sci_level_1a(sci_last)
    self.level_1a.append, struct_stis_sci_level_1a
    if keyword_set(first_level_1a) then begin
      store_data,'stis_L1A',data = self.level_1a,tagnames = 'SPEC_??',val_tag='_NRG'
      options,'stis_L1B_SPEC_??',spec=1
    endif
    if makefile then begin
      self.ncdf_make_file,ddata=self.level_1a, trange=trange,type='L1A'
    endif
  endif


  if isa(self.level_1b,'dynamicarray') then begin
    struct_stis_sci_level_1b = swfo_stis_sci_level_1b(sci_last)
    self.level_1b.append, struct_stis_sci_level_1b
    if makefile then begin
      self.ncdf_make_file,ddata=self.level_1b, trange=trange,type='L1B'
    endif
  endif

end





PRO swfo_stis_hkp_apdat__define

  void = {swfo_stis_hkp_apdat, $
    inherits swfo_gen_apdat, $    ; superclass
    flag: 0 $
  }
END


