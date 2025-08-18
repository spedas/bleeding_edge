; $LastChangedBy: davin-mac $
; $LastChangedDate: 2024-09-10 22:51:25 -0700 (Tue, 10 Sep 2024) $
; $LastChangedRevision: 32817 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu:36867/repos/spdsoft/trunk/projects/SWFO/STIS/ccsds_reader__define.pro $



;+
;  PROCEDURE ccsds_reader
;  This object is a collecton of routines to process socket stream and files that have CCSDS packets
;  is only specific to SWFO in the default decom_procedure on initialization.
;  When a complete ccsds packet is read in  it will execute the routine "swfo_ccsds_spkt_handler"
;-






function ccsds_frame_reader::header_struct,header

  nsync = self.sync_size
  if nsync ne 0 then  sync = self.sync_pattern[0:nsync-1] else sync = !null

  ;if header[0] eq 0x3b then begin
  ;   i=1;    printdat,/hex,self.sync_mask,sync,header     ; trap to detect replay packets for SWFO
  ;endif
  
  
  if n_elements(header) lt self.header_size then return, !null                    ; Not enough bytes in packet header
  if  (isa(sync) && (array_equal(sync,header[0:nsync-1] and self.sync_mask) eq 0)) then begin
    dprint,dlevel=1,verbose=self.verbose,'Invalid Sync skipping.. ',self.sync
    return,!null   ; Not a valid packet
  endif
  
  strct = {  time:!values.d_nan,index:0uL,SEQN:0UL, seqn_delta:0L, scid:0u, vcid:0b, seqid:0u, psize: 0u ,   sigfield:0b  , offset:0u, last4:[0b,0b,0b,0b], hashcode:0uL,replay:0b, valid:1b, gap:0b}
  
  strct.index = self.index++

  
  temp = (header[nsync+0] * 256U + header[nsync+1])
  strct.scid  = ishft(temp,-6)  ;  and 0xFF 
  strct.vcid  = temp and 0x3F
  strct.seqn = ((header[nsync+2] *256ul) +header[nsync+3]) *256ul + header[nsync+4]
  strct.sigfield = header[nsync+5]
  strct.offset = header[nsync+6]*256u + header[nsync+7]
  
  strct.psize = self.frame_size - self.header_size   ; size of payload  (6 bytes less than size of ccsds packet)
  
  if n_elements(header) eq self.frame_size then begin
    strct.last4 = header[-4:-1]
    ;strct.seqid = (strct.last4[-2] and 0b) *100u + strct.vcid
    strct.seqid =  strct.vcid
    strct.hashcode = header.hashcode()
  endif
  
  ;strct.hashcode = header.hashcode()

 ; if isa(sync) && header[0] eq 0x3b then begin    ; special case for SWFO
 ;   strct.apid = strct.apid or 0x8000         ; turn on highest order bit to segregate different apid
 ; endif


  return,strct

end


pro ccsds_frame_reader::print_info,hdr,txt,dlevel=dlevel
  dprint,dlevel=dlevel,verbose=self.verbose,hdr.index,hdr.vcid,hdr.seqn,hdr.seqn_delta,hdr.sigfield,hdr.offset,hdr.last4[2],hdr.last4[3],' '+txt

end



pro ccsds_frame_reader::handle,frame    ; This routine handles a SINGLE ccsds frame  

  if debug(5,self.verbose) then begin
    dprint,self.name
    hexprint,frame
    dprint
  endif
  
  payload = frame[12 : -5]    ; skip header and leave off the last 4 bytes.  Not clear what they are.
  
  frame_headerstr = self.source_dict.headerstr
