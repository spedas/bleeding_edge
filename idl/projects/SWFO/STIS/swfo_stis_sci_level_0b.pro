; $LastChangedBy: dav $
; $LastChangedDate:  $
; $LastChangedRevision:  $
; $URL:  $


function swfo_stis_sci_level_0b,sci_dat,nse_dat,hkp_dat  ;,format=format,reset=reset,cal=cal

  output = !null
  nan = !values.f_nan
  dnan = !values.d_nan

  nd = n_elements(sci_dat)

  if n_params() eq 0 then return,l0b

  if ~isa(sci_dat) || ~isa(nse_dat) || ~isa(hkp_dat) then begin
    dprint,'bad data in L0b'
    return,!null  ; l0b
  endif

  if nd gt 1 then begin
    output = replicate(l0b,nd)
    for i=0l,nd-1 do begin
      output[i] = swfo_stis_sci_level_0b(sci_dat[i],nse_dat[i],hkp_dat[i])
    endfor
    return, output
  endif

  if 1 then begin
    ; stop
    output = { swfo_stis_l0b, $
      time:0.d  ,$
      time_met: 0d, $
      time_gr:  0d, $
      time_unix:  0d, $
      tod_day: 0ul, $
      tod_millisec: 0ul, $
      tod_microsec: 0ul, $
      ; relative time differences between
      ; science and housekeeping/noise packets
      hkp_offset: 0d,$
      nse_offset: 0d,$
      ; these headers are invariant across nse/hkp/sci
      fpga_rev:   0b,  $
      user_09:   0b,  $
      ; from ccsds packets:
      sci_time_delta: 0d, $
      hkp_time_delta: 0d, $
      nse_time_delta: 0d, $
      sci_delaytime: 0d, $
      hkp_delaytime: 0d, $
      nse_delaytime: 0d, $
      sci_apid:   0u,  $
      hkp_apid:   0u,  $
      nse_apid:   0u,  $
      sci_seqn:      0u,  $
      hkp_seqn:      0u,  $
      nse_seqn:      0u,  $
      sci_seqn_delta:  0u,  $
      hkp_seqn_delta:  0u,  $
      nse_seqn_delta:  0u,  $
      sci_packet_size:  0ul,  $
      hkp_packet_size:  0ul,  $
      nse_packet_size:  0ul,  $
      ; from the header info:
      ptcu_bits: 0b, $
      hkp_ptcu_bits: 0b, $
      nse_ptcu_bits: 0b, $
      sci_time_res: 0u, $
      hkp_time_res: 0u, $
      nse_time_res: 0u, $
      decimation_factor_bits: 0b, $
      hkp_decimation_factor_bits: 0b, $
      nse_decimation_factor_bits: 0b, $
      pulser_bits: 0b, $
      hkp_pulser_bits: 0b, $
      nse_pulser_bits: 0b, $
      detector_bits: 0b, $
      hkp_detector_bits: 0b, $
      nse_detector_bits: 0b, $
      aaee_bits: 0b, $
      hkp_aaee_bits: 0b, $
      nse_aaee_bits: 0b, $
      noise_bits: 0u, $
      hkp_noise_bits: 0u, $
      nse_noise_bits: 0u, $
      ; set in swfo_stis_ccsds_header_decom as 1 + time_res
      duration:  0u, $
      hkp_duration:  0u, $
      nse_duration:  0u, $
      ; These are set in swfo_stis_ccsds_header_decom,
      ; but currently fixed.
      ; sci_packet_checksum_reported:  0u,  $
      ; hkp_packet_checksum_reported:  0u,  $
      ; nse_packet_checksum_reported:  0u,  $
      ; sci_packet_checksum_calculated:  0u,  $
      ; hkp_packet_checksum_calculated:  0u,  $
      ; nse_packet_checksum_calculated:  0u,  $
      ; sci_packet_checksum_match:  0b,  $
      ; hkp_packet_checksum_match:  0b,  $
      ; nse_packet_checksum_match:  0b,  $
      sci_gap:  0b,  $
      hkp_gap:  0b,  $
      nse_gap:  0b,  $
      ; hkp_data:
      dac_values: replicate(0u,12), $
      pps_counter:  0u, $
      pps_period_100us:  0u, $
      pps_timeout_100ms:  0b, $
      cmd_fifo_write_ptr:  0u, $
      cmd_fifo_read_ptr:  0u, $
      cmds_remaining: 0u, $ ; not currently in spreadsheet
      cmds_received: 0u, $ ; not currently in spreadsheet
      cmds_executed: 0u, $ ; not currently in spreadsheet
      cmds_executed2:  0u, $ ; u? not b?
      cmds_ignored: 0b, $
      cmds_unknown: 0b, $
      cmds_invalid: 0b, $
      time_cmds_received: 0b, $
      cmd_pause_remaining_100ms: 0u, $
      async_rates: replicate(0., 6), $
      valid_rates: replicate(0., 6), $
      event_timeout_rates: replicate(0., 6), $
      valid_timeout_rates: replicate(0., 6), $
      nopeak_rates: replicate(0., 6), $
      unknown_pattern_rates: replicate(0., 6), $
      negative_pulse_rates: 0., $
      science_events: 0., $
      met_spare: 0b, $
      test_pulse_width_1us: 0b, $
      pulses_remaining: 0u, $
      board_id: 0b, $
      self_tod_enable: 0b, $
      memory_page: 0b, $
      memory_address: 0u, $
      expected_checksum1: 0u, $
      expected_checksum0: 0u, $
      checksum1: 0u, $
      checksum0: 0u, $
      bias_clock_period_2us: 0b, $
      edac_errors: replicate(0b, 10),$
      bus_timeout_counters: replicate(0b, 4),$
      user_0e: 0u, $
      coincidence_window_clkcyc: 0b, $
      noise_delay_1us: 0b, $
      state_machine_errors: replicate(0b, 13),$
      first_cmd_id: 0b, $
      last_cmd_id: 0b, $
      first_cmd_data: 0u, $
      last_cmd_data: 0u, $
      cmd_packets_received: 0b, $
      blr_test_pulse_1us: 0b, $
      blr_extension_half_us: 0b, $
      baseline_restore_mode: 0b, $
      digi_filter_clock_cycles: replicate(0b, 2),$
      pulser_delay_clock_cycles: replicate(0b, 3),$
      valid_enable_mask_bits: 0b, $
      sci_mode_bits: 0b, $
      timeouts_2us: replicate(0b, 3),$
      sci_resolution: 0b, $
      sci_translate: 0u, $
      adc_bias_voltage: 0., $
      temp_dap: 0., $
      voltage_1p5_vd: 0., $
      voltage_3p3_vd: 0., $
      voltage_5p0_vd: 0., $
      voltage_dfe_pos_va: 0., $
      voltage_dfe_neg_va: 0., $
      adc_bias_current: 0., $
      bias_current_microamps: 0., $  ; not currently in spreadsheet
      temp_sensor1: 0., $
      temp_sensor2: 0., $
      adc_baselines: replicate(0., 6),$
      ; adc_voltages: replicate(0., 5),$  ; not currently in spreadsheet
      ; adc_temps: replicate(0., 3),$  ; not currently in spreadsheet
      ; mux_all: replicate(0., 16),$ ; not currently in spreadsheet
      ; hkp_replay: 0b, $ ; not currently in spreadsheet, only for IDL - useful for debugging, different var names for replay
      ; hkp_valid: 0b, $ ; not currently in spreadsheet, only for IDL - placeholder
      ; sci data
      sci_nbins:      672l, $
      sci_counts: replicate(nan, 672),$
      ; nse data
      nse_histogram: replicate(0u, 60), $
      nse_counts: replicate(0u, 60), $
      quality_bits:  0ul}

    ; hkp: from swfo_stis_hkp_apdat__define.pro
    output.dac_values = hkp_dat.dac_values
    output.pps_counter = hkp_dat.pps_counter
    output.pps_period_100us = hkp_dat.pps_period_100us
    output.pps_timeout_100ms = hkp_dat.pps_timeout_100ms
    output.cmd_fifo_write_ptr = hkp_dat.cmd_fifo_write_ptr
    output.cmd_fifo_read_ptr = hkp_dat.cmd_fifo_read_ptr
    output.cmds_remaining = hkp_dat.cmds_remaining ; not currently in spreadsheet
    output.cmds_received = hkp_dat.cmds_received ; not currently in spreadsheet
    output.cmds_executed = hkp_dat.cmds_executed ; not currently in spreadsheet
    output.cmds_executed2 = hkp_dat.cmds_executed2
    output.cmds_ignored = hkp_dat.cmds_ignored
    output.cmds_unknown = hkp_dat.cmds_unknown
    output.cmds_invalid = hkp_dat.cmds_invalid
    output.time_cmds_received = hkp_dat.time_cmds_received
    output.cmd_pause_remaining_100ms = hkp_dat.cmd_pause_remaining_100ms
    output.async_rates = hkp_dat.async_rates
    output.valid_rates = hkp_dat.valid_rates
    output.event_timeout_rates = hkp_dat.event_timeout_rates
    output.valid_timeout_rates = hkp_dat.valid_timeout_rates
    output.nopeak_rates = hkp_dat.nopeak_rates
    output.unknown_pattern_rates = hkp_dat.unknown_pattern_rates
    output.negative_pulse_rates = hkp_dat.negative_pulse_rates
    output.science_events = hkp_dat.science_events
    output.met_spare = hkp_dat.met_spare
    output.test_pulse_width_1us = hkp_dat.test_pulse_width_1us
    output.pulses_remaining = hkp_dat.pulses_remaining
    output.board_id = hkp_dat.board_id
    output.self_tod_enable = hkp_dat.self_tod_enable
    output.memory_page = hkp_dat.memory_page
    output.memory_address = hkp_dat.memory_address
    output.expected_checksum1 = hkp_dat.expected_checksum1
    output.expected_checksum0 = hkp_dat.expected_checksum0
    output.checksum1 = hkp_dat.checksum1
    output.checksum0 = hkp_dat.checksum0
    output.bias_clock_period_2us = hkp_dat.bias_clock_period_2us
    output.edac_errors = hkp_dat.edac_errors
    output.bus_timeout_counters = hkp_dat.bus_timeout_counters
    output.user_0e = hkp_dat.user_0e
    output.coincidence_window_clkcyc = hkp_dat.coincidence_window_clkcyc
    output.noise_delay_1us = hkp_dat.noise_delay_1us
    output.state_machine_errors = hkp_dat.state_machine_errors
    output.first_cmd_id = hkp_dat.first_cmd_id
    output.last_cmd_id = hkp_dat.last_cmd_id
    output.first_cmd_data = hkp_dat.first_cmd_data
    output.last_cmd_data = hkp_dat.last_cmd_data
    output.cmd_packets_received = hkp_dat.cmd_packets_received
    output.blr_test_pulse_1us = hkp_dat.blr_test_pulse_1us
    output.blr_extension_half_us = hkp_dat.blr_extension_half_us
    output.baseline_restore_mode = hkp_dat.baseline_restore_mode
    output.digi_filter_clock_cycles = hkp_dat.digi_filter_clock_cycles
    output.pulser_delay_clock_cycles = hkp_dat.pulser_delay_clock_cycles
    output.valid_enable_mask_bits = hkp_dat.valid_enable_mask_bits
    output.sci_mode_bits = hkp_dat.sci_mode_bits
    output.timeouts_2us = hkp_dat.timeouts_2us
    output.sci_resolution = hkp_dat.sci_resolution
    output.sci_translate = hkp_dat.sci_translate
    ; hkp: ana:
    output.adc_bias_voltage = hkp_dat.adc_bias_voltage
    output.temp_dap = hkp_dat.temp_dap
    output.voltage_1p5_vd = hkp_dat.voltage_1p5_vd
    output.voltage_3p3_vd = hkp_dat.voltage_3p3_vd
    output.voltage_5p0_vd = hkp_dat.voltage_5p0_vd
    output.voltage_dfe_pos_va = hkp_dat.voltage_dfe_pos_va
    output.voltage_dfe_neg_va = hkp_dat.voltage_dfe_neg_va
    output.adc_bias_current = hkp_dat.adc_bias_current
    output.bias_current_microamps = hkp_dat.bias_current_microamps  ; not currently in spreadsheet
    output.temp_sensor1 = hkp_dat.temp_sensor1
    output.temp_sensor2 = hkp_dat.temp_sensor2
    output.adc_baselines = hkp_dat.adc_baselines

    ; Opted to not include the following in l0b files, which
    ; are convenience variables for each packet:
    ; output.adc_voltages = hkp_dat.adc_voltages
    ; output.adc_temps = hkp_dat.adc_temps
    ; output.mux_all = hkp_dat.mux_al

    ; Opted to not include the replay (encoded in filename,
    ; as replay files have different names), valid redundant
    ; quality flag:
    ; output.hkp_replay = hkp_dat.replay
    ; output.hkp_valid = hkp_dat.valid

    ; from packet headers (swfo_stis_ccsds_header_decom.pro):
    output.time       = sci_dat.time
    output.time_met   = sci_dat.met
    output.time_gr  = sci_dat.grtime
    output.time_unix= sci_dat.time
    output.tod_day  = sci_dat.tod_day
    output.tod_millisec  = sci_dat.tod_millisec
    output.tod_microsec= sci_dat.tod_microsec

    ; Instead of recording time, met, grtime, unixtime
    ; tod_day, tod_millisec, tod_microsec for each packet,
    ; get nse/hkp_offset:
    output.hkp_offset = sci_dat.time - hkp_dat.time
    output.nse_offset = sci_dat.time - nse_dat.time

    ; Always same across nse_dat/hkp_dat/sci_dat
    output.fpga_rev = hkp_dat.fpga_rev
    output.user_09 = hkp_dat.user_09

    ; Reead the header info for each packet even if
    ; redundant for debugging:
    ; - time_delta (swfo_ccsds_data)
    output.hkp_time_delta = hkp_dat.time_delta
    output.sci_time_delta = sci_dat.time_delta
    output.nse_time_delta = nse_dat.time_delta
    ; ; - delaytime (swfo_ccsds_data)
    output.hkp_delaytime = hkp_dat.delaytime
    output.sci_delaytime = sci_dat.delaytime
    output.nse_delaytime = nse_dat.delaytime
    ; - APID (swfo_ccsds_data)
    output.hkp_apid = hkp_dat.apid
    output.sci_apid = sci_dat.apid
    output.nse_apid = nse_dat.apid
    ; - SEQN (swfo_ccsds_data)
    output.hkp_seqn = hkp_dat.seqn
    output.sci_seqn = sci_dat.seqn
    output.nse_seqn = nse_dat.seqn
    ; - SEQN_DELTA (swfo_ccsds_data)
    output.hkp_seqn_delta = hkp_dat.seqn_delta
    output.sci_seqn_delta = sci_dat.seqn_delta
    output.nse_seqn_delta = nse_dat.seqn_delta
    ; - Packet size (swfo_ccsds_data)
    output.hkp_packet_size = hkp_dat.packet_size
    output.sci_packet_size = sci_dat.packet_size
    output.nse_packet_size = nse_dat.packet_size
    ; - ptcu_bits (swfo_data_select):
    output.hkp_ptcu_bits = hkp_dat.ptcu_bits
    output.ptcu_bits = sci_dat.ptcu_bits
    output.nse_ptcu_bits = nse_dat.ptcu_bits
    ; - time res (swfo_data_select):
    output.hkp_time_res = hkp_dat.time_res
    output.sci_time_res = sci_dat.time_res
    output.nse_time_res = nse_dat.time_res
    ; - decimation_factor_bits (swfo_data_select):
    output.hkp_decimation_factor_bits = hkp_dat.decimation_factor_bits
    output.decimation_factor_bits = sci_dat.decimation_factor_bits
    output.nse_decimation_factor_bits = nse_dat.decimation_factor_bits
    ; - pulser_bits (swfo_data_select):
    output.hkp_pulser_bits = hkp_dat.pulser_bits
    output.pulser_bits = sci_dat.pulser_bits
    output.nse_pulser_bits = nse_dat.pulser_bits
    ; - detector_bits (swfo_data_select):
    output.hkp_detector_bits = hkp_dat.detector_bits
    output.detector_bits = sci_dat.detector_bits
    output.nse_detector_bits = nse_dat.detector_bits
    ; - aaee_bits (swfo_data_select):
    output.hkp_aaee_bits = hkp_dat.aaee_bits
    output.aaee_bits = sci_dat.aaee_bits
    output.nse_aaee_bits = nse_dat.aaee_bits
    ; - noise_bits (swfo_data_select):
    output.hkp_noise_bits = hkp_dat.noise_bits
    output.noise_bits = sci_dat.noise_bits
    output.nse_noise_bits = nse_dat.noise_bits
    ; - duration = 1 + time_res(swfo_stis_ccsds_header_decom)
    output.hkp_duration = hkp_dat.duration
    output.duration = sci_dat.duration
    output.nse_duration = nse_dat.duration
    ; ; packet_checksums:
    ; NOT INCLUDED -- these are not actually reported
    ; for this instrument.
    ; output.hkp_packet_checksum_reported = hkp_dat.packet_checksum_reported
    ; output.sci_packet_checksum_reported = sci_dat.packet_checksum_reported
    ; output.nse_packet_checksum_reported = nse_dat.packet_checksum_reported
    ; output.hkp_packet_checksum_calculated = hkp_dat.packet_checksum_calculated
    ; output.sci_packet_checksum_calculated = sci_dat.packet_checksum_calculated
    ; output.nse_packet_checksum_calculated = nse_dat.packet_checksum_calculated
    ; output.hkp_packet_checksum_match = hkp_dat.packet_checksum_match
    ; output.sci_packet_checksum_match = sci_dat.packet_checksum_match
    ; output.nse_packet_checksum_match = nse_dat.packet_checksum_match
    ; - gap
    output.hkp_gap = hkp_dat.gap
    output.sci_gap = sci_dat.gap
    output.nse_gap = nse_dat.gap

    ; nse:
    output.nse_histogram =  nse_dat.histogram
    output.nse_counts = nse_dat.raw
    ; output.nse_sigma = nse_dat.sigma
    ; output.nse_baseline = nse_dat.baseline
    ; output.nse_total6 = nse_dat.total6
    ; sci:
    output.sci_nbins  = sci_dat.nbins
    output.sci_counts= sci_dat.counts

    ; output.sci_nonlut_mode = sci_dat.sci_nonlut_mode
    ; output.sci_decimate = sci_dat.sci_decimate
    ; output.sci_translate = sci_dat.sci_translate
    ; output.sci_resolution = sci_dat.sci_resolution
    output.quality_bits  = 0

  endif else begin
    ; Currently inactive:
    ; Code that prepends the structure tags with
    ; hkp, nse, and sci. Unfortunately, runs
    ; very slowly (manually entered tags took 130 msec,
    ;  vs merge_struct using replace_tag takes 30,000 msec,
    ;  and merge_struct using str_element takes 0.1 sec)
    l0b = merge_struct(hkp_dat, nse_dat, ['hkp', 'nse'])
    l0b = merge_struct(l0b, sci_dat, ['', 'sci'])
    ; stop

    ; since stacked according to science packet,
    ; set the science packet time to the main time:
    str_element, l0b, 'time', l0b.sci_time, /add

    ; quality flag place holder
    ; = l0b.hkp_detector_bits
    str_element, l0b, 'quality_flag', 0b, /add
    ; l0b.quality_flag = 0b

    output = l0b
  endelse



  return,output

end

