; $LastChangedBy: davin-mac $
; $LastChangedDate: 2024-01-03 22:36:00 -0800 (Wed, 03 Jan 2024) $
; $LastChangedRevision: 32332 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SWFO/STIS/ptp_reader__define.pro $



;+
;  PROCEDURE ptp_reader
;  This object is a collecton of routines to process socket stream and files that have CCSDS packets
;  is only specific to SWFO in the default decom_procedure on initialization.
;  When a complete ccsds packet is read in  it will execute the routine "swfo_ccsds_spkt_handler"
;-



function ptp_header_struct,ptphdr
  ptp_size = swap_endian(uint(ptphdr,0) ,/swap_if_little_endian )
  ptp_code = ptphdr[2]
  ptp_scid = swap_endian(/swap_if_little_endian, uint(ptphdr,3))

  days  = swap_endian(/swap_if_little_endian, uint(ptphdr,5))
  ms    = swap_endian(/swap_if_little_endian, ulong(ptphdr,7))
  us    = swap_endian(/swap_if_little_endian, uint(ptphdr,11))
  utime = (days-4383L) * 86400L + ms/1000d
  if utime lt   1425168000 then utime += us/1d4   ;  correct for error in pre 2015-3-1 files
  ;      if keyword_set(time) then dt = utime-time  else dt = 0
  source   =    ptphdr[13]
  spare    =    ptphdr[14]
  path  = swap_endian(/swap_if_little_endian, uint(ptphdr,15))
  ;  ptp_header ={ptp_size:ptp_size, ptp_code:ptp_code, ptp_scid: ptp_scid, ptp_time:utime, ptp_source:source, ptp_spare:spare, ptp_path:path }
  ptp_header ={time:utime,psize:ptp_size-17,ptp_size:ptp_size, ptp_code:ptp_code, ptp_scid: ptp_scid, ptp_time:utime, ptp_source:source, ptp_spare:spare, ptp_path:path }
  return,ptp_header
end





function ptp_reader::header_struct,header

  nsync = self.sync_size
  if nsync ne 0 then  sync = self.sync_pattern[0:nsync-1] else sync = !null

  if n_elements(header) lt self.header_size then return, !null                    ; Not enough bytes in packet header

  if  (isa(sync) && array_equal(sync,header[self.sync_start:self.sync_start+nsync-1]) eq 0) then return,!null   ; Not a valid packet

  ;strct = {  time:!values.d_nan, apid:0u,  psize: 0u , type:0u ,valid:0, gap:0}
  ;strct.apid  = (header[nsync+0] * 256U + header[nsync+1]) and 0x3FFF
  ;strct.psize = header[nsync+4] * 256u + header[nsync+5] + 1   ; size of payload  (6 bytes less than size of ccsds packet)
  strct = ptp_header_struct(header)

  return,strct

end






pro ptp_reader::handle,buffer

  if debug(3,self.verbose) then begin
    dprint,verbose=self.verbose,dlevel =2,self.name
    hexprint,buffer
    dprint
  endif

  if self.run_proc then begin
    payload = buffer[self.header_size:*]
    hdr = self.source_dict.headerstr
    if keyword_set(self.decom_procedure) then begin
      if debug(3,self.verbose) then begin
        dprint,self.name,'  ',time_string(hdr.time,prec=3) +'  '+strtrim(hdr.psize),verbose=self.verbose,dlevel=2
      endif
      call_procedure,self.decom_procedure,payload,source_dict=self.source_dict         ; Process the complete packet
    endif else begin
      if debug(3,self.verbose) then begin
        dprint,self.name,time_string(hdr.time,prec=3) +'  '+strtrim(hdr.psize),verbose=self.verbose,dlevel=2
        hexprint,payload        
      endif
    endelse
  endif

end





function ptp_reader::init,sync_pattern=sync_pattern,decom_procedure = decom_procedure,mission=mission,_extra=ex
  ret=self.socket_reader::init(_extra=ex)
  if ret eq 0 then return,0

  if ~isa(sync_pattern) then sync_pattern = ['03'xb,  '00'xb ,'bb'xb ]
  if isa(mission,'string') && mission eq 'SWFO' then begin      ; This keyword is tempporary and WILL be removed
    self.decom_procedure = 'swfo_ccsds_spkt_handler'
  endif
  if isa(mission,'string') && mission eq 'SWX' then begin     ; This keyword is tempporary and WILL be removed
    self.decom_procedure = 'swx_ccsds_spkt_handler'
    swx_apdat_init,/save,/swem
  endif
  self.sync_size = n_elements(sync_pattern)
  self.maxsize = 4100
  self.minsize = 10
  if self.sync_size gt 4 then begin
    dprint,'Number of sync bytes must be <= 4'
    return, 0
  endif
  if self.sync_size ne 0 then self.sync_pattern = sync_pattern
  self.header_size = 17
  self.sync_start = 2

  return,1
end





PRO ptp_reader__define
  void = {ptp_reader, $
    inherits cmblk_reader, $    ; superclass
    sync_start: 0, $
    decom_procedure: '',  $
    minsize: 0UL , $
    maxsize: 0UL  $
  }
END




