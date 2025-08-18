;+
;Procedure:
;  socket_reader
;PURPOSE:
; This tool is a generic multi purpose object that can read data from:
;    1)  regular files
;    2)  data streams (a socket)
;    3)  array of bytes
;  It will optionally record data to a file
;    
;  It is typically used by a higher level object which inherits the methods and possibly overload some of the methods.
;  In particular the following object all call this object:
;    cmblk_reader()   ; reads common block data (files or sockets) that typically contain all of the following data types
;    ccsds_reader()   ; reads ccsds packet data (files or sockets)
;    ccsds_frame_reader()  ; reads ccsds frame data  (still in development)
;    json_reader()         ; reads json files
;    gsemsg_reader()       ; reads SSL "silver box" (swemulator or swifulator output)
;    ascii_reader()        ; ascii text files with each line of text ending with a newline character.
;    
;    It is very common for a hierarchy of nested streams to exist in a single file or stream. 
;    
;  
;    
;  
; Widget tool that opens a socket and reads streaming data from a server (host) and can save it to a file
; or send to a user specified routine. This tool runs in the background.
; Keywords:
;   file_timeres : defines how often the current output file will be closed and a new one will be opened
;   DIRECTORY:  string prepended to fileformat when opening an output file.
; Author:
;    Davin Larson - January 2023
;    proprietary - D. Larson UC Berkeley/SSL
;
; $LastChangedBy: rjolitz $
; $LastChangedDate: 2025-03-04 10:57:07 -0800 (Tue, 04 Mar 2025) $
; $LastChangedRevision: 33161 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/misc/file_stuff/socket_reader__define.pro $
;
;-

COMPILE_OPT IDL2


pro socket_reader::handleTimerEvent,id,data
    self.timer_id = id
    dprint,verbose=self.verbose,dlevel=2,id
    printdat,self.msg,data
end


pro socket_reader::check_connection,nbytes
  if self.isasocket then begin
    if self.input_lun then begin
      period = self.pollinterval+30 > self.reconnect_period
      if nbytes eq 0 then begin
        if self.reconnect && current_time gt self.reconnect_time then begin
          ;  try to reconnect
          dprint,dlevel=1,verbose=self.verbose,'Attempting reconnection to HOST: '+self.host+':'+self.port
          self.host_button_event  ; close
          ;wait,2.   ; 
          self.host_button_event  ; reopen
        endif

      endif
      self.reconnect_time = systime(1) + period
    endif
  endif

end








function socket_reader::read_nbytes,nbytes,source,pos=pos,eofile=eofile

  on_ioerror, fixit

  buf = !null
  if ~isa(pos) then pos=0ul
  if isa(source,/array) then begin          ; source should be an array of bytes
    buf = !null
    n = nbytes < (n_elements(source) - pos)
    if n gt 0 then   buf = source[pos:pos+n-1]
    pos = pos+n
    if pos ge n_elements(source) then eofile = 1    ;  Signal that all bytes have been read
  endif else begin
    if keyword_set(self.input_lun) then begin                ; self.input_lun should be a file LUN
      if self.isasocket then begin
        pos = 0L
        if ~keyword_set(nbytes) then begin
          nbytes =  self.buffersize        ; get up to this many bytes
          nb = 1                  ; get bytes one at a time
        endif else begin
          nb = nbytes              ; if size is known, get them all at once
        endelse
        b = bytarr(nb)
        buf = bytarr(nbytes)
        while( file_poll_input(self.input_lun,timeout=0) && pos lt nbytes ) do begin
          readu,self.input_lun,b,transfer_count=n
          buf[pos:pos+n-1]  = b
          pos = pos+n
        endwhile
        if pos eq 0 then buf = !null else buf = buf[0:pos-1]
        eofile=1
      endif else begin   ; read from real file
        pos = 0L
        if nbytes eq 0  then begin    ; no payload
          buf = !null
          n = 0                  ; 
        endif else begin
          nb = nbytes              ; if size is known, get them all at once
          buf = bytarr(nbytes)
          readu,self.input_lun,buf,transfer_count=n
        endelse
        if n ne nbytes then begin
          buf = (n eq 0) ? !null : buf[0:n-1]
        endif
        eofile = eof(self.input_lun)
      endelse
    endif
  endelse
  self.write,buf
  return,buf
  
  fixit:
  fs = fstat(self.input_lun)
  n = fs.transfer_count           ; for some reason n is not set correctly on eof error
  if n eq 0 then buf = !null else  buf = buf[0:n-1]
  pos = pos + n
  self.write,buf
  dprint,verbose=self.verbose,dlevel=3,'IO warning: '+ !error_state.msg  +strtrim(n_elements(buf)) 
  eofile = eof(self.input_lun)
  return,buf
