; $LastChangedBy: davin-mac $
; $LastChangedDate: 2018-04-24 09:03:12 -0700 (Tue, 24 Apr 2018) $
; $LastChangedRevision: 25103 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SPP/sweap/SWEM/spp_swp_swem_unwrapper.pro $

function spp_swp_swem_unwrapper,ccsds,ptp_header=ptp_header,apdat=apdat
  
  if n_params() eq 0 then begin
    dprint,'Not working yet.'
    return,!null
  endif
 
if debug(3) then begin
;  dprint
;  printdat,time_string(ccsds.time,prec=3)
;  printdat,ccsds,/hex
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
  

  if (ccsds.seq_group eq 3) && keyword_set(ccsds_data) then begin   ; single Loner packets  (not part of multi packet data product)
    dprint,'loner',dlevel=5,ccsds.apid,ccsds.seqn,ccsds.seqn_delta
    spp_ccsds_pkt_handler,ccsds_data[12:*]   ;,remainder=remainder   ;,ptp_header=ptp_header
    if keyword_set(remainder) && debug(2) then begin  ; There should be no remainder
      dprint,'error',dlevel=2
      ;  hexprint,remainder
    endif
  endif else begin
    dprint,'non loner',dlevel=3,ccsds.apid,ccsds.seqn,ccsds.seqn_delta,ccsds.seq_group
 ;   spp_ccsds_pkt_handler,ccsds_data[12:*];,remainder=remainder   ;,ptp_header=ptp_header
  endelse
  
  
  
  
  if ccsds.seq_group eq 5 then begin
    hexprint,ccsds_data,nbytes=32
    printdat,apdat
  endif
  
  return,str
end
