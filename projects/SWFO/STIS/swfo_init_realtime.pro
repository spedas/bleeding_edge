

pro swfo_init_realtime,filenames=filenames,swfo=swfo, stis=stis , exec=exec0, opts=opts

  stis = 1


  if keyword_set(stis) then begin

    if ~isa(opts,'dictionary') then begin   ; set default values for
      opts=dictionary()
      opts.root = root_data_dir()
      opts.file_type = 'cmblk'
      opts.reldir = 'swfo/data/sci/stis/prelaunch/realtime/'+opts.file_type+'/'
      opts.fileformat = 'YYYY/MM/DD/swfo_stis_cmb_YYYYMMDD_hh.dat.gz'
      opts.host = 'swifgse1.ssl.berkeley.edu'
      opts.port = 2432
      opts.title = 'SWFO CMB'
    endif
    ;extra  = opts.ToStruct()
    ;swfo_ptp_recorder,title='SWFO STIS PTP',_extra = extra
    d = opts
    directory = d.root + d.reldir
    case d.file_type of
      'ptp_file':   swfo_ptp_recorder,title=d.title,port=d.port, host=d.host, exec_proc='swfo_ptp_lun_read',destination=d.fileformat,directory=directory,set_file_timeres=3600d
      'gse_file':   swfo_recorder,title=d.title,port=d.port, host=d.host, exec_proc='swfo_gsemsg_lun_read',destination=d.fileformat,directory=directory,set_file_timeres=3600d
      'cmblk': opts.cmblk = commonblock_reader(title=d.title,port=d.port, host=d.host, destination=d.fileformat,directory=directory,set_file_timeres=3600d)
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
