; $LastChangedBy:  $
; $LastChangedDate: 2022-05-01 12:57:34 -0700 (Sun, 01 May 2022) $
; $LastChangedRevision: 30793 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu:36867/repos/spdsoft/trunk/projects/SWFO/STIS/swfo_gsemsg_lun_read.pro $








;+
;  PROCEDURE ccsds_reader
;  This object is a collecton of routines to process socket stream and files that have CCSDS packets
;  is only specific to SWFO in the default decom_procedure on initialization.
;  When a complete ccsds packet is read in  it will execute the routine "swfo_ccsds_spkt_handler"
;-

pro ccsds_reader::read,source,source_dict=parent_dict

  dwait = 10.

  if isa(parent_dict,'dictionary') &&  parent_dict.haskey('cmbhdr') then begin
    header = parent_dict.cmbhdr
    ;   dprint,dlevel=4,verbose=self.verbose,header.description,'  ',header.size
  endif else begin
    dprint,verbose=self.verbose,dlevel=4,'No cmbhdr'
    header = {time: !values.d_nan , gap:0 }
  endelse

  source_dict = self.source_dict

  if ~source_dict.haskey('sync_ccsds_buf') then source_dict.sync_ccsds_buf = !null   ; this contains the contents of the buffer from the last call

  on_ioerror, nextfile
  time = systime(1)
  source_dict.time_received = time

  msg = time_string(source_dict.time_received,tformat='hh:mm:ss.fff -',local=localtime)

  remainder = !null
  nbytes = 0UL
  sync_errors =0ul
  ns = self.nsync
  sync_pattern = ns eq 0 ? !null : self.sync[0:ns-1]
  source_dict.sync_pattern = sync_pattern
  nb = ns + 6   ; length of sync bytes plus 6 byte ccsds header
  while isa( (buf= self.read_nbytes(nb,source,pos=nbytes) ) ) do begin
    if n_elements(buf) ne nb then begin
      dprint,verbose=self.verbose,'Invalid length of CCSDS header',dlevel=1
      hexprint,buf
      source_dict.remainder = buf
      break
    endif
    if debug(3,self.verbose,msg=strtrim(nb)) then begin
      dprint,nb,dlevel=3
      hexprint,buf
    endif
    msg_buf = [remainder,buf]
    sz = msg_buf[4+ns]*256L + msg_buf[5+ns]
    bad_sync = (ns gt 0) && ~array_equal(sync_pattern,msg_buf[0:ns-1] )
    if bad_sync || (sz lt self.minsize) || (sz gt self.maxsize)  then  begin     ;; Lost sync - read one byte at a time
      remainder = msg_buf[1:*]
      nb = 1
      sync_errors += 1
      if debug(2) then begin
        dprint,verbose=self.verbose,dlevel=2,'Lost sync:' ,dwait=2
      endif
      continue
    endif

    pkt_size = sz +1
    buf = self.read_nbytes(pkt_size,source,pos=nbytes)
    ccsds_buf = [msg_buf[ns:ns+5],buf]    ;   ccsds header and payload  (remove sync)

    if  self.run_proc then  call_procedure,self.decom_procedure,ccsds_buf,source_dict=source_dict
    ;if n_elements(source_dict.sync_ccsds_buf) eq pkt_size+4 then source_dict.sync_ccsds_buf = !null $
    ;else    source_dict.sync_ccsds_buf = source_dict.sync_ccsds_buf[pkt_size+4:*]


    if debug(3,self.verbose,msg=strtrim(n_elements(ccsds_buf))) then begin
      hexprint,dlevel=3,ccsds_buf    ;,nbytes=32
    endif
    nb = ns+6     ; initialize for next read
  endwhile

  if sync_errors then begin
    dprint,dlevel=2,sync_errors,' sync errors at "'+time_string(source_dict.time_received)+'"'
    ;printdat,source
    ;hexprint,source
  endif

  if isa(output_lun) then  flush,output_lun

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




function ccsds_reader::init,sync=sync,decom_procedure = decom_procedure,_extra=ex
  ret=self.socket_reader::init(_extra=ex)
  if ret eq 0 then return,0
  
  if keyword_set(decom_procedure) then  self.decom_procedure = decom_procedure else self.decom_procedure ='swfo_ccsds_spkt_handler'
  self.nsync = n_elements(sync)
  self.maxsize = 4100
  self.minsize = 10
  if self.nsync gt 4 then begin
    dprint,'Number of sync bytes must be <= 4'
    return, 0
  endif
  if self.nsync ne 0 then self.sync = sync 

  return,1
end

PRO ccsds_reader__define
  void = {ccsds_reader, $
    inherits socket_reader, $    ; superclass
    decom_procedure: '',  $
    minsize: 0UL,  $
    maxsize: 0UL,  $
    sync:  bytarr(4),  $
    nsync:  0  $
  }
END




