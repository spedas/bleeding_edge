; $LastChangedBy: davin-mac $
; $LastChangedDate: 2025-11-22 07:53:52 -0800 (Sat, 22 Nov 2025) $
; $LastChangedRevision: 33864 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SWFO/swfo_sc_100_apdat__define.pro $


function swfo_sc_100_apdat::decom,ccsds,source_dict=source_dict

  ccsds_data = swfo_ccsds_data(ccsds)

  datastr = {$
    time:ccsds.time,  $
    time_delta:ccsds.time_delta, $
    met:ccsds.met,   $
    grtime: ccsds.grtime,  $
    delaytime: ccsds.delaytime, $
    apid:ccsds.apid,  $
    seqn:ccsds.seqn,$
    seqn_delta:ccsds.seqn_delta,$
    packet_size:ccsds.pkt_size,$
    vcid: ccsds.vcid, $
    vcid_seqn: ccsds.vcid_seqn, $
    file_hash: ccsds.file_hash, $
    replay:    ccsds.replay , $
    station:    ccsds.station  , $
    tod_day:      ccsds.day,  $   ;                    swfo_data_select(ccsds_data,  6*8,16),$
    tod_millisec: ccsds.millisec,  $   ;                    swfo_data_select(ccsds_data,  8*8,32),$
    tod_microsec:  ccsds.microsec,  $   ;                   swfo_data_select(ccsds_data, 12*8,16),$
    flight_software_version_number:   swfo_data_select(ccsds_data, 14*8,32,/signed),$
    packet_definition_version_number: float(swfo_data_select(ccsds_data, 18*8,32),0),$
    adcs_state_0wait_1detumble_2acqsun_3point_4deltav_5earth:swfo_data_select(ccsds_data,22*8,3),$
    attitude_error_xyz_deg:57.29578e-4*swfo_data_select(ccsds_data, [23,25,27]*8,16,/signed),$
    rate_error_xyz_deg_per_sec:4e-5*swfo_data_select(ccsds_data, [29,31,33]*8,16,/signed),$
    attitude_rate_error_bits:swfo_data_select(ccsds_data,35*8,4),$
    sun_point_status_0idle_1magpoint_2intrusion_3avoidance_4maneuver:swfo_data_select(ccsds_data,35*8+4,3),$
    sun_point_minimum_keepout_angle:  57.29578e-4*swfo_data_select(ccsds_data, 36*8,16,/signed),$
    control_torque_xyz:               3.2e-4*swfo_data_select(ccsds_data, [38,40,42]*8,16,/signed),$
    reaction_wheel_torque_command_nm:double(swfo_data_select(ccsds_data,[45,53,61,376]*8,64),0,4),$
    rt_critical_vc:                   swfo_data_select(ccsds_data, 69*8+2, 6),$
    star_tracker_attitude_q1234:3.2e-5*swfo_data_select(ccsds_data,[70:76:2]*8,16,/signed),$
    rt_non_critical_vc:               swfo_data_select(ccsds_data, 78*8+2, 6),$
    star_tracker_rate_vector_xyz:1.146e-4*swfo_data_select(ccsds_data,[79:83:2]*8,16,/signed),$
    body_frame_attitude_q1234:3.2e-5*swfo_data_select(ccsds_data,[86:92:2]*8,16,/signed),$
    body_frame_rate_xyz_deg_per_sec:4e-4*swfo_data_select(ccsds_data, [94,96,98]*8,16,/signed),$
    control_frame_sun_xyz:3.2e-5*swfo_data_select(ccsds_data,[101,103,105]*8,16,/signed),$
    solution_status_0bothstr_1onestr_12ronly_13bothst_14onest_15cssonly_16none:swfo_data_select(ccsds_data,107*8,5),$
    sun_sensor_raw_intensity_12_bit_adc:swfo_data_select(ccsds_data,[108:138:2]*8,16,/signed),$
    measured_sun_vector_xyz:3.2e-5*swfo_data_select(ccsds_data,[148,150,152]*8,16,/signed),$
    measured_sun_vector_status_0good_1coarse_2bad:swfo_data_select(ccsds_data,154*8, 2),$
    pbk_critical_vc:                  swfo_data_select(ccsds_data,154*8+2, 6),$
    fsw_transfer_frame_accept_counter:swfo_data_select(ccsds_data,155*8, 8),$
    fsw_transfer_frame_reject_counter:swfo_data_select(ccsds_data,156*8, 8),$
    fsw_command_accept_counter:       swfo_data_select(ccsds_data,157*8, 8),$
    fsw_command_reject_counter:       swfo_data_select(ccsds_data,158*8, 8),$
    tmon_master_enabled:              swfo_data_select(ccsds_data,237*8, 1),$
    tmon_001_sample_enabled_armed_triggered:swfo_data_select(ccsds_data,237*8+1, 3),$
    thruster_desat_inprogress_status:swfo_data_select(ccsds_data,238*8+6, 1),$
    fsw_power_management_bits:        swfo_data_select(ccsds_data,245*8  , 6),$
    attitude_valid:swfo_data_select(ccsds_data,245*8+6, 1),$
    rate_sensor_good_throughout:swfo_data_select(ccsds_data,245*8+7, 1),$
    battery_current_amps:             double(swfo_data_select(ccsds_data,246*8,64),0),$
    battery_temperature_c:            double(swfo_data_select(ccsds_data,254*8,64),0),$
    battery_voltage_v:                double(swfo_data_select(ccsds_data,262*8,64),0),$
    tmon_bits:                        swfo_data_select(ccsds_data,[280:374:8]*8,64),$
    tmon_230_enabled_armed_triggered: swfo_data_select(ccsds_data,364*8+6, 3),$
    tmon_231_enabled_armed_triggered: swfo_data_select(ccsds_data,365*8+1, 3),$
    tmon_232_enabled_armed_triggered: swfo_data_select(ccsds_data,365*8+4, 3),$
    tmon_233_enabled_armed_triggered: swfo_data_select(ccsds_data,365*8+7, 3),$
    tmon_234_enabled_armed_triggered: swfo_data_select(ccsds_data,366*8+2, 3),$
    tmon_235_enabled_armed_triggered: swfo_data_select(ccsds_data,366*8+5, 3),$
    tmon_236_enabled_armed_triggered: swfo_data_select(ccsds_data,367*8  , 3),$
    reaction_wheel_overspeed_fault_bits:swfo_data_select(ccsds_data,384*8  , 8),$
    thruster_momentum_control_status:swfo_data_select(ccsds_data,385*8+7, 1),$
    sband_downlink_rate:              swfo_data_select(ccsds_data,405*8  ,32),$
    total_system_momentum_xyz_nms:1e-2*swfo_data_select(ccsds_data,[409,411,413]*8,16,/signed),$
    thruster_1234_duration_seconds:1e-3*swfo_data_select(ccsds_data,[421:427:2]*8,16,/signed),$
    reaction_wheel_speed_rpm:    9.5493*double(swfo_data_select(ccsds_data,(429+indgen(4)*8)*8,64),0,4),$
    next_orbital_position_xyz_km:0.2380952380952*swfo_data_select(ccsds_data,[461,464,467]*8,24,/signed),$
    next_orbital_velocity_xyz_km_per_sec:1.12e-6*swfo_data_select(ccsds_data,[470,473,476]*8,24,/signed),$
    propagated_rate_xyz_deg_per_sec:4e-4*swfo_data_select(ccsds_data,[479,481,483]*8,16,/signed),$
    gap:ccsds.gap }

  return,datastr

end


pro swfo_sc_100_apdat__define
  void = {swfo_sc_100_apdat, $
    inherits swfo_gen_apdat $    ; superclass
  }
end

