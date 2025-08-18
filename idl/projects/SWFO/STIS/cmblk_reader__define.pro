;+
;  cmblk_reader
;  This basic object is the entry point for defining and obtaining all data from common block files
;  A description of this file format is available at:
;  https://docs.google.com/presentation/d/1b5ooHfuHJsavys-BOUOOZohXeCzJC1M0MNaUlxM1tEg/edit?usp=sharing
; $LastChangedBy: davin-mac $
; $LastChangedDate: 2024-11-04 20:21:48 -0800 (Mon, 04 Nov 2024) $
; $LastChangedRevision: 32933 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SWFO/STIS/cmblk_reader__define.pro $
;-
COMPILE_OPT IDL2


FUNCTION cmblk_reader::Init,_EXTRA=ex,handlers=handlers

  ;txt = ['tplot,verbose=0,trange=systime(1)+[-1,.05]*3600*.1','timebar, systime(1)']
  ;exec, exec_text = txt

  ; Call our superclass Initialization method.
  void = self.socket_reader::Init(_EXTRA = ex)
  if isa(handlers,'hash') then begin
    self.handlers = handlers 
  endif else  self.handlers = orderedhash()
  self.sync  = 'CMB1'
  self.header_size = 32
  self.sync_pattern = byte('CMB1')
  self.sync_mask = byte([0xff,0xff,0xff,0xff])
  self.sync_size = 4
;  self.desctypes = orderedhash()
  if  keyword_set(ex) then dprint,ex,phelp=2,dlevel=self.dlevel,verbose=self.verbose
  ;IF (ISA(ex)) THEN self->SetProperty, _EXTRA=ex
  
;  self.add_handler, 'MANIP', json_reader(name='Manip',/no_widget,tplot_tagnames='*')

; The following lines are temporary to define read routines for different data
;  self.add_handler, 'raw_tlm',  swfo_raw_tlm('SWFO_raw_telem',/no_widget)
;  self.add_handler, 'KEYSIGHTPS' ,  gse_keysight('Keysight',/no_widget)

;
;  

;  self.add_handler, 'ESC_ESATM',  esc_esatm_reader(name='Esc_ESAs',/no_widget)


  RETURN, 1
END




PRO cmblk_reader::Cleanup
  COMPILE_OPT IDL2
  ; Call our superclass Cleanup method
  dprint,"killing object:", self.name
  self->socket_reader::Cleanup
END


; If overloading this function - the only required element is psize (payload size)

function cmblk_reader::header_struct,header

  cmb = {  $
    sync: 0ul, $
    psize: 0ul, $
    time: !values.d_nan,  $
    seqn: 0u,  $
    user: 0u,  $
    source: 0u,$   ; byte stored as uint
    type: 0u,  $   ; byte stored as uint
    ;   desc_array: bytarr(10) ,     $
    description:'', $
    gap:0}

  sync = self.sync_pattern
  nsync = self.sync_size
  if n_elements(header) lt self.header_size then return,!null
  if  (isa(sync) && array_equal(sync,header[0:nsync-1]) eq 0) then return,!null   ; Not a valid packet

  cmb.sync  = swap_endian(/swap_if_little_endian, ulong(header,0,1) )
  cmb.psize  = swap_endian(/swap_if_little_endian, ulong(header,4,1) )
  cmb.time  = swap_endian(/swap_if_little_endian, double(header,8,1) )
  cmb.seqn  = swap_endian(/swap_if_little_endian, uint(header,16,1) )
  cmb.user  = swap_endian(/swap_if_little_endian, uint(header,18,1) )
  cmb.source=   header[20]    ; byte stored as a uint
  cmb.type  =   header[21]    ; byte stored as a uint
  desc_array = header[22:31]
  ;swap_endian_inplace,cmb,/swap_if_little_endian
  w = where(desc_array gt 48b,/null)                  ; why this?????
  payload_key = desc_array[w]
  if isa(payload_key ) then  cmb.description = string(payload_key)
;  print,time_string(cmb.time)
  return,cmb
end




;+
  ; :Description:
  ;    Describe the procedure.
  ;
  ; :Params:
  ;    source
  ;
  ;
  ;
  ; :Author: davin
  ;-
pro cmblk_reader::read_old2,source     ; This routine is now obsolete - moved to socket_reader__define

  ;dwait = 10.

  dict = self.source_dict
  if dict.haskey('parent_dict') then parent_dict = dict.parent_dict


;  if isa(parent_dict,'dictionary') &&  parent_dict.haskey('headerstr') then begin
;    header = parent_dict.headerstr
;    ;   dprint,dlevel=4,verbose=self.verbose,header.description,'  ',header.size
;  endif else begin
;    dprint,verbose=self.verbose,dlevel=4,'No headerstr'
;    header = {time: !values.d_nan , gap:0 }
;  endelse


  if ~dict.haskey('fifo') then begin
    dict.fifo = !null    ; this contains the unused bytes from a previous call
    dict.flag = 0
    ;self.verbose=3
  endif


  on_ioerror, nextfile
  time = systime(1)
  dict.time_received = time

  msg = '' ;time_string(dict.time_received,tformat='hh:mm:ss.fff -',local=localtime)

  nbytes = 0UL
  ;sync_errors =0ul
  total_bytes = 0L
  endofdata = 0
  while ~endofdata do begin

    if dict.fifo eq !null then begin
      dict.n2read = self.header_size
      dict.headerstr = !null
      dict.sync_errors = 0
      dict.packet_is_complete = 0
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

    if ~isa(dict.headerstr) then begin

      dict.headerstr = self.header_struct(dict.fifo)
      if ~isa(dict.headerstr) then    begin     ; invalid structure: Skip a byte and try again
        dict.fifo = dict.fifo[1:*]
        dict.n2read = 1
        nb = 1
        dict.sync_errors += 1
        continue      ; read one byte at a time until sync is found
      endif
      dict.packet_is_complete = 0
    endif

    if ~dict.packet_is_complete then begin
      nb = dict.headerstr.psize
      if nb eq 0 then begin
        dprint,verbose = self.verbose,dlevel=2,self.name+'; Packet length with zero length'
        dict.fifo = !null
      endif else begin
        dict.packet_is_complete =1
        dict.n2read = nb
      endelse
      continue            ; continue to read the rest of the packet
    endif


    if dict.sync_errors ne 0 then begin
      dprint,verbose=self.verbose,dlevel=2,self.name+': '+strtrim(dict.sync_errors,2)+' sync errors';,dwait =4.
    endif

    ; if it reaches this point then a valid message header+payload has been read in

    if self.save_data && isa(self.dyndata,'dynamicarray') then begin
      self.dyndata.append,dict.headerstr
    endif

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

  if dict.sync_errors ne 0 then begin
    dprint,verbose=self.verbose,dlevel=2,self.name+': '+strtrim(dict.sync_errors,1)+' sync errors at "'+time_string(dict.time_received)+'"'
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

