;+
;WIDGET Procedure:
;  socket_recorder
;PURPOSE:
; Widget tool that opens a socket and records streaming data from a server (host) and can save it to a file
; or send to a user specified routine. This tool runs in the background.
; Keywords:
;   SET_FILE_TIMERES : defines how often the current output file will be closed and a new one will be opened
;   DIRECTORY:  string prepended to fileformat when opening an output file.
; Author:
;    Davin Larson - April 2011
;    proprietary - D. Larson UC Berkeley/SSL
;
; $LastChangedBy: davin-mac $
; $LastChangedDate: 2016-09-28 22:56:26 -0700 (Wed, 28 Sep 2016) $
; $LastChangedRevision: 21979 $
; $URL: $
;
;-


function socket_recorder::get_value,uname
  id = widget_info(self.base,find_by_uname=uname)
  widget_control, id, get_value=value
  return,value
end


function socket_recorder::get_uvalue,uname
  id = widget_info(self.base,find_by_uname=uname)
  widget_control, id, get_uvalue=value
  return,value
end


function socket_recorder::read_lun
  buffer = !null
  if self.hfp gt 0 then begin
    on_ioerror, stream_error
    eofile =0
    self.time_received = systime(1)
    ;    widget_control,wids.base,set_uvalue=self
    buffer= bytarr(self.maxsize)
    b=buffer[0]
    for i=0L,n_elements(buffer)-1 do begin                       ; Read from stream one byte (or value) at a time
      flag = file_poll_input(self.hfp,timeout=0)
      if flag eq 0 then break
      readu,self.hfp,b
      buffer[i] = b
    endfor
    if eofile eq 1 then begin
      stream_error:
      dprint,dlevel=self.dlevel-1,self.title_num+'File error: '+self.hostname+':'+self.hostport+' broken. ',i
      dprint,dlevel=self.dlevel,!error_state.msg
    endif
    if i gt 0 then begin                      ;; process data
      buffer = buffer[0:i-1]
      msg = string(/print,i,buffer[0:(i < 32)-1],format='(i6 ," bytes: ", 128(" ",Z02))')
      self.msg = time_string(self.time_received,tformat='hh:mm:ss - ',local=localtime) + msg
      return,buffer
    endif else begin
      self.msg =time_string(self.time_received,tformat='hh:mm:ss - No data available',local=localtime)
      return,!null
    endelse

  endif
  return,buffer
end


pro socket_recorder::write,buffer
  if keyword_set(self.dfp) then writeu,self.dfp, buffer  ;swap_endian(buffer,/swap_if_little_endian)
  flush,self.dfp
end


pro socket_recorder::process_data,buffer
  exec_proc = self.exec_proc
  exec_proc = self.proc_name()
  if keyword_set(exec_proc) then call_procedure,exec_proc,buffer,info=self.struct()     $   ; Execute exec_proc here
  else print,self.msg
end


PRO socket_recorder::SetProperty, _extra=ex
  ; If user passed in a property, then set it.
  if keyword_set(ex) then begin
    struct_assign,ex,self,/nozero
  endif
END

pro socket_recorder::help
  msg = string('Base ID is: ',self.base)
  output_text_id = widget_info(self.base,find_by_uname='OUTPUT_TEXT')
  widget_control, output_text_id, set_value=msg
  printdat,self.struct()
  ;  help,self,/obj,output=output
  ;  for i=0,n_elements(output)-1 do print,output[i]
end


function socket_recorder::struct
  strct = {socket_recorder}
  struct_assign , self, strct
;  strct.fileformat = self.get_value('DEST_TEXT')
  return,strct
END

function socket_recorder::proc_name
  proc_name_id = widget_info(self.base,find_by_uname='PROC_NAME')
  if keyword_set(proc_name_id) then widget_control,proc_name_id,get_value=proc_name   else proc_name = self.exec_proc
  return, proc_name[0]
end


pro socket_recorder::timed_event
  COMPILE_OPT IDL2

  if self.hfp gt 0 then begin
    wids = *self.wids

    ;;   Switch file name if needed
    if self.file_timeres gt 0 then begin
      if self.time_received ge self.next_filechange then begin
        dprint,dlevel=dlevel,time_string(self.time_received,prec=3)+ ' Time to change files.'
        if self.dfp then begin
          dprint,'closing'
          self.dest_button_event   ; close old file
          self.dest_button_event   ; open  new file
        endif
      endif
      self.next_filechange = self.file_timeres * ceil(self.time_received / self.file_timeres)
    endif

    ; Read data from stream until EOF is encountered or no more data is available
    buffer = self.read_lun()
    while( isa(buffer) ) do begin
      if self.dfp then self.write,buffer
      if self.run_proc then self.process_data, buffer
      msg = self.msg
      buffer = self.read_lun()
    endwhile

    dprint,verbose=self.verbose,dlevel=self.dlevel+1,self.title_num+self.msg,/no_check
    ;help,self.user_dict
    handler = self.user_dict
    ;help,handler
    ;handler.handler,buffer
    ;handler.decommutate,buffer
   ; decommutate
   ; decommutator = handler.decommutator
   ; decommutator(buffer)
    
    
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

