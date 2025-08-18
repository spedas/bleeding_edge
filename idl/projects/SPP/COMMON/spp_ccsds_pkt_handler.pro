This file is obsolete.

pro spp_ccsds_pkt_handler,dbuffer,offset,buffer_length, $
  source_info = source_info, $
  ptp_header=ptp_header, $
  remainder=remainder ,  $
  wrapper_apid=wrapper_apid, $
  original_size=original_size, $
  recurse_level=recurse_level;,ccsds=ccsds

  if not keyword_set(buffer_length) then buffer_length = n_elements(dbuffer)
  if not keyword_set(offset) then offset = 0L
  npackets = 0L
  remainder = !null
  
  while offset lt buffer_length do begin
    ccsds = spp_swp_ccsds_decom(dbuffer,offset,buffer_length,remainder=remainder,dlevel=4)
    if ~keyword_set(ccsds) then begin
      if debug(2) then begin
        dprint,dlevel=4,'Incomplete CCSDS, saving ',n_elements(remainder),' bytes for later '    ;,pkt_size,pkt_size - n_elements(b)
      endif
      break
    endif
    if keyword_set(source_info) then ccsds.source_hash = source_info.input_sourcehash
    npackets +=1
    if  debug(5) then begin
      ccsds_data = spp_swp_ccsds_data(ccsds)  
      n = ccsds.pkt_size
      if n gt 12 then ind = indgen(n-12)+12 else ind = !null      
;      dprint,dlevel=4,format='(i3,i6," APID: ", Z03,"  SeqGrp:",i1, " Seqn: ",i5,"  Size: ",i5,"   ",8(" ",Z02))',npackets,offset,ccsds.apid,ccsds.seq_group,ccsds.seqn,ccsds.pkt_size,ccsds_data[ind]
      dprint,dlevel=4,format='(i3,i6," APID: ", Z03,"  SeqGrp:",i1, " Seqn: ",i5,"  Size: ",i5,"   ")',npackets,offset,ccsds.apid,ccsds.seq_group,ccsds.seqn,ccsds.pkt_size   ;,ccsds_data[ind]
    endif
    offset += ccsds.pkt_size
        
    if keyword_set(ptp_header) then begin
      if ptp_header.ptp_size ne ccsds.pkt_size + 17 then begin
        dprint,dlevel=3,format='("APID: ",Z03," ccsds PKT size: ",i5," does not match ptp size:",i5,a)',ccsds.apid,ccsds.pkt_size+17, ptp_header.ptp_size,' '+time_string(ccsds.time)
      endif
      header=ptp_header
    endif else begin
      header ={ ptp_time:systime(1), ptp_scid: 0, ptp_source:0, ptp_spare:0, ptp_path:0, ptp_size: 17 + ccsds.pkt_size }
    endelse

    apdat = spp_apdat(ccsds.apid)

    if keyword_set( *apdat.ccsds_last) then begin
      ccsds_last = *apdat.ccsds_last
      dseq = (( ccsds.seqn - ccsds_last.seqn ) and '3fff'xu)
      ccsds.seqn_delta = dseq
      ccsds.time_delta = (ccsds.met - ccsds_last.met)
      ;        ccsds.gap = (dseq ne 1)
      ccsds.gap = (dseq gt ccsds_last.seqn_delta)
      ;   printdat,ccsds
    endif   ; else ccsds_last = !null

    if ccsds.seqn_delta gt 1 then begin
      dprint,dlevel=5,format='("Lost ",i5," ",a," (0x", Z03,") packets ",i5," ",a)',  ccsds.seqn_delta-1,apdat.name,apdat.apid,ccsds.seqn,time_string(ccsds.time,prec=3)
    endif

    apdat.handler, ccsds , header, source_info=source_info
    dummy = spp_rt(ccsds.time)     ; This line helps keep track of the current real time

    ;;  Save statistics - get APID_ALL and APID_GAP
    apdat.increment_counters, ccsds
    stats = spp_apdat(0)
    stats.handler, ccsds, header

    ;print,ptrace(option=3)
    if npackets ne 1 then dprint,dlevel=2,npackets

  endwhile

end
