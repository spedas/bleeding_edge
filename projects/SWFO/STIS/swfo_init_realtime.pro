

pro swfo_init_realtime,host=host, port=port , trange=trange, opts=opts, offline=offline

  stis = 1

  if ~keyword_set(port) then port = 2432
  if ~keyword_set(host) then host = 'swifgse1.ssl.berkeley.edu'

  if keyword_set(stis) then begin

    if ~isa(opts,'dictionary') then begin   ; set default values for
      opts=dictionary()
      opts.host = host
      opts.port = port
      opts.root_dir = root_data_dir()
      opts.url = 'http://research.ssl.berkeley.edu/data/'
      opts.title = 'SWFO'
      case opts.port of
        2432: begin
          opts.station    = 'S0'           ; defines which GSE computer is being used
          opts.file_type  = 'CMBLK'
          opts.reldir     = 'swfo/data/sci/stis/prelaunch/realtime/S0/cmblk/'
          opts.fileformat = 'YYYY/MM/DD/swfo_stis_cmblk_YYYYMMDD_hh.dat.gz'
        end
        2433: begin
          opts.station    = 'S1'           ; defines which GSE computer is being used
          opts.file_type  = 'CMBLK'
          opts.reldir     = 'swfo/data/sci/stis/prelaunch/realtime/S1/cmblk/'
          opts.fileformat = 'YYYY/MM/DD/swfo_stis_cmblk_YYYYMMDD_hh.dat.gz'
        end
        2028: begin
          opts.station    = 'S0'
          opts.file_type  = 'gse_file'
          opts.reldir     = 'swfo/data/sci/stis/prelaunch/realtime/S0/gsemsg/'
          opts.fileformat = 'YYYY/MM/DD/swfo_stis_socket_YYYYMMDD_hh.dat.gz'
        end
        2128: begin
          opts.station    = 'S1'
          opts.file_type  = 'gse_file'
          opts.reldir     = 'swfo/data/sci/stis/prelaunch/realtime/S1/gsemsg/'
          opts.fileformat = 'YYYY/MM/DD/swfo_stis_socket_YYYYMMDD_hh.dat.gz'
        end
      endcase

      if keyword_set(offline) then opts.url=''

      opts.exec_text =  ['tplot,verbose=0,trange=systime(1)+[-1.,.05]*600','timebar,systime(1)']
      ;    opts.file_trange = 3
    endif

    ;    trange = struct_value(opts,'file_trange',default=!null)
    if keyword_set(trange) then begin
      ;trange = opts.file_trange
      pathformat = opts.reldir + opts.fileformat
      ;filenames = file_retrieve(pathformat,trange=trange,/hourly_,remote_data_dir=opts.remote_data_dir,local_data_dir= opts.local_data_dir)
      if n_elements(trange eq 1)  then trange = systime(1) + [-trange[0],0]*3600.
      dprint,dlevel=2,'Download raw telemetry files...'
      if 1 then begin
        filenames = file_retrieve(pathformat,trange=trange,/hourly,remote=opts.url,local=opts.root_dir,resolution=3600L)
      endif else begin
        filenames = swfo_file_retrieve(pathformat,trange=trange)
      endelse
      dprint,dlevel=2, "Print the raw data files..."
      dprint,dlevel=2,file_info_string(filenames)
      opts.filenames = filenames
    endif




    str_element,opts,'filenames',filenames


    if keyword_set(stis) then begin
      swfo_stis_apdat_init,/save_flag    ; initialize apids
      ;swfo_apdat_info,/rt_flag ,/save_flag       ; don't use rt_flag anymore
      swfo_apdat_info,/print,/all        ; display apids

    endif


    d = opts
    directory = d.root_dir + d.reldir
    case d.file_type of
      'ptp_file': begin   ; obsolete - Do not use
        message,"Obsolete - Don't use this",/cont
        swfo_ptp_recorder,title=d.title,port=d.port, host=d.host, exec_proc='swfo_ptp_lun_read',destination=d.fileformat,directory=directory,set_file_timeres=3600d
      end
      'gse_file': begin
        if 1 then begin
          raw = swfo_raw_tlm(port=d.port,host=d.host)
          opts.raw = raw
          if opts.haskey('filenames') then begin
            raw.file_read,opts.filenames
          endif
          swfo_apdat_info,/all,/print
          swfo_apdat_info,/all,/create_tplot_vars
        endif else begin
          if opts.haskey('filenames') then begin
            swfo_ptp_file_read,opts.filenames,file_type=opts.file_type  ;,/no_clear
          endif
          swfo_apdat_info,/all,/rt_flag
          swfo_apdat_info,/all,/print
          swfo_recorder,title=d.title,port=d.port, host=d.host, exec_proc='swfo_gsemsg_lun_read',destination=d.fileformat,directory=directory,set_file_timeres=3600d
        endelse
      end
      'CMBLK': begin
        cmb1  = cmblk_reader(port=d.port, host=d.host,directory=directory,fileformat=opts.fileformat)
        ;cmb1.add_handler, 'raw_tlm',  swfo_raw_tlm('SWFO_raw_telem',/no_widget)
        ;cmb1.add_handler, 'KEYSIGHTPS' ,  cmblk_keysight('Keysight',/no_widget)
        opts.cmb = cmb1

        if opts.haskey('filenames') then begin
          cmb1.file_read, opts.filenames        ; Load in the files
        endif

        swfo_apdat_info,/all,/create_tplot_vars

        tplot_options,title='Real Time (CMBLK)'

      end
      else:  dprint,'Unknown format'
    endcase




    str_element,opts,'exec_text',exec_text
    if keyword_set(exec_text) then begin
      exec, exec_text = exec_text,title=opts.title
    endif



  endif


  ;return



  ;spp_swp_set_tplot_options

  ;;--------------------------------------------------
  ;; Useful command to see what APIDs have been loaded
  ;spp_apdat_info,/print
  ;print_struct,ap
  ;;-------------------------------------------------


end