end




pro socket_recorder::host_button_event

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
      *self.buffer_ptr = !null                                  ; Get rid of previous buffer contents cache
      WIDGET_CONTROL, host_button_id, set_value = 'Connecting',sensitive=0
      WIDGET_CONTROL, host_text_id, sensitive=0
      WIDGET_CONTROL, host_port_id, sensitive=0
      socket,hfp,/get_lun,server_name,fix(server_port),error=error ,/swap_if_little_endian,connect_timeout=10
      if keyword_set(error) then begin
        dprint,dlevel=self.dlevel-1,self.title_num+!error_state.msg,error   ;strmessage(error)
        widget_control, output_text_id, set_value=!error_state.msg
        WIDGET_CONTROL, host_button_id, set_value = 'Failed:',sensitive=1
        WIDGET_CONTROL, host_text_id, sensitive=1
        WIDGET_CONTROL, host_port_id, sensitive=1
      endif else begin
        dprint,dlevel=self.dlevel,self.title_num+'Connected to server: "'+server_n_port+'"  Unit: '+strtrim(hfp,2)
        self.hfp = hfp
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
      free_lun,self.hfp
      self.hfp =0
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




pro socket_recorder::dest_button_event

  dest_button_id = widget_info(self.base,find_by_uname='DEST_BUTTON')
  dest_text_id = widget_info(self.base,find_by_uname='DEST_TEXT')
  host_text_id = widget_info(self.base,find_by_uname='HOST_TEXT')
  host_port_id = widget_info(self.base,find_by_uname='HOST_PORT')
  dest_flush_id = widget_info(self.base,find_by_uname='DEST_FLUSH')

  widget_control,dest_button_id,get_value=status

  widget_control,dest_text_id, get_value=filename
  case status of
    'Write to': begin
      if keyword_set(self.dfp) then begin
        free_lun,self.dfp
        self.dfp = 0
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
        file_open,'u',self.directory+self.filename, unit=dfp,dlevel=4,compress=-1,file_mode='666'o,dir_mode='777'o
        dprint,dlevel=dlevel,self.title_num+' Opened output file: '+self.directory+self.filename+'   Unit:'+strtrim(dfp)
        self.dfp = dfp
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
      if self.dfp gt 0 then begin
        free_lun,self.dfp
        self.dfp =0
      endif
      ;            wait,1
      widget_control, dest_text_id ,set_value= self.fileformat,sensitive=1
      WIDGET_CONTROL, dest_button_id, set_value = 'Write to',sensitive=1
      dprint,dlevel=self.dlevel,self.title_num+'Closed output file: '+self.filename,no_check_events=1
    end
    else: begin
      dprint,self.title_num+'Invalid State'
    end
  endcase
end


pro socket_recorder::proc_button_event, on
  proc_name_id = widget_info(self.base,find_by_uname='PROC_NAME')
  proc_button_id = widget_info(self.base,find_by_uname='PROC_BUTTON')

  ;  if n_elements(on) eq 0 then on =1
  if keyword_set(proc_name_id) then widget_control,proc_name_id,get_value=proc_name  $
  else proc_name=''
  if keyword_set(prc_name_id) then  widget_control,proc_name_id,sensitive = (on eq 0)
  self.run_proc = on
  dprint,dlevel=self.dlevel,self.title_num+'"'+proc_name+ '" is '+ (self.run_proc ? 'ON' : 'OFF')
end


pro socket_recorder::destroy
  if self.hfp gt 0 then begin
    fs = fstat(self.hfp)
    dprint,dlevel=self.dlevel-1,self.title_num+'Closing '+fs.name
    free_lun,self.hfp
  endif
  if self.dfp gt 0 then begin
    fs = fstat(self.dfp)
    dprint,dlevel=self.dlevel-1,self.title_num+'Closing '+fs.name
    free_lun,self.dfp
  endif
  WIDGET_CONTROL, self.base, /DESTROY
  ptr_free,ptr_extract(self.struct())
  dprint,dlevel=self.dlevel-1,self.title_num+'Widget Closed'
  return
end



PRO socket_recorder_proc,buffer,info=info

  n = n_elements(buffer)
  if n ne 0 then  begin
    if debug(3) then begin
      dprint,time_string(info.time_received,prec=3) +''+ strtrim(n_elements(buffer))
      n = n_elements(buffer) < 512
      hexprint,buffer[0:n-1]    ;,swap_endian(uint(buffer,0,n_elements(buffer)/2))
    endif
  endif else print,format='(".",$)'
  dprint,dlevel=2,phelp=2,info
  return
end





PRO socket_recorder_event, ev   ; socket_recorder
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


