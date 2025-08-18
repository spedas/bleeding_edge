; $LastChangedBy: davin-mac $
; $LastChangedDate: 2024-05-21 12:27:38 -0700 (Tue, 21 May 2024) $
; $LastChangedRevision: 32621 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SWFO/swfo_sc_120_apdat__define.pro $


function swfo_sc_120_apdat::decom,ccsds,source_dict=source_dict

  ccsds_data = swfo_ccsds_data(ccsds)

  stis_power=                       swfo_data_select(ccsds_data,93 *8+6, 1)
  stis_overcurrent_trip=            swfo_data_select(ccsds_data,95 *8+3, 1)
  stis_overcurrent_enable_status=   swfo_data_select(ccsds_data,95 *8+4, 1)
  stis_survival_heater_power=       swfo_data_select(ccsds_data,207*8+5, 1)
  stis_survival_heater_oc_trip=     swfo_data_select(ccsds_data,1674, 1)

  ccor_power=                       swfo_data_select(ccsds_data,99 *8+6, 1)
  ccor_overcurrent_trip=            swfo_data_select(ccsds_data,101*8+3, 1)
  ccor_overcurrent_enable_status=   swfo_data_select(ccsds_data,101*8+4, 1)
  ccor_survival_heater_power=       swfo_data_select(ccsds_data,226*8+1, 1)
  ccor_survival_heater_oc_trip=     swfo_data_select(ccsds_data,227*8+6, 1)

  mag_arm_power=                    swfo_data_select(ccsds_data,109*8+5, 1)
  mag_power=                        swfo_data_select(ccsds_data,109*8+6, 1)
  mag_overcurrent_trip=             swfo_data_select(ccsds_data,111*8+3, 1)
  mag_overcurrent_enable_status=    swfo_data_select(ccsds_data,111*8+4, 1)
  mag_survival_heater_power=        swfo_data_select(ccsds_data,266*8+1, 1)
  mag_survival_heater_oc_trip=      swfo_data_select(ccsds_data,267*8+6, 1)

  swips_arm_power=                  swfo_data_select(ccsds_data,111*8+5, 1)
  swips_power=                      swfo_data_select(ccsds_data,111*8+6, 1)
  swips_overcurrent_trip=           swfo_data_select(ccsds_data,113*8+3, 1)
  swips_overcurrent_enable_status=  swfo_data_select(ccsds_data,113*8+4, 1)
  swips_survival_heater_power=      swfo_data_select(ccsds_data,256*8+3, 1)
  swips_survival_heater_oc_trip=    swfo_data_select(ccsds_data,258*8  , 1)

  reaction_wheel1_power=                       swfo_data_select(ccsds_data,90 *8  , 1)
  reaction_wheel1_overcurrent_trip=            swfo_data_select(ccsds_data,91 *8+5, 1)
  reaction_wheel1_overcurrent_enable_status=   swfo_data_select(ccsds_data,91 *8+6, 1)

  reaction_wheel2_power=                       swfo_data_select(ccsds_data,185*8+2, 1)
  reaction_wheel2_overcurrent_trip=            swfo_data_select(ccsds_data,186*8+7, 1)
  reaction_wheel2_overcurrent_setpoint_raw=    swfo_data_select(ccsds_data,187*8  ,12)

  reaction_wheel3_power=                       swfo_data_select(ccsds_data,241*8+1, 1)
  reaction_wheel3_overcurrent_trip=            swfo_data_select(ccsds_data,242*8+6, 1)
  reaction_wheel3_overcurrent_setpoint_raw=    swfo_data_select(ccsds_data,242*8+7,12)

  reaction_wheel4_power=                       swfo_data_select(ccsds_data,91 *8+7, 1)
  reaction_wheel4_overcurrent_trip=            swfo_data_select(ccsds_data,93 *8+4, 1)
  reaction_wheel4_overcurrent_enable_status=   swfo_data_select(ccsds_data,93 *8+5, 1)

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
    tod_day:                          swfo_data_select(ccsds_data,6  *8  ,16),$
    tod_millisec:                     swfo_data_select(ccsds_data,8  *8  ,32),$
    tod_microsec:                     swfo_data_select(ccsds_data,12 *8  ,16),$
    power_commanded_charge_control_mode:swfo_data_select(ccsds_data,14 *8  , 2),$
    power_commanded_flag_manual_mode:   swfo_data_select(ccsds_data,14 *8+2, 1),$
    power_fsw_pcm_sas_command_state:    swfo_data_select(ccsds_data,14 *8+3, 1),$
    power_fsw_charge_control_status:    swfo_data_select(ccsds_data,14 *8+4, 1),$
    power_commanded_charge_control_cycle_time_ms:swfo_data_select(ccsds_data,15 *8  ,16),$
    ;power_calculated_vt_setpoint_for_vt_mode:swfo_data_select(ccsds_data,17 *8  ,64),$
    ;power_latest_commanded_voltage_offset:   swfo_data_select(ccsds_data,25 *8  ,64),$
    power_commanded_flag_use_safe_vt_offset: swfo_data_select(ccsds_data,33 *8  , 8),$
    instrument_power_bits:((swips_power*2b+mag_power)*2b+ccor_power)*2b+stis_power,$
    instrument_current_amps:-.02727+.002447*swfo_data_select(ccsds_data,[93,99,109,111]*8+7,12),$
    instrument_survival_heater_current_amps:.000357*swfo_data_select(ccsds_data,[207*8+6,[214,254]*8+2,244*8+4],12),$
    instrument_survival_heater_oc_setpoint_amps:.000357*swfo_data_select(ccsds_data,[209*8+3,[215,255]*8+7,246*8+1],12),$
    stis_power_bits:(((stis_power*2b+stis_overcurrent_trip)*2b+stis_overcurrent_enable_status)*2b+stis_survival_heater_power)*2b+stis_survival_heater_oc_trip,$
    ccor_power_bits:(((ccor_power*2b+ccor_overcurrent_trip)*2b+ccor_overcurrent_enable_status)*2b+ccor_survival_heater_power)*2b+ccor_survival_heater_oc_trip,$
    mag_power_bits:((((mag_arm_power*2b+mag_power)*2b+mag_overcurrent_trip)*2b+mag_overcurrent_enable_status)*2b+mag_survival_heater_power)*2b+mag_survival_heater_oc_trip,$
    swips_power_bits:((((swips_arm_power*2b+swips_power)*2b+swips_overcurrent_trip)*2b+swips_overcurrent_enable_status)*2b+swips_survival_heater_power)*2b+swips_survival_heater_oc_trip,$
    reaction_wheel_power_bits:((reaction_wheel4_power*2b+reaction_wheel3_power)*2b+reaction_wheel2_power)*2b+reaction_wheel1_power,$
    reaction_wheel_current_amps:[-.02727+.002447*swfo_data_select(ccsds_data,90 *8+1,12),.00357*swfo_data_select(ccsds_data,[185*8+3,241*8+2],12),-.02727+.002447*swfo_data_select(ccsds_data,92 *8,12)],$
    subsystem_power_bits:((((swfo_data_select(ccsds_data,86*8+2,1)*2b+swfo_data_select(ccsds_data,95*8+6,1))*2b+swfo_data_select(ccsds_data,97*8+6,1))*2b+swfo_data_select(ccsds_data,105*8+6,1))*2b+swfo_data_select(ccsds_data,107*8+6,1))*2b+swfo_data_select(ccsds_data,172*8+2,1),$
    subsystem_current_amps:[.00357*swfo_data_select(ccsds_data,172*8+3,12),-.02727+.002447*swfo_data_select(ccsds_data,[[107,105,97,95]*8+7,86*8+3],12)],$
    gap:ccsds.gap }

  return,datastr

end


pro swfo_sc_120_apdat__define
  void = {swfo_sc_120_apdat, $
    inherits swfo_gen_apdat $    ; superclass
  }
end

