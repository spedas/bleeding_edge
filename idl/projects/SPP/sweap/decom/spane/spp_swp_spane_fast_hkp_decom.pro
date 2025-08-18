; $LastChangedBy: phyllisw $
; $LastChangedDate: 2023-07-06 12:32:38 -0700 (Thu, 06 Jul 2023) $
; $LastChangedRevision: 31938 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SPP/sweap/decom/spane/spp_swp_spane_fast_hkp_decom.pro $

;;; Fast Housekeeping Data as of SPAN-E FPGA rev #22, 3/10/2015

function spp_swp_spane_fast_hkp_decom,ccsds, source_dict=source_dict  ; ,ptp_header=ptp_header,apdat=apdat

  ;;----------------------
  ;; 1. 20 CCSDS header bytes (should be 10?)
  ;; 2. 512 ADC values, each 2 bytes

  ccsds_data = spp_swp_ccsds_data(ccsds)

  data = swap_endian(/swap_if_little_endian,  uint(ccsds_data,20,512))
  wi, 1
  plot, data

  header    = ccsds_data[0:19]
  ;  ns = pksize - 20
  ;  log_flag    = header[12]
  mode1 = header[13]
  mode2 = (swap_endian(uint(ccsds_data,14,1) ,/swap_if_little_endian ))[0]
  f0 = (swap_endian(ulong(header,16,1), /swap_if_little_endian))[0]
  status_flag = header[18]
  peak_bin = header[19]

  fhk = { $
    ;time:       ptp_header.ptp_time, $
    time:         ccsds.time, $
    MET:          ccsds.met,  $
    apid:         ccsds.apid, $
    seqn:         ccsds.seqn,  $
    seqn_delta:   ccsds.seqn_delta,  $
    seqn_group:   ccsds.seqn_group,  $
    pkt_size:     ccsds.pkt_size,  $
    source_apid:  ccsds.source_apid,  $
    source_hash:  ccsds.source_hash,  $
    compr_ratio:  ccsds.compr_ratio,  $
    ;times:       ccsds.time + (0.87*findgen(512)/512.); New York Second
    ;delay_time:  ptp_header.ptp_time - ccsds.time, $
    mode1:        mode1,  $
    mode2:        mode2,  $
    ;f0:          f0,$
    ;status_flag: status_flag,$
    peak_bin:     peak_bin, $

    ;; 16 bits x offset 20 bytes x 512 values
    ADC:          data, $
    gap:          ccsds.gap $
  }

  return,fhk

end
