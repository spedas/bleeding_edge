; $LastChangedBy: ali $
; $LastChangedDate: 2024-09-11 18:09:23 -0700 (Wed, 11 Sep 2024) $
; $LastChangedRevision: 32823 $
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
    iru_bits:                  swfo_data_select(ccsds_data,690*8+4, 8),$
    gap:ccsds.gap }

  return,datastr

end


pro swfo_sc_110_apdat__define
  void = {swfo_sc_110_apdat, $
    inherits swfo_gen_apdat $    ; superclass
  }
end

