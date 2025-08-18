;+
;WIDGET Procedure:
;  esc_recorder
;PURPOSE:
; Widget tool that opens a socket and records streaming data from a server (host) and can save it to a file
; or send to a user specified routine. This tool runs in the background.
; Keywords:
;   SET_FILE_TIMERES : defines how often the current output file will be closed and a new one will be opened
;   DIRECTORY:  string prepended to fileformat when opening an output file.
; Author:
;    Davin Larson - April 2011
;
; $LastChangedBy: davin-mac $
; $LastChangedDate: 2023-12-02 00:15:24 -0800 (Sat, 02 Dec 2023) $
; $LastChangedRevision: 32264 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/escapade/esa/common/esc_recorder.pro $
;
;-

PRO esc_recorder_event, ev   ; recorder
  ;   on_error,1

  widget_control, ev.top, get_uvalue= info   ; get all widget ID's
  wids = *info.wids
  localtime=1
  dlevel=info.dlevel

  CASE ev.id OF                         ;  Timed events
    wids.base:  begin
      ;   printdat,info
      on_ioerror, stream_error
      eofile =0
      info.time_received = systime(1)
      widget_control,wids.base,set_uvalue=info

      if info.hfp gt 0 then begin
        ;;   Switch file name if needed
        if info.file_timeres ne 0 then begin
          if info.time_received ge info.next_filechange then begin
            dprint,dlevel=dlevel,time_string(info.time_received,prec=3)+ ' Time to change files.'
            if info.dfp then begin
              esc_recorder_event,{top: ev.top, id:wids.dest_button}   ; close old file  - possible error that dfp might change!
              esc_recorder_event,{top: ev.top, id:wids.dest_button}   ; open  new file
            endif
          endif
          widget_control, ev.top, get_uvalue= info   ; get all widget ID's
          info.next_filechange = info.file_timeres * ceil(info.time_received / info.file_timeres)
          widget_control,wids.base,set_uvalue=info
        endif
        if 1 then begin
          esc_raw_lun_read,info.hfp,info.dfp,info=info
          widget_control,wids.base,set_uvalue=info
          msg = info.msg
          dprint,dlevel=4,systime(1)-info.time_received
        endif

        if eofile eq 1 then begin
          stream_error:
          widget_control,wids.host_text,get_value=hostname
          widget_control,wids.host_port,get_value=hostport
          dprint,dlevel=dlevel+1,info.title_num+!error_state.msg
        endif

        widget_control,wids.output_text,set_value=msg
        dprint,dlevel=dlevel+5,info.title_num+msg,/no_check
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
      return
    end
    wids.host_button : begin
      widget_control,wids.host_button,get_value=status
      widget_control,wids.host_text, get_value=server_name
      widget_control,wids.host_port, get_value=server_port
      server_n_port = server_name+':'+server_port
      case status of
        'Connect to': begin
          *info.buffer_ptr = !null                                  ; Get rid of previous buffer contents cache
          WIDGET_CONTROL, wids.host_button, set_value = 'Connecting',sensitive=0
          WIDGET_CONTROL, wids.host_text, sensitive=0
          WIDGET_CONTROL, wids.host_port, sensitive=0
          socket,hfp,/get_lun,server_name,fix(server_port),error=error ,/swap_if_little_endian,connect_timeout=10
          if keyword_set(error) then begin
            dprint,dlevel=dlevel-1,info.title_num+!error_state.msg+strtrim(error)   ;strmessage(error)
            widget_control, wids.output_text, set_value=!error_state.msg
            WIDGET_CONTROL, wids.host_button, set_value = 'Failed:',sensitive=1
            WIDGET_CONTROL, wids.host_text, sensitive=1
            WIDGET_CONTROL, wids.host_port, sensitive=1
          endif else begin
            dprint,dlevel=dlevel,info.title_num+'Connected to server: "'+server_n_port+'"  Unit:'+strtrim(hfp)
            info.hfp = hfp
            WIDGET_CONTROL, wids.base, TIMER=1    ; , set_uvalue=hfp
            WIDGET_CONTROL, wids.host_button, set_value = 'Disconnect',sensitive=1
          endelse
        end
        'Disconnect': begin
          WIDGET_CONTROL, wids.host_button, set_value = 'Closing'  ,sensitive=0
          WIDGET_CONTROL, wids.host_text, sensitive=1
          WIDGET_CONTROL, wids.host_port, sensitive=1
          msg = 'Disconnected from server: "'+server_n_port+'"'
          widget_control, wids.output_text, set_value=msg
          dprint,dlevel=dlevel,info.title_num+msg
          free_lun,info.hfp
          info.hfp =0
          wait,1
          WIDGET_CONTROL, wids.host_button, set_value = 'Connect to',sensitive=1
        end
        else: begin
          WIDGET_CONTROL, wids.host_text, sensitive=1
          WIDGET_CONTROL, wids.host_port, sensitive=1
          WIDGET_CONTROL, wids.host_button, set_value = 'Connect to',sensitive=1
          dprint,info.title_num+'Error Recovery'
        end
      endcase
    end
    wids.dest_button: begin
      widget_control,ev.id,get_value=status

      widget_control,wids.dest_text, get_value=filename
      case status of
        'Write to': begin
          if keyword_set(info.dfp) then begin
            free_lun,info.dfp
            info.dfp = 0
          endif
          WIDGET_CONTROL,   ev.id       , set_value = 'Opening' ,sensitive=0
          widget_control, wids.dest_text, get_value = fileformat,sensitive=0
          filename = time_string(systime(1),tformat = fileformat[0])                     ; Substitute time string
          widget_control,wids.host_text, get_value=hostname
          filename = str_sub(filename,'{HOST}',strtrim(hostname,2) )
          widget_control,wids.host_port, get_value=hostport
          filename = str_sub(filename,'{PORT}',strtrim(hostport,2) )               ; Substitute port number
          widget_control, wids.dest_text, set_uvalue = fileformat,set_value=filename
          if keyword_set(filename) then begin
            file_open,'u',info.directory+filename, unit=dfp,dlevel=4,compress=-1,file_mode='666'o,dir_mode='777'o
            dprint,dlevel=dlevel,info.title_num+'Opened output file: '+file_info_string(info.directory+filename)+' Unit:'+strtrim(dfp)
            info.dfp = dfp
            info.filename= info.directory+filename
            widget_control, wids.dest_flush, sensitive=1
          endif
          ;              wait,1
          WIDGET_CONTROL, ev.id, set_value = 'Close   ',sensitive =1
        end
        'Close   ': begin
          WIDGET_CONTROL, ev.id,          set_value = 'Closing',sensitive=0
          widget_control, wids.dest_flush, sensitive=0
          widget_control, wids.dest_text ,get_uvalue= fileformat,get_value=filename
          if info.dfp gt 0 then begin
            free_lun,info.dfp
            info.dfp =0
          endif
          ;            wait,1
          widget_control, wids.dest_text ,set_value= fileformat,sensitive=1
          WIDGET_CONTROL, ev.id, set_value = 'Write to',sensitive=1
          dprint,dlevel=dlevel,info.title_num+'Closed output file: '+file_info_string(info.directory+filename),no_check_events=1
        end
        else: begin
          dprint,info.title_num+'Invalid State'
        end
      endcase
    end
    wids.dest_flush: begin
      esc_recorder_event,{top: ev.top, id:wids.dest_button}   ; close old file
      esc_recorder_event,{top: ev.top, id:wids.dest_button}   ; open  new file
    end
    ;    wids.host_text:  begin
    ;        widget_control,ev.id,get_value=value
    ;        dprint,'"'+value+'"'
    ;    end
    wids.proc_button: begin
      widget_control,wids.proc_name,get_value=proc_name
      widget_control,wids.proc_name,sensitive = (ev.select eq 0)
      info.run_proc = ev.select
      dprint,dlevel=2,info.title_num+'"'+proc_name+ '" is '+ (info.run_proc ? 'ON' : 'OFF')
    end
    wids.done: begin   ;    'DONE' ;  close files here!
      if info.hfp gt 0 then begin
        fs = fstat(info.hfp)
        dprint,dlevel=dlevel-1,info.title_num+'Closing '+fs.name
        free_lun,info.hfp
      endif
      if info.dfp gt 0 then begin
        fs = fstat(info.dfp)
        dprint,dlevel=dlevel-1,info.title_num+'Closing '+fs.name
        free_lun,info.dfp
      endif
      ptr_free,ptr_extract(info)
      WIDGET_CONTROL, ev.TOP, /DESTROY
      dprint,dlevel=dlevel-1,info.title_num+'Widget Closed'
      return
    end
    else: begin
      msg = string('Base ID is: ',wids.base)
      widget_control, wids.output_text, set_value=msg
      dprint,info.title_num+msg
      printdat,ev
      printdat,info
    end
  ENDCASE
  widget_control,wids.base,set_uvalue=info
