;swfo_stis_ar_crib.pro
;

if ~isa(level_0b_da) then begin

  station = 'S2'
  trange = ['23 7 26 4','23 7 26 5']
  trange = ['23 7 27 4','23 7 27 24']  & station='S2'   ; Calibration with ion gun
  trange = ['2023-7-27 2','2023-7-27 5'] & station='S2' ; Calibration with ion gun with high ion flux and DECIMATION on 
  ;trange = ['23 7 27 17 ','23 7 27 19']  & station='S2'   ; High flux ions from calibration
  ;trange = ['23 6 1','23 6 1 4']  & station='S0'     ; 1/r^2 test with x-ray source
   stop

  ; Keywords for write testing:
  test_ncdf_write = 0
  test_cmblk_write = 0

  ; if 0 then begin
  ;   ;swfo_stis_load,station = 'S2',trange=trange ,reader=rdr,no_widget=1,file='cmblk'
  ;   swfo_stis_load,station = 'S0',trange=trange,reader=rdr,no_widget=1,file='cmblk'
  ; endif else begin
  if find_handle('swfo_stis_sci_COUNTS') eq 0 then begin
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

    if test_cmblk_write then begin
      raw_gsemsg = rdr.get_handlers('raw_tlm')
      ccsds_rdr = raw_gsemsg.getattr('ccsds_reader')
      openw,lun,'SWFO_STIS_L0A.bin',/get_lun
      ccsds_rdr.ccsds_output_lun = lun
    endif


    rdr.file_read,files

    swfo_apdat_info,/print,/all,/create_tplot_var
    tplot_names
    ; endelse
  endif

  swfo_stis_plot,param=param
  printdat,param.lim
  param.range = 10

  sciobj = swfo_apdat('stis_sci')    ; This gets the object that contains all science products
  level_0b_da = sciobj.getattr('level_0b')  ; this a (dynamic) array of structures that contain all level_0B data
  level_1A_da = sciobj.getattr('level_1a')
  level_1b_da = sciobj.getattr('level_1b')


endif
;Additional examples of how to extract data from the object and then recompute the data


level_0b_structs = level_0b_da.array

if 1 then begin
  ;level_1a_structs = level_1a_da.array
  level_1a_structs =   swfo_stis_sci_level_1a(level_0b_structs)
  test_1a = dynamicarray(level_1a_structs,name = 'test_1a')

  tname = 'test_'
  store_data,tname+'L1a',data = test_1a,tagnames = 'SPEC_??',val_tag='_NRG'
  options,tname+'L1a_SPEC_??',spec=1,/ylog,/zlog,yrange=[.1,1e4],zrange=[1,1.]

  tplot,'*L0b_SCI_RESOLUTION *L0b_SCI_TRANSLATE test_*'
  ;stop
endif


level_1b_structs =   swfo_stis_sci_level_1b(level_1a_structs)

; Test monotonicity of time axis:
; (warning: if testing this crib repeatedly, need to do .reset
;  since the swfo_apdat object will append the ccsds packet
;  each time as if a new packet, causing an apparent time reversal.)
; t_unix = reform(level_1b_structs.time_unix[0])
; plot, t_unix - t_unix[0]
; print, t_unix[0], t_unix[n_elements(t_unix) - 1]
; print, min(t_unix), max(t_unix)


if test_ncdf_write then begin
  level_0b_da.make_ncdf,filename='STIS_L0B_test.nc'
  level_1a_da.make_ncdf,filename='STIS_L1A_test.nc'
  level_1b_da.make_ncdf,filename='STIS_L1B_test.nc'
endif

swfo_stis_tplot,/set,'dl1'
swfo_stis_tplot,/set,'iongun',/add

; Adds the hdr fluxes:
swfo_stis_hdr_tplot, level_1b_structs, elec=(station eq 'S0'), ion=(station eq 'S2'), /add


ctime,/silent,t,routine_name="swfo_stis_plot"


end
