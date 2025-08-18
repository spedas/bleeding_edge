; $LastChangedBy: rjolitz $
; $LastChangedDate: 2025-03-04 10:57:07 -0800 (Tue, 04 Mar 2025) $
; $LastChangedRevision: 33161 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SWFO/STIS/gsemsg_reader__define.pro $



function gsemsg_reader::c1msg_struct,header_payload

  type = header_payload[2]*256u + header_payload[3]
  psize = (header_payload[4]*256ul + header_payload[5]) * 2
  
  buf = header_payload[self.header_size:*]
  dprint,dlevel=5,verbose=self.verbose,buf ;,dwait=1
  ;words = fix(buf,0,12)
  ;byteorder,words,/swap_if_little_endian
  days =   swfo_data_select(buf,0,24)
  msec =   swfo_data_select(buf,24,32)
  usec =   swfo_data_select(buf,24+32,16)
  tbd  =   swfo_data_select(buf,9*8, 8)
  rev  =   swfo_data_select(buf,10*8,8)
  flags =  swfo_data_select(buf,11*8,24)
  rate =   swfo_data_select(buf,14*8,16)
  active=  swfo_data_select(buf,16*8,8)
  TBD2  =   swfo_data_select(buf,8*17,8)
  TBDs  =   swfo_data_select(buf,16*9+indgen(3),16)
  ;  tbd9   =  swfo_data_select(buf,9*16,16)  ;
  ;  tbd10  =  swfo_data_select(buf,10*16,16)
  ;  tbd11  =  swfo_data_select(buf11*16,16)
  ;  tbd12  =  swfo_data_select(buf,12*16,16)

  days = days- (365*12L+3)
  time = days * 3600d*24+msec/1000d
  gse_pkt = {time:time, $
    psize: psize, $
    type: type,  $
    rev:  rev, $
    flag_bits:  flags, $
    rate:  rate, $
    active: active,  $
    tbd2  : tbd2, $
    tbds  : tbds, $
    gap:0}
  return,gse_pkt

end


function gsemsg_reader::header_struct,buf
  if n_elements(buf) lt self.header_size || buf[0] ne 'a8'xb || buf[1] ne '29'xb then return,!null
  
  strct = {  time: !values.d_nan,  psize: 0ul , type:0u ,valid:0, gap:0}
    strct.type = buf[2]*256u + buf[3]
    strct.psize = (buf[4]*256ul + buf[5]) * 2
    return,strct

end








;+
;  PROCEDURE SWFO_GSEMSG_Buffer_READ
;  This procedure is only specific to SWFO in the "sync bytes" found in the MSG header.  Otherwise it could be considered generic
;  It purpose is to read bytes from a previously opened MSG file OR stream.  It returns at the end of file (for files) or when
;  no more bytes are available for reading from a stream.
;  It should gracefully handle sync errors and find sync up on a MSG header.
;  When a complete MSG header and its enclosed CCSDS packet are read in, it will execute the routine "swfo_ccsds_spkt_handler"
;-

