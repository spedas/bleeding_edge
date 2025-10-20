; $LastChangedBy: ali $
; $LastChangedDate: 2025-10-14 18:20:42 -0700 (Tue, 14 Oct 2025) $
; $LastChangedRevision: 33757 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SWFO/swfo_sc_110_apdat__define.pro $

function swfo_sc_110_rw_temps,temps
  temps=double(temps)
  c0=-220.0
  c1=0.0119
  c2=7.45e-7
  return,c0+c1*temps+c2*temps^2
end

function swfo_sc_110_apdat::decom,ccsds,source_dict=source_dict

  ccsds_data = swfo_ccsds_data(ccsds)
  rwc=9.16e-6
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
    desired_rates_xyz: 2e-4 * swfo_data_select(ccsds_data,[28,30,32]*8, 16,/signed),$
    desired_control_frame_sun_xyz: 3.2e-5 * swfo_data_select(ccsds_data,[34,36,38]*8, 16,/signed),$
    integral_error_xyz:57.29578e-6*swfo_data_select(ccsds_data, [40,42,44]*8,16,/signed),$
    desired_attitude_q1234:3.2e-5 * swfo_data_select(ccsds_data,[53:59:2]*8, 16,/signed),$
    desired_acceleration_xyz:1e-4* swfo_data_select(ccsds_data,[61,63,65]*8, 16,/signed),$
    star_tracker_tracked_star_count:swfo_data_select(ccsds_data, [141,142,143]*8,8),$
    body_momemtum_xyz:1e-2 * swfo_data_select(ccsds_data,[343,345,347]*8, 16,/signed),$
    feed_forward_torque_xyz:1e-4 * swfo_data_select(ccsds_data,[349,351,353]*8, 16,/signed),$
    propagated_body_frame_xyz_axis_angular_rate:4e-4 * swfo_data_select(ccsds_data,[355,357,359]*8, 16,/signed),$
    propagated_inertial_body_frame_q1234: 3.2e-5 * swfo_data_select(ccsds_data,[361:367:2]*8, 16,/signed),$
    measured_attitude_q1234_qmeasured: 3.2e-5 * swfo_data_select(ccsds_data,[369:375:2]*8, 16,/signed),$
    measured_attitude_q1234_qtriad: 3.2e-5 * swfo_data_select(ccsds_data,[378:384:2]*8, 16,/signed),$
    star_tracker_to_triad_error:57.29578e-4*swfo_data_select(ccsds_data, 386*8,16,/signed),$
    colatitude:57.29578e-4*swfo_data_select(ccsds_data, 388*8,16,/signed),$
    east_longitude:57.29578e-4*swfo_data_select(ccsds_data, 390*8,16,/signed),$
    modeled_intertial_sun_vxyz:3.2e-5*swfo_data_select(ccsds_data, [392,394,396]*8,16,/signed),$
    modeled_intertial_moon_vxyz:3.2e-5*swfo_data_select(ccsds_data, [398,400,402]*8,16,/signed),$
    rate_sensor_bias_123_deg_per_sec: 2e-6*swfo_data_select(ccsds_data,[657,659,661]*8, 16,/signed),$
    rate_sensor_attitude_q1234: 3.2e-5 * swfo_data_select(ccsds_data,[663:669:2]*8, 16,/signed),$
    iru_bits:                  swfo_data_select(ccsds_data,690*8+4, 8),$
    control_frame_rate_xyz_deg_per_sec:4e-4 * swfo_data_select(ccsds_data,[696,698,700]*8, 16,/signed),$
    control_frame_attitude_q1234: 3.2e-5 * swfo_data_select(ccsds_data,[702:708:2]*8, 16,/signed),$
    modeled_spacecraft_to_sun_vxyz: 3.2e-5 * swfo_data_select(ccsds_data,[710,712,714]*8, 16,/signed),$
    modeled_spacecraft_to_sun_distance_km:3.2e-5*swfo_data_select(ccsds_data,716*8, 16,/signed),$
    thruster_1234_duty_seconds:1e-3*swfo_data_select(ccsds_data,[809:815:2]*8,16,/signed),$
    thruster_1234_commanded_on_time_seconds:1e-3*swfo_data_select(ccsds_data,[817:823:2]*8,16,/signed),$
    thruster_torque_xyz_nm:7.6e-3*swfo_data_select(ccsds_data,[825,827,829]*8,16,/signed),$
    thruster_1234_stop_time_seconds:1e-3*swfo_data_select(ccsds_data,[833:839:2]*8,16,/signed),$
    reaction_wheel_xyz_torque_actual_nm: rwc*swfo_data_select(/signed,ccsds_data,[853,855,857]*8,16),$
    reaction_wheel_torque_command_nm:    rwc*swfo_data_select(/signed,ccsds_data,[859,861,863,865]*8,16),$
    reaction_wheel_model_rate_rpm:    .238724*swfo_data_select(/signed,ccsds_data,[867,869,871,873]*8,16),$
    reaction_wheel_torque_friction_nm:    rwc*swfo_data_select(/signed,ccsds_data,[875,877,879,881]*8,16),$
    reaction_wheel_null_torque_nm:    rwc*swfo_data_select(/signed,ccsds_data,[883,885,887,889]*8,16),$
    reaction_wheel_momentum_error_nms:    3.2e-3*swfo_data_select(/signed,ccsds_data,[891,893,895,897]*8,16),$
    reaction_wheel_bus_voltage_v:    .00123*swfo_data_select(ccsds_data,[899+indgen(4)*32]*8,16),$
    reaction_wheel_bus_current_amps:    .00019*swfo_data_select(ccsds_data,[901+indgen(4)*32]*8,16),$
    reaction_wheel_motor_voltage_v:    .000833*swfo_data_select(ccsds_data,[903+indgen(4)*32]*8,16),$
    reaction_wheel_motor_current_amps:    .00067*swfo_data_select(ccsds_data,[905+indgen(4)*32]*8,16),$
    reaction_wheel_bridge_optocoupler_voltage_v:    .00065*swfo_data_select(ccsds_data,[907+indgen(4)*32]*8,16),$
    reaction_wheel_adc_optocoupler_voltage_v:    .00023*swfo_data_select(ccsds_data,[909+indgen(4)*32]*8,16),$
    reaction_wheel_motor_temp:    swfo_sc_110_rw_temps(swfo_data_select(ccsds_data,[911+indgen(4)*32]*8,16)),$
    reaction_wheel_bearing_temp:    swfo_sc_110_rw_temps(swfo_data_select(ccsds_data,[913+indgen(4)*32]*8,16)),$
    reaction_wheel_fpga_temp:    swfo_sc_110_rw_temps(swfo_data_select(ccsds_data,[915+indgen(4)*32]*8,16)),$
    reaction_wheel_ops_temp:    swfo_sc_110_rw_temps(swfo_data_select(ccsds_data,[917+indgen(4)*32]*8,16)),$
    reaction_wheel_dcdc_5v_temp:    swfo_sc_110_rw_temps(swfo_data_select(ccsds_data,[919+indgen(4)*32]*8,16)),$
    reaction_wheel_dcdc_12v_temp:    swfo_sc_110_rw_temps(swfo_data_select(ccsds_data,[1060+indgen(4)*2]*8,16)),$
    reaction_wheel_sdc_fet_temp:    swfo_sc_110_rw_temps(swfo_data_select(ccsds_data,[921+indgen(4)*32]*8,16)),$
    reaction_wheel_sdc_int_temp:    swfo_sc_110_rw_temps(swfo_data_select(ccsds_data,[923+indgen(4)*32]*8,16)),$
    reaction_wheel_5v_current_monitor_ma:    .2*swfo_data_select(ccsds_data,[925+indgen(4)*32]*8,16),$
    reaction_wheel_3p3v_current_monitor_ma:    .2*swfo_data_select(ccsds_data,[927+indgen(4)*32]*8,16),$
    reaction_wheel_1p5v_current_monitor_ma:    .1*swfo_data_select(ccsds_data,[929+indgen(4)*32]*8,16),$
    thruster_force_xyz_newtons: 1e-3*swfo_data_select(ccsds_data,[1034,1036,1038]*8, 16,/signed),$
    thruster_accumulated_acceleration_xyz_km_per_s2: 1e-3*swfo_data_select(ccsds_data,[1040,1042,1044]*8, 16,/signed),$
    gyro_raw_channel_rate_123_deg_per_sec: 4e-4*swfo_data_select(ccsds_data,[1054,1056,1058]*8, 16,/signed),$
    gap:ccsds.gap }

  return,datastr

end


pro swfo_sc_110_apdat__define
  void = {swfo_sc_110_apdat, $
    inherits swfo_gen_apdat $    ; superclass
  }
end

