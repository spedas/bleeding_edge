function spp_generic_decom,ccsds,ptp_header=ptp_header,apdat=apdat

  if n_params() eq 0 then begin
    return,!null
  endif
  str =   ccsds   ; create_struct(ptp_header,ccsds)
  ;dprint,format="('Generic routine for',Z04)",ccsds.apid                                                                                              
  if debug(5,msg='Generic') then begin
     dprint,dlevel=2,'generic:',ccsds.apid,ccsds.pkt_size
 ;    hexprint,ccsds.data
  endif
  return,str

end


