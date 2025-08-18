; buffer should contain bytes for a single ccsds packet, header is
; contained in first 3 words (6 bytes)
; $LastChangedBy: davin-mac $
; $LastChangedDate: 2023-12-11 00:17:46 -0800 (Mon, 11 Dec 2023) $
; $LastChangedRevision: 32281 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SPP/sweap/decom/common/spp_swp_ccsds_decom.pro $

;
;function spp_swp_ccsds_data,ccsds
;  if typename(ccsds) eq 'CCSDS_FORMAT' then data = *ccsds.pdata  else data=ccsds.data
;return,data
;end


function spp_swp_ccsds_decom_mettime,header,spc=spc,span=span,subsec=subsec
  if size(header,/type) eq 1 then begin   ; convert to uints
    n = n_elements(header)
    header2 = swap_endian(uint(header,0,6 < n/2) ,/swap_if_little_endian )
    dprint,dlevel=1,'old code!'
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


function spp_swp_ccsds_decom,buffer,source_dict=source_dict,wrap_ccsds=wrap_ccsds,offset,buffer_length,remainder=remainder , error=error,verbose=verbose,dlevel=dlevel

  error = 0b
  if not keyword_set(offset) then offset = 0
  if not keyword_set(buffer_length) then buffer_length = n_elements(buffer)
  remainder = !null

  d_nan = !values.d_nan
  f_nan = !values.f_nan

  ccsds = { spp_ccsds_format, $
    time:         d_nan,  $             ; unixtime
    MET:          d_nan,  $
    apid:         0u , $
    seqn:         0u , $
    seqn_delta :  0u, $
    seqn_group:    0b , $
    pkt_size:     0ul,  $
    source_apid:  0u   ,  $             ; an indicator of where this packet came from:  0: unknown, apid of wrapper_packet: 0x348 - 0x34f
    source_hash:  0UL,  $               ; hashcode() of source_name
    compr_ratio:  0. , $
    aggregate:    0u,  $                ; number of data samples aggregated - determined from outer wrapper header
    time_delta :  f_nan, $
    ptp_time:     d_nan,  $             ; unixtime from ptp packet
    error :       0b, $
    version :     0b , $   ; this could be eliminated since it is useless
    pdata:        ptr_new(),  $         ; pointer to full packet data including header
    ;ontent_compressed:   0b, $
    ;counter:      0ul,    $             ; packet counter as received - future use
    ;proc_time:    d_nan,  $             ; unixtime when it was processed
    ;source_name:  ''   ,  $             ; file name of source
    ;content_id:   0u   ,  $             ; used by wrapper packets to define the apid of the inner packet
    ;content_nsamples:     0u   ,  $             ;  number of packets that were aggregated (composed)
    gap :         1b  }

  if buffer_length-offset lt 12 then begin
    if debug(2) then begin
      dprint,'CCSDS Buffer length too short to include full header: ',buffer_length-offset,dlevel=2,offset,dwait=20
      hexprint,buffer
    endif
    error = 1b
    return, !null
  endif

  header = swap_endian(uint(buffer[offset+0:offset+11],0,6) ,/swap_if_little_endian )  ; ??? error here  % Illegal subscript range: BUFFER.
  ccsds.version = byte(ishft(header[0],-11) )    ; Corrected - but includes 2 extra bits
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
      ;hexprint,buffer
      ;pktbuffer = 0
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

  ccsds.seqn_group =  ishft(header[1] ,-14)
  ccsds.seqn  =    header[1] and '3FFF'x

  if (ccsds.MET lt 1e5) && (ccsds.apid ne '734'x) then begin ;0x734 is the ground SWEAP ApID (MET=0) tells us when we send command files to the MOC
    dprint,dlevel=dlevel,verbose=verbose,'Invalid MET: ',MET,' For packet type: ',ccsds.apid
    ccsds.time = d_nan
  endif

  if ccsds.MET gt  'FFFFFFF0'x then begin
    dprint,dlevel=dlevel,verbose=verbose,'MAX MET: ',MET,' For packet type: ',ccsds.apid
    ccsds.time = d_nan
  endif

  if isa(wrap_ccsds) then begin
    ccsds.source_apid = wrap_ccsds.apid
    ccsds.aggregate = wrap_ccsds.content_aggregate
    ccsds.compr_ratio = wrap_ccsds.compr_ratio
  endif
  if isa(source_dict) then begin
    if source_dict.haskey('source_info') then ccsds.source_hash = source_dict.source_info.input_sourcehash
    if source_dict.haskey('ptp_header') && isa(source_dict.ptp_header) then begin
      ptp_header = source_dict.ptp_header
      if isa(ptp_header) && ptp_header.ptp_size ne ccsds.pkt_size + 17 then begin
        dprint,dlevel=2,format='("APID: ",Z03," ccsds PKT size: ",i5," does not match ptp size:",i5,a)',ccsds.apid,ccsds.pkt_size+17, ptp_header.ptp_size,' '+time_string(ccsds.time)
      endif
      if isa(source_dict.ptp_header) then ccsds.ptp_time = ptp_header.ptp_time
    endif else begin
      source_dict.ptp_header2 ={ ptp_time:systime(1), ptp_scid: 0, ptp_source:0, ptp_spare:0, ptp_path:0, ptp_size: 17 + ccsds.pkt_size }
    endelse

  endif

  return,ccsds

end