;  frame_headerstr.index = self.index++
  
  ;seqid = frame_headerstr.vcid + 100u * (frame[-2] and 6)
  seqid = frame_headerstr.seqid
  
  if ~self.handlers.haskey(seqid) then begin
    self.print_info,dlevel=2,frame_headerstr,'New VCid: '+strtrim(seqid,2)
    name = self.mission+'_pkt_seqid_'+strtrim(seqid,2)
    if isa(self.source_dict,'dictionary') && self.source_dict.haskey('run_proc')  then run_proc = self.source_dict.run_proc
    self.handlers[seqid] = ccsds_reader(mission=self.mission,/no_widget,sync_pattern=!null,/save_data,name=name,run_proc=run_proc)
    cpkt_rdr = self.handlers[seqid]
    cpkt_rdr.source_dict.fifo = !null
    cpkt_rdr.source_dict.headerstr = !null
    cpkt_rdr.source_dict.last_frm_seqn = 0
    cpkt_rdr.source_dict.dejavu_cntr = 0ul
    cpkt_rdr.source_dict.dejavu_hashcodes = ulonarr(9000)    ; the size of this might need to be increased
  endif
  
  cpkt_rdr = self.handlers[seqid]
    
  frm_seqn = frame_headerstr.seqn
  
  last_frm_seqn = cpkt_rdr.source_dict.last_frm_seqn
  seqn_delta = (long(frm_seqn) - last_frm_seqn) ;and 0xFFFFFFu
  cpkt_rdr.source_dict.last_frm_seqn = frm_seqn
  frame_headerstr.seqn_delta = seqn_delta

  hcode = frame.hashcode()
  dict = cpkt_rdr.source_dict  
  ncodes = n_elements(dict.dejavu_hashcodes)
  w_hcode = where(hcode eq dict.dejavu_hashcodes,/null,nw)
  ;dprint,dlevel=4,verbose=self.verbose,'Frame: ',frm_seqn, seqid, hcode,'  ',  isa(w_hcode) ?  w_hcode[0] : long( -1) , '     ', frame[-4:*]
  
  dejavu_hashcodes = dict.dejavu_hashcodes
  dejavu_hashcodes[dict.dejavu_cntr++] = hcode
  dict.dejavu_hashcodes  = dejavu_hashcodes
  dict.dejavu_cntr = dict.dejavu_cntr mod ncodes
  if isa(w_hcode) then begin
    disp = (dict.dejavu_cntr - ulong(w_hcode[0]) ) mod ncodes
    if disp gt 1 then begin
      self.print_info,dlevel=2,frame_headerstr,'Repeat: '+strtrim(disp,2)+' '+strtrim(nw,2)
    endif else begin
      self.print_info,dlevel=3,frame_headerstr,'Repeat: '+strtrim(disp,2)+' '+strtrim(nw,2)
    endelse
    frame_headerstr.valid = 0
  endif else begin

    self.print_info,dlevel=4,frame_headerstr,'  '
    if seqn_delta ne 1 then begin
      ;dprint,'Jump ahead by ' ,seqn_delta,frm_seqn,verbose = self.verbose,dlevel=2,'                    ', frame[-4:*]
      self.print_info,dlevel=3,frame_headerstr,'Missing'
      frame_headerstr.gap = 1
      cpkt_rdr.source_dict.FIFO = !null
    endif
    offset = frame_headerstr.offset

    length_fifo  =  n_elements(cpkt_rdr.source_dict.fifo)
    if isa(cpkt_rdr.source_dict.headerstr) then begin
      psize =  cpkt_rdr.source_dict.headerstr.psize
    endif

    if length_fifo eq 0  then begin   ; First time there won't be a pre-existing FIFO;  skip the beginning bytes and start at offset
      ;cpkt_rdr.read, payload[offset:*]
      start = offset
    endif else begin
      if offset eq 0x7ff then begin
        ;dprint,dlevel=3,verbose=self.verbose, 'No start packet ',frm_seqn
        self.print_info,dlevel=5,frame_headerstr,'No start packet '
        start = 0
      endif else begin
        if isa(psize) && psize + 6 ne length_fifo+offset then begin
          ;dprint,dlevel=1,verbose=self.verbose, 'Offset error: ',psize+6,length_fifo,offset
          self.print_info,dlevel=1,frame_headerstr,'Offset error: '+string(psize+6-length_fifo)+' '+string(offset)
          start = offset         ; start new sequence
          cpkt_rdr.source_dict.fifo=!null
          cpkt_rdr.source_dict.headerstr=!null
        endif else start = 0
      endelse
    endelse
    
    cpkt_rdr.source_dict.pkt_time = !values.d_nan
    if start lt n_elements(payload) then begin
      cpkt_rdr.read,   payload[start:*]         
    endif else begin
      self.print_info,dlevel=3,frame_headerstr,'Skipping'
    endelse
    frame_headerstr.time = cpkt_rdr.source_dict.pkt_time
    
  endelse
  
  if self.save_data then  self.dyndata.append, frame_headerstr
  
end





function ccsds_frame_reader::init,sync_pattern=sync_pattern,sync_mask=sync_mask,decom_procedure = decom_procedure,mission=mission,_extra=ex
  ret=self.socket_reader::init(_extra=ex)
  if ret eq 0 then return,0

  if isa(mission,'string') then self.mission = mission
  if self.mission eq 'SWFO' then begin
    if ~isa(sync_pattern) then sync_pattern = ['1a'xb,  'cf'xb ,'fc'xb, '1d'xb ]
    ;decom_procedure = 'swfo_ccsds_spkt_handler'
  endif
  self.sync_size = n_elements(sync_pattern)
  self.maxsize = 1100
  self.minsize = 1000
  if self.sync_size gt 4 then begin
    dprint,'Number of sync bytes must be <= 4'
    return, 0
  endif
  if self.sync_size ne 0 then begin
    self.sync_pattern = sync_pattern
    self.sync_mask = ['ff'xb,  'ff'xb ,'ff'xb, 'ff'xb ]
  endif
  if isa(sync_mask) then self.sync_mask = sync_mask
  self.header_size = self.sync_size + 8
  self.header_size =1024   ; just read in the whole frame
  self.frame_size = 1024
  self.save_data = 1
  self.handlers = orderedhash()
  ;self.ccsds_packet_reader = ccsds_reader(mission=mission,/no_widget,sync_pattern=!null,/save_data)

  return,1
end





PRO ccsds_frame_reader__define
  void = {ccsds_frame_reader, $
    inherits socket_reader, $    ; superclass
    frame_size: 0uL, $
    ;decom_procedure: '',  $
    mission: '',  $
    index: 0ul,  $
    handlers: obj_new() , $
    ;ccsds_packet_reader: obj_new(),  $
    ;ccsds_packet_reader2: obj_new(),  $
    ;last_frame_seqn: 0ul,  $
    minsize: 0UL , $
    maxsize: 0UL  $
  }
END




