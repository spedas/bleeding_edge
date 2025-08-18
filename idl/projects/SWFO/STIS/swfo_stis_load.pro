;$LastChangedBy: davin-mac $
;$LastChangedDate: 2024-10-27 01:24:49 -0700 (Sun, 27 Oct 2024) $
;$LastChangedRevision: 32908 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SWFO/STIS/swfo_stis_load.pro $

pro swfo_stis_load,file_type=file_type,station=station,host=host, ncdf_resolution=ncdf_resolution , $
  trange=trange,opts=opts,make_ncdf=make_ncdf,make_ccsds=make_ccsds, debug=debug,run_proc=run_proc, $
  offline=offline,no_exec=no_exec,reader_object=rdr,no_widget=no_widget
  

  if keyword_set(debug) then stop
  if n_elements(trange) eq 0 then trange=2.   ; default to last 2 hours
  if ~keyword_set(file_type) then file_type = 'gsemsg'
  if ~keyword_set(station) then station='S0'
  if ~keyword_set(ncdf_resolution) then ncdf_resolution = 1800
  
  if ~isa(opts,'dictionary') then   opts=dictionary()

  if ~opts.haskey('trange') then opts.trange = trange
  if ~opts.haskey('station') then opts.station = station
  if ~opts.haskey('file_type') then opts.file_type = file_type

  if isa(run_proc) then opts.run_proc = run_proc

  stis = 1

  opts.file_resolution = 3600     ; default file resolution for L0 files stored at Berkeley/ssl
  level = 'L0'
  ncdf_directory = root_data_dir() + 'swfo/data/sci/stis/prelaunch/realtime/'+station+'/ncdf/'

  if keyword_set(stis) then begin
    ;opts.host = 'swifgse1.ssl.berkeley.edu'
    opts.root_dir = root_data_dir()
    opts.url = 'http://research.ssl.berkeley.edu/data/'
    ;opts.title = 'SWFO'
    
    case opts.station of
      'S0':     opts.host = 'swifgse1.ssl.berkeley.edu'
      'S1':     opts.host = 'swifgse1.ssl.berkeley.edu'
      'S2':     opts.host = 'hermroute3.ssl.berkeley.edu'
      'S3':     opts.host = 'swifroute2.ssl.berkeley.edu'
      'cleantent': opts.host = 'snout2router.ssl.berkeley.edu'
      'Ball-BAT' :  opts.host = '136.152.31.185'
      ;'Ball' :  opts.host = '136.152.17.167'
      'Ball' :  opts.host =  'sweapsoc' ;'10.136.128.47';'136.152.28.121' ; '136.152.31.195'
      'Ball2' :  opts.host =  'sweapsoc';,'10.136.128.47';'136.152.28.121' ; '136.152.31.195'
      'STIS' :  opts.host =  'swifgse1.ssl.berkeley.edu'
    endcase
    

    ss_type = opts.station+'/'+opts.file_type
    case ss_type of 
      'Ball-BAT/cmblk': begin
        opts.port       = 2225
        opts.reldir     = 'swfo/data/sci/stis/prelaunch/realtime/'
        opts.fileformat = 'Ball-BAT/cmblk/YYYY/MM/DD/swfo_stis_cmblk_YYYYMMDD_hh.dat.gz'
      end
      'Ball/cmblk': begin
        opts.port       = 2125
        opts.reldir     = 'swfo/data/sci/stis/prelaunch/realtime/'
        opts.fileformat = 'Ball/cmblk/YYYY/MM/DD/swfo_stis_cmblk_YYYYMMDD_hh.dat.gz'
      end
      'Ball2/cmblk': begin
        opts.port       = 2125
        opts.reldir     = 'swfo/data/sci/stis/prelaunch/realtime/'
        opts.fileformat = 'Ball2/cmblk/YYYY/MM/DD/swfo_stis_cmblk_YYYYMMDD_hh.dat.gz'
      end
      'STIS/cmblk': begin
        opts.port       = 2228
        opts.reldir     = 'swfo/data/sci/stis/prelaunch/realtime/'
        opts.fileformat = 'Ball/cmblk/YYYY/MM/DD/swfo_stis_cmblk_YYYYMMDD_hh.dat.gz'
      end
      'Ball/ccsds': begin
        opts.port       = 2125
        opts.reldir     = 'swfo/data/sci/stis/prelaunch/realtime/'
        opts.fileformat = 'Ball/ccsds/YYYY/MM/DD/swfo_stis_ccsds_YYYYMMDD_hh.dat.gz'
      end
      'S0/cmblk': begin
        opts.port       = 2025
        opts.reldir     = 'swfo/data/sci/stis/prelaunch/realtime/'
        opts.fileformat = 'S0/cmblk/YYYY/MM/DD/swfo_stis_cmblk_YYYYMMDD_hh.dat.gz'
      end
      'S1/cmblk': begin
        opts.port       = 2125
        opts.reldir     = 'swfo/data/sci/stis/prelaunch/realtime/'
        opts.fileformat = 'S1/cmblk/YYYY/MM/DD/swfo_stis_cmblk_YYYYMMDD_hh.dat.gz'
      end
      'S2/cmblk': begin
        opts.port       = 2225
        opts.reldir     = 'swfo/data/sci/stis/prelaunch/realtime/'
        opts.fileformat = 'S2/cmblk/YYYY/MM/DD/swfo_stis_cmblk_YYYYMMDD_hh.dat.gz'
      end
      'S3/cmblk': begin
        opts.port       = 2025
        opts.reldir     = 'swfo/data/sci/stis/prelaunch/realtime/'
        opts.fileformat = 'S3/cmblk/YYYY/MM/DD/swfo_stis_cmblk_YYYYMMDD_hh.dat.gz'
      end
      'S0/gsemsg': begin
        opts.port       = 2028
        opts.reldir     = 'swfo/data/sci/stis/prelaunch/realtime/'
        opts.fileformat = 'S0/gsemsg/YYYY/MM/DD/swfo_stis_socket_YYYYMMDD_hh.dat.gz'
      end
      'S1/gsemsg': begin
        opts.port =        2128
        opts.reldir     = 'swfo/data/sci/stis/prelaunch/realtime/'
        opts.fileformat = 'S1/gsemsg/YYYY/MM/DD/swfo_stis_socket_YYYYMMDD_hh.dat.gz'
      end
      'S2/gsemsg': begin
        opts.port =        2228
        opts.reldir     = 'swfo/data/sci/stis/prelaunch/realtime/'
        opts.fileformat = 'S2/gsemsg/YYYY/MM/DD/swfo_stis_socket_YYYYMMDD_hh.dat.gz'
      end
      'S3/gsemsg': begin
        opts.port       = 2028
        opts.reldir     = 'swfo/data/sci/stis/prelaunch/realtime/'
        opts.fileformat = 'S3/gsemsg/YYYY/MM/DD/swfo_stis_gsemsg_YYYYMMDD_hh.dat.gz'
      end
      'S0/ccsds': begin
        opts.port =        2029
        opts.reldir     = 'swfo/data/sci/stis/prelaunch/realtime/'
        opts.fileformat = 'S0/ccsds/YYYY/MM/DD/swfo_stis_ccsds_YYYYMMDD_hh.dat'
      end
      'S1/ccsds': begin
        opts.port =        2129
        opts.reldir     = 'swfo/data/sci/stis/prelaunch/realtime/'
        opts.fileformat = 'S1/ccsds/YYYY/MM/DD/swfo_stis_ccsds_YYYYMMDD_hh.dat'
      end
      'S2/ccsds': begin
        opts.port =        2229
        opts.reldir     = 'swfo/data/sci/stis/prelaunch/realtime/'
        opts.fileformat = 'S2/ccsds/YYYY/MM/DD/swfo_stis_ccsds_YYYYMMDD_hh.dat'
      end
      'S3/ccsds': begin
        opts.port =        2029
        opts.reldir     = 'swfo/data/sci/stis/prelaunch/realtime/'
        opts.fileformat = 'S3/ccsds/YYYY/MM/DD/swfo_stis_ccsds_YYYYMMDD_hh.dat'
      end
      'S0/sccsds': begin
        opts.port =       2027
        opts.reldir     = 'swfo/data/sci/stis/prelaunch/realtime/'
        opts.fileformat = 'S0/sccsds/YYYY/MM/DD/swfo_stis_sccsds_YYYYMMDD_hh.dat'
      end
      'S1/sccsds': begin
        opts.port =       2127
        opts.reldir     = 'swfo/data/sci/stis/prelaunch/realtime/'
        opts.fileformat = 'S1/sccsds/YYYY/MM/DD/swfo_stis_sccsds_YYYYMMDD_hh.dat'
      end
      'S2/sccsds': begin
        opts.port =       2227
        opts.reldir     = 'swfo/data/sci/stis/prelaunch/realtime/'
        opts.fileformat = 'S2/sccsds/YYYY/MM/DD/swfo_stis_sccsds_YYYYMMDD_hh.dat'
      end
      'S3/sccsds': begin
        opts.port =       2027
        opts.reldir     = 'swfo/data/sci/stis/prelaunch/realtime/'
        opts.fileformat = 'S3/sccsds/YYYY/MM/DD/swfo_stis_sccsds_YYYYMMDD_hh.dat'
      end
      'S1/ncdf': begin
        opts.port = 0
        opts.file_resolution = ncdf_resolution
        opts.reldir    = 'swfo/data/sci/stis/prelaunch/realtime/S1/ncdf/'
        opts.fileformat = '$NAME$/$TYPE$/YYYY/MM/DD/swfo_$NAME$_$TYPE$_$RES$_YYYYMMDD_hhmm_v00.nc'
        name  = 'stis_sci'
        res = strtrim(fix(ncdf_resolution),2)   ; '1800'
        level = 'L0B'
      end
      'S0/ncdf': begin
        opts.port = 0
        opts.file_resolution = ncdf_resolution
        opts.reldir    = 'swfo/data/sci/stis/prelaunch/realtime/S0/ncdf/'
        opts.fileformat = '$NAME$/$TYPE$/YYYY/MM/DD/swfo_$NAME$_$TYPE$_$RES$_YYYYMMDD_hhmm_v00.nc'
        name  = 'stis_sci'
        res = strtrim(fix(ncdf_resolution),2)   ; '1800'
        level = 'L0B'
      end
      'cleantent/ptp': begin
      opts.port =       22628
      opts.reldir     = 'swx/s\st/prelaunch/realtime/'
      opts.fileformat = 'cleantent/ptp_reader/YYYY/MM/DD/ptp_reader_YYYYMMDD_hh.dat'
      end
      else: begin
        dprint,'Undefined: '+ss_type
        opts.port = 0
        return
      end
    endcase

    if opts.file_type eq 'ncdf' then begin
      opts.fileformat = str_sub(opts.fileformat,'$NAME$', name)
      opts.fileformat = str_sub(opts.fileformat,'$TYPE$', level)
      opts.fileformat = str_sub(opts.fileformat,'$RES$', res)
    endif


    if keyword_set(offline) then opts.url=''

    opts.exec_text =  ['tplot,verbose=0,trange=systime(1)+[-1.,.05]*600','timebar,systime(1)','swfo_stis_plot']
    ;    opts.file_trange = 3


    ;    trange = struct_value(opts,'file_trange',default=!null)
    if keyword_set(trange) then begin
      ;trange = opts.file_trange
      pathformat = opts.reldir + opts.fileformat
      ;filenames = file_retrieve(pathformat,trange=trange,/hourly_,remote_data_dir=opts.remote_data_dir,local_data_dir= opts.local_data_dir)
      if n_elements(trange eq 1)  then trange = systime(1) + [-trange[0],0.1]*3600.
      timespan,trange
      dprint,dlevel=2,'Download raw telemetry files...'
      if 1 then begin
        filenames = file_retrieve(pathformat,trange=trange,remote=opts.url,local=opts.root_dir,resolution=opts.file_resolution)
      endif else begin
        filenames = swfo_file_retrieve(pathformat,trange=trange)
      endelse
      dprint,dlevel=2, "Files to be loaded:"
      dprint,dlevel=2,file_info_string(filenames)
      opts.filenames = filenames
    endif

    str_element,opts,'filenames',filenames

    if level eq 'L0' then begin
      swfo_stis_apdat_init,/save_flag    ; initialize apids
      ;swfo_apdat_info,/rt_flag ,/save_flag       ; don't use rt_flag anymore
      swfo_apdat_info,/print,/all        ; display apids

      if keyword_set(make_ncdf) then begin
        sci = swfo_apdat('stis_sci')
        sci.ncdf_directory = ncdf_directory
        sci.file_resolution = ncdf_resolution    ; setting the ncdf_resolution to a non zero number will tell the decom software to also generate NCDF files
      endif

    endif




    opts.directory = opts.root_dir + opts.reldir
    file_type = opts.file_type
    rdr = 0
    case file_type of
      'ptp_file': begin   ; obsolete - Do not use
        message,"Obsolete - Don't use this",/cont
        swfo_ptp_recorder,_extra=opts.tostruct(), exec_proc='swfo_ptp_lun_read',destination=opts.fileformat,directory=directory,set_file_timeres=3600d
      end
      'gsemsg': begin
        if 1 then begin
          rdr = gsemsg_reader(_extra= opts.tostruct(),mission='SWFO')          
        endif else begin
          rdr = swfo_raw_tlm(_extra= opts.tostruct())
        endelse
        opts.rdr = rdr
        
        if keyword_set(make_ccsds) then begin   ; this is a special hook to create ccsds files from gsemsg files
          ccsds_writer = ccsds_reader(directory=opts.directory,fileformat = station+'/ccsds/YYYY/MM/DD/swfo_stis_ccsds_YYYYMMDD_hh.dat',run_proc=0)
          rdr.source_dict.ccsds_writer = ccsds_writer
          dprint,'Are you sure about this?'
          ;stop  ; Are you sure about this?
        endif

        if opts.haskey('filenames') then begin
          rdr.file_read,opts.filenames
        endif
        swfo_apdat_info,/all,/print
        swfo_apdat_info,/all,/create_tplot_vars
        
      end
      'ptp': begin
        
        if 0 then begin
          rdr  = cmblk_reader( _extra = opts.tostruct(),name='SWFO_Ball_cmblk')
          opts.rdr = rdr
          if opts.haskey('filenames') then begin
            if keyword_set(test) then begin
              hs = rdr.get_handlers()
              foreach h , hs do begin
                h.exec_proc=0
              endforeach
            endif

            rdr.file_read, opts.filenames        ; Load in the files
          endif
          swfo_apdat_info,/all,/create_tplot_vars
          tplot_options,title='Real Time (PTP)'
          
        endif else begin
          dprint,dlevel=0, 'Warning:  This file type is Obsolete and the code is not tested;
          if opts.haskey('filenames') then begin
            opts.file_type = 'ptp_file'
            swfo_ptp_file_read,opts.filenames,file_type=opts.file_type  ;,/no_clear
          endif
          swfo_apdat_info,/all,/rt_flag
          swfo_apdat_info,/all,/print
          swfo_recorder,port=opts.port, host=opts.host, exec_proc='swfo_gsemsg_lun_read',destination=opts.fileformat,directory=directory,set_file_timeres=3600d          
        endelse
      end
      'cmblk': begin        
        rdr  = cmblk_reader( _extra = opts.tostruct(),name='SWFO_Ball_cmblk',no_widget=no_widget)
        if 1 then begin  ;new method
          rdr.add_handler, 'raw_tlm',  gsemsg_reader(name='SWFO_reader',/no_widget,mission='SWFO')   
          rdr.add_handler, 'raw_ball', ccsds_reader(/no_widget,name='BALL_reader', _extra = opts.tostruct() , sync_pattern = ['2b'xb,  'ad'xb ,'ca'xb, 'fe'xb], sync_mask= [0xef,0xff,0xff,0xff] )  
        endif else begin
          rdr.add_handler, 'raw_tlm',  swfo_raw_tlm(name='SWFO_raw_telem',/no_widget)          
        endelse
     ;   rdr.add_handler, 'KEYSIGHTPS' ,  gse_keysight(name='Keysight',/no_widget,tplot_tagnames='*')
     ;   rdr.add_handler,'IONGUN1',  json_reader(name='IonGun1',no_widget=1,tplot_tagnames='*')
     ;   rdr.add_handler,'IONGUN',  json_reader(name='IonGun',no_widget=1,tplot_tagnames='*')
     ;   kpa_object = gse_keithley(name='pico',/no_widget,tplot_tagnames='*')
     ;   rdr.add_handler,'KEITHLEYPA', kpa_object   ; gse_keithley(name='pico',/no_widget,tplot_tagnames='*')
     ;   rdr.add_handler,'GSE_KPA',    kpa_object   ; gse_keithley(name='pico',/no_widget,tplot_tagnames='*')
        opts.rdr = rdr
        if opts.haskey('filenames') then begin
          if keyword_set(test) then begin
            hs = rdr.get_handlers()
            foreach h , hs do begin
              h.exec_proc=0
            endforeach
          endif
            
          rdr.file_read, opts.filenames        ; Load in the files
        endif
        swfo_apdat_info,/all,/create_tplot_vars
        tplot_options,title='Real Time (CMBLK)'
      end
      'ccsds': begin
        rdr  = ccsds_reader(_extra = opts.tostruct() )
        opts.rdr = rdr
        if opts.haskey('filenames') then begin
          rdr.file_read, opts.filenames        ; Load in the files
        endif
        swfo_apdat_info,/all,/create_tplot_vars
        tplot_options,title='Real Time (CCSDS)'
      end
      'sccsds': begin
        dprint,'Warning - this code segment has not been tested.'
        sync = byte(['1a'x,'cf'x,'fc'x,'1d'x])
        rdr  = ccsds_reader(sync=sync, _extra=opts.toStruct())
        opts.rdr = rdr
        if opts.haskey('filenames') then begin
          rdr.file_read, opts.filenames        ; Load in the files
        endif
        swfo_apdat_info,/all,/create_tplot_vars
        tplot_options,title='Real Time (Sync CCSDS)'
      end
      'ncdf': begin
        prefix = 'ncdf_'+level+'_'
        ;prefix = 'swfo_'
        ncdf_data = swfo_ncdf_read(filenames=filenames)
        store_data,prefix+name+'sci_',data=ncdf_data,tagnames = '*'
      end
      else:  dprint,'Unknown file format'
    endcase

    str_element,opts,'exec_text',exec_text
    if ~keyword_set(no_exec) && ~keyword_set(no_widget) && keyword_set(exec_text) then begin
      exec, exec_text = exec_text;,title=opts.title
    endif

    swfo_stis_tplot,/set,'dl3'
    !except=0
    
    ; Setup plotting routine
    param=dictionary('routine_name','swfo_stis_plot')
    param.read_object = rdr
    swfo_stis_plot,param=param
    dprint,'For visualization, run:'
    print,'ctime,/silent,t,routine_name="swfo_stis_plot"'

  endif

end