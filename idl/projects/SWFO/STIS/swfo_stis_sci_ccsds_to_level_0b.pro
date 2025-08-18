;swfo_stis_sci_ccsds_to_level_0b.pro
;


  station = 'S2'
  trange = ['23 7 26 4','23 7 26 5']
  trange = ['23 7 27 4','23 7 27 24']  & station='S2'   ; Calibration with ion gun
  trange = ['2023-7-27 2','2023-7-27 5'] & station='S2' ; Calibration with ion gun with high ion flux and DECIMATION on 
  l0b_filename = 'STIS_L0B_SSL_iongun_upd.nc'
  ;trange = ['23 7 27 17 ','23 7 27 19']  & station='S2'   ; High flux ions from calibration
  trange = ['23 6 1','23 6 1 4']  & station='S0'     ; 1/r^2 test with x-ray source
  l0b_filename = 'STIS_L0B_SSL_Xray_upd.nc'

  ; Load data if not already in memory:
  swfo_stis_apdat_init,/save_flag

  no_download = 1    ;set to 1 to prevent download from the web
  no_update = 1      ; set to 1 to prevent checking for updates

  source = {$
    remote_data_dir:'http://sprg.ssl.berkeley.edu/data/', $
    master_file: 'swfo/.master', $
    no_update : no_update ,$
    no_download :no_download ,$
    resolution: 3600L  }

  ;pathname = 'swfo/data/sci/stis/prelaunch/realtime/S2/gsemsg/YYYY/MM/DD/swfo_stis_socket_YYYYMMDD_hh.dat.gz'
  ;pathname = 'swfo/data/sci/stis/prelaunch/realtime/S2/cmblk/YYYY/MM/DD/swfo_stis_cmblk_YYYYMMDD_hh.dat.gz'
  pathname = 'swfo/data/sci/stis/prelaunch/realtime/'+station+'/cmblk/YYYY/MM/DD/swfo_stis_cmblk_YYYYMMDD_hh.dat.gz'

  files = file_retrieve(pathname,_extra=source,trange=trange)
  ;w=where(file_test(files),/null)
  ;files = files[w]


  ;rdr = gsemsg_reader(mission='SWFO',/no_widget,verbose=verbose,run_proc=run_proc)
  rdr = cmblk_reader(mission='SWFO',/no_widget,verbose=verbose,run_proc=run_proc)
  rdr.add_handler, 'raw_tlm',  gsemsg_reader(name='SWFO_reader',/no_widget,mission='SWFO')
  rdr.add_handler, 'raw_ball', ccsds_reader(/no_widget,name='BALL_reader' , sync_pattern = ['2b'xb,  'ad'xb ,'ca'xb, 'fe'xb], sync_mask= [0xef,0xff,0xff,0xff] )
  rdr.file_read,files

  ; swfo_apdat_info,/print,/all,/create_tplot_var

  sciobj = swfo_apdat('stis_sci')    ; This gets the object that contains all science products
  level_0b_da = sciobj.getattr('level_0b')  ; this a (dynamic) array of structures that contain all level_0B data
  level_1a_da = sciobj.getattr('level_1a')

  level_0b_structs = level_0b_da.array
  l1a = level_1a_da.array

  store_data, 'total6', data={x: l1a.time_unix, y: transpose(l1a.total6)}
  options, 'total6', labels=['Ch1', 'Ch2', 'Ch3', 'Ch4', 'Ch5', 'Ch6'], ylog=1, labflag=1

  store_data, 'noise_sigma', data={x: l1a.time_unix, y: transpose(l1a.noise_sigma)}
  options, 'noise_sigma', labels=['Ch1', 'Ch2', 'Ch3', 'Ch4', 'Ch5', 'Ch6'], labflag=1

  store_data, 'noise_histogram', data={x: l1a.time_unix, y: transpose(l1a.noise_histogram)}
  options, 'noise_histogram', labels=['Ch1', 'Ch2', 'Ch3', 'Ch4', 'Ch5', 'Ch6'], labflag=1, spec=1,/no_interp,/zlog,constant=findgen(6)*10+5

  tplot, ['total6', 'noise_sigma', 'noise_histogram']

  level_0b_da.make_ncdf,filename=l0b_filename

end
