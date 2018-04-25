; buffer should contain bytes for a single ccsds packet, header is
; contained in first 3 words (6 bytes)


;
;function spp_swp_ccsds_data,ccsds
;  if typename(ccsds) eq 'CCSDS_FORMAT' then data = *ccsds.pdata  else data=ccsds.data
;return,data
;end


function spp_swp_ccsds_decom_mettime,header,spc=spc,span=span,subsec=subsec
  if size(header,/type) eq 1 then begin   ; convert to uints
    n = n_elements(header) 
    header2 = swap_endian(uint(header,0,6 < n/2) ,/swap_if_little_endian )
    dprint,dlevel=3,'old code!'
    return, spp_swp_ccsds_decom_mettime(header2,subsec=subsec,spc=spc,span=span)
  endif
    ; header assumed to be uints at this point
  n = n_elements(header)
  if n lt 5 then return, !values.d_nan

  if keyword_set(span) then begin
    MET = (header[3]*2UL^16 + header[4] + (header[5] and 'fffc'x)  / 2d^16) +   ( (header[5] ) mod 4) * 2d^15/150000              ; SPANS
  endif else if keyword_set(spc) then begin
    MET = (header[3]*2UL^16 + header[4] + (header[5] and 'ffff'x)  / 2d^16)             ; SPC
  endif else begin
    MET = double( header[3]*2UL^16 + header[4] )   ; normal 1 sec resolution
  endelse
return,met
end





function spp_swp_ccsds_decom,buffer,offset,buffer_length,remainder=remainder , error=error,verbose=verbose,dlevel=dlevel

  error = 0b
  if not keyword_set(offset) then offset = 0
  if not keyword_set(buffer_length) then buffer_length = n_elements(buffer)
  remainder = !null


  d_nan = !values.d_nan

  ccsds = { ccsds_format, $
    apid:         0u , $
    version_flag: 0b , $
    seq_group:    0b , $
    seqn:         0u , $
    pkt_size:     0ul,  $
    time:         d_nan,  $
    MET:          d_nan,  $
    ;    data:         pktbuffer, $
    pdata:        ptr_new(),  $
    time_delta :  d_nan, $
    seqn_delta :  0u, $
    error :       0b, $
    gap :         1b  }

  if buffer_length-offset lt 12 then begin
    if debug(3) then begin
      dprint,'CCSDS Buffer length too short to include header: ',buffer_length-offset,dlevel=2,offset
      hexprint,buffer
    endif
    error = 1b
    return, 0
  endif

  header = swap_endian(uint(buffer[offset+0:offset+11],0,6) ,/swap_if_little_endian )

  ccsds.version_flag = byte(ishft(header[0],-8) )    ; THIS DOES NOT LOOK CORRECT

  ccsds.apid = header[0] and '7FF'x

  if n_elements(subsec) eq 0 then subsec= ccsds.apid ge '350'x

  apid = ccsds.apid
  
  MET = spp_swp_ccsds_decom_mettime(header)

  ;  if apid ge '360'x then begin
  ;    MET = (header[3]*2UL^16 + header[4] + (header[5] and 'fffc'x)  / 2d^16) +   ( (header[5] ) mod 4) * 2d^15/150000              ; SPANS
  ;  endif else if apid ge '350'x then begin
  ;    MET = (header[3]*2UL^16 + header[4] + (header[5] and 'ffff'x)  / 2d^16)             ; SPC
  ;  endif else begin
  ;    MET = double( header[3]*2UL^16 + header[4] )
  ;  endelse

; The following MET computation code belongs in the apdat object handler routines - this is a temporaty cluge that may disappear
  
  if apid ge '3c0'x then begin
    MET = spp_swp_ccsds_decom_mettime(header)              ; GSE data
  endif else if apid ge '360'x then begin
    MET = spp_swp_ccsds_decom_mettime(header,/span)              ; SPANS
  endif else if apid ge '350'x then begin
    MET = spp_swp_ccsds_decom_mettime(header,/spc)              ; SPC
  endif else begin
    MET = spp_swp_ccsds_decom_mettime(header)              ; SWEM data
  endelse

  ccsds.met = met
  ccsds.time = spp_spc_met_to_unixtime(ccsds.MET)

  ccsds.pkt_size = header[2] + 7

  if buffer_length-offset lt ccsds.pkt_size then begin
    error=2b
    remainder = buffer[offset:*]
    if debug(dlevel,verbose) then begin
      dprint,'Not enough bytes: pkt_size, buffer_length= ',ccsds.pkt_size,buffer_length-offset,dlevel=dlevel,verbose=verbose
      ;     hexprint,buffer
;      pktbuffer = 0
    endif
    return ,0
  endif else begin
    if ccsds.pkt_size lt 10 then begin
      dprint,ccsds.apid,ccsds.seqn,' Invalid Packet size:' , ccsds.pkt_size,dlevel=3
      return,0
    endif
    if ccsds.pkt_size ne buffer_length-offset then begin
      dprint,'buffer and CCSDS size mismatch',dlevel=3
    endif
    pktbuffer = buffer[offset+0:offset+ccsds.pkt_size-1]
    ccsds.pdata = ptr_new(pktbuffer,/no_copy)
  endelse

  ccsds.seq_group =  ishft(header[1] ,-14)
  ccsds.seqn  =    header[1] and '3FFF'x

  if ccsds.MET lt 1e5 then begin
    dprint,dlevel=dlevel,verbose=verbose,'Invalid MET: ',MET,' For packet type: ',ccsds.apid
    ccsds.time = d_nan
  endif
  
  return,ccsds
  
end


