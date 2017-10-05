; $LastChangedBy: davin-mac $
; $LastChangedDate: 2017-04-11 14:18:24 -0700 (Tue, 11 Apr 2017) $
; $LastChangedRevision: 23136 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SPP/sweap/SWEM/spp_swp_swem_unwrapper.pro $

function spp_swp_swem_unwrapper,ccsds,ptp_header=ptp_header,apdat=apdat
  
  if n_params() eq 0 then begin
    dprint,'Not working yet.'
    return,!null
  endif


  str = {time:ccsds.time, $
         apid:ccsds.apid, $
         seqn:ccsds.seqn, $
         seq_group:ccsds.seq_group, $
         pkt_size:ccsds.pkt_size, $
         gap:0 }

  ccsds_data = spp_swp_ccsds_data(ccsds)

  if debug(5) then begin
    if ccsds_data[13] ne '00'x then   dprint,dlevel=1,'swem',ccsds.pkt_size, ccsds.apid
;    hexprint,ccsds_data,nbytes=32
  endif
  

  if ccsds.seq_group eq 3 && keyword_set(ccsds_data) then begin   ; Loner packets
    spp_ccsds_pkt_handler,ccsds_data[12:*],remainder=remainder,ptp_header=ptp_header
    if keyword_set(remainder) && debug(2) then begin
      dprint,'error',dlevel=2
      hexprint,remainder
    endif
  endif
  
  if ccsds.seq_group eq 5 then begin
    hexprint,ccsds_data,nbytes=32
    printdat,apdat
  endif
  
  return,str
end