;PRO socket_recorder_template,buffer,info=info
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
;function spp_ptp_header_struct,ptphdr
;  ptp_size = swap_endian(uint(ptphdr,0) ,/swap_if_little_endian )
;  ptp_code = ptphdr[2]
;  ptp_scid = swap_endian(/swap_if_little_endian, uint(ptphdr,3))
;  days  = swap_endian(/swap_if_little_endian, uint(ptphdr,5))
;  ms    = swap_endian(/swap_if_little_endian, ulong(ptphdr,7))
;  us    = swap_endian(/swap_if_little_endian, uint(ptphdr,11))
;  utime = (days-4383L) * 86400L + ms/1000d
;  if utime lt   1425168000 then utime += us/1d4   ;  correct for error in pre 2015-3-1 files
;  ;      if keyword_set(time) then dt = utime-time  else dt = 0
;  source   =    ptphdr[13]
;  spare    =    ptphdr[14]
;  path  = swap_endian(/swap_if_little_endian, uint(ptphdr,15))
;  ptp_header ={ptp_size:ptp_size, ptp_code:ptp_code, ptp_scid: ptp_scid, ptp_time:utime, ptp_source:source, ptp_spare:spare, ptp_path:path }
;  return,ptp_header
;end


;
;
;pro socket_recorder::read_lun,lun
;on_ioerror, nextfile
;isasocket = self.isasocket
;;lun = self.dfp
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



function socket_recorder::init,base,title=title,ids=ids,host=host,port=port,fileformat=fileformat,exec_proc=exec_proc, $
  set_connect=set_connect, set_output=set_output, pollinterval=pollinterval, set_file_timeres=set_file_timeres ,$
  get_procbutton = get_procbutton,set_procbutton=set_procbutton,directory=directory, $
  get_filename=get_filename,info=info

  if ~(keyword_set(base) && widget_info(base,/managed) ) then begin
    if not keyword_set(host) then host = 'localhost'
    if not keyword_set(port) then port = '2022'
    if not keyword_set(title) then title = 'Socket Recorder'
    port=strtrim(port,2)
    if not keyword_set(fileformat) then fileformat = 'socket_{HOST}.{PORT}_YYYYMMDD_hhmmss.dat'
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
    ids = create_struct(ids,'proc_name',   widget_text(ids.proc_base,xsize=35, uname='PROC_NAME', value = keyword_set(exec_proc) ? exec_proc :'socket_recorder_proc',/editable, /no_newline))
    ids = create_struct(ids,'done',        WIDGET_BUTTON(ids.proc_base, VALUE='Exit', UNAME='DONE'))
    title_num = title+' ('+strtrim(ids.base,2)+'): '

    self.wids = ptr_new(ids)
    self.hostname = HOST
    self.hostport = port
    self.title = title
    self.title_num = title_num
    self.fileformat = fileformat
    self.buffer_ptr = ptr_new(/allocate_heap)
    self.buffersize = 2L^20
    self.dlevel = 2
    self.isasocket=1
    self.maxsize = 2UL^23

    ;    info.buffer_ptr = ptr_new( bytarr( info.buffersize ) )
    WIDGET_CONTROL, self.base, SET_UVALUE=self
    WIDGET_CONTROL, self.base, /REALIZE
    widget_control, self.base, base_set_title=self.title_num
    XMANAGER, 'socket_recorder', self.base,/no_block
    dprint,dlevel=dlevel,self.title_num+'Widget started'
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
  if n_elements(set_output)  eq 1 && (keyword_set(info.dfp) ne keyword_set(set_output )) then socket_recorder_event, { id:ids.dest_button, top:ids.base }
  if n_elements(set_connect) eq 1 && (keyword_set(info.hfp) ne keyword_set(set_connect)) then socket_recorder_event, { id:ids.host_button, top:ids.base }
  if n_elements(set_procbutton) eq 1 then begin
    widget_control,ids.proc_button,set_button=set_procbutton
    socket_recorder_event, { top:ids.base, id:ids.proc_button, select: keyword_set(set_procbutton) }
  endif
  if n_elements(set_file_timeres) then begin
    self.file_timeres = set_file_timeres
  endif
  if n_elements(directory) then begin
    self.directory = directory
  endif
  get_procbutton = widget_info(ids.proc_button,/button_set)
  ;widget_control,ids.dest_text,get_value=get_filename
  get_filename = keyword_set(self.dfp) ? self.filename : ''
  widget_control, base, set_uvalue= self
  return,1

END





pro socket_recorder__define
  dummy = {socket_recorder, $
    inherits generic_object, $
    ;inherits idl_object, $
    ;verbose:0, $
    ;dlevel: 0, $
    base:0L ,$
    wids:ptr_new(), $
    hostname:'',$
    hostport:'', $
    input_sourcename: '',$
    input_sourcehash: 0UL, $
    title: '', $
    title_num: '', $
    time_received: 0d,  $
    file_timeres: 0d,   $
    next_filechange: 0d, $
    isasocket:0,  $
    hfp:0,  $
    directory:'' ,  $
    fileformat:'',  $
    filename:'', $
    dfp:0 , $
    maxsize:0UL, $
    msg: '', $
    buffersize:0L, $
    buffer_ptr: ptr_new(),   $
    pollinterval:0., $
    exec_proc: '', $
    exec_proc_ptr: ptr_new(), $
    last_time: 0d, $
    total_bytes: 0UL, $
    process_rate: 0d, $
    user_dict: obj_new(),  $
    run_proc:0 }

end

