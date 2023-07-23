; $LastChangedBy: ali $
; $LastChangedDate: 2023-04-24 16:21:20 -0700 (Mon, 24 Apr 2023) $
; $LastChangedRevision: 31787 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SWFO/STIS/swfo_stis_ccsds_header_decom.pro $


function swfo_stis_ccsds_header_decom,ccsds
  ccsds_data = swfo_ccsds_data(ccsds)

  str = {$
    time:ccsds.time,  $
    time_delta:ccsds.time_delta, $
    met:ccsds.met,   $
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
    pulser_frequency:[0.,0.]$
  }
  str.duration=1+str.time_res
  str.noise_period=str.noise_bits and 255u
  str.noise_res=ishft(str.noise_bits,-8) and 7u
  if str.fpga_rev lt 'CC'x then timer_period=10 else timer_period=2.5 ;microseconds
  str.pulser_frequency=[1.,.5]/(1e-6*timer_period*str.noise_period) ;[pulser,noise]
  
  ;dprint,string(str.apid,format = '("0x",Z3)'),str.time-systime(1)

  return,str

end