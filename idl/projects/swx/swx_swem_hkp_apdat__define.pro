; $LastChangedBy: davin-mac $
; $LastChangedDate: 2023-12-02 00:05:21 -0800 (Sat, 02 Dec 2023) $
; $LastChangedRevision: 32261 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/swx/swx_swem_hkp_apdat__define.pro $

function swx_swem_hkp_apdat::decom,ccsds, source_dict=source_dict  ; header,ptp_header=ptp_header

  if n_params() eq 0 then begin
    dprint,'Not working yet.'
    return,!null
  endif

  ccsds_data = swx_ccsds_data(ccsds)

  if ccsds.pkt_size lt 42 then begin
    if debug(2) then begin
      dprint,'error',ccsds.pkt_size,dlevel=2
      hexprint,ccsds_data
      return,0
    endif
  endif

  ;values = swap_endian(ulong(ccsds_data,10,11) )

  temp_par = swx_therm_temp()
  temp_par_10bit      = temp_par
  temp_par_10bit.xmax = 1023

  ;str = {time:   ccsds.time  ,$
  ;     seqn: ccsds.seqn, $
  ;     mon_3p3_c:    ( swap_endian(uint(ccsds_data, 192/8)) and '3ff'x ) * .997  , $
  ;     mon_3p3_v:    ( swap_endian(uint(ccsds_data, 144/8)) and '3ff'x ) * .0035  , $
  ;     gap:  ccsds.gap }
  ;
  str2 = {$
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
    dcb_temp:   func( (swap_endian(uint(ccsds_data, 86/8)) and '3ff'x  ) * 1.,param = temp_par_10bit)   ,  $
    lvps_temp:  func( ( swap_endian(uint(ccsds_data, 102/8)) and '3ff'x ) * 1.,param = temp_par_10bit)   , $
    swem_22_V:  ( swap_endian(uint(ccsds_data, 118/8)) and '3ff'x ) *.0235, $
    swem_3p6_V:  ( swap_endian(uint(ccsds_data, 134/8)) and '3ff'x ) *  .00942, $
    swem_3p3_V:  ( swap_endian(uint(ccsds_data, 150/8)) and '3ff'x ) *  .00411 , $
    swem_1p5_V:  ( swap_endian(uint(ccsds_data, 166/8)) and '3ff'x ) *  .00235 , $
    swem_1p5_C:  ( swap_endian(uint(ccsds_data, 182/8)) and '3ff'x ) *  .913 , $
    swem_3p3_C:  ( swap_endian(uint(ccsds_data, 198/8)) and '3ff'x ) *  .997 , $
    spc_22_C:  ( swap_endian(uint(ccsds_data, 214/8)) and '3ff'x ) *  .507 , $
    spb_22_C:  ( swap_endian(uint(ccsds_data, 230/8)) and '3ff'x ) *  .311  , $
    spa_22_C:  ( swap_endian(uint(ccsds_data, 246/8)) and '3ff'x ) *  .311  , $
    spi_22_C:   ( swap_endian(uint(ccsds_data, 262/8)) and '3ff'x ) * .311  , $
    spb_22_temp:  func( (swap_endian(uint(ccsds_data, 278/8)) and '3ff'x ) *  1.,param = temp_par_10bit)  , $
    spa_22_temp:   func( (swap_endian(uint(ccsds_data, 294/8)) and '3ff'x ) * 1. ,param = temp_par_10bit) , $
    spi_22_temp:   func( (swap_endian(uint(ccsds_data, 310/8)) and '3ff'x ) * 1. ,param = temp_par_10bit) , $
    gap:  ccsds.gap }

  return,str2

end


function swx_swem_hkp_apdat::cdf_global_attributes

  global_att = self.swx_gen_apdat::cdf_global_attributes()
  global_att['Descriptor'] = 'SWEM>SWEAP Electronics Module'
  global_att['Sensor'] = 'SWEM'
  global_att = global_att + self.sw_version()

  return,global_att
end


PRO swx_swem_hkp_apdat__define

  void = {swx_swem_hkp_apdat, $
    inherits swx_gen_apdat, $    ; superclass
    flag: 0 $
  }
END
