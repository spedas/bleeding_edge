function spp_swp_spani_tof_decom,ccsds, source_dict = source_dict  ;,ptp_header=ptp_header,apdat=apdat

  if n_params() eq 0 then begin
    dprint,'Not working yet.'
    return,!null
  endif

  ;; IMPLEMENT DECOMPRESSION
  ccsds_data = spp_swp_ccsds_data(ccsds)


;  str = create_struct(ptp_header,ccsds)
                                ;  dprint,format="('Generic routine
                                ;  for
                                ;  ',Z04)",ccsds.apid                                                                                            
  if debug(5) then begin
     dprint,dlevel=5,'TOF',ccsds.pkt_size, n_elements(ccsds_data[24:*])
     hexprint,ccsds_data
  endif


cnts = ccsds_data[24:*]  
;printdat,ccsds
;hexprint,cnts
;print
  
  
  
  str2 = {time: ccsds.time, $
      met: ccsds.met,  $
      seqn: ccsds.seqn,  $
      pkt_size: ccsds.pkt_size, $
     tof: bytarr(512), $  $ 
     gap: 0b   }

if ccsds.pkt_size  eq 536 then str2.tof = cnts     
     
  return,str2

end