end


function socket_reader::read_line,source,pos=pos ,eofile=eofile ;,nbytes=nb    ; reads a line of ascii file (or buffer)
  on_ioerror, fixit
  ;buf = !null

  if ~isa(pos) then pos=0ul
  eofile = 0
  
  if isa(source,/array) then begin          ; source should be a an array of bytes
    ;dprint,dlevel=3,verbose=self.verbose,'Not tested yet...'
    ns = n_elements(source)
    n =0UL
    eol = self.eol
    startpos = pos
    while pos lt ns  do begin
      b = source[pos]
      n++
      pos++
      if b eq eol then break
    endwhile
    if n eq 0 then buf =  !null  else buf =  source[startpos:pos-1]
    if pos ge ns then eofile=1
  endif else begin
    buf = !null    
    if keyword_set(self.input_lun) then begin
      b = bytarr(1)
      ; read from file or socket one character at a time looking for EOL
      while file_poll_input(self.input_lun,timeout=0) && ~eofile  do begin  
        readu,self.input_lun,b,transfer_count=n
        if n ne 0 then begin
          buf = [buf,b]
          if b[0] eq self.eol then break
        endif else begin
          dprint,verbose=self.verbose,dlevel=1,'End of file'
        endelse
        pos = pos+n
        if ~self.isasocket then eofile = eof(self.input_lun)
      endwhile
    endif else dprint,dlevel=2,verbose=self.verbose,self.name +": Input file is not open."
  end

  self.write,buf
  return,buf
  fixit:
  dprint,'IO error'
  ;stop
  self.write,buf
  return,buf
end


