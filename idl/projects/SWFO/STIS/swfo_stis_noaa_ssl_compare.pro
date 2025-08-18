;swfo_stis_noaa_ssl_compare.pro
;

; ; check the decimation factor ordering:
; noaa_l0b_dec1 = swfo_stis_level_0b_fromncdf(swfo_ncdf_read(filenames='/Users/rjolitz/swfo_dat/SWFO_STIS_xray_combined_l0b_decimation_factor_bits_2_3_5_6.nc'), /noaa)
; noaa_l0b_dec2 = swfo_stis_level_0b_fromncdf(swfo_ncdf_read(filenames='/Users/rjolitz/swfo_dat/SWFO_STIS_xray_combined_l0b_decimation_factor_bits_6_5_3_2.nc'), /noaa)



; e2e4_file = '/Users/rjolitz/swfo_dat/stis_e2e4_rfr_realtime_30min_combined_l0b.nc'
; noaa_xray_test_filename = '/Users/rjolitz/swfo_dat/SWFO_STIS_xray_combined_l0b.nc'

noaa_xray_test_filename = '/Users/rjolitz/swfo_dat/SWFO_STIS_xray_combined_l0b_decimation_factor_bits_2_3_5_6.nc'
ssl_l0b_xray_filename = '/Users/rjolitz/swfo_dat/STIS_L0B_xray_ssl.nc'


window, 0, XSIZE=750, YSIZE=800

tic
level_0b_noaa = swfo_ncdf_read(filenames=noaa_xray_test_filename, force_recdim=0)
print, 'Netcdf from NOAA has been read, has # records: ', n_elements(l0b_noaa_nc)
toc
stop

; tic
; level_0b_noaa = swfo_stis_level_0b_fromncdf(l0b_noaa_nc, /noaa)
; print, 'Relabeled NOAA struct so consistent with SSL categories: ', n_elements(level_0b_noaa)
; toc

noaa_prefix = 'noaa_swfo_stis_'

; Add tplot var:
if n_elements(level_0b_noaa) ne 0 then begin
    ddata = dynamicarray(name='Science_L0b')
    ddata.append, level_0b_noaa
  store_data,noaa_prefix+'L0b',data = ddata,tagnames = '*'  , verbose=1 ;, time_tag = 'TIME_UNIX';,val_tag='_NRG'    ; warning don't use time_tag keyword
  options,noaa_prefix+'L0b_SCI_COUNTS',spec=1, zlog=1
 endif

tplot, noaa_prefix + ['L0b_SCI_COUNTS', 'L0b_SCI_TRANSLATE', $
        'L0b_SCI_RESOLUTION', 'L0b_SCI_DECIMATION_FACTOR_BITS']
options, noaa_prefix + 'L0b_SCI_DECIMATION_FACTOR_BITS', psym=4

; Now convert into L1a and l1b:
level_1a_noaa =   swfo_stis_sci_level_1a(level_0b_noaa)
n_l1a = n_elements(level_1a_noaa)
print, 'Now l1a: ', n_l1a

if n_l1a ne 0 then begin
    ddata = dynamicarray(name='Science_L1a')
    ddata.append, level_1a_noaa
  store_data,noaa_prefix+'L1a',data = ddata,tagnames = 'SPEC_??',val_tag='_NRG'
  options,noaa_prefix+'L1a_SPEC_??',spec=1, zlog=1, ylog=1, yrange=[10, 2e3]
endif

tplot, noaa_prefix+['L1a_SPEC_O3', 'L1a_SPEC_O1', 'L1a_SPEC_F3', 'L1a_SPEC_F1'], /add

level_1b_noaa =   swfo_stis_sci_level_1b(level_1a_noaa)
n_l1b = n_elements(level_1b_noaa)
print, 'Now l1b: ', n_l1b

if n_l1b ne 0 then begin
    swfo_stis_hdr_tplot, level_1b_noaa, prefix=noaa_prefix, /ion, /elec, /add
endif

stop

window, 2, XSIZE=750, YSIZE=800

; ; SSL: Decommutate raw packets and load into a L0b:
; station = 'S2'
; trange = ['23 7 26 4','23 7 26 5']
; trange = ['23 7 27 4','23 7 27 24']    ; Calibration with ion gun
; trange = ['23 7 27 17 ','23 7 27 19']  & station='S2'   ; High flux ions from calibration
; trange = ['23 6 1','23 6 1 4']  & station='S0'     ; 1/r^2 test with x-ray source

; source = {$
; remote_data_dir:'http://sprg.ssl.berkeley.edu/data/', $
; master_file: 'swfo/.master', $
; no_update : 1 ,$
; no_download :1 ,$
; resolution: 3600L  }

