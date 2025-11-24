;+
;FUNCTION:  SWFO_STIS_SCI_LEVEL_0B
;PURPOSE: Creates an array of structures,
; where each structure has fields corresponding
; to the Level 0b data product for SWFO STIS.
;
; This data product selects fields
; from one or more APIDs that are already
; decommutated from the CCSDS packets
; (e.g. via 
;      > swfo_stis_load
;      or
;      >  rdr = ccsds_frame_reader(mission='SWFO')
;      >  dat = ncdf2struct(file)
;      >  frames = struct_value(dat,'swfo_frame_data',default = !null)
;      >  rdr.read , frames).
; 
;FAQ:
;  Q:    Why is this routine so long and the structure have so
;     many fields?
;  A:    There is no time efficient way to dynamically
;     create a new structure that with tag names
;     that are prepended by the struct name based
;     on multiple structures. This was attempted for
;     hkp, nse, and sci structures.
;        Manually entered tags took 130 msec,
;     merge_struct using replace_tag takes 30,000 msec,
;     and merge_struct using str_element takes 0.1 sec.
;        Since this needs to run for each unit of time,
;     this becomes an unmanageable slowdown.
;
;USAGE:
;  ;Load data first:
;  swfo_stis_load, trange=['2025-10-15 5:00', '2025-10-15 6:00']
;  ; Then retrieve all apids:
;  l0b =   swfo_stis_sci_level_l0b(/getall)
;
;KEYWORDS:
;       GETALL:       Retrieves all APID information using swfo_apdat
;                     instead of via the keywords.
;
;       PLAYBACK:     Get Level 0b for playback instead of data
;                     stream if set.
;
;       BLANK:        Returns empty Level 0b structure.
;
;       SCI_DAT:      structure containing decommutated data
;                     from 'stis_sci'/0x350, described in
;                     swfo_stis_sci_apdat::decom
;
;       NSE_DAT:      structure containing decommutated data
;                     from 'stis_nse'/0x351, described in
;                     swfo_stis_nse_apdat::decom
;
;       HKP_DAT:      structure containing decommutated data
;                     from 'stis_hkp'/0x35f, described in
;                     swfo_stis_hkp_apdat::decom
;
;       HKP_DAT:      structure containing decommutated data
;                     from 'stis_hkp'/0x35f, described in
;                     swfo_stis_hkp_apdat::decom
;
;       SC100_DAT:    structure containing decommutated data
;                     from 'sc_100', described in
;                     swfo_sc_100_apdat::decom
;                     (reaction wheel, TMON, sband info)
;
;       SC110_DAT:    structure containing decommutated data
;                     from 'sc_110', described in
;                     swfo_sc_110_apdat::decom
;                     (pointing info, IRU bits)
;
;       PREV_L0B_DAT: placeholder for previous level 0b
;
; $LastChangedBy: davin-mac $
; $LastChangedDate: 2025-11-22 07:53:52 -0800 (Sat, 22 Nov 2025) $
; $LastChangedRevision: 33864 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SWFO/STIS/swfo_stis_sci_level_0b.pro $