; this routine writes a common block (cmblk) header before each segment of data  (should be 32 bytes long!;;;;;
pro socket_reader::write_header, buffer
  cmblk = self.cmblk
  cmblk.time = systime(1)
  cmblk.psize = ulong(n_elements(buffer))  
  self.cmblk.seqn++
  
  writeu,self.output_lun, cmblk

end


pro socket_reader::write ,buffer

  nb = n_elements(buffer)
  self.sum1_bytes += nb
  self.sum2_bytes += nb

  if self.output_lun ne 0 then begin
    if self.file_timeres gt 0 then begin
      if self.time_received ge self.next_filechange then begin
        ; dprint,verbose=self.verbose,dlevel=2,time_string(self.time_received,prec=3)+ ' Time to change files.'
        if self.output_lun ne 0 then begin
          self.open_output,time = self.time_received
        endif
      endif
      self.next_filechange = self.file_timeres * ceil(self.time_received / self.file_timeres)
    endif
    if keyword_set(buffer) && self.output_lun gt 0 then begin
      if self.add_cmblk_header then begin
        self.write_header,buffer
      endif
      writeu,self.output_lun, buffer
    endif    else flush,self.output_lun
  endif
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
pro socket_reader::read,source

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
      dict.packet_is_complete = (dict.headerstr.psize eq 0)
    endif

    if ~dict.packet_is_complete then begin    ; need to read rest of the packet
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


    self.handle,dict.fifo    ; process each packet



    if dict.haskey('flag') && keyword_set(dict.flag) && debug(2,self.verbose,msg='status') then begin
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

  if nbytes ne 0 then msg += string(/print,nbytes,format='(i8 ," bytes: ")')  $
  else msg+= ' No data available'

  dprint,verbose=self.verbose,dlevel=4,msg
  dict.msg = msg

end





pro socket_reader::handle, buffer    ; This routine is typically overloaded by another object

  dprint,dlevel=4,verbose=self.verbose,n_elements(buffer),' Bytes for Handler: "',self.name,'"'
  self.nbytes += n_elements(buffer)
  self.npkts  += 1
  
  if self.save_data && isa(self.dyndata,'dynamicarray') then begin
    self.dyndata.append,self.source_dict.headerstr
  endif


  if self.run_proc then begin
    if self.procedure_name then begin
      call_procedure,self.procedure_name,buffer ,source_dict=self.source_dict
    endif else begin
      if debug(3,self.verbose,msg=self.name+' '+self.msg) then begin
        if debug(3,self.verbose) then      hexprint,buffer
      endif
    endelse
  endif

end






pro socket_reader::read_old1, buffer, source_dict=source_dict
  ; Read data from stream until EOF is encountered or no more data is available on the stream
  ; if the proc flag is set then it will process the data
  ; if the output lun is non zero then it will save the data.

  self.time_received = systime(1)

  nb = 2L^12   ; max number to read - might return fewer
  ; should repeat until done.
  eofile = 0
  total_bytes = 0L
  while ~eofile do begin
    ;nb=0
    if self.eol ge 0 then begin
      buf = self.read_line(buffer,pos=pos,eofile=eofile)
    endif else begin
      buf = self.read_nbytes(nb,buffer,pos=pos,eofile=eofile)
    endelse

    nbytes = n_elements(buf)
    total_bytes += nbytes

    if nbytes gt 0 then begin                      ;; process data
      msg = string(/print,nbytes,buf[0:(nbytes < 32)-1],format='(i6 ," bytes: ", 128(" ",Z02))')
      self.msg = time_string(self.time_received,tformat='hh:mm:ss - ',local=localtime) + msg
    endif else begin
      ;*self.buffer_ptr = !null
      self.msg =time_string(self.time_received,tformat='hh:mm:ss - No data available',local=localtime)
      break
    endelse

    self.handle,buf  ;,source_dict=source_dict

    dprint,verbose=self.verbose,dlevel=4,self.msg,/no_check
    ;eofile = eof(self.input_lun)

  endwhile
  msg = string(/print,total_bytes,format='(i6 ," bytes ")')

  self.msg = time_string(self.time_received,tformat='hh:mm:ss - ',local=localtime) + msg
  dprint,verbose=self.verbose,dlevel=3,self.msg

end






pro socket_reader::open_output,fileformat,time=time,close=close

  dprint,verbose=self.verbose,dlevel=3,"Opening output for: "+self.name

  if self.output_lun gt 0 then begin   ; Close old file
    dprint,verbose=self.verbose,dlevel=2,'Closing file: '+file_info_string(self.filename)
    free_lun,self.output_lun
    self.output_lun = 0
  endif
  if isa(fileformat,/string) then  self.fileformat = fileformat
  if keyword_set(close) then return
  if keyword_set(self.fileformat) then begin
    if ~keyword_set(time) then time=systime(1)
    self.filename = time_string(time,tformat=self.fileformat)
    fullfilename = self.directory + self.filename
    file_open,'u',fullfilename, unit=output_lun,dlevel=4,compress=-1  ;,file_mode='666'o,dir_mode='777'o
    dprint,verbose=self.verbose,dlevel=2,'Opening file: "'+fullfilename+'" Unit:'+strtrim(output_lun,2)+' '+self.title_num
    self.output_lun = output_lun
    self.filename= fullfilename
  endif else dprint,'Fileformat is not specified for "',self.title_num,'"'
end



pro socket_reader::file_read,filenames,trange=trange
  if keyword_set(trange) and keyword_set(self.fileformat) then begin
    pathformat = self.fileformat
    ;filenames = file_retrieve(pathformat,trange=trange,/hourly_,remote_data_dir=opts.remote_data_dir,local_data_dir= opts.local_data_dir)
    if n_elements(trange eq 1)  then trange = systime(1) + [-trange[0],0.1]*3600.
    timespan,trange
    if 0 then begin
      filenames = time_string(self.fileformat)
    endif else begin
      ;remote_url = ''   ; don't download files if writing locally
      dprint,dlevel=2,'Download raw telemetry files...'
      filenames = file_retrieve(pathformat,trange=trange,remote=remote_url,local=self.directory,resolution=self.file_timeres)
    endelse 
    dprint,dlevel=2, "Files to be loaded:"
    dprint,dlevel=2,file_info_string(filenames)
  endif



  on_ioerror, keepgoing
  for i= 0,n_elements(filenames)-1 do begin
    file = filenames[i]
    file_open,'r',file,unit=lun,compress=-1,verbose=2
    if keyword_set(lun) then begin
      self.input_lun = lun
      self.read
      free_lun,lun
      keepgoing:
      self.input_lun = 0
    endif
  endfor

end




;pro socket_reader::process_data,buffer
;  if self.run_proc then begin
;    dprint,self.msg
;    hexprint,buffer
;  endif
;end


PRO socket_reader::SetProperty, _extra=ex
  ; If user passed in a property, then set it.
  if keyword_set(ex) then begin
    struct_assign,ex,self,/nozero
  endif
END


pro socket_reader::GetProperty,name=name,verbose=verbose,dyndata=dyndata,time_received=time_received,source_dict=source_dict
  if arg_present(name) then name=self.name
  if arg_present(dyndata) then dyndata=self.dyndata
  if arg_present(verbose) then verbose=self.verbose
  if arg_present(time_received) then time_received=self.time_received
  if arg_present(source_dict) then source_dict=self.source_dict
  if arg_present(parent_dict) then parent_dict=self.parent_dict
end

pro socket_reader::help , item
  if keyword_set(self.base) and widget_info(self.base,/valid_id) then begin
    msg = string('Base ID is: ',self.base)
    output_text_id = widget_info(self.base,find_by_uname='OUTPUT_TEXT')
    widget_control, output_text_id, set_value=msg
  endif
  help,self
  help,self.getattr(item)
  ;  help,self,/obj,output=output
  ;  for i=0,n_elements(output)-1 do print,output[i]
end




pro socket_reader::print_status,no_header=no_header  ;,apid = apid
   format1 = '(a12,a18,a18,i3,i10,i12,i10,i10,i10,i10,i10,i10)'
   format2 = str_sub(format1,',i',',a')
   ;if ~isa(apid,'string') then apid =''
   apid = self.apid
   ;printdat,apid
   if ~keyword_set(no_header) then $
     print,'APID','Name','Object','S','sum1','sum2','npkts','nreads','Size',format=format2
   print,apid,self.name,typename(self),self.isasocket,self.sum1_bytes,self.sum2_bytes,self.npkts,self.nreads,self.dyndata.size,format=format1
   if ~keyword_set(no_header) then $
     print,'-----','-----','-----','--','----','----','----','----','-------',format=format2
end




;function socket_reader::struct
;  ;  strct = {socket_reader}
;  strct = create_struct(name=typename(self))
;  struct_assign , self, strct
;  return,strct
;END

;function socket_reader::proc_name
;  proc_name_id = widget_info(self.base,find_by_uname='PROC_NAME')
;  if keyword_set(proc_name_id) then widget_control,proc_name_id,get_value=proc_name   else proc_name = self.exec_proc
;  return, proc_name[0]
;end



function socket_reader::get_value,uname
  id = widget_info(self.base,find_by_uname=uname)
  widget_control, id, get_value=value
  return,value
end


function socket_reader::get_uvalue,uname
  id = widget_info(self.base,find_by_uname=uname)
  widget_control, id, get_uvalue=value
  return,value
end




pro socket_reader::timed_event

  if self.input_lun gt 0 then begin
    
    self.sum1_bytes = 0
    self.read

    msg = time_string(systime(1),tformat='hh:mm:ss - ',local=localtime) +' '+ strtrim(self.sum1_bytes,2)+' Bytes'

    wids = *self.wids
    if isa(wids) then begin
      widget_control,wids.output_text,set_value=msg
      widget_control,wids.poll_int,get_value = poll_int
      poll_int = float(poll_int)
      if poll_int le 0 then poll_int = 1
      if 1 then begin
        poll_int = poll_int - (systime(1) mod poll_int)  ; sample on regular boundaries
      endif

      if not keyword_set(eofile) then WIDGET_CONTROL, wids.base, TIMER=poll_int else begin
        widget_control,wids.host_button,timer=2
      endelse

    endif
  endif
  self.time_received = systime(1)
end





pro socket_reader::open_socket,host,port       ; not finished yet - use widget button
  if isa(host,/string) then begin
    
  endif



end




pro socket_reader::host_button_event

  host_button_id = widget_info(self.base,find_by_uname='HOST_BUTTON')
  host_text_id   = widget_info(self.base,find_by_uname='HOST_TEXT')
  output_text_id   = widget_info(self.base,find_by_uname='OUTPUT_TEXT')
  host_port_id   = widget_info(self.base,find_by_uname='HOST_PORT')
  widget_control,host_button_id,get_value=status
  widget_control,host_text_id, get_value=server_name
  widget_control,host_port_id, get_value=server_port
  server_n_port = server_name+':'+server_port
  self.hostname = server_name
  self.hostport = server_port
  case status of
    'Connect to': begin
     ; *self.buffer_ptr = !null                                  ; Get rid of previous buffer contents cache
      WIDGET_CONTROL, host_button_id, set_value = 'Connecting',sensitive=0
      WIDGET_CONTROL, host_text_id, sensitive=0
      WIDGET_CONTROL, host_port_id, sensitive=0
      socket,input_lun,/get_lun,server_name,fix(server_port),error=error ,/swap_if_little_endian,connect_timeout=10
      if keyword_set(error) then begin
        dprint,verbose=self.verbose,dlevel=1,self.title_num+!error_state.msg,error   ;strmessage(error)
        self.isasocket = 0
        widget_control, output_text_id, set_value=!error_state.msg
        WIDGET_CONTROL, host_button_id, set_value = 'Failed:',sensitive=1
        WIDGET_CONTROL, host_text_id, sensitive=1
        WIDGET_CONTROL, host_port_id, sensitive=1
      endif else begin
        dprint,verbose=self.verbose,dlevel=2,self.title_num+'Connected to server: "'+server_n_port+'"  Unit: '+strtrim(input_lun,2)
        self.input_lun = input_lun
        self.isasocket = 1
        WIDGET_CONTROL, self.base, TIMER=1    ;
        WIDGET_CONTROL, host_button_id, set_value = 'Disconnect',sensitive=1
      endelse
    end
    'Disconnect': begin
      WIDGET_CONTROL, host_button_id, set_value = 'Closing'  ,sensitive=0
      WIDGET_CONTROL, host_text_id, sensitive=1
      WIDGET_CONTROL, host_port_id, sensitive=1
      msg = 'Disconnected from server: "'+server_n_port+'"'
      widget_control, output_text_id, set_value=msg
      dprint,dlevel=self.dlevel,self.title_num+msg
      free_lun,self.input_lun
      self.input_lun =0
      self.isasocket = 0
      wait,1
      WIDGET_CONTROL, host_button_id, set_value = 'Connect to',sensitive=1
    end
    else: begin
      WIDGET_CONTROL, host_text_id, sensitive=1
      WIDGET_CONTROL, host_port_id, sensitive=1
      WIDGET_CONTROL, host_button_id, set_value = 'Connect to',sensitive=1
      dprint,self.title_num+'Error Recovery'
    end
  endcase

end





pro socket_reader::dest_button_event

  dest_button_id = widget_info(self.base,find_by_uname='DEST_BUTTON')
  dest_text_id = widget_info(self.base,find_by_uname='DEST_TEXT')
  host_text_id = widget_info(self.base,find_by_uname='HOST_TEXT')
  host_port_id = widget_info(self.base,find_by_uname='HOST_PORT')
  dest_flush_id = widget_info(self.base,find_by_uname='DEST_FLUSH')

  widget_control,dest_button_id,get_value=status

  widget_control,dest_text_id, get_value=filename
  case status of
    'Write to': begin
      if keyword_set(self.output_lun) then begin
        free_lun,self.output_lun
        self.output_lun = 0
      endif
      WIDGET_CONTROL, dest_button_id      , set_value = 'Opening' ,sensitive=0
      widget_control, dest_text_id, get_value = fileformat,sensitive=0
      self.fileformat = fileformat[0]
      filename = time_string(systime(1),tformat = self.fileformat)                     ; Substitute time string
      widget_control,host_text_id, get_value=hostname
      self.hostname = hostname[0]
      filename = str_sub(filename,'{HOST}',strtrim(self.hostname,2) )
      widget_control,host_port_id, get_value=hostport
      self.hostport = hostport
      self.filename = str_sub(filename,'{PORT}',strtrim(self.hostport,2) )               ; Substitute port number
      widget_control, dest_text_id, set_uvalue = fileformat,set_value=self.filename
      if keyword_set(self.filename) then begin
        file_open,'u',self.directory+self.filename, unit=output_lun,dlevel=4,compress=-1,file_mode='666'o,dir_mode='777'o
        dprint,dlevel=dlevel,self.title_num+' Opened output file: '+self.directory+self.filename+'   Unit:'+strtrim(output_lun)
        self.output_lun = output_lun
        self.filename= self.directory+self.filename
        widget_control, dest_flush_id, sensitive=1
      endif
      ;              wait,1
      WIDGET_CONTROL, dest_button_id, set_value = 'Close   ',sensitive =1
    end
    'Close   ': begin
      WIDGET_CONTROL, dest_button_id,          set_value = 'Closing',sensitive=0
      widget_control, dest_flush_id, sensitive=0
      widget_control, dest_text_id ,get_uvalue= fileformat,get_value=filename
      if self.output_lun gt 0 then begin
        free_lun,self.output_lun
        self.output_lun =0
      endif
      ;            wait,1
      widget_control, dest_text_id ,set_value= self.fileformat,sensitive=1
      WIDGET_CONTROL, dest_button_id, set_value = 'Write to',sensitive=1
      dprint,dlevel=self.dlevel,self.title_num+'Closed output file: '+file_info_string(self.filename),no_check_events=1
    end
    else: begin
      dprint,self.title_num+'Invalid State'
    end
  endcase
end


pro socket_reader::proc_button_event, on
  proc_name_id = widget_info(self.base,find_by_uname='PROC_NAME')
  proc_button_id = widget_info(self.base,find_by_uname='PROC_BUTTON')

  ;  if n_elements(on) eq 0 then on =1
  if keyword_set(proc_name_id) then widget_control,proc_name_id,get_value=proc_name  $
  else proc_name=''
  if keyword_set(prc_name_id) then  widget_control,proc_name_id,sensitive = (on eq 0)
  self.run_proc = on
  dprint,verbose=self.verbose,dlevel=1,self.title_num+'"'+proc_name+ '" is '+ (self.run_proc ? 'ON' : 'OFF')
end


pro socket_reader::destroy
  if self.input_lun gt 0 then begin
    fs = fstat(self.input_lun)
    dprint,dlevel=self.dlevel-1,self.title_num+'Closing '+fs.name
    free_lun,self.input_lun
  endif
  if self.output_lun gt 0 then begin
    fs = fstat(self.output_lun)
    dprint,dlevel=self.dlevel-1,self.title_num+'Closing '+fs.name
    free_lun,self.output_lun
  endif
  WIDGET_CONTROL, self.base, /DESTROY
  ; ptr_free,ptr_extract(self.struct())
  dprint,dlevel=self.dlevel-1,self.title_num+'Widget Closed'
  return
end



PRO socket_reader_proc,buffer,info=info

  n = n_elements(buffer)
  if n ne 0 then  begin
    if debug(2) then begin
      dprint,time_string(info.time_received,prec=3) +''+ strtrim(n_elements(buffer))
      n = n_elements(buffer) < 512
      hexprint,buffer[0:n-1]    ;,swap_endian(uint(buffer,0,n_elements(buffer)/2))
    endif
  endif else print,format='(".",$)'
  dprint,dlevel=2,phelp=2,info
  return
end


function socket_reader_object,base
  widget_control, base, get_uvalue= info   ; get all widget ID's
  return,info
end







PRO socket_reader_event, ev   ; socket_reader
  ;   on_error,1
  uname = widget_info(ev.id,/uname)
  dprint,uname,ev,/phelp,dlevel=5

  widget_control, ev.top, get_uvalue= self   ; get the object to make this "look" like a method

  ;printdat,ev,uname
  CASE uname OF                         ;  Timed events
    'BASE':                 self.timed_event
    'HOST_BUTTON' :         self.host_button_event
    'DEST_BUTTON' :         self.dest_button_event
    'DEST_FLUSH': begin
      self.dest_button_event   ; close old file
      self.dest_button_event   ; open  new file
    end
    'PROC_BUTTON':         self.proc_button_event, ev.select
    'DONE':                self.destroy
    else:                  self.help
  ENDCASE
END


;PRO socket_reader_template,buffer,info=info
;;    savetomain,buffer
;;    savetomain,time
;
;    n = n_elements(buffer)
;    if n ne 0 then  begin
;    if debug(2) then begin
;      dprint,time_string(self.time_received,prec=3) +''+ strtrim(n_elements(buffer))
;      n = n_elements(buffer) < 512
;      hexprint,buffer[0:n-1]    ;,swap_endian(uint(buffer,0,n_elements(buffer)/2))
;    endif
;    endif else print,format='(".",$)'
;
;    return
;end



;
;
;pro socket_reader::read_lun,lun
;on_ioerror, nextfile
;isasocket = self.isasocket
;;lun = self.output_lun
;
;buf = bytarr(17)
;remainder = !null
;while (isasocket ? file_poll_input(lun) : ~eof(lun) ) do begin
;  info.time_received = systime(1)
;  readu,lun,buf
;  hdrbuf = [remainder,buf]
;  sz = hdrbuf[0]*256 + hdrbuf[1]
;  if (sz lt 17) || (hdrbuf[2] ne 3) || (hdrbuf[3] ne 0) || (bhdrbuf[4] ne 'bb'x) then  begin     ;; Lost sync - read one byte at a time
;    remainder = hdrbuf[1:*]
;    buf = bytarr(1)
;    if debug(3) then begin
;      dprint,dlevel=3,'Lost sync:',dwait=10
;    endif
;    continue
;  endif
;  ptp_struct = spp_ptp_header_struct(hdrbuf)
;  ccsds_buf = bytarr(sz - n_elements(hdrbuf))
;  readu,lun,ccsds_buf,transfer_count=nb
;
;  if nb ne sz then begin
;    dprint,'File read error. Aborting @ ',fp,' bytes'
;    break
;  endif
;  spp_ccsds_pkt_handler,ccsds_buf,ptp_header=ptp_header
;  ;      if debug(2) then begin
;  ;        dprint,dwait=dwait,dlevel=2,'File percentage: ' ,(fp*100.)/fi.size
;  ;      endif
;  buf = bytarr(17)
;  remainder=!null
;endwhile
;
;if 0 then begin
;  nextfile:
;  dprint,!error_state.msg
;  dprint,'Skipping file'
;endif
;;    dprint,dlevel=2,'Compression: ',float(fp)/fi.size
;end
;
;



function socket_reader::init,name=name,title=title,ids=ids,host=host,port=port,fileformat=fileformat,exec_proc=exec_proc, $
  set_connect=set_connect, set_output=set_output, pollinterval=pollinterval, file_timeres=file_timeres ,$
  tplot_tagnames=tplot_tagnames, $
  ;apid = apid,  $
  eol = eol,  $
  save_data = save_data,  $
  run_proc=run_proc,directory=directory, $
  no_widget=no_widget,verbose=verbose

  if ~keyword_set(name) then name=strlowcase(typename(self))
  self.name  =name

  self.source_dict = dictionary()
  if isa(verbose) then self.verbose = verbose else self.verbose = 2

  if not keyword_set(host) then host = ''
  if not keyword_set(port) then port = '2000'
  if not keyword_set(title) then title = name
  if not keyword_set(file_timeres) then file_timeres=3600.d
  self.file_timeres =file_timeres
  port=strtrim(port,2)
  if not keyword_set(fileformat) then fileformat = name+'/YYYY/MM/DD/'+name+'_YYYYMMDD_hh.dat'
  self.hostname = HOST
  self.hostport = port
  self.title = title
  self.eol   = -1
  self.fileformat = fileformat
  self.buffersize = 2L^20    ; megabyte should be enough
  ;self.buffer_ptr = ptr_new(/allocate_heap)
  self.dlevel = 2
  ;self.isasocket=1
  self.run_proc = isa(run_proc) ? run_proc : 1    ; default to not running proc
  self.dyndata = dynamicarray(name=name,tplot_tagnames=tplot_tagnames)
  if isa(save_data) then self.save_data = save_data
  self.cmblk = {cmblk_header}
  self.cmblk.sync =  0x434D4231
  self.cmblk.time = systime(1)
  self.cmblk.descid = byte(strmid(name,0,10))


  if ~keyword_set(no_widget) then begin
    if ~(keyword_set(base) && widget_info(base,/managed) ) then begin
      self.base = WIDGET_BASE(/COLUMN, title=title , uname='BASE')
      ids = create_struct('base', self.base )
      ids = create_struct(ids,'host_base',   widget_base(ids.base,/row, uname='HOST_BASE') )
      ids = create_struct(ids,'host_button', widget_button(ids.host_base, uname='HOST_BUTTON',value='Connect to') )
      ids = create_struct(ids,'host_text',   widget_text(ids.host_base,  uname='HOST_TEXT' ,VALUE=host ,/EDITABLE ,/NO_NEWLINE ) )
      ids = create_struct(ids,'host_port',   widget_text(ids.host_base,  uname='HOST_PORT',xsize=6, value=port   , /editable, /no_newline))
      ids = create_struct(ids,'poll_int' ,   widget_text(ids.host_base,  uname='POLL_INT',xsize=6,value='1',/editable,/no_newline))
      ;    if n_elements(directory) ne 0 then $
      ;      ids = create_struct(ids,'destdir_text',   widget_text(ids.base,  uname='DEST_DIRECTORY',xsize=40 ,/EDITABLE ,/NO_NEWLINE  ,VALUE=directory))
      ids = create_struct(ids,'dest_base',   widget_base(ids.base,/row, uname='DEST_BASE'))
      ids = create_struct(ids,'dest_button', widget_button(ids.dest_base, uname='DEST_BUTTON',value='Write to'))
      ids = create_struct(ids,'dest_text',   widget_text(ids.dest_base,  uname='DEST_TEXT',xsize=40 ,/EDITABLE ,/NO_NEWLINE  ,VALUE=fileformat))
      ids = create_struct(ids,'dest_flush',  widget_button(ids.dest_base,uname='DEST_FLUSH', value='New' ,sensitive=0))
      ids = create_struct(ids,'output_text', WIDGET_TEXT(ids.base, uname='OUTPUT_TEXT'))
      ids = create_struct(ids,'proc_base',   widget_base(ids.base,/row, uname='PROC_BASE'))
      ids = create_struct(ids,'proc_base2',  widget_base(ids.proc_base ,/nonexclusive))
      ids = create_struct(ids,'proc_button', widget_button(ids.proc_base2,uname='PROC_BUTTON',value='Procedure:'))
      ids = create_struct(ids,'proc_name',   widget_text(ids.proc_base,xsize=35, uname='PROC_NAME', value = keyword_set(exec_proc) ? exec_proc :'socket_reader_proc',/editable, /no_newline))
      ids = create_struct(ids,'done',        WIDGET_BUTTON(ids.proc_base, VALUE='Done', UNAME='DONE'))

      self.title_num  = self.title+' ('+strtrim(ids.base,2)+'): '

      self.wids = ptr_new(ids)

      WIDGET_CONTROL, self.base, SET_UVALUE=self
      WIDGET_CONTROL, self.base, /REALIZE
      widget_control, self.base, base_set_title=self.title_num
      XMANAGER, 'socket_reader', self.base,/no_block
      dprint,dlevel=1,verbose=self.verbose,self.title_num+'Widget started'
      base = self.base
    endif else begin
      widget_control, base, get_uvalue= info   ; get all widget ID's
      ids = info.wids
    endelse
    ;if size(/type,exec_proc) eq 7 then    widget_control,ids.proc_name,set_value=exec_proc
    if size(/type,exec_proc) eq 7 then self.exec_proc = exec_proc
    if size(/type,destination) eq 7 then  widget_control,ids.dest_text,set_value=destination
    if size(/type,host) eq 7 then  widget_control,ids.host_text,set_value=host
    if n_elements(port) eq 1 then  widget_control,ids.host_port,set_value=strtrim(port,2)
    if n_elements(pollinterval) ne 0 then widget_control,ids.poll_int,set_value=strtrim(pollinterval,2)
    if n_elements(set_output)  eq 1 && (keyword_set(info.output_lun) ne keyword_set(set_output )) then socket_reader_event, { id:ids.dest_button, top:ids.base }
    if n_elements(set_connect) eq 1 && (keyword_set(info.input_lun) ne keyword_set(set_connect)) then socket_reader_event, { id:ids.host_button, top:ids.base }
    if n_elements(run_proc) eq 1 then begin
      self.run_proc = run_proc
      widget_control,ids.proc_button,set_button=run_proc
      socket_reader_event, { top:ids.base, id:ids.proc_button, select: keyword_set(run_proc) }
    endif
    if n_elements(file_timeres) then begin
      self.file_timeres = file_timeres
    endif
    if n_elements(directory) then begin
      self.directory = directory
    endif
    get_procbutton = widget_info(ids.proc_button,/button_set)
    ;widget_control,ids.dest_text,get_value=get_filename
    get_filename = keyword_set(self.output_lun) ? self.filename : ''
    widget_control, base, set_uvalue= self

  endif

  return,1

END





pro socket_reader__define

  cmblk ={cmblk_header, $
    sync: 0x434D4231 , $ ;  swap_endian(ulong(byte('CMB1'),0))  
    psize: 0ul, $
    time: !values.d_nan,  $
    seqn: 0us,  $   ; 2 byte sequence counter
    user: 0us,  $   ; 2 byte uint
    source: 0b,$   ; byte stored as uint
    type: 0b,  $   ; byte stored as uint
    descid: bytarr(10)  }
    

  dummy = {socket_reader, $
    inherits generic_object, $
    timer_id: 0u, $
    base:0L ,$
    wids:ptr_new(), $
    hostname:'',$
    hostport:'', $
    title: '', $
    title_num: '', $
    time_received: 0d,  $
    file_timeres: 0d,   $   ; Defines time interval of each output file
    next_filechange: 0d, $ ; don't use - will be deprecated in future
    isasocket:0,  $
    reconnect:  0 ,  $          ;  set flag to attempt reconnect if data has dropped 
    reconnect_time:  0d,  $        ; 
    reconnect_period: 0d, $       ;
    eol:-1 ,$                  ; character used to define End Of Line  typically 0x0A;   use negative integer to ignore
    input_lun:0,  $               ; host input file pointer (lun)
    output_lun:0 , $               ; destination output file pointer (lun)
    directory:'' ,  $          ; output/input directory
    fileformat:'',  $          ; output/input fileformat  - accepts time wild cards i.e.:  "file_YYYYMMDD_hh.dat"
    filename:'', $             ; output filename
    msg: '', $
    buffersize:0L, $
    header_size:0, $
    sync_pattern:  bytarr(4),  $
    sync_mask:  bytarr(4),  $
    sync_size:  0,  $
    ;buffer_ptr: ptr_new(),   $
    parent_reader: obj_new() , $
    parent_dict: obj_new(),   $
    source_dict: obj_new(),  $
    dyndata: obj_new(), $        ; dynamicarray object to save all the data in
    hdr_data: obj_new(), $       ; dynamicarray object to save header data
    apid: '',  $         ; APID name used in common block
    add_cmblk_header:0 ,  $
    cmblk : cmblk, $
    name: '',  $
    save_data: 0b ,  $            ; set this flag to save data
    nbytes: 0UL, $
    sum1_bytes: 0UL, $
    sum2_bytes: 0UL, $
    npkts:  0ul, $
    nreads: 0ul, $
    ;   brate: 0. , $ ; don't use - will be deprecated in future
    ;   prate: 0. , $ ; don't use - will be deprecated in future
    ;   output_filename:  '',   $
    pollinterval:0., $
    procedure_name: '', $
    run_proc:0 }

end