pro gsemsg_reader::read_old,source     ; ,source_dict=parent_dict

  ;dprint,n_elements(source)
  ;hexprint,source
  
  self.header_size = 6   ; this should be in the init function
  ;dwait = 10.
  dict = self.source_dict
  if dict.haskey('parent_dict') then parent_dict = dict.parent_dict
  
  if isa(parent_dict,'dictionary') &&  parent_dict.haskey('cmbhdr') then begin
    header = parent_dict.cmbhdr
    dprint,dlevel=4,verbose=self.verbose,header.description,'  ',header.size
  endif else begin
    dprint,verbose=self.verbose,dlevel=3,'No cmbhdr'
    header = {time: !values.d_nan, seqn:0U, size:0u , gap:0 }
  endelse


  ;source_dict = self.source_dict
  ;dict = self.source_dict

  if ~dict.haskey('fifo') then begin
    dict.fifo = !null    ; this contains the unused bytes from a previous call
    dict.flag = 0
    ;self.verbose=3
  endif

  if debug(4,self.verbose) then begin
    if abs(fix(header.seqn - 3625)) lt 6  || ( header.size ne 134 && header.size ne 30 && header.size ne 268) then begin    ; trap to find problem
      dprint,header
      dprint
      dict.flag = 1
    endif else dict.flag = 0

  endif



  if debug(4,self.verbose,msg='test') then begin
    ;printdat,dict
    print,n_elements(dict.sync_ccsds_buf),n_elements(source)
    hexprint,source
  endif

  on_ioerror, nextfile
  time = systime(1)
  dict.time_received = time

  msg =''; time_string(dict.time_received,tformat='hh:mm:ss.fff -',local=localtime)

  ;remainder = !null
  ;remainder = dict.remainder_gsemsg
  ;dict.remainder_gsemsg = !null
  nbytes = 0UL
  sync_errors =0ul
  total_bytes = 0L
  endofdata = 0
  while ~endofdata do begin

    if dict.fifo eq !null then begin
      dict.n2read = 6
      dict.header_is_valid = 0
      dict.packet_is_valid = 0
    endif
    nb = dict.n2read

    buf= self.read_nbytes(nb,source,pos=nbytes)
    nbuf = n_elements(buf)

    if nbuf eq 0 then begin
      dprint,verbose=self.verbose,dlevel=4,'No more data'
      break
    endif

    bytes_missing = nb - nbuf   ; the number of missing bytes in the read

    dict.fifo = [dict.fifo,buf]
    nfifo = n_elements(dict.fifo)

    if bytes_missing ne 0 then begin
      dict.n2read = bytes_missing
      if ~isa(buf) then endofdata =1
      continue
    endif

    if dict.header_is_valid eq 0 then begin
      sync_pattern = ['A8'xb,'29'xb,'0'xb]

      if (nfifo lt 6) || array_equal(dict.fifo[0:2],sync_pattern) eq 0 then begin
        dict.fifo = dict.fifo[1:*]
        dict.n2read = 1
        nb = 1
        sync_errors += 1
        continue      ; read one byte at a time until sync is found
      endif
      dict.header_is_valid = 1
      dict.packet_is_valid = 0
    endif

    if ~dict.packet_is_valid then begin
      sz = dict.fifo[4]*256L + dict.fifo[5]
      nb = sz * 2
      if nb eq 0 then begin
        dprint,verbose = self.verbose,dlevel=2,'Invalid GSEMSG: Packet length with zero length'
        dict.fifo = !null
        ;nb = 1
        ;dict.packet_is_valid=0
        ;dict.header_is_valid=0
      endif else begin
        dict.packet_is_valid =1        
        dict.n2read = nb
      endelse
      continue            ; continue to read the rest of the packet
    endif


    if sync_errors ne 0 then begin
      dprint,verbose=self.verbose,dlevel=2,sync_errors,' GSEMSG sync errors',dwait =4.
    endif

    ; if it reaches this point then a valid message header+payload has been read in

    ;gsehdr  =  dict.fifo[0:5]
    ;payload =  dict.fifo[6: nb+6 - 1]
    
    self.handle,dict.fifo    ; process each packet


    if keyword_set(dict.flag) && debug(2,self.verbose,msg='status') then begin
      dprint,verbose=self.verbose,dlevel=3,header
      ;dprint,'gsehdr: ',n_elements(gsehdr)
      ;hexprint,gsehdr
      ;dprint,'payload: ',n_elements(payload)
      ;hexprint,payload
      dprint,'fifo: ', n_elements(dict.fifo)  ;,'   ',time_string(gsemsg.time)
      hexprint,dict.fifo
      dprint
    endif

    dict.fifo = !null

  endwhile

  if sync_errors ne 0 then begin
    dprint,verbose=self.verbose,dlevel=2,sync_errors,' GSEMSG sync errors at "'+time_string(dict.time_received)+'"'
    ;printdat,source
    ;hexprint,source
  endif


  if 0 then begin
    nextfile:
    dprint,!error_state.msg
    dprint,'Skipping file'
  endif

  if nbytes ne 0 then msg += string(/print,nbytes,format='(i6 ," bytes: ")')  $
  else msg+= ' No data available'

  dprint,verbose=self.verbose,dlevel=3,msg
  dict.msg = msg

  ;    dprint,dlevel=2,'Compression: ',float(fp)/fi.size