; ;pathname = 'swfo/data/sci/stis/prelaunch/realtime/S2/gsemsg/YYYY/MM/DD/swfo_stis_socket_YYYYMMDD_hh.dat.gz'     
; ;pathname = 'swfo/data/sci/stis/prelaunch/realtime/S2/cmblk/YYYY/MM/DD/swfo_stis_cmblk_YYYYMMDD_hh.dat.gz'
; pathname = 'swfo/data/sci/stis/prelaunch/realtime/'+station+'/cmblk/YYYY/MM/DD/swfo_stis_cmblk_YYYYMMDD_hh.dat.gz'

; files = file_retrieve(pathname,_extra=source,trange=trange)
; ;w=where(file_test(files),/null)
; ;files = files[w]

; swfo_stis_apdat_init,/save_flag

; ;rdr = gsemsg_reader(mission='SWFO',/no_widget,verbose=verbose,run_proc=run_proc)
; rdr = cmblk_reader(mission='SWFO',/no_widget,verbose=verbose,run_proc=run_proc)
; rdr.add_handler, 'raw_tlm',  gsemsg_reader(name='SWFO_reader',/no_widget,mission='SWFO')
; rdr.add_handler, 'raw_ball', ccsds_reader(/no_widget,name='BALL_reader' , sync_pattern = ['2b'xb,  'ad'xb ,'ca'xb, 'fe'xb], sync_mask= [0xef,0xff,0xff,0xff] )



; rdr.file_read,files
; swfo_apdat_info,/print,/all,/create_tplot_var
; tplot_names


; sciobj = swfo_apdat('stis_sci')    ; This gets the object that contains all science products
; level_0b_da = sciobj.getattr('level_0b')  ; this a (dynamic) array of structures that contain all level_0B data
; level_1A_da = sciobj.getattr('level_1a')
; level_1b_da = sciobj.getattr('level_1b')

ssl_l0b = swfo_ncdf_read(filenames=ssl_l0b_xray_filename)

ssl_level_0b = swfo_stis_level_0b_fromncdf(ssl_l0b)

ssl_prefix = 'ssl_swfo_stis_'

; Add tplot var:
if n_elements(ssl_level_0b) ne 0 then begin
    ddata = dynamicarray(name='Science_L0b')
    ddata.append, ssl_level_0b
  store_data,ssl_prefix+'L0b',data = ddata,tagnames = '*'  , verbose=1 ;, time_tag = 'TIME_UNIX';,val_tag='_NRG'    ; warning don't use time_tag keyword
  options,ssl_prefix+'L0b_SCI_COUNTS',spec=1, zlog=1
 endif

tplot, ssl_prefix + ['L0b_SCI_COUNTS', 'L0b_SCI_TRANSLATE', $
        'L0b_SCI_RESOLUTION', 'L0b_SCI_DECIMATION_FACTOR_BITS'], window=2
options, ssl_prefix + 'L0b_SCI_DECIMATION_FACTOR_BITS', psym=4

; Now convert into L1a and l1b:
level_1a_ssl =   swfo_stis_sci_level_1a(ssl_level_0b)
n_l1a = n_elements(level_1a_ssl)
print, 'Now l1a: ', n_l1a

if n_l1a ne 0 then begin
    ddata = dynamicarray(name='Science_L1a')
    ddata.append, level_1a_ssl
  store_data,ssl_prefix+'L1a',data = ddata,tagnames = 'SPEC_??',val_tag='_NRG'
  options,ssl_prefix+'L1a_SPEC_??',spec=1, zlog=1, ylog=1, yrange=[10, 2e3]
endif

tplot, ssl_prefix+['L1a_SPEC_O3', 'L1a_SPEC_O1', 'L1a_SPEC_F3', 'L1a_SPEC_F1'], /add

level_1b_ssl =   swfo_stis_sci_level_1b(level_1a_ssl)
n_l1b = n_elements(level_1b_ssl)
print, 'Now l1b: ', n_l1b

if n_l1b ne 0 then begin
    swfo_stis_hdr_tplot, level_1b_ssl, prefix=prefix, /ion, /elec, /add
endif


; tplot, ['swfo_stis_L0b_SCI_COUNTS', 'swfo_stis_L0b_SCI_TRANSLATE', $
;         'swfo_stis_L0b_SCI_RESOLUTION', 'swfo_stis_L0b_SCI_DECIMATION_FACTOR_BITS'], window=2
; options, 'swfo_stis_L0b_SCI_DECIMATION_FACTOR_BITS', psym=4
; options,'swfo_stis_L0b_SCI_COUNTS',spec=1, zlog=1

; tplot, ['swfo_stis_L1a_SPEC_O3', 'swfo_stis_L1a_SPEC_O1', $
;         'swfo_stis_L1a_SPEC_F3', 'swfo_stis_L1a_SPEC_F1'], /add
; options,'swfo_stis_L1a_SPEC_??',spec=1, zlog=1, ylog=1, yrange=[10, 2e3]
; swfo_stis_hdr_tplot, level_1b_da.array, prefix=prefix, /ion, /elec, /add

end