;+
; $LastChangedBy: davin-mac $
; $LastChangedDate: 2024-11-03 13:15:35 -0800 (Sun, 03 Nov 2024) $
; $LastChangedRevision: 32924 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/swx/swx_swem_wrapper_apdat__define.pro $
;-

;This routine will recursively call the ccsds_pkt_hander to decomutate the inner packet
; It does this after decompression (if needed)
; handler2 expects to get the original science packet stichted back together,  the 12 wrapper header bytes have been removed
pro swx_swem_wrapper_apdat::handler2, buffer, wrap_ccsds=wrap_ccsds,source_dict=source_dict  ;   ,wrapper_header=wrapper_header, wrapper_apid= wrapper_apid

  ;  if debug(self.dlevel+5,msg='handler2')  then begin  ;  wrapper_header[10] ne 0 &&
  ;    dprint,'wrapper header:'
  ;    hexprint,wrapper_header
  ;    dprint,'header of inner packet:'
  ;    hexprint,buffer[0:19]
  ;;    dprint,'data of inner packet:'
  ;;    hexprint,buffer[20:*]
  ;  endif
  ; wrapper_header = source_dict.wrapper_header

  ;  if wrapper_header[10] ne 0 then begin
  ;    dprint,dlevel=self.dlevel+3,source_dict.wrapper_header
  ;  endif
  ;hexprint,wrapper_header
  if wrap_ccsds.content_compressed  then begin   ; compressed packet
    ;    dprint,dlevel = self.dlevel+3, 'compressed packet ',wrapper_header[10]
    buffer = swx_swem_part_decompress_data(buffer,decomp_size =  decomp_size, /stuff_size )
    wrap_ccsds.content_decomp_size = decomp_size
    wrap_ccsds.compr_ratio=float(decomp_size)/float(wrap_ccsds.pkt_size)
    if decomp_size gt 4096+20 then begin
      dprint,'Bad decompressed packet'
    endif
    dprint,dlevel = self.dlevel+3,decomp_size
  endif
  if debug(self.dlevel+5) then begin
    dprint,'header of packet:'
    hexprint,buffer[0:19]
    data = buffer[20:*]
    if 0 then begin
      dprint,'data of decomp packet:'
      hexprint,data
    endif
    dprint,'data signature:'
    w = where(data)
    dprint,fix(w)
    dprint,fix(data[w])
  endif
  if debug(self.dlevel+5) then printdat,buffer,/hex
  n = wrap_ccsds.content_aggregate
  if n eq -1  then begin
    content_ccsds = swx_ccsds_decom(buffer)
    new_header = buffer[0:17]
    data_size = (content_ccsds.pkt_size - 18) / n
    dprint,'aggregate:',n,dlevel=self.dlevel,data_size
    for i=0,n-1 do begin
      new_buffer= [new_header,buffer[18+i*data_size:18+i*data_size+data_size-1]]
      psize_m7= data_size + 18 -7
      ;    dprint,psize_m7
      new_buffer[4] = ishft(psize_m7 , 8)
      new_buffer[5] = psize_m7 and 255
      hexprint,new_buffer,ncol=32+20
    endfor
  endif
  ;  spp_ccsds_pkt_handler,buffer, source_info=source_info, wrapper_apid = self.apid,original_size=original_size   ; recursively handle the inner packet
  swx_ccsds_spkt_handler,buffer, source_dict=source_dict ,wrap_ccsds=wrap_ccsds  ;,     source_info=source_info, wrapper_apid = self.apid,original_size=original_size   ; recursively handle the inner packet

end