end



pro gsemsg_reader::handle_old,buffer   ;,source_dict=source_dict

  msg_buf = buffer
  dict = self.source_dict
  buf = msg_buf[6:*]
  ;dprint
  

  case msg_buf[3] of
    'c1'x: begin
      ;if sz ne 'c'x then begin
      ;  dprint,dlevel=1,verbose=self.verbose,'Invalid GSE message. word size: ',sz
      ;  message,'Error',/cont
      ;endif
      if debug(3,self.verbose,msg='c1 packet') then begin
        ;dprint,nb,dlevel=3
        hexprint,buf
      endif
      raw_tlm_header = self.c1msg_struct(buf)
      if isa(self.dyndata,'dynamicarray') then self.dyndata.append,raw_tlm_header
      dict.gse_header  = raw_tlm_header
    end
    'c3'x: begin
      if 1 then begin
        self.ccsds_reader.read,buf        
      endif else begin
         
      ;sync_pattern = ['1a'x,  'cf'x ,'fc'x, '1d'x ]
      ;dict.sync_pattern = sync_pattern
      if debug(4,self.verbose) then begin
        dprint,sz*2,dlevel=4,verbose=self.verbose
        hexprint,buf
      endif
      if ~dict.haskey('ccsds_dict') then begin
        dict.ccsds_dict =  dictionary()
        ccsds_dict = dict.ccsds_dict
        ccsds_dict.sync_ccsds_buf = !null
        ccsds_dict.sync_pattern = byte(['1a'x,  'cf'x ,'fc'x, '1d'x ])
      endif
      ccsds_dict = dict.ccsds_dict
      ccsds_dict.sync_ccsds_buf = [ccsds_dict.sync_ccsds_buf, buf]
      while 1 do begin ; start processing packet stream
        nbuf = n_elements(ccsds_dict.sync_ccsds_buf)
        skipped = 0UL
        while (nbuf ge 4) && (array_equal(ccsds_dict.sync_ccsds_buf[0:3] ,ccsds_dict.sync_pattern) eq 0) do begin
          dprint,dlevel=5,verbose=self.verbose, 'searching for sync pattern: ',nbuf
          ccsds_dict.sync_ccsds_buf = ccsds_dict.sync_ccsds_buf[1:*]    ; increment one byte at a time looking for sync pattern
          nbuf = n_elements(ccsds_dict.sync_ccsds_buf)
          skipped++
        endwhile
        if skipped ne 0 then begin
          if dict.haskey('gse_header') then time= dict.gse_header.time else time=0d
          dprint,verbose=self.verbose,dlevel=2,'Skipped ',skipped,' bytes to find sync word at '+time_string(time,prec=3)
          if 0 then begin
            if ccsds_dict.haskey('last_ccsds_buf') && isa(ccsds_dict.last_ccsds_buf) then dprint,verbose=self.verbose,dlevel=2,'Killing previous packet because sync word was not detected'
            ccsds_dict.last_ccsds_buf = !null                           ; Kill previous packet if sync was lost
          endif
