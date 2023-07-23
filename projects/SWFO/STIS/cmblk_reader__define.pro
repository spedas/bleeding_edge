;+
;  cmblk_reader
;  This basic object is the entry point for defining and obtaining all data from common block files
; $LastChangedBy: ali $
; $LastChangedDate: 2022-08-05 15:10:39 -0700 (Fri, 05 Aug 2022) $
; $LastChangedRevision: 30999 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu:36867/repos/spdsoft/trunk/projects/SWFO/STIS/swfo_gen_apdat__define.pro $
;-
COMPILE_OPT IDL2


FUNCTION cmblk_reader::Init,_EXTRA=ex,handlers=handlers

  txt = ['tplot,verbose=0,trange=systime(1)+[-1,.05]*3600*.1','timebar, systime(1)']
  exec, exec_text = txt

  ; Call our superclass Initialization method.
  void = self.socket_reader::Init(_EXTRA = ex)
  if isa(handlers,'hash') then begin
    self.handlers = handlers 
  endif else  self.handlers = orderedhash()
  self.sync  = 'CMB1'
  self.desctypes = orderedhash()
  if  keyword_set(ex) then dprint,ex,phelp=2,dlevel=self.dlevel,verbose=self.verbose
  ;IF (ISA(ex)) THEN self->SetProperty, _EXTRA=ex
  
;  self.add_handler, 'MANIP', json_reader(name='Manip',/no_widget,tplot_tagnames='*')

; The following lines are temporary to define read routines for different data
;  self.add_handler, 'raw_tlm',  swfo_raw_tlm('SWFO_raw_telem',/no_widget)
;  self.add_handler, 'KEYSIGHTPS' ,  gse_keysight('Keysight',/no_widget)

;
;  
  self.add_handler, 'ESC_ESATM',  esc_esatm_reader(name='Esc_ESAs',/no_widget)


  RETURN, 1
END




PRO cmblk_reader::Cleanup
  COMPILE_OPT IDL2
  ; Call our superclass Cleanup method
  dprint,"killing object:", self.name
  self->socket_reader::Cleanup
END


function cmblk_reader::header_struct,buf

  cmb = {  $
    sync: 0ul, $
    size: 0ul, $
    time: !values.d_nan,  $
    seqn: 0u,  $
    user: 0u,  $
    source: 0u,$   ; byte stored as uint
    type: 0u,  $   ; byte stored as uint
    ;   desc_array: bytarr(10) ,     $
    description:'', $
    gap:0}

  if ~isa(buf) then return,cmb

  cmb.sync  = swap_endian(/swap_if_little_endian, ulong(buf,0,1) )
  cmb.size  = swap_endian(/swap_if_little_endian, ulong(buf,4,1) )
  cmb.time  = swap_endian(/swap_if_little_endian, double(buf,8,1) )
  cmb.seqn  = swap_endian(/swap_if_little_endian, uint(buf,16,1) )
  cmb.user  = swap_endian(/swap_if_little_endian, uint(buf,18,1) )
  cmb.source=   buf[20]    ; byte stored as a uint
  cmb.type  =   buf[21]    ; byte stored as a uint
  desc_array = buf[22:31]
  ;swap_endian_inplace,cmb,/swap_if_little_endian
  w = where(desc_array gt 48b,/null)
  payload_key = desc_array[w]
  if isa(payload_key ) then  cmb.description = string(payload_key)
  return,cmb
end


