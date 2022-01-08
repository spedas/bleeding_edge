

pro swfo_init_realtime,filenames=filenames,swfo=swfo, stis=stis , exec=exec0, opts=opts

  stis = 1


  if keyword_set(stis) then begin

    if ~isa(opts,'dictionary') then begin   ; set default values for
      opts=dictionary()
      opts.root = root_data_dir()
      opts.reldir = 'swfo/data/sci/stis/prelaunch/realtime/'
      opts.fileformat = 'YYYY/MM/DD/swfo_stis_socket_YYYYMMDD_hh.dat.gz'
      opts.host = '128.32.98.57'
      opts.port = 2428
      opts.title = 'SWFO PTP'
      opts.file_type = 'ptp_file'
    endif
    ;extra  = opts.ToStruct()
    ;swfo_ptp_recorder,title='SWFO STIS PTP',_extra = extra
    d = opts
    directory = d.root + d.reldir
    case opts.file_type of
      'ptp_file':   swfo_ptp_recorder,title=d.title,port=d.port, host=d.host, exec_proc='swfo_ptp_lun_read',destination=d.fileformat,directory=directory,set_file_timeres=3600d
      'gse_file':   swfo_recorder,title=d.title,port=2028, host=d.host, exec_proc='swfo_gsemsg_lun_read',destination=d.fileformat,directory=directory,set_file_timeres=3600d
    endcase
  endif




  if keyword_set(exec0) then begin
    exec, exec_text = ['tplot,verbose=0,trange=systime(1)+[-1.,.05]*600','timebar,systime(1)'],title=title
  endif

  ;return

  tplot_options,title='Real Time'

  if keyword_set(stis) then swfo_apdat_info,/rt_flag ,/save_flag

  ; spp_apdat_info,/rt_Flag,/save_flag,/all

  ;spp_swp_set_tplot_options

  ;;--------------------------------------------------
  ;; Useful command to see what APIDs have been loaded
  ;spp_apdat_info,/print
  ;print_struct,ap
  ;;-------------------------------------------------


end
