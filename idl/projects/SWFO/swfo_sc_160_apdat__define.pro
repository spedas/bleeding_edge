; $LastChangedBy: ali $
; $LastChangedDate: 2024-08-19 18:29:54 -0700 (Mon, 19 Aug 2024) $
; $LastChangedRevision: 32796 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SWFO/swfo_sc_160_apdat__define.pro $


function swfo_sc_160_apdat::decom,ccsds,source_dict=source_dict

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
    pps_output_status_bits:           swfo_data_select(ccsds_data,578*8  , 8),$
    ssr_playback_status:              swfo_data_select(ccsds_data,502*8+4, 1),$
    ssr_percentage_full:              double(swfo_data_select(ccsds_data,363*8  ,64),0),$
    edac_error_count:                 swfo_data_select(ccsds_data,417*8  ,16),$
    flash_error_counts:               swfo_data_select(ccsds_data,[559:566]*8  ,8),$
    flash_successful_block_counts:    swfo_data_select(ccsds_data,[567:569]*8  ,8),$
    flash_edac_counts:                swfo_data_select(ccsds_data,[570:573]*8  ,8),$
    pbk_non_critical_vc:              swfo_data_select(ccsds_data,391*8  , 6),$
    gap:ccsds.gap }

  return,datastr

end


pro swfo_sc_160_apdat__define
  void = {swfo_sc_160_apdat, $
    inherits swfo_gen_apdat $    ; superclass
  }
end