function swx_swem_wrapper_apdat::decom,ccsds, source_dict=source_dict ;,ptp_header,source_info=source_info

  dnan = !values.d_nan
  wrap_ccsds = create_struct( ccsds,  $
    {  $
    content_time_diff: dnan , $   ; difference in time between wrapper met and content met
    content_apid: 0u    , $          ; will replace content_id
    content_decomp_size: 0u,  $
    content_compressed:  0b,  $
    content_aggregate:  0b  $
  } )

  ; struct_assign,ccsds,wrap_ccsds,/no_zero

  ccsds_data = swx_ccsds_data(ccsds)

  wrap_ccsds.pdata  = ptr_new()  ; Not sure if it is useful to keep this info

  if ccsds.pkt_size le 22 then begin
    dprint,'Wrapper packet error - APID:',ccsds.apid,ccsds.pkt_size,dlevel=1,dwait = 2.
    ;printdat,ccsds
    return, wrap_ccsds
  endif

  ;source_dict.wrapper_header = ccsds_data[0:11]
  source_dict.ptp_header=!null   ; get rid of error checking in ptp_header
  wrap_ccsds.content_compressed = (ccsds_data[10] and '80'x) ne 0
  wrap_ccsds.content_aggregate = ccsds_data[11]

  ;self.dlevel=2
  if debug(self.dlevel+5,msg='wrapper') then begin
    hexprint,ccsds_data
  endif

  if keyword_set(self.pbuffer) eq 0 then self.pbuffer = ptr_new(!null)   ; Should be put in init routine

  case ccsds.seqn_group of
    1: begin                                        ; start of multi-packet
      self.cummulative_size = ccsds.pkt_size
      self.active_apid = spp_swp_data_select(ccsds_data,8*12+5,11)   ;  apid of wrapped packet
      self.active_met = spp_swp_data_select(ccsds_data,8*18,32)  ; extract MET from inner packet
      dprint,dlevel=self.dlevel+3,ccsds.apid,ccsds.seqn,ccsds.seqn_delta,ccsds.seqn_group,' Start multi-packet'
      if keyword_set(*self.pbuffer) then dprint,dlevel=self.dlevel,'Warning: New Multipacket started without finishing previous group'
      if debug(self.dlevel+3) then begin
        printdat, /hex,*ccsds.pdata
      endif
      *self.pbuffer = ccsds_data[12:*]
    end
    0: begin   ; middle of multipacket
      self.cummulative_size += ccsds.pkt_size
      dprint,dlevel=self.dlevel+1,'Never expect this on SPP! except for really big packets'
      ;printdat,ccsds
      if keyword_set(*self.pbuffer)  then begin
        dprint,dlevel=self.dlevel+3,ccsds.apid,ccsds.seqn,ccsds.seqn_delta,ccsds.seqn_group,' Mid multi packet'
        *self.pbuffer = [*self.pbuffer,ccsds_data[12:*] ]  ; append final segment
      endif else dprint,dlevel=self.dlevel+1,'Error'
    end
    2: begin    ; End of multi-packet
      self.cummulative_size += ccsds.pkt_size
      if ccsds.seqn_delta ne 1 then begin
        dprint,dlevel=self.dlevel+1,'Missing packets - aborting End of multi-packet'
      endif else begin
        dprint,dlevel=self.dlevel+3,ccsds.apid,ccsds.seqn,ccsds.seqn_delta,ccsds.seqn_group,' End multi-packet'
        if debug(self.dlevel+3) then begin
          printdat, /hex,*ccsds.pdata
        endif
        *self.pbuffer = [*self.pbuffer,ccsds_data[12:*] ]  ; append final segment
        self.handler2, *self.pbuffer, source_dict=source_dict ,wrap_ccsds = wrap_ccsds
      endelse
      *self.pbuffer = !null
      ;    self.active_apid = 0
    end
    3: begin   ; Single packet
      self.cummulative_size = ccsds.pkt_size
      self.active_apid = spp_swp_data_select(ccsds_data,8*12+5,11)   ;  apid of wrapped packet
      self.active_met = spp_swp_data_select(ccsds_data,8*18,32)  ; extract MET from inner packet
      ;    print,self.active_apid,self.apid
      dprint,dlevel=self.dlevel+4,ccsds.apid,ccsds.seqn,ccsds.seqn_delta,ccsds.seqn_group,' Single packet'
      if keyword_set(*self.pbuffer) then dprint,dlevel=self.dlevel,'Warning: New Multipacket started without finishing previous group'
      *self.pbuffer = ccsds_data[12:*]
      self.handler2,*self.pbuffer,  source_dict=source_dict ,wrap_ccsds = wrap_ccsds
      *self.pbuffer = !null
    end

  endcase

  wrap_ccsds.content_apid = self.active_apid
  wrap_ccsds.content_time_diff = ccsds.met - self.active_met ;double minus ulong!!

  return, wrap_ccsds

end


;pro spp_swp_wrapper_apdat::handler,ccsds,source_dict=source_dict  ;  ptp_header,source_info=source_info
;
;  ccsds_data = spp_swp_ccsds_data(ccsds)
;  if ccsds.pkt_size ge 14 then ccsds.content_id = spp_swp_data_select(  ccsds_data, 8*12+5,  11)
;  wrapper_header = ccsds_data[0:11]
;  self->spp_gen_apdat::handler,ccsds,source_dict=source_dict   ;ptp_header
;
;end


PRO swx_swem_wrapper_apdat__define
  void = {swx_swem_wrapper_apdat, $
    inherits swx_gen_apdat, $    ; superclass
    active_apid : 0u, $
    active_met : 0uL, $
    cummulative_size : 0U, $
    pbuffer: ptr_new()   $
  }
END