function swfo_stis_sci_level_0b,getall=getall,prev_l0b_dat=output,$
  sci_dat=sci_dat,nse_dat=nse_dat,hkp_dat=hkp_dat,$
  sc100_dat=sc100_dat,sc110_dat=sc110_dat,$
  datahash=datahash, $
  playback=playback,blank=blank


  ;output = !null
  nan = !values.f_nan
  dnan = !values.d_nan
  
  if ~isa(output,'structure') then  output = {  $
    time:dnan  ,$
    time_met: dnan, $
    time_gr:  dnan, $
    time_unix:  dnan, $
    tod_day: 0ul, $
    tod_millisec: 0ul, $
    tod_microsec: 0ul, $
    ; relative time differences between
    ; science and housekeeping/noise packets
    hkp_offset: dnan,$
    nse_offset: dnan,$
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
    ; apid 100 data (rxn wheel info)
    adcs_state_0wait_1detumble_2acqsun_3point_4deltav_5earth: 0b,$
    sun_point_status_0idle_1magpoint_2intrusion_3avoidance_4maneuver: 0b,$
    sun_point_minimum_keepout_angle: 0.,$
    measured_sun_vector_xyz: replicate(0d, 3), $
    control_torque_xyz: fltarr(3),$
    rt_critical_vc: 0b, $
    star_tracker_attitude_q1234: replicate(0d, 4),$
    rt_non_critical_vc: 0b, $
    body_frame_attitude_q1234: replicate(0d, 4),$
    pbk_critical_vc: 0b, $
    fsw_transfer_frame_accept_counter: 0b, $
    fsw_transfer_frame_reject_counter: 0b, $
    fsw_command_accept_counter: 0b, $
    fsw_command_reject_counter: 0b, $
    tmon_master_enabled: 0b, $
    tmon_001_sample_enabled_armed_triggered: 0b, $
    fsw_power_management_bits: 0b, $
    battery_current_amps: 0d, $
    battery_temperature_c: 0d, $
    battery_voltage_v: 0d, $
    tmon_230_enabled_armed_triggered: 0b, $
    tmon_231_enabled_armed_triggered: 0b, $
    tmon_232_enabled_armed_triggered: 0b, $
    tmon_233_enabled_armed_triggered: 0b, $
    tmon_234_enabled_armed_triggered: 0b, $
    tmon_235_enabled_armed_triggered: 0b, $
    tmon_236_enabled_armed_triggered: 0b, $
    reaction_wheel_overspeed_fault_bits: 0b, $
    sband_downlink_rate:  0ul, $
    reaction_wheel_speed_rpm:  replicate(0d, 4), $
    ; apid 110: location and iru bits
    iru_bits: 0b,$
    modeled_spacecraft_sun_vxyz: replicate(0d, 3), $
    ; quality bits always last:
    quality_bits:  0ul}

  if keyword_set(blank) then return,output   ;l0b



  ;    if ~isa(sci_dat) || ~isa(nse_dat) || ~isa(hkp_dat) then begin
  ;      dprint,'bad data in L0b'
  ;      return,!null  ; l0b
  ;    endif

  if keyword_set(getall) then begin

    if keyword_set(playback) then prefix = 'pb_' else prefix=''
    
    sci_obj = swfo_apdat(prefix +'stis_sci')
    nse_obj = swfo_apdat(prefix +'stis_nse')
    hkp_obj = swfo_apdat(prefix +'stis_hkp2')
    sc100_obj = swfo_apdat(prefix +'sc_100')
    sc110_obj = swfo_apdat(prefix +'sc_110')


    if ~isa(sci_dat) then sci_dat = sci_obj.data.array

    output = replicate(output,n_elements(sci_dat))    
    ; It is important that the data should have been sorted by this time
    sci_time  = sci_obj.data.array.time

    ; Get packet samples nearest to sci_time
    nse_dat   = nse_obj.data.sample(nearest=sci_time,tagname='time')
    hkp_dat   = hkp_obj.data.sample(nearest=sci_time,tagname='time')
    sc100_dat = sc100_obj.data.sample(nearest=sci_time,tagname='time')
    sc110_dat = sc110_obj.data.sample(nearest=sci_time,tagname='time')

  endif


  if keyword_set(datahash) then begin

    sci_da = datahash['stis_sci'] 
    nse_da = datahash['stis_nse']
    hkp_da = datahash['stis_hkp2']
    sc100_da = datahash['sc_100']
    sc110_da = datahash['sc_110']

    sci_dat = sci_da.array

    output = replicate(output,n_elements(sci_dat))

    ; It is important that the data should have been sorted by this time
    sci_time  = sci_dat.time

    ; Get packet samples nearest to sci_time
    nse_dat   = nse_da.sample(nearest=sci_time,tagname='time')
    hkp_dat   = hkp_da.sample(nearest=sci_time,tagname='time')
    sc100_dat = sc100_da.sample(nearest=sci_time,tagname='time')
    sc110_dat = sc110_da.sample(nearest=sci_time,tagname='time')

  endif





  nd= n_elements(output)


  if n_elements(sci_dat) eq nd then begin    ; Should generaly be true
    ; from packet headers (swfo_stis_ccsds_header_decom.pro):
    output.time       = sci_dat.time
    output.time_met   = sci_dat.met
    output.time_gr  = sci_dat.grtime
    output.time_unix= sci_dat.time
    output.tod_day  = sci_dat.tod_day
    output.tod_millisec  = sci_dat.tod_millisec
    output.tod_microsec= sci_dat.tod_microsec
    ; sci:
    output.sci_nbins  = sci_dat.nbins
    output.sci_counts= sci_dat.counts

    output.quality_bits  = sci_dat.replay  

    output.sci_time_delta = sci_dat.time_delta
    output.sci_delaytime = sci_dat.delaytime
    output.sci_apid = sci_dat.apid
    output.sci_seqn = sci_dat.seqn
    output.sci_seqn_delta = sci_dat.seqn_delta
    output.sci_packet_size = sci_dat.packet_size
    output.ptcu_bits = sci_dat.ptcu_bits
    output.sci_time_res = sci_dat.time_res
    output.decimation_factor_bits = sci_dat.decimation_factor_bits
    output.pulser_bits = sci_dat.pulser_bits
    output.detector_bits = sci_dat.detector_bits
    output.aaee_bits = sci_dat.aaee_bits
    output.noise_bits = sci_dat.noise_bits
    output.duration = sci_dat.duration
    output.sci_time_delta = sci_dat.time_delta
    output.sci_delaytime = sci_dat.delaytime
    output.sci_apid = sci_dat.apid
    output.sci_seqn = sci_dat.seqn
    output.sci_seqn_delta = sci_dat.seqn_delta
    output.sci_packet_size = sci_dat.packet_size
    output.sci_time_res = sci_dat.time_res
   ; output.decimation_factor_bits = sci_dat.decimation_factor_bits
    ;output.pulser_bits = sci_dat.pulser_bits
  ;  output.detector_bits = sci_dat.detector_bits
   ; output.aaee_bits = sci_dat.aaee_bits
   ; output.noise_bits = sci_dat.noise_bits
   ; output.duration = sci_dat.duration
    output.sci_gap = sci_dat.gap
    
    ;output.sci_nonlut_mode = sci_dat.sci_nonlut_mode
    ;output.sci_decimate = sci_dat.sci_decimate
    ;output.sci_translate = sci_dat.sci_translate     these don't exist in the science packets
    ;output.sci_resolution = sci_dat.sci_resolution

  endif

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

  if n_elements(nse_dat) eq nd then begin
    ; nse:
    output.nse_histogram =  nse_dat.histogram
    output.nse_counts = nse_dat.raw
    ; output.nse_sigma = nse_dat.sigma
    ; output.nse_baseline = nse_dat.baseline
    ; output.nse_total6 = nse_dat.total6

    output.nse_duration = nse_dat.duration
    output.nse_offset = output.time - nse_dat.time
    output.nse_time_delta = nse_dat.time_delta
    output.nse_delaytime = nse_dat.delaytime
    output.nse_apid = nse_dat.apid
    output.nse_seqn = nse_dat.seqn
    output.nse_seqn_delta = nse_dat.seqn_delta
    output.nse_packet_size = nse_dat.packet_size
    output.nse_ptcu_bits = nse_dat.ptcu_bits
    output.nse_time_res = nse_dat.time_res
    output.nse_decimation_factor_bits = nse_dat.decimation_factor_bits
    output.nse_pulser_bits = nse_dat.pulser_bits
    output.nse_detector_bits = nse_dat.detector_bits
    output.nse_aaee_bits = nse_dat.aaee_bits
    output.nse_noise_bits = nse_dat.noise_bits
    output.nse_duration = nse_dat.duration
    output.nse_gap = nse_dat.gap
  endif


  if n_elements(hkp_dat) eq nd then begin

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
    output.sci_resolution = hkp_dat.sci_resolution   ; don't overwrite
    output.sci_translate = hkp_dat.sci_translate     ; don't overwrite
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


    ; Instead of recording time, met, grtime, unixtime
    ; tod_day, tod_millisec, tod_microsec for each packet,
    ; get nse/hkp_offset:
    output.hkp_offset = output.time - hkp_dat.time

    ; Always same across nse_dat/hkp_dat/sci_dat
    output.fpga_rev = hkp_dat.fpga_rev
    output.user_09 = hkp_dat.user_09

    ; Reead the header info for each packet even if
    ; redundant for debugging:
    ; - time_delta (swfo_ccsds_data)
    output.hkp_time_delta = hkp_dat.time_delta
    ; ; - delaytime (swfo_ccsds_data)
    output.hkp_delaytime = hkp_dat.delaytime
    ; - APID (swfo_ccsds_data)
    output.hkp_apid = hkp_dat.apid
    ; - SEQN (swfo_ccsds_data)
    output.hkp_seqn = hkp_dat.seqn
    ; - SEQN_DELTA (swfo_ccsds_data)
    output.hkp_seqn_delta = hkp_dat.seqn_delta
    ; - Packet size (swfo_ccsds_data)
    output.hkp_packet_size = hkp_dat.packet_size
    ; - ptcu_bits (swfo_data_select):
    output.hkp_ptcu_bits = hkp_dat.ptcu_bits
    ;output.ptcu_bits = sci_dat.ptcu_bits
    ; - time res (swfo_data_select):
    output.hkp_time_res = hkp_dat.time_res
    ; - decimation_factor_bits (swfo_data_select):
    output.hkp_decimation_factor_bits = hkp_dat.decimation_factor_bits
    ; - pulser_bits (swfo_data_select):
    output.hkp_pulser_bits = hkp_dat.pulser_bits
    ; - detector_bits (swfo_data_select):
    output.hkp_detector_bits = hkp_dat.detector_bits
    ; - aaee_bits (swfo_data_select):
    output.hkp_aaee_bits = hkp_dat.aaee_bits
    ; - noise_bits (swfo_data_select):
    output.hkp_noise_bits = hkp_dat.noise_bits
    ; - duration = 1 + time_res(swfo_stis_ccsds_header_decom)
    output.hkp_duration = hkp_dat.duration
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
  endif


  ; apid 100
  if n_elements(sc100_dat) eq nd then begin
    output.reaction_wheel_speed_rpm = sc100_dat.reaction_wheel_speed_rpm
    output.adcs_state_0wait_1detumble_2acqsun_3point_4deltav_5earth = sc100_dat.adcs_state_0wait_1detumble_2acqsun_3point_4deltav_5earth
    output.sun_point_status_0idle_1magpoint_2intrusion_3avoidance_4maneuver = sc100_dat.sun_point_status_0idle_1magpoint_2intrusion_3avoidance_4maneuver
    output.sun_point_minimum_keepout_angle = sc100_dat.sun_point_minimum_keepout_angle
    output.measured_sun_vector_xyz = sc100_dat.measured_sun_vector_xyz
    output.control_torque_xyz = sc100_dat.control_torque_xyz
    output.rt_critical_vc = sc100_dat.rt_critical_vc
    output.star_tracker_attitude_q1234 = sc100_dat.star_tracker_attitude_q1234