END


;PRO exec_proc_template,buffer,info=info
;;    savetomain,buffer
;;    savetomain,time
;
;    n = n_elements(buffer)
;    if n ne 0 then  begin
;    if debug(2) then begin
;      dprint,time_string(info.time_received,prec=3) +''+ strtrim(n_elements(buffer))
;      n = n_elements(buffer) < 512
;      hexprint,buffer[0:n-1]    ;,swap_endian(uint(buffer,0,n_elements(buffer)/2))
;    endif
;    endif else print,format='(".",$)'
;
;    return
;end


PRO esc_recorder,base,title=title,ids=ids,host=host,port=port,destination=destination,exec_proc=exec_proc, $
  set_connect=set_connect, set_output=set_output, pollinterval=pollinterval, set_file_timeres=set_file_timeres ,$
  get_procbutton = get_procbutton,set_procbutton=set_procbutton,directory=directory, $
  get_filename=get_filename,info=info
  if ~(keyword_set(base) && widget_info(base,/managed) ) then begin
    if not keyword_set(host) then host = 'localhost'
    if not keyword_set(port) then port = '2022'
    if not keyword_set(title) then title = 'ESCAPADE GSE Recorder'
    port=strtrim(port,2)
    if not keyword_set(destination) then destination = 'socket_{HOST}.{PORT}_YYYYMMDD_hhmmss.dat'
    ids = create_struct('base', WIDGET_BASE(/COLUMN, title=title ) )
    ids = create_struct(ids,'host_base',   widget_base(ids.base,/row, uname='HOST_BASE') )
    ids = create_struct(ids,'host_button', widget_button(ids.host_base, uname='HOST_BUTTON',value='Connect to') )
    ids = create_struct(ids,'host_text',   widget_text(ids.host_base,  uname='HOST_TEXT' ,VALUE=host ,/EDITABLE ,/NO_NEWLINE ) )
    ids = create_struct(ids,'host_port',   widget_text(ids.host_base,  uname='HOST_PORT',xsize=6, value=port   , /editable, /no_newline))
    ids = create_struct(ids,'poll_int' ,   widget_text(ids.host_base,  uname='POLL_INT',xsize=6,value='1',/editable,/no_newline))
    ;    if n_elements(directory) ne 0 then $
    ;      ids = create_struct(ids,'destdir_text',   widget_text(ids.base,  uname='DEST_DIRECTORY',xsize=40 ,/EDITABLE ,/NO_NEWLINE  ,VALUE=directory))
    ids = create_struct(ids,'dest_base',   widget_base(ids.base,/row, uname='DEST_BASE'))
    ids = create_struct(ids,'dest_button', widget_button(ids.dest_base, uname='DEST_BUTTON',value='Write to'))
    ids = create_struct(ids,'dest_text',   widget_text(ids.dest_base,  uname='DEST_TEXT',xsize=40 ,/EDITABLE ,/NO_NEWLINE  ,VALUE=destination))
    ids = create_struct(ids,'dest_flush',  widget_button(ids.dest_base,uname='DEST_FLUSH', value='New' ,sensitive=0))
    ids = create_struct(ids,'output_text', WIDGET_TEXT(ids.base, uname='OUTPUT_TEXT'))
    ids = create_struct(ids,'proc_base',   widget_base(ids.base,/row, uname='PROC_BASE'))
    ids = create_struct(ids,'proc_base2',  widget_base(ids.proc_base ,/nonexclusive))
    ids = create_struct(ids,'proc_button', widget_button(ids.proc_base2,uname='PROC_BUTTON',value='Procedure:'))
    ids = create_struct(ids,'proc_name',   widget_text(ids.proc_base,xsize=35, uname='PROC_NAME', value = keyword_set(exec_proc) ? exec_proc :'exec_proc_template',/editable, /no_newline))
    ids = create_struct(ids,'done',        WIDGET_BUTTON(ids.proc_base, VALUE='Done', UNAME='DONE'))
    title_num = title+' ('+strtrim(ids.base,2)+'): '

    info = { socket_recorder } 

    info.wids = ptr_new(ids)
    info.next_filechange = 1d20
    info.title=title
    info.title_num = title_num
    info.fileformat = destination
    info.maxsize = 2L^23
    info.buffer_ptr = ptr_new(!null)
    info.verbose =2
    info.exec_proc_ptr = ptr_new(!null)
    info.run_proc = keyword_set(set_procbutton)
    info.user_dict = dictionary()

    ;    info.buffer_ptr = ptr_new( bytarr( info.maxsize ) )
    WIDGET_CONTROL, ids.base, SET_UVALUE=info
    WIDGET_CONTROL, ids.base, /REALIZE
    widget_control, ids.base, base_set_title=title_num
    XMANAGER, 'esc_recorder', ids.base,/no_block
    dprint,dlevel=dlevel,info.title_num+'Widget started'
    base = ids.base
  endif else begin
    widget_control, base, get_uvalue= info   ; get all widget ID's
    ids = *info.wids
  endelse
  if size(/type,exec_proc) eq 7 then    widget_control,ids.proc_name,set_value=exec_proc
  if size(/type,destination) eq 7 then  widget_control,ids.dest_text,set_value=destination
  if size(/type,host) eq 7 then  widget_control,ids.host_text,set_value=host
  if n_elements(port) eq 1 then  widget_control,ids.host_port,set_value=strtrim(port,2)
  if n_elements(pollinterval) ne 0 then widget_control,ids.poll_int,set_value=strtrim(pollinterval,2)
  if n_elements(set_output)  eq 1 && (keyword_set(info.dfp) ne keyword_set(set_output )) then esc_recorder_event, { id:ids.dest_button, top:ids.base }
  if n_elements(set_connect) eq 1 && (keyword_set(info.hfp) ne keyword_set(set_connect)) then esc_recorder_event, { id:ids.host_button, top:ids.base }
  if n_elements(set_procbutton) eq 1 then begin
    widget_control,ids.proc_button,set_button=set_procbutton
    esc_recorder_event, { top:ids.base, id:ids.proc_button, select: keyword_set(set_procbutton) }
  endif
  if n_elements(set_file_timeres) then begin
    info.file_timeres = set_file_timeres
    widget_control, base, set_uvalue= info
  endif
  if n_elements(directory) then begin
    info.directory = directory
    widget_control, base, set_uvalue= info
  endif
  get_procbutton = widget_info(ids.proc_button,/button_set)
  ;widget_control,ids.dest_text,get_value=get_filename
  get_filename = keyword_set(info.dfp) ? info.filename : ''


END