pro cmblk_reader::read ,buffer  , source_dict = source_dict

  if isa(source_dict,'dictionary') then begin
    dprint,'Recursive call not allowed yet.'
  endif


  dwait = 10.
  sync = swap_endian(ulong(byte('CMB1'),0,1),/swap_if_little_endian)

  ; on_ioerror, nextfile
  time = systime(1)
  last_time = self.time_received
  if last_time eq 0 then last_time=!values.d_nan
  self.time_received = time
  self.msg = time_string(time,tformat='hh:mm:ss - ',local=localtime)
  remainder = !null
  nbytes = 0UL
  npkts  = 0UL
  sync_errors = 0UL
  eofile = 0

  if ~self.source_dict.haskey('cmbhdr') then  self.source_dict.cmbhdr = self.header_struct()

  nb = 32   ; number of bytes to be read to get the full header
  while isa( (buf = self.read_nbytes(nb,buffer,pos=nbytes) )   ) do begin
    if debug(5,self.verbose,msg='cmbhdr: ') then begin
      ;dprint,nb,dlevel=4
      hexprint,buf
    endif
    msg_buf = [remainder,buf]
    cmbhdr = self.header_struct(msg_buf)
    if debug(4,self.verbose) then begin
      dprint,dlevel=4,verbose=self.verbose,'CMB: ',time_string(cmbhdr.time,prec=3),' ',cmbhdr.seqn,cmbhdr.size,'  ',cmbhdr.description
    endif
    if cmbhdr.sync ne sync || cmbhdr.size gt 30000 then begin
      remainder = msg_buf[1:*]
      nb = 1             ; advance one byte at a time looking for the sync
      ;if debug(2) then begin
      dprint,verbose=self.verbose,dlevel=1,'Lost sync:',dwait=dwait
      sync_errors++
      continue
    endif
    last_cmbhdr = self.source_dict.cmbhdr
    self.source_dict.cmbhdr = cmbhdr
    ;dprint,dlevel=3,verbose=self.verbose,cmbhdr.size,cmbhdr.seqn,'  ',cmbhdr.description

    ;  read the payload bytes
    payload_buf = self.read_nbytes(cmbhdr.size,pos=nbytes)
    npkts++

    ; decomutate data here!
    self.handle, payload_buf, source_dict=self.source_dict

    mem_current = memory(/current) / 2.^20

    cmbdata = { $
      time:cmbhdr.time   ,$
      seqn:cmbhdr.seqn   ,$
      time_delta: cmbhdr.time-last_cmbhdr.time, $
      seqn_delta: cmbhdr.seqn-last_cmbhdr.seqn, $
      size: cmbhdr.size, $
      user: cmbhdr.user, $
      type: cmbhdr.type, $
      source: cmbhdr.source,  $
      desctype:  0u,  $
      errors: sync_errors, $
      memory: mem_current, $
      gap:0b $
    }
    cmbdata.gap = cmbdata.seqn_delta ne 1
    self.dyndata.append , cmbdata
    nb = 32      ; Get ready for next packet
  endwhile
  
  if sync_errors then begin
    dprint,verbose=self.verbose,dlevel=0,'Encountered '+strtrim(sync_errors,2)+' Errors'
  endif
  delta_time = time - last_time
  self.nbytes += nbytes
  self.npkts  += npkts
  self.nreads += 1
  self.msg += strtrim(self.sum1_bytes,2)+ ' bytes'

  if 0 then begin
    nextfile:
    dprint,verbose=self.verbose,dlevel=0,'File error? '
    self.help
  endif

  dprint,verbose=self.verbose,dlevel=3,self.msg

end




pro cmblk_reader::handle,payload, source_dict=source_dict   ; , cmbhdr= cmbhdr

  ; Decommutate data
  cmbhdr = source_dict.cmbhdr
  descr_key = cmbhdr.description
  handlers = self.handlers
  if cmbhdr.source ne 0 then   source_str = '-'+strtrim(cmbhdr.source,2) else source_str=''
  descr_key = descr_key + source_str
  
  if handlers.haskey( descr_key ) eq 0  then begin        ; establish new ones if not already defined
    dprint,verbose=self.verbose,dlevel=1,'Found new description key: "', descr_key,'"'
    n = n_elements(payload)
    eol = payload[n-1]
    dprint,'Payload:',dlevel=2,verbose=self.verbose
    hexprint,payload
    descr_key_lower = strlowcase(descr_key)
    tagnames='*'
    if n gt 10 && (eol eq 10 || eol eq 13)  then begin 
      dprint,verbose=self.verbose,dlevel=2, "EOL = ",eol
      if  array_equal(payload[[0,n-2]] , [123b,125b]) then begin
        dprint,verbose=self.verbose,dlevel=2,'Identified as JSON'
        new_obj = json_reader(name=descr_key_lower,/no_widget,eol=eol,tplot_tagnames=tagnames)
      endif else begin
        new_obj =  ascii_reader(name=descr_key_lower,/no_widget,eol=eol,tplot_tagnames=tagnames)        
      endelse
    endif else begin
      new_obj =  socket_reader(name=descr_key_lower,/no_widget)      
    endelse
    handlers[descr_key] = new_obj
    new_obj.apid = descr_key
  endif
  
  
  ;if ~self.desctypes.haskey(descr_key) then self.desctypes[descr_key] = n_elements(self.desctypes)

  if self.run_proc then begin
    d = self.source_dict
    d.cmbhdr = cmbhdr            ; this line is redundant!
    handler =  handlers[descr_key]                     ; Get the proper handler object
    if obj_valid(handler) then begin
      handler.read, payload, source_dict=d         ; execute handler
    endif else begin
      dprint,verbose=self.verbose,dlevel=1,'Invalid handle object for cmblk_key: "',descr_key,'"'
    endelse
  endif
end



pro cmblk_reader::print_status,no_header=no_header
  self.socket_reader::print_status,no_header=no_header
  foreach h , self.handlers,apid do   h.print_status,/no_header,apid=apid
end





pro cmblk_reader::add_handler,key,object
  ;help,hds,object
  if isa(key,'HASH') then begin
    self.handlers += key
  endif else begin
    self.handlers[key]= object
    object.apid = key
  endelse
  dprint,'Added new handler: ',key,verbose=self.verbose,dlevel=1
  ;help,self.handlers
end


function cmblk_reader::get_handlers, key
  retval = !null
  handlers = self.handlers
  if obj_valid(handlers) then begin
    if  isa(key,/string) then begin
      if handlers.haskey(key) then retval = handlers[key]
    endif else  retval = handlers
  endif
  return,retval
end



PRO cmblk_reader__define
  void = {cmblk_reader, $
    inherits socket_reader, $    ; superclass
    desctypes:        obj_new(), $
    handlers:     obj_new(),  $
    sync:  'CMB1'     $         ;
  }
END


