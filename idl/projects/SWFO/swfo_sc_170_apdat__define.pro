; $LastChangedBy: davin-mac $
; $LastChangedDate: 2024-05-21 12:27:38 -0700 (Tue, 21 May 2024) $
; $LastChangedRevision: 32621 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SWFO/swfo_sc_170_apdat__define.pro $


function swfo_sc_170_apdat::decom,ccsds,source_dict=source_dict

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
    tod_day:                          swfo_data_select(ccsds_data,6  *8  ,16),$
    tod_millisec:                     swfo_data_select(ccsds_data,8  *8  ,32),$
    tod_microsec:                     swfo_data_select(ccsds_data,12 *8  ,16),$
    stis_automessaging_enabled:       swfo_data_select(ccsds_data,28 *8+3, 1),$
    stis_communications_enabled:      swfo_data_select(ccsds_data,28 *8+4, 1),$
    stis_tod_enabled:                 swfo_data_select(ccsds_data,28 *8+5, 1),$
    stis_tx_protocol_error_counter:   swfo_data_select(ccsds_data,37 *8  , 8),$
    stis_rx_protocol_error_counter:   swfo_data_select(ccsds_data,38 *8  , 8),$
    stis_tod_transmit_success_counter:swfo_data_select(ccsds_data,39 *8  , 8),$
    stis_tod_transmit_fail_counter:   swfo_data_select(ccsds_data,40 *8  , 8),$
    stis_command_counter:             swfo_data_select(ccsds_data,41 *8  , 8),$
    stis_command_fail_counter:        swfo_data_select(ccsds_data,42 *8  , 8),$
    stis_telemetry_counter:           swfo_data_select(ccsds_data,43 *8  , 8),$
    stis_telemetry_fail_counter:      swfo_data_select(ccsds_data,44 *8  , 8),$
    stis_invalid_version_number_ctr:  swfo_data_select(ccsds_data,45 *8  , 8),$
    stis_invalid_type_indicator_ctr:  swfo_data_select(ccsds_data,46 *8  , 8),$
    stis_invalid_secondary_header_ctr:swfo_data_select(ccsds_data,47 *8  , 8),$
    stis_last_packet_length_field:    swfo_data_select(ccsds_data,48 *8  ,32),$
    stis_last_packet_length_total:    swfo_data_select(ccsds_data,52 *8  ,32),$
    mag_automessaging_enabled:        swfo_data_select(ccsds_data,80 *8  , 1),$
    mag_communications_enabled:       swfo_data_select(ccsds_data,80 *8+1, 1),$
    mag_tod_enabled:                  swfo_data_select(ccsds_data,80 *8+2, 1),$
    mag_tx_protocol_error_counter:    swfo_data_select(ccsds_data,81 *8  , 8),$
    mag_rx_protocol_error_counter:    swfo_data_select(ccsds_data,82 *8  , 8),$
    mag_tod_transmit_success_counter: swfo_data_select(ccsds_data,83 *8  , 8),$
    mag_tod_transmit_fail_counter:    swfo_data_select(ccsds_data,84 *8  , 8),$
    mag_invalid_version_number_ctr:   swfo_data_select(ccsds_data,85 *8  , 8),$
    mag_invalid_type_indicator_ctr:   swfo_data_select(ccsds_data,86 *8  , 8),$
    mag_invalid_secondary_header_ctr: swfo_data_select(ccsds_data,87 *8  , 8),$
    mag_last_packet_length_field:     swfo_data_select(ccsds_data,88 *8  ,32),$
    mag_last_packet_length_total:     swfo_data_select(ccsds_data,92 *8  ,32),$
    mag_command_counter:              swfo_data_select(ccsds_data,96 *8  , 8),$
    mag_command_fail_counter:         swfo_data_select(ccsds_data,97 *8  , 8),$
    mag_telemetry_counter:            swfo_data_select(ccsds_data,98 *8  , 8),$
    mag_telemetry_fail_counter:       swfo_data_select(ccsds_data,99 *8  , 8),$
    swips_automessaging_enabled:      swfo_data_select(ccsds_data,80 *8+3, 1),$
    swips_communications_enabled:     swfo_data_select(ccsds_data,80 *8+4, 1),$
    swips_tod_enabled:                swfo_data_select(ccsds_data,80 *8+5, 1),$
    swips_tx_protocol_error_counter:  swfo_data_select(ccsds_data,100*8  , 8),$
    swips_rx_protocol_error_counter:  swfo_data_select(ccsds_data,101*8  , 8),$
    swips_tod_transmit_success_counter:swfo_data_select(ccsds_data,102*8  , 8),$
    swips_tod_transmit_fail_counter:  swfo_data_select(ccsds_data,103*8  , 8),$
    swips_invalid_version_number_ctr: swfo_data_select(ccsds_data,104*8  , 8),$
    swips_invalid_type_indicator_ctr: swfo_data_select(ccsds_data,105*8  , 8),$
    swips_invalid_secondary_header_ctr:swfo_data_select(ccsds_data,106*8  , 8),$
    swips_last_packet_length_field:   swfo_data_select(ccsds_data,107*8  ,32),$
    swips_last_packet_length_total:   swfo_data_select(ccsds_data,111*8  ,32),$
    swips_command_counter:            swfo_data_select(ccsds_data,115*8  , 8),$
    swips_command_fail_counter:       swfo_data_select(ccsds_data,116*8  , 8),$
    swips_telemetry_counter:          swfo_data_select(ccsds_data,117*8  , 8),$
    swips_telemetry_fail_counter:     swfo_data_select(ccsds_data,118*8  , 8),$
    gap:ccsds.gap }

  return,datastr

end


pro swfo_sc_170_apdat__define
  void = {swfo_sc_170_apdat, $
    inherits swfo_gen_apdat $    ; superclass
  }
end