;    output.star_tracker_attitude_q1234 = sc100_dat.start_tracker_attitude_q1234
    output.rt_non_critical_vc = sc100_dat.rt_non_critical_vc
    output.body_frame_attitude_q1234 = sc100_dat.body_frame_attitude_q1234
    output.pbk_critical_vc = sc100_dat.pbk_critical_vc
    output.fsw_transfer_frame_accept_counter = sc100_dat.fsw_transfer_frame_accept_counter
    output.fsw_transfer_frame_reject_counter = sc100_dat.fsw_transfer_frame_reject_counter
    output.fsw_command_accept_counter = sc100_dat.fsw_command_accept_counter
    output.fsw_command_reject_counter = sc100_dat.fsw_command_reject_counter
    output.tmon_master_enabled = sc100_dat.tmon_master_enabled
    output.tmon_001_sample_enabled_armed_triggered = sc100_dat.tmon_001_sample_enabled_armed_triggered
    output.fsw_power_management_bits = sc100_dat.fsw_power_management_bits
    output.battery_current_amps = sc100_dat.battery_current_amps
    output.battery_temperature_c = sc100_dat.battery_temperature_c
    output.battery_voltage_v = sc100_dat.battery_voltage_v
    output.tmon_230_enabled_armed_triggered = sc100_dat.tmon_230_enabled_armed_triggered
    output.tmon_231_enabled_armed_triggered = sc100_dat.tmon_231_enabled_armed_triggered
    output.tmon_232_enabled_armed_triggered = sc100_dat.tmon_232_enabled_armed_triggered
    output.tmon_233_enabled_armed_triggered = sc100_dat.tmon_233_enabled_armed_triggered
    output.tmon_234_enabled_armed_triggered = sc100_dat.tmon_234_enabled_armed_triggered
    output.tmon_235_enabled_armed_triggered = sc100_dat.tmon_235_enabled_armed_triggered
    output.tmon_236_enabled_armed_triggered = sc100_dat.tmon_236_enabled_armed_triggered
    output.reaction_wheel_overspeed_fault_bits = sc100_dat.reaction_wheel_overspeed_fault_bits
    output.sband_downlink_rate = sc100_dat.sband_downlink_rate
  endif

  ; apid 110
  if n_elements(sc110_dat) eq nd then begin
    output.iru_bits = sc110_dat.iru_bits      
    output.modeled_spacecraft_sun_vxyz = sc110_dat.modeled_spacecraft_to_sun_vxyz   ; parameter missing - uncomment when corrected

  endif


  return,output

end

