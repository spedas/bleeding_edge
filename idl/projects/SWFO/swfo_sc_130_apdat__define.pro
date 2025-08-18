; $LastChangedBy: davin-mac $
; $LastChangedDate: 2024-05-21 12:27:38 -0700 (Tue, 21 May 2024) $
; $LastChangedRevision: 32621 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SWFO/swfo_sc_130_apdat__define.pro $

function swfo_sc_130_apm_thermal_conversion,temps
  temps=double(temps)
  c0=-68.0794195858006
  c1=0.144869362010568
  c2=-0.000162342734683212
  c3=1.0265159480653E-07
  c4=-3.03845645517943E-11
  c5=3.40727455823906E-15
  return,c0+c1*temps+c2*temps^2+c3*temps^3+c4*temps^4+c5*temps^5
end

function swfo_sc_130_pcm_thermal_conversion,temp0
  temp0=double(temp0)
  return,163.6-.2928*temp0+2.993e-4*temp0^2-1.5618e-7*temp0^3+3.815e-11*temp0^4-3.5233e-15*temp0^5
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
    stis_interface_temp:              swfo_sc_130_pcm_thermal_conversion(swfo_data_select(ccsds_data,436,12)),$
    stis_temps:                       swfo_sc_130_apm_thermal_conversion(swfo_data_select(ccsds_data,[700,736],12)),$
    pcm_temps_all:                    swfo_sc_130_pcm_thermal_conversion(swfo_data_select(ccsds_data,50*8+indgen(24)*12 ,12)),$
    apm_temps_all:                    swfo_sc_130_apm_thermal_conversion(swfo_data_select(ccsds_data,86*8+indgen(18)*12 ,12)),$
    gap:ccsds.gap }

  return,datastr

end


pro swfo_sc_130_apdat__define
  void = {swfo_sc_130_apdat, $
    inherits swfo_gen_apdat $    ; superclass
  }
end

