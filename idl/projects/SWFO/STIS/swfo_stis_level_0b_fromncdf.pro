;+
;  FUNCTION swfo_stis_level_0b_noaa2ssl
;  
;  PURPOSE:
; Input:
;   filenames: 
; l0b:
;   l0b: structure with renamed tag 
;KEYWORDS:
;  from_l0b: If set, will use nse_noise_bits and nse_histogram
;            from structure.
;
; $LastChangedBy: rjolitz $
; $LastChangedDate: 2025-04-18 14:16:34 -0700 (Fri, 18 Apr 2025) $
; $LastChangedRevision: 33269 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SWFO/STIS/swfo_stis_level_0b_fromncdf.pro $


function swfo_stis_level_0b_fromncdf, l0b_ncdf, noaa=noaa

  ; Structure skeleton  
  nan = !values.f_nan
  dnan = !values.d_nan

  l0b_template = { swfo_stis_l0b, $
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
      sci_ptcu_bits: 0b, $
      hkp_ptcu_bits: 0b, $
      nse_ptcu_bits: 0b, $
      sci_time_res: 0u, $
      hkp_time_res: 0u, $
      nse_time_res: 0u, $
      sci_decimation_factor_bits: 0b, $
      hkp_decimation_factor_bits: 0b, $
      nse_decimation_factor_bits: 0b, $
      sci_pulser_bits: 0b, $
      hkp_pulser_bits: 0b, $
      nse_pulser_bits: 0b, $
      sci_detector_bits: 0b, $
      hkp_detector_bits: 0b, $
      nse_detector_bits: 0b, $
      sci_aaee_bits: 0b, $
      hkp_aaee_bits: 0b, $
      nse_aaee_bits: 0b, $
      sci_noise_bits: 0u, $
      hkp_noise_bits: 0u, $
      nse_noise_bits: 0u, $
      ; set in swfo_stis_ccsds_header_decom as 1 + time_res
      sci_duration:  0u, $
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
      ; l0b_ncdfa:
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
      nse_raw: replicate(0u, 60), $
      quality_bits:  0ul}

    nd = n_elements(l0b_ncdf.time_unix)
    l0b = replicate(l0b_template,nd)

    if keyword_set(noaa) then begin
      ; Time columns:
      l0b.time        = l0b_ncdf.time_unix * 1d  ;PROBLEM: currently Ulongs, should be floats
      l0b.time_met    = l0b_ncdf.time_met
      l0b.time_unix   = l0b_ncdf.time_unix * 1d

      l0b.tod_day     = l0b_ncdf.tod_day
      l0b.tod_millisec= l0b_ncdf.tod_millisec
      l0b.tod_microsec= l0b_ncdf.tod_microsec
      ; Ignore packet_time, equivalent to MET:

      ; Constants:
      l0b.fpga_rev    = l0b_ncdf.fpga_rev
      l0b.user_09     = l0b_ncdf.user_09

      ; Header elements:

      ; sci info:
      l0b.sci_seqn                  = l0b_ncdf.sci_seqn
      l0b.sci_resolution            = l0b_ncdf.sci_resolution
      l0b.sci_translate             = l0b_ncdf.sci_translate 
      l0b.sci_counts                = float(l0b_ncdf.sci_counts ) ; PROBLEM- int!
      l0b.sci_time_res              = l0b_ncdf.time_res

      if tag_exist(l0b_ncdf, 'duration') then  l0b.sci_duration = l0b_ncdf.duration else begin

        l0b.sci_duration = 1 + l0b_ncdf.time_res

      endelse
      ; stop

      ; Map the unlabeled into sci:

      l0b.sci_ptcu_bits             = l0b_ncdf.ptcu_bits.frombits()

      ; l0b.sci_pulser_bits           = l0b_ncdf.pulser_bits.frombits()
      pul_bits = ishft(l0b_ncdf.pulser_bits[0, *],7)+ ishft(l0b_ncdf.pulser_bits[1, *],6)+ l0b_ncdf.pulser_bits[2, *]
      l0b.sci_pulser_bits = reform(pul_bits)

      ; l0b.sci_aaee_bits             = l0b_ncdf.aaee_bits.frombits()
      aaee_bits = ishft(l0b_ncdf.aaee_bits[0, *],2)+ l0b_ncdf.aaee_bits[1, *]
      l0b.sci_aaee_bits = reform(aaee_bits)

      ; l0b.sci_noise_bits            = l0b_ncdf.noise_bits.frombits()
      nse_bits = ishft(uint(l0b_ncdf.noise_bits[0, *]), 11)+ ishft(uint(l0b_ncdf.noise_bits[1, *]),8)+ l0b_ncdf.noise_bits[2, *]
      l0b.sci_noise_bits = reform(nse_bits)

      ; l0b.sci_detector_bits         = l0b_ncdf.detector_bits.frombits()
      det_bits = ishft(l0b_ncdf.detector_bits[0, *],7)+ ishft(l0b_ncdf.detector_bits[1, *],6)+ l0b_ncdf.detector_bits[2, *]
      l0b.sci_detector_bits = reform(det_bits)


      ; Decimation factor bits can be 0,1,2
      ; l0b.sci_decimation_factor_bits= l0b_ncdf.decimation_factor_bits.frombits()

      ; If the decimation bits are ordered as: 6,5,3,2
      dec = l0b_ncdf.decimation_factor_bits[3, *] + ishft(l0b_ncdf.decimation_factor_bits[2, *], 2) +$
        ishft(l0b_ncdf.decimation_factor_bits[1, *], 4) + ishft(l0b_ncdf.decimation_factor_bits[0, *], 6)
      ; ; If the decimation bits are ordered: 2,3,5,6
      ; dec = l0b_ncdf.decimation_factor_bits[0, *] + ishft(l0b_ncdf.decimation_factor_bits[1, *], 2) +$
      ;   ishft(l0b_ncdf.decimation_factor_bits[2, *], 4) + ishft(l0b_ncdf.decimation_factor_bits[3, *], 6)

      l0b.sci_decimation_factor_bits = reform(dec)

      ; if l0b.sci_decimation_factor_bits eq 0b then stop

      ; nse info:
      l0b.nse_seqn                  = l0b_ncdf.nse_seqn
      l0b.nse_histogram             = (l0b_ncdf.nse_counts)
      l0b.nse_offset                = l0b_ncdf.nse_offset

      ; hkp - non analog info:
      l0b.hkp_seqn                  = l0b_ncdf.hkp2_seqn
      l0b.hkp_offset                = l0b_ncdf.hkp2_offset

      l0b.dac_values                = l0b_ncdf.dac_values
      l0b.pps_counter               = l0b_ncdf.pps_counter
      l0b.pps_period_100us          = l0b_ncdf.pps_period_100us
      l0b.pps_timeout_100ms         = l0b_ncdf.pps_timeout_100ms

      l0b.cmd_fifo_write_ptr        = l0b_ncdf.cmd_fifo_write_ptr
      l0b.cmd_fifo_read_ptr         = l0b_ncdf.cmd_fifo_read_ptr
      ; l0b.cmds_remaining            = l0b_ncdf.cmds_remaining ; not currently in spreadsheet
      ; l0b.cmds_received             = l0b_ncdf.cmds_received ; not currently in spreadsheet
      ; l0b.cmds_executed             = l0b_ncdf.cmds_executed ; not currently in spreadsheet
      l0b.cmds_executed2            = l0b_ncdf.cmds_executed2
      l0b.cmds_ignored              = l0b_ncdf.cmds_ignored
      l0b.cmds_unknown              = l0b_ncdf.cmds_unknown
      l0b.cmds_invalid              = l0b_ncdf.cmds_invalid
      l0b.time_cmds_received        = l0b_ncdf.time_cmds_received
      l0b.cmd_pause_remaining_100ms = l0b_ncdf.cmd_pause_remaining_100ms

      l0b.async_rates               = l0b_ncdf.async_rates
      l0b.valid_rates               = l0b_ncdf.valid_rates
      l0b.event_timeout_rates       = l0b_ncdf.event_timeout_rates
      l0b.valid_timeout_rates       = l0b_ncdf.valid_timeout_rates
      l0b.nopeak_rates              = l0b_ncdf.nopeak_rates
      l0b.unknown_pattern_rates     = l0b_ncdf.unknown_pattern_rates

      l0b.negative_pulse_rates      = l0b_ncdf.negative_pulse_rates
      l0b.science_events            = l0b_ncdf.science_events
      l0b.met_spare                 = l0b_ncdf.met_spare
      l0b.test_pulse_width_1us      = l0b_ncdf.test_pulse_width_1us
      l0b.pulses_remaining          = l0b_ncdf.pulses_remaining
      l0b.board_id                  = l0b_ncdf.board_id
      l0b.self_tod_enable           = l0b_ncdf.self_tod_enable
      l0b.memory_page               = l0b_ncdf.memory_page
      l0b.memory_address            = l0b_ncdf.memory_address
      l0b.expected_checksum1        = l0b_ncdf.expected_checksum1
      l0b.expected_checksum0        = l0b_ncdf.expected_checksum0
      l0b.checksum1                 = l0b_ncdf.checksum1
      l0b.checksum0                 = l0b_ncdf.checksum0
      l0b.bias_clock_period_2us     = l0b_ncdf.bias_clock_period_2us
      l0b.edac_errors               = (l0b_ncdf.edac_errors)
      l0b.bus_timeout_counters      = (l0b_ncdf.bus_timeout_counters)
      l0b.user_0e                   = l0b_ncdf.user_0e
      l0b.coincidence_window_clkcyc = l0b_ncdf.coincidence_window_clkcyc
      l0b.noise_delay_1us           = l0b_ncdf.noise_delay_1us
      l0b.state_machine_errors      = (l0b_ncdf.state_machine_errors)
      l0b.first_cmd_id              = l0b_ncdf.first_cmd_id
      l0b.last_cmd_id               = l0b_ncdf.last_cmd_id
      l0b.first_cmd_data            = l0b_ncdf.first_cmd_data
      l0b.last_cmd_data             = l0b_ncdf.last_cmd_data
      l0b.cmd_packets_received      = l0b_ncdf.cmd_packets_received

      l0b.blr_test_pulse_1us        = l0b_ncdf.blr_test_pulse_1us
      l0b.blr_extension_half_us     = l0b_ncdf.blr_extension_half_us
      l0b.baseline_restore_mode     = l0b_ncdf.baseline_restore_mode
      l0b.digi_filter_clock_cycles  = (l0b_ncdf.digi_filter_clock_cycles)
      l0b.pulser_delay_clock_cycles = (l0b_ncdf.pulser_delay_clock_cycles)
      l0b.valid_enable_mask_bits    = l0b_ncdf.valid_enable_mask_bits
      l0b.sci_mode_bits             = l0b_ncdf.sci_mode_bits
      l0b.timeouts_2us              = (l0b_ncdf.timeouts_2us)


      ; hkp - analog signals:
      l0b.adc_bias_voltage    = l0b_ncdf.adc_bias_voltage
      l0b.temp_dap            = l0b_ncdf.temp_dap
      l0b.voltage_1p5_vd      = l0b_ncdf.voltage_1p5_vd
      l0b.voltage_3p3_vd      = l0b_ncdf.voltage_3p3_vd
      l0b.voltage_5p0_vd      = l0b_ncdf.voltage_5p0_vd
      l0b.voltage_dfe_pos_va  = l0b_ncdf.voltage_dfe_pos_va
      l0b.voltage_dfe_neg_va  = l0b_ncdf.voltage_dfe_neg_va
      l0b.bias_current_microamps = l0b_ncdf.adc_bias_current
      l0b.adc_bias_current    = l0b_ncdf.adc_bias_current * 200e3/1e6 ; uninvert to engineering unit
      l0b.temp_sensor1        = l0b_ncdf.temp_sensor1
      l0b.temp_sensor2        = l0b_ncdf.temp_sensor2
      l0b.adc_baselines       = (l0b_ncdf.adc_baselines)

      ; valid enable mask:
      valid_mask = bytarr(6, nd)
      valid_mask[0, *] = l0b_ncdf.stis_valid_enable_mask_d1
      valid_mask[1, *] = l0b_ncdf.stis_valid_enable_mask_d2
      valid_mask[2, *] = l0b_ncdf.stis_valid_enable_mask_d3
      valid_mask[3, *] = l0b_ncdf.stis_valid_enable_mask_d4
      valid_mask[4, *] = l0b_ncdf.stis_valid_enable_mask_d5
      valid_mask[5, *] = l0b_ncdf.stis_valid_enable_mask_d6
      valid_mask = valid_mask.frombits()
      l0b.valid_enable_mask_bits     = valid_mask
    endif else begin

    ; hkp: from swfo_stis_hkp_apdat__define.pro
    l0b.dac_values = l0b_ncdf.dac_values
    l0b.pps_counter = l0b_ncdf.pps_counter
    l0b.pps_period_100us = l0b_ncdf.pps_period_100us
    l0b.pps_timeout_100ms = l0b_ncdf.pps_timeout_100ms
    l0b.cmd_fifo_write_ptr = l0b_ncdf.cmd_fifo_write_ptr
    l0b.cmd_fifo_read_ptr = l0b_ncdf.cmd_fifo_read_ptr
    l0b.cmds_remaining = l0b_ncdf.cmds_remaining ; not currently in spreadsheet
    l0b.cmds_received = l0b_ncdf.cmds_received ; not currently in spreadsheet
    l0b.cmds_executed = l0b_ncdf.cmds_executed ; not currently in spreadsheet
    l0b.cmds_executed2 = l0b_ncdf.cmds_executed2
    l0b.cmds_ignored = l0b_ncdf.cmds_ignored
    l0b.cmds_unknown = l0b_ncdf.cmds_unknown
    l0b.cmds_invalid = l0b_ncdf.cmds_invalid
    l0b.time_cmds_received = l0b_ncdf.time_cmds_received
    l0b.cmd_pause_remaining_100ms = l0b_ncdf.cmd_pause_remaining_100ms
    l0b.async_rates = l0b_ncdf.async_rates
    l0b.valid_rates = l0b_ncdf.valid_rates
    l0b.event_timeout_rates = l0b_ncdf.event_timeout_rates
    l0b.valid_timeout_rates = l0b_ncdf.valid_timeout_rates
    l0b.nopeak_rates = l0b_ncdf.nopeak_rates
    l0b.unknown_pattern_rates = l0b_ncdf.unknown_pattern_rates
    l0b.negative_pulse_rates = l0b_ncdf.negative_pulse_rates
    l0b.science_events = l0b_ncdf.science_events
    l0b.met_spare = l0b_ncdf.met_spare
    l0b.test_pulse_width_1us = l0b_ncdf.test_pulse_width_1us
    l0b.pulses_remaining = l0b_ncdf.pulses_remaining
    l0b.board_id = l0b_ncdf.board_id
    l0b.self_tod_enable = l0b_ncdf.self_tod_enable
    l0b.memory_page = l0b_ncdf.memory_page
    l0b.memory_address = l0b_ncdf.memory_address
    l0b.expected_checksum1 = l0b_ncdf.expected_checksum1
    l0b.expected_checksum0 = l0b_ncdf.expected_checksum0
    l0b.checksum1 = l0b_ncdf.checksum1
    l0b.checksum0 = l0b_ncdf.checksum0
    l0b.bias_clock_period_2us = l0b_ncdf.bias_clock_period_2us
    l0b.edac_errors = l0b_ncdf.edac_errors
    l0b.bus_timeout_counters = l0b_ncdf.bus_timeout_counters
    l0b.user_0e = l0b_ncdf.user_0e
    l0b.coincidence_window_clkcyc = l0b_ncdf.coincidence_window_clkcyc
    l0b.noise_delay_1us = l0b_ncdf.noise_delay_1us
    l0b.state_machine_errors = l0b_ncdf.state_machine_errors
    l0b.first_cmd_id = l0b_ncdf.first_cmd_id
    l0b.last_cmd_id = l0b_ncdf.last_cmd_id
    l0b.first_cmd_data = l0b_ncdf.first_cmd_data
    l0b.last_cmd_data = l0b_ncdf.last_cmd_data
    l0b.cmd_packets_received = l0b_ncdf.cmd_packets_received
    l0b.blr_test_pulse_1us = l0b_ncdf.blr_test_pulse_1us
    l0b.blr_extension_half_us = l0b_ncdf.blr_extension_half_us
    l0b.baseline_restore_mode = l0b_ncdf.baseline_restore_mode
    l0b.digi_filter_clock_cycles = l0b_ncdf.digi_filter_clock_cycles
    l0b.pulser_delay_clock_cycles = l0b_ncdf.pulser_delay_clock_cycles
    l0b.valid_enable_mask_bits = l0b_ncdf.valid_enable_mask_bits
    l0b.sci_mode_bits = l0b_ncdf.sci_mode_bits
    l0b.timeouts_2us = l0b_ncdf.timeouts_2us
    l0b.sci_resolution = l0b_ncdf.sci_resolution
    l0b.sci_translate = l0b_ncdf.sci_translate
    ; hkp: ana:
    l0b.adc_bias_voltage = l0b_ncdf.adc_bias_voltage
    l0b.temp_dap = l0b_ncdf.temp_dap
    l0b.voltage_1p5_vd = l0b_ncdf.voltage_1p5_vd
    l0b.voltage_3p3_vd = l0b_ncdf.voltage_3p3_vd
    l0b.voltage_5p0_vd = l0b_ncdf.voltage_5p0_vd
    l0b.voltage_dfe_pos_va = l0b_ncdf.voltage_dfe_pos_va
    l0b.voltage_dfe_neg_va = l0b_ncdf.voltage_dfe_neg_va
    l0b.adc_bias_current = l0b_ncdf.adc_bias_current
    l0b.bias_current_microamps = l0b_ncdf.bias_current_microamps  ; not currently in spreadsheet
    l0b.temp_sensor1 = l0b_ncdf.temp_sensor1
    l0b.temp_sensor2 = l0b_ncdf.temp_sensor2
    l0b.adc_baselines = l0b_ncdf.adc_baselines

    ; Opted to not include the following in l0b files, which
    ; are convenience variables for each packet:
    ; l0b.adc_voltages = l0b_ncdf.adc_voltages
    ; l0b.adc_temps = l0b_ncdf.adc_temps
    ; l0b.mux_all = l0b_ncdf.mux_al

    ; Opted to not include the replay (encoded in filename,
    ; as replay files have different names), valid redundant
    ; quality flag:
    ; l0b.hkp_replay = l0b_ncdf.replay
    ; l0b.hkp_valid = l0b_ncdf.valid

    ; from packet headers (swfo_stis_ccsds_header_decom.pro):
    l0b.time       = l0b_ncdf.time
    l0b.time_met   = l0b_ncdf.time_met
    l0b.time_gr  = l0b_ncdf.time_gr
    l0b.time_unix= l0b_ncdf.time_unix
    l0b.tod_day  = l0b_ncdf.tod_day
    l0b.tod_millisec  = l0b_ncdf.tod_millisec
    l0b.tod_microsec= l0b_ncdf.tod_microsec

    ; Instead of recording time, met, grtime, unixtime
    ; tod_day, tod_millisec, tod_microsec for each packet,
    ; get nse/hkp_offset:
    l0b.hkp_offset = l0b_ncdf.hkp_offset
    l0b.nse_offset = l0b_ncdf.nse_offset

    ; Always same across l0b_ncdf/l0b_ncdf/l0b_ncdf
    l0b.fpga_rev = l0b_ncdf.fpga_rev
    l0b.user_09 = l0b_ncdf.user_09

    ; Reead the header info for each packet even if
    ; redundant for debugging:
    ; - time_delta (swfo_ccsds_data)
    l0b.hkp_time_delta = l0b_ncdf.hkp_time_delta
    l0b.sci_time_delta = l0b_ncdf.sci_time_delta
    l0b.nse_time_delta = l0b_ncdf.nse_time_delta
    ; ; - delaytime (swfo_ccsds_data)
    l0b.hkp_delaytime = l0b_ncdf.hkp_delaytime
    l0b.sci_delaytime = l0b_ncdf.sci_delaytime
    l0b.nse_delaytime = l0b_ncdf.nse_delaytime
    ; - APID (swfo_ccsds_data)
    l0b.hkp_apid = l0b_ncdf.hkp_apid
    l0b.sci_apid = l0b_ncdf.sci_apid
    l0b.nse_apid = l0b_ncdf.nse_apid
    ; - SEQN (swfo_ccsds_data)
    l0b.hkp_seqn = l0b_ncdf.hkp_seqn
    l0b.sci_seqn = l0b_ncdf.sci_seqn
    l0b.nse_seqn = l0b_ncdf.nse_seqn
    ; - SEQN_DELTA (swfo_ccsds_data)
    l0b.hkp_seqn_delta = l0b_ncdf.hkp_seqn_delta
    l0b.sci_seqn_delta = l0b_ncdf.sci_seqn_delta
    l0b.nse_seqn_delta = l0b_ncdf.nse_seqn_delta
    ; - Packet size (swfo_ccsds_data)
    l0b.hkp_packet_size = l0b_ncdf.hkp_packet_size
    l0b.sci_packet_size = l0b_ncdf.sci_packet_size
    l0b.nse_packet_size = l0b_ncdf.nse_packet_size
    ; - ptcu_bits (swfo_data_select):
    l0b.hkp_ptcu_bits = l0b_ncdf.hkp_ptcu_bits
    l0b.sci_ptcu_bits = l0b_ncdf.sci_ptcu_bits
    l0b.nse_ptcu_bits = l0b_ncdf.nse_ptcu_bits
    ; - time res (swfo_data_select):
    l0b.hkp_time_res = l0b_ncdf.hkp_time_res
    l0b.sci_time_res = l0b_ncdf.sci_time_res
    l0b.nse_time_res = l0b_ncdf.nse_time_res
    ; - decimation_factor_bits (swfo_data_select):
    l0b.hkp_decimation_factor_bits = l0b_ncdf.hkp_decimation_factor_bits
    l0b.sci_decimation_factor_bits = l0b_ncdf.sci_decimation_factor_bits
    l0b.nse_decimation_factor_bits = l0b_ncdf.nse_decimation_factor_bits
    ; - pulser_bits (swfo_data_select):
    l0b.hkp_pulser_bits = l0b_ncdf.hkp_pulser_bits
    l0b.sci_pulser_bits = l0b_ncdf.sci_pulser_bits
    l0b.nse_pulser_bits = l0b_ncdf.nse_pulser_bits
    ; - detector_bits (swfo_data_select):
    l0b.hkp_detector_bits = l0b_ncdf.hkp_detector_bits
    l0b.sci_detector_bits = l0b_ncdf.sci_detector_bits
    l0b.nse_detector_bits = l0b_ncdf.nse_detector_bits
    ; - aaee_bits (swfo_data_select):
    l0b.hkp_aaee_bits = l0b_ncdf.hkp_aaee_bits
    l0b.sci_aaee_bits = l0b_ncdf.sci_aaee_bits
    l0b.nse_aaee_bits = l0b_ncdf.nse_aaee_bits
    ; - noise_bits (swfo_data_select):
    l0b.hkp_noise_bits = l0b_ncdf.hkp_noise_bits
    l0b.sci_noise_bits = l0b_ncdf.sci_noise_bits
    l0b.nse_noise_bits = l0b_ncdf.nse_noise_bits
    ; - duration = 1 + time_res(swfo_stis_ccsds_header_decom)
    l0b.hkp_duration = l0b_ncdf.hkp_duration
    l0b.sci_duration = l0b_ncdf.sci_duration
    l0b.nse_duration = l0b_ncdf.nse_duration
    ; ; packet_checksums:
    ; NOT INCLUDED -- these are not actually reported
    ; for this instrument.
    ; l0b.hkp_packet_checksum_reported = l0b_ncdf.packet_checksum_reported
    ; l0b.sci_packet_checksum_reported = l0b_ncdf.packet_checksum_reported
    ; l0b.nse_packet_checksum_reported = l0b_ncdf.packet_checksum_reported
    ; l0b.hkp_packet_checksum_calculated = l0b_ncdf.packet_checksum_calculated
    ; l0b.sci_packet_checksum_calculated = l0b_ncdf.packet_checksum_calculated
    ; l0b.nse_packet_checksum_calculated = l0b_ncdf.packet_checksum_calculated
    ; l0b.hkp_packet_checksum_match = l0b_ncdf.packet_checksum_match
    ; l0b.sci_packet_checksum_match = l0b_ncdf.packet_checksum_match
    ; l0b.nse_packet_checksum_match = l0b_ncdf.packet_checksum_match
    ; - gap
    l0b.hkp_gap = l0b_ncdf.hkp_gap
    l0b.sci_gap = l0b_ncdf.sci_gap
    l0b.nse_gap = l0b_ncdf.nse_gap

    ; nse:
    l0b.nse_histogram =  l0b_ncdf.nse_histogram
    l0b.nse_raw = l0b_ncdf.nse_raw
    ; l0b.nse_sigma = l0b_ncdf.sigma
    ; l0b.nse_baseline = l0b_ncdf.baseline
    ; l0b.nse_total6 = l0b_ncdf.total6
    ; sci:
    l0b.sci_nbins  = l0b_ncdf.sci_nbins
    l0b.sci_counts= l0b_ncdf.sci_counts

    ; l0b.sci_nonlut_mode = l0b_ncdf.sci_nonlut_mode
    ; l0b.sci_decimate = l0b_ncdf.sci_decimate
    ; l0b.sci_translate = l0b_ncdf.sci_translate
    ; l0b.sci_resolution = l0b_ncdf.sci_resolution
    l0b.quality_bits  = 0


    endelse

    return,l0b

end