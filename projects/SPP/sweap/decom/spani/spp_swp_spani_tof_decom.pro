function spp_swp_spani_tof_decom,ccsds,ptp_header=ptp_header,apdat=apdat

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
;     seqcntr : ccsds.seq_cnt, $
     tof: cnts, $  $ 
     gap: 0b   }
  return,str2

end

