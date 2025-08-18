; $LastChangedBy: davin-mac $
; $LastChangedDate: 2023-11-13 07:46:41 -0800 (Mon, 13 Nov 2023) $
; $LastChangedRevision: 32242 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SWFO/STIS/packet_reader__define.pro $



function packet_reader::header_struct,buf
  dprint,dlevel=5,verbose=self.verbose,buf ;,dwait=1
  
  if n_elements(buf) lt self.header_size then return,!null
  sync = self.source_dict.sync_pattern
  nsync = n_elements(sync)
  if nsync ne 0 && array_equal(buf,sync) eq 0 then return, !null
  pkt_size = buf[nsync+4] * 256u + buf[nsync+5] + 7u         ; valid for CCSDS
  seqn = ( buf[nsynq+2] *256u + buf[nsync+3] ) and '3F'xu
  
  hdr_struct = {  time:0d, apid:0u,   psize:psize, seqn:seqn }  
  
 
   return,hdr_struct

end








;+
;  PROCEDURE SWFO_GSEMSG_Buffer_READ
;  This procedure is only specific to SWFO in the "sync bytes" found in the MSG header.  Otherwise it could be considered generic
;  It purpose is to read bytes from a previously opened MSG file OR stream.  It returns at the end of file (for files) or when
;  no more bytes are available for reading from a stream.
;  It should gracefully handle sync errors and find sync up on a MSG header.
;  When a complete MSG header and its enclosed CCSDS packet are read in, it will execute the routine "swfo_ccsds_spkt_handler"
;-

pro packet_reader::read,source  ,source_dict=parent_dict

  dwait = 10.

  if isa(parent_dict,'dictionary') &&  parent_dict.haskey('cmbhdr') then begin
    header = parent_dict.cmbhdr
    dprint,dlevel=4,verbose=self.verbose,header.description,'  ',header.size
  endif else begin
    dprint,verbose=self.verbose,dlevel=3,'No cmbhdr'
    header = {time: !values.d_nan, seqn:0U, size:0u , gap:0 }
  endelse


  ;printdat,source,/hex
  source_dict = self.source_dict
  dict = self.source_dict

  if ~source_dict.haskey('fifo') then begin
    dict.fifo = !null    ; this contains the unused bytes from a previous call
    dict.flag = 1
    ;self.verbose=3
  endif


  ;if ~source_dict.haskey('sync_ccsds_buf') then begin
  ;  source_dict.sync_ccsds_buf = !null   ; this contains the contents of the buffer from the last call
  ;endif
  ;run_proc=1

  ;if ~source_dict.haskey('remainder_gsemsg') then begin
  ;  source_dict.remainder_gsemsg = !null
  ;endif

  if debug(2,self.verbose) then begin
    if abs(fix(header.seqn - 3625)) lt 6  || ( header.size ne 134 && header.size ne 30 && header.size ne 268) then begin    ; trap to find problem
      dprint,header
      dprint
      dict.flag = 1
    endif

  endif



  if debug(4,self.verbose,msg='test') then begin
    ;printdat,source_dict
    print,n_elements(source_dict.sync_ccsds_buf),n_elements(source)
    hexprint,source
  endif

  on_ioerror, nextfile
  time = systime(1)
  source_dict.time_received = time

  msg = time_string(source_dict.time_received,tformat='hh:mm:ss.fff -',local=localtime)

  ;remainder = !null
  ;remainder = source_dict.remainder_gsemsg
  ;source_dict.remainder_gsemsg = !null
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
      dict.n2read = nb
      dict.packet_is_valid = 1
      continue            ; continue to read the rest of the packet
    endif


    if sync_errors ne 0 then begin
      dprint,verbose=self.verbose,dlevel=3,sync_errors,' sync errors'
    endif

    ; if it reaches this point then a valid message header+payload has been read in

    gsehdr  =  dict.fifo[0:5]
    payload =  dict.fifo[6: nb+6 - 1]
    
    self.handle,dict.fifo    ; process each packet


    if keyword_set(dict.flag) && debug(3,self.verbose,msg='status') then begin
      dprint,verbose=self.verbose,dlevel=3,header
      ;dprint,'gsehdr: ',n_elements(gsehdr)
      ;hexprint,gsehdr
      ;dprint,'payload: ',n_elements(payload)
      ;hexprint,payload
      dprint,'fifo: ', n_elements(dict.fifo)
      ;hexprint,dict.fifo
      dprint
    endif

    dict.fifo = !null

  endwhile

  if sync_errors ne 0 then begin
    dprint,verbose=self.verbose,dlevel=2,sync_errors,' GSEMSG sync errors at "'+time_string(source_dict.time_received)+'"'
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
  source_dict.msg = msg

  ;    dprint,dlevel=2,'Compression: ',float(fp)/fi.size

end



pro packet_reader::handle,buffer   ;,source_dict=source_dict

  msg_buf = buffer
  source_dict = self.source_dict
  buf = msg_buf[6:*]

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
      raw_tlm_header = self.header_struct(buf)
      if isa(self.dyndata,'dynamicarray') then self.dyndata.append,raw_tlm_header
      source_dict.gse_header  = raw_tlm_header
    end
    'c3'x: begin
      ;sync_pattern = ['1a'x,  'cf'x ,'fc'x, '1d'x ]
      ;source_dict.sync_pattern = sync_pattern
      if debug(4,self.verbose) then begin
        dprint,sz*2,dlevel=4,verbose=self.verbose
        hexprint,buf
      endif
      if ~source_dict.haskey('ccsds_dict') then begin
        source_dict.ccsds_dict =  dictionary()
        ccsds_dict = source_dict.ccsds_dict
        ccsds_dict.sync_ccsds_buf = !null
        ccsds_dict.sync_pattern = byte(['1a'x,  'cf'x ,'fc'x, '1d'x ])
      endif
      ccsds_dict = source_dict.ccsds_dict
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
          dprint,verbose=self.verbose,dlevel=2,'Skipped ',skipped,' bytes to find sync word'
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
        ccsds_buf = ccsds_dict.sync_ccsds_buf[4:pkt_size+4-1]  ; not robust!!!
        if self.run_proc then  begin
          swfo_ccsds_spkt_handler,ccsds_buf,source_dict=ccsds_dict
        endif
        if ccsds_dict.haskey('ccsds_writer') && obj_valid(ccsds_dict.ccsds_writer) then begin   ; hook to generate ccsds files
          ccsds_writer = ccsds_dict.ccsds_writer
          ccsds_writer.directory = self.directory
          ccsds_writer.time_received = ccsds_dict.gse_header.time
          if ccsds_writer.getattr('output_lun') eq 0 then begin
            dprint,'Are you sure about this?
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
      endwhile
    end
    else:    message,'GSE raw_tlm error - unknown code'
  endcase


end



PRO packet_reader__define
  void = {packet_reader, $
    inherits socket_reader, $    ; superclass
    ;ccsds_reader:   obj_new(), $         ; user definable object  not used
    ;gsemsg_reader:  obj_new(),  $
    sync_size:  0 , $
    header_size:  0  $
}
END




