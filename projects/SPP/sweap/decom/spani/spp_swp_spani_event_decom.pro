function spp_swp_spani_event_decom,ccsds, ptp_header=ptp_header, apdat=apdat, source_dict=source_dict 

  if n_params() eq 0 then begin
    dprint,'Not working yet.'
    return,!null
  endif


  ccsds_data = spp_swp_ccsds_data(ccsds)

  b = ccsds_data
  psize = 2048
  if n_elements(b) ne psize then begin
     dprint,dlevel=1, 'Size error ',ccsds.pkt_size,ccsds.apid
     return,0
  endif
  
  time = ccsds.time
  ;dprint,time_string(time)

  wrds = swap_endian(ulong(ccsds_data,20,(2048-20)/4) ,/swap_if_little_endian )
  tf = (wrds and '80000000'x) ne 0
  w_tt = where(tf,n_tt)
  w_dt= where(~tf,n_dt)
  tt =  uint(wrds)   ; and 'ffff'x                                                                                                                      
  dt = ishft(wrds,-16) and '1fff'x
  tof = wrds and 'fff'x
  ;tof = wrds and '7ff'x
  ;nonve = (wrds and '800'x) ne 0
  ch  = ishft(wrds and 'ffff'x,-12 )

  ttw=tt[w_tt]
  dttw = ttw - shift(ttw,1)
  dttw[0] = ttw[0]
  ttw2= total(/cum,/preserve,ulong(dttw))

  tw = replicate(0ul, n_elements(wrds) )
  tw[w_tt] = dttw
  tw = total(/cumulative,/preserve,tw)

  tdt = tw[w_dt]

  events = replicate( {time:0d, seq_cntr15:ccsds.seqn and 'f'x,  TOF:0u, dt:0u,  channel:0b , gap:0b} , n_dt )
  events.time = ccsds.time + (tdt-tdt[0])/ 2.^10 * (2d^17/150000d)
  events.channel = ch[w_dt]
  events.tof = tof[w_dt]
  events.dt = dt[w_dt]

;  event_str = { $
;              time: time, $
;              met: ccsds.met,  $
;              seq_cntr: ccsds.seq_cntr, $
;              n_tt: n_tt,$
;              n_dt: n_dt,$
;              tt0: uint(wrds[w_tt[0]] and 'ffff'x), $
;              wrds: wrds, $
;              gap: 0b }
  
  ;event_times = replicate( { time: 0d,seq_cntr15:ccsds.seq_cntr and
  ;'f'x, valmod: 0u }, n_tt )
  ;event_times.time = ccsds.time + (ttw2 - ttw2[0]) / 2.^10
  ;event_times.valmod= ttw

  return, events
end