;          if debug(2) then begin
;            hexprint,msg_buf
;          endif
        endif
        nbuf = n_elements(ccsds_dict.sync_ccsds_buf)
        if nbuf lt 10 then begin
          dprint,verbose=self.verbose,dlevel=4,'Incomplete packet header - wait for later'
          ;         ccsds_dict.sync_ccsds_buf = sync_ccsds_buf
          break
        endif
        pkt_size = ccsds_dict.sync_ccsds_buf[4+4] * 256u + ccsds_dict.sync_ccsds_buf[5+4] + 7
        ;dprint,dlevel=2,'pkt_size: ',pkt_size
        if nbuf lt pkt_size + 4 then begin
          dprint,verbose=self.verbose,dlevel=4,'Incomplete packet - wait for later',nbuf, ' of ',pkt_size
          ;      ccsds_dict.sync_ccsds_buf = sync_ccsds_buf
          break
        endif
        ccsds_buf = ccsds_dict.sync_ccsds_buf[4:pkt_size+4-1]  ; get rid of the syncword. not robust!!!
        if self.run_proc then  begin
          if 0 then begin                          ; This correction will attempt to throw out packets that were incomplete or corrupted
            if ccsds_dict.haskey('last_ccsds_buf') && isa( ccsds_dict.last_ccsds_buf) then begin
              swfo_ccsds_spkt_handler,ccsds_dict.last_ccsds_buf,source_dict=ccsds_dict         ; Process the previos complete packet
            endif
            ccsds_dict.last_ccsds_buf = ccsds_buf             ; Save the current packet and process later  
          endif else begin
            swfo_ccsds_spkt_handler,ccsds_buf,source_dict=ccsds_dict         ; Process the complete packet            
          endelse
        endif
        if ccsds_dict.haskey('ccsds_writer') && obj_valid(ccsds_dict.ccsds_writer) then begin   ; hook to generate ccsds files
          ccsds_writer = ccsds_dict.ccsds_writer
          ccsds_writer.directory = self.directory
          ccsds_writer.time_received = ccsds_dict.gse_header.time
          if ccsds_writer.getattr('output_lun') eq 0 then begin
            dprint,'Are you sure about this?'
            ccsds_writer.output_lun = -1
            ;stop
          endif
          ccsds_writer.write,ccsds_buf
        endif
        if n_elements(ccsds_dict.sync_ccsds_buf) eq pkt_size+4 then begin
          ccsds_dict.sync_ccsds_buf = !null
        endif else begin
          ccsds_dict.sync_ccsds_buf = ccsds_dict.sync_ccsds_buf[pkt_size+4:*]
        endelse
        dprint,verbose=self.verbose,dlevel=4,'Endwhile'
      endwhile
      endelse
    end
    else:    message,'GSE raw_tlm error - unknown code'
  endcase
  dprint,verbose=self.verbose,dlevel=4,'End of handler'


end




pro gsemsg_reader::handle,header_payload   ;,source_dict=source_dict

  ;msg_buf = header_payload
  dict = self.source_dict
  payload = header_payload[self.header_size:*]
  ;dprint


  case header_payload[3] of
    'c1'x: begin
      if debug(3,self.verbose,msg='c1 packet') then begin
        ;dprint,nb,dlevel=3
        hexprint,payload
      endif
      gsemsg_struct = self.c1msg_struct(header_payload)
      if isa(self.dyndata,'dynamicarray') then self.dyndata.append,gsemsg_struct
      dict.gsemsg_struct  = gsemsg_struct
    end
    'c3'x: begin
        ccsds = self.ccsds_reader
        ccsds.source_dict.parent_dict = dict
        ccsds.read,payload
    end
    else:    message,'GSE raw_tlm error - unknown code'
  endcase

  dprint,verbose=self.verbose,dlevel=4,'End of handler'


end






function gsemsg_reader::init,sync_pattern=sync_pattern,decom_procedure = decom_procedure,mission=mission,_extra=ex
  ret=self.socket_reader::init(_extra=ex)
  if ret eq 0 then return,0

  if isa(mission,'string') && mission eq 'SWFO' then begin
    sync_pattern = ['A8'xb,  '29'xb ]
    decom_procedure = 'swfo_ccsds_spkt_handler'
  endif
  self.sync_size = n_elements(sync_pattern)
  self.ccsds_reader = ccsds_reader(mission=mission,/no_widget)
 ; self.maxsize = 4100
 ; self.minsize = 10
  if self.sync_size gt 4 then begin
    dprint,'Number of sync bytes must be <= 4'
    return, 0
  endif
  if self.sync_size ne 0 then self.sync_pattern = sync_pattern
  self.header_size = 6

  return,1
end





PRO gsemsg_reader__define
  void = {gsemsg_reader, $
    inherits cmblk_reader, $    ; superclass ;  this should inherit socket_reader
    ccsds_reader:   obj_new(), $         ; user definable object  not used
    gsemsg_reader:  obj_new()  $
}
END