end





pro cmblk_reader::read_old1 ,buffer      ;, source_dict = source_dict

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
  self.msg =''   ; time_string(time,tformat='hh:mm:ss - ',local=localtime)
  remainder = !null
  nbytes = 0UL
  npkts  = 0UL
  sync_errors = 0UL
  eofile = 0

  if ~self.source_dict.haskey('headerstr') then  self.source_dict.headerstr = self.header_struct()

  nb = 32   ; number of bytes to be read to get the full header
  while isa( (buf = self.read_nbytes(nb,buffer,pos=nbytes) )   ) do begin
    if debug(5,self.verbose,msg='headerstr: ') then begin
      ;dprint,nb,dlevel=4
      hexprint,buf
    endif
    msg_buf = [remainder,buf]
    headerstr = self.header_struct(msg_buf)
    if debug(4,self.verbose) then begin
      dprint,dlevel=4,verbose=self.verbose,'CMB: ',time_string(headerstr.time,prec=3),' ',headerstr.seqn,headerstr.size,'  ',headerstr.description
    endif
    if headerstr.sync ne sync || headerstr.psize gt 30000 then begin
      remainder = msg_buf[1:*]
      nb = 1             ; advance one byte at a time looking for the sync
      ;if debug(2) then begin
      dprint,verbose=self.verbose,dlevel=1,'Lost sync:',dwait=dwait
      sync_errors++
      continue
    endif
    last_headerstr = self.source_dict.headerstr
    self.source_dict.headerstr = headerstr
    ;dprint,dlevel=3,verbose=self.verbose,headerstr.psize,headerstr.seqn,'  ',headerstr.description

    ;  read the payload bytes
    payload_buf = self.read_nbytes(headerstr.psize,pos=nbytes)
    npkts++

    ; decomutate data here!
    self.handle, payload_buf    ;, source_dict=self.source_dict

    mem_current = memory(/current) / 2.^20

    cmbdata = { $
      time:headerstr.time   ,$
      seqn:headerstr.seqn   ,$
      time_delta: headerstr.time-last_headerstr.time, $
      seqn_delta: headerstr.seqn-last_headerstr.seqn, $
      psize: headerstr.psize, $
      user: headerstr.user, $
      type: headerstr.type, $
      source: headerstr.source,  $
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




pro cmblk_reader::handle,header_payload    ;, source_dict=source_dict   ; , headerstr= headerstr

  payload = header_payload[self.header_size:*]    ; strip off the header for common block
  ; Decommutate data
  source_dict = self.source_dict
  headerstr = source_dict.headerstr
  descr_key = headerstr.description
  handlers = self.handlers
  if headerstr.source ne 0 then   source_str = '-'+strtrim(headerstr.source,2) else source_str=''
  descr_key = descr_key + source_str
  
  if handlers.haskey( descr_key ) eq 0  then begin        ; establish new ones if not already defined
    dprint,verbose=self.verbose,dlevel=1,'Found new description key: "', descr_key,'"'
    n = n_elements(payload)
    eol = payload[n-1]
    dprint,'Payload:',dlevel=2,verbose=self.verbose
    hexprint,payload
    descr_key_lower = strlowcase(descr_key)
    tagnames='*'
    if n gt 10 && (eol eq 10 || eol eq 13)  then begin      ; most likely ascii payload
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
    ;new_obj.source_dict.parent_dict = self.source_dict
    handlers[descr_key] = new_obj
    new_obj.apid = descr_key
  endif
  
  
  ;if ~self.desctypes.haskey(descr_key) then self.desctypes[descr_key] = n_elements(self.desctypes)

  if self.run_proc then begin
    dict = self.source_dict
    dict.headerstr = headerstr            ; this line is redundant!
    handler =  handlers[descr_key]                     ; Get the proper handler object
    if obj_valid(handler) then begin
      handler.source_dict.parent_dict = dict
      handler.read, payload     ;, source_dict=dict         ; execute handler
    endif else begin
      dprint,verbose=self.verbose,dlevel=1,'Invalid handle object for cmblk_key: "',descr_key,'"'
    endelse
  endif
  
  
  
  
end



pro cmblk_reader::print_status,no_header=no_header    ;,   apid=apid
  self.socket_reader::print_status,no_header=no_header
  foreach h , self.handlers,apid do   h.print_status,/no_header   ;,apid=apid
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
;    desctypes:        obj_new(), $
    handlers:     obj_new(),  $   ; This will contain an ordered hash of other handlers
    sync:  'CMB1'     $         ;
  }
END


