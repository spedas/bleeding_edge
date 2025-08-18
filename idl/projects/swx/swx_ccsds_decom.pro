; buffer should contain bytes for a single ccsds packet, header is
; contained in first 3 words (6 bytes)
; $LastChangedBy: davin-mac $
; $LastChangedDate: 2024-11-01 10:09:46 -0700 (Fri, 01 Nov 2024) $
; $LastChangedRevision: 32916 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/swx/swx_ccsds_decom.pro $

;
;  This routine still needs to be modified to conform to the swx standard.

;function swx_ccsds_decom_mettime,header,day=day,millisec=millisec,microsec=microsec
;  ; header assumed to be bytes at this point
;  n = n_elements(header)
;  if n lt 5 then return, !values.d_nan
;
;  if header[6] ne 0 then begin
;    dprint,'Time out of range, header[6]= ',header[6];,dwait=20.
;  endif
;  header[6] = 0
;  
;  day = ((header[6]*256UL+header[7])*256)+header[8]
;  millisec = ((header[9]*256UL+header[10])*256+header[11])*256+header[12]
;  microsec = header[13] *256u + header[14]
;  MET = day*24d*3600d + millisec/1000d + microsec/1d6
;  ;MET = (header[3]*2UL^16 + header[4] + (header[5] and 'fffc'x)  / 2d^16) +   ( (header[5] ) mod 4) * 2d^15/150000              ; SPANS
;  return,met
;
;end


function swx_ccsds_decom_mettime,buffer,spc=spc,span=span,subsec=subsec
  if size(buffer,/type) gt 1 then message, 'code error'
  if buffer[6] eq 0 && buffer[7] eq 0 then begin
    if systime(1) gt 1.7018208e+09 then dprint,'Fix the time code in the SWX FPGA!!!!!  Then you can delete this message.',dwait=10.
    return, swx_ccsds_decom_mettime(buffer[3:*])   ; cluge to fix temporary problem in swx fpga
    
  endif

  met = ((buffer[6]*256ul+buffer[7])*256u+buffer[8])*256u+buffer[9]
  met += (buffer[10]*256ul+buffer[11]) / 2d^16
  return,met


  spc = 1
  if size(header,/type) eq 1 then begin   ; convert to uints
    n = n_elements(header)
    header2 = swap_endian(uint(header,0,6 < n/2) ,/swap_if_little_endian )
    dprint,dlevel=1,'old code!'
    return, swx_ccsds_decom_mettime(header2,subsec=subsec,spc=spc,span=span)
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






function swx_ccsds_decom,buffer,source_dict=source_dict,wrap_ccsds=wrap_ccsds,offset,buffer_length,remainder=remainder,error=error,verbose=verbose,dlevel=dlevel

  error = 0b
  if not keyword_set(offset) then offset = 0
  if not keyword_set(buffer_length) then buffer_length = n_elements(buffer)
  remainder = !null

  d_nan = !values.d_nan
  f_nan = !values.f_nan

  ccsds = { swx_ccsds_format, $
    time:         d_nan,  $             ; unixtime
    MET:          d_nan,  $
    grtime:       d_nan,  $
    delaytime:    d_nan,  $
    apid:         0u , $
    seqn:         0u , $
    seqn_delta:   0u,  $
    seqn_group:   0b , $
    pkt_size:     0ul,  $
    day:          0UL,  $
    millisec:     0ul,  $
    microsec:     0u,   $
    source_apid:  0u   ,  $             ; an indicator of where this packet came from:  0: unknown, apid of wrapper_packet: 0x348 - 0x34f
    source_hash:  0UL,  $               ; hashcode() of source_name
    compr_ratio:  0. , $
    aggregate:    0u,  $                ; number of data samples aggregated - determined from outer wrapper header
    time_delta :  f_nan, $
    ptp_time:     d_nan,  $             ; unixtime from ptp packet
    error :       0b, $
    version :     0b , $   ; this could be eliminated since it is useless
    pdata:        ptr_new(),  $         ; pointer to full packet data including header
    ;content_compressed:   0b, $
    ;counter:      0ul,    $             ; packet counter as received - future use
    ;proc_time:    d_nan,  $             ; unixtime when it was processed
    ;source_name:  ''   ,  $             ; file name of source
    ;content_id:   0u   ,  $             ; used by wrapper packets to define the apid of the inner packet
    ;content_nsamples:     0u   ,  $             ;  number of packets that were aggregated (composed)
    gap :         1b  }

  if buffer_length-offset lt 15 then begin
    if debug(2) then begin
      dprint,'CCSDS Buffer length too short to include full header: ',buffer_length-offset,dlevel=2,offset,dwait=20
      hexprint,buffer
    endif
    error = 1b
    return, !null
  endif

  header = swap_endian(uint(buffer[offset+0:offset+5],0,3) ,/swap_if_little_endian )  ; ??? error here  % Illegal subscript range: BUFFER.
  ccsds.version = byte(ishft(header[0],-11) )    ; Corrected - but includes 2 extra bits
  ccsds.apid = header[0] and '7FF'x

  if n_elements(subsec) eq 0 then subsec= ccsds.apid ge '350'x

  apid = ccsds.apid

  ;MET = swx_ccsds_decom_mettime(buffer[offset+0:offset+15],day=day,millisec=millisec,microsec=microsec)
  MET = swx_ccsds_decom_mettime(buffer)   ;[offset+0:offset+15],day=day,millisec=millisec,microsec=microsec)
  ccsds.met = met
  ;ccsds.day = day
  ;ccsds.millisec = millisec
  ;ccsds.microsec = microsec
  ccsds.time = swx_spc_met_to_unixtime(ccsds.MET)

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

  ;  if (ccsds.MET lt 1e5) && (ccsds.apid ne '734'x) then begin ;0x734 is the ground SWEAP ApID (MET=0) tells us when we send command files to the MOC
  ;    dprint,dlevel=dlevel,verbose=verbose,'Invalid MET: ',MET,' For packet type: ',ccsds.apid
  ;    ccsds.time = d_nan
  ;  endif
  ;
  ;  if ccsds.MET gt  'FFFFFFF0'x then begin
  ;    dprint,dlevel=dlevel,verbose=verbose,'MAX MET: ',MET,' For packet type: ',ccsds.apid
  ;    ccsds.time = d_nan
  ;  endif

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
