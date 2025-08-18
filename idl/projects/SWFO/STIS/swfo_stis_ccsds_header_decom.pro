; $LastChangedBy: rjolitz $
; $LastChangedDate: 2025-03-23 18:07:39 -0700 (Sun, 23 Mar 2025) $
; $LastChangedRevision: 33198 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SWFO/STIS/swfo_stis_ccsds_header_decom.pro $


function swfo_stis_ccsds_header_decom,ccsds
  ccsds_data = swfo_ccsds_data(ccsds)

  str = {$
    time:ccsds.time,  $
    time_delta:ccsds.time_delta, $
    met:ccsds.met,   $
    grtime: ccsds.grtime,  $
    delaytime: ccsds.delaytime, $
    apid:ccsds.apid,  $
    seqn:ccsds.seqn,$
    seqn_delta:ccsds.seqn_delta,$
    packet_size:ccsds.pkt_size,$
    tod_day:                swfo_data_select(ccsds_data,(6) *8,  24),$
    tod_millisec:           swfo_data_select(ccsds_data,(9) *8,  32),$
    tod_microsec:           swfo_data_select(ccsds_data,(13)*8,  16),$
    fpga_rev:               swfo_data_select(ccsds_data,(15)*8,   8),$
    ptcu_bits:              swfo_data_select(ccsds_data,(16)*8,   4),$
    time_res:               swfo_data_select(ccsds_data,(16)*8+4,12),$
    decimation_factor_bits: swfo_data_select(ccsds_data,(18)*8,   8),$
    user_09:                swfo_data_select(ccsds_data,(19)*8,   8),$
    pulser_bits:            swfo_data_select(ccsds_data,(20)*8,   8),$
    detector_bits:          swfo_data_select(ccsds_data,(21)*8,   8),$
    aaee_bits:              swfo_data_select(ccsds_data,(22)*8,   4),$
    noise_bits:             swfo_data_select(ccsds_data,(22)*8+4,12),$
    noise_period:0b,$
    noise_res:0b,$
    duration:0,$
    ; pulser_frequency:[0.,0.],$
    packet_checksum_reported:0u,$
    packet_checksum_calculated:0u,$
    packet_checksum_match:2b $
  }
  str.duration=1+str.time_res
  str.noise_period=str.noise_bits and 255u
  str.noise_res=ishft(str.noise_bits,-8) and 7u

  if str.fpga_rev lt 'CC'x then timer_period=10 else timer_period=2.5 ;microseconds
  ; str.pulser_frequency=[1.,.5]/(1e-6*timer_period*str.noise_period) ;[pulser,noise]

  if str.fpga_rev gt 'd1'x then begin
    str.packet_checksum_reported=256u*ccsds_data[-2]+ccsds_data[-1]
    str.packet_checksum_calculated=total(uint([['1a'x,'cf'x,'fc'x,'1d'x],ccsds_data[0:-3]]),/preserve)
    str.packet_checksum_match=str.packet_checksum_calculated eq str.packet_checksum_reported
  endif

  if str.fpga_rev eq '63'x then begin
    str.packet_checksum_reported=256u*ccsds_data[-2]+ccsds_data[-1]
    str.packet_checksum_calculated=total(uint(ccsds_data[0:-3]),/preserve)
    str.packet_checksum_match=str.packet_checksum_calculated eq str.packet_checksum_reported
  endif
  ;dprint,string(str.apid,format = '("0x",Z3)'),str.time-systime(1)

  return,str

end