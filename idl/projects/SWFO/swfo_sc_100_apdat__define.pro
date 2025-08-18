; $LastChangedBy: ali $
; $LastChangedDate: 2025-07-22 18:25:22 -0700 (Tue, 22 Jul 2025) $
; $LastChangedRevision: 33487 $
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
    tod_day:                          swfo_data_select(ccsds_data,  6*8,16),$
    tod_millisec:                     swfo_data_select(ccsds_data,  8*8,32),$
    tod_microsec:                     swfo_data_select(ccsds_data, 12*8,16),$
    flight_software_version_number:   swfo_data_select(ccsds_data, 14*8,32,/signed),$
    packet_definition_version_number: float(swfo_data_select(ccsds_data, 18*8,32),0),$
    rt_critical_vc:                   swfo_data_select(ccsds_data, 69*8+2, 6),$
    rt_non_critical_vc:               swfo_data_select(ccsds_data, 78*8+2, 6),$
    pbk_critical_vc:                  swfo_data_select(ccsds_data,154*8+2, 6),$
    fsw_transfer_frame_accept_counter:swfo_data_select(ccsds_data,155*8, 8),$
    fsw_transfer_frame_reject_counter:swfo_data_select(ccsds_data,156*8, 8),$
    fsw_command_accept_counter:       swfo_data_select(ccsds_data,157*8, 8),$
    fsw_command_reject_counter:       swfo_data_select(ccsds_data,158*8, 8),$
    tmon_master_enabled:              swfo_data_select(ccsds_data,237*8, 1),$
    tmon_001_sample_enabled_armed_triggered:swfo_data_select(ccsds_data,237*8+1, 3),$
    tmon_230_enabled_armed_triggered: swfo_data_select(ccsds_data,364*8+6, 3),$
    tmon_231_enabled_armed_triggered: swfo_data_select(ccsds_data,365*8+1, 3),$
    tmon_232_enabled_armed_triggered: swfo_data_select(ccsds_data,365*8+4, 3),$
    tmon_233_enabled_armed_triggered: swfo_data_select(ccsds_data,365*8+7, 3),$
    tmon_234_enabled_armed_triggered: swfo_data_select(ccsds_data,366*8+2, 3),$
    tmon_235_enabled_armed_triggered: swfo_data_select(ccsds_data,366*8+5, 3),$
    tmon_236_enabled_armed_triggered: swfo_data_select(ccsds_data,367*8  , 3),$
    sband_downlink_rate:              swfo_data_select(ccsds_data,405*8  ,32),$
    fsw_power_management_bits:        swfo_data_select(ccsds_data,245*8  , 6),$
    adcs_state_0wait_1detumble_2acqsun_3point_4deltav_5earth:swfo_data_select(ccsds_data,22*8,3),$
    sun_point_status_0idle_1magpoint_2intrusion_3avoidance_4maneuver:swfo_data_select(ccsds_data,35*8+4,3),$
    battery_current_amps:             double(swfo_data_select(ccsds_data,246*8,64),0),$
    battery_temperature_c:            double(swfo_data_select(ccsds_data,254*8,64),0),$
    battery_voltage_v:                double(swfo_data_select(ccsds_data,262*8,64),0),$
    reaction_wheel_overspeed_fault_bits:swfo_data_select(ccsds_data,384*8  , 8),$
    reaction_wheel_torque_command:    double(swfo_data_select(ccsds_data,[45,53,61,376]*8,64),0,4),$
    reaction_wheel_speed_rpm:         9.5493*double(swfo_data_select(ccsds_data,(429+indgen(4)*8)*8,64),0,4),$
    ;reaction_wheel_speed_raw:         swfo_data_select(ccsds_data,[429,437,445,453]*8  ,64),$
    gap:ccsds.gap }

  return,datastr

end


pro swfo_sc_100_apdat__define
  void = {swfo_sc_100_apdat, $
    inherits swfo_gen_apdat $    ; superclass
  }
end

