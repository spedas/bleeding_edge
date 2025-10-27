; $LastChangedBy: ali $
; $LastChangedDate: 2025-10-24 16:16:24 -0700 (Fri, 24 Oct 2025) $
; $LastChangedRevision: 33791 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SWFO/swfo_sc_130_apdat__define.pro $

function swfo_sc_130_apm_thermal_conversion,t
  c0=-68.0794195858006
  c1=0.144869362010568
  c2=-0.000162342734683212
  c3=1.0265159480653E-07
  c4=-3.03845645517943E-11
  c5=3.40727455823906E-15
  t=double(t)
  return,c0+c1*t+c2*t^2+c3*t^3+c4*t^4+c5*t^5
end

function swfo_sc_130_pcm_external_prt_sense_2kohm,t
  c0=-1200.490381
  c1=1.4040966
  c2=-0.000732947
  c3=1.99888E-07
  c4=-2.69365E-11
  c5=1.43803E-15
  t=double(t)
  return,c0+c1*t+c2*t^2+c3*t^3+c4*t^4+c5*t^5
end

function swfo_sc_130_pcm_external_prt_sense_100ohm,t
  c0=-678.9126059
  c1=14.31941028
  c2=-0.148233514
  c3=0.000833184
  c4=-2.27774E-06
  c5=2.43501E-09
  t=double(t)
  return,c0+c1*t+c2*t^2+c3*t^3+c4*t^4+c5*t^5
end

function swfo_sc_130_pcm_external_prt_sense_1kohm,t
  c0=-238.901861721998
  c1=0.135708288684465
  c2=7.49938676749371E-06
  c3=-7.71754245833273E-11
  c4=-3.60613872861498E-13
  c5=6.58979362925346E-17
  t=double(t)
  return,c0+c1*t+c2*t^2+c3*t^3+c4*t^4+c5*t^5
end

function swfo_sc_130_pcm_external_prt_sense_500ohm,t
  c0=-186.3008395
  c1=-0.05851723
  c2=0.000845779
  c3=-1.00238E-06
  c4=6.02719E-10
  c5=-1.43735E-13
  t=double(t)
  return,c0+c1*t+c2*t^2+c3*t^3+c4*t^4+c5*t^5
end

function swfo_sc_130_pcm_external_thermistor_sense,t
  c0=163.615155674542
  c1=-0.292816607306617
  c2=0.000299323362938377
  c3=-1.56180541252962E-07
  c4=3.81499456006284E-11
  c5=-3.52330588390463E-15
  t=double(t)
  return,c0+c1*t+c2*t^2+c3*t^3+c4*t^4+c5*t^5
end


function swfo_sc_130_apdat::decom,ccsds,source_dict=source_dict

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
    stis_interface_temp:              swfo_sc_130_pcm_external_thermistor_sense(swfo_data_select(ccsds_data,436,12)),$
    stis_temps:                       swfo_sc_130_apm_thermal_conversion(swfo_data_select(ccsds_data,[700,736],12)),$
    pcm_prt_2kohm_temps:              swfo_sc_130_pcm_external_prt_sense_2kohm(swfo_data_select(ccsds_data,23*8+indgen(6)*12,12)),$
    pcm_prt_100ohm_temps:             swfo_sc_130_pcm_external_prt_sense_100ohm(swfo_data_select(ccsds_data,32*8+indgen(4)*12,12)),$
    pcm_prt_1kohm_temps:              swfo_sc_130_pcm_external_prt_sense_1kohm(swfo_data_select(ccsds_data,[15*8+4+indgen(5)*12,38*8+indgen(7)*12],12)),$
    pcm_prt_500ohm_temp:              swfo_sc_130_pcm_external_prt_sense_500ohm(swfo_data_select(ccsds_data,48*8+4,12)),$
    pcm_thermistor_temps:             swfo_sc_130_pcm_external_thermistor_sense(swfo_data_select(ccsds_data,50*8+indgen(24)*12 ,12)),$
    apm_temps:                        swfo_sc_130_apm_thermal_conversion(swfo_data_select(ccsds_data,86*8+indgen(18)*12 ,12)),$
    gap:ccsds.gap }

  return,datastr

end


pro swfo_sc_130_apdat__define
  void = {swfo_sc_130_apdat, $
    inherits swfo_gen_apdat $    ; superclass
  }
end

